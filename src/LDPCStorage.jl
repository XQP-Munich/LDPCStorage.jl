module LDPCStorage

include("utils.jl")

include("alist.jl")
export load_alist, save_to_alist

include("cscmat.jl")  # this format is deprecated in favour of csc.json
# export save_to_cscmat, load_cscmat, load_matrix_from_qc_cscmat_file, CSCMAT_FORMAT_VERSION

include("cscjson.jl")
export load_ldpc_from_json, save_to_bincscjson, save_to_qccscjson, CSCJSON_FORMAT_VERSION

end # module
