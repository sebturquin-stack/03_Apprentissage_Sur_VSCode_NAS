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

cleanup_stack() {
    compose_cmd down --volumes --remove-orphans >/dev/null
}

restart_stack() {
    compose_cmd up -d --build --force-recreate --remove-orphans >/dev/null
}

is_service_running() {
    local service="$1"
    compose_cmd ps --status running --services 2>/dev/null | grep -qx "$service"
}

netdata_health_status() {
    compose_cmd ps --format json 2>/dev/null | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const arr=JSON.parse(d||'[]');const s=arr.find(x=>x.Service===process.argv[1]);process.stdout.write((s&&s.Health)?String(s.Health):'');}catch{process.stdout.write('');}});" "$NETDATA_SERVICE"
}

check_services() {
    if is_service_running "$MCP_SERVICE"; then
        MCP_CONTAINER_STATUS="OK"
    else
        failures=$((failures + 1))
    fi

    if is_service_running "$NETDATA_SERVICE"; then
        NETDATA_CONTAINER_STATUS="OK"
    else
        failures=$((failures + 1))
    fi

    if [[ "$(netdata_health_status)" == "healthy" ]]; then
        NETDATA_HEALTH_STATUS="OK"
    else
        failures=$((failures + 1))
    fi
}

check_mcp_responds() {
    if compose_cmd exec -T "$MCP_SERVICE" node /app/netdata-mcp.js --healthcheck >/dev/null 2>&1; then
        return 0
    fi

    failures=$((failures + 1))
    return 1
}

check_mcp_to_netdata() {
    local output=""

    output="$(compose_cmd exec -T "$MCP_SERVICE" node -e "const url='http://netdata:19999/api/v1/info'; fetch(url).then(r=>{console.log('STATUS='+r.status); process.exit(r.ok?0:1);}).catch(()=>{console.log('STATUS=ERR'); process.exit(2);});" 2>/dev/null || true)"

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
    log "MCP_CONTAINER=$MCP_CONTAINER_STATUS"
    log "NETDATA_CONTAINER=$NETDATA_CONTAINER_STATUS"
    log "NETDATA_HEALTH=$NETDATA_HEALTH_STATUS"
    log "MCP_TO_NETDATA=$MCP_TO_NETDATA_STATUS"
    log "STATUS=$HTTP_STATUS"
}

main() {
    require_tools
    require_paths

    cleanup_stack
    restart_stack

    check_services
    check_mcp_responds
    check_mcp_to_netdata

    print_summary

    if [[ "$failures" -eq 0 ]]; then
        exit 0
    fi

    exit 1
}

main "$@"
