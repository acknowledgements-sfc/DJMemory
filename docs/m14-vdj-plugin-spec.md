# M14 — VirtualDJ Native Plugin Spec

Status: **Research** (M14). Artifact B is implemented and Artifact A now has a
buildable Xcode scaffold. The fixed contract is unchanged. SDK query behavior
marked _(live verify)_ must be confirmed in VirtualDJ before support status can
change.

Related: [virtualdj-plugin-decision.md](virtualdj-plugin-decision.md),
[integration-status.md](integration-status.md),
[research.md](research.md).

---

## 1. Goal & non-goals

**Goal.** Capture richer, real-time set/track events from VirtualDJ than the
file-watch history path provides, and deliver them to DJMemory as an
`ImportedTracklist` (`kind: setHistory`) without private APIs and without
weakening the sandboxed Mac app.

The plugin's only job is to **write append-only JSONL event lines into a local
drop folder**. It never talks to DJMemory over IPC, ports, or the network. The
drop folder is the entire interface between the two artifacts.

**Non-goals for M14.**
- No live control of VirtualDJ (that is Network Control, M13).
- No replacement of the file-watch history path — the plugin is additive and
  must not block Capture verification (see research.md).
- No audio capture — that stays in-app Capture (ScreenCaptureKit / Core Audio).
- No cross-machine sync — that is M15.

## 2. Two artifacts, one contract

| | Artifact | Language / output | Testable without VDJ? |
|---|---|---|---|
| **A** | VirtualDJ plugin | C++, Mac `.bundle` | No — needs VDJ SDK headers + a running VirtualDJ |
| **B** | DJMemory ingest | Swift (`DJMemoryCore`) | **Yes** — pure parser + unit tests over fixture JSONL |

The contract between them is the **JSONL schema (§5)** and the **drop-folder
location + file naming (§6)**. Build B first against fixtures; A can be
developed and validated independently once the schema is frozen.

## 3. SDK surface

Headers are present at
`/Users/robcmartin/Downloads/VirtualDJ8_SDK_20211003`. The Artifact A build
surface is
`virtualdj-plugin-scaffold/DJMemoryVirtualDJPlugin.xcodeproj`.

- VirtualDJ ships a C++ plugin SDK; Mac plugins build as a `.bundle`
  (confirmed in research.md). Bundle identifier space is the plugin's own, not
  `com.atomixproductions.virtualdj`.
- The plugin runs **in-process inside VirtualDJ**, so it inherits VirtualDJ's
  file-access rights, not DJMemory's sandbox. The intended drop path remains
  `~/Documents/VirtualDJ/…`; access from the sandboxed 2026 VirtualDJ build is
  a live-validation item.
- The supplied `vdjPlugin8.h` confirms `IVdjPluginStartStop8`, `OnLoad`,
  `OnGetPluginInfo`, `OnStart`, `OnStop`, `GetInfo`, `GetStringInfo`, and the
  exported `DllGetClassObject` entry point. Artifact A uses this non-DSP base
  and does not depend on the audio/video plugin headers.
- Candidate VDJScript getter strings are centralized in `VDJSDKAdapter.cpp`:
  `deck N get_artist`, `deck N get_title`, `deck N play`, and
  `deck N get_time elapsed`. Their behavior is _(live verify)_ and must not be
  treated as confirmed merely because the bundle compiles.
- Constraint: **no private APIs.** Only documented SDK getters/notifications.

**Verification state:**
1. Done: SDK headers found; `IVdjPluginStartStop8` lifecycle and query wrappers
   compile in an ad-hoc signed universal Mac bundle.
2. Pending live test: getter strings, elapsed units, and the strongest available
   master/on-air signal.
3. Pending live test: VirtualDJ load/install location, worker-thread query
   safety, and drop-folder write latency during a mix. JSONL writes occur on the
   poller worker, not an audio callback.

Live probe, 2026-08-13: the installed sandboxed arm64 VirtualDJ keeps its active
plugin tree in its app container under `PluginsMacArm`, rather than the public
Documents path in the developer guide. The bundle was installed and validated
in `PluginsMacArm/AutoStart`, but the current VirtualDJ license session did not
load the general/basic plugin. VirtualDJ guidance identifies Pro licensing as a
possible requirement for this plugin class. Repeat with a Pro-capable session
before changing the SDK adapter or JSONL drop contract.

## 4. Event model

The plugin observes VirtualDJ and emits a small, stable set of event types.
Deck-level detail is captured, but DJMemory only needs enough to reconstruct the
**ordered list of tracks that actually went on-air**.

| Event | When | Purpose |
|---|---|---|
| `session_start` | Plugin loads / first deck activity after idle | Bounds a set; carries schema + plugin version |
| `track_load` | A track is loaded to a deck | Context only (may be loaded but never played) |
| `track_play` | A deck goes on-air / crossfader commits it | The authoritative "this was played" signal → one `TrackPlay` |
| `session_end` | Plugin unloads / idle timeout | Closes the set; lets ingest finalize |

Rules:
- Only `track_play` produces a `TrackPlay`. `track_load` without a later
  `track_play` is dropped by ingest.
- De-dup: a repeated `track_play` for the same deck+track within a short window
  (e.g. re-cue) collapses to one entry — final policy decided in Artifact B.
- Ordering is by `ts` (emit monotonically; see §5).

## 5. JSONL schema (the contract)

One JSON object per line, UTF-8, `\n`-terminated, **append-only**. Unknown
fields must be ignored by the reader (forward-compat). Field set:

```jsonl
{"v":1,"type":"session_start","ts":"2026-08-12T21:30:00Z","session":"5B6E…","plugin":"1.0.0","app":"virtualdj"}
{"v":1,"type":"track_load","ts":"2026-08-12T21:31:04Z","session":"5B6E…","deck":1,"artist":"Artist A","title":"Track A"}
{"v":1,"type":"track_play","ts":"2026-08-12T21:31:20Z","session":"5B6E…","deck":1,"artist":"Artist A","title":"Track A","elapsed":0.0}
{"v":1,"type":"session_end","ts":"2026-08-12T22:45:00Z","session":"5B6E…"}
```

| Field | Type | Notes |
|---|---|---|
| `v` | int | Schema version. Start at `1`. Reader rejects unknown major versions. |
| `type` | string | One of §4. |
| `ts` | string | ISO-8601 UTC, second precision. Monotonic per session. |
| `session` | string | Opaque id, stable for one plugin session (groups lines into one set). |
| `plugin` | string | Plugin semver (on `session_start` only; optional elsewhere). |
| `app` | string | Always `"virtualdj"` — becomes `ImportedTracklist.appID`. |
| `deck` | int | Deck number (context; not required by ingest). |
| `artist` | string | May be empty if VDJ has no tag. |
| `title` | string | May be empty; a line with neither artist nor title is skipped by ingest. |
| `elapsed` | number | Seconds into the track when it went on-air; optional. |

Design choices:
- **JSONL, not CSV/XML**, so the plugin can append one line per event with no
  rewrite and no partial-file corruption if VirtualDJ quits mid-set.
- The reader tolerates a truncated final line (crash during flush).
- `session` lets one drop file safely contain multiple sets, or multiple files
  share ingest logic.

## 6. Drop folder & file naming

- Location: **`~/Documents/VirtualDJ/DJMemoryDrop/`** — already declared as a
  VirtualDJ `defaultHistoryPaths` entry in
  [DJSoftware.swift](../Sources/DJMemoryCore/DJSoftware.swift) and named in the
  M14 note there. Do not change without updating that source.
- File naming: one file per session, `set-<ISO8601-date>-<session>.jsonl`
  (e.g. `set-2026-08-12-5B6E.jsonl`). Date-prefixed so
  `HistoryFolderIngest` modification-time matching still works.
- Rotation/cleanup: plugin never deletes; DJMemory owns retention after import.

## 7. Ingest mapping (Artifact B, DJMemoryCore)

- Add `"jsonl"` to `HistoryFolderIngest.allowedExtensions` so drop files are
  discovered by the existing autopull/ingest machinery.
- New parser conforming to the existing `TracklistParser` protocol
  (`parse(data:sourceName:) -> [TrackPlay]`), selected by `.jsonl` extension:
  - Parse line-by-line; skip blank/unparseable lines (incl. truncated tail).
  - Reject the file if `v` major version is unknown.
  - Keep only `track_play` lines with a non-empty artist **or** title.
  - Apply the re-cue de-dup rule (§4).
  - Map each to `TrackPlay(title, artist, startTime: ts (or elapsed), source:
    "virtualdj-plugin", confidence: high)`.
- Wrap as `ImportedTracklist(appID: "virtualdj", kind: .setHistory, …)`.
- Because it feeds `HistoryFolderIngest` + the standard parser path, existing
  capture→match→archive matching (`LibrarySessionMatcher`) applies unchanged.

This side is fully unit-testable now against fixture `.jsonl` files — that is the
recommended first build increment after this spec.

## 8. Security & sandbox notes

- **DJMemory stays sandbox-safe.** It only reads `~/Documents/VirtualDJ/…`, which
  it already reaches via the user-granted security-scoped bookmark used for
  VirtualDJ history (same mechanism as Folder Protection). No new entitlement.
- **The plugin is not sandboxed by DJMemory** — it lives inside VirtualDJ and
  writes with VirtualDJ's rights. Keep its footprint to a single append-only
  folder; never write outside `~/Documents/VirtualDJ/DJMemoryDrop/`.
- No network, no ports, no IPC — file drop only. This keeps M14 orthogonal to
  Network Control (M13) and to any future sync (M15).
- The plugin is a **separate distributable artifact** (its own `.bundle`, its own
  signing/notarization), not bundled into the DJMemory app target.

## 9. Open questions

1. SDK plugin category + exact getter/notification verbs _(verify, §3)_.
2. Does VirtualDJ expose a reliable "on-air / crossfader-committed" signal, or
   must the plugin infer `track_play` from deck volume + crossfader position?
3. Re-cue de-dup window value.
4. `startTime` representation in `TrackPlay` — wall-clock `ts` vs track `elapsed`.
5. Multi-session-per-file vs one-file-per-session in practice (retention/UX).
6. Windows parity (out of scope for M14; note only).

## 10. Suggested build order

1. **This spec** (done) — freeze the JSONL schema at `v:1`.
2. **Artifact B** (done) — `.jsonl` extension + `JSONLTracklistParser` + unit tests.
   In `Sources/DJMemoryCore/VirtualDJPluginEvent.swift`; drop folder registered on
   VirtualDJ `defaultHistoryPaths`.
3. **Artifact A** (scaffold built) — native Xcode C++ `.bundle` emits the frozen
   schema; getter semantics and end-to-end behavior still require live VirtualDJ
   validation.
4. Flip M14 from Research → Supported in integration-status.md once a real mix
   round-trips into an archived, matched set.
