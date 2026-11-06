# Package manifests

One package per line, `#` starts a comment. Status tag at the end of each line:

- `[v]` — verified on archlinux.org / the Hyprland wiki on 2026-11-06 (this session)
- `[?]` — standard Arch package, **not** re-checked in this session (archlinux.org was not
  reachable from the build environment). `tests/check-packages.sh` verifies everything.

**2026-11-06: CI (`archlinux:latest` + multilib) confirmed that every package in every list exists**, including all `[?]` entries.
CI re-checks on every push; run `tests/check-packages.sh` locally before changing a manifest.
