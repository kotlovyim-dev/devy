# Architecture Decision Records

Format: **Decision** · Why · Alternatives · Sources. Date of all entries: **2026-11-06** unless noted.
"Revisit" marks decisions that must be re-checked at a later milestone.

---

## ADR-001 — Base and delivery
**Decision:** Arch Linux. Phase 1 = `install.sh` on a fresh Arch; phase 2 = `archiso` ISO wrapping the same scripts.
**Why:** Same path Omarchy took (script first, ISO later), so it is proven for a solo maintainer.
**Sources:** Omarchy repo `install/` (github.com/basecamp/omarchy, MIT); Omarchy 2.0 release notes (ISO added later).

## ADR-002 — Hyprland 0.57, Lua config only ⚠️ (biggest research finding)
**Decision:** The Hyprland config is written in **Lua** (`~/.config/hypr/hyprland.lua`), split into `require()`d modules. No `hyprland.conf` anywhere.
**Why:** Hyprland 0.55 (May 2026) introduced Lua and deprecated hyprlang; **0.57 removed `hyprland.conf` support completely** (PR #15539). Any guide or dotfiles written in the old `bind = SUPER, Q, ...` syntax no longer works. hypr* tools (hyprlock, hypridle, hyprpaper) still use hyprlang, so their configs stay `.conf`.
Each `require()` is its own protected scope, so one broken file does not kill the others (wiki: configuring/core).
**Consequences:**
- Waybar must be **≥ 0.16.0** (released 2026-11-05): older versions send old-style dispatch commands and workspace clicks break (Waybar issue #5198). `devy-doctor` checks this.
- `hyprctl dispatch` now takes Lua: `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'`.
- `tests/lua-check.py` runs our config against a mock `hl` API and checks every option name against the 0.57 wiki option list (`tests/hypr-options-0.57.json`).
**Sources:** hypr.land/news/26_lua · wiki.hypr.land/configuring/core · official example `example/hyprland.lua` in hyprwm/Hyprland @ 0.57.0 · linuxcompatible.org "Hyprland 0.57.0 released, legacy conf dropped" · Waybar git log (Lua dispatch fixes in 0.16.0).

## ADR-003 — Session start: uwsm, no display manager (M1–M3)
**Decision:** `uwsm start hyprland.desktop` from `~/.zprofile` on **tty1** only. tty2–6 stay plain shells (rescue path).
At M4 (with LUKS2) add **autologin on tty1**: the disk password already authenticates the user — the same model as Omarchy ("disk decryption authenticates the user", SDDM autologin).
**Why:** uwsm runs every app as its own systemd unit → clean shutdown, per-app OOM kills, crash isolation. No DM = fewer packages and a faster boot.
**Security:** autologin without disk encryption = anyone with the laptop gets your session. So autologin is **only** enabled together with LUKS.
**Alternatives:** SDDM (Omarchy), greetd+tuigreet/regreet (themeable). Revisit at M4 if a graphical greeter is wanted.
**Sources:** wiki useful-utilities/uwsm (TTY snippet, `uwsm app --`) · Omarchy `default/wayland-sessions/omarchy.desktop`, `install/login/sddm.sh`.

## ADR-004 — Bar: Waybar now, evaluate Quickshell at M3
**Decision:** Waybar ≥ 0.16 for M1–M2. At M3, prototype a Quickshell (QML) bar and keep it only if it is clearly better and stays light.
**Why:** Waybar = official repo, CSS theming, every module we need (workspaces, language indicator, bluetooth, battery, tray). Quickshell has a much higher polish ceiling — Omarchy 4.0 moved its whole shell to Quickshell — but it is a big codebase to own.
**Sources:** Omarchy `bin/omarchy-launch-shell` (Quickshell) · Waybar 0.16.0 tag.

## ADR-005 — Kernel: linux-zen + linux-lts fallback
**Decision:** `linux-zen` default, `linux-lts` as the always-bootable fallback (spec said `linux`; LTS is a better fallback because it is a *different* kernel line, so one regression rarely hits both).
CachyOS kernel/repos: **not now** — experiment in M6.
**Why:** zen is official (no third-party repo trust), tuned for desktop latency. CachyOS wins many Phoronix throughput benchmarks, but much of it comes from x86-64-v3/v4 *package* rebuilds and Zen-specific tuning; for an Alder Lake laptop doing Node/Docker work the gain is small compared to the risk of mixing repos.
**Revisit:** M6, with our own measurements (docs/PERF.md).
**Sources:** Phoronix "Benchmarking the different CachyOS kernel flavors" (2026-06), Phoronix distro comparisons 2026; Arch packages.

## ADR-006 — Bootloader + snapshots: Limine + snapper (M4)
**Decision:** Limine + `limine-snapper-sync` (+ `limine-mkinitcpio-hook`) for bootable snapshot entries; `snap-pac` for pre/post snapshots on every pacman transaction (already in M1).
**Why:** Omarchy ships exactly this and it gives "rollback from the boot menu". GRUB + grub-btrfs also works but is slower and more complex; systemd-boot has no native snapshot menu.
**Note:** `limine-snapper-sync` is AUR (also in the CachyOS repo). M1 uses whatever bootloader archinstall installed; the switch happens in the M4 installer. Secure Boot (sbctl) = M6.
**Sources:** AUR limine-snapper-sync / limine-snapper-cli (gitlab.com/Zesko/limine-snapper-sync) · Omarchy `install/login/limine-snapper.sh` · akitaonrails.com "Omarchy 2.0 — install with the ISO".

## ADR-007 — Power: power-profiles-daemon + thermald (laptop)
**Decision:** `power-profiles-daemon` (works with intel_pstate EPP on Alder Lake) + `thermald`. Not TLP / auto-cpufreq (they conflict with ppd and with each other).
**Revisit:** M2 — measure idle drain on battery; try `powertop --auto-tune` deltas only if measurable.

## ADR-008 — Memory: zram + systemd-oomd, zswap off
**Decision:** zram (zstd, min(RAM/2, 8 GiB), priority 100), sysctl from the ArchWiki zram page (`swappiness=180`, `watermark_boost_factor=0`, `watermark_scale_factor=125`, `page-cluster=0`), zswap disabled, **systemd-oomd** instead of earlyoom.
**Why:** oomd is part of systemd, cgroup-aware, and with uwsm each app is its own cgroup → it kills the one runaway app (a leaking dev server, a 40-tab browser) instead of the desktop freezing. No disk swap → no hibernate (hibernate needs a disk swap; optional, later).
**Sources:** wiki.archlinux.org/title/Zram ("Optimizing swap on zram"; zswap must be disabled) · Fedora discussion on zram defaults.

## ADR-009 — Hybrid GPU (Intel iGPU + RTX 4060)
**Decision:** iGPU renders the desktop; NVIDIA used per app with `prime-run`.
- `nvidia-open-dkms` (open kernel modules recommended for Turing and newer; DKMS so both zen and lts kernels get modules), `nvidia-utils`, `egl-wayland`, `libva-nvidia-driver`.
- `AQ_DRM_DEVICES=/dev/dri/devy-igpu:/dev/dri/devy-dgpu` using **udev symlinks**, because `cardN` numbers change between boots and `:` in by-path names breaks the variable.
- `nvidia-suspend/hibernate/resume` services.
- **No** global `LIBVA_DRIVER_NAME=nvidia` / `__GLX_VENDOR_LIBRARY_NAME=nvidia` on hybrid: it breaks Chromium video when the iGPU drives the display (Omarchy found the same).
- Toggle command `devy-gpu` (iGPU-only ↔ offload) = M2.
**Unverified:** whether the HP Victus 16 has a MUX switch; RTD3 (dGPU sleeping at idle) behaviour. → M2 checklist.
**Sources:** wiki.hypr.land/Nvidia and configuring/extra/multi-gpu · Omarchy `default/hypr/nvidia.lua`.

## ADR-010 — Launcher: fuzzel
**Decision:** fuzzel (official repo, tiny, instant, dmenu mode for clipboard/power/theme menus).
**Alternatives:** Walker (feature-rich, needs the `elephant` service + providers; Omarchy used it), hyprlauncher (first-party, new), rofi (Wayland support upstream since 2025). Revisit at M3 together with the bar.

## ADR-011 — Containers: rootful Docker + `docker` group
**Decision:** Docker (socket-activated) + compose + buildx, user in `docker` group, log rotation in `/etc/docker/daemon.json`.
**Trade-off:** the docker group is root-equivalent. Rootless Docker/Podman are safer but break some compose/devcontainer setups and bind-mount permissions. Documented; revisit if the laptop is used for untrusted images.
**Firewall note:** Docker writes its own iptables rules and **bypasses ufw** for published ports. Bind dev ports to localhost (`127.0.0.1:5432:5432`) — see STABILITY.md.

## ADR-012 — Terminal: Ghostty
**Decision:** Ghostty (official repo, GTK4, GPU-rendered, `config-file = ?file` optional includes). kitty is the fallback if Ghostty misbehaves on the NVIDIA hybrid in M2.

## ADR-013 — Runtimes: mise
**Decision:** mise (official repo) for node/python/pnpm/uv — one tool, per-project versions, fast shims-free activation.

## ADR-014 — Theming engine: palette.toml + templates
**Decision:** One `palette.toml` per theme → `bin/devy-theme` renders `templates/*.tpl` into `~/.config/devy/current/` and live-reloads apps. Apps pick the files up through small links/includes; user files are never overwritten.
**Why:** Same proven idea as Omarchy (`colors.toml` + `default/themed/*.tpl`), but in ~250 lines of stdlib Python with validation and a WCAG contrast check (`devy-theme check`).
**Later (M3):** GTK4/libadwaita accent via `gtk.css`, Qt via qt6ct, btop/nvim/VS Code templates, optional wallpaper-derived palettes (matugen/wallust).

## ADR-015 — Wallpaper: hyprpaper
**Decision:** hyprpaper (first-party, official repo). `swww` was renamed **awww** (Codeberg, 2025-10) and is AUR-only — consider it at M3 for animated transitions.
**Sources:** AUR awww-git; lgfae.com "Renaming swww".

## ADR-016 — Update model
**Decision:** now: `git pull` + numbered run-once migrations (Omarchy `migrations/` style; markers in `~/.local/state/devy/done/`). M6: own pacman repo with meta-packages (`devy-base`, `devy-desktop`, …) so updates come through pacman.

## ADR-017 — Installer (M4)
**Decision:** our own small TUI (bash + `gum`) that writes an **archinstall** JSON config and runs archinstall as the backend, then our `install.sh` in first boot. Omarchy 2.0 did the same ("Configurator front-end to archinstall"). Calamares is too heavy for one maintainer.
Rules: free-space-only dual boot (never shrink Windows), typed confirmation before wiping, VM-only development.

## ADR-018 — ISO (M5)
**Decision:** start with an **online** ISO (small, always installs current packages), offline variant later. Monthly CI rebuild, SHA256 + optional signature, GitHub Releases.

## ADR-019 — Ukrainian support
**Decision:** `kb_layout = "us,ua"`, `kb_variant = ",winkeys"` (Windows-like punctuation), `grp:alt_shift_toggle` + SUPER+ALT+Space. **us must be first** — Hyprland resolves binds against the first layout. Layout shown in Waybar (`hyprland/language`) and on the lock screen (`$LAYOUT`). Locales en_US + uk_UA generated, UI English. Noto fonts (full Cyrillic). `hunspell-uk` is **AUR only** (verified).
**Sources:** wiki configuring/core/binds/keyboard-layouts; AUR hunspell-uk.

## ADR-020 — Name, license, legal
**Decision:** final name **Devy** (confirmed by the user 2026-11-06). Repo will be **public**. License **MIT** (compatible with reusing ideas/code from Omarchy, which is MIT — keep attribution in CREDITS.md).
- Do not put "Arch" in the product name/logo (Arch Linux trademark policy) — "based on Arch Linux" in text is fine. *To verify against the current Arch trademark policy before publishing.*
- NVIDIA drivers: the online ISO downloads them from Arch repos at install time, so we don't redistribute them. Offline ISO → check NVIDIA license terms first (M5).

## ADR-021 — Testing
**Decision:**
1. `tests/lint.sh` (CI): shellcheck, shfmt, Python compile, Waybar JSON, theme validation + contrast, Hyprland Lua mock check, unit tests.
2. `tests/check-packages.sh` (CI, in an `archlinux:latest` container): every manifest entry exists.
3. `tests/smoke.sh`: inside the installed VM/laptop — files, services, session, layouts, notifications.
4. VM host: **VMware Workstation Pro** on the user's Windows 11 (free for personal use, has 3D acceleration for Wayland); `tests/vm/run-qemu.sh` (virtio-vga-gl + virgl, QEMU monitor `screendump` for screenshots) for Linux hosts and future automation.

## ADR-022 — Hyprland realtime priority workaround
**Decision:** `HYPRLAND_NO_RT=1`. Hyprland 0.57 requests realtime priority via rtkit; a slow kernel call can then exceed the RT CPU budget and the kernel kills the compositor (hyprwm/Hyprland#16648). Omarchy applies the same workaround. **Remove when the issue is closed.**

---

## ADR-023 — Browser: Chromium
**Decision:** `chromium` (official repo) with `~/.config/chromium-flags.conf`: native Wayland, `--password-store=gnome-libsecret`.
gnome-keyring is unlocked at TTY login by `pam_gnome_keyring` (wiki snippet), so Chromium/VS Code/gh don't ask for a keyring password.
Hardware video decode on Intel: verify in `chrome://gpu` at M2 before adding any VA-API flags (they change between Chromium releases).
**Sources:** Omarchy `config/chromium-flags.conf`; wiki useful-utilities/uwsm (PAM keyring).

## ADR-024 — Editor: VS Code (Microsoft build)
**Decision:** `visual-studio-code-bin` (AUR) rather than `code` (official repo, Open VSX).
**Why:** the Microsoft marketplace has extensions the TS/Python workflow needs (Pylance, GitHub Copilot, Remote-SSH/Dev Containers); Open VSX lacks some of them.
**Trade-off:** AUR package (supply-chain review needed on updates; it repackages Microsoft's signed tarball). VS Code self-update is off (`update.mode: none`) — paru updates it.
Defaults written only when you have no settings yet: `~/.vscode/argv.json` (`password-store: gnome-libsecret`), font, file-watcher excludes for node_modules/.next/dist.
Neovim stays installed for terminal editing (`$EDITOR`). VS Code theme from the palette = M3.

## ADR-025 — Gaming: Steam + gamemode + MangoHud (default on, `--no-gaming` to skip)
**Decision:** enable `[multilib]`, install **lib32 GPU drivers first** (Intel: lib32-mesa + lib32-vulkan-intel; NVIDIA: lib32-nvidia-utils), **then** `steam gamemode lib32-gamemode mangohud lib32-mangohud`; user added to the `gamemode` group. Skipped in VMs.
**Why the order:** steam depends on the virtual `lib32-vulkan-driver`; with `--noconfirm` pacman picks the first provider (lib32-nvidia-utils) even on non-NVIDIA machines (Omarchy hit this).
**Hybrid laptop:** games run on the RTX 4060 with Steam launch options `prime-run gamemoderun %command%`.
**Sources:** Omarchy `bin/omarchy-install-gaming-steam`, `omarchy-install-gaming-gpu-lib32`.

## ADR-026 — Real-hardware test target: USB SSD
**Decision:** M2 runs Arch+Devy from an external **USB SSD** with its own EFI partition and **systemd-boot** (installs the UEFI fallback path, so F9 boot works without touching Windows). Limine comes with the M4 installer.
Before touching the BIOS: save the **BitLocker recovery key**, disable Fast Startup and Secure Boot. Full steps: docs/USB.md.
**Sources:** ArchWiki "Install Arch Linux on a removable medium".

### Research items → ADR map (spec §11)
| # | Topic | ADR |
|---|---|---|
| 1 | Reference implementations | 001, 003, 006, 014, 016, 017 (Omarchy studied in depth; end-4/HyDE/Caelestia not yet — M3) |
| 2 | Hyprland current state | 002, 022 |
| 3 | Bar | 004 |
| 4 | Hybrid NVIDIA | 009 |
| 5 | Kernel/perf | 005, 007, 008 |
| 6 | Bootloader + snapshots | 006 |
| 7 | Autologin vs greeter | 003 |
| 8 | Installer | 017 |
| 9 | ISO | 018 |
| 10 | Theming | 014 |
| 11 | Dev layer | 011, 012, 013, 023, 024 |
| 12 | Ukrainian | 019 |
| 13 | Update model | 016 |
| 14 | Legal/branding | 020 |
| 15 | Testing | 021 |
