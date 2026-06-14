#!/usr/bin/env bash
set -euo pipefail

NAS_HOST="192.168.8.220"
NAS_SHARE="InfraData"
NAS_USER="SebAdminNAS"
NAS_PASSWORD="Cayenn*"
MOUNT_POINT="/mnt/infradata"

fail() {
  echo "Erreur: $1" >&2
  exit 1
}

log() {
  echo "[mount_nas] $1"
}

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo -n"
fi

if [[ "${EUID}" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo introuvable: execution non-root impossible"
  fi
  if ! sudo -n true >/dev/null 2>&1; then
    fail "sudo -n indisponible: configurer sudo sans mot de passe pour ce script"
  fi
fi

if ! command -v mount >/dev/null 2>&1; then
  fail "commande mount introuvable"
fi

if ! command -v mountpoint >/dev/null 2>&1; then
  fail "commande mountpoint introuvable"
fi

if ! command -v mount.cifs >/dev/null 2>&1; then
  fail "mount.cifs introuvable: installer le paquet cifs-utils"
fi

# 1) Creation du point de montage
${SUDO} mkdir -p "$MOUNT_POINT" || fail "impossible de creer $MOUNT_POINT"

# 2) Demontage propre (idempotent)
${SUDO} umount "$MOUNT_POINT" >/dev/null 2>&1 || true

# 3) Montage CIFS natif
MOUNT_SOURCE="//${NAS_HOST}/${NAS_SHARE}"
MOUNT_OPTS="username=${NAS_USER},password=${NAS_PASSWORD},vers=3.0,iocharset=utf8,uid=1000,gid=1000"

${SUDO} mount -t cifs "$MOUNT_SOURCE" "$MOUNT_POINT" -o "$MOUNT_OPTS" || fail "echec du montage CIFS ${MOUNT_SOURCE} vers ${MOUNT_POINT}"

# 4) Verification du montage
if mountpoint -q "$MOUNT_POINT"; then
  log "SUCCES: ${MOUNT_SOURCE} monte sur ${MOUNT_POINT}"
  exit 0
fi

# 5) Message clair en cas d echec
fail "montage non confirme sur ${MOUNT_POINT}"
