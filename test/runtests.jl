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

@testset "Terminology and model-family precision" begin
    glossary = read(joinpath(ROOT, "appendix", "GlossaryContent.jl"), String)
    lab2 = read(joinpath(NOTEBOOK_DIR, "02_GeometryAtlas.jl"), String)
    lab4 = read(joinpath(NOTEBOOK_DIR, LAB4_NOTEBOOK), String)
    lab4_visuals = read(joinpath(NOTEBOOK_DIR, "Lab4ConceptVisuals.jl"), String)
    curriculum = read(joinpath(ROOT, "CURRICULUM.md"), String)

    @test occursin("Randomized Alternating Least Squares", glossary)
    @test occursin("Randomized CP-ALS (CPRAND/CPRAND-MIX)", glossary)
    @test occursin("term=\"Regularized ALS\"", glossary)
    @test occursin("ridge-regularized ALS", glossary)
    @test !occursin("term=\"RALS\", category=\"Mathematics\", definition=\"Regularized", glossary)
    @test !occursin("\\text{observed error}\n=", lab2)
    @test occursin("not an\nexact additive decomposition", lab2)
    @test occursin("multilinear rank at most", lab2)
    @test occursin("fixed-rank stratum", lab2)
    @test occursin("hypothetical nonnegative BTD-style model", lab4)
    @test occursin("not a nonnegative BTD solver", lab4)
    @test occursin("Nonnegative BTD-style · conceptual", lab4_visuals)
    @test occursin("not exhaustively validate every solver trajectory", curriculum)
    @test occursin("does not expose LM as a CPD solver", glossary)

    lab1 = read(joinpath(NOTEBOOK_DIR, "01_OneObjectManyCoordinates.jl"), String)
    @test !occursin("component_trace_cost_history", lab1)
    @test !occursin("component_trace_cost_history", read(joinpath(NOTEBOOK_DIR, "03_OptimizationFailureMuseum.jl"), String))
    @test !occursin("solver = :lm", read(joinpath(NOTEBOOK_DIR, "03_OptimizationFailureMuseum.jl"), String))
    @test occursin("deterministic reruns from the same start", lab1)
end

@testset "Flattening visual preserves a dense set of entries" begin
    visuals = read(joinpath(DECK_DIR, "IntroDeckVisuals.jl"), String)
    @test occursin("Same 80 entries", visuals)
    @test occursin("4 × 5 × 4 = 80 entries", visuals)
    @test occursin("4 × 20 = 80 entries", visuals)
    @test occursin("for feature = 1:4, sample = 1:4, space = 1:5", visuals)
    @test occursin("matrix_column = (feature - 1) * 5 + space", visuals)
    @test occursin("transition:transform 1.15s", visuals)
    @test occursin("entries rearrange from four 4 by 5 slices", visuals)
    @test occursin("slice_skew = tan(deg2rad(-6))", visuals)
    @test occursin("matrix_guide =", visuals)
    @test !occursin("matrix_guides = join", visuals)
    @test occursin("width:308px; height:77px", visuals)
    @test occursin("background:var(--tk-gray)", visuals)
end

@testset "Tensor anatomy builds a 5 by 3 by 2 object one mode at a time" begin
    visuals = read(joinpath(DECK_DIR, "IntroDeckVisuals.jl"), String)
    @test occursin("5 × 3 × 2 tensor", visuals)
    @test occursin("5-vector", visuals)
    @test occursin("5 × 3 matrix slice", visuals)
    @test occursin("repeat(5,36px)", visuals)
    @test occursin("for j = 1:3", visuals)
    @test occursin("three 5-entry fibers together", visuals)
    @test occursin("stacks two complete 5 × 3 matrix slices", visuals)
    @test occursin("<strong>30</strong><div class=\"tk-muted\">entries", visuals)
end

@testset "Tucker rank visual scales structure and reports compression" begin
    visuals = read(joinpath(DECK_DIR, "IntroDeckVisuals.jl"), String)
    notebook = read(joinpath(DECK_DIR, "TensorKitchen_Interactive_Intro_Deck.jl"), String)
    @test occursin("--core-w", visuals)
    @test occursin("(18+11*r[1])+'px'", visuals)
    @test occursin("(18+11*r[0])+'px'", visuals)
    @test occursin("(3+3*r[2])+'px'", visuals)
    @test occursin("--f1-thickness", visuals)
    @test occursin("const thickness=3+5*rank", visuals)
    @test occursin("repeating-linear-gradient", visuals)
    @test occursin("height:160px; border-radius:var(--f2-radius)", visuals)
    @test occursin("height:135px; border-radius:var(--f3-radius)", visuals)
    @test occursin("left:calc(50% + 120px); top:50%; transform-origin:left center", visuals)
    @test count("max=\"7\" step=\"2\"", visuals) == 3
    @test count("class=\"rank-ticks\"", visuals) == 3
    @test occursin("deck_rank_levels = (1, 3, 5, 7)", notebook)
    @test occursin("for r₁ in deck_rank_levels", notebook)
    @test occursin("compression ratio", visuals)
    @test occursin("full entries ÷", visuals)
end

@testset "Gauge visual shows many Q coordinates with one fixed object" begin
    visuals = read(joinpath(DECK_DIR, "IntroDeckVisuals.jl"), String)
    @test occursin("Choose a coordinate change Q", visuals)
    @test occursin("data-q=\"rotate\"", visuals)
    @test occursin("data-q=\"shear\"", visuals)
    @test occursin("data-q=\"stretch\"", visuals)
    @test occursin("A′ = AQ", visuals)
    @test occursin("B′ = BQ⁻ᵀ", visuals)
    @test occursin("before · X", visuals)
    @test occursin("after · X(Q)", visuals)
    @test occursin("Same matrix X", visuals)
    @test occursin("relative change ≈ 0", visuals)
    @test !occursin("gauge scale · log₁₀(s)", visuals)
    @test !occursin("κ(Q)", visuals)
end

@testset "Glossary appendix is wired into the release pipeline" begin
    root = ROOT
    notebook = read(joinpath(root, "appendix", "GlossaryAppendix.jl"), String)
    content = read(joinpath(root, "appendix", "GlossaryContent.jl"), String)
    cell_order = split(notebook, "# ╔═╡ Cell order:"; limit = 2)[2]
    exporter = read(joinpath(root, "scripts", "export_notebooks.jl"), String)
    pdf_builder = read(joinpath(root, "scripts", "build_glossary_appendix.jl"), String)
    latex_generator = read(joinpath(root, "scripts", "generate_glossary_latex.jl"), String)

    @test isfile(joinpath(root, "appendix", "GlossaryAppendix.tex"))
    @test occursin("GlossaryContent.jl", notebook)
    @test occursin("const RAW_MATH_GLOSSARY", content)
    @test occursin("const RAW_AI_GLOSSARY", content)
    @test length(collect(eachmatch(r"\(term=", content))) >= 100
    @test occursin("const NOTE_CONFIG", content)
    @test occursin("const CLUSTER_ORDER", content)
    @test occursin("<details class=\"glossary-detail", notebook)
    @test !occursin("<b>Definition.</b>", notebook)
    @test !occursin("entry.related", notebook)
    @test !occursin("# ╠═", cell_order)
    @test occursin("appendix\", \"GlossaryAppendix.jl", exporter)
    @test occursin("GlossaryAppendix.html", exporter)
    @test occursin("generate_glossary_latex()", pdf_builder)
    @test occursin("GlossaryContent.jl", latex_generator)
    @test occursin("GlossaryAppendix.pdf", pdf_builder)
    if PUBLIC_LAYOUT
        rebuild = read(joinpath(root, "scripts", "rebuild_all.jl"), String)
        @test occursin("export_notebooks.jl", rebuild)
        @test occursin("build_glossary_appendix.jl", rebuild)
    else
        packager = read(joinpath(root, "scripts", "build_teaching_package.jl"), String)
        @test occursin("GlossaryContent.jl", packager)
        @test occursin("GlossaryAppendix.pdf", packager)
    end
end

@testset "Student-facing Lab 4 excludes developer controls" begin
    notebook = read(joinpath(NOTEBOOK_DIR, LAB4_NOTEBOOK), String)
    visuals = read(joinpath(NOTEBOOK_DIR, "Lab4ConceptVisuals.jl"), String)
    cell_order = split(notebook, "# ╔═╡ Cell order:"; limit = 2)[2]
    @test !occursin("manual_run_button", notebook)
    @test !occursin("Lab 4 checks", notebook)
    @test occursin("Low Rank Neural Representations", notebook)
    @test occursin("## Before we start", notebook)
    @test occursin("candidate concepts, not automatically validated meanings", notebook)
    @test occursin("Dictionary learning", notebook)
    @test occursin("not part of\n    CRAFT", notebook)
    @test !occursin("# ╠═", cell_order)
    @test occursin("composition-panel", visuals)
    @test occursin("grid-template-columns:minmax(220px,.8fr) minmax(0,1.2fr)", visuals)
end
