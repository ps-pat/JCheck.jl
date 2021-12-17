using Random:
    AbstractRNG,
    GLOBAL_RNG,
    bitrand

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

for (type, size) ∈ Dict(Float16 => 16, Float32 => 32, Float64 => 64)
    @eval begin
        function generate(rng::AbstractRNG, ::Type{$type})
            first(reinterpret($type, bitrand($size).chunks))
        end
    end
end

specialcases(::Type{T}) where T <: SampleableReal = [zero(T),
                                                     one(T),
                                                     typemin(T),
                                                     typemax(T)]
