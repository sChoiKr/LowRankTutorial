#!/usr/bin/env julia

using Pluto

function main(args)
    repository_root = normpath(joinpath(@__DIR__, ".."))
    public_layout = isdir(joinpath(repository_root, "notebooks")) && !isdir(joinpath(repository_root, "src"))
    default_notebook = public_layout ?
        joinpath(repository_root, "slides", "TensorKitchen_Interactive_Intro_Deck.jl") :
        joinpath(repository_root, "src", "TensorKitchen_Interactive_Intro_Deck.jl")
    default_output = public_layout ?
        joinpath(repository_root, "slides", "TensorKitchen_Interactive_Intro_Deck.html") :
        joinpath(repository_root, "output", "TensorKitchen_Interactive_Intro_Deck.html")
    notebook_path = get(args, 1, default_notebook)
    output_path = get(args, 2, default_output)

    session = Pluto.ServerSession(;
        options = Pluto.Configuration.from_flat_kwargs(
            disable_writing_notebook_files = true,
            auto_reload_from_file = false,
            capture_stdout = false,
        ),
    )
    notebook = nothing

    try
        notebook = Pluto.SessionActions.open(session, notebook_path; run_async = false)
        Pluto.update_run!(session, notebook, notebook.cells; run_async = false)
        failed_cells = [cell for cell in notebook.cells if cell.errored]
        isempty(failed_cells) || error("Notebook evaluation failed in $(length(failed_cells)) cell(s).")

        mkpath(dirname(output_path))
        write(output_path, Pluto.generate_html(notebook; offline_bundle = true, disable_ui = true))
        println("Wrote $(output_path)")
    finally
        isnothing(notebook) || Pluto.SessionActions.shutdown(session, notebook; async = false)
    end
end

main(ARGS)
