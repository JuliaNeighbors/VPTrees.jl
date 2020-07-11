"""
Hamming distance between two bit strings (as integers)
"""
function hamming(a::Integer, b::Integer)
    count_ones(xor(a, b))
end

"""
Euclidean distance between two vectors.
"""
euclidean(x, y) = sqrt(sum((x .- y).^2))


"""
Brute-force implementation of find().
"""
function find_bruteforce(data, metric, query, radius)
    return findall(d -> metric(query, d) <= radius, data)
end

"""
Brute-force implementation of find().

Note - correct answer is only unambiguous if all distances are distinct
(otherwise there may be a tie in choosing k-th closest data point)."""
function find_nearest_bruteforce(data, metric, query, k)
    dists = [metric(query, d) for d in data]
    idxs = sortperm(dists)
    return idxs[1:min(k, length(data))]
end

"""
Brute-force implementation of find(), but return ties for k-th nearest-neighbor
as separate set of results.
"""
function find_nearest_bruteforce_ties(data, metric, query, k)
    k = min(k, length(data))

    dists = [metric(query, d) for d in data]
    idxs = sortperm(dists)

    maxd = dists[idxs[k]]

    kmin = k
    while kmin > 1 && dists[idxs[kmin - 1]] == maxd
        kmin -= 1
    end

    kmax = k
    while kmax < length(data) && dists[idxs[kmax + 1]] == maxd
        kmax += 1
    end

    return idxs[1:(kmin-1)], idxs[kmin:kmax]
end

"""
Test that find() gives identical results to find_bruteforce().
"""
function test_find(vptree, query, radius)
    result = find(vptree, query, radius)
    bfresult = find_bruteforce(vptree.data, vptree.metric, query, radius)
    @test issetequal(result, bfresult)
end

"""
Test that find_nearest() gives identical results to find_nearest_bruteforce().

This accounts for cases in which there is a tie for the k-th closest point.
"""
function test_find_nearest(vptree, query, k)
    result = find_nearest(vptree, query, k)

    knn1, knn_ties = find_nearest_bruteforce_ties(vptree.data, vptree.metric, query, k)

    @test length(result) == min(k, length(vptree.data))
    @test knn1 ⊆ result
    @test setdiff(result, knn1) ⊆ knn_ties
end


@testset "Tie for kth-nearest-neighbor" begin
    Random.seed!(1)

    metric = hamming
    query = 0b0001
    data = 0b0000:0b1111
    data = [
        # 4 @ D=1
        0b0000,
        0b0011,
        0b0101,
        0b1001,
        # 6 @ D=2
        0b0010,
        0b0100,
        0b1000,
        0b1101,
        0b1011,
        0b0111,
        # 4 @ D=3
        0b1100,
        0b1010,
        0b0110,
        0b1111,
        # 1 @ D=4
        0b1110,
    ]
    vptree = VPTree(data, metric)

    # KNN can include any two data points @ D=2
    k = 6

    knn1, knn_ties = find_nearest_bruteforce_ties(data, metric, query, k)
    @test issetequal(knn1, 1:4)
    @test issetequal(knn_ties, 5:10)

    test_find_nearest(vptree, query, k)
end

@testset "Hamming distance" begin
    Random.seed!(1)

    metric = hamming
    data = UInt8.(0:255)
    vptree = VPTree(data, metric)

    queries = UInt8[0, 1, 15, 107, 255]
    k = 10
    r = 2

    for query in queries
        test_find(vptree, query, r)
        test_find_nearest(vptree, query, k)
    end
end

@testset "Euclidean distance" begin
    Random.seed!(1)

    metric = euclidean
    data = [rand(2) for _ in 1:1000]
    vptree = VPTree(data, metric)

    queries = [rand(2) for _ in 1:10]
    k = 20
    r = .25

    for query in queries
        test_find(vptree, query, r)
        test_find_nearest(vptree, query, k)
    end
end

@testset "Levenshtein distance" begin
    Random.seed!(1)

    metric = Levenshtein()
    data = [randstring(rand(3:5)) for _ in 1:100]
    vptree = VPTree(data, metric)

    queries = ["bla", "blub", "asdf", ":assd", "ast", "baube"]
    k = 10
    r = 3

    for query in queries
        test_find(vptree, query, r)
        test_find_nearest(vptree, query, k)
    end
end

@testset "Construct threaded and unthreaded" begin
    Random.seed!(1)

    data = [UInt(1), UInt(15)]
    metric = hamming

    vptree = VPTree(data, metric; threaded=true)
    @test [1] == find(vptree, UInt(3), 1)
    @test issetequal([1, 2], find(vptree, UInt(3), 2))

    vptree = VPTree(data, metric; threaded=false)
    @test [1] == find(vptree, UInt(3), 1)
    @test issetequal([1, 2], find(vptree, UInt(3), 2))
end

@testset "Construct invalid" begin
    Random.seed!(1)

    # Empty data set
    @test_throws AssertionError VPTree(Vector{Float64}[], euclidean)

    # Non-callable
    @test_throws AssertionError VPTree([1.], 1)

    # No method for metric with data type
    @test_throws MethodError VPTree(["foo"], euclidean)
    @test_throws MethodError VPTree(["foo"], hamming)
end
