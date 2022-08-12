using Test, SparseArrays
using LDPCStorage
using LDPCStorage: hash_sparse_matrix, save_to_cscmat, load_cscmat, load_matrix_from_qc_cscmat_file, CSCMAT_FORMAT_VERSION

qc_file_path = "$(pkgdir(LDPCStorage))/test/files/test_Hqc.cscmat"
h_file_path = "$(pkgdir(LDPCStorage))/test/files/test_H.cscmat"


@testset "hash_sparse_matrix" begin
    hash = hash_sparse_matrix(sparse([1 2 3 0; 5 0 7 8]))
    @test hash == UInt8[0x98, 0x82, 0x9c, 0x17, 0xc6, 0xd2, 0xb4, 0xd4, 0x55, 0x4c, 0x4e, 0x80, 0xd6, 0xea, 0x26,
        0xf8, 0x44, 0xb5, 0x72, 0x65, 0xae, 0x93, 0xb8, 0xea, 0x2a, 0x21, 0x92, 0x00, 0x2a, 0x82, 0xcd, 0x93]
end


@testset "load_cscmat" begin
    Hqc = load_cscmat(qc_file_path; print_file_header=false)
    @test hash_sparse_matrix(Hqc) == UInt8[0x8d, 0xd2, 0x45, 0x0b, 0x9a, 0x5b, 0x8b, 0x4a, 0x6d, 0xab, 0x14, 0x7d,
        0x79, 0x72, 0xdd, 0x15, 0x1a, 0x41, 0x4c, 0xa1, 0xc8, 0xd0, 0x23, 0x84, 0x49, 0x17, 0x6a, 0xc8, 0x2b, 0x05, 0x8f, 0xba]

    H = load_cscmat(h_file_path; print_file_header=false)
    @test hash_sparse_matrix(H) == UInt8[0x46, 0x63, 0xd9, 0x12, 0x4b, 0xd6, 0xb1, 0xdf, 0xaf, 0xe7, 0x4f, 0x5d,
        0x7f, 0x7d, 0x47, 0x5a, 0x4c, 0xd9, 0x6a, 0xf8, 0xae, 0xbb, 0xbd, 0x22, 0xe6, 0xa9, 0x5d, 0x9d, 0xd4, 0x52, 0x33, 0xcb]
end


@testset "save_to_cscmat and load_cscmat" begin    
    Hqc = load_cscmat(qc_file_path; print_file_header=false)
    lifting_factor = 32

    H = load_cscmat(h_file_path; print_file_header=false)

    for allow_omit_entries_if_only_stored_ones in [false, true]
        for try_hex in [false, true]
            for additional_header_lines in ["", "QC matrix with expansion factor 32", "QC matrix\nwith expansion factor\n\n# 32"]

                target_file = tempname() * ".cscmat"

                @show allow_omit_entries_if_only_stored_ones
                @show try_hex

                save_to_cscmat(
                    H, target_file;
                    allow_omit_entries_if_only_stored_ones, try_hex, additional_header_lines)
                H_read = load_cscmat(target_file; print_file_header=false)
                @test H_read == H

                save_to_cscmat(
                    Hqc, target_file;
                    allow_omit_entries_if_only_stored_ones, try_hex, additional_header_lines)
                H_read = load_cscmat(target_file; print_file_header=true)
                @test H_read == Hqc
                println("\n")
            end
        end
    end

end


@testset "load_matrix_from_qc_cscmat_file" begin
    H_32 = load_matrix_from_qc_cscmat_file(qc_file_path; expansion_factor=32)
    H_auto = load_matrix_from_qc_cscmat_file(qc_file_path)
    H_true = load_cscmat(h_file_path; print_file_header=false)

    @test H_true == H_32
    @test H_true == H_auto
end
