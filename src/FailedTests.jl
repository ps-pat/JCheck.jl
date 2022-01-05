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
a `Dict{Symbol, Any}` used for dispatch.
"""
struct FailedTests <: AbstractDict{Symbol, Any}
    dict::Dict{Symbol, Any}
end

"""
    load(io)

Load a collection of failed test cases serialized by a
[`@quickcheck`](@ref) run.
 Argument `io` can be of type `IO`, `AbstractString` or `AbstractPath`.

# Examples
```jldoctest
julia> ft = JCheck.load("JCheck_test.jchk")
2 failing predicates:
Product commute
Is odd
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

"""
    @getcases ft, desc...

Get the predicate with description `desc` and the valuations for which it
failed.

# Note
The predicate with description closest to the one given (in the sense of
the Levenshtein distance) will be returned; there is no need to pass the
exact description.

# Examples
``` jldoctest
julia> ft = JCheck.load("JCheck_test.jchk")
2 failing predicates:
Product commute
Is odd

julia> pred, valuations = @getcases ft iod
NamedTuple{(:predicate, :valuations), Tuple{Function, Vector{Tuple}}}((Serialization.__deserialized_types__.var"#3#4"(), Tuple[(0,), (-9223372036854775808,), (6444904272543528628,)]))
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
