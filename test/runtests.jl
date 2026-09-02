using LinearAlgebra
using Logging
using Random
using Test
using TensorKitchen
using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const NOTEBOOK_DIR = joinpath(ROOT, "notebooks")
const DECK_DIR = joinpath(ROOT, "slides")
const NUMBERED_VISUAL_FILES = [
    "00_PrimerVisuals.jl",
    "01_OneObjectManyCoordinatesVisuals.jl",
    "02_GeometryAtlasVisuals.jl",
    "03_OptimizationFailureMuseumVisuals.jl",
    "04_NeuralRepresentationsVisuals.jl",
]
const NOTEBOOK_VISUAL_SOURCE = join(
    read.(joinpath.(Ref(NOTEBOOK_DIR), vcat("VisualCore.jl", NUMBERED_VISUAL_FILES)), String),
    '\n',
)

include(joinpath(NOTEBOOK_DIR, "Lab4ConceptData.jl"))
using .Lab4ConceptData
include(joinpath(NOTEBOOK_DIR, "Lab3TraceData.jl"))
using .Lab3TraceData
include(joinpath(NOTEBOOK_DIR, "Lab2CapacityData.jl"))
using .Lab2CapacityData
include(joinpath(NOTEBOOK_DIR, "ManualExecution.jl"))
using .ManualExecution
include(joinpath(NOTEBOOK_DIR, "NotebookVisuals.jl"))
using .NotebookVisuals
include(joinpath(ROOT, "scripts", "ArtifactConfig.jl"))
using .ArtifactConfig

const LEARNER_NOTEBOOKS = [
    "00_Primer.jl",
    "01_OneObjectManyCoordinates.jl",
    "02_GeometryAtlas.jl",
    "03_OptimizationFailureMuseum.jl",
    "04_NeuralRepresentations.jl",
]

@testset "Learners predict and observe; tests assert" begin
    for notebook in LEARNER_NOTEBOOKS
        source = read(joinpath(NOTEBOOK_DIR, notebook), String)
        @test !occursin("@assert", source)
        @test occursin("Paul Breiding · Se Eun Choi", source)
    end
    @test all(isfile, joinpath.(Ref(NOTEBOOK_DIR), NUMBERED_VISUAL_FILES))
    primer_visuals = NOTEBOOK_VISUAL_SOURCE
    @test !occursin("checks_passed", primer_visuals)
    @test !occursin("internal consistency checks", primer_visuals)
    @test occursin("Predicted and measured collision diagnostics", primer_visuals)
    @test occursin("ρ³ =", primer_visuals)
    @test occursin("(1+ρ²)/(1−ρ²)", primer_visuals)
end

@testset "Core learning path keeps formal detail optional" begin
    primer = read(joinpath(NOTEBOOK_DIR, "00_Primer.jl"), String)
    lab1 = read(joinpath(NOTEBOOK_DIR, "01_OneObjectManyCoordinates.jl"), String)
    lab2 = read(joinpath(NOTEBOOK_DIR, "02_GeometryAtlas.jl"), String)
    lab3 = read(joinpath(NOTEBOOK_DIR, "03_OptimizationFailureMuseum.jl"), String)
    visuals = NOTEBOOK_VISUAL_SOURCE
    exercises = read(joinpath(NOTEBOOK_DIR, "ExerciseContent.jl"), String)
    exercise_sheet = read(joinpath(NOTEBOOK_DIR, "05_ExerciseSheet.jl"), String)

    @test occursin("Why not flatten an activation tensor?", primer)
    @test occursin("manual_tensor_size_run_control", primer)
    @test occursin("Tensor used below", primer)
    @test occursin("flatten_vs_tensor_visual()", primer)
    @test occursin("Optional tensor mechanics", primer)
    @test occursin("All 60 entries remain", visuals)

    @test occursin("Optional advanced experiment", lab1)
    @test occursin("Symmetry-breaking perturbation ε · changes the tensor", lab1)
    @test occursin("Normalized representation", lab1)
    @test occursin("Intrinsic rank-one representation", lab1)

    @test occursin("Optional math · Formal manifold definitions", lab2)
    @test occursin("Optional tensor mechanics · How does HOSVD", lab2)
    @test !occursin("intrinsic dimension", lowercase(lab2))
    @test occursin("Optional challenge · Prove that the CP rank is exactly four", lab2)
    @test occursin("CP rank 4 is sufficient", lab2)
    @test occursin("CP rank 2 is insufficient", lab2)
    @test !occursin("60 to 10,000", lab2)
    @test occursin("run_atlas_capacity) && !isnothing(atlas_problem)", lab2)
    @test occursin("run_atlas_fits) && !isnothing(atlas_capacity)", lab2)
    @test occursin("run_atlas_summary) && !isnothing(cp_atlas)", lab2)
    @test count("reveal = false", lab2) >= 2

    @test occursin("components look more alike  →  separation falls  →  ALS update sensitivity rises", lab3)
    @test !occursin("d_{\\mathrm{coll}}", lab3)
    @test !occursin("q_{ij}", lab3)
    @test occursin("Optional math · Why does ALS conditioning blow up?", visuals)
    @test occursin("Optional math · How are overlap and separation computed?", visuals)
    @test occursin("Make the two components more alike", visuals)
    @test occursin("Redistribute shared signal", visuals)
    @test occursin("ALS update sensitivity", visuals)
    @test occursin("quiet_solver_call", lab3)
    @test !occursin("move ``ρ``", lab3)
    @test occursin("Geometry-aware RCG", lab3)
    @test occursin("Explore more · compare all four methods", lab3)
    @test !occursin("which eigenvalue becomes small", lowercase(exercises))
    @test !occursin("sign-invariant rank-one collision distance?", lowercase(exercises))
    @test !occursin("Record the sizes of the three unfoldings", exercises)
    @test occursin("complete rank-one patterns become easier or harder", exercises)
    @test occursin("slider, selector, or run button", exercise_sheet)
end

@testset "Primer tensor operations and decompositions" begin
    running_dimensions = manual_tensor_size_value("4,3,2|1", (3, 2, 2))
    @test running_dimensions == (4, 3, 2)
    @test manual_tensor_size_value("invalid|1", (3, 2, 2)) == (3, 2, 2)
    @test manual_tensor_size_value("1,3,3|1", (3, 2, 2)) == (3, 2, 2)
    @test manual_tensor_size_value("10000,3,3|1", (3, 2, 2)) == (3, 2, 2)
    size_control_html = repr(
        MIME("text/html"),
        manual_tensor_size_run_control("Set mode sizes"; default = (3, 2, 2)),
    )
    @test count("type=\"number\"", size_control_html) == 3
    @test occursin("Generate random tensor", size_control_html)
    running_seed = 20260901 + 100 * running_dimensions[1] +
                   10 * running_dimensions[2] + running_dimensions[3]
    running_tensor = randn(MersenneTwister(running_seed), running_dimensions...)

    unfoldings = [unfold_mode(running_tensor, mode) for mode = 1:3]
    @test size.(unfoldings) == [(4, 6), (3, 8), (2, 12)]
    mode_map_rng = MersenneTwister(20260902 + size(running_tensor, 1))
    mode_map = randn(mode_map_rng, size(running_tensor, 1) + 1, size(running_tensor, 1))
    @test size(mode_n_product(running_tensor, mode_map, 1)) == (5, 3, 2)

    multilinear_rng = MersenneTwister(2026082001)
    multilinear_tensor = randn(multilinear_rng, 4, 3, 3)
    maps = (
        randn(multilinear_rng, 2, 4),
        randn(multilinear_rng, 2, 3),
        randn(multilinear_rng, 2, 3),
    )
    after_mode1 = mode_n_product(multilinear_tensor, maps[1], 1)
    after_mode2 = mode_n_product(after_mode1, maps[2], 2)
    multilinear_result = mode_n_product(after_mode2, maps[3], 3)
    @test (size(after_mode1), size(after_mode2)) == ((2, 3, 3), (2, 2, 3))
    @test size(multilinear_result) == (2, 2, 2)
    @test length(multilinear_result) == 8

    tucker_result = tucker(running_tensor, (2, 2, 1); method = :sthosvd)
    Random.seed!(20260810)
    cp_result = cpd(
        running_tensor,
        2;
        solver = :als,
        init = :tucker,
        maxiter = 40,
        tol = 1e-8,
        verbose = false,
    )
    Random.seed!(20260810)
    btd_result = btd(
        running_tensor,
        2,
        (1, 1, 1);
        solver = :als,
        init = :random,
        maxiter = 20,
        tol = 1e-8,
        block_method = :sthosvd,
        max_stagnation_restarts = 0,
        verbose = false,
    )
    Random.seed!(20260810)
    nncp_result = nncpd(
        abs.(running_tensor),
        2;
        solver = :als,
        init = :random,
        maxiter = 40,
        tol = 1e-8,
        verbose = false,
    )
    results = (tucker_result, cp_result, btd_result, nncp_result)
    @test all(size(reconstruct(result)) == size(running_tensor) for result in results)
    @test all(all(isfinite, reconstruct(result)) for result in results)
    @test all(isfinite, [
        rel_error(running_tensor, tucker_result),
        rel_error(running_tensor, cp_result),
        rel_error(running_tensor, btd_result),
        rel_error(abs.(running_tensor), nncp_result),
    ])
    @test minimum(weights(nncp_result)) >= -1e-12
    @test minimum(minimum, factors(nncp_result)) >= -1e-12

    cp_original_factors = [
        Matrix{Float64}(I, 3, 3),
        Matrix{Float64}(I, 3, 3),
        [1.0 0.2 0.5; 0.1 1.0 -0.4],
    ]
    cp_generated = reconstruct_cpd_rankr([1.4, 1.0, 0.7], cp_original_factors)
    Random.seed!(2026082002)
    cp_recovered = cpd(
        cp_generated,
        3;
        solver = :als,
        init = :tucker,
        maxiter = 200,
        tol = 1e-12,
        verbose = false,
    )
    @test size.(factors(cp_recovered)) == [(3, 3), (3, 3), (2, 3)]
    @test size(reconstruct(cp_recovered)) == (3, 3, 2)
    @test norm(cp_generated - reconstruct(cp_recovered)) / norm(cp_generated) < 1e-8
end

@testset "Public @bind payloads stay inside server-side limits" begin
    @test manual_value("2.5", 0.0; minimum = -3.0, maximum = 3.0) == 2.5
    @test manual_value("100", 0.0; minimum = -3.0, maximum = 3.0) == 0.0
    @test manual_value("Inf", 0.0; minimum = -3.0, maximum = 3.0) == 0.0
    @test manual_value("not-a-boolean", true) === true
    @test manual_parameter_value("4.0|2", 0.0; minimum = 0.0, maximum = 4.0) == 4.0
    @test manual_parameter_value("4000|2", 0.0; minimum = 0.0, maximum = 4.0) == 0.0
    allowed_collisions = (0.20, 0.95, 0.995)
    @test manual_choice_value("0.95|1", allowed_collisions, 0.995) == 0.95
    @test manual_choice_value("0.951|1", allowed_collisions, 0.995) == 0.995
    @test_throws ArgumentError manual_value("1", 2.0; minimum = -1.0, maximum = 1.0)
end

@testset "Deterministic live presets are built once per process" begin
    clear_preset_cache!()
    builds = Ref(0)
    first_result = cached_preset((:test, 0.95)) do
        builds[] += 1
        [1.0, 2.0]
    end
    second_result = cached_preset((:test, 0.95)) do
        builds[] += 1
        [9.0]
    end
    @test builds[] == 1
    @test first_result === second_result
    clear_preset_cache!()
end

@testset "Two-tier deployment is explicit and pinned" begin
    tutorial_project = TOML.parsefile(joinpath(ROOT, "Project.toml"))
    @test tutorial_project["compat"]["TensorKitchen"] == "=0.2.0"
    tutorial_manifest = TOML.parsefile(joinpath(ROOT, "Manifest.toml"))
    tensor_kitchen = only(tutorial_manifest["deps"]["TensorKitchen"])
    @test tensor_kitchen["version"] == "0.2.0"
    @test tensor_kitchen["repo-rev"] == "v0.2.0"
    @test only(tutorial_manifest["deps"]["OrderedCollections"])["version"] == "2.0.1"

    tools_project = TOML.parsefile(joinpath(ROOT, "tools", "Project.toml"))
    @test tools_project["compat"]["Pluto"] == "=1.0.3"
    @test tools_project["deps"]["PlutoSliderServer"] == "2fc8631c-6f24-4c5b-bca7-cbb509c42db4"
    @test tools_project["compat"]["PlutoSliderServer"] == "=1.9.0"
    tools_manifest = TOML.parsefile(joinpath(ROOT, "tools", "Manifest.toml"))
    @test only(tools_manifest["deps"]["Pluto"])["version"] == "1.0.3"
    @test only(tools_manifest["deps"]["PlutoSliderServer"])["version"] == "1.9.0"
    @test only(tools_manifest["deps"]["OrderedCollections"])["version"] == "1.8.2"

    deployment = TOML.parsefile(joinpath(ROOT, "tools", "PlutoDeployment.toml"))
    @test !haskey(deployment["SliderServer"], "host")
    @test !haskey(deployment["SliderServer"], "port")
    @test deployment["SliderServer"]["watch_dir"] === false
    @test deployment["Export"]["number_of_parallel_tasks"] == 1

    live_script = read(joinpath(ROOT, "scripts", "run_live_server.jl"), String)
    @test occursin("notebook_paths = LIVE_NOTEBOOK_PATHS", live_script)
    @test occursin("relpath.", live_script)
    @test occursin("joinpath(NOTEBOOK_DIR, path)", live_script)
    @test occursin("1024 <= port <= 65535", live_script)
    @test occursin("Export_output_dir = export_dir", live_script)

    dockerfile = read(joinpath(ROOT, "deploy", "Dockerfile"), String)
    @test occursin("FROM julia:1.12.6-bookworm", dockerfile)
    @test occursin("USER tutorial", dockerfile)
    @test occursin("JULIA_PKG_OFFLINE=true", dockerfile)
    @test occursin("chmod -R a-w /app /opt/julia-depot", dockerfile)
    @test !occursin("chown -R tutorial", dockerfile)

    @test PACKAGE_NAME == "LowRankStructureIsGeometry-public"
    @test ZIP_FILENAME == "LowRankStructureIsGeometry-public.zip"
    @test any(target -> target.output == "html/05_ExerciseSheet.html", EXPORT_TARGETS)
    @test any(target -> target.output == "html/GlossaryAppendix.html", EXPORT_TARGETS)
    @test any(target -> target.output == "slides/TensorKitchen_Interactive_Intro_Deck.html", EXPORT_TARGETS)

    readme = read(joinpath(ROOT, "README.md"), String)
    @test occursin("isolated, resource-limited environment", readme)

    export_script = read(joinpath(ROOT, "scripts", "export_notebooks.jl"), String)
    @test occursin("Static preview", export_script)
    @test occursin("TENSORKITCHEN_LIVE_URL", export_script)
end

@testset "Primer comparison metrics use the displayed target" begin
    signed_target = reshape([-2.0, -1.0, 1.0, 2.0], 2, 2, 1)
    nonnegative_target = abs.(signed_target)
    nncp_reconstruction = copy(nonnegative_target)
    reconstructions = (NNCP = nncp_reconstruction,)
    fingerprints = (NNCP = ["rank: 1"],)
    nonnegative_error = (NNCP = 0.0,)

    @test tensor_reconstruction_gallery(
        nonnegative_target,
        reconstructions;
        errors = nonnegative_error,
        fingerprints = fingerprints,
    ) isa Base.HTML
    @test_throws ArgumentError tensor_reconstruction_gallery(
        signed_target,
        reconstructions;
        errors = nonnegative_error,
        fingerprints = fingerprints,
    )

    primer = read(joinpath(NOTEBOOK_DIR, "00_Primer.jl"), String)
    @test occursin("Part A — Same signed target", primer)
    @test occursin("Part B — Constraint-specific NNCP example", primer)
    @test occursin("not directly comparable", primer)
end

@testset "Lab 1 gauge and CP equivalence invariants" begin
    A = [1.0 0.5; -0.5 1.0; 0.75 -1.0; 1.25 0.25]
    B = [0.5 -1.0; 1.0 0.25; -0.75 0.5]
    X = A * B'
    for log10_scale in (-6.0, -2.0, 0.0, 2.0, 6.0)
        scale = 10.0^log10_scale
        Q = Diagonal([scale, inv(scale)])
        transformed = (A * Q) * (B * inv(Q)')'
        @test norm(X - transformed) / norm(X) < 1e-10
        @test cond(Matrix(Q)) ≈ 10.0^(2 * abs(log10_scale)) rtol = 1e-12
    end

    rng = MersenneTwister(20260901)
    factors_original = [randn(rng, dimension, 2) for dimension in (5, 4, 3)]
    weights_original = [1.5, 0.75]
    object_original = reconstruct_cpd_rankr(weights_original, factors_original)
    alpha, beta = 1e3, 1e-2
    factors_equivalent = copy.(factors_original)
    factors_equivalent[1] .*= alpha
    factors_equivalent[2] .*= beta
    factors_equivalent[3] ./= alpha * beta
    permutation = [2, 1]
    object_equivalent = reconstruct_cpd_rankr(
        weights_original[permutation],
        [factor[:, permutation] for factor in factors_equivalent],
    )
    @test norm(object_original - object_equivalent) / norm(object_original) < 1e-10
    factors_perturbed = copy.(factors_equivalent)
    factors_perturbed[1][1, 1] += 1e-3
    object_perturbed = reconstruct_cpd_rankr(weights_original, factors_perturbed)
    @test norm(object_original - object_perturbed) / norm(object_original) > 1e-14
end

@testset "Lab 3 collision predictions match measurements" begin
    rho = 0.9
    rng = MersenneTwister(27)
    bases = [Matrix(qr(randn(rng, dimension, 3)).Q)[:, 1:3] for dimension in (4, 4, 3)]
    factors_collision = [
        hcat(
            basis[:, 1],
            rho .* basis[:, 1] .+ sqrt(1 - rho^2) .* basis[:, 2],
            basis[:, 3],
        ) for basis in bases
    ]
    measured_alignments = [dot(F[:, 1], F[:, 2]) for F in factors_collision]
    measured_overlap = abs(prod(measured_alignments))
    als_gram = [1.0 rho^2; rho^2 1.0]
    @test all(isapprox(alignment, rho; atol = 1e-10) for alignment in measured_alignments)
    @test measured_overlap ≈ rho^3 atol = 1e-10
    @test sqrt(2 - 2 * measured_overlap) ≈ sqrt(2 - 2 * rho^3) atol = 1e-10
    @test cond(als_gram) ≈ (1 + rho^2) / (1 - rho^2) rtol = 1e-9

    term1 = reconstruct_cpd_rankr([100.0], [F[:, 1:1] for F in factors_collision])
    term2 = reconstruct_cpd_rankr([-99.0], [F[:, 1:1] for F in factors_collision])
    residual = term1 + term2
    cancellation_ratio = (norm(term1) + norm(term2)) / norm(residual)
    @test cancellation_ratio > 10
end

@testset "Swamp heuristic separates plateaus from worsening" begin
    plateau_errors = [1.0, 1.0, 0.99]
    worsening_errors = [1.0, 1.0, 1.2]
    progress_errors = [1.0, 1.0, 0.5]

    @test swamp_flags(plateau_errors; window = 2) == [false, false, true]
    @test swamp_flags(worsening_errors; window = 2) == [false, false, false]
    @test swamp_flags(progress_errors; window = 2) == [false, false, false]
    @test progress_state(last(windowed_log_progress(worsening_errors; window = 2))) == :worsened
    @test progress_state(last(windowed_log_progress(plateau_errors; window = 2))) == :plateau
    @test progress_state(last(windowed_log_progress(progress_errors; window = 2))) == :progress
end

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
    @test !occursin("anchor =", data_source)
end

@testset "Lab 2 teaches matrix and tensor geometry with modern AI bridges" begin
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

end

@testset "Slide deck uses explicit CP outer-product illustrations" begin
    visuals = read(joinpath(DECK_DIR, "IntroDeckVisuals.jl"), String)
    deck = read(joinpath(DECK_DIR, "TensorKitchen_Interactive_Intro_Deck.jl"), String)
    @test count("cpd_sum_svg(", visuals) >= 2
    @test occursin("Why now? Low rank is becoming a design principle in modern AI", deck)
    @test occursin("One low-rank idea — different geometric objects", deck)
    @test occursin("why_now_visual()", deck)
    @test occursin("geometry_language_visual()", deck)
    @test occursin("Reveal next role", visuals)
    @test occursin("RAdaGrad / RAdamW", visuals)
    @test occursin("Tensor Decomposition Networks", visuals)
    @test occursin("What evidence makes an interpretation defensible?", visuals)
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
            result = Logging.with_logger(Logging.NullLogger()) do
                cpd(
                    target,
                    rank;
                    solver = :rcg,
                    geometry = :canonical,
                    p0 = fresh_start,
                    maxiter = iteration,
                    tol = 0.0,
                    verbose = false,
                )
            end
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
