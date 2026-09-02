# Visuals used by 02_GeometryAtlas.jl.

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
