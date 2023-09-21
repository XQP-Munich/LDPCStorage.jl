using Test, SparseArrays
using LDPCStorage

@testset "save and load alist" begin
    # Save and load this arbitrary matrix:
    H = Int8[
        0 0 1 1 0 0 0 0 1 0 0 1 1 0
        1 0 0 1 1 0 0 0 0 0 1 0 0 1
        0 1 0 1 0 1 1 0 1 0 0 1 1 0
        1 0 0 1 0 0 0 1 0 1 0 1 0 1
    ]
    file_path = tempname() * "_unit_test.alist"
    save_to_alist(file_path, H)

    H_loaded = load_alist(file_path)

    H_checked_redundancy = load_alist(file_path; check_redundant=true)

    @test H_checked_redundancy == H_loaded
    @test H == H_loaded

    @test_throws "invalid base 10 digit '#'" load_alist("$(pkgdir(LDPCStorage))/test/files/test_Hqc.cscmat")  # completely invalid file
end
