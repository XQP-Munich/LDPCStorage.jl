# LDPCStorage.jl

[![CI](https://github.com/XQP-Munich/LDPCStorage.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/XQP-Munich/LDPCStorage.jl/actions)
[![codecov](https://codecov.io/gh/XQP-Munich/LDPCStorage.jl/branch/main/graph/badge.svg?token=TGISS7YIJT)](https://codecov.io/gh/XQP-Munich/LDPCStorage.jl)
[![License](https://img.shields.io/github/license/XQP-Munich/LDPCStorage.jl)](./LICENSE)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5589595.svg)](https://doi.org/10.5281/zenodo.5589595)

*Reads and writes file formats for storing sparse matrices containing only zeros and ones.
Intended for use with low density parity check (LDPC) matrices.
Also supports efficient storage for quasi-cyclic LDPC codes.*

## Installation

The package is currently not registered. Install it using the Julia package manager (Pkg) by the REPL command

        ] add <GITHUB URL>

## Supported File Formats
- `alist` (by David MacKay et al., see http://www.inference.org.uk/mackay/codes/alist.html)
- `cscmat` (our custom format) DEPRECATED
- `bincsc.json` (Based on compressed sparse column (CSC). Valid `json`.)
- `qccsc.json` (Based on compressed sparse column (CSC). Valid `json`. Store exponents of quasi-cyclic LDPC matrices)
- `hpp (C++ header)` CSC of matrix as static data (write-only, reading not supported!)
## How to use

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

Also available are versions of the other methods accepting an `IO` object: 
`print_alist`, `print_bincscjson`, etc.

## Contributing
Contributions, feature requests and suggestions are welcome. Open an issue or contact us directly.
