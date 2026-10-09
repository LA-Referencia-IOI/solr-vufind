#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.solr-9-11.yml"
SOURCE_DIR="$SCRIPT_DIR/vufind"
RUNTIME_DIR="$PROJECT_DIR/volumes/solr"
SOLR_VERSION="${SOLR_VERSION:-9.11.0}"

export SOLR_VERSION

CORE_NAMES="biblio authority reserves website"

usage() {
    echo "Usage: $0 {start|restart|stop}" >&2
    exit 1
}

prepare_runtime_files() {
    mkdir -p "$RUNTIME_DIR/data"
    # The Solr image runs as UID/GID 8983, not as the host user.
    chmod a+rwx "$RUNTIME_DIR" "$RUNTIME_DIR/data"
    install -m 0644 "$SOURCE_DIR/solr.xml" "$RUNTIME_DIR/data/solr.xml"

    for core in $CORE_NAMES; do
        mkdir -p "$RUNTIME_DIR/data/$core"
        # Index and spell-check data are runtime state; do not seed or overwrite
        # them from the source configuration when starting the container.
        rsync -a \
            --exclude='data/' \
            --exclude='index/' \
            --exclude='spellShingle/' \
            --exclude='spellchecker/' \
            --exclude='tlog/' \
            "$SOURCE_DIR/$core/" "$RUNTIME_DIR/data/$core/"
        chmod a+rwx "$RUNTIME_DIR/data/$core"
    done

    mkdir -p "$RUNTIME_DIR/data/jars"
    rsync -a "$SOURCE_DIR/jars/" "$RUNTIME_DIR/data/jars/"
}

[ "$#" -eq 1 ] || usage

case "$1" in
    start)
        prepare_runtime_files
        exec docker compose -f "$COMPOSE_FILE" up -d
        ;;
    restart)
        docker compose -f "$COMPOSE_FILE" stop
        prepare_runtime_files
        exec docker compose -f "$COMPOSE_FILE" up -d --force-recreate
        ;;
    stop)
        exec docker compose -f "$COMPOSE_FILE" stop
        ;;
    *)
        usage
        ;;
esac
