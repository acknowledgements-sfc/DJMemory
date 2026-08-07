#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"

swift build --product djmemory >/dev/null
CLI="$ROOT_DIR/.build/debug/djmemory"

SOURCE_DIR="$TMP_DIR/source"
ARCHIVE_DIR="$TMP_DIR/archive"
mkdir -p "$SOURCE_DIR"

STABLE_FILE="$SOURCE_DIR/stable.wav"
PENDING_FILE="$SOURCE_DIR/pending.wav"
printf "audio" > "$STABLE_FILE"
printf "pending audio" > "$PENDING_FILE"
touch -t "$(date -v-2M +%Y%m%d%H%M)" "$STABLE_FILE"

STABLE_OUTPUT="$(DJMEMORY_ARCHIVE_ROOT="$ARCHIVE_DIR" "$CLI" scan "$SOURCE_DIR" serato)"
if [[ "$STABLE_OUTPUT" != *"Archived: stable.wav"* ]]; then
    echo "Expected stable recording to be archived." >&2
    echo "$STABLE_OUTPUT" >&2
    exit 1
fi

PENDING_OUTPUT="$(DJMEMORY_ARCHIVE_ROOT="$ARCHIVE_DIR" "$CLI" scan "$SOURCE_DIR" serato)"
if [[ "$PENDING_OUTPUT" != *"Recording detected. Waiting for file to finish:"* ]]; then
    echo "Expected pending recording to be reported as waiting." >&2
    echo "$PENDING_OUTPUT" >&2
    exit 1
fi

MISSING_OUTPUT="$(DJMEMORY_ARCHIVE_ROOT="$ARCHIVE_DIR" "$CLI" scan "$TMP_DIR/missing" serato)"
if [[ "$MISSING_OUTPUT" != *"Recording folder was moved or deleted. Choose the folder again in setup."* ]]; then
    echo "Expected missing folder recovery message." >&2
    echo "$MISSING_OUTPUT" >&2
    exit 1
fi

echo "DJMemory CLI smoke check passed."
