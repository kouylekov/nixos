-- Hyprland Configuration (Lua)
-- Modern setup with Bulgarian keyboard support.
-- Migrated from hyprlang in 2026-05 for Hyprland 0.55+.
-- Host-specific monitor/input variants live alongside this file and are
-- selected by /etc/hostname (see the dispatch block below).

----------------
--- MONITORS ---
----------------

-- Host-specific monitor & input files: monitors-<hostname>.lua, input-<hostname>.lua.
-- Add a new host by creating those two files and setting networking.hostName.
local function hostname()
    local f = io.open("/etc/hostname")
    if not f then return "desktop" end
    local name = f:read("*l") or "desktop"
    f:close()
    return name:gsub("%s+$", "")
end
local host = hostname()

require("monitors-" .. host)

---------------------
--- MY PROGRAMS  ---
---------------------

local terminal    = "alacritty"
local fileManager = "nautilus"
local browser     = "firefox"

-- Noctalia is the desktop shell: bar, launcher, notifications, clipboard
-- history, control center, OSDs, screenshots, idle handling and the lock
-- screen. It replaced waybar, mako, hypridle, nm-applet and cliphist.
-- Everything below drives it over IPC; see `noctalia msg --help`.
local ipc = "noctalia msg "

-----------------
--- AUTOSTART ---
-----------------

hl.on("hyprland.start", function()
    -- Noctalia reads workspaces, the active window and the keyboard layout
    -- over Hyprland's IPC socket; if the socket isn't ready when it starts
    -- those views come up empty. Poll hyprctl until it answers, then launch.
    local wait_for_ipc = "until hyprctl monitors >/dev/null 2>&1; do sleep 0.1; done"
    hl.exec_cmd("sh -c '" .. wait_for_ipc .. "; exec noctalia'")
    hl.exec_cmd("sh -c '" .. wait_for_ipc .. "; exec gnome-keyring-daemon --start --components=secrets'")
end)

-----------------------------
--- ENVIRONMENT VARIABLES ---
-----------------------------

hl.env("PROTON_PASS_KEY_PROVIDER", "fs")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

---------------------
--- LOOK AND FEEL ---
---------------------

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(e0e0e0ee)", "rgba(c0c0c0ee)" }, angle = 45 },
            inactive_border = "rgba(404040aa)",
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 12,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = false },
        blur   = { enabled = false },
    },

    animations = { enabled = false },

    dwindle = {
        preserve_split = true,
        smart_split    = true,
    },

    master = {
        new_status = "master",
    },
})

-------------
--- INPUT ---
-------------

require("input-" .. host)

-------------------
--- KEYBINDINGS ---
-------------------

local mainMod = "SUPER"

-- Core
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exit())
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T",      hl.dsp.layout("togglesplit"))

-- Lock screen
hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd(ipc .. "session lock"))

-- Noctalia panels
hl.bind(mainMod .. " + A",     hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. " + W",     hl.dsp.exec_cmd(ipc .. "panel-toggle wallpaper"))
hl.bind(mainMod .. " + X",     hl.dsp.exec_cmd(ipc .. "panel-toggle session"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("ALT + Tab",           hl.dsp.exec_cmd(ipc .. "window-switcher hold"))

-- Pass Manager (its own fuzzel --dmenu picker, not the noctalia launcher)
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("/home/milen/projects/pass-cli-dmenu/pass-cli-dmenu"))

-- Clipboard history
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(ipc .. "panel-toggle clipboard"))

-- Screenshots. Both land in noctalia's annotation editor, where Ctrl+C copies
-- and Ctrl+S saves — that covers what the four grim binds used to do.
hl.bind("Print",         hl.dsp.exec_cmd(ipc .. "screenshot-region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"))

-- Move focus (arrows + vim keys)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L",     hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",     hl.dsp.focus({ direction = "down" }))

-- Move windows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + H",     hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L",     hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K",     hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J",     hl.dsp.window.move({ direction = "down" }))

-- Resize windows
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x =  20, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x =   0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x =   0, y =  20, relative = true }), { repeating = true })

-- Workspaces 1-10
for i = 1, 10 do
    local key = i % 10  -- 10 -> 0
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + Tab",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Mumble push-to-talk on Mouse5
hl.bind("mouse:275", hl.dsp.global("info.mumble.Mumble:push_to_talk"), { mouse = true })

-- Media keys. Routed through noctalia rather than wpctl/brightnessctl/playerctl
-- so each keypress also draws the matching OSD overlay.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(ipc .. "volume-up"),        { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(ipc .. "volume-down"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(ipc .. "volume-mute"),      { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(ipc .. "mic-mute"),         { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(ipc .. "brightness-up"),    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"),  { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(ipc .. "media next"),     { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(ipc .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(ipc .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(ipc .. "media previous"), { locked = true })

--------------------
--- WINDOW RULES ---
--------------------

-- Noctalia's Settings window is a regular xdg-toplevel; float it instead of
-- letting dwindle tile it.
hl.window_rule({
    name  = "float-noctalia-settings",
    match = { class = "^dev\\.noctalia\\.Noctalia$" },
    float = true,
})
