# DJMemory Integration Status

Last updated: August 10, 2026.

## Status Labels
- Supported / Partial / Manual Setup / Research — honest labels; never round Partial up to Supported.

## Current App Matrix

| App | Status | Current Support |
| --- | --- | --- |
| Serato DJ Pro | Supported | Recording folder, history import; App audio Capture verified (ScreenCaptureKit) |
| rekordbox | Supported | Manual recording folder, XML Bridge / history import; App audio Capture arm/shareable OK (Manual Setup until live meter + archive verified) |
| Traktor | Supported | Recordings + NML; App audio Capture arm OK on Traktor DJ 2 (Manual Setup until live meter + archive verified). Pro QML CSI live API = Research only |
| VirtualDJ | Partial | File watch + Network Control; App audio Capture arm/shareable OK (Manual Setup until live meter + archive verified). Native plugin = Research (M14) |
| djay Pro | Manual Setup | Documented folders; App audio Capture arm OK on djay Pro 2 (Manual Setup until live meter + archive verified) |
| DJMemory Capture | Manual Setup | App audio (ScreenCaptureKit) verified with Serato; other DJ apps pending live meter; Input device (Core Audio); silence session split |
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
| VirtualDJ native plugin | SDK | Research (M14) |

See `docs/research.md` for per-app depth and links.

## App Audio Capture (Mac)

Primary Mac feature: when a shareable DJ app is found, **auto-arm** Capture (unless the user Disarmed)
→ ScreenCaptureKit filters the running DJ app → silence policy starts/stops/archives takes → stays
watching. Writes **24-bit / 48 kHz** stereo WAV. Requires Screen & System Audio Recording. Does **not**
work when the mix never hits Mac system audio (exclusive interface) — use Input device Capture (also
24-bit / 48 kHz; auto-selects Pioneer/DJM while armed) or folder Protection.

After each archive (Capture or folder scan), DJMemory **autopulls** a nearby local history export from
known history folders when available, stamps track dates from the set, and matches. Soft-fail leaves
manual Import as the recovery path.

Local verify (2026-08-10):

- **Serato DJ Pro** — App audio Capture verified end-to-end (Arm → level meter → Stop & Save / archive) with Screen & System Audio Recording granted.
- **rekordbox / djay Pro 2 / VirtualDJ / Traktor DJ 2 (`com.native-instruments.tmnt`)** — live probe pass with all four apps open (preflight true; each shareable + `ARMED_OK`; each **SILENT_METER** / peak `0.0000` — no deck audio on Mac system output during the run). Labels **not** raised. Re-run with decks playing to system audio until `PASS meter+write`, then raise that app only. Probe: `.build/DJMemory.app/Contents/MacOS/DJMemory --app-audio-probe <softwareID>`.

Do **not** start Traktor QML injection, SSL-API, or Twitch Live Playlist integration in the sandboxed Mac app.

iPad is a **separate** app: no Mac connection; accounts only are shared. On iPad, Capture is device-input only (iPadOS cannot tap another app’s audio).

| Milestone | Scope | Status |
| --- | --- | --- |
| M11 | Capture + Pioneer hybrid | Implemented (Manual Setup until device-verified) |
| M11b | App audio Capture + silence sessions | Implemented (Serato verified; other DJ apps Manual Setup until live meter + archive verified) |
| M12 | Deeper history + capture match window | Partial (post-archive history autopull + 6h match window; no continuous history watcher) |
| M13 | VDJ Network Control commands | Partial |
| M14 | VDJ native plugin | Research |
| M15 | Opt-in cloud sync settings | Settings flags; off by default |
| M16 | User-initiated publish pack | Local export only |
