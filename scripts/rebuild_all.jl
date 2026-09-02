#!/usr/bin/env julia

"""
Rebuild generated teaching artifacts from a public repository checkout.

Pass `--no-pdf` in CI to rebuild static/deterministic assets without requiring
a browser. Run without the flag locally when the committed PDFs need updating.
"""

const ROOT = normpath(joinpath(@__DIR__, ".."))
const JULIA = joinpath(Sys.BINDIR, Base.julia_exename())

function run_step(arguments...)
    command = Cmd(Cmd(String[JULIA, arguments...]); dir = ROOT)
    println("\n→ ", join(command.exec, " "))
    run(command)
end

function main(args = ARGS)
    unknown = setdiff(args, ["--no-pdf"])
    isempty(unknown) || error("Unknown argument(s): $(join(unknown, ", "))")
    no_pdf = "--no-pdf" ∈ args

    isdir(joinpath(ROOT, "notebooks")) || error(
        "This script belongs in the public package, where notebooks/ is at repository root.",
    )

    run_step("--project=tools", joinpath("scripts", "export_notebooks.jl"))
    exercise_arguments = String[
        "--project=.",
        joinpath("scripts", "generate_exercise_materials.jl"),
    ]
    no_pdf && push!(exercise_arguments, "--no-pdf")
    run_step(exercise_arguments...)
    no_pdf || run_step("--project=.", joinpath("scripts", "build_glossary_appendix.jl"))
end

main()
