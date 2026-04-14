## Adapted from Andreas Kröpelin's blog post:
## https://a5s.eu/blog/documenter-local-deploy

using Documenter

const pseudo_remote = abspath(@__DIR__() * "/.pseudo_remote")
if !isdir(pseudo_remote)
    mkdir(pseudo_remote)
    cd(pseudo_remote) do
        run(`$(Documenter.git()) init --bare`)
    end
end

struct LocalDeploy <: Documenter.DeployConfig end
Documenter.deploy_folder(::LocalDeploy; repo, branch, kwargs...) =
    Documenter.DeployDecision(; all_ok = true, branch, repo)
Documenter.authentication_method(::LocalDeploy) = Documenter.HTTPS
Documenter.authenticated_repo_url(::LocalDeploy) = pseudo_remote

deploydocs(;
    repo = pseudo_remote,
    branch = "master",
    devbranch = "master",
    deploy_config = LocalDeploy()
)

const deploy_dir = first(ARGS)
if isdir(deploy_dir)
    cd(deploy_dir) do
        run(`$(Documenter.git()) pull`)
    end
else
    run(`$(Documenter.git()) clone $pseudo_remote $deploy_dir`)
end
