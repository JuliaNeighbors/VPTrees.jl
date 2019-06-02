using BenchmarkTools
randints = [rand(UInt) for _ in 1:10000]
@benchmark VPTree(randints, hamming)
# BenchmarkTools.Trial: 
#   memory estimate:  30.77 MiB
#   allocs estimate:  57265
#   --------------
#   minimum time:     9.711 ms (13.30% GC)
#   median time:      11.121 ms (14.64% GC)
#   mean time:        11.427 ms (19.43% GC)
#   maximum time:     49.389 ms (76.76% GC)
#   --------------
#   samples:          437
#   evals/sample:     1
randints = [rand(UInt) for _ in 1:40000]
vp = VPTree(randints, hamming);
query = rand(UInt)
@benchmark find(vp, query, 20)
# BenchmarkTools.Trial: 
#   memory estimate:  144 bytes
#   allocs estimate:  3
#   --------------
#   minimum time:     15.126 μs (0.00% GC)
#   median time:      17.710 μs (0.00% GC)
#   mean time:        18.302 μs (0.00% GC)
#   maximum time:     95.950 μs (0.00% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1