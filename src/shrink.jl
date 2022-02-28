"""
    shrink(x)

Shrinks an input. Assuming that `x` is of type `T`, the returned value is
of type `Vector{Array{T, N}}`. Returning a vector of length 1 is
interpreted as meaning that no further shrinkage is possible.

# Note
The length of `x` must be at least `2^N` for shrinkage to be possible.
If this is not the case, an array of length 1 containing x will be returned.
"""
shrink(x::T) where T = T[x] # Fallback method.

function shrink_array_loop!(ret::Vector,
                            current_idx::Vector{Int},
                            x::AbstractArray{T, N},
                            ns::Vector,
                            dims::Matrix) where {T, N}
    @inbounds for (k, el) ∈ enumerate(x)
        k -= 1 # Julia's arrays start at 1 :'(
        subarray_idx = zero(Int)

        ## Binary magic!
        @inbounds for p ∈ 1:N
            subarray_idx += 2^(p - 1) * ((k % ns[p]) ÷ dims[p, 1])
            k ÷= ns[p]
        end

        subarray_idx += 1 # :'(
        ret[subarray_idx][current_idx[subarray_idx]] = el
        current_idx[subarray_idx] += 1
    end

    ret
end

function shrink(x::AbstractArray{T, N}) where {T, N}
    any(x -> x < 2, size(x)) && return typeof(x)[x]

    ## Length of each dimension of `x`.
    ns = [size(x)...]

    ## Those will be used to compute the dimensions of the sub-array
    ## generated.
    dims = hcat(ns .- ns .÷ 2, ns .÷ 2)

    ## Preallocate memory for the sub-arrays.
    ret_dims = Iterators.product(eachrow(dims)...) |>
        Iterators.flatten |>
        α -> Iterators.partition(α, N)
    ret = [similar(x, eltype(x), Tuple(dim)) for dim ∈ ret_dims]

    ## Index of the entry to fill by sub-array.
    current_idx = ones(Int, length(ret))

    ## Doing the heavy lifting in a separate function leads to huge
    ## improvements in terms of speed in memory usage.
    shrink_array_loop!(ret, current_idx, x, ns, dims)
end


    ret
end
