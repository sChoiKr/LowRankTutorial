#!/usr/bin/env julia

"""Create a stable release ZIP from Git-tracked and intentional source files."""

include(joinpath(@__DIR__, "ArtifactConfig.jl"))
using .ArtifactConfig

const ROOT = abspath(joinpath(@__DIR__, ".."))
const DIST = joinpath(ROOT, "dist")
const ZIP_PATH = joinpath(DIST, ZIP_FILENAME)
const ROOT_FILES = Set([
    ".dockerignore",
    ".gitignore",
    "CITATION.cff",
    "CURRICULUM.md",
    "LICENSE",
    "Manifest.toml",
    "Project.toml",
    "README.md",
    "REFERENCES.md",
])
const ROOT_DIRECTORIES = Set([
    ".github",
    "appendix",
    "deploy",
    "exercises",
    "html",
    "instructor",
    "notebooks",
    "scripts",
    "slides",
    "test",
    "tools",
])

function validate_release_path(path)
    components = splitpath(path)
    allowed = path in ROOT_FILES || (!isempty(components) && first(components) in ROOT_DIRECTORIES)
    allowed || error("Refusing to package unexpected path: $path")
    any(component -> startswith(component, ".") && component != ".github", components[2:end]) &&
        error("Refusing to package hidden nested path: $path")
    path
end

function git_release_files()
    output = read(
        Cmd(Cmd(["git", "ls-files", "--cached", "--others", "--exclude-standard"]); dir = ROOT),
        String,
    )
    files = filter(
        path -> !isempty(path) && isfile(joinpath(ROOT, path)),
        split(chomp(output), '\n'),
    )
    validate_release_path.(files)
end

function extracted_release_files()
    files = String[]
    append!(files, [path for path in ROOT_FILES if isfile(joinpath(ROOT, path))])
    for directory in ROOT_DIRECTORIES
        directory_path = joinpath(ROOT, directory)
        isdir(directory_path) || continue
        for (current, subdirectories, names) in walkdir(directory_path)
            filter!(name -> !startswith(name, "."), subdirectories)
            for name in names
                startswith(name, ".") && continue
                path = relpath(joinpath(current, name), ROOT)
                isfile(joinpath(ROOT, path)) && push!(files, validate_release_path(path))
            end
        end
    end
    files
end

function release_files()
    files = if ispath(joinpath(ROOT, ".git"))
        Sys.which("git") === nothing && error("The `git` command is required in a repository checkout.")
        git_release_files()
    else
        extracted_release_files()
    end
    sort!(unique(files))
end

function main()
    Sys.which("zip") === nothing && error("The `zip` command is required.")
    files = release_files()
    isempty(files) && error("No release files were found.")
    mkpath(DIST)
    isfile(ZIP_PATH) && rm(ZIP_PATH; force = true)

    mktempdir() do staging_root
        package_root = joinpath(staging_root, PACKAGE_NAME)
        for relative_path in files
            destination = joinpath(package_root, relative_path)
            mkpath(dirname(destination))
            cp(joinpath(ROOT, relative_path), destination; force = true)
        end
        run(Cmd(Cmd(["zip", "-qr", ZIP_PATH, PACKAGE_NAME]); dir = staging_root))
    end
    println("Wrote $ZIP_PATH with $(length(files)) files")
    ZIP_PATH
end

main()
