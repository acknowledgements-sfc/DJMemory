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
| Vercel production env (Clerk + Supabase URL + account URL) | Pushed (see below) |
| `admin/.env.local` `SUPABASE_SERVICE_ROLE_KEY` | Set (2026-08-09) |
| Vercel `SUPABASE_SERVICE_ROLE_KEY` | Set + production redeployed |
| Clerk Native API for Mac + iPad | **Dashboard step** (see below) |
| `admin_roles` owner row | After first admin Clerk sign-in |
| `npx vercel --prod` | After service_role is on Vercel |

## You do next (≈3 minutes)

### 1. Supabase service_role

1. Open [API settings](https://supabase.com/dashboard/project/alywaxyxnaxwbbsiaafs/settings/api) (system browser; sign in if needed).
2. Under **Project API keys**, reveal **`service_role`** (`secret`) and copy it.
3. From repo root:

```sh
bash scripts/fill-supabase-service-role-from-clipboard.sh
bash scripts/push-accounts-vercel-env.sh
cd admin && npx vercel --prod
```

### 2. Clerk Native API (Mac + iPad)

1. Open [Native applications](https://dashboard.clerk.com/~/native-applications).
2. Enable **Native API** if not already on.
3. Register two apps (Team ID / App ID Prefix `3JYK7Q92SF`):

| App | Bundle ID | Redirect |
| --- | --- | --- |
| macOS | `app.djmemory.DJMemory` | `app.djmemory.DJMemory://callback` |
| iPad | `app.djmemory.DJMemory.iPad` | `app.djmemory.DJMemory.iPad://callback` |

Also allowlist those redirect URLs under Paths / OAuth as shown in the Dashboard.

### 3. Admin owner row

Inserted 2026-08-09 for `yo@rcawhatsgood.com` as `owner`.

**Check:** Clerk session `userId` must match `admin_roles.clerk_user_id` exactly. Current row uses `rcatestgood`. Real Clerk IDs usually look like `user_2…` (Dashboard → Users → user → **User ID**). If `/admin` still returns Forbidden after sign-in, paste the real `user_…` id and we’ll update the row.

Until `SUPABASE_SERVICE_ROLE_KEY` is set and Vercel is redeployed, Mac/iPad account sync fails soft (local features stay full).
