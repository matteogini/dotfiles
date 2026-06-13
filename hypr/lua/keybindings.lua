local p = require("lua.programs")
local mainMod = "SUPER"

-- Basic binds
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(p.terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + Space", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 800, y = 600, relative = false }))
    hl.dispatch(hl.dsp.window.center())
end)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(p.fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("quickshell ipc call qsIpc toggleClipboard"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("quickshell ipc call qsIpc toggleControlCenter"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(p.menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(p.browser))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(p.note))
hl.bind("F6", hl.dsp.exec_cmd(p.screenshot))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(p.powermenu))
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd(p.lock))
hl.bind(mainMod .. " + SHIFT + F12", hl.dsp.exec_cmd("brightnessctl s 0"))
hl.bind("XF86Launch1", hl.dsp.exec_cmd(p.rog))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("quickshell ipc call qsIpc toggleThemeSwitcher"))
hl.bind("mouse:277", hl.dsp.window.close())
local battery_mode = false
hl.bind(mainMod .. " + B", function()
    battery_mode = not battery_mode
    if battery_mode then
        -- Power saving mode
        hl.config({
            animations = { enabled = false },
            decoration = {
                rounding = 0,
                shadow = { enabled = false },
                blur = { enabled = false }
            }
        })
    else
        -- High performance mode (restoring from theme)
        local theme = require("theme")
        hl.config({
            animations = { enabled = true },
            decoration = {
                rounding = theme.rounding,
                shadow = { enabled = theme.shadow_enabled },
                blur = { enabled = theme.blur_enabled }
            }
        })
    end
    hl.exec_cmd("/home/matteo/.local/bin/battery_mode.sh")
end)

-- Workspace Packing (SUPER+A)
hl.bind(mainMod .. " + A", function()
    local workspaces = hl.get_workspaces()
    local windows = hl.get_windows()
    local active_ws = hl.get_active_workspace()
    if not workspaces or not windows or not active_ws then return end
    local active_ids = {}
    for _, ws in pairs(workspaces) do
        if ws.id and ws.id > 0 and ws.windows and ws.windows > 0 then
            table.insert(active_ids, ws.id)
        end
    end
    table.sort(active_ids)
    local target = 1
    local curr_ws_id = active_ws.id
    local new_active_ws_id = curr_ws_id
    for _, ws_id in ipairs(active_ids) do
        if ws_id ~= target then
            for _, win in pairs(windows) do
                if win.workspace and win.workspace.id == ws_id then
                    hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false, window = win }))
                end
            end
            if ws_id == curr_ws_id then new_active_ws_id = target end
        end
        target = target + 1
    end
    hl.dispatch(hl.dsp.focus({ workspace = new_active_ws_id }))
end)

-- Movement
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Resize
hl.bind("ALT + right", hl.dsp.window.resize({ x = 30,  y = 0,  relative = true }), { repeating = true })
hl.bind("ALT + left",  hl.dsp.window.resize({ x = -30, y = 0,  relative = true }), { repeating = true })
hl.bind("ALT + up",    hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
hl.bind("ALT + down",  hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })

-- Workspaces
hl.bind(mainMod .. " + Space", hl.dsp.focus({ workspace = "empty" }))
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+ && quickshell ipc call qsIpc showOsd V $(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[0-9.]*' | awk '{print $1 * 100}')"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%- && quickshell ipc call qsIpc showOsd V $(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[0-9.]*' | awk '{print $1 * 100}')"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && quickshell ipc call qsIpc showOsd V $(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q 'MUTED' && echo 0 || wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o '[0-9.]*' | awk '{print $1 * 100}')"), { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl s 5%+ | grep -oP '\\(\\K[^%]+' | xargs -I {} quickshell ipc call qsIpc showOsd B {}"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl s 5%- | grep -oP '\\(\\K[^%]+' | xargs -I {} quickshell ipc call qsIpc showOsd B {}"), { locked = true, repeating = true })
hl.bind(mainMod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind(mainMod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind(mainMod .. " + XF86AudioMicMute", hl.dsp.exec_cmd("/home/matteo/.local/bin/spotify_restart.sh"),   { locked = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Switch
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprlock"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprlock"), { locked = true })
