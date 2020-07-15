using Documenter, SkillRating

makedocs(;
    modules=[SkillRating],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/altre/VPTrees.jl/blob/{commit}{path}#L{line}",
    sitename="VPTrees.jl",
    authors="Alan Schelten",
    assets=String[],
)

deploydocs(;
    repo="github.com/altre/VPTrees.jl",
)
