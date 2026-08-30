module Lab4ConceptVisuals

using Printf

export activation_matrix_visual,
       concept_explorer_visual,
       concept_importance_visual,
       matrix_tensor_extension_visual,
       nmf_microscope_visual,
       nonnegative_comparison_visual,
       rank_vocabulary_visual,
       recursive_craft_visual

const COUNTER = Ref(0)

function next_id(prefix)
    COUNTER[] += 1
    return "$prefix-$(COUNTER[])"
end

escape_html(value) = replace(string(value), '&' => "&amp;", '<' => "&lt;", '>' => "&gt;", '"' => "&quot;")
js_number(value) = @sprintf("%.7g", float(value))
js_vector(values) = "[" * join(js_number.(values), ",") * "]"
js_matrix(values) = "[" * join((js_vector(view(values, row, :)) for row in axes(values, 1)), ",") * "]"
js_string(value) = "\"" * replace(string(value), '\\' => "\\\\", '"' => "\\\"") * "\""
js_strings(values) = "[" * join(js_string.(values), ",") * "]"

function common_style(id)
    return """
    <style>
      #$id{font:15px/1.45 system-ui,-apple-system,sans-serif;color:#303427;background:#fffdf8;border:1px solid #d9ddc9;border-radius:18px;padding:20px;box-shadow:0 12px 30px rgba(62,70,39,.08)}
      #$id *{box-sizing:border-box} #$id button,#$id select,#$id input{font:inherit}
      #$id button{cursor:pointer} #$id .l4-grid{display:grid;gap:20px} #$id .l4-title{font-weight:760;color:#4f5937;margin-bottom:7px}
      #$id .l4-note{font-size:13px;color:#68705b} #$id .l4-card{background:#f5f6ee;border:1px solid #d9ddc9;border-radius:13px;padding:13px;min-width:0}
      #$id .l4-patches{display:grid;grid-template-columns:repeat(3,minmax(70px,1fr));gap:9px}
      #$id .l4-patch{appearance:none;border:2px solid transparent;border-radius:12px;background:#fff;padding:6px;color:#34382b;text-align:left}
      #$id .l4-patch.active{border-color:#69764b;box-shadow:0 0 0 3px rgba(105,118,75,.14)}
      #$id .l4-patch-art{height:55px;border-radius:8px;margin-bottom:4px;border:1px solid rgba(57,64,39,.12)}
      #$id .l4-patch-name{font-size:11px;line-height:1.15;display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
      #$id .l4-bars{display:flex;align-items:flex-end;gap:5px;height:92px;padding-top:8px}
      #$id .l4-bars span{flex:1;min-width:5px;border-radius:5px 5px 1px 1px;background:#607e98;transition:height .32s ease,background .25s ease}
      #$id .l4-bars.signed{align-items:center;position:relative} #$id .l4-bars.signed:after{content:'';position:absolute;left:0;right:0;top:50%;border-top:1px dashed #aeb49f}
      #$id .l4-bars.signed span{position:relative;z-index:1;align-self:center;transform-origin:center bottom}
      #$id .l4-metric{font-variant-numeric:tabular-nums;font-size:22px;font-weight:720;color:#59653e}
      #$id .l4-control{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin:8px 0 13px} #$id input[type=range]{flex:1;min-width:160px;accent-color:#68764a}
      #$id select{border:1px solid #bbc2a8;background:white;border-radius:8px;padding:5px 8px;color:inherit}
      #$id .l4-pill{border:1px solid #bbc2a8;background:#f6f7f0;border-radius:999px;padding:5px 10px;color:#4e563e}
      #$id .l4-pill.active{background:#657149;color:white;border-color:#657149}
      #$id .l4-equation{font-family:ui-monospace,SFMono-Regular,monospace;background:#eef1e5;border-radius:10px;padding:10px;text-align:center;color:#4d5735}
      #$id .l4-warning{border-left:4px solid #b7753f;background:#fbf2e9;border-radius:8px;padding:10px 12px;color:#6b472c}
      @media(max-width:760px){#$id{padding:14px}#$id .l4-patches{grid-template-columns:repeat(2,1fr)}}
    </style>
    """
end

function patch_background(patch)
    color, base = patch.color, patch.base
    if patch.kind == :disk
        return "radial-gradient(circle at 50% 50%,$color 0 29%,transparent 30%),linear-gradient(135deg,$base,#fff)"
    elseif patch.kind == :stripes
        return "repeating-linear-gradient(90deg,$color 0 7px,$base 7px 15px)"
    elseif patch.kind == :glow
        return "radial-gradient(circle at 50% 50%,#fff7c6 0 10%,$color 28%,transparent 60%),$base"
    elseif patch.kind == :striped_disk
        return "radial-gradient(circle at 50% 50%,transparent 0 31%,$base 32%),repeating-linear-gradient(90deg,$color 0 6px,#dce4e8 6px 13px)"
    elseif patch.kind == :glowing_disk
        return "radial-gradient(circle at 50% 50%,#fff6b2 0 12%,$color 13% 34%,transparent 35%),$base"
    else
        return "radial-gradient(circle at 50% 50%,#fff3ac 0 12%,transparent 45%),repeating-linear-gradient(90deg,$color 0 6px,$base 6px 13px)"
    end
end

function patch_button(patch, index; selected = false)
    active = selected ? " active" : ""
    return """
    <button class="l4-patch$active" type="button" data-patch="$(index - 1)" title="$(escape_html(patch.name))">
      <div class="l4-patch-art" style="background:$(patch_background(patch))"></div>
      <span class="l4-patch-name">$(escape_html(patch.name))</span>
    </button>
    """
end

function patch_grid(patches; limit = length(patches))
    return join((patch_button(patch, index; selected = index == 1) for (index, patch) in enumerate(patches[1:limit])))
end

function activation_matrix_visual(data)
    id = next_id("activation-matrix")
    matrix_rows = join(["<div class=\"a-row$(row == 1 ? " active" : "")\" data-row=\"$(row - 1)\">" *
                        join(["<i style=\"--v:$(js_number(data.activations[row, column]))\"></i>" for column in axes(data.activations, 2)]) * "</div>"
                        for row in axes(data.activations, 1)])
    Base.HTML("""
    <div id="$id">
      $(common_style(id))
      <style>
        #$id .pipeline{grid-template-columns:1.05fr .82fr 1.05fr;align-items:center} #$id .arrow{text-align:center;font-size:28px;color:#8a9276}
        #$id .a-matrix{display:grid;gap:3px} #$id .a-row{display:grid;grid-template-columns:repeat(8,1fr);gap:3px;padding:3px;border:2px solid transparent;border-radius:7px}
        #$id .a-row.active{border-color:#b66f42;background:#fff} #$id .a-row i{height:13px;border-radius:2px;background:color-mix(in srgb,#607e98 calc(var(--v)*75%),#eef0e8)}
        #$id .network{height:52px;display:grid;place-items:center;background:linear-gradient(90deg,#6b7950,#607e98);color:white;border-radius:10px;font-weight:700;margin:8px 0}
        @media(max-width:850px){#$id .pipeline{grid-template-columns:1fr}#$id .arrow{transform:rotate(90deg)}}
      </style>
      <div class="l4-grid pipeline">
        <section><div class="l4-title">Image crops</div><div class="l4-patches">$(patch_grid(data.patches; limit=6))</div></section>
        <section class="l4-card"><div class="l4-title" id="$id-selected">$(escape_html(data.patches[1].name))</div><div class="network">chosen neural layer</div><div class="l4-note">pooled activation from this crop</div><div class="l4-bars" id="$id-bars">$(join("<span></span>" for _ in axes(data.activations,2)))</div></section>
        <section><div class="l4-title">Activation matrix A</div><div class="l4-card a-matrix">$matrix_rows</div><div class="l4-note" style="margin-top:7px">one row = one crop's activation pattern</div></section>
      </div>
      <div class="l4-equation" style="margin-top:16px">crop i → neural layer → row A[i, :]</div>
      <script>
      (()=>{const root=document.getElementById('$id');const A=$(js_matrix(data.activations));const names=$(js_strings(getproperty.(data.patches,:name)));const bars=[...root.querySelectorAll('#$id-bars span')];
        function show(i){root.querySelector('#$id-selected').textContent=names[i];bars.forEach((bar,j)=>bar.style.height=`\${10+76*A[i][j]/1.75}px`);root.querySelectorAll('.a-row').forEach(row=>row.classList.toggle('active',+row.dataset.row===i));root.querySelectorAll('[data-patch]').forEach(button=>button.classList.toggle('active',+button.dataset.patch===i));}
        root.querySelectorAll('[data-patch]').forEach(button=>button.addEventListener('click',()=>show(+button.dataset.patch)));show(0);
      })();
      </script>
    </div>
    """)
end

function nmf_microscope_visual(data, trace)
    id = next_id("nmf-microscope")
    Us = "[" * join((js_matrix(snapshot.U) for snapshot in trace), ",") * "]"
    Ws = "[" * join((js_matrix(snapshot.W) for snapshot in trace), ",") * "]"
    Rs = "[" * join((js_matrix(snapshot.reconstruction) for snapshot in trace), ",") * "]"
    errors = js_vector(getproperty.(trace, :error))
    iterations = js_vector(getproperty.(trace, :iteration))
    options = join("<option value=\"$(index - 1)\">$(escape_html(patch.name))</option>" for (index,patch) in enumerate(data.patches))
    concept_cards = join("<div class=\"l4-card concept\"><div class=\"l4-title\">Concept $j · $(escape_html(data.concept_names[j]))</div><div class=\"weight\"></div><div class=\"l4-bars\">$(join("<span></span>" for _ in axes(data.activations,2)))</div></div>" for j in 1:3)
    Base.HTML("""
    <div id="$id">
      $(common_style(id))
      <style>
        #$id .nmf-top{display:grid;grid-template-columns:.8fr 1.8fr;gap:18px} #$id .concepts{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
        #$id .concept .l4-bars{height:68px} #$id .weight{font-size:21px;font-weight:750;color:#ad6940}
        #$id .compare{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-top:14px} #$id .compare .l4-bars{height:76px}
        @media(max-width:780px){#$id .nmf-top{grid-template-columns:1fr}#$id .concepts{grid-template-columns:1fr}#$id .compare{grid-template-columns:1fr}}
      </style>
      <div class="l4-control"><label>Selected crop <select id="$id-patch">$options</select></label><label>Iteration <b id="$id-iter"></b></label><input id="$id-step" type="range" min="0" max="$(length(trace)-1)" value="0" step="1"><span>relative error <b id="$id-error"></b></span></div>
      <div class="l4-grid nmf-top">
        <section class="l4-card"><div class="l4-title">A[i, :] as a mixture</div><div id="$id-patch-art" class="l4-patch-art" style="height:105px;background:$(patch_background(data.patches[1]))"></div><div class="l4-note">Each U[i,j] is a nonnegative recipe weight.</div></section>
        <section class="concepts">$concept_cards</section>
      </div>
      <div class="l4-equation" style="margin-top:14px">A[i, :] ≈ U[i,1]W[:,1]ᵀ + U[i,2]W[:,2]ᵀ + U[i,3]W[:,3]ᵀ</div>
      <div class="compare"><div class="l4-card"><div class="l4-title">Observed activation</div><div class="l4-bars observed">$(join("<span></span>" for _ in axes(data.activations,2)))</div></div><div class="l4-card"><div class="l4-title">Reconstructed activation</div><div class="l4-bars reconstructed">$(join("<span></span>" for _ in axes(data.activations,2)))</div></div></div>
      <script>
      (()=>{const root=document.getElementById('$id');const A=$(js_matrix(data.activations)),Us=$Us,Ws=$Ws,Rs=$Rs,errs=$errors,iters=$iterations;const backgrounds=$(js_strings(patch_background.(data.patches)));let crop=0,step=0;
        function paintBars(selector,values,max=1.75){root.querySelectorAll(selector+' span').forEach((bar,j)=>bar.style.height=`\${8+68*Math.abs(values[j])/max}px`)}
        function draw(){const U=Us[step],W=Ws[step];root.querySelector('#$id-iter').textContent=iters[step];root.querySelector('#$id-error').textContent=errs[step].toFixed(3);root.querySelector('#$id-patch-art').style.background=backgrounds[crop];root.querySelectorAll('.concept').forEach((card,j)=>{card.querySelector('.weight').textContent=U[crop][j].toFixed(2)+' ×';card.querySelectorAll('.l4-bars span').forEach((bar,k)=>bar.style.height=`\${7+55*W[k][j]}px`)});paintBars('.observed',A[crop]);paintBars('.reconstructed',Rs[step][crop]);}
        root.querySelector('#$id-patch').addEventListener('change',e=>{crop=+e.target.value;draw()});root.querySelector('#$id-step').addEventListener('input',e=>{step=+e.target.value;draw()});draw();
      })();
      </script>
    </div>
    """)
end

function rank_vocabulary_visual(data, sweep)
    id = next_id("rank-vocabulary")
    entries = String[]
    for result in sweep
        labels = js_strings(result.labels)
        tops = js_vector(result.top_patch .- 1)
        push!(entries, "{rank:$(result.rank),error:$(js_number(result.error)),labels:$labels,tops:$tops}")
    end
    Base.HTML("""
    <div id="$id">
      $(common_style(id))
      <style>
        #$id .rank-layout{grid-template-columns:230px 1fr;align-items:start} #$id .vocab{display:grid;grid-template-columns:repeat(auto-fit,minmax(125px,1fr));gap:10px}
        #$id .mini-art{height:70px;border-radius:9px;border:1px solid #d6dac8;margin-bottom:7px} #$id .state{font-size:27px;font-weight:760;color:#59643f}
        @media(max-width:720px){#$id .rank-layout{grid-template-columns:1fr}}
      </style>
      <div class="l4-grid rank-layout"><section class="l4-card"><div class="l4-title">Number of concepts r</div><div class="l4-control"><input id="$id-rank" type="range" min="1" max="5" value="3"><span class="state" id="$id-value">3</span></div><div>reconstruction error</div><div class="l4-metric" id="$id-error"></div><p class="l4-note">Underfit merges ingredients. Extra factors can split or duplicate them.</p></section><section><div class="l4-title">Current concept vocabulary</div><div class="vocab" id="$id-vocab"></div></section></div>
      <div class="l4-warning" style="margin-top:14px"><b>Question:</b> the error usually falls as r grows, but did the vocabulary become clearer?</div>
      <script>
      (()=>{const root=document.getElementById('$id');const results=[$(join(entries,","))];const backgrounds=$(js_strings(patch_background.(data.patches)));
        function draw(rank){const item=results[rank-1];root.querySelector('#$id-value').textContent=rank;root.querySelector('#$id-error').textContent=item.error.toFixed(3);root.querySelector('#$id-vocab').innerHTML=item.labels.map((label,j)=>`<div class="l4-card"><div class="mini-art" style="background:\${backgrounds[item.tops[j]]}"></div><b>\${label}</b><div class="l4-note">representative crop</div></div>`).join('');}
        root.querySelector('#$id-rank').addEventListener('input',e=>draw(+e.target.value));draw(3);
      })();
      </script>
    </div>
    """)
end

function concept_explorer_visual(data, fit)
    id = next_id("concept-explorer")
    options = join("<option value=\"$(j-1)\">Concept $j · $(escape_html(data.concept_names[j]))</option>" for j in eachindex(data.concept_names))
    patch_cards = patch_grid(data.patches)
    Base.HTML("""
    <div id="$id">
      $(common_style(id))
      <style>
        #$id .explore{grid-template-columns:minmax(220px,.8fr) minmax(0,1.2fr);align-items:start}
        #$id .toplist{display:grid;gap:7px} #$id .topitem{display:grid;grid-template-columns:45px 1fr auto;gap:8px;align-items:center;padding:6px;background:#fff;border-radius:8px}
        #$id .thumb{height:36px;border-radius:6px} #$id .score{font-variant-numeric:tabular-nums;color:#a7633c;font-weight:750}
        #$id .composition-panel{margin-top:20px} #$id .composition-layout{display:grid;grid-template-columns:minmax(0,1.35fr) minmax(280px,.65fr);gap:18px;align-items:start}
        #$id .composition-layout .l4-patches{grid-template-columns:repeat(4,minmax(70px,1fr))}
        #$id .composition-bars{background:#fff;border:1px solid #d9ddc9;border-radius:10px;padding:11px 13px;min-width:0}
        @media(max-width:900px){#$id .explore,#$id .composition-layout{grid-template-columns:1fr}#$id .composition-layout .l4-patches{grid-template-columns:repeat(3,minmax(70px,1fr))}}
        @media(max-width:620px){#$id .composition-layout .l4-patches{grid-template-columns:repeat(2,minmax(70px,1fr))}}
      </style>
      <div class="l4-control"><label>Concept <select id="$id-concept">$options</select></label><span class="l4-note">A concept direction becomes interpretable only through examples and tests.</span></div>
      <div class="l4-grid explore">
        <section class="l4-card"><div class="l4-title">Concept activation vector W[:,j]</div><div class="l4-bars cav">$(join("<span></span>" for _ in axes(fit.W,1)))</div><div class="l4-note">A direction in activation-feature space, not a human label by itself.</div></section>
        <section class="l4-card"><div class="l4-title">Top crops by U[i,j]</div><div class="toplist" id="$id-top"></div></section>
      </div>
      <section class="l4-card composition-panel">
        <div class="l4-title">Selected crop composition</div>
        <div class="composition-layout">
          <div class="l4-patches">$patch_cards</div>
          <div class="composition-bars" id="$id-composition"></div>
        </div>
      </section>
      <script>
      (()=>{const root=document.getElementById('$id');const U=$(js_matrix(fit.U)),W=$(js_matrix(fit.W));const names=$(js_strings(getproperty.(data.patches,:name))),concepts=$(js_strings(data.concept_names)),backgrounds=$(js_strings(patch_background.(data.patches)));let concept=0,crop=0;
        function draw(){root.querySelectorAll('.cav span').forEach((bar,k)=>bar.style.height=`\${7+72*W[k][concept]}px`);const order=U.map((row,i)=>[i,row[concept]]).sort((a,b)=>b[1]-a[1]).slice(0,4);root.querySelector('#$id-top').innerHTML=order.map(([i,v])=>`<div class="topitem"><div class="thumb" style="background:\${backgrounds[i]}"></div><span>\${names[i]}</span><span class="score">\${v.toFixed(2)}</span></div>`).join('');root.querySelector('#$id-composition').innerHTML=U[crop].map((v,j)=>`<div style="display:grid;grid-template-columns:120px 1fr 38px;gap:7px;align-items:center;margin:5px 0"><span>\${concepts[j]}</span><i style="height:9px;border-radius:8px;background:#71805a;width:\${Math.min(100,v*65)}%"></i><b>\${v.toFixed(2)}</b></div>`).join('');root.querySelectorAll('[data-patch]').forEach(b=>b.classList.toggle('active',+b.dataset.patch===crop));}
        root.querySelector('#$id-concept').addEventListener('change',e=>{concept=+e.target.value;draw()});root.querySelectorAll('[data-patch]').forEach(b=>b.addEventListener('click',()=>{crop=+b.dataset.patch;draw()}));draw();
      })();
      </script>
    </div>
    """)
end

function nonnegative_comparison_visual(data, nmf, svd_fit)
    id = next_id("nonnegative-compare")
    options = join("<option value=\"$(i-1)\">$(escape_html(patch.name))</option>" for (i,patch) in enumerate(data.patches))
    Base.HTML("""
    <div id="$id">
      $(common_style(id))
      <style>
        #$id .compare-layout{grid-template-columns:240px 1fr} #$id .coeffs{display:grid;grid-template-columns:repeat(3,1fr);gap:10px} #$id .coefficient{text-align:center;font-size:23px;font-weight:760;padding:16px 7px;border-radius:10px;background:#eef1e6}
        #$id .negative{background:#f8e8e3;color:#9d493a} #$id .positive{color:#53613a} @media(max-width:700px){#$id .compare-layout{grid-template-columns:1fr}}
      </style>
      <div class="l4-control"><button class="l4-pill active" data-method="nmf">NMF · additive</button><button class="l4-pill" data-method="svd">SVD · signed</button><label>Crop <select id="$id-patch">$options</select></label></div>
      <div class="l4-grid compare-layout"><section class="l4-card"><div id="$id-art" class="l4-patch-art" style="height:130px;background:$(patch_background(data.patches[1]))"></div><div class="l4-title" id="$id-method-title">Nonnegative recipe</div><div class="l4-note" id="$id-copy">Every contribution adds an activation direction.</div></section><section><div class="l4-title">Coordinates for this crop</div><div class="coeffs" id="$id-coeffs"></div><div class="l4-equation" id="$id-equation" style="margin-top:12px"></div></section></div>
      <div class="l4-warning" style="margin-top:14px"><b>Nonnegative ≠ uniquely meaningful.</b> Additive coordinates can be easier to inspect, but rank, layer, initialization, stability, examples, and behavior still matter.</div>
      <script>
      (()=>{const root=document.getElementById('$id');const nmf=$(js_matrix(nmf.U)),svd=$(js_matrix(svd_fit.coefficients)),backgrounds=$(js_strings(patch_background.(data.patches)));let method='nmf',crop=0;
        function draw(){const values=method==='nmf'?nmf[crop]:svd[crop];root.querySelector('#$id-art').style.background=backgrounds[crop];root.querySelector('#$id-coeffs').innerHTML=values.map((v,j)=>`<div class="coefficient \${v<0?'negative':'positive'}">\${v>=0?'+':''}\${v.toFixed(2)}<div class="l4-note">direction \${j+1}</div></div>`).join('');root.querySelector('#$id-method-title').textContent=method==='nmf'?'Nonnegative recipe':'Signed coordinate system';root.querySelector('#$id-copy').textContent=method==='nmf'?'Every contribution adds an activation direction.':'Positive and negative coordinates can reinforce or cancel.';root.querySelector('#$id-equation').textContent=method==='nmf'?'activation ≈ positive part + positive part + positive part':'activation ≈ signed direction + signed direction + signed direction';root.querySelectorAll('[data-method]').forEach(b=>b.classList.toggle('active',b.dataset.method===method));}
        root.querySelectorAll('[data-method]').forEach(b=>b.addEventListener('click',()=>{method=b.dataset.method;draw()}));root.querySelector('#$id-patch').addEventListener('change',e=>{crop=+e.target.value;draw()});draw();
      })();
      </script>
    </div>
    """)
end

function concept_importance_visual(data, coefficients, proxy)
    id = next_id("concept-importance")
    baseline = 1 / (1 + exp(-(-1.15 + sum([0.15,2.25,0.90] .* coefficients))))
    Base.HTML("""
    <div id="$id">
      $(common_style(id))
      <style>
        #$id .importance{grid-template-columns:1fr 1fr;align-items:center} #$id .scorecard{text-align:center;padding:25px} #$id .scorevalue{font-size:44px;font-weight:780;color:#59663d;font-variant-numeric:tabular-nums}
        #$id .importance-row{display:grid;grid-template-columns:120px 1fr 42px;gap:9px;align-items:center;margin:9px 0} #$id .meter{height:11px;background:#e5e8da;border-radius:9px;overflow:hidden} #$id .meter i{display:block;height:100%;background:#b67442;border-radius:9px}
        @media(max-width:700px){#$id .importance{grid-template-columns:1fr}}
      </style>
      <div class="l4-grid importance"><section class="l4-card"><div class="l4-title">Perturb one concept</div><div class="l4-control"><select id="$id-concept">$(join("<option value=\"$(j-1)\">$(escape_html(data.concept_names[j]))</option>" for j in eachindex(data.concept_names)))</select><input id="$id-strength" type="range" min="0" max="1.2" value="$(js_number(coefficients[1]))" step="0.01"><b id="$id-strength-value"></b></div><div id="$id-presence"></div><hr style="border:0;border-top:1px solid #d7dbc8;margin:16px 0"><div class="l4-title">Variance-based sensitivity intuition</div><div id="$id-proxy"></div></section><section class="l4-card scorecard"><div class="l4-note">synthetic class score</div><div class="scorevalue" id="$id-score"></div><div id="$id-delta"></div><div class="l4-note" style="margin-top:12px">The teaching model is synthetic; the distinction between coefficient size and behavioral influence is the point.</div></section></div>
      <div class="l4-warning" style="margin-top:14px"><b>Presence ≠ importance.</b> A concept can be strongly present in a crop yet have little effect on this prediction.</div>
      <script>
      (()=>{const root=document.getElementById('$id');const base=$(js_vector(coefficients)),weights=[0.15,2.25,0.90],proxy=$(js_vector(proxy)),names=$(js_strings(data.concept_names));let concept=0;const logistic=x=>1/(1+Math.exp(-x));const baseline=$(js_number(baseline));
        function rows(values,target){return values.map((v,j)=>`<div class="importance-row"><span>\${names[j]}</span><div class="meter"><i style="width:\${100*v/Math.max(...values)}%"></i></div><b>\${target==='proxy'?(100*v).toFixed(0)+'%':v.toFixed(2)}</b></div>`).join('')}
        function draw(){const strength=+root.querySelector('#$id-strength').value,changed=[...base];changed[concept]=strength;const score=logistic(-1.15+changed.reduce((s,v,j)=>s+v*weights[j],0));root.querySelector('#$id-strength-value').textContent=strength.toFixed(2);root.querySelector('#$id-score').textContent=score.toFixed(3);const delta=score-baseline;root.querySelector('#$id-delta').textContent=`baseline \${baseline.toFixed(3)} · change \${delta>=0?'+':''}\${delta.toFixed(3)}`;root.querySelector('#$id-presence').innerHTML=rows(changed,'presence');root.querySelector('#$id-proxy').innerHTML=rows(proxy,'proxy');}
        root.querySelector('#$id-concept').addEventListener('change',e=>{concept=+e.target.value;root.querySelector('#$id-strength').value=base[concept];draw()});root.querySelector('#$id-strength').addEventListener('input',draw);draw();
      })();
      </script>
    </div>
    """)
end

function recursive_craft_visual()
    id = next_id("recursive-craft")
    Base.HTML("""
    <div id="$id">
      $(common_style(id))
      <style>
        #$id .layer-layout{grid-template-columns:240px 1fr;align-items:center} #$id .tree{min-height:230px;display:grid;place-items:center;text-align:center} #$id .parent{display:inline-block;background:#5e6d42;color:white;border-radius:50%;width:96px;height:96px;padding-top:35px;font-weight:750;position:relative}
        #$id .children{display:flex;gap:18px;justify-content:center;margin-top:48px;position:relative} #$id .child{background:#edf0e5;border:2px solid #78845d;border-radius:12px;padding:12px 16px;min-width:92px;position:relative} #$id .child:before{content:'';position:absolute;left:50%;top:-49px;height:47px;border-left:2px solid #a8af98;transform:rotate(var(--angle,0deg));transform-origin:bottom}
        @media(max-width:700px){#$id .layer-layout{grid-template-columns:1fr}}
      </style>
      <div class="l4-grid layer-layout"><section class="l4-card"><div class="l4-title">Layer selector</div><div class="l4-control"><span>earlier</span><input id="$id-layer" type="range" min="0" max="2" value="2" step="1"><span>later</span></div><div class="l4-metric" id="$id-layer-name"></div><p class="l4-note">Earlier layers often support finer visual ingredients; later layers can amalgamate them into a class-level pattern.</p></section><section class="tree" id="$id-tree"></section></div>
      <div class="l4-equation">semantic granularity depends on the chosen layer</div>
      <script>
      (()=>{const root=document.getElementById('$id');const states=[{layer:'early layer · 4',parent:'visual parts',children:['curve','parallel lines','bright edge']},{layer:'middle layer · 7',parent:'airplane parts',children:['wing','body','window']},{layer:'late layer · 10',parent:'airplane',children:[]}];
        function draw(i){const s=states[i];root.querySelector('#$id-layer-name').textContent=s.layer;root.querySelector('#$id-tree').innerHTML=`<div><div class="parent">\${s.parent}</div>\${s.children.length?`<div class="children">\${s.children.map((c,j)=>`<div class="child" style="--angle:\${(j-1)*18}deg">\${c}</div>`).join('')}</div>`:'<p class="l4-note">One compact late-layer concept. Move earlier to ask what composes it.</p>'}</div>`;}
        root.querySelector('#$id-layer').addEventListener('input',e=>draw(+e.target.value));draw(2);
      })();
      </script>
    </div>
    """)
end

function matrix_tensor_extension_visual()
    id = next_id("matrix-tensor")
    Base.HTML("""
    <div id="$id">
      $(common_style(id))
      <style>
        #$id .representation{min-height:245px;display:grid;grid-template-columns:1fr 70px 1.2fr;gap:16px;align-items:center} #$id .block{display:grid;gap:4px;padding:12px;background:#eef1e5;border-radius:12px} #$id .block i{height:12px;background:linear-gradient(90deg,#6b7d54,#7894a8);border-radius:3px;opacity:.75} #$id .modes{display:flex;gap:8px;flex-wrap:wrap;justify-content:center} #$id .mode{border:1px solid #cbd0bd;background:white;border-radius:9px;padding:8px;text-align:center;min-width:84px} #$id .times{text-align:center;font-size:27px;color:#8b9279}
      </style>
      <div class="l4-control"><button class="l4-pill active" data-view="matrix">Matrix NMF</button><button class="l4-pill" data-view="cp">Tensor NNCPD</button><button class="l4-pill" data-view="btd">Nonnegative BTD</button></div>
      <div class="representation" id="$id-stage"></div>
      <div class="l4-warning"><b>Boundary:</b> This is not CRAFT. It is a tensor-structured extension question inspired by CRAFT.</div>
      <script>
      (()=>{const root=document.getElementById('$id');const stage=root.querySelector('#$id-stage');let view='matrix';const rows=n=>Array.from({length:n},()=>'<i></i>').join('');
        function draw(){root.querySelectorAll('[data-view]').forEach(b=>b.classList.toggle('active',b.dataset.view===view));if(view==='matrix'){stage.innerHTML=`<div><div class="l4-title">A: crop × feature</div><div class="block">\${rows(8)}</div></div><div class="times">≈</div><div><div class="modes"><div class="mode">crop usage<br><b>U</b></div><div class="times">×</div><div class="mode">concept direction<br><b>Wᵀ</b></div></div><p class="l4-note">Location was pooled before factorization.</p></div>`}else if(view==='cp'){stage.innerHTML=`<div><div class="l4-title">𝒜: sample × location × feature</div><div class="block" style="box-shadow:9px -9px #d9dec9,18px -18px #c6ccb2">\${rows(6)}</div></div><div class="times">≈ Σ</div><div><div class="modes"><div class="mode">which samples<br><b>sᵣ</b></div><div class="times">⊗</div><div class="mode">where<br><b>ℓᵣ</b></div><div class="times">⊗</div><div class="mode">features<br><b>fᵣ</b></div></div><p class="l4-note">Each candidate concept is separable across all three modes.</p></div>`}else{stage.innerHTML=`<div><div class="l4-title">𝒜: sample × location × feature</div><div class="block" style="box-shadow:9px -9px #d9dec9,18px -18px #c6ccb2">\${rows(6)}</div></div><div class="times">≈ Σ</div><div><div class="modes"><div class="mode">sample profile</div><div class="times">⊗</div><div class="mode" style="min-width:180px">small location × feature block</div></div><p class="l4-note">A concept may need a small multilinear block rather than one location–feature pair.</p></div>`}}
        root.querySelectorAll('[data-view]').forEach(b=>b.addEventListener('click',()=>{view=b.dataset.view;draw()}));draw();
      })();
      </script>
    </div>
    """)
end

end
