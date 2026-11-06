#!/usr/bin/env bash
# 60 — theme: apply the default theme (or keep the current one on re-runs).

log_step "Theme"
theme="graphite"
if [[ -f $DEVY_CONFIG_HOME/devy/current-theme ]]; then
  theme="$(cat "$DEVY_CONFIG_HOME/devy/current-theme")"
fi
export DEVY_ROOT
extra=()
[[ $DEVY_DRY_RUN == 1 ]] && extra=(--dry-run)
# devy-theme has its own --dry-run, so it is called directly (not through `run`).
python3 -I "$DEVY_ROOT/bin/devy-theme" "$theme" --no-reload "${extra[@]}"
