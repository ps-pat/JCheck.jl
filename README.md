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
┌ Warning: Predicate "Is odd" does not hold for valuation (x = 0.02649402104579135,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:145
┌ Warning: Predicate "Is odd" does not hold for valuation (x = 0.1386790386668667,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:145
┌ Warning: Predicate "Is odd" does not hold for valuation (x = 0.3388381873521852,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:145
┌ Warning: Predicate "Is odd" does not hold for valuation (x = 0.025718876907983246,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:145
┌ Warning: Predicate "Is odd" does not hold for valuation (x = 0.538074498993818,)
└ @ Main ~/Projets/JCheck/src/TestSet.jl:145
Test Summary:      | Pass  Fail  Total
Sample Test Set    |    3     1      4
  Test Identity    |    1            1
  Test Is odd      |          1      1
  Test Sum commute |    1            1
ERROR: Some tests did not pass: 3 passed, 1 failed, 0 errored, 0 broken.
```

## TODO
- [ ] Better documentation
- [X] Support for special cases
- [X] More informative message for failing tests
- [ ] Serialization of problematic cases
- [ ] Shrinkage of failing test cases
- [ ] More generators
- [ ] Parallel testing
- [ ] ...

## Acknowledgements
- [Randomized Property Test](https://git.sr.ht/~quf/RandomizedPropertyTest.jl): inspiration for this package.
- [Quickcheck](https://github.com/nick8325/quickcheck): OG random
  property based testing.
