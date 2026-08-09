# DJMemory iPad Companion

Last updated: August 9, 2026.

## Product shape

**iPadOS 17+ companion** — a **standalone** iOS app (bundle ID `app.djmemory.DJMemory.iPad`) that runs without the Mac app. It is **not** a port of Mac folder Protection.

| Mac-only | iPad companion |
| --- | --- |
| Serato / rekordbox / Traktor / VirtualDJ folder watch | Library browse / edit |
| Menu bar, login items | Files + Share import (djay first) |
| Claiming desktop apps are installed | Optional parallel capture |

Honest labels: mobile adapters start **Manual Setup**. Serato and other desktop engines stay Mac-only on this device.

“Not full DJMemory on iPad” means the **local job** differs (no desktop folder Protection). Same product family; different on-device workflow.

## Shared accounts backend (locked)

Mac and iPad use **one** Clerk + Supabase + Vercel stack:

| Layer | Shared |
| --- | --- |
| Clerk | Same publishable key / Native API; register Mac + iPad bundle IDs |
| Supabase | Project `alywaxyxnaxwbbsiaafs` (users, devices, licenses, diagnostics) |
| Vercel | `djmemory-admin` — `/api/devices`, `/api/license`, `/api/diagnostics` |

Both clients resolve the host via [`DJMemoryAccountConfiguration`](../Sources/DJMemoryCore/DJMemoryAccountConfiguration.swift) (`DJMEMORY_ACCOUNT_URL`, default `https://djmemory-admin.vercel.app`). Local library/import never depends on sign-in.

## Open in Xcode

```sh
# from repo root (requires xcodegen)
xcodegen generate --spec project.yml
open DJMemory.xcodeproj
```

Select the **DJMemoryiPad** scheme → iPad simulator or device (iOS 17+).

Bundle ID: `app.djmemory.DJMemory.iPad`

## Architecture

- Shared [`DJMemoryCore`](../Sources/DJMemoryCore) (PathProviding + iOS bookmark options + account URL config).
- UI in [`Sources/DJMemoryCompanion`](../Sources/DJMemoryCompanion).
- Thin `@main` wrapper in [`Apps/DJMemoryCompanion`](../Apps/DJMemoryCompanion).
- Optional Clerk account (same privacy rules as Mac).
