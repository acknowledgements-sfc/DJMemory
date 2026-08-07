#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="DJMemory"
BUNDLE_DIR="$ROOT_DIR/.build/$APP_NAME.app"

cd "$ROOT_DIR"

bash scripts/build-app.sh debug >/dev/null
codesign --verify --deep --strict "$BUNDLE_DIR"

osascript -e "tell application id \"app.djmemory.DJMemory\" to quit" >/dev/null 2>&1 || true
sleep 1

open "$BUNDLE_DIR"

for _ in {1..20}; do
    if pgrep -x "$APP_NAME" >/dev/null; then
        echo "DJMemory smoke check passed."
        osascript -e "tell application id \"app.djmemory.DJMemory\" to quit" >/dev/null 2>&1 || true
        exit 0
    fi

    sleep 0.5
done

echo "DJMemory smoke check failed: app process did not launch." >&2
exit 1
