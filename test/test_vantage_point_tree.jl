"""
Check if should skip data point i, for skip arg which may be `nothing`.
"""
shouldskip(skip, i) = !isnothing(skip) && skip(i)

# Filter array by predicate on indices
skipindices!(skip, a) = deleteat!(a, findall(skip, axes(a, 1)))
skipindices!(skip::Nothing, a) = a

skipindices(skip, a) = [x for (i, x) in enumerate(a) if !skip(i)]
skipindices(skip::Nothing, a) = a

# Filter array by predicate on values
skipvalues(skip, a) = filter(i -> !skip(i), a)
skipvalues(skip::Nothing, a) = a

skipvalues!(skip, a) = filter!(i -> !skip(i), a)
skipvalues!(skip::Nothing, a) = a


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
function find_bruteforce(data, metric, query, radius, skip=nothing)
    return [i for (i, d) in enumerate(data) if !shouldskip(skip, i) && metric(query, d) <= radius]
end

"""
Brute-force implementation of find().

Note - correct answer is only unambiguous if all distances are distinct
(otherwise there may be a tie in choosing k-th closest data point)."""
function find_nearest_bruteforce(data, metric, query, k, skip=nothing)
    dists = [metric(query, d) for d in data]
    idxs = skipindices!(skip, sortperm(dists))
    return idxs[1:min(k, end)]
end

"""
Brute-force implementation of find(), but return ties for k-th nearest-neighbor
as separate set of results.
"""
function find_nearest_bruteforce_ties(data, metric, query, k, skip=nothing)
    dists = [metric(query, d) for d in data]
    idxs = skipvalues!(skip, sortperm(dists))
    k = min(k, length(idxs))

    maxd = dists[idxs[k]]

    kmin = k
    while kmin > 1 && dists[idxs[kmin - 1]] == maxd
        kmin -= 1
    end

    kmax = k
    while kmax < length(idxs) && dists[idxs[kmax + 1]] == maxd
        kmax += 1
    end

    return idxs[1:(kmin-1)], idxs[kmin:kmax]
end

"""
Test that find() gives identical results to find_bruteforce().
"""
function test_find(vptree, query, radius, skip=nothing)
    result = find(vptree, query, radius, skip)
    bfresult = find_bruteforce(vptree.data, vptree.metric, query, radius, skip)
    @test issetequal(result, bfresult)
end

"""
Test that find_nearest() gives identical results to find_nearest_bruteforce().

This accounts for cases in which there is a tie for the k-th closest point.
"""
function test_find_nearest(vptree, query, k, skip=nothing)
    result = find_nearest(vptree, query, k, skip)

    nearest, ties = find_nearest_bruteforce_ties(vptree.data, vptree.metric, query, k, skip)

    @test length(result) == min(k, length(vptree.data))
    @test nearest ⊆ result
    @test setdiff(result, nearest) ⊆ ties
end


# Skip every 3rd data point
skip3(i) = i % 3 == 0


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

    nearest, ties = find_nearest_bruteforce_ties(data, metric, query, k)
    @test issetequal(nearest, 1:4)
    @test issetequal(ties, 5:10)

    test_find_nearest(vptree, query, k)

    # With skip arg
    # This skips 1 of the D=1 and two of the D=2, so D=2 is still the tied value
    # with k=6.
    # So, sets should be the same as before just with skipped indices filtered out.
    skip = skip3
    nearest_s, ties_s = find_nearest_bruteforce_ties(data, metric, query, k, skip)
    @test issetequal(nearest_s, skipvalues(skip, nearest))
    # @test issetequal(ties_s, skipindices(skip, ties))
    @test Set(ties_s) == Set(skipvalues(skip, ties))
    test_find_nearest(vptree, query, k, skip)
end

@testset "Hamming distance" begin
    Random.seed!(1)

    metric = hamming
    data = collect(0x0000:0xFFFF)

    queries = [0x0000, 0x0001, 0x4eaf, 0xa44a, 0xFFFF]
    k = 50
    r = 5

    for threaded in [false, true]
        vptree = VPTree(data, metric, threaded=threaded)

        for query in queries
            for skip in [nothing, skip3]
                test_find(vptree, query, r, skip)
                test_find_nearest(vptree, query, k, skip)
            end
        end
    end
end

@testset "Euclidean distance" begin
    Random.seed!(1)

    metric = euclidean
    data = [rand(2) for _ in 1:10000]

    queries = [rand(2) for _ in 1:10]
    k = 50
    r = .25

    for threaded in [false, true]
        vptree = VPTree(data, metric)

        for query in queries
            for skip in [nothing, skip3]
                test_find(vptree, query, r, skip)
                test_find_nearest(vptree, query, k, skip)
            end
        end
    end
end

@testset "Levenshtein distance" begin
    Random.seed!(1)

    queries = ["bla", "blub", "asdf", ":assd", "ast", "baube"]
    alphabet = union(queries..., "xyz")

    metric = Levenshtein()
    data = unique(randstring(alphabet, rand(3:5)) for _ in 1:10000)

    k = 10
    r = 3

    for threaded in [false, true]
        vptree = VPTree(data, metric)

        for query in queries
            for skip in [nothing, skip3]
                test_find(vptree, query, r, skip)
                test_find_nearest(vptree, query, k, skip)
            end
        end
    end
end

@testset "Construct invalid" begin

    # Empty data set
    @test_throws AssertionError VPTree(Vector{Float64}[], euclidean)

    # Non-callable
    @test_throws AssertionError VPTree([1.], 1)

    # No method for metric with data type
    @test_throws MethodError VPTree(["foo"], euclidean)
    @test_throws MethodError VPTree(["foo"], hamming)
end
