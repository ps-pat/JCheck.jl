@testset "generate & specialcases methods" begin
    for type ∈ types_with_generate
        @test length(generate(type, 100)) == 100
        @test !isempty(specialcases(type))
    end

    @test isempty(specialcases(Any))
end
