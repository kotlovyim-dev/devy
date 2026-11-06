#!/usr/bin/env bash
# 99 — finish: record the installed version and tell the user what's next.

log_step "Finish"
if [[ $DEVY_DRY_RUN != 1 ]]; then
  git -C "$DEVY_ROOT" rev-parse --short HEAD >"$DEVY_STATE_DIR/installed-version" 2>/dev/null || true
fi
cat <<'MSG'

    Devy is installed.
      • Reboot, log in on tty1 — Hyprland starts automatically.
      • SUPER+Enter terminal · SUPER+Space apps · SUPER+Shift+Esc power menu
      • Check health:   devy-doctor --perf
      • Update safely:  devy-update
MSG
