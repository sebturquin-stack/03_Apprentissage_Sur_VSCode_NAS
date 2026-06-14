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

notify_windows_failure() {
  local message="$1"

  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "\
      \$wshell = New-Object -ComObject WScript.Shell; \
      \$wshell.Popup('$message', 8, 'MCP Boot Error', 0x10) | Out-Null\
    " >/dev/null 2>&1 || true
  fi
}

fail() {
  local message="$1"
  echo "Erreur: $message" >&2
  log_line "ECHEC | $message"
  notify_windows_failure "$message"
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

  while (( attempt <= MOUNT_RETRY_COUNT )); do
    if sudo -n bash "$MOUNT_SCRIPT" >/dev/null 2>&1 && [[ -d "$NAS_ROOT" ]]; then
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

compose_output=""
if ! compose_output="$(cd "$PROJECT_DIR" && docker compose up -d 2>&1)"; then
  fail "docker compose up -d a echoue: $compose_output"
fi

log_line "OK | NAS accessible et docker compose up -d execute"
