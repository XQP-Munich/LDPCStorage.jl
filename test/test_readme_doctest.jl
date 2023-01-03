const ALL_CODEBLOCKS_IN_README = [
raw"""
```julia
using SparseArrays
using LDPCStorage

H = sparse(Int8[
        0 0 1 1 0 0 0 0 1 0 0 1 1 0
        1 0 0 1 1 0 0 0 0 0 1 0 0 1
        0 1 0 1 0 1 1 0 1 0 0 1 1 0
        1 0 0 1 0 0 0 1 0 1 0 1 0 1
    ])

save_to_alist("./ldpc.alist", H)
H_alist = load_alist("./ldpc.alist")
H == H_alist || warn("Failure")

save_to_bincscjson("./ldpc.bincsc.json", H)
H_csc = load_ldpc_from_json("./ldpc.bincsc.json")
H == H_csc || warn("Failure")

open("./autogen_ldpc.hpp", "w+") do io
    print_cpp_header(io, H)
end
```
""",
]


@testset "README only contains code blocks mentioned here" begin
    # if this test fails, enter all codeblocks 

    readme_path = "$(pkgdir(LDPCStorage))/README.md"
    readme_contents = read(readme_path, String)

    for (i, code_block) in enumerate(ALL_CODEBLOCKS_IN_README)
        # check that above code is contained verbatim in README
        @test contains(readme_contents, code_block)
    end

    # check that README does not contain any other Julia code blocks
    @test length(collect(eachmatch(r"```julia", readme_contents))) == length(ALL_CODEBLOCKS_IN_README)
end


@testset "codeblocks copied in README run without errors" begin
    for (i, code_block) in enumerate(ALL_CODEBLOCKS_IN_README)
        @testset "Codeblock $i" begin
            # remove the ```julia ... ``` ticks and parse code
            parsed_code = Meta.parseall(code_block[9:end-4])
    
            # check if it runs without exceptions
            eval(parsed_code)
        end
    end
end
