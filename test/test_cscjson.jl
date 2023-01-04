using Test, SparseArrays
using LDPCStorage
using LDPCStorage: hash_sparse_matrix

qccscjson_exampl_file_path = "$(pkgdir(LDPCStorage))/test/files/test_Hqc.qccsc.json"
bincscjson_exampl_file_path = "$(pkgdir(LDPCStorage))/test/files/test_H.bincsc.json"

@testset "load_ldpc_from_json" begin
    Hqc = load_ldpc_from_json(qccscjson_exampl_file_path)
    @test hash_sparse_matrix(Hqc) == UInt8[0x8d, 0xd2, 0x45, 0x0b, 0x9a, 0x5b, 0x8b, 0x4a, 0x6d, 0xab, 0x14, 0x7d,
        0x79, 0x72, 0xdd, 0x15, 0x1a, 0x41, 0x4c, 0xa1, 0xc8, 0xd0, 0x23, 0x84, 0x49, 0x17, 0x6a, 0xc8, 0x2b, 0x05, 0x8f, 0xba]

    H = load_ldpc_from_json(bincscjson_exampl_file_path)
    @test hash_sparse_matrix(H) == UInt8[0x46, 0x63, 0xd9, 0x12, 0x4b, 0xd6, 0xb1, 0xdf, 0xaf, 0xe7, 0x4f, 0x5d,
        0x7f, 0x7d, 0x47, 0x5a, 0x4c, 0xd9, 0x6a, 0xf8, 0xae, 0xbb, 0xbd, 0x22, 0xe6, 0xa9, 0x5d, 0x9d, 0xd4, 0x52, 0x33, 0xcb]
end


@testset "save_to_bincscjson and load_ldpc_from_json" begin    
    H = load_ldpc_from_json(bincscjson_exampl_file_path)

    target_file = tempname() * ".bincsc.json"

    # TODO think about whether to allow (and just drop) stored zeros
    save_to_bincscjson(target_file, H; comments="Some comment")
    H_read = load_ldpc_from_json(target_file)
    @test H_read == H
end


@testset "save_to_qccscjson and load_ldpc_from_json" begin    
    Hqc = load_ldpc_from_json(qccscjson_exampl_file_path)

    target_file = tempname() * ".qccsc.json"
    save_to_qccscjson(target_file, Hqc;  comments="Some comment", qc_expansion_factor=32)
    H_read = load_ldpc_from_json(target_file)
    @test H_read == Hqc

    @test LDPCStorage.Hqc_to_pcm(Hqc, 32) == load_ldpc_from_json(
        target_file; expand_qc_exponents_to_binary=true)
end


@testset "Hqc_to_pcm" begin
    Hqc = sparse([
        4 0 1 
        1 2 -99  # the -99 will be a zero.
    ])
    Hqc[2,3] = 0 # replace -99 by stored zero in sparse matrix

    expansion_factor = 4
    # each entry of Hqc describes an `expansion_factor x expansion_factor`` sized subblock of H

    H_expected = sparse([
        1  0  0  0    0  0  0  0    0  1  0  0
        0  1  0  0    0  0  0  0    0  0  1  0
        0  0  1  0    0  0  0  0    0  0  0  1
        0  0  0  1    0  0  0  0    1  0  0  0

        0  1  0  0    0  0  1  0    0  0  0  0
        0  0  1  0    0  0  0  1    0  0  0  0
        0  0  0  1    1  0  0  0    0  0  0  0
        1  0  0  0    0  1  0  0    0  0  0  0
    ])

    @test LDPCStorage.Hqc_to_pcm(Hqc, expansion_factor) == H_expected
end


@testset "stored zeros" begin
    H = sparse(Int8[
        0 0 1 1 0 0 0 0 1 0 0 1 1 0
        1 9 0 1 1 0 0 0 0 0 1 0 0 1  # 9 will be stored zero
        0 1 0 1 0 1 1 0 1 0 0 1 1 0
        1 0 0 1 0 0 0 1 0 1 0 1 0 1
    ])

    H[2,2] = 0 # 9 becomes a stored zero

    target_file = tempname() * ".bincsc.json"

    @test_throws ErrorException save_to_bincscjson(target_file, H; comments="Some comment")
end
