@testset "@add_predicates" begin
    qc = Quickcheck("Set for @add_predicates tests")

    @test isa(@add_predicate(qc, "Identity", (x::Float64 -> x == x)),
              Quickcheck)
    @test isa(@add_predicate(qc, "Is odd", (n::Int -> isodd(n))),
              Quickcheck)
    @test isa(@add_predicate(qc, "Sum commute",
                             ((n::Int, x::Float64) -> n + x == x + n)),
              Quickcheck)

    @test_throws(ErrorException,
                 @add_predicate(qc, "Identity", x == x))

    @test_throws(ErrorException,
                 @add_predicate(qc, "Identity", x -> x == x))
    @test_throws(ErrorException,
                 @add_predicate(qc, "sum commute",
                                (n, x::Float64) -> n + x == x + n))
    @test_throws(ErrorException,
                 @add_predicate(qc, "sum commute",
                                (n::Int, x) -> n + x == x + n))
    @test_throws(ErrorException,
                 @add_predicate(qc, "sum commute",
                                (n, x) -> n + x == x + n))

    @test_throws(ErrorException,
                 @add_predicate(qc, "sum commute",
                                (n, x -> n + x == x + n)))
    @test_throws(ErrorException,
                 @add_predicate(qc, "sum commute",
                                [n, x] -> n + x == x + n))

    ## Test that every type for which a `generate` method exists can
    ## be added to a `Quickcheck`.
    for type ∈ types_with_generate
        @eval begin
            qc = Quickcheck("dummy")
            @test @add_predicate(qc,
                                 string($type) * " true",
                                 x::$type -> true) isa Quickcheck
            @test isnothing(@quickcheck qc)
        end
    end
end
