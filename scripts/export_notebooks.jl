#!/usr/bin/env julia

"""Export every Pluto teaching artifact as self-contained static HTML."""

using Pluto

include(joinpath(@__DIR__, "ArtifactConfig.jl"))
using .ArtifactConfig

const ROOT = normpath(joinpath(@__DIR__, ".."))
const REPOSITORY_README_URL =
    "https://github.com/sChoiKr/LowRankTutorial#static-and-live-entry-points"

escape_html(value::AbstractString) = replace(
    value,
    '&' => "&amp;",
    '<' => "&lt;",
    '>' => "&gt;",
    '"' => "&quot;",
)

normalize_generated_html(html::AbstractString) =
    join(rstrip.(split(String(html), '\n'; keepempty = true)), '\n')

function static_preview_notice()
    live_url = strip(get(ENV, "TENSORKITCHEN_LIVE_URL", ""))
    destination = isempty(live_url) ? REPOSITORY_README_URL : live_url
    label = isempty(live_url) ? "Run locally" : "Open the live Julia version"
    """
    <aside class="tk-static-preview" role="note">
      <strong>Static preview.</strong> Browser-native visuals work here; Julia-backed
      experiments require the live server or local Pluto.
      <a href="$(escape_html(destination))">$(escape_html(label))</a>
    </aside>
    """
end

function add_static_preview_notice(html::AbstractString)
    style = """
    <style id="tk-static-preview-style">
      .tk-static-preview{box-sizing:border-box;margin:0;padding:.7rem 1.2rem;border-bottom:1px solid #a7ad82;background:#f1f0df;color:#40462f;font:600 14px/1.45 system-ui,sans-serif;text-align:center}
      .tk-static-preview a{color:#4d6070;margin-left:.35rem;text-decoration:underline;text-underline-offset:2px}
    </style>
    """
    styled = replace(String(html), "</head>" => style * "</head>"; count = 1)
    body_start = findfirst("<body", styled)
    isnothing(body_start) && error("Generated Pluto HTML has no body element")
    body_end = findnext('>', styled, first(body_start))
    isnothing(body_end) && error("Generated Pluto HTML has an unterminated body element")
    styled[firstindex(styled):body_end] * static_preview_notice() *
    styled[nextind(styled, body_end):lastindex(styled)]
end

function export_notebook(session, target)
    source_path = joinpath(ROOT, target.source)
    output_path = joinpath(ROOT, target.output)
    isfile(source_path) || error("Missing notebook source: $(target.source)")
    mkpath(dirname(output_path))

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
            error("$(basename(source_path)) failed in $(length(failed_cells)) cell(s).")
        end

        generated = Pluto.generate_html(notebook; offline_bundle = true, disable_ui = true)
        html = target.static_notice ? add_static_preview_notice(generated) : generated
        html = normalize_generated_html(html)
        write(output_path, html)
        println("Wrote $output_path")
    finally
        isnothing(notebook) || Pluto.SessionActions.shutdown(session, notebook; async = false)
    end
end

function selected_targets(filters)
    isempty(filters) && return EXPORT_TARGETS
    filter(EXPORT_TARGETS) do target
        any(filter_text ->
            occursin(filter_text, target.source) || occursin(filter_text, target.output),
            filters,
        )
    end
end

function main(args = ARGS)
    targets = selected_targets(args)
    isempty(targets) && error("No export target matched: $(join(args, ", "))")
    session = Pluto.ServerSession(;
        options = Pluto.Configuration.from_flat_kwargs(
            disable_writing_notebook_files = true,
            auto_reload_from_file = false,
            capture_stdout = false,
        ),
    )
    foreach(target -> export_notebook(session, target), targets)
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
