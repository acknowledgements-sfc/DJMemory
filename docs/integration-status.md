# DJMemory Integration Status

Last updated: August 10, 2026.

## Status Labels
- Supported / Partial / Manual Setup / Research — honest labels; never round Partial up to Supported.

## Current App Matrix

| App | Status | Current Support |
| --- | --- | --- |
| Serato DJ Pro | Supported | Recording folder, history import; App audio Capture verified (ScreenCaptureKit) |
| rekordbox | Supported | Manual recording folder, XML import; App audio Capture target (Manual Setup until verified) |
| Traktor | Supported | Recordings + NML; App audio Capture target (Manual Setup until verified) |
| VirtualDJ | Partial | File watch + Network Control; App audio Capture target (Manual Setup until verified) |
| djay Pro | Manual Setup | Documented folders; App audio Capture target (Manual Setup until verified) |
| DJMemory Capture | Manual Setup | App audio (ScreenCaptureKit) verified with Serato; other DJ apps pending; Input device (Core Audio); silence session split |
| Pioneer Hardware | Manual Setup | USB PIONEERREC / RECxxx.WAV watch |

## App Audio Capture (Mac)

Primary Mac feature: when a shareable DJ app is found, **auto-arm** Capture (unless the user Disarmed)
→ ScreenCaptureKit filters the running DJ app → silence policy starts/stops/archives takes → stays
watching. Writes **24-bit / 48 kHz** stereo WAV. Requires Screen & System Audio Recording. Does **not**
work when the mix never hits Mac system audio (exclusive interface) — use Input device Capture (also
24-bit / 48 kHz; auto-selects Pioneer/DJM while armed) or folder Protection.

After each archive (Capture or folder scan), DJMemory **autopulls** a nearby local history export from
known history folders when available, stamps track dates from the set, and matches. Soft-fail leaves
manual Import as the recovery path.

Local verify (2026-08-10): Serato DJ Pro App audio Capture verified end-to-end (Arm → level meter → Stop & Save / archive) with Screen & System Audio Recording granted. rekordbox, Traktor, VirtualDJ, and djay Pro remain Manual Setup for app-audio until verified the same way.

iPad is a **separate** app: no Mac connection; accounts only are shared. On iPad, Capture is device-input only (iPadOS cannot tap another app’s audio).

| Milestone | Scope | Status |
| --- | --- | --- |
| M11 | Capture + Pioneer hybrid | Implemented (Manual Setup until device-verified) |
| M11b | App audio Capture + silence sessions | Implemented (Serato verified; other DJ apps Manual Setup until verified) |
| M12 | Deeper history + capture match window | Partial (post-archive history autopull + 6h match window; no continuous history watcher) |
| M13 | VDJ Network Control commands | Partial |
| M14 | VDJ native plugin | Research |
| M15 | Opt-in cloud sync settings | Settings flags; off by default |
| M16 | User-initiated publish pack | Local export only |
