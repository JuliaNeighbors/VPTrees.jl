using BenchmarkTools
using Random
using VPTrees

Random.seed!(1)
randints = [rand(UInt) for _ in 1:10000]
@benchmark VPTree(randints, hamming)
# BenchmarkTools.Trial: 
#   memory estimate:  35.86 MiB
#   allocs estimate:  76700
#   --------------
#   minimum time:     10.176 ms (10.80% GC)
#   median time:      12.889 ms (25.68% GC)
#   mean time:        12.748 ms (23.92% GC)
#   maximum time:     56.511 ms (79.30% GC)
#   --------------
#   samples:          392
#   evals/sample:     1
randints = [rand(UInt) for _ in 1:40000]
vptree = VPTree(randints, hamming);
query = rand(UInt)
@benchmark find(vptree, query, 20)
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