-- Enriched beta research and privacy-safe marketing funnel.
-- Never store audio, track titles, artists, or local file paths here.

alter table public.beta_invites
  add column if not exists source text not null default 'waitlist',
  add column if not exists dj_software text[] not null default '{}',
  add column if not exists macos_version text,
  add column if not exists dj_type text,
  add column if not exists recording_frequency text,
  add column if not exists current_workflow text,
  add column if not exists biggest_pain text,
  add column if not exists willing_to_test boolean,
  add column if not exists research_completed_at timestamptz;

create table if not exists public.marketing_events (
  id uuid primary key default gen_random_uuid(),
  event_name text not null check (event_name in (
    'page_view',
    'demo_view',
    'waitlist_started',
    'waitlist_joined',
    'research_completed'
  )),
  source text not null default 'direct',
  session_id text,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint marketing_events_no_sensitive_fields check (
    not (properties ? 'title')
    and not (properties ? 'artist')
    and not (properties ? 'tracklist')
    and not (properties ? 'audio')
    and not (properties ? 'path')
  )
);

create index if not exists marketing_events_created_at_idx
  on public.marketing_events (created_at desc);

alter table public.marketing_events enable row level security;
revoke all on public.marketing_events from anon, authenticated;
grant all on public.marketing_events to service_role;
