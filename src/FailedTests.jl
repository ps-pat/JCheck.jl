import JLSO

import Base:
    iterate,
    length,
    eltype,
    getindex

using FilePathsBase: AbstractPath

using StringDistances:
    findnearest,
    Levenshtein

struct FailedTests <: AbstractDict{Symbol, Any}
    dict::Dict{Symbol, Any}
end

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
