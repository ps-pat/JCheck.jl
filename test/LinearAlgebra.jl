reduce_length(x) = all(<=(length(x)), length.(shrink(x)))

@testset "LinearAlgebra.jl" begin
    qc = Quickcheck("LinearAlgebra")

    ## TODO: Merge with loop under when type can be partially specified.
    for (type, args) ∈ (:Symmetric => (:mat_sym, :Int),
                        :Hermitian => (:mat_herm, :ComplexF64))
        varname = first(args)
        etype = last(args)

        @eval begin
            @add_predicate($qc,
                           "Reduce `" * string($type) * "` length",
                           $varname::$type{$etype, SquareMatrix{$etype}} ->
                               reduce_length($varname))
        end
    end

    for (type, varname) ∈ (:UpperTriangular => :mat_ut,
                           :UnitUpperTriangular => :mat_uut,
                           :LowerTriangular => :mat_lt,
                           :UnitLowerTriangular => :mat_llt,
                           :UpperHessenberg => :mat_uh,
                           :Diagonal => :mat_diag,
                           :Bidiagonal => :mat_bidiag,
                           :SymTridiagonal => :mat_symtridiag,
                           :Tridiagonal => :mat_tridiag)
        @eval begin
            @add_predicate($qc,
                           "Reduce `" * string($type) * "` length",
                           $varname::$type{Int} -> reduce_length($varname))
        end
    end
    
    @quickcheck qc
end
