# DJMemory Integration Status

Last updated: August 13, 2026.

## Status Labels
- Supported / Partial / Manual Setup / Research — honest labels; never round Partial up to Supported.

## Current App Matrix

| App | Status | Current Support |
| --- | --- | --- |
| Serato DJ Pro | Supported | Recording folder, history import; App audio Capture verified (ScreenCaptureKit); Process Audio Tap implemented, needs live meter + archive verification |
| rekordbox | Supported | Manual recording folder, XML Bridge / history import; App audio Capture verified end-to-end (ScreenCaptureKit meter + archive write); Process Audio Tap implemented, needs live meter + archive verification |
| Traktor | Supported | Recordings + NML; App audio Capture verified end-to-end on Traktor DJ 2 (meter + archive write). Pro QML CSI live API = Research only |
| VirtualDJ | Supported | File watch + Network Control; App audio Capture verified end-to-end (meter + archive write). Native plugin = Research (M14) |
| djay Pro | Supported | Documented folders; App audio Capture verified end-to-end on djay Pro 2 (meter + archive write) |
| DJMemory Capture | Implemented | App audio backend selector prefers Process Audio Tap on macOS 14.2+ and falls back to ScreenCaptureKit; ScreenCaptureKit verified end-to-end on Serato, rekordbox, djay Pro 2, VirtualDJ, Traktor DJ 2; Input device (Core Audio); silence session split |
| Pioneer Hardware | Manual Setup | USB PIONEERREC / RECxxx.WAV watch |

## Source map (official vs community / sandbox-safe vs research)

Locked Mac product paths stay **sandbox-safe**. Community live-deck hacks stay **research** until sandbox policy changes.

| Source | Kind | Use in DJMemory |
| --- | --- | --- |
| Process Audio Tap | Platform SDK | Preferred App audio Capture backend on macOS 14.2+; live verification pending |
| ScreenCaptureKit App audio | Platform SDK | Product Capture |
| Folder Protection + bookmarks | Product | Copy-only archive |
| Local history CSV / XML / NML | Official exports + documented folders | Import + autopull |
| Input device Capture | Core Audio | Product fallback |
| rekordbox XML Bridge | Official developer | Library/playlist import — not live deck audio |
| VirtualDJ Network Control | Community / product Partial | Optional control (M13); Capture independent |
| Serato Twitch Now Playing / Live Playlists | Official cloud | **Do not** use as Capture or default tracklist path |
| SSL-API (Scratch Live binary) | Community | Research only |
| Traktor Kontrol D2 QML CSI replacement | Community (patches Traktor.app) | Research only; Pro-oriented; not App Store–safe |
| VirtualDJ native plugin | SDK | Research (M14) — ingest implemented; `.bundle` not started |

See `docs/research.md` for per-app depth and links.

## App Audio Capture (Mac)

Primary Mac feature: when a shareable DJ app is found, **auto-arm** Capture (unless the user Disarmed)
→ Process Audio Tap captures the running DJ app on macOS 14.2+ → ScreenCaptureKit is the fallback
backend → silence policy starts/stops/archives takes → stays watching. Writes **24-bit / 48 kHz**
stereo WAV. Requires `NSAudioCaptureUsageDescription`; ScreenCaptureKit fallback also requires Screen
& System Audio Recording. Does **not** work when the mix never hits Mac system audio (exclusive
interface) — use Input device Capture (also 24-bit / 48 kHz; auto-selects Pioneer/DJM while armed) or
folder Protection.

After each archive (Capture or folder scan), DJMemory **autopulls** a nearby local history export from
known history folders when available, stamps track dates from the set, and matches. Because many DJ
apps only flush their history export when the set ends — often *after* the recording archives — DJMemory
also runs a **continuous history watcher** (M12): FSEvents on the granted history folders, a backstop
poll on the scan interval, and a launch catch-up sweep. Any late-written or mid-set-appended export
within the match window of a recent archive is auto-ingested (idempotently) and attached by the live
matcher; a closer export upgrades an earlier auto-match, while a user's manual pin is never overridden.
Soft-fail leaves manual Import as the recovery path.

Local verify (2026-08-10):

- **Serato DJ Pro** — App audio Capture verified end-to-end (Arm → level meter → Stop & Save / archive) with Screen & System Audio Recording granted.

Local verify (2026-08-12) — write-path bug found and fixed:

- The `AppAudioCaptureService` / `CaptureService` write path converted buffers to a standalone 24-bit `CaptureAudioFormat.writeFormat()` before calling `AVAudioFile.write(from:)`, but `AVAudioFile(forWriting:settings:)` always expects Float32 deinterleaved buffers matching its own `processingFormat` (it packs to the on-disk bit depth internally). Mismatch threw `com.apple.coreaudio.avfaudio error -50` on every write, deterministically, regardless of source app. Fixed in `AppAudioCaptureService.swift` / `CaptureService.swift` by converting to the file's actual `processingFormat` instead of a separately-computed 24-bit target.
- **Serato DJ Pro / rekordbox / djay Pro 2 / VirtualDJ / Traktor DJ 2 (`com.native-instruments.tmnt`)** — re-probed with decks playing live audio to Mac system output after the fix: all five now report `PASS meter+write <id>` (peaks 0.26–0.42, staged WAVs written and verified). Probe: `.build/DJMemory.app/Contents/MacOS/DJMemory --app-audio-probe <seconds> <softwareID>`.

Implementation update (2026-08-13):

- `AppAudioCaptureService` now selects a backend: Process Audio Tap first on macOS 14.2+ unless `DJMEMORY_FORCE_SCK_APP_AUDIO=1`, then ScreenCaptureKit fallback. The Process Audio Tap service creates a private Core Audio tap with `CATapDescription`, attaches it to a private aggregate device, meters/writes PCM through the shared 24-bit / 48 kHz WAV path, and destroys the tap/device on stop or failed arm.
- Packaging check: `scripts/build-app.sh` already writes `NSAudioCaptureUsageDescription`. Local SDK/header search did **not** confirm a public `com.apple.security.system-audio-capture` entitlement; keep this as a Developer ID/App Store review item until Apple documents a required entitlement or signing failure proves it.
- Local probe: VirtualDJ was the only running target. Default backend reported `backend: Process Audio Tap` and forced fallback reported `backend: ScreenCaptureKit`; both armed and cleaned up. Meter was silent, so live meter + archive verification remains pending.
- Probe update (2026-08-13): `swift run djmemory app-audio-probe <seconds> <softwareID>` and `.build/DJMemory.app/Contents/MacOS/DJMemory --app-audio-probe <seconds> <softwareID>` now archive successful metered captures through `ArchiveService.ingestCapture`, print archive + metadata paths, and confirm the new session appears in `SessionLibrary`.
- Local attempt (2026-08-13 08:24): Serato and rekordbox probe attempts reported Screen & System Audio Recording preflight `true`, then `targets: (none)` because no shareable DJ app target was running. Forced `DJMEMORY_FORCE_SCK_APP_AUDIO=1` produced the same target-discovery result.
- Live verification still required: open Serato and rekordbox, play real audio through Mac system output, then run `.build/DJMemory.app/Contents/MacOS/DJMemory --app-audio-probe <seconds> serato` and `rekordbox` without `DJMEMORY_FORCE_SCK_APP_AUDIO=1`; confirm backend `Process Audio Tap`, meter, staging WAV, archive write, and Library visibility. Repeat one forced `DJMEMORY_FORCE_SCK_APP_AUDIO=1` fallback check and confirm backend `ScreenCaptureKit`.

Do **not** start Traktor QML injection, SSL-API, or Twitch Live Playlist integration in the sandboxed Mac app.

iPad is a **separate** app: no Mac connection; accounts only are shared. On iPad, Capture is device-input only (iPadOS cannot tap another app’s audio).

| Milestone | Scope | Status |
| --- | --- | --- |
| M11 | Capture + Pioneer hybrid | Implemented (Manual Setup until device-verified) |
| M11b | App audio Capture + silence sessions | Implemented (Serato, rekordbox, djay Pro 2, VirtualDJ, Traktor DJ 2 all verified end-to-end; meter + archive write confirmed for all five 2026-08-12) |
| M12 | Deeper history + capture match window | Implemented (post-archive autopull + configurable 6h match window + continuous history watcher: FSEvents on history folders, backstop poll, and launch catch-up sweep; late/appended exports auto-ingest and match. Hardware Capture/Pioneer sets match the nearest matchable export from any DJ app within the window; auto-matches upgrade to a closer export while user pins stay sacred) |
| M13 | VDJ Network Control commands | Partial |
| M14 | VDJ native plugin | Research (Artifact B JSONL ingest implemented; Artifact A C++ `.bundle` not started — SDK unverified) |
| M15 | Opt-in cloud sync settings | Settings flags; off by default |
| M16 | User-initiated publish pack | Local export only |
| M17 | Process Audio Tap Capture | Implemented in code; live Serato/rekordbox verification pending |
