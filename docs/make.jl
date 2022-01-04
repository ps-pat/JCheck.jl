using JCheck

using Documenter

DocMeta.setdocmeta!(JCheck,
                    :DocTestSetup,
                    :(using JCheck),
                    recursive=true)

makedocs(sitename="JCheck.jl",
         doctest = true,
         modules = [JCheck],
         pages = ["Home" => "index.md",
                  "Reference" => "reference.md"])

deploydocs(
    repo = "github.com/ps-pat/JCheck.jl.git",
    devbranch = "main")
