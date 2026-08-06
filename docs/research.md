# Research Notes

Last checked: August 6, 2026.

## Competitor: Serauto

Serauto appears to target the core Serato pain: DJs forget to save recordings or lose temporary recordings. The public site at `https://www.serauto.app/` currently presents itself as "Stereo Aura - DJ Platform"; search results and community mentions still associate Serauto with Serato auto-recording.

Working assumption: Serauto is a narrow Serato-focused utility, likely watching Serato recording/temp folders and helping preserve recent recordings. This needs hands-on verification by installing or inspecting the app if available.

## Adjacent Competitors

- Native recording in DJ apps: Serato, rekordbox, VirtualDJ, Traktor, and djay all have some recording workflow, but usually require manual start/save and do not create a cross-platform archive.
- DAWs/editors: Audacity, Ableton Live, Logic Pro, and GarageBand can record audio, but they do not know what DJ app/session produced the set.
- Playlist/history tools: DJCU, MIXO, Lexicon, rekordcloud, and similar tools handle library conversion/metadata, not automatic capture.
- Streaming/publishing workflows: Mixcloud, SoundCloud, Dropbox/Drive folders, and podcast tooling start after the recording exists.

## Integration Depth By Platform

### Serato DJ Pro

Likely depth: medium for file-based recording recovery, low for official control.

Observed public surfaces:

- Default macOS recording path: `~/Music/_Serato_/Recording`.
- Serato history includes sessions, played tracks, export to txt/csv/m3u, and Serato Playlists.
- No obvious public SDK/API for external control.

MVP integration:

- Watch `~/Music/_Serato_/Recording`.
- Detect Serato running.
- Preserve new or changed recording files.
- Read exported history files if the user points DJMemory at `History Export`.
- Later: investigate live `.session` parsing, but treat it as brittle.

### rekordbox

Likely depth: low to medium.

Observed public surfaces:

- rekordbox exposes XML playlist import/export style developer documentation.
- Play histories can be exported/imported in some workflows, but live control is not a clear public API.

MVP integration:

- Watch user-selected recording folder.
- Read exported XML/history artifacts when available.
- Detect rekordbox running and prompt once for the user to configure recording location.

### djay Pro

Likely depth: low until local files are verified.

MVP integration:

- Detect `djay Pro` process.
- Watch user-selected recording folder.
- Add AppleScript/accessibility research later if automation is required.

### VirtualDJ

Likely depth: high relative to the others.

Observed public surfaces:

- VirtualDJ documents SDK customization for skins, controllers, effects/plugins, and database.
- VirtualDJ plugins on Mac are `.bundle` files.
- Community docs mention a Network Control plugin/REST-style local control path.

MVP integration:

- File watch recording/history folders.
- Add an optional VirtualDJ adapter using Network Control if present.
- Later: native VirtualDJ plugin for richer events.

### Traktor

Likely depth: medium for files/history, low for direct control.

Observed public surfaces:

- Traktor root directory lives under `~/Documents/Native Instruments/Traktor <version>`.
- `History` contains automatically saved history playlists.
- Internal recordings live under `~/Music/Traktor/Recordings`.

MVP integration:

- Discover newest Traktor root folder.
- Watch `History` and `~/Music/Traktor/Recordings`.
- Parse NML/XML for session metadata.

## Product Opportunity

The wedge is not "another recorder." It is "never lose a set again":

- automatic recovery and archiving
- session naming based on date, venue, DJ software, and setlist
- waveform/level sanity checks
- one place to find recordings and tracklists across DJ platforms
- post-set actions: normalize, trim silence, export tracklist, upload/share

## Technical Risks

- Sandboxed macOS apps need explicit folder access for Music/Documents folders.
- Audio capture from another app may require a virtual audio driver or Aggregate Device workflow.
- App Store review may object to private APIs or UI automation; stay file-based for MVP.
- Streaming-service recording restrictions may create policy/legal constraints. The product should preserve user recordings but avoid bypassing DRM or app limitations.
