---
name: project-waybar-workspace-clicks
description: Waybar workspace clicks are broken under Hyprland 0.55 Lua config; user has chosen to leave it and wait for upstream fix
metadata: 
  node_type: memory
  type: project
  originSessionId: c92b22fb-56c7-4da3-85ac-1f1fd71939e5
---

Waybar's `hyprland/workspaces` module clicks do not switch workspaces under Hyprland 0.55 + the Lua config migration. User has chosen NOT to work around this — relies on Super+1..9 keybinds (which work fine via `hl.dsp.focus`).

**Why:** Hyprland 0.55 IPC `dispatch <arg>` now Lua-evaluates `<arg>` (wraps as `return hl.dispatch(<arg>)`). Waybar's `Workspace::handleClicked` is hardcoded to `IPC::dispatch("workspace", "N")` — the user's `on-click: "activate"` setting is ignored for the actual switch. The legacy `workspace N` syntax is not valid Lua, so Hyprland errors. No compat flag exists; no Lua API to register a `workspace` dispatcher; IPC has no raw-mode bypass. Upstream Waybar issue #5008 is open with no PR as of 2026-05.

**How to apply:** If the user reports workspace clicks broken again, don't re-investigate — point them at this memory. Revisit only when Waybar #5008 lands or user asks to implement a workaround (the options were: custom per-workspace modules, custom modules + state script, or a local waybar patch in nixpkgs overlay). Same root cause as commit 4ffa974 (logout fix that switched to `hl.dsp.exit()`).
