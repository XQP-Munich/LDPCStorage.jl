using SparseArrays
using LinearAlgebra


"""Load an LDPC matrix from a text file in alist format."""
function load_alist(file_path::AbstractString; check_redundant=false,)
    if file_extension(file_path) != ".alist"
        @warn "load_alist called on file with extension '$(file_extension(file_path))', expected '.alist'"
    end

    file = open(file_path, "r")
    nVN, nCN = space_sep_ints(readline(file))
    dmax_VN, dmax_CN = space_sep_ints(readline(file))
    var_node_degs = space_sep_ints(readline(file))
    check_node_degs = space_sep_ints(readline(file))
    remaining_lines = readlines(file)
    close(file)

    if length(remaining_lines) != nVN + nCN
        error("Number of lines in $file_path is inconcistent with stated matrix size.")
    end

    if dmax_CN != maximum(check_node_degs)
        error("Alist file $file_path claims: max. CN degree=$dmax_CN but contents give $(maximum(check_node_degs)).")
    end

    if dmax_VN != maximum(var_node_degs)
        error("Alist file $file_path claims: max. VN degree=$dmax_CN but contents give $(maximum(var_node_degs)).")
    end

    # parity check matrix
    H = spzeros(Int8, nCN, nVN)

    # fill the matrix
    for col_ind in 1:nVN
        rows = space_sep_ints(remaining_lines[col_ind])

        if check_redundant && length(rows) != var_node_degs[col_ind]
            error("Variable node degree in $file_path inconcistent with below data for VN $col_ind.")
        end

        for row_ind in rows
            H[row_ind, col_ind] = 1
        end
    end

    # the second half of the alist file is redundant. Check that it is consistent.
    if check_redundant
        entry_counter = 0
        for row_ind in 1:nCN
            cols = space_sep_ints(remaining_lines[nVN + row_ind])

            check_node_degree = length(cols)
            if check_node_degree != check_node_degs[row_ind]
                error("Check node degree in $file_path inconcistent with below data for CN $row_ind.")
            end

            entry_counter += check_node_degree
            for col_ind in cols
                if H[row_ind, col_ind] != 1
                    error("VN and CN specifications in $file_path disagree on matrix entry ($row_ind, $col_ind).")
                end
            end
        end

        if entry_counter != sum(H)
            error("VN and CN specification in $file_path are inconsistent.")
        end
    end

    return H
end


"""
    function save_to_alist(matrix::AbstractArray{Int8,2}, out_file_path::String)

Save LDPC matrix to file in alist format. For details about the format, see:
https://aff3ct.readthedocs.io/en/latest/user/simulation/parameters/codec/ldpc/decoder.html#dec-h-path-image-required-argument
http://www.inference.org.uk/mackay/codes/alist.html
todo test this carefully
"""
function save_to_alist(matrix::AbstractArray{Int8,2}, out_file_path::String)

    (the_M, the_N) = size(matrix)

    variable_node_degrees = get_variable_node_degrees(matrix)
    check_node_degrees = get_check_node_degrees(matrix)

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
    # check node index is '1' (and not '0')
    # variable node '1'
    """
        Get indices of elements equal to one in a matrix.
        :param matrix: 2d numpy array
        :return: Array of strings, one string with indices for each line in the matrix.
    """
    function get_node_indices(matrix::AbstractArray{Int8,2})
        # the first check node index is '1' (and not '0')
        degrees = [findall(row .== 1) for row in eachrow(matrix)]
        return [join(string.(index_list), " ") for index_list in degrees]
    end
    append!(lines, get_node_indices(transpose(matrix)))

    # -- Part 3 --
    # each following line describes the variables nodes connected to a check node, the first
    # variable node index is '1' (and not '0')
    # check node '1'
    append!(lines, get_node_indices(matrix))

    open(out_file_path, "w+") do file
        for line in lines
            println(file, line)
        end
    end

    return nothing
end



# helper methods for testing the parity check matrix
function get_variable_node_degrees(matrix::AbstractArray{Int8,2})
    @assert(length(size(matrix)) == 2, "Matrix required. Wrong number of dimensions")
    return [sum(row) for row in eachcol(matrix)]
end


function get_check_node_degrees(matrix::AbstractArray{Int8,2})
    @assert(length(size(matrix)) == 2, "Matrix required. Wrong number of dimensions")
    return [sum(row) for row in eachrow(matrix)]
end
