using Test
using VPTrees

@testset "VPTree.jl" begin
    @testset "fnd in radius" begin
        data = [UInt(1), UInt(15)]
        metric = hamming
        vptree = VPTree(data, metric)
        @test [1] == find(vptree, UInt(3), 1)
        @test Set([1, 2]) == Set(find(vptree, UInt(3), 2))
        data = collect(1:200)
        vptree = VPTree(data, hamming);
        for f in data[find(vptree, 2, 4)]
            @test hamming(2, f) <= 4
        end
    end

    @testset "quickselect" begin
        a = [5,7,6,90,7,-1,3]
        k = 4
        comp = (a,b) -> a < b ? -1 : a > b ? 1 : 0
        @test 6 == select!(a,k, comp)
        @test a[4] == 6
        for i in 1:length(a)
            @test select!(a, i, comp) == a[i]
        end
    end
end

