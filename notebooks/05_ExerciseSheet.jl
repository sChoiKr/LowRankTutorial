### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ a15c02c1-fc98-4d1c-927f-e2938b59c89b
begin
    include(joinpath(@__DIR__, "ExerciseContent.jl"))
    using .ExerciseContent
end

# ╔═╡ cfa3c5af-d8dd-4552-a579-983531526a8c
md"""
# TensorKitchen exercises

**Paul Breiding · Se Eun Choi**

These are the same exercises used to generate the printable student sheet and
answer key. Work through them beside the named Lab notebook:

1. open the Lab and use the relevant slider, selector, or run button;
2. make a prediction and inspect the visual result;
3. return here, select an answer, and open **Check answer** for that problem.

All exercise blocks are visible immediately. Answers remain hidden until you
open the corresponding **Check answer** control.
"""

# ╔═╡ b2b85ec5-a637-4539-a427-f641108bef50
render_exercise(exercise_by_number(1))

# ╔═╡ 420db871-ebbb-4908-8d4d-31d013f672b0
render_exercise(exercise_by_number(2))

# ╔═╡ afc790b2-76a1-435c-ab7b-dd2579bdb250
render_exercise(exercise_by_number(3))

# ╔═╡ 98d7b734-2020-4a20-8c8d-4fef0ce1477d
render_exercise(exercise_by_number(4))

# ╔═╡ acb63205-7bdd-4381-8868-29a1273243b2
render_exercise(exercise_by_number(5))

# ╔═╡ 38490d32-2d50-4bd0-ac9b-48c0db4e99d3
render_exercise(exercise_by_number(6))

# ╔═╡ 0123e053-c2c1-44ce-a597-f8074b4cc0d0
md"""
!!! note "Single source of truth"
    Questions, choices, answers, and notebook references are defined together
    in `ExerciseContent.jl`. The Markdown, HTML, student PDF, answer-key PDF,
    and this Pluto notebook all consume that same data.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "71853c6197a6a7f222db0f1978c7cb232b87c5ee"

[deps]
"""

# ╔═╡ Cell order:
# ╟─cfa3c5af-d8dd-4552-a579-983531526a8c
# ╟─a15c02c1-fc98-4d1c-927f-e2938b59c89b
# ╟─b2b85ec5-a637-4539-a427-f641108bef50
# ╟─420db871-ebbb-4908-8d4d-31d013f672b0
# ╟─afc790b2-76a1-435c-ab7b-dd2579bdb250
# ╟─98d7b734-2020-4a20-8c8d-4fef0ce1477d
# ╟─acb63205-7bdd-4381-8868-29a1273243b2
# ╟─38490d32-2d50-4bd0-ac9b-48c0db4e99d3
# ╟─0123e053-c2c1-44ce-a597-f8074b4cc0d0
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
