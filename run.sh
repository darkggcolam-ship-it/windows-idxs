#!/usr/bin/env bash
set -e

### CONFIG ###
ISO_URL="https://onedrive-cf.cloudmini.net/api/raw?path=/Public/Vultr/M%E1%BB%9Bi%201909/Update%200907/Win10_ltsc_x64FRE_en-us.iso"
ISO_FILE="win11-gamer.iso"

DISK_FILE="win11.qcow2"
DISK_SIZE="64G"

RAM="8G"
CORES="4"
THREADS="2"

VNC_DISPLAY=":0"   # 5900
RDP_PORT="3389"

### CHECK KVM ###
[ -e /dev/kvm ] || { echo "❌ no /dev/kvm"; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo "❌ no qemu"; exit 1; }

### ISO ###
[ -f "${ISO_FILE}" ] || wget -O "${ISO_FILE}" "${ISO_URL}"

### DISK ###
[ -f "${DISK_FILE}" ] || qemu-img create -f qcow2 "${DISK_FILE}" "${DISK_SIZE}"

echo "🚀 Windows 11 KVM BIOS + SCSI (LSI)"
echo "🖥️  VNC : localhost:5900"
echo "🖧  RDP : localhost:3389"

qemu-system-x86_64 \
  -enable-kvm \
  -machine pc,accel=kvm \
  -cpu host,hv-relaxed,hv-vapic,hv-spinlocks=0x1fff \
  -smp sockets=1,cores=${CORES},threads=${THREADS} \
  -m ${RAM} \
  -mem-prealloc \
  -rtc base=localtime \
  -boot menu=on \
  \
  -device lsi53c895a,id=scsi0 \
  -drive file=${DISK_FILE},if=none,format=qcow2,id=hd0 \
  -device scsi-hd,drive=hd0,bus=scsi0.0 \
  \
  -cdrom ${ISO_FILE} \
  \
  -netdev user,id=net0,hostfwd=tcp::${RDP_PORT}-:3389 \
  -device e1000,netdev=net0 \
  \
  -display none \
  -vnc ${VNC_DISPLAY} \
  -usb -device usb-tablet
