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
The macro [`@quickcheck`](@ref) launch the process of looking for
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

### Testing With Custom Types
