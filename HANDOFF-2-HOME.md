# DJMemory — Handoff addendum: Home dashboard + sidebar sources

Companion to `HANDOFF.md`. Read that first — §2 (tokens), §3 (type mapping), §5 (state matrix), and
§7 (non-negotiables) all apply here unchanged. This file adds two things the original spec did not
cover, plus the three Core gaps they need.

Section numbers continue from `HANDOFF.md`: screens are §4.9 and §4.10, gaps are G7–G9, tasks are
T12–T13.

---

## §4.9 Home — the landing screen

A user-focused dashboard, not a second Protection pane. Protection answers *"am I covered?"*; Home
answers *"what have I been doing, and is anything wrong?"* It is the default route and the first
sidebar item (`house` SF Symbol).

Layout is a single scrolling column, max width 1180pt, 12pt gaps between sections.

**1. Identity band** — a card, not a hero.
- 44pt monogram tile with the user's initials, tinted with the per-app accent (§2) of the app that
  recorded their most recent set. Border at 33% alpha, fill at 8%, text at full accent.
- `Good evening, <first name>` at 17pt semibold, with a state badge + dot beside it (pulsing while
  scanning). Time-of-day greeting: morning / afternoon / evening.
- Meta line at 11pt `mutedForeground`, dot-separated: handle (monospaced) · city with a `mappin`
  glyph · residency · `DJMemory since <month year>`.
- Trailing: `Scan Now` (primary, spinner + "Scanning…" while busy) and `Open Library`.
- Hairline divider, then **one adaptive sentence** per `ProtectionState`:
  - *protected* — "N sources watched. Your last N sets this month were archived automatically — you have **N weeks** running with nothing lost."
  - *scanning* — "Checking N watched folders for new recordings…"
  - *needsSetup* — "N of M sources watched. N still need a folder before DJMemory can protect them."
  - *attentionNeeded* — "A saved folder is unavailable, so new sets from <App> are not being archived right now. Everything already in your archive is safe."

  The second clause of the last one matters. When something breaks, say what is still safe in the
  same breath.

**2. Attention banners** — one `danger`-toned panel per unreachable folder, directly below the
identity band and above everything else. Icon, "<App> folder is unavailable", the path and "The
drive may be unplugged.", and a primary `Fix Folder` button routing to recovery. A missing drive is
the first thing on the page, never below the fold.

**3. Your last set + at a glance** — two columns, `1fr` and 296pt, collapsing to one below ~1280pt.

Left, a panel titled *Your last set* with an `Archived & verified` badge and an
`Open in Library` action:
- Event name at 15pt semibold; `<venue>, <city> · Archived <timestamp>` beneath.
- Trailing app chip tinted with that app's accent.
- Waveform in an inset `muted` well, 56pt tall, ~88 bars, tinted with the app accent, with a
  monospaced `00:00` / duration ruler under it. Per-bar opacity `0.28 + amplitude * 0.5` gives the
  strip depth without a gradient.
- Four facts in a row: Duration, Tracks (`—` when unmatched), Size, Tracklist (Matched/Unmatched).
- The archive path as a path chip.
- **The user's own private note, quoted back italic behind a left rule.** Small thing,
  disproportionate effect — it is the one piece of the screen they wrote themselves.
- Actions: `Reveal in Finder`, `Edit details`.

Right, a 2×2 tile mosaic: **Sets protected** (`ok`, with "N this month"), **Hours archived** (with
storage size), **Sources watched** (`N/M`, toned by worst state), **Unmatched sets** (`warn` when
non-zero).

**4. Recent sets shelf** — horizontally scrolling row of 196pt cards, six most recent. Each card:
28-bar accent waveform as the cover-art stand-in, event name, `venue, city`, then a hairline footer
with an accent swatch, app name, and duration. Whole card is one button into the Library.

**5. Your most played tracks** — the dense table, aggregated across matched tracklists. Columns:
zero-padded monospaced index, Track (title + artist stacked), Last played at (event name),
Plays (right-aligned, with a 1pt `primary` bar scaled against the top track's count). Eight rows.

**6. Latest activity** — 320pt rail beside the table. Five most recent events: tone dot, title,
monospaced timestamp. Error rows tinted `danger` at 6%. `All activity` action in the header.

**7. Where you play most** — six venue cards: name, city, `N sets`. Each filters the Library.

**8. Your tags** — chips built from the tags the user typed into set details, each with a count.
Header note: "From set details you wrote."

**9. Your DJ apps** — unlike the sidebar (§4.10), this section lists **all** supported apps,
including un-configured ones. This is the discovery surface. Each card: 3pt accent bar, name,
support badge, state dot + `state · N sets`, and one action — `Fix` / `Set up` / `Manage`.

**10. Footer** — the standing privacy line, centered, with a shield glyph when protected.

### Deliberate exclusions

- **No photography and no cover art.** A monogram and generated waveforms keep this a system
  utility. Album art would make it a media library, which this is not.
- **No gradients, no hero image, no marketing framing.** §7.8 still holds on the landing screen.
- **No player.** The references this design borrows from are music players; DJMemory is not one.
  Do not add transport controls, a now-playing bar, or scrubbing.

---

## §4.10 Sidebar — only real sources

Replaces the DJ Apps behaviour in §4.1.

- The **DJ Apps section lists only apps with a configured recordings folder.** An app the user has
  never set up does not belong in a list of things being protected.
- An app whose folder is configured but *unreachable* **stays in the list**. It is set up; it is
  broken. Removing it would hide the one row the user needs in order to fix it.
- Because "needs setup" can no longer occur in this list, the status dot reduces to three cases:
  `danger` (unreachable), `info` (scanning), `ok` (watched).
- When nothing is configured, show a one-line hint in place of the list: "No DJ apps set up yet.
  Use + to add one."
- A **`+` button sits across from the DJ Apps section label** and opens a picker of supported apps
  that are not yet set up. On macOS use a `Menu` or `.popover` anchored to the button — do not build
  a custom overlay. (The prototype uses one only because it is a web page.)
  - Each row: accent swatch, app name, support badge, and "Not installed on this Mac" where the
    probe found no application.
  - Picking a row navigates to that app's setup screen.
  - Closes on selection, outside click, or Escape. The button reads as toggled while open.
  - If every supported app is configured: "Every supported DJ app is already set up."
  - Footer line: "Setting one up means choosing its recordings folder. Nothing is uploaded." State
    the cost and the guarantee at the moment of the decision.

---

## Additional Core gaps

`HANDOFF.md` §3 lists G1–G6. Home needs three more. All three are pure aggregation over data that
already exists — no new persistence except G7.

- **G7 — no user profile.** `AppSettings` has no display name, handle, city, or residency, so the
  identity band has nothing to render. Add a `DJProfile` value + store (`profile.json`) with every
  field optional. The screen must degrade honestly: no name → "Good evening" with no comma; no
  residency → drop that clause; initials fall back to a `person` glyph. **Do not invent a
  placeholder name at runtime.**
- **G8 — no aggregate library statistics.** Home needs total archived hours, archive size on disk,
  sets archived this month, and unmatched count. `ArchiveMetadata.durationSeconds` and `fileSize`
  already exist, so this is a summation over `SessionLibrary`, not new data capture. The "N weeks
  running" streak is consecutive ISO weeks containing ≥1 archive — if you implement it, test the
  boundary where the current week has no set yet, and drop the clause rather than showing `0`.
- **G9 — no cross-set aggregation.** Top tracks require counting `TrackPlay` across every
  `ImportedTracklist` of kind `.setHistory` (never `.collection` — a collection import can hold
  thousands of tracks and would swamp the counts). Venue and tag tallies come from
  `SetContext.venue` and `.tags`. Put these in `DJMemoryCore` as pure functions with unit tests; they
  are the easiest thing on this list to get subtly wrong and the hardest to notice.

Tag parsing note: `SetContext.tags` is free text the user typed. Split on commas, trim, lowercase
for counting, and preserve their original casing for display.

---

## Additional state matrix rows

Extends `HANDOFF.md` §5. A `#Preview` per state.

| Group | States |
| --- | --- |
| Greeting | morning · afternoon · evening · no profile name |
| Identity band | full profile · name only · empty profile |
| Home last-set | matched · unmatched · with private note · no note · **no sets archived yet** |
| Home aggregates | populated · zero sets · zero matched tracklists (empty top-tracks table) |
| Sidebar sources | none configured · some configured · one unreachable |
| Add-app picker | options available · all apps configured |

**The zero states are the ones that will get skipped.** A brand-new user opens Home before anything
is archived: no last set, no shelf, no top tracks, no venues, no tags. Every one of those sections
needs an honest empty state that points at onboarding or `Choose Folder`, not a blank panel.

---

## Tasks

**T12 — Home dashboard.** Depends on T3 (primitives), T4 (Core gaps), and G7–G9. Sections 1–10
above, all states in the matrix, both appearances. Route `.home` becomes the default landing screen
and the first sidebar item. *Done when:* every section has a populated and an empty preview, and a
profile with no name renders without a placeholder.

**T13 — Sidebar sources + add-app picker.** §4.10. Small and independent — it only needs T3, so it
can land any time after that. *Done when:* an app with no folder is absent from the sidebar but
present in the picker and in Home's "Your DJ apps"; an app with an unreachable folder stays in the
sidebar with a `danger` dot; all existing `sidebar.*` accessibility identifiers still resolve, and
the new ones follow the same shape (`sidebar.addApp`, `sidebar.addApp.<id>`).
