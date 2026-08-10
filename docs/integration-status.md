# DJMemory Integration Status

Last updated: August 9, 2026.

## Status Labels
- Supported / Partial / Manual Setup / Research — honest labels; never round Partial up to Supported.

## Current App Matrix

| App | Status | Current Support |
| --- | --- | --- |
| Serato DJ Pro | Supported | Recording folder, history import; App audio Capture target (Manual Setup until verified) |
| rekordbox | Supported | Manual recording folder, XML import; App audio Capture target (Manual Setup until verified) |
| Traktor | Supported | Recordings + NML; App audio Capture target (Manual Setup until verified) |
| VirtualDJ | Partial | File watch + Network Control; App audio Capture target (Manual Setup until verified) |
| djay Pro | Manual Setup | Documented folders; App audio Capture target (Manual Setup until verified) |
| DJMemory Capture | Manual Setup | App audio (ScreenCaptureKit) + Input device (Core Audio); silence session split |
| Pioneer Hardware | Manual Setup | USB PIONEERREC / RECxxx.WAV watch |

## App Audio Capture (Mac)

Primary Mac feature: arm Capture → ScreenCaptureKit filters a running DJ app → silence policy starts/stops/archives takes → re-arms. Requires Screen & System Audio Recording. Does **not** work when the mix never hits Mac system audio (exclusive interface).

Local verify (2026-08-09): ad-hoc `.build/DJMemory.app` launches after stripping `associated-domains` from ad-hoc entitlements; Serato installed/running; `djmemory app-audio-probe` returns `permissionDenied` until Screen & System Audio Recording is granted for DJMemory. Per-app meter/archive still Manual Setup until that grant + a live take succeed.

iPad is a **separate** app: no Mac connection; accounts only are shared. On iPad, Capture is device-input only (iPadOS cannot tap another app’s audio).

| Milestone | Scope | Status |
| --- | --- | --- |
| M11 | Capture + Pioneer hybrid | Implemented (Manual Setup until device-verified) |
| M11b | App audio Capture + silence sessions | Implemented (Manual Setup until verified per DJ app) |
| M12 | Deeper history + capture match window | Partial |
| M13 | VDJ Network Control commands | Partial |
| M14 | VDJ native plugin | Research |
| M15 | Opt-in cloud sync settings | Settings flags; off by default |
| M16 | User-initiated publish pack | Local export only |
