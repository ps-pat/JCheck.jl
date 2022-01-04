[![Tests](https://github.com/ps-pat/JCheck.jl/actions/workflows/test.yml/badge.svg)](https://github.com/ps-pat/JCheck.jl/actions/workflows/test.yml)
[![Codecov](https://codecov.io/gh/ps-pat/JCheck.jl/branch/main/graph/badge.svg?token=UF41E6AO1S)](https://codecov.io/gh/ps-pat/JCheck.jl)

# JCheck
*Randomized Property Based Testing for Julia*

## Example

## Testing properties.
``` julia
using Test: @testset, @test
using JCheck
using Random: Xoshiro

rng = Xoshiro(42)

qc = Quickcheck("A Test", n = 5, rng = rng)
@add_predicate qc "Identity" (x::Float64 -> x == x)
@add_predicate qc "Is odd" (n::Int -> isodd(n))
@add_predicate qc "Sum commute" ((n::Int, x::Float64) -> n + x == x + n)

@testset "Sample Test Set" begin
    @test isempty([])

    @quickcheck(qc)
end
```

``` julia
┌ Warning: Predicate "Is odd" does not hold for valuation (n = 0,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:168
┌ Warning: Predicate "Is odd" does not hold for valuation (n = -9223372036854775808,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:168
┌ Warning: Predicate "Is odd" does not hold for valuation (n = -5361574982048072896,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:168
┌ Warning: Predicate "Is odd" does not hold for valuation (n = 4014594483864527338,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:168

Some predicates do not hold for some valuations; they have been saved to JCheck_<date>.jchk.
Use function `load` and macro `@getcases` to explore the problematic cases.

Test Summary:      | Pass  Fail  Total
Sample Test Set    |    3     1      4
  Test Identity    |    1            1
  Test Is odd      |          1      1
  Test Sum commute |    1            1
ERROR: Some tests did not pass: 3 passed, 1 failed, 0 errored, 0 broken.
```

### Analyzing problematic cases.
``` julia
julia> ft = JCheck.load("JCheck_test.jchk")
JCheck.FailedTests with 2 entries:
  Symbol("Sum commute") => NamedTuple{(:predicate, :valuations), Tuple{Function…
  Symbol("Is odd")      => NamedTuple{(:predicate, :valuations), Tuple{Function…

julia> pred, valuations = @getcases ft Sum
NamedTuple{(:predicate, :valuations), Tuple{Function, Vector{Tuple}}}
    ((Serialization.__deserialized_types__.var"##274"(), Tuple[(0, -Inf),
    (0, Inf)]))

julia> valuations
2-element Vector{Tuple}:
 (0, -Inf)
 (0, Inf)

julia> pred(first(valuations)...)
false
```


## TODO
- [ ] Better documentation
- [X] Support for special cases
- [X] More informative message for failing tests
- [X] Serialization of problematic cases
- [ ] Shrinkage of failing test cases
- [ ] More generators
- [ ] Parallel testing
- [ ] ...

## Acknowledgements
- [Randomized Property Test](https://git.sr.ht/~quf/RandomizedPropertyTest.jl): inspiration for this package.
- [QuickCheck](https://github.com/nick8325/quickcheck): OG random
  property based testing.
- [JLSO](https://github.com/invenia/JLSO.jl): Used for containing
  serialized test objects.
