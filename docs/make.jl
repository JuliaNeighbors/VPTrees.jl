using VPTrees
using Documenter

makedocs(;
    modules=[VPTrees],
    authors="Alan Schelten <alan.schelten@mercateo.com> and contributors",
    repo="https://github.com/JuliaNeighbors/VPTrees.jl/blob/{commit}{path}#L{line}",
    sitename="VPTrees.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaNeighbors.github.io/VPTrees.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaNeighbors/VPTrees.jl",
)
