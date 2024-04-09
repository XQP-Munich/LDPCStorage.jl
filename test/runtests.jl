using Test, Aqua
using LDPCStorage

@testset "Aqua (Code quality)" begin
    Aqua.test_ambiguities([LDPCStorage, Core])  # exclude `Base` in order to not hit unrelated ambiguities from StatsBase.
    Aqua.test_unbound_args(LDPCStorage)
    Aqua.test_undefined_exports(LDPCStorage)
    Aqua.test_project_extras(LDPCStorage)
    Aqua.test_stale_deps(LDPCStorage)
     # Don't care about compat entries for test-only dependencies.
     # Also ignore LinearAlgebra because in current Julia it doesn't "have a version"?!
    Aqua.test_deps_compat(LDPCStorage; check_extras = false, ignore=[:LinearAlgebra]) 
    Aqua.test_piracies(LDPCStorage)
    Aqua.test_persistent_tasks(LDPCStorage)
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
