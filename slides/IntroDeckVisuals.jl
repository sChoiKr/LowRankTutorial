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
       hero_visual,
       model_assumption_visual,
       tensor_anatomy_visual,
       tucker_rank_visual,
       validation_visual

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
      .tk-footer { position: absolute; left: 48px; right: 48px; bottom: 22px; display: flex; justify-content: space-between; color: #858978; font-size: 12px; }
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
          <div class="tk-btnrow" style="margin-top:12px"><button class="tk-btn" type="button">▶ Assemble the tensor</button><span class="assembly-state">7 slices separated</span><span class="tk-caption">Se Eun Choi · TensorKitchen tutorial</span></div>
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
          <p class="tk-lede" style="font-size:18px;margin-top:24px">The axes are not interchangeable labels. Each one carries a different question.</p>
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
      <div class="tk-footer"><span>Multiway data keeps its semantic axes</span><span>02</span></div>
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
        [0.26 0.26; 0.41 0.59; 0.60 0.26],
        [0.53 0.52; 0.82 1.19; 1.19 0.52],
    ]
    scale = maximum(abs, reduce(vcat, vec.(values)))
    column_html(A, j, class_name) = """
    <div class="build-column $class_name">
      $(join(["<span style=\"background:$(heat_color(A[i, j], scale))\"></span>" for i = axes(A, 1)]))
    </div>
    """
    front_columns = column_html(values[1], 1, "col1") * column_html(values[1], 2, "col2")
    back_columns = column_html(values[2], 1, "col1") * column_html(values[2], 2, "col2")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .anatomy { display:grid; grid-template-columns:1fr 1fr; gap:48px; align-items:center; min-height:390px; }
        #$id .build-scene { position:relative; height:340px; perspective:900px; overflow:visible; }
        #$id .construction { position:absolute; left:48%; top:45%; width:114px; height:154px; transform-style:preserve-3d; transform:translate(-50%,-50%); transition:transform 1.1s cubic-bezier(.2,.75,.18,1); }
        #$id .build-layer { position:absolute; inset:0; display:flex; gap:2px; padding:16px; border:2px solid var(--tk-terra); border-radius:18px; background:rgba(255,253,247,.86); box-shadow:8px 16px 30px rgba(40,44,27,.13); transform-style:preserve-3d; transition:transform 1.1s cubic-bezier(.2,.75,.18,1), opacity .65s ease, border-color .35s ease, box-shadow .35s ease; }
        #$id .build-column { display:grid; grid-template-rows:repeat(3,38px); gap:2px; transition:transform .8s cubic-bezier(.18,.8,.2,1), opacity .45s ease; }
        #$id .build-column span { width:38px; height:38px; border-radius:7px; }
        #$id .front-layer { transform:translateZ(0); }
        #$id .back-layer { opacity:0; transform:translate(42px,34px) scale(.9); }
        #$id[data-step="1"] .front-layer .col1 { transform:translateX(20px); }
        #$id[data-step="1"] .front-layer .col2 { opacity:0; transform:translateX(-22px); }
        #$id[data-step="1"] .back-layer { opacity:0; }
        #$id[data-step="2"] .build-layer { border-color:var(--tk-blue); }
        #$id[data-step="2"] .front-layer .col1,
        #$id[data-step="2"] .front-layer .col2 { opacity:1; transform:translateX(0); }
        #$id[data-step="2"] .back-layer { opacity:0; }
        #$id[data-step="3"] .construction { transform:translate(-50%,-50%) rotateX(58deg) rotateY(-30deg) rotateZ(-22deg) scale(1.12); }
        #$id[data-step="3"] .build-layer { border-color:var(--tk-ochre); box-shadow:10px 18px 30px rgba(195,160,77,.18); }
        #$id[data-step="3"] .front-layer { transform:translateZ(28px); }
        #$id[data-step="3"] .back-layer { opacity:1; transform:translateZ(-28px); }
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
          <div class="build-state" aria-live="polite"><strong id="$id-state">3-vector</strong><span id="$id-index">X[:, 1, 1]</span></div>
        </div>
        <div class="anatomy-copy">
          <div class="tk-kicker">3 × 2 × 2 tensor</div>
          <div class="metricline"><div><strong>3</strong><div class="tk-muted">order</div></div><div><strong>12</strong><div class="tk-muted">entries</div></div><div><strong>3</strong><div class="tk-muted">modes</div></div></div>
          <div class="build-controls">
            <button class="tk-btn active" data-step="1">Mode 1 · Build a fiber</button>
            <button class="tk-btn" data-step="2">+ Mode 2 · Form a matrix</button>
            <button class="tk-btn" data-step="3">+ Mode 3 · Stack into a tensor</button>
          </div>
          <p id="$id-copy" class="tk-lede" style="font-size:17px;margin-top:18px">A mode-1 fiber contains 3 values while the other two indices stay fixed.</p>
        </div>
      </div>
      <div class="tk-footer"><span>Add one independent direction at a time</span><span>03</span></div>
      <script>
        (() => {
          const root = document.getElementById('$id');
          const content = {
            1:{state:'3-vector',index:'X[:, 1, 1]',copy:'A mode-1 fiber contains 3 values while the other two indices stay fixed.'},
            2:{state:'3 × 2 matrix slice',index:'X[:, :, 1]',copy:'Adding Mode 2 places two mode-1 fibers side by side to form a matrix slice.'},
            3:{state:'3 × 2 × 2 tensor',index:'X',copy:'Adding Mode 3 stacks two complete matrix slices and rotates them into a third-order tensor.'}
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
    A1 = [0.2 0.5; 0.7 1.0; 0.4 0.8]
    A2 = [0.8 0.3; 0.5 0.9; 1.0 0.2]
    tensor_slices = "<div class=\"flat-slice fs1\">$(heatmap_html(A1; cell=38, radius=6))</div><div class=\"flat-slice fs2\">$(heatmap_html(A2; cell=38, radius=6))</div>"
    matrix = hcat(A1, A2)
    Base.HTML("""
    <div id="$id" class="tk-stage" data-view="tensor">
      <style>
        #$id .flat-grid { display:grid; grid-template-columns:1fr 1fr; gap:46px; align-items:center; min-height:390px; }
        #$id .viz { min-height:300px; display:grid; place-items:center; position:relative; }
        #$id .tensor-view, #$id .matrix-view { transition:opacity .3s ease, transform .4s ease; }
        #$id .tensor-view { position:relative; width:250px; height:230px; perspective:700px; }
        #$id .flat-slice { position:absolute; padding:15px; border-radius:16px; background:var(--tk-paper); border:2px solid var(--tk-blue); box-shadow:0 16px 30px rgba(45,50,31,.12); }
        #$id .fs1 { left:20px; top:28px; transform:rotateX(55deg) rotateZ(-17deg); }
        #$id .fs2 { left:88px; top:84px; transform:rotateX(55deg) rotateZ(-17deg); border-color:var(--tk-ochre); }
        #$id .matrix-view { position:absolute; opacity:0; transform:scale(.82); padding:20px; border-radius:18px; background:var(--tk-paper); border:2px solid var(--tk-terra); }
        #$id[data-view="matrix"] .tensor-view { opacity:0; transform:scale(.82); }
        #$id[data-view="matrix"] .matrix-view { opacity:1; transform:scale(1); }
        #$id .mode-equation { font-size:clamp(1.6rem,3vw,2.8rem); font-weight:780; line-height:1.25; letter-spacing:-.03em; }
        #$id .space { color:var(--tk-blue); } #$id .feature { color:var(--tk-ochre); } #$id .merged { color:var(--tk-terra); }
        #$id .loss { margin-top:24px; padding-left:16px; border-left:4px solid var(--tk-terra); color:var(--tk-muted); font-size:18px; }
        @media(max-width:760px){#$id .flat-grid{grid-template-columns:1fr}#$id .viz{min-height:250px}}
      </style>
      <div class="flat-grid">
        <div class="viz">
          <div class="tensor-view">$tensor_slices</div>
          <div class="matrix-view">$(heatmap_html(matrix; cell=34, radius=5))</div>
        </div>
        <div>
          <div class="tk-kicker">Same 12 numbers</div>
          <div class="mode-equation" id="$id-equation">sample × <span class="space">space</span> × <span class="feature">feature</span></div>
          <div class="loss" id="$id-loss">Space and feature remain separately modeled.</div>
          <button class="tk-btn" id="$id-toggle" style="margin-top:28px">▶ Flatten modes 2 + 3</button>
        </div>
      </div>
      <div class="tk-footer"><span>Flattening preserves entries, not mode semantics</span><span>04</span></div>
      <script>
        (() => {
          const root=document.getElementById('$id'); const button=root.querySelector('#$id-toggle');
          button.addEventListener('click',()=>{
            const matrix=root.dataset.view==='matrix'; root.dataset.view=matrix?'tensor':'matrix';
            root.querySelector('#$id-equation').innerHTML=matrix?'sample × <span class="space">space</span> × <span class="feature">feature</span>':'sample × <span class="merged">(space · feature)</span>';
            root.querySelector('#$id-loss').textContent=matrix?'Space and feature remain separately modeled.':'The matrix no longer models space and feature as distinct axes.';
            button.textContent=matrix?'▶ Flatten modes 2 + 3':'↻ Restore the tensor';
          });
        })();
      </script>
    </div>
    """)
end

function compression_visual()
    id = next_deck_id("tk-compress")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id { padding:30px 44px; }
        #$id .compress-grid { display:grid; grid-template-columns:.82fr 1.18fr; gap:52px; align-items:center; min-height:390px; }
        #$id .control { display:grid; grid-template-columns:92px 1fr 48px; gap:12px; align-items:center; margin:13px 0; }
        #$id .control label { color:var(--tk-muted); font-size:13px; font-weight:700; }
        #$id .control output { font-size:14px; font-weight:750; color:var(--tk-olive-dark); text-align:right; }
        #$id .control-note { max-width:310px; font-size:12px; line-height:1.35; }
        #$id .results { position:relative; padding-top:76px; }
        #$id .counts { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:16px; }
        #$id .count { min-width:0; padding:11px 0; border-top:2px solid rgba(94,103,64,.22); }
        #$id .count-label { display:block; min-height:28px; background:transparent !important; color:var(--tk-muted); font-size:12px; line-height:1.15; }
        #$id .count strong { display:block; overflow-wrap:anywhere; color:var(--tk-olive-dark); font-size:clamp(1.35rem,2.2vw,2rem); font-weight:650; letter-spacing:-.025em; line-height:1.05; }
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
        #$id .cp-mini { position:absolute; top:20px; right:32px; width:250px; color:var(--tk-muted); }
        #$id .cp-mini-title { margin-bottom:7px; color:var(--tk-olive-dark); font-size:11px; font-weight:750; letter-spacing:.045em; text-align:center; text-transform:uppercase; }
        #$id .cp-equation { display:flex; align-items:center; justify-content:center; gap:7px; height:34px; }
        #$id .cp-equation b { color:var(--tk-muted); font-size:13px; font-weight:650; }
        #$id .rank-one { position:relative; width:28px; height:23px; }
        #$id .rank-one i { position:absolute; left:2px; top:5px; width:22px; height:15px; border:1px solid currentColor; background:color-mix(in srgb,currentColor 18%,transparent); transform:skewY(-18deg); }
        #$id .rank-one i:nth-child(1) { transform:translate(-3px,-3px) skewY(-18deg); opacity:.45; }
        #$id .rank-one i:nth-child(2) { transform:skewY(-18deg); opacity:.68; }
        #$id .rank-one i:nth-child(3) { transform:translate(3px,3px) skewY(-18deg); opacity:.9; }
        #$id .rank-one.r1 { color:var(--tk-terra); }
        #$id .rank-one.r2 { color:var(--tk-blue); }
        #$id .rank-one.rr { color:var(--tk-ochre); }
        #$id .rank-one.result { width:34px; color:var(--tk-olive); transform:scale(1.12); }
        #$id .cp-mini-caption { display:block; margin-top:3px; font-size:10px; text-align:center; }
        @media(max-width:760px){
          #$id .compress-grid{grid-template-columns:1fr;gap:20px}
          #$id .results{padding-top:0}
          #$id .cp-mini{position:relative;top:auto;right:auto;margin:0 0 18px auto}
          #$id .counts{grid-template-columns:repeat(3,minmax(0,1fr))}
        }
      </style>
      <div class="cp-mini" role="img" aria-label="CP decomposition represents a tensor as a sum of R rank-one tensors">
        <div class="cp-mini-title">CPD = sum of rank-1 tensors</div>
        <div class="cp-equation">
          <div class="rank-one r1"><i></i><i></i><i></i></div><b>+</b>
          <div class="rank-one r2"><i></i><i></i><i></i></div><b>+ ··· +</b>
          <div class="rank-one rr"><i></i><i></i><i></i></div><b>→</b>
          <div class="rank-one result"><i></i><i></i><i></i></div>
        </div>
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
      <div class="tk-footer"><span>Low rank replaces ambient entries with structured coordinates</span><span>05</span></div>
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
        #$id .rank-one { width:270px; height:220px; display:grid; place-items:center; position:relative; }
        #$id .rank-one::before,#$id .rank-one::after { content:''; position:absolute; width:170px; height:170px; border:2px solid var(--component); border-radius:20px; transform:rotate(18deg); opacity:.36; }
        #$id .rank-one::after { transform:rotate(-18deg); opacity:.18; }
        #$id .outer { display:grid; grid-template-columns:repeat(6,25px); gap:4px; position:relative; z-index:2; }
        #$id .outer span { width:25px; height:25px; border-radius:4px; background:var(--component); transition:opacity .3s ease; }
        #$id .component-title { font-size:30px; font-weight:830; margin-top:8px; color:var(--component); }
        @media(max-width:760px){#$id .cp-grid{grid-template-columns:1fr}#$id .rank-one{height:180px}}
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
          <div class="rank-one"><div class="outer"></div></div>
          <div class="component-title" id="$id-title">a₁ ⊗ b₁ ⊗ c₁</div>
          <div class="tk-caption">One component links one profile from every mode.</div>
        </div>
      </div>
      <div class="tk-footer"><span>CP: shared components across every mode</span><span>06</span></div>
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
            });
            const outer=root.querySelector('.outer');outer.innerHTML='';
            for(let row=0;row<5;row++)for(let col=0;col<6;col++){const span=document.createElement('span');span.style.opacity=.12+.8*item.sample[row]*item.space[col];outer.appendChild(span);}
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
        #$id .tucker-viz { position:relative; min-height:330px; display:grid; place-items:center; }
        #$id .core { width:150px; height:130px; display:grid; place-items:center; border-radius:26px; background:linear-gradient(145deg,var(--tk-olive),var(--tk-olive-dark)); color:white; box-shadow:18px 18px 0 rgba(195,160,77,.16); font-weight:850; font-size:24px; transition:transform .3s ease; }
        #$id .factor { position:absolute; border-radius:999px; opacity:.8; transition:width .3s ease,height .3s ease; }
        #$id .f1 { width:220px; height:13px; background:var(--tk-terra); top:24px; left:50%; transform:translateX(-50%); }
        #$id .f2 { width:13px; height:220px; background:var(--tk-blue); left:45px; top:50%; transform:translateY(-50%); }
        #$id .f3 { width:13px; height:190px; background:var(--tk-ochre); right:45px; top:50%; transform:translateY(-50%) rotate(32deg); }
        #$id .metrics { display:flex; gap:38px; justify-content:center; margin-top:18px; }
        #$id .metrics strong { font-size:30px; color:var(--tk-olive-dark); }
        @media(max-width:760px){#$id .tucker-grid{grid-template-columns:1fr}}
      </style>
      <div class="tucker-grid">
        <div>
          <div class="tk-kicker">Choose one rank per mode</div>
          <div class="rank-control"><label>sample r₁</label><input class="tk-slider" id="$id-r1" type="range" min="1" max="4" value="3"><output id="$id-o1">3</output></div>
          <div class="rank-control"><label>space r₂</label><input class="tk-slider" id="$id-r2" type="range" min="1" max="4" value="2"><output id="$id-o2">2</output></div>
          <div class="rank-control"><label>feature r₃</label><input class="tk-slider" id="$id-r3" type="range" min="1" max="4" value="2"><output id="$id-o3">2</output></div>
          <p class="tk-lede" style="font-size:18px">The core records how the three mode subspaces interact.</p>
        </div>
        <div>
          <div class="tucker-viz"><div class="factor f1"></div><div class="factor f2"></div><div class="factor f3"></div><div class="core" id="$id-core">3 × 2 × 2</div></div>
          <div class="metrics"><div><strong id="$id-params">84</strong><div class="tk-caption">coordinates</div></div><div><strong id="$id-error">0.020</strong><div class="tk-caption">relative error</div></div></div>
        </div>
      </div>
      <div class="tk-footer"><span>Tucker: different compression for different modes</span><span>07</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id'), errors={$error_entries}, dims=[$(dims[1]),$(dims[2]),$(dims[3])];
          const sliders=[1,2,3].map(i=>root.querySelector('#$id-r'+i));
          const update=()=>{
            const r=sliders.map(x=>+x.value);r.forEach((x,i)=>root.querySelector('#$id-o'+(i+1)).textContent=x);
            root.querySelector('#$id-core').textContent=r.join(' × ');root.querySelector('#$id-core').style.transform='scale('+(0.88+.04*(r[0]+r[1]+r[2]))+')';
            const params=r[0]*r[1]*r[2]+dims[0]*r[0]+dims[1]*r[1]+dims[2]*r[2];
            root.querySelector('#$id-params').textContent=params.toLocaleString();
            const error=errors[r.join('-')];root.querySelector('#$id-error').textContent=error.toFixed(3);
          };sliders.forEach(x=>x.addEventListener('input',update));update();
        })();
      </script>
    </div>
    """)
end

function model_assumption_visual()
    id = next_deck_id("tk-models")
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .model-layout { min-height:390px; display:grid; grid-template-rows:auto 1fr; gap:28px; }
        #$id .model-main { display:grid; grid-template-columns:.7fr .9fr 1.2fr; gap:36px; align-items:center; }
        #$id .model-name { font-size:clamp(3.4rem,7vw,7rem); font-weight:880; color:var(--tk-olive-dark); letter-spacing:-.07em; }
        #$id .model-glyph { min-height:235px; position:relative; display:grid; place-items:center; }
        #$id .glyph-core { width:90px; height:90px; border-radius:22px; background:var(--tk-olive); box-shadow:60px -38px 0 rgba(93,126,157,.45),-62px 34px 0 rgba(201,111,74,.45); transition:all .3s ease; }
        #$id .model-copy strong { display:block; font-size:clamp(1.7rem,3vw,3rem); line-height:1.08; color:var(--tk-ink); letter-spacing:-.035em; }
        #$id .model-copy p { color:var(--tk-muted); font-size:18px; line-height:1.5; }
        #$id[data-model="cp"] .glyph-core { border-radius:50%; width:25px; height:25px; box-shadow:70px 0 0 var(--tk-blue),-35px 60px 0 var(--tk-terra),-35px -60px 0 var(--tk-ochre); }
        #$id[data-model="tucker"] .glyph-core { width:100px;height:100px;box-shadow:70px 0 0 rgba(93,126,157,.36),0 70px 0 rgba(201,111,74,.36); }
        #$id[data-model="btd"] .glyph-core { width:62px;height:62px;box-shadow:78px 0 0 var(--tk-blue),-78px 0 0 var(--tk-terra); }
        #$id[data-model="nncp"] .glyph-core { width:28px;height:130px;border-radius:10px;box-shadow:48px 35px 0 var(--tk-sage),-48px 62px 0 var(--tk-ochre); }
        @media(max-width:760px){#$id .model-main{grid-template-columns:1fr 1fr}#$id .model-copy{grid-column:1/-1}}
      </style>
      <div class="model-layout">
        <div class="tk-btnrow">
          <button class="tk-btn active" data-model="cp">CP</button><button class="tk-btn" data-model="tucker">Tucker</button><button class="tk-btn" data-model="btd">BTD</button><button class="tk-btn" data-model="nncp">NNCPD</button>
        </div>
        <div class="model-main">
          <div class="model-name" id="$id-name">CP</div>
          <div class="model-glyph"><div class="glyph-core"></div></div>
          <div class="model-copy"><div class="tk-kicker" id="$id-block">rank-one terms</div><strong id="$id-promise">One component links every mode.</strong><p id="$id-caution">Scaling and component order remain ambiguous.</p></div>
        </div>
      </div>
      <div class="tk-footer"><span>A model name is a structural assumption</span><span>08</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id');const data={
            cp:['CP','rank-one terms','One component links every mode.','Scaling and component order remain ambiguous.'],
            tucker:['Tucker','one interacting core','Each mode gets its own subspace.','Core entries depend on the chosen bases.'],
            btd:['BTD','a sum of small Tucker blocks','Each concept may have internal variation.','Blocks carry Tucker gauges and may permute.'],
            nncp:['NNCPD','nonnegative rank-one terms','Components form additive parts.','The constraint can increase reconstruction error.']
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
    map = heatmap_html(X; cell=30, radius=5)
    Base.HTML("""
    <div id="$id" class="tk-stage">
      <style>
        #$id .gauge-grid { display:grid; grid-template-columns:1.1fr .9fr; gap:52px; align-items:center; min-height:390px; }
        #$id .coords { position:relative; height:285px; }
        #$id .axis { position:absolute; left:50%; top:50%; background:rgba(94,103,64,.25); }
        #$id .x { width:280px;height:1px;transform:translate(-50%,-50%); } #$id .y { width:1px;height:250px;transform:translate(-50%,-50%); }
        #$id .ellipse { position:absolute; left:50%; top:50%; width:110px;height:110px;border-radius:50%;border:4px solid var(--tk-terra);background:rgba(201,111,74,.09);transform:translate(-50%,-50%);transition:width .25s ease,height .25s ease; }
        #$id .matrix-fixed { display:grid; place-items:center; padding:22px; border-radius:22px; background:rgba(255,253,247,.8); }
        #$id .gauge-metrics { display:flex; gap:34px; margin-top:22px; }
        #$id .gauge-metrics strong { display:block;font-size:30px;color:var(--tk-olive-dark); }
        @media(max-width:760px){#$id .gauge-grid{grid-template-columns:1fr}#$id .coords{height:240px}}
      </style>
      <div class="gauge-grid">
        <div>
          <div class="tk-kicker">Move the factor coordinates</div>
          <div class="coords"><div class="axis x"></div><div class="axis y"></div><div class="ellipse"></div></div>
          <label style="font-weight:800" for="$id-scale">gauge scale · log₁₀(s)</label>
          <input class="tk-slider" id="$id-scale" type="range" min="-4" max="4" step=".1" value="0">
          <div class="gauge-metrics"><div><strong id="$id-s">1</strong><span class="tk-caption">s</span></div><div><strong id="$id-k">1</strong><span class="tk-caption">κ(Q)</span></div></div>
        </div>
        <div class="matrix-fixed">
          <div class="tk-kicker">Represented matrix X</div>
          <div style="margin:24px 0">$map</div>
          <div class="tk-formula">X = ABᵀ = (AQ)(BQ⁻ᵀ)ᵀ</div>
          <p class="tk-lede" style="font-size:18px;text-align:center">The coordinates stretch. The object does not move.</p>
        </div>
      </div>
      <div class="tk-footer"><span>Representation determines what counts as equivalent</span><span>09</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id'), slider=root.querySelector('#$id-scale'), ellipse=root.querySelector('.ellipse');
          const fmt=x=>(x>=1e4||x<1e-3)?x.toExponential(1):Number(x.toPrecision(3)).toString();
          const update=()=>{const e=+slider.value,s=Math.pow(10,e),stretch=Math.pow(10,.18*e);ellipse.style.width=Math.max(18,Math.min(250,110*stretch))+'px';ellipse.style.height=Math.max(18,Math.min(230,110/stretch))+'px';root.querySelector('#$id-s').textContent=fmt(s);root.querySelector('#$id-k').textContent=fmt(Math.pow(10,2*Math.abs(e)));};
          slider.addEventListener('input',update);update();
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
        #$id .checkpoint strong { font-size:19px;display:block; }
        #$id .checkpoint span { color:var(--tk-muted);font-size:14px;line-height:1.35;display:block;margin-top:7px; }
        #$id .answer { text-align:center;font-size:clamp(1.5rem,3vw,3rem);font-weight:830;letter-spacing:-.035em;min-height:60px;color:var(--tk-terra); }
      </style>
      <div class="validation">
        <div>
          <div class="path">
            <div class="checkpoint active"><div class="dot">1</div><strong>Fit</strong><span>Does the reconstructed tensor match?</span></div>
            <div class="checkpoint"><div class="dot">2</div><strong>Stability</strong><span>Do restarts recover the same object?</span></div>
            <div class="checkpoint"><div class="dot">3</div><strong>Identifiability</strong><span>Are factors determined by the model?</span></div>
            <div class="checkpoint"><div class="dot">4</div><strong>Validation</strong><span>Do perturbations support the claimed meaning?</span></div>
          </div>
          <div class="answer" id="$id-answer">Low error starts the investigation.</div>
        </div>
        <div class="tk-btnrow" style="justify-content:center"><button class="tk-btn" id="$id-next">▶ Ask the next question</button><button class="tk-btn" id="$id-reset">Reset</button></div>
      </div>
      <div class="tk-footer"><span>Identifiable factor ≠ meaningful concept</span><span>10</span></div>
      <script>
        (()=>{
          const root=document.getElementById('$id'),steps=[...root.querySelectorAll('.checkpoint')],messages=['Low error starts the investigation.','Stable solutions are easier to trust.','Identifiability makes component questions mathematically coherent.','Meaning still requires external evidence.'];let index=0;
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
        <div class="tk-display" style="font-size:clamp(1.6rem,2.6vw,3.6rem);margin-top:22px">A decomposition is a compressed geometric hypothesis.</span></div>
      </div>
      <div class="tk-footer"><span>Continue with Labs 1–4</span><span>11</span></div>
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
