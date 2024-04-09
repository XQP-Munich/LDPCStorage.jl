
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

@testset "write c++ header for quasi-cyclic exponents of matrix" begin
    
    output_path = tempname()

    Hqc = load_ldpc_from_json(qccscjson_exampl_file_path)
    expansion_factor = LDPCStorage.get_qc_expansion_factor(qccscjson_exampl_file_path)

    open(output_path, "w+") do io
        print_cpp_header_QC(io, Hqc; expansion_factor)
    end

    # TODO check correctness of written C++ header!
end
