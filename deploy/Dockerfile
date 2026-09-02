# Reproducible PlutoSliderServer image for the public live tutorial.
FROM julia:1.12.6-bookworm

ENV JULIA_DEPOT_PATH=/opt/julia-depot \
    JULIA_NUM_THREADS=2 \
    TENSORKITCHEN_HOST=0.0.0.0 \
    TENSORKITCHEN_PORT=8080

WORKDIR /app

COPY Project.toml Manifest.toml ./
COPY tools/Project.toml tools/Manifest.toml tools/PlutoDeployment.toml ./tools/

RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()' \
    && julia --project=tools -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Keep the built package depot read-only at runtime while giving Julia a small
# writable overlay for locks, logs, and compiled-cache bookkeeping.
ENV JULIA_DEPOT_PATH=/tmp/julia-depot:/opt/julia-depot \
    JULIA_PKG_OFFLINE=true

COPY notebooks ./notebooks
COPY scripts/run_live_server.jl ./scripts/run_live_server.jl
COPY scripts/ArtifactConfig.jl ./scripts/ArtifactConfig.jl

RUN useradd --create-home --uid 10001 tutorial \
    && chmod -R a-w /app /opt/julia-depot

USER tutorial
EXPOSE 8080

CMD ["julia", "--project=tools", "scripts/run_live_server.jl"]
