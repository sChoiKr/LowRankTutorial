# Low-Rank Structure Is Geometry

Interactive Pluto teaching materials for learning how representation,
coordinate equivalence, model assumptions, optimization stability, and
behavioral validation constrain low-rank interpretation.

This repository is the submission-facing educational resource. Development
sources, temporary browser profiles, and intermediate build output are not
included.

## What is included

- `notebooks/`: the numbered, executable learner sequence;
- `html/`: browser-readable exports for reviewers without Julia;
- `appendix/`: searchable Pluto glossary, printable source, HTML, and PDF;
- `slides/`: the interactive introductory deck and standalone HTML;
- `exercises/`: student worksheet in Markdown, HTML, and PDF;
- `instructor/`: teaching notes, guide, and answer key;
- `scripts/`: source-to-HTML/PDF rebuild and release commands;
- `test/`: lightweight checks for the shared data and public wiring;
- `CURRICULUM.md`: pedagogical rationale and alignment boundary;
- `REFERENCES.md`: mathematical, software, and AI source map.

## Quick start

- Julia 1.12.6 recommended (Julia 1.12 is required by `Project.toml`)
- TensorKitchen 0.2.0, pinned to its public GitHub tag in the manifests
- Pluto 1.0.3 in a separate tool environment

Instantiate the tutorial environment from the repository root:

```sh
julia --project=. -e 'import Pkg; Pkg.instantiate()'
```

Install Pluto once in its own environment. It is kept separate because the
currently pinned TensorKitchen and Pluto dependency sets cannot be resolved in
one Julia project:

```sh
julia --project=@pluto -e 'import Pkg; Pkg.add(Pkg.PackageSpec(name="Pluto", version="1.0.3"))'
```

Open the primer:

```sh
julia --project=@pluto -e 'using Pluto; Pluto.run(notebook=abspath("notebooks", "00_Primer.jl"))'
```

## Guided sequence

| Order | Interactive notebook | Browser-readable export | Main question |
| ---: | --- | --- | --- |
| 0 | [`00_Primer.jl`](notebooks/00_Primer.jl) | [`00_Primer.html`](html/00_Primer.html) | What object and decomposition vocabulary are being used? |
| 1 | [`01_OneObjectManyCoordinates.jl`](notebooks/01_OneObjectManyCoordinates.jl) | [`01_OneObjectManyCoordinates.html`](html/01_OneObjectManyCoordinates.html) | Which coordinates represent the same object? |
| 2 | [`02_GeometryAtlas.jl`](notebooks/02_GeometryAtlas.jl) | [`02_GeometryAtlas.html`](html/02_GeometryAtlas.html) | What assumptions do CP, Tucker, and BTD make? |
| 3 | [`03_OptimizationFailureMuseum.jl`](notebooks/03_OptimizationFailureMuseum.jl) | [`03_OptimizationFailureMuseum.html`](html/03_OptimizationFailureMuseum.html) | What causes a plateau, and what evidence distinguishes collision? |
| 4 | [`04_NeuralRepresentations.jl`](notebooks/04_NeuralRepresentations.jl) | [`04_NeuralRepresentations.html`](html/04_NeuralRepresentations.html) | How does a factor become a testable concept hypothesis? |
| 5 | [`05_ExerciseSheet.jl`](notebooks/05_ExerciseSheet.jl) | — | Can learners apply the distinctions? |

The optional [`GlossaryAppendix.jl`](appendix/GlossaryAppendix.jl) provides
searchable mathematical and AI/interpretability definitions. A static
[`GlossaryAppendix.html`](appendix/GlossaryAppendix.html) and printable
[`GlossaryAppendix.pdf`](appendix/GlossaryAppendix.pdf) are included for
reviewers and learners who do not use Pluto. Terms, topic clusters, selective
interpretation notes, and citation keys share
[`GlossaryContent.jl`](appendix/GlossaryContent.jl) as their source of truth.

The conceptual progression is:

> **Representation → Equivalence → Model assumption → Optimization stability → Interpretation → Auditability**

## Student and instructor materials

The interactive presentation is `slides/TensorKitchen_Interactive_Intro_Deck.jl`;
its standalone version is `slides/TensorKitchen_Interactive_Intro_Deck.html`.
Printable student materials are isolated in `exercises/`. Teaching notes and
all answers are in `instructor/`.

## Reproducible release ZIP

Run the repository checks:

```sh
julia --project=. test/runtests.jl
```

Rebuild all notebook HTML, slides, exercise files, glossary files, tests, and
the release ZIP:

```sh
julia scripts/rebuild_all.jl
```

The PDF fallback needs a Chromium-based browser. If no TeX engine is present,
glossary PDF generation also needs Python with `pypdf`; set
`TENSORKITCHEN_PYTHON` if necessary.

To package the files without regenerating the teaching artifacts:

```sh
julia scripts/build_release.jl
```

The command writes `dist/LowRankStructureIsGeometry.zip`. The `dist/` directory
is ignored by Git and is intended for a GitHub Release asset, not source
control.

## Scope boundary

This resource does not present tensor decomposition as an alignment algorithm.
It teaches what reconstruction, invariance, conditioning, stability, and
behavioral evidence can—and cannot—support. See `CURRICULUM.md`.

## License and citation

Citation metadata is provided in `CITATION.cff`. The current `LICENSE` is an
all-rights-reserved notice pending a contributor-approved public license.
