# Deploy DJMemory Accounts (Clerk + Supabase + Vercel)

Last updated: August 7, 2026.

## Status (2026-08-08)

- Supabase project **DJMemory** created in Cadence org (`alywaxyxnaxwbbsiaafs`, `us-west-1`).
- URL: `https://alywaxyxnaxwbbsiaafs.supabase.co`
- Migration `initial_accounts_schema` applied (users, devices, licenses, beta_invites, diagnostic_uploads, admin_roles, admin_audit_events + RLS).
- Still needed for deploy: Clerk keys + Supabase **service_role** key (Settings → API; never expose to the browser).

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
6. **macOS native (Settings Account panel):** Enable **Native API** under [Native applications](https://dashboard.clerk.com/~/native-applications). Register the DJMemory app:
   - **App ID Prefix (Team ID):** `3JYK7Q92SF`
   - **Bundle ID:** `app.djmemory.DJMemory`
   Associated Domains `webcredentials:glorious-longhorn-36.clerk.accounts.dev` is already in [`packaging/DJMemory.entitlements`](../packaging/DJMemory.entitlements). Local protection never depends on Native API being enabled.

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

### 5. macOS Settings deep-link

Optional: set `DJMEMORY_ACCOUNT_URL` to the production account URL when launching the app. Default in Settings is `https://accounts.djmemory.app` until that domain is wired.

### 6. Smoke

- `GET /api/health` → `{ ok: true, … }`
- Sign in → `/admin` (needs `admin_roles` row)
- Create a beta invite → row in `beta_invites` + `admin_audit_events`
