using LinearAlgebra
using Logging
using Random
using Test
using TensorKitchen
using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const NOTEBOOK_DIR = joinpath(ROOT, "notebooks")

include(joinpath(NOTEBOOK_DIR, "Lab2CapacityData.jl"))
using .Lab2CapacityData
include(joinpath(NOTEBOOK_DIR, "Lab3TraceData.jl"))
using .Lab3TraceData
include(joinpath(NOTEBOOK_DIR, "Lab4ConceptData.jl"))
using .Lab4ConceptData

@testset "Lab 1 mathematical invariants" begin
    A = [1.0 0.5; -0.5 1.0; 0.75 -1.0; 1.25 0.25]
    B = [0.5 -1.0; 1.0 0.25; -0.75 0.5]
    X = A * B'
    scales = 10.0 .^ (-6.0, -2.0, 0.0, 2.0, 6.0)
    transformed = [begin
        Q = Diagonal([scale, inv(scale)])
        (A * Q) * (B * inv(Q)')'
    end for scale in scales]

    @test all(norm(X - candidate) / norm(X) < 1e-10 for candidate in transformed)
    @test all(
        cond(Matrix(Diagonal([scale, inv(scale)]))) ≈
        10.0^(2 * abs(log10(scale))) for scale in scales
    )

    rng = MersenneTwister(20260901)
    factors_original = [randn(rng, dimension, 2) for dimension in (5, 4, 3)]
    weights_original = [1.5, 0.75]
    object_original = reconstruct_cpd_rankr(weights_original, factors_original)

    equivalent = copy.(factors_original)
    equivalent[1] .*= 1e3
    equivalent[2] .*= 1e-2
    equivalent[3] ./= 10.0
    object_rescaled = reconstruct_cpd_rankr(weights_original, equivalent)
    @test norm(object_original - object_rescaled) / norm(object_original) < 1e-10

    permutation = [2, 1]
    object_permuted = reconstruct_cpd_rankr(
        weights_original[permutation],
        [factor[:, permutation] for factor in equivalent],
    )
    @test norm(object_original - object_permuted) / norm(object_original) < 1e-10

    perturbed = copy.(equivalent)
    perturbed[1][1, 1] += 1e-3
    object_perturbed = reconstruct_cpd_rankr(weights_original, perturbed)
    @test norm(object_original - object_perturbed) / norm(object_original) > 1e-14
end

@testset "Lab 2 model-capacity claims" begin
    problem = make_two_block_tensor()
    oracle_cp = cp_oracle_representation(problem)
    oracle_btd = sum(problem.true_blocks)
    oracle_tucker = tucker(problem.target, (4, 4, 2); method = :sthosvd)

    @test problem.dimensions == (10, 10, 6)
    @test problem.multilinear_rank == (4, 4, 2)
    @test multilinear_ranks(problem.target) == (4, 4, 2)
    @test oracle_cp.rank_bound == 4
    @test norm(problem.target - oracle_cp.reconstruction) / norm(problem.target) < 1e-12
    @test norm(problem.target - oracle_btd) / norm(problem.target) < 1e-14
    @test rel_error(problem.target, oracle_tucker) < 1e-12
    @test size(oracle_cp.reconstruction) == size(problem.target)
    @test size(reconstruct(oracle_tucker)) == size(problem.target)

    cp2_floor = unfolding_rank_lower_bound(problem.target, (2, 2, 2))
    tucker221_floor = unfolding_rank_lower_bound(problem.target, (2, 2, 1))
    @test cp2_floor.lower_bound > 0.25
    @test tucker221_floor.lower_bound > 0.25

    reduced_tucker = tucker(problem.target, (2, 2, 1); method = :sthosvd)
    @test rel_error(problem.target, reduced_tucker) + 1e-12 >=
          tucker221_floor.lower_bound
end

@testset "Lab 3 diagnostic formulas" begin
    rho = 0.9
    rng = MersenneTwister(27)
    bases = [
        Matrix(qr(randn(rng, dimension, 3)).Q)[:, 1:3] for
        dimension in (4, 4, 3)
    ]
    factors_collision = [
        hcat(
            basis[:, 1],
            rho .* basis[:, 1] .+ sqrt(1 - rho^2) .* basis[:, 2],
            basis[:, 3],
        ) for basis in bases
    ]
    alignments = [dot(F[:, 1], F[:, 2]) for F in factors_collision]
    overlap = abs(prod(alignments))

    @test all(isapprox(alignment, rho; atol = 1e-10) for alignment in alignments)
    @test overlap ≈ rho^3 atol = 1e-10
    @test sqrt(2 - 2overlap) ≈ sqrt(2 - 2rho^3) atol = 1e-10
    @test cond([1.0 rho^2; rho^2 1.0]) ≈
          (1 + rho^2) / (1 - rho^2) rtol = 1e-9

    histories = (
        plateau = [1.0, 1.0, 0.99],
        worsened = [1.0, 1.0, 1.2],
        progress = [1.0, 1.0, 0.5],
    )
    @test swamp_flags(histories.plateau; window = 2) == [false, false, true]
    @test swamp_flags(histories.worsened; window = 2) == [false, false, false]
    @test swamp_flags(histories.progress; window = 2) == [false, false, false]
    @test Tuple(
        progress_state(last(windowed_log_progress(errors; window = 2))) for
        errors in histories
    ) == (:plateau, :worsened, :progress)

    # RCG exposes genuine checkpoint errors, while component diagnostics are
    # reported only at the initial and final endpoints.
    dims, rank = (4, 3, 2), 2
    normalize_columns(F) = F ./ sqrt.(sum(abs2, F; dims = 1))
    true_factors = [normalize_columns(randn(rng, n, rank)) for n in dims]
    target = reconstruct_cpd_rankr([1.0, 0.7], true_factors)
    initial = CPDPoint(
        ones(rank),
        [normalize_columns(randn(rng, n, rank)) for n in dims],
    )
    requested = [0, 1, 2]
    solved = Dict{Int,Any}()
    relative_error(point) =
        norm(target - reconstruct_cpd_rankr(weights(point), factors(point))) / norm(target)
    diagnostic(point) = (
        distance = norm(factors(point)[1][:, 1] - factors(point)[1][:, 2]),
        condition = cond(factors(point)[1]' * factors(point)[1]),
    )
    trace = endpoint_manifold_trace(
        requested_iterations = requested,
        initial_point = initial,
        solve_checkpoint = iteration -> begin
            start = CPDPoint(copy(weights(initial)), copy.(factors(initial)))
            result = Logging.with_logger(Logging.NullLogger()) do
                cpd(
                    target,
                    rank;
                    solver = :rcg,
                    geometry = :canonical,
                    p0 = start,
                    maxiter = iteration,
                    tol = 0.0,
                    verbose = false,
                )
            end
            solved[iteration] = CPDPoint(weights(result), factors(result))
        end,
        error = relative_error,
        diagnostic = diagnostic,
    )
    expected_errors = vcat(
        relative_error(initial),
        [relative_error(solved[k]) for k in requested[2:end]],
    )
    @test Set(keys(solved)) == Set(requested[2:end])
    @test trace.errors ≈ expected_errors
    @test trace.distances === nothing && trace.conditions === nothing &&
          length(trace.points) == 2
    @test all(isfinite, (
        trace.initial_distance,
        trace.initial_condition,
        trace.final_distance,
        trace.final_condition,
    ))
end

@testset "Lab 4 concept-pipeline integrity" begin
    data = synthetic_concept_data()
    @test size(data.activations) == (12, 8)
    @test size(data.true_usage) == (12, 3)
    @test size(data.true_directions) == (8, 3)
    @test minimum(data.activations) >= 0

    history = nmf_trace(data.activations, 3)
    final_nmf = last(history)
    @test length(history) >= 5
    @test final_nmf.error < first(history).error
    @test final_nmf.error < 0.03
    @test minimum(final_nmf.U) >= 0
    @test minimum(final_nmf.W) >= 0

    sweep = rank_sweep(data)
    @test length(sweep) == 5
    @test sweep[3].error < sweep[1].error
    @test sweep[5].error <= sweep[3].error + 1e-8
    @test !hasproperty(sweep[3], :labels)
    @test all(length(indices) == 3 for indices in sweep[3].top_patches)
    @test isnothing(sweep[2].oracle)
    @test length(sweep[3].oracle) == 3
    @test all(0 <= match.overlap <= 1 for match in sweep[3].oracle)

    altered_truth = merge(data, (
        true_usage = reverse(data.true_usage; dims = 2),
        true_directions = reverse(data.true_directions; dims = 2),
        concept_names = ["oracle A", "oracle B", "oracle C"],
    ))
    altered_sweep = rank_sweep(altered_truth)
    paired = collect(zip(sweep, altered_sweep))
    @test all(reference.error ≈ altered.error for (reference, altered) in paired)
    @test all(reference.U ≈ altered.U for (reference, altered) in paired)
    @test all(reference.W ≈ altered.W for (reference, altered) in paired)
    @test all(
        reference.top_patches == altered.top_patches for
        (reference, altered) in paired
    )
    @test sweep[3].oracle != altered_sweep[3].oracle
end

@testset "Environment and export smoke tests" begin
    tutorial_project = TOML.parsefile(joinpath(ROOT, "Project.toml"))
    tutorial_manifest = TOML.parsefile(joinpath(ROOT, "Manifest.toml"))
    tensor_kitchen = only(tutorial_manifest["deps"]["TensorKitchen"])
    @test tutorial_project["compat"]["TensorKitchen"] == "=0.2.0"
    @test tensor_kitchen["version"] == "0.2.0"
    @test tensor_kitchen["repo-rev"] == "v0.2.0"

    tools_project = TOML.parsefile(joinpath(ROOT, "tools", "Project.toml"))
    tools_manifest = TOML.parsefile(joinpath(ROOT, "tools", "Manifest.toml"))
    @test tools_project["compat"]["Pluto"] == "=1.0.3"
    @test tools_project["compat"]["PlutoSliderServer"] == "=1.9.0"
    @test only(tools_manifest["deps"]["Pluto"])["version"] == "1.0.3"
    @test only(tools_manifest["deps"]["PlutoSliderServer"])["version"] == "1.9.0"
end
