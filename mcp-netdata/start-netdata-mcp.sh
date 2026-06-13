#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="${NETDATA_BASE_URL:-http://netdata:19999}"
TIMEOUT_MS="${NETDATA_TIMEOUT_MS:-5000}"
SOURCE_DIR="${SOURCE_DIR:-$SCRIPT_DIR}"
COMPOSE_FILE="${COMPOSE_FILE:-$SOURCE_DIR/docker-compose.yml}"
SERVICE_NAME="${SERVICE_NAME:-netdata-mcp}"

usage() {
    cat <<'EOF'
Usage:
  ./start-netdata-mcp.sh build   Build service image via Docker Compose
  ./start-netdata-mcp.sh up      Build and start service via Docker Compose
  ./start-netdata-mcp.sh down    Stop and remove service stack
  ./start-netdata-mcp.sh status  Show service status and health
  ./start-netdata-mcp.sh logs    Follow service logs
  ./start-netdata-mcp.sh health  Run healthcheck command in the service container

Environment:
  NETDATA_BASE_URL Netdata base URL (default: http://172.17.0.1:19999)
  NETDATA_TIMEOUT_MS Netdata timeout in milliseconds (default: 5000)
  SOURCE_DIR       Project directory (default: directory of this script)
  COMPOSE_FILE     Compose file path (default: SOURCE_DIR/docker-compose.yml)
  SERVICE_NAME     Compose service name (default: netdata-mcp)
EOF
}

require_compose() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "docker is not available in PATH" >&2
        exit 1
    fi

    if ! docker compose version >/dev/null 2>&1; then
        echo "docker compose is not available" >&2
        exit 1
    fi
}

require_source_dir() {
    if [[ "$SOURCE_DIR" == *\\* || "$COMPOSE_FILE" == *\\* ]]; then
        echo "Windows/UNC style paths are not supported in this script. Use Linux/WSL paths (e.g. /mnt/c/...)." >&2
        exit 1
    fi

    if [[ ! -d "$SOURCE_DIR" ]]; then
        echo "source directory does not exist: $SOURCE_DIR" >&2
        exit 1
    fi

    if [[ ! -f "$COMPOSE_FILE" ]]; then
        echo "compose file does not exist: $COMPOSE_FILE" >&2
        exit 1
    fi

    if [[ ! -f "$SOURCE_DIR/netdata-mcp.js" ]]; then
        echo "missing runtime file: $SOURCE_DIR/netdata-mcp.js" >&2
        exit 1
    fi
}

compose_cmd() {
    NETDATA_BASE_URL="$BASE_URL" NETDATA_TIMEOUT_MS="$TIMEOUT_MS" docker compose -f "$COMPOSE_FILE" --project-directory "$SOURCE_DIR" "$@"
}

build_image() {
    compose_cmd build "$SERVICE_NAME"
}

start_container() {
    compose_cmd up -d --build "$SERVICE_NAME"
}

show_status() {
    compose_cmd ps

    local container_id
    container_id="$(compose_cmd ps -q "$SERVICE_NAME" 2>/dev/null || true)"
    if [[ -n "$container_id" ]]; then
        docker inspect "$container_id" --format '{{.State.Health.Status}}' 2>/dev/null || true
    fi
}

follow_logs() {
    compose_cmd logs -f --tail 200 "$SERVICE_NAME"
}

run_healthcheck() {
    compose_cmd exec -T "$SERVICE_NAME" node /app/netdata-mcp.js --healthcheck
}

main() {
    require_compose
    require_source_dir

    local command="${1:-}"
    case "$command" in
        build)
            build_image
            ;;
        up)
            build_image
            start_container
            ;;
        down)
            compose_cmd down --remove-orphans
            ;;
        status)
            show_status
            ;;
        logs)
            follow_logs
            ;;
        health)
            run_healthcheck
            ;;
        ""|-h|--help|help)
            usage
            ;;
        *)
            echo "Unknown command: $command" >&2
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"
