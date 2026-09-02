### A Pluto.jl notebook ###
# v0.20.17

using Markdown
using InteractiveUtils

# ╔═╡ b07350fb-19c1-4d83-9afe-11a59ed56202
md"""
# Glossary Appendix: Low-Rank Structure Is Geometry

**Paul Breiding · Se Eun Choi**

This notebook is an **optional companion** to the main tutorial.

Use it when you encounter a term that is unfamiliar. Mathematical and
AI/interpretability vocabulary are organized into topic clusters, followed by
a cross-language map showing where the two vocabularies meet. Use your
browser's Find command (`Ctrl+F` or `Cmd+F`) to jump directly to a term in both
the Pluto and static HTML versions.

> **Two recurring cautions**
>
> **coordinates ≠ intrinsic object**  
> **learned factor / dictionary atom ≠ validated semantic concept**
"""

# ╔═╡ f13a6a1c-3ed5-4a1a-9b42-3ef264e72703
begin
    include(joinpath(@__DIR__, "GlossaryContent.jl"))
    using .GlossaryContent
    nothing
end

# ╔═╡ 229053c5-e870-47c1-84cb-aa8c244c9507
md"""
## Browse the glossary

Every entry is rendered below so the glossary works identically in Pluto, in
the standalone HTML, and in print. Entries are grouped first by domain and then
by topic cluster.
"""

# ╔═╡ 9b90625c-0509-4143-b224-46c219b47704
function escape_html(s)
    replace(string(s), "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;")
end;

# ╔═╡ 658bce71-f9fd-40e0-b452-b333689583b2
begin
function prose_html(text)
    markdown_text = replace(string(text), r"\$([^$]+)\$" => s"``\1``")
    sprint(show, MIME"text/html"(), Markdown.parse(markdown_text))
end

function glossary_card(entry)
    accent = entry.category == "Mathematics" ? "#3f5f73" : "#6b5d45"
    note = isnothing(entry.note) ? """""" : """
      <details class="glossary-detail note-detail">
        <summary>$(escape_html(entry.note_label))</summary>
        $(prose_html(entry.note))
      </details>
    """
    source_keys = join(["[$(escape_html(key))]" for key in entry.citations], " ")
    sources = isempty(entry.citations) ? """""" : """
      <details class="glossary-detail source-detail">
        <summary>Sources&nbsp; $source_keys</summary>
        <p>Use the reference index below to expand these citation keys.</p>
      </details>
    """
    """
    <article style="
        margin:0 0 16px 0;
        padding:17px 19px;
        border:1px solid rgba(80,80,70,.18);
        border-left:5px solid $accent;
        border-radius:10px;
        background:rgba(250,250,247,.82);
        line-height:1.52;">
      <div style="display:flex;justify-content:space-between;gap:12px;align-items:baseline;flex-wrap:wrap">
        <strong style="font-size:1.12rem;">$(escape_html(entry.term))</strong>
        <span style="font-size:.78rem;letter-spacing:.04em;text-transform:uppercase;color:#666">
          $(escape_html(replace(entry.cluster, r"^[IVX]+\.\s*" => "")))
        </span>
      </div>
      <div class="glossary-summary">$(prose_html(entry.summary))</div>
      $note
      $sources
    </article>
    """
end

function grouped_glossary_html(entries)
    sections = String[]
    for category in ("Mathematics", "AI & Interpretability")
        category_entries = filter(e -> e.category == category, entries)
        isempty(category_entries) && continue
        accent = category == "Mathematics" ? "#3f5f73" : "#6b5d45"
        push!(sections, """
          <header class="domain-heading" style="border-color:$accent">
            <span>$(escape_html(category))</span>
            <small>$(length(category_entries)) terms</small>
          </header>
        """)
        for cluster in CLUSTER_ORDER[category]
            cluster_entries = filter(e -> e.cluster == cluster, category_entries)
            isempty(cluster_entries) && continue
            push!(sections, "<h3 class=\"cluster-heading\">$(escape_html(cluster))</h3>")
            append!(sections, glossary_card.(cluster_entries))
        end
    end
    """
    <div class="glossary-results">
      <style>
        .glossary-results{max-width:900px;margin:0 auto}
        .domain-heading{display:flex;justify-content:space-between;align-items:baseline;margin:34px 0 16px;padding:0 0 9px;border-bottom:3px solid;font-size:1.4rem;font-weight:750}
        .domain-heading small{font-size:.78rem;font-weight:500;color:#6a6a62}
        .cluster-heading{margin:27px 0 12px;font-size:1.05rem;letter-spacing:.015em;color:#494940}
        .glossary-summary>p{margin:10px 0 8px}
        .glossary-detail{margin-top:10px;padding:8px 11px;border-radius:8px;background:rgba(91,97,67,.07)}
        .glossary-detail summary{cursor:pointer;font-weight:700;color:#4c5336}
        .glossary-detail p{margin:8px 0 2px}
        .source-detail{background:transparent;border:1px solid rgba(80,80,70,.13);color:#5f5f58}
      </style>
      $(join(sections))
    </div>
    """
end
nothing
end

# ╔═╡ 272c96b8-cf5a-4f5b-9fc2-bf0b8ed1bc16
begin
    Base.HTML(grouped_glossary_html(GLOSSARY_ENTRIES))
end

# ╔═╡ 26ed4a41-b122-4fc0-a9c3-d35481614e30
md"""
## Cross-language map

A useful way to read the tutorial is to translate a mathematical object into the interpretability claim someone may want to make about it.

| Mathematical language | Interpretability language | Caution |
|:--|:--|:--|
| factor / dictionary atom | candidate feature or concept direction | a direction becomes semantic only after validation |
| coefficient | feature or concept usage | presence is not importance |
| subspace | representation or update subspace | a subspace can be stable even when a particular basis is arbitrary |
| rank | vocabulary capacity / granularity | more rank can split or duplicate concepts |
| conditioning | representation stability | good reconstruction can coexist with fragile coordinates |
| identifiability | recoverability | recoverability is not domain meaning |
| perturbation / intervention | behavioral evidence | interpretation depends on the intervention and controls |

**A mathematically recoverable factor is not automatically a scientifically meaningful concept.**
"""

# ╔═╡ 08035f82-d7ce-4acf-a1cd-f55a9eaaef07
md"""
## Compare representation families

| Method | Learned representation | Main structural assumption | Interpretability caution |
|:--|:--|:--|:--|
| SVD / PCA-style | orthogonal directions / subspace | orthogonality, variance structure | basis directions need not be semantic |
| NMF | nonnegative directions + nonnegative usage | additive nonnegative mixture | nonnegative ≠ unique or meaningful |
| Dictionary learning | reusable atoms + coefficients | learned basis, often sparse coding | atom ≠ concept |
| Sparse autoencoder | decoder features + sparse latent code | nonlinear encoder + sparse feature usage | SAE feature ≠ validated concept |
| CPD | rank-one tensor components | separability across modes | scaling/permutation and stability matter |
| Tucker | mode subspaces + interaction core | low multilinear rank | core coordinates are basis-dependent |
| BTD | multilinear-rank blocks | structured within-component interaction | block semantics require validation |
"""

# ╔═╡ ae106bd3-328b-41fc-a653-ded365331409
md"""
## Sparse autoencoder mini-reference

A sparse autoencoder learns

```math
z=f_{enc}(x),\qquad \hat x=f_{dec}(z),
```

with a reconstruction objective plus a sparsity-inducing term,

```math
\mathcal L
=
\|x-\hat x\|^2
+
\lambda\,\Omega(z).
```

The **encoder** determines which latent features activate. The **decoder** maps those latent coefficients 
back into activation space. Decoder directions are often interpreted as learned features or dictionary atoms.

The important boundary for this tutorial is:

```math
\text{SAE feature}\neq\text{validated semantic concept}.
```

To make the semantic step, inspect coherence, stability, held-out behavior, and controlled interventions.
"""

# ╔═╡ 43a38993-cbb8-42bf-918b-6fa069ed8ec2
md"""
## Reference map
"""

# ╔═╡ d49333e8-7d47-4487-b4aa-bf6a66f95f09
Markdown.parse(join(
    ["- **[$(r.short)]** $(r.citation)" for r in GLOSSARY_REFERENCES],
    "\n",
))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ Cell order:
# ╟─b07350fb-19c1-4d83-9afe-11a59ed56202
# ╟─f13a6a1c-3ed5-4a1a-9b42-3ef264e72703
# ╟─229053c5-e870-47c1-84cb-aa8c244c9507
# ╟─9b90625c-0509-4143-b224-46c219b47704
# ╟─658bce71-f9fd-40e0-b452-b333689583b2
# ╟─272c96b8-cf5a-4f5b-9fc2-bf0b8ed1bc16
# ╟─26ed4a41-b122-4fc0-a9c3-d35481614e30
# ╟─08035f82-d7ce-4acf-a1cd-f55a9eaaef07
# ╟─ae106bd3-328b-41fc-a653-ded365331409
# ╟─43a38993-cbb8-42bf-918b-6fa069ed8ec2
# ╟─d49333e8-7d47-4487-b4aa-bf6a66f95f09
# ╟─00000000-0000-0000-0000-000000000001
