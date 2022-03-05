#!/usr/bin/env julia

using JCheck
using Test

include("types_with_generate.jl")

@time begin
    @testset "JCheck's tests" begin
        include("Quickcheck.jl")
        include("shrink.jl")
        include("generate.jl")
    end
end
