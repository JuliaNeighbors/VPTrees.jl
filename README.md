# VPTrees

[![Build Status](https://travis-ci.com/altre/VPTrees.jl.svg?branch=master)](https://travis-ci.com/altre/VPTrees.jl)
[![Coveralls](https://coveralls.io/repos/github/altre/VPTrees.jl/badge.svg?branch=master)](https://coveralls.io/github/altre/VPTrees.jl?branch=master)

Implementation of Vantage Point Trees in Julia. 
A Vantage Point Tree is a metric tree which can be used for nearest neighbor or radius searches in any metric space.
See [Data structures and algorithms for nearest neighbor search in general metric spaces](http://web.cs.iastate.edu/~honavar/nndatastructures.pdf).

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

## Related Packages
The following packages implement other data structures for use in nearest neighbor and radius search in metric space:
- [BKTrees.jl](https://github.com/zgornel/BKTrees.jl)
- [NearestNeighbors.jl](https://github.com/KristofferC/NearestNeighbors.jl) implementing Ball Trees