#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-netdata-mcp:local}"
CONTAINER_NAME="${CONTAINER_NAME:-01_Node-20_MCP}"
BASE_URL="${NETDATA_BASE_URL:-http://172.17.0.1:19999}"
SOURCE_DIR="${SOURCE_DIR:-$SCRIPT_DIR}"

usage() {
    cat <<'EOF'
Usage:
  ./start-netdata-mcp.sh build   Build the Docker image
  ./start-netdata-mcp.sh up      Build and start the container
  ./start-netdata-mcp.sh down    Stop and remove the container
  ./start-netdata-mcp.sh status  Show container status and health
  ./start-netdata-mcp.sh logs    Follow container logs
  ./start-netdata-mcp.sh health  Run the healthcheck command in the container

Environment:
  IMAGE_NAME       Docker image name (default: netdata-mcp:local)
  CONTAINER_NAME   Docker container name (default: 01_Node-20_MCP)
  NETDATA_BASE_URL Netdata base URL (default: http://172.17.0.1:19999)
  SOURCE_DIR       Build context directory (default: directory of this script)
EOF
}

require_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "docker is not available in PATH" >&2
        exit 1
    fi
}

build_image() {
    docker build --pull -t "$IMAGE_NAME" "$SOURCE_DIR"
}

ensure_stopped_container_removed() {
    if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        docker rm -f "$CONTAINER_NAME" >/dev/null
    fi
}

start_container() {
    ensure_stopped_container_removed
    docker run -d -i \
        --name "$CONTAINER_NAME" \
        --restart=unless-stopped \
        --user 1000:1000 \
        -e "NETDATA_BASE_URL=$BASE_URL" \
        --health-cmd='node /app/netdata-mcp.js --healthcheck' \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        -v "$SOURCE_DIR":/app \
        -w /app \
        "$IMAGE_NAME"
}

show_status() {
    docker ps -a --filter "name=$CONTAINER_NAME" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
    if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        docker inspect "$CONTAINER_NAME" --format '{{.State.Health.Status}}' 2>/dev/null || true
    fi
}

follow_logs() {
    docker logs -f --tail 200 "$CONTAINER_NAME"
}

run_healthcheck() {
    docker exec -i "$CONTAINER_NAME" node /app/netdata-mcp.js --healthcheck
}

main() {
    require_docker

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
            docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-netdata-mcp:local}"
CONTAINER_NAME="${CONTAINER_NAME:-01_Node-20_MCP}"
BASE_URL="${NETDATA_BASE_URL:-http://172.17.0.1:19999}"
SOURCE_DIR="${SOURCE_DIR:-$SCRIPT_DIR}"

usage() {
    cat <<'EOF'
Usage:
  ./start-netdata-mcp.sh build   Build the Docker image
  ./start-netdata-mcp.sh up      Build and start the container
  ./start-netdata-mcp.sh down    Stop and remove the container
  ./start-netdata-mcp.sh status  Show container status and health
  ./start-netdata-mcp.sh logs    Follow container logs
  ./start-netdata-mcp.sh health  Run the healthcheck command in the container

Environment:
  IMAGE_NAME       Docker image name (default: netdata-mcp:local)
  CONTAINER_NAME   Docker container name (default: 01_Node-20_MCP)
  NETDATA_BASE_URL Netdata base URL (default: http://172.17.0.1:19999)
  SOURCE_DIR       Build context directory (default: directory of this script)
EOF
}

require_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "docker is not available in PATH" >&2
        exit 1
    fi
}

build_image() {
    docker build --pull -t "$IMAGE_NAME" "$SOURCE_DIR"
}

ensure_stopped_container_removed() {
    if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        docker rm -f "$CONTAINER_NAME" >/dev/null
    fi
}

start_container() {
    ensure_stopped_container_removed
    docker run -d -i \
        --name "$CONTAINER_NAME" \
        --restart=unless-stopped \
        --user 1000:1000 \
        -e "NETDATA_BASE_URL=$BASE_URL" \
        --health-cmd='node /app/netdata-mcp.js --healthcheck' \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        -v "$SOURCE_DIR":/app \
        -w /app \
        "$IMAGE_NAME"
}

show_status() {
    docker ps -a --filter "name=$CONTAINER_NAME" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
    if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        docker inspect "$CONTAINER_NAME" --format '{{.State.Health.Status}}' 2>/dev/null || true
    fi
}

follow_logs() {
    docker logs -f --tail 200 "$CONTAINER_NAME"
}

run_healthcheck() {
    docker exec -i "$CONTAINER_NAME" node /app/netdata-mcp.js --healthcheck
}

main() {
    require_docker

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
            docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
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
