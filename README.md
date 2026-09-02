# Low-Rank Structure Is Geometry

Interactive Pluto teaching materials for learning how representation, coordinate equivalence, model assumptions, optimization stability, and behavioral validation constrain low-rank interpretation.

## What is included

- `notebooks/`: the numbered, executable learner sequence;
- `html/`: browser-readable exports for reviewers without Julia;
- `appendix/`: searchable Pluto glossary source and PDF;
- `slides/`: the interactive introductory deck and standalone HTML;
- `exercises/`: student worksheet in Markdown, HTML, and PDF;
- `instructor/`: teaching notes and answer key;
- `scripts/`: source-to-HTML/PDF rebuild and release commands;
- `deploy/Dockerfile`: isolated PlutoSliderServer deployment;
- `test/`: lightweight checks for the shared data and public wiring;
- `CURRICULUM.md`: pedagogical rationale and alignment boundary;
- `REFERENCES.md`: mathematical, software, and AI source map.

## Start here: interactive intro deck

**Every learner should begin with the interactive intro deck before opening Lab 0.** It establishes the general concept of low-rank factorization like tensor methods and why low-rank structure matters in modern AI, introduces the geometric objects used throughout the tutorial, and gives a visual map for the numbered labs.

- Open the no-install browser version:
  [`TensorKitchen_Interactive_Intro_Deck.html`](slides/TensorKitchen_Interactive_Intro_Deck.html)
- The corresponding Pluto source is
  [`TensorKitchen_Interactive_Intro_Deck.jl`](slides/TensorKitchen_Interactive_Intro_Deck.jl).

After the deck, continue with `00_Primer.jl` and follow the guided sequence in order.

## Quick start

- Julia 1.12.6 recommended (Julia 1.12 is required by `Project.toml`)
- TensorKitchen 0.2.0, pinned to its public GitHub tag in the manifests
- Pluto 1.0.3 in a separate tool environment

Instantiate the tutorial environment from the repository root:

```sh
julia --project=. -e 'import Pkg; Pkg.instantiate()'
```

Instantiate the separate Pluto tool environment as well. Keeping it separate
prevents Pluto from re-resolving TensorKitchen's pinned numerical dependencies.

```sh
julia --project=tools -e 'import Pkg; Pkg.instantiate()'
```

After viewing the intro deck, open the primer:

```sh
julia --project=tools -e 'using Pluto; Pluto.run(notebook=abspath("notebooks", "00_Primer.jl"))'
```

## Static and live entry points

- **Static review:** open the committed files in `html/` and `slides/`. They
  need no Julia installation; notebook exports clearly mark that new Julia
  computations are unavailable in this tier.
- **Live Julia-backed tutorial:** after instantiating both environments, run
  `julia --project=tools scripts/run_live_server.jl` and open
  `http://127.0.0.1:8080`.
- **Local editable Pluto:** use the primer command above when teaching from
  the notebook source.

Public live hosting must run the included [`deploy/Dockerfile`](deploy/Dockerfile) inside an isolated, resource-limited environment.

## Guided sequence

| Order | Interactive notebook | Browser-readable export | Main question |
| ---: | --- | --- | --- |
| **Start** | [`Interactive intro deck`](slides/TensorKitchen_Interactive_Intro_Deck.jl) | [`Open deck`](slides/TensorKitchen_Interactive_Intro_Deck.html) | Why does low-rank geometry matter in modern AI, and what objects will the tutorial study? |
| 0 | [`00_Primer.jl`](notebooks/00_Primer.jl) | [`00_Primer.html`](html/00_Primer.html) | What object and decomposition vocabulary are being used? |
| 1 | [`01_OneObjectManyCoordinates.jl`](notebooks/01_OneObjectManyCoordinates.jl) | [`01_OneObjectManyCoordinates.html`](html/01_OneObjectManyCoordinates.html) | Which coordinates represent the same object? |
| 2 | [`02_GeometryAtlas.jl`](notebooks/02_GeometryAtlas.jl) | [`02_GeometryAtlas.html`](html/02_GeometryAtlas.html) | How do Stiefel, fixed-rank, Segre, and Tucker objects connect to current AI uses? |
| 3 | [`03_OptimizationFailureMuseum.jl`](notebooks/03_OptimizationFailureMuseum.jl) | [`03_OptimizationFailureMuseum.html`](html/03_OptimizationFailureMuseum.html) | What causes a plateau, and what evidence distinguishes collision? |
| 4 | [`04_NeuralRepresentations.jl`](notebooks/04_NeuralRepresentations.jl) | [`04_NeuralRepresentations.html`](html/04_NeuralRepresentations.html) | How does a factor become a testable concept hypothesis? |
| 5 | [`05_ExerciseSheet.jl`](notebooks/05_ExerciseSheet.jl) | [`05_ExerciseSheet.html`](html/05_ExerciseSheet.html) | Can learners apply the distinctions? |

The optional [`GlossaryAppendix.jl`](appendix/GlossaryAppendix.jl) provides mathematical and AI/interpretability definitions grouped by topic; browser Find works in both Pluto and the static export. A generated site export, [`GlossaryAppendix.html`](html/GlossaryAppendix.html), and printable [`GlossaryAppendix.pdf`](appendix/GlossaryAppendix.pdf) are included for reviewers and learners who do not use Pluto. Terms, topic clusters, selective interpretation notes, and citation keys share [`GlossaryContent.jl`](appendix/GlossaryContent.jl) as their source of truth.

The conceptual progression is:

> **Representation → Equivalence → Model assumption → Optimization stability → Interpretation → Auditability**

## Student and instructor materials

The interactive presentation is `slides/TensorKitchen_Interactive_Intro_Deck.jl`; its standalone version is `slides/TensorKitchen_Interactive_Intro_Deck.html`. Printable student materials are isolated in `exercises/`. Teaching notes and all answers are in `instructor/`.

## Reproducible release ZIP

Run the repository checks:

```sh
julia --project=. test/runtests.jl
```

CI rebuilds deterministic/static assets without invoking a browser PDF engine,
then checks the generated text and builds the release ZIP:

```sh
julia scripts/rebuild_all.jl --no-pdf
git diff --exit-code -- . ':(exclude)**/*.html' ':(exclude)**/*.pdf' ':(exclude)dist/**'
julia scripts/build_release.jl
```

PDF generation is deliberately separate from the ZIP job. To refresh the
committed reviewer PDFs locally, run `julia scripts/rebuild_all.jl` without the
flag after installing a Chromium-based browser.

## Author contributions

Se Eun Choi led the development of the tutorial, including the overall instructional design, implementation of the Pluto notebooks, interactive experiments and visualizations, exercises, glossary, static exports, and repository infrastructure. She also developed the connections to neural representations and interpretability and carried out the numerical experiments used throughout the materials. Paul Breiding contributed the central mathematical perspective and conceptual framing, advised on tensor geometry, manifold optimization, identifiability, and numerical phenomena, and provided mathematical review and iterative feedback on the tutorial structure and examples. Both authors contributed to refining the mathematical narrative and final presentation.

## License and citation

Citation metadata is provided in `CITATION.cff`. The current `LICENSE` is an all-rights-reserved notice pending a contributor-approved public license.
