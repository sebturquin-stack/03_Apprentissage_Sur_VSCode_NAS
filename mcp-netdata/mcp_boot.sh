#!/usr/bin/env bash
set -u

NAS_ROOT="/mnt/infradata/07_VSCode_Workspaces"
PROJECT_DIR="/mnt/infradata/07_VSCode_Workspaces/03_Apprentissage_Sur_VSCode/mcp-netdata"
MOUNT_SCRIPT="$HOME/mount_nas.sh"
LOG_FILE="$HOME/mcp_boot.log"
MOUNT_RETRY_COUNT=3
MOUNT_RETRY_DELAY_SECONDS=3

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_line() {
  printf '%s | %s\n' "$(timestamp)" "$1" >>"$LOG_FILE"
}

run_mount_script() {
  if [[ "${EUID}" -eq 0 ]]; then
    bash "$MOUNT_SCRIPT"
  else
    sudo -n bash "$MOUNT_SCRIPT"
  fi
}

fail() {
  local message="$1"
  echo "Erreur: $message" >&2
  log_line "ECHEC | $message"
  if command -v logger >/dev/null 2>&1; then
    logger -t mcp_boot "$message" || true
  fi
  exit 1
}

ensure_nas_available() {
  local attempt=1

  if [[ -d "$NAS_ROOT" ]]; then
    return 0
  fi

  if [[ ! -f "$MOUNT_SCRIPT" ]]; then
    fail "Script de montage introuvable: $MOUNT_SCRIPT"
  fi

  if [[ "${EUID}" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      fail "sudo introuvable: execution non-root impossible pour le montage NAS"
    fi
    if ! sudo -n true >/dev/null 2>&1; then
      fail "sudo -n indisponible: configurer sudo sans mot de passe pour ce script"
    fi
  fi

  while (( attempt <= MOUNT_RETRY_COUNT )); do
    if run_mount_script >/dev/null 2>&1 && [[ -d "$NAS_ROOT" ]]; then
      log_line "INFO | Montage NAS reussi a la tentative $attempt"
      return 0
    fi

    if (( attempt < MOUNT_RETRY_COUNT )); then
      log_line "INFO | Montage NAS echoue a la tentative $attempt, nouvelle tentative"
      sleep "$MOUNT_RETRY_DELAY_SECONDS"
    fi

    attempt=$((attempt + 1))
  done

  return 1
}

log_line "INFO | Demarrage mcp_boot"

if ! ensure_nas_available; then
  fail "NAS inaccessible: $NAS_ROOT absent apres $MOUNT_RETRY_COUNT tentatives de montage"
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  fail "Dossier projet introuvable: $PROJECT_DIR"
fi

if ! command -v docker >/dev/null 2>&1; then
  fail "docker introuvable dans ce shell"
fi

if ! docker compose version >/dev/null 2>&1; then
  fail "plugin docker compose indisponible"
fi

compose_output=""
if ! compose_output="$(cd "$PROJECT_DIR" && docker compose up -d 2>&1)"; then
  fail "docker compose up -d a echoue: $compose_output"
fi

log_line "OK | NAS accessible et docker compose up -d execute"
