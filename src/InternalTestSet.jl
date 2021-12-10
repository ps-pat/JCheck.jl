import Test: Test, record, finish
using Test: AbstractTestSet, DefaultTestSet, Result, Pass, Fail, Error
using Test: get_testset_depth, get_testset

struct InternalTestSet <: AbstractTestSet
    default_ts::DefaultTestSet
end

InternalTestSet(desc::AbstractString; verbose::Bool = false) =
    InternalTestSet(DefaultTestSet(desc, verbose = verbose))

record(ts::InternalTestSet, t::Result) = record(ts.default_ts, t)

function record(ts::InternalTestSet, t::Fail)
    push!(ts.default_ts.results, t)
    t
end

finish(ts::InternalTestSet) = finish(ts.default_ts)
