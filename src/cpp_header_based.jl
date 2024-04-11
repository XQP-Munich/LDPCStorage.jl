# This script generates a `.hpp` file (C++ header) containing
# an LDPC code stored in compressed sparse column (CSC) format.
# See command line help for how to use it.

using SparseArrays
using LinearAlgebra

using Pkg

# TODO!!!! USE `pkgversion(m::Module)` IN JULIA 1.9

const CPP_FILE_DESCRIPTION_BINARY_BINARY = """
// This file was automatically generated using LDPCStorage.jl (https://github.com/XQP-Munich/LDPCStorage.jl).
// A sparse LDPC matrix (containing only zeros and ones) is saved in compressed sparse column (CSC) format.
// The "values" array of the CSC format is not included because all entries are assumed to be `1`.
// Hence only two arrays are stored: `colptr` and `row_idx`.
//
// Since the matrix (and LDPC code) is known at compile time, there is no need to save it separately in a file.
// This significantly blows up the executable size (the memory would still have to be used when saving the matrix).
"""

const CPP_FILE_DESCRIPTION_QC_EXPONENTS = """
// This file was automatically generated using LDPCStorage.jl (https://github.com/XQP-Munich/LDPCStorage.jl).
// A sparse quasi-cyclic LDPC matrix (containing only zeros and ones) is saved in compressed sparse column (CSC) format.
// The matrix is not stored directly, rather its quasi-cyclic exponents are stored in CSC format, hence using arrays for
// `colptr`, `row_idx` and `values`.
//
// Since the matrix (and LDPC code) is known at compile time, there is no need to save it separately in a file.
// This significantly blows up the executable size (the memory would still have to be used when saving the matrix).
"""

function smallest_cpp_type(x::Real)
    if x isa Integer
        bits_needed = ceil(Int, log2(x))
        if bits_needed <= 8
            return "std::uint8_t"
        elseif bits_needed <= 16
            return "std::uint16_t"
        elseif bits_needed <= 32
            return "std::uint32_t"
        elseif bits_needed <= 64
            return "std::uint64_t"
        else
            throw(ArgumentError("Value $x does not fit a standard-supported C++ fixed width integer type."))
        end
    else
        return "double"
    end
end


"""
$(SIGNATURES)

Output C++ header storing the sparse binary (containing only zeros and ones) matrix H
in compressed sparse column (CSC) format.

Note the conversion from Julia's one-based indices to zero-based indices in C++ (also within CSC format)!
"""
function print_cpp_header(
    io::IO,
    H::SparseMatrixCSC{Int8}
    ;
    namespace_name::AbstractString = "AutogenLDPC",
    )
    H = dropzeros(H)  # remove stored zeros!
    _, _, values = findnz(H)

    all(values .== 1) || throw(ArgumentError("Expected matrix containing only zeros and ones."))

    num_nonzero = length(values)
    colptr_cpp_type = smallest_cpp_type(num_nonzero)

    row_idx_cpp_type = smallest_cpp_type(size(H, 1))

    print(io, CPP_FILE_DESCRIPTION_BINARY_BINARY)

    println(io, """
    #include <cstdint>
    #include <array>

    namespace $namespace_name {

    constexpr inline std::size_t M = $(size(H, 1));  // number of matrix rows
    constexpr inline std::size_t N = $(size(H, 2));  // number of matrix columns
    constexpr inline std::size_t num_nz = $num_nonzero;  // number of stored entries

    constexpr inline std::array<$colptr_cpp_type, N + 1> colptr = {""")

    for (i, idx) in enumerate(H.colptr)
        print(io, "0x$(string(idx - 1, base=16))")  # Convert index to base zero
        if i != length(H.colptr)
            print(io, ",")
        end
        if mod(i, 100) == 0
            println(io, "")  # for formatting.
        end
    end
    println(io, "\n};\n")

    println(io, "// ------------------------------------------------------- \n")
    println(io, "constexpr inline std::array<$row_idx_cpp_type, num_nz> row_idx = {")

    for (i, idx) in enumerate(H.rowval)
        print(io, "0x$(string(idx - 1, base=16))")  # Convert index to base zero
        if i != length(H.rowval)
            print(io, ",")
        end
        if mod(i, 100) == 0
            println(io, "")  # for formatting.
        end
    end
    println(io, "\n};\n\n")

    println(io, "} // namespace $namespace_name")
end


"""
$(SIGNATURES)

Output C++ header storing the quasi-cyclic exponents of an LDPC matrix in compressed sparse column (CSC) format.
This implies three arrays, which are called `colptr`, `row_idx` and `values`.
The expansion factor must also be given (it is simply stored as a variable in the header).

Note the conversion from Julia's one-based indices to zero-based indices in C++ (also within CSC format)!
"""
function print_cpp_header_QC(
    io::IO,
    H::SparseMatrixCSC
    ;
    expansion_factor::Integer,
    namespace_name::AbstractString = "AutogenLDPC_QC",
    )
    H = dropzeros(H)  # remove stored zeros!
    _, _, values = findnz(H)

    num_nonzero = length(values)
    colptr_cpp_type = smallest_cpp_type(num_nonzero)

    row_idx_cpp_type = smallest_cpp_type(size(H, 1))

    values_cpp_type = smallest_cpp_type(maximum(values))

    print(io, CPP_FILE_DESCRIPTION_QC_EXPONENTS)

    println(io, """
    #include <cstdint>
    #include <array>

    namespace $namespace_name {

    constexpr inline std::size_t M = $(size(H, 1));  // number of matrix rows
    constexpr inline std::size_t N = $(size(H, 2));  // number of matrix columns
    constexpr inline std::size_t num_nz = $num_nonzero;  // number of stored entries
    constexpr inline std::size_t expansion_factor = $expansion_factor;

    constexpr inline std::array<$colptr_cpp_type, N + 1> colptr = {""")

    for (i, idx) in enumerate(H.colptr)
        print(io, "0x$(string(idx - 1, base=16))")  # Convert index to base zero
        if i != length(H.colptr)
            print(io, ",")
        end
        if mod(i, 100) == 0
            println(io, "")  # for formatting.
        end
    end
    println(io, "\n};\n")

    println(io, "// ------------------------------------------------------- \n")
    println(io, "constexpr inline std::array<$row_idx_cpp_type, num_nz> row_idx = {")

    for (i, idx) in enumerate(H.rowval)
        print(io, "0x$(string(idx - 1, base=16))")  # Convert index to base zero
        if i != length(H.rowval)
            print(io, ",")
        end
        if mod(i, 100) == 0
            println(io, "")  # for formatting.
        end
    end
    println(io, "\n};\n\n")

    println(io, "// ------------------------------------------------------- \n")
    println(io, "constexpr inline std::array<$values_cpp_type, num_nz> values = {")

    for (i, v) in enumerate(H.nzval)
        print(io, string(v))
        if i != length(H.rowval)
            print(io, ",")
        end
        if mod(i, 100) == 0
            println(io, "")  # for formatting.
        end
    end
    println(io, "\n};\n\n")

    println(io, "} // namespace $namespace_name")
end
