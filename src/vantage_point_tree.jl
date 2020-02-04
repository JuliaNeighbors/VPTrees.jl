import Base.show
import DataStructures
import Random

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
    VPTree(data::Vector{InputType}, metric::Function; threaded=false)

Construct Vantage Point Tree with a vector of `data` and given metric function `metric`. 
`threaded` uses threading is only avaible in Julia 1.3+ to parallelize construction of the Tree.
When not explicitly set, is set to true when the necessary conditions are met.

## Example:

```julia
using VPTrees
using StringDistances

data = ["bla", "blub", "asdf", ":assd", "ast", "baube"]
metric = (a, b) -> evaluate(Levenshtein(),a,b)
vptree = VPTree(data, metric)
query = "blau"
radius = 2
data[find(vptree, query, radius)]
# 2-element Array{String,1}:
#  "bla" 
#  "blub"
n_neighbors = 3
data[find_nearest(vptree, query, n_neighbors)]
# 3-element Array{String,1}:
#  "baube"
#  "blub" 
#  "bla"
```
"""
struct VPTree{InputType, MetricReturnType}
    data::Vector{InputType}
    metric::Function
    root::Node{InputType, MetricReturnType}
    MetricReturnType::DataType
    function VPTree(data::Vector{InputType}, metric::Function; threaded=nothing) where {InputType}
        if threaded == true
        if VERSION < v"1.3-DEV" 
            @warn "incompatible julia version for `threaded=true`: $VERSION, requires >= v\"1.3\", setting `threaded=false`"
            threaded = false
        elseif Threads.nthreads() == 1
            @warn "`threaded = true`, but `Threads.nthreads() == 1`"
            threaded = false
        elseif threaded === nothing && VERSION >= v"1.3-DEV" && Threads.nthreads() == 1
            # TODO: How big data do you need for this to help?
            threaded = true
        end
        @assert length(data) > 0 "Input data must contain at least one point."
        MetricReturnType = typeof(metric(data[1], data[1]))
        indexed_data = Random.shuffle!(collect(enumerate(data)))
        root = _construct_tree_rec!(indexed_data, metric, MetricReturnType, threaded)
        new{InputType, MetricReturnType}(data, metric, root, MetricReturnType)
    end
end

function VPTree(data::Vector{T}, metric::Function, MetricReturnType) where T
    VPTree(data, metric)
end

const SMALL_DATA = 100

@deprecate VPTree(data::Vector, metric::Function, MetricReturnType::DataType) VPTree(data::Vector, metric::Function)

function _construct_tree_rec!(data::AbstractVector{Tuple{Int, InputType}}, metric, MetricReturnType, threaded)::Union{Node{InputType, MetricReturnType}, Nothing} where InputType
    if isempty(data)
        return nothing
    end
    n_data = length(data)
    if n_data == 1
        return Node(data[1][1], data[1][2], zero(MetricReturnType), zero(MetricReturnType), zero(MetricReturnType), nothing, nothing)
    end
    vantage_point = data[1]
    rest = view(data, 2:length(data))
    distances = [metric(d[2], vantage_point[2]) for d in rest]
    i_middle = div(n_data - 1, 2) + 1
    distance_order = sortperm(distances, alg=PartialQuickSort(i_middle))
    permute!(rest, distance_order)
    
    left_rest = view(rest, 1:i_middle)
    should_spawn = threaded && length(rest) > SMALL_DATA
    left_node = if should_spawn
        Threads.@spawn _construct_tree_rec!(left_rest, metric, MetricReturnType, threaded)
    else
        _construct_tree_rec!(left_rest, metric, MetricReturnType, threaded)
    end
    
    right_rest = view(rest, i_middle + 1:length(rest))
    right_node = _construct_tree_rec!(right_rest, metric, MetricReturnType, threaded)
    
    min_dist, max_dist = extrema(distances)
    radius = distances[distance_order[i_middle]]
    
    if should_spawn
        Node{InputType, MetricReturnType}(vantage_point[1], vantage_point[2], radius,  min_dist, max_dist, fetch(left_node), right_node)
    else
        Node{InputType, MetricReturnType}(vantage_point[1], vantage_point[2], radius,  min_dist, max_dist, left_node, right_node)
    end
end

"""
    find(vptree::VPTree{InputType, MetricReturnType}, query::InputType, radius::MetricReturnType)::Vector{Int}

Find all items in `vptree` within `radius` with respect to the metric defined in the VPTree.
Returns Indices into VPTree.data.

## Example

```julia
using VPTrees
using StringDistances

data = ["bla", "blub", "asdf", ":assd", "ast", "baube"]
metric = (a, b) -> evaluate(Levenshtein(),a,b)
vptree = VPTree(data, metric)
query = "blau"
radius = 2
data[find(vptree, query, radius)]
# 2-element Array{String,1}:
#  "bla" 
#  "blub"
```
"""
function find(vptree::VPTree{InputType, MetricReturnType}, query::InputType, radius::MetricReturnType)::Vector{Int} where {InputType, MetricReturnType}
    results = Vector{Int}()
    _find(vptree.root, query, radius, results, vptree.metric)
    results
end

function _find(vantage_point, query, radius, results, metric) 
    distance = metric(vantage_point.data, query)
    if distance <= radius
        push!(results, vantage_point.index)
    end
    if distance - radius <= vantage_point.radius && vantage_point.left_child !== nothing && distance + radius >= vantage_point.min_dist
        _find(vantage_point.left_child, query, radius, results, metric)
    end
    if distance + radius > vantage_point.radius && vantage_point.right_child !== nothing && distance - radius <= vantage_point.max_dist
        _find(vantage_point.right_child, query, radius, results, metric)
    end
end

"""
    find_nearest(vptree::VPTree{InputType, MetricReturnType}, query::InputType, n_neighbors::Int)::Vector{Int}

Find `n_neighbors` items in `vptree` closest to `query` with respect to the metric defined in the VPTree.
Returns Indices into VPTree.data.

## Example:

```julia
using VPTrees
using StringDistances

data = ["bla", "blub", "asdf", ":assd", "ast", "baube"]
metric = (a, b) -> evaluate(Levenshtein(),a,b)
vptree = VPTree(data, metric)
query = "blau"
n_neighbors = 3
data[find_nearest(vptree, query, n_neighbors)]
# 3-element Array{String,1}:
#  "baube"
#  "blub" 
#  "bla"
```
"""
function find_nearest(vptree::VPTree{InputType, MetricReturnType}, query::InputType, n_neighbors::Int)::Vector{Int} where {InputType, MetricReturnType}
    @assert n_neighbors > 0 "Can't search for fewer than 1 neighbors"
    candidates = DataStructures.BinaryMaxHeap{Tuple{MetricReturnType, Int}}()
    _find_nearest(vptree.root, query, n_neighbors, candidates, vptree.metric)
    [t[2] for t in candidates.valtree]
end

function _find_nearest(vantage_point, query, n_neighbors, candidates, metric) 
    distance = metric(vantage_point.data, query)
    radius = length(candidates) < n_neighbors ? typemax(typeof(vantage_point.radius)) : DataStructures.top(candidates)[1]
    if distance < radius
        push!(candidates, (distance, vantage_point.index))
        if length(candidates) > n_neighbors
            pop!(candidates)
        end
    end
    # Switch radius to one side to prevent overflow.
    if distance < vantage_point.radius
        # Switch radius to one side to prevent overflow.
        if distance - vantage_point.radius <= radius && vantage_point.left_child !== nothing && distance - vantage_point.min_dist >= -radius
            _find_nearest(vantage_point.left_child, query, n_neighbors, candidates, metric) 
        end
        if distance - vantage_point.radius > -radius && vantage_point.right_child !== nothing && distance - vantage_point.max_dist <= radius
            _find_nearest(vantage_point.right_child, query, n_neighbors, candidates, metric) 
        end
    else
        if distance - vantage_point.radius > -radius && vantage_point.right_child !== nothing && distance - vantage_point.max_dist <= radius
            _find_nearest(vantage_point.right_child, query, n_neighbors, candidates, metric) 
        end
        if distance - vantage_point.radius <= radius && vantage_point.left_child !== nothing && distance - vantage_point.min_dist >= -radius
            _find_nearest(vantage_point.left_child, query, n_neighbors, candidates, metric) 
        end
    end
end
