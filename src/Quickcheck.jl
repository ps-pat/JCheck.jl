using Random: AbstractRNG, GLOBAL_RNG

using Base: method_argnames

using Test: @test, @testset

import JLSO

import Dates

include("InternalTestSet.jl")

ArgsDict = Dict{Symbol,
                NamedTuple{(:type, :values),
                           Tuple{DataType, Vector{Any}}}}

PredsAssoc = Vector{NamedTuple{(:pred, :desc, :args),
                               Tuple{Function, String, Vector{Symbol}}}}
"""
    Quickcheck

Contain a set of property to check through the generation of random input.

# Fields

- `description::AbstractString`: description for the instance.
- `rng::AbstractRNG`: PRNG used to generate inputs.
- `predicates::PredsAssoc`: predicates to check.
- `variables::ArgsDict`: Arguments used by the predicates.
- `n::Int`: Number of random inputs to generate.
- `serialize_fails::Bool`: If true, serialize failing inputs to a JLSO file.
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

- `desc::AbstractString`: description for the instance.
- `rng::AbstractRNG`: PRNG used to generate inputs.
- `n::Int`: Number of random inputs to generate.
- `serialize_fails::Bool`: If true, serialize failing inputs to a JLSO file.

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
                       types::Vector{DataType},
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
        oldtype_pair = get!(qc.variables, arg) do
            values = [generate(qc.rng, type)
                      for _ ∈ range(1, length = qc.n)]
            (type = type, values = values)
        end

        oldtype_pair.type === type && continue

        error("A declaration for variable $arg already exists with type \
               $(oldtype_pair.type); please choose another name for $arg")
    end

    push!(qc.predicates, (pred = pred, desc = desc, args = [args...]))

    qc
end

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
        it -> Iterators.zip(it...)

    args, esc(Expr(:tuple, types...))
end

function Base.show(io::IO, qc::Quickcheck)
    nbpredicates = length(qc.predicates)
    nbvariables = length(qc.variables)

    predicate_string = "predicate" * (nbpredicates < 2 ? "" : 's')
    variable_string = "variable" * (nbvariables < 2 ? '.' : "s:")

    header = "$(qc.description): $nbpredicates $predicate_string and \
              $nbvariables free $variable_string"

    if isempty(qc.variables)
        print(header)
        return
    end

    vars = String[]
    for (variable, entry) ∈ pairs(qc.variables)
        push!(vars, string(variable) * "::" * string(entry.type))
    end

    print(header, "\n", join(vars, "\n"))
end

function quickcheck(qc::Quickcheck)
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
        types = map(v -> qc.variables[v].type, args)
        specialcases_itr =
            Iterators.product(specialcases.(types)...) |>
            Iterators.flatten |>
            itr -> Iterators.partition(itr, length(args)) |>
            itr -> Iterators.map(Tuple, itr)

        ## Random cases.
        randomcases = map(arg -> qc.variables[arg].values, args)

        for valuation ∈ Iterators.flatten([specialcases_itr,
                                           zip(randomcases...)])
            pass = pred(valuation...)

            if !pass
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
        filename = "JCheck_" * Dates.format(Dates.now(),
                                            "yyyy-mm-dd_HH-MM-SS")
        fileextension = ".jchk"

        ## Make sure that no 2 files with the same name are
        ## created. Most likely useless except for people with
        ## nothing better to do trying to break shit.
        if ispath(filename * fileextension)
            filename *= "--1"
        end

        while ispath(filename * fileextension)
            ## 29 (28) works because the part of the name up to
            ## the index has a fixed width. Please don't fuck it
            ## up.
            idx = parse(Int, filename[29:end]) + 1

            filename = filename[1:28] * string(idx)
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
        printstyled(" to explore the problematic cases.",
                    color = message_color)
        println("\n")
    end

    nothing
end

"""
    @quickcheck qc

Check the properties specified in object `qc` of type [`Quickcheck`](@ref).
"""
macro quickcheck(qc)
    _qc = esc(qc)
    :(quickcheck($_qc))
end
