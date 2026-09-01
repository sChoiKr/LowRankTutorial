using LinearAlgebra
using Random
using Test
using TensorKitchen

const ROOT = normpath(joinpath(@__DIR__, ".."))
const PUBLIC_LAYOUT = isdir(joinpath(ROOT, "notebooks")) && !isdir(joinpath(ROOT, "src"))
const NOTEBOOK_DIR = PUBLIC_LAYOUT ? joinpath(ROOT, "notebooks") : joinpath(ROOT, "src")
const DECK_DIR = PUBLIC_LAYOUT ? joinpath(ROOT, "slides") : joinpath(ROOT, "src")
const LAB4_NOTEBOOK = PUBLIC_LAYOUT ? "04_NeuralRepresentations.jl" : "Lab4_LowRankNeuralRepresentations.jl"

include(joinpath(NOTEBOOK_DIR, "Lab4ConceptData.jl"))
using .Lab4ConceptData
include(joinpath(NOTEBOOK_DIR, "Lab3TraceData.jl"))
using .Lab3TraceData
include(joinpath(NOTEBOOK_DIR, "Lab2CapacityData.jl"))
using .Lab2CapacityData

@testset "Lab 4 synthetic concept pipeline" begin
    data = synthetic_concept_data()
    @test size(data.activations) == (12, 8)
    @test size(data.true_usage) == (12, 3)
    @test size(data.true_directions) == (8, 3)
    @test minimum(data.activations) >= 0

    history = nmf_trace(data.activations, 3)
    @test length(history) >= 5
    @test last(history).error < first(history).error
    @test last(history).error < 0.03
    @test minimum(last(history).U) >= 0
    @test minimum(last(history).W) >= 0

    sweep = rank_sweep(data)
    @test length(sweep) == 5
    @test sweep[3].error < sweep[1].error
    @test sweep[5].error <= sweep[3].error + 1e-8
    @test !hasproperty(sweep[3], :labels)
    @test length(sweep[3].top_patches) == 3
    @test all(length(indices) == 3 for indices in sweep[3].top_patches)
    @test isnothing(sweep[2].oracle)
    @test length(sweep[3].oracle) == 3
    @test all(0 <= match.overlap <= 1 for match in sweep[3].oracle)

    # The optimization must not depend on planted semantic truth. Only the
    # separate oracle evaluation is allowed to inspect these fields.
    altered_truth = merge(data, (
        true_usage = reverse(data.true_usage; dims = 2),
        true_directions = reverse(data.true_directions; dims = 2),
        concept_names = ["oracle A", "oracle B", "oracle C"],
    ))
    altered_sweep = rank_sweep(altered_truth)
    for (reference, altered) in zip(sweep, altered_sweep)
        @test reference.error ≈ altered.error
        @test reference.U ≈ altered.U
        @test reference.W ≈ altered.W
        @test reference.top_patches == altered.top_patches
        @test reference.error ≈ norm(data.activations - reference.U * reference.W') / norm(data.activations)
        @test minimum(reference.U) >= 0
        @test minimum(reference.W) >= 0
    end
    @test sweep[3].oracle != altered_sweep[3].oracle

    svd_fit = svd_representation(data.activations, 3)
    @test svd_fit.error <= last(history).error + 1e-8

    coefficients = vec(data.true_usage[5, :])
    proxy = concept_importance_proxy(coefficients)
    @test argmax(coefficients) != argmax(proxy)
    @test isapprox(sum(proxy), 1.0; atol = 1e-10)
end

@testset "Lab 4 separates NMF output from semantic oracle labels" begin
    data_source = read(joinpath(NOTEBOOK_DIR, "Lab4ConceptData.jl"), String)
    visual_source = read(joinpath(NOTEBOOK_DIR, "Lab4ConceptVisuals.jl"), String)
    notebook_source = read(joinpath(NOTEBOOK_DIR, LAB4_NOTEBOOK), String)
    @test !occursin("anchor =", data_source)
    @test !occursin("aligned_to_truth", data_source)
    @test !occursin("vocabulary = Dict", data_source)
    @test occursin("U = 0.15 .+ rand", data_source)
    @test occursin("oracle = rank == size", data_source)
    @test !occursin("Current concept vocabulary", visual_source)
    @test !occursin("rank_vocabulary_visual", visual_source)
    @test occursin("Candidate factors returned by NMF", visual_source)
    @test occursin("NMF supplies no semantic name", visual_source)
    @test occursin("evaluation only", visual_source)
    @test occursin("Your label hypothesis", visual_source)
    @test !occursin("anchor = concept_data", notebook_source)
    @test occursin("factorization output", notebook_source)
    @test occursin("vec(nmf_fit.U[importance_crop, :])", notebook_source)
end

@testset "Lab 2 teaches matrix and tensor geometry with modern AI bridges" begin
    lab2 = read(joinpath(NOTEBOOK_DIR, "02_GeometryAtlas.jl"), String)
    visuals = read(joinpath(NOTEBOOK_DIR, "NotebookVisuals.jl"), String)
    curriculum = read(joinpath(ROOT, "CURRICULUM.md"), String)
    @test occursin("\\mathrm{St}(n,r)", lab2)
    @test occursin("\\mathcal M_r", lab2)
    @test occursin("\\mathrm{rank}(W)=r", lab2)
    @test occursin("W=AB^\\top", lab2)
    @test occursin("JoinModel", lab2)
    @test occursin("StelLA", lab2)
    @test occursin("RAdaGrad/RAdamW", lab2)
    @test occursin("Tensor Decomposition Networks", lab2)
    @test occursin("ai_geometry_bridge_visual()", lab2)
    @test occursin("function ai_geometry_bridge_visual", visuals)
    @test occursin("Stiefel frame", visuals)
    @test occursin("Fixed-rank matrix", visuals)
    @test occursin("Segre component", visuals)
    @test occursin("Tucker object", visuals)
    @test occursin("conceptual bridges rather than reproductions", curriculum)

    rng = Random.MersenneTwister(20260831)
    U = Matrix(qr(randn(rng, 6, 2)).Q)[:, 1:2]
    V = Matrix(qr(randn(rng, 5, 2)).Q)[:, 1:2]
    S = [1.4 0.2; -0.1 0.8]
    Q = [0.0 -1.0; 1.0 0.0]
    R = [0.0 1.0; -1.0 0.0]
    W = U * S * V'
    transformed = (U * Q) * (Q' * S * R) * (V * R)'
    @test U' * U ≈ Matrix{Float64}(I, 2, 2)
    @test U * U' ≈ (U * Q) * (U * Q)'
    @test W ≈ transformed
    @test rank(W) == 2
end

@testset "Lab 2 separates exact model capacity from achieved fit" begin
    problem = make_two_block_tensor()
    oracle_cp = cp_oracle_representation(problem)
    oracle_btd = sum(problem.true_blocks)
    oracle_tucker = tucker(problem.target, (4, 4, 2); method = :sthosvd)

    @test size(problem.target) == (10, 10, 6)
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
    @test cp2_floor.mode_bounds[1] > 0
    @test tucker221_floor.mode_bounds[3] > 0
    reduced_tucker = tucker(problem.target, (2, 2, 1); method = :sthosvd)
    @test rel_error(problem.target, reduced_tucker) + 1e-12 >= tucker221_floor.lower_bound

    hosvd_rng = MersenneTwister(2026082004)
    hosvd_tensor = randn(hosvd_rng, 3, 3, 2)
    unfoldings = [mode_unfolding(hosvd_tensor, mode) for mode = 1:3]
    @test size.(unfoldings) == [(3, 6), (3, 6), (2, 9)]
    @test Tuple(rank(unfolding) for unfolding in unfoldings) == (3, 3, 2)
    hosvd_fit = tucker(hosvd_tensor, (3, 3, 2); method = :sthosvd)
    @test rel_error(hosvd_tensor, hosvd_fit) < 1e-12

    lab2 = read(joinpath(NOTEBOOK_DIR, "02_GeometryAtlas.jl"), String)
    visuals = read(joinpath(NOTEBOOK_DIR, "NotebookVisuals.jl"), String)
    @test !occursin("Run Lab 2 checks", lab2)
    @test !occursin("@assert", lab2)
    @test occursin("Can the model represent it, and can the algorithm find it?", lab2)
    @test occursin("more iterations cannot repair insufficient model capacity", lab2)
    @test occursin("Give CP rank 2 a 500-sweep budget", lab2)
    @test occursin("rigorous lower bound for every CP-rank-2 tensor", lab2)
    @test occursin("capacity_fit_visual(", lab2)
    @test occursin("model_language_visual()", lab2)
    @test occursin("function capacity_fit_visual", visuals)
    @test occursin("function model_language_visual", visuals)
    @test occursin("Sufficient capacity", visuals)
    @test occursin("Reduced capacity", visuals)
    @test occursin("rigorous lower bound on error", visuals)
end

@testset "Slide deck uses explicit CP outer-product illustrations" begin
    visuals = read(joinpath(DECK_DIR, "IntroDeckVisuals.jl"), String)
    @test count("cpd_sum_svg(", visuals) >= 2
    @test occursin("cp_component_outer_svg", visuals)
    @test occursin("cp_model_abstract_svg", visuals)
    @test occursin("data-vector=\"sample\"", visuals)
    @test occursin("component 1", visuals)
    @test occursin("component R", visuals)
    @test occursin("+ ⋯ +", visuals)
    @test occursin("data-vector-stick=\"c\"", visuals)
    @test !occursin("data-depth-face", visuals)
    @test occursin("all factors ≥ 0", visuals)
    @test occursin("nncp-model-glyph", visuals)
    @test occursin("three vectors form one rank-1 tensor", visuals)
    @test occursin("CPD = sum of rank-1 outer products", visuals)
    @test !occursin(".rank-one::before", visuals)
end

@testset "Lab 3 distinguishes stored diagnostic traces from final endpoints" begin
    lab3 = read(joinpath(NOTEBOOK_DIR, "03_OptimizationFailureMuseum.jl"), String)
    trace_source = read(joinpath(NOTEBOOK_DIR, "Lab3TraceData.jl"), String)
    visuals = read(joinpath(NOTEBOOK_DIR, "NotebookVisuals.jl"), String)
    @test !occursin("fill(final_diagnostic.distance", lab3)
    @test !occursin("fill(final_diagnostic.condition", lab3)
    @test occursin("endpoint_manifold_trace(", lab3)
    @test occursin("distances = nothing", trace_source)
    @test occursin("conditions = nothing", trace_source)
    @test occursin("diagnostic_trace = false", trace_source)
    @test occursin("diagnostic_trace = true", lab3)
    @test occursin("RCG and RGD do not have an iteration-level", lab3)
    @test !occursin("increase directional separation more quickly", lab3)
    @test occursin("Iteration-level distance · stored block-solver points only", visuals)
    @test occursin("Final minimum rank-one distance · all solvers", visuals)
    @test occursin("Final ALS-system condition · all solvers", visuals)
    @test occursin("Evidence boundary:", visuals)
end

@testset "Manifold trace regression uses real solver history and endpoint diagnostics" begin
    rng = MersenneTwister(20260831)
    dims = (4, 3, 2)
    rank = 2
    normalize_columns(F) = F ./ sqrt.(sum(abs2, F; dims = 1))
    true_factors = [normalize_columns(randn(rng, n, rank)) for n in dims]
    target = reconstruct_cpd_rankr([1.0, 0.7], true_factors)
    initial = CPDPoint(ones(rank), [normalize_columns(randn(rng, n, rank)) for n in dims])
    stored_initial = CPDPoint(copy(weights(initial)), copy.(factors(initial)))
    requested = [0, 1, 2, 4]

    relative_error(point) = norm(target - reconstruct_cpd_rankr(weights(point), factors(point))) / norm(target)
    function endpoint_diagnostic(point)
        first_factor = factors(point)[1]
        return (
            distance = norm(first_factor[:, 1] - first_factor[:, 2]),
            condition = cond(first_factor' * first_factor),
        )
    end
    solved_checkpoints = Dict{Int,Any}()
    trace = endpoint_manifold_trace(
        requested_iterations = requested,
        initial_point = stored_initial,
        solve_checkpoint = iteration -> begin
            fresh_start = CPDPoint(copy(weights(initial)), copy.(factors(initial)))
            result = cpd(
                target,
                rank;
                solver = :rcg,
                geometry = :canonical,
                p0 = fresh_start,
                maxiter = iteration,
                tol = 0.0,
                verbose = false,
            )
            point = CPDPoint(weights(result), factors(result))
            solved_checkpoints[iteration] = point
            point
        end,
        error = relative_error,
        diagnostic = endpoint_diagnostic,
    )

    expected_errors = vcat(
        relative_error(stored_initial),
        [relative_error(solved_checkpoints[k]) for k in Iterators.drop(requested, 1)],
    )
    @test trace.errors ≈ expected_errors
    @test trace.distances === nothing
    @test trace.conditions === nothing
    @test trace.diagnostic_trace === false
    @test length(trace.points) == 2
    @test relative_error(trace.points[1]) ≈ relative_error(stored_initial)
    @test Set(keys(solved_checkpoints)) == Set(requested[2:end])
    @test relative_error(trace.points[2]) ≈ relative_error(solved_checkpoints[last(requested)])
    @test trace.initial_distance ≈ endpoint_diagnostic(stored_initial).distance
    @test trace.initial_condition ≈ endpoint_diagnostic(stored_initial).condition
    @test trace.final_distance ≈ endpoint_diagnostic(solved_checkpoints[last(requested)]).distance
    @test trace.final_condition ≈ endpoint_diagnostic(solved_checkpoints[last(requested)]).condition
end