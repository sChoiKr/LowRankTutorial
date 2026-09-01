# Teaching notes

## Instructor framing

Open with one sentence: low-rank decomposition can produce candidate structure, but the course is about deciding what that structure warrants us to claim. Keep the distinction between **object-level evidence** and **coordinate-level evidence** visible throughout the session.

The intended progression is documented in [`../CURRICULUM.md`](../CURRICULUM.md). The short form is:

> Representation -> Equivalence -> Model assumption -> Optimization stability -> Interpretation -> Auditability

## Before class

1. Start Julia with `julia --project=.` and confirm `using TensorKitchen` succeeds.
2. Open each notebook once in Pluto so compilation does not interrupt the live explanation.
3. Keep code folded. Reveal experiments individually after learners make a prediction.
4. Confirm the interactive deck export and the two exercise PDFs open locally.

## Facilitation pattern

Use the same four prompts for every experiment:

1. **Predict:** What should change, and what should remain invariant?
2. **Observe:** Which visual or diagnostic tests that prediction?
3. **Explain:** Is the result about the represented object, its coordinates, the model family, or the optimizer?
4. **Limit the claim:** Which rung of the evidence ladder has been reached, and what evidence is still missing?

## Suggested core route

### Primer - 10 to 15 minutes

- Begin with the activation-tensor flattening toggle: the entry count is
  unchanged, but sample and token cease to be separate axes.
- Use mode products only as optional tensor mechanics if the group needs them.
- Contrast CP rank-one summands with Tucker mode subspaces and a core.
- End by asking why a low reconstruction error does not imply unique or meaningful factors.

### Lab 1 - 20 minutes

- Use the matrix gauge slider before showing the formula.
- Ask learners to identify the unchanged matrix and the changing factor norms/conditioning.
- Use CP rescaling and permutation to transfer the idea from matrices to tensors.
- Treat the normalized-versus-intrinsic representation race as an optional
  advanced comparison, not a universal benchmark. Mention TensorKitchen's
  `:canonical`/`:native` names only after the learner-facing distinction is clear.

### Lab 2 - 15 to 20 minutes

- Use the geometry bridge to distinguish a basis/frame, its spanned subspace,
  and the reconstructed low-rank matrix `W = USVᵀ`.
- Keep the formal Stiefel/fixed-rank definitions and coordinate gauges inside
  Optional math unless the audience already knows manifold terminology.
- Map StelLA to learned Stiefel frames/subspaces, RAdaGrad/RAdamW to intrinsic
  fixed-rank weights, and TDN to CP-structured tensor-product operators. State
  that these are paper bridges, not method replications.
- Ask which model most directly represents a sum of Tucker blocks before running
  a fit. Treat the exact CP-rank-four proof as an optional challenge; the core
  only needs “four terms suffice” and “two terms cannot suffice.”
- Use the model cards to separate component assumptions from solver success.
- Require one sentence beginning: “This component is interpretable only if ...”

### Lab 3 - 25 minutes

- Move the collision control slowly and repeat the central chain: component
  similarity rises, collision distance falls, and ALS conditioning rises.
- Ask in plain language why ALS cannot decide which near-copy contributed what.
  Open the Gram/eigenvalue derivation only as Optional math.
- Use ALS versus RCG as the core solver race, with shared target, start,
  tolerance, and budget. Put regularized ALS and RGD under Explore more.
- Scrub the ALS trace and let learners identify the plateau from diagnostics before showing the heuristic label.

### Lab 4 - 20 to 25 minutes

- Ask learners to click one crop and state exactly what one row of `A` means.
- Scrub NMF iterations and have learners distinguish the crop recipe `U[i,:]` from the candidate directions `W[:,j]`.
- Move rank below and above three; reconstruction error is not the only criterion for a coherent concept vocabulary.
- In the concept explorer, require a label justified by several high-usage crops rather than by the CAV alone.
- Perturb a large-but-weak and a smaller-but-influential coefficient to establish presence ≠ importance.
- Mark the matrix/tensor toggle boundary aloud: the tensor model is inspired by CRAFT, not an implementation of CRAFT.
- End with one stability test and one behavioral or intervention test.

## Assessment

The printable student sheet is in `exercises/`; the short answer key is packaged with instructor materials.
