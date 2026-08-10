# Accounts deploy ops checklist (repo-side)

Last updated: August 9, 2026.

This tracks what the repo can verify. Secrets never belong in git.

| Step | Status |
| --- | --- |
| Supabase project + `001_initial.sql` | Done |
| Client routes `/api/devices`, `/api/license`, `/api/diagnostics` | Done |
| Clerk middleware matcher includes `/__clerk` + API | Done (`admin/src/middleware.ts`) |
| Document Mac + iPad Native API bundle IDs | Done (`docs/accounts-deploy.md`) |
| `admin/.env.local` Clerk keys | Present |
| Vercel project linked | Done — `acknowledgements-sfcs-projects/djmemory-admin` (`prj_G8oOgEBzVlweAXQRYYp8tq8praQu`) |
| Vercel production env (Clerk + Supabase URL + account URL) | Pushed |
| `admin/.env.local` `SUPABASE_SERVICE_ROLE_KEY` | Done (2026-08-09) |
| Vercel `SUPABASE_SERVICE_ROLE_KEY` | Done + production redeployed |
| Clerk Native API for Mac + iPad | **You do next** |
| `admin_roles` owner row | Inserted for `yo@rcawhatsgood.com` — **verify** Clerk User ID matches session |
| Shared client account URL | Done — `DJMemoryAccountConfiguration` default `https://beatrevival.com` (Mac + iPad) |
| Vercel custom domains | Done — `beatrevival.com` + `www.beatrevival.com` on `djmemory-admin` |
| Hover DNS → Vercel | Done (2026-08-09) — A `@` → `76.76.21.21`, CNAME `www` → `cname.vercel-dns.com`; `https://beatrevival.com/admin` live |
| Clerk Production + allowlist `beatrevival.com` | **You do next** (Hobby OK; MFA needs Clerk Pro — skip until Pro) |
| Marketing + `POST /api/waitlist` | Done |
| `npx vercel --prod` | Deployed with service_role |

## You do next

### 1. Clerk Native API (Mac + iPad)

1. Open [Native applications](https://dashboard.clerk.com/~/native-applications).
2. Enable **Native API** if not already on.
3. Register two apps (Team ID / App ID Prefix `3JYK7Q92SF`):

| App | Bundle ID | Redirect |
| --- | --- | --- |
| macOS | `app.djmemory.DJMemory` | `app.djmemory.DJMemory://callback` |
| iPad | `app.djmemory.DJMemory.iPad` | `app.djmemory.DJMemory.iPad://callback` |

Also allowlist those redirect URLs under Paths / OAuth as shown in the Dashboard.

### 2. Admin owner row (verify)

Inserted 2026-08-09 for `yo@rcawhatsgood.com` as `owner`.

**Check:** Clerk session `userId` must match `admin_roles.clerk_user_id` exactly. If the row still uses `rcatestgood` (not a real `user_…` id), `/admin` returns Forbidden. Fix: Dashboard → Users → user → **User ID**, then update the row.

### 3. Clerk Production for beatrevival.com

1. Dashboard → **DJMemory** → **Production** instance.
2. Allowlist origins/redirects: `https://beatrevival.com`, `https://www.beatrevival.com`, `https://djmemory-admin.vercel.app`, `http://localhost:3000`.
3. Put Production `pk_` / `sk_` into Vercel env + `admin/.env.local`, then `npx vercel --prod`.
4. Optional (Clerk Pro ~$25/mo): enforce MFA for admin users.
5. After production Frontend API host is known, update Associated Domains entitlements if leaving `*.clerk.accounts.dev`.

Production host is live: `https://beatrevival.com`. Fallback: `https://djmemory-admin.vercel.app`.

### Service role (already done)

`SUPABASE_SERVICE_ROLE_KEY` is set in `admin/.env.local` and Vercel production. Re-run only if rotating the key:

```sh
bash scripts/fill-supabase-service-role-from-clipboard.sh
bash scripts/push-accounts-vercel-env.sh
cd admin && npx vercel --prod
```
