using SparseArrays
using LinearAlgebra
using JSON

const CSCJSON_FORMAT_VERSION = v"0.3.3"  # track version of our custom compressed sparse storage json file format.
const format_if_nnz_values_omitted = :BINCSCJSON
const format_if_nnz_values_stored = :COMPRESSED_SPARSE_COLUMN

const description = "Compressed sparse column storage of a matrix. The format defines a sparse matrix using arrays "*
    "'column pointers' (json key `colptr`), 'row indices' (key `rowval`) and 'stored entries of the matrix' (key `nzval`). "*
    "If the `format` is $format_if_nnz_values_omitted, the `nzval` array is omitted and all non-zero entries of the matrix are assumed to be '1'."*
    "If `format` is $format_if_nnz_values_stored, `nzval` is included."


get_metadata() = Dict(
    [
    :julia_package_version => string(pkgversion(LDPCStorage))
    :julia_package_url => "https://github.com/XQP-Munich/LDPCStorage.jl"
    ]
)


struct InconsistentBINCSCError <: Exception
    msg::Any
end

function Base.showerror(io::IO, e::InconsistentBINCSCError)
    print(io, "InconsistentBINCSCError: ", e.msg)
end


"""
$(SIGNATURES)

Helper method to use with files. See `print_bincscjson` for main interface.

Writes the two arrays `colptr` and `rowval` defining compressed sparse column (CSC) storage of a the into a json file.
Errors unless sparse matrix only contains ones and zeros.
The third array of CSC format, i.e., the nonzero entries, is not needed, since the matrix is assumed to only contain ones and zeros.
"""
function save_to_bincscjson(
    destination_file_path::String, mat::SparseMatrixCSC, 
    ;
    varargs...,
    )
    expected_extension = ".bincsc.json"
    if !endswith(destination_file_path, expected_extension)
        @warn "Expected extension '$expected_extension' when writing to '$(destination_file_path)')"
    end
    
    open(destination_file_path, "w+") do file
        print_bincscjson(file, mat; varargs...)
    end

    return nothing
end


"""
$(SIGNATURES)

Writes the two arrays `colptr` and `rowval` defining compressed sparse column (CSC) storage of a the into a json file.
Errors unless sparse matrix only contains ones and zeros.
The third array of CSC format, i.e., the nonzero entries, is not needed, since the matrix is assumed to only contain ones and zeros.
"""
function print_bincscjson(
    io::IO, mat::SparseMatrixCSC
    ;
    comments::AbstractString="",
    )
    all(x->x==1, mat.nzval) || throw(ArgumentError(
        "The input matrix has nonzero entries besides 1. Note: the matrix should have no stored zeros."))
    
    data = Dict(
        :CSCJSON_FORMAT_VERSION => string(CSCJSON_FORMAT_VERSION),
        :description => description*"\n\nThis file stores a sparse binary matrix in compressed sparse column (CSC) format.",
        :comments => comments,
        :format => format_if_nnz_values_omitted,  # this function does not store nonzero values.
        :n_rows => mat.m,
        :n_columns => mat.n,
        :n_stored_entries => nnz(mat),
        :colptr => mat.colptr .- 1,
        :rowval => mat.rowval .- 1,
    )

    try
        data[:metadata] = get_metadata()
    catch e
        @warn "Generating metadata failed. Including default. Error:\n $e"
        data[:metadata] = "Metadata generation failed."
    end

    JSON.print(io, data)

    return nothing
end


"""
$(SIGNATURES)

Helper method to use with files. See `print_qccscjson` for main interface.

write the three arrays defining compressed sparse column (CSC) storage of a matrix into a file.
This is used to store the exponents of a quasi-cyclic LDPC matrix.
The QC expansion factor must be specified.
"""
function save_to_qccscjson(
    destination_file_path::String, mat::SparseMatrixCSC
    ;
    varargs...
    )

    expected_extension = ".qccsc.json"
    if !endswith(destination_file_path, expected_extension) 
        @warn "Expected extension '$expected_extension' when writing to '$(destination_file_path)')"
    end

    open(destination_file_path, "w+") do file
        print_qccscjson(file, mat; varargs...)
    end

    return nothing
end


"""
$(SIGNATURES)

write the three arrays defining compressed sparse column (CSC) storage of a matrix into a file.
This is used to store the exponents of a quasi-cyclic LDPC matrix.
The matrix is assumed to contain quasi-cyclic exponents of an LDPC matrix.
The QC expansion factor must be specified.
"""
function print_qccscjson(
    io::IO, mat::SparseMatrixCSC, 
    ;
    qc_expansion_factor::Integer,
    comments::AbstractString="",
    )
    data = Dict(
        :CSCJSON_FORMAT_VERSION => string(CSCJSON_FORMAT_VERSION),
        :description => description*"\n\nThis file stores the quasi-cyclic exponents of a low density parity check (LDPC) code in compressed sparse column (CSC) format.",
        :comments => comments,
        :format => format_if_nnz_values_stored,  # this function does store nonzero values.
        :n_rows => mat.m,
        :n_columns => mat.n,
        :n_stored_entries => nnz(mat),
        :qc_expansion_factor => qc_expansion_factor,
        :colptr => mat.colptr .- 1,
        :rowval => mat.rowval .- 1,
        :nzval => mat.nzval,
    )

    try
        data[:metadata] = get_metadata()
    catch e
        @warn "Generating metadata failed. Including default. Error:\n $e"
        data[:metadata] = "Metadata generation failed."
    end

    JSON.print(io, data)

    return nothing
end


"""
$(SIGNATURES)

Loads LDPC matrix from a json file containing compressed sparse column (CSC) storage for either of
- `qccscjson` (CSC of quasi-cyclic exponents) format
- `bincscjson` (CSC of sparse binary matrix) format

Use option to expand quasi-cyclic exponents and get a sparse binary matrix.
"""
function load_ldpc_from_json(file_path::AbstractString; expand_qc_exponents_to_binary=false)
    data = JSON.parsefile(file_path)

    if VersionNumber(data["CSCJSON_FORMAT_VERSION"]) != CSCJSON_FORMAT_VERSION
        @warn "File $file_path 
        uses format version $(data["CSCJSON_FORMAT_VERSION"])) while library uses format version $CSCJSON_FORMAT_VERSION. Possibly incompatible."
    end

    if data["format"] == string(format_if_nnz_values_omitted)
        return SparseMatrixCSC(data["n_rows"], data["n_columns"], data["colptr"] .+1, data["rowval"] .+1, ones(Int8, data["n_stored_entries"]))
    elseif data["format"] == string(format_if_nnz_values_stored)
        Hqc = SparseMatrixCSC(data["n_rows"], data["n_columns"], data["colptr"] .+1, data["rowval"] .+1, Array{Int}(data["nzval"]))
        if expand_qc_exponents_to_binary
            return Hqc_to_pcm(Hqc, data["qc_expansion_factor"])
        else
            return Hqc
        end
    else
        throw(InconsistentBINCSCError("File $file_path specifies invalid format `$(data["format"])`."))
    end
end


function get_qc_expansion_factor(file_path::AbstractString)
    data = JSON.parsefile(file_path)
    return Int(data["qc_expansion_factor"])
end
