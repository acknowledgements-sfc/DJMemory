# DJMemory domain glossary

Terms agents and humans use when changing this codebase. Prefer these names over synonyms.

## Capture

- **Capture session** — The armed App audio session loop: watch → record on energy → idle silence → save or discard → watch again.
- **App audio Capture** — Recording system audio from a running DJ app via ScreenCaptureKit (not a folder copy).
- **Silence session** — Pure policy (`SilenceSessionController`) that decides when a Capture session starts and finalizes from RMS levels.
- **Capture session coordinator** — Deep module (`CaptureSessionCoordinator`) that maps silence events to Capture phases and engine actions; AppModel remains the adapter for permissions, ingest, and notifications.
- **CapturePCMWriter** — Shared convert-and-write helper for Capture PCM buffers (`CaptureService` + `AppAudioCaptureService`). `convert` returns a `(buffer, error)` tuple, not `Result`.
- **App-audio pre-roll** — Ring of already-converted `writeFormat` buffers captured while watching, flushed when a take starts so the archive begins at the true first signal (`prerollSeconds` = start hold + 0.5s).

## Tracklists

- **Tracklist autopull** — After archive, `TracklistAutopull` soft-fails looking for a nearby history export in known history folders and attaches it to the session when proximity match misses.
- **History auto-ingest** — Continuous sweep (`HistoryAutoIngest`) of granted + default history folders: FSEvents, 3s debounce, periodic-scan backstop, launch catch-up. Idempotent; does not override a user's manual pin.
- **JSONL plugin ingest** — `JSONLTracklistParser` reads VirtualDJ plugin drop files (`.jsonl` in `~/Documents/VirtualDJ/DJMemoryDrop`). Only `track_play` events become `TrackPlay` rows (`source: "virtualdj-plugin"`). Spec: `docs/m14-vdj-plugin-spec.md`. The C++ `.bundle` (Artifact A) is not in this repo yet.

## Folder access

- **Security-scoped bookmark** — macOS bookmark data that grants DJMemory access to a user-chosen folder across launches.
- **Stale bookmark** — Bookmark that no longer resolves; a recoverable failure — choose the folder again. Never crash; never silently fall through to an unscored path for archive writes in the app.
