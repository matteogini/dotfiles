local animations = {}

function animations.apply()
    -- Beziers
    hl.curve("easeOutQuint", { type = "bezier", points = { {0.83, 0}, {0.17, 1} } })
    hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

    -- Base Animations
    hl.animation({ leaf = "windows",    enabled = true, speed = 10, bezier = "default", style = "slide bottom" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 10, bezier = "default", style = "slide top" })

    -- Functional Enhancements
    hl.animation({ leaf = "fade",             enabled = true, speed = 5, bezier = "default" })
    hl.animation({ leaf = "layers",           enabled = true, speed = 4, bezier = "default", style = "fade" })
    hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "myBezier", style = "slidevert" })
end

return animations
