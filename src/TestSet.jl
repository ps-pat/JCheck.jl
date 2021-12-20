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

struct Quickcheck <: AbstractTestSet
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

function Quickcheck(desc::AbstractString;
                    rng::AbstractRNG = GLOBAL_RNG,
                    n::Int = 100,
                    serialize_fails = true)
    Quickcheck(rng, PredsAssoc(), ArgsDict(), n, serialize_fails)
end

macro add_variables(qc, vardec...)
    ## Expressions that are to be returned by the macro.
    ret = Expr[]

    ## Name of the TestSet.
    _qc = esc(qc)

    for declaration in vardec
        ## `declaration` must be an expression (type `Expr`) of the
        ## form `x::Type` where `x` is a `Symbol` and `Type` is a
        ## `DataType`.
        declaration isa Expr &&
            declaration.head == :(::) &&
            first(declaration.args) isa Symbol &&
            eval(last(declaration.args)) isa DataType ||
            error("Invalid variable declaration $declaration")

        varname = Ref(first(declaration.args))
        vartype = esc(last(declaration.args))

        ## Add variables to the test set.
        push!(ret, quote
                  _varname = $varname[]
                  _vartype = $vartype

                  ## If a variable has already been declared, make
                  ## sure that it has the same type.
                  if haskey($_qc.variables, _varname)
                      previous_vartype =
                          $_qc.variables[_varname].type

                      _vartype === previous_vartype ||
                          error("$_varname has already been declared \
                                     with type $previous_vartype")
                  else
                      $_qc.variables[_varname] =
                          (type = _vartype,
                           values = [generate($_qc.rng, _vartype)
                                     for _ ∈ range(1, length = $_qc.n)])
                  end

                  $_qc
              end)
    end

    Expr(:block, ret...)
end

function add_predicate(qc::Quickcheck, desc::AbstractString, pred::Function)
    for method ∈ methods(pred)
        method.nargs < 2 && continue

        args = method_argnames(method)[2:end]
        types = method.sig.parameters[2:end]

        ismatch = true
        for (arg, type) ∈ zip(args, types)
            if !haskey(qc.variables, arg)
                ismatch = false
                break
            elseif !(qc.variables[arg].type <: type)
                ismatch = false
                break
            end
        end

        if ismatch
            push!(qc.predicates, (pred = pred, desc = desc, args = args))
            return qc
        end
    end

    error("No method of \"$desc\" has a signature matching a subset \
           of variables declared in test set")
end

macro add_predicate(qc, desc, pred)
    :(add_predicate($(esc(qc)), $desc, $(esc(pred))))
end

function Base.show(io::IO, qc::Quickcheck)
    header = "Test set with $(length(qc.predicates)) predicates \
              and $(length(qc.variables)) free variables:"

    vars = String[]
    for (variable, entry) ∈ pairs(qc.variables)
        push!(vars, string(variable) * "::" * string(entry.type))
    end

    print(header, "\n", join(vars, "\n"))
end

macro quickcheck(qc)
    quote
        local _qc = $(esc(qc))

        ## Stores failed cases. The key is the test predicate's
        ## description (as a symbol). The value is a named tuple
        ## containing the actual predicate (predicate) and a vector of
        ## inputs for which the predicate evaluated to `false`
        ## (valuation).
        local failed = Dict{Symbol,
                            NamedTuple{(:predicate, :valuations),
                                       Tuple{Function, Vector{Tuple}}}}()

        @testset InternalTestSet "Test $desc" for
            (pred, desc, args) ∈ _qc.predicates

            ## Flip to `false` if predicate evaluates to `false` for any
            ## valuation.
            local holds = true

            ## Special cases.
            types = map(v -> _qc.variables[v].type, args)
            specialcases_itr =
                Iterators.product(specialcases.(types)...) |>
                Iterators.flatten |>
                itr -> Iterators.partition(itr, length(args)) |>
                itr -> Iterators.map(Tuple, itr)

            ## Random cases.
            randomcases = map(arg -> _qc.variables[arg].values, args)

            for valuation ∈ Iterators.flatten([specialcases_itr,
                                               zip(randomcases...)])
                pass = pred(valuation...)

                if !pass
                    ex = Expr(:tuple,
                              (Expr(:(=), arg, val)
                               for (arg, val) ∈ zip(args, valuation))...)
                    @warn "Predicate \"$desc\" does not hold \
                           for valuation $ex"

                    if _qc.serialize_fails
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

        if !isempty(failed) && _qc.serialize_fails
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
end
