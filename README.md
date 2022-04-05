[![Tests](https://github.com/ps-pat/JCheck.jl/actions/workflows/test.yml/badge.svg)](https://github.com/ps-pat/JCheck.jl/actions/workflows/test.yml)
[![Codecov](https://codecov.io/gh/ps-pat/JCheck.jl/branch/main/graph/badge.svg?token=UF41E6AO1S)](https://codecov.io/gh/ps-pat/JCheck.jl)
[![Documentation](https://img.shields.io/badge/Doc-Stable-success)](https://patrickfournier.ca/JCheck.jl/dev/)

# JCheck
*Randomized Property Based Testing for Julia*

**<p align="center">:construction: Usable, but still a work in progress :construction:</p>**
Please have a look at the [documentation](https://patrickfournier.ca/JCheck.jl/dev/).

## TODO
- [ ] Better documentation
- [X] Support for special cases
- [X] More informative message for failing tests
- [X] Serialization of problematic cases
- [X] Shrinkage of failing test cases
- [ ] More generators
- [ ] Parallel testing
- [ ] ...

## Acknowledgements
- [Randomized Property Test](https://git.sr.ht/~quf/RandomizedPropertyTest.jl): inspiration for this package.
- [QuickCheck](https://github.com/nick8325/quickcheck): OG random
  property based testing.
- [JLSO](https://github.com/invenia/JLSO.jl): used for containing
  serialized test objects.
