# DJMemory Beta Release Checklist

Last updated: August 7, 2026.

## Build

- Run `swift test`.
- Run `bash scripts/smoke-cli.sh`.
- Run `swift build --product DJMemoryApp`.
- Run `bash scripts/build-app.sh release`.
- Run `bash scripts/package-beta.sh`.
- Confirm `.build/DJMemory.app` exists.
- Confirm `codesign --verify --deep --strict .build/DJMemory.app` passes.
- Confirm `.build/distribution/` contains a zip and JSON manifest with a SHA-256 checksum.
- Review `docs/mvp-readiness-audit.md` for automated evidence and remaining manual checks.

## Signing and Distribution

- Debug/local beta builds may use ad hoc signing (default `scripts/build-app.sh` / `scripts/package-beta.sh`).
- External beta builds: set `DJMEMORY_DISTRIBUTION=developer-id` (see [`docs/signing-and-notarization.md`](signing-and-notarization.md)).
- `scripts/notarize-app.sh` submits with `notarytool` and staples; fails loudly without Developer ID + credentials.
- Developer ID signing + notarization are required before broad direct-download distribution.
- App Store distribution remains later, but sandbox posture should stay enabled.

## Manual Smoke Test

- Launch the packaged `.app`.
- Confirm the app opens to Home.
- Confirm the menu-bar item appears.
- Set a recording folder for at least one DJ app.
- Quit and relaunch.
- Confirm the folder still appears.
- Run Scan Now against a folder with no new files.
- Confirm the Protection dashboard and menu-bar status show last-scan and next-scan timing.
- Add or update an audio file in a watched folder and confirm DJMemory schedules a scan soon.
- Import one supported tracklist file.
- Search archived sets by filename, app, venue, or matched track text.
- Export diagnostics and confirm the report avoids track titles by default.
- Run `swift run djmemory diagnostics ./DJMemory-Diagnostics.json` and confirm it writes a redacted support report.

## Permission Recovery

- Move or revoke access to a saved folder.
- Confirm the folder row shows an attention state.
- Confirm the protected-source count does not include the inaccessible folder.
- Choose the folder again.
- Confirm the warning clears and scanning can run.

## Privacy Review

- Confirm no audio files are uploaded.
- Confirm no tracklists are uploaded by default.
- Confirm diagnostics are saved only when the user chooses Export Diagnostics.
- Confirm diagnostics include counts and redacted paths, not full track contents.

## Known Issues Template

Before each beta build, document:

- supported DJ apps
- partial DJ apps
- unsupported formats
- known parser limitations
- signing/notarization status
- minimum macOS version
- recovery steps for folder permission issues
