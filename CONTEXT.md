# DJMemory domain glossary

Terms agents and humans use when changing this codebase. Prefer these names over synonyms.

## Capture

- **Capture session** — The armed App audio session loop: watch → record on energy → idle silence → save or discard → watch again.
- **App audio Capture** — Recording system audio from a running DJ app via ScreenCaptureKit (not a folder copy).
- **Silence session** — Pure policy (`SilenceSessionController`) that decides when a Capture session starts and finalizes from RMS levels.
- **Capture session coordinator** — Deep module (`CaptureSessionCoordinator`) that maps silence events to Capture phases and engine actions; AppModel remains the adapter for permissions, ingest, and notifications.
- **CapturePCMWriter** — Shared convert-and-write helper for Capture PCM buffers (`CaptureService` + `AppAudioCaptureService`).

## Tracklists

- **Tracklist autopull** — After archive, `TracklistAutopull` soft-fails looking for a nearby history export in known history folders and attaches it to the session when proximity match misses.

## Folder access

- **Security-scoped bookmark** — macOS bookmark data that grants DJMemory access to a user-chosen folder across launches.
- **Stale bookmark** — Bookmark that no longer resolves; a recoverable failure — choose the folder again. Never crash; never silently fall through to an unscored path for archive writes in the app.
