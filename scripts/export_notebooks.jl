#!/usr/bin/env julia

"""
Export the learner-facing notebooks and optional glossary as self-contained
static HTML.

Pluto is intentionally installed in a separate tool environment because
TensorKitchen 0.2.0 and Pluto 1.0.3 currently require incompatible versions of
OrderedCollections when placed in one Julia project.

Recommended invocation:

    julia --project=@pluto scripts/export_notebooks.jl
"""

using Pluto

const ROOT = normpath(joinpath(@__DIR__, ".."))
const PUBLIC_LAYOUT = isdir(joinpath(ROOT, "notebooks")) && !isdir(joinpath(ROOT, "src"))
const HTML_DIR = PUBLIC_LAYOUT ? joinpath(ROOT, "html") : joinpath(ROOT, "output", "notebooks")

const NOTEBOOK_EXPORTS = PUBLIC_LAYOUT ? [
    joinpath("notebooks", "00_Primer.jl") => joinpath("html", "00_Primer.html"),
    joinpath("notebooks", "01_OneObjectManyCoordinates.jl") => joinpath("html", "01_OneObjectManyCoordinates.html"),
    joinpath("notebooks", "02_GeometryAtlas.jl") => joinpath("html", "02_GeometryAtlas.html"),
    joinpath("notebooks", "03_OptimizationFailureMuseum.jl") => joinpath("html", "03_OptimizationFailureMuseum.html"),
    joinpath("notebooks", "04_NeuralRepresentations.jl") => joinpath("html", "04_NeuralRepresentations.html"),
    joinpath("appendix", "GlossaryAppendix.jl") => joinpath("appendix", "GlossaryAppendix.html"),
] : [
    joinpath("src", "Intro_to_TensorKitchen.jl") => joinpath("output", "notebooks", "00_Primer.html"),
    joinpath("src", "Lab1_LowRankGeometry.jl") => joinpath("output", "notebooks", "01_OneObjectManyCoordinates.html"),
    joinpath("src", "Lab2_GeometryAtlas.jl") => joinpath("output", "notebooks", "02_GeometryAtlas.html"),
    joinpath("src", "Lab3_OptimizationFailureMuseum.jl") => joinpath("output", "notebooks", "03_OptimizationFailureMuseum.html"),
    joinpath("src", "Lab4_LowRankNeuralRepresentations.jl") => joinpath("output", "notebooks", "04_NeuralRepresentations.html"),
    joinpath("appendix", "GlossaryAppendix.jl") => joinpath("output", "notebooks", "06_GlossaryAppendix.html"),
]

function export_notebook(source_path, output_path)
    mkpath(dirname(output_path))
    session = Pluto.ServerSession(;
        options = Pluto.Configuration.from_flat_kwargs(
            disable_writing_notebook_files = true,
            auto_reload_from_file = false,
            capture_stdout = false,
        ),
    )
    notebook = nothing
    try
        notebook = Pluto.SessionActions.open(session, source_path; run_async = false)
        Pluto.update_run!(session, notebook, notebook.cells; run_async = false)
        failed_cells = [cell for cell in notebook.cells if cell.errored]
        if !isempty(failed_cells)
            for cell in failed_cells
                println(stderr, "Cell $(cell.cell_id) failed:")
                show(stderr, MIME"text/plain"(), cell.output.body)
                println(stderr)
            end
            error(
                "$(basename(source_path)) failed in $(length(failed_cells)) cell(s).",
            )
        end
        write(output_path, Pluto.generate_html(notebook; offline_bundle = true, disable_ui = true))
        println("Wrote $(output_path)")
    finally
        isnothing(notebook) || Pluto.SessionActions.shutdown(session, notebook; async = false)
    end
end

function export_all_notebooks(filters = String[])
    mkpath(HTML_DIR)
    for (source_relative_path, output_relative_path) in NOTEBOOK_EXPORTS
        selected = isempty(filters) || any(filter -> occursin(filter, source_relative_path) || occursin(filter, output_relative_path), filters)
        selected || continue
        export_notebook(
            joinpath(ROOT, source_relative_path),
            joinpath(ROOT, output_relative_path),
        )
    end
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    export_all_notebooks(ARGS)
end
