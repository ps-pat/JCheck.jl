using JCheck

using Documenter

using Git: git

## Determine which version we are building documentation for
current_version = try
    gitout = (read ∘ git)(["describe", "--tags", "--abbrev=0", "--exact-match"])
    version = mapreduce(Char, *, gitout[1:end - 1])
    match(r"v[0-9]+\.[0-9]+\.[0-9]+", version).match
catch
    "dev"
end
@info "Building for version $current_version"

writter = Documenter.HTMLWriter.HTML(
    canonical = "https://patrickfournier.ca/software/documentation/jcheck/stable",
    edit_link = "master",
    size_threshold_warn = 200 * 1024,
    size_threshold = nothing
)

makedocs(
    build="build/$current_version",
    draft="draft" ∈ ARGS,
    sitename="JCheck.jl",
    format=Documenter.HTML(; collapselevel=1),
    doctest=true,
    repo=Remotes.GitHub("ps-pat", "JCheck.jl"),
    modules=[JCheck],
    pages=[
        "Home" => "index.md",
        "Reference" => "reference.md"
    ]
)
