#!/usr/bin/env bash
# 15 — gaming: Steam + gamemode + MangoHud (ADR-025). Skipped with --no-gaming and in VMs.
# Order matters: lib32 GPU drivers FIRST, then steam (see packages/gaming.txt header).

if [[ $DEVY_GAMING != 1 || $DEVY_PROFILE == vm ]]; then
  log_step "Gaming (skipped)"
else
  log_step "Gaming"
  pkg_dir="$DEVY_ROOT/packages"

  # Enable [multilib] (32-bit repo): uncomment its block, or append it if the block is absent.
  if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    if grep -q '^#\[multilib\]' /etc/pacman.conf; then
      run_root sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
    else
      printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | run_root tee -a /etc/pacman.conf >/dev/null
    fi
    run_root pacman -Sy --noconfirm
    log_ok "enabled [multilib]"
  fi

  vendors="$(cat /sys/class/drm/card*/device/vendor 2>/dev/null | sort -u || true)"
  lib32_lists=()
  if [[ $vendors == *0x8086* ]]; then lib32_lists+=("$pkg_dir/gaming-lib32-intel.txt"); fi
  if [[ $vendors == *0x10de* ]]; then lib32_lists+=("$pkg_dir/gaming-lib32-nvidia.txt"); fi
  if [[ $vendors == *0x1002* ]]; then lib32_lists+=("$pkg_dir/gaming-lib32-amd.txt"); fi

  if [[ ${#lib32_lists[@]} -eq 0 ]]; then
    log_warn "no supported GPU found for 32-bit drivers: skipping Steam"
  else
    mapfile -t lib32 < <(read_pkg_list "${lib32_lists[@]}" | sort -u)
    run_root pacman -S --needed --noconfirm "${lib32[@]}"
    mapfile -t gaming < <(read_pkg_list "$pkg_dir/gaming.txt")
    run_root pacman -S --needed --noconfirm "${gaming[@]}"
    # gamemode can renice/change governor only for members of the 'gamemode' group.
    if getent group gamemode >/dev/null && ! id -nG "$DEVY_USER" | grep -qw gamemode; then
      run_root usermod -aG gamemode "$DEVY_USER"
    fi
    log_ok "Steam ready. Hybrid laptop: Steam game → Properties → Launch options: prime-run gamemoderun %command%"
  fi
fi
