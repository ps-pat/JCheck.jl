module JCheck

include("generate.jl")

export generate
export specialcases

export SquareMatrix

include("Quickcheck.jl")

export Quickcheck

export @add_predicate
export @quickcheck

include("FailedTests.jl")

export load

export @getcases

include("shrink.jl")

export shrink
export shrinkable

end
