# This script generates a `.hpp` file (C++ header) containing
# an LDPC code stored in compressed sparse column (CSC) format.
# See command line help for how to use it.

using SparseArrays
using LinearAlgebra

using Pkg

# TODO!!!! USE `pkgversion(m::Module)` IN JULIA 1.9
const cpp_file_description = """
// This file was automatically generated using LDPCStorage.jl (https://github.com/XQP-Munich/LDPCStorage.jl).
// A sparse LDPC matrix (containing only zeros and ones) is saved in compressed sparse column (CSC) format.
// Since the matrix (and LDPC code) is known at compile time, there is no need to save it separately in a file.
// This significantly blows up the executable size (the memory would still have to be used when saving the matrix).

"""


"""
$(SIGNATURES)

Output C++ header storing the sparse binary (containing only zeros and ones) matrix H
in compressed sparse column (CSC) format.

Note the conversion from Julia's one-based indices to zero-based indices in C++ (also within CSC format).
"""
function print_cpp_header(
    io::IO,
    H::AbstractArray{Int8, 2}
    ;
    namespace_name::AbstractString = "AutogenLDPC",
    )
    H = dropzeros(H)  # remove stored zeros!
    _, _, values = findnz(H)

    all(values .== 1) || throw(ArgumentError("Expected matrix containing only zeros and ones."))

    num_nonzero = length(values)
    if log2(num_nonzero) < 16
        colptr_cpp_type = "std::uint16_t"
    elseif log2(num_nonzero) < 32
        colptr_cpp_type = "std::uint32_t"
    elseif log2(num_nonzero) < 64
        colptr_cpp_type = "std::uint64_t"
    else
        throw(ArgumentError("Input matrix not sparse? Has $num_nonzero entries..."))
    end

    if log2(size(H, 1)) < 16
        row_idx_type = "std::uint16_t"
    else 
        row_idx_type = "std::uint32_t"
    end

    print(io, cpp_file_description)

    println(io, """
    #include <cstdint>
    #include <array>

    namespace $namespace_name {

    constexpr inline std::size_t M = $(size(H, 1));
    constexpr inline std::size_t N = $(size(H, 2));
    constexpr inline std::size_t num_nz = $num_nonzero;
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
    println(io, "constexpr inline std::array<$row_idx_type, num_nz> row_idx = {")

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
