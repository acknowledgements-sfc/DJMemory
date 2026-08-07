# Figma Make Prompt: DJMemory User Flows and Screens

Last updated: August 6, 2026.

Use this prompt in Figma Make to generate editable user flows and screen designs for DJMemory.

```text
Design a complete editable Figma product flow for DJMemory, a native macOS app for DJs.

Product context:
DJMemory is a macOS safety-net app for DJs. It watches recording folders used by DJ software, waits until set recordings are complete, copies them into a durable local archive, writes metadata sidecars, imports track history when available, and helps DJs find and organize saved sets. The app is local-first. It must never imply that audio files or full tracklists are uploaded by default.

Primary user:
A working or semi-working DJ using a Mac. They may use Serato DJ Pro, rekordbox, Traktor, VirtualDJ, or djay Pro. They want confidence that a recorded set will not be lost after a gig or practice session.

Core product question:
"Am I protected right now?"

Design style:
Native macOS utility app. Quiet, polished, trustworthy, dense enough for real repeated use. Avoid marketing-page styling, big hero sections, decorative gradients, or playful illustrations. Use a clear sidebar, strong status hierarchy, compact cards or panels, native tables, clear empty states, and visible next actions. Keep cards at 8px radius or less. Use icons for actions where appropriate. Make the product feel like a reliable DJ workflow tool, not a consumer social app.

Main navigation:
1. Protection
2. Library
3. Activity
4. Settings
5. DJ app setup entries for:
   - Serato DJ Pro
   - rekordbox
   - Traktor
   - VirtualDJ
   - djay Pro

Integration statuses:
- Serato DJ Pro: Supported
- rekordbox: Supported
- Traktor: Supported
- VirtualDJ: Partial
- djay Pro: Manual Setup

Key screens to design:

1. First-run onboarding
- Welcome: DJMemory backs up sets recorded by DJ software.
- Choose DJ apps: show supported apps and honest support labels.
- Folder permissions: recording folder first, optional history folder second.
- Archive location: default is ~/Music/DJMemory.
- Optional history import: Serato CSV/TXT, rekordbox XML, Traktor NML.
- Ready state: show protected apps and Scan Now.

2. Protection dashboard
- Primary status: Protected, Needs Setup, Scanning, Attention Needed.
- Metrics: Protected Sources, Archived Sets, Imported Histories.
- Source rows for each DJ app with:
  - app name
  - setup state
  - support status
  - recording folder path
  - quick action: Setup
  - quick action: Choose Folder
  - quick action: Scan Now
- Empty state when no folder is configured.
- Warning state when saved folder is inaccessible.

3. DJ app setup screen
- App title and support label.
- Set Recording Folder button.
- Set History Folder button.
- Status tiles:
  - State
  - App found / not found
  - Recordings ready / needs folder
  - History found / optional
- Folder list with reveal and clear actions.
- Track History import section.
- Latest scan result section.
- Plain-language setup steps.

4. Library screen
- Archived Sets table:
  - recording
  - app
  - tracks
  - duration
  - size
  - matched tracklist
  - archived path
- Imported Tracklists table:
  - file
  - app
  - tracks
  - kind: Set History or Collection
  - preview
- Empty states for no archived sets and no imported tracklists.

5. Archived set detail panel
- Recording filename
- app name
- duration
- file size
- source path
- archive path
- buttons: Reveal Source, Reveal Archive
- editable fields:
  - Event
  - Venue
  - City
  - Tags
  - Private Notes
- matched tracklist preview
- manual tracklist picker
- buttons: Apply Match, Detach, Save Details
- related activity list

6. Tracklist detail panel
- Imported file name
- app name
- kind
- track count
- search field
- track table with number, title, artist, played time
- reveal source file action

7. Activity screen
- Activity log rows for:
  - scans
  - archives
  - imports
  - errors
  - diagnostics exports
- Export Diagnostics button.
- Clear Activity button.
- Empty state.
- Error row state with clear next action.

8. Settings screen
- Automatic scanning toggle.
- Scan interval segmented control.
- Archive naming template field.
- Example archive name.
- Current state panel:
  - archive folder
  - protected sources
  - imported tracklists
- Future account section placeholder:
  - Sign in optional
  - Local protection works without account
  - No audio upload by default

9. Account and backend concept screens
These are design concepts only, not implementation requirements yet.
- Optional sign-in screen.
- Account settings screen:
  - email
  - devices
  - license/beta status
  - release channel
- Admin dashboard concept:
  - user lookup
  - beta invite status
  - device list
  - license status
  - diagnostics metadata only
  - audit log
- Security copy must make clear admins cannot access audio or full tracklists by default.

10. Permission recovery flow
- Saved folder is missing or inaccessible.
- Explain what happened in plain language.
- Button: Choose Folder Again.
- Button: Clear Folder.
- Confirm recovered state.

Deliverables:
- Create an editable flow map showing the user journey from first launch to protected state to archived set review.
- Create editable macOS desktop screens for every screen listed above.
- Include realistic sample data:
  - Serato DJ Pro
  - rekordbox
  - Traktor
  - VirtualDJ
  - djay Pro
  - archived set: "2026-08-06 2230 - Serato DJ Pro - Set.wav"
  - venue: "Room 2"
  - city: "San Francisco"
  - tags: "house, late-night"
- Include component states:
  - Protected
  - Needs Setup
  - Scanning
  - Attention Needed
  - Supported
  - Partial
  - Manual Setup
  - Set History
  - Collection
- Use clear labels and no placeholder lorem ipsum.
- Make all screens editable, organized, and named clearly.
```
