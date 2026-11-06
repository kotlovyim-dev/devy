-- Keybindings. SUPER is the main modifier. Full list: docs/KEYBINDS.md
-- Apps are started through `uwsm app --` so each one runs in its own systemd unit:
-- a crashing or memory-hungry app can be killed alone without taking the session down.

local mod = "SUPER"
local app = "uwsm app -- "

local terminal = app .. "ghostty"
local launcher = "fuzzel" -- fuzzel launches the chosen app itself (launch-prefix in fuzzel.ini)
local files = app .. "nautilus --new-window"
local browser = app .. "chromium"
local editor = app .. "code"

local function bind(keys, dispatcher, flags)
  hl.bind(keys, dispatcher, flags)
end
local function exec(keys, cmd, flags)
  hl.bind(keys, hl.dsp.exec_cmd(cmd), flags)
end

-- Apps ----------------------------------------------------------------------------
exec(mod .. " + Return", terminal)
exec(mod .. " + Space", launcher)
exec(mod .. " + E", files)
exec(mod .. " + B", browser)
exec(mod .. " + O", editor)
exec(mod .. " + C", "devy-menu clipboard")
exec(mod .. " + comma", "makoctl dismiss --all")
exec(mod .. " + SHIFT + comma", "devy-menu dnd")
exec(mod .. " + Escape", "loginctl lock-session")
exec(mod .. " + SHIFT + Escape", "devy-menu power")
exec(mod .. " + ALT + Space", "hyprctl switchxkblayout all next")
exec(mod .. " + SHIFT + T", "devy-menu theme")

-- Screenshots -----------------------------------------------------------------------
exec(mod .. " + SHIFT + S", "devy-screenshot region")
exec("Print", "devy-screenshot screen")
exec(mod .. " + Print", "devy-screenshot window")

-- Windows ----------------------------------------------------------------------------
bind(mod .. " + Q", hl.dsp.window.close())
bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
bind(mod .. " + P", hl.dsp.window.pseudo())
bind(mod .. " + S", hl.dsp.layout("togglesplit"))
bind(mod .. " + G", hl.dsp.group.toggle())

-- Focus / move: vim keys and arrows.
local dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(dirs) do
  bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
  bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end
for _, dir in ipairs({ "left", "down", "up", "right" }) do
  bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
  bind(mod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Resize with SUPER+CTRL+hjkl (repeats while held).
local resize = { h = { -40, 0 }, l = { 40, 0 }, k = { 0, -40 }, j = { 0, 40 } }
for key, d in pairs(resize) do
  bind(mod .. " + CTRL + " .. key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
end

-- Mouse: SUPER + left drag moves, SUPER + right drag resizes.
bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces ----------------------------------------------------------------------------
for i = 1, 10 do
  local key = i % 10
  bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad terminal: SUPER+` shows/hides a drop-down terminal.
bind(mod .. " + grave", hl.dsp.workspace.toggle_special("scratch"))
bind(mod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratch" }))

-- Session ------------------------------------------------------------------------------------
exec(mod .. " + SHIFT + R", "hyprctl reload")
-- `uwsm stop` ends the session cleanly (stops all session units first).
exec(mod .. " + SHIFT + E", "uwsm stop")

-- Media / hardware keys (work on the lock screen too) ---------------------------------------
local hw = { locked = true, repeating = true }
exec("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", hw)
exec("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", hw)
exec("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
exec("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true })
exec("XF86MonBrightnessUp", "brightnessctl -e4 -n2 set 5%+", hw)
exec("XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 5%-", hw)
exec("XF86AudioNext", "playerctl next", { locked = true })
exec("XF86AudioPrev", "playerctl previous", { locked = true })
exec("XF86AudioPlay", "playerctl play-pause", { locked = true })
exec("XF86AudioPause", "playerctl play-pause", { locked = true })
