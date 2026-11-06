#!/usr/bin/env bash
# Devy installer: turns a fresh, minimal Arch Linux (btrfs) install into the Devy desktop.
#
# Usage: ./install.sh [--dry-run] [--yes] [--profile laptop|desktop|vm] [--no-gaming] [--only NN] [--skip NN[,NN]]
#
# Safe to re-run: every step is idempotent.
set -euo pipefail

DEVY_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export DEVY_ROOT

usage() {
  sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

DEVY_DRY_RUN=0
DEVY_YES=0
DEVY_GAMING=1
DEVY_PROFILE=""
ONLY=""
SKIP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DEVY_DRY_RUN=1 ;;
    --yes | -y) DEVY_YES=1 ;;
    --no-gaming) DEVY_GAMING=0 ;;
    --profile)
      DEVY_PROFILE="${2:?--profile needs a value}"
      shift
      ;;
    --only)
      ONLY="${2:?--only needs a step number}"
      shift
      ;;
    --skip)
      SKIP="${2:?--skip needs a step number}"
      shift
      ;;
    -h | --help) usage 0 ;;
    *)
      echo "unknown option: $1" >&2
      usage 1
      ;;
  esac
  shift
done

# Auto-detect the profile when not given.
if [[ -z $DEVY_PROFILE ]]; then
  virt="$(systemd-detect-virt 2>/dev/null || true)"
  if [[ -n $virt && $virt != none ]]; then
    DEVY_PROFILE=vm
  elif compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
    DEVY_PROFILE=laptop
  else
    DEVY_PROFILE=desktop
  fi
fi
case "$DEVY_PROFILE" in laptop | desktop | vm) ;; *)
  echo "bad profile: $DEVY_PROFILE" >&2
  exit 1
  ;;
esac

export DEVY_DRY_RUN DEVY_YES DEVY_PROFILE DEVY_GAMING
# shellcheck source=install/lib.sh
source "$DEVY_ROOT/install/lib.sh"

log_step "Devy installer — profile: $DEVY_PROFILE$([[ $DEVY_DRY_RUN == 1 ]] && echo ' (dry run)')"
log_info "log file: $DEVY_LOG"

for step in "$DEVY_ROOT"/install/[0-9][0-9]-*.sh; do
  num="$(basename "$step" | cut -c1-2)"
  [[ -n $ONLY && $num != "$ONLY" ]] && continue
  [[ -n $SKIP && ",$SKIP," == *",$num,"* ]] && continue
  # Each step runs in a subshell so one step's variables cannot leak into the next.
  # shellcheck source=/dev/null
  (source "$step")
done

log_step "Done."
