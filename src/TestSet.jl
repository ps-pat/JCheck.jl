using Random: AbstractRNG, GLOBAL_RNG

using Base: method_argnames

using Test: @test, @testset

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
end

function Quickcheck(desc::AbstractString;
                    rng::AbstractRNG = GLOBAL_RNG,
                    n::Int = 100)
    Quickcheck(rng, PredsAssoc(), ArgsDict(), n)
end

macro add_variables(qc, vardec...)
    ## Expressions that are to be returned by the macro.
    ret = Expr[]

    ## Name of the TestSet.
    _qc = esc(qc)

    for declaration in vardec
        ## `type` must be an expression (type `Expr`) of the form
        ## `x::Type` where `x` is a `Symbol` and `Type` is a
        ## `DataType`.
        declaration isa Expr &&
            declaration.head == :(::) &&
            first(declaration.args) isa Symbol &&
            eval(last(declaration.args)) isa DataType ||
            error("Invalid variable declaration $declaration")

        varname = Ref(first(declaration.args))
        vartype = last(declaration.args)

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

        @testset InternalTestSet "Test $desc" for (pred, desc, args) ∈ _qc.predicates
            ## Flip to `false` if predicate evaluates to `false` for any
            ## valuation.
            local holds = true

            valuations = map(arg -> _qc.variables[arg].values, args)
            for valuation ∈ zip(valuations...)
                pass = pred(valuation...)

                if !pass
                    ex = Expr(:tuple,
                              (Expr(:(=), arg, val)
                               for (arg, val) ∈ zip(args, valuation))...)
                    @warn "Predicate \"$desc\" does not hold \
                           for valuation $ex"
                    holds = false
                end
            end
            @test holds
        end
        nothing
    end
end
