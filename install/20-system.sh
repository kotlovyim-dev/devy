#!/usr/bin/env bash
# 20 — system: memory (zram + OOM), stability fixes, maintenance timers, snapshots,
# firewall, locale/time. Every fix here is listed with its reason in docs/STABILITY.md.

log_step "System tuning"

# --- zram swap -----------------------------------------------------------------
# Compressed swap in RAM. Half of RAM, max 8 GiB, zstd. (ArchWiki: Zram)
write_root_file /etc/systemd/zram-generator.conf <<'EOF'
# Devy: compressed swap in RAM (see docs/STABILITY.md#memory)
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# zswap must be off when zram is used, otherwise zram is barely used (ArchWiki: Zram).
# We set it at runtime here and via kernel cmdline in the bootloader step (M4).
write_root_file /etc/tmpfiles.d/devy-zswap.conf <<'EOF'
w- /sys/module/zswap/parameters/enabled - - - - N
EOF

# Values from ArchWiki "Zram#Optimizing swap on zram" (originally Pop!_OS).
write_root_file /etc/sysctl.d/90-devy-zram.conf <<'EOF'
# Devy: tuned for swap on zram. Source: ArchWiki Zram#Optimizing_swap_on_zram
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

# Many file watchers (Next.js, Vite, VS Code, Docker bind mounts) hit the default limit
# and fail with ENOSPC "System limit for number of file watchers reached".
write_root_file /etc/sysctl.d/90-devy-dev.conf <<'EOF'
# Devy: room for dev-server file watchers (webpack/vite/tsc --watch, IDEs)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
EOF

# --- OOM: never freeze the whole desktop ------------------------------------------
# systemd-oomd kills the biggest offender cgroup under memory pressure *before* the
# kernel thrashes. Works well with uwsm, because every app runs in its own unit.
write_root_file /etc/systemd/system/-.slice.d/10-devy-oomd.conf <<'EOF'
[Slice]
ManagedOOMSwap=kill
EOF
write_root_file /etc/systemd/system/user@.service.d/10-devy-oomd.conf <<'EOF'
[Service]
ManagedOOMMemoryPressure=kill
ManagedOOMMemoryPressureLimit=60%
EOF
enable_unit systemd-oomd.service

# --- fast, predictable shutdown -----------------------------------------------------
# The default 90 s "A stop job is running..." wait is one of the most common complaints.
write_root_file /etc/systemd/system.conf.d/10-devy-timeouts.conf <<'EOF'
[Manager]
DefaultTimeoutStopSec=15s
EOF
write_root_file /etc/systemd/user.conf.d/10-devy-timeouts.conf <<'EOF'
[Manager]
DefaultTimeoutStopSec=10s
EOF

# --- journal: bounded size -----------------------------------------------------------
write_root_file /etc/systemd/journald.conf.d/10-devy.conf <<'EOF'
[Journal]
SystemMaxUse=500M
EOF

# --- network ---------------------------------------------------------------------------
# Wi-Fi power saving causes random drops/latency spikes on many cards. Small battery cost.
write_root_file /etc/NetworkManager/conf.d/10-devy-wifi-powersave.conf <<'EOF'
[connection]
# 2 = disable power saving
wifi.powersave = 2
EOF
enable_unit NetworkManager.service
enable_unit bluetooth.service

# --- maintenance timers ------------------------------------------------------------------
enable_unit fstrim.timer   # SSD TRIM weekly (util-linux)
enable_unit paccache.timer # keep the pacman cache small (pacman-contrib)
enable_unit systemd-timesyncd.service

if [[ "$(findmnt -no FSTYPE /)" == btrfs ]]; then
  enable_unit "btrfs-scrub@-.timer" # monthly data integrity check (btrfs-progs)
fi

# reflector: fast, fresh mirrors near Lviv. Runs weekly via its timer.
write_root_file /etc/xdg/reflector/reflector.conf <<'EOF'
# Devy defaults (see `reflector --help`)
--save /etc/pacman.d/mirrorlist
--protocol https
--country Poland,Germany,Ukraine,Czechia
--latest 15
--sort rate
EOF
enable_unit reflector.timer

# --- snapshots (btrfs + snapper + snap-pac) -------------------------------------------------
setup_snapper() {
  if [[ "$(findmnt -no FSTYPE /)" != btrfs ]]; then
    log_warn "root is not btrfs: skipping snapper"
    return 0
  fi
  if run_root test -f /etc/snapper/configs/root 2>/dev/null && [[ $DEVY_DRY_RUN != 1 ]]; then
    log_info "snapper 'root' config exists"
  else
    # archinstall mounts a separate @snapshots subvolume at /.snapshots, which makes
    # `snapper create-config` fail. Standard fix (ArchWiki: Snapper#Configuration of snapper and mount point):
    # unmount it, let snapper create its config, then put the @snapshots mount back.
    if findmnt -n /.snapshots >/dev/null; then
      log_info "re-creating snapper config around the existing /.snapshots mount"
      run_root umount /.snapshots
      run_root rmdir /.snapshots
      run_root snapper -c root create-config /
      run_root btrfs subvolume delete /.snapshots
      run_root mkdir /.snapshots
      run_root mount -a
      run_root chmod 750 /.snapshots
    else
      run_root snapper -c root create-config /
    fi
  fi
  # Keep a bounded number of snapshots so the disk never fills up silently.
  run_root snapper -c root set-config \
    TIMELINE_CREATE=no NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5 NUMBER_CLEANUP=yes
  enable_unit snapper-cleanup.timer
  # snap-pac (installed from base.txt) now snapshots before/after every pacman transaction.
  log_ok "snapper ready (pre/post snapshots on every pacman transaction)"
}
setup_snapper

# --- firewall ---------------------------------------------------------------------------------
# Default deny inbound. Note: Docker publishes ports by editing iptables directly and
# bypasses ufw — see docs/STABILITY.md#docker-and-firewall.
if [[ $DEVY_DRY_RUN == 1 ]] || ! sudo ufw status | grep -q 'Status: active'; then
  run_root ufw default deny incoming
  run_root ufw default allow outgoing
  run_root ufw --force enable
fi
enable_unit ufw.service

# --- keyring unlocked at login ----------------------------------------------------------
# Chromium, VS Code (GitHub sign-in) and gh store secrets in gnome-keyring. Without a
# display manager nothing unlocks it, so every app would ask for a password. Add
# pam_gnome_keyring to the TTY login (snippet from the Hyprland wiki, useful-utilities/uwsm).
# The leading '-' makes PAM skip the line if the module is missing, so login never breaks.
if [[ -f /etc/pam.d/login ]] && ! grep -q pam_gnome_keyring /etc/pam.d/login; then
  run_root cp -n /etc/pam.d/login /etc/pam.d/login.devy-bak
  run_root sed -i \
    -e '/^auth[[:space:]]\+include[[:space:]]\+system-local-login/a -auth      optional     pam_gnome_keyring.so' \
    -e '/^password[[:space:]]\+include[[:space:]]\+system-local-login/a -password  optional     pam_gnome_keyring.so    use_authtok' \
    -e '/^session[[:space:]]\+include[[:space:]]\+system-local-login/a -session   optional     pam_gnome_keyring.so    auto_start' \
    /etc/pam.d/login
  log_ok "gnome-keyring unlocks at TTY login (backup: /etc/pam.d/login.devy-bak)"
fi

# --- locale & time ---------------------------------------------------------------------------
for loc in en_US.UTF-8 uk_UA.UTF-8; do
  if ! grep -q "^${loc} UTF-8" /etc/locale.gen; then
    run_root sed -i "s/^#\s*${loc} UTF-8/${loc} UTF-8/" /etc/locale.gen
    regen_locale=1
  fi
done
[[ ${regen_locale:-0} == 1 ]] && run_root locale-gen
# English UI, Ukrainian formats for date/numbers would surprise in a dev setup, so keep en_US.
[[ -f /etc/locale.conf ]] || write_root_file /etc/locale.conf <<<'LANG=en_US.UTF-8'

if [[ "$(timedatectl show -p Timezone --value 2>/dev/null)" != Europe/Kyiv ]]; then
  run_root timedatectl set-timezone Europe/Kyiv
fi
run_root timedatectl set-ntp true

log_ok "system tuned"
