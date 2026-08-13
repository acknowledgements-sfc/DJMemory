# DJMemory Integration Status

Last updated: August 12, 2026.

## Status Labels
- Supported / Partial / Manual Setup / Research — honest labels; never round Partial up to Supported.

## Current App Matrix

| App | Status | Current Support |
| --- | --- | --- |
| Serato DJ Pro | Supported | Recording folder, history import; App audio Capture verified (ScreenCaptureKit) |
| rekordbox | Supported | Manual recording folder, XML Bridge / history import; App audio Capture verified end-to-end (meter + archive write) |
| Traktor | Supported | Recordings + NML; App audio Capture verified end-to-end on Traktor DJ 2 (meter + archive write). Pro QML CSI live API = Research only |
| VirtualDJ | Supported | File watch + Network Control; App audio Capture verified end-to-end (meter + archive write). Native plugin = Research (M14) |
| djay Pro | Supported | Documented folders; App audio Capture verified end-to-end on djay Pro 2 (meter + archive write) |
| DJMemory Capture | Implemented | App audio (ScreenCaptureKit) verified end-to-end on Serato, rekordbox, djay Pro 2, VirtualDJ, Traktor DJ 2; Input device (Core Audio); silence session split |
| Pioneer Hardware | Manual Setup | USB PIONEERREC / RECxxx.WAV watch |

## Source map (official vs community / sandbox-safe vs research)

Locked Mac product paths stay **sandbox-safe**. Community live-deck hacks stay **research** until sandbox policy changes.

| Source | Kind | Use in DJMemory |
| --- | --- | --- |
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
→ ScreenCaptureKit filters the running DJ app → silence policy starts/stops/archives takes → stays
watching. Writes **24-bit / 48 kHz** stereo WAV. Requires Screen & System Audio Recording. Does **not**
work when the mix never hits Mac system audio (exclusive interface) — use Input device Capture (also
24-bit / 48 kHz; auto-selects Pioneer/DJM while armed) or folder Protection.

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
