# Visuals used by 03_OptimizationFailureMuseum.jl.

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
              <td data-label="component separation"><strong>$(number_label(case.minimum_distance))</strong><span>near 0 = indistinguishable</span></td>
              <td data-label="update sensitivity"><strong>$(case.maximum_condition < 3 ? "low" : case.maximum_condition < 10 ? "rising" : case.maximum_condition < 100 ? "high" : "very high")</strong><span>higher = less reliable allocation</span></td>
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
        @media(max-width:760px){#$root_id thead{display:none}#$root_id table,#$root_id tbody,#$root_id tr,#$root_id th,#$root_id td{display:block}#$root_id tbody tr{padding:.55rem;border-bottom:1px solid #dfe2d5}#$root_id th,#$root_id td{border:0;padding:.25rem .45rem}#$root_id td:before{content:attr(data-label) '  ';font-size:.68rem;color:#737a65}#$root_id .fc-takeaway{grid-template-columns:1fr}}
        @media(prefers-color-scheme:dark){#$root_id table{background:#25281f;border-color:#555d45}#$root_id thead th,#$root_id .fc-takeaway div{background:#303526;color:#e6eadc}#$root_id tbody th,#$root_id td strong,#$root_id .fc-title{color:#e6eadc}#$root_id td,#$root_id td span{color:#c9cfbd}}
      </style>
      <div class="fc-title">Same rank and ALS budget; different diagnostic stories</div>
      <table>
        <thead><tr><th>case</th><th>reconstruction progress</th><th>component separation</th><th>ALS update sensitivity</th><th>diagnosis</th></tr></thead>
        <tbody>$rows</tbody>
      </table>
      <div class="fc-takeaway"><div>Slow optimization ⇏ component collision.</div><div>Low separation + high update sensitivity supports a collision explanation.</div></div>
    </div>
    """)
end

"""Show two complete CP patterns merging, then let the learner redistribute their shared signal."""
function component_collision_visual(result)
    root_id = next_id("component-collision")
    rho = Float64(result.rho)
    display_rho = 0.20
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
    reference_vectors = [Float64.(result.factors[mode][:, 1]) for mode in eachindex(result.factors)]
    orthogonal_vectors = [
        (Float64.(result.factors[mode][:, 2]) .- rho .* reference_vectors[mode]) ./
        sqrt(max(1 - rho^2, eps())) for mode in eachindex(result.factors)
    ]
    js_array(values) = "[$(join(string.(values), ","))]"
    js_reference = "[$(join(js_array.(reference_vectors), ","))]"
    js_orthogonal = "[$(join(js_array.(orthogonal_vectors), ","))]"
    profiles = join([
        """
        <div class="cc-profile-panel">
          <div class="cc-mode">Mode $mode factor columns</div>
          $(paired_profile_svg(result.factors[mode][:, 1], result.factors[mode][:, 2]))
        </div>
        """ for mode in eachindex(result.factors)
    ])
    function vector_glyph(values, label, component; dynamic = false, mode = 1)
        maximum_magnitude = max(maximum(abs, values), eps())
        entries = join([
            begin
                sign_class = value >= 0 ? "positive" : "negative"
                opacity = round(0.28 + 0.72 * abs(value) / maximum_magnitude; digits = 3)
                data = dynamic ? "data-mode-entry data-mode=\"$mode\" data-index=\"$index\"" : ""
                "<i class=\"$sign_class\" style=\"opacity:$opacity\" $data></i>"
            end for (index, value) in enumerate(values)
        ])
        """
        <div class="cc-vector-group cc-component-$component" aria-label="$label vector for component $component">
          <div class="cc-vector-bracket">$entries</div>
          <span>$label</span>
        </div>
        """
    end
    function tensor_pattern(component; dynamic = false)
        a = result.factors[1][:, component]
        b = result.factors[2][:, component]
        slice_scale = result.factors[3][1, component]
        values = a * b' .* slice_scale
        maximum_magnitude = max(maximum(abs, values), eps())
        cells = join([
            begin
                value = values[row, column]
                sign_class = value >= 0 ? "positive" : "negative"
                opacity = round(0.22 + 0.78 * abs(value) / maximum_magnitude; digits = 3)
                data = dynamic ? "data-pattern-entry data-row=\"$row\" data-column=\"$column\"" : ""
                "<i class=\"$sign_class\" style=\"opacity:$opacity\" $data></i>"
            end for row in axes(values, 1) for column in axes(values, 2)
        ])
        "<div class=\"cc-pattern cc-component-$component\" aria-label=\"First slice of rank-one tensor component $component\">$cells</div>"
    end
    function outer_product_term(component)
        suffix = component == 1 ? "₁" : "₂"
        dynamic = component == 2
        vector_a = vector_glyph(result.factors[1][:, component], "a$suffix", component; dynamic, mode = 1)
        vector_b = vector_glyph(result.factors[2][:, component], "b$suffix", component; dynamic, mode = 2)
        vector_c = vector_glyph(result.factors[3][:, component], "c$suffix", component; dynamic, mode = 3)
        pattern = tensor_pattern(component; dynamic)
        """
        <div class="cc-term cc-term-$component">
          <div class="cc-term-name"><strong>Component $component</strong><span>T$suffix</span></div>
          <div class="cc-factor-row">$vector_a<span class="cc-outer">⊗</span>$vector_b<span class="cc-outer">⊗</span>$vector_c<span class="cc-equals">→</span>$pattern</div>
        </div>
        """
    end
    outer_products = outer_product_term(1) * outer_product_term(2)
    return Base.HTML("""
    <div id="$root_id" class="cc-wrap" aria-label="Interactive CP component collision explorer">
      <style>
        #$root_id { color:var(--pluto-output-color,#303628);font:15px/1.4 system-ui;width:100%; }
        #$root_id * { box-sizing:border-box; }
        #$root_id .cc-control { margin-bottom:.75rem;padding:.75rem .85rem;border:1px solid #d3d7c5;border-radius:12px;background:#fbfaf4; }
        #$root_id .cc-control label { display:flex;justify-content:space-between;gap:1rem;color:#4f5934;font-weight:700; }
        #$root_id .cc-control input { width:100%;margin:.55rem 0 .2rem;accent-color:#657047; }
        #$root_id .cc-control-scale { display:flex;justify-content:space-between;color:#626954;font-size:.74rem; }
        #$root_id .cc-profiles { display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.65rem;min-width:0; }
        #$root_id .cc-profile-panel,#$root_id .cc-object-space { border:1px solid #d3d7c5;background:#fbfaf4;border-radius:14px;padding:.7rem;min-width:0; }
        #$root_id .cc-profile-panel { overflow:hidden; }
        #$root_id .cc-mode { color:#626954;font-size:.82rem;font-weight:650;margin-bottom:.15rem; }
        #$root_id .cc-grid { stroke:#d8d9cf;stroke-width:1; }
        #$root_id .cc-profile-one { fill:none;stroke:#5d7e9d;stroke-width:3; }
        #$root_id .cc-profile-two { fill:none;stroke:#c96f4a;stroke-width:3;stroke-dasharray:7 5; }
        #$root_id .cc-object-space { overflow:hidden; }
        #$root_id .cc-object-title { display:flex;justify-content:space-between;gap:1rem;color:#626954;font-size:.82rem;font-weight:650;margin-bottom:.55rem; }
        #$root_id .cc-status { color:#4f5934; }
        #$root_id .cc-outer-products { display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.8rem; }
        #$root_id .cc-term { min-width:0;padding:.55rem .65rem;background:#f1f2e8;border-radius:10px;transition:transform .8s cubic-bezier(.2,.75,.2,1); }
        #$root_id .cc-term-name { display:flex;justify-content:space-between;color:#303628;margin-bottom:.45rem; }
        #$root_id .cc-term-name span { color:#626954;font-size:.74rem; }
        #$root_id .cc-factor-row { display:flex;align-items:center;justify-content:center;gap:.3rem;min-width:0; }
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
        #$root_id .cc-pattern { display:grid;grid-template-columns:repeat(4,8px);grid-template-rows:repeat(4,8px);gap:2px;padding:4px;border:1px solid currentColor;color:#5d7e9d;flex:0 0 auto; }
        #$root_id .cc-pattern.cc-component-2 { color:#c96f4a; }
        #$root_id .cc-pattern i { display:block;background:currentColor;border-radius:1px;transition:opacity .35s ease,background .35s ease; }
        #$root_id .cc-pattern i.negative { background:transparent;border:1px solid currentColor; }
        #$root_id .cc-metrics { display:grid;grid-template-columns:repeat(2,1fr);gap:.55rem;margin-top:.8rem; }
        #$root_id .cc-metric { border-top:3px solid #657047;background:#f1f2e8;padding:.55rem .65rem;border-radius:0 0 8px 8px; }
        #$root_id .cc-metric span { display:block;color:#626954;font-size:.76rem; }
        #$root_id .cc-metric strong { display:block;font-size:1.05rem;font-variant-numeric:tabular-nums;color:#303628; }
        #$root_id .cc-track { height:10px;background:#dfe2d5;border-radius:999px;overflow:hidden;margin:.4rem 0 .2rem; }
        #$root_id .cc-track i { display:block;height:100%;background:#657047;border-radius:inherit;transition:width .45s ease; }
        #$root_id .cc-metric small { display:block;color:#626954;font-size:.7rem; }
        #$root_id .cc-mode-values { display:flex!important;gap:.55rem;flex-wrap:wrap;margin-top:.12rem; }
        #$root_id .cc-mode-values span { display:inline!important;color:#303628;font-size:.78rem; }
        #$root_id .cc-mode-values b { font-variant-numeric:tabular-nums; }
        #$root_id .cc-conclusion { margin:.65rem 0 0;text-align:center;color:#4f5934;font-weight:650;min-height:1.4em; }
        #$root_id .cc-redistribute { margin-top:.8rem;padding:.75rem .85rem;border-left:4px solid #c96f4a;background:#f1f2e8; }
        #$root_id .cc-redistribute-head { display:flex;justify-content:space-between;align-items:center;gap:.75rem;flex-wrap:wrap; }
        #$root_id .cc-redistribute button { border:1px solid #657047;border-radius:999px;background:#657047;color:white;padding:.45rem .75rem;font:600 14px system-ui;cursor:pointer; }
        #$root_id .cc-allocation { display:grid;grid-template-columns:1fr 1fr;gap:.65rem;margin-top:.65rem; }
        #$root_id .cc-allocation label { display:flex;justify-content:space-between;color:#626954;font-size:.76rem; }
        #$root_id .cc-allocation .cc-track i { background:#5d7e9d; }
        #$root_id .cc-allocation>div:nth-child(2) .cc-track i { background:#c96f4a; }
        #$root_id .cc-object-change { margin-top:.6rem;padding-top:.55rem;border-top:1px solid #d3d7c5; }
        #$root_id .cc-object-change label { display:flex;justify-content:space-between;gap:.75rem;color:#626954;font-size:.76rem; }
        #$root_id .cc-object-change .cc-track i { background:#657047; }
        #$root_id .cc-change { margin-top:.55rem;color:#4f5934;font-size:.8rem;font-weight:650; }
        #$root_id .cc-detail { margin-top:.8rem;border:1px solid #d3d7c5;border-radius:12px;background:#fbfaf4;overflow:hidden; }
        #$root_id .cc-detail summary { cursor:pointer;padding:.65rem .8rem;color:#626954;font-weight:650; }
        #$root_id .cc-detail-body { padding:0 .8rem .8rem; }
        #$root_id .cc-detail-equation { margin:.65rem 0 0;color:#626954;font-size:.8rem;line-height:1.45;text-align:center; }
        #$root_id .cc-detail-equation code { color:#303628;background:#f1f2e8;padding:.15rem .35rem;border-radius:5px; }
        #$root_id .cc-legend { display:flex;gap:1rem;flex-wrap:wrap;color:#626954;font-size:.8rem; }
        #$root_id .cc-line { width:28px;border-top:3px solid #5d7e9d;display:inline-block;vertical-align:middle;margin-right:.3rem; }
        #$root_id .cc-line.dashed { border-color:#c96f4a;border-top-style:dashed; }
        @media(max-width:760px){#$root_id .cc-outer-products{grid-template-columns:1fr}#$root_id .cc-term{transform:none!important}}
        @media(max-width:680px){#$root_id .cc-profiles{grid-template-columns:1fr}#$root_id .cc-metrics{grid-template-columns:1fr}}
        @media(max-width:430px){#$root_id .cc-term{gap:.2rem;padding:.4rem .35rem}#$root_id .cc-vector-bracket{padding-inline:5px;min-width:26px}#$root_id .cc-vector-bracket i{width:14px}#$root_id .cc-term-name{min-width:53px}#$root_id .cc-term-name span{white-space:normal}}
        @media(prefers-reduced-motion:reduce){#$root_id .cc-term,#$root_id .cc-track i,#$root_id .cc-pattern i{transition-duration:.01ms}}
        @media(prefers-color-scheme:dark){#$root_id .cc-control,#$root_id .cc-profile-panel,#$root_id .cc-object-space,#$root_id .cc-detail{background:#25281f;border-color:#555d45}#$root_id .cc-term,#$root_id .cc-metric,#$root_id .cc-redistribute,#$root_id .cc-detail-equation code{background:#303526}#$root_id .cc-control label,#$root_id .cc-control-scale,#$root_id .cc-status,#$root_id .cc-mode,#$root_id .cc-object-title,#$root_id .cc-vector-group>span,#$root_id .cc-legend,#$root_id .cc-metric span,#$root_id .cc-mode-values span,#$root_id .cc-allocation label,#$root_id .cc-object-change label,#$root_id .cc-detail summary,#$root_id .cc-detail-equation,#$root_id .cc-conclusion,#$root_id .cc-change{color:#d6dcc8}#$root_id .cc-term-name,#$root_id .cc-term-name strong,#$root_id .cc-metric strong,#$root_id .cc-detail-equation code{color:#f2f3eb}#$root_id .cc-term-name span{color:#c6cdb9}#$root_id .cc-grid{stroke:#555}#$root_id .cc-track{background:#454b3b}#$root_id .cc-object-change{border-top-color:#555d45}}
      </style>
      <div class="cc-control">
        <label for="$root_id-rho"><span>Make the two components more alike</span><output id="$root_id-rho-value">$(round(100display_rho; digits=1))%</output></label>
        <input id="$root_id-rho" type="range" min="0" max="0.999" step="0.001" value="$display_rho">
        <div class="cc-control-scale"><span>Distinct</span><span>Almost identical</span></div>
      </div>
      <div class="cc-object-space">
        <div class="cc-object-title"><span>Complete rank-one patterns</span><span class="cc-status" id="$root_id-status"></span></div>
        <div class="cc-outer-products">$outer_products</div>
      </div>
      <div class="cc-metrics">
        <div class="cc-metric"><span>Component separation</span><strong id="$root_id-separation">$(number_label(collision_distance))</strong><div class="cc-track"><i id="$root_id-separation-bar"></i></div><small>near 0 = nearly indistinguishable</small></div>
        <div class="cc-metric"><span>ALS update sensitivity</span><strong id="$root_id-sensitivity"></strong><div class="cc-track"><i id="$root_id-sensitivity-bar"></i></div><small>higher = harder to divide the shared signal reliably</small></div>
      </div>
      <div class="cc-conclusion" id="$root_id-conclusion"></div>
      <div class="cc-redistribute">
        <div class="cc-redistribute-head"><strong>Can a different allocation produce almost the same pattern?</strong><button type="button" id="$root_id-redistribute">Redistribute shared signal</button></div>
        <div class="cc-allocation">
          <div><label><span>Component 1 contribution</span><b id="$root_id-share1">50%</b></label><div class="cc-track"><i id="$root_id-share1-bar" style="width:50%"></i></div></div>
          <div><label><span>Component 2 contribution</span><b id="$root_id-share2">50%</b></label><div class="cc-track"><i id="$root_id-share2-bar" style="width:50%"></i></div></div>
        </div>
        <div class="cc-object-change"><label><span>Reconstructed pattern change</span><b id="$root_id-object-change-label">none yet</b></label><div class="cc-track"><i id="$root_id-object-change-bar" style="width:0%"></i></div></div>
        <div class="cc-change" id="$root_id-change">Change the allocation after choosing a similarity level.</div>
      </div>
      <details class="cc-detail">
        <summary>Optional math: How are overlap and separation computed?</summary>
        <div class="cc-detail-body">
          <div class="cc-detail-equation"><code>dᵢⱼ = min(‖T̂ᵢ−T̂ⱼ‖F, ‖T̂ᵢ+T̂ⱼ‖F)</code></div>
          <div class="cc-detail-equation"><code>qᵢⱼ = |⟨T̂ᵢ,T̂ⱼ⟩F| = product of the modewise cosine magnitudes</code></div>
          <div class="cc-profiles">$profiles</div>
          <div class="cc-mode-values">$modewise_labels</div>
          <div class="cc-detail-equation"><code>Worked snapshot at ρ = $(number_label(rho)): q₁₂ = ρ³ = $(number_label(overlap)); d₁₂ = √(2 − 2ρ³) = $(number_label(collision_distance))</code></div>
          <div class="cc-legend"><span><i class="cc-line"></i>component 1</span><span><i class="cc-line dashed"></i>component 2</span></div>
        </div>
      </details>
      <script>
        (() => {
          const root = document.getElementById('$root_id');
          const slider = root.querySelector('#$root_id-rho');
          const reference = $js_reference;
          const orthogonal = $js_orthogonal;
          let redistributed = false;
          const format = value => value < 0.001 ? value.toExponential(2) : value.toFixed(value < 0.1 ? 3 : 2);
          const vectorsAt = rho => reference.map((mode, m) => mode.map((value, i) => rho * value + Math.sqrt(Math.max(0, 1-rho*rho)) * orthogonal[m][i]));
          const paint = (cell, value, scale) => {
            cell.classList.toggle('negative', value < 0);
            cell.classList.toggle('positive', value >= 0);
            cell.style.opacity = String(.22 + .78 * Math.abs(value) / Math.max(scale, Number.EPSILON));
          };
          const updateRedistribution = separation => {
            const first = redistributed ? 80 : 50, second = 100 - first;
            root.querySelector('#$root_id-share1').textContent = first + '%';
            root.querySelector('#$root_id-share2').textContent = second + '%';
            root.querySelector('#$root_id-share1-bar').style.width = first + '%';
            root.querySelector('#$root_id-share2-bar').style.width = second + '%';
            const change = .3 * separation;
            const word = change < .025 ? 'tiny' : change < .10 ? 'small' : change < .25 ? 'noticeable' : 'large';
            root.querySelector('#$root_id-object-change-label').textContent = redistributed ? word : 'none yet';
            root.querySelector('#$root_id-object-change-bar').style.width = redistributed ? (100*separation/Math.sqrt(2)) + '%' : '0%';
            root.querySelector('#$root_id-change').textContent = redistributed
              ? 'The coordinate allocation changed strongly; the reconstructed pattern change is ' + word + '.'
              : 'Change the allocation after choosing a similarity level.';
          };
          const update = () => {
            const rho = Number(slider.value);
            const vectors = vectorsAt(rho);
            const overlap = rho ** 3;
            const separation = Math.sqrt(Math.max(0, 2 - 2 * overlap));
            const condition = (1 + rho*rho) / Math.max(1 - rho*rho, Number.EPSILON);
            root.querySelector('#$root_id-rho-value').textContent = (100*rho).toFixed(1) + '%';
            root.querySelectorAll('[data-mode-entry]').forEach(cell => {
              const m = Number(cell.dataset.mode)-1, i = Number(cell.dataset.index)-1;
              paint(cell, vectors[m][i], Math.max(...vectors[m].map(Math.abs)));
            });
            const pattern = [];
            for (let row=0; row<vectors[0].length; row++) for (let column=0; column<vectors[1].length; column++) pattern.push(vectors[0][row]*vectors[1][column]*vectors[2][0]);
            const patternScale = Math.max(...pattern.map(Math.abs), Number.EPSILON);
            root.querySelectorAll('[data-pattern-entry]').forEach((cell,index) => paint(cell,pattern[index],patternScale));
            root.querySelector('.cc-term-1').style.transform = 'translateX(' + (rho*8) + '%)';
            root.querySelector('.cc-term-2').style.transform = 'translateX(-' + (rho*8) + '%)';
            root.querySelector('#$root_id-separation').textContent = format(separation);
            root.querySelector('#$root_id-separation-bar').style.width = (100*separation/Math.sqrt(2)) + '%';
            const sensitivity = condition < 3 ? 'Low' : condition < 10 ? 'Rising' : condition < 100 ? 'High' : 'Very high';
            root.querySelector('#$root_id-sensitivity').textContent = sensitivity;
            root.querySelector('#$root_id-sensitivity-bar').style.width = Math.min(100, 25*Math.log10(condition)+8) + '%';
            const status = separation > 1 ? 'Clearly distinct' : separation > .45 ? 'Approaching' : separation > .14 ? 'Difficult to distinguish' : 'Nearly indistinguishable';
            root.querySelector('#$root_id-status').textContent = status;
            root.querySelector('#$root_id-conclusion').textContent = separation < .45
              ? 'ALS can still fit the combined pattern, but separating the two contributions is becoming unreliable.'
              : 'The two complete patterns are still distinguishable, so ALS has a clearer allocation problem.';
            updateRedistribution(separation);
          };
          slider.addEventListener('input', update);
          root.querySelector('#$root_id-redistribute').addEventListener('click', event => {
            redistributed = !redistributed;
            event.currentTarget.textContent = redistributed ? 'Return to equal split' : 'Redistribute shared signal';
            updateRedistribution(Math.sqrt(Math.max(0,2-2*Number(slider.value)**3)));
          });
          update();
        })();
      </script>
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
      <summary>Optional math: Why does ALS conditioning blow up?</summary>
      <div class="gc-body"><div class="gc-equation">
        <div class="gc-piece"><div class="gc-label">BᵀB  column similarity table</div>$(matrix(factor_gram))</div>
        <div class="gc-op">.*</div>
        <div class="gc-piece"><div class="gc-label">CᵀC  column similarity table</div>$(matrix(factor_gram))</div>
        <div class="gc-op">=</div>
        <div class="gc-piece"><div class="gc-label">Hₐ  ALS system</div>$(matrix(als_gram))</div>
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
          <div><span>$(escape_html(label))</span><strong>$(number_label(final_distance)) <small> $distance_meaning</small></strong></div>
          <div class="sr-track"><i style="width:$(100*final_distance/maximum_distance)%;background:$color"></i></div>
        </div>
        """)
        final_condition = final_conditions[index]
        condition_meaning = final_condition < 3 ? "low" :
                            final_condition < 10 ? "rising" :
                            final_condition < 100 ? "high" : "very high"
        condition_width = 100 * condition_logs[index] / maximum_condition_log
        push!(final_condition_bars, """
        <div class="sr-bar-row">
          <div><span>$(escape_html(label))</span><strong>$condition_meaning</strong></div>
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
        <div class="sr-panel"><strong>Component separation over time  stored block-solver points only</strong><div class="sr-help">Only ALS and regularized ALS store a factor point after every sweep. RCG and RGD are intentionally absent from this trajectory panel.</div><div class="sr-trace-legend">$(join(traced_labels))</div>$(chart(distance_lines,"component separation for stored sweep points", "well separated", "near 0"))</div>
        <div class="sr-panel"><strong>Final component separation  all solvers</strong><div class="sr-help">One endpoint diagnostic per solver. Near 0 means that the nearest returned pair is nearly indistinguishable.</div><div class="sr-bars">$(join(final_distance_bars))</div></div>
        <div class="sr-panel"><strong>Endpoint ALS update sensitivity  all solvers</strong><div class="sr-help">This evaluates how difficult an ALS-style allocation would be at each returned representation. For RCG and RGD it is not their internal linear system or an iteration history.</div><div class="sr-bars">$(join(final_condition_bars))</div></div>
        <div class="sr-boundary"><strong>Evidence boundary:</strong> block-solver curves use stored sweep points. RCG and RGD errors come from deterministic checkpoint reruns from the same start; they contribute endpoint separation and sensitivity only.</div>
      </div>
    </div>
    """)
end

function swamp_microscope_visual(trace; window::Integer = 20, progress_states = nothing)
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
    states = isnothing(progress_states) ? [
        index <= window ? :unavailable :
        improvements[index] < 0 ? :worsened :
        improvements[index] < 0.05 ? :plateau : :progress for index in eachindex(errors)
    ] : Symbol.(collect(progress_states))
    length(states) == length(errors) ||
        throw(ArgumentError("Progress-state history must match the error history."))
    detected = states .== :plateau
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
        #$root_id .sm-status.worsened { border-color:#a94d58;background:#f7e9eb; }
        @media(max-width:760px){#$root_id .sm-metrics{grid-template-columns:1fr 1fr}}
        @media(prefers-color-scheme:dark){#$root_id .sm-chart{background:#25281f;border-color:#555d45}#$root_id .sm-metric,#$root_id .sm-status{background:#303526}#$root_id .sm-status.detected{background:#3b2e28}}
      </style>
      <div class="sm-chart">
        <svg viewBox="0 0 $width $height" role="img" aria-label="ALS error trajectory with an iteration cursor and swamp-like region">
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
        <div class="sm-metric"><span>component separation</span><strong id="$root_id-distance"></strong></div>
        <div class="sm-metric"><span>ALS update sensitivity</span><strong id="$root_id-condition"></strong></div>
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
          const states = [$(join(["'$(state)'" for state in states],","))];
          const xs = [$(join(xs,","))]; const ys = [$(join(ys,","))];
          const slider = root.querySelector('#$root_id-slider');
          const format = value => value === null ? 'not available yet' : (Math.abs(value) >= 1e4 || (Math.abs(value) > 0 && Math.abs(value) < 1e-3) ? value.toExponential(2) : value.toPrecision(4));
          const update = () => {
            const index = Number(slider.value) - 1;
            root.querySelector('#$root_id-iteration').textContent = iterations[index];
            root.querySelector('#$root_id-error').textContent = format(errors[index]);
            root.querySelector('#$root_id-distance').textContent = format(distances[index]);
            root.querySelector('#$root_id-condition').textContent = conditions[index] < 3 ? 'low' : conditions[index] < 10 ? 'rising' : conditions[index] < 100 ? 'high' : 'very high';
            root.querySelector('#$root_id-improvement').textContent = format(improvements[index]);
            root.querySelector('#$root_id-cursor').setAttribute('x1', xs[index]); root.querySelector('#$root_id-cursor').setAttribute('x2', xs[index]);
            root.querySelector('#$root_id-marker').setAttribute('cx', xs[index]); root.querySelector('#$root_id-marker').setAttribute('cy', ys[index]);
            const status = root.querySelector('#$root_id-status');
            status.classList.toggle('detected', detected[index]);
            status.classList.toggle('worsened', states[index] === 'worsened');
            if (states[index] === 'plateau') {
              const collisionEvidence = distances[index] < 0.3 && conditions[index] > 100;
              status.innerHTML = collisionEvidence
                ? '<strong>Plateau observed.</strong> Low component separation and high update sensitivity support collision-induced ill-conditioning in this run.'
                : '<strong>Plateau observed.</strong> The error curve alone does not identify its cause; inspect separation, update sensitivity, initialization, rank, and model fit.';
            } else if (states[index] === 'worsened') {
              status.innerHTML = '<strong>Objective worsened.</strong> The error increased over this window, so this point is not labeled as a plateau.';
            } else if (states[index] === 'progress') {
              status.innerHTML = '<strong>Meaningful progress.</strong> The error fell by at least 0.05 log₁₀ units over this window.';
            } else {
              status.innerHTML = '<strong>Not enough history yet.</strong> Move beyond the first window to classify progress.';
            }
          };
          slider.addEventListener('input', update); update();
        })();
      </script>
    </div>
    """)
end

"""Show how a gauge transformation can destroy coordinates without moving X."""
