# PRD: DJMemory macOS App

Last updated: August 6, 2026.

## Goal

Build a macOS app that automatically preserves DJ set recordings and session metadata across major DJ software.

## Target User

Working DJs who record live sets for review, posting, radio, client delivery, or archiving, and who do not want to remember each app's recording/save workflow during a set.

## Problem

DJ apps usually make recording possible but fragile:

- the DJ must remember to start recording
- the DJ must remember to save/name the file
- track history and audio recording are often separated
- each DJ platform stores recordings and histories differently
- temporary files can be overwritten or lost

## MVP

DJMemory runs as a macOS menu-bar app and watches configured DJ software locations. When it detects a new set recording, it copies it into a DJMemory library, applies a predictable name, and attaches session metadata when available.

### MVP Platforms

1. Serato DJ Pro
2. Traktor
3. VirtualDJ
4. rekordbox
5. djay Pro

### MVP Features

- First-run setup that detects installed DJ apps.
- Per-app adapter cards showing detection status, recording folder, history folder, and permission state.
- Folder access prompts for Music/Documents locations.
- File watcher for new recordings.
- Recording preservation: copy-on-complete into DJMemory library.
- Session record with app name, start/end time, source path, archive path, file size, and status.
- Basic conflict-safe naming: `YYYY-MM-DD HHmm - App Name - Set.ext`.
- Manual "rescan recent recordings" action.
- Exportable metadata JSON next to each archived recording.

### Beta Features

- Serato history export ingestion.
- Traktor NML history parsing.
- VirtualDJ Network Control probe.
- Silence/level validation after recording.
- Post-set rename flow with venue/event fields.
- Auto-copy to Dropbox/Drive/Music folder.

### Later

- Virtual audio device capture mode.
- Optional VirtualDJ plugin.
- Mixcloud/SoundCloud upload preparation.
- Tracklist generation from history.
- AI set summary: genres, energy arc, likely highlights.
- Menu bar now-recording status.

## Non-Goals For MVP

- Bypassing DJ software DRM or streaming restrictions.
- Private API hooking.
- Automatic UI clicking inside DJ apps.
- Replacing each DJ app's native recorder.
- Mobile companion app.

## UX Principles

- The app should feel like a reliable backstage utility, not a content platform.
- The default screen should answer: "Am I protected right now?"
- Setup must avoid dense technical language.
- Every adapter should expose a simple health state: Ready, Needs Folder Access, App Not Found, Needs Setup, Watching.

## Data Model

### DJAppAdapter

- id
- displayName
- bundleIdentifiers
- defaultRecordingLocations
- defaultHistoryLocations
- integrationDepth
- capabilities

### RecordingSession

- id
- sourceApp
- detectedAt
- completedAt
- sourceURL
- archiveURL
- duration
- fileSize
- status
- metadataURL

### TrackPlay

- title
- artist
- startTime
- endTime
- deck
- source

## Architecture

- `DJMemoryCore`: adapters, app detection, file discovery, session model.
- `DJMemoryApp`: SwiftUI menu-bar UI.
- `DJMemoryCLI`: local diagnostics and development probes.
- Future helper: privileged or unsandboxed helper only if needed for audio-device workflows.

## Acceptance Criteria

- On first launch, user can see which DJ apps are installed.
- User can grant access to recording/history folders.
- When a recording appears in a watched folder and stops changing, DJMemory archives it.
- The archived file has a metadata JSON sidecar.
- App never deletes or mutates source recordings.
- User can rescan and recover recently created recordings.

## Open Questions

- Brand name: DJMemory is the current working name.
- Should the MVP be menu-bar only, full-window, or both?
- Do we want direct audio capture in v1, or file-preservation only?
- Which platform should be the first deep integration after Serato: Traktor or VirtualDJ?
