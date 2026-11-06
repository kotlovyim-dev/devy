#!/usr/bin/env bash
# 40 — desktop: link configs, install devy-* commands, enable session services, login flow.

log_step "Desktop"

cfg="$DEVY_ROOT/config"

# --- config files ------------------------------------------------------------------
# Whole directories are symlinked so `git pull` in the repo updates them instantly.
# Machine-specific and generated files live outside the repo in ~/.config/devy/.
for dir in hypr waybar fuzzel ghostty uwsm; do
  link_config "$cfg/$dir" "$DEVY_CONFIG_HOME/$dir"
done
run mkdir -p "$DEVY_CONFIG_HOME/mako" # mako/config is a link to the rendered theme file
link_config "$cfg/starship.toml" "$DEVY_CONFIG_HOME/starship.toml"
link_config "$cfg/chromium-flags.conf" "$DEVY_CONFIG_HOME/chromium-flags.conf"
link_config "$cfg/code-flags.conf" "$DEVY_CONFIG_HOME/code-flags.conf"
link_config "$cfg/git/config" "$DEVY_CONFIG_HOME/git/config"
link_config "$cfg/zsh/zshrc" "$HOME/.zshrc"
link_config "$cfg/zsh/zprofile" "$HOME/.zprofile"

# User override file: created once, never overwritten.
user_lua="$DEVY_CONFIG_HOME/devy/user.lua"
if [[ ! -e $user_lua ]]; then
  run mkdir -p "$(dirname "$user_lua")"
  if [[ $DEVY_DRY_RUN != 1 ]]; then
    cat >"$user_lua" <<'LUA'
-- Your personal Hyprland overrides. Loaded last; Devy never changes this file.
-- Examples:
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "1920x0", scale = 1 })
-- hl.config({ input = { touchpad = { natural_scroll = false } } })
LUA
  fi
  log_ok "created $user_lua"
fi

# --- commands ------------------------------------------------------------------------
run mkdir -p "$HOME/.local/bin"
# Exec bits get lost when the repo passes through Windows; set them every run.
run chmod +x "$DEVY_ROOT"/bin/devy-* "$DEVY_ROOT"/install.sh "$DEVY_ROOT"/tests/*.sh "$DEVY_ROOT"/tests/vm/*.sh
for f in "$DEVY_ROOT"/bin/devy-*; do
  link_config "$f" "$HOME/.local/bin/$(basename "$f")"
done

# --- session services (systemd user units bound to graphical-session.target) ----------
# uwsm starts graphical-session.target, so these start with Hyprland and restart on crash.
enable_unit --user waybar.service hypridle.service hyprpaper.service hyprpolkitagent.service

# --- login: TTY1 -> uwsm -> Hyprland --------------------------------------------------------
# No display manager in M1 (fewer moving parts, faster boot). ~/.zprofile starts the
# session on tty1; tty2..6 stay plain shells as a rescue path. With LUKS (M4) we add
# autologin on tty1, because the disk password already authenticates you.
if [[ "$(getent passwd "$DEVY_USER" | cut -d: -f7)" != */zsh ]]; then
  run_root chsh -s /usr/bin/zsh "$DEVY_USER"
fi

# --- fonts cache -------------------------------------------------------------------------------
run fc-cache -f >/dev/null

log_ok "desktop configured"
