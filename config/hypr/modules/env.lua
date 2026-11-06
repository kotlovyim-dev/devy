-- Environment for the Hyprland session.
-- Session-wide variables that other programs also need live in ~/.config/uwsm/env
-- (uwsm exports them to the whole systemd user session). Only compositor-side
-- variables go here.

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Hyprland 0.57 asks rtkit for realtime priority; a slow kernel call can then make
-- the kernel SIGKILL the compositor (hyprwm/Hyprland#16648, worked around the same
-- way by Omarchy). Remove when that issue is closed.
hl.env("HYPRLAND_NO_RT", "1")

hl.config({
  xwayland = {
    -- Let XWayland apps render at native resolution instead of being blurry-scaled.
    force_zero_scaling = true,
  },
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
    focus_on_activate = true,
  },
})
