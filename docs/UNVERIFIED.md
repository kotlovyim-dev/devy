# What I could not verify (please test manually)

The build environment had **no Arch machine, no VM and no access to archlinux.org/AUR** (network policy).
Everything below was written from current official docs (Hyprland wiki @ 0.57, Omarchy source, ArchWiki), and
the static checks pass — but it has **not been run on Arch**.

## High priority (M1 — in the VM)
1. ~~Package names~~ — **verified by CI on 2026-11-06**: all packages exist in Arch repos/AUR.
2. **Waybar ≥ 0.16.0 in Arch repos.** It was released 2026-11-05 (one day before this work). If Arch still has 0.15,
   workspace clicks won't work → install `waybar-git` from AUR temporarily.
3. **The whole Hyprland session**: config loads with no errors (`hyprctl configerrors` empty), bar, launcher, notifications, lock.
   The Lua config passed a mock-API check against the 0.57 option list, but real Hyprland is the judge.
4. **Absolute-path `require()`** in `hyprland.lua` for `~/.config/devy/current/hypr.lua` etc. — documented by the wiki, not run.
5. **hyprlock variables** (`$text`, `$accent`… from a `source`d file) and **`##` escape** in `placeholder_text`.
6. **Theme links inside symlinked dirs** (`~/.config/waybar/devy-theme.css` etc.): design is meant to work with or without symlink resolution, but check Waybar/Ghostty/fuzzel really load them.
7. **Ghostty live reload** on SIGUSR2 in `devy-theme` (marked UNTESTED in code).
8. **systemd user units** shipped by waybar/hypridle/hyprpaper/hyprpolkitagent and that they start via uwsm's graphical-session.target.
9. **snapper setup** on archinstall's btrfs layout (the `/.snapshots` re-mount dance in 20-system.sh).
10. **systemd-oomd drop-ins** actually kill a runaway process (test: `stress-ng --vm 1 --vm-bytes 120%` in a terminal → only that terminal unit should die).
11. Ukrainian `winkeys` variant + Alt+Shift switch; Cyrillic in all apps.

## M2 (real HP Victus)
12. Hybrid GPU: udev symlinks `/dev/dri/devy-igpu|devy-dgpu`, `AQ_DRM_DEVICES`, `prime-run glxinfo | grep renderer`, `nvidia-smi`.
13. Suspend/resume with NVIDIA, external monitor on HDMI, dGPU runtime sleep (battery).
14. Does the Victus have a **MUX switch** in BIOS? (unknown)
15. Audio (SOF firmware), brightness keys, touchpad gestures, battery readout.
16. Boot time < 10 s and idle RAM < 700 MB — record in PERF.md.

17. Chromium/VS Code: gnome-keyring unlocked by PAM at TTY login (no password prompt), `code-flags.conf` read by the AUR launcher.
18. Steam: multilib enable, lib32 driver order, game runs with `prime-run gamemoderun %command%`.
19. Full M2 checklist: docs/USB.md §5.

## Your choices (2026-11-06)
Name **Devy** · browser **Chromium** · editor **VS Code** · hardware tests from a **USB SSD** · **Steam/gaming on** · repo **public** · no extra helper commands.

## Decisions made without you (easy to change)
- Lock = **SUPER+Esc** (SUPER+L is focus-right in vim keys).
- File manager **Nautilus**, launcher **fuzzel**, terminal **Ghostty**, theme **Graphite** (graphite + one electric-blue accent).
