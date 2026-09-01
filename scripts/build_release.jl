#!/usr/bin/env julia

"""Create a GitHub Release ZIP from the clean public repository checkout."""

const ROOT = rstrip(abspath(joinpath(@__DIR__, "..")), '/')
const PACKAGE_NAME = basename(ROOT)
const DIST = joinpath(ROOT, "dist")
const ZIP_PATH = joinpath(DIST, "$PACKAGE_NAME.zip")

function main()
    Sys.which("zip") === nothing && error("The `zip` command is required.")
    isempty(PACKAGE_NAME) && error("Could not determine a package name from $ROOT")
    mkpath(DIST)
    isfile(ZIP_PATH) && rm(ZIP_PATH; force = true)
    command = Cmd([
        "zip", "-qr", ZIP_PATH, PACKAGE_NAME,
        "-x", "$PACKAGE_NAME/.git/*",
        "-x", "$PACKAGE_NAME/dist/*",
        "-x", "$PACKAGE_NAME/.DS_Store",
        "-x", "$PACKAGE_NAME/*/.DS_Store",
        "-x", "$PACKAGE_NAME/*.log",
    ])
    run(Cmd(command; dir = dirname(ROOT)))
    println("Wrote $ZIP_PATH")
end

main()
