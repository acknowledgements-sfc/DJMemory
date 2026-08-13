# Codex / Claude leave-off — 2026-08-12

Repo: `/Users/robcmartin/Documents/Codex/2026-08-06/i-wan/SetCatcher`
Remote: `origin` → `https://github.com/acknowledgements-sfc/DJMemory.git`
Branch: **`main`**, **not pushed**.

Read `AGENTS.md` first. This file is the fleet leave-off, not the UI spec
(`HANDOFF.md` / `CURSOR-HANDOFF.md`).

---

## Where we stopped

Four local commits landed on `main` after a Claude Code fleet built them in one
working tree and hit a session limit mid-commit. Re-verified **144 tests, 0
failures** before committing. **Do not re-do these commits.**

| Commit | Message |
|---|---|
| `ca4e57f` | Buffer app-audio pre-roll so Capture takes start at first signal. |
| `845fc47` | Watch history folders so late exports still match archived sets. |
| `99c0d63` | Ingest VirtualDJ plugin JSONL drop files as ImportedTracklists. |
| `cb2cf1f` | Specify the VirtualDJ plugin JSONL contract and record fleet leave-off. |

`AppModel.swift` was split across the first two commits on purpose: M11b got
only the `prerollSeconds: startHold + 0.5` hunk; M12 got the history-watcher
rest. Do not squash.

Nothing from this fleet is on `origin` unless someone pushed after this file
was written. Confirm with `git status -sb` / `git log origin/main..HEAD`.

---

## What is done

**M11b pre-roll.** While watching, `AppAudioCaptureService` keeps a converted
PCM ring and flushes it when a take starts. `startMonitoring(..., prerollSeconds:)`
is wired from `AppModel` to `silenceSessionConfig.startHoldSeconds + 0.5`.
`CapturePCMWriter.convert` returns a `(buffer, error)` tuple — **not**
`Result<_, String>`.

**M12 history watcher.** `HistoryAutoIngest` sweeps granted + default history
folders. `AppModel` runs FSEvents, a 3s debounce, a periodic-scan backstop, and
a launch catch-up. `docs/integration-status.md` marks M12 Implemented.

**M14 Artifact B (Swift ingest).** Frozen `v:1` contract:
`docs/m14-vdj-plugin-spec.md`. Implementation:

- `JSONLTracklistParser` + `VirtualDJPluginEvent` in
  `Sources/DJMemoryCore/VirtualDJPluginEvent.swift`
- `.jsonl` routed from `VirtualDJHistoryParser`
- `"jsonl"` in `HistoryFolderIngest.allowedExtensions`
- drop folder `~/Documents/VirtualDJ/DJMemoryDrop` on VirtualDJ
  `defaultHistoryPaths`

Parser rules: only `type: "track_play"` → `TrackPlay`; source
`"virtualdj-plugin"`; confidence `0.95`; consecutive same `(deck, artist,
title)` de-dup; truncated final line skipped; unknown major `v` throws
`.unsupportedVersion`. **Do not rename** `JSONLTracklistParser`.

---

## What is not done (next work)

**M14 Artifact A — not started.** C++ Mac `.bundle` that appends JSONL into
`~/Documents/VirtualDJ/DJMemoryDrop/set-<date>-<session>.jsonl`. Blocked on
verifying the VirtualDJ SDK (spec §3): plugin category, getter verbs, on-air /
crossfader signal, off-audio-thread flush. **No private APIs.** Separate
signing/notarization; not bundled into DJMemory.app.

Do not flip M14 to Supported in `docs/integration-status.md` until a real mix
archives and matches.

Open (spec §9): on-air signal vs inferred play; recue window; `startTime` =
wall-clock `ts` vs `elapsed`; multi-session files.

If SDK headers are not on disk, stop and say so. Do not invent SDK APIs.

---

## Sibling tree — leave it alone

`/Users/robcmartin/Documents/Codex/2026-08-06/i-wan/DJMemory` is a different
clone (GitHub issue #15). Do not mix working trees.

---

## Paste this to start the next session

```
Read AGENTS.md, CONTEXT.md, and HANDOFF-CODEX.md in
/Users/robcmartin/Documents/Codex/2026-08-06/i-wan/SetCatcher.

Fleet work is already committed locally on main (ca4e57f, 845fc47, 99c0d63,
plus the docs commit). Do not re-implement or re-commit it. Not pushed unless
git status says otherwise.

Next: M14 Artifact A (C++ VirtualDJ plugin) only if the user asks and SDK
headers are on disk — see docs/m14-vdj-plugin-spec.md §3. Otherwise stop.
```
