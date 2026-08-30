using Test

const ROOT = normpath(joinpath(@__DIR__, ".."))
const PUBLIC_LAYOUT = isdir(joinpath(ROOT, "notebooks")) && !isdir(joinpath(ROOT, "src"))
const NOTEBOOK_DIR = PUBLIC_LAYOUT ? joinpath(ROOT, "notebooks") : joinpath(ROOT, "src")
const LAB4_NOTEBOOK = PUBLIC_LAYOUT ? "04_NeuralRepresentations.jl" : "Lab4_LowRankNeuralRepresentations.jl"

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
