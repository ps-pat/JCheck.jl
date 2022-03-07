using Base:
    splat,
    Fix2

"""
    shrink(x)

Shrink an input. The returned value is a `Vector` with elements `similar`
to `x`. Returning a vector of length 1 is interpreted as meaning that
no further shrinkage is possible.

# Default Shrinkers
`shrink` methods for the following types are shipped with this package:
- `AbstractString`
- `AbstractArray{T, N}` for any `T` and `N`

# Implementation
- Any implementation of `shrink(x::T)` must come with an implementation of
  [`shrinkable(x::T)`](@ref). Failure to do so will prevent
  [`@quickcheck`](@ref) from calling `shrink` on an object of type `T`.
- `shrink(x)` must return [x] if `shrinkable(x)` evaluate to `false`. We
  suggest that the first line of your method is something like:

    shrinkable(x) || return typeof(x)[x]
"""
shrink(x::T) where T = T[x] # Fallback method.

function shrink_array_loop!(ret::Vector,
                            x::AbstractArray{T, N},
                            ns::Tuple,
                            dims::Tuple{Int, Int}...) where {T, N}
    ## Index of the entry to fill by sub-array.
    current_idx = ones(Int, length(ret))

    @inbounds for (k, el) ∈ enumerate(x)
        k -= 1 # Julia's arrays start at 1 :'(
        subarray_idx = zero(Int)

        ## Binary magic!
        @inbounds for p ∈ 1:N
            subarray_idx += 2^(p - 1) * ((k % ns[p]) ÷ dims[p][1])
            k ÷= ns[p]
        end

        subarray_idx += 1 # :'(
        ret[subarray_idx][current_idx[subarray_idx]] = el
        current_idx[subarray_idx] += 1
    end

    ret
end

function shrink(x::AbstractArray{T, N}) where {T, N}
    shrinkable(x) || return typeof(x)[x]

    ## Length of each dimension of `x`.
    ns = size(x)

    ## Those will be used to compute the dimensions of the sub-array
    ## generated.
    dims = ntuple(i -> (ns[i] - ns[i] ÷ 2, ns[i] ÷ 2), N)

    ## Preallocate memory for the sub-arrays.
    ret_dims = dims |>
        splat(Iterators.product) |>
        Iterators.flatten |>
        Fix2(Iterators.partition, N) .|>
        NTuple{N, Int}
    ret = [similar(x, eltype(x), dim) for dim ∈ ret_dims]

    ## Doing the heavy lifting in a separate function leads to huge
    ## improvements in terms of speed and memory usage.
    shrink_array_loop!(ret, x, ns, dims...)
end

function shrink(x::AbstractString)
    shrinkable(x) || return typeof(x)[x]

    n = length(x) ÷ 2
    [x[1:n], x[range(n + 1, end)]]
end

"""
    shrinkable(x)

Determines if `x` is shrinkable.

# Note
Shrinkage can easily be disabled for type `T` using overloading:

    shrinkable(x::T) = false
"""
shrinkable(x) = false # Fallback method

shrinkable(x::AbstractArray) = all(>=(2), size(x))

shrinkable(x::AbstractString) = length(x) >= 2
