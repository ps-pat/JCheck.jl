import Test: Test, record, finish
using Test: AbstractTestSet, DefaultTestSet, Result, Pass, Fail, Error
using Test: get_testset_depth, get_testset

struct JTestSet <: AbstractTestSet
    testset::DefaultTestSet
end

function JTestSet(desc::AbstractString; verbose::Bool = false)
    JTestSet(DefaultTestSet(desc, verbose = verbose))
end


record(ts::JTestSet, res::Union{AbstractTestSet, Result}) =
    record(ts.testset, res)

finish(ts::JTestSet) = finish(ts.testset)


# mutable struct JTestSet <: Test.AbstractTestSet
#     description::AbstractString
#     results::Vector
#     n_passed::Int
#     time_start::Float64
#     time_end::Float64
# end

# JTestSet(description::AbstractString) =
#     JTestSet(description, [], zero(Int), time(), zero(Float64))

# record(ts::JTestSet, child::AbstractTestSet) = push!(ts.results, child)

# function record(ts::JTestSet, res::Result)
#     push!(ts.results, res)
#     res
# end

# function record(ts::JTestSet, res::Pass)
#     ts.n_passed += 1
#     res
# end

# function finish(ts::JTestSet)
#     ts.time_end = time()

#     if get_testset_depth() > 0
#         record(get_testset(), ts)
#     end

#     print_test_results(ts::JTestSet)

#     ts
# end

# function get_test_counts(ts::JTestSet)
#     passes, fails, errors, broken = ts.npassed, 0, 0, 0,
# end

function print_test_results(ts::JTestSet)
    total_pass = ts.n_passed + count(res -> res isa Pass, ts.results)
end
