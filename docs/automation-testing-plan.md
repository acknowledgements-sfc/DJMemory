# DJMemory Automation Testing Plan

Last updated: August 6, 2026.

## Current Passing Baseline

Verified on August 6, 2026:

- `swift test` passes the current Swift test suite.
- `bash scripts/build-app.sh debug` builds `.build/DJMemory.app`.
- `bash scripts/smoke-cli.sh` builds the CLI once, scans generated temporary recording folders, verifies stable archives, pending-recording output, missing-folder recovery messages, and diagnostics JSON export.
- `bash scripts/smoke-app.sh` builds, verifies the app signature, launches DJMemory, confirms the app process exists, performs a best-effort main-window check, and quits cleanly.
- `bash scripts/package-beta.sh` builds a release app bundle and writes a zip plus JSON manifest to `.build/distribution/`.
- `codesign --verify --deep --strict .build/DJMemory.app` verifies the ad hoc signed app bundle.

The smoke test treats process launch as required. Main-window detection is best-effort because macOS automation permissions can block System Events inspection on a tester's machine.

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

Current coverage includes archive copy behavior, duplicate prevention through archive metadata/fingerprints, file stability, audio filtering, metadata sidecars, folder stores, settings stores, imported tracklist stores, parser behavior, diagnostics privacy redaction, set context, manual tracklist matching, and a temporary recording-folder integration path.
The CLI smoke path also writes a diagnostics report to a temporary file and verifies the home folder path is not leaked into that JSON.
Library search is covered by `LibrarySessionSearchTests`, and the archived-set and tracklist search fields expose accessibility identifiers for future app automation.

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
bash scripts/package-beta.sh
codesign --verify --deep --strict .build/DJMemory.app
```

Expected checks:

- app bundle exists
- beta zip and manifest exist for handoff
- executable is copied into bundle
- Info.plist exists
- ad hoc signature verifies
- sandbox entitlements are attached
- smoke script launches the app process, performs a best-effort window check, and quits cleanly

### 4. macOS UI Smoke Automation

Use macOS Automator / AppleScript / JXA where possible. `scripts/smoke-app.sh` verifies that the app builds, codesigns, launches, and quits; it also attempts a main-window check and reports a warning when macOS automation permissions block window inspection.

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
  - menu bar actions
- Keep `scripts/smoke-app.sh` permissive around the main-window check so macOS privacy settings do not block launch verification.
- Add small sanitized parser fixtures under `Tests/DJMemoryCoreTests/Fixtures` for Serato, rekordbox, and Traktor once representative samples are available.
- Keep archive and scanner integration coverage based on generated temporary directories rather than checked-in audio files.
- Continue running `swift test` after fixture or test changes and `bash scripts/smoke-app.sh` for app bundle verification.
