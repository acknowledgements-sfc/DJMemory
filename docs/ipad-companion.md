# DJMemory iPad Companion

Last updated: August 9, 2026.

## Product shape

**iPadOS 17+ companion** — not a port of Mac folder Protection.

| Mac-only | iPad companion |
| --- | --- |
| Serato / rekordbox / Traktor / VirtualDJ folder watch | Library browse / edit |
| Menu bar, login items | Files + Share import (djay first) |
| Claiming desktop apps are installed | Optional parallel capture |

Honest labels: mobile adapters start **Manual Setup**. Serato and other desktop engines stay Mac-only on this device.

## Open in Xcode

```sh
# from repo root (requires xcodegen)
xcodegen generate --spec project.yml
open DJMemory.xcodeproj
```

Select the **DJMemoryiPad** scheme → iPad simulator or device (iOS 17+).

Bundle ID: `app.djmemory.DJMemory.iPad`

## Architecture

- Shared [`DJMemoryCore`](../Sources/DJMemoryCore) (PathProviding + iOS bookmark options).
- UI in [`Sources/DJMemoryCompanion`](../Sources/DJMemoryCompanion).
- Thin `@main` wrapper in [`Apps/DJMemoryCompanion`](../Apps/DJMemoryCompanion).
- Optional Clerk account (same privacy rules as Mac). Local archive/import never depends on sign-in.
