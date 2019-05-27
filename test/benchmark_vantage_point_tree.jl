using BenchmarkTools
randints = [rand(UInt) for _ in 1:10000]
@benchmark VPTree(randints, hamming)
vp = VPTree(randints, hamming);
query = rand(UInt)
@benchmark find(vp, query, 20)
