using Test, Aqua
using LDPCStorage

@testset "Aqua (Code quality)" begin
    Aqua.test_all(LDPCStorage)
end

@testset "LDPCStorage" begin

    all_tests = Dict{String,Array{String,1}}(
        "File Formats" => [
            "test_alist.jl",
            "test_cscmat.jl",
            "test_cscjson.jl",
            "test_cpp_header.jl",
            "test_readme_doctest.jl",
        ],
    )

    for (testsetname, test_files) in all_tests
        @testset "$testsetname" begin
            @info "Running tests for `$testsetname`\n$(repeat("=", 60))\n"
            for source in test_files
                @testset "$source" begin
                    @info "Running tests in `$source`..."
                    include(source)
                end
            end
        end
    end

    # check if any files were missed in the explicit list above
    potential_testfiles =
        [file for file in readdir(@__DIR__) if match(r"^test_.*\.jl$", file) !== nothing]
    tested_files = all_tests |> values |> Iterators.flatten

    @test isempty(setdiff(potential_testfiles, tested_files))

end  # @testset "LDPCStorage"
