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
swift run DJMemoryApp
swift test
```

Archived recordings are copied to `~/Music/DJMemory` by default with a JSON metadata sidecar. Source files are never moved, renamed, or deleted.

`DJMemoryApp` launches the first SwiftUI app shell with setup status, menu-bar status, and an archived-session library view.

The app can save recording/history folder selections using macOS security-scoped bookmarks, which keeps the setup path compatible with sandboxed distribution.

## Product Direction

The practical integration strategy is file-first:

1. Watch each DJ app's recording and history locations.
2. Detect active sessions by app process plus audio/file activity.
3. Save/rename/archive the recording automatically when possible.
4. Attach setlists from history exports or app-local history files.
5. Add deeper integrations only where supported, especially VirtualDJ.
