using Random:
    AbstractRNG,
    GLOBAL_RNG,
    randexp,
    randstring,
    bitrand,
    shuffle!

using Base:
    Fix1,
    IndexLinear

import Base:
    eltype,
    length,
    ndims,
    size,
    axes,
    eachindex,
    stride,
    IndexStyle,
    getindex

include("generate_LinearAlgebra.jl")

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
- `Complex{T <: Real}`
- `String`
- `Char`
- `Array{T, N}`
- `BitArray{N}`
- `SquareMatrix{T}`.
- Any [special matrix](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/#Special-matrices) implemented by Julia's LinearAlgebra module.
- `Union{T...}`
- `UnitRange{T}`, `StepRange{T, T}`

In the previous list, `T` represent any type for which a `generate`
method is implemented.

# Special Matrices (LinearAlgebra)
- Generators are implemented for `<...>Triangular{T}` as well as
  `<...>Triangular{T, S}`. In the first case, `S` default to
  `SquareMatrix{T}`. The exact same thing is true for `UpperHessenberg`.
- Same idea for `<...>diagonal{T, V}` with `V` defaulting to `Vector{T}`.
- Generators are only implemented for `Symmetric{T, S}` and
  `Hermitian{T, S}` right now. Most of the time, you will want to specify
  `S` = `SquareMatrix{T}`.

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

# Implementation
When implementing `generate` for your type `T` keep the following in mind:
- Your method should return a `Vector{T}`
- It is not necessary to write `generate(T, n)` or
  `generate([rng, ]Array{T, N}, n) where N`; this is handled automatically.
  You only need to implement `generate(::AbstractRNG, ::Type{T}, ::Int)`
- Consider implementing [`specialcases`](@ref) and [`shrink`](@ref) for
  `T` as well.

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

for (type, σ) ∈ Dict(:Float16 => 16, :Float32 => 32, :Float64 => 64)
    @eval begin
        function generate(rng::AbstractRNG, ::Type{$type}, n::Int)
            raw_data = reinterpret($type, bitrand(rng, $σ * n).chunks)
            convert(Vector{$type}, raw_data)[begin:n]
        end
    end
end

@generated specialcases(::Type{T}) where T <: SampleableReal =
    T[zero(T), one(T), typemin(T), typemax(T)]

## Complex numbers.
generate(rng::AbstractRNG, ::Type{Complex{T}}, n::Int) where T <: Real =
    Complex.(generate(rng, T, n), generate(rng, T, n))

@generated specialcases(::Type{Complex{T}}) where T <: Real =
    Complex{T}[zero(Complex{T}),
               one(Complex{T}),
               typemin(T) + typemin(T)im,
               typemax(T) + typemax(T)im]

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

@generated specialcases(::Type{Char}) = Char['\0']

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
    Union{Array{<:Any, N}, BitArray{N}} where N

    DT[DT(undef, [zero(Int) for _ ∈ 1:N]...)]
end

## Union Type
function destructure_union(U::Union)
    types = sizehint!(DataType[], 4)
    U2 = U
    aunion = U2.a isa Union
    bunion = U2.b isa Union
    while true
        if aunion
            bunion || push!(types, U2.b)
            U2 = U2.a
        elseif bunion
            aunion || push!(types, U2.a)
            U2 = U2.b
        else
            push!(types, U2.a, U2.b)
            break
        end
        aunion = U2.a isa Union
        bunion = U2.b isa Union
    end
    types
end

function generate(rng::AbstractRNG, U::Union, n::Int)
    types = destructure_union(U)
    m = length(types)

    n < m && error("The number of elements in `U` must be greater than or \
                    equal to `n`.")

    chunksize = n ÷ m
    chunksizes = [fill(chunksize, m - 1); n - (m - 1) * chunksize]

    ## TODO: Compiler can't infer the type of `ret`, probably because
    ## the type of `generate(...)` cannot be inferred.
    ret::Vector{U} = mapreduce((n, type) -> generate(rng, type, n),
                               vcat,
                               chunksizes, types)

    shuffle!(ret)
end

specialcases(U::Union) =
    destructure_union(U) .|>
    specialcases |>
    collect ∘ Iterators.flatten

## AbstractRange
function generate(rng::AbstractRNG, ::Type{UnitRange{T}}, n::Int) where T
    data = generate(rng, T, 2n) |> Fix2(Iterators.partition, 2)

    map(data) do pair
        x, y = first(pair), last(pair)
        x <= y ? UnitRange(x, y) : UnitRange(y, x)
    end
end

specialcases(::Type{UnitRange{T}}) where T =
    UnitRange{T}[UnitRange(one(T), zero(T))]

function generate(rng::AbstractRNG,
                  ::Type{StepRange{T, S}},
                  n::Int) where {T, S}
    lbounds = generate(rng, T, n)

    spacings = rand(rng, setdiff(range(convert(S, -100), length = 200), 0), n)

    lens = abs.(rand(rng, Int16, n))
    ubounds = lbounds .+ lens .* spacings .|> Fix1(convert, T)

    map(StepRange, lbounds, spacings, ubounds)
end

specialcases(::Type{StepRange{T, S}}) where {T, S} =
    StepRange{T, S}[StepRange(one(T), one(S), zero(T))]
