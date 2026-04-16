import JLSO

import Base:
    iterate,
    length,
    eltype,
    getindex,
    show

using FilePathsBase: AbstractPath

using StringDistances:
    findnearest,
    Levenshtein

"""
    FailedTests

Container for failed tests from a [`@quickcheck`](@ref) run. Wrapper around
a `Dict{Symbol, Any}`.
"""
struct FailedTests <: AbstractDict{Symbol, Any}
    dict::Dict{Symbol, Any}
end

export load
"""
    load(io)

Load a collection of failed test cases serialized by a
[`@quickcheck`](@ref) run.
 Argument `io` can be of type `IO`, `AbstractString` or `AbstractPath`.

# Examples
```jldoctest; setup = :(import JCheck)
julia> ft = JCheck.load("JCheck_test.jchk")
2 failing predicates:
Is odd
- commutes
```
"""
load(io::Union{IO, AbstractString, AbstractPath}) =
    FailedTests(JLSO.load(io))

## Iteration interface.

iterate(ft::FailedTests, state::Int = 1) = iterate(ft.dict, state)

eltype(::Type{FailedTests}) = Pair{Symbol, Any}

length(ft::FailedTests) = length(ft.dict)

## Indexing interface.
getindex(ft::FailedTests, key::Symbol) = getindex(ft.dict, key)

getindex(ft::FailedTests, key::AbstractString) =
    getindex(ft.dict, Symbol(key))

export @getcases
"""
    @getcases ft, desc...

Get the predicate with description `desc` and the valuations for which it
failed.

# Note
The predicate with description closest to the one given (in the sense of
the Levenshtein distance) will be returned; there is no need to pass the
exact description.

# Examples
```jldoctest; setup = :(using JCheck)
julia> ft = JCheck.load("JCheck_test.jchk")
2 failing predicates:
Is odd
- commutes

julia> pred, valuations = @getcases ft iod
@NamedTuple{predicate::Function, valuations::Vector{Tuple}}((Serialization.__deserialized_types__.var"#11#12"(), Tuple[(0,), (-9223372036854775808,), (-1603514452799603314,), (1420394807175553538,), (4507329505808279390,), (-426481527288535688,), (-5691388592443778052,), (-7859122130299025792,), (-5525456812138927418,), (-7209867710197627164,)  …  (2031324158527932024,), (7907216074681153692,), (4734352501972781814,), (7649976476383282706,), (-6664068458754296008,), (-5721291110713069694,), (8573438617342549320,), (-5611383820228536680,), (-4303975626508744234,), (-5727584619371173840,)]))

julia> map(x -> pred(x...), valuations)
53-element Vector{Bool}:
 0
 0
 0
 0
 0
 0
 0
 0
 0
 0
 ⋮
 0
 0
 0
 0
 0
 0
 0
 0
 0
```
"""
macro getcases(ft, desc...)
    _ft = esc(ft)
    _desc = join(String.(desc), ' ')

    :(getcases($_ft, $_desc))
end

function getcases(ft::FailedTests, desc::AbstractString)
    desc_matched = first(findnearest(desc,
                                     String.(keys(ft)),
                                     Levenshtein()))

    ft[desc_matched]
end

function show(io::IO, ::MIME"text/plain", ft::FailedTests)
    nbfailed = length(ft)

    header = "$nbfailed failing predicate" *
        (nbfailed > 1 ? "s" : "") *
        ":\n"

    print(io, header * join(String.(keys(ft)), "\n"))
end
