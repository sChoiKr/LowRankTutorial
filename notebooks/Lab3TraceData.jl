module Lab3TraceData

export cached_preset,
       clear_preset_cache!,
       endpoint_manifold_trace,
       progress_state,
       swamp_flags,
       windowed_log_progress

const PRESET_CACHE = Dict{Any,Any}()
const PRESET_CACHE_LOCK = ReentrantLock()

"""
    cached_preset(key) do
        build_result()
    end

Build a deterministic, bounded teaching preset at most once per Julia process.
The lock also prevents simultaneous public-server requests from duplicating an
expensive solver race. Callers must validate all client-provided values before
forming `key`.
"""
function cached_preset(builder::Function, key)
    lock(PRESET_CACHE_LOCK) do
        get!(builder, PRESET_CACHE, key)
    end
end

"""Empty the in-process preset cache; intended for regression tests."""
function clear_preset_cache!()
    lock(PRESET_CACHE_LOCK) do
        empty!(PRESET_CACHE)
    end
    nothing
end

"""
    windowed_log_progress(errors; window=20)

Return ``p_k = \\log_{10}(e_{k-w}/e_k)`` for each objective-error sample.
The first `window` entries are `NaN` because no full comparison window exists.
Positive values mean improvement; negative values mean that the objective
worsened over the window.
"""
function windowed_log_progress(errors; window::Int = 20)
    window > 0 || throw(ArgumentError("window must be positive"))
    values = Float64.(collect(errors))
    [
        index > window ?
        log10(max(values[index-window], eps()) / max(values[index], eps())) : NaN for
        index in eachindex(values)
    ]
end

"""Classify one windowed progress score for the learner-facing microscope."""
function progress_state(score::Real; threshold::Real = 0.05)
    !isfinite(score) && return :unavailable
    score < 0 && return :worsened
    score < threshold && return :plateau
    return :progress
end

"""Mark only slow, nonnegative progress as plateau-like."""
function swamp_flags(errors; window::Int = 20, threshold::Real = 0.05)
    [
        progress_state(score; threshold) == :plateau for
        score in windowed_log_progress(errors; window)
    ]
end

"""
    endpoint_manifold_trace(; requested_iterations, initial_point,
                              solve_checkpoint, error, diagnostic)

Build the learner-facing record for a solver whose public result exposes only
its endpoint. `solve_checkpoint(k)` reruns the deterministic solver from the
same initial point with budget `k`, providing genuine checkpoint errors without
inventing intermediate factor points. Component distance and conditioning are
reported only for the initial and final endpoints.
"""
function endpoint_manifold_trace(;
    requested_iterations,
    initial_point,
    solve_checkpoint,
    error,
    diagnostic,
)
    iterations = Int.(collect(requested_iterations))
    isempty(iterations) && throw(ArgumentError("requested_iterations must not be empty"))
    all(>=(0), iterations) || throw(ArgumentError("requested_iterations must be nonnegative"))
    issorted(iterations) || throw(ArgumentError("requested_iterations must be sorted"))
    allunique(iterations) || throw(ArgumentError("requested_iterations must be unique"))
    first(iterations) == 0 || throw(ArgumentError("requested_iterations must start at 0"))

    checkpoint_points = Any[initial_point]
    append!(checkpoint_points, [solve_checkpoint(k) for k in Iterators.drop(iterations, 1)])
    errors = Float64[error(point) for point in checkpoint_points]
    final_point = last(checkpoint_points)
    initial_diagnostic = diagnostic(initial_point)
    final_diagnostic = diagnostic(final_point)

    return (
        errors = errors,
        distances = nothing,
        conditions = nothing,
        points = Any[initial_point, final_point],
        initial_distance = initial_diagnostic.distance,
        initial_condition = initial_diagnostic.condition,
        final_distance = final_diagnostic.distance,
        final_condition = final_diagnostic.condition,
        diagnostic_trace = false,
        final_point = final_point,
    )
end

end
