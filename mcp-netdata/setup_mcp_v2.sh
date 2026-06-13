#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-${SCRIPT_DIR}}"
START_SCRIPT="${START_SCRIPT:-${PROJECT_DIR}/start-netdata-mcp.sh}"
ALIAS_NAME="${ALIAS_NAME:-mcp-restart}"
STATUS_ALIAS_NAME="${STATUS_ALIAS_NAME:-mcp-status}"
LOGS_ALIAS_NAME="${LOGS_ALIAS_NAME:-mcp-logs}"
LOGS_FOLLOW_ALIAS_NAME="${LOGS_FOLLOW_ALIAS_NAME:-mcp-logsf}"
DIAG_ALIAS_NAME="${DIAG_ALIAS_NAME:-mcp-diag}"
JOURNAL_LAST_ALIAS_NAME="${JOURNAL_LAST_ALIAS_NAME:-mcp-jlast}"
JOURNAL_NEW_ALIAS_NAME="${JOURNAL_NEW_ALIAS_NAME:-mcp-jnew}"
SESSION_START_ALIAS_NAME="${SESSION_START_ALIAS_NAME:-mcp-jstart}"
START_ALIAS_NAME="${START_ALIAS_NAME:-mcp-start}"
STOP_ALIAS_NAME="${STOP_ALIAS_NAME:-mcp-stop}"
ALIAS_FILE="${HOME}/.bashrc"
ALIAS_BLOCK_START="# >>> mcp-netdata aliases >>>"
ALIAS_BLOCK_END="# <<< mcp-netdata aliases <<<"
JOURNAL_FILE="${JOURNAL_FILE:-}"

log() {
  printf '[setup_mcp] %s\n' "$*"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '[setup_mcp] missing command: %s\n' "$1" >&2
    exit 1
  fi
}

validate_paths() {
  if [[ "${PROJECT_DIR}" == *\\* || "${START_SCRIPT}" == *\\* ]]; then
    printf '[setup_mcp] Windows/UNC style paths are not supported in this script. Use Linux/WSL paths (e.g. /mnt/c/...).\n' >&2
    exit 1
  fi

  if [[ ! -d "${PROJECT_DIR}" ]]; then
    printf '[setup_mcp] project directory not found: %s\n' "${PROJECT_DIR}" >&2
    exit 1
  fi

  if [[ ! -f "${START_SCRIPT}" ]]; then
    printf '[setup_mcp] start script not found: %s\n' "${START_SCRIPT}" >&2
    exit 1
  fi

  if [[ ! -r "${START_SCRIPT}" ]]; then
    printf '[setup_mcp] start script not readable: %s\n' "${START_SCRIPT}" >&2
    exit 1
  fi
}

rewrite_alias_block() {
  touch "${ALIAS_FILE}"

  if grep -qF "${ALIAS_BLOCK_START}" "${ALIAS_FILE}" 2>/dev/null; then
    log "Replacing existing alias block in ${ALIAS_FILE}"
    local tmp_file
    tmp_file="$(mktemp)"

    awk -v start="${ALIAS_BLOCK_START}" -v end="${ALIAS_BLOCK_END}" '
      $0 == start { in_block = 1; next }
      $0 == end { in_block = 0; next }
      !in_block { print }
    ' "${ALIAS_FILE}" >"${tmp_file}"

    mv "${tmp_file}" "${ALIAS_FILE}"
  else
    log "Adding alias block to ${ALIAS_FILE}"
  fi

  {
    printf '\n%s\n' "${ALIAS_BLOCK_START}"
    printf "mcp_netdata_script='%s'\n" "${START_SCRIPT}"
    printf "mcp_netdata_status() { bash \"\$mcp_netdata_script\" status; }\n"
    printf "mcp_netdata_logs() { bash \"\$mcp_netdata_script\" logs; }\n"
    printf "mcp_netdata_logs_follow() { bash \"\$mcp_netdata_script\" logs; }\n"
    printf "mcp_netdata_start() { bash \"\$mcp_netdata_script\" up; }\n"
    printf "mcp_netdata_stop() { bash \"\$mcp_netdata_script\" down; }\n"
    printf "mcp_netdata_restart() { bash \"\$mcp_netdata_script\" down; bash \"\$mcp_netdata_script\" up; }\n"
    printf "mcp_netdata_diag() { local fail=0; echo '=== DIAG MCP NETDATA (Compose) ==='; echo '[1/3] Compose status'; if bash \"\$mcp_netdata_script\" status; then echo 'OK - status'; else echo 'KO - status'; fail=1; fi; echo '[2/3] Runtime healthcheck'; if bash \"\$mcp_netdata_script\" health; then echo 'OK - healthcheck'; else echo 'KO - healthcheck'; fail=1; fi; echo '[3/3] Container logs'; if bash \"\$mcp_netdata_script\" logs; then echo 'OK - logs'; else echo 'KO - logs'; fail=1; fi; if [[ \$fail -eq 0 ]]; then echo 'RESULTAT GLOBAL: OK'; else echo 'RESULTAT GLOBAL: KO'; fi; return \$fail; }\n"
    printf "mcp_netdata_journal_last() { local journal=\"\${JOURNAL_FILE:-}\"; if [[ -z \"\$journal\" ]]; then echo 'JOURNAL_FILE is not set'; return 1; fi; if [[ ! -f \"\$journal\" ]]; then echo \"Journal introuvable: \$journal\"; return 1; fi; awk '/^### \\[/{prev=last; last=\"\"; printing=1} printing{last=last \$0 ORS} END{if (prev != \"\") printf \"%s\", prev; if (last != \"\") printf \"%s\", last}' \"\$journal\"; }\n"
    printf "mcp_netdata_journal_new() { local journal=\"\${JOURNAL_FILE:-}\"; local now os_name machine; if [[ -z \"\$journal\" ]]; then echo 'JOURNAL_FILE is not set'; return 1; fi; now=\"\$(date '+%%Y-%%m-%%d %%H:%%M')\"; os_name=\"\$(uname -s)\"; machine=\"\$(hostname -s)\"; { echo; echo \"### [\${now}] | OS: \${os_name} | Machine: \${machine}\"; echo \"- Objectif de la session: ____\"; echo \"- Ce que j ai fait (3 lignes max):\"; echo \"  1. ____\"; echo \"  2. ____\"; echo \"  3. ____\"; echo \"- Resultat: OK / Partiel / Echec\"; echo \"- Blocage (si oui): ____\"; echo \"- Prochaine action (1 seule): ____\"; echo \"- Commande cle (optionnel): \\\`____\\\`\"; echo \"- Fichier(s) touches (optionnel): ____\"; } >> \"\$journal\"; echo \"Entree ajoutee dans \$journal\"; }\n"
    printf "mcp_netdata_session_start() { echo 'Regle Ultra Simple: lire les 2 dernieres entrees puis ajouter 1 entree en fin de session.'; echo; mcp_netdata_journal_last || true; echo; echo 'Commande pour preparer une nouvelle entree: mcp-jnew'; }\n"
    printf "alias %s='mcp_netdata_restart'\n" "${ALIAS_NAME}"
    printf "alias %s='mcp_netdata_start'\n" "${START_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_stop'\n" "${STOP_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_status'\n" "${STATUS_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_logs'\n" "${LOGS_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_logs_follow'\n" "${LOGS_FOLLOW_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_diag'\n" "${DIAG_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_journal_last'\n" "${JOURNAL_LAST_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_journal_new'\n" "${JOURNAL_NEW_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_session_start'\n" "${SESSION_START_ALIAS_NAME}"
    printf '%s\n' "${ALIAS_BLOCK_END}"
  } >>"${ALIAS_FILE}"
}

need_cmd bash
need_cmd docker
need_cmd awk
need_cmd mktemp
need_cmd mv
validate_paths

rewrite_alias_block

log "Done. Run: source ${ALIAS_FILE}"
log "Project directory: ${PROJECT_DIR}"
log "Start script: ${START_SCRIPT}"
log "Quick restart alias: ${ALIAS_NAME}"
log "Start alias: ${START_ALIAS_NAME}"
log "Stop alias: ${STOP_ALIAS_NAME}"
log "Status alias: ${STATUS_ALIAS_NAME}"
log "Logs alias: ${LOGS_ALIAS_NAME}"
log "Logs follow alias: ${LOGS_FOLLOW_ALIAS_NAME}"
log "Diag alias: ${DIAG_ALIAS_NAME}"
log "Journal last alias: ${JOURNAL_LAST_ALIAS_NAME}"
log "Journal new alias: ${JOURNAL_NEW_ALIAS_NAME}"
log "Session start alias: ${SESSION_START_ALIAS_NAME}"
