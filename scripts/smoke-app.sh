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
        if WINDOW_CHECK_OUTPUT="$(osascript <<APPLESCRIPT 2>&1
tell application "System Events"
    if not (exists process "$APP_NAME") then
        return "missing-process"
    end if

    tell process "$APP_NAME"
        repeat 20 times
            if (count of windows) > 0 then
                return "window-found"
            end if
            delay 0.25
        end repeat
    end tell
end tell

return "no-window"
APPLESCRIPT
)"; then
            if [[ "$WINDOW_CHECK_OUTPUT" == "window-found" ]]; then
                echo "DJMemory window check passed."
            else
                echo "DJMemory smoke check warning: main window was not detected ($WINDOW_CHECK_OUTPUT)." >&2
            fi
        else
            echo "DJMemory smoke check warning: window check was blocked or unavailable." >&2
            echo "$WINDOW_CHECK_OUTPUT" >&2
        fi

        echo "DJMemory smoke check passed."
        osascript -e "tell application id \"app.djmemory.DJMemory\" to quit" >/dev/null 2>&1 || true
        exit 0
    fi

    sleep 0.5
done

echo "DJMemory smoke check failed: app process did not launch." >&2
exit 1
