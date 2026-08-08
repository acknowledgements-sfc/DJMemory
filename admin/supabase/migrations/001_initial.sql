-- DJMemory accounts / admin schema (v1)
-- Apply with: supabase db push / SQL editor
-- Privacy: no audio, no track titles/artists in diagnostic_uploads.metadata

create extension if not exists "pgcrypto";

create type public.user_status as enum ('active', 'disabled', 'invited');
create type public.license_plan as enum ('free', 'beta', 'pro');
create type public.license_status as enum ('active', 'expired', 'revoked', 'trial');
create type public.invite_status as enum ('pending', 'accepted', 'revoked', 'expired');
create type public.admin_role as enum ('owner', 'support', 'release_manager', 'read_only');

create table public.users (
  id uuid primary key default gen_random_uuid(),
  clerk_user_id text not null unique,
  email text not null unique,
  display_name text,
  status public.user_status not null default 'active',
  release_channel text not null default 'stable',
  created_at timestamptz not null default now()
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  device_name text not null,
  app_version text,
  last_seen timestamptz not null default now(),
  install_channel text not null default 'local',
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index devices_user_id_idx on public.devices (user_id);

create table public.licenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  plan public.license_plan not null default 'free',
  status public.license_status not null default 'active',
  renews_or_expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index licenses_user_id_idx on public.licenses (user_id);

create table public.beta_invites (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  status public.invite_status not null default 'pending',
  sent_at timestamptz not null default now(),
  accepted_at timestamptz,
  created_by_clerk_id text,
  unique (email, status)
);

create table public.diagnostic_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users (id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint diagnostic_metadata_no_track_fields check (
    not (metadata ? 'title')
    and not (metadata ? 'artist')
    and not (metadata ? 'tracks')
    and not (metadata ? 'tracklist')
  )
);

create table public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  clerk_user_id text not null unique,
  email text not null,
  role public.admin_role not null,
  created_at timestamptz not null default now()
);

create table public.admin_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_clerk_id text not null,
  actor_email text,
  action text not null,
  target text,
  result text not null default 'ok',
  ip_context text,
  created_at timestamptz not null default now()
);

create index admin_audit_events_created_at_idx on public.admin_audit_events (created_at desc);

alter table public.users enable row level security;
alter table public.devices enable row level security;
alter table public.licenses enable row level security;
alter table public.beta_invites enable row level security;
alter table public.diagnostic_uploads enable row level security;
alter table public.admin_roles enable row level security;
alter table public.admin_audit_events enable row level security;

-- No direct anon/authenticated client access. Server routes use the service role.
-- Policies deny by default (RLS on, no grants for anon).

revoke all on all tables in schema public from anon, authenticated;
grant usage on schema public to service_role;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
