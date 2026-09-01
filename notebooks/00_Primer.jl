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

# ╔═╡ 27f7d3a6-27cf-4d5b-baf9-3595a2668b55
begin
    using LinearAlgebra
    using Random
    using TensorKitchen
    include(joinpath(@__DIR__, "ExerciseContent.jl"))
    using .ExerciseContent
    include(joinpath(@__DIR__, "ManualExecution.jl"))
    using .ManualExecution
    include(joinpath(@__DIR__, "NotebookVisuals.jl"))
    using .NotebookVisuals
end

# ╔═╡ 43ec4b97-7a5a-4af0-b2c5-192a75aa73d2
md"""
# Introduction to TensorKitchen

## Motivation

Modern AI systems produce high-dimensional internal representations across samples, 
tokens, layers, spatial locations, or features. Low-rank factorizations provide 
one way to ask whether these representations contain simpler structured variation.

However, finding a low-dimensional factor is not enough. An internal feature is useful 
for auditing only if we understand the assumptions that produced it, the symmetries 
that make its coordinates non-unique, the numerical conditions under which it can be 
recovered, and whether it predicts or causally relates to behavior we care about.


## A short primer on tensor decompositions

A tensor is a multidimensional array. A vector has order one, a matrix has
order two, and an array `A[i,j,k]` has order three. Tensor decompositions replace
a large array by smaller structured objects that reveal or compress variation
across its modes.

This notebook introduces four TensorKitchen models:

1. **CP decomposition:** a sum of rank-one tensors;
2. **Tucker decomposition:** a small core coupled to one subspace per mode;
3. **block term decomposition (BTD):** a sum of Tucker blocks;
4. **nonnegative CP decomposition:** CP with nonnegative coordinates.

The aim is API orientation, not model selection. Labs 1–4 study ambiguity,
geometry, optimization failures, and interpretation in more depth.

!!! tip "Presenter-controlled execution"
    The experiment cells do not run when the page first opens. Explain the
    idea, make a prediction, and then press the olive **Play** button immediately
    above that code block to reveal its result.
"""

# ╔═╡ 023c6ad4-7eb3-451a-abd5-4dc6cdf78779
md"""
!!! note "Source and implementation"
    This primer adapts the mathematical progression of Paul Breiding's
    *Introduction to Tensorlab* to Julia and TensorKitchen. The mathematical
    definitions are standard; all executable examples below use
    TensorKitchen's public API and fixed random seeds.
"""

# ╔═╡ a1100001-0b9f-4ae5-91d6-418125e04dd0
@bind run_tensor_setup manual_run_button("▶ Tensor setup")

# ╔═╡ f83b831d-c09e-45ee-808b-d849239d0e80
if manual_run_requested(run_tensor_setup)
    begin
        running_tensor = zeros(3, 2, 2)
        running_tensor[:, :, 1] = [
            0.2582 0.2622
            0.4087 0.5949
            0.5959 0.2622
        ]
        running_tensor[:, :, 2] = [
            0.5261 0.5244
            0.8174 1.1898
            1.1898 0.5244
        ]

        tensor_anatomy = (
            order = ndims(running_tensor),
            dimensions = size(running_tensor),
            entries = length(running_tensor),
            frobenius_norm = norm(running_tensor),
        )
    end
else
    manual_waiting("Run tensor setup")
end

# ╔═╡ 3a7ec1c2-4f18-4bfa-b9d0-253f22fc9911
md"""
## 1. Why not flatten an activation tensor?

Suppose neural activations have axes **sample × token × feature**. Flattening
sample and token produces an ordinary matrix with the same entries, but the
row index no longer says whether a change came from the sample or the token.

Use the two views below. The arithmetic does not change—``3×4×5=12×5=60``—but
the tensor view keeps three separate scientific questions visible.

**Predict.** Which representation would you choose if you wanted to compare
token patterns across samples?
"""

# ╔═╡ 51d78d0a-82d7-4443-820f-a31ac7b1e393
flatten_vs_tensor_visual()

# ╔═╡ 38859d3f-319c-4801-bf1e-38eb600842cb
md"""
## Optional tensor mechanics: unfoldings and mode products

For ``A\in\mathbb{R}^{n_1\times\cdots\times n_d}``, the mode-``k`` unfolding
places mode ``k`` in the rows and all remaining modes in the columns.
TensorKitchen exposes this operation as `unfold_mode(A, k)`.

A mode product replaces one mode by applying a matrix:

```math
B=A\times_k U.
```

If `A` has size `(n₁,…,nₖ,…,n_d)` and `U` has size `m×nₖ`, then `B` has size
`(n₁,…,m,…,n_d)`.

This optional TensorLab-inspired experiment starts with a `(4, 3, 3)` tensor and
applies a separate linear map to every mode. Predict every intermediate shape
before reading `multilinear_summary`.
"""

# ╔═╡ a1100002-e82a-42eb-bf89-d4f9d2a7f71a
@bind run_modes manual_run_button("Optional · run modes and multilinear maps")

# ╔═╡ c5f88082-954d-4530-9d59-d82fe6beb6a5
if manual_run_requested(run_modes)
begin
    unfoldings = [unfold_mode(running_tensor, mode) for mode = 1:3]
    mode_map = [
        1.0 0.0 0.0
        0.0 1.0 0.0
        1.0 0.0 1.0
        0.0 1.0 1.0
    ]
    mode_product_example = mode_n_product(running_tensor, mode_map, 1)

    mode_summary = (
        unfolding_sizes = size.(unfoldings),
        original_size = size(running_tensor),
        product_size = size(mode_product_example),
    )

    multilinear_rng = MersenneTwister(2026082001)
    multilinear_tensor = randn(multilinear_rng, 4, 3, 3)
    M1 = randn(multilinear_rng, 2, 4)
    M2 = randn(multilinear_rng, 2, 3)
    M3 = randn(multilinear_rng, 2, 3)
    after_mode1 = mode_n_product(multilinear_tensor, M1, 1)
    after_mode2 = mode_n_product(after_mode1, M2, 2)
    multilinear_result = mode_n_product(after_mode2, M3, 3)
    multilinear_summary = (
        input_size = size(multilinear_tensor),
        map_sizes = size.((M1, M2, M3)),
        intermediate_sizes = (size(after_mode1), size(after_mode2)),
        output_size = size(multilinear_result),
        output_entries = length(multilinear_result),
    )
end
else
    manual_waiting("Run modes and multilinear maps")
end

# ╔═╡ ec814a15-3e3d-4daa-a73f-d4eaa1048d1e
md"""
## 2. Tucker: one core and several mode subspaces

A Tucker approximation has the form

```math
\widehat A=\mathcal G\times_1U^{(1)}\times_2\cdots\times_dU^{(d)}.
```

The tuple `(r₁,…,r_d)` is its multilinear rank. It can allocate a different
compression level to every mode. `tucker` computes the model; `core`, `factors`,
and `reconstruct` inspect the result.
"""

# ╔═╡ c2100001-83e0-4c67-8078-f6633fc9e738
decomposition_illustration(:tucker)

# ╔═╡ a1100003-2c62-49f7-89fd-08fa2d451221
@bind run_tucker manual_run_button("▶ Tucker decomposition")

# ╔═╡ f41e625e-33eb-48f9-b07d-39c884fbc4e3
if manual_run_requested(run_tucker)
begin
    tucker_result = tucker(running_tensor, (2, 2, 1); method = :sthosvd)
    tucker_summary = (
        core_size = size(core(tucker_result)),
        factor_sizes = size.(factors(tucker_result)),
        reconstruction_size = size(reconstruct(tucker_result)),
        relative_error = rel_error(running_tensor, tucker_result),
    )
end
else
    manual_waiting("Run Tucker decomposition")
end

# ╔═╡ 49500a20-fe0e-4315-8e06-f1e3a6d3c112
md"""
## 3. CP: a sum of rank-one components

A rank-``R`` CP approximation is

```math
\widehat A=\sum_{r=1}^{R}\lambda_r
u_r^{(1)}\otimes\cdots\otimes u_r^{(d)}.
```

Every mode shares the same number of components. `weights(result)` stores the
component magnitudes and `factors(result)` stores one factor matrix per mode.
CP fitting is nonconvex, so the requested rank and initialization matter.

For the reconstruction exercise, the notebook also generates a rank-3 tensor
from factor matrices of sizes `(3, 3)`, `(3, 3)`, and `(2, 3)`, fits a rank-3
CPD, and reports what object-level accuracy does and does not establish.
"""

# ╔═╡ c2100002-e79e-43bf-b54b-f5e49456c203
decomposition_illustration(:cpd)

# ╔═╡ a1100004-b187-4360-89ac-f8f057960da5
@bind run_cp manual_run_button("▶ CP decompositions")

# ╔═╡ 3073e49c-2591-4f93-a374-f6ae3eb8bb97
if manual_run_requested(run_cp)
begin
    Random.seed!(20260810)
    cp_result = cpd(
        running_tensor,
        2;
        solver = :als,
        init = :tucker,
        maxiter = 40,
        tol = 1e-8,
        verbose = false,
    )
    cp_summary = (
        weights = weights(cp_result),
        factor_sizes = size.(factors(cp_result)),
        components = length(components(cp_result)),
        relative_error = rel_error(running_tensor, cp_result),
    )

    cp_reconstruction_rng = MersenneTwister(2026082002)
    cp_original_factors = [
        Matrix{Float64}(I, 3, 3),
        Matrix{Float64}(I, 3, 3),
        [1.0 0.2 0.5; 0.1 1.0 -0.4],
    ]
    cp_original_weights = [1.4, 1.0, 0.7]
    cp_generated_tensor = reconstruct_cpd_rankr(
        cp_original_weights,
        cp_original_factors,
    )
    Random.seed!(2026082002)
    cp_recovered = cpd(
        cp_generated_tensor,
        3;
        solver = :als,
        init = :tucker,
        maxiter = 200,
        tol = 1e-12,
        verbose = false,
    )
    cp_reconstructed_tensor = reconstruct(cp_recovered)
    cp_reconstruction_experiment = (
        tensor_size = size(cp_generated_tensor),
        rank = 3,
        returned_weights = length(weights(cp_recovered)),
        returned_factor_sizes = size.(factors(cp_recovered)),
        reconstruction_size = size(cp_reconstructed_tensor),
        relative_frobenius_error = norm(cp_generated_tensor - cp_reconstructed_tensor) /
                                   norm(cp_generated_tensor),
    )
end
else
    manual_waiting("Run CP decompositions")
end

# ╔═╡ f7cc1f80-96ce-4459-bb98-93d4dff147ea
md"""
## 4. BTD: a sum of Tucker blocks

BTD combines the preceding ideas:

```math
\widehat A=\sum_{b=1}^{B}
\mathcal G_b\times_1U_b^{(1)}\times_2\cdots\times_dU_b^{(d)}.
```

Each summand is a Tucker block. TensorKitchen currently uses the same
multilinear rank for every block. `blocks(result)` exposes the fitted blocks.
This small call is only an API demonstration; Lab 2 separates model capacity
from optimization success more carefully.
"""

# ╔═╡ c2100003-206d-46a2-8b10-9d647c94bcd9
decomposition_illustration(:btd)

# ╔═╡ a1100005-bc96-4f6a-b333-fdf576afdd17
@bind run_btd manual_run_button("▶ BTD decomposition")

# ╔═╡ 5e5c00e0-4cbc-4e7b-929e-ac7b1ed62029
if manual_run_requested(run_btd)
begin
    Random.seed!(20260810)
    btd_result = btd(
        running_tensor,
        2,
        (1, 1, 1);
        solver = :als,
        init = :random,
        maxiter = 20,
        tol = 1e-8,
        block_method = :sthosvd,
        max_stagnation_restarts = 0,
        verbose = false,
    )
    btd_summary = (
        number_of_blocks = length(blocks(btd_result)),
        first_core_size = size(core(blocks(btd_result)[1])),
        relative_error = rel_error(running_tensor, btd_result),
    )
end
else
    manual_waiting("Run BTD decomposition")
end

# ╔═╡ 81f4cdfd-2da2-4dc1-b3ab-9033ef8be0e4
md"""
## 5. Nonnegative CP for nonnegative data

When negative component entries are not meaningful, `nncpd` constrains the CP coordinates
to be nonnegative. This is not a numerical preference, but a modeling assumption: it changes
which explanations are admissible.
"""

# ╔═╡ a1100006-1765-471f-9a70-d9c0968cd75c
@bind run_nncp manual_run_button("▶ Nonnegative CP")

# ╔═╡ d1ae1c80-69fc-49b5-993c-a53d87b732b8
if manual_run_requested(run_nncp)
begin
    nonnegative_tensor = abs.(running_tensor)
    Random.seed!(20260810)
    nncp_result = nncpd(
        nonnegative_tensor,
        2;
        solver = :als,
        init = :random,
        maxiter = 40,
        tol = 1e-8,
        verbose = false,
    )
    nncp_summary = (
        relative_error = rel_error(nonnegative_tensor, nncp_result),
        minimum_weight = minimum(weights(nncp_result)),
        minimum_factor_entry = minimum(minimum, factors(nncp_result)),
    )
end
else
    manual_waiting("Run nonnegative CP")
end

# ╔═╡ 67779e52-5c96-445b-b676-f20cd035c66c
md"""
## 6. A common result vocabulary

TensorKitchen uses the same basic questions across decomposition families:

- What compact coordinates were learned? `weights`, `factors`, `core`, `blocks`;
- What tensor do they represent? `reconstruct(result)`;
- How well does it fit? `rel_error(A, result)`;
- How did optimization behave? `iterations`, `converged`, `solver_info`.

### Which model should I try first?

- Use **CP** when a common collection of components should explain every mode.
- Use **Tucker** when modes need different compression levels or interacting
  latent coordinates.
- Use **BTD** when the tensor is plausibly a sum of multilinear-rank blocks.
- Use **NNCPD** when additive, nonnegative parts are part of the scientific
  meaning of the data.

Small reconstruction error alone does not prove that a model's coordinates are
unique, stable, or interpretable. The following labs focus on those questions.
"""

# ╔═╡ a1100007-b6eb-4a94-accc-57fe5f243f9d
@bind run_comparison manual_run_button("▶ Compare the four models")

# ╔═╡ a78d3578-21da-4bbb-b9c4-8b00b9ee3cb0
if manual_run_requested(run_comparison)
begin
    final_reconstructions = (
        Tucker = reconstruct(tucker_result),
        CP = reconstruct(cp_result),
        BTD = reconstruct(btd_result),
        NNCP = reconstruct(nncp_result),
    )
    final_errors = (
        Tucker = tucker_summary.relative_error,
        CP = cp_summary.relative_error,
        BTD = btd_summary.relative_error,
        NNCP = nncp_summary.relative_error,
    )
    final_fingerprints = (
        Tucker = [
            "multilinear rank: $(size(core(tucker_result)))",
            "core size: $(size(core(tucker_result)))",
            "factor matrices: $(length(factors(tucker_result)))",
            "relative error: $(round(tucker_summary.relative_error; sigdigits = 4))",
        ],
        CP = [
            "rank: $(length(weights(cp_result)))",
            "components: $(length(components(cp_result)))",
            "weights: [$(join(round.(weights(cp_result); sigdigits = 3), ", "))]",
            "relative error: $(round(cp_summary.relative_error; sigdigits = 4))",
        ],
        BTD = [
            "blocks: $(length(blocks(btd_result)))",
            "block rank: $(size(core(blocks(btd_result)[1])))",
            "core per block: $(size(core(blocks(btd_result)[1])))",
            "relative error: $(round(btd_summary.relative_error; sigdigits = 4))",
        ],
        NNCP = [
            "rank: $(length(weights(nncp_result)))",
            "components: $(length(components(nncp_result)))",
            "minimum weight ≥ 0: $(nncp_summary.minimum_weight >= -1e-12)",
            "minimum factor entry ≥ 0: $(nncp_summary.minimum_factor_entry >= -1e-12)",
            "relative error: $(round(nncp_summary.relative_error; sigdigits = 4))",
        ],
    )
    cp_factor_entries = reduce(vcat, vec.(factors(cp_result)))
    nncp_factor_entries = reduce(vcat, vec.(factors(nncp_result)))

    tensor_reconstruction_gallery(
        running_tensor,
        final_reconstructions;
        errors = final_errors,
        fingerprints = final_fingerprints,
        cp_factor_entries = cp_factor_entries,
        nncp_factor_entries = nncp_factor_entries,
    )
end
else
    manual_waiting("Run the decomposition examples above, then compare the four models")
end

# ╔═╡ 8db268b8-9c16-47de-b6c6-1b02eb7dca17
md"""
## Try it yourself

Use the results immediately above, answer one problem at a time, and open
**Check answer** only after self-check.
"""

# ╔═╡ 893a5017-036a-45ae-8cb6-7149cdbdaaa1
render_exercise(exercise_by_number(1))

# ╔═╡ e1c418f3-cb70-4180-ad88-7d5e9eb79051
render_exercise(exercise_by_number(2))

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
# ╟─27f7d3a6-27cf-4d5b-baf9-3595a2668b55
# ╟─43ec4b97-7a5a-4af0-b2c5-192a75aa73d2
# ╟─023c6ad4-7eb3-451a-abd5-4dc6cdf78779
# ╟─a1100001-0b9f-4ae5-91d6-418125e04dd0
# ╟─f83b831d-c09e-45ee-808b-d849239d0e80
# ╟─3a7ec1c2-4f18-4bfa-b9d0-253f22fc9911
# ╟─51d78d0a-82d7-4443-820f-a31ac7b1e393
# ╟─38859d3f-319c-4801-bf1e-38eb600842cb
# ╟─a1100002-e82a-42eb-bf89-d4f9d2a7f71a
# ╟─c5f88082-954d-4530-9d59-d82fe6beb6a5
# ╟─ec814a15-3e3d-4daa-a73f-d4eaa1048d1e
# ╟─c2100001-83e0-4c67-8078-f6633fc9e738
# ╟─a1100003-2c62-49f7-89fd-08fa2d451221
# ╟─f41e625e-33eb-48f9-b07d-39c884fbc4e3
# ╟─49500a20-fe0e-4315-8e06-f1e3a6d3c112
# ╟─c2100002-e79e-43bf-b54b-f5e49456c203
# ╟─a1100004-b187-4360-89ac-f8f057960da5
# ╟─3073e49c-2591-4f93-a374-f6ae3eb8bb97
# ╟─f7cc1f80-96ce-4459-bb98-93d4dff147ea
# ╟─c2100003-206d-46a2-8b10-9d647c94bcd9
# ╟─a1100005-bc96-4f6a-b333-fdf576afdd17
# ╟─5e5c00e0-4cbc-4e7b-929e-ac7b1ed62029
# ╟─81f4cdfd-2da2-4dc1-b3ab-9033ef8be0e4
# ╟─a1100006-1765-471f-9a70-d9c0968cd75c
# ╟─d1ae1c80-69fc-49b5-993c-a53d87b732b8
# ╟─67779e52-5c96-445b-b676-f20cd035c66c
# ╟─a1100007-b6eb-4a94-accc-57fe5f243f9d
# ╟─a78d3578-21da-4bbb-b9c4-8b00b9ee3cb0
# ╟─8db268b8-9c16-47de-b6c6-1b02eb7dca17
# ╟─893a5017-036a-45ae-8cb6-7149cdbdaaa1
# ╟─e1c418f3-cb70-4180-ad88-7d5e9eb79051
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
