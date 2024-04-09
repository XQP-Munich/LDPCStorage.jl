using SparseArrays, SHA

"""
$(SIGNATURES)

parse a single line of space separated integers
"""
space_sep_ints(s::AbstractString; base=10) = parse.(Int, split(s); base)


function file_extension(path::String)
    if contains(path, ".")
        return path[findlast(isequal('.'),path):end]
    else
        return ""
    end
end


"""
$(SIGNATURES)

Returns a 256 bit hash of a sparse matrix.
This function should only be used for unit tests!!!
"""
function hash_sparse_matrix(H::SparseMatrixCSC)
    ctx = SHA2_256_CTX()

    io = IOBuffer(UInt8[], read=true, write=true)
    write(io, H.colptr)
    write(io, H.rowval)
    write(io, H.nzval)

    update!(ctx, take!(io))

    return digest!(ctx)
end
