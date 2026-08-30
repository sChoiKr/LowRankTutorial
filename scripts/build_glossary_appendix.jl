#!/usr/bin/env julia

"""
Build the printable glossary appendix.

When a TeX engine is available, the PDF is compiled from
`appendix/GlossaryAppendix.tex`. Otherwise the script prints the complete
default view of the exported Pluto glossary HTML. Run `export_notebooks.jl`
before this script so the HTML fallback is current.
"""

const ROOT = normpath(joinpath(@__DIR__, ".."))
const PUBLIC_LAYOUT = isdir(joinpath(ROOT, "notebooks")) && !isdir(joinpath(ROOT, "src"))
const TEX_SOURCE = joinpath(ROOT, "appendix", "GlossaryAppendix.tex")
const HTML_SOURCE = PUBLIC_LAYOUT ?
    joinpath(ROOT, "appendix", "GlossaryAppendix.html") :
    joinpath(ROOT, "output", "notebooks", "06_GlossaryAppendix.html")
const PDF_OUTPUT = PUBLIC_LAYOUT ?
    joinpath(ROOT, "appendix", "GlossaryAppendix.pdf") :
    joinpath(ROOT, "output", "pdf", "GlossaryAppendix.pdf")
const PDF_TRIMMER = joinpath(@__DIR__, "trim_leading_blank_pdf_page.py")

include(joinpath(@__DIR__, "generate_glossary_latex.jl"))

function find_browser()
    candidates = filter(!isnothing, [
        Sys.which("chromium"),
        Sys.which("google-chrome"),
        Sys.which("microsoft-edge"),
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    ])
    found = findfirst(isfile, candidates)
    isnothing(found) ? nothing : candidates[found]
end

function find_pdf_python()
    candidates = String[]
    haskey(ENV, "TENSORKITCHEN_PYTHON") && push!(candidates, ENV["TENSORKITCHEN_PYTHON"])
    for executable in ("python3", "python")
        candidate = Sys.which(executable)
        isnothing(candidate) || push!(candidates, candidate)
    end

    runtime_root = joinpath(homedir(), ".cache", "codex-runtimes")
    if isdir(runtime_root)
        for (directory, _, files) in walkdir(runtime_root)
            "python3" in files || continue
            endswith(directory, joinpath("dependencies", "python", "bin")) || continue
            push!(candidates, joinpath(directory, "python3"))
        end
    end

    for candidate in unique(candidates)
        isfile(candidate) || continue
        check = pipeline(
            Cmd([candidate, "-c", "import pypdf"]),
            stdout = devnull,
            stderr = devnull,
        )
        success(check) && return candidate
    end
    nothing
end

function trim_leading_blank_page(output_path)
    python = find_pdf_python()
    isnothing(python) && error(
        "The HTML PDF fallback needs Python with `pypdf` to remove Pluto's empty loader page. " *
        "Install `pypdf` or set TENSORKITCHEN_PYTHON to a compatible Python executable.",
    )
    run(Cmd([python, PDF_TRIMMER, output_path]))
end

function build_with_latex(engine, output_path)
    mktempdir() do build_dir
        local_source = joinpath(build_dir, basename(TEX_SOURCE))
        cp(TEX_SOURCE, local_source; force = true)

        if basename(engine) == "latexmk"
            run(Cmd([
                engine,
                "-pdf",
                "-interaction=nonstopmode",
                "-halt-on-error",
                basename(local_source),
            ]; dir = build_dir))
        else
            command = Cmd([
                engine,
                "-interaction=nonstopmode",
                "-halt-on-error",
                basename(local_source),
            ]; dir = build_dir)
            run(command)
            run(command)
        end

        built_pdf = joinpath(build_dir, "GlossaryAppendix.pdf")
        isfile(built_pdf) || error("TeX engine did not produce $built_pdf")
        cp(built_pdf, output_path; force = true)
    end
end

function build_from_html(browser, output_path)
    isfile(HTML_SOURCE) || error(
        "Missing $HTML_SOURCE. Run `julia --project=@pluto scripts/export_notebooks.jl Glossary` first.",
    )

    mktempdir() do profile
        temporary_pdf = joinpath(profile, basename(output_path))
        print_html = joinpath(profile, "GlossaryAppendix.print.html")
        html = read(HTML_SOURCE, String)
        html = replace(
            html,
            "<div style=\"min-height:100vh;display:flex\">" => "<div style=\"min-height:0;display:flex\">",
        )
        html = replace(
            html,
            "<pluto-editor class=\"loading fullscreen\"" => "<pluto-editor class=\"loading\"",
        )
        print_css = """
        <style>
          @page { size: A4; margin: 14mm 12mm; }
          @media print {
            pluto-cell[id="229053c5-e870-47c1-84cb-aa8c244c9507"],
            pluto-cell[id="2434a01e-10ee-4e98-95cc-8d75d8ba3608"],
            pluto-cell[id="59b922a9-e05f-4e53-a798-e1af37173609"],
            pluto-cell[id="8d4b4e2e-06a3-41a1-8164-ff645363c401"],
            pluto-shoulder, pluto-runarea, input, select { display:none !important; }
            details.note-detail:not([open]) > :not(summary) { display:block !important; }
            .domain-heading, .cluster-heading { break-after:avoid; }
            .glossary-detail { break-inside:avoid; }
            article { break-inside:avoid; }
          }
        </style>
        """
        html = replace(html, "</head>" => print_css * "</head>")
        write(print_html, html)
        file_url = "file://" * replace(abspath(print_html), " " => "%20")
        command = Cmd([
            browser,
            "--headless=new",
            "--disable-gpu",
            "--disable-background-networking",
            "--disable-component-update",
            "--disable-default-apps",
            "--disable-sync",
            "--no-first-run",
            "--no-default-browser-check",
            "--no-pdf-header-footer",
            "--run-all-compositor-stages-before-draw",
            "--virtual-time-budget=10000",
            "--user-data-dir=$profile",
            "--print-to-pdf=$(abspath(temporary_pdf))",
            file_url,
        ])
        process = run(command; wait = false)
        deadline = time() + 60
        previous_size = -1
        stable_ticks = 0
        while process_running(process) && time() < deadline
            current_size = isfile(temporary_pdf) ? filesize(temporary_pdf) : -1
            stable_ticks = current_size > 0 && current_size == previous_size ? stable_ticks + 1 : 0
            stable_ticks >= 5 && break
            previous_size = current_size
            sleep(0.2)
        end
        process_running(process) && kill(process)
        try
            wait(process)
        catch error
            isfile(temporary_pdf) || rethrow(error)
        end
        isfile(temporary_pdf) && filesize(temporary_pdf) > 0 ||
            error("Browser did not create $output_path")
        mv(temporary_pdf, output_path; force = true)
        trim_leading_blank_page(output_path)
    end
end

function build_glossary_appendix()
    generate_glossary_latex()
    isfile(TEX_SOURCE) || error("Missing glossary source: $TEX_SOURCE")
    mkpath(dirname(PDF_OUTPUT))

    engines = filter(!isnothing, [
        Sys.which("latexmk"),
        Sys.which("pdflatex"),
        Sys.which("lualatex"),
        Sys.which("xelatex"),
    ])
    engine = isempty(engines) ? nothing : first(engines)

    if !isnothing(engine)
        build_with_latex(engine, PDF_OUTPUT)
        println("Wrote $PDF_OUTPUT from LaTeX")
    else
        browser = find_browser()
        isnothing(browser) && error(
            "No TeX engine or Chromium-based browser found for glossary PDF generation.",
        )
        @warn "No TeX engine found; printing the complete Pluto HTML glossary instead."
        build_from_html(browser, PDF_OUTPUT)
        println("Wrote $PDF_OUTPUT from the Pluto HTML export")
    end

    PDF_OUTPUT
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    build_glossary_appendix()
end
