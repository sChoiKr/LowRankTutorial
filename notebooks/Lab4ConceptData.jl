module Lab4ConceptData

using LinearAlgebra
using Random
using Statistics

export concept_importance_proxy,
       concept_score,
       nmf_trace,
       rank_sweep,
       svd_representation,
       synthetic_concept_data

"""A deterministic, small activation dataset whose visual ingredients are known."""
function synthetic_concept_data(; seed::Integer = 20260830)
    patches = [
        (name = "Crimson disk", color = "#b85c45", base = "#f4e7d7", kind = :disk),
        (name = "Blue stripes", color = "#557f9e", base = "#e6edf1", kind = :stripes),
        (name = "Bright center", color = "#d5a342", base = "#f4ead6", kind = :glow),
        (name = "Striped disk", color = "#557f9e", base = "#f4e7d7", kind = :striped_disk),
        (name = "Glowing disk", color = "#b85c45", base = "#f4ead6", kind = :glowing_disk),
        (name = "Bright stripes", color = "#d5a342", base = "#e6edf1", kind = :bright_stripes),
        (name = "Soft circle", color = "#8b9a68", base = "#edf0e5", kind = :disk),
        (name = "Fine texture", color = "#6f87a1", base = "#e8ecef", kind = :stripes),
        (name = "Pale center", color = "#d8b96d", base = "#f1eadf", kind = :glow),
        (name = "Round texture", color = "#9f6858", base = "#e8edf0", kind = :striped_disk),
        (name = "Round highlight", color = "#a45f4c", base = "#f2ead9", kind = :glowing_disk),
        (name = "Textured light", color = "#667f98", base = "#efe6d4", kind = :bright_stripes),
    ]

    # Rows are crops; columns are known latent visual ingredients.
    usage = [
        0.95 0.05 0.08
        0.04 0.94 0.06
        0.05 0.06 0.96
        0.78 0.82 0.08
        0.83 0.05 0.76
        0.06 0.80 0.82
        0.68 0.07 0.12
        0.08 0.70 0.10
        0.08 0.08 0.67
        0.62 0.66 0.12
        0.69 0.08 0.62
        0.08 0.63 0.69
    ]

    # Columns are nonnegative activation directions for three ingredients.
    directions = [
        0.92 0.08 0.12
        0.74 0.18 0.08
        0.15 0.90 0.10
        0.08 0.72 0.22
        0.35 0.12 0.95
        0.58 0.28 0.73
        0.22 0.65 0.46
        0.48 0.42 0.67
    ]

    rng = MersenneTwister(seed)
    activations = max.(usage * directions' .+ 0.012 .* randn(rng, size(usage, 1), size(directions, 1)), 0.0)
    return (
        patches = patches,
        activations = activations,
        true_usage = usage,
        true_directions = directions,
        concept_names = ["round form", "vertical texture", "bright center"],
        feature_names = ["f$i" for i in axes(activations, 2)],
    )
end

function normalize_nmf!(U, W)
    for component in axes(W, 2)
        scale = max(norm(view(W, :, component)), eps(Float64))
        W[:, component] ./= scale
        U[:, component] .*= scale
    end
    return U, W
end

function aligned_to_truth(U, W, truth)
    size(W, 2) == size(truth, 2) || return U, W
    remaining = collect(axes(W, 2))
    order = Int[]
    for target in axes(truth, 2)
        scores = [abs(dot(view(W, :, candidate), view(truth, :, target))) /
                  max(norm(view(W, :, candidate)) * norm(view(truth, :, target)), eps()) for candidate in remaining]
        chosen_position = argmax(scores)
        push!(order, remaining[chosen_position])
        deleteat!(remaining, chosen_position)
    end
    return U[:, order], W[:, order]
end

"""Multiplicative-update NMF snapshots for an iteration scrubber."""
function nmf_trace(A::AbstractMatrix, rank::Integer;
                   checkpoints = (0, 1, 2, 5, 10, 25, 60, 120),
                   seed::Integer = 20260830,
                   anchor = nothing)
    rank > 0 || throw(ArgumentError("rank must be positive"))
    minimum(A) >= 0 || throw(ArgumentError("NMF input must be nonnegative"))
    rng = MersenneTwister(seed + 37rank)
    rows, features = size(A)
    if !isnothing(anchor) && rank == size(anchor.true_directions, 2)
        U = max.(anchor.true_usage .+ 0.18 .* rand(rng, rows, rank), 1e-5)
        W = max.(anchor.true_directions .+ 0.18 .* rand(rng, features, rank), 1e-5)
    else
        U = 0.15 .+ rand(rng, rows, rank)
        W = 0.15 .+ rand(rng, features, rank)
    end
    normalize_nmf!(U, W)

    wanted = sort(unique(Int.(collect(checkpoints))))
    maximum(wanted; init = 0) >= 0 || throw(ArgumentError("checkpoints must be nonnegative"))
    snapshots = NamedTuple[]
    function record!(iteration)
        shown_U, shown_W = isnothing(anchor) ? (copy(U), copy(W)) : aligned_to_truth(copy(U), copy(W), anchor.true_directions)
        reconstruction = shown_U * shown_W'
        push!(snapshots, (
            iteration = iteration,
            U = shown_U,
            W = shown_W,
            reconstruction = reconstruction,
            error = norm(A - reconstruction) / max(norm(A), eps()),
        ))
    end

    0 in wanted && record!(0)
    for iteration in 1:maximum(wanted; init = 0)
        U .*= (A * W) ./ max.(U * (W' * W), 1e-10)
        W .*= (A' * U) ./ max.(W * (U' * U), 1e-10)
        normalize_nmf!(U, W)
        iteration in wanted && record!(iteration)
    end
    return snapshots
end

function rank_sweep(data; ranks = 1:5)
    vocabulary = Dict(
        1 => ["shape + texture + light"],
        2 => ["round form", "texture + light"],
        3 => data.concept_names,
        4 => ["round form", "coarse stripes", "fine stripes", "bright center"],
        5 => ["warm circle", "soft circle", "coarse stripes", "fine stripes", "bright center"],
    )
    return [begin
        final = last(nmf_trace(data.activations, rank; checkpoints = (160,), anchor = rank == 3 ? data : nothing))
        labels = get(vocabulary, rank, ["factor $index" for index in 1:rank])
        top_patch = [argmax(view(final.U, :, component)) for component in 1:rank]
        (rank = rank, error = final.error, labels = labels, U = final.U, W = final.W, top_patch = top_patch)
    end for rank in ranks]
end

function svd_representation(A::AbstractMatrix, rank::Integer = 3)
    factorization = svd(A)
    chosen = 1:min(rank, length(factorization.S))
    coefficients = factorization.U[:, chosen] * Diagonal(factorization.S[chosen])
    directions = factorization.V[:, chosen]
    reconstruction = coefficients * directions'
    return (
        coefficients = coefficients,
        directions = directions,
        reconstruction = reconstruction,
        error = norm(A - reconstruction) / max(norm(A), eps()),
    )
end

logistic(x) = inv(1 + exp(-x))

"""A small synthetic classifier used only to distinguish presence from importance."""
concept_score(coefficients::AbstractVector) = logistic(-1.15 + dot([0.15, 2.25, 0.90], coefficients))

function concept_importance_proxy(coefficients::AbstractVector)
    baseline = concept_score(coefficients)
    changes = [begin
        scores = Float64[]
        for strength in range(0, 1; length = 41)
            altered = copy(coefficients)
            altered[concept] = strength
            push!(scores, (concept_score(altered) - baseline)^2)
        end
        mean(scores)
    end for concept in eachindex(coefficients)]
    total = sum(changes)
    total > 0 ? changes ./ total : fill(0.0, length(changes))
end

end
