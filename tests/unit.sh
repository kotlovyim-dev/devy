#!/usr/bin/env bash
# Unit tests for install/lib.sh and devy-theme. Runs anywhere (no Arch, no root).
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" XDG_STATE_HOME="$TMP/home/.local/state"
mkdir -p "$HOME"

pass=0
check() { # check "name" cmd...
  if "${@:2}"; then pass=$((pass + 1)); else
    echo "FAIL: $1"
    exit 1
  fi
}

# shellcheck source=install/lib.sh
DEVY_ROOT="$ROOT" source "$ROOT/install/lib.sh"

# read_pkg_list strips comments/blank lines/trailing spaces.
printf 'foo   # comment\n\n# only comment\nbar\n' >"$TMP/p.txt"
check "read_pkg_list" test "$(read_pkg_list "$TMP/p.txt" | tr '\n' ' ')" == "foo bar "

# link_config: creates link, second run is a no-op, real files are backed up once.
mkdir -p "$TMP/src"
echo a >"$TMP/src/file"
echo old >"$HOME/target"
link_config "$TMP/src/file" "$HOME/target" >/dev/null 2>&1
check "link created" test -L "$HOME/target"
check "backup kept" test "$(cat "$HOME/target.devy-bak")" == old
before="$(stat -c %Y "$HOME/target.devy-bak")"
out="$(link_config "$TMP/src/file" "$HOME/target" 2>&1)"
check "link idempotent (no output)" test -z "$out"
check "backup untouched" test "$(stat -c %Y "$HOME/target.devy-bak")" == "$before"

# dry-run never touches the filesystem.
DEVY_DRY_RUN=1 link_config "$TMP/src/file" "$HOME/dry-target" >/dev/null 2>&1
check "dry-run writes nothing" test ! -e "$HOME/dry-target"

# devy-theme: renders, links, and re-applying gives identical files.
python3 -I "$ROOT/bin/devy-theme" graphite --no-reload >/dev/null
check "theme state" test "$(cat "$XDG_CONFIG_HOME/devy/current-theme")" == graphite
check "waybar link" test -L "$XDG_CONFIG_HOME/waybar/devy-theme.css"
check "no leftover tokens" bash -c "! grep -R '{{' '$XDG_CONFIG_HOME/devy/current'"
sum1="$(cat "$XDG_CONFIG_HOME"/devy/current/* | sha256sum)"
python3 -I "$ROOT/bin/devy-theme" --reapply --no-reload >/dev/null
sum2="$(cat "$XDG_CONFIG_HOME"/devy/current/* | sha256sum)"
check "theme re-apply idempotent" test "$sum1" == "$sum2"
check "theme contrast (WCAG AA)" python3 -I "$ROOT/bin/devy-theme" check graphite >/dev/null

# A real file where a theme link should go is never overwritten.
rm "$XDG_CONFIG_HOME/mako/config"
echo "my own mako config" >"$XDG_CONFIG_HOME/mako/config"
python3 -I "$ROOT/bin/devy-theme" graphite --no-reload >/dev/null
check "user file preserved" test "$(cat "$XDG_CONFIG_HOME/mako/config")" == "my own mako config"

echo "unit: ok ($pass checks)"
