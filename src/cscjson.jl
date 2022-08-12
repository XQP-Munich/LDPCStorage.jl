using SparseArrays
using LinearAlgebra
using JSON

CSCJSON_FORMAT_VERSION = v"0.3.0"  # track version of our custom compressed sparse storage json file format.
const format_if_nnz_values_omitted = :BINCSCJSON
const format_if_nnz_values_stored = :COMPRESSED_SPARSE_COLUMN

const description = "Compressed sparse column storage of a matrix (arrays `colptr`, `rowval`, `stored_values` "*
    "are given in fields of the same name. Stored entries may be zero.). "*
    "If the `format` is $format_if_nnz_values_omitted, the nonzero values are omitted to save storage space. "*
    "Otherwise, format is expected to be $format_if_nnz_values_stored."


"""
Errors unless sparse matrix only contains ones and zeros.
writes the two arrays `colptr` and `rowval` defining compressed sparse column (CSC) storage of a the into a json file.
The third array of CSC format, i.e., the nonzero entries, is not needed, since 
"""
function save_to_bincscjson(
    mat::SparseMatrixCSC, destination_file_path::String
    ;
    comments::AbstractString="",
    )
    all(x->x==1, mat.nzval) || error(
        "The input matrix has nonzero entries besides 1. Note: the matrix should have no stored zeros.")

    expected_extension = ".bincsc.json"
    if !endswith(destination_file_path, expected_extension)
        @warn "Expected extension '$expected_extension' when writing to '$(destination_file_path)')"
    end
    
    data = Dict(
        :CSCJSON_FORMAT_VERSION => string(CSCJSON_FORMAT_VERSION),
        :description => description,
        :comments => comments,
        :format => format_if_nnz_values_omitted,  # this function does not store nonzero values.
        :n_rows => mat.m,
        :n_columns => mat.n,
        :n_stored_entries => nnz(mat),
        :colptr => mat.colptr .- 1,
        :rowval => mat.rowval .- 1,
    )

    open(destination_file_path, "w+") do file
        JSON.print(file, data)
    end

    return nothing
end


"""
write the three arrays defining compressed sparse column (CSC) storage of a matrix into a file.
This is used to store the exponents of a quasi-cyclic LDPC matrix.
The QC expansion factor must be specified.
"""
function save_to_qccscjson(
    mat::SparseMatrixCSC, destination_file_path::String,
    ;
    qc_expansion_factor::Integer,
    comments::AbstractString="",
    )

    expected_extension = ".qccsc.json"
    if !endswith(destination_file_path, expected_extension) 
        @warn "Expected extension '$expected_extension' when writing to '$(destination_file_path)')"
    end

    data = Dict(
        :CSCJSON_FORMAT_VERSION => string(CSCJSON_FORMAT_VERSION),
        :description => description,
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

    open(destination_file_path, "w+") do file
        JSON.print(file, data)
    end

    return nothing
end


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
        error("File $file_path specifies invalid format `$(data["format"])`.")
    end
end
