set shell := ["nu", "-c"]

doc-host-location := x"${WEBSITE_LOCATION}/content/software/documentation/jcheck"

# Deploy documentation locally
doc-deploy:
    julia --project=docs docs/deploy.jl {{ doc-host-location }}

# Build documentation for current commit (set `mode` to `draft` to enable draft mode).
doc-make mode="":
    julia --project=docs --eval "import Pkg; Pkg.instantiate(); Pkg.precompile()"
    time julia --project=docs -- docs/make.jl {{ mode }}
