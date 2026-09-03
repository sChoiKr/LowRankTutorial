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

# ╔═╡ d5746a1e-713a-4a2c-81d4-2bb5ad2f8600
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
    include(joinpath(@__DIR__, "Lab2CapacityData.jl"))
    using .Lab2CapacityData
end

# ╔═╡ bb3a9421-8680-4191-ae85-7460e133718b
md"""
# Lab 2 Geometry Atlas

**Paul Breiding  Se Eun Choi**

## One low-rank idea, several geometric objects

Recent AI methods use low rank in different ways: as learned orthonormal
frames, intrinsic fixed-rank matrices, rank-one tensor operators, or coupled
mode subspaces. This lab asks:

1. what counts as one component;
2. which coordinates describe it;
3. which coordinate changes preserve the represented object;
4. whether poor fit comes from model capacity or optimization.

Follow the same loop as Lab 1: **predict, manipulate, observe, explain, check**.

!!! tip "Presenter-controlled execution"
    Structural tabs respond immediately. Numerical experiments wait for their
    olive run controls. Explain and predict first; reveal only the next result
    when you are ready.
"""

# ╔═╡ a2400001-6a70-4e0e-9e35-9e0220260001
md"""
## Matrix geometry meets tensor geometry

Low-rank geometry asks us to decide whether we mean an individual basis vector,
the subspace spanned by several vectors, or the reconstructed object itself.
An orthonormal frame can rotate without changing its subspace, and different
``U,S,V`` coordinates can reconstruct the same low-rank matrix ``W=USV^\top``.
The same distinction reappears for CP rank-one components and Tucker mode
subspaces: interpret the represented object first, and raw coordinates only
after accounting for their equivalences.

Use the four tabs below and ask the same question each time: **what is the
coordinate description, and what is the object that should remain unchanged?**
"""

# ╔═╡ a2400002-6a70-4e0e-9e35-9e0220260002
ai_geometry_bridge_visual()

# ╔═╡ a2400004-6a70-4e0e-9e35-9e0220260004

begin
    optional_math_body = repr(
        MIME"text/html"(),
        md"""
The Stiefel manifold is
``\mathrm{St}(n,r)=\{U\in\mathbb{R}^{n\times r}:U^\top U=I_r\}``.
An orthogonal change ``U\mapsto UQ`` changes the frame but preserves
``\operatorname{span}(U)``.

The fixed-rank set is
``\mathcal M_r=\{W\in\mathbb{R}^{m\times n}:\operatorname{rank}(W)=r\}``.
With ``W=USV^\top``, the transformation
``(U,S,V)\mapsto(UQ,Q^\top SR,VR)``
leaves ``W`` unchanged for orthogonal ``Q,R``.

A CP rank-one term is a Segre object ``a\otimes b\otimes c``.
Tucker uses one mode subspace per axis and a core; basis changes in those
subspaces can be absorbed by the core. TensorKitchen's `JoinModel`
combines Segre terms for CP and Tucker blocks for BTD.
"""
    )

    Base.HTML("""
    <details style="
        margin:1rem 0;
        border:1px solid #d3d7c5;
        border-radius:12px;
        padding:.75rem .9rem;
    ">
      <summary style="
          cursor:pointer;
          font-weight:700;
          color:#4f5934;
      ">
        Optional math: Formal manifold definitions and coordinate gauges
      </summary>

      <div style="margin-top:.8rem;line-height:1.5">
        $optional_math_body
      </div>
    </details>
    """)
end

# ╔═╡ a2400003-6a70-4e0e-9e35-9e0220260003
md"""
### Why these objects appear in current AI research

- [StelLA (Li et al., NeurIPS 2025)](https://proceedings.neurips.cc/paper_files/paper/2025/hash/6cb0c6e7d50d5d65613f0456ca85e2db-Abstract-Conference.html)
  uses Stiefel-constrained factors to make the learned input and output
  subspaces of low-rank adaptation explicit.
- [RAdaGrad/RAdamW (Bian et al., NeurIPS 2025)](https://proceedings.neurips.cc/paper_files/paper/2025/hash/5679173c400b332796426e443ab5ea0d-Abstract-Conference.html)
  optimize fixed-rank DNN weight matrices as manifold objects rather than
  treating one redundant factor pair as the object itself.
- [Tensor Decomposition Networks (Lin et al., NeurIPS 2025)](https://proceedings.neurips.cc/paper_files/paper/2025/hash/7fe3f83c15c1c96daf4689d358c9cadf-Abstract-Conference.html)
  use CP-style low-rank structure inside expensive equivariant tensor-product
  operators.
- [CRAFT (Fel et al., CVPR 2023)](https://openaccess.thecvf.com/content/CVPR2023/html/Fel_CRAFT_Concept_Recursive_Activation_FacTorization_for_Explainability_CVPR_2023_paper.html)
  uses matrix NMF on neural activations to discover candidate concept directions;
  Lab 4 then asks what semantic and behavioral evidence supports them.

The same low-rank idea is used for **subspace learning**, **intrinsic weight
optimization**, **architectural efficiency**, and **interpretation**.

**Checkpoint.** For ``W=USV^\top``, which item should be compared across two
runs: the raw columns, their subspaces, or the reconstructed matrix? The answer
depends on the claim. Compare ``W`` for object equality, compare subspaces for
learned input/output spaces, and compare raw columns only after resolving their
basis ambiguity.
"""

# ╔═╡ b852133b-c61e-4ed7-acd3-076043bebc73
md"""
## Model cards

| Model | Object | Basic component | Coordinates | Essential equivalence | TensorKitchen view |
|:--|:--|:--|:--|:--|:--|
| CP | rank-at-most-``R`` tensor | rank-one Segre tensor | weights and factor vectors | reciprocal scaling and component permutation | `cpd`, `components` |
| Tucker | multilinear rank at most ``(r_1,\ldots,r_d)``; fixed-rank stratum when every mode rank is attained | one core with mode subspaces | core and mode factors | basis changes absorbed by the core | `tucker`, `core`, `factors` |
| BTD | sum of multilinear-rank blocks | Tucker block | one core and factors per block | Tucker gauges inside blocks and block permutation | `btd`, `blocks` |

**Predict.** Which model should naturally describe a sum of two
multilinear-rank blocks? Does belonging to a model class guarantee that an
iterative optimizer will find the exact representation?
"""

# ╔═╡ b852133c-c61e-4ed7-acd3-076043bebc73
Base.HTML(raw"""
<details style="margin:.8rem 0;border:1px solid #d3d7c5;border-radius:12px;padding:.7rem .85rem">
  <summary style="cursor:pointer;font-weight:700;color:#4f5934">Optional tensor mechanics: How does HOSVD find mode subspaces?</summary>
  <p style="line-height:1.5">HOSVD forms one matrix unfolding per tensor mode and uses its singular vectors to construct that mode's Tucker subspace. The three unfolding ranks form the multilinear rank; they need not equal CP rank. After building the tensors below, inspect <code>hosvd_summary</code> for a small <code>(3,3,2)</code> example.</p>
</details>
""")

# ╔═╡ fa60d7da-320d-45f3-a938-ae9cdaf33c41
begin
    nothing
end

# ╔═╡ c003bff4-9bf3-440c-a647-3e1e458f78b5
nothing

# ╔═╡ b2200001-0fdf-432c-8e85-522ae2df06e6
@bind run_atlas_problem manual_run_button("Build the two-block tensor")

# ╔═╡ d5f72a11-a2fe-42a8-8682-77ff62475d47
if manual_run_requested(run_atlas_problem)
begin
    atlas_problem = make_two_block_tensor()

    hosvd_rng = MersenneTwister(2026082004)
    hosvd_tensor = randn(hosvd_rng, 3, 3, 2)
    hosvd_unfoldings = [mode_unfolding(hosvd_tensor, mode) for mode = 1:3]
    hosvd_ranks = Tuple(rank(unfolding) for unfolding in hosvd_unfoldings)
    hosvd_result = tucker(hosvd_tensor, hosvd_ranks; method = :sthosvd)
    hosvd_summary = (
        tensor_size = size(hosvd_tensor),
        unfolding_sizes = size.(hosvd_unfoldings),
        unfolding_ranks = hosvd_ranks,
        multilinear_rank = size(core(hosvd_result)),
        relative_error = rel_error(hosvd_tensor, hosvd_result),
    )
end
else
    atlas_problem = hosvd_rng = hosvd_tensor = hosvd_unfoldings = hosvd_ranks =
        hosvd_result = hosvd_summary = nothing
    manual_waiting("Build the two-block tensor")
end

# ╔═╡ a2500001-6a70-4e0e-9e35-9e0220260001
if !isnothing(atlas_problem)
    tensor_slices_visual(
        "Block 1: localized structure" => atlas_problem.true_blocks[1],
        "Block 2:  second structure" => atlas_problem.true_blocks[2],
        "Target:  block 1 + block 2" => atlas_problem.target;
        title = "The target is visibly assembled from two multilinear blocks",
        shared_scale = true,
        reveal = false,
    )
else
    manual_waiting("Build the target to reveal its two generating blocks.")
end

# ╔═╡ a2500002-6a70-4e0e-9e35-9e0220260002
md"""
## Experiment: Can the model represent it, and can the algorithm find it?

The target is the sum of two rank-``(2,2,1)`` Tucker blocks. Before running a
solver, predict whether each model class contains this tensor exactly:

| Candidate model | Exact representation possible? |
|:--|:--:|
| CP rank 4 | ? |
| Tucker rank ``(4,4,2)`` | ? |
| two-block BTD with block rank ``(2,2,1)`` | ? |

The next reveal uses **explicit representations**.
This separates the question “is the target in the model family?” from “did this finite run find it?”
"""

# ╔═╡ a2500003-6a70-4e0e-9e35-9e0220260003
@bind run_atlas_capacity manual_run_button("Reveal exact model capacity")

# ╔═╡ a2500004-6a70-4e0e-9e35-9e0220260004
if manual_run_requested(run_atlas_capacity) && !isnothing(atlas_problem)
begin
    atlas_target = atlas_problem.target
    atlas_cp_oracle = cp_oracle_representation(atlas_problem)
    atlas_tucker_oracle = tucker(atlas_target, (4, 4, 2); method = :sthosvd)
    atlas_btd_oracle_reconstruction = sum(atlas_problem.true_blocks)
    atlas_capacity = (
        actual_multilinear_rank = atlas_problem.multilinear_rank,
        cp_rank = atlas_cp_oracle.rank_bound,
        cp_error = norm(atlas_target - atlas_cp_oracle.reconstruction) / norm(atlas_target),
        tucker_error = rel_error(atlas_target, atlas_tucker_oracle),
        btd_error = norm(atlas_target - atlas_btd_oracle_reconstruction) / norm(atlas_target),
        cp2_floor = unfolding_rank_lower_bound(atlas_target, (2, 2, 2)).lower_bound,
        tucker221_floor = unfolding_rank_lower_bound(atlas_target, (2, 2, 1)).lower_bound,
    )
end
else
    atlas_target = atlas_cp_oracle = atlas_tucker_oracle =
        atlas_btd_oracle_reconstruction = atlas_capacity = nothing
    manual_waiting(isnothing(atlas_problem) ? "Build the two-block tensor first." : "Reveal capacity before asking the algorithms to fit the target.")
end

# ╔═╡ a2500005-6a70-4e0e-9e35-9e0220260005
if !isnothing(atlas_capacity)
md"""
### Capacity reveal

| Model | Explicit representation error | Reading |
|:--|--:|:--|
| CP rank 4 | **$(round(atlas_capacity.cp_error; sigdigits=3))** | each ``(2,2,1)`` block contributes at most two rank-one terms |
| Tucker ``(4,4,2)`` | **$(round(atlas_capacity.tucker_error; sigdigits=3))** | the requested mode ranks contain the target |
| BTD: 2 × ``(2,2,1)`` | **$(round(atlas_capacity.btd_error; sigdigits=3))** | these are the two generating blocks |

The target's unfolding ranks are **$(atlas_capacity.actual_multilinear_rank)**.
The explicit four-term CP construction shows that CP rank 4 is sufficient.
The positive mode-unfolding error floor shows that CP rank 2 is insufficient.
"""
else
    manual_waiting("The exact representations will appear after the capacity reveal.")
end

# ╔═╡ a2500010-6a70-4e0e-9e35-9e0220260010
Base.HTML(raw"""
<details style="margin:.8rem 0;border:1px solid #d3d7c5;border-radius:12px;padding:.7rem .85rem">
  <summary style="cursor:pointer;font-weight:700;color:#4f5934">Optional challenge: Prove that the CP rank is exactly four</summary>
  <p style="line-height:1.5">Each of the two generating \((2,2,1)\) Tucker blocks has CP rank at most two, so their sum has CP rank at most four. The mode-1 unfolding has matrix rank four, and every CP representation needs at least that many rank-one terms. Together, the upper and lower bounds prove CP rank exactly four.</p>
</details>
""")

# ╔═╡ b2200002-e854-4567-8f7b-075870cf81a8
@bind run_atlas_fits manual_run_button("Let the finite algorithms try")

# ╔═╡ 5279578a-3c0f-49b2-861c-e65802c0d995
if manual_run_requested(run_atlas_fits) && !isnothing(atlas_capacity)
begin
    oracle_btd_reconstruction = sum(atlas_problem.true_blocks)
    oracle_btd_error = norm(atlas_target - oracle_btd_reconstruction) / norm(atlas_target)

    # Sufficient-capacity models.
    tucker_atlas = atlas_tucker_oracle

    Random.seed!(atlas_problem.seed)
    cp_atlas = cpd(
        atlas_target,
        4;
        solver = :als,
        init = :random,
        maxiter = 60,
        tol = 1e-8,
        verbose = false,
    )

    Random.seed!(atlas_problem.seed)
    btd_atlas = btd(
        atlas_target,
        atlas_problem.block_count,
        atlas_problem.block_rank;
        solver = :als,
        init = :random,
        maxiter = 30,
        tol = 1e-8,
        block_method = :sthosvd,
        max_stagnation_restarts = 0,
        verbose = false,
    )

    # Deliberately underspecified models. A larger iteration budget cannot
    # remove their positive unfolding-rank capacity floor.
    Random.seed!(atlas_problem.seed)
    cp_atlas_low = cpd(
        atlas_target,
        2;
        solver = :als,
        init = :random,
        maxiter = 60,
        tol = 1e-8,
        verbose = false,
    )
    tucker_atlas_low = tucker(atlas_target, (2, 2, 1); method = :sthosvd)
    # A one-block BTD is precisely one Tucker block. TensorKitchen's joined BTD
    # API starts at two blocks, so the one-block comparison uses this equivalent
    # Tucker representation directly.
    btd_atlas_low = tucker_atlas_low
end
else
    oracle_btd_reconstruction = oracle_btd_error = tucker_atlas = cp_atlas =
        btd_atlas = cp_atlas_low = tucker_atlas_low = btd_atlas_low = nothing
    manual_waiting(isnothing(atlas_capacity) ? "Build the target and reveal exact model capacity first." : "Fit CP, Tucker, and BTD")
end

# ╔═╡ b2200003-2988-45c7-8f90-34fb6ded99f4
@bind run_atlas_summary manual_run_button("Compare capacity with achieved fit")

# ╔═╡ 1367b9b7-ad09-4c6b-ab38-cf4e2f5c8a01
if manual_run_requested(run_atlas_summary) && !isnothing(cp_atlas)
begin
    dims = atlas_problem.dimensions
    cp_rank = 4
    tucker_rank = (4, 4, 2)
    block_rank = atlas_problem.block_rank
    block_count = atlas_problem.block_count

    # These are raw coordinate counts, not intrinsic manifold dimensions.
    coordinate_counts = (
        cp = cp_rank * (1 + sum(dims)),
        tucker = prod(tucker_rank) + sum(dims .* tucker_rank),
        btd = block_count * (prod(block_rank) + sum(dims .* block_rank)),
    )

    atlas_summary = (
        oracle_btd_error = oracle_btd_error,
        fitted_cp_error = rel_error(atlas_target, cp_atlas),
        fitted_tucker_error = rel_error(atlas_target, tucker_atlas),
        fitted_btd_error = rel_error(atlas_target, btd_atlas),
        fitted_cp_iterations = iterations(cp_atlas),
        fitted_btd_iterations = iterations(btd_atlas),
        coordinate_counts = coordinate_counts,
        sufficient = [
            (
                model = "CP",
                setting = "rank 4",
                capacity_error = atlas_capacity.cp_error,
                fitted_error = rel_error(atlas_target, cp_atlas),
                reason = "An explicit four-term CP representation proves that the family contains the target.",
                method = "finite randomized-start CP-ALS: 60 sweeps",
            ),
            (
                model = "Tucker",
                setting = "rank (4,4,2)",
                capacity_error = atlas_capacity.tucker_error,
                fitted_error = rel_error(atlas_target, tucker_atlas),
                reason = "All three requested mode ranks match the target's unfolding ranks.",
                method = "direct sequentially truncated HOSVD",
            ),
            (
                model = "BTD",
                setting = "2 × (2,2,1)",
                capacity_error = atlas_capacity.btd_error,
                fitted_error = rel_error(atlas_target, btd_atlas),
                reason = "The two generating Tucker blocks are an exact BTD representation.",
                method = "finite randomized-start BTD-ALS: 30 sweeps",
            ),
        ],
        reduced = [
            (
                model = "CP",
                setting = "rank 2",
                capacity_error = atlas_capacity.cp2_floor,
                fitted_error = rel_error(atlas_target, cp_atlas_low),
                reason = "A rank-2 CP tensor cannot have a mode-1 unfolding of rank 4.",
                method = "finite randomized-start CP-ALS: 60 sweeps",
            ),
            (
                model = "Tucker",
                setting = "rank (2,2,1)",
                capacity_error = atlas_capacity.tucker221_floor,
                fitted_error = rel_error(atlas_target, tucker_atlas_low),
                reason = "The requested mode ranks are smaller than the target's (4,4,2) ranks.",
                method = "direct sequentially truncated HOSVD",
            ),
            (
                model = "BTD",
                setting = "1 × (2,2,1)",
                capacity_error = atlas_capacity.tucker221_floor,
                fitted_error = rel_error(atlas_target, btd_atlas_low),
                reason = "One block has unfolding ranks at most (2,2,1), below the target ranks.",
                method = "one-block BTD = Tucker (2,2,1): direct STHOSVD",
            ),
        ],
    )
end
else
    dims = cp_rank = tucker_rank = block_rank = block_count = coordinate_counts =
        atlas_summary = nothing
    manual_waiting(isnothing(cp_atlas) ? "Run the finite fits first." : "Compute model comparison summary")
end

# ╔═╡ a2500006-6a70-4e0e-9e35-9e0220260006
if !isnothing(atlas_summary)
    capacity_fit_visual(
        atlas_summary.sufficient,
        atlas_summary.reduced;
        actual_multilinear_rank = atlas_capacity.actual_multilinear_rank,
    )
else
    manual_waiting("Run the fits, then compare capacity bounds with achieved errors.")
end

# ╔═╡ b2200004-a4cb-40c3-b160-417cffb766dc
@bind run_atlas_visual manual_run_button("▶ Reveal the slice comparison")

# ╔═╡ 424968ea-f51d-4843-be58-69d36aed6232
if manual_run_requested(run_atlas_visual) && !isnothing(atlas_summary)
tensor_slices_visual(
    "Target mini-video" => atlas_target,
    "CP reconstruction" => reconstruct(cp_atlas),
    "Tucker reconstruction" => reconstruct(tucker_atlas),
    "BTD reconstruction" => reconstruct(btd_atlas);
    title = "Move through time and compare the model assumptions",
    shared_scale = true,
    reveal = false,
)
else
    manual_waiting(isnothing(atlas_summary) ? "Complete the model comparison first." : "Reveal the slice comparison")
end

# ╔═╡ e80b86d5-b968-45f6-8327-78c335ec4e8c
md"""
## Model capacity is not optimization success

The target admits an exact four-component CP representation, has multilinear
rank ``(4,4,2)``, and has an exact two-block BTD
representation. The blue values above come from explicit representations or SVD-based 
unfolding-rank lower bounds. The orange values come from particular algorithms and 
finite budgets.

This distinction is fundamental. An observed reconstruction error can reflect
contributions from **model mismatch**, **optimization suboptimality**, and
**numerical effects**. These contributions are diagnostic categories, not an
exact additive decomposition of the scalar relative error.

The experiment separates the first two diagnostic categories:

- if an explicit representation reaches roundoff but a finite fit does not,
  the gap concerns optimization;
- if the unfolding ranks impose a positive error floor, more iterations cannot
  repair the missing model capacity.

Tucker ``(4,4,2)`` is found by a direct SVD-based method. CP uses rank-one terms
instead of multilinear-rank blocks; its rank-four fit is a different coordinate
system and a different nonconvex problem.

The coordinate counts above are storage-oriented counts. They include gauge
redundancy and should not be confused with intrinsic model dimension.
"""

# ╔═╡ d6ed9925-78dd-4aa7-b245-749493392466
md"""
## Inspect the learned objects

**Same tensor, different explanations.** All three sufficient-capacity models
can reconstruct this target, but the word *component* means something different
in each structural language.

```julia
components(cp_atlas)
core(tucker_atlas)
factors(tucker_atlas)
blocks(btd_atlas)
```

**Explain.** If Tucker achieves a smaller error here, does that prove Tucker is
always the better decomposition? Which statement concerns the model class, and
which concerns the algorithm and budget used in this one run?

**Explain.** Two models reconstruct the same tensor equally well. What evidence
would you need before saying that one decomposition is the more meaningful
explanation? Reconstruction alone does not answer that question; Lab 4 returns
to semantic and behavioral validation.
"""

# ╔═╡ a2500007-6a70-4e0e-9e35-9e0220260007
model_language_visual()

# ╔═╡ b2200005-e480-466c-8315-f622cc14502d
md"""
### Capacity challenge

Suppose the iteration budget is increased from 60 to 500, as in the control
immediately below.

- Could CP rank 2 become exact for this target?
- Could Tucker ``(2,2,1)`` become exact?
- Could one ``(2,2,1)`` BTD block become exact?

No. Each reduced model has unfolding ranks below the target's ``(4,4,2)``.
The positive blue lower bound in the reduced-capacity panel is independent of
the optimizer.
"""

# ╔═╡ a2500008-6a70-4e0e-9e35-9e0220260008
@bind run_atlas_more_iterations manual_run_button("Give CP rank 2 a 500-sweep budget")

# ╔═╡ a2500009-6a70-4e0e-9e35-9e0220260009
if manual_run_requested(run_atlas_more_iterations)
begin
    challenge_problem = make_two_block_tensor()
    challenge_floor = unfolding_rank_lower_bound(
        challenge_problem.target,
        (2, 2, 2),
    ).lower_bound

    Random.seed!(challenge_problem.seed)
    challenge_short = cpd(
        challenge_problem.target,
        2;
        solver = :als,
        init = :random,
        maxiter = 60,
        tol = 1e-8,
        verbose = false,
    )
    Random.seed!(challenge_problem.seed)
    challenge_long = cpd(
        challenge_problem.target,
        2;
        solver = :als,
        init = :random,
        maxiter = 500,
        tol = 1e-8,
        verbose = false,
    )

    short_error = rel_error(challenge_problem.target, challenge_short)
    long_error = rel_error(challenge_problem.target, challenge_long)
    md"""
    ### More optimization, same capacity limit

    | CP rank 2 run | Sweeps actually used | Relative error |
    |:--|--:|--:|
    | 60-sweep budget | **$(iterations(challenge_short))** | **$(round(short_error; sigdigits=5))** |
    | 500-sweep budget | **$(iterations(challenge_long))** | **$(round(long_error; sigdigits=5))** |
    | lower bound for every CP-rank-2 tensor | — | **≥ $(round(challenge_floor; sigdigits=5))** |

    The longer budget can reduce an optimization gap, but it cannot cross the
    positive capacity floor. Here the solver stops after
    **$(iterations(challenge_long))** sweeps because further ALS updates no
    longer make meaningful progress. Even an unlimited budget cannot make a
    CP-rank-2 tensor acquire the target's mode-1 unfolding rank of 4.
    """
end
else
    manual_waiting("Increase the iteration budget only after making your prediction.")
end

# ╔═╡ c949996c-01b9-4712-9c08-60a5b545c0bc
nothing

# ╔═╡ c1d78869-c3a2-484d-85fa-542503b33f92
md"""
### Takeaway

**A decomposition name specifies a family of objects.** CP chooses rank-one summands,
Tucker chooses interacting mode subspaces, and BTD chooses a sum of Tucker blocks.
Interpretation begins with that structural assumption; optimization diagnostics tell
us how well a particular algorithm reached the chosen family.
"""

# ╔═╡ b6eaf7d6-39f4-46c0-9f7d-bb0875773610
md"""
## Exercise - mode subspaces and model choice

Use the model cards and slice comparison above. Reveal answers one at a time
after recording your own observation. The HOSVD arithmetic is an optional
extension rather than a prerequisite for this exercise.
"""

# ╔═╡ 781f3223-9c87-4cc9-829c-c5cc790f6ddf
render_exercise(exercise_by_number(4))

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
# ╟─d5746a1e-713a-4a2c-81d4-2bb5ad2f8600
# ╟─bb3a9421-8680-4191-ae85-7460e133718b
# ╟─a2400001-6a70-4e0e-9e35-9e0220260001
# ╟─a2400002-6a70-4e0e-9e35-9e0220260002
# ╟─a2400004-6a70-4e0e-9e35-9e0220260004
# ╟─a2400003-6a70-4e0e-9e35-9e0220260003
# ╟─b852133b-c61e-4ed7-acd3-076043bebc73
# ╟─b852133c-c61e-4ed7-acd3-076043bebc73
# ╟─fa60d7da-320d-45f3-a938-ae9cdaf33c41
# ╟─c003bff4-9bf3-440c-a647-3e1e458f78b5
# ╟─b2200001-0fdf-432c-8e85-522ae2df06e6
# ╟─d5f72a11-a2fe-42a8-8682-77ff62475d47
# ╟─a2500001-6a70-4e0e-9e35-9e0220260001
# ╟─a2500002-6a70-4e0e-9e35-9e0220260002
# ╟─a2500003-6a70-4e0e-9e35-9e0220260003
# ╟─a2500004-6a70-4e0e-9e35-9e0220260004
# ╟─a2500005-6a70-4e0e-9e35-9e0220260005
# ╟─a2500010-6a70-4e0e-9e35-9e0220260010
# ╟─b2200002-e854-4567-8f7b-075870cf81a8
# ╟─5279578a-3c0f-49b2-861c-e65802c0d995
# ╟─b2200003-2988-45c7-8f90-34fb6ded99f4
# ╟─1367b9b7-ad09-4c6b-ab38-cf4e2f5c8a01
# ╟─a2500006-6a70-4e0e-9e35-9e0220260006
# ╟─b2200004-a4cb-40c3-b160-417cffb766dc
# ╟─424968ea-f51d-4843-be58-69d36aed6232
# ╟─e80b86d5-b968-45f6-8327-78c335ec4e8c
# ╟─d6ed9925-78dd-4aa7-b245-749493392466
# ╟─a2500007-6a70-4e0e-9e35-9e0220260007
# ╟─b2200005-e480-466c-8315-f622cc14502d
# ╟─a2500008-6a70-4e0e-9e35-9e0220260008
# ╟─a2500009-6a70-4e0e-9e35-9e0220260009
# ╟─c949996c-01b9-4712-9c08-60a5b545c0bc
# ╟─c1d78869-c3a2-484d-85fa-542503b33f92
# ╟─b6eaf7d6-39f4-46c0-9f7d-bb0875773610
# ╟─781f3223-9c87-4cc9-829c-c5cc790f6ddf
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
