#!/usr/bin/env bash
# 00 — preflight: refuse to run anywhere we could do damage.
# Sourced by install.sh (lib.sh already loaded).

log_step "Preflight checks"

[[ $EUID -ne 0 ]] || die "Run as your normal user, not root (sudo is used when needed)."

[[ -f /etc/arch-release ]] || die "This is not Arch Linux (/etc/arch-release missing)."

[[ "$(uname -m)" == x86_64 ]] || die "Only x86_64 is supported for now."

[[ -d /sys/firmware/efi ]] || die "UEFI boot required (legacy BIOS is not supported)."

has sudo || die "sudo is missing: pacman -S sudo, then add your user to 'wheel'."
if [[ $DEVY_DRY_RUN != 1 ]]; then
  sudo -v || die "sudo did not authenticate."
fi

if ! curl -fsS --max-time 8 -o /dev/null https://archlinux.org; then
  die "No internet connection (cannot reach archlinux.org)."
fi
log_ok "internet ok"

root_fs="$(findmnt -no FSTYPE /)"
if [[ $root_fs == btrfs ]]; then
  log_ok "root filesystem is btrfs"
else
  log_warn "root filesystem is '$root_fs', not btrfs: snapshots/rollback will be skipped."
fi

# Hyprland/uwsm need a real login session, not a chroot.
if systemd-detect-virt --chroot 2>/dev/null; then
  die "Running inside a chroot. Boot the installed system and run install.sh from your user."
fi

# Never run a desktop install while a pacman transaction is in progress.
[[ ! -e /var/lib/pacman/db.lck ]] || die "pacman is locked (/var/lib/pacman/db.lck). Finish other updates first."

log_ok "preflight passed (profile: $DEVY_PROFILE)"
