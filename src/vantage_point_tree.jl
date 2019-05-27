struct Node{T}
    index::Int
    data::T
    radius::Int
    left_child::Union{Node{T}, Nothing}
    right_child::Union{Node{T}, Nothing}
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
    #TODO: need data?
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
    vantage_point = data[1]
    n_data = length(data)
    if n_data == 1
        return Node(vantage_point[1], vantage_point[2], 0, nothing, nothing)
    elseif n_data > 1
        sort!(data[2:end], by=a->metric(vantage_point[2], a[2]))
        i_middle = div(n_data-1, 2) + 1
        radius = metric(data[i_middle][2], vantage_point[2])
        left_data = data[2:i_middle]
        left_node = _construct_tree_rec!(left_data, metric)
        right_data = data[i_middle + 1:end]
        right_node = _construct_tree_rec!(right_data, metric)
        return Node(vantage_point[1], vantage_point[2], radius, left_node, right_node)
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
    if distance + radius < vantage_point.radius
        _find(vantage_point.left_child, query, radius, results, metric)
    elseif distance - radius > vantage_point.radius
        _find(vantage_point.right_child, query, radius, results, metric)
    else
        _find(vantage_point.left_child, query, radius, results, metric)
        _find(vantage_point.right_child, query, radius, results, metric)
    end
end