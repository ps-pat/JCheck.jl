using LinearAlgebra:
    Symmetric,
    Hermitian,
    UpperTriangular,
    UnitUpperTriangular,
    LowerTriangular,
    UnitLowerTriangular,
    UpperHessenberg,
    Tridiagonal,
    SymTridiagonal,
    Bidiagonal,
    Diagonal,
    UniformScaling

## Types for which a `generate` method is implemented. For parametric
## types, the parameters are arbitrary.
types_with_generate = [Bool,
                       UInt8, UInt16, UInt32, UInt64, UInt128,
                       Int128, Int16, Int32, Int64, Int8,
                       Float16, Float32, Float64,
                       Complex{Float64},
                       String, Char,
                       Vector{Float64}, Matrix{Int}, Array{Float32, 3},
                       BitVector, BitMatrix, BitArray{5},
                       SquareMatrix{Float64},
                       Symmetric{Float64, SquareMatrix{Float64}},
                       Hermitian{Float64, SquareMatrix{Float64}},
                       UpperTriangular{Float64},
                       UnitUpperTriangular{Float64},
                       LowerTriangular{Float64},
                       UnitLowerTriangular{Float64},
                       UpperHessenberg{Float64}, Tridiagonal{Float64},
                       SymTridiagonal{Float64}, Bidiagonal{Float64},
                       Diagonal{Float64}, UniformScaling{Float64},
                       Union{Complex{Float64}, String, Char,
                             Vector{Float64}, Matrix{Int},
                             Array{Float32, 3}, BitVector, BitMatrix,
                             BitArray{5}, SquareMatrix{Float64},
                             Symmetric{Float64, SquareMatrix{Float64}}}]
@testset "generate & specialcases methods" begin
    for type ∈ types_with_generate
        @test length(generate(type, 100)) == 100
        @test !isempty(specialcases(type))
    end

    @test isempty(specialcases(Any))
end
