#!/usr/bin/env julia

"""Rebuild every generated teaching artifact from a public repository checkout."""

const ROOT = normpath(joinpath(@__DIR__, ".."))
const JULIA = joinpath(Sys.BINDIR, Base.julia_exename())

function run_step(arguments...)
    command = Cmd(Cmd(String[JULIA, arguments...]); dir = ROOT)
    println("\n→ ", join(command.exec, " "))
    run(command)
end

function main()
    isdir(joinpath(ROOT, "notebooks")) || error(
        "This script belongs in the public package, where notebooks/ is at repository root.",
    )

    run_step("--project=@pluto", joinpath("scripts", "export_notebooks.jl"))
    run_step("--project=@pluto", joinpath("scripts", "export_interactive_intro_deck.jl"))
    run_step("--project=.", joinpath("scripts", "generate_exercise_materials.jl"))
    run_step("--project=.", joinpath("scripts", "build_glossary_appendix.jl"))
    run_step("--project=.", joinpath("test", "runtests.jl"))
    run_step(joinpath("scripts", "build_release.jl"))
end

main()
