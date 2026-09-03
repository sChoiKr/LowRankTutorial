# Visuals used by 01_OneObjectManyCoordinates.jl.

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
          <div class="cp-section-title">Coordinate view: component 1</div>
          $mode_rows
          <div class="cp-meter coordinate"><div class="cp-meter-head"><span>Coordinate difference</span><strong>$(number_label(result.relative_coordinate_change))</strong></div><div class="cp-track"><i></i></div></div>
          <div style="color:#626954;font-size:.8rem;margin-top:.5rem">α=$(number_label(result.alpha))  β=$(number_label(result.beta))  permute=$(result.reversed)  ε=$(number_label(result.epsilon))</div>
        </div>
        <div class="cp-arrow"><strong>→</strong><span>reconstruct<br>π(θ)</span></div>
        <div>
          <div class="cp-section-title">Object view: first tensor slice</div>
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
      <div class="gr-start">Same target, same start, same optimization budget<span class="gr-ratio">component scale separation 1 : $(number_label(scale_ratio))</span></div>
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
          <tr><td>final fit: relative error</td><td>$(number_label(result.canonical.relative_error))</td><td>$(number_label(result.native.relative_error))</td></tr>
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
