module Lab2CapacityData

using LinearAlgebra
using TensorKitchen

export cp_oracle_representation,
       make_two_block_tensor,
       mode_unfolding,
       multilinear_ranks,
       unfolding_rank_lower_bound

smooth_profile(n, center, width) =
    exp.(-0.5 .* ((collect(1:n) .- center) ./ width) .^ 2)
normalize_profile(v) = v ./ norm(v)

function mode_unfolding(tensor, mode::Integer)
    order = ndims(tensor)
    1 <= mode <= order || throw(ArgumentError("mode must lie between 1 and $order"))
    permutation = (mode, (axis for axis = 1:order if axis != mode)...)
    reshape(permutedims(tensor, permutation), size(tensor, mode), :)
end

multilinear_ranks(tensor) =
    Tuple(rank(mode_unfolding(tensor, mode)) for mode = 1:ndims(tensor))

"""Deterministic two-block target used by Lab 2."""
function make_two_block_tensor(; seed::Int = 20260812)
    dims = (10, 10, 6)
    block_rank = (2, 2, 1)

    cores = [
        reshape([1.0, 0.25, 0.15, 0.75], block_rank),
        reshape([0.8, -0.15, 0.35, 1.0], block_rank),
    ]
    factor_sets = [
        [
            hcat(
                normalize_profile(smooth_profile(10, 2.8, 1.2)),
                normalize_profile(smooth_profile(10, 6.2, 1.5)),
            ),
            hcat(
                normalize_profile(smooth_profile(10, 3.0, 1.3)),
                normalize_profile(smooth_profile(10, 7.2, 1.4)),
            ),
            reshape(normalize_profile(collect(range(0.25, 1.0; length = 6))), :, 1),
        ],
        [
            hcat(
                normalize_profile(smooth_profile(10, 5.0, 1.1)),
                normalize_profile(smooth_profile(10, 8.2, 1.0)),
            ),
            hcat(
                normalize_profile(smooth_profile(10, 7.8, 1.2)),
                normalize_profile(smooth_profile(10, 4.7, 1.0)),
            ),
            reshape(normalize_profile(collect(range(1.0, 0.25; length = 6))), :, 1),
        ],
    ]
    blocks = [
        reconstruct_tucker(core, factors) for (core, factors) in zip(cores, factor_sets)
    ]
    target = sum(blocks)
    return (
        seed = seed,
        target = target,
        true_blocks = blocks,
        true_cores = cores,
        true_factors = factor_sets,
        dimensions = dims,
        block_rank = block_rank,
        block_count = 2,
        multilinear_rank = multilinear_ranks(target),
    )
end

"""
Convert each `(2,2,1)` Tucker block into at most two rank-one terms by taking
the SVD of its `2 × 2` core matrix. The two blocks therefore give an explicit
CP representation with four terms.
"""
function cp_oracle_representation(problem)
    weights_cp = Float64[]
    mode_vectors = [Vector{Vector{Float64}}() for _ = 1:3]
    for (core, factors) in zip(problem.true_cores, problem.true_factors)
        core_svd = svd(core[:, :, 1])
        for component in eachindex(core_svd.S)
            push!(weights_cp, core_svd.S[component])
            push!(mode_vectors[1], factors[1] * core_svd.U[:, component])
            push!(mode_vectors[2], factors[2] * core_svd.V[:, component])
            push!(mode_vectors[3], vec(factors[3]))
        end
    end
    factor_matrices = [hcat(vectors...) for vectors in mode_vectors]
    reconstruction = reconstruct_cpd_rankr(weights_cp, factor_matrices)
    return (
        weights = weights_cp,
        factors = factor_matrices,
        reconstruction = reconstruction,
        rank_bound = length(weights_cp),
    )
end

"""
Rigorous lower bound on relative approximation error for any tensor whose
mode-`m` unfolding ranks do not exceed `rank_limits[m]`.
"""
function unfolding_rank_lower_bound(tensor, rank_limits)
    length(rank_limits) == ndims(tensor) ||
        throw(DimensionMismatch("one rank limit is required per tensor mode"))
    denominator = max(norm(tensor), eps(Float64))
    mode_bounds = [begin
        singular_values = svdvals(mode_unfolding(tensor, mode))
        cutoff = min(Int(rank_limits[mode]), length(singular_values))
        tail = cutoff == length(singular_values) ? Float64[] : singular_values[(cutoff+1):end]
        norm(tail) / denominator
    end for mode = 1:ndims(tensor)]
    return (lower_bound = maximum(mode_bounds), mode_bounds = Tuple(mode_bounds))
end

end
