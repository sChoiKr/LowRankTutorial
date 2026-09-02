module BrowserPrint

export find_browser, print_html_pdf

function find_browser()
    candidates = filter(!isnothing, [
        Sys.which("chromium"),
        Sys.which("chromium-browser"),
        Sys.which("google-chrome"),
        Sys.which("google-chrome-stable"),
        Sys.which("microsoft-edge"),
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    ])
    found = findfirst(isfile, candidates)
    isnothing(found) ? nothing : candidates[found]
end

function print_html_pdf(
    browser::AbstractString,
    html_path::AbstractString,
    pdf_path::AbstractString;
    timeout_seconds::Real = 30,
    virtual_time_budget::Union{Nothing,Integer} = nothing,
)
    mkpath(dirname(pdf_path))
    mktempdir() do profile
        temporary_pdf = joinpath(profile, basename(pdf_path))
        file_url = "file://" * replace(abspath(html_path), " " => "%20")
        arguments = String[
            browser,
            "--headless=new",
            "--disable-gpu",
            "--disable-background-networking",
            "--disable-component-update",
            "--disable-default-apps",
            "--disable-sync",
            "--no-first-run",
            "--no-default-browser-check",
            "--no-pdf-header-footer",
            "--user-data-dir=$profile",
            "--print-to-pdf=$(abspath(temporary_pdf))",
        ]
        if !isnothing(virtual_time_budget)
            push!(arguments, "--run-all-compositor-stages-before-draw")
            push!(arguments, "--virtual-time-budget=$virtual_time_budget")
        end
        push!(arguments, file_url)

        process = run(Cmd(arguments); wait = false)
        deadline = time() + timeout_seconds
        previous_size = -1
        stable_ticks = 0
        while process_running(process) && time() < deadline
            current_size = isfile(temporary_pdf) ? filesize(temporary_pdf) : -1
            stable_ticks = current_size > 0 && current_size == previous_size ? stable_ticks + 1 : 0
            stable_ticks >= 5 && break
            previous_size = current_size
            sleep(0.2)
        end
        process_running(process) && kill(process)
        try
            wait(process)
        catch error
            isfile(temporary_pdf) || rethrow(error)
        end
        isfile(temporary_pdf) && filesize(temporary_pdf) > 0 ||
            error("Browser did not create $pdf_path")
        mv(temporary_pdf, pdf_path; force = true)
    end
    pdf_path
end

end
