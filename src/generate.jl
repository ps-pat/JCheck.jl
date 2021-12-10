using Random: AbstractRNG, GLOBAL_RNG

generate(::Type{T}) where T = generate(GLOBAL_RNG, T)

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
generate(rng::AbstractRNG, ::Type{T}) where T <: SampleableReal = rand(T)

specialcases(::Type{T}) where T <: SampleableReal = [zero(T), one(T)]
