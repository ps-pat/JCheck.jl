#!/usr/bin/env julia

using JCheck
using Test

@time begin
    @testset "JCheck's tests" begin
        include("TestSet.jl")
    end
end
