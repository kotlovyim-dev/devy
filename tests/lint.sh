#!/usr/bin/env bash
# Static checks — run before every commit (CI runs the same).
# Needs: shellcheck, shfmt, python3, and `pip install lupa` for the Lua check.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mapfile -t sh_files < <(
  {
    echo install.sh
    ls install/*.sh tests/*.sh tests/vm/*.sh
    grep -l '^#!/usr/bin/env bash' bin/*
  } | sort -u
)

echo "== shellcheck"
shellcheck -x "${sh_files[@]}"
echo "== shfmt"
shfmt -d -i 2 -ci "${sh_files[@]}"
echo "== python"
python3 -m py_compile bin/devy-theme tests/lua-check.py
echo "== waybar config is valid JSON (after stripping // comments)"
python3 -c "import json,re,sys; json.loads(re.sub(r'^\s*//.*$','',open('config/waybar/config.jsonc').read(),flags=re.M))"
echo "== themes"
for t in themes/*/; do python3 -I bin/devy-theme check "$(basename "$t")" >/dev/null; done
echo "== hyprland lua (mock API, options checked against wiki 0.57)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for t in themes/*/; do
  XDG_CONFIG_HOME="$tmp" python3 -I bin/devy-theme "$(basename "$t")" --no-reload >/dev/null
  python3 tests/lua-check.py config/hypr "$tmp/devy/current/hypr.lua"
done
echo "== unit"
bash tests/unit.sh
echo "lint: all green"
