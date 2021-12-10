module JCheck

include("generate.jl")

export generate
export specialcases

include("TestSet.jl")

export Quickcheck

export @add_variables
export @add_predicate
export @quickcheck

end
