# Terminal Cascade Feature Plan & Deep Research

## Objective
When opening a new `foot` terminal, if there is already an existing `foot` terminal on the workspace, the old terminal(s) should be moved slightly up (and perhaps slightly right) and reduced in size. This will create a visible "cascading" or "stacked" effect instead of the terminals completely overlapping due to the default center window rule.

## Context
Currently, `hypr/lua/windowrules.lua` forces `foot` windows to float, have a size of `850 650`, and be centered:
```lua
hl.window_rule({
    name  = "foot",
    match = { class = "^(foot|footclient)$" },
    float = true,
    size  = "850 650",
    center = true,
})
```

Because static window rules in Hyprland apply only when a window is *mapped* (created), we cannot use them to modify *already existing* windows when a new one opens. We need a dynamic approach. After researching the capabilities of your Lua API (`hl`), here is the breakdown of the best implementation options.

---

## 1. Native Lua Event Listener (`hl.on`) - 🏆 The Best Option
Your configuration already makes heavy use of the native Lua API (`hl.bind`, `hl.on("hyprland.start")`, etc.). Hyprland's Lua API supports listening to window manager events natively.

**How it works:**
```lua
hl.on("openwindow", function(win)
    if win.class == "foot" or win.class == "footclient" then
        local windows = hl.get_windows()
        local active_ws = hl.get_active_workspace()
        for _, w in pairs(windows) do
            -- Find other foot windows on the same workspace, excluding the new one
            if (w.class == "foot" or w.class == "footclient") and w.workspace.id == active_ws.id and w.address ~= win.address then
                -- Cascade them up and left/right
                hl.dispatch(hl.dsp.window.resizewindowpixel("-20 -20,address:" .. w.address))
                hl.dispatch(hl.dsp.window.movewindowpixel("10 -20,address:" .. w.address))
            end
        end
    end
end)
```

**Why it's the best:**
- **Zero Overhead:** No external bash scripts or daemons running in the background. It uses Hyprland's native event loop.
- **Universal Capture:** It catches *every* `foot` terminal you open, whether it's through your `SUPER + Q` keybind or through an application launcher like `fuzzel`/`rofi`.
- **Consistency:** It keeps your configuration strictly inside Lua, matching the rest of your beautiful rice.

---

## 2. Bash Launcher Wrapper - 🥈 The Safest Fallback
This approach changes your `SUPER + Q` bind to run a script (`smart_foot.sh`) that cascades existing terminals via `hyprctl` and then launches `foot`.

**How it works:**
1. **Create `~/.local/bin/smart_foot.sh`**: Uses `hyprctl clients -j` and `jq` to find addresses of floating `foot` windows on the current workspace. Loops through them and dispatches `resizewindowpixel` and `movewindowpixel`. Then launches `foot`.
2. **Update Keybindings**: Change `hl.bind(mainMod .. " + Q", ...)` to execute the script.

**Why it's good:**
- **Guaranteed to work:** Relies strictly on standard `hyprctl` IPC commands.

**Why it's NOT the best:**
- **Incomplete:** If you launch `foot` from anywhere other than the keybind (like an app menu), the cascade won't happen.
- **Slight Delay:** Invoking `hyprctl` multiple times via bash is marginally slower than native Lua IPC.

---

## 3. Background IPC Daemon (`socat`) - 🥉 The Legacy Option
This involves a background script listening to the Hyprland UNIX socket (`.socket2.sock`) for the `openwindow>>` string.

**Why it's NOT the best:**
- **Messy:** It requires a perpetual background script parsing string streams, which is resource-inefficient and prone to breaking if Hyprland changes its socket output format.

---

## Final Implementation & Discoveries

We implemented the **Native Lua Event Listener (Option 1)** in `hypr/lua/windowrules.lua`. During implementation and testing, we uncovered several complex behaviors in `hyprland-lua` and Hyprland's physics engine that required advanced workarounds:

1. **The `window.open` Event Target:** Instead of guessing which window triggered the event via focus timers, we discovered the event natively passes the `win` object as an argument.
2. **The "Un-Float" Bug:** Calling `hl.dsp.window.resize` on a background window stripped its floating status, causing it to tile and maximize (`1440x868`). We resolved this by chaining `hl.dsp.window.float({ action = "on" })` right before the resize.
3. **Natural Horizontal Centering:** We found that Hyprland automatically shrinks floating windows inward from both the left and right simultaneously. By omitting the `X` movement and only shifting `Y` upwards (`y = -20`), the cascaded stack naturally maintains a perfect horizontal center.
4. **Guarding Off-Center and Fullscreen Terminals:** We explicitly restricted the cascade to windows that share the exact horizontal center as the newly spawned window (`math.abs(win_center_x - w_center_x) <= 2`). Furthermore, to protect maximized or fullscreen windows, we ensured that the background window width must not exceed the standard floating width (`w.size.x <= 860`).

### Final Code Snippet

```lua
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
```
This solution is robust, entirely native to Lua, and fully accounts for edge cases.
