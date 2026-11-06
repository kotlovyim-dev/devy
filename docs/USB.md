# Testing Devy on the HP Victus from a USB drive (M2)

Goal: run Devy on the real laptop **without touching Windows or the internal disk**.
Unplug the USB drive → the laptop boots Windows exactly as before.

## What you need
- **Target drive: a USB 3.x SSD, 64 GB or more.** A normal USB flash stick works, but it is slow and wears out fast
  (Docker + pacman write a lot). An external NVMe/SATA SSD in a USB-C enclosure is ideal.
- A second small USB stick (or Ventoy) with the Arch ISO.

## 1. Prepare Windows (do not skip)
1. **Save your BitLocker recovery key.** Changing Secure Boot can make Windows ask for it on the next boot.
   Find it at https://aka.ms/myrecoverykey (Microsoft account) or in an admin terminal: `manage-bde -protectors -get C:`.
   Write it down / photo on your phone.
2. Turn off **Fast Startup**: Control Panel → Power Options → "Choose what the power buttons do" → uncheck *Turn on fast startup*.
3. Optional but recommended: make Windows keep the clock in UTC (see docs/STABILITY.md §5).

## 2. BIOS (HP: press **F10** at power-on; boot menu is **F9**)
- **Secure Boot: Disabled** (Devy does not sign its bootloader yet — that is M6). Keep UEFI mode.
- Leave the internal disk and its boot entries alone.

## 3. Install Arch on the USB SSD
Boot the Arch ISO stick (F9), then **identify the disks**:
```bash
lsblk -o NAME,SIZE,MODEL,TRAN
```
`nvme0n1` = the internal Windows disk — **never select it**. Your target shows `TRAN = usb` and the SSD's size/model.

Run `archinstall` with the settings from docs/VM.md, plus:
| Setting | Value for the USB install |
|---|---|
| Disk | **only the USB SSD** (check size + model twice), wipe it, btrfs, default subvolumes, zstd |
| Bootloader | **systemd-boot** for now: it also installs the UEFI fallback `EFI/BOOT/BOOTX64.EFI`, so the drive boots from F9 even without a firmware entry. (Limine arrives with the M4 installer.) |
| Kernel | linux-zen + linux-lts |

The bootloader goes to the EFI partition **on the USB drive** (archinstall creates it on the selected disk), so Windows' boot partition is not changed.

After the install, before rebooting, check the fallback file exists:
```bash
ls /mnt/boot/EFI/BOOT/BOOTX64.EFI
```

### Optional: make the drive boot on other PCs too
ArchWiki "Install Arch Linux on a removable medium": in `/etc/mkinitcpio.conf` move `block` (and `keyboard`)
**before** `autodetect` in the `HOOKS=(...)` line, then `sudo mkinitcpio -P`. This keeps disk drivers for other machines in the image.

## 4. Install Devy
Boot the USB SSD (F9 → the USB drive), log in, then:
```bash
sudo pacman -S --needed git
git clone https://github.com/<you>/devy ~/.local/share/devy
cd ~/.local/share/devy
bash install.sh --dry-run
bash install.sh            # profile: laptop (auto); NVIDIA hybrid + Steam included
reboot
```

## 5. M2 checklist (write results in docs/PERF.md and docs/UNVERIFIED.md)
- [ ] `devy-doctor --perf` — no failures; boot time and idle RAM recorded
- [ ] `bash tests/smoke.sh` passes
- [ ] `prime-run glxinfo | grep "OpenGL renderer"` shows the RTX 4060; without prime-run it shows Intel (`mesa-utils` package)
- [ ] `nvidia-smi` works; after 1 min idle `cat /sys/class/drm/card*/device/power/runtime_status` shows the dGPU `suspended`
- [ ] Suspend + resume (lid close) 3 times, the screen comes back
- [ ] HDMI external monitor
- [ ] Brightness / volume / mic-mute keys, touchpad gestures, Bluetooth, Wi-Fi, battery in the bar
- [ ] Chromium: YouTube 1080p60 plays smoothly; `chrome://gpu` shows "Video Decode: Hardware accelerated"
- [ ] VS Code: GitHub sign-in survives a reboot (keyring works)
- [ ] Steam: one game with launch options `prime-run gamemoderun %command%`, MangoHud shows the NVIDIA GPU
- [ ] Is there a **MUX / "discrete only"** option in the BIOS? (note it)
