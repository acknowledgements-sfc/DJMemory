# DJMemory

DJMemory is a planned macOS app for DJs that automatically captures set recordings and attaches usable session metadata from Serato DJ Pro, rekordbox, djay Pro, VirtualDJ, and Traktor.

The first scaffold is intentionally small:

- a Swift core package for software detection and adapter modeling
- a CLI probe for local discovery
- research notes and a PRD in `docs/`

## Run

```bash
swift run djmemory probe
swift run djmemory archive /path/to/set.wav serato
swift run djmemory scan ~/Music/_Serato_/Recording serato
swift run djmemory watch ~/Music/_Serato_/Recording serato
swift run djmemory virtualdj-network
swift run DJMemoryApp
swift test
bash scripts/smoke-app.sh
```

Archived recordings are copied to `~/Music/DJMemory` by default with a JSON metadata sidecar. The default archive folder is created on launch. A custom archive folder can be set in Settings. Source files are never moved, renamed, or deleted.

`DJMemoryApp` launches the first SwiftUI app shell with setup status, menu-bar status, and an archived-session library view.
First launch shows a setup sheet that summarizes detected DJ apps, the archive location, and the next setup action.

For a clickable local macOS app bundle:

```bash
bash scripts/build-app.sh
open .build/DJMemory.app
```

The local bundle is signed ad hoc with sandbox-oriented entitlements in `packaging/DJMemory.entitlements`. Xcode is still needed later for Developer ID/App Store signing, icons, notarization, and archived release export.

Beta handoff checks live in `docs/beta-release-checklist.md`.
Current DJ app support levels live in `docs/integration-status.md`.
Local smoke-test coverage lives in `scripts/smoke-app.sh`.

The app can save recording/history folder selections using macOS security-scoped bookmarks, which keeps the setup path compatible with sandboxed distribution. Custom archive folders use the same bookmark approach.

Configured recording folders can be scanned from the app with **Scan Now**. While the app is open, it also checks configured folders once per minute.

To open the package in Xcode:

```bash
bash scripts/open-xcode.sh
```

Xcode is not required for day-to-day preview, but it will be needed for production signing, sandbox entitlement inspection, icons, notarization, and packaged app export.

## Product Direction

The practical integration strategy is file-first:

1. Watch each DJ app's recording and history locations.
2. Detect active sessions by app process plus audio/file activity.
3. Save/rename/archive the recording automatically when possible.
4. Attach setlists from history exports or app-local history files.
5. Add deeper integrations only where supported, especially VirtualDJ.
