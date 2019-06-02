import Base.show

struct Node{T}
    index::Int
    data::T
    radius::Int
    min_dist::Int
    max_dist::Int
    left_child::Union{Node{T}, Nothing}
    right_child::Union{Node{T}, Nothing}
end

function Base.show(io::IO, n::Node)
    print("Node $(typeof(n).parameters[1]), radius $(n.radius), depth $(_depth(n))")
end

function _depth(n)
    if n == nothing 
        0
    else
        1 + max(_depth(n.left_child), _depth(n.right_child))
    end
end

"""
    Construct Vantage Point Tree with data type `T` and given metric.

    # Arguments
    - `data:: Vector{T}`: The data to be stored in the Tree
    - `metric:: Function`: A metric taking to parameters of type T and returning a distance with type `Float64`.
"""
struct VPTree{T}
    metric::Function
    root::Node{T}
    #TODO: copy 
    #TODO: randomize
    #TODO: trick for metric return type?
    function  VPTree(data::Vector{T}, metric) where T
        data = collect(enumerate(data))
        root = _construct_tree_rec!(data, metric)
        new{T}(metric, root)
    end
end


function _construct_tree_rec!(data, metric)
    if isempty(data)
        return nothing
    end
    n_data = length(data)
    if n_data == 1
        return Node(data[1][1], data[1][2], 0, 0, 0, nothing, nothing)
    end
    i_vantage = rand(1:n_data)
    rest = data[1:end .!= i_vantage]
    i_middle = div(n_data - 1, 2) + 1
    vantage_point = data[i_vantage]
    select!(rest, i_middle, comparer(metric, vantage_point))
    radius = metric(rest[i_middle][2], vantage_point[2])
    left_rest = rest[1:i_middle - 1]
    left_node = _construct_tree_rec!(left_rest, metric)
    right_rest = rest[i_middle:end]
    right_node = _construct_tree_rec!(right_rest, metric)
    (min_dist, _), (max_dist, _) = extrema(rest)
    Node(vantage_point[1], vantage_point[2], radius,  min_dist, max_dist, left_node, right_node)
end

function comparer(metric, vantage_point)
    function compare(a, b)
        dist_a = metric(vantage_point[2], a[2])
        dist_b = metric(vantage_point[2], b[2])
        dist_a < dist_b ? -1 : dist_a > dist_b ? 1 : 0
    end
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
function find(vptree::VPTree{T}, query::T, radius) where T
    results = Vector{Int}()
    _find(vptree.root, query, radius, results, vptree.metric)
    results
end

function _find(vantage_point, query, radius, results, metric) 
    if vantage_point == nothing
        return 
    end
    distance = metric(vantage_point.data, query)
    if distance <= radius
        push!(results, vantage_point.index)
    end
    if distance + radius > vantage_point.radius && distance - radius <= vantage_point.max_dist
        _find(vantage_point.left_child, query, radius, results, metric)
    end
    if distance - radius <= vantage_point.radius && distance + radius >= vantage_point.min_dist
        _find(vantage_point.right_child, query, radius, results, metric)
    end
end

function select!(a::AbstractVector, k::Integer, comp)
    lo = 1
    hi = length(a)
    if k < lo || k > hi; error("k is out of bounds"); end

    while true

        if lo == hi; return a[lo]; end

        i, j = lo, hi
        pivot = a[rand(lo:hi)]
        while i < j
            while comp(a[i], pivot) == -1; i += 1; end
            while comp(a[j], pivot) == 1; j -= 1; end
            if comp(a[i],  a[j]) == 0
                i += 1
            elseif i < j
                a[i], a[j] = a[j], a[i]
            end
        end
        pivot_ind = j

        length = pivot_ind - lo + 1
        if k == length
            return a[pivot_ind]
        elseif k < length
            hi = pivot_ind - 1
        else
            lo = pivot_ind + 1
            k = k - length
        end

    end # while true...
end
