-- Keyboard, mouse, touchpad.
-- Layouts: English (US) first — Hyprland resolves binds against the FIRST layout, so
-- SUPER+letter binds keep working while Ukrainian is active (wiki: binds/keyboard-layouts).
-- Ukrainian uses the "winkeys" variant: same punctuation positions as on Windows.
-- Switch: Alt+Shift (XKB option) or SUPER+ALT+Space (see binds.lua).

hl.config({
  input = {
    kb_layout = "us,ua",
    kb_variant = ",winkeys",
    kb_options = "grp:alt_shift_toggle",
    kb_model = "",
    kb_rules = "",

    numlock_by_default = true,
    repeat_rate = 40,
    repeat_delay = 250,

    follow_mouse = 1,
    sensitivity = 0,

    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      disable_while_typing = true,
      clickfinger_behavior = true,
      scroll_factor = 0.5,
    },
  },
})

-- 3-finger horizontal swipe switches workspaces.
hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})
