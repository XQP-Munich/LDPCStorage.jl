"""
$(DocStringExtensions.README)
"""
module LDPCStorage

using DocStringExtensions

include("utils.jl")

include("alist.jl")
export save_to_alist, print_alist, load_alist

include("cscmat.jl")  # this format is deprecated in favour of csc.json
# export save_to_cscmat, load_cscmat, load_matrix_from_qc_cscmat_file, CSCMAT_FORMAT_VERSION

include("cscjson.jl")
export print_bincscjson, save_to_bincscjson
export print_qccscjson, save_to_qccscjson
export load_ldpc_from_json, CSCJSON_FORMAT_VERSION

# This format stores the LDPC code as static data in a c++ header file.
include("cpp_header_based.jl")
export print_cpp_header

end # module
