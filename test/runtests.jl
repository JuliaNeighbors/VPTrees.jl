using Test
using VPTrees
using Random
using StringDistances
using Aqua

Aqua.test_all(VPTrees)

@testset "VPTree" begin include("test_vantage_point_tree.jl") end
