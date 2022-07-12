var documenterSearchIndex = {"docs":
[{"location":"reference/#Reference","page":"Reference","title":"Reference","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"CurrentModule = JCheck","category":"page"},{"location":"reference/#Quickcheck","page":"Reference","title":"Quickcheck","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"Quickcheck\nQuickcheck(::AbstractString)\n@add_predicate(::Any, ::Any, ::Any)\n@quickcheck(::Any, ::AbstractString)","category":"page"},{"location":"reference/#JCheck.Quickcheck","page":"Reference","title":"JCheck.Quickcheck","text":"Quickcheck\n\nContain a set of property to check through the generation of random input.\n\nFields\n\ndescription::AbstractString: description for the instance.\nrng::AbstractRNG: PRNG used to generate inputs.\npredicates::PredsAssoc: predicates to check.\nvariables::ArgsDict: Arguments used by the predicates.\nn::Int: Number of random inputs to generate.\nserialize_fails::Bool: If true, serialize failing inputs to a JLSO file.\n\n\n\n\n\n","category":"type"},{"location":"reference/#JCheck.Quickcheck-Tuple{AbstractString}","page":"Reference","title":"JCheck.Quickcheck","text":"Quickcheck(desc; rng=GLOBAL_RNG, n=100, serialize_fails=true)\n\nConstructor for type Quickcheck.\n\nArguments\n\ndesc::AbstractString: description for the instance.\nrng::AbstractRNG: PRNG used to generate inputs.\nn::Int: Number of random inputs to generate.\nserialize_fails::Bool: If true, serialize failing inputs to a JLSO file.\n\nExamples\n\njulia> qc = Quickcheck(\"A Test\")\nA Test: 0 predicate and 0 free variable.\n\n\n\n\n\n","category":"method"},{"location":"reference/#JCheck.@add_predicate-Tuple{Any, Any, Any}","page":"Reference","title":"JCheck.@add_predicate","text":"@add_predicate qc desc pred\n\nAdd the predicate pred to the set of tests qc with description desc.\n\nArguments\n\nqc: Object of type Quickcheck.\ndesc: String describing the predicate.\npred: Predicate in the form of an anonymous function.\n\nNotes\n\nThe form of pred is very strict:\n\nIt has to be an anonymous function. Formally, it should be an Expr of type ->.\nThe type of each argument appearing on the left-hand side of pred has to be specified with the x::Type syntax.\nThe names of the arguments of pred matter! Specifically, in a given Quickcheck object, the type of every argument must be consistent across predicates (see examples).\nEach predicate stored in a given Quickcheck object must be given a distinct description.\n\nExamples\n\njulia> qc = Quickcheck(\"A Test\")\nA Test: 0 predicate and 0 free variable.\n\njulia> @add_predicate qc \"Identity\" (x::Float64 -> x == x)\nA Test: 1 predicate and 1 free variable.\nx::Float64\n\njulia> @add_predicate qc \"Sum commute\" ((n::Int, x::Float64) -> n + x == x + n)\nA Test: 2 predicates and 2 free variables:\nn::Int64\nx::Float64\n\njulia> @add_predicate qc \"Is odd\" isodd(x)\nERROR: Predicate declaration must have the form of an anonymous function (... -> ...)\n[...]\n\njulia> @add_predicate qc \"Is odd\" (x::Int -> is_odd(x))\nERROR: A declaration for variable x already exists with type Float64; please choose another name for x\n[...]\n\n\n\n\n\n","category":"macro"},{"location":"reference/#JCheck.@quickcheck-Tuple{Any, AbstractString}","page":"Reference","title":"JCheck.@quickcheck","text":"@quickcheck qc [file_id::AbstractString=\"yyyy-mm-dd_HH-MM-SS\"]\n\nCheck the properties specified in object qc of type Quickcheck.\n\nIf qc.serialize_fails is true, serialize the failing cases to JCheck_<file_id>.jchk. Those can latter be analyzed using load and @getcases.\n\nNote\n\nIf no argument file_id is passed, defaults to current time.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Failed-Cases-Analysis","page":"Reference","title":"Failed Cases Analysis","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"FailedTests\nload(::Union{IO, AbstractString, AbstractPath})\n@getcases(::Any, ::Any...)","category":"page"},{"location":"reference/#JCheck.FailedTests","page":"Reference","title":"JCheck.FailedTests","text":"FailedTests\n\nContainer for failed tests from a @quickcheck run. Wrapper around a Dict{Symbol, Any} used for dispatch.\n\n\n\n\n\n","category":"type"},{"location":"reference/#JCheck.load-Tuple{Union{AbstractString, IO, FilePathsBase.AbstractPath}}","page":"Reference","title":"JCheck.load","text":"load(io)\n\nLoad a collection of failed test cases serialized by a @quickcheck run.  Argument io can be of type IO, AbstractString or AbstractPath.\n\nExamples\n\njulia> ft = JCheck.load(\"JCheck_test.jchk\")\n2 failing predicates:\nProduct commute\nIs odd\n\n\n\n\n\n","category":"method"},{"location":"reference/#JCheck.@getcases-Tuple{Any, Vararg{Any}}","page":"Reference","title":"JCheck.@getcases","text":"@getcases ft, desc...\n\nGet the predicate with description desc and the valuations for which it failed.\n\nNote\n\nThe predicate with description closest to the one given (in the sense of the Levenshtein distance) will be returned; there is no need to pass the exact description.\n\nExamples\n\njulia> ft = JCheck.load(\"JCheck_test.jchk\")\n2 failing predicates:\nProduct commute\nIs odd\n\njulia> pred, valuations = @getcases ft iod\nNamedTuple{(:predicate, :valuations), Tuple{Function, Vector{Tuple}}}((Serialization.__deserialized_types__.var\"#3#4\"(), Tuple[(0,), (-9223372036854775808,), (6444904272543528628,)]))\n\njulia> map(x -> pred(x...), valuations)\n3-element Vector{Bool}:\n 0\n 0\n 0\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Random-Input-Generation","page":"Reference","title":"Random Input Generation","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"generate\nspecialcases(::Type)","category":"page"},{"location":"reference/#JCheck.generate","page":"Reference","title":"JCheck.generate","text":"generate([rng=GLOBAL_RNG], T, n)\n\nSample n random instances of type T.\n\nArguments\n\nrng::AbstractRNG: random number generator to use.\nT::Type: type of the instances.\nn::Int: number of realizations to sample.\n\nDefault generators\n\ngenerate methods for the following types are shipped with this package:\n\nSubtypes of AbstractFloat\nSubtypes of Integer except BigInt\nComplex{T <: Real}\nString\nChar\nArray{T, N}\nBitArray{N}\nSquareMatrix{T}.\nAny special matrix implemented by Julia's LinearAlgebra module.\nUnion{T...}\nUnitRange{T}, StepRange{T, T}\n\nIn the previous list, T represent any type for which a generate method is implemented.\n\nSpecial Matrices (LinearAlgebra)\n\nGenerators are implemented for <...>Triangular{T} as well as <...>Triangular{T, S}. In the first case, S default to SquareMatrix{T}. The exact same thing is true for UpperHessenberg.\nSame idea for <...>diagonal{T, V} with V defaulting to Vector{T}.\nGenerators are only implemented for Symmetric{T, S} and Hermitian{T, S} right now. Most of the time, you will want to specify S = SquareMatrix{T}.\n\nArrays & Strings\n\nGeneral purpose generators for arrays and strings are a little bit tricky to implement given that a length for each sampled element must be specified. The following choices have been made for the default generators shipped with this package:\n\nString: The length of each string is approximately exponentially distributed with mean 64.\nArray{T, N}: The length of each dimension of a given array is approximately exponentially distributed with mean 24 ÷ N + 1 (in a low effort attempt to keep the number of entries manageable).\n\nIf this is not appropriate for your needs, don't hesitate to reimplement generate.\n\nImplementation\n\nWhen implementing generate for your type T keep the following in mind:\n\nYour method should return a Vector{T}\nIt is not necessary to write generate(T, n) or generate([rng, ]Array{T, N}, n) where N; this is handled automatically. You only need to implement generate(::AbstractRNG, ::Type{T}, ::Int)\nConsider implementing specialcases and shrink for T as well.\n\nExamples\n\nusing Random: Xoshiro\n\nrng = Xoshiro(42)\n\ngenerate(rng, Float32, 10)\n\n# output\n\n10-element Vector{Float32}:\n -1.5388016f7\n -5.3113024f-19\n -1.3960648f35\n  1.5957566f31\n -4.381218f26\n  2.380078f35\n  3.878954f9\n -1.1950524f-7\n  7.525897f24\n -3.1891005f-12\n\n\n\n\n\n","category":"function"},{"location":"reference/#JCheck.specialcases-Tuple{Type}","page":"Reference","title":"JCheck.specialcases","text":"specialcases(T)\n\nNon-random inputs that are always checked by @quickcheck.\n\nArguments\n\nT::Type: type of the inputs.\n\nImplementation\n\nYour method should return a Vector{T}\nUseless without a generate method for T.\nBe mindful of combinatoric explosion! @quickcheck generate an input for each element of the Cartesian product of the special cases of every arguments of the predicates it is trying to falsify. Only include special cases that are truly special.\n\nExamples\n\njulia> specialcases(Int)\n4-element Vector{Int64}:\n                    0\n                    1\n -9223372036854775808\n  9223372036854775807\n\njulia> specialcases(Float64)\n4-element Vector{Float64}:\n   0.0\n   1.0\n -Inf\n  Inf\n\n\n\n\n\n","category":"method"},{"location":"reference/#Shrinkage","page":"Reference","title":"Shrinkage","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"shrink(::Any)\nshrinkable(::Any)","category":"page"},{"location":"reference/#JCheck.shrink-Tuple{Any}","page":"Reference","title":"JCheck.shrink","text":"shrink(x)\n\nShrink an input. The returned value is a Vector with elements similar to x. Returning a vector of length 1 is interpreted as meaning that no further shrinkage is possible.\n\nDefault Shrinkers\n\nshrink methods for the following types are shipped with this package:\n\nAbstractString\nAbstractArray{T, N} for any T and N\n\nImplementation\n\nAny implementation of shrink(x::T) must come with an implementation of shrinkable(x::T). Failure to do so will prevent @quickcheck from calling shrink on an object of type T.\nshrink(x) must return [x] if shrinkable(x) evaluate to false. We suggest that the first line of your method is something like:\nshrinkable(x) || return typeof(x)[x]\n\n\n\n\n\n","category":"method"},{"location":"reference/#JCheck.shrinkable-Tuple{Any}","page":"Reference","title":"JCheck.shrinkable","text":"shrinkable(x)\n\nDetermines if x is shrinkable.\n\nNote\n\nShrinkage can easily be disabled for type T using overloading:\n\nshrinkable(x::T) = false\n\n\n\n\n\n","category":"method"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = JCheck","category":"page"},{"location":"#JCheck.jl-Documentation","page":"Home","title":"JCheck.jl Documentation","text":"","category":"section"},{"location":"#What-is-JCheck.jl?","page":"Home","title":"What is JCheck.jl?","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"JCheck is a test framework for the Julia programming language. It aims imitating the one and only Quickcheck. The user specifies a set of properties in the form of predicates. JCheck then tries to falsifies these predicates. Since it is in general impossible to evaluate a predicate for every possible input, JCheck (as does QuickCheck) employs a Monte Carlo approach: it samples a set of inputs at random and pass them as arguments to the predicates. In order to make analysis of problematic cases more convenient, those can be serialized in a JLSO file for further experimentation.","category":"page"},{"location":"#Features","page":"Home","title":"Features","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Reuse inputs to cut into the time dedicated to cases generation.\nSerialization of problematic cases for convenient analysis.\nIntegration with Julia's testing framework.\nAllow specification of \"special cases\" i.e. non-random inputs that are always checked.\nShrinkage of failing test cases.","category":"page"},{"location":"#Usage","page":"Home","title":"Usage","text":"","category":"section"},{"location":"#Container","page":"Home","title":"Container","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"In order for them to be used in a test, predicates must be contained in a Quickcheck object. Those are fairly easy to create. The most basic way is to call the constructor with a short and simple description:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Test:\n    @testset,\n    @test\n\nusing JCheck","category":"page"},{"location":"","page":"Home","title":"Home","text":"qc = Quickcheck(\"A Test\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"For more advanced usages, see documentation of the Quickcheck constructor.","category":"page"},{"location":"#Adding-predicates","page":"Home","title":"Adding predicates","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Once a Quickcheck object has been created, the next step is to populate it with predicates. This can be done with the @add_predicate macro:","category":"page"},{"location":"","page":"Home","title":"Home","text":"@add_predicate qc \"Sum commute\" ((x::Float64, n::Int) -> x + n == n + x)","category":"page"},{"location":"","page":"Home","title":"Home","text":"A predicate is a function that returns either true or false. In the context of JCheck the form of the predicate is very strict; please read the documentation of @add_predicate.","category":"page"},{"location":"#(Quick)checking","page":"Home","title":"(Quick)checking","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The macro @quickcheck launches the process of looking for falsifying instances in a Quickcheck object.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@quickcheck qc\n\nTest Summary:    | Pass  Total\nTest Sum commute |    1      1","category":"page"},{"location":"#As-part-of-a-[@testset](https://docs.julialang.org/en/v1/stdlib/Test/#Test.@testset)","page":"Home","title":"As part of a @testset","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The @quickcheck macro can be nested inside @testset. This allows easy integration to a package's set of tests.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@testset \"Sample test set\" begin\n    @test isempty([])\n\n    @quickcheck qc\nend\n\nTest Summary:   | Pass  Total\nSample test set |    2      2","category":"page"},{"location":"","page":"Home","title":"Home","text":"Let's add a failing predicate.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@add_predicate qc \"I fail\" (x::Float64 -> false)\n\n@testset \"Sample failing test set\" begin\n    @test isempty([])\n\n    @quickcheck qc\nend\n\n┌ Warning: Predicate \"I fail\" does not hold for valuation (x = 0.0,)\n└ @ JCheck ~/Projets/JCheck/src/Quickcheck.jl:267\n┌ Warning: Predicate \"I fail\" does not hold for valuation (x = 1.0,)\n└ @ JCheck ~/Projets/JCheck/src/Quickcheck.jl:267\n\n[...]\n\nSome predicates do not hold for some valuations; they have been saved\nto JCheck_yyyy-mm-dd_HH-MM-SS.jchk. Use function load and macro @getcases\nto explore problematic cases.\n\nTest Summary:           | Pass  Fail  Total\nSample failing test set |    2     1      3\n  Test Sum commute      |    1            1\n  Test I fail           |          1      1\nERROR: Some tests did not pass: 2 passed, 1 failed, 0 errored, 0 broken.","category":"page"},{"location":"#Analysing-failing-cases","page":"Home","title":"Analysing failing cases","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"By default, failing test cases are serialized to a JLSO file so they can easily be analyzed.","category":"page"},{"location":"","page":"Home","title":"Home","text":"ft = JCheck.load(\"JCheck_test.jchk\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"Failing cases for a predicate can be extracted by using its description with @getcases. There is no need to give the exact description of the predicate you want to extract; the entry with description closest to the one given (in the sense of the Levenshtein distance) will be matched.","category":"page"},{"location":"","page":"Home","title":"Home","text":"pred, valuations = @getcases ft i od\n\n## Each element of `valuations` is a tuple.\nmap(x -> pred(x...), valuations)","category":"page"},{"location":"#Types-with-built-in-generators","page":"Home","title":"Types with built-in generators","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"For a list of types for which a generator is included in the package, see reference for generate.","category":"page"},{"location":"#Testing-With-Custom-Types","page":"Home","title":"Testing With Custom Types","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"JCheck can easily be extended to work with custom type from which it is possible to randomly sample instances. The only requirement is to overload generate. For instance, an implementation for type Int64 could look like this:","category":"page"},{"location":"","page":"Home","title":"Home","text":"import JCheck: generate\nusing Random: AbstractRNG\n\ngenerate(rng::AbstractRNG, ::Type{Int64}, n::Int) =\n    rand(rng, Int64, n)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Optionally, it is possible to specify so called \"special cases\" for a type. Those are always checked. Doing so is as easy as overloading specialcases. For Int, this could look like this:","category":"page"},{"location":"","page":"Home","title":"Home","text":"import JCheck: specialcases\n\nspecialcases(::Type{Int64}) =\n    Int64[0, 1, typemin(Int64), typemax(Int64)]","category":"page"},{"location":"","page":"Home","title":"Home","text":"For implementation details, see documentation of these two functions.","category":"page"},{"location":"#Shrinkage","page":"Home","title":"Shrinkage","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@quickcheck will try to shrink any failing test case if possible. In order to enable shrinkage for a given type, the following two methods must be implemented:","category":"page"},{"location":"","page":"Home","title":"Home","text":"shrinkable\nshrink","category":"page"},{"location":"","page":"Home","title":"Home","text":"The first one is a predicate evaluating to true for an object if it can be shrinked. The second one is a function returning a Vector of shrunk objects. The implementation for type Abstractstring is the following:","category":"page"},{"location":"","page":"Home","title":"Home","text":"shrinkable(x::AbstractString) = length(x) >= 2\n\nfunction shrink(x::AbstractString)\n    shrinkable(x) || return typeof(x)[x]\n\n    n = length(x) ÷ 2\n    [x[1:n], x[range(n + 1, end)]]\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"For more details and a list of default shrinkers, see the documentation of these methods.","category":"page"}]
}
