#!/usr/bin/env bash
# Boot a UEFI QEMU/KVM VM for testing Devy (Linux host). For a Windows host, see docs/VM.md
# (VMware Workstation). GPU: virtio-vga-gl + virgl so Hyprland gets real OpenGL.
#
#   tests/vm/run-qemu.sh install path/to/archlinux.iso   # first boot from the ISO
#   tests/vm/run-qemu.sh run                             # boot the installed disk
#   tests/vm/run-qemu.sh screenshot out.ppm              # grab the screen (visual check)
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
work="$here/work"
disk="$work/devy.qcow2"
vars="$work/OVMF_VARS.4m.fd"
monitor="$work/monitor.sock"
mkdir -p "$work"

ovmf_code=""
for f in /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd; do
  [[ -f $f ]] && ovmf_code="$f" && break
done
[[ -n $ovmf_code ]] || {
  echo "OVMF not found (Arch: pacman -S edk2-ovmf)" >&2
  exit 1
}
if [[ ! -f $vars ]]; then
  cp "$(dirname "$ovmf_code")/$(basename "$ovmf_code" | sed 's/CODE/VARS/')" "$vars"
fi
[[ -f $disk ]] || qemu-img create -f qcow2 "$disk" 40G

# shellcheck disable=SC2054  # commas are QEMU option syntax, not array separators
common=(
  -enable-kvm -machine q35 -cpu host -smp 4 -m 6G
  -drive "if=pflash,format=raw,readonly=on,file=$ovmf_code"
  -drive "if=pflash,format=raw,file=$vars"
  -drive "file=$disk,if=virtio,discard=unmap"
  -device virtio-vga-gl -display gtk,gl=on
  -audiodev pipewire,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0
  -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22
  -monitor "unix:$monitor,server,nowait"
)

case "${1:-}" in
  install)
    iso="${2:?usage: run-qemu.sh install archlinux.iso}"
    exec qemu-system-x86_64 "${common[@]}" -cdrom "$iso" -boot order=d
    ;;
  run) exec qemu-system-x86_64 "${common[@]}" ;;
  screenshot)
    out="${2:-$work/screen.ppm}"
    echo "screendump $out" | socat - "UNIX-CONNECT:$monitor" >/dev/null
    echo "saved $out"
    ;;
  *)
    sed -n '2,8p' "$0"
    exit 1
    ;;
esac
