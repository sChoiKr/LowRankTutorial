using Test

const ROOT = normpath(joinpath(@__DIR__, ".."))
const PUBLIC_LAYOUT = isdir(joinpath(ROOT, "notebooks")) && !isdir(joinpath(ROOT, "src"))
const NOTEBOOK_DIR = PUBLIC_LAYOUT ? joinpath(ROOT, "notebooks") : joinpath(ROOT, "src")
const DECK_DIR = PUBLIC_LAYOUT ? joinpath(ROOT, "slides") : joinpath(ROOT, "src")
const LAB4_NOTEBOOK = PUBLIC_LAYOUT ? "04_NeuralRepresentations.jl" : "Lab4_LowRankNeuralRepresentations.jl"
const AUTHOR_NAMES = ("Paul Breiding", "Se Eun Choi")

@testset "Every learner-facing source credits both authors" begin
    authored_sources = [
        joinpath(NOTEBOOK_DIR, "00_Primer.jl"),
        joinpath(NOTEBOOK_DIR, "01_OneObjectManyCoordinates.jl"),
        joinpath(NOTEBOOK_DIR, "02_GeometryAtlas.jl"),
        joinpath(NOTEBOOK_DIR, "03_OptimizationFailureMuseum.jl"),
        joinpath(NOTEBOOK_DIR, "04_NeuralRepresentations.jl"),
        joinpath(NOTEBOOK_DIR, "05_ExerciseSheet.jl"),
        joinpath(ROOT, "slides", "TensorKitchen_Interactive_Intro_Deck.jl"),
        joinpath(ROOT, "appendix", "GlossaryAppendix.jl"),
        joinpath(ROOT, "instructor", "TeachingNotes.md"),
    ]
    for path in authored_sources
        content = read(path, String)
        for author in AUTHOR_NAMES
            @test occursin(author, content)
        end
    end

    exercise_content = read(joinpath(NOTEBOOK_DIR, "ExerciseContent.jl"), String)
    @test occursin("Paul Breiding · Se Eun Choi", exercise_content)
    glossary_generator = read(joinpath(ROOT, "scripts", "generate_glossary_latex.jl"), String)
    @test occursin("Paul Breiding \\\\and Se Eun Choi", glossary_generator)
end

include(joinpath(NOTEBOOK_DIR, "Lab4ConceptData.jl"))
using .Lab4ConceptData

@testset "Lab 4 synthetic concept pipeline" begin
    data = synthetic_concept_data()
    @test size(data.activations) == (12, 8)
    @test size(data.true_usage) == (12, 3)
    @test size(data.true_directions) == (8, 3)
    @test minimum(data.activations) >= 0

    history = nmf_trace(data.activations, 3; anchor = data)
    @test length(history) >= 5
    @test last(history).error < first(history).error
    @test last(history).error < 0.03
    @test minimum(last(history).U) >= 0
    @test minimum(last(history).W) >= 0

    sweep = rank_sweep(data)
    @test length(sweep) == 5
    @test sweep[3].error < sweep[1].error
    @test sweep[5].error <= sweep[3].error + 1e-8

    svd_fit = svd_representation(data.activations, 3)
    @test svd_fit.error <= last(history).error + 1e-8

    coefficients = vec(data.true_usage[5, :])
    proxy = concept_importance_proxy(coefficients)
    @test argmax(coefficients) != argmax(proxy)
    @test isapprox(sum(proxy), 1.0; atol = 1e-10)
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

@testset "Why-now slide connects low-rank geometry to current AI uses" begin
    visuals = read(joinpath(DECK_DIR, "IntroDeckVisuals.jl"), String)
    notebook = read(joinpath(DECK_DIR, "TensorKitchen_Interactive_Intro_Deck.jl"), String)
    @test occursin("why_now_visual", visuals)
    @test occursin("why_now_visual()", notebook)
    @test occursin("Modern AI is rediscovering", visuals)
    @test occursin("Tensor Product Attention Is All You Need", visuals)
    @test occursin("Tensor Decomposition Networks for Fast ML Interatomic Potentials", visuals)
    @test occursin("Towards Interpretability Without Sacrifice", visuals)
    @test occursin("Efficiency", visuals)
    @test occursin("Scientific AI", visuals)
    @test occursin("Interpretability", visuals)
    @test occursin("<span>02</span>", visuals)
    @test occursin("<span>12</span>", visuals)
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
