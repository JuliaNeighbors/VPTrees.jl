using StringDistances
using DataFrames
using FeatherFiles

function normalized_levenshtein_metric(x::String,y::String)::Float64
    gld = evaluate(Levenshtein(), x, y)
    2 * gld/(length(x) + length(y) + gld)
end

df = FeatherFiles.load("/Users/alanschelten/code/man/articles.feather") |> DataFrame
sm = df[1:1000000,:name]
@time VPTree(sm, normalized_levenshtein_metric)

sm[find_nearest(t, "Scherenröllchenbahn", 10)]