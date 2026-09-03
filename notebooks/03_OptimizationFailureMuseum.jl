### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ cece0f98-a9d1-4e8e-a218-6b01a0d7486a
begin
    using LinearAlgebra
    using Random
    using TensorKitchen
    include(joinpath(@__DIR__, "NotebookVisuals.jl"))
    using .NotebookVisuals
    include(joinpath(@__DIR__, "ExerciseContent.jl"))
    using .ExerciseContent
    include(joinpath(@__DIR__, "ManualExecution.jl"))
    using .ManualExecution
    include(joinpath(@__DIR__, "Lab3TraceData.jl"))
    using .Lab3TraceData
end

# ╔═╡ e1916c58-a025-46da-8584-8c1c32314237
md"""
# Lab 3 Observe Stagnation, Diagnose Its Geometry

**Se Eun Choi · Paul Breiding**

## A plateau tells us that optimization is slow, not why

CP optimization can stall for several different reasons. Component collision
is one important mechanism, but it is not a complete explanation of every
swamp. This lab begins with collision because it gives a particularly clear
connection between geometry and ALS conditioning, then compares it with a slow
run caused by a different starting point.

A CP model adds several complete rank-one patterns. Two components collide
when their patterns become nearly indistinguishable. ALS can still fit their
combined contribution, but it becomes harder to decide how much signal belongs
to each component.

### What is component collision?

The core visual uses a **component separation** score. Near zero means that the
two complete rank-one patterns are nearly indistinguishable. A larger value
means that ALS has more visible evidence for assigning them different roles.
The exact sign-invariant distance and overlap formulas are kept in Optional
math below Exhibit 1.

### Why does this matter for optimization?

Alternating least squares (ALS) updates one factor matrix at a time. When two
components are nearly identical, the local least-squares system cannot clearly
separate their roles. The update may still be defined, but it becomes poorly
conditioned: small numerical changes can cause large coordinate changes, and
progress can slow dramatically.

This is one reason swamp-like behavior can appear. The optimizer keeps moving,
but the reconstructed tensor improves only very slowly.

Exhibit 1 shows this relationship without requiring matrix formulas:

```text
components look more alike
→ component separation decreases
→ the ALS update becomes more sensitive
```

The local matrix and condition-number derivation first appear in the collapsed
Optional math panel after the visual.

The arrows here describe a possible mechanism, not a universal law:

```math
\text{component collision}
\xrightarrow{\text{can cause}}
\text{ill-conditioning}
\xrightarrow{\text{can contribute to}}
\text{swamp-like stagnation}.
```

The notebook follows this sequence:

1. make two complete rank-one patterns look more alike and watch separation fall;
2. compare a healthy run, collision-induced difficulty, and a poor start;
3. compare ALS with one geometry-aware method from the same starting point;
4. scrub through an ALS trajectory to inspect a plateau, with an optional
   shared-checkpoint continuation;
5. explore the four-method comparison and cancellation bonus only if time allows.

At every stage, read the object-level diagnostic (reconstruction error)
together with component separation and update sensitivity. No single number
identifies the cause of a plateau.

!!! tip "Presenter-controlled execution"
    Run the exhibits in order. First observe behavior, then diagnose it. The
    goal is not to label every slow run a collision or to rank solvers
    universally.

"""

# ╔═╡ 9a2a8351-25d3-4bb7-aa12-42f7dce4a801
failure_map_visual()

# ╔═╡ a8d37d26-c3f4-41a8-a25f-43b91cdd15b6
md"""
!!! note "Connections to earlier labs"
    **Lab 1:** equivalent coordinates can represent the same object, but some
    equivalent scalings are numerically much worse. **Lab 2:** model capacity
    and optimization success are different; noise or model mismatch can leave
    residual error even when the optimizer is behaving correctly.
"""

# ╔═╡ d333cfa5-dc56-45aa-bd31-949322dc1019
begin
    normalize_columns_lab3(F) = F ./ sqrt.(sum(abs2, F; dims = 1))
    smooth_profile_lab3(n, center, width) =
        exp.(-0.5 .* ((collect(1:n) .- center) ./ width) .^ 2)

    function normalized_factor_copy(factors)
        [normalize_columns_lab3(copy(F)) for F in factors]
    end

    function component_overlap(factors, first_component::Int, second_component::Int)
        normalized = normalized_factor_copy(factors)
        abs(prod(
            dot(F[:, first_component], F[:, second_component]) for
            F in normalized
        ))
    end

    rankone_collision_distance(factors, first_component::Int, second_component::Int) =
        sqrt(max(0.0, 2 - 2 * component_overlap(factors, first_component, second_component)))

    function minimum_component_distance(factors)
        rank = size(first(factors), 2)
        minimum(
            rankone_collision_distance(factors, first_component, second_component) for
            first_component = 1:(rank-1) for
            second_component = (first_component+1):rank
        )
    end

    function als_subproblem_gram(factors, updated_mode::Int)
        normalized = normalized_factor_copy(factors)
        rank = size(first(normalized), 2)
        gram = ones(eltype(first(normalized)), rank, rank)
        for mode in eachindex(normalized)
            mode == updated_mode && continue
            gram .*= normalized[mode]' * normalized[mode]
        end
        gram
    end

    als_subproblem_condition(factors, updated_mode::Int) =
        cond(als_subproblem_gram(factors, updated_mode))
    maximum_als_condition(factors) =
        maximum(als_subproblem_condition(factors, mode) for mode in eachindex(factors))
end

# ╔═╡ afc199e3-3303-492f-8929-3858029211c2
begin
    function collision_problem(rho::Real; seed::Int = 27)
        0 <= rho < 1 || throw(ArgumentError("rho must lie in [0, 1)."))
        rng = MersenneTwister(seed)
        dims = (4, 4, 3)
        rank = 3
        orthogonal_bases = [
            Matrix(qr(randn(rng, dimension, rank)).Q)[:, 1:rank] for
            dimension in dims
        ]
        factors_true = [
            hcat(
                basis[:, 1],
                rho .* basis[:, 1] .+ sqrt(1 - rho^2) .* basis[:, 2],
                basis[:, 3],
            ) for basis in orthogonal_bases
        ]
        weights_true = [1.0, 1.0, 0.7]
        target = reconstruct_cpd_rankr(weights_true, factors_true)
        initial_factors = [normalize_columns_lab3(randn(rng, n, rank)) for n in dims]
        pair_gram = [1.0 rho^2; rho^2 1.0]
        (
            rho = Float64(rho),
            target = target,
            weights = weights_true,
            factors = factors_true,
            initial_point = CPDPoint(ones(rank), initial_factors),
            component_overlap = component_overlap(factors_true, 1, 2),
            collision_distance = rankone_collision_distance(factors_true, 1, 2),
            pair_gram = pair_gram,
            pair_eigenvalues = (1 + rho^2, 1 - rho^2),
            pair_condition = cond(pair_gram),
            full_gram_condition = als_subproblem_condition(factors_true, 1),
        )
    end

    function canonical_point_from_raw(raw_factors)
        normalized = copy.(raw_factors)
        rank = size(first(normalized), 2)
        lambda = ones(eltype(first(normalized)), rank)
        for component = 1:rank, mode in eachindex(normalized)
            column_norm = max(norm(normalized[mode][:, component]), eps())
            lambda[component] *= column_norm
            normalized[mode][:, component] ./= column_norm
        end
        CPDPoint(lambda, normalized)
    end

    point_tensor(point) = reconstruct_cpd_rankr(weights(point), factors(point))
    point_error(target, point) = norm(target - point_tensor(point)) / norm(target)

    function point_diagnostics(target, point)
        (
            error = point_error(target, point),
            distance = minimum_component_distance(factors(point)),
            condition = maximum_als_condition(factors(point)),
        )
    end

    function block_als_trace(target, initial_point; sweeps::Int, ridge::Real = 0.0)
        raw = copy.(factors(initial_point))
        raw[1] .*= reshape(weights(initial_point), 1, :)
        points = Any[CPDPoint(copy(weights(initial_point)), copy.(factors(initial_point)))]
        errors = Float64[]
        distances = Float64[]
        conditions = Float64[]
        function record!(point)
            diagnostic = point_diagnostics(target, point)
            push!(errors, diagnostic.error)
            push!(distances, diagnostic.distance)
            push!(conditions, diagnostic.condition)
        end
        record!(first(points))
        for _ = 1:sweeps
            for updated_mode in eachindex(raw)
                rank = size(first(raw), 2)
                gram = ones(eltype(target), rank, rank)
                for mode in eachindex(raw)
                    mode == updated_mode && continue
                    gram .*= raw[mode]' * raw[mode]
                end
                ridge > 0 && (gram[diagind(gram)] .+= ridge)
                raw[updated_mode] = mttkrp(target, raw, updated_mode) / gram
            end
            point = canonical_point_from_raw(raw)
            push!(points, point)
            record!(point)
            raw = copy.(factors(point))
            raw[1] .*= reshape(weights(point), 1, :)
        end
        (
            iterations = collect(0:sweeps),
            errors = errors,
            distances = distances,
            conditions = conditions,
            points = points,
            ridge = Float64(ridge),
        )
    end

    function sample_trace(trace, requested_iterations)
        indices = requested_iterations .+ 1
        (
            errors = trace.errors[indices],
            distances = trace.distances[indices],
            conditions = trace.conditions[indices],
            points = trace.points[indices],
            final_distance = trace.distances[last(indices)],
            final_condition = trace.conditions[last(indices)],
            diagnostic_trace = true,
        )
    end

    function manifold_trace(target, initial_point, solver, requested_iterations)
        stored_initial = CPDPoint(copy(weights(initial_point)), copy.(factors(initial_point)))
        endpoint_manifold_trace(
            requested_iterations = requested_iterations,
            initial_point = stored_initial,
            solve_checkpoint = iteration -> begin
                solver_initial = CPDPoint(
                    copy(weights(stored_initial)),
                    copy.(factors(stored_initial)),
                )
                result = quiet_solver_call() do
                    cpd(
                        target,
                        length(weights(stored_initial));
                        solver = solver,
                        geometry = :canonical,
                        p0 = solver_initial,
                        maxiter = iteration,
                        tol = 0.0,
                        verbose = false,
                    )
                end
                CPDPoint(weights(result), factors(result))
            end,
            error = point -> point_error(target, point),
            diagnostic = point -> point_diagnostics(target, point),
        )
    end

    """Hide solver progress/debug streams while allowing exceptions to propagate."""
    function quiet_solver_call(f)
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                f()
            end
        end
    end

    function cancellation_problem(; seed::Int = 2026081302, separation::Real = 1e-3)
        base_problem = collision_problem(1 - separation; seed)
        weights_cancel = [100.0, -99.0, 1.0]
        target = reconstruct_cpd_rankr(weights_cancel, base_problem.factors)
        component_norms = abs.(weights_cancel)
        components = [
            reconstruct_cpd_rankr(
                [weights_cancel[component]],
                [reshape(F[:, component], :, 1) for F in base_problem.factors],
            ) for component = 1:3
        ]
        merge(base_problem, (
            target = target,
            weights = weights_cancel,
            component_norms = component_norms,
            components = components,
            cancellation_ratio = sum(component_norms) / norm(target),
        ))
    end

    function perturb_large_component(problem; relative_step::Real = 1e-5)
        factors_perturbed = copy.(problem.factors)
        direction = normalize(collect(range(-1.0, 1.0; length = size(first(factors_perturbed), 1))))
        factors_perturbed[1][:, 1] .+= relative_step .* direction
        changed = reconstruct_cpd_rankr(problem.weights, factors_perturbed)
        coordinate_change = norm(factors_perturbed[1][:, 1] - problem.factors[1][:, 1])
        object_change = norm(changed - problem.target) / norm(problem.target)
        (
            coordinate_change = coordinate_change,
            relative_object_change = object_change,
            amplification = object_change / coordinate_change,
        )
    end
end

# ╔═╡ 0e23b980-5cd0-42ac-b19f-f71b2cc5754e
md"""
Use the control inside the visual. It changes the complete component patterns
continuously without rerunning the Julia experiment.
"""

# ╔═╡ d3300001-e237-4d09-94a3-40a9288f6ab2
begin
    collision_rho = 0.90
    collision_demo = collision_problem(collision_rho)
end

# ╔═╡ aa0ad7c9-d080-4808-85d6-aad466f2cc8e
md"""
## Exhibit 1 How do we know two CP components are colliding?

Two complete rank-one patterns are shown side by side. Move the similarity
control toward **Almost identical** and watch Component 2 morph toward
Component 1 across all three mode vectors and the resulting tensor pattern.

Read only two core diagnostics:

- **Component separation:** near 0 means nearly indistinguishable;
- **ALS update sensitivity:** higher means it is harder to divide the shared
  signal reliably between the two components.

Then press **Redistribute shared signal**. The contribution coordinates change
from an equal split to an 80/20 split. When the patterns are distinct, that
reallocation visibly changes their sum; near collision, the coordinates change
strongly while the reconstructed pattern changes very little.

This is the intuition behind ill-conditioning. The exact separation, overlap,
Gram-matrix, and eigenvalue formulas are available only in the two Optional
math panels.
"""

# ╔═╡ 2bff8e06-c245-4e31-ab2f-940425745672
component_collision_visual(collision_demo)

# ╔═╡ 5557d442-1440-43ad-9671-50d8fc162c2e
md"""
### Why ALS struggles near a collision

ALS updates one factor matrix while temporarily holding the other two fixed.
When two rank-one terms become near-copies, ALS can still fit their combined
effect but cannot reliably decide how much should be assigned to each term.
That ambiguity makes the local update poorly conditioned and can slow progress.

```text
components look more alike  →  separation falls  →  ALS update sensitivity rises
```

**Guiding question.** As you move the similarity control toward **Almost
identical**, does separating the two components become easier or harder for
ALS? The collapsed panel below explains
the Gram matrix and eigenvalues only if you want the algebra behind the visual.
"""

# ╔═╡ caed6d54-555b-4554-be16-6afbb1fa82e8
gram_condition_visual(collision_demo)

# ╔═╡ 20f1e1e8-69fb-4ce2-bf1b-659bbc597f15
md"""
## Exhibit 2 Does every slow run come from component collision?

No. This comparison keeps the CP rank at 3 and gives every case 20 ALS sweeps:

1. **healthy:** a separated target with a nearby initialization;
2. **collision:** a target whose first two rank-one directions nearly coincide;
3. **poor start:** the same separated target as the healthy case, but from a
   deliberately difficult random initialization.

The poor-start seed is fixed to make the contrast reproducible; it is a
teaching counterexample, not a claim about how often random starts fail. Read
the table diagnostically: slow reconstruction together with low component
separation and high update sensitivity supports a collision explanation.
Slow reconstruction with separated components points elsewhere.

```math
\text{slow optimization}\;\not\Rightarrow\;\text{component collision}
```
"""

# ╔═╡ 40f4fe24-8a27-4a8e-9d18-8136d989da7e
@bind run_failure_comparison_control manual_run_button("Compare three ALS cases")

# ╔═╡ 801210da-c642-4550-94fd-a031f91223a6
if manual_run_requested(run_failure_comparison_control)
    comparison_sweeps = 20
    comparison_separated = collision_problem(0.2)

    healthy_rng = MersenneTwister(99)
    healthy_factors = [
        normalize_columns_lab3(F .+ 0.04 .* randn(healthy_rng, size(F))) for
        F in comparison_separated.factors
    ]
    healthy_start = CPDPoint(copy(comparison_separated.weights), healthy_factors)

    poor_rng = MersenneTwister(76)
    poor_factors = [
        normalize_columns_lab3(randn(poor_rng, dimension, 3)) for
        dimension in size(comparison_separated.target)
    ]
    poor_start = CPDPoint(ones(3), poor_factors)
    comparison_collision = collision_problem(0.995)

    comparison_traces = (
        healthy = block_als_trace(
            comparison_separated.target,
            healthy_start;
            sweeps = comparison_sweeps,
        ),
        collision = block_als_trace(
            comparison_collision.target,
            comparison_collision.initial_point;
            sweeps = comparison_sweeps,
        ),
        poor_start = block_als_trace(
            comparison_separated.target,
            poor_start;
            sweeps = comparison_sweeps,
        ),
    )

    comparison_summary = (label, trace, interpretation) -> (
        label = label,
        progress_orders = log10(max(first(trace.errors), eps()) / max(last(trace.errors), eps())),
        minimum_distance = minimum(trace.distances),
        maximum_condition = maximum(trace.conditions),
        interpretation = interpretation,
    )
    comparison_cases = [
        comparison_summary(
            "Well separated",
            comparison_traces.healthy,
            "Healthy: rapid progress with separated directions and easy ALS blocks.",
        ),
        comparison_summary(
            "Collision",
            comparison_traces.collision,
            "Collision: separation collapses and the ALS update becomes highly sensitive.",
        ),
        comparison_summary(
            "Poor start",
            comparison_traces.poor_start,
            "Slow for another reason: components remain separated and update sensitivity stays moderate.",
        ),
    ]
    nothing
else
    comparison_sweeps = comparison_separated = healthy_rng = healthy_factors =
        healthy_start = poor_rng = poor_factors = poor_start = comparison_collision =
        comparison_traces = comparison_summary = comparison_cases = nothing
    manual_waiting("Run the controlled comparison when you are ready.")
end

# ╔═╡ e168700d-d715-47cb-91eb-92b995560b0e
if !isnothing(comparison_cases)
    failure_comparison_visual(comparison_cases)
else
    manual_waiting("The three-case diagnostic table will appear after the run.")
end

# ╔═╡ 55cb3d04-b421-4e94-a835-549997cbb84d
md"""
## Exhibit 3 When components collide, do optimization methods behave differently?

Choose a collision level, then compare **ALS** with one geometry-aware method,
**Riemannian conjugate gradient (RCG)**, on the same target, rank, starting
`CPDPoint`, checkpoints, and stopping rule. The goal is not to crown a winner;
it is to ask whether two optimization mechanisms react differently to the same
ill-conditioned representation.

### Reading fit and component separation

- **Log relative reconstruction error** asks whether each solver is fitting the
  target tensor; lower is better at the object level.
- **Component separation over time** is available for ALS because the
  notebook stores its actual point after every sweep.
- **RCG has no iteration-level separation line here.** Its error curve comes
  from deterministic checkpoint reruns; separation and update sensitivity are
  shown only for the returned endpoint.
- **Final component separation** near 0 means that at least one returned pair
  is nearly indistinguishable.
- **Endpoint ALS update sensitivity** describes how difficult an ALS-style
  allocation would be at the returned representation. It is not a system RCG
  solved internally.

Read the object error and representation diagnostics together. A small error
with low final separation means that the tensor is fitted even though two
returned components remain difficult to distinguish. Use **Explore more**
afterward to add regularized ALS and Riemannian gradient descent (RGD).
"""

# ╔═╡ d3300002-5de6-4e86-b793-6c2810776cf4
@bind solver_race_control manual_choice_run_control(
    "Choose the collision level",
    "Well separated · ρ = 0.20" => 0.20,
    "Nearly colliding · ρ = 0.95" => 0.95,
    "Severe collision · ρ = 0.995" => 0.995;
    default = 3,
    run_label = "Run solver race",
)

# ╔═╡ 394fc1c6-25ce-4edf-b6dc-868086185c3d
if manual_parameter_run_requested(solver_race_control)
    race_rho = manual_choice_value(solver_race_control, (0.20, 0.95, 0.995), 0.995)
    race_bundle = cached_preset((:solver_race, race_rho)) do
        problem = collision_problem(race_rho)
        iterations = [0, 1, 2, 4, 6, 8]
        als_full = block_als_trace(
            problem.target,
            problem.initial_point;
            sweeps = 60,
            ridge = 0.0,
        )
        regularized_full = block_als_trace(
            problem.target,
            problem.initial_point;
            sweeps = 60,
            ridge = 1e-2,
        )
        race = (
            ALS = sample_trace(als_full, iterations),
            regularized_ALS = sample_trace(regularized_full, iterations),
            RCG = manifold_trace(
                problem.target,
                problem.initial_point,
                :rcg,
                iterations,
            ),
            RGD = manifold_trace(
                problem.target,
                problem.initial_point,
                :rgd,
                iterations,
            ),
        )
        (
            problem = problem,
            iterations = iterations,
            als_full = als_full,
            regularized_full = regularized_full,
            race = race,
        )
    end
    race_problem = race_bundle.problem
    race_iterations = race_bundle.iterations
    race_als_full = race_bundle.als_full
    race_regularized_full = race_bundle.regularized_full
    solver_race = race_bundle.race
    nothing
else
    race_rho = 0.995
    race_bundle = race_problem = race_iterations = race_als_full = race_regularized_full = solver_race = nothing
    manual_waiting("Choose a collision level, then run the controlled solver race.")
end

# ╔═╡ f0842b0a-fc23-4390-a9a1-493b720ba24d
if !isnothing(solver_race)
    solver_race_visual(
        race_iterations,
        "ALS" => solver_race.ALS,
        "Geometry-aware RCG" => solver_race.RCG;
        title = "Core comparison · same problem and starting point",
    )
else
    manual_waiting("The error trajectories and final component-separation comparison will appear after the run.")
end

# ╔═╡ d3300004-5de6-4e86-b793-6c2810776cf4
@bind run_extended_solver_race manual_run_button("Explore more · compare all four methods")

# ╔═╡ f0842b0b-fc23-4390-a9a1-493b720ba24d
if manual_run_requested(run_extended_solver_race) && !isnothing(solver_race)
    solver_race_visual(
        race_iterations,
        "ALS" => solver_race.ALS,
        "Regularized ALS" => solver_race.regularized_ALS,
        "RCG" => solver_race.RCG,
        "RGD" => solver_race.RGD;
        title = "Explore more · four optimization mechanisms",
    )
else
    manual_waiting("The two-method comparison above is the core activity. Open this extension only if time allows.")
end

# ╔═╡ b263a1d1-6f69-4994-9ab9-d5b2e818356b
md"""
## Exhibit 4 What does a plateau show, and what does it not show?

Use the iteration scrubber to inspect the ALS run from Exhibit 3. At each
sweep it shows reconstruction error, component separation, ALS update
sensitivity, and progress over the previous 20 sweeps. Define the windowed
progress score

```math
p_k=\log_{10}\!\left(\frac{e_{k-20}}{e_k}\right).
```

The microscope distinguishes three states:

- ``p_k\ge 0.05``: meaningful progress;
- ``0\le p_k<0.05``: plateau-like slow progress;
- ``p_k<0``: the objective worsened.

This is a transparent teaching heuristic, not a mathematical definition of a
swamp. Crucially, the plateau flag requires slow **nonnegative** progress; an
increase in error is reported separately as worsening. It does **not** use
separation or update sensitivity to decide *why* progress is slow.

```math
\text{plateau detection}\ne\text{plateau explanation}
```

Move the scrubber from left to right and ask three separate questions:

1. Is the represented tensor improving?
2. Are two fitted terms becoming nearly indistinguishable?
3. Is the ALS update becoming more sensitive?

In this controlled run, low separation together with high update sensitivity
supports a collision explanation. In another run, the same flat error curve
could come from initialization, rank choice, scaling, or model mismatch.
"""

# ╔═╡ d3300003-5dd7-40e5-a3ee-986e586a40e3
if !isnothing(race_als_full)
    microscope_progress = windowed_log_progress(race_als_full.errors; window = 20)
    swamp_microscope_visual(
        race_als_full;
        window = 20,
        progress_states = [progress_state(score) for score in microscope_progress],
    )
else
    manual_waiting("Run the solver race first; its ALS sweeps feed this microscope.")
end

# ╔═╡ 6c45be83-4fc7-44a1-9cf3-1c54c16babd0
md"""
### Optional extension: Can another optimizer escape a swamp checkpoint?

The first swamp-like ALS iterate becomes a checkpoint ``p_{\mathrm{swamp}}``.
Every continuation below starts from that **exact same `CPDPoint`**. No method
gets a different random initialization.

```text
                         same checkpoint
                              ●
                 ┌────────────┼────────────┐
                 ↓            ↓            ↓
                ALS     regularized ALS   RCG / RGD
```

Ask which mechanism changes the trajectory, not which method is “always best.”
Regularization stabilizes a block solve, conjugate directions reuse geometric
information, and RGD follows the local Riemannian gradient.

The continuation plot uses the same evidence boundary as Exhibit 3. All four
methods show their reconstruction-error history. ALS and regularized ALS also
show actual sweep-by-sweep component separation. RCG and RGD show only endpoint
separation and update sensitivity because their intermediate factor points are
not available here.

For the block solvers, a falling error together with increasing separation means
that the stored sweep points both fit the object and separate the near-copy
directions. For RCG and RGD, compare the error history with the final endpoint
diagnostics only; the figure does not claim when or how their separation
changed during optimization.
"""

# ╔═╡ 79421847-df2a-438d-9572-9781558967b3
@bind run_escape_control manual_run_button("Continue from the shared checkpoint")

# ╔═╡ 3e4976a8-217b-4a49-a7e2-e4e3a7763ea6
if manual_run_requested(run_escape_control) && !isnothing(race_als_full)
    flagged = swamp_flags(race_als_full.errors; window = 20)
    escape_checkpoint_index = something(findfirst(flagged), min(31, length(flagged)))
    escape_checkpoint_iteration = race_als_full.iterations[escape_checkpoint_index]
    escape_checkpoint = race_als_full.points[escape_checkpoint_index]
    escape_iterations = [0, 1, 2, 4, 6]
    escape_als_full = block_als_trace(
        race_problem.target,
        escape_checkpoint;
        sweeps = last(escape_iterations),
        ridge = 0.0,
    )
    escape_regularized_full = block_als_trace(
        race_problem.target,
        escape_checkpoint;
        sweeps = last(escape_iterations),
        ridge = 1e-2,
    )
    escape_runs = (
        ALS = sample_trace(escape_als_full, escape_iterations),
        regularized_ALS = sample_trace(escape_regularized_full, escape_iterations),
        RCG = manifold_trace(
            race_problem.target,
            escape_checkpoint,
            :rcg,
            escape_iterations,
        ),
        RGD = manifold_trace(
            race_problem.target,
            escape_checkpoint,
            :rgd,
            escape_iterations,
        ),
    )
    nothing
else
    escape_checkpoint_index = escape_checkpoint_iteration = escape_checkpoint =
        escape_iterations = escape_als_full = escape_regularized_full = escape_runs = nothing
    manual_waiting("Run the solver race first, then continue from its shared swamp checkpoint.")
end

# ╔═╡ 03512fbd-c0ce-4251-8e83-ebf899b909ca
if !isnothing(escape_runs)
    solver_race_visual(
        escape_iterations,
        "ALS" => escape_runs.ALS,
        "Regularized ALS" => escape_runs.regularized_ALS,
        "RCG" => escape_runs.RCG,
        "RGD" => escape_runs.RGD;
        title = "Continuation from ALS sweep $escape_checkpoint_iteration: one checkpoint, four mechanisms",
    )
else
    manual_waiting("The continuation trajectories will appear after the checkpoint run.")
end

# ╔═╡ 971ea2d2-94a8-4a7c-9ae7-97811232d781
md"""
## Bonus exhibit: Can a small reconstructed tensor hide large fragile terms?

### Near-cancellation makes collision even worse

The collision experiment used ordinary positive weights to isolate directional
geometry. Now we deliberately combine two distinct diagnostics:

- **directional collision:** the component separation is near zero;
- **magnitude / cancellation:** the weighted term norms are large but their
  signed sum is much smaller.

The construction is

```math
\mathcal X=100T_1-99T_2+T_3,
```

where ``T_1`` and ``T_2`` are nearly identical. Large terms form a much smaller
represented tensor because ``+100T_1`` and ``-99T_2`` nearly erase one another.
It is the tensor analogue of subtracting two large, nearly equal numbers and
keeping only a small remainder.

### What the slice comparison is meant to show

The first panel is the large positive term ``+100T_1``. The second is the large
negative near-copy ``-99T_2``. The third is their represented sum together with
``T_3``. All panels use the same color scale, so the comparison exposes how
large hidden component magnitudes can produce a much smaller final object.

The **cancellation ratio** is

```math
\frac{\sum_r\|\lambda_rT_r\|_F}{\|\mathcal X\|_F}.
```

A large value means the decomposition contains much more component magnitude
than is visible in the final tensor. The **perturbation amplification** asks how
much a tiny coordinate change is magnified at the represented-object level
after that delicate balance is disturbed.

Before looking at tensor slices, the warm-up treats each tensor term as an arrow
in the Frobenius inner-product space. The following norm bars show the same
idea numerically; the slice comparison then shows where the cancellation occurs.

The three additional RGD runs perturb the target by ``0``, ``10^{-14}``, and
``10^{-12}`` from the same starting coordinates. Their purpose is to test
sensitivity, not to define collision or a swamp. This bonus shows why
collision plus cancellation is more fragile than collision alone.

As you reveal the bonus, look for four linked observations:

1. the two weighted component terms are individually large;
2. their signed sum is much smaller;
3. the cancellation ratio exposes the hidden magnitude;
4. a small coordinate perturbation can disturb the delicate balance.
"""

# ╔═╡ cd911313-f6c5-4d83-8ec0-cb2ae61361e3
@bind run_bonus_control manual_run_button("Run bonus cancellation stress test")

# ╔═╡ 23744f53-982b-40a1-8d92-d8553204e956
if manual_run_requested(run_bonus_control)
    bonus_problem = cancellation_problem()
    bonus_sensitivity = perturb_large_component(bonus_problem)
    bonus_als = quiet_solver_call() do
        cpd(
            bonus_problem.target,
            3;
            solver = :als,
            p0 = bonus_problem.initial_point,
            maxiter = 25,
            tol = 0.0,
            verbose = false,
        )
    end
    bonus_start = CPDPoint(weights(bonus_als), factors(bonus_als))
    bonus_rng = MersenneTwister(2026081303)
    bonus_direction = normalize(randn(bonus_rng, size(bonus_problem.target)))
    bonus_levels = (0.0, 1e-14, 1e-12)
    bonus_targets = [
        bonus_problem.target .+ level .* norm(bonus_problem.target) .* bonus_direction for
        level in bonus_levels
    ]
    bonus_iterations = 1:5
    bonus_runs = [
        [
            quiet_solver_call() do
                cpd(
                    target,
                    3;
                    solver = :rgd,
                    geometry = :canonical,
                    p0 = CPDPoint(copy(weights(bonus_start)), copy.(factors(bonus_start))),
                    maxiter = iteration,
                    tol = 0.0,
                    verbose = false,
                )
            end for iteration in bonus_iterations
        ] for target in bonus_targets
    ]
    bonus_traces = [[rel_error(result) for result in runs] for runs in bonus_runs]
    bonus_normalized_traces = [trace ./ first(trace) for trace in bonus_traces]
    nothing
else
    bonus_problem = bonus_sensitivity = bonus_als = bonus_start = bonus_levels =
        bonus_targets = bonus_iterations = bonus_runs = bonus_traces =
        bonus_normalized_traces = nothing
    manual_waiting("Run the optional stress test when you are ready.")
end

# ╔═╡ 24bd44ca-e383-4e99-8630-1d1bbf17cf13
if !isnothing(bonus_problem)
    cancellation_warmup_visual(bonus_problem, bonus_sensitivity)
else
    manual_waiting("The bonus diagnostics will appear after the optional run.")
end

# ╔═╡ a3c93f10-4878-4d8b-88e2-e84c824543a1
if !isnothing(bonus_problem)
    tensor_slices_visual(
        "+100 × component" => bonus_problem.components[1],
        "−99 × near-copy" => bonus_problem.components[2],
        "represented tensor" => bonus_problem.target;
        title = "Cancellation: +100 T₁ and −99 T₂ nearly erase each other",
        shared_scale = true,
        reveal = false,
    )
else
    manual_waiting("The cancellation illustration will appear after the bonus run.")
end

# ╔═╡ 9b32115c-d09a-4eb5-936b-58c153a39b45
if !isnothing(bonus_normalized_traces)
    trajectory_visual(
        "relative perturbation 0" => bonus_normalized_traces[1],
        "relative perturbation 10^-14" => bonus_normalized_traces[2],
        "relative perturbation 10^-12" => bonus_normalized_traces[3];
        title = "Advanced view: five residuals after tiny target perturbations",
        logscale = false,
        reveal = false,
    )
else
    manual_waiting("The advanced perturbation traces will appear after the bonus run.")
end

# ╔═╡ 09da72c2-9352-4d4b-8504-7ed0afab4c4a
md"""
### Takeaway

```math
\text{A plateau tells us that optimization is slow; it does not tell us why.}
```

**Optimization success, representation stability, and reconstruction accuracy
are different questions.** Low component separation and high update sensitivity
can support a collision-based diagnosis; component norms and cancellation ratio
reveal a different degeneracy mechanism. Initialization, rank choice, scaling
imbalance, and model mismatch require their own checks.

The correct workflow is therefore: **observe stagnation, then diagnose its
geometry.**

## Exercise: collision, sensitive updates, and swamps

Use the failure map, component-similarity control, comparison panel, optional Gram example, solver
race, and plateau microscope above.
Each answer remains hidden until you open that problem's **Check answer** button.
"""

# ╔═╡ 15b22a8b-eeba-4198-b2f7-f04f3229ac2a
render_exercise(exercise_by_number(5))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
TensorKitchen = "3630a16b-0f2f-4d88-afbf-c7d59eccf553"

[compat]
TensorKitchen = "~0.2.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "0adec751d406070c41809bdad81097ec33251c80"

[[deps.ADTypes]]
git-tree-sha1 = "9b38b82a9fe131f3d331a53b7203d9d1a2a4602c"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "1.22.4"

    [deps.ADTypes.extensions]
    ADTypesChainRulesCoreExt = "ChainRulesCore"
    ADTypesConstructionBaseExt = "ConstructionBase"
    ADTypesEnzymeCoreExt = "EnzymeCore"

    [deps.ADTypes.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "7063ad1083578215c7c4bf410368150abe8d5524"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.45"

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    IntervalSetsExt = "IntervalSets"
    LinearAlgebraExt = "LinearAlgebra"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"
    TestExt = "Test"
    UnitfulExt = "Unitful"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "daa72978cd7a624246e894a4f4f067706d4e17e2"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.7.0"
weakdeps = ["SparseArrays", "StaticArrays"]

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "d57bd3762d308bded22c3b82d033bff85f6195c6"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.4.0"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra"]
git-tree-sha1 = "60f11b38ebeabd984f5535838d91e197d97202f0"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.28.1"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceAMDGPUExt = "AMDGPU"
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceCUDSSExt = ["CUDSS", "CUDA"]
    ArrayInterfaceChainRulesCoreExt = "ChainRulesCore"
    ArrayInterfaceChainRulesExt = "ChainRules"
    ArrayInterfaceFillArraysExt = "FillArrays"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceMetalExt = "Metal"
    ArrayInterfaceReverseDiffExt = "ReverseDiff"
    ArrayInterfaceSparseArraysExt = "SparseArrays"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    FillArrays = "1a297f60-69ca-5386-bcde-b61e274b549b"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.CommonMark]]
deps = ["PrecompileTools"]
git-tree-sha1 = "7e0e715804be2cfdc251d9a4bd10ace7a1b791e5"
uuid = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
version = "1.0.3"

    [deps.CommonMark.extensions]
    CommonMarkMarkdownASTExt = "MarkdownAST"
    CommonMarkMarkdownExt = "Markdown"

    [deps.CommonMark.weakdeps]
    Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
    MarkdownAST = "d0879d2d-cac2-40c8-9cee-1863dc0c7391"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ConstructionBase]]
git-tree-sha1 = "b4b092499347b18a015186eae3042f72267106cb"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.6.0"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "b0bc6d2cad1fed8b7fd59a1551a991cb3d2809e6"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.6"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "79a2aca180a85c690c58a020d47b426954b590f8"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.16.0"

[[deps.DifferentiationInterface]]
deps = ["ADTypes", "LinearAlgebra"]
git-tree-sha1 = "dbd46a5cd0e79a97438b0ebbec42e744e8f436fe"
uuid = "a0c0ee7d-e4b9-4e03-894e-1c5f64a51d63"
version = "0.7.20"

    [deps.DifferentiationInterface.extensions]
    DifferentiationInterfaceChainRulesCoreExt = "ChainRulesCore"
    DifferentiationInterfaceDiffractorExt = "Diffractor"
    DifferentiationInterfaceEnzymeExt = ["EnzymeCore", "Enzyme"]
    DifferentiationInterfaceFastDifferentiationExt = "FastDifferentiation"
    DifferentiationInterfaceFiniteDiffExt = "FiniteDiff"
    DifferentiationInterfaceFiniteDifferencesExt = "FiniteDifferences"
    DifferentiationInterfaceForwardDiffExt = ["ForwardDiff", "DiffResults"]
    DifferentiationInterfaceGPUArraysCoreExt = ["GPUArraysCore", "Adapt"]
    DifferentiationInterfaceGTPSAExt = "GTPSA"
    DifferentiationInterfaceHyperHessiansExt = "HyperHessians"
    DifferentiationInterfaceMooncakeExt = "Mooncake"
    DifferentiationInterfacePolyesterForwardDiffExt = ["PolyesterForwardDiff", "ForwardDiff", "DiffResults"]
    DifferentiationInterfaceReverseDiffExt = ["ReverseDiff", "DiffResults"]
    DifferentiationInterfaceSparseArraysExt = "SparseArrays"
    DifferentiationInterfaceSparseConnectivityTracerExt = "SparseConnectivityTracer"
    DifferentiationInterfaceSparseMatrixColoringsExt = "SparseMatrixColorings"
    DifferentiationInterfaceStaticArraysExt = "StaticArrays"
    DifferentiationInterfaceSymbolicsExt = "Symbolics"
    DifferentiationInterfaceTrackerExt = "Tracker"
    DifferentiationInterfaceZygoteExt = ["Zygote", "ForwardDiff"]

    [deps.DifferentiationInterface.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DiffResults = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
    Diffractor = "9f5e2b26-1114-432f-b630-d3fe2085c51c"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastDifferentiation = "eb9bf01b-bf85-4b60-bf87-ee5de06c00be"
    FiniteDiff = "6a86dc24-6348-571c-b903-95158fe2bd41"
    FiniteDifferences = "26cc04aa-876d-5657-8c51-4c34ba976000"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    GTPSA = "b27dd330-f138-47c5-815b-40db9dd9b6e8"
    HyperHessians = "06b494a0-c8e0-40cc-ad32-d99506a00a6c"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SparseConnectivityTracer = "9f842d2f-2579-4b1d-911e-f412cf18a3f5"
    SparseMatrixColorings = "0a514795-09f3-496d-8182-132a7b665d35"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.ExprTools]]
git-tree-sha1 = "d2e49e7efd29719d6f28b891b0e0e159daa9d2b4"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.11"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "83cf05ab16a73219e5f6bd1bdfa9848fa24ac627"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.2.0"

[[deps.Glob]]
git-tree-sha1 = "246c628cec062230b7d183aab88841fa94fcabe9"
uuid = "c27321d9-0574-5035-807b-f59d2c89b15c"
version = "1.5.0"

[[deps.Glossaries]]
git-tree-sha1 = "60a11a815b6113e7024157c31a77a75619d97a23"
uuid = "8f48dd54-e453-4cdc-9500-53b96149560b"
version = "0.1.1"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "DataStructures", "Inflate", "LinearAlgebra", "Random", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "7eb45fe833a5b7c51cf6d89c5a841d5967e44be3"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.14.0"

    [deps.Graphs.extensions]
    GraphsSharedArraysExt = "SharedArrays"

    [deps.Graphs.weakdeps]
    Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"
    SharedArrays = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7204148362dafe5fe6a273f855b8ccbe4df8173e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.8.0"

[[deps.JuliaFormatter]]
deps = ["CommonMark", "Glob", "JuliaSyntax", "PrecompileTools", "TOML", "Test"]
git-tree-sha1 = "878a99e9b2f2ac45efe9b384727134a9f1744071"
uuid = "98e50ef6-434e-11e9-1051-2b60c6c9e899"
version = "2.10.1"

[[deps.JuliaSyntax]]
git-tree-sha1 = "0d4b3dab95018bcf3925204475693d9f09dc45b8"
uuid = "70703baa-626e-46a2-a12c-08ffd08c73b4"
version = "1.0.2"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.Kronecker]]
deps = ["LinearAlgebra", "NamedDims", "SparseArrays", "StatsBase"]
git-tree-sha1 = "9253429e28cceae6e823bec9ffde12460d79bb38"
uuid = "2c470bb0-bcc8-11e8-3dad-c9649493f05e"
version = "0.5.5"

[[deps.LRUCache]]
git-tree-sha1 = "5519b95a490ff5fe629c4a7aa3b3dfc9160498b3"
uuid = "8ac3fa9e-de4c-5943-b1dc-09c6b5f20637"
version = "1.6.2"
weakdeps = ["Serialization"]

    [deps.LRUCache.extensions]
    SerializationExt = ["Serialization"]

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.LinearMaps]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "7f6be2e4cdaaf558623d93113d6ddade7b916209"
uuid = "7a12625a-238d-50fd-b39a-03d52299707e"
version = "3.11.4"

    [deps.LinearMaps.extensions]
    LinearMapsChainRulesCoreExt = "ChainRulesCore"
    LinearMapsSparseArraysExt = "SparseArrays"
    LinearMapsStatisticsExt = "Statistics"

    [deps.LinearMaps.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "bba2d9aa057d8f126415de240573e86a8f39d2a1"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "1.0.1"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.ManifoldDiff]]
deps = ["ADTypes", "DifferentiationInterface", "LinearAlgebra", "ManifoldsBase", "Markdown", "Random", "Requires"]
git-tree-sha1 = "28c69b401c75dd3f3b34a39bb7cb7948a2aeb61d"
uuid = "af67fdf4-a580-4b9f-bbec-742ef357defd"
version = "0.4.5"

    [deps.ManifoldDiff.weakdeps]
    FiniteDiff = "6a86dc24-6348-571c-b903-95158fe2bd41"
    FiniteDifferences = "26cc04aa-876d-5657-8c51-4c34ba976000"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Manifolds]]
deps = ["ADTypes", "DifferentiationInterface", "Graphs", "Kronecker", "LinearAlgebra", "ManifoldDiff", "ManifoldsBase", "Markdown", "MatrixEquations", "Quaternions", "Random", "SimpleWeightedGraphs", "SpecialFunctions", "StaticArrays", "Statistics", "StatsBase", "Tullio"]
git-tree-sha1 = "9b55584585d731512ef6895ba6ad6ff4ec5cc8cf"
uuid = "1cead3c2-87b3-11e9-0ccd-23c62b72b94e"
version = "0.11.29"

    [deps.Manifolds.extensions]
    ManifoldsBoundaryValueDiffEqExt = ["BoundaryValueDiffEqMIRK", "SciMLBase"]
    ManifoldsDistributionsExt = ["Distributions", "RecursiveArrayTools"]
    ManifoldsHybridArraysExt = "HybridArrays"
    ManifoldsNLsolveExt = "NLsolve"
    ManifoldsOrdinaryDiffEqDiffEqCallbacksExt = ["DiffEqCallbacks", "OrdinaryDiffEq", "OrdinaryDiffEqRosenbrock", "OrdinaryDiffEqVerner", "RecursiveArrayTools", "SciMLBase"]
    ManifoldsOrdinaryDiffEqExt = "OrdinaryDiffEq"
    ManifoldsRecipesBaseExt = ["Colors", "RecipesBase"]
    ManifoldsRecursiveArrayToolsExt = "RecursiveArrayTools"
    ManifoldsTestExt = "Test"

    [deps.Manifolds.weakdeps]
    BoundaryValueDiffEqMIRK = "1a22d4ce-7765-49ea-b6f2-13c8438986a6"
    Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
    DiffEqCallbacks = "459566f4-90b8-5000-8ac3-15dfb0a30def"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    HybridArrays = "1baab800-613f-4b0a-84e4-9cd3431bfbb9"
    NLsolve = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
    OrdinaryDiffEq = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"
    OrdinaryDiffEqRosenbrock = "43230ef6-c299-4910-a778-202eb28ce4ce"
    OrdinaryDiffEqVerner = "79d7bb75-1356-48c1-b8c0-6832512096c2"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"
    SciMLBase = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.ManifoldsBase]]
deps = ["LinearAlgebra", "Markdown", "Preferences", "Printf", "Random"]
git-tree-sha1 = "751a06f12d5c20cff34bb981ea2fd9a42defe8d0"
uuid = "3362f125-f0bb-47a3-aa74-596ffd7ef2fb"
version = "2.5.0"

    [deps.ManifoldsBase.extensions]
    ManifoldsBaseMakieExt = "Makie"
    ManifoldsBasePlotsExt = "Plots"
    ManifoldsBaseQuaternionsExt = "Quaternions"
    ManifoldsBaseRecursiveArrayToolsExt = "RecursiveArrayTools"
    ManifoldsBaseStatisticsExt = "Statistics"

    [deps.ManifoldsBase.weakdeps]
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
    Quaternions = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.Manopt]]
deps = ["DataStructures", "Dates", "Glossaries", "LinearAlgebra", "ManifoldDiff", "ManifoldsBase", "Markdown", "Preferences", "Printf", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "1087e0b79e620e2d8df1ad3fdbc96ef69d3e47c7"
uuid = "0fc0a36d-df90-57f3-8f93-d78a9fc72bb5"
version = "0.6.3"

    [deps.Manopt.extensions]
    ManoptLRUCacheExt = "LRUCache"
    ManoptLineSearchesExt = "LineSearches"
    ManoptManifoldsExt = "Manifolds"
    ManoptRecursiveArrayToolsExt = "RecursiveArrayTools"
    ManoptRipQPQuadraticModelsExt = ["RipQP", "QuadraticModels"]

    [deps.Manopt.weakdeps]
    LRUCache = "8ac3fa9e-de4c-5943-b1dc-09c6b5f20637"
    LineSearches = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
    Manifolds = "1cead3c2-87b3-11e9-0ccd-23c62b72b94e"
    QuadraticModels = "f468eda6-eac5-11e8-05a5-ff9e497bcd19"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"
    RipQP = "1e40b3f8-35eb-4cd8-8edd-3e515bb9de08"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MatrixEquations]]
deps = ["LinearAlgebra", "LinearMaps"]
git-tree-sha1 = "e357e9f4cf3b1306ba6119e49e4d94cd57816835"
uuid = "99c1a7ee-ab34-5fd5-8076-27c950a045f4"
version = "2.6.3"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "dbd2e8cd2c1c27f0b584f6661b4309609c5a685e"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.4"

[[deps.NamedDims]]
deps = ["LinearAlgebra", "Statistics"]
git-tree-sha1 = "f9e4a49ecd1ea2eccfb749a506fa882c094152b4"
uuid = "356022a1-0364-5f58-8944-0da4b18d706f"
version = "1.2.3"

    [deps.NamedDims.extensions]
    AbstractFFTsExt = "AbstractFFTs"
    ChainRulesCoreExt = "ChainRulesCore"
    CovarianceEstimationExt = "CovarianceEstimation"
    TrackerExt = "Tracker"

    [deps.NamedDims.weakdeps]
    AbstractFFTs = "621f4979-c628-5d54-868e-fcf4e3e8185c"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    CovarianceEstimation = "587fd27a-f159-11e8-2dae-1979310e6154"
    Requires = "ae029012-a4dd-5104-9daa-d747884805df"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.7+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05f45c2e0de6259db764adbfd2f1dc6d3f8de13c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "2.0.1"

[[deps.PackageExtensionCompat]]
git-tree-sha1 = "fb28e33b8a95c4cee25ce296c817d89cc2e53518"
uuid = "65ce6f38-6b18-4e1d-a461-8949797d7930"
version = "1.0.2"
weakdeps = ["Requires", "TOML"]

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "edbeefc7a4889f528644251bdb5fc9ab5348bc2c"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "fbb92c6c56b34e1a2c4c36058f68f332bec840e7"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "4fbbafbc6251b883f4d2705356f3641f3652a7fe"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.4.0"

[[deps.Quaternions]]
deps = ["LinearAlgebra", "Random", "RealDot"]
git-tree-sha1 = "4d8c1b7c3329c1885b857abb50d08fa3f4d9e3c8"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.7.7"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "LinearAlgebra", "PrecompileTools", "RecipesBase", "SciMLPublic", "StaticArraysCore", "SymbolicIndexingInterface"]
git-tree-sha1 = "89a235781fdda53fe6c8092e4a4ed9ce9cf04ed3"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "4.3.6"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsCUDAExt = "CUDA"
    RecursiveArrayToolsFastBroadcastExt = "FastBroadcast"
    RecursiveArrayToolsFastBroadcastPolyesterExt = ["FastBroadcast", "Polyester"]
    RecursiveArrayToolsForwardDiffExt = "ForwardDiff"
    RecursiveArrayToolsKernelAbstractionsExt = "KernelAbstractions"
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    RecursiveArrayToolsMooncakeExt = "Mooncake"
    RecursiveArrayToolsReverseDiffExt = ["ReverseDiff", "Zygote"]
    RecursiveArrayToolsSparseArraysExt = ["SparseArrays"]
    RecursiveArrayToolsStatisticsExt = "Statistics"
    RecursiveArrayToolsStructArraysExt = "StructArrays"
    RecursiveArrayToolsTablesExt = ["Tables"]
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    FastBroadcast = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    Polyester = "f517fe37-dbe3-4b94-8317-1923a5111588"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "65c9e1142f0372bfc16ba14b9edd57737fe0039f"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.24"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SciMLPublic]]
git-tree-sha1 = "cf9aaf8b9ed5db993259ea8b24cf2b7ba9bd3b79"
uuid = "431bcebd-1456-4ced-9d72-93c2757fff0b"
version = "1.2.4"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "7ddb0b49c109481b046972c0e4ab02b2127d6a75"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.6"

[[deps.SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays"]
git-tree-sha1 = "749a2b719ec7f34f280c0d97ac3dab5c89818631"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.5.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "13cd91cc9be159e3f4d95b857fa2aa383b53772a"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.3"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.12.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "c3ac026e735264e9bdc6a9bcbd1b1e781b36e3bc"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.8.3"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "246a8bb2e6667f832eea063c3a56aef96429a3db"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.18"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6ab403037779dae8c514bad259f32a447262455a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.4"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "178ed29fd5b2a2cfc3bd31c13375ae925623ff36"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.8.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "e4d7a1a0edc20af42689ea6f4f3587a2175d50ee"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.12"

[[deps.Strided]]
deps = ["LinearAlgebra", "PrecompileTools", "StridedViews", "TupleTools"]
git-tree-sha1 = "5fa7f6845c91e6e351880cee67a9efc3b892bd3b"
uuid = "5e0ebb24-38b0-5f93-81fe-25c709ecae67"
version = "2.6.4"

    [deps.Strided.extensions]
    StridedAMDGPUExt = "AMDGPU"
    StridedGPUArraysExt = "GPUArrays"
    StridedcuBLASExt = "cuBLAS"

    [deps.Strided.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    GPUArrays = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
    cuBLAS = "182d3088-87b7-4494-8cad-fc6afaa545bc"

[[deps.StridedViews]]
deps = ["LinearAlgebra", "PrecompileTools"]
git-tree-sha1 = "21dc3942c478661f72c527ff5d67baa98e555372"
uuid = "4db3bf67-4bd7-4b4e-b153-31dc3fb37143"
version = "0.5.2"

    [deps.StridedViews.extensions]
    StridedViewsAMDGPUExt = "AMDGPU"
    StridedViewsAdaptExt = "Adapt"
    StridedViewsCUDACoreExt = "CUDACore"
    StridedViewsJLArraysExt = "JLArrays"
    StridedViewsPtrArraysExt = "PtrArrays"

    [deps.StridedViews.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    CUDACore = "bd0ed864-bdfe-4181-a5ed-ce625a5fdea2"
    JLArrays = "27aeb0d3-9eb9-45fb-866b-73c2ecf80fcb"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    PtrArrays = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.8.3+2"

[[deps.SymbolicIndexingInterface]]
deps = ["Accessors", "ArrayInterface", "RuntimeGeneratedFunctions", "StaticArraysCore"]
git-tree-sha1 = "ae6fd46b22508c2dfcd0fabf144ce5e9d9d2e719"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.3.53"

    [deps.SymbolicIndexingInterface.extensions]
    SymbolicIndexingInterfacePrettyTablesExt = "PrettyTables"

    [deps.SymbolicIndexingInterface.weakdeps]
    PrettyTables = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TensorKitchen]]
deps = ["JuliaFormatter", "LinearAlgebra", "Manifolds", "ManifoldsBase", "Manopt", "PrecompileTools", "ProgressMeter", "Random", "RecursiveArrayTools", "TensorOperations"]
git-tree-sha1 = "4641efca48aa45423a22f140ac78079abfdd21bd"
repo-rev = "v0.2.0"
repo-url = "https://github.com/TensorKitchen/TensorKitchen.jl.git"
uuid = "3630a16b-0f2f-4d88-afbf-c7d59eccf553"
version = "0.2.0"

[[deps.TensorOperations]]
deps = ["LRUCache", "LinearAlgebra", "PackageExtensionCompat", "PrecompileTools", "Preferences", "PtrArrays", "Strided", "StridedViews", "TupleTools", "VectorInterface"]
git-tree-sha1 = "e8c1d2e0e5ff26553ded73be8e55a88efd671eb9"
uuid = "6aa20fa7-93e2-5fca-9bc0-fbd0db3c71a2"
version = "5.7.0"

    [deps.TensorOperations.extensions]
    TensorOperationsAMDGPUExt = "AMDGPU"
    TensorOperationsBumperExt = "Bumper"
    TensorOperationsCUDACoreExt = "CUDACore"
    TensorOperationsChainRulesCoreExt = "ChainRulesCore"
    TensorOperationsEnzymeExt = "Enzyme"
    TensorOperationsJLArraysExt = "JLArrays"
    TensorOperationsMooncakeExt = "Mooncake"
    TensorOperationscuTENSORExt = "cuTENSOR"

    [deps.TensorOperations.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    Bumper = "8ce10254-0962-460f-a3d8-1f77fea1446e"
    CUDACore = "bd0ed864-bdfe-4181-a5ed-ce625a5fdea2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    JLArrays = "27aeb0d3-9eb9-45fb-866b-73c2ecf80fcb"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    cuTENSOR = "011b41b2-24ef-40a8-b3eb-fa098493e9e1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tullio]]
deps = ["DiffRules", "LinearAlgebra", "Requires"]
git-tree-sha1 = "de0febfe1243e89f352abd4ca0e9de6c8e6190c5"
uuid = "bc48ee85-29a4-5162-ae0b-a64e1601d4bc"
version = "0.3.9"

    [deps.Tullio.extensions]
    TullioCUDAExt = "CUDA"
    TullioChainRulesCoreExt = "ChainRulesCore"
    TullioFillArraysExt = "FillArrays"
    TullioTrackerExt = "Tracker"

    [deps.Tullio.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    FillArrays = "1a297f60-69ca-5386-bcde-b61e274b549b"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.TupleTools]]
git-tree-sha1 = "41e43b9dc950775eac654b9f845c839cd2f1821e"
uuid = "9d95972d-f1c8-5527-a6e0-b4b365fa01f6"
version = "1.6.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.VectorInterface]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "949dd28df19a5bf0973214e4a9d36c19079d4d45"
uuid = "409d34a3-91d5-4945-b6ec-7529ddf182d8"
version = "0.6.0"

    [deps.VectorInterface.extensions]
    VectorInterfaceChainRulesCoreExt = "ChainRulesCore"
    VectorInterfaceEnzymeExt = "Enzyme"
    VectorInterfaceMooncakeExt = "Mooncake"
    VectorInterfaceStaticArraysExt = "StaticArrays"

    [deps.VectorInterface.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"
"""

# ╔═╡ Cell order:
# ╟─cece0f98-a9d1-4e8e-a218-6b01a0d7486a
# ╟─e1916c58-a025-46da-8584-8c1c32314237
# ╠═9a2a8351-25d3-4bb7-aa12-42f7dce4a801
# ╟─a8d37d26-c3f4-41a8-a25f-43b91cdd15b6
# ╟─d333cfa5-dc56-45aa-bd31-949322dc1019
# ╟─afc199e3-3303-492f-8929-3858029211c2
# ╟─0e23b980-5cd0-42ac-b19f-f71b2cc5754e
# ╟─d3300001-e237-4d09-94a3-40a9288f6ab2
# ╟─aa0ad7c9-d080-4808-85d6-aad466f2cc8e
# ╠═2bff8e06-c245-4e31-ab2f-940425745672
# ╟─5557d442-1440-43ad-9671-50d8fc162c2e
# ╟─caed6d54-555b-4554-be16-6afbb1fa82e8
# ╟─20f1e1e8-69fb-4ce2-bf1b-659bbc597f15
# ╠═40f4fe24-8a27-4a8e-9d18-8136d989da7e
# ╠═801210da-c642-4550-94fd-a031f91223a6
# ╠═e168700d-d715-47cb-91eb-92b995560b0e
# ╟─55cb3d04-b421-4e94-a835-549997cbb84d
# ╟─d3300002-5de6-4e86-b793-6c2810776cf4
# ╟─394fc1c6-25ce-4edf-b6dc-868086185c3d
# ╟─f0842b0a-fc23-4390-a9a1-493b720ba24d
# ╟─d3300004-5de6-4e86-b793-6c2810776cf4
# ╟─f0842b0b-fc23-4390-a9a1-493b720ba24d
# ╟─b263a1d1-6f69-4994-9ab9-d5b2e818356b
# ╟─d3300003-5dd7-40e5-a3ee-986e586a40e3
# ╟─6c45be83-4fc7-44a1-9cf3-1c54c16babd0
# ╟─79421847-df2a-438d-9572-9781558967b3
# ╟─3e4976a8-217b-4a49-a7e2-e4e3a7763ea6
# ╟─03512fbd-c0ce-4251-8e83-ebf899b909ca
# ╟─971ea2d2-94a8-4a7c-9ae7-97811232d781
# ╟─cd911313-f6c5-4d83-8ec0-cb2ae61361e3
# ╟─23744f53-982b-40a1-8d92-d8553204e956
# ╟─24bd44ca-e383-4e99-8630-1d1bbf17cf13
# ╟─a3c93f10-4878-4d8b-88e2-e84c824543a1
# ╟─9b32115c-d09a-4eb5-936b-58c153a39b45
# ╟─09da72c2-9352-4d4b-8504-7ed0afab4c4a
# ╟─15b22a8b-eeba-4198-b2f7-f04f3229ac2a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
