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

- Use the running tensor to establish order, dimensions, and modes.
- Contrast CP rank-one summands with Tucker mode subspaces and a core.
- End by asking why a low reconstruction error does not imply unique or meaningful factors.

### Lab 1 - 20 minutes

- Use the matrix gauge slider before showing the formula.
- Ask learners to identify the unchanged matrix and the changing factor norms/conditioning.
- Use CP rescaling and permutation to transfer the idea from matrices to tensors.
- Treat the geometry race as one controlled comparison, not a universal benchmark.

### Lab 2 - 15 to 20 minutes

- Use the geometry bridge to distinguish a Stiefel frame `U`, its subspace
  `span(U)`, and the fixed-rank matrix `W = USVᵀ`.
- Ask why `UQ` is a different frame but the same subspace, and why transformed
  `U,S,V` coordinates can still represent the same `W`.
- Map StelLA to learned Stiefel frames/subspaces, RAdaGrad/RAdamW to intrinsic
  fixed-rank weights, and TDN to CP-structured tensor-product operators. State
  that these are paper bridges, not method replications.
- Ask which model most directly represents a sum of Tucker blocks before running a fit.
- Use the model cards to separate component assumptions from solver success.
- Require one sentence beginning: “This component is interpretable only if ...”

### Lab 3 - 25 minutes

- Move the collision control slowly and connect rank-one overlap to the two-column Gram example.
- Explain that the small eigenvalue corresponds to difficulty separating two nearly identical components.
- In the solver race, point out the shared target, start, tolerance, and budget.
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
