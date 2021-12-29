module JCheck

include("generate.jl")

export generate
export specialcases

include("TestSet.jl")

export Quickcheck

export @add_predicate
export @quickcheck

include("FailedTests.jl")

export load

export @getcases

end
