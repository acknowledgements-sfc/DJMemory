# DJMemory Admin (accounts + support)

Optional web accounts and support-first admin for DJMemory.

Stack: **Clerk** (auth) + **Supabase** (Postgres/RLS) + **Vercel** (host).

Local protection in the macOS app **never** depends on this service. Audio and full tracklists are never uploaded by default. Admins cannot play or download audio or view tracklist contents.

## Setup

1. Create a Clerk application. Enforce MFA for admin users in Clerk.
2. Create a Supabase project. Run [`supabase/migrations/001_initial.sql`](supabase/migrations/001_initial.sql).
3. Insert your admin row:

```sql
insert into public.admin_roles (clerk_user_id, email, role)
values ('user_xxx', 'you@example.com', 'owner');
```

4. Copy `.env.example` to `.env.local` and fill keys.
5. `npm install && npm run dev`
6. Deploy `admin/` to Vercel; set the same env vars.

## Scripts

- `npm run dev` — local Next.js
- `npm run build` — production build
- `npm run start` — serve production build

## Privacy

- Diagnostics uploads accept **metadata only** (counts, paths, timings, errors).
- Server routes use the Supabase **service role**; anon/authenticated have no table grants.
- Every admin search, detail view, and mutation writes `admin_audit_events`.
