# Glossary Appendix

**Paul Breiding · Se Eun Choi**

The optional glossary companion is generated from one content schema:

- `GlossaryContent.jl` — source of truth for terms, clusters, notes, and citation keys;
- `GlossaryAppendix.jl` — interactive Pluto glossary with search and domain filters;
- `GlossaryAppendix.tex` — generated printable source. Do not edit directly.

Suggested repository location:

```text
appendix/
├── GlossaryContent.jl
├── GlossaryAppendix.tex
└── GlossaryAppendix.jl
```

## Build integration

From the repository root:

```sh
julia --project=@pluto scripts/export_notebooks.jl Glossary
julia --project=. scripts/generate_glossary_latex.jl
julia --project=. scripts/build_glossary_appendix.jl
```

The first command writes `appendix/GlossaryAppendix.html`. The
second regenerates LaTeX from the shared schema. The third writes
`appendix/GlossaryAppendix.pdf`, preferring the LaTeX source
when a TeX engine is installed and otherwise printing the complete static
Pluto glossary. The browser fallback also needs Python with `pypdf` to remove
Pluto's empty loader page; set `TENSORKITCHEN_PYTHON` if that package is not in
the default Python environment. `scripts/build_release.jl` runs the PDF step automatically and
packages the `.jl`, `.tex`, `.html`, and `.pdf` versions together.

The glossary deliberately separates mathematical terminology from AI /
interpretability terminology, while adding cross-links between the two.

The main notebooks should still define unfamiliar terms locally in one sentence.
This appendix is for deeper optional study.
