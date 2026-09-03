module ExerciseContent

export ExerciseQuestion,
       ExerciseSection,
       Exercise,
       WORKSHEET_TITLE,
       WORKSHEET_AUTHOR,
       EXERCISES,
       exercise_by_number,
       render_exercise

const WORKSHEET_TITLE = "Low-Rank Structure Is Geometry"
const WORKSHEET_AUTHOR = "Se Eun Choi · Paul Breiding"

"""One prompt and its answer. The answer lives beside the prompt by design."""
Base.@kwdef struct ExerciseQuestion
    id::String
    prompt::String
    answer::String
    options::Vector{String} = String[]
    answer_lines::Int = 1
end

Base.@kwdef struct ExerciseSection
    title::String = ""
    introduction::String = ""
    questions::Vector{ExerciseQuestion}
end

Base.@kwdef struct Exercise
    number::Int
    title::String
    notebook::String
    location::String = ""
    minutes::Int
    introduction::String = ""
    sections::Vector{ExerciseSection}
end

q(id, prompt, answer; options=String[], answer_lines=1) =
    ExerciseQuestion(; id, prompt, answer, options, answer_lines)

const EXERCISES = Exercise[
    Exercise(
        number=1,
        title="Keep the axes or flatten them?",
        notebook="notebooks/00_Primer.jl",
        location="Section 1",
        minutes=6,
        introduction="Compare a sample × token × feature activation tensor of size (3, 4, 5) with the matrix obtained by flattening sample and token together.",
        sections=[ExerciseSection(questions=[
            q("1", "How many entries are in the 3 × 4 × 5 tensor?", "60 entries."; options=["12", "20", "60", "120"]),
            q("2", "If sample and token are flattened into one axis, what is the matrix size?", "(12, 5)."; options=["(3, 20)", "(12, 5)", "(4, 15)", "(60, 1)"]),
            q("3", "Does flattening delete any numerical entries?", "No. Both views contain the same 60 numerical entries."; options=["Yes", "No"]),
            q("4", "What information is no longer explicit in the 12 × 5 matrix?", "The row index no longer separates which sample and which token produced an entry."; answer_lines=2),
            q("5", "Which view is more useful for comparing token patterns across samples, and why?", "The tensor view, because sample and token remain separate axes that can be compared independently."; answer_lines=2),
        ])],
    ),
    Exercise(
        number=2,
        title="Build, decompose, reconstruct",
        notebook="notebooks/00_Primer.jl",
        location="Section 3",
        minutes=7,
        introduction="Generate a rank-3 tensor from A of size (3, 3), B of size (3, 3), and C of size (2, 3). Fit a rank-3 CPD and inspect the returned object.",
        sections=[ExerciseSection(questions=[
            q("1", "What is the size of the generated tensor, and how many rank-one terms were used?", "The tensor has size (3, 3, 2) and uses three rank-one terms."),
            q("2", "What is the format of the returned CP decomposition?", "Three component weights and one factor matrix per mode; here the factor sizes are (3, 3), (3, 3), and (2, 3)."; answer_lines=2),
            q("3", "Reconstruct T-hat. What size does it have?", "(3, 3, 2)."),
            q("4", "Record ||T - T-hat||F / ||T||F from the notebook.", "Accept the near-zero relative Frobenius error printed by the notebook."),
            q("5", "If the relative error is nearly zero, what has been verified?", "The represented tensor has been reconstructed accurately."; answer_lines=2),
            q("6", "What has not been verified by a near-zero error?", "Uniqueness, stability, and recovery of the exact original factor coordinates have not been verified."; answer_lines=2),
            q("7", "Must the fitted factor columns equal the original columns entry by entry?", "No. CP coordinates can differ by component permutation and reciprocal rescaling even when the tensor is identical."; options=["Yes", "No"]),
        ])],
    ),
    Exercise(
        number=3,
        title="Same object, different coordinates",
        notebook="notebooks/01_OneObjectManyCoordinates.jl",
        location="Sections 1A–1B",
        minutes=8,
        introduction="Open the Matrix gauge experiment. Make a prediction, then move the gauge slider and compare coordinate change with object change.",
        sections=[
            ExerciseSection(title="Measure", questions=[
                q("1", "Set log10(s) = 0. Record s and κ(Q).", "s = 1 and κ(Q) = 1."),
                q("2", "Set log10(s) = 3. Record s and κ(Q).", "s = 1000 and κ(Q) = 1,000,000."),
                q("3", "Tick every quantity that changes strongly.", "Factor coordinates and factor conditioning change strongly; the represented matrix does not."; options=["factor coordinates", "factor conditioning", "represented matrix"]),
                q("4", "In the CP rescaling and permutation experiment, does the represented tensor change?", "No."; options=["Yes", "No"]),
            ]),
            ExerciseSection(title="Predict and explain", questions=[
                q("5", "For Q(s) = diag(s, s⁻¹), what do you expect as s becomes very large?", "The factors can become badly scaled, the reconstruction error stays near zero, and κ(Q) increases."; options=["X changes dramatically", "the factors may become badly scaled", "the reconstruction error stays near zero", "κ(Q) increases"]),
                q("6", "If A′ = AQ and B′ = BQ⁻ᵀ, complete A′B′ᵀ = ____.", "A′B′ᵀ = ABᵀ = X."),
                q("7", "Two different factor pairs produce the same matrix. Which object should we regard as the underlying object?", "The represented matrix X."; options=["A", "B", "the pair (A, B)", "the represented matrix X"]),
                q("8", "If X = A₁B₁ᵀ = A₂B₂ᵀ, must A₁ = A₂ and B₁ = B₂?", "No."; options=["Yes", "No"]),
                q("9", "A relative reconstruction error is 10⁻¹⁴. Which conclusion is justified?", "The recovered matrix is extremely close to the target matrix; this alone says nothing about factor uniqueness or conditioning."; options=["the factors are unique", "the recovered matrix is extremely close", "the problem is well-conditioned", "every factor was recovered correctly"]),
                q("10", "Finish the sentence: A low-rank factorization is a ____ of the underlying matrix. The coordinates can change while the represented ____ stays the same.", "A representation (or coordinate description) of the underlying matrix; the represented object stays the same."; answer_lines=2),
            ]),
        ],
    ),
    Exercise(
        number=4,
        title="Mode subspaces and model choice",
        notebook="notebooks/02_GeometryAtlas.jl",
        location="Model cards and capacity experiment",
        minutes=8,
        introduction="Compare CP, Tucker, and BTD on the two-block target. Focus first on the structure each model preserves; unfolding-rank arithmetic is an optional extension.",
        sections=[
            ExerciseSection(title="Read the structural assumption", questions=[
                q("1", "In a Tucker model, must every mode use the same compression rank?", "No. Tucker can choose a different low-dimensional subspace for each mode."; options=["Yes", "No"]),
                q("2", "What does the Tucker core describe?", "It describes how the latent coordinates from the separate mode subspaces interact."; answer_lines=2),
                q("3", "Which object is a CP component: one mode vector or the complete outer product across all modes?", "The complete rank-one outer product across all modes."; options=["One mode vector", "The complete outer product"]),
                q("4", "Why should raw Tucker factor columns not automatically be treated as unique concepts?", "A basis can change inside a mode subspace while a compensating core change preserves the represented tensor."; answer_lines=2),
            ]),
            ExerciseSection(title="Choose the structural model", questions=[
                q("5", "Which model uses one shared list of rank-one components across all modes?", "CP."; options=["CP", "Tucker", "BTD"]),
                q("6", "Which model uses one core with a possibly different compression rank for each mode?", "Tucker."; options=["CP", "Tucker", "BTD"]),
                q("7", "The Lab 2 target is a sum of two small Tucker blocks. Which model most directly mirrors that construction?", "BTD."; options=["CP", "Tucker", "BTD"]),
                q("8", "If one fitted model has the smallest error in this finite run, does that prove it is always the best model?", "No. Structural capacity, optimization success, numerical error, and the scientific meaning of the coordinates are different issues."; options=["Yes", "No"]),
            ]),
        ],
    ),
    Exercise(
        number=5,
        title="Observe stagnation, diagnose its geometry",
        notebook="notebooks/03_OptimizationFailureMuseum.jl",
        minutes=10,
        introduction="Use the failure map, component-similarity control, three-case comparison, solver race, and plateau microscope to separate an observation from its possible cause.",
        sections=[
            ExerciseSection(title="Collision and reliable ALS updates", questions=[
                q("1", "Move the control from Distinct toward Almost identical. What happens to component separation?", "Component separation decreases toward zero."; options=["It decreases", "It stays fixed", "It increases"]),
                q("2", "Do the two complete rank-one patterns become easier or harder to distinguish?", "Harder to distinguish."; options=["Easier", "Harder"]),
                q("3", "As component separation decreases, what happens to ALS update sensitivity?", "It increases, showing that the local allocation is becoming less reliable."; options=["It decreases", "It stays fixed", "It increases"]),
                q("4", "In plain language, what becomes hard for ALS near a collision?", "ALS can still fit the combined contribution, but it has difficulty deciding how much belongs to each of the two nearly identical components."; answer_lines=2),
                q("5", "Press Redistribute shared signal near a collision. What changes strongly, and what changes very little?", "The component contribution coordinates change strongly, while the reconstructed pattern changes very little."; answer_lines=2),
            ]),
            ExerciseSection(title="Trajectory and plateau diagnosis", questions=[
                q("6", "Why must every solver in the race start from the same CPDPoint?", "It isolates the optimization method as the changed variable; otherwise different initial coordinates could explain different outcomes."; answer_lines=2),
                q("7", "What observation triggers the plateau flag, and which diagnostics are used afterward to test a collision explanation?", "The flag uses only slow error improvement over the last 20 sweeps. Component separation and ALS update sensitivity are diagnostic evidence, not part of the plateau detector."; answer_lines=2),
                q("8", "The poor-start case is slow even though its components remain separated and update sensitivity is moderate. Does slow optimization by itself prove collision?", "No. A plateau is an observation; initialization and other mechanisms can explain it."; options=["Yes", "No"]),
                q("9", "Can a reconstruction error be small while individual components remain difficult to interpret reliably?", "Yes. Object-level fit and coordinate-level separation or stability are different diagnostics."; options=["Yes", "No"]),
            ]),
        ],
    ),
    Exercise(
        number=6,
        title="From activations to a concept claim",
        notebook="notebooks/04_NeuralRepresentations.jl",
        location="Concept explorer and evidence ladder",
        minutes=14,
        introduction="Audit one candidate concept in the synthetic CRAFT-style pipeline. Separate what the factorization shows from the semantic and behavioral claims that still require evidence.",
        sections=[
            ExerciseSection(title="Read the factorization", questions=[
                q("1", "What does one row of the activation matrix A represent?", "The pooled activation-feature vector produced by one image crop."; answer_lines=2),
                q("2", "In A ≈ UWᵀ, what do U[i,j] and W[:,j] represent?", "U[i,j] is candidate-concept j's nonnegative usage in crop i; W[:,j] is its candidate concept activation direction in feature space."; answer_lines=3),
                q("3", "Move the rank slider from 1 to 5. At which rank are the three planted ingredients easiest to name, and what happens on either side?", "They are clearest near rank 3. Smaller ranks merge ingredients; larger ranks can split or duplicate them even while reconstruction error falls."; answer_lines=3),
                q("4", "Choose one concept. Which evidence helps you propose a human label: the CAV alone or the high-usage crops?", "The high-usage crops connect the activation direction to recurring visible examples; the CAV alone is not human-readable."; options=["CAV alone", "High-usage crops"]),
            ]),
            ExerciseSection(title="Audit the claim", questions=[
                q("5", "In the perturbation experiment, is the most present concept necessarily the most important to the class score?", "No. Presence is a coordinate in the activation reconstruction; importance concerns the model output's sensitivity to changing that coordinate."; options=["Yes", "No"]),
                q("6", "Why is nonnegativity not enough for a concept claim? Give one stability check.", "NMF coordinates can depend on rank, layer, initialization, and optimization. For example, compare factors and top crops across seeds, nearby ranks, or layers."; answer_lines=2),
                q("7", "Why is the sample × location × feature factorization in 4H not CRAFT?", "CRAFT factorizes pooled crop activations with matrix NMF and uses its own attribution machinery for location. The tensor model is a TensorKitchen extension question with different structural assumptions."; answer_lines=2),
            ]),
        ],
    ),
]

exercise_by_number(number::Integer) = only(filter(exercise -> exercise.number == number, EXERCISES))

function html_escape(text::AbstractString)
    replace(text, '&' => "&amp;", '<' => "&lt;", '>' => "&gt;", '"' => "&quot;")
end

function inline_html(text::AbstractString)
    escaped = html_escape(text)
    escaped = replace(escaped, r"`([^`]+)`" => s"<code>\1</code>")
    replace(escaped, '\n' => "<br>")
end

"""Render one exercise as a Pluto-friendly interactive HTML card."""
function render_exercise(exercise::Exercise)
    sections = String[]
    for section in exercise.sections
        heading = isempty(section.title) ? "" : "<h3>$(inline_html(section.title))</h3>"
        intro = isempty(section.introduction) ? "" : "<p>$(inline_html(section.introduction))</p>"
        questions = String[]
        for question in section.questions
            options = isempty(question.options) ? "" : "<div class=\"tk-options\">" *
                join(("<label><input type=\"checkbox\"> $(inline_html(option))</label>" for option in question.options), "") *
                "</div>"
            push!(questions, """
            <article class="tk-question">
              <p><b>$(inline_html(question.id)).</b> $(inline_html(question.prompt))</p>
              $options
              <details><summary>Check answer</summary><div>$(inline_html(question.answer))</div></details>
            </article>
            """)
        end
        push!(sections, "$heading$intro$(join(questions))")
    end
    Base.HTML("""
    <style>
      .tk-exercise{font:16px/1.55 system-ui,sans-serif;color:#2e3224;background:#fff;border:1px solid #d5d9c3;border-radius:16px;overflow:hidden;margin:1rem 0 2rem;box-shadow:0 10px 30px rgba(78,88,52,.1)}
      .tk-head{background:linear-gradient(120deg,#4e5834,#70794c);color:#fff;padding:1rem 1.25rem}.tk-head h2{margin:0;font-size:1.35rem}.tk-meta{opacity:.86;margin-top:.25rem;font-size:.86rem}
      .tk-body{padding:1rem 1.25rem}.tk-body h3{color:#59623d;border-bottom:1px solid #d9dec6;padding-bottom:.3rem;margin:1.2rem 0 .5rem}
      .tk-question{background:#f4f6ec;border-left:4px solid #b4773c;border-radius:8px;padding:.72rem .9rem;margin:.7rem 0}.tk-question p{margin:.05rem 0 .45rem}
      .tk-options{display:flex;flex-wrap:wrap;gap:.4rem 1.1rem;margin:.25rem 0 .55rem}.tk-options label{cursor:pointer}.tk-options input{accent-color:#667044}
      .tk-question details{margin-top:.55rem}.tk-question summary{display:inline-block;cursor:pointer;border:1px solid #c8cdaa;border-radius:999px;padding:.25rem .7rem;color:#55603a;background:#fff;font-weight:650;font-size:.86rem}.tk-question details div{margin-top:.55rem;padding:.55rem .7rem;background:#ecf3e8;border-radius:7px;color:#3f6044}
      code{background:#e8ecd8;padding:.08rem .25rem;border-radius:4px}
    </style>
    <section class="tk-exercise">
      <header class="tk-head"><h2>Exercise $(exercise.number) — $(inline_html(exercise.title))</h2><div class="tk-meta">$(inline_html(exercise.notebook))$(isempty(exercise.location) ? "" : " · $(inline_html(exercise.location))") · about $(exercise.minutes) minutes</div></header>
      <div class="tk-body"><p>$(inline_html(exercise.introduction))</p>$(join(sections))</div>
    </section>
    """)
end

end
