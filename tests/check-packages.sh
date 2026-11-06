#!/usr/bin/env bash
# Verify every package in packages/*.txt exists: repo lists via `pacman -Si`, aur.txt via
# the AUR RPC. Run on Arch (or in an archlinux container — CI does this).
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=install/lib.sh
DEVY_ROOT="$ROOT" source "$ROOT/install/lib.sh"

missing=0
sudo_or_not=()
[[ $EUID -ne 0 ]] && sudo_or_not=(sudo)
"${sudo_or_not[@]}" pacman -Sy >/dev/null

for list in "$ROOT"/packages/*.txt; do
  [[ $(basename "$list") == aur.txt ]] && continue
  while read -r pkg; do
    if ! pacman -Si "$pkg" >/dev/null 2>&1; then
      # A group (e.g. nerd-fonts) or a provided name is OK too.
      if ! pacman -Sg "$pkg" >/dev/null 2>&1 && ! pacman -Ssq "^${pkg}\$" >/dev/null 2>&1; then
        echo "MISSING (repo): $pkg  [$(basename "$list")]"
        missing=$((missing + 1))
      fi
    fi
  done < <(read_pkg_list "$list")
done

while read -r pkg; do
  n="$(curl -fsS "https://aur.archlinux.org/rpc/v5/info?arg[]=$pkg" | jq '.resultcount')"
  if [[ $n != 1 ]]; then
    echo "MISSING (AUR): $pkg"
    missing=$((missing + 1))
  fi
done < <(read_pkg_list "$ROOT/packages/aur.txt")

if ((missing)); then
  echo "check-packages: $missing missing"
  exit 1
fi
echo "check-packages: all packages exist"
