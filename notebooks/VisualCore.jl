# Shared rendering helpers used by multiple numbered labs.

const VISUAL_COUNTER = Ref(0)

function next_id(prefix)
    VISUAL_COUNTER[] += 1
    return "$(prefix)-$(VISUAL_COUNTER[])"
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

function heatmap_svg(
    A::AbstractMatrix; 
    width = 210, 
    height = 155, 
    scale = nothing,
    cell_border = "rgba(255,255,255,0.82)",
    cell_border_width = 1.0,
    outer_border = "rgba(94,103,64,0.55)",
    outer_border_width = 1.0,
    outer_radius = 8,
)
    rows, cols = size(A)
    chosen_scale = 
        isnothing(scale) ? maximum(abs, A; init = 0.0) : scale
    
    cell_width = width / cols
    cell_height = height / rows
    
    #Unique ID is required because several SVG heatmaps may appear
    #simultaneously in one Pluto notebook.
    clip_id = next_id("heatmap-clip")

    cells = String[]

    for row in 1:rows, col in 1:cols
        value = A[row, col]

        x = (col-1) * cell_width
        y = (row-1) * cell_height

        push!(
            cells,
            """
            <rect
                x="$x"
                y="$y"
                width="$cell_width"
                height="$cell_height"
                fill="$(heat_color(value, chosen_scale))"
                stroke="$cell_border"
                stroke-width="$cell_border_width"
                vector-effect="non-scaling-stroke"
            >
                <title>
                    row $row, column $col: $(number_label(value))
                </title>
            </rect>
            """,
        )
    end

    return """
    <svg
        viewBox="0 0 $width $height"
        width="$width"
        height="$height"
        role="img"
        aria-label="Matrix heatmap"
        style="
            display:block;
            max-width:100%;
            height:auto;
            overflow:visible;
        "
    >
        <defs>
            <clipPath id="$clip_id">
                <rect
                    x="0"
                    y="0"
                    width="$width"
                    height="$height"
                    rx="$outer_radius"
                    ry="$outer_radius"
                />
            </clipPath>
        </defs>

        <!-- Individual tensor entries -->
        <g clip-path="url(#$clip_id)">
            $(join(cells))
        </g>

        <!-- Rounded boundary of the complete matrix slice -->
        <rect
            x="$(outer_border_width / 2)"
            y="$(outer_border_width / 2)"
            width="$(width - outer_border_width)"
            height="$(height - outer_border_width)"
            rx="$outer_radius"
            ry="$outer_radius"
            fill="none"
            stroke="$outer_border"
            stroke-width="$outer_border_width"
            vector-effect="non-scaling-stroke"
            pointer-events="none"
        />
    </svg>
    """
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

      #$root_id .nv-grid { display: flex; flex-wrap: wrap; align-items: flex-start; gap: 1rem; }
      #$root_id .nv-panel { min-width: 0; width: fit-content; max-width: 100%; }
      #$root_id .nv-title { font-weight: 600; margin-bottom: .35rem; }
      #$root_id .nv-subtitle { color: #666; font-size: .78rem; margin-top: .35rem; font-variant-numeric: tabular-nums; }
      #$root_id .nv-metrics { display: flex; gap: 1.25rem; flex-wrap: wrap; margin-top: .75rem; font-variant-numeric: tabular-nums; }
      #$root_id .nv-axis { stroke: #9ca3af; stroke-width: 1; }
      #$root_id .nv-gridline { stroke: #d1d5db; stroke-width: 1; }
      #$root_id .nv-label { fill: currentColor; font-size: 11px; }
      #$root_id .nv-muted { fill: #6b7280; font-size: 10px; }
      #$root_id .nv-frame[hidden] { display: none; }
      #$root_id .nv-frame { width: fit-content; max-width: 100%; }
      #$root_id .nv-frame svg { display: block; }
      @media (prefers-color-scheme: dark) {
        #$root_id .nv-subtitle { color: #bbb; }
        #$root_id .nv-gridline, #$root_id .nv-axis { stroke: #555; }
        #$root_id .nv-muted { fill: #bbb; }
        #$root_id .nv-play { border-color: #93c5fd; }
      }
    </style>
    """
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

function tensor_slices_visual(
    pairs::Pair...;
    title = "Inspect tensor slices",
    shared_scale = false,
    reveal = true,
    heatmap_width = 210,
    heatmap_height = 155,
    cell_border_width = 1.0,
    outer_radius = 8,
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
            """
            <div
                class="nv-frame"
                data-slice="$slice"
                $(slice == 1 ? "" : "hidden")
            >
                $(
                    heatmap_svg(
                        tensor[:, :, slice];
                        scale = scale,
                        width = heatmap_width,
                        height = heatmap_height,
                        cell_border_width = cell_border_width,
                        outer_radius = outer_radius,
                    )
                )
            </div>
            """            
            for slice in 1:slice_count
        ]
        push!(panels, 
        """
        <div class=\"nv-panel\">
          <div class=\"nv-title\">
            $(escape_html(label))
          </div>
          $(join(frames))
          <div class=\"nv-subtitle\">
            blue = positive, red = negative, intensity = magnitude
            <br>
            color range ±$(number_label(scale))
          </div>
        </div>
        """,
        )
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
