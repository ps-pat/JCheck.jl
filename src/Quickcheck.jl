using Random: AbstractRNG, GLOBAL_RNG

using Base:
    splat,
    Fix1

using Test: @test, @testset

import JLSO

import Dates

using Memoization: @memoize

include("InternalTestSet.jl")

ArgsDict = Dict{Symbol, Vector}

PredsAssoc = Vector{NamedTuple{(:pred, :desc, :args),
                               Tuple{Function, String, Vector{Symbol}}}}
"""
    Quickcheck

Contain a set of properties to check through the generation of random input.

# Fields

- `description::AbstractString`: description for the instance
- `rng::AbstractRNG`: PRNG used to generate inputs
- `predicates::PredsAssoc`: predicates to check
- `variables::ArgsDict`: arguments used by the predicates
- `n::Int`: number of random inputs to generate
- `serialize_fails::Bool`: if true, serialize failing inputs to a JLSO file
"""
struct Quickcheck
    description::AbstractString

    ## PRNG used to generate inputs.
    rng::AbstractRNG

    ## Predicates and the names of their arguments.
    predicates::PredsAssoc

    ## Arguments, their type and a vector of randomly generated values.
    variables::ArgsDict

    ## Number of random inputs to generate.
    n::Int

    ## Should failing inputs be serialized?
    serialize_fails::Bool
end

"""
    Quickcheck(desc; rng=GLOBAL_RNG, n=100, serialize_fails=true)

Constructor for type [`Quickcheck`](@ref).

# Arguments

- `desc::AbstractString`: description for the instance
- `rng::AbstractRNG`: PRNG used to generate inputs
- `n::Int`: number of random inputs to generate
- `serialize_fails::Bool`: if true, serialize failing inputs to a JLSO file

# Examples
```jldoctest
julia> qc = Quickcheck("A Test")
A Test: 0 predicate and 0 free variable.
```
"""
function Quickcheck(desc::AbstractString;
                    rng::AbstractRNG = GLOBAL_RNG,
                    n::Int = 100,
                    serialize_fails = true)
    Quickcheck(desc, rng, PredsAssoc(), ArgsDict(), n, serialize_fails)
end

function add_predicate(qc::Quickcheck,
                       desc::AbstractString,
                       args::Vector{Symbol},
                       types::Union{Vector{DataType},
                                    Vector{UnionAll},
                                    Vector{Union}},
                       pred::Function)
    ## Make sure that no predicate with the same description exists in
    ## `qc`.
    for (_, olddesc, _) ∈ qc.predicates
        olddesc === desc &&
            error("A predicate with the same description already exists")
    end

    for (arg, type) ∈ Iterators.zip(args, types)
        ## Make sure that suitable variables are available in `qc`. If
        ## `arg` is not present already, simply add it. Otherwise, we
        ## make sure types are the same.
        if !haskey(qc.variables, arg)
            qc.variables[arg] = generate(qc.rng, type, qc.n)
            continue
        end

        oldtype = eltype(qc.variables[arg])
        oldtype === type && continue

        error("A declaration for variable $arg already exists with type \
               $oldtype; please choose another name for $arg")
    end

    push!(qc.predicates, (pred = pred, desc = desc, args = [args...]))

    qc
end

"""
    @add_predicate qc desc pred

Add the predicate `pred` to the set of tests `qc` with description `desc`.

# Arguments

- `qc`: object of type [`Quickcheck`](@ref Quickcheck)
- `desc`: string describing the predicate
- `pred`: predicate in the form of an [anonymous function](https://docs.julialang.org/en/v1/manual/functions/#man-anonymous-functions)

# Notes

The form of `pred` is very strict:
- It has to be an anonymous function. Formally, it should be an
  `Expr` of type `->`.
- The type of each argument appearing on the left-hand side of `pred` has
  to be specified with the `x::Type` syntax.
- The names of the arguments of `pred` matter! Specifically, in a given
  [`Quickcheck`](@ref Quickcheck) object, the type of every argument must
  be consistent across predicates (see examples).
- Each predicate stored in a given [`Quickcheck`](@ref Quickcheck) object
  must be given a distinct description.

# Examples
```jldoctest
julia> qc = Quickcheck("A Test")
A Test: 0 predicate and 0 free variable.

julia> @add_predicate qc "Identity" (x::Float64 -> x == x)
A Test: 1 predicate and 1 free variable.
x::Float64

julia> @add_predicate qc "Sum commute" ((n::Int, x::Float64) -> n + x == x + n)
A Test: 2 predicates and 2 free variables:
n::Int64
x::Float64

julia> @add_predicate qc "Is odd" isodd(x)
ERROR: Predicate declaration must have the form of an anonymous function (... -> ...)
[...]

julia> @add_predicate qc "Is odd" (x::Int -> is_odd(x))
ERROR: A declaration for variable x already exists with type Float64; please choose another name for x
[...]
```
"""
macro add_predicate(qc, desc, pred)
    ## Perform a bunch of checks.
    pred.head === :(->) ||
        return :(error("Predicate declaration must have the form of an \
                        anonymous function (... -> ...)"))

    local declarations = first(pred.args)

    if !(declarations isa Expr)
        var = Meta.quot(declarations)
        return :(error("A type must be specified for free variable \
                        $($var)"))
    end

    declarations.head ∈ [:(::), :tuple] ||
        return :(error("The rhs of the predicate must either be a single \
                        variable of a tuple of variables."))

    if declarations.head === :tuple
        for declaration ∈ declarations.args
            if !(declaration isa Expr)
                var = Meta.quot(declaration)
                return :(error("A type must be specified for free \
                                variable $($var)"))
            end
        end
    end

    ## Manage differences between unary and non unary predicates.
    local pred_arguments::Vector{Expr} =
        declarations.head === :tuple ?
        declarations.args : [declarations]

    local args, types = destructure_declaration(pred_arguments)

    :(add_predicate($(esc(qc)),
                    $desc,
                    [$args...],
                    [$types...],
                    $(esc(pred))))
end

function destructure_declaration(vardec::Union{Vector{Expr},
                                               Tuple{Vararg{Expr}}})
    args, types = vardec |>
        args -> Iterators.map(e -> [first(e.args), last(e.args)], args) |>
        splat(Iterators.zip)

    args, esc(Expr(:tuple, types...))
end

function Base.show(io::IO, qc::Quickcheck)
    nbpredicates = length(qc.predicates)
    nbvariables = length(qc.variables)

    predicate_string = "predicate" * (nbpredicates < 2 ? "" : 's')
    variable_string = "variable" * (nbvariables < 2 ? '.' : "s:")

    header = "$(qc.description): $nbpredicates $predicate_string and \
              $nbvariables free $variable_string"

    isempty(qc.variables) && return print(io, header)

    vars = String[]
    for (variable, entry) ∈ pairs(qc.variables)
        push!(vars, string(variable) * "::" * string(eltype(entry)))
    end

    print(io, header, "\n", join(vars, "\n"))
end

@memoize function evaluate_shrink(predicate::Function,
                                  valuation::Tuple,
                                  depth::Int)
    ## If `valuation` satisfies `predicate`, return it with depth 0.
    predicate(valuation...) && return valuation, zero(Int)

    ## Verify that at least one entry of valuation is shrinkable. If
    ## that's not the case, just return it.
    any(shrinkable, valuation) || return valuation, depth

    ## Let the shrinkage begin!
    candidates = valuation |>
        Fix1(Iterators.map, shrink) |>
        splat(Iterators.product)

    isempty(candidates) && return valuation, depth

    best_candidate, candidates = Iterators.peel(candidates)
    shrunk_best_candidates = evaluate_shrink(predicate, best_candidate, depth + 1)
    for candidate ∈ candidates
        shrunk_candidate = evaluate_shrink(predicate, candidate, depth + 1)

        if last(shrunk_candidate) > last(shrunk_best_candidates)
            shrunk_best_candidates = shrunk_candidate
        end
    end

    ## If no candidate falsifies the predicate, just return the
    ## original valuation.
    iszero(last(shrunk_best_candidates)) && return valuation, depth

    shrunk_best_candidates
end

evaluate_shrink(predicate::Function, valuation::Tuple) =
    first(evaluate_shrink(predicate, valuation, 1))

function quickcheck(qc::Quickcheck, file_id::AbstractString)
    ## Stores failed cases. The key is the test predicate's
    ## description (as a symbol). The value is a named tuple
    ## containing the actual predicate (predicate) and a vector of
    ## inputs for which the predicate evaluated to `false`
    ## (valuation).
    local failed = Dict{Symbol,
                        NamedTuple{(:predicate, :valuations),
                                   Tuple{Function, Vector{Tuple}}}}()

    @testset InternalTestSet "Test $desc" for
        (pred, desc, args) ∈ qc.predicates

        ## Flip to `false` if predicate evaluates to `false` for any
        ## valuation.
        local holds = true

        ## Special cases.
        specialcases_itr = args |>
            Fix1(Iterators.map,
                 specialcases ∘ eltype ∘ Fix1(getindex, qc.variables)) |>
            splat(Iterators.product)

        ## Random cases.
        randomcases_itr = args |>
            Fix1(Iterators.map, Fix1(getindex, qc.variables)) |>
            splat(Iterators.zip)

        for valuation ∈ Iterators.flatten((specialcases_itr,
                                           randomcases_itr))
            if !pred(valuation...)
                try
                    valuation = evaluate_shrink(pred, valuation)
                catch e
                    @warn "Could not shrink valuation, got the following \
                           error: $e"
                end

                ex = Expr(:tuple,
                          (Expr(:(=), arg, val)
                           for (arg, val) ∈ zip(args, valuation))...)
                @warn "Predicate \"$desc\" does not hold \
                               for valuation $ex"

                if qc.serialize_fails
                    if !haskey(failed, Symbol(desc))
                        failed[Symbol(desc)] = (predicate = pred,
                                                valuations = Tuple[])
                    end

                    push!(failed[Symbol(desc)].valuations, valuation)
                end
                holds = false
            end
        end
        @test holds
    end

    if !isempty(failed) && qc.serialize_fails
        filename = "JCheck_" * file_id
        fileextension = ".jchk"

        ## Make sure that no 2 files with the same name are
        ## created. Most likely useless except for people with
        ## nothing better to do trying to break shit.
        if ispath(filename * fileextension)
            filename *= "--1"
        end

        while ispath(filename * fileextension)
            id_start = last(findfirst("--", filename)) + one(Int)

            idx = parse(Int, filename[id_start:end]) + 1

            filename = filename[begin:(id_start - 1)] * string(idx)
        end

        JLSO.save(filename * fileextension, failed)

        ## Warn the user that some predicates do not hold.
        message_color = Base.warn_color()

        println()
        printstyled("Some predicates do not hold for some valuations; \
                             they have been saved to \
                             $(filename * fileextension). Use function ",
                    color = message_color)
        printstyled("load", color = message_color, underline = true)
        printstyled(" and macro ", color = message_color)
        printstyled("@getcases",
                    color = message_color,
                    underline = true)
        printstyled(" to explore problematic cases.",
                    color = message_color)
        println("\n")
    end

    nothing
end

"""
    @quickcheck qc [file_id::AbstractString="yyyy-mm-dd_HH-MM-SS"]

Check the properties specified in object `qc` of type [`Quickcheck`](@ref).

If `qc.serialize_fails` is `true`, serialize the failing cases to
`JCheck_<file_id>.jchk`. Those can latter be analyzed using
[`load`](@ref) and [`@getcases`](@ref).

# Note

If no argument `file_id` is passed, defaults to current time.
"""
macro quickcheck(qc, file_id::AbstractString)
    _qc = esc(qc)

    :(quickcheck($_qc, $file_id))
end

macro quickcheck(qc)
    _qc = esc(qc)

    file_id = Dates.format(Dates.now(), "yyyy-mm-dd_HH-MM-SS")

    :(@quickcheck($_qc, $file_id))
end
