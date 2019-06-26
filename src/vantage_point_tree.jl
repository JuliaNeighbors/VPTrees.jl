import Base.show
import DataStructures

struct Node{InputType, MetricReturnType}
    index::Int
    data::InputType
    radius::MetricReturnType
    min_dist::MetricReturnType
    max_dist::MetricReturnType
    left_child::Union{Node{InputType, MetricReturnType}, Nothing}
    right_child::Union{Node{InputType, MetricReturnType}, Nothing}
end

function Base.show(io::IO, n::Node)
    print("Node $(typeof(n).parameters[1]): $(n.data), index $(n.index) radius $(n.radius), depth $(_depth(n))")
end

function _depth(n)
    if n == nothing 
        0
    else
        1 + max(_depth(n.left_child), _depth(n.right_child))
    end
end

"""
    Construct Vantage Point Tree with data type `InputType` and given metric with return type `MetricReturnType`.

    # Arguments
    - `data:: Vector{T}`: The data to be stored in the Tree
    - `metric:: Function`: A metric taking to parameters of type T and returning a distance with type `metricReturnType`.
    - `metricReturnType:: DataType`: Return type of `metric`.
"""
struct VPTree{InputType, MetricReturnType}
    metric::Function
    root::Node{InputType, MetricReturnType}
    MetricReturnType::DataType
    function VPTree(data::Vector{InputType}, metric::Function, MetricReturnType) where {InputType}
        data = collect(enumerate(data))
        root = _construct_tree_rec!(data, metric, MetricReturnType)
        new{InputType, MetricReturnType}(metric, root, MetricReturnType)
    end
end

function _construct_tree_rec!(data::Vector{Tuple{Int, InputType}}, metric, MetricReturnType) where InputType
    if isempty(data)
        return nothing
    end
    n_data = length(data)
    if n_data == 1
        return Node(data[1][1], data[1][2], zero(MetricReturnType), zero(MetricReturnType), zero(MetricReturnType), nothing, nothing)
    end
    i_vantage = rand(1:n_data)
    rest = data[1:end .!= i_vantage]
    i_middle = div(n_data - 1, 2) + 1
    vantage_point = data[i_vantage]
    radius = metric(rest[i_middle][2], vantage_point[2])
    distances = [metric(d[2], vantage_point[2]) for d in rest]
    select!(rest, i_middle, distances)
    left_rest = rest[1:i_middle]
    left_node = _construct_tree_rec!(left_rest, metric, MetricReturnType)
    right_rest = rest[i_middle + 1:end]
    right_node = _construct_tree_rec!(right_rest, metric, MetricReturnType)
    min_dist, max_dist = extrema(distances)
    Node{InputType, MetricReturnType}(vantage_point[1], vantage_point[2], radius,  min_dist, max_dist, left_node, right_node)
end

"""
    Efficiently compute hamming distance between the bits of two integer values.
"""
function hamming(a::Integer, b::Integer)
    count_ones(xor(a, b))
end

"""
    Find all items in `vptree` within `radius` with respect to the metric defined in the VPTree.
    
    # Returns
    `Vector{Int}`: Indices into VPTree.data.
"""
function find(vptree::VPTree{InputType, MetricReturnType}, query::InputType, radius::MetricReturnType) where {InputType, MetricReturnType}
    results = Vector{Int}()
    _find(vptree.root, query, radius, results, vptree.metric)
    results
end

function _find(vantage_point, query, radius, results, metric) 
    distance = metric(vantage_point.data, query)
    if distance <= radius
        push!(results, vantage_point.index)
    end
    if distance - radius <= vantage_point.radius && vantage_point.left_child != nothing && distance + radius >= vantage_point.min_dist
        _find(vantage_point.left_child, query, radius, results, metric)
    end
    if distance + radius > vantage_point.radius && vantage_point.right_child != nothing && distance - radius <= vantage_point.max_dist
        _find(vantage_point.right_child, query, radius, results, metric)
    end
end

function find_nearest(vptree::VPTree{T}, query::T, n_neighbors) where T
    candidates = DataStructures.BinaryMaxHeap{Tuple{Int,Int}}()
    _find_nearest(vptree.root, query, n_neighbors, candidates, vptree.metric)
    [t[2] for t in candidates.valtree]
end

function _find_nearest(vantage_point, query, n_neighbors, candidates, metric) 
    distance = metric(vantage_point.data, query)
    radius = length(candidates) < n_neighbors ? typemax(Int) : DataStructures.top(candidates)[1]
    if distance < radius
        push!(candidates, (distance, vantage_point.index))
        if length(candidates) > n_neighbors
            pop!(candidates)
        end
    end
    # Switch radius to one side to prevent overflow.
    if distance - vantage_point.radius <= radius && vantage_point.left_child != nothing && distance - vantage_point.min_dist >= -radius
        _find_nearest(vantage_point.left_child, query, n_neighbors, candidates, metric) 
    end
    if distance - vantage_point.radius > -radius && vantage_point.right_child != nothing && distance - vantage_point.max_dist <= radius
        _find_nearest(vantage_point.right_child, query, n_neighbors, candidates, metric) 
    end
end

function select!(a::AbstractVector, k::Integer, distances)
    lo = 1
    hi = length(a)
    if k < lo || k > hi; error("k is out of bounds"); end

    while true

        if lo == hi; return a[lo]; end

        pivot = distances[rand(lo:hi)]
        i, j = lo, hi
        while i < j
            while distances[i] < pivot; i += 1; end
            while distances[j] > pivot; j -= 1; end
            if distances[i] == distances[j]
                i += 1
            elseif i < j
                a[i], a[j] = a[j], a[i]
                distances[i], distances[j] = distances[j], distances[i]
            end
        end
        pivot_ind = j

        n = pivot_ind - lo + 1
        if k == n
            return a[pivot_ind]
        elseif k < n
            hi = pivot_ind - 1
        else
            lo = pivot_ind + 1
            k = k - n
        end

    end # while true...
end
