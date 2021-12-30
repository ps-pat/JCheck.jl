#!/usr/bin/env julia

using JCheck
using Test

@time begin
    @testset "JCheck's tests" begin
        include("Quickcheck.jl")
    end
end
