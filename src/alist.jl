using SparseArrays
using LinearAlgebra
using StatsBase: countmap

struct InconsistentAlistFileError <: Exception 
    msg::Any
end

function Base.showerror(io::IO, e::InconsistentAlistFileError)
    print(io, "InconsistentAlistFileError: ", e.msg)
end

"""
$(SIGNATURES)

Load an LDPC matrix from a text file in alist format. Returns a SparseMatrixCSC{Int8}.

By default, issues a warning if file extension is not ".alist". (Change `warn_unexpected_file_extension` to disable.)
The alist format is redundant (the two halves of a file specify the same information, once by-row and once by-column).
This function only uses the first half. (Change `check_redundant` to also parse and verify the second half.)

For definition of alist format, see http://www.inference.org.uk/mackay/codes/alist.html
"""
function load_alist(file_path::AbstractString; check_redundant=false, warn_unexpected_file_extension=true)
    if warn_unexpected_file_extension && file_extension(file_path) != ".alist"
        @warn "load_alist called on file with extension '$(file_extension(file_path))', expected '.alist'"
    end

    local nVN, nCN
    local dmax_VN, dmax_CN
    local var_node_degs, check_node_degs
    local remaining_lines
    try
        open(file_path, "r") do file
            nVN, nCN = space_sep_ints(readline(file))  # sparse matrix has size (nCN, nVN)
            dmax_VN, dmax_CN = space_sep_ints(readline(file))
            var_node_degs = space_sep_ints(readline(file))
            check_node_degs = space_sep_ints(readline(file))
            remaining_lines = readlines(file)
        end
    catch e
        throw(InconsistentAlistFileError("Failed to parse '$(abspath(file_path))' as alist file. Reason:\n$e"))
    end
    
    # ignore empty lines. Allows, e.g., trailing newlines.
    # The alist-files which this library writes do not include a trailing newline.
    filter!(remaining_lines) do s
        !isnothing(findfirst(r"\S+", s))  # r"\S+" means "at least one non-whitespace character"
    end

    if length(remaining_lines) != nVN + nCN
        throw(InconsistentAlistFileError("Number of lines in $file_path is inconcistent with stated matrix size."))
    end

    if dmax_CN != maximum(check_node_degs)
        throw(InconsistentAlistFileError("Alist file $file_path claims: max. CN degree=$dmax_CN but contents give $(maximum(check_node_degs))."))
    end

    if dmax_VN != maximum(var_node_degs)
        throw(InconsistentAlistFileError("Alist file $file_path claims: max. VN degree=$dmax_CN but contents give $(maximum(var_node_degs))."))
    end

    # fill the matrix using coordinate format (COO)
    I = Int[]; sizehint!(I, nCN ÷ 100)  # assume sparsity of 1% to minimize re-allocations
    J = Int[]; sizehint!(J, nVN ÷ 100)  # assume sparsity of 1% to minimize re-allocations
    for col_ind in 1:nVN
        rows = space_sep_ints(remaining_lines[col_ind])

        if check_redundant && length(rows) != var_node_degs[col_ind]
            throw(InconsistentAlistFileError("Variable node degree in $file_path inconcistent with below data for VN $col_ind."))
        end

        for row_ind in rows
            # achieves `H[row_ind, col_ind] = 1`
            push!(I, row_ind)
            push!(J, col_ind)
        end
    end
    H = sparse(I, J, one(Int8))  # has size (nCN, nVN)

    # the second half of the alist file is redundant. Check that it is consistent.
    if check_redundant
        entry_counter = 0
        for row_ind in 1:nCN
            cols = space_sep_ints(remaining_lines[nVN + row_ind])

            check_node_degree = length(cols)
            if check_node_degree != check_node_degs[row_ind]
                throw(InconsistentAlistFileError("Check node degree in $file_path inconcistent with below data for CN $row_ind."))
            end

            entry_counter += check_node_degree
            for col_ind in cols
                if H[row_ind, col_ind] != 1
                    throw(InconsistentAlistFileError("VN and CN specifications in $file_path disagree on matrix entry ($row_ind, $col_ind)."))
                end
            end
        end

        if entry_counter != sum(H)
            throw(InconsistentAlistFileError("VN and CN specification in $file_path are inconsistent."))
        end
    end

    return H
end


"""
$(SIGNATURES)

Save LDPC matrix to file in alist format. 
It is assumed that the matrix only contains zeros and ones. Otherwise, behavior is undefined.

For details about the Alist format, see:

https://aff3ct.readthedocs.io/en/latest/user/simulation/parameters/codec/ldpc/decoder.html#dec-h-path-image-required-argument

http://www.inference.org.uk/mackay/codes/alist.html
"""
function save_to_alist(out_file_path::String, matrix::AbstractMatrix{Int8})
    open(out_file_path, "w+") do file
        print_alist(file, matrix)
    end

    return nothing
end

"""
$(SIGNATURES)

Save LDPC matrix to file in alist format.
It is assumed that the matrix only contains zeros and ones. Otherwise, behavior is undefined.

For details about the Alist format, see:

https://aff3ct.readthedocs.io/en/latest/user/simulation/parameters/codec/ldpc/decoder.html#dec-h-path-image-required-argument

http://www.inference.org.uk/mackay/codes/alist.html
"""
function print_alist(io::IO, matrix::AbstractMatrix{Int8})
    (the_M, the_N) = size(matrix)

    check_node_degrees, variable_node_degrees = get_node_degrees(matrix)

    # write data as specified by the alist format
    lines = String[]
    # -- Part 1 --
    # 'the_N' is the total number of variable nodes and 'the_M' is the total number of check nodes
    push!(lines, "$the_N $the_M")

    # 'dmax_VN' is the highest variable node degree and 'dmax_CN' is the highest check node degree
    push!(lines, "$(maximum(variable_node_degrees)) $(maximum(check_node_degrees))")

    # list of the degrees for each variable node
    push!(lines, join(["$deg" for deg in variable_node_degrees], " "))

    # list of the degrees for each check node
    push!(lines, join(["$deg" for deg in check_node_degrees], " "))

    # -- Part 2 --
    # each following line describes the check nodes connected to a variable node, the first
    # check node index is '1' (i.e., alist format uses 1-based indexing)
    # variable node '1'
    """
        Get indices of elements equal to one in a matrix.
        Returns `Vector{String}`, one string with indices for each row of the matrix.
    """
    function get_node_indices(matrix::AbstractArray{Int8,2})
        degrees = [findall(row .== 1) for row in eachrow(matrix)]
        return [join(string.(index_list), " ") for index_list in degrees]
    end
    append!(lines, get_node_indices(transpose(matrix)))

    # -- Part 3 --
    # each following line describes the variables nodes connected to a check node, the first
    # variable node index is '1' (i.e., alist format uses 1-based indexing)
    # check node '1'
    append!(lines, get_node_indices(matrix))

    for line in lines
        println(io, line)
    end

    return nothing
end

function get_node_degrees(matrix::AbstractMatrix{Int8})
    check_node_degrees = [sum(row) for row in eachrow(matrix)]
    variable_node_degrees = [sum(row) for row in eachcol(matrix)]
    return check_node_degrees, variable_node_degrees
end

"""Faster version operating on sparse arrays. Assumes all non-zero values are 1!!"""
function get_node_degrees(H_::AbstractSparseMatrix{Int8})
    H = dropzeros(H_)

    I, J, _ = findnz(H)  # assumes all non-zero values are 1!
    row_counts = countmap(I)
    col_counts = countmap(J)
    
    check_node_degrees = zeros(Int, size(H, 1))
    var_node_degrees = zeros(Int, size(H, 2))
    check_node_degrees[collect(keys(row_counts))] .= values(row_counts)
    var_node_degrees[collect(keys(col_counts))] .= values(col_counts)

    return check_node_degrees, var_node_degrees
end
