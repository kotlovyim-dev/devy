-- Window and layer rules. See https://wiki.hypr.land/configuring/core/rules/

-- Many apps ask to be maximized on start; in a tiling WM that just fights the layout.
hl.window_rule({
  name = "suppress-maximize",
  match = { class = ".*" },
  suppress_event = "maximize",
})

-- Fix XWayland drag & drop ghost windows (from the official example config).
hl.window_rule({
  name = "fix-xwayland-drags",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

-- Small utility windows float and are centered.
hl.window_rule({
  name = "float-utilities",
  match = {
    class = "^(org\\.pulseaudio\\.pavucontrol|blueman-manager|nm-connection-editor|xdg-desktop-portal-gtk|org\\.gnome\\.Calculator|com\\.gabm\\.satty|imv|mpv)$",
  },
  float = true,
  center = true,
})

-- File pickers and "Save as" dialogs float.
hl.window_rule({
  name = "float-dialogs",
  match = { title = "^(Open File|Open Folder|Save As|Save File|Select a File|File Upload|Choose Files).*" },
  float = true,
  center = true,
})

-- Picture-in-picture video stays on top in the corner.
hl.window_rule({
  name = "pip",
  match = { title = "^(Picture[- ]in[- ][Pp]icture|Картинка в картинці)$" },
  float = true,
  pin = true,
  keep_aspect_ratio = true,
})

-- Steam: small helper windows float; the main window and games stay tiled/fullscreen.
hl.window_rule({
  name = "steam-dialogs",
  match = { class = "^steam$", title = "^(Friends List|Steam Settings|Steam - News|Special Offers)$" },
  float = true,
  center = true,
})

-- Scratchpad terminal (SUPER+`): lives on special:scratch, floating, centered.
hl.window_rule({
  name = "scratch-terminal",
  match = { class = "^dev\\.devy\\.scratch$" },
  workspace = "special:scratch silent",
  float = true,
  size = { "monitor_w * 0.7", "monitor_h * 0.65" },
  center = true,
})

-- Blur behind the bar, launcher and notifications.
hl.layer_rule({ name = "blur-bar", match = { namespace = "^waybar$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-launcher", match = { namespace = "^launcher$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-notifications", match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.2 })
-- No slide-in for screenshot selection, it should feel instant.
hl.layer_rule({ name = "no-anim-selection", match = { namespace = "^selection$" }, no_anim = true })
