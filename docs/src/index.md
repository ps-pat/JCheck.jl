```@meta
CurrentModule = JCheck
ShareDefaultModule = true
```

# JCheck.jl Documentation

## What is JCheck.jl?
JCheck is a test framework for the [Julia programming language](https://julialang.org/). It aims to replicate some of the functionalities of [Quickcheck](https://github.com/nick8325/quickcheck). The user specifies a set of properties as predicates, and JCheck then attempts to find cases that violate these predicates. Since it is generally impossible to evaluate a predicate for every possible input, JCheck, like QuickCheck, uses a Monte Carlo approach: it generates a set of random inputs and passes them as arguments to the predicates. Serialization to a [JLSO](https://github.com/invenia/JLSO.jl) file is enabled by default to facilitate analysis of problematic cases.

## Features
- Reuse inputs to reduce the time spent on case generation.
- Serialization of problematic cases for easier analysis.
- Integration with Julia's testing framework.
- Allow specification of "special cases," that is, non-random inputs that are always checked.
- Shrinkage of failing test cases.

## Usage
### Container
Predicates must be contained in a [`Quickcheck`](@ref) object to be used in a test. They are easy to create. The most basic way is to call the constructor with a brief and simple description:

```@repl
using Test: @testset, @test

using JCheck

qc = Quickcheck("A Test")
```

For more advanced uses, see the documentation of the [`Quickcheck`](@ref Quickcheck(::AbstractString)) constructor.

### Adding predicates
Once a [`Quickcheck`](@ref) object has been created, the next step is to populate it with predicates. This can be done using the [`@add_predicate`](@ref) macro.

```@repl
@add_predicate qc "Sum commute" ((x::Float64, n::Int) -> x + n == n + x)
```

A predicate is a function that returns either `true` or `false`. In the context of `JCheck`, the form of the predicate is strict; please read the documentation of [`@add_predicate`](@ref).

### (Quick)checking
The macro [`@quickcheck`](@ref) initiates the process of searching for falsifying instances within a [`Quickcheck`](@ref) object.

```@repl
@quickcheck qc
```

#### As part of a [`@testset`](https://docs.julialang.org/en/v1/stdlib/Test/#Test.@testset)
The [`@quickcheck`](@ref) macro can be nested within a [`@testset`](https://docs.julialang.org/en/v1/stdlib/Test/#Test.@testset). This facilitates integration into a package's test suite.

```@jldoctest; setup = :(using Test: @testset, @test; using JCheck: @quickcheck)
@testset "Sample test set" begin
    @test isempty([])

    @quickcheck qc
end

Test Summary:   | Pass  Total
Sample test set |    2      2
```

Let's add a failing predicate.

```@jldoctest
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
By default, failing test cases are serialized to a [JLSO](https://github.com/invenia/JLSO.jl) file for subsequent analysis.

```@repl
ft = JCheck.load("JCheck_test.jchk")
```

Failing cases for a predicate can be extracted using its description with [`@getcases`](@ref). There's no need to provide the exact description of the predicate you want to extract; the entry whose description is closest (in terms of Levenshtein distance) will be matched.

```@repl
pred, valuations = @getcases ft i od

map(x -> pred(x...), valuations) # each element of `valuations` is a tuple.
```

### Types with built-in generators
For a list of types for which a generator is included in the package, see the reference for [`generate`](@ref).

### Testing With Custom Types
JCheck can be easily extended to work with custom types from which it is possible to randomly generate instances. The only requirement is to overload [`generate`](@ref). For example, an implementation for the type `Int64` could look like this:

```@repl
using Random: AbstractRNG

generate(rng::AbstractRNG, ::Type{Int64}, n::Int) = rand(rng, Int64, n)
```

Optionally, it is possible to specify so-called "special cases" for a type. These are always checked. Implementing them is as easy as overloading [`specialcases`](@ref). For `Int`, this could look like this:

```@repl
specialcases(::Type{Int64}) = Int64[0, 1, typemin(Int64), typemax(Int64)]
```

For implementation details, refer to the documentation of these two functions.

#### Shrinkage
`@quickcheck`](@ref) will attempt to shrink any failing test case if possible. In order to enable shrinkage for a given type, the following two methods must be implemented:
- [`shrinkable`](@ref)
- [`shrink`](@ref)

The first one is a predicate that evaluates to `true` for an object if it can be shrunk. The second is a function that returns a `Vector` of shrunk objects. The implementation for type `AbstractString` is as follows:

```@example
shrinkable(x::AbstractString) = length(x) >= 2

function shrink(x::AbstractString)
    shrinkable(x) || return typeof(x)[x]

    n = length(x) ÷ 2
    [x[1:n], x[range(n + 1, end)]]
end
```

For more details and a list of default shrinkers, see the documentation for these methods.
