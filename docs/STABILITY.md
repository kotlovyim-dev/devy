# Stability & speed: common Linux problems and how Devy handles them

Rule: every fix has a reason and a source. No "magic" tweaks copied from forums.
Status: **ON** = applied by `install.sh` today · **M2/M4** = planned · **DOC** = manual step, explained here.

## 1. The system breaks after an update
| Problem | Devy fix | Where | Status |
|---|---|---|---|
| A bad update leaves the system unbootable or broken | `snap-pac`: btrfs snapshot **before and after** every pacman transaction; `snapper rollback` | 20-system.sh | ON |
| …and you need to roll back without a working system | Boot a snapshot from the boot menu (Limine + limine-snapper-sync) | M4 installer | M4 |
| New kernel has a regression | `linux-lts` installed as a second boot entry | packages/base.txt | ON |
| After a kernel update, USB sticks/new devices stop working until reboot | `kernel-modules-hook` keeps the running kernel's modules | base.txt | ON |
| "signature is unknown trust" on old installs | `archlinux-keyring` refreshed before every install/upgrade | 10-packages.sh | ON |
| Partial upgrades (`pacman -Sy pkg`) break libraries | installer always does `pacman -Syu` first; `devy-update` is the one update command | 10-packages, devy-update | ON |
| Snapshots silently fill the disk | snapper NUMBER_LIMIT=10 + cleanup timer; `devy-doctor` warns at 85% disk | 20-system, doctor | ON |
| Config breaks after a Hyprland release (0.55→0.57 broke every old config) | Lua config + `tests/lua-check.py` checks every option against the wiki list for the installed version; `devy-doctor` checks versions | tests/, doctor | ON |
| `.pacnew` files forgotten | `devy-update` lists them (`sudo pacdiff`) | devy-update | ON |

## 2. Freezes and slowness
| Problem | Devy fix | Status |
|---|---|---|
| Out of RAM → whole desktop freezes for minutes (classic Linux problem) | zram swap + **systemd-oomd** kills the one runaway app early; apps run as separate units via `uwsm app` so only that app dies | ON |
| zram does nothing because zswap is also on | zswap disabled (tmpfiles) | ON |
| "System limit for number of file watchers reached" (Next.js, Vite, VS Code) | `fs.inotify.max_user_watches=524288`, `max_user_instances=1024` | ON |
| Shutdown hangs 90 s "A stop job is running…" | `DefaultTimeoutStopSec=15s` (system), 10 s (user) | ON |
| Journal grows to many GB | `SystemMaxUse=500M` | ON |
| Docker container logs fill the disk | json-file log rotation 3×10 MB | ON |
| pacman cache grows forever | `paccache.timer` | ON |
| Slow mirrors | `reflector.timer` (PL/DE/UA/CZ, https, sorted by rate) | ON |
| SSD slows down over time | `fstrim.timer` | ON |
| Silent data corruption | monthly `btrfs scrub` | ON |
| Compositor killed under load (Hyprland 0.57 realtime bug #16648) | `HYPRLAND_NO_RT=1` | ON |
| Slow shell | zsh without plugin manager; compinit cache once per day; target < 50 ms (`devy-doctor --perf`) | ON |
| Animations stutter in a VM | VM profile disables blur/shadows/animations | ON |

## 3. Desktop annoyances
| Problem | Devy fix | Status |
|---|---|---|
| Electron apps (VS Code, Discord, Obsidian) blurry or flickering | `ELECTRON_OZONE_PLATFORM_HINT=auto` → native Wayland | ON |
| Qt/GTK apps use X11 by accident | `QT_QPA_PLATFORM=wayland;xcb`, `GDK_BACKEND=wayland,x11,*` (session-wide via uwsm, not /etc/environment) | ON |
| Blurry XWayland apps on scaled screens | `xwayland.force_zero_scaling` | ON |
| Apps maximize themselves and break tiling | `suppress_event = "maximize"` rule | ON |
| "Open file" dialogs open huge and tiled | dialog title rule → float + center | ON |
| Bar/services die and don't come back | waybar, hypridle, hyprpaper, polkit agent are systemd user units → restart on crash | ON |
| Lock screen shows wrong layout, you can't type the password | layout shown on the lock screen (`$LAYOUT`); US is always first | ON |
| Desktop broken → no way to fix it | tty2–6 are always plain shells (Ctrl+Alt+F2) | ON |
| Wi-Fi drops / latency spikes | NetworkManager `wifi.powersave = 2` | ON |

## 4. NVIDIA hybrid laptop (M2 — needs real hardware)
| Problem | Planned fix |
|---|---|
| Black screen / flicker on Wayland | iGPU drives the desktop; nvidia-open-dkms; modeset (default on Arch) |
| Broken resume from suspend | `nvidia-suspend/resume/hibernate` services (ON when NVIDIA detected) |
| Chromium video black on hybrid | no global NVIDIA VA-API/GLX variables (ON) |
| Electron/Chromium stall up to a minute after boot on Intel+NVIDIA (wiki) | test on Victus; workaround from Hyprland wiki if seen |
| dGPU never sleeps → battery drain | check `runtime_status` (doctor shows it), RTD3 settings |
| External monitor on HDMI (often wired to NVIDIA) | dGPU listed second in `AQ_DRM_DEVICES` |

## 5. Secrets and logins
| Problem | Devy fix | Status |
|---|---|---|
| Chromium/VS Code keep asking "unlock keyring" or store passwords in plain text | gnome-keyring unlocked at TTY login via PAM; Chromium and VS Code told to use it | ON |
| Steam pulls the wrong (NVIDIA) 32-bit driver on Intel/AMD machines | lib32 drivers installed before Steam | ON |

## 6. Manual steps (DOC)
- **Clock wrong after booting Windows (dual boot):** set Windows to UTC (Arch wiki recommends this) — in an admin PowerShell:
  `reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f`
- **Windows Fast Startup** locks NTFS disks and can break dual boot: turn it off in Windows power settings.
- **BitLocker:** save the recovery key before changing Secure Boot / boot order (docs/USB.md).
- **Docker and the firewall:** Docker bypasses ufw for published ports. In compose files publish dev services on localhost only: `"127.0.0.1:5432:5432"`.
