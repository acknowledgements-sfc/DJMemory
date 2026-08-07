# DJMemory MVP Readiness Audit

Last updated: August 6, 2026.

This audit maps the v0.1 PRD acceptance criteria to current implementation evidence and the manual checks still needed before handing a beta to DJs.

## Automated Evidence

Current passing baseline:

- `swift test`: 61 tests, 0 failures.
- `bash scripts/smoke-cli.sh`: CLI archive/scan/diagnostics smoke path passes.
- `bash scripts/build-app.sh`: `.build/DJMemory.app` builds and signs with sandbox-oriented entitlements.
- `bash scripts/smoke-app.sh`: packaged app launches, verifies code signature, performs best-effort window detection, and quits cleanly.
- `bash scripts/package-beta.sh`: creates a versioned zip and JSON manifest under `.build/distribution/`.

## Acceptance Criteria

| Requirement | Status | Evidence | Manual Beta Check |
| --- | --- | --- | --- |
| User can install/run DJMemory on macOS. | Ready for local beta | `scripts/build-app.sh`, `scripts/smoke-app.sh`, `scripts/package-beta.sh`, `packaging/DJMemory.entitlements` | Open the packaged zip on a clean tester Mac and confirm macOS launch prompts are understandable. |
| User can configure at least one watched recording folder. | Ready for local beta | `FolderAccessStoreTests`, folder chooser flow in `AppModel.chooseFolder`, setup controls in `ContentView` | Choose Serato and rekordbox recording folders through the app picker and relaunch to confirm persistence. |
| DJMemory archives a completed recording without changing the source file. | Automated | `ArchiveServiceTests.testArchiveCopiesSourceAndWritesMetadata`, `ScanCoordinatorTests.testScanRecentArchivesAudioFromRequestsAndSkipsDuplicateScan`, `scripts/smoke-cli.sh` | Place a real short recording in a watched folder and confirm the original remains unchanged. |
| Archived recordings appear in the library. | Ready for local beta | `SessionLibraryTests`, `LibrarySessionMatcherTests`, library table/detail views in `ContentView` | Archive a test recording from the app, then confirm it appears in Library with reveal actions. |
| Each archived recording has a metadata JSON sidecar. | Automated | `ArchiveServiceTests.testArchiveCopiesSourceAndWritesMetadata`, `ArchiveServiceTests.testArchiveMetadataIncludesDurationField`, `SessionLibraryTests` | Open the archived folder and confirm audio plus `.json` sidecar are visible. |
| Manual rescan can recover recent recordings from watched folders. | Automated | `ScanCoordinatorTests`, `scripts/smoke-cli.sh`, app `Rescan Last 24 Hours` actions | Add a stable audio file while DJMemory is open, click Rescan Last 24 Hours, and confirm archive creation. |
| Recording folders trigger automatic protection while the app is open. | Automated with manual follow-up | `FolderChangeMonitorTests`, `AppModel` debounced folder-change scan, one-minute scheduled scan backup | Add or modify a file in a watched folder and confirm Next Scan shows `Soon`, then the scan runs. |
| Serato defaults are detected when folders exist. | Automated | `SupportedDJSoftwareTests`, `SoftwareProbe`, Serato defaults in `DJSoftware` | Confirm `~/Music/_Serato_/Recording` appears on a Mac with Serato data. |
| rekordbox installation is detected when available. | Automated model, needs real app check | `SupportedDJSoftwareTests`, `SoftwareProbe`, rekordbox bundle id in `DJSoftware` | Install/open rekordbox and confirm the app row shows installed or running. |
| Default archive location is `~/Music/DJMemory`, with Settings support for a custom archive folder. | Automated | `ArchiveServiceTests.testDefaultArchiveRootIsMusicDJMemory`, `AppSettingsStoreTests`, archive chooser in `AppModel.chooseArchiveFolder` | Choose a custom archive folder, relaunch, and confirm new archives land there. |
| Permission errors are visible and understandable. | Automated with manual follow-up | `ScanCoordinatorTests.testScanRecentCapturesErrorsPerFolder`, `testScanRecentReportsPlainLanguageErrorWhenPathIsAFile`, `testScanRecentReportsArchiveFolderUnavailable`, Protection attention state, CLI diagnostics export | Move or revoke a saved folder and confirm the row says recovery is needed and protected-source count excludes it. |

## Should-Have Coverage

| Item | Status | Evidence |
| --- | --- | --- |
| Serato default folder detection | Implemented | `DJSoftware`, `SoftwareProbe`, `SupportedDJSoftwareTests` |
| rekordbox installed-app detection | Implemented | `DJSoftware`, `SoftwareProbe`, `SupportedDJSoftwareTests` |
| Default archive folder creation | Implemented | `ArchiveService.ensureArchiveRootExists`, app launch refresh path, `ArchiveServiceTests` |
| User-editable archive naming template | Implemented | `AppSettings`, settings UI, `ArchiveServiceTests.testArchiveUsesCustomNamingTemplate` |
| Failure state with plain-language next step | Implemented | `ScanCoordinator.scanErrorDescription`, UI attention states, scanner tests |
| Basic diagnostics export | Implemented | `DiagnosticsReportBuilder`, app export action, CLI `diagnostics` command, `DiagnosticsReportTests`, `scripts/smoke-cli.sh` |

## Known Manual Validation Still Required

- Real Serato recording folder and history export on a DJ machine.
- Real rekordbox install and XML/history export on a DJ machine.
- macOS folder picker behavior under a clean user account.
- Menu-bar behavior during a real recording session.
- Notarized Developer ID build path before broad direct-download distribution.
