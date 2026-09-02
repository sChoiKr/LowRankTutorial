# Low-Rank Representation: Geometry, Optimization, and Interpretation

## Scope

This curriculum studies mathematical conditions under which low-rank representations may become useful evidence in interpretability and alignment auditing.

Before interpreting a component, we ask what object was represented, which coordinate changes preserve it, whether the model matches the question, and whether the result is stable and behaviorally supported.

## Audience and prerequisites

- Advanced undergraduates, graduate students, and early-stage AI researchers.
- Required: a solid foundation in linear algebra, including matrix rank, SVD, matrix multiplication, and norms, plus introductory knowledge of gradient descent.
- Not required: differential geometry or prior tensor-decomposition knowledge.


## Learning progression

The learning progression describes what the learner studies:

> **Representation -> Equivalence -> Model assumption -> Optimization stability -> Interpretation -> Auditability**


| Stage                  | Guiding question                                               | Primary resource     | Evidence produced                                                                 |
| ---------------------- | -------------------------------------------------------------- | -------------------- | --------------------------------------------------------------------------------- |
| Representation         | What mathematical object is being approximated?                | Primer               | Flattening tradeoffs, tensor modes, reconstruction maps, and decomposition vocabulary |
| Equivalence            | Which coordinate changes preserve that object?                 | Lab 1                | Matrix gauges and CP rescaling/permutation invariants                             |
| Model assumption       | What geometric object and component structure does the model use? | Lab 2             | Frame/subspace/object bridge plus CP, Tucker, and BTD controlled comparisons       |
| Optimization stability | When does optimization become unreliable, and how can we diagnose why? | Lab 3                | Diagnostics that separate slow optimization from its possible causes |
| Interpretation         | What semantic claim is being made about a component?           | Lab 4                | Explicit links between tensorization, constraints, factors, and proposed concepts |
| Auditability           | What external evidence supports that claim?                    | Lab 4 and assessment | Behavioral tests, held-out tasks, labels, perturbations, or interventions         |


The order is deliberate. Semantic labels are postponed until learners can distinguish an intrinsic object from a coordinate choice, and behavioral claims are postponed until numerical stability has been examined.

The optional glossary appendix supports every stage without becoming a new prerequisite. Learners can search mathematical and AI/interpretability terms, follow their cross-language links, and return to the experiment that introduced the term. Main notebooks still define unfamiliar vocabulary locally in one sentence.

## Evidence levels for interpretability claims

The evidence levels describes how strong an interpretability claim is.
A discovered feature can support different levels of evidence:

1. **Reconstruction:** the low-rank model approximates the selected data object.
2. **Invariance and identifiability:** the claim is formulated in quantities invariant to known coordinate symmetries, and any remaining ambiguity is stated explicitly.
3. **Conditioning:** small perturbations of the data do not cause disproportionately large changes in the recovered decomposition, after known equivalences are accounted for.
4. **Stability:** the finding persists across seeds, data perturbations, reasonable ranks, and solver choices.
5. **Behavioral validation:** the feature is predictively related to model behavior on held-out examples or tasks.
6. **Intervention:** changing the feature produces the predicted behavioral effect while relevant controls are held fixed.

**Good reconstruction alone stops at Step 1.** This is a checklist for stating what kind of evidence an experiment has and has not produced.

# Tutorial design specification

### Primer - specify the representation

The primer begins by contrasting a sample × token × feature tensor with a
flattened matrix containing the same entries. Before decomposition, learners
choose three mode sizes and generate a reproducible random running tensor; its
size, entry count, seed, and slices remain visible so the object in each later
experiment is explicit. It then distinguishes CP, Tucker, BTD, and nonnegative CP.
The central question is simple: *what object has the method reconstructed, and which axes retain independent meaning?* Mode-product dimension arithmetic is optional
tensor mechanics rather than the first core activity.

### Lab 1: One object, many coordinates

This is the conceptual center of the tutorial.

- **1A Matrix gauge.** Vary an invertible matrix `Q` in `X = A*B' = (A*Q)*(B*inv(Q)')'`. Observe reconstruction invariance alongside factor norms and conditioning.
- **1B CP equivalence.** Move reciprocal scales across the vectors in one rank-one tensor, then permute components. Compare tensors rather than raw columns.
- **Optional 1C Parameterization and optimization.** Compare a normalized
  representation with an intrinsic rank-one representation under the same
  target, initialization, solver family, tolerance, and iteration budget.
  TensorKitchen calls them `:canonical` and `:native`; the comparison is a
  controlled experiment, not a universal solver ranking.

### Lab 2: Geometry atlas

Lab 2 begins with a matrix-to-tensor geometry bridge. Learners distinguish a
basis/frame from its spanned subspace, distinguish a low-rank matrix from its
non-unique `USVᵀ` coordinates, and then transfer the same object-versus-
coordinates reasoning to CP rank-one and Tucker objects. Formal Stiefel and
fixed-rank manifold definitions are optional mathematical detail. StelLA,
RAdaGrad/RAdamW, and Tensor Decomposition Networks are explicitly identified as
recent AI examples of these different geometric choices.
These paper connections are conceptual bridges rather than reproductions of
the full methods or their reported empirical results.

The tensor models are then presented using the same five-field card:

| Model | Object | Component | Coordinates | Equivalence | TensorKitchen view |
| --- | --- | --- | --- | --- | --- |
| CP | rank-at-most-R tensor | Segre rank-one tensor | weights and factor vectors | reciprocal scaling and permutation | JoinModel of Segre components |
| Tucker | multilinear rank at most the requested tuple; fixed-rank stratum when every mode rank is attained | one core with mode subspaces | core and mode factors | basis changes absorbed by the core | Tucker geometry |
| BTD | sum of multilinear-rank blocks | Tucker block | block cores and factors | internal Tucker gauges and block permutation | JoinModel of Tucker components |

Assessment evidence inside the notebook asks learners to decide whether a
claim should compare reconstructed matrices, learned subspaces, or raw factor
columns after resolving basis ambiguity.


### Lab 3: Observe stagnation, diagnose its geometry

The main exhibits:

- A failure map separating the observation of a plateau from possible causes
  such as component collision, cancellation, initialization, rank choice,
  scaling, and model mismatch.

- An interactive collision demo showing how two nearly identical components
  become harder for ALS to separate, and how their contributions can shift
  between components even when the reconstructed tensor changes very little.

- A controlled comparison showing that slow optimization does not by itself
  imply component collision.

- A shared-start comparison of ALS and RCG, using reconstruction histories and
  endpoint diagnostics to compare how the two methods behave on the same
  problem. Regularized ALS and RGD are provided as an Explore-more extension.

- An optional cancellation experiment comparing component similarity,
  component magnitude, cancellation, and sensitivity to small perturbations.

### Lab 4: From activations to concepts

We use CRAFT as a concrete example of dictionary-style concept discovery from neural activations. Concept discovery is treated as a hypothesis-and-validation pipeline.

- Click synthetic image crops and identify the corresponding activation-matrix row.
- Inspect `A ≈ UWᵀ` through crop recipes, candidate concept directions, and NMF iteration snapshots.
- Change rank and watch candidate concepts merge, separate, or split.
- Connect each direction to high-usage examples, then separate concept presence from behavioral importance.
- Move across neural layers to study recursive semantic granularity.
- Compare matrix CRAFT with an explicitly labeled tensor-structured extension question.

## Learning outcomes and assessment evidence

After the guided path, learners should be able to:

1. distinguish a low-rank object from its non-unique coordinates, and state which ambiguities must be handled before comparing factors;

2. compare CP, Tucker, and BTD by the structure each model permits and explain how that changes the interpretation of a component;

3. distinguish a frame, its subspace, and the represented low-rank object, then
   transfer that distinction to CP rank-one and Tucker representations;

4. distinguish model mismatch from optimization failure using reconstruction, conditioning, and component-level diagnostics;

5. evaluate an interpretability claim by stating what evidence has been established and what validation should come next.

Learner assessment comes from prediction prompts, direct manipulation, short explanation tasks, the printable exercise sheet, and the Lab 4 concept-audit exercise. Repository tests cover selected numerical invariants, regression cases, and content wiring; they do not validate every solver trajectory or pedagogical claim.

## Suggested teaching paths


| Path                 | Duration   | Use                                                                           |
| -------------------- | ---------- | ----------------------------------------------------------------------------- |
| Visual overview      | 15-20 min  | Interactive deck + one discussion using the evidence levels                   |
| Core workshop        | 90-120 min | Primer plus Labs 1-4, using one central experiment per Lab                    |
| Interpretation focus | 45-60 min  | Lab 1 invariance, Lab 3 collision, and Lab 4 behavioral-validation discussion |
| Full practical       | 2.5-3 h    | All notebook experiments plus the exercise sheet and group debrief            |


For live teaching, focus on one interaction at a time. Ask learners to predict what will change, manipulate the control, identify what remained invariant, and state what the result supports.

## Boundaries instructors should state explicitly

- A decomposition is a modeling tool, not an automatic explanation or alignment method.
- Identifiability and numerical stability are related but distinct.
- A stable factor can still be behaviorally irrelevant; a behaviorally correlated factor can still be non-causal.
- Constraints such as nonnegativity express assumptions and may aid description, but do not certify semantics.
- Solver comparisons are controlled experiments in these notebooks, not universal rankings of algorithms.

See `[README.md](README.md)` for installation and navigation, `[instructor/TeachingNotes.md](instructor/TeachingNotes.md)` for a facilitation script, and `[REFERENCES.md](REFERENCES.md)` for mathematical and AI sources.
