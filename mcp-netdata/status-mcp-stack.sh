#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SOURCE_DIR:-$SCRIPT_DIR}"
COMPOSE_FILE="${COMPOSE_FILE:-$SOURCE_DIR/docker-compose.yml}"

MCP_SERVICE="${MCP_SERVICE:-netdata-mcp}"
NETDATA_SERVICE="${NETDATA_SERVICE:-netdata}"

MCP_CONTAINER_STATUS="FAIL"
NETDATA_CONTAINER_STATUS="FAIL"
NETDATA_HEALTH_STATUS="FAIL"
MCP_TO_NETDATA_STATUS="FAIL"
HTTP_STATUS="N/A"

failures=0

log() {
    printf '%s\n' "$*"
}

require_tools() {
    if ! command -v docker >/dev/null 2>&1; then
        log "ERROR: docker introuvable dans PATH"
        exit 1
    fi

    if ! docker compose version >/dev/null 2>&1; then
        log "ERROR: docker compose indisponible"
        exit 1
    fi
}

require_paths() {
    if [[ "$SOURCE_DIR" == *\\* || "$COMPOSE_FILE" == *\\* ]]; then
        log "ERROR: chemins Windows/UNC detectes. Utiliser un chemin Linux/WSL2 (ex: /mnt/c/...)."
        exit 1
    fi

    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log "ERROR: compose file introuvable: $COMPOSE_FILE"
        exit 1
    fi
}

compose_cmd() {
    docker compose -f "$COMPOSE_FILE" --project-directory "$SOURCE_DIR" "$@"
}

service_container_id() {
    local service="$1"
    compose_cmd ps -q "$service" 2>/dev/null | head -n 1
}

is_running() {
    local cid="$1"
    docker inspect "$cid" --format '{{.State.Running}}' 2>/dev/null | grep -qi '^true$'
}

is_healthy() {
    local cid="$1"
    docker inspect "$cid" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' 2>/dev/null | grep -qi '^healthy$'
}

check_containers_running() {
    local mcp_cid=""
    local netdata_cid=""

    mcp_cid="$(service_container_id "$MCP_SERVICE")"
    netdata_cid="$(service_container_id "$NETDATA_SERVICE")"

    if [[ -n "$mcp_cid" ]] && is_running "$mcp_cid"; then
        MCP_CONTAINER_STATUS="OK"
    else
        failures=$((failures + 1))
    fi

    if [[ -n "$netdata_cid" ]] && is_running "$netdata_cid"; then
        NETDATA_CONTAINER_STATUS="OK"
    else
        failures=$((failures + 1))
    fi

    if [[ -n "$netdata_cid" ]] && is_healthy "$netdata_cid"; then
        NETDATA_HEALTH_STATUS="OK"
    else
        failures=$((failures + 1))
    fi
}

check_mcp_to_netdata() {
    local output=""

    output="$(compose_cmd exec -T "$MCP_SERVICE" node -e "const url='http://netdata:19999/api/v1/info'; fetch(url).then(r=>{console.log('STATUS=' + r.status); process.exit(r.ok?0:1);}).catch(()=>{console.log('STATUS=ERR'); process.exit(2);});" 2>/dev/null || true)"

    if grep -q 'STATUS=' <<<"$output"; then
        HTTP_STATUS="${output#*STATUS=}"
        HTTP_STATUS="${HTTP_STATUS%%[$'\r\n']*}"
    fi

    if [[ "$HTTP_STATUS" == "200" ]]; then
        MCP_TO_NETDATA_STATUS="OK"
    else
        failures=$((failures + 1))
    fi
}

print_summary() {
    log ""
    log "=== MCP / Netdata Status ==="
    log "MCP_CONTAINER     : $MCP_CONTAINER_STATUS"
    log "NETDATA_CONTAINER : $NETDATA_CONTAINER_STATUS"
    log "NETDATA_HEALTH    : $NETDATA_HEALTH_STATUS"
    log "MCP_TO_NETDATA    : $MCP_TO_NETDATA_STATUS (HTTP=$HTTP_STATUS)"

    if [[ "$failures" -eq 0 ]]; then
        log "RESUME            : OK"
    else
        log "RESUME            : FAIL"
    fi
}

main() {
    require_tools
    require_paths

    check_containers_running
    check_mcp_to_netdata
    print_summary

    if [[ "$failures" -eq 0 ]]; then
        exit 0
    fi

    exit 1
}

main "$@"
