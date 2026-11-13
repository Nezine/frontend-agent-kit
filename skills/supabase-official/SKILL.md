---
name: supabase-official
description: "Router to the official Supabase agent skills (supabase/agent-skills, MIT) for the Expo SDK 58 hackathon build: install-by-reference, scoped to the Edge Function AI endpoint and the fallback mirror table, with the free-tier pins and the RLS/grant rules. Use when the backend builder needs authoritative Supabase procedures (Edge Functions, secrets, migrations, RLS, CLI) beyond what backend-kit pins. Never vendored into the repo."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Node 22+ and Supabase CLI 3.1.0. This skill installs nothing by itself; it records the install command and the scope rules for the official package.
metadata:
  version: "0.1.0"
---

# supabase-official — official Supabase agent skills, install-by-reference

You are the backend builder for the hackathon app (Expo SDK 58). This
skill is a ROUTER, not a copy: the official Supabase skills live
upstream and are revised per release. A vendored copy rots — the same
rule `mobile-kit` applies to Expo Skills. Install by reference, use the
scope below, and never copy the package into this repo.

## 0. Pins — read first, never drift

- Package: `supabase/agent-skills` — https://github.com/supabase/agent-skills
- Announcement: https://supabase.com/blog/supabase-agent-skills
- License: **MIT** (verified via GitHub API 2026-11-13)
- Repo state verified 2026-11-13: 2 skills (`supabase`,
  `supabase-postgres-best-practices`), `package.json` version **0.1.9**,
  updated 2026-11-13, 3,048 stars.
- `@supabase/supabase-js` **2.119.0** · Supabase CLI **3.1.0**
  (`npm view`, 2026-11-13).
- Free-tier pins (official pages, read 2026-11-13): Supabase Free
  $0/month, 2 active projects, 500 MB DB, 50,000 MAU, 5 GB egress,
  **500,000 Edge Function invocations/month included**; free projects
  pause after 1 week of inactivity. Edge Functions (Free): wall clock
  **150 s**, CPU **2 s/request**, idle timeout **150 s → 504**, memory
  **256 MB**, max 100 functions, secrets max 100/project (48 KiB each).
  Sources: https://supabase.com/pricing and
  https://supabase.com/docs/guides/functions/limits (updated 29 Oct 2026).

## 1. Install

```bash
npx skills add supabase/agent-skills
```

Both skills install at once. They land in `.agents/skills/` in the
project (Claude Code: `~/.claude/skills/` for a global install). The
package also serves skills at
`https://supabase.com/.well-known/agent-skills/` for discovery tooling.
If the install command fails, report the exact error and stop; do not
invent another install source.

## 2. Scope for tomorrow (Edge Function first)

The `supabase` skill covers all Supabase products. Tomorrow the team
uses exactly three of them:

1. **Edge Functions** — the `ai-run` function is the AI endpoint
   (Gemini primary, Groq fallback). Write it in Deno (`Deno.serve`),
   secrets via `supabase secrets set`, deploy with `supabase functions
   deploy ai-run`. The skill's first principle applies here:
   **Supabase changes frequently — verify against the changelog and
   current docs before implementing; do not rely on training data.**
   Fetch `https://supabase.com/changelog.md` and scan for
   `breaking-change` tags relevant to Edge Functions before deploying.
2. **Database (fallback mirror only)** — the `runs` table mirror is
   created ONLY if the 13:00 Convex-fallback switch fires (see
   `backend-kit` §7). Same columns as the Convex `runs` table, plus
   `UNIQUE (user_id, idempotency_key)`. Reads go through a `get-run`
   Edge Function; the table is never directly readable by anon.
3. **Auth (anonymous, optional)** — `signInAnonymously()` for the
   fallback table's owner policies, only if the fallback fires.
   Anonymous users carry the `authenticated` role, not `anon` — see §3.

Everything else in the skill (Storage, Vectors, Realtime, Cron,
Queues, SSR integrations) is out of scope for the demo. Do not build
on it.

## 3. Rules that must not be broken (from the official skill, read in full 2026-11-13)

- **Grant + RLS + policies are ONE migration, in that order.** Since
  30 Oct 2026, new tables in `public` start with NO Data API access:
  no grant = 42501 "permission denied for table", and Postgres checks
  the grant BEFORE RLS — policies alone fix nothing. A 42501 error
  means a missing grant, not a broken policy. RLS denial returns empty
  data, not an error.
- **RLS on every table in any exposed schema.** Never create a table
  and "add RLS later".
- **`auth.role()` is deprecated — use the `TO` clause.** And
  `auth.role() = 'authenticated'` breaks silently when anonymous
  sign-ins are enabled, because anonymous users carry the
  `authenticated` role.
- **`TO authenticated` alone is authentication without authorization
  (BOLA/IDOR).** Every policy combines it with an ownership predicate:
  `using ( (select auth.uid()) = user_id )`, and UPDATE policies need
  both `USING` and `WITH CHECK`.
- **Never expose `service_role` in a public client.** Prefer
  publishable keys for frontend code. Never add `SECURITY DEFINER` to
  resolve a permission error — it silently removes access control.
- **UPDATE requires a SELECT policy** — without one, updates silently
  return 0 rows, no error.
- **Storage upsert requires INSERT + SELECT + UPDATE** (only relevant
  if the idea adds uploads — it does not in slice 1).
- **Pin package versions and commit lockfiles** when installing
  Supabase packages.
- **CLI: always discover commands via `--help`, never guess.** Known
  gotchas from the skill: `supabase db query` requires CLI v2.79.0+;
  `supabase db advisors` requires CLI v2.81.3+; the browser flow of
  `supabase login` creates a classic token with full account access —
  in CI use a scoped `SUPABASE_ACCESS_TOKEN` instead.
- **Schema changes:** decide declarative (`supabase/schemas/`) vs
  imperative migrations first. In imperative projects, iterate with
  `execute_sql` (MCP) or `supabase db query` (CLI) and generate the
  clean migration only when ready (`supabase db pull
  <descriptive-name> --local --yes`); do NOT use `apply_migration`
  to iterate — it writes a history entry on every call. Never edit
  the hosted schema in the dashboard — a dashboard edit is a
  migration that doesn't exist in git.
- **Debugging:** on any Supabase error (HTTP, Postgres, PostgREST,
  RLS surprise, Edge Function crash), fetch the Monitoring and
  Debugging doc
  (https://supabase.com/docs/guides/monitoring-and-debugging.md)
  before diagnosing — do not work from memory.

## 4. The Postgres best-practices skill

`supabase-postgres-best-practices` (same package) holds Postgres
guidance across 8 categories: query performance, connection
management, schema design, concurrency and locking, security and RLS,
data access patterns, monitoring and diagnostics, advanced features.
Load it before creating or altering the fallback mirror table. It is
general Postgres guidance, not Supabase-specific — it applies to the
mirror table, not to Convex.

## 5. File map

| File | What it is |
|---|---|
| `SKILL.md` (this file) | Install command, tomorrow's scope, the unbreakable rules. |
| (upstream) `supabase/agent-skills` | The official package — installed by reference, never vendored. |

## 6. Verification status (read 2026-11-13)

- Repo cloned (depth 1) 2026-11-13: 2 skill dirs confirmed;
  `skills/supabase/SKILL.md` (155 lines) read in full;
  `skills/supabase-postgres-best-practices/SKILL.md` (64 lines) read.
- License MIT and updated date 2026-11-13 verified via the GitHub
  API today.
- **Version inconsistency inside the official repo:** the skill
  file's frontmatter says `version: "0.1.2"` while `package.json`
  says `0.1.9`. The content was read in full and is current on the
  RLS/grant rules; only the version string is stale. Do not quote
  `0.1.2` as the package version.
- The install command was verified on the official blog post
  (https://supabase.com/blog/supabase-agent-skills). The install
  itself was NOT run in this pass (installing writes into a project;
  the builders run it in the hackathon repo).
- URLs verified by the coordinator 2026-11-13:
  `https://supabase.com/changelog.md` → HTTP 200;
  `https://supabase.com/.well-known/agent-skills/` → HTTP 308
  (redirects to the skills catalog).
- **CHƯA ĐỌC:** whether the team's Supabase project is currently
  paused (dashboard-only check — wake it the night before and ping
  it daily); the exact `supabase functions deploy` output for
  `ai-run` (first deploy happens on build day).
