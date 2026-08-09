# DJMemory MVP Readiness Audit

Last updated: August 9, 2026.

This audit maps the v0.1 PRD acceptance criteria to current implementation evidence and the manual checks still needed before handing a beta to DJs.

## Automated Evidence

Current passing baseline (commit `5301588`, 2026-08-07):

- `swift test`: 91 tests, 0 failures.
- `bash scripts/smoke-cli.sh`: CLI archive/scan/diagnostics smoke path passes.
- `swift build --product DJMemoryApp`: passes.
- `bash scripts/build-app.sh release`: `.build/DJMemory.app` builds and signs with sandbox-oriented entitlements.
- `codesign --verify --deep --strict .build/DJMemory.app`: passes.
- `bash scripts/smoke-app.sh`: packaged app launches, verifies code signature, performs best-effort window detection, and quits cleanly.
- `bash scripts/package-beta.sh`: creates `.build/distribution/DJMemory-0.1.0-ff5e0c6.zip` + JSON manifest with matching SHA-256 (`c11df4c7…`) from the prior package cut; re-run after new commits for a matching SHA.
- `swift run djmemory diagnostics <path>`: writes metadata-only report (counts, paths, activity messages; no track titles/artists).
- Signing: ad-hoc sandboxed local beta. Notarization: not notarized (Developer ID path gated; see `docs/signing-and-notarization.md`).

## Manual Beta Results (2026-08-07, Round 1 on this Mac)

| Check | Result | Notes |
| --- | --- | --- |
| Packaged `.app` launches | Pass | `bash scripts/smoke-app.sh`; window check passed; process starts and quits cleanly. |
| Landing route | Pass | Default `selectedRoute = .home` (`AppModel`). Checklist aligned to Home (was incorrectly Protection). |
| Menu-bar item present | Pass | `MenuBarExtra` in `DJMemoryApp.swift`; smoke launch includes menu-bar host. |
| Folder bookmark persistence | Pass | `~/Library/Application Support/DJMemory/folder-access.json` retains 10 accesses with `bookmarkData` across relaunches on this machine. |
| Archive copies source; sidecar written | Pass | `djmemory archive` of 1s WAV → `~/Music/DJMemory/…wav` + `.json`; source SHA-256 unchanged. |
| Diagnostics metadata-only | Pass | CLI diagnostics top-level keys: archiveRootPath, archives, generatedAt, imports, recentActivity, software, totals. No title/artist/tracklist fields. Sidecar has no track titles. |
| Permission / unreachable recovery (unit) | Pass | `FolderAccessStoreTests`, `DiagnosticsReportTests.testProtectedSourceCountExcludesUnreachableRecordingFolders`, Protection attention UI. |
| Unreachable-folder recovery (GUI e2e move/revoke) | Blocked | Needs interactive Finder/revoke on tester Mac; Core + UI wired. |
| Folder-change “Soon” scan timing (GUI) | Blocked | Covered by `FolderChangeMonitorTests` + AppModel debounce; live GUI timing still needs eyes. |
| Library search / import UI | Blocked | Parsers + `LibrarySessionSearchTests` green; CSV samples exist under `~/Music/DJMemory/CSV`; in-app import click not driven in this pass. |
| Real Serato recording folder + history | Blocked | Needs DJ machine with Serato data. |
| Real rekordbox install + XML/history | Blocked | Needs Mac with rekordbox installed. |
| Menu-bar during live recording session | Blocked | Needs live DJ session. |
| Clean-user Gatekeeper / notarized open | Blocked | Ad-hoc only until Developer ID + notarization credentials exist. |

## Round 2 readiness (2026-08-09)

Automation and packaging scripts are ready. Round 2 remains **owner: product tester on a DJ Mac**.

| Item | Status |
| --- | --- |
| `scripts/build-app.sh` / `package-beta.sh` / `notarize-app.sh` | Ready (Developer ID gated) |
| Account client APIs (`/api/devices`, `/api/license`, `/api/diagnostics`) | Implemented; needs deployed admin + service role |
| iPad companion scheme `DJMemoryiPad` | Builds via `xcodegen` + Xcode (iOS 17+) |
| Serato / rekordbox live folder + history | Still blocked — needs DJ Mac |
| Notarized direct-download | Still blocked — needs Developer ID + notary credentials (see `docs/signing-and-notarization.md`) |

Run Round 2 from `docs/user-testing-plan.md` after a Developer ID or notarized build when available.

## Acceptance Criteria

| Requirement | Status | Evidence | Manual Beta Check |
| --- | --- | --- | --- |
| User can install/run DJMemory on macOS. | Ready for local beta | `scripts/build-app.sh`, `scripts/smoke-app.sh`, `scripts/package-beta.sh`, `packaging/DJMemory.entitlements` | Open the packaged zip on a clean tester Mac and confirm macOS launch prompts are understandable. **Blocked** until notarized build. |
| User can configure at least one watched recording folder. | Ready for local beta | `FolderAccessStoreTests`, folder chooser flow in `AppModel.chooseFolder`, setup controls | **Pass** on this Mac: bookmarks persist in `folder-access.json`. Reconfirm Serato/rekordbox pickers on DJ machine. |
| DJMemory archives a completed recording without changing the source file. | Automated + Pass | Archive tests, smoke-cli, 2026-08-07 CLI archive hash match | Place a real short recording in a watched folder and confirm the original remains unchanged. |
| Archived recordings appear in the library. | Ready for local beta | `SessionLibraryTests`, library views | Archive a test recording from the app, then confirm Library + search. **Blocked** for GUI click-path. |
| Each archived recording has a metadata JSON sidecar. | Automated + Pass | Archive tests; 2026-08-07 sidecar next to archived WAV | Open the archived folder and confirm audio plus `.json` sidecar are visible. |
| Manual rescan can recover recent recordings from watched folders. | Automated | `ScanCoordinatorTests`, `scripts/smoke-cli.sh`, app Rescan actions | Add a stable audio file while open, Rescan Last 24 Hours. |
| Recording folders trigger automatic protection while the app is open. | Automated with manual follow-up | `FolderChangeMonitorTests`, AppModel debounce | Confirm Next Scan shows `Soon`. **Blocked** GUI. |
| Serato defaults are detected when folders exist. | Automated | `SupportedDJSoftwareTests`, `SoftwareProbe` | Confirm on Mac with Serato data. **Blocked**. |
| rekordbox installation is detected when available. | Automated model, needs real app check | `SupportedDJSoftwareTests`, `SoftwareProbe` | Confirm installed/running. **Blocked**. |
| Default archive location is `~/Music/DJMemory`, with Settings support for a custom archive folder. | Automated + Pass | Archive tests; archive landed in `~/Music/DJMemory` | Choose a custom archive folder, relaunch. |
| Permission errors are visible and understandable. | Automated with manual follow-up | Scan error tests, Protection attention, diagnostics | GUI move/revoke recovery. **Blocked** e2e. |

## Should-Have Coverage

| Item | Status | Evidence |
| --- | --- | --- |
| Serato default folder detection | Implemented | `DJSoftware`, `SoftwareProbe`, `SupportedDJSoftwareTests` |
| rekordbox installed-app detection | Implemented | `DJSoftware`, `SoftwareProbe`, `SupportedDJSoftwareTests` |
| Default archive folder creation | Implemented | `ArchiveService.ensureArchiveRootExists`, app launch refresh path, `ArchiveServiceTests` |
| User-editable archive naming template | Implemented | `AppSettings`, settings UI, `ArchiveServiceTests.testArchiveUsesCustomNamingTemplate` |
| Failure state with plain-language next step | Implemented | `ScanCoordinator.scanErrorDescription`, UI attention states, scanner tests |
| Basic diagnostics export | Implemented | `DiagnosticsReportBuilder`, app export action, CLI `diagnostics` command, `DiagnosticsReportTests`, `scripts/smoke-cli.sh` |

## Known Manual Validation Still Required (Blocked)

Owner: product tester on a DJ Mac. Next step: run Round 2 from `docs/user-testing-plan.md` after a notarized or Developer ID build when available.

- Real Serato recording folder and history export on a DJ machine.
- Real rekordbox install and XML/history export on a DJ machine.
- macOS folder picker behavior under a clean user account.
- Menu-bar behavior during a real recording session.
- Unreachable-folder recovery flow end-to-end (move/revoke → Attention → re-choose → clear) in the GUI.
- Folder-change “Soon” timing in the live UI.
- In-app tracklist import + library search click-path.
- Notarized Developer ID build path before broad direct-download distribution.

## Local Beta Known-Issues Snapshot (5301588)

- **Supported:** Serato DJ Pro, rekordbox, Traktor
- **Partial:** VirtualDJ
- **Manual Setup:** djay Pro, DJMemory Capture, Pioneer Hardware
- **Unsupported formats:** anything outside watched recording extensions / documented history parsers
- **Parser limitations:** see `docs/integration-status.md` (VDJ plugin research; capture match window partial)
- **Signing / notarization:** ad-hoc sandboxed local beta; **not notarized** (`DJMEMORY_DISTRIBUTION=developer-id` + `scripts/notarize-app.sh` ready when Developer ID cert exists; see `docs/signing-and-notarization.md`)
- **Accounts / admin:** optional web app in `admin/` (Clerk + Supabase + Vercel); macOS Settings deep-links via `settings.openAccount` — local protection never depends on it
- **Minimum macOS:** 14.0
- **Landing route:** Home
- **Folder permission recovery:** Protection / Recovery UI — choose a different folder, or clear saved folder (sources are never deleted)
