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

Use generated temporary folders and files for archive and scanner behavior. Use small sanitized fixtures for parser behavior when real-world export shape matters.

Test fixtures:

- generated fake WAV/AIFF/MP3/M4A recordings
- generated growing file vs stable file cases
- generated missing folder, moved folder, and duplicate source recording cases
- sanitized Serato CSV/TXT history exports under `Tests/DJMemoryCoreTests/Fixtures`
- sanitized rekordbox XML collection exports under `Tests/DJMemoryCoreTests/Fixtures`
- sanitized Traktor NML history files under `Tests/DJMemoryCoreTests/Fixtures`

Keep generated temp-directory tests for archive/scanner behavior. Keep real-world DJ exports out of the repo unless they have been sanitized and are small enough to review comfortably.

Expected checks:

- archive copy exists
- metadata JSON exists
- source file is unchanged
- duplicate scan does not re-archive
- parser extracts expected count
- collection imports do not auto-match to recordings

### 3. App Bundle Verification

Use the existing packaging and smoke scripts for beta-readiness checks.

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
- smoke script launches the app process and quits cleanly

### 4. macOS UI Smoke Automation

Use macOS Automator / AppleScript / JXA where possible. `scripts/smoke-app.sh` already verifies that the app builds, codesigns, launches, and quits; the next enhancement is confirming that the main window exists when macOS automation permissions allow it.

Automatable checks:

- launch app
- confirm app process exists
- confirm main window exists when accessibility automation is available
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

- Add accessibility identifiers to uncovered app controls:
  - setup-row buttons
  - library/session actions
  - track search
  - tracklist matching controls
  - settings toggle, picker, and text field
  - menu bar actions
- Extend `scripts/smoke-app.sh` with a main-window check using AppleScript/JXA when automation permissions are available, while keeping a clear fallback for machines where macOS privacy settings block window inspection.
- Add small sanitized parser fixtures under `Tests/DJMemoryCoreTests/Fixtures` for Serato, rekordbox, and Traktor once representative samples are available.
- Keep archive and scanner integration coverage based on generated temporary directories rather than checked-in audio files.
- Continue running `swift test` after fixture or test changes and `bash scripts/smoke-app.sh` for app bundle verification.
