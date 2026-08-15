# Pioneer Hardware Setup (M11)

DJMemory does not install Pioneer drivers. Support labels stay capability-specific. Do not round
Manual Setup up to Supported until the matching checklist has an external (non-dev) pass.

## Laptop + XDJ-XZ / CDJs over USB (verified target)

A DJ runs DJMemory on the Mac, connected to an XDJ-XZ or CDJs over USB, playing through Serato or
rekordbox on that laptop. The Mac is in the audio loop the whole time.

1. Grant the Serato or rekordbox recordings folder (Folder Protection).
2. Connect the XZ (or mixer that presents a Pioneer Core Audio input) over USB.
3. Leave Pioneer rig safety nets on **Both** (Settings → Capture). Input Capture auto-selects the
   Pioneer device and records when audio is detected; idle silence saves the take.
4. If the DJ hits Record, Folder Protection archives that file. If they forget, Input Capture still
   archives the USB output. Overlapping files appear as **one set** in Library: DJ-software recording
   primary, Input Capture labeled Hardware backup. Sources are never moved, renamed, or deleted.

This path does **not** cover a booth where master output never reaches the Mac.

## DJM-900 / DJM-V10 / DJM-V10LF
1. Connect USB and install the Pioneer driver.
2. Assign MIX (REC OUT) in Setting Utility.
3. Open Capture, select the DJM, Start/Stop — or use Both so unattended Input Capture runs when the
   DJM is the selected Pioneer input.
4. Import a tracklist from Set Detail when available.

## XDJ-RX2 / RX3 / XZ / AZ — USB MASTER REC (Manual Setup)
Use this when the Mac is **out** of the audio path (standalone hardware-to-house).

1. MASTER REC to USB → PIONEERREC / RECxxx.WAV.
2. Add Pioneer Hardware and choose the stick or PIONEERREC folder. The folder must be granted and
   the drive must be mounted.
3. DJMemory copies stable files; originals stay on the stick.
4. MASTER REC has no clock — archive uses file mtime.

## CDJ-2000 / 2000NXS / 3000
Players do not record the master. DJMemory can protect only what reaches the Mac. Route USB through
this laptop or a DJM, or grant a PIONEERREC folder. A separate standalone mixer whose master never
reaches the Mac is Manual Setup / Research.

## Phase 1 bench (XDJ-XZ as Core Audio input)

Confirmation, not new detection. Auto-select is a name/manufacturer substring (`xdj` / `cdj` /
`djm` / `pioneer`).

- [ ] XZ appears as a Core Audio input over USB. Record the exact device name here when verified.
- [ ] Known-Pioneer auto-select picks it while Input mode is armed.
- [ ] Level metering moves with master output.
- [ ] A 24-bit/48 kHz stereo WAV archives through `ingestCapture` and appears in Library.
- [ ] Unplug mid-record, microphone permission denied, and disk-full show the existing failure
      messages and a next action (Open Microphone Settings / free space).

Exit: one input-capture set off the XZ archives cleanly. Keep Pioneer Input Capture labeled
**Manual Setup** until Phase 2 has an external pass.

## Phase 2 combined-rig bench

Serato or rekordbox through the XZ on the same Mac, Folder Protection watching the app record
folder, Input Capture unattended on the XZ (Both posture).

- [ ] Both paths archive independently; Library shows **one** row with primary + Hardware backup.
- [ ] Both files exist on disk; source files are unchanged.
- [ ] Forgot Record: Capture-only set appears as one row, not labeled backup.
- [ ] No naming collision; no set masquerading as two Library rows.
- [ ] Unplug / permission / disk-full still actionable.

External (non-dev) verification is the gate before Input Capture off the XZ USB master is labeled
Supported.
