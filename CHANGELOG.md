# Changelog

## [Unreleased] — M1 skeleton (2026-11-06)
### Added
- Installer: `install.sh` + steps 00 preflight, 10 packages, 20 system, 30 gpu, 40 desktop, 50 dev, 60 theme, 99 finish; `--dry-run`, `--yes`, `--profile`, `--only`, `--skip`.
- Hyprland 0.57 **Lua** config split in modules; Waybar, fuzzel, mako, Ghostty, hyprlock, hypridle, hyprpaper, uwsm env, zsh, starship, git configs.
- Theme engine `devy-theme` (palette.toml → templates, live reload, WCAG check) and theme **Graphite**.
- `devy-doctor`, `devy-update`, `devy-menu`, `devy-screenshot`, `devy-dpms`.
- Stability defaults: snap-pac snapshots, linux-lts fallback, kernel-modules-hook, zram + systemd-oomd, shutdown timeouts, journal/docker log limits, reflector/paccache/fstrim/scrub timers, Wi-Fi powersave off, ufw.
- Tests: lint, unit, Hyprland Lua mock check against wiki option list, package check, smoke test, QEMU script; GitHub Actions.
- Docs: DECISIONS (22 ADRs), STABILITY, VM, UNVERIFIED, KEYBINDS, PERF, CREDITS.
- Chromium (Wayland flags, keyring), VS Code (`visual-studio-code-bin`, argv/settings defaults), gnome-keyring PAM unlock.
- Gaming step `15-gaming.sh`: multilib, lib32 drivers first, Steam, gamemode, MangoHud (`--no-gaming` to skip).
- docs/USB.md: safe real-hardware testing from a USB SSD (BitLocker, Secure Boot, systemd-boot fallback, M2 checklist).
### UNTESTED
- Everything on real Arch/Hyprland (see docs/UNVERIFIED.md). NVIDIA hybrid path in 30-gpu.sh (M2).
