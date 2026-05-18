-- Mirrored mode for presentations — any external monitor mirrors the built-in display.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.25 })
hl.monitor({ output = "",      mode = "preferred", position = "auto", scale = 1, mirror_of = "eDP-1" })
