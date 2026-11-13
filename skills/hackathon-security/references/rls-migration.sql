-- rls-migration.sql — Supabase migration for the hackathon build (fallback backend).
-- UNVERIFIED-SNIPPET: composed from documented patterns; parsed as Postgres SQL
-- with sqlglot 30.31.0 on 2026-11-13 (the two Postgres-specific statements —
-- ALTER TABLE ... ENABLE ROW LEVEL SECURITY and SET LOCAL role — parse as
-- generic commands, which is syntax acceptance, not semantic validation).
-- NOT executed against a live Supabase project. Run the §B5 proofs (Advisor,
-- pg_policies, anon transaction below) against the real project at T+2:20/T+3:20.
--
-- Design: NO grant to anon/authenticated at all, and NO policies.
-- RLS on + zero policies = default deny. All reads/writes go through the
-- Edge Function (service role). After the 30 Oct 2026 grants change, a new
-- table starts with no Data API access anyway — this design deliberately
-- does not opt in. Source: https://github.com/orgs/supabase/discussions/45329

create table public.shares (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.shares enable row level security;
revoke all on table public.shares from anon, authenticated;
-- grant select on table public.shares to anon;  -- DO NOT UNCOMMENT

-- Anon proof — run in the SQL Editor, then check the results, then rollback.
-- SET LOCAL must be inside a transaction: outside one it raises
-- ERROR: SET LOCAL can only be used in transaction blocks.
begin;
  set local role anon;
  select count(*) as anon_rows_total from public.shares;
  -- PASS: 0. Any number > 0 = STOP (a policy/grant is leaking rows).
  insert into public.shares (title) values ('qc-probe') returning id;
  -- PASS: error (42501 missing grant) or 0 rows. A returned id = STOP.
rollback;
