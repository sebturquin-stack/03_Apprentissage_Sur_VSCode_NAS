#!/usr/bin/env bash
set -euo pipefail

MOUNT_POINT="/mnt/infradata"
DRIVE_LETTER="Z:"
RETRY_COUNT=3
RETRY_DELAY_SECONDS=2

fail() {
  echo "Erreur: $1" >&2
  exit 1
}

if ! grep -qi microsoft /proc/version 2>/dev/null; then
  fail "ce script doit etre execute dans WSL"
fi

mkdir_ok=true
sudo -n mkdir -p "$MOUNT_POINT" >/dev/null 2>&1 || mkdir_ok=false

if mountpoint -q "$MOUNT_POINT"; then
  sudo -n umount "$MOUNT_POINT" >/dev/null 2>&1 || mkdir_ok=false
fi

attempt=1
while (( attempt <= RETRY_COUNT )); do
  if [[ "$mkdir_ok" == true ]] && sudo -n mount -t drvfs "$DRIVE_LETTER" "$MOUNT_POINT" >/dev/null 2>&1; then
    exit 0
  fi

  if (( attempt < RETRY_COUNT )); then
    sleep "$RETRY_DELAY_SECONDS"
  fi

  attempt=$((attempt + 1))
done

fail "echec du montage $DRIVE_LETTER vers $MOUNT_POINT apres $RETRY_COUNT tentatives"
