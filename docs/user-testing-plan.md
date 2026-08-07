# DJMemory User Testing Plan

Last updated: August 6, 2026.

## Goal

Validate that DJs can understand, configure, and trust DJMemory without developer help.

The test should answer:

- Does the user know whether they are protected?
- Can they grant folder access?
- Can they archive or find a recording?
- Can they import and attach track history?
- Can they recover when something goes wrong?

## Test Rounds

### Round 1: Internal Smoke Test

Tester: Rob or internal builder.

Use the current local build before inviting anyone else.

Tasks:

- Launch `.build/DJMemory.app`.
- Confirm the app opens to Protection.
- Set a recording folder for one app.
- Run Scan Now.
- Import Serato CSV/TXT, rekordbox XML, and Traktor NML samples when available.
- Open Library.
- Select an archived set.
- Add event, venue, city, tags, and notes.
- Attach and detach a tracklist.
- Export diagnostics.
- Quit and relaunch.
- Confirm folders, imports, notes, and settings persist.

Pass criteria:

- No source files are moved, renamed, or deleted.
- App state survives relaunch.
- Scan/import failures appear in plain language.
- Diagnostics export does not include full track titles by default.

### Round 2: Real DJ File Test

Tester: Rob using real DJ files.

Tasks:

- Use a real Serato recording folder.
- Use a real Serato history export.
- Use a real rekordbox XML export.
- Use a real Traktor NML history file if available.
- Confirm parsed track count and visible track names.
- Confirm archive metadata sidecars are created.
- Confirm manually attaching the right tracklist works.

Pass criteria:

- Real files parse accurately enough to trust.
- Collection exports are not mistaken for one set history.
- Archived sets are easy to find in Finder.
- The Library makes sense with real data volume.

### Round 3: New User Onboarding Test

Tester: DJ who has not seen DJMemory.

Prompt the user with tasks, not instructions:

- Make DJMemory protect your Serato recordings.
- Make DJMemory protect a folder for another DJ app.
- Import a track history.
- Find a saved recording.
- Explain whether you think DJMemory is protecting you.
- Recover from a folder warning.

Observe:

- Where they pause.
- What labels they read.
- Whether they understand folder permissions.
- Whether Protection status is clear.
- Whether Library empty states make sense.
- Whether they can recover without asking for help.

Pass criteria:

- User can complete setup in under five minutes.
- User can explain what DJMemory does and does not do.
- User can identify the protected folder.
- User does not expect DJMemory to upload audio or control DJ software.

### Round 4: Beta Build Test

Tester: external beta tester.

Tasks:

- Download or receive packaged app.
- Open without terminal commands.
- Grant folder access.
- Run Scan Now.
- Import a history file.
- Export diagnostics.
- Quit and relaunch.

Pass criteria:

- App launches without confusing Gatekeeper/signing friction.
- Folder permissions survive relaunch.
- Beta tester can report a useful bug with diagnostics.
- Known limitations are visible and honest.

### Round 5: Accounts and Admin Test

Run this only after account/backend implementation exists.

Tasks:

- Sign up or sign in.
- Confirm local protection still works without cloud upload.
- Confirm device appears in account.
- Confirm admin can view invite/license/device state.
- Confirm admin cannot see audio or full tracklist contents by default.
- Confirm admin changes are audited.

Pass criteria:

- Accounts do not block local-first protection.
- Admin tools are support-focused.
- Sensitive DJ content remains private by default.

## Notes to Capture

For each session, capture:

- tester role and DJ software used
- macOS version
- DJMemory version or commit
- files tested
- task completion notes
- moments of confusion
- bugs found
- feature requests
- trust rating from 1 to 5
- setup confidence from 1 to 5

## Stop Conditions

Stop the test if:

- the app might modify original DJ files
- the user cannot recover from a permission issue
- imported data appears to expose private tracklists unexpectedly
- the app crashes during archive or import
