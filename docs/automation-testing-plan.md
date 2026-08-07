# DJMemory Automation Testing Plan

Last updated: August 6, 2026.

## Automation Layers

### 1. Swift Unit Tests

Use for core behavior:

- archive copy behavior
- duplicate prevention
- file stability
- audio filtering
- metadata sidecars
- folder stores
- settings stores
- imported tracklist stores
- parser behavior
- diagnostics privacy
- set context and manual tracklist matching

Run:

```bash
swift test
```

### 2. Fixture-Based Integration Tests

Use generated folders and files to simulate DJ app output.

Test fixtures:

- fake WAV/AIFF/MP3/M4A recordings
- growing file vs stable file
- Serato CSV/TXT history export
- rekordbox XML collection export
- Traktor NML history file
- missing folder
- moved folder
- duplicate source recording

Expected checks:

- archive copy exists
- metadata JSON exists
- source file is unchanged
- duplicate scan does not re-archive
- parser extracts expected count
- collection imports do not auto-match to recordings

### 3. App Bundle Verification

Use the packaging script for beta-readiness checks.

Run:

```bash
bash scripts/build-app.sh debug
bash scripts/smoke-app.sh
codesign --verify --deep --strict .build/DJMemory.app
```

Expected checks:

- app bundle exists
- executable is copied into bundle
- Info.plist exists
- ad hoc signature verifies
- sandbox entitlements are attached

### 4. macOS UI Smoke Automation

Use macOS Automator / AppleScript / JXA where possible.

Automatable checks:

- launch app
- confirm app process exists
- confirm main window exists
- click sidebar items
- click Scan Now
- open Finder reveal actions
- export diagnostics through save panel when accessible

Manual fallback remains necessary for:

- system permission prompts
- security-scoped folder picker behavior
- visual polish judgment
- menu-bar-only edge cases

### 5. Future Web Automation

Use Node/Playwright only for future web surfaces:

- account sign-in
- admin dashboard
- beta invite workflow
- billing/license portal
- support diagnostics viewer

Do not use Figma as a functional test tool. Figma is for visual flows and screen review only.

## Recommended Next Automation Work

- Add accessibility identifiers to key SwiftUI controls.
- Add fixture folders under `Tests/Fixtures` if file sizes stay small.
- Extend `scripts/smoke-app.sh` with a window check if a stable UI automation permission path is available.
- Add a sample recording-folder integration test using temporary directories.
- Add parser fixture tests for real-world Serato, rekordbox, and Traktor files once sanitized samples are available.
