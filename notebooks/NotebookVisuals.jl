module NotebookVisuals

using LinearAlgebra
using Printf

export activation_maps_visual,
       ai_geometry_bridge_visual,
       cancellation_warmup_visual,
       capacity_fit_visual,
       component_collision_visual,
       cp_components_visual,
       cp_equivalence_puzzle_visual,
       decomposition_illustration,
       failure_comparison_visual,
       failure_map_visual,
       flatten_vs_tensor_visual,
       gauge_dial_visual,
       gauge_visual,
       geometry_race_visual,
       gram_condition_visual,
       model_language_visual,
       solver_race_visual,
       swamp_microscope_visual,
       tensor_reconstruction_gallery,
       tensor_slices_visual,
       trajectory_visual

const VISUAL_COUNTER = Ref(0)

function next_id(prefix)
    VISUAL_COUNTER[] += 1
    return "$(prefix)-$(VISUAL_COUNTER[])"
end

"""Contrast semantic tensor axes with the same entries after flattening."""
function flatten_vs_tensor_visual()
    root_id = next_id("flatten-vs-tensor")
    tensor_cells = join("<i></i>" for _ = 1:20)
    slices = join(
        "<div class=\"ft-slice s$sample\">$tensor_cells</div>" for sample = 1:3
    )
    matrix_cells = join("<i></i>" for _ = 1:60)
    return Base.HTML("""
    <div id="$root_id" class="ft-wrap" data-view="tensor">
      <style>
        #$root_id{--olive:#657047;--blue:#5d7e9d;--terra:#c96f4a;--muted:#68705b;--paper:rgba(255,253,247,.85);color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;margin:1rem 0}
        #$root_id *{box-sizing:border-box}#$root_id .ft-controls{display:flex;gap:.55rem;flex-wrap:wrap;margin-bottom:.85rem}#$root_id button{border:1px solid rgba(94,103,64,.32);border-radius:999px;background:var(--paper);color:inherit;padding:.5rem .8rem;font:inherit;cursor:pointer}#$root_id button[aria-pressed=true]{background:var(--olive);color:white}
        #$root_id .ft-stage{display:grid;grid-template-columns:minmax(280px,1fr) minmax(230px,.8fr);gap:1.2rem;align-items:center;min-height:245px}#$root_id .ft-object{position:relative;height:220px;display:grid;place-items:center}#$root_id .ft-copy{border-left:4px solid var(--olive);padding:.2rem 0 .2rem .9rem}#$root_id .ft-copy strong{display:block;margin-bottom:.45rem}#$root_id .ft-copy p{margin:.35rem 0;color:var(--muted)}#$root_id .ft-equation{font-weight:650;color:var(--olive)}
        #$root_id .ft-tensor,#$root_id .ft-matrix{position:absolute;inset:0;display:grid;place-items:center;transition:opacity .45s ease,transform .7s ease}#$root_id .ft-matrix{opacity:0;transform:translateX(28px) scale(.92)}#$root_id[data-view=matrix] .ft-tensor{opacity:0;transform:translateX(-28px) scale(.92)}#$root_id[data-view=matrix] .ft-matrix{opacity:1;transform:none}
        #$root_id .ft-slice{position:absolute;display:grid;grid-template-columns:repeat(5,24px);grid-template-rows:repeat(4,24px);gap:3px;padding:8px;border:1px solid var(--blue);background:var(--paper);box-shadow:0 9px 20px rgba(45,50,31,.10)}#$root_id .ft-slice i,#$root_id .ft-matrix-grid i{background:color-mix(in srgb,var(--blue) 32%,transparent);border-radius:2px}#$root_id .s1{transform:translate(-18px,-18px)}#$root_id .s2{transform:translate(0,0)}#$root_id .s3{transform:translate(18px,18px)}
        #$root_id .ft-matrix-grid{display:grid;grid-template-columns:repeat(5,18px);grid-template-rows:repeat(12,10px);gap:2px;padding:10px;border:2px solid var(--olive);background:var(--paper)}#$root_id .ft-matrix-grid i{background:#a7aaa2}#$root_id .ft-label{position:absolute;color:var(--muted);font-size:.78rem;font-weight:650}#$root_id .sample{left:8px;top:18px;color:var(--terra)}#$root_id .token{right:10px;bottom:16px;color:var(--blue)}#$root_id .feature{right:2px;top:18px;color:var(--olive)}
        @media(max-width:700px){#$root_id .ft-stage{grid-template-columns:1fr}#$root_id .ft-copy{margin-top:.4rem}}@media(prefers-color-scheme:dark){#$root_id{--muted:#c0c6b3;--paper:rgba(39,43,34,.9)}}
      </style>
      <div class="ft-controls" role="group" aria-label="Representation view">
        <button type="button" data-view="tensor" aria-pressed="true">Tensor · keep three axes</button>
        <button type="button" data-view="matrix" aria-pressed="false">Flatten sample × token</button>
      </div>
      <div class="ft-stage">
        <div class="ft-object" role="img" aria-label="The same 60 activation entries viewed as a tensor or flattened matrix">
          <div class="ft-tensor">$slices<span class="ft-label sample">sample</span><span class="ft-label token">token</span><span class="ft-label feature">feature</span></div>
          <div class="ft-matrix"><div class="ft-matrix-grid">$matrix_cells</div></div>
        </div>
        <div class="ft-copy"><strong id="$root_id-title">3 × 4 × 5 activation tensor</strong><p id="$root_id-copy">Sample, token, and feature remain separate questions.</p><div class="ft-equation" id="$root_id-equation">sample × token × feature</div></div>
      </div>
      <script>(()=>{const root=document.getElementById('$root_id');const buttons=[...root.querySelectorAll('[data-view]')],title=root.querySelector('#$root_id-title'),copy=root.querySelector('#$root_id-copy'),equation=root.querySelector('#$root_id-equation');buttons.forEach(button=>button.addEventListener('click',()=>{const matrix=button.dataset.view==='matrix';root.dataset.view=button.dataset.view;buttons.forEach(item=>item.setAttribute('aria-pressed',String(item===button)));title.textContent=matrix?'12 × 5 flattened matrix':'3 × 4 × 5 activation tensor';copy.textContent=matrix?'All 60 entries remain, but sample and token are merged into one row index.':'Sample, token, and feature remain separate questions.';equation.textContent=matrix?'(sample × token) × feature':'sample × token × feature';}));})();</script>
    </div>
    """)
end

"""
    ai_geometry_bridge_visual()

Connect four low-rank coordinate systems to their intrinsic geometric objects
and to recent AI uses. The paper names are pedagogical bridges, not claims that
the notebook reproduces the full methods.
"""
function ai_geometry_bridge_visual()
    root_id = next_id("ai-geometry-bridge")
    matrix_cells(rows, cols) = join("<i></i>" for _ in 1:(rows * cols))
    return Base.HTML("""
    <div id="$root_id" class="gb-wrap">
      <style>
        #$root_id {
          --gb-ink:var(--pluto-output-color,#303628); --gb-muted:#68705b;
          --gb-paper:rgba(255,253,247,.88); --gb-line:rgba(94,103,64,.30);
          --gb-olive:#657047; --gb-blue:#5d7e9d; --gb-terra:#c96f4a; --gb-ochre:#c3a04d;
          width:100%;margin:1rem 0 1.35rem;padding:18px 20px;border:1px solid var(--gb-line);
          border-radius:18px;background:linear-gradient(145deg,var(--gb-paper),rgba(246,241,229,.70));
          color:var(--gb-ink);font:15px/1.42 Inter,Avenir Next,Avenir,system-ui,sans-serif;box-sizing:border-box;
        }
        #$root_id *{box-sizing:border-box} #$root_id .gb-tabs{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-bottom:16px}
        #$root_id button{appearance:none;border:1px solid var(--gb-line);border-radius:10px;background:transparent;color:var(--gb-ink);padding:9px 8px;font:inherit;font-weight:650;font-size:13px;line-height:1.2;cursor:pointer}
        #$root_id button[aria-pressed="true"]{background:var(--gb-olive);border-color:var(--gb-olive);color:white}
        #$root_id .gb-panel{display:none;grid-template-columns:minmax(245px,.9fr) minmax(0,1.35fr);gap:22px;align-items:center;min-height:238px}
        #$root_id .gb-panel.active{display:grid} #$root_id .gb-object{display:grid;place-items:center;min-height:205px;border-right:1px solid var(--gb-line);padding-right:18px}
        #$root_id .gb-formula{font:600 18px/1.25 Georgia,Cambria,serif;text-align:center;margin-bottom:14px;color:var(--gb-olive)}
        #$root_id .gb-caption{margin-top:12px;color:var(--gb-muted);font-size:12px;text-align:center;max-width:260px}
        #$root_id .gb-facts{display:grid;grid-template-columns:112px 1fr;gap:0;border-top:1px solid var(--gb-line)}
        #$root_id .gb-facts b,#$root_id .gb-facts span{padding:9px 8px;border-bottom:1px solid var(--gb-line)}
        #$root_id .gb-facts b{color:var(--gb-muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em}
        #$root_id .gb-facts span{font-size:13px} #$root_id .gb-paper-note{margin-top:11px;padding:9px 11px;border-left:3px solid var(--gb-ochre);background:color-mix(in srgb,var(--gb-ochre) 12%,transparent);font-size:12px;color:var(--gb-muted)}
        #$root_id .gb-matrix{display:grid;gap:3px;padding:6px;border:1px solid currentColor;background:var(--gb-paper)}
        #$root_id .gb-matrix i{display:block;background:currentColor;opacity:.24}
        #$root_id .gb-axes{position:relative;width:180px;height:118px} #$root_id .gb-axis{position:absolute;left:36px;bottom:22px;width:108px;height:5px;border-radius:8px;background:currentColor;transform-origin:left center}
        #$root_id .gb-axis:after{content:'';position:absolute;right:-2px;top:-5px;border-left:11px solid currentColor;border-top:7px solid transparent;border-bottom:7px solid transparent}
        #$root_id .gb-a1{color:var(--gb-terra);transform:rotate(0deg)} #$root_id .gb-a2{color:var(--gb-blue);transform:rotate(-90deg)}
        #$root_id .gb-rank-flow{display:flex;align-items:center;gap:8px} #$root_id .gb-u{grid-template-columns:repeat(2,11px);grid-template-rows:repeat(6,11px);color:var(--gb-terra)}
        #$root_id .gb-s{grid-template-columns:repeat(2,13px);grid-template-rows:repeat(2,13px);color:var(--gb-ochre)} #$root_id .gb-v{grid-template-columns:repeat(5,11px);grid-template-rows:repeat(2,11px);color:var(--gb-blue)}
        #$root_id .gb-w{grid-template-columns:repeat(5,10px);grid-template-rows:repeat(6,9px);color:var(--gb-olive)} #$root_id .gb-op{font:20px Georgia,serif;color:var(--gb-muted)}
        #$root_id .gb-segre{display:flex;align-items:center;gap:8px} #$root_id .gb-stick{border:1px solid currentColor;background:color-mix(in srgb,currentColor 30%,var(--gb-paper));border-radius:3px}
        #$root_id .gb-stick.a{width:12px;height:78px;color:var(--gb-terra)} #$root_id .gb-stick.b{width:72px;height:12px;color:var(--gb-blue)} #$root_id .gb-stick.c{width:55px;height:12px;color:var(--gb-ochre);transform:rotate(-34deg);margin-left:-5px}
        #$root_id .gb-stack{position:relative;width:80px;height:72px;margin-left:4px} #$root_id .gb-stack i{position:absolute;left:7px;top:17px;width:58px;height:42px;border:1px solid var(--gb-olive);background:color-mix(in srgb,var(--gb-olive) 18%,var(--gb-paper));transform:translate(calc(var(--k)*5px),calc(var(--k)*-6px)) skewY(-10deg)}
        #$root_id .gb-tucker{display:flex;align-items:center;gap:9px} #$root_id .gb-core{grid-template-columns:repeat(2,14px);grid-template-rows:repeat(2,14px);color:var(--gb-terra)}
        #$root_id .gb-factors{display:flex;gap:5px;align-items:end} #$root_id .gb-factors .gb-matrix{grid-template-columns:repeat(2,8px);color:var(--gb-blue)} #$root_id .gb-factors .f1{grid-template-rows:repeat(6,8px)} #$root_id .gb-factors .f2{grid-template-rows:repeat(5,8px);color:var(--gb-ochre)} #$root_id .gb-factors .f3{grid-template-rows:repeat(4,8px);color:var(--gb-olive)}
        @media(prefers-color-scheme:dark){#$root_id{--gb-muted:#bdc3ae;--gb-paper:rgba(40,44,34,.88);--gb-line:rgba(190,198,164,.34);background:linear-gradient(145deg,rgba(44,49,37,.86),rgba(32,36,29,.78))}}
        @media(max-width:760px){#$root_id .gb-tabs{grid-template-columns:1fr 1fr}#$root_id .gb-panel.active{grid-template-columns:1fr}#$root_id .gb-object{border-right:0;border-bottom:1px solid var(--gb-line);padding:0 0 14px}#$root_id .gb-facts{grid-template-columns:92px 1fr}}
      </style>
      <div class="gb-tabs" role="group" aria-label="Choose a low-rank geometric object">
        <button type="button" data-key="stiefel" aria-pressed="true">Orthonormal frame</button>
        <button type="button" data-key="fixed" aria-pressed="false">Low-rank matrix</button>
        <button type="button" data-key="segre" aria-pressed="false">Segre component</button>
        <button type="button" data-key="tucker" aria-pressed="false">Tucker object</button>
      </div>
      <section class="gb-panel active" data-panel="stiefel">
        <div class="gb-object"><div><div class="gb-formula">U ∈ St(n,r), &nbsp;UᵀU = Iᵣ</div><div class="gb-axes" role="img" aria-label="Two orthonormal frame directions"><i class="gb-axis gb-a1"></i><i class="gb-axis gb-a2"></i></div><div class="gb-caption">An ordered orthonormal frame. Its columns have unit length and are mutually perpendicular.</div></div></div>
        <div><div class="gb-facts"><b>Frame</b><span>the orthonormal columns of U</span><b>Subspace</b><span>rotating the frame can leave span(U) unchanged</span><b>Question</b><span>are you interpreting one column or the whole learned subspace?</span><b>AI bridge</b><span>StelLA makes learned input/output frames and subspaces explicit</span></div><div class="gb-paper-note">Formal Stiefel notation is optional; the essential distinction is frame versus subspace.</div></div>
      </section>
      <section class="gb-panel" data-panel="fixed">
        <div class="gb-object"><div><div class="gb-formula">W ∈ ℳᵣ, &nbsp;rank(W)=r</div><div class="gb-rank-flow" role="img" aria-label="U times S times V transpose produces one fixed-rank matrix W"><div class="gb-matrix gb-u">$(matrix_cells(6,2))</div><span class="gb-op">×</span><div class="gb-matrix gb-s">$(matrix_cells(2,2))</div><span class="gb-op">×</span><div class="gb-matrix gb-v">$(matrix_cells(2,5))</div><span class="gb-op">=</span><div class="gb-matrix gb-w">$(matrix_cells(6,5))</div></div><div class="gb-caption">U, S, and V are coordinates; W is the represented rank-r matrix.</div></div></div>
        <div><div class="gb-facts"><b>Coordinates</b><span>U, S, and V describe the matrix</span><b>Object</b><span>the represented low-rank matrix W</span><b>Question</b><span>are you interpreting a basis vector, a subspace, or W itself?</span><b>AI bridge</b><span>RAdaGrad/RAdamW optimize the fixed-rank weight matrix as the object</span></div><div class="gb-paper-note">Different U,S,V coordinates can describe the same W; the formal gauge is in Optional math.</div></div>
      </section>
      <section class="gb-panel" data-panel="segre">
        <div class="gb-object"><div><div class="gb-formula">T = a ⊗ b ⊗ c</div><div class="gb-segre" role="img" aria-label="Three vectors form one rank-one tensor"><i class="gb-stick a"></i><span class="gb-op">⊗</span><i class="gb-stick b"></i><span class="gb-op">⊗</span><i class="gb-stick c"></i><span class="gb-op">→</span><div class="gb-stack">$(join("<i style=\"--k:$k\"></i>" for k in 0:3))</div></div><div class="gb-caption">One separable interaction across three modes is one Segre rank-one tensor.</div></div></div>
        <div><div class="gb-facts"><b>Coordinates</b><span>three mode vectors and an optional scalar weight</span><b>Object</b><span>a rank-one tensor on the Segre variety/manifold away from zero</span><b>Gauge</b><span>reciprocal rescalings and sign transfers preserve the outer product</span><b>AI bridge</b><span>Tensor Decomposition Networks use CP-style low-rank structure inside tensor-product operators</span></div><div class="gb-paper-note">A CP model is a sum of these Segre objects; TensorKitchen represents that sum through component geometries.</div></div>
      </section>
      <section class="gb-panel" data-panel="tucker">
        <div class="gb-object"><div><div class="gb-formula">T = G ×₁ U¹ ×₂ U² ×₃ U³</div><div class="gb-tucker" role="img" aria-label="Three mode factor matrices expand a Tucker core into a tensor"><div class="gb-factors"><div class="gb-matrix f1">$(matrix_cells(6,2))</div><div class="gb-matrix f2">$(matrix_cells(5,2))</div><div class="gb-matrix f3">$(matrix_cells(4,2))</div></div><span class="gb-op">×</span><div class="gb-matrix gb-core">$(matrix_cells(2,2))</div><span class="gb-op">→</span><div class="gb-stack">$(join("<i style=\"--k:$k\"></i>" for k in 0:3))</div></div><div class="gb-caption">Mode subspaces are coupled by a small interaction core.</div></div></div>
        <div><div class="gb-facts"><b>Coordinates</b><span>one core G and one factor matrix per mode</span><b>Object</b><span>multilinear rank at most the requested tuple; a fixed-rank stratum when attained</span><b>Gauge</b><span>basis changes in a mode can be absorbed into the core</span><b>Tutorial bridge</b><span>Lab 2 compares this single coupled object with CP rank-one sums and BTD sums of Tucker blocks</span></div><div class="gb-paper-note">Tucker geometry is the tensor-side analogue of describing an object through interacting mode subspaces rather than isolated columns.</div></div>
      </section>
      <script>
        (()=>{const root=document.getElementById('$root_id');const buttons=[...root.querySelectorAll('[data-key]')],panels=[...root.querySelectorAll('[data-panel]')];buttons.forEach(button=>button.addEventListener('click',()=>{const key=button.dataset.key;buttons.forEach(item=>item.setAttribute('aria-pressed',String(item===button)));panels.forEach(panel=>panel.classList.toggle('active',panel.dataset.panel===key));}));})();
      </script>
    </div>
    """)
end

"""Compare a known capacity bound with the error achieved by one finite run."""
function capacity_fit_visual(sufficient, reduced; actual_multilinear_rank = (4, 4, 2))
    root_id = next_id("capacity-fit")
    error_width(error) = error <= 1e-14 ? 1.5 : clamp(7 + 93 * (log10(error) + 14) / 14, 2, 100)
    function card(row, mode)
        capacity_label = mode == :sufficient ? "explicit representation error" : "rigorous lower bound on error"
        status = mode == :sufficient ? "contains target" : "insufficient capacity"
        """
        <article class="cf-card">
          <div class="cf-head"><strong>$(escape_html(row.model))</strong><span>$(escape_html(row.setting))</span></div>
          <div class="cf-status">$(escape_html(status))</div>
          <div class="cf-measure"><div><span>$capacity_label</span><b>$(number_label(row.capacity_error))</b></div><div class="cf-track"><i class="capacity" style="width:$(error_width(row.capacity_error))%"></i></div></div>
          <div class="cf-measure"><div><span>finite run achieved</span><b>$(number_label(row.fitted_error))</b></div><div class="cf-track"><i class="fit" style="width:$(error_width(row.fitted_error))%"></i></div></div>
          <p>$(escape_html(row.reason))</p>
          <small>$(escape_html(row.method))</small>
        </article>
        """
    end
    sufficient_cards = join(card(row, :sufficient) for row in sufficient)
    reduced_cards = join(card(row, :reduced) for row in reduced)
    return Base.HTML("""
    <div id="$root_id" class="cf-wrap" data-view="sufficient">
      <style>
        #$root_id { --cf-ink:var(--pluto-output-color,#303628);--cf-muted:#68705b;--cf-paper:rgba(255,253,247,.88);--cf-line:rgba(94,103,64,.3);--cf-olive:#657047;--cf-blue:#5d7e9d;--cf-terra:#c96f4a;color:var(--cf-ink);font-family:Inter,Avenir Next,Avenir,system-ui,sans-serif;width:100%;margin:1rem 0; }
        #$root_id *{box-sizing:border-box} #$root_id .cf-controls{display:flex;gap:.55rem;flex-wrap:wrap;margin-bottom:.85rem} #$root_id button{border:1px solid var(--cf-line);border-radius:999px;background:var(--cf-paper);color:var(--cf-ink);padding:.5rem .8rem;font:inherit;cursor:pointer} #$root_id button[aria-pressed="true"]{background:var(--cf-olive);color:#fff}
        #$root_id .cf-rank{margin:.25rem 0 .85rem;color:var(--cf-muted);font-size:.88rem} #$root_id .cf-panel{display:none;grid-template-columns:repeat(3,minmax(0,1fr));gap:.8rem} #$root_id[data-view="sufficient"] .cf-panel.sufficient,#$root_id[data-view="reduced"] .cf-panel.reduced{display:grid}
        #$root_id .cf-card{border:1px solid var(--cf-line);border-radius:14px;background:var(--cf-paper);padding:.85rem;min-width:0} #$root_id .cf-head{display:flex;justify-content:space-between;gap:.5rem;align-items:baseline} #$root_id .cf-head strong{font-size:1.02rem;color:var(--cf-olive)} #$root_id .cf-head span{font-size:.78rem;color:var(--cf-muted);text-align:right} #$root_id .cf-status{margin:.45rem 0 .7rem;font-weight:650;font-size:.82rem}
        #$root_id .cf-measure{margin:.65rem 0} #$root_id .cf-measure>div:first-child{display:flex;justify-content:space-between;gap:.5rem;color:var(--cf-muted);font-size:.76rem} #$root_id .cf-measure b{color:var(--cf-ink);font-variant-numeric:tabular-nums} #$root_id .cf-track{height:10px;margin-top:.25rem;background:color-mix(in srgb,var(--cf-muted) 16%,transparent);border-radius:999px;overflow:hidden} #$root_id .cf-track i{display:block;height:100%;min-width:2px;border-radius:inherit} #$root_id .capacity{background:var(--cf-blue)} #$root_id .fit{background:var(--cf-terra)}
        #$root_id p{min-height:3.2em;margin:.7rem 0 .35rem;color:var(--cf-ink);font-size:.8rem;line-height:1.35} #$root_id small{color:var(--cf-muted);font-size:.72rem} #$root_id .cf-question{margin-top:.8rem;border-left:4px solid var(--cf-olive);padding:.6rem .75rem;background:color-mix(in srgb,var(--cf-olive) 8%,transparent);font-weight:600}
        @media(max-width:780px){#$root_id .cf-panel{grid-template-columns:1fr}#$root_id p{min-height:0}}
        @media(prefers-color-scheme:dark){#$root_id{--cf-muted:#c0c6b3;--cf-paper:rgba(39,43,34,.9);--cf-line:rgba(196,203,174,.32)}}
      </style>
      <div class="cf-controls" role="group" aria-label="Capacity setting">
        <button type="button" data-view="sufficient" aria-pressed="true">Sufficient capacity</button>
        <button type="button" data-view="reduced" aria-pressed="false">Reduced capacity</button>
      </div>
      <div class="cf-rank">Target unfolding ranks: $(join(actual_multilinear_rank," × ")). Blue is a known capacity bound; orange is one algorithm run.</div>
      <section class="cf-panel sufficient">$sufficient_cards</section>
      <section class="cf-panel reduced">$reduced_cards</section>
      <div class="cf-question">If the model contains the target but the finite run does not reach its floor, the remaining gap is an optimization question. More iterations cannot remove a positive capacity floor.</div>
      <script>
        (()=>{const root=document.getElementById('$root_id');root.querySelectorAll('[data-view]').forEach(button=>button.addEventListener('click',()=>{root.dataset.view=button.dataset.view;root.querySelectorAll('[data-view]').forEach(item=>item.setAttribute('aria-pressed',String(item===button)));}));})();
      </script>
    </div>
    """)
end

"""Show what the word component means in CP, Tucker, and BTD."""
function model_language_visual()
    root_id = next_id("model-language")
    bars(class_name) = join("<i></i>" for _ = 1:3) |> cells -> "<div class=\"ml-bars $class_name\">$cells</div>"
    return Base.HTML("""
    <div id="$root_id" class="ml-wrap">
      <style>
        #$root_id{--ml-ink:var(--pluto-output-color,#303628);--ml-muted:#68705b;--ml-paper:rgba(255,253,247,.88);--ml-line:rgba(94,103,64,.3);--ml-olive:#657047;--ml-blue:#5d7e9d;--ml-terra:#c96f4a;color:var(--ml-ink);font-family:Inter,Avenir Next,Avenir,system-ui,sans-serif;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.8rem;margin:1rem 0} #$root_id *{box-sizing:border-box}
        #$root_id article{border:1px solid var(--ml-line);border-radius:14px;background:var(--ml-paper);padding:.9rem;text-align:center} #$root_id h4{margin:0;color:var(--ml-olive)} #$root_id .ml-icon{height:84px;display:flex;align-items:center;justify-content:center;gap:.35rem;color:var(--ml-muted)} #$root_id .ml-bars{display:flex;align-items:center;gap:3px} #$root_id .ml-bars i{display:block;width:10px;height:54px;border:1px solid currentColor;background:color-mix(in srgb,currentColor 28%,transparent)} #$root_id .b{transform:rotate(90deg);color:var(--ml-blue)} #$root_id .a{color:var(--ml-terra)} #$root_id .c{transform:rotate(-38deg);color:var(--ml-olive)} #$root_id .ml-core{width:34px;height:34px;border:2px solid var(--ml-terra);background:color-mix(in srgb,var(--ml-terra) 18%,transparent);display:grid;place-items:center;font-weight:700} #$root_id .ml-matrix{width:15px;height:58px;border:1px solid var(--ml-blue);background:repeating-linear-gradient(to bottom,color-mix(in srgb,var(--ml-blue) 35%,transparent) 0 8px,transparent 8px 10px)} #$root_id .ml-block{width:48px;height:46px;border:2px solid currentColor;background:color-mix(in srgb,currentColor 15%,transparent);display:grid;place-items:center;font-size:.72rem} #$root_id .one{color:var(--ml-blue)} #$root_id .two{color:var(--ml-terra)}
        #$root_id strong{display:block;margin:.2rem 0;font-size:.9rem} #$root_id p{margin:.35rem 0;color:var(--ml-muted);font-size:.8rem;line-height:1.35} #$root_id code{font-size:.75rem}
        @media(max-width:760px){#$root_id{grid-template-columns:1fr}} @media(prefers-color-scheme:dark){#$root_id{--ml-muted:#c0c6b3;--ml-paper:rgba(39,43,34,.9);--ml-line:rgba(196,203,174,.32)}}
      </style>
      <article><h4>CP</h4><div class="ml-icon">$(bars("a"))<b>⊗</b>$(bars("b"))<b>⊗</b>$(bars("c"))</div><strong>one component = one separable outer product</strong><p>Individual mode vectors jointly define one rank-one tensor.</p><code>components(cp_atlas)</code></article>
      <article><h4>Tucker</h4><div class="ml-icon"><div class="ml-matrix"></div><b>×</b><div class="ml-core">G</div><b>×</b><div class="ml-matrix"></div></div><strong>one model = mode subspaces + interacting core</strong><p>The core couples latent coordinates across all modes.</p><code>core(tucker_atlas)</code></article>
      <article><h4>BTD</h4><div class="ml-icon"><div class="ml-block one">block 1</div><b>+</b><div class="ml-block two">block 2</div></div><strong>one component = one small Tucker block</strong><p>Several multilinear blocks are added to form the tensor.</p><code>blocks(btd_atlas)</code></article>
    </div>
    """)
end

escape_html(x) = replace(
    string(x),
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "\"" => "&quot;",
)

function number_label(x)
    ax = abs(float(x))
    if iszero(ax)
        return "0"
    elseif ax ≥ 1e4 || ax < 1e-3
        return @sprintf("%.2e", x)
    elseif ax ≥ 100
        return @sprintf("%.0f", x)
    elseif ax ≥ 10
        return @sprintf("%.1f", x)
    else
        return @sprintf("%.3g", x)
    end
end

function mix_channel(a, b, t)
    return round(Int, clamp((1 - t) * a + t * b, 0, 255))
end

function heat_color(value, scale)
    t = clamp(abs(float(value)) / max(float(scale), eps()), 0, 1)
    neutral = (243, 244, 246)
    target = value ≥ 0 ? (37, 99, 235) : (220, 38, 38)
    strength = 0.12 + 0.88 * t
    rgb = ntuple(i -> mix_channel(neutral[i], target[i], strength), 3)
    return @sprintf("#%02x%02x%02x", rgb...)
end

function heatmap_svg(A::AbstractMatrix; width = 210, height = 155, scale = nothing)
    rows, cols = size(A)
    chosen_scale = isnothing(scale) ? maximum(abs, A; init = 0.0) : scale
    cell_width = width / cols
    cell_height = height / rows
    cells = String[]
    for row in 1:rows, col in 1:cols
        value = A[row, col]
        push!(
            cells,
            "<rect x=\"$((col - 1) * cell_width)\" y=\"$((row - 1) * cell_height)\" width=\"$(cell_width + 0.2)\" height=\"$(cell_height + 0.2)\" fill=\"$(heat_color(value, chosen_scale))\"><title>row $row, column $col: $(number_label(value))</title></rect>",
        )
    end
    return "<svg viewBox=\"0 0 $width $height\" role=\"img\" aria-label=\"Matrix heatmap\">$(join(cells))</svg>"
end

function shared_style(root_id)
    return """
    <style>
      #$root_id { color: var(--pluto-output-color, #222); width: 100%; font-family: system-ui, sans-serif; }
      #$root_id .nv-controls { display: flex; gap: .75rem; align-items: center; flex-wrap: wrap; margin: .5rem 0 1rem; }
      #$root_id .nv-launch { display: flex; align-items: center; justify-content: space-between; gap: 1rem; flex-wrap: wrap; margin: .7rem 0; }
      #$root_id .nv-play { appearance: none; border: 1px solid #64748b; border-radius: .45rem; background: #2563eb; color: white; padding: .45rem .8rem; font: inherit; font-weight: 600; cursor: pointer; }
      #$root_id .nv-play:hover { background: #1d4ed8; }
      #$root_id .nv-play:focus-visible { outline: 3px solid rgba(59,130,246,.45); outline-offset: 2px; }
      #$root_id .nv-stage[hidden] { display: none !important; }
      #$root_id input[type=range] { flex: 1 1 220px; }
      #$root_id .nv-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 1rem; }
      #$root_id .nv-panel { min-width: 0; }
      #$root_id .nv-title { font-weight: 600; margin-bottom: .35rem; }
      #$root_id .nv-subtitle { color: #666; font-size: .86rem; margin-top: .25rem; font-variant-numeric: tabular-nums; }
      #$root_id .nv-metrics { display: flex; gap: 1.25rem; flex-wrap: wrap; margin-top: .75rem; font-variant-numeric: tabular-nums; }
      #$root_id .nv-axis { stroke: #9ca3af; stroke-width: 1; }
      #$root_id .nv-gridline { stroke: #d1d5db; stroke-width: 1; }
      #$root_id .nv-label { fill: currentColor; font-size: 11px; }
      #$root_id .nv-muted { fill: #6b7280; font-size: 10px; }
      #$root_id .nv-frame[hidden] { display: none; }
      @media (prefers-color-scheme: dark) {
        #$root_id .nv-subtitle { color: #bbb; }
        #$root_id .nv-gridline, #$root_id .nv-axis { stroke: #555; }
        #$root_id .nv-muted { fill: #bbb; }
        #$root_id .nv-play { border-color: #93c5fd; }
      }
    </style>
    """
end

diagram_cells(count::Integer) = join("<i></i>" for _ in 1:count)

function diagram_tensor(label, class_name; layers = 4)
    layer_html = join("<span style=\"--layer:$layer\"></span>" for layer in 0:(layers - 1))
    return """
    <div class="di-object $class_name">
      <div class="di-stack">$layer_html</div>
      <div class="di-object-label">$label</div>
    </div>
    """
end

function diagram_factor(label, class_name)
    return """
    <div class="di-factor $class_name" aria-label="$label factor matrix">
      <div class="di-factor-grid">$(diagram_cells(12))</div>
      <span>$label</span>
    </div>
    """
end

function diagram_cpd_term(component_label)
    return """
    <div class="di-cpd-term" aria-label="rank-one component $component_label: a $component_label outer product b $component_label outer product c $component_label">
      <div class="di-cpd-arm di-cpd-a"><i></i><span>a<sub>$component_label</sub></span></div>
      <div class="di-cpd-arm di-cpd-b"><i></i><span>b<sub>$component_label</sub></span></div>
      <div class="di-cpd-arm di-cpd-c"><i></i><span>c<sub>$component_label</sub></span></div>
      <div class="di-cpd-joint">⊗</div>
      <div class="di-rank-caption">λ<sub>$component_label</sub>(a<sub>$component_label</sub> ⊗ b<sub>$component_label</sub> ⊗ c<sub>$component_label</sub>)</div>
    </div>
    """
end

function diagram_cpd_factor_matrices()
    return """
    <div class="di-cpd-factor-group" aria-label="weight vector lambda and factor matrices A, B, and C collect the CP component coordinates">
      <div class="di-cpd-weights"><div>$(diagram_cells(4))</div><strong>λ</strong></div>
      <div class="di-cpd-matrix di-cpd-matrix-a"><div class="di-cpd-columns">$(diagram_cells(4))</div><strong>A</strong></div>
      <div class="di-cpd-matrix di-cpd-matrix-b"><div class="di-cpd-columns">$(diagram_cells(4))</div><strong>B</strong></div>
      <div class="di-cpd-matrix di-cpd-matrix-c"><div class="di-cpd-columns">$(diagram_cells(4))</div><strong>C</strong></div>
      <div class="di-cpd-factor-caption">columns: A=[a₁ ··· a<sub>R</sub>]&nbsp; B=[b₁ ··· b<sub>R</sub>]&nbsp; C=[c₁ ··· c<sub>R</sub>]</div>
    </div>
    """
end

"""
    decomposition_illustration(kind::Symbol)

Return an immediately visible structural illustration for `:cpd`, `:tucker`,
or `:btd`. The diagrams use the same visual grammar: thin stacks are tensors,
gridded plates are factor matrices, and small dark stacks are Tucker cores.
"""
function decomposition_illustration(kind::Symbol)
    kind in (:cpd, :tucker, :btd) ||
        throw(ArgumentError("kind must be :cpd, :tucker, or :btd"))

    root_id = next_id("decomposition-illustration")
    full_tensor = diagram_tensor("reconstructed tensor X̂", "di-full"; layers = 5)

    title, subtitle, accessible_label, construction = if kind == :cpd
        source_tensor = diagram_tensor("tensor X", "di-full di-cpd-source"; layers = 5)
        first_term = diagram_cpd_term("1")
        last_term = diagram_cpd_term("R")
        factor_matrices = diagram_cpd_factor_matrices()
        (
            "CPD",
            "Each component links one column from A, B, and C; their outer product is rank 1, and R terms are added.",
            "CP decomposition: tensor X is approximated by a sum of R rank-one outer products, whose vectors form the columns of factor matrices A, B, and C",
            """
            $source_tensor<span class="di-op di-cpd-approx">≈</span>
            $first_term<span class="di-op di-dots">+ ··· +</span>
            $last_term<span class="di-op">=</span>$factor_matrices
            """,
        )
    elseif kind == :tucker
        factors = join([
            diagram_factor("U⁽¹⁾", "di-factor-1"),
            diagram_factor("U⁽²⁾", "di-factor-2"),
            diagram_factor("U⁽³⁾", "di-factor-3"),
        ])
        core = diagram_tensor("core G", "di-core"; layers = 3)
        (
            "Tucker",
            "A small interaction core is expanded through a separate factor matrix for each mode.",
            "Tucker decomposition: three mode factor matrices expand a small core into the full tensor",
            """
            <div class="di-factor-bundle">$factors<div class="di-group-label">mode subspaces</div></div>
            <span class="di-op">×</span>$core<span class="di-arrow">→</span>$full_tensor
            """,
        )
    else
        blocks = [
            """
            <div class="di-block di-block-$block">
              <div class="di-block-core">G<sub>$block</sub></div>
              $(diagram_tensor("Tucker block $block", "di-block-tensor"; layers = 4))
            </div>
            """ for block in 1:2
        ]
        (
            "BTD",
            "Each term is a Tucker model; several multilinear blocks are added to reconstruct the tensor.",
            "Block term decomposition: a sum of Tucker blocks reconstructs the full tensor",
            """
            $(blocks[1])<span class="di-op">+</span>$(blocks[2])
            <span class="di-op di-dots">+ ···</span><span class="di-arrow">→</span>$full_tensor
            """,
        )
    end

    return Base.HTML("""
    <div id="$root_id" class="di-wrap">
      <style>
        #$root_id {
          --di-ink: var(--pluto-output-color, #282d24);
          --di-muted: #69705d;
          --di-paper: rgba(255,253,247,.78);
          --di-line: rgba(94,103,64,.32);
          --di-olive: #657047;
          --di-blue: #5d7e9d;
          --di-terra: #c96f4a;
          --di-ochre: #c3a04d;
          width:100%; margin:1rem 0 1.35rem; padding:18px 22px 20px;
          border:1px solid var(--di-line); border-radius:18px;
          background:linear-gradient(145deg,var(--di-paper),rgba(246,241,229,.64));
          color:var(--di-ink); font-family:Inter,Avenir Next,Avenir,system-ui,sans-serif;
          box-sizing:border-box;
        }
        #$root_id * { box-sizing:border-box; }
        #$root_id .di-heading { display:flex; align-items:baseline; gap:12px; margin-bottom:15px; }
        #$root_id .di-heading strong { color:var(--di-olive); font-size:15px; font-weight:750; letter-spacing:.08em; text-transform:uppercase; }
        #$root_id .di-heading span { color:var(--di-muted); font-size:13px; line-height:1.35; }
        #$root_id .di-flow { display:flex; min-height:126px; align-items:center; justify-content:center; gap:9px; padding:10px 4px 2px; }
        #$root_id .di-op, #$root_id .di-arrow { flex:0 0 auto; color:var(--di-muted); font-family:Georgia,serif; font-size:24px; font-weight:500; }
        #$root_id .di-arrow { color:var(--di-olive); font-size:30px; }
        #$root_id .di-dots { font-size:18px; }
        #$root_id .di-object { flex:0 0 auto; width:104px; text-align:center; }
        #$root_id .di-stack { position:relative; width:70px; height:72px; margin:0 auto 7px; perspective:500px; }
        #$root_id .di-stack span { position:absolute; left:8px; top:14px; width:55px; height:42px; border:1px solid currentColor; border-radius:5px; background:color-mix(in srgb,currentColor 17%,var(--di-paper)); box-shadow:0 5px 10px rgba(45,50,31,.07); transform:translate(calc(var(--layer) * 4px),calc(var(--layer) * -5px)) skewY(-12deg); }
        #$root_id .di-object-label { min-height:30px; color:var(--di-muted); font-family:Georgia,Cambria,serif; font-size:11px; line-height:1.2; }
        #$root_id .di-cpd-term { position:relative; flex:0 0 112px; width:112px; height:105px; }
        #$root_id .di-cpd-arm { position:absolute; color:var(--di-muted); font:11px/1 Georgia,Cambria,serif; }
        #$root_id .di-cpd-arm i { display:block; border:1px solid currentColor; background:color-mix(in srgb,currentColor 24%,var(--di-paper)); box-shadow:inset 0 0 0 1px color-mix(in srgb,currentColor 12%,transparent); }
        #$root_id .di-cpd-arm span { position:absolute; color:var(--di-ink); white-space:nowrap; }
        #$root_id .di-cpd-arm sub { font-size:8px; }
        #$root_id .di-cpd-a { left:8px; top:23px; color:var(--di-terra); }
        #$root_id .di-cpd-a i { width:11px; height:55px; background:repeating-linear-gradient(to bottom,color-mix(in srgb,var(--di-terra) 55%,var(--di-paper)) 0 10px,var(--di-paper) 10px 12px); }
        #$root_id .di-cpd-a span { left:16px; bottom:-1px; }
        #$root_id .di-cpd-b { left:25px; top:23px; color:var(--di-blue); }
        #$root_id .di-cpd-b i { width:72px; height:11px; background:repeating-linear-gradient(to right,color-mix(in srgb,var(--di-blue) 55%,var(--di-paper)) 0 12px,var(--di-paper) 12px 14px); }
        #$root_id .di-cpd-b span { right:-2px; top:16px; }
        #$root_id .di-cpd-c { left:28px; top:8px; color:var(--di-ochre); transform:rotate(-40deg); transform-origin:left center; }
        #$root_id .di-cpd-c i { width:48px; height:10px; background:repeating-linear-gradient(to right,color-mix(in srgb,var(--di-ochre) 58%,var(--di-paper)) 0 9px,var(--di-paper) 9px 11px); }
        #$root_id .di-cpd-c span { left:51px; top:-1px; transform:rotate(40deg); }
        #$root_id .di-cpd-joint { position:absolute; left:18px; top:17px; color:var(--di-muted); font:9px/1 Georgia,serif; }
        #$root_id .di-rank-caption { position:absolute; left:0; right:0; bottom:0; color:var(--di-muted); font:10px/1.1 Georgia,Cambria,serif; text-align:center; white-space:nowrap; }
        #$root_id .di-rank-caption sub { font-size:7px; }
        #$root_id .di-cpd-source { width:94px; }
        #$root_id .di-cpd-source .di-stack { transform:scale(.9); }
        #$root_id .di-cpd-approx { font-size:27px; }
        #$root_id .di-cpd-factor-group { position:relative; flex:0 0 160px; width:160px; height:112px; }
        #$root_id .di-cpd-weights { position:absolute; left:0; top:29px; width:14px; color:var(--di-olive); text-align:center; }
        #$root_id .di-cpd-weights>div { display:grid; grid-template-rows:repeat(4,1fr); gap:1px; width:8px; height:55px; margin:0 auto; border:1px solid currentColor; padding:1px; background:var(--di-paper); }
        #$root_id .di-cpd-weights i { display:block; background:currentColor; opacity:.35; }
        #$root_id .di-cpd-weights i:nth-child(1), #$root_id .di-cpd-weights i:nth-child(4) { opacity:.75; }
        #$root_id .di-cpd-weights strong { display:block; margin-top:3px; color:var(--di-ink); font:700 12px/1 Georgia,Cambria,serif; }
        #$root_id .di-cpd-matrix { position:absolute; color:var(--di-muted); }
        #$root_id .di-cpd-matrix strong { position:absolute; color:var(--di-ink); font:700 14px/1 Georgia,Cambria,serif; }
        #$root_id .di-cpd-columns { display:grid; border:1px solid currentColor; background:var(--di-paper); overflow:hidden; }
        #$root_id .di-cpd-columns i { display:block; border-right:1px solid color-mix(in srgb,currentColor 42%,transparent); background:color-mix(in srgb,currentColor 22%,var(--di-paper)); }
        #$root_id .di-cpd-columns i:last-child { border-right:0; }
        #$root_id .di-cpd-matrix-a { left:20px; top:27px; color:var(--di-terra); }
        #$root_id .di-cpd-matrix-a .di-cpd-columns { width:34px; height:59px; grid-template-columns:repeat(4,1fr); }
        #$root_id .di-cpd-matrix-a strong { left:12px; top:23px; }
        #$root_id .di-cpd-matrix-b { left:62px; top:27px; color:var(--di-blue); }
        #$root_id .di-cpd-matrix-b .di-cpd-columns { width:77px; height:31px; grid-template-columns:repeat(4,1fr); }
        #$root_id .di-cpd-matrix-b strong { left:34px; top:9px; }
        #$root_id .di-cpd-matrix-c { left:69px; top:8px; color:var(--di-ochre); transform:skewX(-38deg); }
        #$root_id .di-cpd-matrix-c .di-cpd-columns { width:52px; height:16px; grid-template-columns:repeat(4,1fr); }
        #$root_id .di-cpd-matrix-c strong { left:22px; top:1px; transform:skewX(38deg); }
        #$root_id .di-cpd-factor-caption { position:absolute; left:-5px; right:-5px; bottom:1px; color:var(--di-muted); font:9px/1.2 Georgia,Cambria,serif; text-align:center; white-space:nowrap; }
        #$root_id .di-cpd-factor-caption sub { font-size:7px; }
        #$root_id .di-full { color:var(--di-olive); width:104px; }
        #$root_id .di-full .di-stack { transform:scale(.94); }
        #$root_id .di-full .di-object-label { color:var(--di-ink); font-family:inherit; font-weight:700; }
        #$root_id .di-core { width:92px; color:var(--di-terra); }
        #$root_id .di-core .di-stack { transform:scale(.72); }
        #$root_id .di-factor-bundle { position:relative; display:flex; align-items:flex-end; gap:9px; padding-bottom:23px; }
        #$root_id .di-factor { width:54px; text-align:center; }
        #$root_id .di-factor-grid { display:grid; grid-template-columns:repeat(3,11px); grid-template-rows:repeat(4,8px); gap:2px; justify-content:center; padding:5px; border:1px solid currentColor; background:var(--di-paper); transform:skewY(-8deg); }
        #$root_id .di-factor-grid i { display:block; background:currentColor; opacity:.24; }
        #$root_id .di-factor-grid i:nth-child(3n+1) { opacity:.65; }
        #$root_id .di-factor span { display:block; margin-top:6px; color:var(--di-muted); font:11px/1 Georgia,serif; }
        #$root_id .di-factor-1 { color:var(--di-terra); }
        #$root_id .di-factor-2 { color:var(--di-blue); }
        #$root_id .di-factor-3 { color:var(--di-ochre); }
        #$root_id .di-group-label { position:absolute; left:0; right:0; bottom:0; color:var(--di-muted); font-size:10px; text-align:center; }
        #$root_id .di-block { position:relative; display:flex; align-items:center; gap:3px; padding:8px 8px 4px; border:1px dashed var(--di-line); border-radius:12px; }
        #$root_id .di-block-core { display:grid; width:28px; height:28px; place-items:center; border:1px solid currentColor; border-radius:5px; background:color-mix(in srgb,currentColor 18%,var(--di-paper)); color:inherit; font:12px/1 Georgia,serif; }
        #$root_id .di-block-tensor { width:84px; color:inherit; }
        #$root_id .di-block-tensor .di-stack { transform:scale(.72); }
        #$root_id .di-block-tensor .di-object-label { font-family:inherit; }
        #$root_id .di-block-1 { color:var(--di-blue); }
        #$root_id .di-block-2 { color:var(--di-terra); }
        @media(prefers-color-scheme:dark){
          #$root_id { --di-muted:#b9bea9; --di-paper:rgba(40,44,34,.82); --di-line:rgba(190,198,164,.34); background:linear-gradient(145deg,rgba(44,49,37,.82),rgba(32,36,29,.75)); }
        }
        @media(max-width:760px){
          #$root_id .di-heading{align-items:flex-start;flex-direction:column;gap:4px}
          #$root_id .di-flow{justify-content:flex-start;gap:8px;overflow-x:auto;padding-bottom:10px}
          #$root_id .di-object{transform:scale(.9);margin:-5px}
          #$root_id .di-cpd-term{flex-basis:112px}
        }
      </style>
      <div class="di-heading"><strong>$title</strong><span>$subtitle</span></div>
      <div class="di-flow" role="img" aria-label="$accessible_label">$construction</div>
    </div>
    """)
end

function tensor_slice_pair_markup(tensor::AbstractArray{<:Real,3}, scale; width = 72, height = 56)
    slices = [
        """
        <div class="fs-slice">
          $(heatmap_svg(tensor[:, :, slice]; width = width, height = height, scale = scale))
          <span>slice $slice</span>
        </div>
        """ for slice in axes(tensor, 3)
    ]
    return "<div class=\"fs-slices\">$(join(slices))</div>"
end

function fingerprint_card_markup(model::Symbol, lines)
    slug = lowercase(String(model))
    items = join("<li>$(escape_html(line))</li>" for line in lines)
    return """
    <div class="fs-fingerprint fs-$slug">
      <strong>$(escape_html(String(model)))</strong>
      <ul>$items</ul>
    </div>
    """
end

function factor_sign_markup(label, entries, denominator)
    negative = count(x -> x < 0, entries)
    nonnegative = length(entries) - negative
    negative_width = 100 * negative / max(denominator, 1)
    nonnegative_width = 100 * nonnegative / max(denominator, 1)
    minimum_entry = isempty(entries) ? 0.0 : minimum(entries)
    maximum_entry = isempty(entries) ? 0.0 : maximum(entries)
    return """
    <div class="fs-sign-model">
      <div class="fs-sign-head"><strong>$(escape_html(label)) factors</strong><span>range $(number_label(minimum_entry)) to $(number_label(maximum_entry))</span></div>
      <div class="fs-sign-row"><span>negative</span><div class="fs-sign-track"><i class="fs-negative" style="width:$(negative_width)%"></i></div><b>$negative</b></div>
      <div class="fs-sign-row"><span>nonnegative</span><div class="fs-sign-track"><i class="fs-nonnegative" style="width:$(nonnegative_width)%"></i></div><b>$nonnegative</b></div>
    </div>
    """
end

"""
    tensor_reconstruction_gallery(target, reconstructions; errors, fingerprints,
                                  cp_factor_entries, nncp_factor_entries)

Build the final primer synthesis: an anonymous reconstruction-identification
prompt, revealed residual and error comparisons, model fingerprints, and a
CP-versus-NNCP coordinate-sign comparison. `reconstructions`, `errors`, and
`fingerprints` must contain `Tucker`, `CP`, `BTD`, and `NNCP` fields.
"""
function tensor_reconstruction_gallery(
    target::AbstractArray{<:Real,3},
    reconstructions::NamedTuple;
    errors::NamedTuple,
    fingerprints::NamedTuple,
    cp_factor_entries::AbstractVector,
    nncp_factor_entries::AbstractVector,
)
    ndims(target) == 3 || throw(ArgumentError("The synthesis gallery expects an order-three tensor."))
    required_models = (:Tucker, :CP, :BTD, :NNCP)
    for model in required_models
        hasproperty(reconstructions, model) || throw(ArgumentError("Missing $model reconstruction."))
        hasproperty(errors, model) || throw(ArgumentError("Missing $model error."))
        hasproperty(fingerprints, model) || throw(ArgumentError("Missing $model fingerprint."))
        size(getproperty(reconstructions, model)) == size(target) ||
            throw(ArgumentError("$model reconstruction has the wrong size."))
    end

    root_id = next_id("tensor-synthesis")
    display_order = (:BTD, :Tucker, :NNCP, :CP)
    letters = ('A', 'B', 'C', 'D')
    reconstruction_scale = maximum([
        maximum(abs, target; init = 0.0),
        [maximum(abs, getproperty(reconstructions, model); init = 0.0) for model in required_models]...,
    ])
    residuals = Dict(
        model => abs.(target .- getproperty(reconstructions, model)) for model in required_models
    )
    residual_scale = maximum(maximum(residuals[model]; init = 0.0) for model in required_models)
    maximum_error = maximum(getproperty(errors, model) for model in required_models)

    original_markup = tensor_slice_pair_markup(target, reconstruction_scale; width = 108, height = 78)
    anonymous_cards = String[]
    for (letter, model) in zip(letters, display_order)
        slug = lowercase(String(model))
        slices = tensor_slice_pair_markup(
            getproperty(reconstructions, model),
            reconstruction_scale;
            width = 64,
            height = 48,
        )
        push!(anonymous_cards, """
        <div class="fs-reconstruction fs-$slug">
          <div class="fs-card-title"><strong>$letter</strong><span data-reveal-name hidden>$(escape_html(String(model)))</span></div>
          $slices
        </div>
        """)
    end

    residual_cards = String[]
    error_rows = String[]
    fingerprint_cards = String[]
    for model in required_models
        slug = lowercase(String(model))
        residual_markup = tensor_slice_pair_markup(
            residuals[model],
            residual_scale;
            width = 64,
            height = 48,
        )
        maximum_residual = maximum(residuals[model]; init = 0.0)
        push!(residual_cards, """
        <div class="fs-residual fs-$slug">
          <strong>$(escape_html(String(model)))</strong>
          $residual_markup
          <span>max |residual| = $(number_label(maximum_residual))</span>
        </div>
        """)

        error_value = getproperty(errors, model)
        error_width = iszero(maximum_error) ? 0.0 : 100 * error_value / maximum_error
        push!(error_rows, """
        <div class="fs-error-row fs-$slug">
          <strong>$(escape_html(String(model)))</strong>
          <div class="fs-error-track"><i style="width:$(error_width)%"></i></div>
          <span>$(@sprintf("%.3e", error_value))</span>
        </div>
        """)

        push!(
            fingerprint_cards,
            fingerprint_card_markup(model, getproperty(fingerprints, model)),
        )
    end

    factor_denominator = max(length(cp_factor_entries), length(nncp_factor_entries))
    factor_signs = join([
        factor_sign_markup("CP", cp_factor_entries, factor_denominator),
        factor_sign_markup("NNCP", nncp_factor_entries, factor_denominator),
    ])

    return Base.HTML("""
    <div id="$root_id" class="fs-root">
      <style>
        #$root_id {
          --fs-ink:var(--pluto-output-color,#282d24); --fs-muted:#69705d;
          --fs-paper:rgba(255,253,247,.76); --fs-line:rgba(94,103,64,.3);
          --fs-olive:#657047; --fs-blue:#5d7e9d; --fs-terra:#c96f4a; --fs-ochre:#c3a04d;
          width:100%; color:var(--fs-ink); font-family:Inter,Avenir Next,Avenir,system-ui,sans-serif;
        }
        #$root_id *{box-sizing:border-box}
        #$root_id .fs-section{padding:22px 0;border-top:1px solid var(--fs-line)}
        #$root_id .fs-section:first-child{border-top:0;padding-top:8px}
        #$root_id .fs-kicker{margin-bottom:5px;color:var(--fs-olive);font-size:12px;font-weight:750;letter-spacing:.11em;text-transform:uppercase}
        #$root_id .fs-title{margin-bottom:13px;color:var(--fs-ink);font-size:18px;font-weight:720;line-height:1.25}
        #$root_id .fs-subtitle{margin:8px 0 13px;color:var(--fs-muted);font-size:13px;line-height:1.4}
        #$root_id .fs-original{display:flex;justify-content:center;text-align:center}
        #$root_id .fs-original>div{padding:12px 18px;border:1px solid var(--fs-line);border-radius:14px;background:var(--fs-paper)}
        #$root_id .fs-original strong{display:block;margin-bottom:8px;font-size:13px}
        #$root_id .fs-slices{display:flex;justify-content:center;gap:5px}
        #$root_id .fs-slice{min-width:0;text-align:center}
        #$root_id .fs-slice svg{display:block;width:100%;height:auto;border-radius:4px}
        #$root_id .fs-slice span{display:block;margin-top:3px;color:var(--fs-muted);font-size:9px}
        #$root_id .fs-question{margin:17px auto 10px;max-width:590px;text-align:center}
        #$root_id .fs-question strong{display:block;font-size:16px}
        #$root_id .fs-question span{color:var(--fs-muted);font-size:12px}
        #$root_id .fs-reconstruction-grid,#$root_id .fs-residual-grid,#$root_id .fs-fingerprint-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px}
        #$root_id .fs-reconstruction,#$root_id .fs-residual{min-width:0;padding:10px 7px;border-top:3px solid var(--model-color);background:color-mix(in srgb,var(--model-color) 6%,transparent);text-align:center}
        #$root_id .fs-card-title{display:flex;justify-content:center;gap:5px;min-height:22px;align-items:baseline}
        #$root_id .fs-card-title strong{font-size:17px}
        #$root_id .fs-card-title span{color:var(--fs-muted);font-size:11px}
        #$root_id .fs-tucker{--model-color:var(--fs-olive)} #$root_id .fs-cp{--model-color:var(--fs-blue)}
        #$root_id .fs-btd{--model-color:var(--fs-terra)} #$root_id .fs-nncp{--model-color:var(--fs-ochre)}
        #$root_id .fs-reveal-row{display:flex;justify-content:center;margin-top:14px}
        #$root_id .fs-reveal{appearance:none;border:1px solid var(--fs-olive);border-radius:999px;background:var(--fs-olive);color:#fff;padding:9px 15px;font:700 13px/1 system-ui,sans-serif;cursor:pointer}
        #$root_id .fs-reveal:disabled{cursor:default;opacity:.68}
        #$root_id .fs-answer{min-height:19px;margin-top:9px;color:var(--fs-muted);font-size:12px;text-align:center}
        #$root_id .fs-residual>strong{display:block;margin-bottom:6px;font-size:12px}
        #$root_id .fs-residual>span{display:block;margin-top:5px;color:var(--fs-muted);font-size:9px}
        #$root_id .fs-error-chart{display:grid;gap:9px;margin-top:8px}
        #$root_id .fs-error-row{display:grid;grid-template-columns:68px 1fr 85px;gap:9px;align-items:center}
        #$root_id .fs-error-row strong{font-size:12px}
        #$root_id .fs-error-row span{font:11px/1.2 ui-monospace,SFMono-Regular,monospace;text-align:right}
        #$root_id .fs-error-track{height:11px;border-radius:6px;background:rgba(94,103,64,.12);overflow:hidden}
        #$root_id .fs-error-track i{display:block;height:100%;border-radius:inherit;background:var(--model-color)}
        #$root_id .fs-warning{margin-top:13px;padding:10px 12px;border-left:3px solid var(--fs-ochre);background:color-mix(in srgb,var(--fs-ochre) 8%,transparent);color:var(--fs-muted);font-size:12px;line-height:1.4}
        #$root_id .fs-warning strong{color:var(--fs-ink)}
        #$root_id .fs-fingerprint{min-width:0;padding:11px 10px;border-top:3px solid var(--model-color);background:color-mix(in srgb,var(--model-color) 6%,transparent)}
        #$root_id .fs-fingerprint>strong{font-size:12px}
        #$root_id .fs-fingerprint ul{margin:7px 0 0;padding-left:15px;color:var(--fs-muted);font-size:10px;line-height:1.45}
        #$root_id .fs-sign-grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}
        #$root_id .fs-sign-model{min-width:0}
        #$root_id .fs-sign-head{display:flex;justify-content:space-between;gap:8px;margin-bottom:10px}
        #$root_id .fs-sign-head strong{font-size:12px}
        #$root_id .fs-sign-head span{color:var(--fs-muted);font-size:10px}
        #$root_id .fs-sign-row{display:grid;grid-template-columns:72px 1fr 24px;gap:7px;align-items:center;margin:6px 0}
        #$root_id .fs-sign-row>span,#$root_id .fs-sign-row>b{color:var(--fs-muted);font-size:10px;font-weight:600}
        #$root_id .fs-sign-row>b{text-align:right}
        #$root_id .fs-sign-track{height:9px;border-radius:5px;background:rgba(94,103,64,.12);overflow:hidden}
        #$root_id .fs-sign-track i{display:block;height:100%;border-radius:inherit}
        #$root_id .fs-negative{background:var(--fs-terra)} #$root_id .fs-nonnegative{background:var(--fs-olive)}
        #$root_id .fs-bridge{margin-top:18px;padding:16px;border:1px solid var(--fs-line);border-radius:14px;background:var(--fs-paper);text-align:center}
        #$root_id .fs-bridge strong{display:block;font:600 18px/1.25 Georgia,Cambria,serif}
        #$root_id .fs-bridge span{display:block;margin-top:6px;color:var(--fs-muted);font-size:12px}
        #$root_id [hidden]{display:none!important}
        @media(prefers-color-scheme:dark){
          #$root_id{--fs-muted:#bcc1ae;--fs-paper:rgba(40,44,34,.78);--fs-line:rgba(190,198,164,.32)}
        }
        @media(max-width:720px){
          #$root_id .fs-reconstruction-grid,#$root_id .fs-residual-grid,#$root_id .fs-fingerprint-grid{grid-template-columns:repeat(2,minmax(0,1fr))}
          #$root_id .fs-sign-grid{grid-template-columns:1fr}
        }
      </style>

      <section class="fs-section">
        <div class="fs-kicker">A · What object did they reconstruct?</div>
        <div class="fs-title">One tensor, four reconstructions</div>
        <div class="fs-original"><div><strong>Original tensor · 3 × 2 × 2</strong>$original_markup</div></div>
        <div class="fs-question"><strong>Can you identify the model from the reconstruction alone?</strong><span>The cards are deliberately shuffled. Inspect the two slices before revealing their names.</span></div>
        <div class="fs-reconstruction-grid">$(join(anonymous_cards))</div>
        <div class="fs-reveal-row"><button class="fs-reveal" type="button">Reveal models</button></div>
        <div class="fs-answer" aria-live="polite">Similar-looking reconstructions can come from different coordinate systems.</div>
      </section>

      <div class="fs-post-reveal" hidden>
        <section class="fs-section">
          <div class="fs-kicker">B · Where did each fit miss?</div>
          <div class="fs-title">Absolute residuals |A − X̂|</div>
          <div class="fs-residual-grid">$(join(residual_cards))</div>
        </section>

        <section class="fs-section">
          <div class="fs-kicker">C · How well did these particular fits reconstruct it?</div>
          <div class="fs-title">Relative reconstruction error</div>
          <div class="fs-error-chart" role="img" aria-label="Relative reconstruction errors for Tucker, CP, BTD, and NNCP">$(join(error_rows))</div>
          <div class="fs-warning"><strong>Not a model-selection benchmark.</strong> Tucker uses rank (2,2,1); CP and NNCP use rank 2; BTD uses two rank-(1,1,1) blocks. The bars describe these particular fits, not a fair capacity-matched competition.</div>
        </section>

        <section class="fs-section">
          <div class="fs-kicker">D · What coordinates did they learn?</div>
          <div class="fs-title">Model fingerprints</div>
          <div class="fs-fingerprint-grid">$(join(fingerprint_cards))</div>
        </section>

        <section class="fs-section">
          <div class="fs-kicker">E · What changes when coordinates must be nonnegative?</div>
          <div class="fs-title">CP versus NNCP factor-coordinate range</div>
          <div class="fs-sign-grid">$factor_signs</div>
          <div class="fs-warning"><strong>Constraint changes the admissible explanation.</strong> CP permits signed factor entries; NNCP restricts every factor coordinate to the nonnegative region, even when the reconstructed tensors look similar.</div>
          <div class="fs-bridge"><strong>Similar reconstructed objects ≠ the same internal representation.</strong><span>Lab 1 continues with the distinction between the represented object and its coordinates.</span></div>
        </section>
      </div>

      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const button = root.querySelector('.fs-reveal');
          const answer = root.querySelector('.fs-answer');
          const laterSections = root.querySelector('.fs-post-reveal');
          button.addEventListener('click', () => {
            root.querySelectorAll('[data-reveal-name]').forEach(label => label.hidden = false);
            laterSections.hidden = false;
            button.textContent = 'Models revealed';
            button.disabled = true;
            answer.textContent = 'A = BTD · B = Tucker · C = NNCP · D = CP. The object alone did not reveal the coordinate system.';
          });
        })();
      </script>
    </div>
    """)
end

function play_button()
    return """
    <button
      class=\"nv-play\"
      type=\"button\"
      aria-expanded=\"false\"
      onclick=\"const stage=this.parentElement.nextElementSibling; stage.hidden=!stage.hidden; this.textContent=stage.hidden?'▶ Experiment':'Hide results'; this.setAttribute('aria-expanded',String(!stage.hidden));\"
    >▶ Experiment</button>
    """
end

function gauge_visual(X::AbstractMatrix)
    root_id = next_id("gauge-visual")
    matrix_svg = heatmap_svg(X; width = 210, height = 155)
    return Base.HTML("""
    <div id=\"$root_id\">
      $(shared_style(root_id))
      <div class=\"nv-launch\">
        <div class=\"nv-title\">Matrix gauge experiment</div>
        $(play_button())
      </div>
      <div class=\"nv-stage\" hidden>
        <div class=\"nv-controls\">
          <label for=\"$root_id-scale\"><strong>Move the gauge:</strong> log₁₀(s)</label>
          <input id=\"$root_id-scale\" type=\"range\" min=\"-4\" max=\"4\" step=\"0.1\" value=\"0\">
          <output id=\"$root_id-scale-value\">s = 1</output>
        </div>
        <div class=\"nv-grid\">
          <div class=\"nv-panel\">
            <div class=\"nv-title\">Latent coordinate grid</div>
            <svg viewBox=\"0 0 260 180\" role=\"img\" aria-label=\"Gauge deformation of latent coordinates\">
              <line class=\"nv-axis\" x1=\"20\" y1=\"90\" x2=\"240\" y2=\"90\"></line>
              <line class=\"nv-axis\" x1=\"130\" y1=\"15\" x2=\"130\" y2=\"165\"></line>
              <ellipse id=\"$root_id-ellipse\" cx=\"130\" cy=\"90\" rx=\"50\" ry=\"50\" fill=\"rgba(37,99,235,.16)\" stroke=\"#2563eb\" stroke-width=\"2\"></ellipse>
              <line id=\"$root_id-axis-a\" x1=\"130\" y1=\"90\" x2=\"180\" y2=\"90\" stroke=\"#d97706\" stroke-width=\"3\"></line>
              <line id=\"$root_id-axis-b\" x1=\"130\" y1=\"90\" x2=\"130\" y2=\"40\" stroke=\"#059669\" stroke-width=\"3\"></line>
            </svg>
            <div class=\"nv-subtitle\">The factor coordinates stretch and compress.</div>
          </div>
          <div class=\"nv-panel\">
            <div class=\"nv-title\">Represented matrix X</div>
            $matrix_svg
            <div class=\"nv-subtitle\"><strong>Unchanged</strong> for every slider value.</div>
          </div>
        </div>
        <div class=\"nv-metrics\">
          <span>κ(Q) = <strong id=\"$root_id-condition\">1</strong></span>
          <span>relative object change ≈ <strong>0</strong></span>
        </div>
      </div>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const slider = root.querySelector('#$root_id-scale');
          const ellipse = root.querySelector('#$root_id-ellipse');
          const axisA = root.querySelector('#$root_id-axis-a');
          const axisB = root.querySelector('#$root_id-axis-b');
          const output = root.querySelector('#$root_id-scale-value');
          const condition = root.querySelector('#$root_id-condition');
          const format = x => (x >= 1e4 || x < 1e-3) ? x.toExponential(1) : x.toPrecision(3).replace(/\\.?0+\$/, '');
          const update = () => {
            const exponent = Number(slider.value);
            const scale = Math.pow(10, exponent);
            const stretch = Math.pow(10, .22 * exponent);
            const rx = Math.max(8, Math.min(105, 50 * stretch));
            const ry = Math.max(8, Math.min(72, 50 / stretch));
            ellipse.setAttribute('rx', rx);
            ellipse.setAttribute('ry', ry);
            axisA.setAttribute('x2', 130 + rx);
            axisB.setAttribute('y2', 90 - ry);
            output.value = 's = ' + format(scale);
            output.textContent = output.value;
            condition.textContent = format(Math.pow(10, 2 * Math.abs(exponent)));
          };
          slider.addEventListener('input', update);
          update();
        })();
      </script>
    </div>
    """)
end

function tensor_slices_visual(
    pairs::Pair...;
    title = "Inspect tensor slices",
    shared_scale = false,
    reveal = true,
)
    isempty(pairs) && throw(ArgumentError("Provide at least one labelled tensor."))
    tensors = [last(pair) for pair in pairs]
    all(ndims(tensor) == 3 for tensor in tensors) ||
        throw(ArgumentError("Slice visual expects order-three tensors."))
    slice_count = minimum(size(tensor, 3) for tensor in tensors)
    global_scale = maximum(maximum(abs, tensor; init = 0.0) for tensor in tensors)
    root_id = next_id("tensor-slices")
    panels = String[]
    for pair in pairs
        label, tensor = pair
        scale = shared_scale ? global_scale : maximum(abs, tensor; init = 0.0)
        frames = [
            "<div class=\"nv-frame\" data-slice=\"$slice\" $(slice == 1 ? "" : "hidden")>$(heatmap_svg(tensor[:, :, slice]; scale = scale))</div>" for
            slice in 1:slice_count
        ]
        push!(panels, """
        <div class=\"nv-panel\">
          <div class=\"nv-title\">$(escape_html(label))</div>
          $(join(frames))
          <div class=\"nv-subtitle\">color range ±$(number_label(scale))</div>
        </div>
        """)
    end
    launch = reveal ? "<div class=\"nv-launch\"><div class=\"nv-title\">$(escape_html(title))</div>$(play_button())</div>" :
             "<div class=\"nv-title\" style=\"margin-bottom:.75rem\">$(escape_html(title))</div>"
    hidden = reveal ? "hidden" : ""
    return Base.HTML("""
    <div id=\"$root_id\">
      $(shared_style(root_id))
      $launch
      <div class=\"nv-stage\" $hidden>
        <div class=\"nv-controls\">
          <label for=\"$root_id-slice\">Slice</label>
          <input id=\"$root_id-slice\" type=\"range\" min=\"1\" max=\"$slice_count\" step=\"1\" value=\"1\">
          <output id=\"$root_id-slice-value\">1 / $slice_count</output>
        </div>
        <div class=\"nv-grid\">$(join(panels))</div>
      </div>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const slider = root.querySelector('#$root_id-slice');
          const output = root.querySelector('#$root_id-slice-value');
          const update = () => {
            const selected = slider.value;
            root.querySelectorAll('.nv-frame').forEach(frame => frame.hidden = frame.dataset.slice !== selected);
            output.value = selected + ' / $slice_count';
            output.textContent = output.value;
          };
          slider.addEventListener('input', update);
          update();
        })();
      </script>
    </div>
    """)
end

function profile_svg(values::AbstractVector; width = 240, height = 125, scale = nothing)
    count = length(values)
    maxabs = isnothing(scale) ? maximum(abs, values; init = 1.0) : scale
    baseline = height / 2
    bar_width = width / max(count, 1)
    bars = String[]
    for (index, value) in enumerate(values)
        magnitude = 0.42 * height * abs(value) / max(maxabs, eps())
        y = value ≥ 0 ? baseline - magnitude : baseline
        color = value ≥ 0 ? "#2563eb" : "#dc2626"
        push!(bars, "<rect x=\"$((index - 1) * bar_width + 1)\" y=\"$y\" width=\"$(max(bar_width - 2, 1))\" height=\"$magnitude\" fill=\"$color\"><title>index $index: $(number_label(value))</title></rect>")
    end
    return """
    <svg viewBox=\"0 0 $width $height\" role=\"img\" aria-label=\"Signed factor profile\">
      <line class=\"nv-axis\" x1=\"0\" y1=\"$baseline\" x2=\"$width\" y2=\"$baseline\"></line>
      $(join(bars))
    </svg>
    """
end

function cp_components_visual(models::Pair...; mode_names = ("Mode 1", "Mode 2", "Mode 3"), title = "Inspect CP coordinates")
    isempty(models) && throw(ArgumentError("Provide at least one labelled CP model."))
    first_weights, first_factors = last(first(models))
    rank = length(first_weights)
    model_values = [last(model) for model in models]
    root_id = next_id("cp-components")
    model_panels = String[]
    for model in models
        label = first(model)
        weights, factors = last(model)
        components = String[]
        for component in 1:rank
            modes = String[]
            for mode in eachindex(factors)
                shared_scale = maximum(
                    maximum(abs, model_factors[mode][:, component]; init = 0.0) for
                    (_, model_factors) in model_values
                )
                push!(
                    modes,
                    "<div><div class=\"nv-subtitle\">$(escape_html(mode_names[mode])) · shared scale ±$(number_label(shared_scale))</div>$(profile_svg(factors[mode][:, component]; scale = shared_scale))</div>",
                )
            end
            push!(components, """
            <div class=\"nv-frame\" data-component=\"$component\" $(component == 1 ? "" : "hidden")>
              <div class=\"nv-subtitle\">component weight = $(number_label(weights[component]))</div>
              <div class=\"nv-grid\">$(join(modes))</div>
            </div>
            """)
        end
        push!(model_panels, "<div class=\"nv-panel\"><div class=\"nv-title\">$(escape_html(label))</div>$(join(components))</div>")
    end
    return Base.HTML("""
    <div id=\"$root_id\">
      $(shared_style(root_id))
      <div class=\"nv-launch\">
        <div class=\"nv-title\">$(escape_html(title))</div>
        $(play_button())
      </div>
      <div class=\"nv-stage\" hidden>
        <div class=\"nv-controls\">
          <label for=\"$root_id-component\">Component</label>
          <input id=\"$root_id-component\" type=\"range\" min=\"1\" max=\"$rank\" step=\"1\" value=\"1\">
          <output id=\"$root_id-component-value\">1 / $rank</output>
        </div>
        <div class=\"nv-grid\">$(join(model_panels))</div>
      </div>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const slider = root.querySelector('#$root_id-component');
          const output = root.querySelector('#$root_id-component-value');
          const update = () => {
            const selected = slider.value;
            root.querySelectorAll('.nv-frame').forEach(frame => frame.hidden = frame.dataset.component !== selected);
            output.value = selected + ' / $rank';
            output.textContent = output.value;
          };
          slider.addEventListener('input', update);
          update();
        })();
      </script>
    </div>
    """)
end

function trajectory_visual(
    pairs::Pair...;
    title = "Optimization trajectory",
    logscale = true,
    reveal = true,
)
    isempty(pairs) && throw(ArgumentError("Provide at least one labelled trajectory."))
    histories = [collect(float.(last(pair))) for pair in pairs]
    maximum_length = maximum(length, histories)
    transformed = [logscale ? log10.(max.(history, eps())) : history for history in histories]
    ymin = minimum(minimum, transformed)
    ymax = maximum(maximum, transformed)
    yrange = max(ymax - ymin, eps())
    width, height = 620, 245
    left, right, top, bottom = 48, 16, 16, 35
    plot_width = width - left - right
    plot_height = height - top - bottom
    colors = ["#2563eb", "#d97706", "#059669", "#dc2626"]
    root_id = next_id("trajectory")
    lines = String[]
    markers = String[]
    js_points = String[]
    legend = String[]
    for (index, pair) in enumerate(pairs)
        label = first(pair)
        history = histories[index]
        values = transformed[index]
        xs = [left + plot_width * (iteration - 1) / max(maximum_length - 1, 1) for iteration in eachindex(values)]
        ys = [top + plot_height * (1 - (value - ymin) / yrange) for value in values]
        points = join(["$(xs[i]),$(ys[i])" for i in eachindex(xs)], " ")
        color = colors[mod1(index, length(colors))]
        push!(lines, "<polyline points=\"$points\" fill=\"none\" stroke=\"$color\" stroke-width=\"2.5\"></polyline>")
        push!(markers, "<circle id=\"$root_id-marker-$index\" cx=\"$(first(xs))\" cy=\"$(first(ys))\" r=\"4.5\" fill=\"$color\"></circle>")
        push!(js_points, "[$(join(["[$(xs[i]),$(ys[i]),$(history[i])]" for i in eachindex(xs)], ","))]")
        push!(legend, "<span><span style=\"display:inline-block;width:.8rem;height:.8rem;background:$color;margin-right:.35rem\"></span>$(escape_html(label)): <strong id=\"$root_id-value-$index\">$(number_label(first(history)))</strong></span>")
    end
    launch = reveal ? "<div class=\"nv-launch\"><div class=\"nv-title\">$(escape_html(title))</div>$(play_button())</div>" :
             "<div class=\"nv-title\" style=\"margin-bottom:.75rem\">$(escape_html(title))</div>"
    hidden = reveal ? "hidden" : ""
    return Base.HTML("""
    <div id=\"$root_id\">
      $(shared_style(root_id))
      $launch
      <div class=\"nv-stage\" $hidden>
        <svg viewBox=\"0 0 $width $height\" role=\"img\" aria-label=\"Line chart of optimization trajectories\">
        <line class=\"nv-axis\" x1=\"$left\" y1=\"$(height-bottom)\" x2=\"$(width-right)\" y2=\"$(height-bottom)\"></line>
        <line class=\"nv-axis\" x1=\"$left\" y1=\"$top\" x2=\"$left\" y2=\"$(height-bottom)\"></line>
        <line id=\"$root_id-cursor\" x1=\"$left\" y1=\"$top\" x2=\"$left\" y2=\"$(height-bottom)\" stroke=\"#6b7280\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line>
        $(join(lines))
        $(join(markers))
        <text class=\"nv-muted\" x=\"$left\" y=\"$(height-8)\">iteration 1</text>
        <text class=\"nv-muted\" x=\"$(width-right)\" y=\"$(height-8)\" text-anchor=\"end\">iteration $maximum_length</text>
        <text class=\"nv-muted\" x=\"12\" y=\"$(top+5)\">$(logscale ? "log₁₀" : "value")</text>
        </svg>
        <div class=\"nv-controls\">
          <label for=\"$root_id-iteration\">Inspect iteration</label>
          <input id=\"$root_id-iteration\" type=\"range\" min=\"1\" max=\"$maximum_length\" step=\"1\" value=\"1\">
          <output id=\"$root_id-iteration-value\">1 / $maximum_length</output>
        </div>
        <div class=\"nv-metrics\">$(join(legend))</div>
      </div>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const slider = root.querySelector('#$root_id-iteration');
          const output = root.querySelector('#$root_id-iteration-value');
          const cursor = root.querySelector('#$root_id-cursor');
          const series = [$(join(js_points, ","))];
          const format = x => (Math.abs(x) >= 1e4 || (Math.abs(x) > 0 && Math.abs(x) < 1e-3)) ? x.toExponential(2) : x.toPrecision(4);
          const update = () => {
            const iteration = Number(slider.value);
            const cursorX = $left + $plot_width * (iteration - 1) / Math.max($maximum_length - 1, 1);
            cursor.setAttribute('x1', cursorX);
            cursor.setAttribute('x2', cursorX);
            series.forEach((points, index) => {
              const point = points[Math.min(iteration, points.length) - 1];
              const marker = root.querySelector('#$root_id-marker-' + (index + 1));
              marker.setAttribute('cx', point[0]);
              marker.setAttribute('cy', point[1]);
              root.querySelector('#$root_id-value-' + (index + 1)).textContent = format(point[2]);
            });
            output.value = iteration + ' / $maximum_length';
            output.textContent = output.value;
          };
          slider.addEventListener('input', update);
          update();
        })();
      </script>
    </div>
    """)
end

function paired_profile_svg(first_profile, second_profile; width = 250, height = 92)
    count = min(length(first_profile), length(second_profile))
    all_values = vcat(first_profile[1:count], second_profile[1:count])
    lower, upper = extrema(all_values)
    span = max(upper - lower, eps())
    point_string(values) = join([
        "$(18 + (width - 36) * (index - 1) / max(count - 1, 1)),$(10 + (height - 24) * (1 - (values[index] - lower) / span))" for
        index = 1:count
    ], " ")
    return """
    <svg viewBox="0 0 $width $height" role="img" aria-label="Solid component one profile and dashed component two profile">
      <line class="cc-grid" x1="18" y1="$(height-13)" x2="$(width-18)" y2="$(height-13)"></line>
      <polyline class="cc-profile-one" points="$(point_string(first_profile))"></polyline>
      <polyline class="cc-profile-two" points="$(point_string(second_profile))"></polyline>
    </svg>
    """
end

"""
    failure_map_visual()

Separate the observation of slow optimization from several possible diagnoses.
"""
function failure_map_visual()
    root_id = next_id("failure-map")
    causes = [
        ("Component collision", "Rank-one directions become hard to distinguish."),
        ("Degeneracy / cancellation", "Large signed terms hide behind a bounded sum."),
        ("Poor initialization", "The run starts in an unhelpful optimization region."),
        ("Rank choice", "Redundant or wrong rank changes the coordinate geometry."),
        ("Scaling imbalance", "Equivalent factors can have numerically uneven scales."),
        ("Noise / model mismatch", "The requested CP model may not match the data."),
    ]
    cards = join([
        "<div class=\"fm-cause\"><strong>$(escape_html(title))</strong><span>$(escape_html(copy))</span></div>" for
        (title, copy) in causes
    ])
    return Base.HTML("""
    <div id="$root_id" class="fm-wrap" aria-label="Map of possible reasons for slow CP optimization">
      <style>
        #$root_id { color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;width:100%; }
        #$root_id .fm-question { color:#4f5934;font-size:1.08rem;font-weight:700;margin-bottom:.6rem; }
        #$root_id .fm-flow { display:grid;grid-template-columns:minmax(190px,.42fr) 36px minmax(0,1.58fr);align-items:center;gap:.65rem; }
        #$root_id .fm-observation { border:2px solid #c96f4a;background:#fbf2eb;border-radius:14px;padding:1rem;text-align:center; }
        #$root_id .fm-observation strong { display:block;color:#9f4f34;font-size:1rem; }
        #$root_id .fm-observation span { display:block;color:#626954;font-size:.78rem;margin-top:.25rem; }
        #$root_id .fm-arrow { color:#657047;text-align:center;font-size:1.7rem;font-weight:800; }
        #$root_id .fm-causes { display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.55rem; }
        #$root_id .fm-cause { border-left:4px solid #657047;background:#f1f2e8;padding:.6rem .7rem;min-width:0; }
        #$root_id .fm-cause strong { display:block;color:#4f5934;font-size:.84rem; }
        #$root_id .fm-cause span { display:block;color:#626954;font-size:.72rem;line-height:1.35;margin-top:.12rem; }
        #$root_id .fm-bottom { margin-top:.7rem;padding:.6rem .75rem;border-radius:10px;background:#fbfaf4;border:1px solid #d3d7c5;color:#4f5934;text-align:center;font-weight:650; }
        @media(max-width:760px){#$root_id .fm-flow{grid-template-columns:1fr}#$root_id .fm-arrow{transform:rotate(90deg)}#$root_id .fm-causes{grid-template-columns:1fr}}
        @media(prefers-color-scheme:dark){#$root_id .fm-observation{background:#382820;border-color:#cf7955}#$root_id .fm-observation strong{color:#f0a17c}#$root_id .fm-observation span,#$root_id .fm-cause span{color:#d6dcc8}#$root_id .fm-cause{background:#303526}#$root_id .fm-cause strong,#$root_id .fm-question,#$root_id .fm-bottom{color:#e6eadc}#$root_id .fm-bottom{background:#25281f;border-color:#555d45}}
      </style>
      <div class="fm-question">Why can CP optimization stall?</div>
      <div class="fm-flow">
        <div class="fm-observation"><strong>Observation: slow progress</strong><span>A plateau tells us what happened, not why.</span></div>
        <div class="fm-arrow">→</div>
        <div class="fm-causes">$cards</div>
      </div>
      <div class="fm-bottom">This lab isolates one mechanism at a time. We begin with collision because it gives a clear geometry → conditioning connection.</div>
    </div>
    """)
end

"""
    failure_comparison_visual(cases)

Compare controlled ALS runs while keeping plateau observation distinct from its diagnosis.
"""
function failure_comparison_visual(cases)
    root_id = next_id("failure-comparison")
    rows = join([
        begin
            progress_word = case.progress_orders > 4 ? "fast" : case.progress_orders > 1 ? "partial" : "slow"
            """
            <tr>
              <th scope="row">$(escape_html(case.label))</th>
              <td data-label="error reduction"><strong>$(number_label(case.progress_orders)) decades</strong><span>$progress_word</span></td>
              <td data-label="min distance"><strong>$(number_label(case.minimum_distance))</strong><span>0 means collision</span></td>
              <td data-label="max ALS κ"><strong>$(number_label(case.maximum_condition))</strong><span>larger is harder</span></td>
              <td data-label="interpretation">$(escape_html(case.interpretation))</td>
            </tr>
            """
        end for case in cases
    ])
    return Base.HTML("""
    <div id="$root_id" class="fc-wrap" aria-label="Comparison of three causes of CP optimization behavior">
      <style>
        #$root_id { color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;width:100%; }
        #$root_id .fc-title { color:#4f5934;font-size:1.05rem;font-weight:700;margin-bottom:.5rem; }
        #$root_id table { width:100%;border-collapse:separate;border-spacing:0;border:1px solid #d3d7c5;border-radius:14px;overflow:hidden;background:#fbfaf4; }
        #$root_id th,#$root_id td { padding:.65rem .7rem;text-align:left;border-bottom:1px solid #dfe2d5;vertical-align:top; }
        #$root_id thead th { color:#4f5934;background:#eef0e5;font-size:.76rem; }
        #$root_id tbody th { color:#4f5934;font-size:.82rem;white-space:nowrap; }
        #$root_id tbody tr:last-child th,#$root_id tbody tr:last-child td { border-bottom:0; }
        #$root_id td { color:#626954;font-size:.75rem; }
        #$root_id td strong { display:block;color:#303628;font-size:.88rem;font-variant-numeric:tabular-nums; }
        #$root_id td span { display:block;font-size:.68rem;color:#737a65; }
        #$root_id .fc-takeaway { display:grid;grid-template-columns:1fr 1fr;gap:.6rem;margin-top:.65rem; }
        #$root_id .fc-takeaway div { border-left:4px solid #c96f4a;background:#f1f2e8;padding:.55rem .7rem;color:#4f5934;font-weight:650; }
        #$root_id .fc-takeaway div:last-child { border-color:#657047; }
        @media(max-width:760px){#$root_id thead{display:none}#$root_id table,#$root_id tbody,#$root_id tr,#$root_id th,#$root_id td{display:block}#$root_id tbody tr{padding:.55rem;border-bottom:1px solid #dfe2d5}#$root_id th,#$root_id td{border:0;padding:.25rem .45rem}#$root_id td:before{content:attr(data-label) ' · ';font-size:.68rem;color:#737a65}#$root_id .fc-takeaway{grid-template-columns:1fr}}
        @media(prefers-color-scheme:dark){#$root_id table{background:#25281f;border-color:#555d45}#$root_id thead th,#$root_id .fc-takeaway div{background:#303526;color:#e6eadc}#$root_id tbody th,#$root_id td strong,#$root_id .fc-title{color:#e6eadc}#$root_id td,#$root_id td span{color:#c9cfbd}}
      </style>
      <div class="fc-title">Same rank and ALS budget; different diagnostic stories</div>
      <table>
        <thead><tr><th>case</th><th>reconstruction progress</th><th>minimum rank-one distance</th><th>maximum ALS conditioning</th><th>diagnosis</th></tr></thead>
        <tbody>$rows</tbody>
      </table>
      <div class="fc-takeaway"><div>Slow optimization ⇏ component collision.</div><div>Small distance + large κ is evidence for collision-induced ill-conditioning.</div></div>
    </div>
    """)
end

"""
    component_collision_visual(result)

Show two CP rank-one terms moving together. Sign-invariant rank-one distance
and ALS local conditioning are the primary diagnostics; overlap and modewise
factor cosines are kept in an expandable mathematical detail. `result` supplies `rho`,
`component_overlap`, `collision_distance`, `pair_condition`, and normalized
`factors`.
"""
function component_collision_visual(result)
    root_id = next_id("component-collision")
    rho = Float64(result.rho)
    overlap = Float64(result.component_overlap)
    collision_distance = Float64(result.collision_distance)
    pair_condition = Float64(result.pair_condition)
    modewise_similarities = [
        abs(dot(result.factors[mode][:, 1], result.factors[mode][:, 2])) for
        mode in eachindex(result.factors)
    ]
    modewise_labels = join([
        "<span>mode $mode <b>$(number_label(value))</b></span>" for
        (mode, value) in enumerate(modewise_similarities)
    ])
    profiles = join([
        """
        <div class="cc-profile-panel">
          <div class="cc-mode">Mode $mode factor columns</div>
          $(paired_profile_svg(result.factors[mode][:, 1], result.factors[mode][:, 2]))
        </div>
        """ for mode in eachindex(result.factors)
    ])
    function vector_glyph(values, label, component)
        maximum_magnitude = max(maximum(abs, values), eps())
        entries = join([
            begin
                sign_class = value >= 0 ? "positive" : "negative"
                opacity = round(0.28 + 0.72 * abs(value) / maximum_magnitude; digits = 3)
                "<i class=\"$sign_class\" style=\"opacity:$opacity\" title=\"$(number_label(value))\"></i>"
            end for value in values
        ])
        """
        <div class="cc-vector-group cc-component-$component" aria-label="$label vector for component $component">
          <div class="cc-vector-bracket">$entries</div>
          <span>$label</span>
        </div>
        """
    end
    function outer_product_term(component)
        suffix = component == 1 ? "₁" : "₂"
        vector_a = vector_glyph(result.factors[1][:, component], "a$suffix", component)
        vector_b = vector_glyph(result.factors[2][:, component], "b$suffix", component)
        vector_c = vector_glyph(result.factors[3][:, component], "c$suffix", component)
        """
        <div class="cc-term cc-component-$component">
          $vector_a<span class="cc-outer">⊗</span>$vector_b<span class="cc-outer">⊗</span>$vector_c
          <span class="cc-equals">=</span>
          <div class="cc-term-name"><strong>T$suffix</strong><span>rank-one tensor</span></div>
        </div>
        """
    end
    outer_products = outer_product_term(1) * outer_product_term(2)
    status = collision_distance > 1.0 ? "Well separated" :
             collision_distance > 0.45 ? "Beginning to approach" :
             collision_distance > 0.14 ? "Difficult to distinguish" : "Near collision"
    return Base.HTML("""
    <div id="$root_id" class="cc-wrap" aria-label="CP component collision at rho $(number_label(rho))">
      <style>
        #$root_id { color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;width:100%; }
        #$root_id .cc-heading { display:flex;justify-content:space-between;align-items:baseline;gap:1rem;flex-wrap:wrap;margin-bottom:.65rem; }
        #$root_id .cc-heading strong { font-size:1.08rem;color:#4f5934; }
        #$root_id .cc-status { color:#687050;font-weight:600; }
        #$root_id .cc-profiles { display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.65rem;min-width:0; }
        #$root_id .cc-profile-panel,#$root_id .cc-object-space { border:1px solid #d3d7c5;background:#fbfaf4;border-radius:14px;padding:.7rem;min-width:0; }
        #$root_id .cc-profile-panel { overflow:hidden; }
        #$root_id .cc-mode { color:#626954;font-size:.82rem;font-weight:650;margin-bottom:.15rem; }
        #$root_id .cc-grid { stroke:#d8d9cf;stroke-width:1; }
        #$root_id .cc-profile-one { fill:none;stroke:#5d7e9d;stroke-width:3; }
        #$root_id .cc-profile-two { fill:none;stroke:#c96f4a;stroke-width:3;stroke-dasharray:7 5; }
        #$root_id .cc-object-space { display:flex;flex-direction:column;gap:.55rem; }
        #$root_id .cc-object-title { color:#626954;font-size:.82rem;font-weight:650; }
        #$root_id .cc-outer-products { display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.65rem; }
        #$root_id .cc-term { display:flex;align-items:center;gap:.34rem;min-width:0;padding:.5rem .55rem;background:#f1f2e8;border-radius:10px; }
        #$root_id .cc-vector-group { display:grid;justify-items:center;gap:.1rem;color:#5d7e9d;flex:0 0 auto; }
        #$root_id .cc-component-2.cc-vector-group { color:#c96f4a; }
        #$root_id .cc-vector-group>span { color:#626954;font-size:.7rem;font-weight:700; }
        #$root_id .cc-vector-bracket { position:relative;display:grid;gap:2px;padding:3px 6px;min-width:29px; }
        #$root_id .cc-vector-bracket:before,#$root_id .cc-vector-bracket:after { content:'';position:absolute;top:0;bottom:0;width:4px;border-top:1.5px solid currentColor;border-bottom:1.5px solid currentColor; }
        #$root_id .cc-vector-bracket:before { left:0;border-left:1.5px solid currentColor; }
        #$root_id .cc-vector-bracket:after { right:0;border-right:1.5px solid currentColor; }
        #$root_id .cc-vector-bracket i { display:block;width:17px;height:6px;background:currentColor;border-radius:2px; }
        #$root_id .cc-vector-bracket i.negative { background:transparent;border:1.5px solid currentColor; }
        #$root_id .cc-outer,#$root_id .cc-equals { color:#687050;font-size:1rem;font-weight:700;flex:0 0 auto; }
        #$root_id .cc-term-name { display:grid;margin-left:auto;min-width:68px;color:#303628; }
        #$root_id .cc-term-name strong { font-size:1rem; }
        #$root_id .cc-term-name span { color:#626954;font-size:.68rem;white-space:nowrap; }
        #$root_id .cc-outer-note { color:#626954;font-size:.76rem;line-height:1.35; }
        #$root_id .cc-metrics { display:grid;grid-template-columns:repeat(2,1fr);gap:.55rem;margin-top:.8rem; }
        #$root_id .cc-metric { border-top:3px solid #657047;background:#f1f2e8;padding:.55rem .65rem;border-radius:0 0 8px 8px; }
        #$root_id .cc-metric span { display:block;color:#626954;font-size:.76rem; }
        #$root_id .cc-metric strong { display:block;font-size:1.05rem;font-variant-numeric:tabular-nums;color:#303628; }
        #$root_id .cc-mode-values { display:flex!important;gap:.55rem;flex-wrap:wrap;margin-top:.12rem; }
        #$root_id .cc-mode-values span { display:inline!important;color:#303628;font-size:.78rem; }
        #$root_id .cc-mode-values b { font-variant-numeric:tabular-nums; }
        #$root_id .cc-conclusion { margin:.65rem 0 0;text-align:center;color:#4f5934;font-weight:650; }
        #$root_id .cc-detail { margin-top:.8rem;border:1px solid #d3d7c5;border-radius:12px;background:#fbfaf4;overflow:hidden; }
        #$root_id .cc-detail summary { cursor:pointer;padding:.65rem .8rem;color:#626954;font-weight:650; }
        #$root_id .cc-detail-body { padding:0 .8rem .8rem; }
        #$root_id .cc-detail-equation { margin:.65rem 0 0;color:#626954;font-size:.8rem;line-height:1.45;text-align:center; }
        #$root_id .cc-detail-equation code { color:#303628;background:#f1f2e8;padding:.15rem .35rem;border-radius:5px; }
        #$root_id .cc-legend { display:flex;gap:1rem;flex-wrap:wrap;color:#626954;font-size:.8rem; }
        #$root_id .cc-line { width:28px;border-top:3px solid #5d7e9d;display:inline-block;vertical-align:middle;margin-right:.3rem; }
        #$root_id .cc-line.dashed { border-color:#c96f4a;border-top-style:dashed; }
        @media(max-width:760px){#$root_id .cc-outer-products{grid-template-columns:1fr}}
        @media(max-width:680px){#$root_id .cc-profiles{grid-template-columns:1fr}#$root_id .cc-metrics{grid-template-columns:1fr}}
        @media(max-width:430px){#$root_id .cc-term{gap:.2rem;padding:.4rem .35rem}#$root_id .cc-vector-bracket{padding-inline:5px;min-width:26px}#$root_id .cc-vector-bracket i{width:14px}#$root_id .cc-term-name{min-width:53px}#$root_id .cc-term-name span{white-space:normal}}
        @media(prefers-color-scheme:dark){#$root_id .cc-profile-panel,#$root_id .cc-object-space,#$root_id .cc-detail{background:#25281f;border-color:#555d45}#$root_id .cc-term,#$root_id .cc-metric,#$root_id .cc-detail-equation code{background:#303526}#$root_id .cc-heading strong,#$root_id .cc-status,#$root_id .cc-mode,#$root_id .cc-object-title,#$root_id .cc-vector-group>span,#$root_id .cc-outer-note,#$root_id .cc-legend,#$root_id .cc-metric span,#$root_id .cc-mode-values span,#$root_id .cc-detail summary,#$root_id .cc-detail-equation,#$root_id .cc-conclusion{color:#d6dcc8}#$root_id .cc-term-name,#$root_id .cc-term-name strong,#$root_id .cc-metric strong,#$root_id .cc-detail-equation code{color:#f2f3eb}#$root_id .cc-term-name span{color:#c6cdb9}#$root_id .cc-grid{stroke:#555}}
      </style>
      <div class="cc-heading"><strong>CPD component collision</strong><span class="cc-status">$status</span></div>
      <div class="cc-object-space">
        <div class="cc-object-title">Two rank-one tensor components</div>
        <div class="cc-outer-products">$outer_products</div>
        <div class="cc-outer-note">Each component is the outer product of three mode vectors. As ρ approaches 1, T₁ and T₂ move toward the same point in tensor space.</div>
      </div>
      <div class="cc-metrics">
        <div class="cc-metric"><span>rank-one collision distance d(T₁,T₂)</span><strong>$(number_label(collision_distance))</strong></div>
        <div class="cc-metric"><span>ALS condition number κ(H₁)</span><strong>$(number_label(pair_condition))</strong></div>
      </div>
      <div class="cc-conclusion">As rank-one distance shrinks toward zero, ALS has more difficulty deciding which component should explain the shared contribution.</div>
      <details class="cc-detail">
        <summary>Mathematical detail · Why does the overlap have this value?</summary>
        <div class="cc-detail-body">
          <div class="cc-profiles">$profiles</div>
          <div class="cc-mode-values">$modewise_labels</div>
          <div class="cc-detail-equation"><code>overlap = product of mode cosines = $(number_label(overlap)); d = √(2 − 2 × overlap) = $(number_label(collision_distance))</code></div>
          <div class="cc-legend"><span><i class="cc-line"></i>component 1</span><span><i class="cc-line dashed"></i>component 2</span></div>
        </div>
      </details>
    </div>
    """)
end

"""
    cancellation_warmup_visual(problem, sensitivity)

Explain near-cancellation first as two large, almost-opposite directions that
leave a small residual, then compare component and represented-object norms.
"""
function cancellation_warmup_visual(problem, sensitivity)
    root_id = next_id("cancellation-warmup")
    component_norms = Float64.(problem.component_norms)
    target_norm = Float64(norm(problem.target))
    scale = max(maximum(component_norms), target_norm, eps())
    bar(label, value, class_name) = """
      <div class="cw-bar-row $class_name">
        <div><span>$(escape_html(label))</span><strong>$(number_label(value))</strong></div>
        <div class="cw-track"><i style="width:$(100 * value / scale)%"></i></div>
      </div>
    """
    return Base.HTML("""
    <div id="$root_id" class="cw-wrap" aria-label="Near cancellation warm-up and norm comparison">
      <style>
        #$root_id { color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;width:100%; }
        #$root_id .cw-grid { display:grid;grid-template-columns:minmax(0,1.05fr) minmax(280px,.95fr);gap:1rem; }
        #$root_id .cw-panel { border:1px solid #d3d7c5;background:#fbfaf4;border-radius:14px;padding:.8rem;min-width:0; }
        #$root_id .cw-title { color:#4f5934;font-size:.9rem;font-weight:700;margin-bottom:.6rem; }
        #$root_id .cw-arrows { display:grid;gap:.6rem; }
        #$root_id .cw-arrow-row { display:grid;grid-template-columns:86px 1fr;align-items:center;gap:.7rem; }
        #$root_id .cw-arrow-row span { color:#626954;font-size:.78rem;font-weight:650; }
        #$root_id .cw-arrow { position:relative;height:8px;background:#5d7e9d;border-radius:999px; }
        #$root_id .cw-arrow:after { content:'';position:absolute;right:-1px;top:-5px;border-left:12px solid #5d7e9d;border-top:9px solid transparent;border-bottom:9px solid transparent; }
        #$root_id .cw-arrow.negative { width:99%;margin-left:auto;background:#c96f4a; }
        #$root_id .cw-arrow.negative:after { display:none; }
        #$root_id .cw-arrow.negative:before { content:'';position:absolute;left:-1px;top:-5px;border-right:12px solid #c96f4a;border-top:9px solid transparent;border-bottom:9px solid transparent; }
        #$root_id .cw-add { text-align:center;color:#687050;font-weight:750;font-size:.78rem;margin:.1rem 0; }
        #$root_id .cw-arrow.residual { width:8%;min-width:18px;background:#657047; }
        #$root_id .cw-arrow.residual:after { border-left-color:#657047; }
        #$root_id .cw-note { color:#626954;font-size:.76rem;line-height:1.35;margin-top:.7rem; }
        #$root_id .cw-bars { display:grid;gap:.65rem; }
        #$root_id .cw-bar-row>div:first-child { display:flex;justify-content:space-between;gap:.6rem;color:#626954;font-size:.78rem; }
        #$root_id .cw-bar-row strong { color:#303628;font-variant-numeric:tabular-nums; }
        #$root_id .cw-track { height:12px;background:#e3e5d9;border-radius:999px;overflow:hidden;margin-top:.2rem; }
        #$root_id .cw-track i { display:block;height:100%;min-width:3px;background:#5d7e9d;border-radius:inherit; }
        #$root_id .negative-term .cw-track i { background:#c96f4a; }
        #$root_id .represented .cw-track i { background:#657047; }
        #$root_id .cw-metrics { display:grid;grid-template-columns:1fr 1fr;gap:.6rem;margin-top:.75rem; }
        #$root_id .cw-metric { border-left:4px solid #657047;background:#f1f2e8;padding:.55rem .65rem; }
        #$root_id .cw-metric:last-child { border-color:#c96f4a; }
        #$root_id .cw-metric span { display:block;color:#626954;font-size:.72rem; }
        #$root_id .cw-metric strong { color:#303628;font-size:1rem;font-variant-numeric:tabular-nums; }
        @media(max-width:820px){#$root_id .cw-grid{grid-template-columns:1fr}}
        @media(max-width:480px){#$root_id .cw-metrics{grid-template-columns:1fr}}
        @media(prefers-color-scheme:dark){#$root_id .cw-panel{background:#25281f;border-color:#555d45}#$root_id .cw-title,#$root_id .cw-arrow-row span,#$root_id .cw-note,#$root_id .cw-bar-row>div:first-child,#$root_id .cw-metric span{color:#d6dcc8}#$root_id .cw-track{background:#454b3b}#$root_id .cw-metric{background:#303526}#$root_id .cw-bar-row strong,#$root_id .cw-metric strong{color:#f2f3eb}}
      </style>
      <div class="cw-grid">
        <div class="cw-panel">
          <div class="cw-title">Warm-up: two large, almost-opposite directions</div>
          <div class="cw-arrows">
            <div class="cw-arrow-row"><span>+100 T₁</span><div class="cw-arrow"></div></div>
            <div class="cw-arrow-row"><span>−99 T₂</span><div class="cw-arrow negative"></div></div>
            <div class="cw-add">add the two near-copies ↓</div>
            <div class="cw-arrow-row"><span>small residual</span><div class="cw-arrow residual"></div></div>
          </div>
          <div class="cw-note">The arrows represent directions in tensor object space. They are large individually, but point almost oppositely after the sign is included, so most of their magnitude disappears in the sum.</div>
        </div>
        <div class="cw-panel">
          <div class="cw-title">Same comparison as Frobenius norms</div>
          <div class="cw-bars">
            $(bar("‖+100 T₁‖F", component_norms[1], "positive-term"))
            $(bar("‖−99 T₂‖F", component_norms[2], "negative-term"))
            $(bar("‖represented tensor X‖F", target_norm, "represented"))
          </div>
          <div class="cw-metrics">
            <div class="cw-metric"><span>cancellation ratio</span><strong>$(number_label(problem.cancellation_ratio))</strong></div>
            <div class="cw-metric"><span>perturbation amplification</span><strong>$(number_label(sensitivity.amplification))×</strong></div>
          </div>
          <div class="cw-note">A high ratio means large hidden terms are cancelling. Amplification measures how strongly a tiny coordinate change affects the represented tensor after that balance is disturbed.</div>
        </div>
      </div>
    </div>
    """)
end

function gram_condition_visual(result)
    root_id = next_id("gram-condition")
    rho = Float64(result.rho)
    rho2 = rho^2
    lambda_sum = 1 + rho2
    lambda_difference = 1 - rho2
    condition = lambda_sum / lambda_difference
    matrix(values) = """
      <div class="gc-matrix">
        <span>$(number_label(values[1,1]))</span><span>$(number_label(values[1,2]))</span>
        <span>$(number_label(values[2,1]))</span><span>$(number_label(values[2,2]))</span>
      </div>
    """
    factor_gram = [1.0 rho; rho 1.0]
    als_gram = [1.0 rho2; rho2 1.0]
    difference_width = max(2.0, 100 * lambda_difference / lambda_sum)
    measured_mode_alignment = abs(dot(result.factors[2][:, 1], result.factors[2][:, 2]))
    predicted_overlap = rho^3
    predicted_condition = (1 + rho2) / (1 - rho2)
    return Base.HTML("""
    <details id="$root_id" class="gc-wrap">
      <style>
        #$root_id { color:var(--pluto-output-color,#303628);font:15px/1.42 system-ui;width:100%;border:1px solid #d3d7c5;border-radius:14px;padding:.75rem .9rem; }
        #$root_id>summary{cursor:pointer;font-weight:700;color:#4f5934}
        #$root_id .gc-body{margin-top:.8rem}
        #$root_id .gc-equation { display:flex;align-items:center;justify-content:center;gap:1rem;flex-wrap:wrap;padding:1rem;border:1px solid #d3d7c5;background:#fbfaf4;border-radius:14px; }
        #$root_id .gc-piece { text-align:center; }
        #$root_id .gc-label { color:#626954;font-size:.8rem;margin-bottom:.45rem; }
        #$root_id .gc-matrix { position:relative;display:grid;grid-template-columns:repeat(2,3.4rem);gap:.35rem .75rem;padding:.35rem .8rem;font-variant-numeric:tabular-nums; }
        #$root_id .gc-matrix:before,#$root_id .gc-matrix:after { content:'';position:absolute;top:0;bottom:0;width:7px;border-top:2px solid #657047;border-bottom:2px solid #657047; }
        #$root_id .gc-matrix:before { left:0;border-left:2px solid #657047; } #$root_id .gc-matrix:after { right:0;border-right:2px solid #657047; }
        #$root_id .gc-op { color:#657047;font-size:1.4rem;font-weight:650; }
        #$root_id .gc-note { flex-basis:100%;text-align:center;color:#626954;font-size:.82rem; }
        #$root_id .gc-directions { display:grid;grid-template-columns:1fr 1fr;gap:1rem;margin-top:.85rem; }
        #$root_id .gc-direction { border-left:4px solid #5d7e9d;padding:.65rem .8rem;background:#f1f2e8; }
        #$root_id .gc-direction.difference { border-color:#c96f4a; }
        #$root_id .gc-bar { height:12px;background:#5d7e9d;margin:.55rem 0 .3rem;border-radius:999px;width:100%;min-width:2px; }
        #$root_id .difference .gc-bar { background:#c96f4a;width:$(difference_width)%; }
        #$root_id .gc-direction strong { font-variant-numeric:tabular-nums; }
        #$root_id .gc-bottom { margin-top:.75rem;color:#4f5934;font-weight:650;text-align:center; }
        #$root_id .gc-compare { display:grid;grid-template-columns:minmax(145px,1.3fr) 1fr 1fr;gap:.35rem .75rem;margin-top:.85rem;padding-top:.75rem;border-top:1px solid #d3d7c5;font-variant-numeric:tabular-nums; }
        #$root_id .gc-compare strong { color:#4f5934; }
        #$root_id .gc-compare span { color:#626954; }
        @media(max-width:700px){#$root_id .gc-directions{grid-template-columns:1fr}}
        @media(max-width:520px){#$root_id .gc-compare{grid-template-columns:1fr}#$root_id .gc-compare strong{margin-top:.35rem}}
        @media(prefers-color-scheme:dark){#$root_id .gc-equation{background:#25281f;border-color:#555d45}#$root_id .gc-direction{background:#303526}}
      </style>
      <summary>Optional math · Why does ALS conditioning blow up?</summary>
      <div class="gc-body"><div class="gc-equation">
        <div class="gc-piece"><div class="gc-label">BᵀB · column similarity table</div>$(matrix(factor_gram))</div>
        <div class="gc-op">.*</div>
        <div class="gc-piece"><div class="gc-label">CᵀC · column similarity table</div>$(matrix(factor_gram))</div>
        <div class="gc-op">=</div>
        <div class="gc-piece"><div class="gc-label">Hₐ · ALS system</div>$(matrix(als_gram))</div>
        <div class="gc-note">The dots mean cell-by-cell (Hadamard) multiplication: the off-diagonal entry is ρ × ρ = ρ², not a matrix product.</div>
      </div>
      <div class="gc-directions">
        <div class="gc-direction"><strong>shared direction [1, 1]</strong><div class="gc-bar"></div><span>eigenvalue 1 + ρ² = $(number_label(lambda_sum))</span></div>
        <div class="gc-direction difference"><strong>difference direction [1, −1]</strong><div class="gc-bar"></div><span>eigenvalue 1 − ρ² = $(number_label(lambda_difference))</span></div>
      </div>
      <div class="gc-bottom">κ = $(number_label(condition)). ALS can still see the sum, but can barely tell which component contributed what.</div>
      <div class="gc-compare" aria-label="Predicted and measured collision diagnostics">
        <strong>quantity</strong><strong>predicted</strong><strong>measured</strong>
        <span>mode-vector alignment</span><span>ρ = $(number_label(rho))</span><span>$(number_label(measured_mode_alignment))</span>
        <span>rank-one overlap</span><span>ρ³ = $(number_label(predicted_overlap))</span><span>$(number_label(result.component_overlap))</span>
        <span>ALS condition number</span><span>(1+ρ²)/(1−ρ²) = $(number_label(predicted_condition))</span><span>$(number_label(result.pair_condition))</span>
      </div>
      </div>
    </details>
    """)
end

function solver_race_visual(iterations, series::Pair...; title = "Controlled solver race")
    isempty(series) && throw(ArgumentError("Provide at least one solver trace."))
    xs_data = collect(Int.(iterations))
    all(length(last(pair).errors) == length(xs_data) for pair in series) ||
        throw(ArgumentError("Every error trace must match the iteration vector."))
    has_diagnostic_trace(trace) = hasproperty(trace, :diagnostic_trace) ?
                                  trace.diagnostic_trace : !isnothing(trace.distances)
    all(
        !has_diagnostic_trace(last(pair)) ||
        length(last(pair).distances) == length(xs_data) for pair in series
    ) || throw(ArgumentError("Every available component-distance trace must match the iteration vector."))
    root_id = next_id("solver-race")
    colors = ["#5d7e9d", "#c96f4a", "#657047", "#c3a04d"]
    width, height = 560, 230
    left, right, top, bottom = 52, 18, 18, 34
    plot_width, plot_height = width - left - right, height - top - bottom
    xmin, xmax = extrema(xs_data)
    xcoord(x) = left + plot_width * (x - xmin) / max(xmax - xmin, 1)
    error_values = [log10(max(Float64(value), eps())) for pair in series for value in last(pair).errors]
    ymin, ymax = extrema(error_values)
    yrange = max(ymax - ymin, eps())
    error_y(value) = top + plot_height * (1 - (log10(max(Float64(value), eps())) - ymin) / yrange)
    maximum_distance = sqrt(2.0)
    distance_y(value) = top + plot_height * (1 - clamp(Float64(value) / maximum_distance, 0, 1))
    error_lines = String[]
    distance_lines = String[]
    final_distance_bars = String[]
    final_condition_bars = String[]
    legend = String[]
    traced_labels = String[]
    final_conditions = [
        hasproperty(last(pair), :final_condition) ?
        Float64(last(pair).final_condition) : Float64(last(last(pair).conditions)) for pair in series
    ]
    condition_logs = log10.(max.(final_conditions, 1.0))
    maximum_condition_log = max(maximum(condition_logs), 1.0)
    for (index, pair) in enumerate(series)
        label, trace = pair
        color = colors[mod1(index, length(colors))]
        error_points = join(["$(xcoord(xs_data[i])),$(error_y(trace.errors[i]))" for i in eachindex(xs_data)], " ")
        push!(error_lines, "<polyline points=\"$error_points\" fill=\"none\" stroke=\"$color\" stroke-width=\"2.8\"></polyline>")
        if has_diagnostic_trace(trace)
            distance_points = join(["$(xcoord(xs_data[i])),$(distance_y(trace.distances[i]))" for i in eachindex(xs_data)], " ")
            push!(distance_lines, "<polyline points=\"$distance_points\" fill=\"none\" stroke=\"$color\" stroke-width=\"2.8\"></polyline>")
            push!(traced_labels, "<span><i style=\"background:$color\"></i>$(escape_html(label))</span>")
        end
        final_distance = clamp(
            hasproperty(trace, :final_distance) ? Float64(trace.final_distance) : Float64(last(trace.distances)),
            0,
            maximum_distance,
        )
        distance_meaning = final_distance < 0.15 ? "near collision" :
                           final_distance < 0.45 ? "strong overlap" :
                           final_distance < 0.9 ? "partly separated" : "separated"
        push!(final_distance_bars, """
        <div class="sr-bar-row">
          <div><span>$(escape_html(label))</span><strong>$(number_label(final_distance)) <small>· $distance_meaning</small></strong></div>
          <div class="sr-track"><i style="width:$(100*final_distance/maximum_distance)%;background:$color"></i></div>
        </div>
        """)
        final_condition = final_conditions[index]
        condition_meaning = final_condition < 10 ? "well conditioned" :
                            final_condition < 1e3 ? "elevated" : "ill-conditioned"
        condition_width = 100 * condition_logs[index] / maximum_condition_log
        push!(final_condition_bars, """
        <div class="sr-bar-row">
          <div><span>$(escape_html(label))</span><strong>κ $(number_label(final_condition)) <small>· $condition_meaning</small></strong></div>
          <div class="sr-track"><i style="width:$(condition_width)%;background:$color"></i></div>
        </div>
        """)
        push!(legend, "<span><i style=\"background:$color\"></i>$(escape_html(label))</span>")
    end
    chart(lines, ylabel, ytop, ybottom) = """
      <svg viewBox="0 0 $width $height" role="img" aria-label="$ylabel by iteration">
        <line class="sr-axis" x1="$left" y1="$(height-bottom)" x2="$(width-right)" y2="$(height-bottom)"></line>
        <line class="sr-axis" x1="$left" y1="$top" x2="$left" y2="$(height-bottom)"></line>
        $(join(lines))
        <text class="sr-label" x="$left" y="$(height-9)">0</text><text class="sr-label" x="$(width-right)" y="$(height-9)" text-anchor="end">$xmax iterations</text>
        <text class="sr-label" x="8" y="$(top+4)">$ytop</text><text class="sr-label" x="8" y="$(height-bottom)">$ybottom</text>
      </svg>
    """
    return Base.HTML("""
    <div id="$root_id" class="sr-wrap">
      <style>
        #$root_id { color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;width:100%; }
        #$root_id .sr-title { color:#4f5934;font-size:1.08rem;font-weight:650;margin-bottom:.45rem; }
        #$root_id .sr-legend { display:flex;gap:1rem;flex-wrap:wrap;margin-bottom:.65rem;color:#626954;font-size:.82rem; }
        #$root_id .sr-legend i { display:inline-block;width:20px;height:4px;border-radius:3px;margin-right:.35rem;vertical-align:middle; }
        #$root_id .sr-grid { display:grid;grid-template-columns:1fr 1fr;gap:1rem; }
        #$root_id .sr-panel { border:1px solid #d3d7c5;background:#fbfaf4;border-radius:14px;padding:.65rem;min-width:0; }
        #$root_id .sr-panel strong { display:block;color:#626954;font-size:.86rem;margin-bottom:.25rem; }
        #$root_id svg { width:100%;height:auto;display:block; }
        #$root_id .sr-axis { stroke:#a8ad9d;stroke-width:1; } #$root_id .sr-label { fill:currentColor;font-size:11px; }
        #$root_id .sr-bars { display:grid;grid-template-columns:1fr;gap:.8rem;padding:.75rem .3rem; }
        #$root_id .sr-bar-row>div:first-child { display:flex;justify-content:space-between;gap:1rem;font-size:.82rem; }
        #$root_id .sr-bar-row strong { display:flex;align-items:baseline;gap:.2rem;color:#303628;font-variant-numeric:tabular-nums; }
        #$root_id .sr-bar-row small { color:#626954;font-size:.7rem;font-weight:500; }
        #$root_id .sr-track { height:13px;background:#e3e5d9;border-radius:999px;overflow:hidden;margin-top:.25rem; }
        #$root_id .sr-track i { display:block;height:100%;min-width:2px;border-radius:inherit; }
        #$root_id .sr-help { margin:.2rem .3rem .7rem;color:#626954;font-size:.76rem;line-height:1.35; }
        #$root_id .sr-trace-legend { display:flex;gap:.75rem;flex-wrap:wrap;margin:.2rem .3rem .55rem;color:#626954;font-size:.72rem; }
        #$root_id .sr-trace-legend i { display:inline-block;width:16px;height:3px;border-radius:3px;margin-right:.3rem;vertical-align:middle; }
        #$root_id .sr-boundary { grid-column:1 / -1;padding:.65rem .8rem;border-left:3px solid #c3a04d;background:#f4f2e7;color:#565d47;font-size:.78rem;line-height:1.4; }
        @media(max-width:820px){#$root_id .sr-grid{grid-template-columns:1fr}#$root_id .sr-boundary{grid-column:auto}}
        @media(prefers-color-scheme:dark){#$root_id .sr-panel{background:#25281f;border-color:#555d45}#$root_id .sr-title,#$root_id .sr-panel>strong,#$root_id .sr-legend,#$root_id .sr-help,#$root_id .sr-bar-row>div:first-child>span,#$root_id .sr-bar-row small{color:#d6dcc8}#$root_id .sr-bar-row strong{color:#f2f3eb}#$root_id .sr-track{background:#454b3b}}
      </style>
      <div class="sr-title">$(escape_html(title))</div>
      <div class="sr-legend">$(join(legend))</div>
      <div class="sr-grid">
        <div class="sr-panel"><strong>Log relative reconstruction error</strong>$(chart(error_lines,"log relative error",number_label(10.0^ymax),number_label(10.0^ymin)))</div>
        <div class="sr-panel"><strong>Iteration-level distance · stored block-solver points only</strong><div class="sr-help">Only ALS and regularized ALS store a factor point after every sweep. RCG and RGD are intentionally absent from this trajectory panel.</div><div class="sr-trace-legend">$(join(traced_labels))</div>$(chart(distance_lines,"minimum rank-one distance for stored sweep points", "√2 · separated", "0 · collision"))</div>
        <div class="sr-panel"><strong>Final minimum rank-one distance · all solvers</strong><div class="sr-help">One endpoint diagnostic per solver. Near 0 means that the nearest returned rank-one pair is close to collision.</div><div class="sr-bars">$(join(final_distance_bars))</div></div>
        <div class="sr-panel"><strong>Final ALS-system condition · all solvers</strong><div class="sr-help">Conditioning evaluated at each returned factor point. For RCG and RGD this is not an iteration history or their internal linear system.</div><div class="sr-bars">$(join(final_condition_bars))</div></div>
        <div class="sr-boundary"><strong>Evidence boundary:</strong> block-solver curves use stored sweep points. RCG and RGD errors come from deterministic checkpoint reruns from the same start; they contribute final distance and condition diagnostics only.</div>
      </div>
    </div>
    """)
end

function swamp_microscope_visual(trace; window::Integer = 20)
    root_id = next_id("swamp-microscope")
    iterations = collect(Int.(trace.iterations))
    errors = collect(Float64.(trace.errors))
    distances = collect(Float64.(trace.distances))
    conditions = collect(Float64.(trace.conditions))
    length(iterations) == length(errors) == length(distances) == length(conditions) ||
        throw(ArgumentError("All microscope histories must have equal length."))
    improvements = [
        index > window ? log10(max(errors[index-window], eps()) / max(errors[index], eps())) : NaN for
        index in eachindex(errors)
    ]
    detected = [index > window && improvements[index] < 0.05 for index in eachindex(errors)]
    first_detected = something(findfirst(detected), length(errors))
    width, height = 720, 270
    left, right, top, bottom = 58, 20, 22, 38
    plot_width, plot_height = width - left - right, height - top - bottom
    transformed = log10.(max.(errors, eps()))
    ymin, ymax = extrema(transformed)
    yrange = max(ymax - ymin, eps())
    xs = [left + plot_width * (i - 1) / max(length(errors) - 1, 1) for i in eachindex(errors)]
    ys = [top + plot_height * (1 - (value - ymin) / yrange) for value in transformed]
    points = join(["$(xs[i]),$(ys[i])" for i in eachindex(xs)], " ")
    plateau_x = xs[first_detected]
    plateau_width = max(width - right - plateau_x, 0)
    js_array(values) = join([isfinite(value) ? string(value) : "null" for value in values], ",")
    return Base.HTML("""
    <div id="$root_id" class="sm-wrap">
      <style>
        #$root_id { color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;width:100%; }
        #$root_id .sm-chart { border:1px solid #d3d7c5;background:#fbfaf4;border-radius:14px;padding:.55rem; }
        #$root_id svg { display:block;width:100%;height:auto; } #$root_id .sm-axis { stroke:#a8ad9d;stroke-width:1; } #$root_id .sm-label { fill:currentColor;font-size:11px; }
        #$root_id .sm-controls { display:flex;align-items:center;gap:.8rem;margin:.7rem 0; } #$root_id input { flex:1;accent-color:#657047; }
        #$root_id .sm-metrics { display:grid;grid-template-columns:repeat(4,1fr);gap:.6rem; }
        #$root_id .sm-metric { border-top:3px solid #657047;background:#f1f2e8;padding:.55rem .65rem;min-width:0; }
        #$root_id .sm-metric span { display:block;color:#626954;font-size:.76rem; } #$root_id .sm-metric strong { display:block;font-variant-numeric:tabular-nums;font-size:1rem; }
        #$root_id .sm-status { margin-top:.7rem;padding:.65rem .8rem;border-left:4px solid #657047;background:#f1f2e8; }
        #$root_id .sm-status.detected { border-color:#c96f4a;background:#f8eee8; }
        @media(max-width:760px){#$root_id .sm-metrics{grid-template-columns:1fr 1fr}}
        @media(prefers-color-scheme:dark){#$root_id .sm-chart{background:#25281f;border-color:#555d45}#$root_id .sm-metric,#$root_id .sm-status{background:#303526}#$root_id .sm-status.detected{background:#3b2e28}}
      </style>
      <div class="sm-chart">
        <svg viewBox="0 0 $width $height" role="img" aria-label="ALS error trajectory with an iteration cursor and swamp-like region">
          <rect x="$plateau_x" y="$top" width="$plateau_width" height="$plot_height" fill="rgba(201,111,74,.12)"></rect>
          <line class="sm-axis" x1="$left" y1="$(height-bottom)" x2="$(width-right)" y2="$(height-bottom)"></line>
          <line class="sm-axis" x1="$left" y1="$top" x2="$left" y2="$(height-bottom)"></line>
          <polyline points="$points" fill="none" stroke="#5d7e9d" stroke-width="3"></polyline>
          <line id="$root_id-cursor" x1="$(xs[first_detected])" y1="$top" x2="$(xs[first_detected])" y2="$(height-bottom)" stroke="#657047" stroke-width="2"></line>
          <circle id="$root_id-marker" cx="$(xs[first_detected])" cy="$(ys[first_detected])" r="5" fill="#c96f4a"></circle>
          <text class="sm-label" x="$left" y="$(height-10)">sweep 0</text><text class="sm-label" x="$(width-right)" y="$(height-10)" text-anchor="end">sweep $(last(iterations))</text>
          <text class="sm-label" x="8" y="$(top+5)">log error</text>
        </svg>
      </div>
      <div class="sm-controls"><label for="$root_id-slider">ALS iteration</label><input id="$root_id-slider" type="range" min="1" max="$(length(errors))" value="$first_detected" step="1"><output id="$root_id-iteration">$(iterations[first_detected])</output></div>
      <div class="sm-metrics">
        <div class="sm-metric"><span>relative error</span><strong id="$root_id-error"></strong></div>
        <div class="sm-metric"><span>min rank-one distance</span><strong id="$root_id-distance"></strong></div>
        <div class="sm-metric"><span>max ALS Gram κ</span><strong id="$root_id-condition"></strong></div>
        <div class="sm-metric"><span>log improvement, last $window sweeps</span><strong id="$root_id-improvement"></strong></div>
      </div>
      <div id="$root_id-status" class="sm-status"></div>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const iterations = [$(join(iterations,","))];
          const errors = [$(js_array(errors))];
          const distances = [$(js_array(distances))];
          const conditions = [$(js_array(conditions))];
          const improvements = [$(js_array(improvements))];
          const detected = [$(join(detected,","))];
          const xs = [$(join(xs,","))]; const ys = [$(join(ys,","))];
          const slider = root.querySelector('#$root_id-slider');
          const format = value => value === null ? 'not available yet' : (Math.abs(value) >= 1e4 || (Math.abs(value) > 0 && Math.abs(value) < 1e-3) ? value.toExponential(2) : value.toPrecision(4));
          const update = () => {
            const index = Number(slider.value) - 1;
            root.querySelector('#$root_id-iteration').textContent = iterations[index];
            root.querySelector('#$root_id-error').textContent = format(errors[index]);
            root.querySelector('#$root_id-distance').textContent = format(distances[index]);
            root.querySelector('#$root_id-condition').textContent = format(conditions[index]);
            root.querySelector('#$root_id-improvement').textContent = format(improvements[index]);
            root.querySelector('#$root_id-cursor').setAttribute('x1', xs[index]); root.querySelector('#$root_id-cursor').setAttribute('x2', xs[index]);
            root.querySelector('#$root_id-marker').setAttribute('cx', xs[index]); root.querySelector('#$root_id-marker').setAttribute('cy', ys[index]);
            const status = root.querySelector('#$root_id-status');
            status.classList.toggle('detected', detected[index]);
            if (detected[index]) {
              const collisionEvidence = distances[index] < 0.3 && conditions[index] > 100;
              status.innerHTML = collisionEvidence
                ? '<strong>Plateau observed.</strong> Small rank-one distance and large ALS κ support collision-induced ill-conditioning as the explanation in this run.'
                : '<strong>Plateau observed.</strong> The error curve alone does not identify its cause; inspect distance, conditioning, initialization, rank, and model fit.';
            } else {
              status.innerHTML = '<strong>No plateau flag here.</strong> This is an observation heuristic, not a diagnosis or mathematical definition.';
            }
          };
          slider.addEventListener('input', update); update();
        })();
      </script>
    </div>
    """)
end

"""Show how a gauge transformation can destroy coordinates without moving X."""
function gauge_dial_visual(result)
    root_id = next_id("gauge-dial")
    object_scale = max(
        maximum(abs, result.object; init = 0.0),
        maximum(abs, result.reconstructed_object; init = 0.0),
    )
    original_svg = heatmap_svg(result.object; width = 190, height = 135, scale = object_scale)
    changed_svg = heatmap_svg(result.reconstructed_object; width = 190, height = 135, scale = object_scale)
    distortion_decades = log10(max(result.gauge_condition, 1.0))
    distortion_width = 100 * clamp(distortion_decades / 12, 0, 1)
    object_width = 100 * clamp((log10(max(result.relative_object_change, 1e-16)) + 16) / 6, 0, 1)
    found = result.gauge_condition > 1e8 && result.relative_object_change < 1e-10
    challenge_class = found ? "is-found" : ""
    challenge_text = found ?
        "✓ You found it: the coordinates are extremely ill-conditioned while X is unchanged. This is gauge freedom." :
        "Keep pushing until κ(Q) exceeds 10⁸ while the object change stays below 10⁻¹⁰."
    ratios = result.changed_factor_norms ./ result.original_factor_norms
    return Base.HTML("""
    <div id="$root_id" class="gd-wrap">
      <style>
        #$root_id { --olive:#657047; --olive-dark:#485031; --blue:#5d7e9d; --terra:#c96f4a; color:var(--pluto-output-color,#282d24); font-family:system-ui,sans-serif; }
        #$root_id .gd-grid { display:grid; grid-template-columns:minmax(260px,.86fr) minmax(360px,1.14fr); gap:1.35rem; align-items:start; }
        #$root_id .gd-meter { margin:.35rem 0 1rem; }
        #$root_id .gd-meter-head { display:flex; justify-content:space-between; gap:1rem; align-items:baseline; font-variant-numeric:tabular-nums; }
        #$root_id .gd-meter-head span { color:#626954; font-size:.88rem; letter-spacing:.04em; text-transform:uppercase; }
        #$root_id .gd-track { height:13px; margin-top:.4rem; background:#e7e5da; border-radius:999px; overflow:hidden; position:relative; }
        #$root_id .gd-fill { display:block; height:100%; min-width:2px; border-radius:inherit; }
        #$root_id .distortion { background:linear-gradient(90deg,var(--blue),var(--terra)); width:$(distortion_width)%; }
        #$root_id .object { background:var(--olive); width:$(object_width)%; }
        #$root_id .gd-scale { display:flex; justify-content:space-between; color:#737867; font-size:.78rem; margin-top:.2rem; }
        #$root_id .gd-norms { display:grid; grid-template-columns:1fr 1fr; gap:.65rem; margin-top:1rem; }
        #$root_id .gd-stat { border-left:3px solid #a8af8e; padding-left:.65rem; }
        #$root_id .gd-stat strong { display:block; font-size:1.15rem; font-variant-numeric:tabular-nums; }
        #$root_id .gd-stat span { color:#626954; font-size:.82rem; }
        #$root_id .gd-objects { display:grid; grid-template-columns:1fr auto 1fr; gap:.7rem; align-items:center; }
        #$root_id .gd-object { text-align:center; min-width:0; }
        #$root_id .gd-object svg { width:100%; max-height:145px; }
        #$root_id .gd-arrow { color:var(--olive); font-size:1.6rem; }
        #$root_id .gd-caption { color:#626954; font-size:.82rem; }
        #$root_id .gd-challenge { margin-top:1rem; border:1px solid #b9bea6; border-radius:12px; padding:.8rem 1rem; background:#f8f6ed; }
        #$root_id .gd-challenge.is-found { border-color:#657047; background:#eef1e6; color:var(--olive-dark); }
        #$root_id .gd-challenge strong { display:block; margin-bottom:.2rem; }
        #$root_id .gd-takeaway { margin-top:1rem; padding:.7rem 0; border-top:1px solid #d6d5cb; font-weight:600; }
        @media(max-width:760px){ #$root_id .gd-grid{grid-template-columns:1fr} }
        @media(prefers-color-scheme:dark){ #$root_id .gd-track{background:#45483f} #$root_id .gd-challenge{background:#32352f;color:#eef0e6} }
      </style>
      <div class="gd-grid">
        <div>
          <div class="gd-meter">
            <div class="gd-meter-head"><span>Coordinate distortion</span><strong>κ(Q) = $(number_label(result.gauge_condition))</strong></div>
            <div class="gd-track"><span class="gd-fill distortion"></span></div>
            <div class="gd-scale"><span>1</span><span>10¹²</span></div>
          </div>
          <div class="gd-meter">
            <div class="gd-meter-head"><span>Object change</span><strong>$(number_label(result.relative_object_change))</strong></div>
            <div class="gd-track"><span class="gd-fill object"></span></div>
            <div class="gd-scale"><span>≈ machine precision</span><span>10⁻¹⁰</span></div>
          </div>
          <div class="gd-norms">
            <div class="gd-stat"><strong>$(number_label(ratios[1]))×</strong><span>change in ‖A‖</span></div>
            <div class="gd-stat"><strong>$(number_label(ratios[2]))×</strong><span>change in ‖B‖</span></div>
            <div class="gd-stat"><strong>$(number_label(result.changed_factor_conditions[1]))</strong><span>κ(AQ)</span></div>
            <div class="gd-stat"><strong>$(number_label(result.changed_factor_conditions[2]))</strong><span>κ(BQ⁻ᵀ)</span></div>
          </div>
        </div>
        <div>
          <div class="gd-objects">
            <div class="gd-object"><strong>Original X</strong>$original_svg</div>
            <div class="gd-arrow">→</div>
            <div class="gd-object"><strong>Reconstructed X′</strong>$changed_svg</div>
          </div>
          <div class="gd-caption">Both heatmaps use the same color scale. The factors move; the represented matrix does not.</div>
          <div class="gd-challenge $challenge_class"><strong>Challenge: break the coordinates, not the object</strong>$challenge_text</div>
        </div>
      </div>
      <div class="gd-takeaway">I can move very far in factor coordinates without moving the represented matrix at all.</div>
    </div>
    """)
end

"""Connect CP coordinate changes to the reconstructed object as a reveal puzzle."""
function cp_equivalence_puzzle_visual(result)
    root_id = next_id("cp-puzzle")
    tensor_scale = max(
        maximum(abs, result.original_tensor; init = 0.0),
        maximum(abs, result.reconstructed_tensor; init = 0.0),
    )
    residual = result.reconstructed_tensor .- result.original_tensor
    residual_scale = maximum(abs, residual; init = 0.0)
    original_svg = heatmap_svg(result.original_tensor[:, :, 1]; width = 185, height = 135, scale = tensor_scale)
    changed_svg = heatmap_svg(result.reconstructed_tensor[:, :, 1]; width = 185, height = 135, scale = tensor_scale)
    residual_svg = heatmap_svg(residual[:, :, 1]; width = 185, height = 135, scale = max(residual_scale, eps()))
    before = result.original_first_component_norms
    after = result.rescaled_component_norms_before_permutation
    maximum_norm = max(maximum(before), maximum(after), eps())
    mode_rows = join([
        """
        <div class="cp-mode">
          <span>mode $mode</span>
          <div><i class="before" style="width:$(100 * before[mode] / maximum_norm)%"></i><small>before $(number_label(before[mode]))</small></div>
          <div><i class="after" style="width:$(100 * after[mode] / maximum_norm)%"></i><small>after $(number_label(after[mode]))</small></div>
        </div>
        """ for mode in eachindex(before)
    ])
    same_object = result.relative_object_change < 1e-10
    expected = same_object ? "same" : "different"
    explanation = same_object ?
        "Scaling and permutation disguised the coordinates, but reconstruction cancelled them exactly." :
        "The ε perturbation changed a factor direction, so reconstruction now produces a genuinely different tensor."
    coordinate_width = 100 * clamp(log10(1 + result.relative_coordinate_change) / 5, 0.02, 1)
    tensor_width = 100 * clamp((log10(max(result.relative_object_change, 1e-16)) + 16) / 16, 0.005, 1)
    return Base.HTML("""
    <div id="$root_id" class="cp-wrap">
      <style>
        #$root_id { --olive:#657047; --blue:#5d7e9d; --terra:#c96f4a; color:var(--pluto-output-color,#282d24); font-family:system-ui,sans-serif; }
        #$root_id .cp-map { display:grid; grid-template-columns:minmax(260px,.9fr) 70px minmax(340px,1.25fr); gap:1rem; align-items:center; }
        #$root_id .cp-section-title { color:#626954; font-size:.78rem; letter-spacing:.08em; text-transform:uppercase; font-weight:700; margin-bottom:.75rem; }
        #$root_id .cp-mode { display:grid; grid-template-columns:58px 1fr; gap:.25rem .55rem; margin:.65rem 0; align-items:center; }
        #$root_id .cp-mode>span { grid-row:1/3; font-weight:600; }
        #$root_id .cp-mode>div { height:18px; background:#e9e7de; border-radius:4px; position:relative; overflow:hidden; }
        #$root_id .cp-mode i { display:block; height:100%; min-width:2px; }
        #$root_id .cp-mode .before { background:var(--blue); opacity:.55; }
        #$root_id .cp-mode .after { background:var(--terra); }
        #$root_id .cp-mode small { position:absolute; inset:1px 5px auto auto; font-size:.72rem; color:#303628; font-variant-numeric:tabular-nums; }
        #$root_id .cp-meter { margin-top:.9rem; }
        #$root_id .cp-meter-head { display:flex; justify-content:space-between; font-size:.83rem; gap:.5rem; }
        #$root_id .cp-track { height:10px; background:#e9e7de; border-radius:999px; overflow:hidden; margin-top:.3rem; }
        #$root_id .cp-track i { display:block; height:100%; border-radius:inherit; }
        #$root_id .coordinate i { width:$(coordinate_width)%; background:var(--terra); }
        #$root_id .tensor i { width:$(tensor_width)%; background:var(--olive); }
        #$root_id .cp-arrow { text-align:center; color:var(--olive); }
        #$root_id .cp-arrow strong { display:block; font-size:1.65rem; }
        #$root_id .cp-arrow span { font-size:.75rem; }
        #$root_id .cp-objects { display:grid; grid-template-columns:1fr 1fr; gap:.65rem; }
        #$root_id .cp-object { text-align:center; min-width:0; }
        #$root_id .cp-object svg { width:100%; max-height:135px; }
        #$root_id .cp-residual { margin-top:.55rem; display:grid; grid-template-columns:145px 1fr; gap:.8rem; align-items:center; }
        #$root_id .cp-residual svg { width:145px; }
        #$root_id .cp-hidden { filter:blur(8px); opacity:.28; user-select:none; transition:filter .25s ease,opacity .25s ease; }
        #$root_id.revealed .cp-hidden { filter:none; opacity:1; }
        #$root_id .cp-question { margin-top:1rem; border-top:1px solid #d6d5cb; padding-top:.8rem; display:flex; align-items:center; gap:.55rem; flex-wrap:wrap; }
        #$root_id button { border:1px solid #7c8465; border-radius:999px; background:transparent; color:inherit; padding:.42rem .78rem; font:600 14px system-ui; cursor:pointer; }
        #$root_id button.selected { background:#e8ebdf; border-color:var(--olive); }
        #$root_id .reveal { background:var(--olive); color:white; margin-left:auto; }
        #$root_id .cp-answer { width:100%; padding:.65rem .8rem; background:#f1f3ea; border-radius:9px; display:none; }
        #$root_id.revealed .cp-answer { display:block; }
        @media(max-width:800px){ #$root_id .cp-map{grid-template-columns:1fr} #$root_id .cp-arrow strong{transform:rotate(90deg)} }
        @media(prefers-color-scheme:dark){ #$root_id .cp-mode>div,#$root_id .cp-track{background:#45483f} #$root_id .cp-mode small{color:#f1f2eb} #$root_id .cp-answer{background:#34372f} }
      </style>
      <div class="cp-map">
        <div>
          <div class="cp-section-title">Coordinate view · component 1</div>
          $mode_rows
          <div class="cp-meter coordinate"><div class="cp-meter-head"><span>Coordinate difference</span><strong>$(number_label(result.relative_coordinate_change))</strong></div><div class="cp-track"><i></i></div></div>
          <div style="color:#626954;font-size:.8rem;margin-top:.5rem">α=$(number_label(result.alpha)) · β=$(number_label(result.beta)) · permute=$(result.reversed) · ε=$(number_label(result.epsilon))</div>
        </div>
        <div class="cp-arrow"><strong>→</strong><span>reconstruct<br>π(θ)</span></div>
        <div>
          <div class="cp-section-title">Object view · first tensor slice</div>
          <div class="cp-objects">
            <div class="cp-object"><strong>Original</strong>$original_svg</div>
            <div class="cp-object"><strong>Transformed</strong>$changed_svg</div>
          </div>
          <div class="cp-residual cp-hidden">
            <div>$residual_svg</div>
            <div>
              <strong>Residual</strong>
              <div>‖X′−X‖ / ‖X‖ = <b>$(number_label(result.relative_object_change))</b></div>
              <div class="cp-meter tensor"><div class="cp-track"><i></i></div></div>
            </div>
          </div>
        </div>
      </div>
      <div class="cp-question">
        <strong>Same object or different object?</strong>
        <button type="button" data-guess="same">Same</button>
        <button type="button" data-guess="different">Different</button>
        <button type="button" class="reveal">Reveal residual</button>
        <div class="cp-answer"><strong id="$root_id-verdict"></strong> $explanation</div>
      </div>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          let guess = '';
          root.querySelectorAll('[data-guess]').forEach(button => button.addEventListener('click', () => {
            guess = button.dataset.guess;
            root.querySelectorAll('[data-guess]').forEach(item => item.classList.toggle('selected', item === button));
          }));
          root.querySelector('.reveal').addEventListener('click', () => {
            root.classList.add('revealed');
            const verdict = root.querySelector('#$root_id-verdict');
            verdict.textContent = guess ? (guess === '$expected' ? '✓ Correct. ' : 'Not this time. ') : '';
            root.querySelector('.reveal').textContent = 'Residual revealed';
          });
        })();
      </script>
    </div>
    """)
end

function javascript_array(values)
    return "[$(join(string.(Float64.(values)), ","))]"
end

"""A synchronized iteration scrubber for canonical and native CP geometry."""
function geometry_race_visual(result)
    root_id = next_id("geometry-race")
    c_cost = result.canonical.cost_history
    n_cost = result.native.cost_history
    c_motion = result.canonical.maximum_component_change
    n_motion = result.native.maximum_component_change
    trace_iterations = result.canonical.trace_iterations
    trace_iterations == result.native.trace_iterations ||
        throw(ArgumentError("Geometry histories must use the same checkpoints."))
    maximum_length = maximum(length.((c_cost, n_cost, c_motion, n_motion)))
    c_reduction = 100 * (1 - last(c_cost) / max(first(c_cost), eps()))
    n_reduction = 100 * (1 - last(n_cost) / max(first(n_cost), eps()))
    step_range(values) = isempty(values) ? "—" : "$(number_label(minimum(values))) – $(number_label(maximum(values)))"
    scale_ratio = 10.0^result.log10_scale_separation
    return Base.HTML("""
    <div id="$root_id" class="gr-wrap">
      <style>
        #$root_id { --olive:#657047; --blue:#5d7e9d; --terra:#c96f4a; color:var(--pluto-output-color,#282d24); font-family:system-ui,sans-serif; }
        #$root_id .gr-start { text-align:center; color:#626954; font-size:.82rem; letter-spacing:.08em; text-transform:uppercase; margin-bottom:.75rem; }
        #$root_id .gr-ratio { display:block; color:inherit; font-size:1.05rem; letter-spacing:0; margin-top:.15rem; text-transform:none; }
        #$root_id .gr-lanes { display:grid; grid-template-columns:1fr 1fr; gap:1rem; }
        #$root_id .gr-lane { border-top:4px solid var(--blue); padding-top:.65rem; }
        #$root_id .gr-lane.native { border-color:var(--terra); }
        #$root_id .gr-lane h4 { margin:.1rem 0 .8rem; font-size:1rem; }
        #$root_id .gr-diagnostic { display:grid; grid-template-columns:120px 1fr 88px; gap:.65rem; align-items:center; margin:.65rem 0; }
        #$root_id .gr-diagnostic>span { color:#626954; font-size:.84rem; }
        #$root_id .gr-diagnostic strong { text-align:right; font-variant-numeric:tabular-nums; }
        #$root_id .gr-track { height:12px; background:#e7e5da; border-radius:999px; overflow:hidden; }
        #$root_id .gr-track i { display:block; height:100%; border-radius:inherit; transition:width .12s linear; }
        #$root_id .canonical i { background:var(--blue); }
        #$root_id .native i { background:var(--terra); }
        #$root_id .gr-scrubber { margin:1rem 0; }
        #$root_id .gr-scrubber label { display:flex; justify-content:space-between; gap:1rem; font-weight:600; }
        #$root_id .gr-scrubber input { width:100%; accent-color:var(--olive); }
        #$root_id table { width:100%; border-collapse:collapse; font-variant-numeric:tabular-nums; }
        #$root_id th,#$root_id td { padding:.45rem .55rem; border-bottom:1px solid #d6d5cb; text-align:right; }
        #$root_id th:first-child,#$root_id td:first-child { text-align:left; }
        #$root_id details { margin-top:.8rem; border-top:1px solid #d6d5cb; padding-top:.65rem; }
        #$root_id summary { cursor:pointer; font-weight:600; }
        #$root_id .gr-prompt { margin-top:.85rem; padding:.65rem .8rem; border-left:4px solid var(--olive); background:#f2f3ea; }
        @media(max-width:720px){ #$root_id .gr-lanes{grid-template-columns:1fr} #$root_id .gr-diagnostic{grid-template-columns:100px 1fr 80px} }
        @media(prefers-color-scheme:dark){ #$root_id .gr-track{background:#45483f} #$root_id .gr-prompt{background:#34372f} }
      </style>
      <div class="gr-start">Same target · same start · same optimization budget<span class="gr-ratio">component scale separation 1 : $(number_label(scale_ratio))</span></div>
      <div class="gr-lanes">
        <div class="gr-lane canonical">
          <h4>Normalized representation</h4>
          <div class="gr-diagnostic"><span>current cost</span><div class="gr-track"><i id="$root_id-c-cost"></i></div><strong id="$root_id-c-cost-value"></strong></div>
          <div class="gr-diagnostic"><span>component motion</span><div class="gr-track"><i id="$root_id-c-motion"></i></div><strong id="$root_id-c-motion-value"></strong></div>
        </div>
        <div class="gr-lane native">
          <h4>Intrinsic rank-one representation</h4>
          <div class="gr-diagnostic"><span>current cost</span><div class="gr-track"><i id="$root_id-n-cost"></i></div><strong id="$root_id-n-cost-value"></strong></div>
          <div class="gr-diagnostic"><span>component motion</span><div class="gr-track"><i id="$root_id-n-motion"></i></div><strong id="$root_id-n-motion-value"></strong></div>
        </div>
      </div>
      <div class="gr-scrubber">
        <label for="$root_id-iteration"><span>Solver checkpoint</span><output id="$root_id-iteration-value">iteration $(first(trace_iterations))</output></label>
        <input id="$root_id-iteration" type="range" min="1" max="$maximum_length" step="1" value="1">
      </div>
      <table aria-label="Geometry race final summary">
        <thead><tr><th>Final summary</th><th>Normalized</th><th>Intrinsic rank-one</th></tr></thead>
        <tbody>
          <tr><td>final fit · relative error</td><td>$(number_label(result.canonical.relative_error))</td><td>$(number_label(result.native.relative_error))</td></tr>
          <tr><td>cost reduction</td><td>$(number_label(c_reduction))%</td><td>$(number_label(n_reduction))%</td></tr>
          <tr><td>final component motion</td><td>$(number_label(last(c_motion)))</td><td>$(number_label(last(n_motion)))</td></tr>
        </tbody>
      </table>
      <details>
        <summary>Show solver details and TensorKitchen geometry names</summary>
        <p style="color:#626954;font-size:.86rem">TensorKitchen calls these <code>:canonical</code> and <code>:native</code> Segre geometries.</p>
        <table>
          <tbody>
            <tr><td>gradient norm</td><td>$(number_label(result.canonical.gradient_norm))</td><td>$(number_label(result.native.gradient_norm))</td></tr>
            <tr><td>iterations</td><td>$(result.canonical.iterations)</td><td>$(result.native.iterations)</td></tr>
            <tr><td>converged</td><td>$(result.canonical.converged)</td><td>$(result.native.converged)</td></tr>
            <tr><td>function evaluations</td><td>$(result.canonical.function_evaluations)</td><td>$(result.native.function_evaluations)</td></tr>
            <tr><td>line-search trials</td><td>$(result.canonical.line_search_trials)</td><td>$(result.native.line_search_trials)</td></tr>
            <tr><td>accepted step-size range</td><td>$(step_range(result.canonical.accepted_stepsizes))</td><td>$(step_range(result.native.accepted_stepsizes))</td></tr>
          </tbody>
        </table>
        <p style="color:#626954;font-size:.86rem">Gradient norms and step sizes depend on the chosen geometry, so their absolute values are not geometry-independent distances.</p>
      </details>
      <div class="gr-prompt">Try the race at L = 0 (ρ = 1), then at L = 3 (ρ = 1000). Did scale heterogeneity make the paths more visibly different?</div>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const slider = root.querySelector('#$root_id-iteration');
          const series = {
            cCost: $(javascript_array(c_cost)), nCost: $(javascript_array(n_cost)),
            cMotion: $(javascript_array(c_motion)), nMotion: $(javascript_array(n_motion)),
            iterations: $(javascript_array(trace_iterations))
          };
          const at = (values, index) => values[Math.min(index, values.length - 1)];
          const format = value => (Math.abs(value) >= 1e4 || (Math.abs(value) > 0 && Math.abs(value) < 1e-3)) ? value.toExponential(2) : value.toPrecision(4);
          const allMotion = series.cMotion.concat(series.nMotion);
          const maxMotion = Math.max.apply(null, allMotion.concat([Number.EPSILON]));
          const update = () => {
            const index = Number(slider.value) - 1;
            const cCost = at(series.cCost,index), nCost = at(series.nCost,index);
            const cMotion = at(series.cMotion,index), nMotion = at(series.nMotion,index);
            const cProgress = 100 * Math.max(0, 1 - cCost / Math.max(series.cCost[0],Number.EPSILON));
            const nProgress = 100 * Math.max(0, 1 - nCost / Math.max(series.nCost[0],Number.EPSILON));
            root.querySelector('#$root_id-c-cost').style.width = Math.min(cProgress,100) + '%';
            root.querySelector('#$root_id-n-cost').style.width = Math.min(nProgress,100) + '%';
            root.querySelector('#$root_id-c-motion').style.width = 100 * cMotion / maxMotion + '%';
            root.querySelector('#$root_id-n-motion').style.width = 100 * nMotion / maxMotion + '%';
            root.querySelector('#$root_id-c-cost-value').textContent = format(cCost);
            root.querySelector('#$root_id-n-cost-value').textContent = format(nCost);
            root.querySelector('#$root_id-c-motion-value').textContent = format(cMotion);
            root.querySelector('#$root_id-n-motion-value').textContent = format(nMotion);
            root.querySelector('#$root_id-iteration-value').textContent = 'iteration ' + Math.round(at(series.iterations,index));
          };
          slider.addEventListener('input', update);
          update();
        })();
      </script>
    </div>
    """)
end

function js_tensor_data(tensor)
    samples, locations, features = size(tensor)
    sample_strings = String[]
    for sample in 1:samples
        feature_strings = [
            "[$(join(string.(float.(tensor[sample, :, feature])), ","))]" for
            feature in 1:features
        ]
        push!(sample_strings, "[$(join(feature_strings, ","))]")
    end
    return "[$(join(sample_strings, ","))]"
end

function activation_maps_visual(pairs::Pair...; spatial_shape = (3, 3), title = "Inspect spatial activation maps")
    isempty(pairs) && throw(ArgumentError("Provide at least one labelled activation tensor."))
    first_tensor = last(first(pairs))
    samples, locations, features = size(first_tensor)
    prod(spatial_shape) == locations ||
        throw(ArgumentError("spatial_shape must contain the location mode."))
    root_id = next_id("activation-maps")
    panels = [
        "<div class=\"nv-panel\"><div class=\"nv-title\">$(escape_html(first(pair)))</div><div id=\"$root_id-map-$index\" style=\"display:grid;grid-template-columns:repeat($(spatial_shape[2]),1fr);gap:2px;aspect-ratio:1\"></div></div>" for
        (index, pair) in enumerate(pairs)
    ]
    data = join([js_tensor_data(last(pair)) for pair in pairs], ",")
    return Base.HTML("""
    <div id=\"$root_id\">
      $(shared_style(root_id))
      <div class=\"nv-launch\">
        <div class=\"nv-title\">$(escape_html(title))</div>
        $(play_button())
      </div>
      <div class=\"nv-stage\" hidden>
        <div class=\"nv-controls\">
          <label for=\"$root_id-sample\">Sample</label>
          <input id=\"$root_id-sample\" type=\"range\" min=\"1\" max=\"$samples\" step=\"1\" value=\"1\">
          <output id=\"$root_id-sample-value\">1</output>
          <label for=\"$root_id-feature\">Feature</label>
          <input id=\"$root_id-feature\" type=\"range\" min=\"1\" max=\"$features\" step=\"1\" value=\"1\">
          <output id=\"$root_id-feature-value\">1</output>
        </div>
        <div class=\"nv-grid\">$(join(panels))</div>
      </div>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const sampleSlider = root.querySelector('#$root_id-sample');
          const featureSlider = root.querySelector('#$root_id-feature');
          const data = [$data];
          const mix = (a, b, t) => Math.round((1 - t) * a + t * b);
          const color = (value, scale) => {
            const t = Math.min(Math.abs(value) / Math.max(scale, Number.EPSILON), 1);
            const neutral = [243, 244, 246];
            const target = value >= 0 ? [37, 99, 235] : [220, 38, 38];
            const strength = .12 + .88 * t;
            return 'rgb(' + neutral.map((v, i) => mix(v, target[i], strength)).join(',') + ')';
          };
          const update = () => {
            const sample = Number(sampleSlider.value) - 1;
            const feature = Number(featureSlider.value) - 1;
            data.forEach((model, index) => {
              const values = model[sample][feature];
              const scale = Math.max(...values.map(Math.abs), Number.EPSILON);
              const panel = root.querySelector('#$root_id-map-' + (index + 1));
              panel.replaceChildren(...values.map((value, location) => {
                const cell = document.createElement('div');
                cell.style.background = color(value, scale);
                cell.title = 'location ' + (location + 1) + ': ' + value.toPrecision(4);
                return cell;
              }));
            });
            root.querySelector('#$root_id-sample-value').textContent = sample + 1;
            root.querySelector('#$root_id-feature-value').textContent = feature + 1;
          };
          sampleSlider.addEventListener('input', update);
          featureSlider.addEventListener('input', update);
          update();
        })();
      </script>
    </div>
    """)
end

end
