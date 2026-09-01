module Lab3TraceData

export endpoint_manifold_trace

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
