-- Laptop monitor configuration
-- USB-C (DP-3): side-by-side — external on left, laptop on right
-- HDMI and other ports: mirror mode

-- Built-in display
hl.monitor({ output = "eDP-1", mode = "preferred", position = "2560x0", scale = 1 })

-- USB-C connection (DP-3): extended desktop mode
hl.monitor({ output = "DP-3",  mode = "preferred", position = "0x0", scale = 1 })

-- HDMI connections: mirror mode
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })
hl.monitor({ output = "HDMI-A-2", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })

-- Other DisplayPort connections: mirror mode
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })
hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })
