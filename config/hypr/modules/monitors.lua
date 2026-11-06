-- Monitors. Default: every output at its preferred mode, auto position and scale.
-- Put fixed layouts (e.g. external monitor left of the laptop) in ~/.config/devy/user.lua:
--   hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
-- See https://wiki.hypr.land/configuring/core/monitors/

hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = "auto",
})
