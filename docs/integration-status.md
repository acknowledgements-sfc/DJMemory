# DJMemory Integration Status

Last updated: August 6, 2026.

## Status Labels

- Supported: DJMemory has a credible file/history path implemented or wired for normal use.
- Partial: DJMemory can detect or watch likely files, but the integration needs real-world verification.
- Manual Setup: DJMemory can work if the user chooses folders manually.
- Research: visible only when the app should not imply current support.

## Current App Matrix

| App | Status | Current Support | Next Verification |
| --- | --- | --- | --- |
| Serato DJ Pro | Supported | Default recording folder, history import, archive scanning | More real Serato history exports |
| rekordbox | Supported | Manual recording folder, XML collection import, archive scanning | Real rekordbox history/session export format |
| Traktor | Supported | Default recording folder, versioned history discovery, NML import | Real Traktor NML history files from multiple versions |
| VirtualDJ | Partial | App detection, likely user folder, manual file watching | Confirm recording/history defaults and database/history formats |
| djay Pro | Manual Setup | App detection, user-selected recording folder | Confirm default recording/export locations |

## Milestone 10 Boundary

Milestone 10 completes the file-based integration expansion. It does not include:

- direct audio capture
- VirtualDJ native plugin
- VirtualDJ Network Control implementation
- cloud sync
- publishing workflows

Those belong after the core safety-net product is stable.
