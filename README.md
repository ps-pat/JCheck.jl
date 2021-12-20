# JCheck
*Randomized Property Based Testing for Julia*

## Example

``` julia
using Test: @testset, @test
using JCheck
using Random: Xoshiro

rng = Xoshiro(42)

qc = Quickcheck("A Test", n = 5, rng = rng)
@add_variables qc x::Float64 n::Int
@add_predicate qc "Identity" (x -> x == x)
@add_predicate qc "Is odd" isodd
@add_predicate qc "Sum commute" ((n, x) -> n * x == x * n)

@testset "Sample Test Set" begin
    @test isempty([])

    @quickcheck(qc)
end
```

``` julia
┌ Warning: Predicate "Is odd" does not hold for valuation (n = 0,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:155
┌ Warning: Predicate "Is odd" does not hold for valuation (n = -9223372036854775808,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:155
┌ Warning: Predicate "Is odd" does not hold for valuation (n = -1194673449930948368,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:155
┌ Warning: Predicate "Is odd" does not hold for valuation (n = -6574272390120163918,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:155
┌ Warning: Predicate "Sum commute" does not hold for valuation (n = 0, x = -Inf)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:155
┌ Warning: Predicate "Sum commute" does not hold for valuation (n = 0, x = Inf)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:155

Some predicates do not hold for some valuations; they have been saved to JCheck_<date>.jchk.
Use function load and macro @getcases to explore the problematic cases.

Test Summary:      | Pass  Fail  Total
Sample Test Set    |    2     2      4
  Test Identity    |    1            1
  Test Is odd      |          1      1
  Test Sum commute |          1      1
ERROR: Some tests did not pass: 2 passed, 2 failed, 0 errored, 0 broken.
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
- [Quickcheck](https://github.com/nick8325/quickcheck): OG random
  property based testing.
