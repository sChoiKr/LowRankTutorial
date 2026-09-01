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

"""Multiplicative-update NMF snapshots from a reproducible random start."""
function nmf_trace(A::AbstractMatrix, rank::Integer;
                   checkpoints = (0, 1, 2, 5, 10, 25, 60, 120),
                   seed::Integer = 20260830)
    rank > 0 || throw(ArgumentError("rank must be positive"))
    minimum(A) >= 0 || throw(ArgumentError("NMF input must be nonnegative"))
    rng = MersenneTwister(seed + 37rank)
    rows, features = size(A)
    U = 0.15 .+ rand(rng, rows, rank)
    W = 0.15 .+ rand(rng, features, rank)
    normalize_nmf!(U, W)

    wanted = sort(unique(Int.(collect(checkpoints))))
    maximum(wanted; init = 0) >= 0 || throw(ArgumentError("checkpoints must be nonnegative"))
    snapshots = NamedTuple[]
    function record!(iteration)
        shown_U, shown_W = copy(U), copy(W)
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

function oracle_matches(W, data)
    return [begin
        scores = [
            abs(dot(view(W, :, candidate), view(data.true_directions, :, planted))) /
            max(norm(view(W, :, candidate)) * norm(view(data.true_directions, :, planted)), eps()) for
            planted in axes(data.true_directions, 2)
        ]
        best = argmax(scores)
        (name = data.concept_names[best], overlap = scores[best])
    end for candidate in axes(W, 2)]
end

function rank_sweep(data; ranks = 1:5)
    return [begin
        final = last(nmf_trace(data.activations, rank; checkpoints = (160,)))
        top_patches = [
            sortperm(view(final.U, :, component); rev = true)[1:min(3, size(final.U, 1))] for
            component in 1:rank
        ]
        (
            rank = rank,
            error = final.error,
            U = final.U,
            W = final.W,
            top_patches = top_patches,
            oracle = rank == size(data.true_directions, 2) ? oracle_matches(final.W, data) : nothing,
        )
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
