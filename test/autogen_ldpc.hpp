// This file was automatically generated using LDPCStorage.jl (https://github.com/XQP-Munich/LDPCStorage.jl).
// A sparse LDPC matrix (containing only zeros and ones) is saved in compressed sparse column (CSC) format.
// Since the matrix (and LDPC code) is known at compile time, there is no need to save it separately in a file.
// This significantly blows up the executable size (the memory would still have to be used when saving the matrix).

#include <cstdint>
#include <array>

namespace AutogenLDPC {

constexpr inline std::size_t M = 4;
constexpr inline std::size_t N = 14;
constexpr inline std::size_t num_nz = 23;
constexpr inline std::array<std::uint16_t, N + 1> colptr = {
0x0,0x2,0x3,0x4,0x8,0x9,0xa,0xb,0xc,0xe,0xf,0x10,0x13,0x15,0x17
};

// ------------------------------------------------------- 

constexpr inline std::array<std::uint16_t, num_nz> row_idx = {
0x1,0x3,0x2,0x0,0x0,0x1,0x2,0x3,0x1,0x2,0x2,0x3,0x0,0x2,0x3,0x1,0x0,0x2,0x3,0x0,0x2,0x1,0x3
};


} // namespace AutogenLDPC
