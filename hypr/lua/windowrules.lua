hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name  = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})

hl.window_rule({
    name  = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

hl.window_rule({
    name  = "blueberry",
    match = { class = "blueberry.py" },
    float = true,
    size  = "400 500",
    move  = "(monitor_w-410) 35",
})

hl.window_rule({
    name  = "calculator",
    match = { class = "org.gnome.Calculator" },
    float = true,
    size  = "400 500",
    move  = "(monitor_w-410) 95",
})

hl.window_rule({
    name  = "file-dialogs",
    match = { title = "^(Apri file|Open File|Salva come|Save As|Sfoglia|Library)$" },
    float = true,
    size  = "800 500",
    center = true,
})

hl.window_rule({
    name  = "portal-gtk",
    match = { class = "xdg-desktop-portal-gtk" },
    float = true,
    size  = "900 600",
    center = true,
})

hl.window_rule({
    name  = "spotify",
    match = { class = "^(Spotify|spotify)$" },
    float = true,
    size  = "800 600",
    center = true,
    workspace = "special:magic silent",
})

hl.window_rule({
    name  = "foot",
    match = { class = "^(foot|footclient)$" },
    float = true,
    size  = "850 650",
    center = true,
})

-- Terminal Cascade Feature
hl.on("window.open", function(win)
    local win_addr = win.address
    hl.timer(function()
        local active_ws = hl.get_active_workspace()
        if not active_ws then return end

        local is_foot = false
        for _, w in pairs(hl.get_windows()) do
            if w.address == win_addr then
                if w.class == "foot" or w.class == "footclient" then
                    is_foot = true
                end
                break
            end
        end

        if not is_foot then return end

        for _, w in pairs(hl.get_windows()) do
            if (w.class == "foot" or w.class == "footclient") and w.workspace.id == active_ws.id and w.address ~= win_addr and w.size.x <= 860 then
                -- Check if the background window is part of the center stack
                -- The new window (win) spawns exactly at the center. We compare horizontal centers.
                local win_center_x = win.at.x + (win.size.x / 2)
                local w_center_x = w.at.x + (w.size.x / 2)
                
                if math.abs(win_center_x - w_center_x) <= 2 then
                    hl.dispatch(hl.dsp.window.float({ action = "on", window = w }))
                    hl.dispatch(hl.dsp.window.resize({ x = -20, y = -20, relative = true, window = w }))
                    hl.dispatch(hl.dsp.window.move({ x = 0, y = -20, relative = true, window = w }))
                end
            end
        end
    end, { timeout = 100, type = "oneshot" })
end)
