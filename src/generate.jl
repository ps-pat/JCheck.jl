using Random:
    AbstractRNG,
    GLOBAL_RNG,
    bitrand,
    randexp,
    randstring,
    bitrand

using Base: Fix1

using LinearAlgebra:
    Diagonal,
    Bidiagonal,
    Tridiagonal

"""
    generate([rng=GLOBAL_RNG], T, n)

Sample `n` random instances of type `T`.

# Arguments

- `rng::AbstractRNG`: random number generator to use.
- `T::Type`: type of the instances.
- `n::Int`: number of realizations to sample.

# Default generators
`generate` methods for the following types are shipped with this package:
- Subtypes of `AbstractFloat`
- Subtypes of `Integer` except `BigInt`
- `Complex{T <: Real}` where `T` is any subtype of `Real` for which a
  `generate` method exists
- `String`
- `Char`
- `Array{T, N}` where `T` is any type for which a `generate` method exists
- `BitArray{N}`
- `Diagonal`, `Bidiagonal` & `Tridiagonal` matrices (from LinearAlgebra)

# Implementation
When implementing `generate` for your type `T` keep the following in mind:
- Your method should return a `Vector{T}`
- It is not necessary to write `generate(T, n)` or
  `generate([rng, ]Array{T, N}, n) where N`; this is handled automatically.
  You only need to implement `generate(::AbstractRNG, ::Type{T}, ::Int)`
- Consider implementing [`specialcases`](@ref) and [`shrink`](@ref) for
  `T` as well.

# Arrays & Strings
General purpose generators for arrays and strings are a little bit tricky
to implement given that a length for each sampled element must be specified.
The following choices have been made for the default generators shipped with
this package:
- `String`: The length of each string is approximately exponentially
  distributed with mean 64.
- `Array{T, N}`: The length of each dimension of a given array is
  approximately exponentially distributed with mean 24 ÷ N + 1
  (in a low effort attempt to keep the number of entries manageable).

If this is not appropriate for your needs, don't hesitate to reimplement
`generate`.

# Examples
``` jldoctest
using Random: Xoshiro

rng = Xoshiro(42)

generate(rng, Float32, 10)

# output

10-element Vector{Float32}:
 -1.5388016f7
 -5.3113024f-19
 -1.3960648f35
  1.5957566f31
 -4.381218f26
  2.380078f35
  3.878954f9
 -1.1950524f-7
  7.525897f24
 -3.1891005f-12
```
"""
function generate end

## If no random number generator is specified, use `GLOBAL_RNG`.
generate(::Type{T}, n::Int) where T = generate(GLOBAL_RNG, T, n)

"""
    specialcases(T)

Non-random inputs that are always checked by [`@quickcheck`](@ref).

# Arguments

- `T::Type`: type of the inputs.

# Implementation

- Your method should return a `Vector{T}`
- Useless without a [`generate`](@ref) method for `T`.
- Be mindful of combinatoric explosion! [`@quickcheck`](@ref) generate an
  input for each element of the Cartesian product of the special cases of
  every arguments of the predicates it is trying to falsify. Only include
  special cases that are *truly* special.

# Examples
``` jldoctest
julia> specialcases(Int)
4-element Vector{Int64}:
                    0
                    1
 -9223372036854775808
  9223372036854775807

julia> specialcases(Float64)
4-element Vector{Float64}:
   0.0
   1.0
 -Inf
  Inf
```
"""
@generated specialcases(::Type{T}) where T = Vector{T}()

## Subtypes of Real on which `rand` can be called directly.
SampleableReal = Union{AbstractFloat,
                       Bool,
                       Unsigned,
                       Int128,
                       Int16,
                       Int32,
                       Int64,
                       Int8}

## Real numbers.
generate(rng::AbstractRNG, ::Type{T}, n::Int) where T <: SampleableReal =
    rand(rng, T, n)

for (type, size) ∈ Dict(Float16 => 16, Float32 => 32, Float64 => 64)
    @eval begin
        function generate(rng::AbstractRNG, ::Type{$type}, n::Int)
            raw_data = reinterpret($type, bitrand(rng, $size * n).chunks)
            convert(Vector{$type}, raw_data)[begin:n]
        end
    end
end

@generated specialcases(::Type{T}) where T <: SampleableReal =
    T[zero(T), one(T), typemin(T), typemax(T)]

## Complex numbers.
generate(rng::AbstractRNG, ::Type{Complex{T}}, n::Int) where T <: Real =
    Complex.(generate(rng, T, n), generate(rng, T, n))

## TODO: implement.
@generated specialcases(::Type{Complex{T}}) where T <: Real = Complex{T}[]

## Strings.
randlen(rng::AbstractRNG, theta::Real, args...) =
    Int.(round.(randexp(rng, args...) * theta)) .+ one(Int)

function generate(rng::AbstractRNG, ::Type{String}, n::Int)
    chrlst = UInt8['0':'9';'A':'Z';'a':'z'; ' ']
    map(len -> randstring(rng, chrlst, len), randlen(rng, 63, n))
end

@generated specialcases(::Type{String}) = String[""]

## Chars.
generate(rng::AbstractRNG, ::Type{Char}, n::Int) =
    rand(rng, Char, n)

## Array.

function generate(rng::AbstractRNG,
                  ::Type{Array{T, N}},
                  n::Int) where {T, N}
    ## Sizes of the arrays.
    sizes = [randlen(rng, 24 ÷ N, N) for _ ∈ 1:n]

    map(sizes) do σ
        data = generate(rng, T, prod(σ))
        ret = Array{T, N}(undef, σ...)
        for k ∈ eachindex(ret)
            ret[k] = data[k]
        end
        ret
    end
end

function generate(rng::AbstractRNG, ::Type{BitArray{N}}, n::Int) where N
    ## Sizes of the arrays.
    sizes = [randlen(rng, 24 ÷ N, N) for _ ∈ 1:n]

    map(σ -> bitrand(rng, σ...), sizes)
end

@generated function specialcases(::Type{DT}) where DT <:
    Union{Array{T, N}, BitArray{N}} where {T, N}

    DT[DT(undef, [zero(Int) for _ ∈ 1:N]...)]
end

## Special Matrices

generate(rng::AbstractRNG, ::Type{Diagonal{T}}, n::Int) where T =
    randlen(rng, 12, n) .|> Fix1(generate, T) .|> Diagonal

@generated specialcases(::Type{Diagonal{T}}) where T =
    Diagonal[Diagonal{T}(T[])]

generate(rng::AbstractRNG, ::Type{Bidiagonal{T}}, n::Int) where T =
    map(zip(randlen(rng, 12, n), bitrand(rng, n))) do (σ, uplo)
        ul = uplo ? :U : :L
        data = generate(rng, T, 2σ - 1)
        Bidiagonal(data[1:σ], data[range(σ + 1, 2σ - 1)], ul)
    end

@generated specialcases(::Type{Bidiagonal{T}}) where T =
    Bidiagonal{T}[Bidiagonal{T}(T[], T[], :U)]

generate(rng::AbstractRNG, ::Type{Tridiagonal{T}}, n::Int) where T =
    map(randlen(rng, 12, n)) do σ
        data = generate(rng, T, 3σ - 2)
        Tridiagonal(data[range(1, σ - 1)],
                    data[range(σ, 2σ - 1)],
                    data[range(2σ, 3σ - 2)])
    end

@generated specialcases(::Type{Tridiagonal{T}}) where T =
    Tridiagonal{T}[Tridiagonal{T}(T[], T[], T[])]
