using Random:
    AbstractRNG,
    GLOBAL_RNG,
    bitrand

"""
    generate([rng=GLOBAL_RNG], T, n)

Sample `n` random instances of type `T`.

# Arguments

- `rng::AbstractRNG`: random number generator to use.
- `T::Type`: type of the instances.
- `n::Int`: number of realizations to sample.

# Implementation

- Your method should return a `Vector{T}`
- It is not necessary to write `generate(T, n)`; this is handled
  automatically. You only need to implement
  `generate(::AbstractRNG, ::Type{T}, ::Int)`
- Consider implementing [`specialcases`](@ref) for `T` as well.

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
generate(::Type{T}, n::Int) where T = generate(GLOBAL_RNG, T, n)

specialcases(::Type{T}) where T = Vector{T}()

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

specialcases(::Type{T}) where T <: SampleableReal = T[zero(T),
                                                      one(T),
                                                      typemin(T),
                                                      typemax(T)]
