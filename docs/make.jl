using JCheck

using Documenter

DocMeta.setdocmeta!(JCheck,
                    :DocTestSetup,
                    :(using JCheck),
                    recursive=true)

makedocs(sitename="JCheck.jl",
         doctest = true,
         modules = [JCheck])

deploydocs(
    repo = "github.com/ps-pat/JCheck.jl.git",
    devbranch = "main")
