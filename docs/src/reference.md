# Reference

``` @meta
CurrentModule = JCheck
```

## Quickcheck

``` @docs
Quickcheck
Quickcheck(::AbstractString)
@add_predicate(::Any, ::Any, ::Any)
@quickcheck(::Any, ::AbstractString)
```

## Failed Cases Analysis

``` @docs
FailedTests
load(::Union{IO, AbstractString, AbstractPath})
@getcases(::Any, ::Any...)
```

## Random Input Generation

``` @docs
generate(::Type, ::Int)
specialcases(::Type)
```
