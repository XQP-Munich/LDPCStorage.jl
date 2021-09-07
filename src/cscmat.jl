using SparseArrays
using LinearAlgebra


CSCMAT_FORMAT_VERSION = v"0.1.0"  # track version of our custom CSCMAT file format.


"""
write the three arrays defining compressed sparse column (CSC) storage of a matrix into a file.

If `try_hex`, integers in arrays are stored as hexadecimals (without 0x prefix!)
If `allow_omit_entries_if_only_stored_ones`, the `stored values` array is omitted if all stored values compare equal to 1.
"""
function save_to_cscmat(
    mat::SparseMatrixCSC, destination_file_path::String
    ;
    additional_header_lines="",
    try_hex::Bool=false,
    allow_omit_entries_if_only_stored_ones=false,
    )

    try
        additional_header_lines = "#"*join(split(additional_header_lines, "\n"), "\n# ")
    catch
        @warn "Failed to process additional header lines. Discarding them."
        additional_header_lines = ""
    end

    if file_extension(destination_file_path) != ".cscmat"
        @warn "Writing to sparse column storage file with with extension
            '$(file_extension(destination_file_path))', expected '.cscmat'. (path '$(destination_file_path)')"
    end

    number_map(x::Real) = x
    number_map(n::Integer) = string(n, base=try_hex ? 16 : 10)

    open(destination_file_path, "w+") do file
        println(file, "# $CSCMAT_FORMAT_VERSION")
        println(file, "# Compressed sparse column storage of matrix (arrays `colptr`, `rowval`, `stored_values`"
            *" as space separated $(try_hex ? "hexadecimal" : "decimal") integers. Stored entries may be zero.).")
        println(file, additional_header_lines)
        println(file, "# n_rows n_columns n_stored_entries")
        println(file, "$(mat.m) $(mat.n) $(nnz(mat))\n")

        println(file, join(number_map.(mat.colptr .- 1), " "))  # convert to zero-based indices
        println(file, "")
        println(file, join(number_map.(mat.rowval .- 1), " "))  # convert to zero-based indices
        println(file, "")

        if !allow_omit_entries_if_only_stored_ones || any(x->x!=1, mat.nzval)
            println(file, join(number_map.(mat.nzval), " "))
        end
    end

    return nothing
end


function read_file_header(file_path; comment_marker = '#')
    header = ""
    open(file_path, "r") do file
        next_line = ""
        while true
            header *= (next_line*"\n")
            next_line = readline(file)

            (length(next_line) > 0 && next_line[1] == comment_marker) || break
        end
    end

    return header
end


"""
read the three arrays defining compressed sparse column (CSC) storage of a matrix into a file.

If `try_hex`, integers are stored as hexadecimals (without 0x prefix!)
"""
function load_cscmat(file_path::String;
    print_file_header=false)
    expected_file_extension = ".cscmat"
    if file_extension(file_path) != expected_file_extension
        @warn "load_cscmat called on file '$(file_path)'
            with extension '$(file_extension(file_path))', expected $expected_file_extension"
    end

    file = open(file_path, "r")
    header = ""
    next_line = ""
    while true
        header *= (next_line*"\n")
        next_line = readline(file)

        (length(next_line) > 0 && next_line[1] == '#') || break
    end

    try
        header[1] == "# $CSCMAT_FORMAT_VERSION" && @warn "File written in format $(header[1][2:end]) is being read in format $CSCMAT_FORMAT_VERSION"
    catch e
        @warn "Failed to verify CSC file format version: $e"
    end

    if contains(header, "hexadecimal")
        base = 16
    else
        base = 10
    end

    print_file_header && print(header)

    n_rows, n_cols, n_nnz = space_sep_ints(next_line)
    _ = readline(file)  # empty line

    colptr = space_sep_ints(readline(file); base)
    _ = readline(file)  # empty line

    rowval = space_sep_ints(readline(file); base)
    _ = readline(file)  # empty line

    stored_entries = space_sep_ints(readline(file); base)
    _ = readline(file)  # empty line
    remaining_lines = readlines(file)
    close(file)

    if length(remaining_lines) > 0
        @warn "Ignoring additional lines:\n`$remaining_lines`"
    end

    if length(stored_entries) == 0
        stored_entries = ones(Int8, n_nnz)
    end

    # convert from zero-based to one-based indices.
    return SparseMatrixCSC(n_rows, n_cols, colptr .+1, rowval .+1, stored_entries)
end



"""
convert matrix of exponents for QC LDPC matrix to the actual binary LDPC matrix.

The resulting QC-LDPC matrix is a block matrix where each block is either zero,
or a circ-shifted identity matrix of size `expansion_factor`x`expansion_factor`.
Each entry of the matrix Hqc denotes the amount of circular shift in the QC-LDPC matrix.
No entry (i.e., a zero but not a stored one) at a given position in Hqc means the associated block is zero.
"""
function Hqc_to_pcm(
    Hqc::SparseMatrixCSC{T,Int} where T <: Integer,
    expansion_factor::Integer,
    )
    scale_idx(idx::Integer, expansion_factor::Integer) = (idx - 1) * expansion_factor + 1
    shifted_identity(N::Integer, shift::Integer, scalar_one=Int8(1)) = circshift(Matrix(scalar_one*I, N, N), (0, shift))

    H = spzeros(Int8, size(Hqc, 1) * expansion_factor, size(Hqc, 2) * expansion_factor)

    Is, Js, Vs = findnz(Hqc)

    for (i, j, v) in zip(Is, Js, Vs)
        i_start = scale_idx(i, expansion_factor)
        i_end = scale_idx(i+1,expansion_factor) - 1
        j_start = scale_idx(j, expansion_factor)
        j_end = scale_idx(j+1, expansion_factor) - 1
        H[i_start:i_end, j_start:j_end] = shifted_identity(expansion_factor, v, Int8(1))
    end

    return H
end


"""
Load exponents for a QC-LDPC matrix from a `.CSCMAT` file and return the binary LDPC matrix.

Not every input `.cscmat` file will give a meaninful result.
The `.cscmat` format allows to store general sparse matrices in text format.
Meanwhile, this function expects that the file stores exponents for a quasi-cyclic LDPC matrix.
The exponent matrix is read and expanded using the expansion factor.

If the expansion factor is not provided, the CSCMAT file must contain a line specifying it.
"""
function load_matrix_from_qc_cscmat_file(file_path::AbstractString; expansion_factor=nothing)
    if isnothing(expansion_factor)
        header = ""
        next_line = ""

        open(file_path, "r") do f
            while true
                header *= (next_line * "\n")
                next_line = readline(f)

                (length(next_line) > 0 && next_line[1] == '#') || break
            end
        end

        m = match(r"Quasi cyclic exponents for a binary LDPC matrix with expansion factor ([0-9]*)\.", header)
        if isnothing(m)
            error("Failed to infer expansion factor! No header line found containing it.")
        else
            expansion_factor = parse(Int, m.captures[1])
            @info "Inferred expansion factor from file header: $expansion_factor"
        end
    end

    Hqc = load_cscmat(file_path)

    H = Hqc_to_pcm(Hqc, expansion_factor)

    return H
end
