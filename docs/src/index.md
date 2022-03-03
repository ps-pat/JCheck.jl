```@meta
CurrentModule = JCheck
```

# JCheck.jl Documentation

## What is JCheck.jl?
JCheck is a test framework for the [Julia programming
language](https://julialang.org/). It aims imitating the one and only
[Quickcheck](https://github.com/nick8325/quickcheck). The user
specifies a set of properties in the form of predicates. JCheck then
tries to falsifies these predicates. Since it is in general impossible
to evaluate a predicate for every possible input, JCheck (as does
QuickCheck) employs a Monte Carlo approach: it samples a set of inputs
at random and pass them as arguments to the predicates. In order to
make analysis of problematic cases more convenient, those can be
serialized in a [JLSO](https://github.com/invenia/JLSO.jl) file for
further experimentation.

## Features
- Reuse inputs to cut into the time dedicated to cases generation.
- Serialization of problematic cases for convenient analysis.
- Integration with Julia's testing framework.
- Allow specification of "special cases" i.e. non-random inputs that
  are always checked.
- Shrinkage of failing test cases.

## Usage
### Container
In order for them to be used in a test, predicates must be contained
in a [`Quickcheck`](@ref) object. Those are fairly easy to create. The
most basic way is to call the constructor with a short and simple
description:

``` @setup example_index
using Test:
    @testset,
    @test

using JCheck
```

``` @example example_index
qc = Quickcheck("A Test")
```

For more advanced usages, see documentation of the [`Quickcheck`](@ref
Quickcheck(::AbstractString)) constructor.

### Adding predicates
Once a [`Quickcheck`](@ref) object has been created, the next step is
to populate it with predicates. This can be done with the
[`@add_predicate`](@ref) macro:

``` @example example_index
@add_predicate qc "Sum commute" ((x::Float64, n::Int) -> x + n == n + x)
```

A predicate is a function that returns either `true` or `false`. In
the context of `JCheck` the form of the predicate is very strict;
please read the documentation of [`@add_predicate`](@ref).

### (Quick)checking
The macro [`@quickcheck`](@ref) launches the process of looking for
falsifying instances in a [`Quickcheck`](@ref) object.

``` @jldoctest
@quickcheck qc

Test Summary:    | Pass  Total
Test Sum commute |    1      1
```

#### As part of a [`@testset`](https://docs.julialang.org/en/v1/stdlib/Test/#Test.@testset)
The [`@quickcheck`](@ref) macro can be nested inside
[`@testset`](https://docs.julialang.org/en/v1/stdlib/Test/#Test.@testset).
This allows easy integration to a package's set of tests.

``` @jldoctest
@testset "Sample test set" begin
    @test isempty([])

    @quickcheck qc
end

Test Summary:   | Pass  Total
Sample test set |    2      2
```

Let's add a failing predicate.

``` @jldoctest example_index
@add_predicate qc "I fail" (x::Float64 -> false)

@testset "Sample failing test set" begin
    @test isempty([])

    @quickcheck qc
end

┌ Warning: Predicate "I fail" does not hold for valuation (x = 0.0,)
└ @ JCheck ~/Projets/JCheck/src/Quickcheck.jl:267
┌ Warning: Predicate "I fail" does not hold for valuation (x = 1.0,)
└ @ JCheck ~/Projets/JCheck/src/Quickcheck.jl:267

[...]

Some predicates do not hold for some valuations; they have been saved
to JCheck_yyyy-mm-dd_HH-MM-SS.jchk. Use function load and macro @getcases
to explore problematic cases.

Test Summary:           | Pass  Fail  Total
Sample failing test set |    2     1      3
  Test Sum commute      |    1            1
  Test I fail           |          1      1
ERROR: Some tests did not pass: 2 passed, 1 failed, 0 errored, 0 broken.
```

### Analysing failing cases
By default, failing test cases are serialized to a
[JLSO](https://github.com/invenia/JLSO.jl) file so they can easily be
analyzed.

``` @example example_index
ft = JCheck.load("JCheck_test.jchk")
```

Failing cases for a predicate can be extracted by using its
description with [`@getcases`](@ref). There is no need to give the
exact description of the predicate you want to extract; the entry with
description closest to the one given (in the sense of the Levenshtein
distance) will be matched.

``` @example example_index
pred, valuations = @getcases ft i od

## Each element of `valuations` is a tuple.
map(x -> pred(x...), valuations)
```

### Types with built-in generators
For a list of types for which a generator is included in the package,
see reference for [`generate`](@ref).

### Testing With Custom Types
JCheck can easily be extended to work with custom type from which it
is possible to randomly sample instances. The only requirement is to
overload [`generate`](@ref). For instance, an implementation for type
`Int64` could look like this:

``` @example example_index
import JCheck: generate
using Random: AbstractRNG

generate(rng::AbstractRNG, ::Type{Int64}, n::Int) =
    rand(rng, Int64, n)
```

Optionally, it is possible to specify so called "special cases" for a
type. Those are always checked. Doing so is as easy as overloading
[`specialcases`](@ref). For `Int`, this could look like this:

``` @example
import JCheck: specialcases

specialcases(::Type{Int64}) =
    Int64[0, 1, typemin(Int64), typemax(Int64)]
```

For implementation details, see documentation of these two functions.

#### Shrinkage
[`@quickcheck`](@ref) will try to shrink any failing test case if
possible. In order to enable shrinkage for a given type, the following
two methods must be implemented:
- [`shrinkable`](@ref)
- [`shrink`](@ref)

The first one is a predicate evaluating to `true` for an object if it
can be shrinked. The second one is a function returning a `Vector` of
shrunk objects. The implementation for type `Abstractstring` is the
following:

``` @example
shrinkable(x::AbstractString) = length(x) >= 2

function shrink(x::AbstractString)
    shrinkable(x) || return typeof(x)[x]

    n = length(x) ÷ 2
    [x[1:n], x[range(n + 1, end)]]
end
```

For more details and a list of default shrinkers, see the
documentation of these methods.
