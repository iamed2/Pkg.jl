function create(path::String)
    dir, pkg = dirname(path), basename(path)
    isdir(path) && cmderror("$(abspath(path)) already exists")
    project(pkg, dir)
    entrypoint(pkg, dir)
    LibGit2.init(path)
    repo = LibGit2.GitRepo(path)
    LibGit2.add!(repo, "*")
    @info "Committing generated files"
    LibGit2.commit(repo, "created project $pkg")
end

function genfile(f::Function, pkg::String, dir::String, file::String)
    path = joinpath(dir, pkg, file)
    @info "Generating $path"
    mkpath(dirname(path))
    open(f, path, "w")
    return
end

function project(pkg::String, dir::String)
    name = email = nothing
    gitname = LibGit2.getconfig("user.name", "")
    isempty(gitname) || (name = gitname)
    gitmail = LibGit2.getconfig("user.email", "")
    isempty(gitmail) || (email = gitmail)

    if name == nothing
        for env in ["GIT_AUTHOR_NAME", "GIT_COMMITTER_NAME", "USER", "USERNAME", "NAME"]
            name = get(ENV, env, nothing)
            name != nothing && break
        end
    end

    if name == nothing
        cmderror("could not determine user, please set ", Sys.iswindows ? "USERNAME" : "USER",
                 " environment variable")
    end

    if email == nothing
        for env in ["GIT_AUTHOR_EMAIL", "GIT_COMMITTER_EMAIL", "EMAIL"];
            email = get(ENV, env, nothing)
            email != nothing && break
        end
    end

    authorstr = "[\"$name " * (email == nothing ? "" : "<$email>") * "\"]"

    genfile(pkg, dir, "Project.toml") do io
        print(io,
            """
            name = "$pkg"
            uuid = "$(UUIDs.uuid1())"
            version = "0.1.0"
            author = $authorstr

            [deps]
            """
        )
    end
end

function entrypoint(pkg::String, dir)
    genfile(pkg, dir, "src/$pkg.jl") do io
        print(io,
           """
            module $pkg

            greet() = print("Hello World!")

            end # module
            """
        )
    end
end
