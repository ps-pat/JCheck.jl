#!/usr/bin/env julia

using JCheck
using Test

import Aqua

include("types_with_generate.jl")

@testset "JCheck's tests" verbose = true begin
    Aqua.test_all(JCheck)

    include("Quickcheck.jl")
    include("shrink.jl")
    include("generate.jl")
    include("LinearAlgebra.jl")
end
