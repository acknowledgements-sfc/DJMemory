# DJMemory Accounts API

Last updated: August 7, 2026.

Authority: [`docs/onboarding-accounts-security.md`](onboarding-accounts-security.md).

The macOS app stays fully usable without sign-in. This API backs optional licensing, beta invites, device registration, and opt-in diagnostics metadata. It must never become a dependency of local archive/scan/protection paths.

## Base URL

- Local: `http://localhost:3000`
- Production: set via Vercel deployment (also `NEXT_PUBLIC_ACCOUNT_URL`)

## Privacy boundaries

| Data | Default |
| --- | --- |
| Audio files | Never uploaded |
| Full tracklists / titles / artists | Never uploaded by default; not accepted in diagnostics metadata |
| Diagnostics | Opt-in; metadata only (counts, paths, timings, error strings) |
| Admin access | No audio playback/download; no tracklist contents |

## Public

### `GET /api/health`

Returns service health and privacy posture. No auth.

## Admin (Clerk session + `admin_roles` row)

All admin routes require a signed-in Clerk user with a matching `admin_roles` row. Mutations require `owner`, `support`, or `release_manager` (`read_only` is view-only). Invite management: `owner`, `release_manager`, or `support`.

Every successful admin call writes an `admin_audit_events` row.

### `GET /api/admin/users?email=`

Search users by email substring (max 50).

### `PATCH /api/admin/users`

Body: `{ "userId", "status?", "releaseChannel?" }`

### `GET /api/admin/users/detail?userId=`

Returns devices, licenses, and diagnostics metadata for one user. Response includes an explicit `restrictions` object stating audio/tracklist denial.

### `GET /api/admin/invites`

List beta invites.

### `POST /api/admin/invites`

Body: `{ "email" }` to create, or `{ "resendId" }` to resend.

### `POST /api/admin/revoke`

Body: `{ "action": "revoke_device"|"revoke_license", "deviceId"|"licenseId" }`

### `GET /api/admin/audit`

Recent audit events (max 200).

## Future macOS contract (documented, not required for local protection)

These endpoints are reserved for a later app build. Do not call them from archive/scan paths.

| Intent | Proposed | Notes |
| --- | --- | --- |
| Register device | `POST /api/devices` | Optional after sign-in |
| License status | `GET /api/license` | Cache locally; offline = full local features |
| Upload diagnostics | `POST /api/diagnostics` | User-initiated; metadata validated server-side |

Until implemented, the macOS Settings **Account** panel deep-links to the public account page only.

## Roles

| Role | Capabilities |
| --- | --- |
| owner | Full admin |
| support | User lookup, invites, revoke, diagnostics metadata |
| release_manager | Invites, release channel |
| read_only | Lookup and audit view without mutation |
