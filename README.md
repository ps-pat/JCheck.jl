# JCheck
*Randomized Property Based Testing for Julia*

## Example

``` julia
using Test: @testset, @test
using JCheck

qc = Quickcheck("A Test", n = 5)
@add_variables qc x::Float64 n::Int
@add_predicate qc "Identity" (x -> x == x)
@add_predicate qc "Is odd" isodd
@add_predicate qc "Sum commute" ((n, x) -> n * x == x * n)

@testset "Sample Test Set" begin
    @test isempty([])

    @quickcheck(qc)
end
```

## TODO
- [ ] Better documentation
- [ ] Support for special cases
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
