
function main(args)

end

@testset "write c++ header" begin
    output_path = tempname()

    H = sparse(Int8[
        0 0 1 1 0 0 0 0 1 0 0 1 1 0
        1 9 0 1 1 0 0 0 0 0 1 0 0 1  # 9 will be stored zero
        0 1 0 1 0 1 1 0 1 0 0 1 1 0
        1 0 0 1 0 0 0 1 0 1 0 1 0 1
    ])

    H[2,2] = 0 # 9 becomes a stored zero

    open(output_path, "w+") do io
        print_cpp_header(io, H)
    end

    # TODO check correctness of written C++ header!
end
