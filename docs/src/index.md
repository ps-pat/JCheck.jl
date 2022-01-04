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
### Predicate container

### Adding predicates

### (Quick)checking

### Analysing failing cases
