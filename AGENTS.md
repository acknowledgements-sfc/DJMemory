# DJMemory

Native macOS utility that automatically backs up DJ set recordings from Serato DJ Pro, rekordbox,
Traktor, VirtualDJ, and djay Pro. Local-first. Swift Package Manager, SwiftUI, macOS 14+.

## Commands

```sh
swift build                        # build all targets
swift test                         # DJMemoryCoreTests
swift run DJMemoryApp              # run the SwiftUI app
swift run djmemory probe           # CLI: detect installed DJ software
swift run djmemory scan            # CLI: one-shot scan of configured folders
swift run djmemory watch           # CLI: continuous watch
swift run djmemory virtualdj-network
bash scripts/build-app.sh          # produce .build/DJMemory.app (ad-hoc signed)
bash scripts/smoke-app.sh          # UI smoke test — run before finishing UI work
bash scripts/open-xcode.sh
```

There are **no external package dependencies**. Do not add one without saying why in the PR
description; prefer the platform SDK.

## Layout

- `Package.swift` — tools 5.10, `.macOS(.v14)`. Products: `DJMemoryApp` (executable),
  `djmemory` (CLI executable), `DJMemoryCore` (library).
- `Sources/DJMemoryCore/` — all models, stores, scanning, and archiving. **No SwiftUI, no AppKit
  UI.** This layer is unit-tested and must stay UI-agnostic.
- `Sources/DJMemoryCLI/` — thin CLI over Core.
- `Sources/DJMemoryApp/` — SwiftUI app. `DJMemoryApp.swift` (entry), `AppModel.swift`
  (`@MainActor ObservableObject`, the single view-model), `ContentView.swift`,
  `MenuBarStatusView.swift`, `LocalNotificationService.swift`.
- `Sources/DJMemoryApp/Theme/` — design tokens and primitives.
- `Sources/DJMemoryApp/Views/` — one view per file.
- `Tests/DJMemoryCoreTests/`
- `docs/` — `prd.md`, `research.md`, `integration-status.md`,
  `onboarding-accounts-security.md`, `automation-testing-plan.md`, `user-testing-plan.md`,
  `beta-release-checklist.md`.
- `packaging/DJMemory.entitlements`

## Architecture rules

- **`AppModel` is the only view model.** Views read `@Published` state via `@EnvironmentObject` and
  call `AppModel` methods. No view owns persistence, file IO, or scanning.
- **All mutation goes through `AppModel`.** Its `@Published` properties are `private(set)`; keep
  them that way.
- **New domain logic belongs in `DJMemoryCore` with a unit test**, not in a view.
- Persistence lives in `~/Library/Application Support/DJMemory/` as JSON
  (`settings.json`, `set-contexts.json`, activity log, folder access). New fields must decode
  against files written by older builds — give every added property a `Codable` default.
- Folder access uses **security-scoped bookmarks** via `FolderAccessStore`. Never hardcode a path
  outside `PathResolver` / `SupportedDJSoftware`.
- `ScanCoordinator.scanRecent(requests:hoursBack:now:)` is the single scan entry point.

## UI rules

- Read `HANDOFF.md` before UI work. It owns the token table, screen specs, state matrix, and copy.
- **Use tokens from `Theme/Tokens.swift` only.** No raw hex, no `cornerRadius:` literals, no
  `.green` / `.red` / `.yellow` / `.quaternary` in view code.
- Dark appearance is the default; every screen must be correct in both.
- Dense, native, quiet: body 12pt, radii ≤ 8, 1px hairline dividers, monospaced digits in tables,
  monospaced paths. No gradients, no hero sections, no decorative illustrations.
- One view per file in `Views/`, `internal` not `private`, with a `#Preview` per state it owns.
- **Preserve every existing `.accessibilityIdentifier`** (`sidebar.*`, `onboarding.*`,
  `protection.*`, `protectionSource.<id>.*`, `setup.<id>.*`, `historyImport.<id>.*`, `library.*`,
  `setDetail.<id>.*`, `tracklistDetail.<id>.*`, `settings.*`, `activity.*`,
  `virtualdj.networkControl.check`, `header.openArchiveFolder`). `scripts/smoke-app.sh` depends on
  them. Add identifiers for new controls in the same shape.
- Every error state must name what happened in plain language and offer at least one button that
  resolves it. No dead ends.

## Product non-negotiables

1. **Local-first.** No network calls for archiving, scanning, or tracklist parsing.
2. **Audio files are never uploaded by default**, and the UI says so.
3. **Full tracklists stay on this Mac** unless the user explicitly exports them.
4. **Source recordings are never moved, renamed, or deleted** — copy only.
5. **Honest support labels.** `IntegrationSupportStatus` is user-visible; never present `partial`,
   `manualSetup`, or `research` as `supported`.
6. **Diagnostics exports contain metadata only** — paths, timings, counts, error strings. Never
   audio, never track titles.
7. Local protection never depends on an account.

## Code quality

- Match the surrounding style; the codebase uses no linter config.
- `swift build` must be warning-free for code you touch.
- Prefer `ContentUnavailableView` for empty states, `Table` for tabular data,
  `NavigationSplitView` for the shell.
- Keep view files under ~250 lines. If one grows past that, extract a subview.
