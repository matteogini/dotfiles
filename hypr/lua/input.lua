hl.config({
    input = {
        kb_layout  = "it",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "move" })
hl.gesture({ fingers = 3, direction = "up", action = "close" })
hl.gesture({
    fingers = 3,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
        hl.dispatch(hl.dsp.window.resize({ x = 850, y = 650, relative = false }))
        hl.dispatch(hl.dsp.window.center())
    end
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
