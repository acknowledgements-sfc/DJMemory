# Deploy DJMemory Accounts (Clerk + Supabase + Vercel)

Last updated: August 9, 2026.

## Status (2026-08-09)

- Supabase project **DJMemory** created in Cadence org (`alywaxyxnaxwbbsiaafs`, `us-west-1`).
- URL: `https://alywaxyxnaxwbbsiaafs.supabase.co`
- Migration `initial_accounts_schema` applied (users, devices, licenses, beta_invites, diagnostic_uploads, admin_roles, admin_audit_events + RLS).
- Client contract implemented: `POST /api/devices`, `GET /api/license`, `POST /api/diagnostics` (see [`accounts-api.md`](accounts-api.md)).
- macOS Settings Account wires Clerk session → device register, license refresh, optional diagnostics upload.
- Vercel project **djmemory-admin** linked on team `acknowledgements-sfcs-projects`; production env has Clerk keys + `SUPABASE_URL` + `NEXT_PUBLIC_ACCOUNT_URL`.
- Still needed (human): `SUPABASE_SERVICE_ROLE_KEY` in `.env.local` + Vercel, then `npx vercel --prod`; Clerk Native API for Mac + iPad; `admin_roles` owner row after first admin sign-in.
- Helpers: [`scripts/fill-supabase-service-role-from-clipboard.sh`](../scripts/fill-supabase-service-role-from-clipboard.sh), [`scripts/push-accounts-vercel-env.sh`](../scripts/push-accounts-vercel-env.sh). See [`accounts-ops-checklist.md`](accounts-ops-checklist.md).

## Checklist

### 1. Supabase

1. ~~Create project~~ Done: **DJMemory** (`alywaxyxnaxwbbsiaafs`).
2. ~~Apply [`admin/supabase/migrations/001_initial.sql`](../admin/supabase/migrations/001_initial.sql)~~ Done via MCP.
3. Copy **service_role** key (Settings → API) into `admin/.env.local` as `SUPABASE_SERVICE_ROLE_KEY`.
4. After first Clerk admin signs in, insert:

```sql
insert into public.admin_roles (clerk_user_id, email, role)
values ('user_XXXX', 'you@example.com', 'owner');
```

### 2. Clerk

1. Create an application at [dashboard.clerk.com](https://dashboard.clerk.com) named **DJMemory**.
2. Enable email magic link (and OAuth if desired).
3. Enforce MFA for users who will hold admin roles.
4. Copy **Publishable key** and **Secret key**.
5. Set allowed redirect URLs to the Vercel URL + `http://localhost:3000`.
6. **Native apps:** Enable **Native API** under [Native applications](https://dashboard.clerk.com/~/native-applications).

| Client | App ID Prefix (Team ID) | Bundle ID | Redirect |
| --- | --- | --- | --- |
| macOS | `3JYK7Q92SF` | `app.djmemory.DJMemory` | `app.djmemory.DJMemory://callback` |
| iPad companion | `3JYK7Q92SF` | `app.djmemory.DJMemory.iPad` | `app.djmemory.DJMemory.iPad://callback` |

Associated Domains `webcredentials:glorious-longhorn-36.clerk.accounts.dev` is in [`packaging/DJMemory.entitlements`](../packaging/DJMemory.entitlements) (Mac) and [`Apps/DJMemoryCompanion/DJMemoryCompanion.entitlements`](../Apps/DJMemoryCompanion/DJMemoryCompanion.entitlements) (iPad). Local protection never depends on Native API being enabled.

### 3. Local env

```sh
cd admin
cp .env.example .env.local
# fill:
# NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
# CLERK_SECRET_KEY=
# SUPABASE_URL=
# SUPABASE_SERVICE_ROLE_KEY=
# NEXT_PUBLIC_ACCOUNT_URL=https://<your-vercel-host>
npm run dev
```

### 4. Vercel

From repo root (or `admin/` with Root Directory = `admin`):

```sh
cd admin
npx vercel link   # team: acknowledgements-sfc's projects; create project djmemory-admin
npx vercel env add NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY production
npx vercel env add CLERK_SECRET_KEY production
npx vercel env add NEXT_PUBLIC_CLERK_SIGN_IN_URL production   # /sign-in
npx vercel env add SUPABASE_URL production
npx vercel env add SUPABASE_SERVICE_ROLE_KEY production
npx vercel env add NEXT_PUBLIC_ACCOUNT_URL production         # https://djmemory-admin.vercel.app (or custom)
npx vercel --prod
```

Or connect GitHub repo `acknowledgements-sfc/DJMemory` with **Root Directory** `admin`.

### 5. macOS / iPad account URL

Optional: set `DJMEMORY_ACCOUNT_URL` to the production account URL when launching clients. Default is `https://accounts.djmemory.app` until that domain is wired.

### 6. Smoke

- `GET /api/health` → `{ ok: true, … }`
- Sign in → `/admin` (needs `admin_roles` row)
- Create a beta invite → row in `beta_invites` + `admin_audit_events`
- Signed-in Mac: Settings → Refresh Account → device row + license summary
- Signed-in Mac: Upload Diagnostics Metadata → `diagnostic_uploads` row (no titles/artists)
