using Random:
    AbstractRNG,
    GLOBAL_RNG,
    bitrand

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
