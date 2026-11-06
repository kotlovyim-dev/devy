# Devy

A fast, stable, good-looking **Arch Linux + Hyprland** setup for web development.
Not a new distro built from scratch: an opinionated, reproducible layer on top of Arch.

> Status: **M1 skeleton** — static checks pass, **not yet run on real Arch**. Start in a VM: [docs/VM.md](docs/VM.md), then a USB SSD on real hardware: [docs/USB.md](docs/USB.md).
> What still needs a human test: [docs/UNVERIFIED.md](docs/UNVERIFIED.md).

## What you get
- **Hyprland 0.57** (Lua config) started by **uwsm** — every app is its own systemd unit.
- One design system: `themes/<name>/palette.toml` → bar, launcher, notifications, lock screen, terminal, borders, GTK. Switch live: `devy-theme graphite`.
- **Stability first:** btrfs snapshots on every update, LTS fallback kernel, zram + systemd-oomd (no RAM freezes), fast shutdown, bounded logs — see [docs/STABILITY.md](docs/STABILITY.md).
- Dev-ready: VS Code, Chromium, zsh + starship, mise (Node LTS, Python, pnpm, uv), Docker + compose, lazygit, gh, Neovim, Claude Code CLI.
- Gaming: Steam + gamemode + MangoHud, games on the NVIDIA GPU with `prime-run` (skip with `--no-gaming`).
- English + Ukrainian keyboard (Alt+Shift), layout shown in the bar and on the lock screen.

## Quick start (fresh Arch, btrfs, minimal profile)
```bash
git clone <repo> ~/.local/share/devy && cd ~/.local/share/devy
bash install.sh --dry-run     # see every action first
bash install.sh               # profile auto-detected: vm | laptop | desktop
```
Options: `--yes` (no questions), `--profile vm`, `--no-gaming`, `--only 40`, `--skip 10,50`. Re-running is safe (idempotent).
Log: `~/.local/state/devy/install.log`.

## Daily commands
| Command | What it does |
|---|---|
| `devy-update` | pacman + AUR update with automatic snapshots, then a short report |
| `devy-doctor [--perf]` | health check (versions, failed units, zram, GPU, theme) |
| `devy-theme <name>` / `list` / `check` | apply / list / validate themes |
| `devy-menu power\|clipboard\|theme\|dnd` | small menus (also on keybinds) |

Keybindings: [docs/KEYBINDS.md](docs/KEYBINDS.md). Your own Hyprland overrides go in `~/.config/devy/user.lua` (never touched by updates).

## Layout
```
install.sh  install/NN-*.sh   installer steps (preflight, packages, system, gpu, desktop, dev, theme)
packages/*.txt               package manifests (verified status per line)
config/                      app configs, symlinked into ~/.config
themes/<name>/               palette.toml + templates/*.tpl + wallpapers/
bin/devy-*                   commands
tests/                       lint.sh, unit.sh, lua-check.py, check-packages.sh, smoke.sh, vm/run-qemu.sh
docs/                        DECISIONS (ADRs), STABILITY, VM, UNVERIFIED, KEYBINDS, PERF, CREDITS
```

## Development
```bash
pip install shellcheck-py shfmt-py lupa
bash tests/lint.sh           # everything CI runs
```
CI: `.github/workflows/lint.yml` runs lint and checks every package name in an Arch container.

## Roadmap
M1 VM desktop → M2 HP Victus (hybrid NVIDIA) → M3 theming polish + 2nd theme → M4 TUI installer (LUKS2, Limine, rollback) → M5 ISO + CI releases → M6 own pacman repo.

## Contributing
Issues and PRs are welcome. Before a PR: `bash tests/lint.sh` must be green, new packages need a status tag in `packages/*.txt`, and anything not tested on real hardware is marked `UNTESTED` in code and in docs/UNVERIFIED.md.

License: MIT. Credits: [docs/CREDITS.md](docs/CREDITS.md). Devy is not affiliated with Arch Linux or Hyprland.
