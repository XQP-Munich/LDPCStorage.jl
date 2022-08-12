# LDPCStorage.jl

[![CI](https://github.com/XQP-Munich/LDPCStorage.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/XQP-Munich/LDPCStorage.jl/actions)
[![codecov](https://codecov.io/gh/XQP-Munich/LDPCStorage.jl/branch/main/graph/badge.svg?token=TGISS7YIJT)](https://codecov.io/gh/XQP-Munich/LDPCStorage.jl)
[![License](https://img.shields.io/github/license/XQP-Munich/LDPCStorage.jl)](./LICENSE)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5589595.svg)](https://doi.org/10.5281/zenodo.5589595)

*Utility functions for reading and writing files containing low density parity check (LDPC) matrices.*

## Installation

The package is currently not registered. Install it using the Julia package manager (Pkg) by the REPL command

        ] add <GITHUB URL>

## Supported File Formats
- `alist` (by David MacKay et al., see http://www.inference.org.uk/mackay/codes/alist.html)
- `cscmat` (our custom format) DEPRECATED
- `bincsc.json` (Based on compressed sparse columns (CSC). Valid `json`. Replacement for `cscmat`.)
- `qccsc.json` (Based on compressed sparse columns (CSC). Valid `json`. Store exponents of quasi-cyclic LDPC matrices)

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

save_to_alist(H, "ldpc.alist")
H_alist = load_alist("ldpc.alist")
H == H_alist || warn("Failure")

save_to_bincscjson(H, "ldpc.bincsc.json")
H_csc = load_ldpc_from_json("ldpc.bincsc.json")
H == H_csc || warn("Failure")
```

## Contributing
Contributions, feature requests and suggestions are welcome. Open an issue or contact us directly.
