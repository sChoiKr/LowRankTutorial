module ManualExecution

export manual_checkbox,
       manual_choice,
       manual_choice_run_control,
       manual_parameter_run_control,
       manual_parameter_run_requested,
       manual_parameter_value,
       manual_run_button,
       manual_run_requested,
       manual_slider,
       manual_value,
       manual_waiting

const CONTROL_COUNTER = Ref(0)

function next_control_id(prefix::AbstractString)
    CONTROL_COUNTER[] += 1
    return "$(prefix)-$(CONTROL_COUNTER[])"
end

"""A bonded preset selector that recomputes only when its Run button is pressed."""
function manual_choice_run_control(
    label::AbstractString,
    options::Pair...;
    default::Integer = 1,
    run_label::AbstractString = "Run experiment",
)
    isempty(options) && throw(ArgumentError("Provide at least one labelled choice."))
    1 <= default <= length(options) || throw(ArgumentError("default is out of range."))
    id = next_control_id("tk-choice-run")
    buttons = String[]
    for (index, option) in enumerate(options)
        option_label, option_value = option
        checked = index == default ? "checked" : ""
        push!(buttons, """
        <label style="display:flex;align-items:center;gap:.45rem;padding:.5rem .7rem;border:1px solid #c6cbb3;border-radius:999px;cursor:pointer;background:#fffdf7">
          <input type="radio" name="$id-option" value="$(escape_html(string(option_value)))" $checked style="accent-color:#657047">
          <span>$(escape_html(string(option_label)))</span>
        </label>
        """)
    end
    default_value = escape_html(string(last(options[default])))
    return Base.HTML("""
    <div id="$id" style="display:block;border:1px solid #a8af8e;border-radius:12px;background:#fbfaf4;color:#303628;padding:.85rem 1rem;font:15px/1.35 system-ui">
      <strong style="display:block;margin-bottom:.6rem">$(escape_html(label))</strong>
      <div style="display:flex;gap:.55rem;flex-wrap:wrap">$(join(buttons))</div>
      <button type="button" style="margin-top:.75rem;border:1px solid #5e6740;border-radius:999px;background:#5e6740;color:white;padding:.55rem 1rem;font:600 15px system-ui;cursor:pointer">$(escape_html(run_label))</button>
      <script>
        (() => {
          const root = document.getElementById('$id');
          const button = root.querySelector('button');
          let runs = 0;
          button.addEventListener('click', () => {
            runs += 1;
            const selected = root.querySelector('input:checked');
            root.value = (selected ? selected.value : '$default_value') + '|' + runs;
            button.textContent = '↻ Run again';
            root.dispatchEvent(new CustomEvent('input', {bubbles: true}));
          });
          root.value = '$default_value|0';
        })();
      </script>
    </div>
    """)
end

"""A compact bonded choice control for a small set of pedagogical presets."""
function manual_choice(
    label::AbstractString,
    options::Pair...;
    default::Integer = 1,
)
    isempty(options) && throw(ArgumentError("Provide at least one labelled choice."))
    1 <= default <= length(options) || throw(ArgumentError("default is out of range."))
    id = next_control_id("tk-choice")
    safe_label = escape_html(label)
    buttons = String[]
    for (index, option) in enumerate(options)
        option_label, option_value = option
        checked = index == default ? "checked" : ""
        push!(buttons, """
        <label style="display:flex;align-items:center;gap:.45rem;padding:.5rem .7rem;border:1px solid #c6cbb3;border-radius:999px;cursor:pointer;background:#fffdf7">
          <input type="radio" name="$id-option" value="$(escape_html(string(option_value)))" $checked style="accent-color:#657047">
          <span>$(escape_html(string(option_label)))</span>
        </label>
        """)
    end
    default_value = escape_html(string(last(options[default])))
    return Base.HTML("""
    <div id="$id" style="display:block;border:1px solid #a8af8e;border-radius:12px;background:#fbfaf4;color:#303628;padding:.8rem 1rem;font:15px/1.35 system-ui">
      <strong style="display:block;margin-bottom:.6rem">$safe_label</strong>
      <div style="display:flex;gap:.55rem;flex-wrap:wrap">$(join(buttons))</div>
      <script>
        (() => {
          const root = document.getElementById('$id');
          const update = (event) => {
            if (event) event.stopPropagation();
            const selected = root.querySelector('input:checked');
            root.value = selected ? selected.value : '$default_value';
            root.dispatchEvent(new CustomEvent('input', {bubbles: true}));
          };
          root.querySelectorAll('input').forEach(input => input.addEventListener('change', update));
          root.value = '$default_value';
        })();
      </script>
    </div>
    """)
end

escape_html(text::AbstractString) = replace(
    text,
    '&' => "&amp;",
    '<' => "&lt;",
    '>' => "&gt;",
    '"' => "&quot;",
)

function manual_run_button(label::AbstractString)
    safe_label = escape_html(label)
    Base.HTML("""
    <button
      type="button"
      value="0"
      style="border:1px solid #5e6740;border-radius:999px;background:#5e6740;color:white;padding:.55rem 1rem;font:600 15px system-ui;cursor:pointer"
      onclick="this.value=String(Number(this.value)+1);this.textContent='↻ Run again';this.dispatchEvent(new CustomEvent('input',{bubbles:true}))"
    >$safe_label</button>
    """)
end

"""A lightweight reactive slider that works as a Pluto bond without PlutoUI."""
function manual_slider(
    label::AbstractString;
    minimum::Real,
    maximum::Real,
    step::Real,
    default::Real,
    value_prefix::AbstractString = "",
    value_suffix::AbstractString = "",
)
    id = next_control_id("tk-slider")
    safe_label = escape_html(label)
    safe_prefix = escape_html(value_prefix)
    safe_suffix = escape_html(value_suffix)
    return Base.HTML("""
    <div id="$id" style="display:block;border:1px solid #a8af8e;border-radius:12px;background:#fbfaf4;color:#303628;padding:.8rem 1rem;font:15px/1.35 system-ui">
      <label for="$id-input" style="display:flex;justify-content:space-between;gap:1rem;align-items:baseline;margin-bottom:.45rem">
        <strong>$safe_label</strong>
        <span style="font-variant-numeric:tabular-nums"><span>$safe_prefix</span><b id="$id-value">$default</b><span>$safe_suffix</span></span>
      </label>
      <input id="$id-input" type="range" min="$minimum" max="$maximum" step="$step" value="$default" style="width:100%;accent-color:#657047">
      <script>
        (() => {
          const root = document.getElementById('$id');
          const input = root.querySelector('input');
          const value = root.querySelector('#$id-value');
          const update = (event) => {
            if (event) event.stopPropagation();
            root.value = input.value;
            value.textContent = input.value;
            root.dispatchEvent(new CustomEvent('input', {bubbles: true}));
          };
          input.addEventListener('input', update);
          root.value = input.value;
        })();
      </script>
    </div>
    """)
end

"""A reactive checkbox bond with a visible descriptive label."""
function manual_checkbox(label::AbstractString; default::Bool = false)
    id = next_control_id("tk-checkbox")
    safe_label = escape_html(label)
    checked = default ? "checked" : ""
    return Base.HTML("""
    <div id="$id" style="display:block;border:1px solid #a8af8e;border-radius:12px;background:#fbfaf4;color:#303628;padding:.72rem 1rem;font:15px/1.35 system-ui">
      <label for="$id-input" style="display:flex;gap:.65rem;align-items:center;cursor:pointer">
        <input id="$id-input" type="checkbox" $checked style="width:1.05rem;height:1.05rem;accent-color:#657047">
        <strong>$safe_label</strong>
      </label>
      <script>
        (() => {
          const root = document.getElementById('$id');
          const input = root.querySelector('input');
          const update = (event) => {
            if (event) event.stopPropagation();
            root.value = input.checked ? 'true' : 'false';
            root.dispatchEvent(new CustomEvent('input', {bubbles: true}));
          };
          input.addEventListener('change', update);
          root.value = input.checked ? 'true' : 'false';
        })();
      </script>
    </div>
    """)
end

"""
    manual_parameter_run_control(label; ...)

Let the learner adjust a parameter locally, but update the Pluto bond only when
the run button is pressed. The bound value has the form `"value|run_count"`.
"""
function manual_parameter_run_control(
    label::AbstractString;
    minimum::Real,
    maximum::Real,
    step::Real,
    default::Real,
    run_label::AbstractString = "▶ Run",
    value_prefix::AbstractString = "",
    value_suffix::AbstractString = "",
)
    id = next_control_id("tk-parameter-run")
    safe_label = escape_html(label)
    safe_run_label = escape_html(run_label)
    safe_prefix = escape_html(value_prefix)
    safe_suffix = escape_html(value_suffix)
    return Base.HTML("""
    <div id="$id" style="display:block;border:1px solid #a8af8e;border-radius:12px;background:#fbfaf4;color:#303628;padding:.9rem 1rem;font:15px/1.35 system-ui">
      <label for="$id-input" style="display:flex;justify-content:space-between;gap:1rem;align-items:baseline;margin-bottom:.45rem">
        <strong>$safe_label</strong>
        <span style="font-variant-numeric:tabular-nums"><span>$safe_prefix</span><b id="$id-value">$default</b><span>$safe_suffix</span></span>
      </label>
      <input id="$id-input" type="range" min="$minimum" max="$maximum" step="$step" value="$default" style="width:100%;accent-color:#657047">
      <div style="display:flex;justify-content:space-between;align-items:center;gap:1rem;margin-top:.7rem;flex-wrap:wrap">
        <span id="$id-ratio" style="color:#626954;font-size:.9rem"></span>
        <button id="$id-button" type="button" style="border:1px solid #5e6740;border-radius:999px;background:#5e6740;color:white;padding:.55rem 1rem;font:600 15px system-ui;cursor:pointer">$safe_run_label</button>
      </div>
      <script>
        (() => {
          const root = document.getElementById('$id');
          const input = root.querySelector('input');
          const value = root.querySelector('#$id-value');
          const ratio = root.querySelector('#$id-ratio');
          const button = root.querySelector('button');
          let runs = 0;
          const preview = (event) => {
            if (event) event.stopPropagation();
            value.textContent = input.value;
            ratio.textContent = 'largest component = ' + Math.pow(10, Number(input.value)).toLocaleString(undefined, {maximumFractionDigits: 1}) + '× smallest';
          };
          input.addEventListener('input', preview);
          button.addEventListener('click', () => {
            runs += 1;
            root.value = input.value + '|' + runs;
            button.textContent = '↻ Run again';
            root.dispatchEvent(new CustomEvent('input', {bubbles: true}));
          });
          root.value = input.value + '|0';
          preview();
        })();
      </script>
    </div>
    """)
end

function manual_run_requested(value)
    value === missing && return false
    try
        parse(Int, string(value)) > 0
    catch
        false
    end
end

function manual_value(value, default::Real)
    value === missing && return Float64(default)
    try
        return parse(Float64, string(value))
    catch
        return Float64(default)
    end
end

function manual_value(value, default::Bool)
    value === missing && return default
    lowercase(string(value)) == "true"
end

function manual_parameter_run_requested(value)
    value === missing && return false
    parts = split(string(value), '|'; limit = 2)
    length(parts) == 2 || return false
    try
        parse(Int, parts[2]) > 0
    catch
        false
    end
end

function manual_parameter_value(value, default::Real)
    value === missing && return Float64(default)
    parameter = first(split(string(value), '|'; limit = 2))
    try
        parse(Float64, parameter)
    catch
        Float64(default)
    end
end

manual_waiting(label::AbstractString) = Base.HTML("""
<div style="border:1px dashed #a8af8e;border-radius:10px;background:#f7f4e8;color:#59623d;padding:.8rem 1rem;font:15px/1.45 system-ui">
  <b>Waiting.</b><br>$label
</div>
""")

end
