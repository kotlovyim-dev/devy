# Testing Devy in a VM

Never test the installer on your real disk. Use a VM first (M1), then a spare disk/USB (M2).

## Option A — VMware Workstation Pro on Windows 11 (recommended for you)
Free for personal use, has 3D acceleration that Hyprland needs.

1. Download the Arch ISO from archlinux.org/download (check the SHA256).
2. New VM → "Linux, Other Linux 6.x kernel 64-bit", **4 CPUs, 6–8 GB RAM, 40 GB disk**.
3. VM Settings → Options → Advanced → Firmware: **UEFI**.
4. Display → **Accelerate 3D graphics** ON, graphics memory 2–4 GB.
5. Boot the ISO and run `archinstall` (next section).

## Option B — QEMU/KVM on a Linux host
```bash
tests/vm/run-qemu.sh install ~/Downloads/archlinux-x86_64.iso   # first boot
tests/vm/run-qemu.sh run                                        # later boots
tests/vm/run-qemu.sh screenshot shot.ppm                         # visual check
```
Uses UEFI (OVMF) and `virtio-vga-gl` so Hyprland has real OpenGL (virgl). SSH: `ssh -p 2222 user@localhost`.

## archinstall settings (what Devy expects)
| Setting | Value |
|---|---|
| Disk layout | Wipe the **virtual** disk, **btrfs**, *use default subvolume structure* (`@`, `@home`, `@log`, `@pkg`, `@.snapshots`), **compression: zstd** |
| Swap | zram or off (Devy writes its own zram config either way) — **no swap partition** |
| Bootloader | Limine if offered (snapshot boot menu later), otherwise systemd-boot |
| Kernel | `linux-zen` (+ `linux-lts`) |
| Profile | **Minimal** (no desktop — Devy installs it) |
| Audio | Pipewire |
| Network | NetworkManager |
| User | your user with sudo (wheel) |
| Timezone | Europe/Kyiv |

## Install Devy
After the first boot, log in on the TTY:
```bash
sudo pacman -S --needed git
git clone <your Devy repo URL> ~/.local/share/devy
cd ~/.local/share/devy
bash install.sh --dry-run     # read what it will do
bash install.sh               # do it (profile is auto-detected: vm)
reboot
```
Log in on tty1 → Hyprland starts. Open a terminal (SUPER+Enter):
```bash
bash ~/.local/share/devy/tests/smoke.sh
devy-doctor --perf
bash ~/.local/share/devy/install.sh   # second run must change nothing (idempotency check)
```
