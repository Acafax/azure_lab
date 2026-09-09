#!/usr/bin/env bash

set -euo pipefail

volume_group="data_vg"
mirror_lv="lv_mirror"
stripe_lv="lv_stripe"
mirror_mount="/mnt/lvm/mirror"
stripe_mount="/mnt/lvm/stripe"
disks=(
  "/dev/disk/azure/scsi1/lun0"
  "/dev/disk/azure/scsi1/lun1"
  "/dev/disk/azure/scsi1/lun2"
)

for disk in "${disks[@]}"; do
  for _ in {1..30}; do
    [[ -b "$disk" ]] && break
    sleep 2
  done

  if [[ ! -b "$disk" ]]; then
    printf 'Expected data disk %s was not found.\n' "$disk" >&2
    exit 1
  fi
done

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y lvm2

if ! vgs "$volume_group" >/dev/null 2>&1; then
  pvcreate -y "${disks[@]}"
  vgcreate "$volume_group" "${disks[@]}"
fi

if ! lvs "$volume_group/$mirror_lv" >/dev/null 2>&1; then
  lvcreate --type raid1 --mirrors 1 --size 2G --name "$mirror_lv" "$volume_group"
fi

if ! lvs "$volume_group/$stripe_lv" >/dev/null 2>&1; then
  lvcreate --stripes 3 --stripesize 64 --size 6G --name "$stripe_lv" "$volume_group"
fi

mirror_device="/dev/$volume_group/$mirror_lv"
stripe_device="/dev/$volume_group/$stripe_lv"

for device in "$mirror_device" "$stripe_device"; do
  if ! blkid "$device" >/dev/null 2>&1; then
    mkfs.ext4 "$device"
  fi
done

install -d -m 0755 "$mirror_mount" "$stripe_mount"

for device_and_mount in "$mirror_device:$mirror_mount" "$stripe_device:$stripe_mount"; do
  device="${device_and_mount%%:*}"
  mount_path="${device_and_mount##*:}"
  uuid="$(blkid -s UUID -o value "$device")"

  if ! grep -qE "^[[:space:]]*UUID=$uuid[[:space:]]" /etc/fstab; then
    printf 'UUID=%s %s ext4 defaults,nofail 0 2\n' "$uuid" "$mount_path" >> /etc/fstab
  fi

  if ! mountpoint -q "$mount_path"; then
    mount "$mount_path"
  fi
done

dd if=/dev/zero of="$mirror_mount/testfile" bs=1G count=1 oflag=direct status=progress
dd if="$mirror_mount/testfile" of=/dev/null bs=1G count=1 iflag=direct status=progress
dd if=/dev/zero of="$stripe_mount/testfile" bs=1G count=1 oflag=direct status=progress
dd if="$stripe_mount/testfile" of=/dev/null bs=1G count=1 iflag=direct status=progress
