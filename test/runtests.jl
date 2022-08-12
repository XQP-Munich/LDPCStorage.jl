using Test
using LDPCStorage

@testset "LDPCStorage" begin

    all_tests = Dict{String, Array{String, 1}}(
        "File Formats" => ["test_alist.jl",
                           "test_cscmat.jl",
                           "test_cscjson.jl",
                           ],
        )

    for (testsetname, test_files) in all_tests
        @testset "$testsetname"  begin
            @info "Running tests for `$testsetname`\n$(repeat("=", 60))\n"
            for source in test_files
                @testset "$source" begin
                    @info "Running tests in `$source`..."
                    include(source)
                end
            end
        end
    end

end  # @testset "LDPCStorage"
