# DJMemory for iPad

Last updated: August 9, 2026.

## Product shape

**DJMemory for iPad** is a **standalone** iPadOS 17+ app (bundle ID `app.djmemory.DJMemory.iPad`).

There is **no Mac connection**. It does not pair with, mirror, or sync archives from the Mac app. It only works with DJ apps and audio **on this iPad**.

| On this iPad | Not on iPad |
| --- | --- |
| Local library browse / edit | Mac folder Protection |
| Files + Share import (djay first) | Listening to Mac DJ apps (Serato, rekordbox, Traktor, VirtualDJ, …) |
| Parallel **device input** capture while you DJ on this iPad | ScreenCaptureKit / per-app audio tap of another iPad app (iPadOS does not allow that) |
| Optional account sign-in | Requiring the Mac app to be online |

Honest labels: mobile adapters start **Manual Setup**. Desktop DJ engines are a separate Mac product — they are not “missing” from iPad; they are out of scope here.

## What Mac and iPad share (only this)

**User accounts and account-related information** — one Clerk + Supabase + Vercel stack:

| Layer | Shared |
| --- | --- |
| Clerk | Same publishable key / Native API; register Mac + iPad bundle IDs |
| Supabase | Project `alywaxyxnaxwbbsiaafs` (users, devices, licenses, diagnostics) |
| Vercel | `djmemory-admin` — `/api/devices`, `/api/license`, `/api/diagnostics` |

Both clients resolve the host via [`DJMemoryAccountConfiguration`](../Sources/DJMemoryCore/DJMemoryAccountConfiguration.swift) (`DJMEMORY_ACCOUNT_URL`, default `https://beatrevival.com`).

**Not shared:** local archives, recordings, tracklists, Capture sessions, folder bookmarks, or any live audio path. Local library/import never depends on sign-in.

## Open in Xcode

```sh
# from repo root (requires xcodegen)
xcodegen generate --spec project.yml
open DJMemory.xcodeproj
```

Select the **DJMemoryiPad** scheme → iPad simulator or device (iOS 17+).

Bundle ID: `app.djmemory.DJMemory.iPad`

## Architecture

- Shared [`DJMemoryCore`](../Sources/DJMemoryCore) code (paths, archive helpers, account URL config) — not a runtime link to a Mac.
- UI in [`Sources/DJMemoryCompanion`](../Sources/DJMemoryCompanion).
- Thin `@main` wrapper in [`Apps/DJMemoryCompanion`](../Apps/DJMemoryCompanion).
- Optional Clerk account (same privacy rules as Mac: no automatic audio upload).
