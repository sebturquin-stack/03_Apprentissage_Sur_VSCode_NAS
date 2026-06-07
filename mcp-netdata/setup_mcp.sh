1-nan
0-nan
0-nan
0-nan
0-nan
1-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
1-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan
0-nan

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
    printf "alias %s='docker restart %s && sudo systemctl start %s.service'\n" "${ALIAS_NAME}" "${CONTAINER_NAME}" "${SERVICE_NAME}"
    printf "alias %s='docker start %s && sudo systemctl start %s.service'\n" "${START_ALIAS_NAME}" "${CONTAINER_NAME}" "${SERVICE_NAME}"
    printf "alias %s='docker stop %s && sudo systemctl stop %s.service'\n" "${STOP_ALIAS_NAME}" "${CONTAINER_NAME}" "${SERVICE_NAME}"
    printf "alias %s='mcp_netdata_status'\n" "${STATUS_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_logs -n 200'\n" "${LOGS_ALIAS_NAME}"
    printf "alias %s='mcp_netdata_logs -f -n 200'\n" "${LOGS_FOLLOW_ALIAS_NAME}"
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
