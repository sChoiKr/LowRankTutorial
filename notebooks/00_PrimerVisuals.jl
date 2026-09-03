# Visuals used by 00_Primer.jl.

function flatten_vs_tensor_visual()
    root_id = next_id("flatten-vs-tensor")

    entries = String[]

    for sample = 1:3, token = 1:4, feature = 1:5
        n = (sample -1) * 20 + (token - 1) * 5 + feature

        #Tensor: three slightly offset 4 x 5 slices
        tx = 42 + (sample -1) * 24 + (feature -1) * 19
        ty = 28 + (sample -1) * 20 + (token -1) * 19

        #Matrix: merge sample x token into one row index
        matrix_row = (sample -1) * 4 + token
        mx = 95 + (feature -1) * 19
        my = 18 + (matrix_row -1) * 14

        push!(entries, """
        <i
            class="ft-entry sample-$sample"
            style="
                --tx:$(tx)px;
                --ty:$(ty)px;
                --mx:$(mx)px;
                --my:$(my)px;
                --n:$n;
            "
        ></i>
        """)
    end

    return Base.HTML("""
    <div id="$root_id" class="ft-wrap" data-view="tensor">
      <style>
        #$root_id{--olive:#657047;--blue:#5d7e9d;--terra:#c96f4a;--ochre:#c3a04d;--muted:#68705b;--paper:rgba(255,253,247,.85);color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;margin:1rem 0}
        #$root_id *{box-sizing:border-box}
        #$root_id .ft-controls{display:flex;gap:.55rem;flex-wrap:wrap;margin-bottom:.85rem}
        #$root_id button{border:1px solid rgba(94,103,64,.32);border-radius:999px;background:var(--paper);color:inherit;padding:.5rem .8rem;font:inherit;cursor:pointer}
        #$root_id button[aria-pressed=true]{background:var(--olive);color:white}
        #$root_id .ft-stage{display:grid;grid-template-columns:300px 1fr;gap:1.4rem;align-items:center;}
        #$root_id .ft-object{position:relative;width:280px;height:220px}
        #$root_id .ft-entry{position:absolute; width:16px; height:16px;border:1px solid rgba(255,255,255,.8);border-radius:3px;background:var(--blue); transform:translate(var(--tx),var(--ty));transition:transform .9s ease, background .5s ease;transition-delay:calc(var(--n) * 3ms);}
        #$root_id .sample-1 { background:var(--terra);}
        #$root_id .sample-2 { background:var(--blue);}
        #$root_id .sample-3 { background:var(--ochre);}
        #$root_id .ft-matrix-guide{position:absolute;left:92px;top:15px;width:103px;height:173px;border:1.5px solid rgba(94,103,64,.45);border-radius:8px;background:rgba(255,253,247,.25);opacity:0;transition:opacity .35s ease;pointer-events:none;}
        #$root_id[data-view=matrix] .ft-matrix-guide{opacity:1;}
        #$root_id[data-view=matrix] .ft-entry {transform:translate(var(--mx),var(--my));background:#9ca09a;border:1px solid rgba(84,91,69,.55);border-radius:2px;box-shadow:0 1px 2px rgba(45,50,31,.10);}
        #$root_id .ft-copy{border-left:4px solid var(--olive);padding-left:.9rem;}
        #$root_id .ft-copy p{color:var(--muted);}
        #$root_id .ft-equation {color:var(--olive);font-weight:700;}
        @media(max-width:700px){#$root_id .ft-stage{grid-template-columns:1fr;}}
        @media(prefers-reduced-motion:reduce) {#$root_id .ft-entry {transition:none;}}
      </style>
      <div class="ft-controls">
        <button data-view="tensor" aria-pressed="true">
          Tensor · keep three axes
        </button>
        <button data-view="matrix" aria-pressed="false">
          Flatten sample × token
        </button>
      </div>

      <div class="ft-stage">

        <div class="ft-object">
          <div class="ft-matrix-guide"></div>
          $(join(entries))
        </div>

        <div class="ft-copy">
          <strong id="$root_id-title">
            3 × 4 × 5 activation tensor
          </strong>

          <p id="$root_id-copy">
            Sample, token, and feature remain separate modes.
          </p>

          <div class="ft-equation" id="$root_id-equation">
            sample × token × feature
          </div>
        </div>
      </div>

      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const buttons = [...root.querySelectorAll('[data-view]')];

          const title = root.querySelector('#$root_id-title');
          const copy = root.querySelector('#$root_id-copy');
          const equation = root.querySelector('#$root_id-equation');

          buttons.forEach(button => {
            button.addEventListener('click', () => {
              const matrix = button.dataset.view === 'matrix';

              root.dataset.view = button.dataset.view;

              buttons.forEach(b =>
                b.setAttribute(
                  'aria-pressed',
                  String(b === button)
                )
              );

              title.textContent = matrix
                ? '12 × 5 flattened matrix'
                : '3 × 4 × 5 activation tensor';

              copy.textContent = matrix
                ? 'All 60 entries remain; sample and token now share one row index.'
                : 'Sample, token, and feature remain separate modes.';

              equation.textContent = matrix
                ? '(sample × token) × feature'
                : 'sample × token × feature';
            });
          });
        })();
      </script>
    </div>
    """)
end

function running_tensor_card(tensor::AbstractArray{<:Real,3}; seed::Integer)
    root_id = next_id("primer-specimen")
    dimensions = size(tensor)
    return Base.HTML("""
    <div id="$root_id" class="ps-card">
      <style>
        #$root_id{--olive:#657047;--muted:#68705b;display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px;margin:.8rem 0 1rem;padding:14px;border:1px solid rgba(94,103,64,.28);border-radius:16px;background:rgba(255,253,247,.66);font:14px/1.35 system-ui;color:var(--pluto-output-color,#303628)}
        #$root_id *{box-sizing:border-box}#$root_id .ps-metric{padding:8px 10px;border-left:3px solid var(--olive)}#$root_id .ps-metric span{display:block;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.07em}#$root_id .ps-metric strong{display:block;margin-top:3px;font-size:17px;font-weight:680}#$root_id .ps-question{grid-column:1/-1;margin-top:2px;padding:9px 11px;border-radius:10px;background:rgba(101,112,71,.09);color:var(--muted)}#$root_id .ps-question strong{color:var(--pluto-output-color,#303628)}
        @media(max-width:680px){#$root_id{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(prefers-color-scheme:dark){#$root_id{--muted:#bec4b1;background:rgba(40,44,34,.7)}}
      </style>
      <div class="ps-metric"><span>Specimen</span><strong>𝒳</strong></div>
      <div class="ps-metric"><span>Dimensions</span><strong>$(join(dimensions, " × "))</strong></div>
      <div class="ps-metric"><span>Entries</span><strong>$(length(tensor))</strong></div>
      <div class="ps-metric"><span>Fixed seed</span><strong>$seed</strong></div>
      <div class="ps-question"><strong>Observe:</strong> if one mode size changes, which displayed quantities change—and which structural property, the tensor order, stays fixed?</div>
    </div>
    """)
end

function mode_mechanics_visual(original_size, unfolding_sizes, map_size, result_size)
    root_id = next_id("primer-mechanics")
    unfolding_descriptions = [
        "Mode 1 becomes the rows; modes 2 and 3 are combined into the columns.",
        "Mode 2 becomes the rows; modes 1 and 3 are combined into the columns.",
        "Mode 3 becomes the rows; modes 1 and 2 are combined into the columns.",
    ]
    unfolding_cards = join([
        "<button type=\"button\" data-mode=\"$mode\" aria-pressed=\"$(mode == 1)\">Mode $mode<span>$(join(unfolding_sizes[mode], " × "))</span></button>" for mode in 1:3
    ])
    return Base.HTML("""
    <div id="$root_id" class="pm-root">
      <style>
        #$root_id{--olive:#657047;--blue:#5d7e9d;--terra:#c96f4a;--muted:#68705b;margin:1rem 0;padding:16px;border:1px solid rgba(94,103,64,.28);border-radius:16px;background:rgba(255,253,247,.64);color:var(--pluto-output-color,#303628);font:14px/1.4 system-ui}#$root_id *{box-sizing:border-box}
        #$root_id .pm-title{font-weight:720;margin-bottom:4px}#$root_id .pm-rule{margin-bottom:10px;color:var(--muted);font-size:12px}#$root_id .pm-tabs{display:flex;gap:8px;flex-wrap:wrap}#$root_id button{display:flex;flex-direction:column;gap:2px;min-width:105px;padding:8px 12px;border:1px solid rgba(94,103,64,.3);border-radius:10px;background:transparent;color:inherit;cursor:pointer;text-align:left}#$root_id button[aria-pressed=true]{background:var(--olive);color:white}#$root_id button span{font:12px ui-monospace,SFMono-Regular,monospace}#$root_id .pm-unfold-copy{min-height:20px;margin-top:8px;color:var(--muted);font-size:12px}
        #$root_id .pm-flow{display:grid;grid-template-columns:1fr auto 1fr auto 1fr;gap:12px;align-items:center;margin-top:18px;text-align:center}#$root_id .pm-box{padding:14px 8px;border-radius:12px;background:rgba(93,126,157,.09);border-top:3px solid var(--blue)}#$root_id .pm-box.map{background:rgba(201,111,74,.08);border-color:var(--terra)}#$root_id .pm-box strong{display:block;font-size:18px}#$root_id .pm-box span{display:block;color:var(--muted);font-size:11px;margin-top:3px}#$root_id .pm-arrow{font-size:22px;color:var(--olive)}#$root_id .pm-observe{margin-top:14px;padding:9px 11px;border-left:3px solid var(--olive);color:var(--muted)}
        @media(max-width:700px){#$root_id .pm-flow{grid-template-columns:1fr}#$root_id .pm-arrow{transform:rotate(90deg)}}@media(prefers-color-scheme:dark){#$root_id{--muted:#bec4b1;background:rgba(40,44,34,.7)}}
      </style>
      <div class="pm-title">Unfold the same tensor—no entries are added or removed</div>
      <div class="pm-rule">Rows = selected mode; columns = all remaining indices combined.</div>
      <div class="pm-tabs" role="group" aria-label="Unfolding sizes">$unfolding_cards</div>
      <div class="pm-unfold-copy" aria-live="polite">$(unfolding_descriptions[1])</div>
      <div class="pm-flow">
        <div class="pm-box"><strong>$(join(original_size, " × "))</strong><span>running tensor</span></div><div class="pm-arrow">×₁</div>
        <div class="pm-box map"><strong>$(join(map_size, " × "))</strong><span>one mode-1 map</span></div><div class="pm-arrow">→</div>
        <div class="pm-box"><strong>$(join(result_size, " × "))</strong><span>result tensor</span></div>
      </div>
      <div class="pm-observe"><strong>What changed?</strong> Only the first dimension: $(original_size[1]) → $(result_size[1]). Modes 2 and 3 keep their sizes.</div>
      <script>(()=>{const root=document.getElementById('$root_id'),copy=root.querySelector('.pm-unfold-copy'),descriptions=$(repr(unfolding_descriptions));root.querySelectorAll('[data-mode]').forEach(button=>button.addEventListener('click',()=>{root.querySelectorAll('[data-mode]').forEach(item=>item.setAttribute('aria-pressed',String(item===button)));copy.textContent=descriptions[Number(button.dataset.mode)-1];}));})();</script>
    </div>
    """)
end

function tucker_structure_inspector(target, result; error)
    root_id = next_id("primer-tucker")
    dimensions = size(target)
    core_dimensions = size(core(result))
    factor_dimensions = size.(factors(result))
    compression = dimensions ./ core_dimensions
    strongest_mode = argmax(compression)
    factors_markup = join([
        "<div class=\"pt-factor\"><strong>U<sup>($mode)</sup></strong><span>$(dimensions[mode]) → $(core_dimensions[mode])</span><div class=\"pt-retained\"><i style=\"width:$(round(Int, 100core_dimensions[mode] / dimensions[mode]))%\"></i></div><em>$(number_label(compression[mode]))× reduction</em></div>" for mode in 1:3
    ])
    reconstruction = reconstruct(result)
    reconstruction_markup = tensor_slice_pair_markup(
        reconstruction,
        maximum(abs, reconstruction; init = 0.0);
        width = 76,
        height = 54,
    )
    return Base.HTML("""
    <div id="$root_id" class="pt-root">
      <style>
        #$root_id{--olive:#657047;--blue:#5d7e9d;--terra:#c96f4a;--muted:#68705b;margin:1rem 0;padding:17px;border:1px solid rgba(94,103,64,.28);border-radius:16px;background:rgba(255,253,247,.64);color:var(--pluto-output-color,#303628);font:14px/1.4 system-ui}#$root_id *{box-sizing:border-box}#$root_id .pt-layout{display:grid;grid-template-columns:1.15fr .7fr 1fr;gap:14px;align-items:center}#$root_id .pt-title{font-size:17px;font-weight:720;margin-bottom:11px}#$root_id .pt-factor{display:grid;grid-template-columns:48px 54px minmax(60px,1fr) 82px;gap:7px;align-items:center;margin:9px 0}#$root_id .pt-factor span{color:var(--muted);font:12px ui-monospace,SFMono-Regular,monospace}#$root_id .pt-factor em{color:var(--muted);font-size:10px;font-style:normal}#$root_id .pt-retained{height:12px;border-radius:3px;background:rgba(93,126,157,.12);overflow:hidden}#$root_id .pt-retained i{display:block;height:100%;min-width:5px;border-radius:3px;background:var(--blue)}#$root_id .pt-core{display:grid;place-items:center;min-height:118px;border-radius:14px;background:rgba(201,111,74,.10);border:1px solid rgba(201,111,74,.35);text-align:center}#$root_id .pt-core strong{display:block;color:var(--terra);font-size:22px}#$root_id .pt-core span{display:block;color:var(--muted);font-size:12px}#$root_id .pt-reconstruction{text-align:center}#$root_id .pt-reconstruction>strong{display:block;margin-bottom:6px;font-size:12px}#$root_id .fs-slices{display:flex;gap:3px;justify-content:center}#$root_id .fs-slice svg{display:block;width:100%;height:auto}#$root_id .fs-slice span{display:block;color:var(--muted);font-size:8px}#$root_id .pt-metrics{display:flex;gap:18px;flex-wrap:wrap;margin-top:14px;padding-top:12px;border-top:1px solid rgba(94,103,64,.2)}#$root_id .pt-metrics strong{display:block;font-size:16px}#$root_id .pt-metrics span{color:var(--muted);font-size:11px}#$root_id .pt-evidence{margin-top:13px;padding:10px 12px;border-left:3px solid var(--olive);background:rgba(101,112,71,.08);color:var(--muted)}#$root_id .pt-evidence strong{color:inherit}#$root_id .pt-evidence b{color:var(--pluto-output-color,#303628)}
        @media(max-width:760px){#$root_id .pt-layout{grid-template-columns:1fr}}@media(prefers-color-scheme:dark){#$root_id{--muted:#bec4b1;background:rgba(40,44,34,.7)}}
      </style>
      <div class="pt-title">Tucker structure inspector</div>
      <div class="pt-layout"><div>$factors_markup</div><div class="pt-core"><div><strong>core 𝒢</strong><span>$(join(core_dimensions, " × "))</span></div></div><div class="pt-reconstruction"><strong>reconstruction X̂</strong>$reconstruction_markup</div></div>
      <div class="pt-metrics"><div><strong>mode $strongest_mode</strong><span>compressed most</span></div><div><strong>$(join(size(reconstruct(result)), " × "))</strong><span>reconstructed size</span></div><div><strong>$(@sprintf("%.3e", error))</strong><span>ST-HOSVD relative error</span></div></div>
      <div class="pt-evidence"><b>Established:</b> this fit uses one core and three mode factors, with the strongest reduction in mode $strongest_mode.<br><strong>Not established:</strong> that this is the correct scientific model or that its coordinates are unique.</div>
    </div>
    """)
end

function vector_profile_markup(vector)
    scale = maximum(abs, vector; init = 0.0)
    bars = join([
        "<i class=\"$(value < 0 ? "negative" : "positive")\" style=\"height:$(round(Int, 5 + 30abs(value) / max(scale, eps())))px\"><span>$(number_label(value))</span></i>" for value in vector
    ])
    return "<div class=\"pc-bars\">$bars</div>"
end

function cp_component_inspector(target, result; error)
    root_id = next_id("primer-cp")
    factor_matrices = factors(result)
    rank = length(weights(result))
    cards = join([
        """
        <div class="pc-card"><div class="pc-card-title"><strong>component $component</strong><span>λ = $(number_label(weights(result)[component]))</span></div>
          $(join(["<div class=\"pc-mode\"><span>mode $mode</span>$(vector_profile_markup(factor_matrices[mode][:, component]))</div>" for mode in 1:3]))
          <div class="pc-link">u<sub>$component</sub><sup>(1)</sup> ⊗ u<sub>$component</sub><sup>(2)</sup> ⊗ u<sub>$component</sub><sup>(3)</sup></div>
        </div>
        """ for component in 1:rank
    ])
    return Base.HTML("""
    <div id="$root_id" class="pc-root">
      <style>
        #$root_id{--olive:#657047;--blue:#5d7e9d;--terra:#c96f4a;--muted:#68705b;margin:1rem 0;padding:17px;border:1px solid rgba(94,103,64,.28);border-radius:16px;background:rgba(255,253,247,.64);color:var(--pluto-output-color,#303628);font:14px/1.4 system-ui}#$root_id *{box-sizing:border-box}#$root_id .pc-title{display:flex;justify-content:space-between;gap:14px;align-items:baseline;margin-bottom:5px}#$root_id .pc-title strong{font-size:17px}#$root_id .pc-title span{color:var(--muted);font-size:12px}#$root_id .pc-legend{margin-bottom:10px;color:var(--muted);font-size:10px;text-align:right}#$root_id .pc-legend .positive{color:var(--blue);font-weight:700}#$root_id .pc-legend .negative{color:var(--terra);font-weight:700}#$root_id .pc-grid{display:grid;grid-template-columns:repeat($rank,minmax(0,1fr));gap:12px}#$root_id .pc-card{padding:12px;border-top:3px solid var(--blue);background:rgba(93,126,157,.07)}#$root_id .pc-card-title{display:flex;justify-content:space-between;gap:8px}#$root_id .pc-card-title span{color:var(--muted);font-size:11px}#$root_id .pc-mode{display:grid;grid-template-columns:50px 1fr;gap:8px;align-items:end;margin-top:10px}#$root_id .pc-mode>span{color:var(--muted);font-size:10px}#$root_id .pc-bars{height:42px;display:flex;align-items:center;gap:3px;border-bottom:1px solid rgba(94,103,64,.25)}#$root_id .pc-bars i{position:relative;display:block;flex:1;min-width:5px;max-width:18px;border-radius:2px 2px 0 0}#$root_id .pc-bars i.positive{background:var(--blue)}#$root_id .pc-bars i.negative{background:var(--terra)}#$root_id .pc-bars i span{display:none}#$root_id .pc-link{margin-top:10px;color:var(--olive);font-family:Georgia,Cambria,serif;text-align:center}#$root_id .pc-evidence{margin-top:13px;padding:10px 12px;border-left:3px solid var(--olive);background:rgba(101,112,71,.08);color:var(--muted)}#$root_id .pc-evidence b{color:var(--pluto-output-color,#303628)}
        @media(max-width:680px){#$root_id .pc-grid{grid-template-columns:1fr}}@media(prefers-color-scheme:dark){#$root_id{--muted:#bec4b1;background:rgba(40,44,34,.7)}}
      </style>
      <div class="pc-title"><strong>Two linked rank-one components</strong><span>rank $rank · relative error $(@sprintf("%.3e", error))</span></div>
      <div class="pc-legend"><span class="positive">blue: ≥ 0</span> · <span class="negative">terra: &lt; 0</span></div>
      <div class="pc-grid">$cards</div>
      <div class="pc-evidence"><b>Established:</b> $rank complete outer-product patterns reconstruct this target with the displayed error.<br><strong>Not established:</strong> that the components are unique, stable, or semantic concepts.</div>
    </div>
    """)
end

function btd_structure_inspector(target, result; error)
    root_id = next_id("primer-btd")
    fitted_blocks = blocks(result)
    block_rank = size(core(first(fitted_blocks)))
    blocks_markup = join(["<div class=\"pb-block\"><span>block $index</span><strong>core $(join(size(core(block)), " × "))</strong><i>mode ranks $(join(size(core(block)), " | "))</i><i>Tucker structure inside</i></div>" for (index, block) in enumerate(fitted_blocks)])
    return Base.HTML("""
    <div id="$root_id" class="pb-root">
      <style>
        #$root_id{--olive:#657047;--blue:#5d7e9d;--terra:#c96f4a;--muted:#68705b;margin:1rem 0;padding:17px;border:1px solid rgba(94,103,64,.28);border-radius:16px;background:rgba(255,253,247,.64);color:var(--pluto-output-color,#303628);font:14px/1.4 system-ui}#$root_id *{box-sizing:border-box}#$root_id .pb-contrast{display:grid;grid-template-columns:.8fr auto 1.3fr;gap:12px;align-items:center}#$root_id .pb-cp{padding:14px;border:1px dashed rgba(93,126,157,.5);text-align:center}#$root_id .pb-cp strong{display:block;color:var(--blue)}#$root_id .pb-arrow{color:var(--olive);font-size:23px}#$root_id .pb-blocks{display:grid;grid-template-columns:repeat($(length(fitted_blocks)),minmax(0,1fr));gap:8px}#$root_id .pb-block{padding:11px;border-top:3px solid var(--terra);background:rgba(201,111,74,.07)}#$root_id .pb-block span,#$root_id .pb-block i{display:block;color:var(--muted);font-size:10px;font-style:normal}#$root_id .pb-block strong{display:block;margin:4px 0;font-size:13px}#$root_id .pb-metric{margin-top:13px;color:var(--muted)}#$root_id .pb-evidence{margin-top:11px;padding:10px 12px;border-left:3px solid var(--olive);background:rgba(101,112,71,.08);color:var(--muted)}#$root_id .pb-evidence b{color:var(--pluto-output-color,#303628)}
        @media(max-width:680px){#$root_id .pb-contrast{grid-template-columns:1fr}#$root_id .pb-arrow{transform:rotate(90deg);text-align:center}}@media(prefers-color-scheme:dark){#$root_id{--muted:#bec4b1;background:rgba(40,44,34,.7)}}
      </style>
      <div class="pb-contrast"><div class="pb-cp"><strong>CP term · 1 × 1 × 1</strong><span>one direction per mode</span><div>a ⊗ b ⊗ c</div></div><div class="pb-arrow">versus</div><div class="pb-blocks">$blocks_markup</div></div>
      <div class="pb-metric">BTD fit: $(length(fitted_blocks)) blocks · shared block rank $(join(block_rank, " × ")) · relative error $(@sprintf("%.3e", error))</div>
      <div class="pb-evidence"><b>Established:</b> each fitted term may carry multilinear variation inside its block, unlike one CP rank-one term.<br><strong>Not established:</strong> that a block corresponds to a real-world concept or that this block structure is uniquely determined.</div>
    </div>
    """)
end

function nonnegative_constraint_visual(target, cp_result, nncp_result; cp_error, nncp_error)
    root_id = next_id("primer-nonnegative")
    cp_minimum = min(minimum(weights(cp_result)), minimum(minimum, factors(cp_result)))
    nncp_minimum = min(minimum(weights(nncp_result)), minimum(minimum, factors(nncp_result)))
    cp_minimum_class = cp_minimum < 0 ? "pn-negative" : ""
    target_markup = tensor_slice_pair_markup(target, maximum(target); width = 86, height = 60)
    return Base.HTML("""
    <div id="$root_id" class="pn-root">
      <style>
        #$root_id{--olive:#657047;--blue:#5d7e9d;--terra:#c96f4a;--muted:#68705b;margin:1rem 0;padding:17px;border:1px solid rgba(94,103,64,.28);border-radius:16px;background:rgba(255,253,247,.64);color:var(--pluto-output-color,#303628);font:14px/1.4 system-ui}#$root_id *{box-sizing:border-box}#$root_id .pn-layout{display:grid;grid-template-columns:.75fr 1.25fr;gap:18px;align-items:center}#$root_id .pn-target{text-align:center}#$root_id .pn-target strong{display:block;margin-bottom:7px}#$root_id .fs-slices{display:flex;gap:4px;justify-content:center}#$root_id .fs-slice svg{display:block;width:100%;height:auto}#$root_id .fs-slice span{display:block;color:var(--muted);font-size:9px}#$root_id table{width:100%;border-collapse:collapse;font-size:12px}#$root_id th,#$root_id td{padding:8px;border-bottom:1px solid rgba(94,103,64,.2);text-align:left}#$root_id th{color:var(--muted);font-weight:650}#$root_id .pn-negative{color:var(--terra);font-weight:700}#$root_id .pn-nonnegative{color:var(--olive);font-weight:700}#$root_id .pn-evidence{margin-top:13px;padding:10px 12px;border-left:3px solid var(--olive);background:rgba(101,112,71,.08);color:var(--muted)}#$root_id .pn-evidence b{color:var(--pluto-output-color,#303628)}
        @media(max-width:700px){#$root_id .pn-layout{grid-template-columns:1fr}}@media(prefers-color-scheme:dark){#$root_id{--muted:#bec4b1;background:rgba(40,44,34,.7)}}
      </style>
      <div class="pn-layout"><div class="pn-target"><strong>Same nonnegative target 𝒴 ≥ 0</strong>$target_markup</div><table><thead><tr><th>fit</th><th>relative error</th><th>minimum returned coordinate</th><th>guarantee</th></tr></thead><tbody><tr><td>CP</td><td>$(@sprintf("%.3e", cp_error))</td><td class="$cp_minimum_class">$(number_label(cp_minimum))</td><td>none on signs</td></tr><tr><td>NNCP</td><td>$(@sprintf("%.3e", nncp_error))</td><td class="pn-nonnegative">$(number_label(nncp_minimum))</td><td>coordinates ≥ 0</td></tr></tbody></table></div>
      <div class="pn-evidence"><b>Established:</b> NNCP enforces nonnegative coordinates; unconstrained CP may use negative coordinates for the same nonnegative data. Errors describe these particular fits; this comparison concerns the sign constraint.<br><strong>Not established:</strong> that either component is identifiable or has a semantic meaning. Nonnegativity is a modeling constraint, not semantic validation.</div>
    </div>
    """)
end

"""
    ai_geometry_bridge_visual()

Connect four low-rank coordinate systems to their intrinsic geometric objects
and to recent AI uses. The paper names are pedagogical bridges, not claims that
the notebook reproduces the full methods.
"""

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
            <div class="di-cpd-layout">
              <div class="di-cpd-sum">$source_tensor<span class="di-op di-cpd-approx">≈</span>
              $first_term<span class="di-op di-dots">+ ··· +</span>$last_term</div>
              <div class="di-cpd-storage"><span>the vectors are stored as columns—not equated with the tensor</span>$factor_matrices</div>
            </div>
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
        #$root_id .di-cpd-layout { display:flex; flex-direction:column; align-items:center; width:100%; }
        #$root_id .di-cpd-sum { display:flex; align-items:center; justify-content:center; gap:9px; width:100%; }
        #$root_id .di-cpd-storage { display:flex; align-items:center; justify-content:center; gap:12px; margin-top:7px; padding-top:8px; border-top:1px dashed var(--di-line); }
        #$root_id .di-cpd-storage>span { max-width:150px; color:var(--di-muted); font-size:10px; line-height:1.3; text-align:right; }
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
          #$root_id .di-cpd-layout{min-width:560px}
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

"""
    tensor_reconstruction_gallery(target, reconstructions; errors, fingerprints,
                                  target_label, gallery_title, comparison_note)

Build one target-consistent reconstruction gallery. Every supplied error is
checked against the displayed target before rendering, so a metric computed for
one tensor cannot silently appear beside a different target.
"""
function tensor_reconstruction_gallery(
    target::AbstractArray{<:Real,3},
    reconstructions::NamedTuple;
    errors::NamedTuple,
    fingerprints::NamedTuple,
    target_label::AbstractString = "Original target",
    gallery_title::AbstractString = "One target, several reconstructions",
    comparison_note::AbstractString = "These bars describe the displayed target and these particular fits; they are not a capacity-matched model-selection benchmark.",
)
    ndims(target) == 3 || throw(ArgumentError("The synthesis gallery expects an order-three tensor."))
    models = keys(reconstructions)
    isempty(models) && throw(ArgumentError("At least one reconstruction is required."))
    keys(errors) == models || throw(ArgumentError("Error labels must match reconstruction labels and order."))
    keys(fingerprints) == models || throw(ArgumentError("Fingerprint labels must match reconstruction labels and order."))
    target_norm = norm(target)
    for model in models
        hasproperty(errors, model) || throw(ArgumentError("Missing $model error."))
        hasproperty(fingerprints, model) || throw(ArgumentError("Missing $model fingerprint."))
        reconstruction = getproperty(reconstructions, model)
        size(reconstruction) == size(target) ||
            throw(ArgumentError("$model reconstruction has the wrong size."))
        measured_error = iszero(target_norm) ? norm(reconstruction) : norm(target - reconstruction) / target_norm
        isapprox(getproperty(errors, model), measured_error; rtol = 1e-8, atol = 1e-12) ||
            throw(ArgumentError("$model error was not computed against the displayed target."))
    end

    root_id = next_id("tensor-synthesis")
    display_order = Set(models) == Set((:Tucker, :CP, :BTD)) ? (:BTD, :Tucker, :CP) : models
    letters = collect('A':'Z')[1:length(models)]
    reconstruction_scale = maximum([
        maximum(abs, target; init = 0.0),
        [maximum(abs, getproperty(reconstructions, model); init = 0.0) for model in models]...,
    ])
    residuals = Dict(
        model => abs.(target .- getproperty(reconstructions, model)) for model in models
    )
    residual_scale = maximum(maximum(residuals[model]; init = 0.0) for model in models)
    maximum_error = maximum(getproperty(errors, model) for model in models)

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
    for model in models
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

    reveal_mapping = join(["$(letters[index]) = $(display_order[index])" for index in eachindex(display_order)], " · ")
    columns = min(length(models), 4)

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
        #$root_id .fs-reconstruction-grid,#$root_id .fs-residual-grid,#$root_id .fs-fingerprint-grid{display:grid;grid-template-columns:repeat($columns,minmax(0,1fr));gap:10px}
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
        }
      </style>

      <section class="fs-section">
        <div class="fs-kicker">A · What object did they reconstruct?</div>
        <div class="fs-title">$(escape_html(gallery_title))</div>
        <div class="fs-original"><div><strong>$(escape_html(target_label)) · $(join(size(target), " × "))</strong>$original_markup</div></div>
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
          <div class="fs-error-chart" role="img" aria-label="Relative reconstruction errors against the displayed target">$(join(error_rows))</div>
          <div class="fs-warning"><strong>Read against this target only.</strong> $(escape_html(comparison_note))</div>
        </section>

        <section class="fs-section">
          <div class="fs-kicker">D · What coordinates did they learn?</div>
          <div class="fs-title">Model fingerprints</div>
          <div class="fs-fingerprint-grid">$(join(fingerprint_cards))</div>
        </section>

        <section class="fs-section"><div class="fs-bridge"><strong>Similar reconstructions ≠ the same factorization.</strong><span>Lab 1 continues with the distinction between the represented object and its coordinates.</span></div></section>
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
            answer.textContent = '$(escape_html(reveal_mapping)). The object alone did not reveal the coordinate system.';
          });
        })();
      </script>
    </div>
    """)
end
