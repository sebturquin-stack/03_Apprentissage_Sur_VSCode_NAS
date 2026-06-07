#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-01_Node-20_MCP}"
SERVICE_NAME="${SERVICE_NAME:-mcp-netdata-watchdog}"
WATCHDOG_SCRIPT="/usr/local/bin/${SERVICE_NAME}.sh"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_FILE="/etc/systemd/system/${SERVICE_NAME}.timer"
ALIAS_NAME="${ALIAS_NAME:-mcp-restart}"
STATUS_ALIAS_NAME="${STATUS_ALIAS_NAME:-mcp-status}"
LOGS_ALIAS_NAME="${LOGS_ALIAS_NAME:-mcp-logs}"
LOGS_FOLLOW_ALIAS_NAME="${LOGS_FOLLOW_ALIAS_NAME:-mcp-logsf}"
DIAG_ALIAS_NAME="${DIAG_ALIAS_NAME:-mcp-diag}"
START_ALIAS_NAME="${START_ALIAS_NAME:-mcp-start}"
STOP_ALIAS_NAME="${STOP_ALIAS_NAME:-mcp-stop}"
ALIAS_FILE="${HOME}/.bashrc"
ALIAS_BLOCK_START="# >>> mcp-netdata aliases >>>"
ALIAS_BLOCK_END="# <<< mcp-netdata aliases <<<"

log() {
  printf '[setup_mcp] %s\n' "$*"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '[setup_mcp] missing command: %s\n' "$1" >&2
    exit 1
  fi
}

need_cmd docker
need_cmd sudo
need_cmd systemctl
need_cmd tee
need_cmd awk
need_cmd mktemp
need_cmd mv

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
    printf "mcp_netdata_status() { echo \"=== docker inspect (%s) ===\"; docker inspect %s; echo; echo \"=== watchdog service (%s.service) ===\"; sudo systemctl status %s.service --no-pager; echo; echo \"=== watchdog timer (%s.timer) ===\"; sudo systemctl status %s.timer --no-pager; }\n" "${CONTAINER_NAME}" "${CONTAINER_NAME}" "${SERVICE_NAME}" "${SERVICE_NAME}" "${SERVICE_NAME}" "${SERVICE_NAME}"
    printf "mcp_netdata_logs() { sudo journalctl -u %s.service -u %s.timer --no-pager \"\$@\"; }\n" "${SERVICE_NAME}" "${SERVICE_NAME}"
    printf "mcp_netdata_diag() { set -o pipefail; local fail=0; echo '=== DIAG MCP NETDATA EXPRESS ==='; echo '[1/4] Montage CIFS /mnt/infradata'; if mountpoint /mnt/infradata >/dev/null 2>&1; then echo 'OK - /mnt/infradata monte'; else echo 'KO - /mnt/infradata non monte'; fail=1; fi; echo '[2/4] Conteneur %s'; if docker ps --format '{{.Names}}' | grep -qx '%s'; then echo 'OK - conteneur en cours'; else echo 'KO - conteneur arrete/absent'; fail=1; fi; echo '[3/4] Presence du script MCP dans le bind mount'; if docker exec %s test -f /app/netdata-mcp.js; then echo 'OK - /app/netdata-mcp.js present'; else echo 'KO - /app/netdata-mcp.js absent'; fail=1; fi; echo '[4/4] Smoke test runtime MCP (3s max)'; timeout 3s docker exec -i %s node /app/netdata-mcp.js </dev/null >/tmp/mcp_diag_out.log 2>/tmp/mcp_diag_err.log; local ec=\$?; if grep -q \"Cannot find module '/app/netdata-mcp.js'\" /tmp/mcp_diag_err.log; then echo 'KO - module introuvable dans le conteneur'; fail=1; elif [[ \$ec -eq 0 || \$ec -eq 124 ]]; then echo \"OK - runtime MCP demarre (exit=\$ec)\"; else echo \"KO - runtime MCP en erreur (exit=\$ec)\"; tail -n 20 /tmp/mcp_diag_err.log; fail=1; fi; if [[ \$fail -eq 0 ]]; then echo 'RESULTAT GLOBAL: OK'; else echo 'RESULTAT GLOBAL: KO'; fi; return \$fail; }\n" "${CONTAINER_NAME}" "${CONTAINER_NAME}" "${CONTAINER_NAME}" "${CONTAINER_NAME}"
    printf "alias %s='docker restart %s && sudo systemctl start %s.service'\n" "${ALIAS_NAME}" "${CONTAINER_NAME}" "${SERVICE_NAME}"
    printf "alias %s='docker start %s && sudo systemctl start %s.service'\n" "${START_ALIAS_NAME}" "${CONTAINER_NAME}" "${SERVICE_NAME}"
    printf "alias %s='docker stop %s && sudo systemctl stop %s.service'\n" "${STOP_ALIAS_NAME}" "${CONTAINER_NAME}" "${SERVICE_NAME}"
    printf "alias %s='mcp_netdata_status'\n" "${STATUS_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_logs -n 200'\n" "${LOGS_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_logs -f -n 200'\n" "${LOGS_FOLLOW_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_diag'\n" "${DIAG_ALIAS_NAME}"
    printf '%s\n' "${ALIAS_BLOCK_END}"
  } >>"${ALIAS_FILE}"
}

log "Installing watchdog script: ${WATCHDOG_SCRIPT}"
sudo tee "${WATCHDOG_SCRIPT}" >/dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="\${1:-${CONTAINER_NAME}}"

if ! command -v docker >/dev/null 2>&1; then
  logger -t ${SERVICE_NAME} "docker not found"
  exit 0
fi

if ! docker inspect "\${CONTAINER_NAME}" >/dev/null 2>&1; then
  logger -t ${SERVICE_NAME} "container \${CONTAINER_NAME} not found"
  exit 0
fi

running="\$(docker inspect -f '{{.State.Running}}' "\${CONTAINER_NAME}" 2>/dev/null || echo false)"
if [[ "\${running}" != "true" ]]; then
  logger -t ${SERVICE_NAME} "container \${CONTAINER_NAME} is stopped, starting"
  docker start "\${CONTAINER_NAME}" >/dev/null || logger -t ${SERVICE_NAME} "failed to start \${CONTAINER_NAME}"
fi
EOF
sudo chmod 755 "${WATCHDOG_SCRIPT}"

log "Installing systemd service: ${SERVICE_FILE}"
sudo tee "${SERVICE_FILE}" >/dev/null <<EOF
[Unit]
Description=MCP Netdata Docker Watchdog
After=docker.service network-online.target
Wants=docker.service

[Service]
Type=oneshot
ExecStart=${WATCHDOG_SCRIPT} ${CONTAINER_NAME}

[Install]
WantedBy=multi-user.target
EOF

log "Installing systemd timer: ${TIMER_FILE}"
sudo tee "${TIMER_FILE}" >/dev/null <<EOF
[Unit]
Description=Run MCP Netdata Watchdog every minute

[Timer]
OnBootSec=45s
OnUnitActiveSec=60s
AccuracySec=10s
Persistent=true
Unit=${SERVICE_NAME}.service

[Install]
WantedBy=timers.target
EOF

log "Reloading systemd and enabling timer"
sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}.timer"
sudo systemctl start "${SERVICE_NAME}.service"

rewrite_alias_block

log "Done. Run: source ${ALIAS_FILE}"
log "Check timer: sudo systemctl status ${SERVICE_NAME}.timer --no-pager"
log "Quick restart: ${ALIAS_NAME}"
log "Start alias: ${START_ALIAS_NAME}"
log "Stop alias: ${STOP_ALIAS_NAME}"
log "Status alias: ${STATUS_ALIAS_NAME}"
log "Logs alias: ${LOGS_ALIAS_NAME}"
log "Logs follow alias: ${LOGS_FOLLOW_ALIAS_NAME}"
log "Diag alias: ${DIAG_ALIAS_NAME}"
