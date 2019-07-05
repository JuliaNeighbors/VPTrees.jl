using BenchmarkTools
using Random
using VPTrees

Random.seed!(1)
function hamming(a::Integer, b::Integer)
    count_ones(xor(a, b))
end
randints = [rand(UInt) for _ in 1:10000]
@benchmark VPTree(randints, hamming)
# BenchmarkTools.Trial: 
#   memory estimate:  36.16 MiB
#   allocs estimate:  96189
#   --------------
#   minimum time:     14.749 ms (10.84% GC)
#   median time:      17.335 ms (21.43% GC)
#   mean time:        17.348 ms (20.07% GC)
#   maximum time:     63.897 ms (73.87% GC)
#   --------------
#   samples:          288
#   evals/sample:     1
randints = [rand(UInt) for _ in 1:40000]
vptree = VPTree(randints, hamming);
query = rand(UInt)
radius = 20
@benchmark find(vptree, query, radius)

# BenchmarkTools.Trial: 
#   memory estimate:  2.22 KiB
#   allocs estimate:  8
#   --------------
#   minimum time:     230.819 μs (0.00% GC)
#   median time:      253.774 μs (0.00% GC)
#   mean time:        276.296 μs (0.40% GC)
#   maximum time:     11.471 ms (97.37% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1
@benchmark find_nearest(vptree, query, 20)
# BenchmarkTools.Trial: 
#   memory estimate:  1.38 KiB
#   allocs estimate:  9
#   --------------
#   minimum time:     321.168 μs (0.00% GC)
#   median time:      343.786 μs (0.00% GC)
#   mean time:        360.818 μs (0.00% GC)
#   maximum time:     1.245 ms (0.00% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1

using StringDistances
using Statistics

metric(a::AbstractString, b::AbstractString) = evaluate(Levenshtein(), a,b)
prefixes = readlines("resources/benchmark_data.csv")

Random.seed!(2)
t = VPTree(prefixes, metric)
rng = Random.MersenneTwister(1)
@benchmark find(t, prefixes[rand(rng, 1:length(prefixes))], 2)
rng = Random.MersenneTwister(1)
@benchmark findall(a -> metric(prefixes[rand(rng, 1:length(prefixes))], a) <= 2, prefixes)