using Test
using VantagePointTree

@testset "VPTree.jl" begin
    data = [UInt(1), UInt(15)]
    metric = hamming
    vptree = VPTree(data, metric)
    @test [1] == find(vptree, UInt(3), 1)
    @test [1, 2] == find(vptree, UInt(3), 2)
    data = collect(1:200)
    vptree = VPTree(data, hamming);
    @test [2, 3, 6] == find(vptree, 2, 1)
    @test [8, 9, 10, 12, 24] == find(vptree, 8, 1)
end

