import Base.show
import DataStructures
import Random

struct Node{InputType, MetricReturnType}
    index::Int
    data::InputType
    radius::MetricReturnType
    min_dist::MetricReturnType
    max_dist::MetricReturnType
    n_data::Int
    left_child::Union{Node{InputType, MetricReturnType}, Nothing}
    right_child::Union{Node{InputType, MetricReturnType}, Nothing}
end

function Base.show(io::IO, n::Node)
    print("Node $(typeof(n).parameters[1]): $(n.data), index $(n.index) radius $(n.radius)")
end

"""
    VPTree(data::Vector{InputType}, metric; threaded=nothing)

Construct Vantage Point Tree with a vector of `data` and given a callable `metric`.
`threaded` uses threading is only avaible in Julia 1.3+ to parallelize construction of the Tree.
When not explicitly set, is set to true when the necessary conditions are met.

## Example:

```julia
using VPTrees
using StringDistances

data = ["bla", "blub", "asdf", ":assd", "ast", "baube"]
vptree = VPTree(data, Levenshtein())
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
    metric
    root::Node{InputType, MetricReturnType}
    MetricReturnType::DataType
    threaded::Bool
    function VPTree(data::Vector{InputType}, metric; threaded=nothing) where InputType
        threaded = _check_threaded(threaded)
        @assert length(data) > 0 "Input data must contain at least one point."
        @assert !isempty(methods(metric)) "`metric` must be callable, was: $(metric)"
        MetricReturnType = typeof(metric(data[1], data[1]))
        indexed_data = Random.shuffle!(collect(enumerate(data)))
        root = threaded ? _construct_tree_rec_threaded!(indexed_data, metric, MetricReturnType) : _construct_tree_rec!(indexed_data, metric, MetricReturnType)
        new{InputType, MetricReturnType}(data, metric, root, MetricReturnType, threaded)
    end
end

function _check_threaded(threaded)
    if !isnothing(threaded) && threaded == true
        if VERSION < v"1.3-DEV"
            @warn "incompatible julia version for `threaded=true`: $VERSION, requires >= v\"1.3\", setting `threaded=false`"
            threaded = false
        elseif Threads.nthreads() == 1
            @warn "`threaded = true`, but `Threads.nthreads() == 1`, setting `threaded=false`"
            threaded = false
        end
    end
    if isnothing(threaded)
        threaded = VERSION >= v"1.3-DEV" && Threads.nthreads() > 1
    end
    threaded
end

function VPTree(data::Vector{T}, metric::Function, MetricReturnType) where T
    VPTree(data, metric)
end

const SMALL_DATA = 1000

@deprecate VPTree(data::Vector, metric::Function, MetricReturnType::DataType) VPTree(data::Vector, metric)

function _construct_tree_rec_threaded!(data::AbstractVector{Tuple{Int, InputType}}, metric, MetricReturnType) where InputType
    if isempty(data)
        return nothing
    end
    n_data = length(data)
    if n_data == 1
        return Node(data[1][1], data[1][2], zero(MetricReturnType), zero(MetricReturnType), zero(MetricReturnType), n_data, nothing, nothing)
    end
    vantage_point = data[1]
    rest = view(data, 2:length(data))
    distances = [metric(d[2], vantage_point[2]) for d in rest]
    i_middle = div(n_data - 1, 2) + 1
    distance_order = sortperm(distances, alg=PartialQuickSort(i_middle))
    permute!(rest, distance_order)

    min_dist, max_dist = extrema(distances)
    radius = distances[distance_order[i_middle]]
    left_rest = view(rest, 1:i_middle)

    should_spawn = length(rest) > SMALL_DATA
    left_node = if should_spawn
        Threads.@spawn _construct_tree_rec_threaded!(left_rest, metric, MetricReturnType)
    else
        _construct_tree_rec!(left_rest, metric, MetricReturnType)
    end

    right_rest = view(rest, i_middle + 1:length(rest))
    right_node = _construct_tree_rec_threaded!(right_rest, metric, MetricReturnType)

    if should_spawn
        Node{InputType, MetricReturnType}(vantage_point[1], vantage_point[2], radius,  min_dist, max_dist, n_data, fetch(left_node), right_node)
    else
        Node{InputType, MetricReturnType}(vantage_point[1], vantage_point[2], radius,  min_dist, max_dist, n_data, left_node, right_node)
    end
end

function _construct_tree_rec!(data::AbstractVector{Tuple{Int, InputType}}, metric, MetricReturnType) where InputType
    if isempty(data)
        return nothing
    end
    n_data = length(data)
    if n_data == 1
        return Node(data[1][1], data[1][2], zero(MetricReturnType), zero(MetricReturnType), zero(MetricReturnType), n_data, nothing, nothing)
    end
    vantage_point = data[1]
    rest = view(data, 2:length(data))
    distances = [metric(d[2], vantage_point[2]) for d in rest]
    i_middle = div(n_data - 1, 2) + 1
    distance_order = sortperm(distances, alg=PartialQuickSort(i_middle))
    permute!(rest, distance_order)

    left_rest = view(rest, 1:i_middle)

    left_node = _construct_tree_rec!(left_rest, metric, MetricReturnType)

    right_rest = view(rest, i_middle + 1:length(rest))
    right_node = _construct_tree_rec!(right_rest, metric, MetricReturnType)

    min_dist, max_dist = extrema(distances)
    radius = distances[distance_order[i_middle]]

    Node{InputType, MetricReturnType}(vantage_point[1], vantage_point[2], radius,  min_dist, max_dist, n_data, left_node, right_node)
end

"""
    find(vptree::VPTree{InputType, MetricReturnType}, query::InputType, radius::MetricReturnType, skip=nothing)::Vector{Int}

Find all items in `vptree` within `radius` of `query` with respect to the metric defined in the VPTree.
Returns indices into VPTree.data. The optional `skip` argument is a function `f(::Int)::Bool` which can
be used to omit points in the tree from the search based on their index.

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
function find(vptree::VPTree{InputType, MetricReturnType}, query::InputType, radius::MetricReturnType, skip=nothing)::Vector{Int} where {InputType, MetricReturnType}
    if vptree.threaded
        results_threads = [Vector{Int}() for i in 1:Threads.nthreads()]
        _find_threaded(vptree.root, query, radius, results_threads, vptree.metric, skip)
        return reduce(vcat, results_threads)
    else
        results = Vector{Int}()
        _find(vptree.root, query, radius, results, vptree.metric, skip)
        return results
    end
end

function _find(vantage_point, query, radius, results, metric, skip)
    distance = metric(vantage_point.data, query)
    if distance <= radius && (isnothing(skip) || !skip(vantage_point.index))
        push!(results, vantage_point.index)
    end
    if distance - radius <= vantage_point.radius && !isnothing(vantage_point.left_child) && distance + radius >= vantage_point.min_dist
        _find(vantage_point.left_child, query, radius, results, metric, skip)
    end
    if distance + radius >= vantage_point.radius && !isnothing(vantage_point.right_child) && distance - radius <= vantage_point.max_dist
        _find(vantage_point.right_child, query, radius, results, metric, skip)
    end
end

function _find_threaded(vantage_point, query, radius, results, metric, skip)
    distance = metric(vantage_point.data, query)
    if distance <= radius && (isnothing(skip) || !skip(vantage_point.index))
        push!(results[Threads.threadid()], vantage_point.index)
    end
    goleft = distance + radius >= vantage_point.radius && !isnothing(vantage_point.right_child) && distance - radius <= vantage_point.max_dist
    if distance - radius <= vantage_point.radius && !isnothing(vantage_point.left_child) && distance + radius >= vantage_point.min_dist
        if goleft && vantage_point.n_data > SMALL_DATA
            r = Threads.@spawn _find_threaded(vantage_point.left_child, query, radius, results, metric, skip)
        else
            _find_threaded(vantage_point.left_child, query, radius, results, metric, skip)
        end
    end
    if goleft
        _find_threaded(vantage_point.right_child, query, radius, results, metric, skip)
    end
    if @isdefined r
        wait(r)
    end
end

"""
    find_nearest(vptree::VPTree{InputType, MetricReturnType}, query::InputType, n_neighbors::Int, skip=nothing)::Vector{Int}

Find `n_neighbors` items in `vptree` closest to `query` with respect to the metric defined in the VPTree.
Returns indices into VPTree.data. The optional `skip` argument is a function `f(::Int)::Bool` which can
be used to omit points in the tree from the search based on their index.

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
function find_nearest(vptree::VPTree{InputType, MetricReturnType}, query::InputType, n_neighbors::Int, skip=nothing)::Vector{Int} where {InputType, MetricReturnType}
    @assert n_neighbors > 0 "Can't search for fewer than 1 neighbors"
    candidates = DataStructures.BinaryMaxHeap{Tuple{MetricReturnType, Int}}()
    _find_nearest(vptree.root, query, n_neighbors, candidates, vptree.metric, skip)
    [t[2] for t in candidates.valtree]
end

function _find_nearest(vantage_point, query, n_neighbors, candidates, metric, skip)
    distance = metric(vantage_point.data, query)
    radius = length(candidates) < n_neighbors ? typemax(typeof(vantage_point.radius)) : DataStructures.top(candidates)[1]
    if distance < radius && (isnothing(skip) || !skip(vantage_point.index))
        push!(candidates, (distance, vantage_point.index))
        if length(candidates) > n_neighbors
            pop!(candidates)
        end
    end
    # Switch radius to one side to prevent overflow.
    if distance < vantage_point.radius
        # Switch radius to one side to prevent overflow.
        if distance - vantage_point.radius <= radius && !isnothing(vantage_point.left_child) && distance - vantage_point.min_dist >= -radius
            _find_nearest(vantage_point.left_child, query, n_neighbors, candidates, metric, skip)
        end
        if distance - vantage_point.radius > -radius && !isnothing(vantage_point.right_child) && distance - vantage_point.max_dist <= radius
            _find_nearest(vantage_point.right_child, query, n_neighbors, candidates, metric, skip)
        end
    else
        if distance - vantage_point.radius > -radius && !isnothing(vantage_point.right_child) && distance - vantage_point.max_dist <= radius
            _find_nearest(vantage_point.right_child, query, n_neighbors, candidates, metric, skip)
        end
        if distance - vantage_point.radius <= radius && !isnothing(vantage_point.left_child) && distance - vantage_point.min_dist >= -radius
            _find_nearest(vantage_point.left_child, query, n_neighbors, candidates, metric, skip)
        end
    end
end
