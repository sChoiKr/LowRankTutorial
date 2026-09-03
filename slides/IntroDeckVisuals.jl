module IntroDeckVisuals

using LinearAlgebra
using Printf

export ai_modes_visual,
       closing_visual,
       compression_visual,
       cp_linked_visual,
       deck_theme,
       flattening_visual,
       gauge_geometry_visual,
       geometry_language_visual,
       hero_visual,
       model_assumption_visual,
       tensor_anatomy_visual,
       tucker_rank_visual,
       validation_visual,
       why_now_visual

const DECK_COUNTER = Ref(0)

function next_deck_id(prefix)
    DECK_COUNTER[] += 1
    "$(prefix)-$(DECK_COUNTER[])"
end

escape_html(x) = replace(
    string(x),
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "\"" => "&quot;",
)

function heat_color(value, scale)
    t = clamp(abs(float(value)) / max(float(scale), eps()), 0, 1)
    neutral = (239, 234, 220)
    positive = (93, 126, 157)
    negative = (201, 111, 74)
    target = value ≥ 0 ? positive : negative
    strength = 0.16 + 0.84t
    channels = ntuple(3) do i
        round(Int, (1 - strength) * neutral[i] + strength * target[i])
    end
    @sprintf("#%02x%02x%02x", channels...)
end

function heatmap_html(A::AbstractMatrix; cell = 18, radius = 3)
    scale = maximum(abs, A; init = 1.0)
    cells = String[]
    for value in A
        push!(cells, "<span style=\"background:$(heat_color(value, scale))\"></span>")
    end
    """
    <div class="tk-heatmap" style="--rows:$(size(A, 1));--cols:$(size(A, 2));--cell:$(cell)px;--radius:$(radius)px">
      $(join(cells))
    </div>
    """
end

"""Compact CPD equation inspired by a three-stick outer-product diagram."""
function cpd_sum_svg(id::AbstractString)
    terms = [
        (x = 4, color = "var(--tk-terra)", sub = "₁", label = "component 1"),
        (x = 158, color = "var(--tk-blue)", sub = "₂", label = "component 2"),
        (x = 382, color = "var(--tk-ochre)", sub = "ᵣ", label = "component R"),
    ]
    term_svg = join(("""
      <g transform="translate($(term.x),2)" style="color:$(term.color)">
        <!-- Three flat rectangular vector sticks: a_r, b_r, and c_r. -->
        <rect data-vector-stick="c" x="45" y="46" width="58" height="14" rx="2" transform="rotate(-42 38 56)" fill="currentColor" fill-opacity=".48" stroke="currentColor" stroke-width="1.7"/>
        <rect data-vector-stick="a" x="30" y="60" width="14" height="54" rx="2" fill="currentColor" fill-opacity=".68" stroke="currentColor" stroke-width="1.7"/>
        <rect data-vector-stick="b" x="48" y="52" width="55" height="14" rx="2" fill="currentColor" fill-opacity=".58" stroke="currentColor" stroke-width="1.7"/>
        <text x="58" y="139" text-anchor="middle" fill="currentColor" font-size="14" font-weight="800">$(term.label)</text>
        <text x="58" y="158" text-anchor="middle" fill="currentColor" font-size="12" font-weight="700">a$(term.sub) ⊗ b$(term.sub) ⊗ c$(term.sub)</text>
      </g>
    """ for term in terms), "")
    """
    <svg class="cpd-sum-svg" viewBox="0 0 680 174" role="img" aria-label="A tensor is approximated by component 1 plus component 2 through component R">
      <title>CPD: component 1 plus component 2 through component R</title>
      $term_svg
      <text x="136" y="68" text-anchor="middle" fill="var(--tk-muted)" font-size="27" font-weight="650">+</text>
      <text x="330" y="68" text-anchor="middle" fill="var(--tk-muted)" font-size="23" font-weight="650">+ ⋯ +</text>
      <text x="514" y="68" text-anchor="middle" fill="var(--tk-muted)" font-size="25" font-weight="650">≈</text>
      <g transform="translate(548,20)">
        <polygon points="0,24 24,0 104,0 80,24" fill="var(--tk-olive)" fill-opacity=".28" stroke="var(--tk-olive-dark)" stroke-width="2"/>
        <rect x="0" y="24" width="80" height="88" rx="2" fill="var(--tk-olive)" fill-opacity=".42" stroke="var(--tk-olive-dark)" stroke-width="2"/>
        <polygon points="80,24 104,0 104,88 80,112" fill="var(--tk-olive)" fill-opacity=".22" stroke="var(--tk-olive-dark)" stroke-width="2"/>
        <text x="40" y="78" text-anchor="middle" fill="var(--tk-olive-dark)" font-size="22" font-weight="800">𝒯</text>
      </g>
    </svg>
    """
end

"""One interactive CP component shown explicitly as three segmented vectors."""
function cp_component_outer_svg(id::AbstractString)
    sample = join(["<rect data-segment x=\"52\" y=\"$(24 + 27i)\" width=\"22\" height=\"22\" rx=\"4\"/>" for i = 0:4])
    space = join(["<rect data-segment x=\"$(146 + 27i)\" y=\"83\" width=\"22\" height=\"22\" rx=\"4\"/>" for i = 0:5])
    feature = join(["<rect data-segment x=\"$(354 + 27i)\" y=\"$(96 - 20i)\" width=\"22\" height=\"16\" rx=\"2\"/>" for i = 0:3])
    """
    <svg class="component-outer-svg" viewBox="0 0 500 190" role="img" aria-label="Outer product of sample, space, and feature vectors">
      <title>One CP rank-one component: sample vector outer product space vector outer product feature vector</title>
      <g data-vector="sample" fill="var(--component)">$sample</g>
      <text x="63" y="178" text-anchor="middle" fill="var(--component)" font-size="16" font-weight="800">aᵣ</text>
      <text x="112" y="99" text-anchor="middle" fill="var(--tk-muted)" font-size="28" font-weight="650">⊗</text>
      <g data-vector="space" fill="var(--component)">$space</g>
      <text x="219" y="132" text-anchor="middle" fill="var(--component)" font-size="16" font-weight="800">bᵣ</text>
      <text x="326" y="99" text-anchor="middle" fill="var(--tk-muted)" font-size="28" font-weight="650">⊗</text>
      <g data-vector="feature" fill="var(--component)">$feature</g>
      <text x="469" y="28" text-anchor="middle" fill="var(--component)" font-size="16" font-weight="800">cᵣ</text>
    </svg>
    """
end

"""Small structural icon for CP or nonnegative CP on the model-comparison slide."""
function cp_model_abstract_svg(; nonnegative::Bool = false)
    colors = nonnegative ? fill("var(--tk-olive)", 3) : ["var(--tk-terra)", "var(--tk-blue)", "var(--tk-ochre)"]
    terms = join(("""
      <g transform="translate($(36 + 104i),55)" style="color:$(colors[i + 1])">
        <rect x="-6" y="0" width="12" height="48" rx="3" fill="currentColor" fill-opacity=".78"/>
        <rect x="0" y="-6" width="48" height="12" rx="3" fill="currentColor" fill-opacity=".62"/>
        <rect x="0" y="-6" width="46" height="12" rx="3" transform="rotate(-42 0 0)" fill="currentColor" fill-opacity=".46"/>
        <circle cx="0" cy="0" r="4" fill="currentColor"/>
      </g>
    """ for i = 0:2), "")
    condition = nonnegative ? """
      <rect x="82" y="132" width="166" height="25" rx="12.5" fill="var(--tk-olive)" fill-opacity=".13"/>
      <text x="165" y="149" text-anchor="middle" fill="var(--tk-olive-dark)" font-size="15" font-weight="800">all factors ≥ 0</text>
    """ : """
      <text x="165" y="149" text-anchor="middle" fill="var(--tk-muted)" font-size="15" font-weight="750">sum of rank-1 terms</text>
    """
    label = nonnegative ? "Nonnegative CP: additive rank-one terms whose factor entries are nonnegative" : "CP: a sum of rank-one terms"
    """
    <svg class="cp-model-abstract-svg" viewBox="0 0 330 165" role="img" aria-label="$label">
      <title>$label</title>
      $terms
      <text x="105" y="62" text-anchor="middle" fill="var(--tk-muted)" font-size="24" font-weight="650">+</text>
      <text x="209" y="62" text-anchor="middle" fill="var(--tk-muted)" font-size="24" font-weight="650">+</text>
      $condition
    </svg>
    """
end

function deck_theme()
    Base.HTML("""
    <style>
      :root {
        --tk-olive: #5e6740;
        --tk-olive-dark: #41482d;
        --tk-cream: #f6f1e5;
        --tk-paper: #fffdf7;
        --tk-ink: #252a22;
        --tk-muted: #6d715f;
        --tk-gray: #898d89;
        --tk-sage: #a7b08b;
        --tk-blue: #5d7e9d;
        --tk-ochre: #c3a04d;
        --tk-terra: #c96f4a;
      }
      pluto-notebook { max-width: 1180px !important; }
      pluto-cell { max-width: 1120px !important; }
      .edit_or_run { display: none !important; }
      pluto-output h1, pluto-output h2 {
        color: var(--tk-ink) !important;
        font-family: Inter, Avenir Next, Avenir, system-ui, sans-serif !important;
        letter-spacing: -0.035em;
      }
      pluto-output h1 { font-size: clamp(3.2rem, 7vw, 6.4rem) !important; line-height: .98; }
      pluto-output h2 { font-size: clamp(2.2rem, 4vw, 3.7rem) !important; line-height: 1.04; }
      pluto-output p { color: var(--tk-muted); font-size: 1.16rem; line-height: 1.5; }
      body.presentation { background: var(--tk-cream); }
      body.presentation pluto-cell {
        width: min(1120px, calc(100vw - 72px)) !important;
        max-width: 1120px !important;
        margin-left: auto;
        margin-right: auto;
      }
      body.presentation .tk-stage { min-height: 470px; }
      body.presentation pluto-output h1 { font-size: clamp(3.1rem, 5.8vw, 4.7rem) !important; }
      body.presentation pluto-cell[id="795e3756-69de-4a54-b01e-d3f89ac03052"],
      body.presentation pluto-cell[id="13151c6e-7fb1-45c1-a9e5-34e3b9011ac7"],
      body.presentation pluto-cell[id="2fa06813-ee7d-4838-910d-a0adbb4453c3"] {
        height: 0 !important;
        min-height: 0 !important;
        margin: 0 !important;
        overflow: hidden !important;
      }
      body.presentation pluto-output h1,
      body.presentation pluto-output h2 { scroll-margin-top: 24px; }
      .tk-stage {
        box-sizing: border-box;
        width: 100%;
        min-height: 500px;
        overflow: hidden;
        position: relative;
        border: 1px solid rgba(94,103,64,.2);
        border-radius: 28px;
        background:
          radial-gradient(circle at 88% 8%, rgba(195,160,77,.17), transparent 27%),
          linear-gradient(145deg, var(--tk-paper), var(--tk-cream));
        color: var(--tk-ink);
        box-shadow: 0 18px 60px rgba(48,53,34,.10);
        padding: clamp(24px, 4vw, 48px);
        font-family: Inter, Avenir Next, Avenir, system-ui, sans-serif;
      }
      .tk-stage * { box-sizing: border-box; }
      .tk-kicker { color: var(--tk-olive); font-weight: 800; text-transform: uppercase; letter-spacing: .14em; font-size: 16px; }
      .tk-display { font-size: clamp(2rem, 4.4vw, 4.2rem); line-height: 1.02; letter-spacing: -.045em; font-weight: 760; }
      .tk-lede { color: var(--tk-muted); font-size: clamp(17px, 1.9vw, 23px); line-height: 1.45; max-width: 690px; }
      .tk-row { display: flex; gap: clamp(22px, 4vw, 58px); align-items: center; }
      .tk-row > * { min-width: 0; }
      .tk-grow { flex: 1 1 0; }
      .tk-btnrow { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
      .tk-btn {
        appearance: none;
        border: 1px solid rgba(94,103,64,.45);
        border-radius: 999px;
        background: rgba(255,253,247,.86);
        color: var(--tk-olive-dark);
        padding: 10px 16px;
        font: 700 15px/1.1 Inter, system-ui, sans-serif;
        cursor: pointer;
        transition: transform .18s ease, background .18s ease, color .18s ease;
      }
      .tk-btn:hover { transform: translateY(-1px); }
      .tk-btn.active, .tk-btn[aria-pressed="true"] { background: var(--tk-olive); color: white; border-color: var(--tk-olive); }
      .tk-btn:focus-visible, .tk-stage input:focus-visible { outline: 3px solid rgba(195,160,77,.55); outline-offset: 3px; }
      .tk-stat { font-variant-numeric: tabular-nums; }
      .tk-stat strong { display: block; font-size: clamp(2rem, 4vw, 4rem); letter-spacing: -.04em; color: var(--tk-olive-dark); }
      .tk-muted { color: var(--tk-muted); }
      .tk-accent { color: var(--tk-terra); }
      .tk-caption { color: var(--tk-muted); font-size: 14px; line-height: 1.4; }
      .tk-heatmap { display: grid; grid-template-columns: repeat(var(--cols), var(--cell)); grid-template-rows: repeat(var(--rows), var(--cell)); gap: 2px; }
      .tk-heatmap span { width: var(--cell); height: var(--cell); border-radius: var(--radius); }
      .tk-slider { width: 100%; accent-color: var(--tk-olive); }
      .tk-rule { height: 1px; background: rgba(94,103,64,.2); margin: 18px 0; }
      .tk-formula { font-family: Georgia, Cambria, serif; font-size: clamp(1.5rem, 2.6vw, 2.8rem); letter-spacing: -.02em; }
      .tk-footer { position: absolute; left: 48px; right: 48px; bottom: 22px; display: flex; justify-content: space-between; color: #858978; font-size: 14px; }
      #tk-present-control {
        position: fixed;
        left: 18px;
        bottom: 18px;
        z-index: 10000;
        appearance: none;
        border: 1px solid rgba(94,103,64,.38);
        border-radius: 999px;
        background: rgba(255,253,247,.92);
        color: var(--tk-olive-dark);
        box-shadow: 0 8px 26px rgba(48,53,34,.15);
        padding: 9px 14px;
        font: 750 13px/1 Inter, system-ui, sans-serif;
        cursor: pointer;
        backdrop-filter: blur(8px);
      }
      body.presentation #tk-present-control { opacity: .16; }
      body.presentation #tk-present-control:hover { opacity: 1; }
      @media (max-width: 760px) {
        .tk-stage { min-height: 560px; border-radius: 18px; padding: 24px; }
        .tk-row { flex-direction: column; align-items: stretch; }
        .tk-footer { left: 24px; right: 24px; }
      }
    </style>
    <button id="tk-present-control" type="button" onclick="const entering=!document.body.classList.contains('presentation');window.present?.();if(entering)setTimeout(()=>document.querySelector('button.changeslide.next')?.click(),80)" title="Enter Pluto presentation mode">Present</button>
    """)
end

function hero_visual()
    id = next_deck_id("tk-hero")
    layer_cells = join(["<span></span>" for _ in 1:30])
    tensor_layers = join(["<div class=\"hero-layer l$i\">$layer_cells</div>" for i = 1:7])
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id { min-height: 360px; padding:28px 38px; }
        #$id .hero-grid { display:grid; grid-template-columns: 1.08fr .92fr; gap:34px; align-items:center; min-height:300px; }
        #$id .hero-copy { position:relative; z-index:2; }
        #$id .hero-stack { position:relative; height:280px; perspective:900px; transform:scale(.82); }
        #$id .tensor-turntable { position:absolute; inset:0; transform-style:preserve-3d; transform:rotateX(0deg) rotateY(0deg) rotateZ(0deg) scale(1); transform-origin:50% 50%; transition:transform 1.45s cubic-bezier(.2,.72,.18,1); will-change:transform; }
        #$id .hero-layer { position:absolute; left:50%; top:50%; display:grid; grid-template-columns:repeat(6,28px); grid-template-rows:repeat(5,28px); gap:4px; padding:14px; border:1px solid rgba(65,72,45,.35); border-radius:14px; background:rgba(255,253,247,.78); box-shadow:0 16px 34px rgba(45,50,31,.11); transform-style:preserve-3d; transition:transform 1.8s cubic-bezier(.22,.72,.2,1), opacity 1.2s ease; }
        #$id .hero-layer span { border-radius:4px; background:var(--tk-blue); opacity:.2; }
        #$id .hero-layer span:nth-child(4n+1) { background:var(--tk-terra); opacity:.65; }
        #$id .hero-layer span:nth-child(5n+2) { background:var(--tk-ochre); opacity:.72; }
        #$id .l1 { transform:translate(-68%,-86%) rotateX(58deg) rotateZ(-22deg) translateZ(180px); }
        #$id .l2 { transform:translate(-62%,-74%) rotateX(58deg) rotateZ(-22deg) translateZ(120px); }
        #$id .l3 { transform:translate(-56%,-62%) rotateX(58deg) rotateZ(-22deg) translateZ(60px); }
        #$id .l4 { transform:translate(-50%,-50%) rotateX(58deg) rotateZ(-22deg) translateZ(0); }
        #$id .l5 { transform:translate(-44%,-38%) rotateX(58deg) rotateZ(-22deg) translateZ(-60px); }
        #$id .l6 { transform:translate(-38%,-26%) rotateX(58deg) rotateZ(-22deg) translateZ(-120px); }
        #$id .l7 { transform:translate(-32%,-14%) rotateX(58deg) rotateZ(-22deg) translateZ(-180px); }
        #$id.assembled .l1 { transform:translate(-50%,-59%) rotateX(58deg) rotateZ(-22deg) translateZ(54px); }
        #$id.assembled .l2 { transform:translate(-50%,-56%) rotateX(58deg) rotateZ(-22deg) translateZ(36px); }
        #$id.assembled .l3 { transform:translate(-50%,-53%) rotateX(58deg) rotateZ(-22deg) translateZ(18px); }
        #$id.assembled .l4 { transform:translate(-50%,-50%) rotateX(58deg) rotateZ(-22deg) translateZ(0); }
        #$id.assembled .l5 { transform:translate(-50%,-47%) rotateX(58deg) rotateZ(-22deg) translateZ(-18px); }
        #$id.assembled .l6 { transform:translate(-50%,-44%) rotateX(58deg) rotateZ(-22deg) translateZ(-36px); }
        #$id.assembled .l7 { transform:translate(-50%,-41%) rotateX(58deg) rotateZ(-22deg) translateZ(-54px); }
        #$id.tensor-complete .tensor-turntable { transform:rotateX(12deg) rotateY(-48deg) rotateZ(5deg) scale(1.04); }
        #$id.tensor-complete .hero-layer { border-color:rgba(65,72,45,.5); box-shadow:8px 14px 24px rgba(45,50,31,.13); }
        #$id .assembly-state { color:var(--tk-muted); font-size:12px; font-weight:750; min-width:118px; transition:color .25s ease; }
        #$id.assembled .assembly-state { color:var(--tk-ochre); }
        #$id.tensor-complete .assembly-state { color:var(--tk-olive); }
        #$id .tk-btn:disabled { cursor:wait; opacity:.72; }
        #$id .mode-label { position:absolute; font-weight:800; color:var(--tk-muted); font-size:13px; letter-spacing:.08em; text-transform:uppercase; }
        #$id .m1 { right:0; top:33px; color:var(--tk-terra); } #$id .m2 { left:10px; bottom:30px; color:var(--tk-blue); } #$id .m3 { right:10px; bottom:20px; color:var(--tk-ochre); }
        @media(max-width:760px){ #$id .hero-grid{grid-template-columns:1fr} #$id .hero-stack{height:280px} }
      </style>
      <div class="hero-grid">
        <div class="hero-copy">
          <div class="tk-kicker">TensorKitchen · Interactive introduction</div>
          <div class="tk-display" style="font-size:clamp(1.7rem,2.8vw,2.7rem);font-weight:720;letter-spacing:-.025em;margin:8px 0 9px">Millions of entries. <span class="tk-accent">Few interacting factors.</span></div>
          <p class="tk-lede" style="font-size:clamp(16px,2.25vw,18px);line-height:1.22;margin:0;max-width:560px">Modern AI produces enormous multiway arrays, yet their variation may be organized by a much smaller structure.</p>
          <div class="tk-btnrow" style="margin-top:12px"><button class="tk-btn" type="button">▶ Assemble the tensor</button><span class="assembly-state">7 slices separated</span><span class="tk-caption">Paul Breiding · Se Eun Choi · TensorKitchen tutorial</span></div>
        </div>
        <div class="hero-stack" aria-label="Seven tensor slices separated in space">
          <div class="tensor-turntable">$tensor_layers</div>
          <span class="mode-label m1">features</span><span class="mode-label m2">samples</span><span class="mode-label m3">context</span>
        </div>
      </div>
      <div class="tk-footer"><span>Low-rank tensors for AI</span><span>01</span></div>
      <script>
        (() => {
          const root = document.getElementById('$id');
          const button = root.querySelector('button');
          const state = root.querySelector('.assembly-state');
          let rotationTimer;
          let completionTimer;
          button.addEventListener('click', () => {
            clearTimeout(rotationTimer);
            clearTimeout(completionTimer);
            if (!root.classList.contains('assembled')) {
              root.classList.add('assembled');
              root.classList.remove('tensor-complete');
              button.disabled = true;
              button.textContent = 'Assembling slices…';
              state.textContent = 'Moving 7 slices together';
              rotationTimer = setTimeout(() => {
                root.classList.add('tensor-complete');
                button.textContent = 'Rotating into 3D…';
                state.textContent = 'Revealing tensor depth';
              }, 1850);
              completionTimer = setTimeout(() => {
                button.disabled = false;
                button.textContent = '↻ Separate the modes';
                state.textContent = '3D tensor complete';
              }, 3350);
            } else {
              root.classList.remove('tensor-complete', 'assembled');
              button.textContent = '▶ Assemble the tensor';
              state.textContent = '7 slices separated';
            }
          });
        })();
      </script>
    </div>
    """)
end

function why_now_visual()
    id = next_deck_id("tk-why-now")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id { min-height:510px; padding:24px 42px; container-type:inline-size; }
        #$id .why-grid { position:relative; min-height:408px; display:grid; grid-template-columns:minmax(0,1fr) 234px minmax(0,1fr); grid-template-rows:1fr 1fr; column-gap:32px; row-gap:16px; align-items:center; }
        #$id .why-grid::before, #$id .why-grid::after { content:''; position:absolute; left:19%; right:19%; top:50%; height:1px; background:linear-gradient(90deg,transparent,rgba(94,103,64,.34),transparent); z-index:0; }
        #$id .why-grid::after { transform:rotate(90deg); }
        #$id .hub { grid-column:2; grid-row:1 / 3; align-self:center; justify-self:center; width:210px; height:210px; position:relative; z-index:2; display:grid; place-items:center; text-align:center; border:2px solid var(--tk-olive); background:rgba(255,253,247,.96); box-shadow:0 18px 44px rgba(48,53,34,.14); transform:rotate(45deg); transition:border-color .3s ease, box-shadow .3s ease; }
        #$id .hub-copy { transform:rotate(-45deg); width:166px; }
        #$id .hub small { display:block; color:var(--tk-terra); font-size:10px; font-weight:900; letter-spacing:.12em; }
        #$id .hub strong { display:block; color:var(--tk-olive-dark); font-size:22px; letter-spacing:-.035em; line-height:1.05; margin-top:5px; }
        #$id .hub span { display:block; color:var(--tk-muted); font-size:11px; font-weight:750; margin-top:6px; line-height:1.22; }
        #$id .hub .hub-why { font-weight:600; }
        #$id .branch { appearance:none; position:relative; z-index:2; min-height:142px; padding:14px 18px 12px 68px; border:0; border-left:3px solid var(--branch); background:transparent; color:inherit; text-align:left; font:inherit; cursor:pointer; opacity:.72; transition:opacity .3s ease, transform .3s ease, background .3s ease; }
        #$id .branch:hover, #$id .branch.active { opacity:1; transform:translateY(-2px); background:linear-gradient(90deg,color-mix(in srgb,var(--branch) 12%,transparent),transparent 76%); }
        #$id .adapt, #$id .optimize { justify-self:end; width:min(330px,100%); }
        #$id .architect, #$id .interpret { justify-self:start; width:min(330px,100%); }
        #$id .adapt { --branch:var(--tk-terra); grid-column:1; grid-row:1; }
        #$id .optimize { --branch:var(--tk-blue); grid-column:1; grid-row:2; }
        #$id .architect { --branch:var(--tk-ochre); grid-column:3; grid-row:1; }
        #$id .interpret { --branch:var(--tk-olive); grid-column:3; grid-row:2; }
        #$id .branch-icon { position:absolute; left:14px; top:18px; width:38px; height:38px; color:var(--branch); font:700 17px/38px Georgia,serif; text-align:center; border:1px solid currentColor; }
        #$id .branch-kicker { color:var(--branch); font-size:14px; font-weight:900; letter-spacing:.14em; }
        #$id .branch strong { display:block; color:var(--tk-ink); font-size:21px; line-height:1.12; margin-top:6px; }
        #$id .branch p { margin:6px 0 0; color:var(--tk-muted); font-size:14px; line-height:1.3; }
        #$id .branch-note { display:block; margin-top:5px; color:var(--branch); font-size:11px; font-weight:800; }
        #$id .synthesis { position:absolute; z-index:3; left:8%; right:8%; bottom:4px; text-align:center; color:var(--tk-olive-dark); font-size:15px; font-weight:760; }
        @container (max-width:760px){#$id .why-grid{grid-template-columns:1fr 1fr;grid-template-rows:auto;gap:8px;min-height:650px;margin-bottom:60px}#$id .hub{grid-column:1/3;grid-row:1;width:150px;height:150px}#$id .hub-copy{width:120px}#$id .hub strong{font-size:17px}#$id .branch{grid-column:auto!important;grid-row:auto!important;min-height:112px;padding-left:52px}#$id .branch-icon{left:8px}#$id .synthesis{bottom:42px;font-size:13px}}
        @media(max-width:760px){#$id{padding:22px;min-height:720px}#$id .why-grid{grid-template-columns:1fr 1fr;grid-template-rows:auto;gap:8px;min-height:590px}#$id .hub{grid-column:1/3;grid-row:1;width:150px;height:150px}#$id .hub-copy{width:120px}#$id .hub strong{font-size:17px}#$id .branch{grid-column:auto!important;grid-row:auto!important;min-height:112px;padding-left:52px}#$id .branch-icon{left:8px}#$id .synthesis{bottom:18px;font-size:13px}}
      </style>
      <div class="why-grid">
        <button class="branch adapt active" data-role="adapt"><div class="branch-icon">USVᵀ</div><div class="branch-kicker">ADAPTATION</div><strong>StelLA</strong><p>A geometry-aware LoRA method that learns orthonormal input/output subspaces.</p><span class="branch-note">extends low-rank adaptation</span></button>
        <div class="hub"><div class="hub-copy"><small id="$id-hub-role">ADAPTATION</small><strong id="$id-hub-method">StelLA</strong><span id="$id-hub-object">Stiefel factors U, V</span><span class="hub-why" id="$id-hub-why">Learn orthonormal input/output subspaces.</span></div></div>
        <button class="branch optimize" data-role="optimize"><div class="branch-icon">Wᵣ</div><div class="branch-kicker">OPTIMIZE</div><strong>RAdaGrad / RAdamW</strong><p>Optimize the fixed-rank weight matrix as the geometric object.</p></button>
        <button class="branch architect" data-role="architect"><div class="branch-icon">⊗</div><div class="branch-kicker">ARCHITECT</div><strong>Tensor Decomposition Networks</strong><p>Replace expensive tensor-product operators with CP-style low-rank structure.</p></button>
        <button class="branch interpret" data-role="interpret"><div class="branch-icon">UWᵀ</div><div class="branch-kicker">INTERPRET</div><strong>CRAFT</strong><p>Factor activations into candidate concept directions and usage coefficients.</p></button>
        <div class="synthesis">Low-rank structure appears in several roles—through different objects and constraints.</div>
      </div>
      <div class="tk-footer"><span>Recent examples · StelLA · RAdaGrad/RAdamW · TDN · CRAFT</span><span>03</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id'),branches=[...root.querySelectorAll('[data-role]')];
          const data={
            adapt:{role:'ADAPTATION',method:'StelLA',object:'Stiefel factors U, V',why:'Learn orthonormal input/output subspaces.'},
            optimize:{role:'OPTIMIZATION',method:'RAdaGrad / RAdamW',object:'Fixed-rank weight matrix',why:'Optimize the matrix intrinsically on its manifold.'},
            architect:{role:'ARCHITECTURE',method:'Tensor Decomposition Networks',object:'CP-style tensor operator',why:'Reduce the cost of tensor-product operations.'},
            interpret:{role:'INTERPRETABILITY',method:'CRAFT',object:'Nonnegative concept directions',why:'Expose candidate directions and their usage coefficients.'}
          };
          const select=branch=>{const item=data[branch.dataset.role];branches.forEach(x=>x.classList.toggle('active',x===branch));root.querySelector('#$id-hub-role').textContent=item.role;root.querySelector('#$id-hub-method').textContent=item.method;root.querySelector('#$id-hub-object').textContent=item.object;root.querySelector('#$id-hub-why').textContent=item.why;};
          branches.forEach(branch=>branch.addEventListener('click',()=>select(branch)));select(branches[0]);
        })();
      </script>
    </div>
    """)
end

function geometry_language_visual()
    id = next_deck_id("tk-geometry-language")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id { min-height:510px; padding:24px 42px; }
        #$id .object-rail { position:relative; display:grid; grid-template-columns:repeat(5,1fr); gap:12px; margin:2px 0 18px; }
        #$id .object-rail::before { content:''; position:absolute; left:8%; right:8%; top:32px; height:2px; background:rgba(94,103,64,.22); }
        #$id .object-node { appearance:none; position:relative; z-index:2; border:0; background:transparent; color:var(--tk-muted); cursor:pointer; padding:0 4px 8px; font:inherit; text-align:center; }
        #$id .object-node::before { content:''; display:block; width:64px; height:64px; margin:0 auto 8px; border:2px solid currentColor; background:var(--tk-paper); transform:rotate(45deg) scale(.72); transition:transform .35s ease, background .3s ease, box-shadow .3s ease; }
        #$id .object-node::after { content:attr(data-glyph); position:absolute; left:50%; top:21px; transform:translateX(-50%); color:inherit; font:700 16px/1 Georgia,serif; white-space:nowrap; }
        #$id .object-node.active { color:var(--tk-terra); }
        #$id .object-node.active::before { transform:rotate(45deg) scale(.86); background:#fff8f2; box-shadow:0 8px 22px rgba(48,53,34,.12); }
        #$id .node-name { display:block; color:var(--tk-ink); font-size:14px; font-weight:820; line-height:1.15; }
        #$id .node-geometry { display:block; color:currentColor; font-size:11px; font-weight:760; margin-top:3px; }
        #$id .detail { display:grid; grid-template-columns:.86fr 1.14fr; gap:40px; align-items:center; min-height:205px; padding:16px 4px 12px; border-top:1px solid rgba(94,103,64,.18); border-bottom:1px solid rgba(94,103,64,.18); }
        #$id .formula-stage { min-height:160px; display:flex; flex-direction:column; justify-content:center; align-items:center; text-align:center; position:relative; }
        #$id .formula-stage::before { content:''; position:absolute; width:170px; height:100px; border:1px solid rgba(94,103,64,.2); transform:skew(-8deg) rotate(-2deg); background:rgba(255,253,247,.55); }
        #$id .object-formula { position:relative; z-index:1; color:var(--tk-olive-dark); font:700 clamp(1.6rem,2.7vw,2.55rem)/1.1 Georgia,serif; letter-spacing:-.03em; }
        #$id .object-kind { position:relative; z-index:1; color:var(--tk-muted); font-size:13px; font-weight:800; margin-top:12px; }
        #$id .interpret-copy { min-height:158px; display:grid; align-content:center; gap:14px; }
        #$id .detail-label { color:var(--tk-terra); font-size:12px; font-weight:900; letter-spacing:.13em; text-transform:uppercase; }
        #$id .detail strong { display:block; color:var(--tk-ink); font-size:21px; line-height:1.22; margin-top:4px; }
        #$id .detail p { color:var(--tk-muted); font-size:17px; line-height:1.35; margin:4px 0 0; }
        #$id .application-bridge { display:flex; align-items:center; gap:10px; margin-top:2px; }
        #$id .application-bridge span { color:var(--tk-terra); font-size:11px; font-weight:900; letter-spacing:.12em; text-transform:uppercase; }
        #$id .application-bridge strong { display:inline; margin:0; padding:4px 9px; border-radius:999px; background:rgba(184,92,69,.09); color:var(--tk-terra); font-size:13px; }
        #$id .shared-questions { display:grid; grid-template-columns:repeat(3,1fr); gap:24px; padding-top:15px; }
        #$id .shared-question { border-top:3px solid rgba(94,103,64,.24); padding-top:9px; color:var(--tk-ink); font-size:14px; font-weight:760; line-height:1.25; }
        #$id .shared-question span { color:var(--tk-terra); font-size:12px; font-weight:900; margin-right:7px; }
        @media(max-width:760px){#$id{padding:22px}#$id .object-rail{grid-template-columns:repeat(5,140px);overflow-x:auto}#$id .detail{grid-template-columns:1fr;gap:8px}#$id .formula-stage{min-height:110px}#$id .interpret-copy{min-height:120px}#$id .shared-questions{gap:8px}#$id .shared-question{font-size:12px}}
      </style>
      <div class="object-rail" role="tablist" aria-label="Low-rank models, objects, and constraints">
        <button class="object-node active" role="tab" aria-selected="true" data-key="frame" data-glyph="U"><span class="node-name">Orthonormal frame</span><span class="node-geometry">Stiefel</span></button>
        <button class="object-node" role="tab" aria-selected="false" data-key="matrix" data-glyph="Wᵣ"><span class="node-name">Rank-r matrix</span><span class="node-geometry">Fixed-rank</span></button>
        <button class="object-node" role="tab" aria-selected="false" data-key="rankone" data-glyph="a⊗b⊗c"><span class="node-name">Rank-one tensor</span><span class="node-geometry">Segre</span></button>
        <button class="object-node" role="tab" aria-selected="false" data-key="tucker" data-glyph="𝒢"><span class="node-name">Tucker block</span><span class="node-geometry">Mode subspaces + core</span></button>
        <button class="object-node" role="tab" aria-selected="false" data-key="nmf" data-glyph="UWᵀ"><span class="node-name">NMF concept bank</span><span class="node-geometry">Nonnegative</span></button>
      </div>
      <div class="detail">
        <div class="formula-stage"><div class="object-formula" id="$id-formula">UᵀU = I</div><div class="object-kind" id="$id-kind">ORTHONORMAL FRAME</div></div>
        <div class="interpret-copy">
          <div><div class="detail-label">Geometry / structure</div><strong id="$id-geometry">Stiefel manifold</strong><p id="$id-structure">The columns form an orthonormal coordinate frame for a subspace.</p></div>
          <div><div class="detail-label">What should we interpret?</div><strong id="$id-question">The frame—or the subspace it spans?</strong></div>
          <div class="application-bridge"><span>Why-now bridge</span><strong id="$id-bridge">StelLA</strong></div>
        </div>
      </div>
      <div class="shared-questions">
        <div class="shared-question"><span>01</span>What is the object?</div>
        <div class="shared-question"><span>02</span>Which coordinates are redundant?</div>
        <div class="shared-question"><span>03</span>What evidence makes an interpretation defensible?</div>
      </div>
      <div class="tk-footer"><span>One language · object, symmetry, evidence</span><span>10</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id');
          const data={
            frame:{formula:'UᵀU = I',kind:'ORTHONORMAL FRAME',geometry:'Stiefel manifold',structure:'The columns form an orthonormal coordinate frame for a subspace.',question:'The frame—or the subspace it spans?',bridge:'StelLA'},
            matrix:{formula:'rank(W) = r',kind:'FIXED-RANK MATRIX',geometry:'Fixed-rank manifold',structure:'The matrix W is the object; a factorization supplies non-unique coordinates.',question:'The matrix itself—or one particular pair of factors?',bridge:'RAdaGrad / RAdamW'},
            rankone:{formula:'a ⊗ b ⊗ c',kind:'RANK-ONE TENSOR',geometry:'Segre geometry',structure:'One component couples one direction from every mode.',question:'What does this complete coupled pattern represent?',bridge:'Tensor Decomposition Networks'},
            tucker:{formula:'𝒢 ×₁ U₁ ×₂ U₂ ×₃ U₃',kind:'TUCKER BLOCK',geometry:'Mode subspaces + core',structure:'Each factor selects a mode subspace; the core records their interactions.',question:'Which subspaces—and which interactions—carry meaning?',bridge:'Multilinear representation'},
            nmf:{formula:'A ≈ UWᵀ,  U,W ≥ 0',kind:'NMF CONCEPT BANK',geometry:'Nonnegative factorization',structure:'Additive directions and usage coefficients form candidate concepts.',question:'What external evidence justifies naming a direction?',bridge:'CRAFT'}
          };
          const nodes=[...root.querySelectorAll('[data-key]')];
          nodes.forEach(node=>node.addEventListener('click',()=>{
            nodes.forEach(x=>{const active=x===node;x.classList.toggle('active',active);x.setAttribute('aria-selected',active);});
            const item=data[node.dataset.key];
            root.querySelector('#$id-formula').textContent=item.formula;
            root.querySelector('#$id-kind').textContent=item.kind;
            root.querySelector('#$id-geometry').textContent=item.geometry;
            root.querySelector('#$id-structure').textContent=item.structure;
            root.querySelector('#$id-question').textContent=item.question;
            root.querySelector('#$id-bridge').textContent=item.bridge;
          }));
        })();
      </script>
    </div>
    """)
end

function ai_modes_visual()
    id = next_deck_id("tk-ai-modes")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .mode-layout { display:grid; grid-template-columns:280px 1fr; gap:46px; align-items:center; min-height:390px; }
        #$id .choices { display:flex; flex-direction:column; gap:10px; }
        #$id .choices .tk-btn { text-align:left; border-radius:14px; padding:14px 16px; }
        #$id .mode-space { position:relative; min-height:390px; display:grid; place-items:center; }
        #$id .mode-object { width:min(560px,95%); height:300px; position:relative; border-radius:48% 52% 45% 55%; background:radial-gradient(circle at 40% 34%, rgba(255,255,255,.9), rgba(167,176,139,.28) 38%, rgba(93,126,157,.18)); border:1px solid rgba(94,103,64,.24); transition:transform .3s ease; }
        #$id .mode-object.changed { transform:scale(.985); }
        #$id .axis { position:absolute; left:50%; top:50%; height:4px; transform-origin:left center; border-radius:10px; transition:opacity .25s ease, transform .35s ease; }
        #$id .axis.hidden { opacity:0; pointer-events:none; }
        #$id .axis::after { content:''; position:absolute; right:-2px; top:-5px; border-left:11px solid currentColor; border-top:7px solid transparent; border-bottom:7px solid transparent; }
        #$id .a1 { width:38%; background:var(--tk-terra); color:var(--tk-terra); transform:rotate(-12deg); }
        #$id .a2 { width:33%; background:var(--tk-blue); color:var(--tk-blue); transform:rotate(58deg); }
        #$id .a3 { width:33%; background:var(--tk-ochre); color:var(--tk-ochre); transform:rotate(130deg); }
        #$id .a4 { width:34%; background:var(--tk-olive); color:var(--tk-olive); transform:rotate(202deg); }
        #$id .a5 { width:31%; background:var(--tk-sage); color:#747d56; transform:rotate(274deg); }
        #$id .axis-label { position:absolute; z-index:2; padding:3px 7px; border-radius:7px; background:rgba(255,253,247,.82); white-space:nowrap; font-weight:820; font-size:14px; line-height:1; transition:opacity .25s ease; }
        #$id .axis-label.hidden { opacity:0; pointer-events:none; }
        #$id .lab1 { right:2%; top:40%; color:var(--tk-terra); }
        #$id .lab2 { right:10%; bottom:7%; color:var(--tk-blue); }
        #$id .lab3 { left:10%; bottom:7%; color:var(--tk-ochre); }
        #$id .lab4 { left:3%; top:26%; color:var(--tk-olive); }
        #$id .lab5 { left:50%; top:4%; color:#747d56; transform:translateX(-50%); }
        #$id .mode-count { position:absolute; left:50%; top:50%; transform:translate(-50%,-50%); width:112px; height:112px; display:grid; place-items:center; text-align:center; border-radius:50%; background:rgba(255,253,247,.9); border:1px solid rgba(94,103,64,.24); color:var(--tk-olive-dark); font-size:14px; font-weight:820; line-height:1.25; box-shadow:0 10px 30px rgba(45,50,31,.08); }
        #$id .example { position:absolute; bottom:-10px; left:0; right:0; text-align:center; color:var(--tk-muted); font-size:16px; }
        @media(max-width:760px){#$id .mode-layout{grid-template-columns:1fr}#$id .choices{flex-direction:row;overflow:auto}#$id .mode-space{min-height:300px}}
      </style>
      <div class="mode-layout">
        <div>
          <div class="tk-kicker">Choose an AI object</div>
          <div class="choices" style="margin-top:18px">
            <button class="tk-btn active" data-key="activation">Neural activations</button>
            <button class="tk-btn" data-key="attention">Attention maps</button>
            <button class="tk-btn" data-key="recommendation">Recommendations</button>
            <button class="tk-btn" data-key="science">Scientific AI</button>
          </div>
          <p class="tk-lede" style="font-size:16px;margin-top:24px">The axes are not interchangeable labels. Each one carries a different question.</p>

        </div>
        <div class="mode-space">
          <div class="mode-object">
            <div class="axis a1"></div><span class="axis-label lab1" id="$id-l1">sample</span>
            <div class="axis a2"></div><span class="axis-label lab2" id="$id-l2">layer</span>
            <div class="axis a3"></div><span class="axis-label lab3" id="$id-l3">position</span>
            <div class="axis a4"></div><span class="axis-label lab4" id="$id-l4">feature</span>
            <div class="axis a5 hidden"></div><span class="axis-label lab5 hidden" id="$id-l5"></span>
            <div class="mode-count" id="$id-count">4 meaningful<br>axes</div>
          </div>
          <div class="example" id="$id-example">Which feature activates at which position and layer, for which sample?</div>
        </div>
      </div>
      <div class="tk-footer"><span>Before reducing dimension, decide which axes should remain distinct.</span><span>02</span></div>
      <script>
        (() => {
          const root = document.getElementById('$id');
          const data = {
            activation: [['sample','layer','position','feature'],'Which feature activates at which position and layer, for which sample?'],
            attention: [['sample','layer','head','query token','key token'],'Which head connects which query token to which key token, at which layer and for which sample?'],
            recommendation: [['user','item','time','context'],'Which item is relevant to which user, at what time and in which context?'],
            science: [['simulation','time','latitude','longitude','variable'],'How does each variable evolve across latitude, longitude, and time in each simulation?']
          };
          const axes = [...root.querySelectorAll('.axis')];
          const labels = [1,2,3,4,5].map(index => root.querySelector('#$id-l'+index));
          const object = root.querySelector('.mode-object');
          root.querySelectorAll('[data-key]').forEach(button => button.addEventListener('click', () => {
            root.querySelectorAll('[data-key]').forEach(x => x.classList.toggle('active', x === button));
            const item = data[button.dataset.key];
            labels.forEach((label,index) => {
              const visible = index < item[0].length;
              axes[index].classList.toggle('hidden', !visible);
              label.classList.toggle('hidden', !visible);
              label.textContent = visible ? item[0][index] : '';
            });
            root.querySelector('#$id-count').innerHTML = item[0].length+' meaningful<br>axes';
            root.querySelector('#$id-example').textContent = item[1];
            object.classList.remove('changed'); requestAnimationFrame(() => object.classList.add('changed'));
          }));
        })();
      </script>
    </div>
    """)
end

function tensor_anatomy_visual()
    id = next_deck_id("tk-anatomy")
    values = [
        [0.18 0.31 0.42; 0.34 0.47 0.58; 0.51 0.63 0.72; 0.69 0.78 0.86; 0.88 0.96 1.05],
        [0.27 0.39 0.50; 0.43 0.56 0.67; 0.62 0.74 0.82; 0.80 0.91 0.99; 1.01 1.10 1.19],
    ]
    scale = maximum(abs, reduce(vcat, vec.(values)))
    column_html(A, j, class_name) = """
    <div class="build-column $class_name">
      $(join(["<span style=\"background:$(heat_color(A[i, j], scale))\"></span>" for i = axes(A, 1)]))
    </div>
    """
    front_columns = join([column_html(values[1], j, "col$j") for j = 1:3])
    back_columns = join([column_html(values[2], j, "col$j") for j = 1:3])
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .anatomy { display:grid; grid-template-columns:1fr 1fr; gap:48px; align-items:center; min-height:410px; }
        #$id .build-scene { position:relative; height:370px; perspective:1000px; overflow:visible; }
        #$id .construction { position:absolute; left:48%; top:46%; width:148px; height:216px; transform-style:preserve-3d; transform:translate(-50%,-50%); transition:transform 1.25s cubic-bezier(.2,.75,.18,1); }
        #$id .build-layer { position:absolute; top:0; left:0; width:148px; height:216px; box-sizing:border-box; border:2px solid var(--tk-terra); border-radius:17px; background:rgba(255,253,247,.86); box-shadow:8px 16px 30px rgba(40,44,27,.13); transform-style:preserve-3d; transition:transform 1.25s cubic-bezier(.2,.75,.18,1), opacity .7s ease, border-color .4s ease, box-shadow .4s ease, width .9s cubic-bezier(.2,.75,.18,1), left .9s cubic-bezier(.2,.75,.18,1); }
        #$id .build-column { position:absolute; top:12px; display:grid; grid-template-rows:repeat(5,36px); gap:3px; transition:transform 1s cubic-bezier(.18,.8,.2,1), opacity .6s ease; }
        #$id .build-column span { width:36px; height:36px; border-radius:7px; }
        #$id .col1 { left:12px; }
        #$id .col2 { left:56px; }
        #$id .col3 { left:100px; }
        #$id .front-layer { transform:translateZ(0); }
        #$id .back-layer { opacity:0; transform:translate(48px,36px) scale(.9); }
        #$id[data-step="1"] .front-layer { left:44px; width:60px; }
        #$id[data-step="1"] .front-layer .col2 { opacity:0; transform:translateX(70px); }
        #$id[data-step="1"] .front-layer .col3 { opacity:0; transform:translateX(130px); }
        #$id[data-step="1"] .back-layer { opacity:0; }
        #$id[data-step="2"] .build-layer { border-color:var(--tk-blue); }
        #$id[data-step="2"] .front-layer .col1,
        #$id[data-step="2"] .front-layer .col2,
        #$id[data-step="2"] .front-layer .col3 { opacity:1; transform:translateX(0); }
        #$id[data-step="2"] .back-layer { opacity:0; }
        #$id[data-step="3"] .construction { transform:translate(-50%,-50%) rotateX(58deg) rotateY(-26deg) rotateZ(-20deg) scale(.96); }
        #$id[data-step="3"] .build-layer { border-color:var(--tk-ochre); box-shadow:10px 18px 30px rgba(195,160,77,.18); }
        #$id[data-step="3"] .front-layer { transform:translateZ(34px); }
        #$id[data-step="3"] .back-layer { opacity:1; transform:translateZ(-34px); }
        #$id .build-state { position:absolute; left:0; right:0; bottom:8px; text-align:center; }
        #$id .build-state strong { display:block; color:var(--tk-olive-dark); font-size:22px; letter-spacing:-.02em; }
        #$id .build-state span { display:block; margin-top:5px; color:var(--tk-muted); font:700 13px/1.3 ui-monospace,SFMono-Regular,Menlo,monospace; }
        #$id .anatomy-copy { min-height:310px; display:flex; flex-direction:column; justify-content:center; }
        #$id .metricline { display:flex; gap:34px; margin:20px 0; }
        #$id .metricline strong { font-size:34px; color:var(--tk-olive-dark); }
        #$id .build-controls { display:grid; gap:8px; }
        #$id .build-controls .tk-btn { text-align:left; border-radius:12px; }
        @media(max-width:760px){#$id .anatomy{grid-template-columns:1fr}#$id .build-scene{height:300px}}
      </style>
      <div class="anatomy">
        <div class="build-scene" aria-label="A vector becoming a matrix and then a three-dimensional tensor">
          <div class="construction">
            <div class="build-layer back-layer">$back_columns</div>
            <div class="build-layer front-layer">$front_columns</div>
          </div>
          <div class="build-state" aria-live="polite"><strong id="$id-state">5-vector</strong><span id="$id-index">X[:, 1, 1]</span></div>
        </div>
        <div class="anatomy-copy">
          <div class="tk-kicker">5 × 3 × 2 tensor</div>
          <div class="metricline"><div><strong>3</strong><div class="tk-muted">order</div></div><div><strong>30</strong><div class="tk-muted">entries</div></div><div><strong>3</strong><div class="tk-muted">modes</div></div></div>
          <div class="build-controls">
            <button class="tk-btn active" data-step="1">Mode 1 · Build a fiber</button>
            <button class="tk-btn" data-step="2">+ Mode 2 · Form a matrix</button>
            <button class="tk-btn" data-step="3">+ Mode 3 · Stack into a tensor</button>
          </div>
          <p id="$id-copy" class="tk-lede" style="font-size:17px;margin-top:18px">Mode 1 begins with one long fiber: 5 entries while the other two indices stay fixed.</p>
        </div>
      </div>
      <div class="tk-footer"><span>Add one independent direction at a time</span><span>04</span></div>
      <script>
        (() => {
          const root = document.getElementById('$id');
          const content = {
            1:{state:'5-vector',index:'X[:, 1, 1]',copy:'Mode 1 begins with one long fiber: 5 entries while the other two indices stay fixed.'},
            2:{state:'5 × 3 matrix slice',index:'X[:, :, 1]',copy:'Mode 2 brings three 5-entry fibers together, side by side, to form one matrix slice.'},
            3:{state:'5 × 3 × 2 tensor',index:'X',copy:'Mode 3 stacks two complete 5 × 3 matrix slices in depth to complete the tensor.'}
          };
          root.dataset.step='1';
          root.querySelectorAll('[data-step]').forEach(button => button.addEventListener('click', () => {
            const step=button.dataset.step,item=content[step];
            root.dataset.step=step;
            root.querySelectorAll('[data-step]').forEach(x => x.classList.toggle('active', x===button));
            root.querySelector('#$id-state').textContent=item.state;
            root.querySelector('#$id-index').textContent=item.index;
            root.querySelector('#$id-copy').textContent=item.copy;
          }));
        })();
      </script>
    </div>
    """)
end

function flattening_visual()
    id = next_deck_id("tk-flatten")
    # A denser 4 × 5 × 4 example makes it possible to follow all 80 entries
    # as four semantic slices become four adjacent column groups.
    entries = String[]
    slice_angle = deg2rad(-8)
    slice_skew = tan(deg2rad(-6))
    for feature = 1:4, sample = 1:4, space = 1:5
        n = (feature - 1) * 20 + (sample - 1) * 5 + space
        guide_x = 37 + (feature - 1) * 29
        guide_y = 25 + (feature - 1) * 24
        local_x = 5 + (space - 1) * 18
        local_y = 5 + (sample - 1) * 18
        skewed_x = local_x + slice_skew * local_y
        tensor_x = round(guide_x + cos(slice_angle) * skewed_x - sin(slice_angle) * local_y; digits = 2)
        tensor_y = round(guide_y + sin(slice_angle) * skewed_x + cos(slice_angle) * local_y; digits = 2)
        matrix_column = (feature - 1) * 5 + space
        matrix_x = 24 + (matrix_column - 1) * 15
        matrix_y = 92 + (sample - 1) * 18
        shade = 0.48 + 0.10 * mod(sample + space, 4)
        push!(entries, """<span class="entry feature-$feature" style="--tx:$(tensor_x)px;--ty:$(tensor_y)px;--mx:$(matrix_x)px;--my:$(matrix_y)px;--n:$n;--z:$feature;--shade:$shade" aria-hidden="true"></span>""")
    end
    entries_html = join(entries)
    tensor_guides = join([
        """<span class="slice-guide sg-$feature" style="--gx:$(37 + (feature - 1) * 29)px;--gy:$(25 + (feature - 1) * 24)px"></span>"""
        for feature = 1:4
    ])
    matrix_guide = """<span class="matrix-guide"></span>"""
    Base.HTML("""
    <div id="$id" class="tk-stage" data-view="tensor">
      <style>
        #$id .flat-grid { display:grid; grid-template-columns:1fr 1fr; gap:46px; align-items:center; min-height:390px; }
        #$id .viz { min-height:300px; display:grid; place-items:center; position:relative; }
        #$id .rearrange { position:relative; width:330px; height:245px; }
        #$id .entry { position:absolute; left:0; top:0; width:13px; height:13px; border-radius:3px; opacity:var(--shade); background:var(--tk-blue); box-shadow:0 2px 5px rgba(45,50,31,.12); z-index:var(--z); transform-origin:0 0; transform:translate(var(--tx),var(--ty)) rotate(-8deg) skewX(-6deg); transition:transform 1.15s cubic-bezier(.2,.72,.2,1), background-color .75s ease, opacity .75s ease; transition-delay:calc(var(--n) * 5ms); }
        #$id .entry.feature-2 { background:var(--tk-ochre); }
        #$id .entry.feature-3 { background:var(--tk-terra); }
        #$id .entry.feature-4 { background:var(--tk-olive); }
        #$id[data-view="matrix"] .entry { opacity:.78; background:var(--tk-gray); transform:translate(var(--mx),var(--my)); }
        #$id .slice-guide, #$id .matrix-guide { position:absolute; pointer-events:none; transition:opacity .38s ease; }
        #$id .slice-guide { left:0; top:0; width:95px; height:77px; border:1.5px solid rgba(65,72,45,.34); border-radius:9px; background:rgba(255,253,247,.22); box-shadow:0 10px 22px rgba(45,50,31,.08); transform-origin:0 0; transform:translate(var(--gx),var(--gy)) rotate(-8deg) skewX(-6deg); }
        #$id .matrix-guide { left:19px; top:87px; width:308px; height:77px; border:1.5px solid rgba(65,72,45,.38); border-radius:7px; opacity:0; }
        #$id[data-view="matrix"] .slice-guide { opacity:0; }
        #$id[data-view="matrix"] .matrix-guide { opacity:1; transition-delay:.65s; }
        #$id .view-label { position:absolute; left:0; right:0; bottom:4px; color:var(--tk-muted); font-size:12px; font-weight:650; text-align:center; transition:opacity .25s ease; }
        #$id .matrix-label { opacity:0; }
        #$id[data-view="matrix"] .tensor-label { opacity:0; }
        #$id[data-view="matrix"] .matrix-label { opacity:1; transition-delay:.85s; }
        #$id .mode-equation { font-size:clamp(1.6rem,3vw,2.8rem); font-weight:780; line-height:1.25; letter-spacing:-.03em; }
        #$id .space { color:var(--tk-blue); } #$id .feature { color:var(--tk-ochre); } #$id .merged { color:var(--tk-terra); }
        #$id .entry-count { margin-top:15px; color:var(--tk-olive-dark); font-size:16px; font-weight:720; }
        #$id .loss { margin-top:24px; padding-left:16px; border-left:4px solid var(--tk-terra); color:var(--tk-muted); font-size:18px; }
        @media(max-width:760px){#$id .flat-grid{grid-template-columns:1fr}#$id .viz{min-height:250px}}
        @media(prefers-reduced-motion:reduce){#$id .entry,#$id .slice-guide,#$id .matrix-guide,#$id .view-label{transition:none!important}}
      </style>
      <div class="flat-grid">
        <div class="viz">
          <div class="rearrange" role="img" aria-label="Eighty tensor entries rearrange from four 4 by 5 slices into one 4 by 20 matrix">
            $tensor_guides
            $matrix_guide
            $entries_html
            <div class="view-label tensor-label">4 samples × 5 spaces × 4 features</div>
            <div class="view-label matrix-label">4 samples × 20 merged coordinates</div>
          </div>
        </div>
        <div>
          <div class="tk-kicker">Same 80 entries</div>
          <div class="mode-equation" id="$id-equation">sample × <span class="space">space</span> × <span class="feature">feature</span></div>
          <div class="entry-count" id="$id-count">4 × 5 × 4 = 80 entries</div>
          <div class="loss" id="$id-loss">Space and feature remain separately modeled.</div>
          <button class="tk-btn" id="$id-toggle" style="margin-top:28px">Flatten modes 2 + 3</button>
        </div>
      </div>
      <div class="tk-footer"><span>Flattening preserves entries, not mode semantics</span><span>05</span></div>
      <script>
        (() => {
          const root=document.getElementById('$id'); const button=root.querySelector('#$id-toggle');
          button.addEventListener('click',()=>{
            const matrix=root.dataset.view==='matrix'; root.dataset.view=matrix?'tensor':'matrix';
            root.querySelector('#$id-equation').innerHTML=matrix?'sample × <span class="space">space</span> × <span class="feature">feature</span>':'sample × <span class="merged">(space · feature)</span>';
            root.querySelector('#$id-count').textContent=matrix?'4 × 5 × 4 = 80 entries':'4 × 20 = 80 entries';
            root.querySelector('#$id-loss').textContent=matrix?'Space and feature remain separately modeled.':'The matrix no longer models space and feature as distinct axes.';
            button.textContent=matrix?'Flatten modes 2 + 3':'Restore the tensor';
          });
        })();
      </script>
    </div>
    """)
end

function compression_visual()
    id = next_deck_id("tk-compress")
    cpd_diagram = cpd_sum_svg("$id-cpd")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id { padding:30px 44px; }
        #$id .compress-grid { display:grid; grid-template-columns:.82fr 1.18fr; gap:52px; align-items:center; min-height:390px; }
        #$id .control { display:grid; grid-template-columns:92px 1fr 48px; gap:12px; align-items:center; margin:13px 0; }
        #$id .control label { color:var(--tk-muted); font-size:13px; font-weight:700; }
        #$id .control output { font-size:14px; font-weight:750; color:var(--tk-olive-dark); text-align:right; }
        #$id .control-note { max-width:310px; font-size:12px; line-height:1.35; }
        #$id .results { position:relative; padding-top:126px; }
        #$id .counts { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:16px; }
        #$id .count { min-width:0; padding:11px 0; border-top:2px solid rgba(94,103,64,.22); }
        #$id .count-label { display:block; min-height:28px; background:transparent !important; color:var(--tk-muted); font-size:12px; line-height:1.15; }
        #$id .count strong { display:block; white-space:nowrap; overflow-wrap:normal; color:var(--tk-olive-dark); font-size:clamp(1.1rem,1.75vw,1.55rem); font-weight:650; letter-spacing:-.025em; line-height:1.05; }
        #$id .bar { height:10px; border-radius:10px; background:rgba(94,103,64,.12); overflow:hidden; margin-top:9px; }
        #$id .bar span { display:block; height:100%; border-radius:inherit; transition:width .3s ease; }
        #$id .bar.full > span { width:100%; background:var(--tk-terra); }
        #$id .bar.cp > span { background:var(--tk-blue); }
        #$id .bar.tucker > span { background:var(--tk-olive); }
        #$id .method-notes { display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:18px; }
        #$id .method-note { padding-left:10px; color:var(--tk-muted); font-size:12px; line-height:1.35; }
        #$id .method-note.cp-note { border-left:3px solid var(--tk-blue); }
        #$id .method-note.tucker-note { border-left:3px solid var(--tk-olive); }
        #$id .method-note strong { display:block; margin-bottom:2px; color:var(--tk-ink); font-size:13px; font-weight:750; }
        #$id .comparison { margin-top:14px; color:var(--tk-ink); font-size:15px; font-weight:620; line-height:1.3; }
        #$id .comparison .cp-value { color:var(--tk-blue); }
        #$id .comparison .tucker-value { color:var(--tk-olive); }
        #$id .cp-mini { position:absolute; top:6px; right:12px; width:370px; color:var(--tk-muted); }
        #$id .cp-mini-title { margin-bottom:7px; color:var(--tk-olive-dark); font-size:11px; font-weight:750; letter-spacing:.045em; text-align:center; text-transform:uppercase; }
        #$id .cpd-sum-svg { display:block; width:100%; height:auto; }
        #$id .cp-mini-caption { display:block; margin-top:3px; font-size:10px; text-align:center; }
        @media(max-width:760px){
          #$id .compress-grid{grid-template-columns:1fr;gap:20px}
          #$id .results{padding-top:0}
          #$id .cp-mini{position:relative;top:auto;right:auto;margin:0 0 18px auto}
          #$id .counts{grid-template-columns:repeat(3,minmax(0,1fr))}
        }
      </style>
      <div class="cp-mini" role="img" aria-label="CP decomposition represents a tensor as a sum of R rank-one tensors">
        <div class="cp-mini-title">CPD = sum of rank-1 outer products</div>
        $cpd_diagram
        <span class="cp-mini-caption"><span id="$id-mini-rank">R = 4</span> linked outer products</span>
      </div>
      <div class="compress-grid">
        <div>
          <div class="tk-kicker">Adjust the ambient tensor</div>
          <div class="control"><label>samples</label><input class="tk-slider" id="$id-n1" type="range" min="8" max="64" value="32"><output id="$id-o1">32</output></div>
          <div class="control"><label>space</label><input class="tk-slider" id="$id-n2" type="range" min="8" max="64" value="32"><output id="$id-o2">32</output></div>
          <div class="control"><label>features</label><input class="tk-slider" id="$id-n3" type="range" min="4" max="32" value="16"><output id="$id-o3">16</output></div>
          <div class="control"><label>rank</label><input class="tk-slider" id="$id-r" type="range" min="1" max="12" value="4"><output id="$id-or">4</output></div>
          <p class="tk-caption control-note">The same rank r is used in each mode. CP counts include one weight per component.</p>
        </div>
        <div class="results">
          <div class="counts">
            <div class="count full tk-stat"><span class="count-label">Full tensor</span><strong id="$id-full">16,384</strong><div class="bar full"><span></span></div></div>
            <div class="count cp tk-stat"><span class="count-label">CP coordinates</span><strong id="$id-cp">388</strong><div class="bar cp"><span id="$id-cpbar"></span></div></div>
            <div class="count tucker tk-stat"><span class="count-label">Tucker coordinates</span><strong id="$id-tucker">384</strong><div class="bar tucker"><span id="$id-tbar"></span></div></div>
          </div>
          <div class="method-notes">
            <div class="method-note cp-note"><strong>CP decomposition</strong>Adds r rank-one tensors, linking one vector from every mode in each component.</div>
            <div class="method-note tucker-note"><strong>Tucker decomposition</strong>Combines three factor matrices through a small r × r × r interaction core.</div>
          </div>
          <div class="comparison">Stored coordinates — CP <span class="cp-value" id="$id-cp-ratio">2.4%</span> · Tucker <span class="tucker-value" id="$id-tucker-ratio">2.3%</span> of the full tensor.</div>
        </div>
      </div>
      <div class="tk-footer"><span>Low rank replaces ambient entries with structured coordinates</span><span>06</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id');
          const ids=['n1','n2','n3','r']; const inputs=ids.map(x=>root.querySelector('#$id-'+x));
          const fmt=x=>Math.round(x).toLocaleString();
          const update=()=>{
            const n1=+inputs[0].value,n2=+inputs[1].value,n3=+inputs[2].value,r=+inputs[3].value;
            root.querySelector('#$id-o1').textContent=n1;root.querySelector('#$id-o2').textContent=n2;root.querySelector('#$id-o3').textContent=n3;root.querySelector('#$id-or').textContent=r;
            const full=n1*n2*n3, cp=r*(1+n1+n2+n3), tucker=r*r*r+r*(n1+n2+n3);
            root.querySelector('#$id-full').textContent=fmt(full);root.querySelector('#$id-cp').textContent=fmt(cp);root.querySelector('#$id-tucker').textContent=fmt(tucker);
            root.querySelector('#$id-cpbar').style.width=Math.min(100,100*cp/full)+'%';root.querySelector('#$id-tbar').style.width=Math.min(100,100*tucker/full)+'%';
            root.querySelector('#$id-cp-ratio').textContent=(100*cp/full).toFixed(1)+'%';
            root.querySelector('#$id-tucker-ratio').textContent=(100*tucker/full).toFixed(1)+'%';
            root.querySelector('#$id-mini-rank').textContent='R = '+r;
          };
          inputs.forEach(x=>x.addEventListener('input',update));update();
        })();
      </script>
    </div>
    """)
end

function cp_linked_visual()
    id = next_deck_id("tk-cp-linked")
    outer_diagram = cp_component_outer_svg("$id-outer")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .cp-grid { display:grid; grid-template-columns:1fr 1.05fr; gap:48px; align-items:center; min-height:390px; }
        #$id .profiles { display:grid; gap:24px; }
        #$id .profile-row { display:grid; grid-template-columns:90px 1fr; gap:14px; align-items:end; }
        #$id .profile-label { font-weight:800; color:var(--tk-muted); }
        #$id .bars { display:flex; gap:6px; height:64px; align-items:end; border-bottom:1px solid rgba(94,103,64,.22); }
        #$id .bars span { flex:1; min-width:8px; border-radius:5px 5px 0 0; background:var(--component); transition:height .3s ease; }
        #$id .component-side { display:grid; place-items:center; }
        #$id .outer-product { width:min(500px,100%); padding:14px 10px 8px; border:1px solid rgba(94,103,64,.18); border-radius:22px; background:rgba(255,253,247,.68); }
        #$id .component-outer-svg { display:block; width:100%; height:auto; overflow:visible; }
        #$id .component-outer-svg [data-segment] { stroke:var(--component); stroke-width:1.2; transition:opacity .3s ease; }
        #$id .outer-product-label { margin-top:-2px; color:var(--tk-muted); font-size:12px; font-weight:750; letter-spacing:.08em; text-align:center; text-transform:uppercase; }
        #$id .component-title { font-size:30px; font-weight:830; margin-top:8px; color:var(--component); }
        @media(max-width:760px){#$id .cp-grid{grid-template-columns:1fr}#$id .outer-product{max-width:430px}}
      </style>
      <div class="cp-grid">
        <div>
          <div class="tk-kicker">Select one rank-one term</div>
          <div class="tk-btnrow" style="margin:18px 0 28px">
            <button class="tk-btn active" data-component="0">Component 1</button><button class="tk-btn" data-component="1">Component 2</button><button class="tk-btn" data-component="2">Component 3</button>
          </div>
          <div class="profiles">
            <div class="profile-row"><div class="profile-label">sample</div><div class="bars" data-profile="sample"></div></div>
            <div class="profile-row"><div class="profile-label">space</div><div class="bars" data-profile="space"></div></div>
            <div class="profile-row"><div class="profile-label">feature</div><div class="bars" data-profile="feature"></div></div>
          </div>
        </div>
        <div class="component-side">
          <div class="outer-product">
            $outer_diagram
            <div class="outer-product-label">three vectors form one rank-1 tensor</div>
          </div>
          <div class="component-title" id="$id-title">a₁ ⊗ b₁ ⊗ c₁</div>
          <div class="tk-caption">One component links one profile from every mode.</div>
        </div>
      </div>
      <div class="tk-footer"><span>CP: shared components across every mode</span><span>07</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id');
          const components=[
            {color:'#c96f4a',sample:[.15,.5,1,.65,.2],space:[.1,.3,.75,1,.55,.2],feature:[1,.7,.25,.12]},
            {color:'#5d7e9d',sample:[.8,1,.55,.2,.1],space:[1,.65,.2,.15,.5,.8],feature:[.2,.45,1,.7]},
            {color:'#c3a04d',sample:[.1,.25,.5,.9,1],space:[.2,.45,.8,1,.7,.3],feature:[.65,1,.55,.2]}
          ];
          const draw=(index)=>{
            const item=components[index]; root.style.setProperty('--component',item.color);
            ['sample','space','feature'].forEach(name=>{
              const bars=root.querySelector('[data-profile="'+name+'"]');bars.innerHTML='';
              item[name].forEach(value=>{const span=document.createElement('span');span.style.height=(8+value*56)+'px';bars.appendChild(span);});
              root.querySelectorAll('[data-vector="'+name+'"] [data-segment]').forEach((segment,i)=>segment.style.opacity=.18+.82*item[name][i]);
            });
            root.querySelector('#$id-title').textContent='a'+String.fromCharCode(8321+index)+' ⊗ b'+String.fromCharCode(8321+index)+' ⊗ c'+String.fromCharCode(8321+index);
          };
          root.querySelectorAll('[data-component]').forEach(button=>button.addEventListener('click',()=>{root.querySelectorAll('[data-component]').forEach(x=>x.classList.toggle('active',x===button));draw(+button.dataset.component);}));draw(0);
        })();
      </script>
    </div>
    """)
end

function tucker_rank_visual(errors::AbstractDict, dims::NTuple{3,Int})
    id = next_deck_id("tk-tucker-rank")
    error_entries = join(
        ["'$(r[1])-$(r[2])-$(r[3])':$(round(value; sigdigits=7))" for (r, value) in sort(collect(errors); by=first)],
        ",",
    )
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .tucker-grid { display:grid; grid-template-columns:.9fr 1.1fr; gap:54px; align-items:center; min-height:390px; }
        #$id .rank-control { display:grid; grid-template-columns:88px 1fr 42px; gap:12px; margin:17px 0; align-items:center; }
        #$id .rank-control label { color:var(--tk-muted); font-weight:800; }
        #$id .rank-control output { font-weight:900; color:var(--tk-olive); font-size:22px; text-align:right; }
        #$id .rank-track { min-width:0; }
        #$id .rank-track .tk-slider { width:100%; }
        #$id .rank-ticks { display:flex; justify-content:space-between; padding:1px 3px 0; color:var(--tk-muted); font-size:9px; font-weight:700; }
        #$id .tucker-viz { --f1-thickness:18px; --f2-thickness:18px; --f3-thickness:18px; --f1-band:6px; --f2-band:6px; --f3-band:6px; --f1-radius:10px; --f2-radius:10px; --f3-radius:10px; position:relative; min-height:330px; display:grid; place-items:center; }
        #$id .core-wrap { position:relative; width:155px; height:155px; display:grid; place-items:center; }
        #$id .core-shape { --core-w:51px; --core-h:51px; --core-depth:12px; width:var(--core-w); height:var(--core-h); border-radius:clamp(5px,calc(var(--core-w) * .18),16px); background:linear-gradient(145deg,var(--tk-olive),var(--tk-olive-dark)); box-shadow:var(--core-depth) var(--core-depth) 0 rgba(195,160,77,.22); transition:width .45s cubic-bezier(.2,.75,.2,1),height .45s cubic-bezier(.2,.75,.2,1),box-shadow .45s ease,border-radius .45s ease; }
        #$id .core-label { position:absolute; left:50%; top:calc(50% + 91px); transform:translateX(-50%); color:var(--tk-olive-dark); font-size:14px; font-weight:800; white-space:nowrap; }
        #$id .factor { position:absolute; opacity:.82; overflow:hidden; transition:width .45s ease,height .45s ease,border-radius .45s ease; }
        #$id .factor::after { content:''; position:absolute; inset:0; pointer-events:none; opacity:.72; }
        #$id .f1 { width:220px; height:var(--f1-thickness); border-radius:var(--f1-radius); background:var(--tk-terra); top:24px; left:50%; transform:translateX(-50%); }
        #$id .f1::after { background:repeating-linear-gradient(to bottom,transparent 0 calc(var(--f1-band) - 1px),rgba(255,253,247,.72) calc(var(--f1-band) - 1px) var(--f1-band)); }
        #$id .f2 { width:var(--f2-thickness); height:160px; border-radius:var(--f2-radius); background:var(--tk-blue); left:65px; top:50%; transform:translateY(-50%); }
        #$id .f2::after { background:repeating-linear-gradient(to right,transparent 0 calc(var(--f2-band) - 1px),rgba(255,253,247,.72) calc(var(--f2-band) - 1px) var(--f2-band)); }
        #$id .f3 { width:var(--f3-thickness); height:135px; border-radius:var(--f3-radius); background:var(--tk-ochre); left:calc(50% + 120px); top:50%; transform-origin:left center; transform:translateY(-50%) rotate(32deg); }
        #$id .f3::after { background:repeating-linear-gradient(to right,transparent 0 calc(var(--f3-band) - 1px),rgba(255,253,247,.72) calc(var(--f3-band) - 1px) var(--f3-band)); }
        #$id .factor-dim { position:absolute; color:var(--tk-muted); font-size:11px; font-weight:700; white-space:nowrap; }
        #$id .d1 { top:2px; left:50%; transform:translateX(-50%); color:var(--tk-terra); }
        #$id .d2 { left:3px; top:50%; transform:translateY(-50%) rotate(-90deg); color:var(--tk-blue); }
        #$id .d3 { left:calc(50% + 104px); top:76px; color:var(--tk-ochre); }
        #$id .metrics { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:22px; margin-top:18px; text-align:center; }
        #$id .metrics strong { display:block; font-size:26px; color:var(--tk-olive-dark); white-space:nowrap; }
        #$id .ratio-formula { margin-top:10px; color:var(--tk-muted); font-size:12px; font-weight:650; text-align:center; }
        @media(prefers-reduced-motion:reduce){#$id .core-shape,#$id .factor{transition:none!important}}
        @media(max-width:760px){#$id .tucker-grid{grid-template-columns:1fr}}
      </style>
      <div class="tucker-grid">
        <div>
          <div class="tk-kicker">Choose one rank per mode</div>
          <div class="rank-control"><label>sample r₁</label><div class="rank-track"><input class="tk-slider" id="$id-r1" type="range" min="0" max="3" step="1" value="2"><div class="rank-ticks"><span>1</span><span>2</span><span>3</span><span>5</span></div></div><output id="$id-o1">3</output></div>
          <div class="rank-control"><label>space r₂</label><div class="rank-track"><input class="tk-slider" id="$id-r2" type="range" min="0" max="3" step="1" value="1"><div class="rank-ticks"><span>1</span><span>2</span><span>3</span><span>5</span></div></div><output id="$id-o2">2</output></div>
          <div class="rank-control"><label>feature r₃</label><div class="rank-track"><input class="tk-slider" id="$id-r3" type="range" min="0" max="3" step="1" value="1"><div class="rank-ticks"><span>1</span><span>2</span><span>3</span><span>5</span></div></div><output id="$id-o3">2</output></div>
          <p class="tk-lede" style="font-size:18px">The core records how the three mode subspaces interact.</p>
        </div>
        <div>
          <div class="tucker-viz" id="$id-viz" role="img" aria-label="Tucker core and three factor matrices change thickness with the selected multilinear ranks">
            <div class="factor f1"></div><div class="factor-dim d1" id="$id-d1">U₁ · $(dims[1]) × 3</div>
            <div class="factor f2"></div><div class="factor-dim d2" id="$id-d2">U₂ · $(dims[2]) × 2</div>
            <div class="factor f3"></div><div class="factor-dim d3" id="$id-d3">U₃ · $(dims[3]) × 2</div>
            <div class="core-wrap"><div class="core-shape" id="$id-core-shape"></div><div class="core-label" id="$id-core">core · 3 × 2 × 2</div></div>
          </div>
          <div class="metrics">
            <div><strong id="$id-params">135</strong><div class="tk-caption">stored coordinates</div></div>
            <div><strong id="$id-ratio">9.3×</strong><div class="tk-caption">compression ratio</div></div>
            <div><strong id="$id-error">0.020</strong><div class="tk-caption">ST-HOSVD relative error</div></div>
          </div>
          <div class="ratio-formula" id="$id-ratio-formula">1,260 full entries ÷ 135 stored = 9.3×</div>
        </div>
      </div>
      <div class="tk-footer"><span>Tucker: different compression for different modes</span><span>08</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id'), errors={$error_entries}, dims=[$(dims[1]),$(dims[2]),$(dims[3])], levels=[1,2,3,5], full=dims[0]*dims[1]*dims[2];
          const sliders=[1,2,3].map(i=>root.querySelector('#$id-r'+i));
          const update=()=>{
            const r=sliders.map(x=>levels[+x.value]);r.forEach((x,i)=>root.querySelector('#$id-o'+(i+1)).textContent=x);
            const core=root.querySelector('#$id-core-shape'), viz=root.querySelector('#$id-viz');
            core.style.setProperty('--core-w',(18+11*r[1])+'px');
            core.style.setProperty('--core-h',(18+11*r[0])+'px');
            core.style.setProperty('--core-depth',(3+3*r[2])+'px');
            r.forEach((rank,i)=>{
              const thickness=3+5*rank, mode=i+1;
              viz.style.setProperty('--f'+mode+'-thickness',thickness+'px');
              viz.style.setProperty('--f'+mode+'-band',(thickness/rank)+'px');
              viz.style.setProperty('--f'+mode+'-radius',rank===1?'999px':rank===3?'10px':'5px');
            });
            root.querySelector('#$id-core').textContent='core · '+r.join(' × ');
            root.querySelector('#$id-d1').textContent='U₁ · '+dims[0]+' × '+r[0];
            root.querySelector('#$id-d2').textContent='U₂ · '+dims[1]+' × '+r[1];
            root.querySelector('#$id-d3').textContent='U₃ · '+dims[2]+' × '+r[2];
            const params=r[0]*r[1]*r[2]+dims[0]*r[0]+dims[1]*r[1]+dims[2]*r[2];
            root.querySelector('#$id-params').textContent=params.toLocaleString();
            const ratio=full/params;
            root.querySelector('#$id-ratio').textContent=ratio.toFixed(1)+'×';
            root.querySelector('#$id-ratio-formula').textContent=full.toLocaleString()+' full entries ÷ '+params.toLocaleString()+' stored = '+ratio.toFixed(1)+'×';
            const error=errors[r.join('-')];root.querySelector('#$id-error').textContent=error.toFixed(3);
          };sliders.forEach(x=>x.addEventListener('input',update));update();
        })();
      </script>
    </div>
    """)
end

function model_assumption_visual()
    id = next_deck_id("tk-models")
    cp_diagram = cp_model_abstract_svg()
    nncp_diagram = cp_model_abstract_svg(; nonnegative = true)
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .model-layout { min-height:390px; display:grid; grid-template-rows:auto 1fr; gap:28px; }
        #$id .model-main { display:grid; grid-template-columns:minmax(0,1.25fr) minmax(175px,.75fr); gap:28px; align-items:center; }
        #$id .model-main > * { min-width:0; }
        #$id .model-visual { min-width:0; display:grid; grid-template-rows:auto 1fr; align-content:center; }
        #$id .model-name { margin-bottom:8px; font-size:clamp(2.2rem,3.4vw,3.5rem); font-weight:850; color:var(--tk-olive-dark); letter-spacing:-.055em; }
        #$id .model-glyph { min-height:210px; position:relative; display:grid; place-items:center; }
        #$id .glyph-core { width:90px; height:90px; border-radius:22px; background:var(--tk-olive); box-shadow:60px -38px 0 rgba(93,126,157,.45),-62px 34px 0 rgba(201,111,74,.45); transition:all .3s ease; }
        #$id .model-decomp-glyph { display:none; width:min(330px,100%); }
        #$id .cp-model-abstract-svg { display:block; width:100%; height:auto; overflow:visible; }
        #$id .model-copy strong { display:block; font-size:clamp(1.35rem,2.4vw,2.4rem); line-height:1.08; color:var(--tk-ink); letter-spacing:-.035em; }
        #$id .model-copy p { color:var(--tk-muted); font-size:16px; line-height:1.4; }
        #$id[data-model="cp"] .glyph-core,#$id[data-model="nncp"] .glyph-core { display:none; }
        #$id[data-model="cp"] .cp-model-glyph { display:block; }
        #$id[data-model="nncp"] .nncp-model-glyph { display:block; }
        #$id[data-model="tucker"] .glyph-core { width:100px;height:100px;box-shadow:70px 0 0 rgba(93,126,157,.36),0 70px 0 rgba(201,111,74,.36); }
        #$id[data-model="btd"] .glyph-core { width:62px;height:62px;box-shadow:78px 0 0 var(--tk-blue),-78px 0 0 var(--tk-terra); }
        @media(max-width:760px){#$id .model-main{grid-template-columns:1fr}#$id .model-glyph{min-height:190px}}
      </style>
      <div class="model-layout">
        <div class="tk-btnrow">
          <button class="tk-btn active" data-model="cp">CP</button><button class="tk-btn" data-model="tucker">Tucker</button><button class="tk-btn" data-model="btd">BTD</button><button class="tk-btn" data-model="nncp">NNCPD</button>
        </div>
        <div class="model-main">
          <div class="model-visual">
            <div class="model-name" id="$id-name">CP</div>
            <div class="model-glyph">
              <div class="glyph-core"></div>
              <div class="model-decomp-glyph cp-model-glyph">$cp_diagram</div>
              <div class="model-decomp-glyph nncp-model-glyph">$nncp_diagram</div>
            </div>
          </div>
          <div class="model-copy"><div class="tk-kicker" id="$id-block">rank-one terms</div><strong id="$id-promise">One component links every mode.</strong><p id="$id-caution">Scaling and component order remain ambiguous.</p></div>
        </div>
      </div>
      <div class="tk-footer"><span>A model name is a structural assumption</span><span>09</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id');const data={
            cp:['CP','rank-one terms','One component links every mode.','Scaling and component order remain ambiguous.'],
            tucker:['Tucker','one interacting core','Each mode gets its own subspace.','Core entries depend on the chosen bases.'],
            btd:['BTD','a sum of small Tucker blocks','Each block can contain internal multilinear variation.','Blocks carry Tucker gauges and may permute.'],
            nncp:['NNCPD','nonnegative rank-one terms','Nonnegative factors support an additive representation.','Additivity does not by itself make a component a semantic part.']
          };
          const draw=key=>{root.dataset.model=key;const x=data[key];root.querySelector('#$id-name').textContent=x[0];root.querySelector('#$id-block').textContent=x[1];root.querySelector('#$id-promise').textContent=x[2];root.querySelector('#$id-caution').textContent=x[3];};
          root.querySelectorAll('[data-model]').forEach(button=>button.addEventListener('click',()=>{root.querySelectorAll('[data-model]').forEach(x=>x.classList.toggle('active',x===button));draw(button.dataset.model);}));draw('cp');
        })();
      </script>
    </div>
    """)
end

function gauge_geometry_visual(X::AbstractMatrix)
    id = next_deck_id("tk-gauge")
    map = heatmap_html(X; cell=18, radius=3)

    decomposition = svd(X)
    retained = min(2, length(decomposition.S))
    root_singular_values = sqrt.(decomposition.S[1:retained])
    A = decomposition.U[:, 1:retained] * Diagonal(root_singular_values)
    B = decomposition.V[:, 1:retained] * Diagonal(root_singular_values)
    if retained == 1
        A = hcat(A, zeros(size(A, 1)))
        B = hcat(B, zeros(size(B, 1)))
    end

    angle = 0.92
    transformations = [
        (key = "identity", label = "Original coordinates", note = "Start from one pair of factor coordinates.", Q = Matrix{Float64}(I, 2, 2)),
        (key = "rotate", label = "Rotate Q", note = "Both coordinate clouds rotate, while their product stays fixed.", Q = [cos(angle) -sin(angle); sin(angle) cos(angle)]),
        (key = "shear", label = "Shear Q", note = "A leans one way and B compensates in the inverse direction.", Q = [1.0 1.05; 0.0 1.0]),
        (key = "stretch", label = "Stretch Q", note = "One coordinate direction expands while the paired factor contracts.", Q = [1.85 0.0; 0.0 0.55]),
    ]

    transformed = [
        (
            item.key,
            A * item.Q,
            B * inv(item.Q)',
            item.label,
            item.note,
        )
        for item in transformations
    ]
    max_coordinate = maximum(
        abs,
        vcat([vec(item[2]) for item in transformed]..., [vec(item[3]) for item in transformed]...);
        init = 1.0,
    )
    coordinate_scale = 65 / max_coordinate

    js_matrix(M) = "[" * join(
        ["[" * join([@sprintf("%.8f", value) for value in row], ",") * "]" for row in eachrow(M)],
        ",",
    ) * "]"
    variant_data = join(
        [
            "'$(item[1])':{A:$(js_matrix(item[2])),B:$(js_matrix(item[3])),label:'$(item[4])',note:'$(item[5])'}"
            for item in transformed
        ],
        ",",
    )
    marks(n, color) = join([
        """<g class="coord-mark" data-index="$(i - 1)" style="--mark:$color"><line x1="120" y1="82" x2="120" y2="82"></line><circle cx="120" cy="82" r="4.5"></circle></g>"""
        for i = 1:n
    ])
    a_marks = marks(size(A, 1), "var(--tk-terra)")
    b_marks = marks(size(B, 1), "var(--tk-blue)")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .gauge-grid { display:grid; grid-template-columns:1.18fr .82fr; gap:34px; align-items:center; min-height:390px; }
        #$id .q-controls { display:flex; flex-wrap:wrap; gap:8px; margin:12px 0 14px; }
        #$id .factor-plots { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
        #$id .factor-plot { min-width:0; text-align:center; }
        #$id .factor-plot strong { display:block; margin-bottom:2px; color:var(--tk-olive-dark); font-size:13px; }
        #$id .factor-plot span { display:block; margin-bottom:4px; color:var(--tk-muted); font-size:10px; }
        #$id .coord-svg { display:block; width:100%; height:auto; overflow:visible; }
        #$id .coord-axis { stroke:rgba(94,103,64,.24); stroke-width:1; }
        #$id .coord-mark line { stroke:var(--mark); stroke-width:2; opacity:.5; }
        #$id .coord-mark circle { fill:var(--mark); stroke:var(--tk-paper); stroke-width:1.5; }
        #$id .q-note { min-height:38px; margin-top:7px; color:var(--tk-muted); font-size:13px; line-height:1.35; }
        #$id .matrix-fixed { display:grid; place-items:center; padding:18px 12px; border-radius:22px; background:rgba(255,253,247,.8); }
        #$id .matrix-compare { display:grid; grid-template-columns:1fr auto 1fr; gap:8px; align-items:center; margin:16px 0 13px; }
        #$id .matrix-copy { display:grid; place-items:center; }
        #$id .matrix-copy small { margin-bottom:5px; color:var(--tk-muted); font-size:10px; font-weight:750; }
        #$id .equals { color:var(--tk-olive); font-size:28px; font-weight:850; }
        #$id .after-map { position:relative; border-radius:10px; transition:box-shadow .28s ease,transform .28s ease; }
        #$id .after-map.changed { box-shadow:0 0 0 4px rgba(94,103,64,.18); transform:scale(1.025); }
        #$id .unchanged { color:var(--tk-olive-dark); font-size:18px; font-weight:850; text-align:center; }
        #$id .change-error { margin-top:4px; color:var(--tk-muted); font-size:11px; text-align:center; }
        #$id .gauge-formula { margin-top:12px; color:var(--tk-muted); font-size:13px; font-weight:650; text-align:center; }
        @media(prefers-reduced-motion:reduce){#$id .after-map{transition:none!important}}
        @media(max-width:760px){#$id .gauge-grid{grid-template-columns:1fr}#$id .factor-plots{grid-template-columns:1fr 1fr}}
      </style>
      <div class="gauge-grid">
        <div>
          <div class="tk-kicker">Choose an invertible coordinate change · Q ∈ GL(2)</div>
          <div class="q-controls">
            <button class="tk-btn active" data-q="identity">Original</button>
            <button class="tk-btn" data-q="rotate">Rotate</button>
            <button class="tk-btn" data-q="shear">Shear</button>
            <button class="tk-btn" data-q="stretch">Stretch</button>
          </div>
          <div class="factor-plots">
            <div class="factor-plot"><strong>A′ = AQ</strong><span>rows of the first factor</span><svg class="coord-svg plot-a" viewBox="0 0 240 164" role="img" aria-label="Rows of A after the selected coordinate change"><line class="coord-axis" x1="16" y1="82" x2="224" y2="82"></line><line class="coord-axis" x1="120" y1="10" x2="120" y2="154"></line>$a_marks</svg></div>
            <div class="factor-plot"><strong>B′ = BQ⁻ᵀ</strong><span>compensating factor coordinates</span><svg class="coord-svg plot-b" viewBox="0 0 240 164" role="img" aria-label="Rows of B after the compensating inverse coordinate change"><line class="coord-axis" x1="16" y1="82" x2="224" y2="82"></line><line class="coord-axis" x1="120" y1="10" x2="120" y2="154"></line>$b_marks</svg></div>
          </div>
          <div class="q-note"><strong id="$id-q-label">Original coordinates</strong> · <span id="$id-q-note">Start from one pair of factor coordinates.</span></div>
        </div>
        <div class="matrix-fixed">
          <div class="tk-kicker">The represented object</div>
          <div class="matrix-compare">
            <div class="matrix-copy"><small>before · X</small>$map</div>
            <div class="equals">=</div>
            <div class="matrix-copy"><small>after · X(Q)</small><div class="after-map">$map</div></div>
          </div>
          <div class="unchanged">✓ Same matrix X</div>
          <div class="change-error">relative change ≈ 0</div>
          <div class="gauge-formula">A′B′ᵀ = (AQ)(BQ⁻ᵀ)ᵀ = ABᵀ</div>
        </div>
      </div>
      <div class="tk-footer"><span>The parameterization determines which coordinates are equivalent</span><span>11</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id'),data={$variant_data},scale=$(@sprintf("%.8f", coordinate_scale));
          const panels={A:root.querySelector('.plot-a'),B:root.querySelector('.plot-b')};
          const current={A:data.identity.A.map(p=>p.slice()),B:data.identity.B.map(p=>p.slice())};
          let animation=0;
          const paint=(name,points)=>{
            const marks=[...panels[name].querySelectorAll('.coord-mark')];
            points.forEach((point,index)=>{
              const x=120+scale*point[0],y=82-scale*point[1],mark=marks[index];
              const line=mark.querySelector('line'),circle=mark.querySelector('circle');
              line.setAttribute('x2',x);line.setAttribute('y2',y);circle.setAttribute('cx',x);circle.setAttribute('cy',y);
            });
          };
          const draw=key=>{
            const target=data[key],start={A:current.A.map(p=>p.slice()),B:current.B.map(p=>p.slice())},token=++animation,begin=performance.now();
            root.querySelectorAll('[data-q]').forEach(button=>button.classList.toggle('active',button.dataset.q===key));
            root.querySelector('#$id-q-label').textContent=target.label;root.querySelector('#$id-q-note').textContent=target.note;
            const after=root.querySelector('.after-map');after.classList.remove('changed');requestAnimationFrame(()=>after.classList.add('changed'));
            const frame=now=>{
              if(token!==animation)return;
              const raw=Math.min(1,(now-begin)/650),t=1-Math.pow(1-raw,3);
              ['A','B'].forEach(name=>{current[name]=start[name].map((point,i)=>[point[0]+(target[name][i][0]-point[0])*t,point[1]+(target[name][i][1]-point[1])*t]);paint(name,current[name]);});
              if(raw<1)requestAnimationFrame(frame);
            };requestAnimationFrame(frame);
          };
          root.querySelectorAll('[data-q]').forEach(button=>button.addEventListener('click',()=>draw(button.dataset.q)));
          paint('A',current.A);paint('B',current.B);
        })();
      </script>
    </div>
    """)
end

function validation_visual()
    id = next_deck_id("tk-validation")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .validation { min-height:390px; display:grid; grid-template-rows:1fr auto; }
        #$id .path { display:grid; grid-template-columns:repeat(4,1fr); gap:10px; align-items:start; position:relative; padding-top:70px; }
        #$id .path::before { content:'';position:absolute;left:9%;right:9%;top:108px;height:3px;background:rgba(94,103,64,.18); }
        #$id .checkpoint { position:relative;text-align:center;opacity:.25;transform:translateY(10px);transition:opacity .35s ease,transform .35s ease; }
        #$id .checkpoint.active { opacity:1;transform:none; }
        #$id .dot { width:78px;height:78px;border-radius:50%;display:grid;place-items:center;margin:0 auto 18px;background:var(--tk-paper);border:3px solid var(--tk-sage);font-size:28px;font-weight:900;position:relative;z-index:2; }
        #$id .checkpoint.active .dot { background:var(--tk-olive);color:white;border-color:var(--tk-olive); }
        #$id .checkpoint strong { font-size:17px;display:block; }
        #$id .checkpoint span { color:var(--tk-muted);font-size:12px;line-height:1.35;display:block;margin-top:7px; }
        #$id .answer { text-align:center;font-size:clamp(1.5rem,3vw,3rem);font-weight:830;letter-spacing:-.035em;min-height:60px;color:var(--tk-terra); }
      </style>
      <div class="validation">
        <div>
          <div class="path">
            <div class="checkpoint active"><div class="dot">1</div><strong>Fit</strong><span>Does the model reconstruct the selected object?</span></div>
            <div class="checkpoint"><div class="dot">2</div><strong>Well-definedness</strong><span>What remains determined after known equivalences are accounted for?</span></div>
            <div class="checkpoint"><div class="dot">3</div><strong>Numerical reliability</strong><span>Is it well-conditioned and stable across perturbations, starts, or reasonable solvers?</span></div>
            <div class="checkpoint"><div class="dot">4</div><strong>External validation</strong><span>Does the meaning generalize to held-out behavior or survive a controlled intervention?</span></div>
          </div>
          <div class="answer" id="$id-answer">Low error starts the investigation.</div>
        </div>
        <div class="tk-btnrow" style="justify-content:center"><button class="tk-btn" id="$id-next">▶ Ask the next question</button><button class="tk-btn" id="$id-reset">Reset</button></div>
      </div>
      <div class="tk-footer"><span>Fit is necessary—not sufficient—for interpretation</span><span>12</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id'),steps=[...root.querySelectorAll('.checkpoint')],messages=['Reconstruction fit starts the investigation.','Interpret only what remains well-defined after known equivalences.','Conditioning and stability determine whether the numerical result is reliable.','Meaning needs held-out behavioral evidence or a controlled intervention.'];let index=0;
          const draw=()=>{steps.forEach((x,i)=>x.classList.toggle('active',i<=index));root.querySelector('#$id-answer').textContent=messages[index];root.querySelector('#$id-next').disabled=index===3;};
          root.querySelector('#$id-next').addEventListener('click',()=>{index=Math.min(3,index+1);draw();});root.querySelector('#$id-reset').addEventListener('click',()=>{index=0;draw();});draw();
        })();
      </script>
    </div>
    """)
end

function closing_visual()
    id = next_deck_id("tk-closing")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id { min-height:500px; display:grid; place-items:center; padding:26px 44px; }
        #$id .closing { width:min(920px,100%); text-align:center; }
        #$id .question-row { display:grid;grid-template-columns:repeat(3,1fr);gap:22px;margin:24px 0; }
        #$id .question { padding:18px 16px;border-top:3px solid rgba(94,103,64,.2);transition:border-color .25s ease,transform .25s ease;cursor:pointer; }
        #$id .question:hover,#$id .question.active { border-color:var(--tk-terra);transform:translateY(-4px); }
        #$id .question strong { font-size:22px;display:block;color:var(--tk-olive-dark); }
        #$id .question span { display:block;color:var(--tk-muted);font-size:15px;margin-top:8px; }
        #$id .closing-answer { min-height:58px;font-size:clamp(1.5rem,2.7vw,2.7rem);font-weight:820;letter-spacing:-.03em;color:var(--tk-terra); }
        @media(max-width:760px){#$id .question-row{grid-template-columns:1fr}}
      </style>
      <div class="closing">
        <div class="tk-kicker">Three questions for every decomposition</div>
        <div class="question-row">
          <div class="question active" data-q="0"><strong>Structure</strong><span>What smaller object could generate the data?</span></div>
          <div class="question" data-q="1"><strong>Symmetry</strong><span>Which coordinate changes preserve that object?</span></div>
          <div class="question" data-q="2"><strong>Evidence</strong><span>How will the interpretation be tested?</span></div>
        </div>
        <div class="closing-answer" id="$id-answer">Low rank proposes a smaller generative structure.</div>
        <div class="tk-display" style="font-size:clamp(1.35rem,2.2vw,2.65rem);margin-top:22px">The decomposition proposes structure. Geometry tells us what is invariant. Interpretation needs evidence.</div>
      </div>
      <div class="tk-footer"><span>Continue with Labs 1–4</span><span>13</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id'),answers=['Low rank proposes a smaller generative structure.','Geometry tells us which descriptions represent the same object.','Interpretation becomes credible only when predictions survive external tests.'];
          root.querySelectorAll('[data-q]').forEach(item=>item.addEventListener('click',()=>{root.querySelectorAll('[data-q]').forEach(x=>x.classList.toggle('active',x===item));root.querySelector('#$id-answer').textContent=answers[+item.dataset.q];}));
        })();
      </script>
    </div>
    """)
end

end
