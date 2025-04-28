using Base: Fix2

import Base:
    similar,
    eltype,
    size,
    getindex,
    setindex!,
    IndexStyle

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

############################################################
### Square matrix type.
############################################################

struct SquareMatrix{T} <: DenseMatrix{T}
    mat::Matrix{T}
end

IndexStyle(::Type{SquareMatrix}) = IndexLinear()

IndexStyle(::SquareMatrix) = IndexStyle(SquareMatrix)

eltype(::Type{SquareMatrix{T}}) where T = T

size(x::SquareMatrix) = size(x.mat)

getindex(A::SquareMatrix, inds...) = getindex(A.mat, inds...)

setindex!(A::SquareMatrix, X, inds...) = setindex!(A.mat, X, inds...)

similar(array::SquareMatrix,
        element_type::Type{T} = eltype(array),
        dims::Tuple{Int, Vararg{Int, N}} = size(array)) where {T, N} =
    SquareMatrix(similar(array.mat, element_type, dims))

function generate(rng, ::Type{SquareMatrix{T}}, n) where T
    sizes = randlen(rng, 12, n)

    SquareMatrix{T}[SquareMatrix{T}(reshape(generate(rng, T, σ^2), σ, σ))
                    for σ ∈ sizes]
end

@generated specialcases(::Type{SquareMatrix{T}}) where T =
    SquareMatrix{T}.(specialcases(Matrix{T}))

shrink(x::SquareMatrix) = SquareMatrix.(shrink(x.mat)[[1, 4]])

############################################################
### Generators and special cases for special matrices.
############################################################

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
const TrigOrHess = Union{<:Type{<:AbstractTriangular{T}},
                         <:Type{UpperHessenberg{T, S}}} where {T, S}

generate(rng, type::TrigOrHess{T, S}, n) where {T, S <: AbstractMatrix{T}} =
    map(type, generate(rng, S, n))

specialcases(type::TrigOrHess{T, S}) where {T, S <: AbstractMatrix{T}} =
    map(type, specialcases(S))

## Ugly hack to simplify common usage.
## TODO: Doesn't work for `Symmetric` & `Hermitian`.
for (type, mat) ∈ (:UpperTriangular => :SquareMatrix,
                   :UnitUpperTriangular => :SquareMatrix,
                   :LowerTriangular => :SquareMatrix,
                   :UnitLowerTriangular => :SquareMatrix,
                   :UpperHessenberg => :Matrix,
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

for type ∈ [:Symmetric, :Hermitian]
    @eval begin
        msg = "Not implemented for `" * string($type) * "{T}`; " *
            "specify `" * string($type) * "{T, S}` instead"

        generate(rng, ::Type{$type{T}}, n) where T = error(msg)

        specialcases(::Type{$type{T}}) where T = error(msg)
    end
end

############################################################
### Shrinkers for special matrices.
############################################################

## Diagonal-ish matrices.

shrink(x::Diagonal) = shrinkable(x) ? Diagonal.(shrink(x.diag)) : [x]

function shrink_bi_symtri(x)
    diags = shrink(x.dv)

    sdiags = Vector{typeof(x.ev)}(undef, 2)
    sdiags[1] = x.ev[range(1, length = length(first(diags)) - 1)]
    sdiags[2] = x.ev[range(end, length = length(last(diags)) - 1, step = -1)]

    (diags, sdiags)
end

shrink(x::Bidiagonal) = shrinkable(x) ?
    broadcast(Bidiagonal, shrink_bi_symtri(x)..., x.uplo) : [x]

shrink(x::SymTridiagonal) = shrinkable(x) ?
    broadcast(SymTridiagonal, shrink_bi_symtri(x)...) : [x]

function shrink(x::Tridiagonal)
    shrinkable(x) || return [x]

    diags = shrink(x.d)

    udiags = Vector{typeof(x.du)}(undef, 2)
    ldiags = Vector{typeof(x.dl)}(undef, 2)

    ranges = [range(1, length = length(first(diags)) - 1),
              range(length(x.du), length = length(last(diags)) - 1, step = -1)]

    udiags[1] = x.du[first(ranges)]
    udiags[2] = x.du[last(ranges)]

    ldiags[1] = x.dl[first(ranges)]
    ldiags[2] = x.dl[last(ranges)]

    map(Tridiagonal, ldiags, diags, udiags)
end

shrinkable(x::UniformScaling) = false

## Symmetric and Hermitian matrices.

shrink(x::T) where T <: Union{Symmetric, Hermitian} =
    shrinkable(x) ? broadcast(T, shrink(x.data), x.uplo) : [x]

shrink(x::T) where T <: Union{AbstractTriangular, UpperHessenberg} =
    shrinkable(x) ? broadcast(T, shrink(x.data)) : [x]
