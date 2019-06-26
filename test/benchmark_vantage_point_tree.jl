using BenchmarkTools
using Random
# using VPTrees

Random.seed!(1)
randints = [rand(UInt) for _ in 1:10000]
@benchmark VPTree(randints, hamming, Int)
# BenchmarkTools.Trial: 
#   memory estimate:  36.07 MiB
#   allocs estimate:  83368
#   --------------
#   minimum time:     11.573 ms (11.58% GC)
#   median time:      14.957 ms (30.30% GC)
#   mean time:        14.883 ms (28.10% GC)
#   maximum time:     71.537 ms (81.26% GC)
#   --------------
#   samples:          336
#   evals/sample:     1
randints = [rand(UInt) for _ in 1:40000]
vptree = VPTree(randints, hamming, Int);
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
#   minimum time:     342.551 μs (0.00% GC)
#   median time:      371.987 μs (0.00% GC)
#   mean time:        413.776 μs (0.00% GC)
#   maximum time:     1.425 ms (0.00% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1