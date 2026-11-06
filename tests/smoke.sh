#!/usr/bin/env bash
# Smoke test — run INSIDE the installed system (VM or laptop), from a Hyprland terminal.
# Checks files, services and the running session; exits non-zero on any failure.
#   ./tests/smoke.sh            full check (needs a running Hyprland session)
#   ./tests/smoke.sh --no-session   only files/services (e.g. over SSH)
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fails=0
t() { # t "description" command...
  if "${@:2}" >/dev/null 2>&1; then printf '  ok   %s\n' "$1"; else
    printf '  FAIL %s\n' "$1"
    fails=$((fails + 1))
  fi
}

echo "Files"
t "config/hypr is linked from the repo" test "$(readlink -f ~/.config/hypr)" == "$ROOT/config/hypr"
t "theme rendered" test -f ~/.config/devy/current/hypr.lua
t "gpu.lua generated" test -f ~/.config/devy/local/gpu.lua
t "devy-theme on PATH" command -v devy-theme
t "zram config" test -f /etc/systemd/zram-generator.conf
t "sysctl zram tuning applied" test "$(sysctl -n vm.page-cluster)" == 0
t "inotify watches raised" test "$(sysctl -n fs.inotify.max_user_watches)" -ge 524288

echo "Services"
for u in systemd-oomd NetworkManager ufw; do t "$u active" systemctl is-active "$u"; done
t "zram swap on" bash -c "swapon --show=NAME --noheadings | grep -q zram"
t "fstrim.timer enabled" systemctl is-enabled fstrim.timer
t "docker.socket enabled" systemctl is-enabled docker.socket
t "no failed system units" test -z "$(systemctl --failed --no-legend --plain)"

if [[ ${1:-} != --no-session ]]; then
  echo "Session"
  t "Hyprland running" hyprctl version
  t "Hyprland config has no errors" bash -c "[[ -z \"\$(hyprctl configerrors 2>/dev/null | grep -v '^$')\" ]]"
  for u in waybar hypridle hyprpaper hyprpolkitagent; do t "$u.service active" systemctl --user is-active "$u.service"; done
  t "two keyboard layouts (us,ua)" bash -c "hyprctl devices -j | jq -e '[.keyboards[].layout] | any(. == \"us,ua\")'"
  t "layout switch works" hyprctl switchxkblayout all next
  hyprctl switchxkblayout all prev >/dev/null 2>&1
  t "notification sends" notify-send -t 1500 "Devy smoke test" "notifications work"
  t "audio server (pipewire)" wpctl status
  t "portal running" busctl --user status org.freedesktop.portal.Desktop
fi

echo
if ((fails)); then
  echo "smoke: $fails failed"
  exit 1
fi
echo "smoke: all passed"
