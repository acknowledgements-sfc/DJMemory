# DJMemory Onboarding, Accounts, Backend Admin, and Security

Last updated: August 6, 2026.

## Product Principle

DJMemory is local-first. A user account may unlock licensing, beta access, sync, support, and future cloud features, but the core safety-net workflow must not require uploading audio files or tracklists.

## New-User Onboarding

The first-run flow should answer one question: "Am I protected now?"

1. Welcome
   - State that DJMemory backs up sets recorded by DJ software.
   - Clarify that source recordings are copied, not moved or deleted.
2. Choose DJ Apps
   - Show Serato, rekordbox, Traktor, VirtualDJ, and djay.
   - Label each app as Supported, Partial, or Manual Setup.
3. Folder Access
   - Ask for recording folders first.
   - Ask for history folders second and label them optional.
   - Explain that folder access is needed because macOS protects Music/Documents.
4. Archive Location
   - Default to `~/Music/DJMemory`.
   - Allow choosing a different archive folder later in Settings.
5. Import History
   - Offer optional import for Serato CSV/TXT, rekordbox XML, and Traktor NML.
   - State that rekordbox XML library imports are browsable collections, not one set history.
6. Ready State
   - Show protected apps, watched folders, and the next scan time.
   - Provide Scan Now as the first action.

## Account Model

Accounts are optional for local alpha and early beta. Accounts become required only for cloud-backed features or paid licensing.

Account-backed features:

- beta invite access
- license/subscription status
- device list
- release/update channel
- support request linkage
- future cloud backup or sync, if explicitly enabled

Local-only without account:

- folder setup
- recording archive
- metadata sidecars
- imported tracklist storage
- set notes
- diagnostics export file

## Backend Scope

The first backend should be intentionally small.

Required entities:

- User: email, display name, created date, status.
- Device: user ID, device name, app version, last seen, install channel.
- License: plan, status, renewal or expiry date.
- Beta Invite: email, status, sent date, accepted date.
- Diagnostic Upload: optional, user-initiated, metadata-only by default.
- Admin Audit Event: actor, action, target, timestamp, IP/device context.

Explicitly out of scope for the first backend:

- automatic audio upload
- automatic tracklist upload
- social publishing
- streaming integrations
- cloud backup of archived recordings

## Admin Access

Admin tools should be support-first, not surveillance-first.

Roles:

- Owner: full access, role management, billing configuration.
- Support: user lookup, device/license status, diagnostic metadata, beta invite status.
- Release Manager: beta invites, release channel assignment, version rollout controls.
- Read Only: audit-safe lookup without mutation rights.

Admin capabilities:

- search users by email
- view account and device status
- resend beta invite
- change release channel
- inspect diagnostics metadata
- revoke device/license access
- view audit log

Admin restrictions:

- no audio playback or download
- no tracklist contents by default
- no direct local file paths unless the user explicitly included them in a diagnostic export
- no silent account mutation; every mutation writes an audit event

## Security Requirements

Authentication:

- email magic link or OAuth for user accounts
- enforced MFA for admin accounts
- short-lived admin sessions
- explicit logout and session revocation

Authorization:

- role-based access control for admin tools
- least-privilege permissions per admin role
- server-side authorization checks for every admin action

Data protection:

- encrypt backend data at rest through the platform/database provider
- use TLS for all network traffic
- store no audio or full tracklists by default
- hash or redact sensitive local paths in uploaded diagnostics where possible

Auditability:

- log all admin sign-ins
- log all admin data views that expose user-specific records
- log all mutations
- include actor, target, timestamp, action, and result

Incident basics:

- ability to revoke admin sessions
- ability to disable an account
- ability to rotate backend secrets
- ability to export audit events for investigation

## Implementation Defaults

- Keep the macOS app fully usable without sign-in through v1.0 unless licensing requires otherwise.
- Add account UI only after the onboarding and backend contract are stable.
- Treat uploaded diagnostics as opt-in support artifacts.
- Put account/backend failures behind clear local fallback states so recording protection still works.
