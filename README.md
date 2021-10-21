# LDPCStorage.jl

[![CI](https://github.com/XQP-Munich/LDPCStorage.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/XQP-Munich/LDPCStorage.jl/actions)
[![codecov](https://codecov.io/gh/XQP-Munich/LDPCStorage.jl/branch/main/graph/badge.svg?token=TGISS7YIJT)](https://codecov.io/gh/XQP-Munich/LDPCStorage.jl)
[![License](https://img.shields.io/github/license/XQP-Munich/LDPCStorage.jl)](./LICENSE)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5589595.svg)](https://doi.org/10.5281/zenodo.5589595)

*Utility functions for reading and writing files containing LDPC matrices.*

## Installation

The package is currently not registered. Install it using the Julia package manager (Pkg) by the REPL command

        ] add <GITHUB URL>

## Supported File Formats
- alist (by David MacKay et al., see http://www.inference.org.uk/mackay/codes/alist.html)
- cscmat (our custom format)

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

save_to_cscmat(H, "ldpc.cscmat")
H_cscmat = load_cscmat("ldpc.cscmat")
H == H_cscmat || warn("Failure")
```

## Contributing
Contributions, feature requests and suggestions are welcome. Open an issue or contact us directly.
