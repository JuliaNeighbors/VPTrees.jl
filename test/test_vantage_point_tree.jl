using Test
using VPTrees
using Random
using StringDistances

function hamming(a::Integer, b::Integer)
    count_ones(xor(a, b))
end

@testset "VPTree.jl" begin
    @testset "find in radius" begin
        Random.seed!(1)
        data = [UInt(1), UInt(15)]
        metric = hamming
        vptree = VPTree(data, metric, Int)
        @test [1] == find(vptree, UInt(3), 1)
        @test Set([1, 2]) == Set(find(vptree, UInt(3), 2))
        data = [2,3,6]
        vptree = VPTree(data, hamming, Int);
        @test Set([d for d in data if (hamming(d, 2)) <= 1]) == Set(data[find(vptree, 2, 1)])
        data = collect(1:200)
        vptree = VPTree(data, hamming, Int);
        for f in data[find(vptree, 2, 4)]
            @test hamming(2, f) <= 4
        end
    end

    @testset "find n neighbors" begin
        Random.seed!(1)
        data = [UInt(1), UInt(15)]
        metric = hamming
        vptree = VPTree(data, metric, Int)
        @test [1] == find_nearest(vptree, UInt(3), 1)
        @test Set([1, 2]) == Set(find_nearest(vptree, UInt(3), 2))
        data = collect(1:7)
        vptree = VPTree(data, hamming, Int);
        find_nearest(vptree, 2, 2)
        [string(i, base=2) for i in data[find_nearest(vptree, 2, 2)]]
        for f in data[find_nearest(vptree, 2, 3)]
            @test hamming(2, f) <= 1
        end
    end

    @testset "quickselect" begin
        Random.seed!(1)
        a = [5,7,6,90,7,-1,3]
        k = 4
        distances = [abs(d + 5) for d in a]
        @test 6 == VPTrees.select!(a,k, distances)
        @test a[4] == 6
        for i in 1:length(a)
            a = [5,7,6,90,7,-1,3]
            distances = [abs(d + 5) for d in a]
            @test VPTrees.select!(a, i, distances) == a[i]
        end
    end

    @testset "euclidean distance" begin
        Random.seed!(1)
        data = [(1,2),(15,16)]
        metric = (a, b) -> sqrt(sum((a .- b).^2))
        vptree = VPTree(data, metric, Float64)
        @test [1] == find(vptree, (3,3), 3.)
        @test Set([1, 2]) == Set(find(vptree, (3,3), 100.))
        @test Set([(1,2)]) == Set(data[find_nearest(vptree, (2,2), 1)])
    end

    @testset "levenshtein distance" begin
        Random.seed!(1)
        data = ["bla", "blub", "asdf", ":assd", "ast", "baube"]
        metric = (a, b) -> evaluate(Levenshtein(),a,b)
        vptree = VPTree(data, metric, Int)
        query="blau"
        @test Set(["bla", "blub"]) == Set(data[find(vptree, query, 2)])
        @test Set(["bla", "blub", "baube"]) == Set(data[find_nearest(vptree, query, 3)])
    end
end

