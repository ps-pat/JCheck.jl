#!/usr/bin/env julia

using JCheck
using Test

import Aqua

Aqua.test_all(JCheck)

include("types_with_generate.jl")

@testset "JCheck's tests" begin
    include("Quickcheck.jl")
    include("shrink.jl")
    include("generate.jl")
    include("LinearAlgebra.jl")
end
