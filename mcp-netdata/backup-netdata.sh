#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SOURCE_DIR:-$SCRIPT_DIR}"
COMPOSE_FILE="${COMPOSE_FILE:-$SOURCE_DIR/docker-compose.yml}"

NETDATA_SERVICE="${NETDATA_SERVICE:-netdata}"
BACKUP_DIR="${BACKUP_DIR:-$SOURCE_DIR/backups}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE_NAME="netdata_data_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

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
    if [[ "$SOURCE_DIR" == *\\* || "$COMPOSE_FILE" == *\\* || "$BACKUP_DIR" == *\\* ]]; then
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

backup_volume() {
    mkdir -p "$BACKUP_DIR"

    # Sauvegarde sans interruption: conteneur ephemere base sur le service netdata.
    compose_cmd run --rm -T --no-deps \
        -v "${BACKUP_DIR}:/backup" \
        --entrypoint sh \
        "$NETDATA_SERVICE" \
        -c "tar -czf /backup/$ARCHIVE_NAME -C /var/lib/netdata ."
}

main() {
    require_tools
    require_paths

    if backup_volume; then
        log "BACKUP_STATUS=OK"
        log "VOLUME=netdata_data (/var/lib/netdata)"
        log "ARCHIVE=$ARCHIVE_PATH"
        exit 0
    fi

    log "BACKUP_STATUS=FAIL"
    exit 1
}

main "$@"
