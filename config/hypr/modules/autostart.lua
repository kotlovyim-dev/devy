-- Autostart.
-- Long-running services (waybar, hypridle, hyprpaper, polkit agent) are systemd user
-- units bound to graphical-session.target, enabled by install/40-desktop.sh. uwsm
-- starts that target, so they start/stop with the session and restart on crash.
-- Only things without a unit are started here.

hl.on("hyprland.start", function()
  -- Clipboard history (text + images) for SUPER+C.
  hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
  hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
  -- Hidden scratchpad terminal, shown with SUPER+`.
  hl.exec_cmd("uwsm app -- ghostty --class=dev.devy.scratch")
end)
