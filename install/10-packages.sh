#!/usr/bin/env bash
# 10 — packages: pacman tuning, full upgrade, repo packages, paru bootstrap, AUR packages.

log_step "Packages"

pkg_dir="$DEVY_ROOT/packages"

# --- pacman.conf tuning (idempotent sed edits) -----------------------------------
# ParallelDownloads speeds up big installs; Color/VerbosePkgLists make output readable.
if ! grep -q '^ParallelDownloads' /etc/pacman.conf; then
  run_root sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
fi
grep -q '^Color' /etc/pacman.conf || run_root sed -i 's/^#Color/Color/' /etc/pacman.conf
grep -q '^VerbosePkgLists' /etc/pacman.conf || run_root sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf

# Refresh keyring first: an expired archlinux-keyring is a classic cause of
# "signature is unknown trust" failures on older installs.
run_root pacman -Sy --needed --noconfirm archlinux-keyring

# Partial upgrades are unsupported on Arch, so always do a full upgrade before installing.
run_root pacman -Su --noconfirm

# --- repo packages ---------------------------------------------------------------
lists=("$pkg_dir/base.txt" "$pkg_dir/desktop.txt" "$pkg_dir/dev.txt")
case "$DEVY_PROFILE" in
  vm) lists+=("$pkg_dir/gpu-vm.txt") ;;
  *)
    # GPU lists are chosen from the PCI vendor IDs present (8086 Intel, 10de NVIDIA, 1002 AMD).
    vendors="$(cat /sys/class/drm/card*/device/vendor 2>/dev/null | sort -u || true)"
    if [[ $vendors == *0x8086* ]]; then lists+=("$pkg_dir/gpu-intel.txt"); fi
    if [[ $vendors == *0x10de* ]]; then lists+=("$pkg_dir/gpu-nvidia.txt"); fi
    if [[ $vendors == *0x1002* ]]; then lists+=("$pkg_dir/gpu-amd.txt"); fi
    ;;
esac
if [[ $DEVY_PROFILE == laptop ]]; then lists+=("$pkg_dir/laptop.txt"); fi

mapfile -t repo_pkgs < <(read_pkg_list "${lists[@]}" | sort -u)
log_info "${#repo_pkgs[@]} repo packages from: $(basename -a "${lists[@]}" | tr '\n' ' ')"
run_root pacman -S --needed --noconfirm "${repo_pkgs[@]}"

# --- paru (AUR helper) bootstrap -----------------------------------------------------
if ! has paru; then
  log_info "bootstrapping paru from the AUR (paru-bin, prebuilt)"
  tmp="$(mktemp -d)"
  run git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  if [[ $DEVY_DRY_RUN != 1 ]]; then
    (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
  fi
  rm -rf "$tmp"
fi

# --- AUR packages (kept to a minimum: supply-chain risk) ---------------------------
mapfile -t aur_pkgs < <(read_pkg_list "$pkg_dir/aur.txt")
if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
  log_info "AUR: ${aur_pkgs[*]}"
  # --skipreview is NOT used: paru shows PKGBUILD diffs for review unless --yes.
  if [[ $DEVY_YES == 1 ]]; then
    run paru -S --needed --noconfirm --skipreview "${aur_pkgs[@]}"
  else
    run paru -S --needed "${aur_pkgs[@]}"
  fi
fi

log_ok "packages installed"
