### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ b7a8dd66-e771-4f60-b42a-5c77e27cff01
begin
    using LinearAlgebra
    using Statistics
    include(joinpath(@__DIR__, "Lab4ConceptData.jl"))
    using .Lab4ConceptData
    include(joinpath(@__DIR__, "Lab4ConceptVisuals.jl"))
    using .Lab4ConceptVisuals
    include(joinpath(@__DIR__, "ExerciseContent.jl"))
    using .ExerciseContent
end

# ╔═╡ 3a63a896-13d1-460b-9181-3832822b1a02
md"""
# Lab 4 Low Rank Neural Representations

## Before we start

**Concept discovery** looks for recurring structure in neural activations that
may correspond to human-interpretable patterns. The resulting factors are
candidate concepts, not automatically validated meanings. *(Ghorbani et al.,
2019; Fel et al., 2023)*

**Dictionary learning** represents data using a small collection of learned
directions and coefficients describing how strongly each direction is used.
*(Mairal et al., 2009)*

**Nonnegative matrix factorization (NMF)** is a constrained dictionary-learning
model,

```math
A \approx UW^\top,\qquad U,W\ge0,
```

that represents each observation as an additive mixture of nonnegative
components. *(Lee & Seung, 1999)*

CRAFT applies this idea to neural activations: the columns of ``W`` become
candidate Concept Activation Vectors, while ``U`` records how strongly each
image crop uses them. *(Fel et al., 2023)*

## What does concept discovery actually claim?

A neural layer converts an input into an activation pattern. If many image
crops produce related patterns, we may hypothesize that the network is
responding to recurring internal features. In this lab, we follow the CRAFT
pipeline from those activations to a concept hypothesis:

CRAFT starts from image patches,
extracts layer activations ``A``, 
factorizes them with NMF ``A \approx UW^\top``, 
interprets the resulting directions as candidate concepts, 
and then evaluates their importance and validity.

Each crop becomes one row of the activation matrix ``A``. Nonnegative matrix
factorization then searches for activation directions ``W_1,\ldots,W_r`` such
that each crop activation can be approximately reconstructed as a nonnegative
mixture:

```math
A_{i,:}\approx \sum_{j=1}^r U_{ij}W_{:,j}^\top.
```

In this interpretation, ``W_{:,j}`` is a **candidate concept activation
vector**, and ``U_{ij}`` says how strongly crop ``i`` uses it. The factorization
does not name the concept. We propose a label by inspecting high-coefficient
crops, then test whether that proposal is stable and connected to model
behavior.

!!! info "A controlled concept laboratory"
    The patches, activations, and classifier below are synthetic. This lets us
    know the planted visual ingredients and isolate each idea without loading a
    neural network or image dataset. The main NMF experiments nevertheless
    start from reproducible random nonnegative factors. The planted factors are
    not used to initialize, reorder, or name the learned candidates. Ground
    truth appears only in a separately labeled, optional oracle comparison.
"""

# ╔═╡ d0d7bb20-e6ff-488f-b2c8-3db81184c503
begin
    concept_data = synthetic_concept_data()
    nmf_history = nmf_trace(concept_data.activations, 3)
    nmf_fit = last(nmf_history)
    rank_results = rank_sweep(concept_data)
    svd_fit = svd_representation(concept_data.activations, 3)
    importance_crop = 5
    importance_coefficients = vec(nmf_fit.U[importance_crop, :])
    importance_proxy = concept_importance_proxy(importance_coefficients)
end

# ╔═╡ dc602b33-c998-4d67-8639-4989553a1004
md"""
## 4A. Image patch becomes one row of ``A``

CRAFT first makes image crops and sends each crop through a chosen neural
layer. For a convolutional layer, spatial activations can be pooled into one
feature vector per crop. Stacking those vectors gives

```math
A\in\mathbb R_{\ge0}^{n\times p},
```

where ``n`` is the number of crops and ``p`` the number of activation features.
Click a patch and follow it through the layer. The corresponding row of ``A``
is highlighted on the right.

**Guiding question:** What does one row of ``A`` represent?
"""

# ╔═╡ 278114dc-87f7-451e-b97c-ed4f6c658605
activation_matrix_visual(concept_data)

# ╔═╡ 93e66fda-34be-4997-bfc8-9a1d53813d06
md"""
## 4B. NMF microscope: the meanings of ``U`` and ``W``

CRAFT factorizes the crop activation matrix as

```math
A\approx UW^\top,\qquad U\ge0,\;W\ge0.
```

The matrix shapes carry the interpretation:

- ``A\in\mathbb R^{n\times p}``: crop × activation feature;
- ``U\in\mathbb R_{\ge0}^{n\times r}``: crop × candidate concept usage;
- ``W\in\mathbb R_{\ge0}^{p\times r}``: activation-feature directions, whose
  columns are candidate Concept Activation Vectors (CAVs).

Choose a crop, then scrub through multiplicative NMF updates. The three
weighted directions add to a reconstruction of that crop's activation.
Early iterations show a poor recipe; later iterations fit the activation more
closely. Candidate 1, 2, and 3 are only algorithmic identifiers: the run begins
from a fixed random initialization and is not aligned to the planted factors.
"""

# ╔═╡ c8b1b17e-8c6e-4a5e-929c-a2f9c0368c07
nmf_microscope_visual(concept_data, nmf_history)

# ╔═╡ 5e84951c-9aa9-4685-a135-f13a264a7108
md"""
## 4C. Rank changes the candidate factorization

The factorization rank ``r`` is the number of candidate concepts available to
the explanation. Too few directions may force distinct patterns into one
factor; extra directions may split a pattern or create near-duplicates. Those
are hypotheses to investigate from ``W`` and high-usage crops—not semantic
labels produced by NMF.

Move the slider from ``r=1`` to ``r=5``. For each anonymous candidate, inspect
its learned activation profile and three highest-usage crops, then write your
own tentative label. Only at ``r=3`` can you optionally reveal a synthetic
oracle comparison. That panel evaluates the finished fit; it does not alter the
initialization, optimization, ordering, or learner labels.

```math
\text{smaller reconstruction error}\;\not\Rightarrow\;
\text{clearer semantic interpretation}.
```

```math
\text{factorization output}\neq\text{semantic label}
```
"""

# ╔═╡ 489c77c0-1aa5-4bd3-b8ff-f5246f466409
rank_candidate_visual(concept_data, rank_results)

# ╔═╡ e9d79484-bbf8-480f-8971-20a97ef1760a
md"""
## 4D. Concept explorer: connect directions to examples

A column of ``W`` is a vector in activation space. It is not yet a
human-readable idea. To form a semantic hypothesis, inspect crops with large
``U_{ij}``: those are the examples that use candidate concept ``j`` most
strongly.

Select a candidate concept. Read the three panels together:

1. the CAV shows its activation direction;
2. top crops provide evidence for a possible human label;
3. the selected crop's row of ``U`` shows its mixture of candidates.

Then click different crops in the composition panel. A plausible label should
explain a coherent family of high-usage examples, not one attractive image.
Enter that label in **Your label hypothesis**: it is deliberately stored as a
learner interpretation, not displayed as an NMF result.
"""

# ╔═╡ 9a6b2f64-55cf-491f-9d57-a29dd0f3c20b
concept_explorer_visual(concept_data, nmf_fit)

# ╔═╡ 257492fb-150c-4289-98c3-175588f9ce0c
md"""
## 4E. Why use a nonnegative representation?

An SVD coordinate may be positive or negative, so directions can reinforce or
cancel. NMF instead expresses a crop activation as an additive mixture of
nonnegative directions. That can align more naturally with a "parts add up"
reading of nonnegative activations.

Toggle the same crop between its NMF and rank-three SVD coordinates.

!!! warning "Constraint is not a semantic guarantee"
    ``nonnegative`` does not mean ``unique`` or ``meaningful``. NMF may have
    multiple approximate solutions, and the chosen rank, layer, examples, and
    initialization all affect the result. This is the same object-versus-
    coordinates distinction developed in Lab 1.
"""

# ╔═╡ b10f29bc-6e5c-4b5a-ae3e-7261fdd6f30d
nonnegative_comparison_visual(concept_data, nmf_fit, svd_fit)

# ╔═╡ 0eef65e1-6986-4aa9-a9a0-b870dced840e
md"""
## 4F. Presence is not importance

A large coefficient ``U_{ij}`` means candidate ``j`` is strongly present in
crop ``i`` under this factorization. It does **not** say that the model's output
depends strongly on that candidate.

Select a concept and change its strength. In the synthetic classifier, the
candidate with the largest learned coefficient need not be the candidate that
changes the score most. This section uses the learned ``U`` coordinates from
the random-start NMF fit, not the planted usage matrix.

CRAFT estimates concept importance with Sobol sensitivity indices. The useful
intuition is variance-based: repeatedly vary one candidate while the others
also vary, and ask how much of the output variation is attributable to that
candidate. The small sensitivity meters below are a teaching proxy, not the
paper's full estimator.
"""

# ╔═╡ bcf7c841-f160-457b-b770-9e66c966ae0f
concept_importance_visual(importance_coefficients, importance_proxy)

# ╔═╡ 65d0ee5f-80cb-4425-8d53-d957d1277f10
md"""
## 4G. Recursive CRAFT: concept granularity changes by layer

The **R** in CRAFT is *Recursive*. A late layer may amalgamate several visual
ingredients into one class-level candidate. To explain that candidate, CRAFT
can move to an earlier layer and factorize the activations associated with it
again.

Move from layer 10 toward layer 4. The illustration is synthetic, but the
question is real:

```math
\text{Which layer contains the semantic granularity needed for this explanation?}
```
"""

# ╔═╡ 2c946a40-6dfc-4b80-a4f7-40ef2c73b711
recursive_craft_visual()

# ╔═╡ ba41c265-2497-45a1-93f1-32a7d426f812
md"""
## 4H. Beyond matrix CRAFT, retain location as a mode?

The CRAFT NMF stage pools a crop into a matrix row. CRAFT later provides
spatial evidence through Concept Attribution Maps, so it would be incorrect to
say that the full method ignores *where*. But TensorKitchen can ask a distinct
structural question:

> What if location were retained as a factorization mode instead of pooled
> before concept factorization?

Compare the assumptions in the toggle:

- matrix NMF: a candidate is an activation direction;
- NNCPD: a candidate is a separable sample × location × feature pattern;
- hypothetical nonnegative BTD-style model: a candidate may contain a small
  location × feature block.

The tensor models preserve more mode semantics, but they impose stronger and
different assumptions. They are not automatically more interpretable.

The third choice is a **conceptual nonnegative block-term extension**, not a
decomposition implemented by TensorKitchen v0.2.0. The pinned release provides
BTD and NNCPD as separate model families, but not a nonnegative BTD solver.
"""

# ╔═╡ 7ccd77d9-1c16-4907-bbdb-bdfc77a6a713
matrix_tensor_extension_visual()

# ╔═╡ 6822f203-6fce-41cb-827b-ee309fdb0f14
md"""
## Evidence ladder: from a factor to a defensible concept claim

Move one rung at a time:

```text
factor found
    ↓
high-usage examples support a coherent label
    ↓
the factor and examples are stable across ranks / runs / nearby layers
    ↓
perturbation or sensitivity connects the candidate to model behavior
    ↓
held-out or interventional evidence supports the claim
```

Reconstruction is necessary evidence that the factorization represents the
activations. It is not sufficient evidence for semantics, stability, or causal
importance.

```math
\textbf{A neural concept is not a factor vector alone: it is a
hypothesis linking activations, examples, and behavior.}
```

!!! note "CRAFT and this lab"
    Sections 4A–4G teach the matrix-NMF, example inspection, sensitivity, and
    recursive-layer ideas motivated by Fel et al., *CRAFT* (CVPR 2023).
    Section 4H is explicitly a TensorKitchen extension question, not part of
    CRAFT.
"""

# ╔═╡ e179f261-fd4d-4889-b6bb-124665a6ae15
md"""
## Exercise: audit one candidate concept

Use the rank and concept controls above.

1. Before revealing the oracle, at which rank do the top crops support the most
   coherent label hypotheses? What happens when rank is too small or too large?
2. Choose one candidate concept. Use its CAV, top crops, and two selected-crop
   compositions to propose a label.
3. Reveal the synthetic oracle only after writing your labels. Which candidate
   matches your hypothesis, and where does your interpretation differ?
4. Is the most present candidate also the most behaviorally important in the
   perturbation experiment? Cite the score change.
5. List one stability check and one behavioral check you would require before
   reporting the label as a neural concept.
6. In one sentence, explain why the tensor extension is inspired by CRAFT but
   is not CRAFT itself.
"""

# ╔═╡ 4109130a-0d03-447c-bb5c-ec79e5292116
render_exercise(exercise_by_number(6))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "4dc6a6a8c66e115ed88539b1663045a960c3b602"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"
"""

# ╔═╡ Cell order:
# ╟─b7a8dd66-e771-4f60-b42a-5c77e27cff01
# ╟─3a63a896-13d1-460b-9181-3832822b1a02
# ╟─d0d7bb20-e6ff-488f-b2c8-3db81184c503
# ╟─dc602b33-c998-4d67-8639-4989553a1004
# ╟─278114dc-87f7-451e-b97c-ed4f6c658605
# ╟─93e66fda-34be-4997-bfc8-9a1d53813d06
# ╟─c8b1b17e-8c6e-4a5e-929c-a2f9c0368c07
# ╟─5e84951c-9aa9-4685-a135-f13a264a7108
# ╟─489c77c0-1aa5-4bd3-b8ff-f5246f466409
# ╟─e9d79484-bbf8-480f-8971-20a97ef1760a
# ╟─9a6b2f64-55cf-491f-9d57-a29dd0f3c20b
# ╟─257492fb-150c-4289-98c3-175588f9ce0c
# ╟─b10f29bc-6e5c-4b5a-ae3e-7261fdd6f30d
# ╟─0eef65e1-6986-4aa9-a9a0-b870dced840e
# ╟─bcf7c841-f160-457b-b770-9e66c966ae0f
# ╟─65d0ee5f-80cb-4425-8d53-d957d1277f10
# ╟─2c946a40-6dfc-4b80-a4f7-40ef2c73b711
# ╟─ba41c265-2497-45a1-93f1-32a7d426f812
# ╟─7ccd77d9-1c16-4907-bbdb-bdfc77a6a713
# ╟─6822f203-6fce-41cb-827b-ee309fdb0f14
# ╟─e179f261-fd4d-4889-b6bb-124665a6ae15
# ╟─4109130a-0d03-447c-bb5c-ec79e5292116
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
