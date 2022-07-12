using Base: Fix2

using LinearAlgebra:
    AbstractTriangular,
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

struct SquareMatrix{T} <: DenseMatrix{T}
    mat::Matrix{T}
end

IndexStyle(::Type{<:SquareMatrix}) = IndexLinear()

for func ∈ [:eltype, :size, :getindex]
    @eval $func(M::SquareMatrix, args...) = $func(M.mat, args...)
end

function generate(rng, ::Type{SquareMatrix{T}}, n) where T
    sizes = randlen(rng, 12, n)

    SquareMatrix{T}[SquareMatrix{T}(reshape(generate(rng, T, σ^2), σ, σ))
                    for σ ∈ sizes]
end

@generated specialcases(::Type{SquareMatrix{T}}) where T =
    SquareMatrix{T}.(specialcases(Matrix{T}))

## Diagonal-ish matrices.

generate(rng, ::Type{Diagonal{T, V}}, n) where {T, V <: AbstractVector{T}} =
    broadcast(Diagonal, generate(rng, V, n))

function generate(rng, ::Type{Bidiagonal{T, V}}, n) where {T, V <: AbstractVector{T}}
    diags = generate(rng, V, n)
    sdiags = map(len -> rand(rng, eltype(V), len), length.(diags) .- 1)
    uplo = rand(rng, ['U', 'L'], n)

    map(Bidiagonal, diags, sdiags, uplo)
end

function generate(rng, ::Type{Tridiagonal{T, V}}, n) where {T, V <: AbstractVector{T}}
    diags = generate(rng, V, n)
    uldiags = map(len -> rand(rng, eltype(V), len),
                  repeat(length.(diags) .- 1, 2))

    map(Tridiagonal, uldiags[1:n], diags, uldiags[(n+1):end])
end

function generate(rng, ::Type{SymTridiagonal{T, V}}, n) where {T, V <: AbstractVector{T}}
    diags = generate(rng, V, n)
    sdiags = map(len -> rand(rng, eltype(V), len), length.(diags) .- 1)

    map(SymTridiagonal, diags, sdiags)
end

generate(rng, ::Type{UniformScaling{T}}, n) where T =
    broadcast(UniformScaling, generate(rng, T, n))

for (type, args) ∈ Dict(:Diagonal => ([],),
                        :SymTridiagonal => ([], []),
                        :Tridiagonal => ([], [], []))
    @eval begin
        @generated specialcases(::Type{$type{T, V}}) where {T, V <: AbstractVector} =
            $type{T, V}[$type{T, V}($args...)]
    end
end

@generated specialcases(::Type{Bidiagonal{T, V}}) where {T, V <: AbstractVector{T}} =
    [Bidiagonal{T, V}([], [], 'U'), Bidiagonal{T, V}([], [], 'L')]

@generated specialcases(::Type{UniformScaling{T}}) where T =
    UniformScaling{T}[UniformScaling{T}(0)]

## Symmetric and Hermitian matrices.
const SymOrHerm =
    Union{<:Type{Symmetric{T, S}}, <:Type{Hermitian{T, S}}} where {T, S}

SymOrHerm_Simple = SymOrHerm{T, SquareMatrix{T}} where T

generate(rng, type::SymOrHerm{T, S}, n) where {T, S <: AbstractMatrix{T}} =
    map(type, generate(rng, S, n), rand(rng, ['U', 'L'], n))

function specialcases(type::SymOrHerm{T, S}) where {T, S <: AbstractMatrix{T}}
    sc_S = specialcases(S)
    [Fix2(type, 'U').(sc_S); Fix2(type, 'L').(sc_S)]
end

## Triangular & Hessenberg matrices.
const TrigOrHess = Union{<:Type{<:AbstractTriangular{T, S}},
                         <:Type{UpperHessenberg{T, S}}} where {T, S}

generate(rng, type::TrigOrHess{T, S}, n) where {T, S <: AbstractMatrix{T}} =
    map(type, generate(rng, S, n))

specialcases(type::TrigOrHess{T, S}) where {T, S <: AbstractMatrix{T}} =
    map(type, specialcases(S))

## Ugly hack to simplify common usage.
## TODO: Doesn't work for `Symmetric` & `Hermitian`.
for (type, mat) ∈ Dict(:UpperTriangular => :SquareMatrix,
                       :UnitUpperTriangular => :SquareMatrix,
                       :LowerTriangular => :SquareMatrix,
                       :UnitLowerTriangular => :SquareMatrix,
                       :UpperHessenberg => :Matrix,
                       # :Symmetric => :SquareMatrix,
                       # :Hermitian => :SquareMatrix,
                       :Diagonal => :Vector,
                       :Bidiagonal => :Vector,
                       :Tridiagonal => :Vector,
                       :SymTridiagonal => :Vector)
    @eval begin
        generate(rng, ::Type{$type{T}}, n) where T =
            generate(rng, $type{T, $mat{T}}, n)

        @generated specialcases(::Type{$type{T}}) where T =
            specialcases($type{T, $mat{T}})
    end
end
