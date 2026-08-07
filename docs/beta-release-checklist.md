# DJMemory Beta Release Checklist

Last updated: August 6, 2026.

## Build

- Run `swift test`.
- Run `bash scripts/smoke-cli.sh`.
- Run `swift build --product DJMemoryApp`.
- Run `bash scripts/build-app.sh release`.
- Run `bash scripts/package-beta.sh`.
- Confirm `.build/DJMemory.app` exists.
- Confirm `codesign --verify --deep --strict .build/DJMemory.app` passes.
- Confirm `.build/distribution/` contains a zip and JSON manifest with a SHA-256 checksum.

## Signing and Distribution

- Debug/local beta builds may use ad hoc signing.
- `scripts/package-beta.sh` creates a local beta zip only; it is not notarized.
- External beta builds should use Developer ID signing.
- Notarization is required before broad direct-download distribution.
- App Store distribution remains later, but sandbox posture should stay enabled.

## Manual Smoke Test

- Launch the packaged `.app`.
- Confirm the app opens to Protection.
- Confirm the menu-bar item appears.
- Set a recording folder for at least one DJ app.
- Quit and relaunch.
- Confirm the folder still appears.
- Run Scan Now against a folder with no new files.
- Import one supported tracklist file.
- Export diagnostics and confirm the report avoids track titles by default.

## Permission Recovery

- Move or revoke access to a saved folder.
- Confirm the folder row shows an attention state.
- Choose the folder again.
- Confirm the warning clears and scanning can run.

## Privacy Review

- Confirm no audio files are uploaded.
- Confirm no tracklists are uploaded by default.
- Confirm diagnostics are saved only when the user chooses Export Diagnostics.
- Confirm diagnostics include counts and paths, not full track contents.

## Known Issues Template

Before each beta build, document:

- supported DJ apps
- partial DJ apps
- unsupported formats
- known parser limitations
- signing/notarization status
- minimum macOS version
- recovery steps for folder permission issues
