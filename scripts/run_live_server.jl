#!/usr/bin/env julia

"""Serve the five Julia-backed labs with PlutoSliderServer."""

using PlutoSliderServer

const ROOT = normpath(joinpath(@__DIR__, ".."))
const NOTEBOOK_DIR = joinpath(ROOT, "notebooks")
const CONFIG_PATH = joinpath(ROOT, "tools", "PlutoDeployment.toml")
include(joinpath(@__DIR__, "ArtifactConfig.jl"))
using .ArtifactConfig

const LIVE_NOTEBOOK_PATHS = relpath.(
    joinpath.(Ref(ROOT), LIVE_NOTEBOOKS),
    Ref(NOTEBOOK_DIR),
)

function validated_port(value::AbstractString)
    port = try
        parse(Int, value)
    catch
        error("TENSORKITCHEN_PORT must be an integer between 1024 and 65535")
    end
    1024 <= port <= 65535 || error("TENSORKITCHEN_PORT must be between 1024 and 65535")
    port
end

function main()
    all(path -> isfile(joinpath(NOTEBOOK_DIR, path)), LIVE_NOTEBOOK_PATHS) ||
        error("One or more live notebooks are missing")
    host = get(ENV, "TENSORKITCHEN_HOST", "0.0.0.0")
    port = validated_port(get(ENV, "TENSORKITCHEN_PORT", "8080"))
    println("Starting TensorKitchen live tutorial on http://$host:$port")
    println("Public deployments must run inside an isolated, resource-limited container.")
    export_dir = mktempdir(; prefix = "tensorkitchen-live-")
    try
        PlutoSliderServer.run_directory(
            NOTEBOOK_DIR;
            notebook_paths = LIVE_NOTEBOOK_PATHS,
            config_toml_path = CONFIG_PATH,
            Export_output_dir = export_dir,
            SliderServer_host = host,
            SliderServer_port = port,
        )
    finally
        isdir(export_dir) && rm(export_dir; recursive = true, force = true)
    end
end

main()
