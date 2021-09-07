using Test, SparseArrays, SHA
using LDPCStorage

qc_file_path = "$(pkgdir(LDPCStorage))/test/files/test_Hqc.cscmat"
h_file_path = "$(pkgdir(LDPCStorage))/test/files/test_H.cscmat"


"""
Returns a 256 bit hash of an sparse matrix.
This function should only be used for unit tests!
"""
function hash_sparse_matrix(H::SparseMatrixCSC)
    ctx = SHA2_256_CTX()

    update!(ctx, H.colptr .% UInt8)
    update!(ctx, H.rowval .% UInt8)
    update!(ctx, H.nzval .% UInt8)

    return digest!(ctx)
end


@testset "hash_sparse_matrix" begin
    hash = hash_sparse_matrix(sparse([1 2 3 0; 5 0 7 8]))
    @test hash == UInt8[0x82, 0x80, 0xcf, 0xe6, 0x13, 0x4b, 0x54, 0x50, 
        0x2a, 0xc4, 0x21, 0x33, 0x6e, 0xd5, 0xe4, 0x2d, 
        0x61, 0xa9, 0x30, 0x45, 0x77, 0xa7, 0x45, 0x09, 
        0x29, 0xca, 0x0b, 0x5a, 0x5b, 0x9f, 0x0b, 0x0f]
end


@testset "load_cscmat" begin
    Hqc = load_cscmat(qc_file_path; print_file_header=false)
    lifting_factor = 32
    @test hash_sparse_matrix(Hqc) == UInt8[0xf7, 0x41, 0xee, 0x9c, 0xf8, 0x2c, 0x0b, 0xb8, 0x02, 0x2f, 0x4f, 0xa6, 0x40, 0xa5, 0xb0, 
        0xcd, 0xf0, 0x7c, 0x11, 0xfc, 0x6d, 0x99, 0xb0, 0x13, 0x9e, 0x18, 0x19, 0xb2, 0xc7, 0x7d, 0x25, 0x92]

    H = load_cscmat(h_file_path; print_file_header=false)
    @test hash_sparse_matrix(H) == UInt8[0xf0, 0xe7, 0x55, 0xa8, 0x38, 0x9c, 0xf6, 0x1f, 0x41, 0x5e, 0x6d, 0xd4, 0xaa, 0x38, 0xee, 
        0xb6, 0x77, 0x05, 0xad, 0x73, 0x32, 0xc6, 0xf0, 0x0e, 0x75, 0x2a, 0x1d, 0xe3, 0xc9, 0x88, 0x67, 0xc5]
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


@testset "Hqc_to_pcm" begin    
    Hqc = load_cscmat(qc_file_path; print_file_header=false)
    lifting_factor = 32
   

    H = load_cscmat(h_file_path; print_file_header=false)

    @test LDPCStorage.Hqc_to_pcm(Hqc, lifting_factor) == H
end


@testset "load_matrix_from_qc_cscmat_file" begin
    H_32 = load_matrix_from_qc_cscmat_file(qc_file_path; expansion_factor=32)
    H_auto = load_matrix_from_qc_cscmat_file(qc_file_path)
    H_true = load_cscmat(h_file_path; print_file_header=false)

    @test H_true == H_32
    @test H_true == H_auto
end
