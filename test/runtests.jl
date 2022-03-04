#!/usr/bin/env julia

using JCheck
using Test

@time begin
    @testset "JCheck's tests" begin
        include("Quickcheck.jl")
        include("shrink.jl")
        include("generate.jl")
    end
end
