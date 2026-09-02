#!/usr/bin/env julia

"""
Build the printable glossary appendix from the generated static HTML.

Run `export_notebooks.jl` before this script so the HTML is current. Using the
same browser rendering path everywhere keeps the committed PDF independent of
local TeX installations and avoids storing a generated `.tex` intermediate.
"""

const ROOT = normpath(joinpath(@__DIR__, ".."))
const HTML_SOURCE = joinpath(ROOT, "html", "GlossaryAppendix.html")
const PDF_OUTPUT = joinpath(ROOT, "appendix", "GlossaryAppendix.pdf")

include(joinpath(@__DIR__, "BrowserPrint.jl"))
using .BrowserPrint

function build_from_html(browser, output_path)
    isfile(HTML_SOURCE) || error(
        "Missing $HTML_SOURCE. Run `julia --project=tools scripts/export_notebooks.jl Glossary` first.",
    )

    mktempdir() do build_dir
        print_html = joinpath(build_dir, "GlossaryAppendix.print.html")
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
            pluto-shoulder, pluto-runarea, input, select { display:none !important; }
            details.note-detail:not([open]) > :not(summary) { display:block !important; }
            .domain-heading, .cluster-heading { break-after:avoid; }
            .glossary-detail { break-inside:avoid; }
            article {
              display:table !important;
              width:100% !important;
              break-inside:avoid-page !important;
              page-break-inside:avoid !important;
            }
          }
        </style>
        """
        html = replace(html, "</head>" => print_css * "</head>")
        write(print_html, html)
        print_html_pdf(
            browser,
            print_html,
            output_path;
            timeout_seconds = 60,
            virtual_time_budget = 10_000,
        )
    end
end

function build_glossary_appendix()
    mkpath(dirname(PDF_OUTPUT))
    browser = find_browser()
    isnothing(browser) && error(
        "A Chromium-based browser is required for glossary PDF generation.",
    )
    build_from_html(browser, PDF_OUTPUT)
    println("Wrote $PDF_OUTPUT from the static glossary HTML")

    PDF_OUTPUT
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    build_glossary_appendix()
end
