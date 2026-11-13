# Database Deep Brief — muse-fleet hackathon build (Sat 14/11/2026)

**Date:** 2026-11-13 · **Author:** database research subagent · **Status:** draft for red team
**Scope:** the data layer only. The stack pick is CARRIED, not re-picked: **Expo + React Native + TypeScript SDK 57, Convex primary / Supabase fallback** (backend-agent-toolkit-20261112 + mobile-agent-toolkit-20261112 reports, 12/11). This brief deepens that pick into something the team can implement tomorrow, 11:00–16:00, with the demo on a real Android phone (kill + reopen, main AI flow live = 40 points).

**How to read this:** §2–§4 are copy-paste starter code. §9 is the traps list — read it before writing a line of schema. §10 is the bold plays. §12 is the hour-by-hour runbook. Every load-bearing claim carries a URL + access date; anything not verified is marked **CHƯA ĐỌC** or **UNVERIFIED** in §13.

---

## §1. The one decision that matters before 11:00

**Convex primary, Supabase fallback — confirmed, with one addition: anonymous auth on both.**

The backend report's pick stands (Convex: one TS codebase, docs designed for AI-generated code, per-agent scoped dev deployments, free tier 1M calls). The mobile report's conflict is resolved the same way the parent oriented it: **Convex primary, Supabase fallback**. The AI endpoint lives on Convex (an `action`); if Convex is unreachable at 11:00, the fallback is the mobile report's Supabase Edge Function — but the schema sketch in §2 is written so the same table shapes map 1:1 to Postgres, so a switch costs a re-type, not a re-design.

**The addition — no sign-up wall, but real row ownership.** The backend report's lever says "no sign-up wall, share-link persistence only". The way to have both is anonymous auth:

- **Convex:** `@convex-dev/auth` supports anonymous sign-in (backend report, 12/11). The phone gets a server-issued identity on first launch; every row is stamped with that identity; `ctx.auth.getUserIdentity()` gates reads/writes inside each function.
- **Supabase:** `supabase.auth.signInAnonymously()` creates an anonymous session in one line — **but anonymous users get the `authenticated` role, NOT the `anon` role**, and any policy written `TO authenticated USING (true)` lets an anonymous user read *every* row (tested 2026-10-28 against the open-source Supabase Auth server — VibeLocked Edition 5, https://buttondown.com/vibelocked/archive/vibelocked-edition-5-anonymous-supabase-users/, accessed 2026-11-13). So anonymous auth on Supabase only works if every policy keys on `auth.uid() = user_id` — never on the role alone. See trap T2.

**Bold recommendation (evidenced, not hype): do not build a login screen at all.** The demo's first 30 seconds are the AI feature, not an auth form. Anonymous identity + share links (see §10.3) covers the "market expansion / first users" criterion (25 points) better than accounts do: a judge can open a share link with no install and no account.

---

## §2. Schema sketch — starter template for a generic AI-feature app

The app is generic on purpose: one **input** (whatever the user gives — text, photo, voice note, a list), one **AI run** (the essential AI step), one **result** (the thing the user keeps, shares, or acts on). Every hackathon idea the team might pick tomorrow maps onto these four tables. Rename `items`/`runs` to the domain nouns once the idea lands; do not redesign the shapes.

### 2.1 Convex (`convex/schema.ts`)

```ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // One row per device identity. Created on first launch by anonymous auth.
  // Never store email/name here — the demo has no accounts.
  users: defineTable({
    anonymousId: v.string(),          // convex auth subject, or client UUID fallback
    displayName: v.optional(v.string()),
    agent: v.optional(v.string()),    // "milo" | "mie" | "migga" | "muse" — dev only, see §8
    isDemo: v.boolean(),              // true for seeded demo rows, false for live rows
  })
    .index("by_anonymousId", ["anonymousId"]),

  // The user's stuff: whatever the app organises (notes, photos, lists, cards…).
  // One table, not one table per feature — you do not have time for joins.
  items: defineTable({
    userId: v.id("users"),
    title: v.string(),
    body: v.optional(v.string()),
    imageId: v.optional(v.id("_storage")),   // Convex file storage, see §2.3
    status: v.union(
      v.literal("draft"),
      v.literal("ready"),        // AI run finished, result attached
      v.literal("failed"),       // AI run failed — user-visible, retryable
    ),
    agent: v.optional(v.string()),           // dev-namespacing, see §8
    isDemo: v.boolean(),
  })
    .index("by_user", ["userId"])
    .index("by_user_status", ["userId", "status"])
    .index("by_demo", ["isDemo"]),

  // The AI run itself — ONE ROW PER RUN, never overwrite the last result.
  // This table is the demo's memory: kill the app, reopen it, the last run
  // is still here, and the judges see the result, not a loading spinner.
  aiRuns: defineTable({
    userId: v.id("users"),
    itemId: v.id("items"),
    idempotencyKey: v.string(),   // client-generated UUID, see §10.4
    inputSummary: v.string(),     // short, displayable — never the raw prompt
    model: v.string(),            // e.g. "gpt-6.1-terra" — record what actually ran
    status: v.union(
      v.literal("queued"),
      v.literal("running"),
      v.literal("done"),
      v.literal("failed"),
    ),
    resultText: v.optional(v.string()),
    resultJson: v.optional(v.string()),  // structured output, JSON-encoded, size-capped
    error: v.optional(v.string()),       // the REAL error string, not "something went wrong"
    durationMs: v.optional(v.number()),
    agent: v.optional(v.string()),
    isDemo: v.boolean(),
  })
    .index("by_item", ["itemId"])
    .index("by_user_status", ["userId", "status"])
    .index("by_user_idempotencyKey", ["userId", "idempotencyKey"])
    .index("by_demo", ["isDemo"]),

  // Share links: the market-expansion story, with no second app install.
  // A code the user can hand to anyone; the link renders the result.
  shares: defineTable({
    runId: v.id("aiRuns"),
    code: v.string(),             // short, unguessable, e.g. 8 chars from crypto
    createdBy: v.id("users"),
    viewCount: v.number(),
    isDemo: v.boolean(),
  })
    .index("by_code", ["code"])
    .index("by_run", ["runId"]),
});
```

**Why these shapes (each line is a trap avoided):**

- `aiRuns` is append-only. Overwriting the last result is the single most common demo-killer: the judges kill the app mid-run, reopen it, and the in-flight result is gone. Append-only + `status` means reopen always shows *something* — the last `done` run, or a `failed` run with a retry button. (§9, T1.)
- `idempotencyKey` + `by_user_idempotencyKey` index. Convex has no unique constraint syntax; the dedup pattern is: in the same mutation transaction, look the key up on the index first, return the existing row on a hit (TanStack DB Convex collection docs, https://tanstack.com/db/latest/docs/collections/convex-collection, accessed 2026-11-13: "Your Convex mutation must accept idempotencyKey… Look up the key in an indexed receipts table. If a receipt exists, return its saved result… Convex executes these writes atomically. A client can lose an acknowledgement after the server commits, so SDK request deduplication alone cannot replace this durable receipt"). **The lookup is scoped by `(userId, idempotencyKey)` — never global:** the same TanStack section continues "Scope receipt keys to the authenticated owner, and apply authorization before returning a saved result" — a client replaying another user's key must never be handed that user's saved result, so check `doc.userId === user._id` before returning. Convex mutations are serializable, so two concurrent identical calls cannot both miss (corroborated by independent OCC teardowns — loams.dev, devtoolsacademy — red-team verified 2026-11-13). (§10.4.)
- `status` is a closed union, not a free string. A typo'd status string ("Done" vs "done") is an invisible bug that only shows up on stage. Validators reject it at write time (Convex schema docs, `v.union`/`v.literal` — https://docs.convex.dev/database/schemas, accessed 2026-11-13).
- `resultJson` is a *string*, not `v.any()`. `v.any()` defeats schema validation — the one safety net you have. Cap it client-side (~50 KB) so one runaway model output cannot bloat the table.
- `isDemo` on every table. The demo reset (§4) deletes `isDemo: true` rows and reseeds; live rows (if any judge creates one) survive. Without the flag, reset = delete everything, including the judges' own data, in front of them.
- `_creationTime` is auto-added to every document (Convex schema docs). **Sort by `_creationTime`, never by a client timestamp** — the phone clock is untrusted and the café Wi-Fi may serve a stale NTP. (Schema docs, same URL.)
- Index budget: max 32 indexes per table, max 16 fields per index (official Convex limits page, read by the red team 2026-11-13 — the first draft cited it via Waymark only). The sketch uses 10 indexes total. You will not hit the cap; the point is to know it exists before someone adds an index per screen.

### 2.2 Supabase mirror (same shapes, Postgres + RLS)

```sql
-- Run once, in order. Every table is born with RLS ON and owner-only policies.
-- Never create a table and "add RLS later" — later never comes before the demo.
create table public.users (
  -- id MUST be the auth user id (auth.uid()), not a random UUID:
  -- every owner policy compares against auth.uid(), so a random id
  -- would match nothing and the policies would deny everything.
  id uuid primary key references auth.users(id),
  anonymous_id text not null unique,
  display_name text,
  agent text,
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  body text,
  image_path text,
  status text not null default 'draft'
    check (status in ('draft','ready','failed')),
  agent text,
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.ai_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  idempotency_key text not null,
  input_summary text not null,
  model text not null,
  status text not null default 'queued'
    check (status in ('queued','running','done','failed')),
  result_text text,
  result_json jsonb,
  error text,
  duration_ms integer,
  agent text,
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, idempotency_key)   -- the dedup the DB enforces for you
);
create table public.shares (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.ai_runs(id) on delete cascade,
  code text not null unique,
  created_by uuid not null references public.users(id) on delete cascade,
  view_count integer not null default 0,
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);
create index items_by_user on public.items (user_id);
create index items_by_user_status on public.items (user_id, status);
create index ai_runs_by_item on public.ai_runs (item_id);
create index ai_runs_by_user_status on public.ai_runs (user_id, status);
create index shares_by_code on public.shares (code);
-- Grants + RLS + policies live in the SAME migration as these tables —
-- see §3.2. Never create these tables without the grant block: since
-- 30 Oct 2026 a new public table with no GRANT is invisible to the Data API.
```

Notes: `unique (user_id, idempotency_key)` is the Postgres-native version of the Convex index-check pattern — the DB rejects the duplicate, the app catches the conflict and re-reads the existing row. `status` uses `CHECK` constraints because Postgres has no union validator. `result_json jsonb` is the one place a schemaless column is acceptable — it is output, not input, and the app validates it before rendering.

### 2.3 Files (AI-generated images, user photos)

- **Convex:** file storage is built in — `ctx.storage.store()` in a mutation, `generateUploadUrl` for the client, `getUrl` to read (Convex changelog 1.48, https://www.convex.dev/changelog — OFFICIAL changelog, accessed 2026-11-13; the official storage docs page is **CHƯA ĐỌC**). Store the returned storage ID (`v.id("_storage")`, as in §2.1), never a raw URL — a `getUrl` URL is a bearer URL valid for the file's lifetime (anyone holding it can read the file, no auth; only the *upload* URL expires, after 1 hour), so the ID is the handle you control and the URL is the handle you hand out.
- **Supabase:** Storage is a separate bucket with **its own RLS on `storage.objects`** — table policies do not cover it. Each upload mode needs its own policy: a new file needs INSERT; `upsert: true` on a new path needs INSERT **and** SELECT; overwriting needs UPDATE too; and policies that only check `bucket_id` let a second user overwrite the first user's file (VibeLocked Edition 5, same URL as §1). Put each user's files under their uid and compare against `auth.uid()`. Treat download URLs like passwords.

---

## §3. The RLS / policy rules that must exist before any user data flows

**Rule zero: no table goes live without its access rule — and on Supabase there are TWO layers, not one.** The GRANT decides whether a role can touch a table at all; RLS decides which rows it sees. Since 30 Oct 2026, new tables in `public` start with NO grant at all (trap T11) — policies alone fix nothing, and Postgres checks the grant before RLS. On both backends, the default is deny — and the failure mode is silence (empty data), not an error, once the grant exists.

### 3.1 Convex — the check lives inside every function

Convex has no RLS equivalent: public `query`/`mutation`/`action` functions are callable by anyone with the deployment URL, so authorization must be checked inside the function via `ctx.auth.getUserIdentity()`; `internal*` functions are not publicly callable (BNA UI deployment page + valentynkorzun.dev, accessed 2026-11-13 — both THIRD-PARTY, consistent with each other).

Copy this pattern into every public function. No exceptions, no "we'll add auth later":

```ts
// convex/lib/auth.ts — one helper, imported everywhere
import { QueryCtx, MutationCtx } from "../_generated/server";

export async function requireUser(ctx: QueryCtx | MutationCtx) {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) throw new Error("unauthenticated");
  const user = await ctx.db
    .query("users")
    .withIndex("by_anonymousId", (q) => q.eq("anonymousId", identity.subject))
    .unique();
  if (!user) throw new Error("no user row — call ensureUser first");
  return user;
}

// Every read then adds: .withIndex("by_user", q => q.eq("userId", user._id))
// Every write then checks: doc.userId === user._id, or throws.
```

And the audit rule that makes this enforceable in a 5-hour build — **the team's own rule, not Owlat's**: every public function carries a `// public: <reason>` comment, and a grep in CI fails the build if a bare `query(`/`mutation(`/`action(` appears without one. This is *inspired by* Owlat's convention, but it is not Owlat's rule: Owlat bans the bare builders outright everywhere except one allowlisted file (`authedFunctions.ts`) and puts the `// public: <reason>` comment on its *wrapper* builders (`publicQuery` / `publicMutation` / `publicAction`) — a bare `query(` with a `// public:` comment would still fail Owlat's lint (Owlat docs, https://docs.owlat.app/developer/convex/, accessed 2026-11-13). The team's grep rule is weaker than Owlat's and honestly labelled as such; it costs 10 minutes and it is the only thing standing between "demo" and "anyone on the internet can read the judges' data". If the team has time, adopting Owlat faithfully (wrapper builders + lint) is strictly better.

### 3.2 Supabase — RLS policies (run before the first insert)

```sql
-- GRANT + RLS + POLICIES ARE ONE UNIT. Supabase's own guidance: put all
-- three in the same migration, in this order — grant, enable RLS, policies.
-- Since 30 Oct 2026, new tables in `public` start with NO Data API access:
-- no grant = 42501 "permission denied for table", and Postgres checks the
-- grant BEFORE RLS, so policies alone fix nothing.
-- (Supabase changelog, https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically,
--  accessed 2026-11-13; announced Apr 2026, default for new projects
--  30 May 2026, applied to all projects 30 Oct 2026.)

-- 1. Grants: only what each role needs. anon gets nothing.
grant select, insert, update, delete on public.users   to authenticated;
grant select, insert, update, delete on public.items   to authenticated;
grant select, insert, update, delete on public.ai_runs to authenticated;
grant select, insert, update, delete on public.shares  to authenticated;
revoke all on public.users, public.items, public.ai_runs, public.shares from anon;

-- 2. RLS on.
alter table public.users   enable row level security;
alter table public.items   enable row level security;
alter table public.ai_runs enable row level security;
alter table public.shares  enable row level security;

-- 3. Policies. Identity model: public.users.id IS the auth user id
-- (references auth.users(id) — see §2.2), so auth.uid() matches it.
-- (select auth.uid()) is the documented form: evaluated once per query.
create policy "owners insert own users row"
  on public.users for insert to authenticated
  with check ((select auth.uid()) = id);
create policy "owners read own users row"
  on public.users for select to authenticated
  using ((select auth.uid()) = id);
create policy "owners read own items"
  on public.items for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "owners insert own items"
  on public.items for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "owners update own items"
  on public.items for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "owners delete own items"
  on public.items for delete to authenticated
  using ((select auth.uid()) = user_id);
create policy "owners read own ai_runs"
  on public.ai_runs for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "owners insert own ai_runs"
  on public.ai_runs for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "owners update own ai_runs"
  on public.ai_runs for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "owners delete own ai_runs"
  on public.ai_runs for delete to authenticated
  using ((select auth.uid()) = user_id);
-- Shares is different: it has no user_id column —
-- its policies key on created_by:
create policy "owners read own shares"
  on public.shares for select to authenticated
  using ((select auth.uid()) = created_by);
create policy "owners insert own shares"
  on public.shares for insert to authenticated
  with check ((select auth.uid()) = created_by);
create policy "owners delete own shares"
  on public.shares for delete to authenticated
  using ((select auth.uid()) = created_by);

-- The ONE public read path: anyone with the code may read that single run.
-- Implemented as a SECURITY DEFINER function, NOT a public SELECT policy.
-- (A security definer function runs as its owner and bypasses RLS.)
create or replace function public.read_shared_run(p_code text)
returns setof public.ai_runs
language sql
security definer
set search_path = public
as $$
  select r.* from public.ai_runs r
  join public.shares s on s.run_id = r.id
  where s.code = p_code;
$$;
revoke all on function public.read_shared_run(text) from public;
grant execute on function public.read_shared_run(text) to anon, authenticated;
-- The share page renders resultText from the run row. If it also needs the
-- item title, extend this function to return it — do not open a public
-- SELECT on items.
-- service_role bypasses RLS by design — it must never appear in the app bundle.
```

Mechanics verified from the official RLS docs (mirrored on the Supabase GitHub repo + agilesoftlabs guide, accessed 2026-11-13): `ALTER TABLE … ENABLE ROW LEVEL SECURITY`; default deny-all once enabled; `CREATE POLICY … FOR SELECT/INSERT/UPDATE/DELETE/ALL TO anon/authenticated USING (…) WITH CHECK (…)`; `service_role` bypasses RLS. The grants layer is verified from the official Supabase changelog (URL in the SQL block above): new `public` tables get no automatic Data API grants — announced Apr 2026, default for new projects 30 May 2026, all projects 30 Oct 2026; a missing grant returns 42501, and RLS denial (once the grant exists) returns empty data, not an error.

**The three Supabase traps that live in this section (full detail in §9, T2/T3/T11):** anonymous users are `authenticated`, so role-only policies are open doors; RLS denial returns **empty data, not an error** — a missing policy looks exactly like "the seed didn't load"; and a **missing grant returns 42501, not empty data** — so when the screen is empty, check the grant first (42501 = grant), then the policies. If the screen is empty, check policies before re-seeding — and test them through the Data API with the app's key/JWT, never the SQL Editor (it runs as postgres/service_role and bypasses RLS, so it shows rows the app can't see).

---

## §4. Seed data — the demo never shows an empty screen

**Principle: the seed is the demo's understudy.** If the AI call fails, if the network drops, if the judges kill the app 10 seconds in — the seeded rows are what they see. Seed generously, seed realistically, and seed *finished* AI results, not empty shells.

### 4.1 The seed list (13 rows, ~10 minutes to write)

| # | Table | Content | Why |
|---|-------|---------|-----|
| 1–3 | items + aiRuns (done) | Three complete, believable items with `status: ready` and a finished `resultText` each | The home screen on first open. Three is the magic number: one looks empty, two looks thin, three looks like a product |
| 4 | items + aiRuns (failed) | One item with `status: failed` and a human-readable `error` ("Model timed out after 30s — retry") | Proves the failure state is designed, not a crash; the retry button is visible and works |
| 5 | items + aiRuns (queued) | One item with `status: queued` | Proves the waiting state. (Do NOT seed a `running` row: with no backing process it would never transition to `done` and would demo a stuck spinner. The live `running` state is demonstrated by a real run.) |
| 6 | shares | One share code pointing at run #1, `viewCount: 3` | The share flow is demonstrable without making a new run |
| 7 | users | The demo user row (`isDemo: true`) | Everything above hangs off it; the app signs in as this user on first launch |
| 8 | items | One deliberately *ordinary* item (not the prettiest) | Judges distrust a demo that only shows the best case; the ordinary row is credibility |

All seeded rows carry `isDemo: true`. All seeded `resultText` is **real output from a real run of the actual model during rehearsal** — never hand-written lorem, never invented. If the real model hasn't produced it yet, the seed is a placeholder and must be replaced before 15:00.

### 4.2 How to load it

- **Convex (three ways, verified — stack.convex.dev seeding guide, accessed 2026-11-13):**
  1. Dashboard manual entry — slowest, only for one-off fixes.
  2. CLI import: `npx convex import --table items items.jsonl` (CSV / JSON array / JSONL / export zip all accepted; import fails under schema validation if the data doesn't match — which is a feature, it catches a bad seed before it lands).
  3. **In code (recommended for the hackathon):** a `convex/seed.ts` internal mutation that deletes all `isDemo: true` rows and then inserts the 13 rows — idempotent by construction, so running it twice rebuilds rather than duplicating. One command reseeds: `npx convex run seed:reset --prod` — and that command is the "2-minute rebuild" guarantee in §10.1.
- **Supabase:** `supabase/seed.sql` is auto-applied after migrations on `supabase db reset` (and on `supabase start`) — official CLI reference + local-development guide, accessed 2026-11-13. Write the seed as SQL, commit it, and `supabase db reset` becomes the rebuild command. `supabase db reset --remote` replays migrations + seed on the linked project — **destructive, drops the remote schema** — so it is the reset button, not a casual command.

### 4.3 The seed test (5 minutes, do it at 14:00)

Fresh install → open app → **the three finished results are visible within 3 seconds, with no network interaction from the user**. Then kill the app, reopen, same screen. Then airplane mode, reopen, same screen (from the bundled fallback, §10.2). If any step fails, the seed is broken, not the demo.

---

## §5. Offline / sync — what the user sees when the network drops mid-demo

This is the section the judges will test without telling you: they kill the app, they walk between rooms, the café Wi-Fi stutters. Here is the honest behaviour, per backend, from verified sources — and the design that follows from it.

### 5.1 Convex

Sources **conflict** on the details, so the design uses only the intersection every source agrees on:

- Queuert PITFALLS.md (third-party, researched 2026-01-23): mutations queue when offline, but **query results are NOT cached locally** — airplane-mode `useQuery` = no data.
- BNA UI realtime page (third-party): reads render from the last state the client had (a warm app still shows something); **a mutation with no connection REJECTS — it does not silently queue**; on reconnect, every active query resyncs automatically.
- TanStack DB Convex collection docs (official TanStack): the client serves a query's cached result to a new subscription at once.

**Safe demo rule (the intersection):** in-memory last-known state only, no durable offline cache, and design as if offline mutations **may reject** — the sources genuinely conflict on whether they queue or reject (Queuert: queues; BNA UI: rejects; TanStack docs: "Convex handles WebSocket interruptions without rejecting the mutation promise"), so the behaviour is **contested, not settled**. The engineering response is the same either way: try/catch + visible retry + idempotency key. Design consequences:

1. **Never render `undefined` as empty.** `useQuery` returns `undefined` while loading on first mount — and once a query has loaded it will **never be `undefined` again**, even as the data reactively updates (official best-practices page, same URL). So the flash-of-empty happens on fresh mount (kill-and-reopen), not on reconnect: after a network drop the last value stays on screen while the client resubscribes. Official Convex guidance (https://docs.convex.dev/understanding/best-practices/other-recommendations, accessed 2026-11-13): "Check for `undefined` to determine if a query is loading… `undefined` is not a valid return type for queries." So the screen has exactly three states: `undefined` → skeleton (never the empty state); `[]` → genuine empty state; data → render. **The classic demo-killer is showing "No items yet" for 2 seconds on kill-and-reopen while the query resubscribes** — the judges see an empty screen at the exact moment that matters (trap T1).
2. **Every mutation call is wrapped in try/catch with a visible retry.** If the network dropped, the mutation may reject outright or may queue and resolve later — either way the UI must not silently swallow it. The UI must say "Couldn't save — retry" and keep the user's input on screen. A silent failure looks like a broken app; a visible retry looks like a robust one.
3. **Optimistic update for the one interaction the judges will hammer** (the primary action button): `useMutation` with `optimisticUpdate` so the UI responds instantly and reconciles when the server answers. Only for the primary action — optimistic updates on every field are a bug farm in 5 hours.

### 5.2 Supabase

- **No client-side database:** queries fail when offline (data null + fetch error) — RxDB docs, tomodahinata guide, iloveblogs, accessed 2026-11-13.
- **Realtime is WebSocket; missed events during a disconnect are NOT replayed** — the app must refetch on `SUBSCRIBED` (same sources).
- **Limits:** 200 concurrent connections Free / 500 Pro / 10,000 Team; 100 channels per connection (same sources). Four humans + four agents + a few judges will not hit 200 — but one channel per row would.

Design consequences: the Supabase fallback app **must** refetch on reconnect and on app-foreground, and must show a cached last result from AsyncStorage (the mobile report's pattern — cache the last AI result JSON in AsyncStorage). TanStack Query's `persistQueryClient` + `createAsyncStoragePersister` persists its cache to AsyncStorage/MMKV for cold-start renders, with `onlineManager` (NetInfo) pausing/resuming and `networkMode: 'online'` pausing mutations offline (jared.lynskey.co.nz, reactnative.codeguides.io, sheets-and-giggles local-state.md — all third-party, accessed 2026-11-13). **Note:** whether TanStack persist composes directly with Convex's `useQuery` is **UNVERIFIED** (plausible, not sourced) — the practical bridge below does not depend on it: cache the last AI result JSON in AsyncStorage, which is already the mobile report's pattern.

### 5.3 Kill-and-reopen — the 40-point moment, step by step

| Second | What happens (Convex) | What the judges see |
|---|---|---|
| 0 | App killed | — |
| 0–1 | App relaunches, Convex client reconnects, `useQuery` resubscribes | Skeleton (not empty state — see §5.1.1) |
| 1–3 (estimate — not measured) | Last `done` aiRun arrives from the server | The finished result, exactly as before the kill |
| 3+ | Any `running` run either completes (live update pushes) or stays `running` with a spinner | A live product, not a screenshot |

If the network is dead at reopen, the skeleton stays — and that is when the bundled fallback (§10.2) earns its place.

---

## §6. Migrations during a 5-hour build — change schema without breaking the running app

**The golden rule: never break the running app to improve the schema.** The app on the demo phone is running from 11:00; the schema will change at least twice before 15:00. The pattern that survives this (stack.convex.dev "The secret to migrations" + BNA UI deployment page, accessed 2026-11-13):

1. **Widen** — add the new field as `v.optional(...)`. Deploy. Old code ignores it; new code handles its absence.
2. **Backfill** — a one-off mutation that fills the field on existing rows (or the seed re-run does it).
3. **Narrow** — in a *later* deploy, tighten to required. Never widen + narrow in the same deploy.

Two hard facts that make this non-optional:

- **The first push after a schema change validates ALL existing documents, and the push FAILS if any fail** (official Convex schema docs, https://docs.convex.dev/database/schemas, accessed 2026-11-13). A tightening change against seeded rows that lack the field = a failed deploy at the worst moment. Staged validators (`.staged()`) validate a tightening change in the background instead; `schemaValidation: false` is the escape hatch — use it only to unblock a demo, never as a habit.
- **`npx convex deploy` does not roll back.** Deploy the backend *before* the app that needs it, and never deploy a schema you haven't first pushed to a dev deployment.

**Hour-by-hour migration discipline:**

| Hour | Schema rule |
|---|---|
| 11:00–12:00 | Schema v1 lands with the seed. No changes after 12:00 except additive-optional. |
| 12:00–14:00 | Additive-optional only. Any field you "need" can wait — add it optional, backfill, move on. |
| 14:00–15:00 | **Schema freeze.** No schema changes at all. If a field is missing, the app handles its absence. |
| 15:00 | Final deploy to prod (the demo bunker, §10.1). After this, schema is read-only. |

**Supabase equivalent:** migrations live in `supabase/migrations/` as SQL files; `supabase db push` is the migrations-only path (official CLI reference, accessed 2026-11-13). Never edit the hosted schema in the dashboard — a dashboard edit is a migration that doesn't exist in git, and the next `db push` will fight it. Every migration is additive until 14:00; destructive migrations (`DROP COLUMN`) are banned for the day.

---

## §7. Backup / export before submission

- **Convex (official docs, https://docs.convex.dev/database/backup-restore, accessed 2026-11-13):** dashboard backups, manual backups stored 7 days; `npx convex export --path ./backups` — the path is a *directory*, the export writes `snapshot_{ts}.zip` inside it — with `<table>/documents.jsonl` per table; `npx convex import --table <name>` restores. **Run the export at 15:00, right after the prod deploy, and again at 15:45.** The zip is also the seed source for tomorrow's post-hackathon work.
- **Supabase:** no automatic backups on the Free plan; manual export via `supabase db dump` (pg_dump wrapper — CLI reference URL verified, details not read in full, **partial**). Pro ($25/mo) gives 7 days of daily backups (supaclone.io + Medium comparison, third-party, accessed 2026-11-13) — **do not buy Pro during the build window**; the free `db dump` is enough.
- **The phone is a backup too.** The last AI result is a document in the database, not pixels on a screen. If the database dies, the export restores it; if the app dies, the database re-renders it. The only unrecoverable loss is a result that was never written to the DB — which is why §2 makes `aiRuns` append-only and why the action writes the row *before* returning to the client.

---

## §8. Per-agent dev data isolation — 4 agents, one shared backend

The failure mode: Milo seeds test rows, Mie wipes them with a reset, Migga's AI runs overwrite Milo's, and the 15:00 demo shows a mix of four agents' garbage. The fix is boring and total: **namespaces + separate deployments, never shared rows.**

### 8.1 Convex (recommended)

One dev deployment per agent, with scoped deploy keys (official Convex AI overview, verified 2026-11-12 in the backend report). Each agent runs `npx convex dev` against *their* deployment; the integrator (Muse) owns the single prod deployment and merges there. Additionally, every row carries the `agent` column from §2 — so even if two agents' data lands in the same deployment during integration, a query filtered by `agent` shows only your own rows, and the 15:00 reset deletes `agent != null` rows first.

### 8.2 Supabase fallback

**Trap: the Free plan allows only 2 active projects, so 4 separate projects don't fit** (supaclone.io + Medium, accessed 2026-11-13). The workaround, in order of preference:

1. **Local-first (best):** each agent develops against a local Supabase stack (`supabase start` runs the full stack locally via Docker — official local-development guide, accessed 2026-11-13). Migrations + seed live in git; the shared hosted project receives them only at integration, via `supabase db push`.
2. **Namespaced rows in one shared project:** every row carries the `agent` column; every query filters by it; the reset deletes by agent. Works, but one agent's bad migration still breaks the other three — which is why option 1 is first.
3. Separate orgs for extra projects — **DEAD END, do not attempt.** The 2-active-project Free limit counts across every organisation where you are Owner or Administrator — creating another organisation does not help, and paused projects don't count toward the limit (Neon free-tier guide, https://neon.com/guides/neon-vs-supabase-free-plan, accessed 2026-11-13, consistent with Supabase's billing docs and six other Nov-2026 sources; red-team verified).

### 8.3 The integration rule

**15:00 is the merge deadline for data, not just code.** After 15:00, nobody seeds, nobody resets, nobody migrates. The integrator runs the seed once, verifies the three finished results on the real phone, and the data is frozen with the code (see §10.1).

---

## §9. Top 11 traps — what breaks at demo time, and the fix

(T1–T8 are the required top 8; T9–T11 are bonus, found in the deep pass — T11 was caught by the red team.)

| # | Trap | What breaks at demo time | Fix |
|---|---|---|---|
| **T1** | **`useQuery` returns `undefined` while loading — and the app renders it as "empty"** | Judges kill + reopen the app; for 1–3 s the query resubscribes and returns `undefined`; the screen flashes "No items yet" — the judges see an empty product at the exact moment worth 40 points | Three states, no exceptions: `undefined` → skeleton; `[]` → empty state; data → render. Official guidance: "Check for `undefined` to determine if a query is loading… `undefined` is not a valid return type for queries" (docs.convex.dev/understanding/best-practices/other-recommendations, accessed 2026-11-13). Test it by killing the app on the real phone, not the emulator |
| **T2** | **Supabase anonymous users are `authenticated`, not `anon`** | A policy `TO authenticated USING (true)` — written to mean "signed-in users only" — lets *any* anonymous visitor read every row. A judge who opens the app gets everyone's data; worse, a policy `auth.uid() IS NOT NULL` lets an anonymous user read another user's posts | Every policy keys on `(select auth.uid()) = user_id`, never on the role. `is_anonymous` checks only work as **restrictive** policies (permissive policies OR together, so a permissive `is false` check next to the normal policy does nothing); write `is false`, not `is not true` — `is false` fails closed (VibeLocked Edition 5, tested 2026-10-28, https://buttondown.com/vibelocked/archive/vibelocked-edition-5-anonymous-supabase-users/, accessed 2026-11-13) |
| **T3** | **RLS denial looks like missing data, not an error** | The screen is empty; the team re-seeds, re-deploys, re-checks the seed — and the rows were there all along, hidden by a missing or wrong policy. Supabase returns empty, not forbidden (once the grant exists — see T11) | When the screen is empty, check the grant first (42501 = missing grant, a loud error), then the policies — and test policies through the Data API with the app's key/JWT, never the SQL Editor (it runs as postgres/service_role and bypasses RLS, so it shows rows the app can't see and misleads the debugger into thinking policies are fine) |
| **T4** | **Convex functions are public by default — the auth check is yours to forget** | Any function without a `ctx.auth.getUserIdentity()` check is callable by anyone with the deployment URL. The demo's "share link" becomes "anyone can list all runs" | The `requireUser` helper (§3.1) in every public function + the team's own `// public: <reason>` rule (a grep in CI fails the build on a bare builder without one — inspired by Owlat's convention, but the team's own rule: Owlat itself bans bare builders outright except in one allowlisted file). The integrator greps before every merge |
| **T5** | **Schema tightening fails the deploy against existing rows** | At 14:30 someone makes a field required; the push validates all existing documents, the seeded rows lack the field, the deploy fails — a failed push applies nothing, so the old backend keeps serving, but the deploy is blocked at the worst moment. (No automatic rollback exists for a *successful* bad deploy — which is why the freeze matters.) | Widen (optional) → backfill → narrow, in separate deploys (§6). Schema freeze from 14:00. Staged validators (`.staged()`) for any tightening change (official schema docs) |
| **T6** | **Offline mutations: behaviour contested on Convex — and the UI swallows the failure either way** | The judge taps the primary action while the Wi-Fi stutters; the mutation may reject outright or may queue and resolve later — sources genuinely conflict (Queuert: queues; BNA UI: rejects; TanStack docs: "Convex handles WebSocket interruptions without rejecting the mutation promise") — and nothing happens on screen in the meantime; the judge taps again, and when the network returns, two AI runs fire, two rows appear, and the second one burns the demo's time | Wrap every mutation in try/catch with a visible "Couldn't save — retry" state that keeps the input on screen; give the primary action an `idempotencyKey` (§2.1) so a double-tap returns the same run instead of starting a second one (TanStack Convex collection docs on durable receipts) |
| **T7** | **Supabase realtime misses events on reconnect — and never replays them** | The judge's phone drops Wi-Fi for 20 seconds; the AI run finishes during the gap; the phone never learns, and the screen sits on "running…" forever | Refetch on `SUBSCRIBED` and on app-foreground, always. On Convex the resubscribe is automatic — but the skeleton rule (T1) still applies during the resubscribe gap |
| **T8** | **The seed is hand-written fiction, and the judges can tell** | The seeded "AI results" read like placeholder copy; a judge asks a follow-up and the app has no real answer; credibility for the whole "real problem with evidence" criterion (35 points) drops | Every seeded `resultText` is real output from a real run of the actual model during rehearsal. If the model hasn't produced it yet, the seed is a placeholder and must be replaced before 15:00 (§4.1) |
| **T9** | **Anonymous sign-in rate limit: 30/hour per IP** | Four humans + four agents + judges, all on the café Wi-Fi, each opening the app fresh — the 31st anonymous sign-in from that IP gets a 429 (tested: "The 31st from one address got 429, and a second address went straight through" — VibeLocked Edition 5, same URL as T2) | Create the anonymous identity **once** at 11:00 and persist the session (`persistSession`/`autoRefreshToken` true); never sign in again during the day. If a 429 appears, the fix is not "retry harder" — it is "stop signing in" |
| **T10** | **The first AI call after idle is the slowest — and it happens on stage** | The model endpoint hasn't been called for an hour; the first call pays cold-start + model-load latency; the judges watch a spinner for 30–60 s and conclude the AI is slow | Warm-up ping at 14:45 and again at 15:50: one real AI run against the prod deployment, from the real phone, timed. If it takes >15 s, the demo script opens with a seeded result and runs the live call second. (Recommendation — a latency claim about the team's own endpoint can only be measured on the day, not sourced in advance.) Also: never depend on a mid-window EAS build — free queue 90+ min at peak (mobile report, 12/11 — inherited figure, not independently re-verified here) |
| **T11** | **Supabase 30 Oct 2026 grants change: new tables start with NO Data API access** | The fallback tables are created on 14/11 — every query fails with 42501 "permission denied for table"; the team debugs RLS policies for hours while the fix is one GRANT per table | Grant + RLS + policies in ONE migration, in that order (§3.2). A 42501 error means a missing grant, not a broken policy — RLS denial returns empty data, a missing grant returns 42501. (Supabase changelog, https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically, accessed 2026-11-13; announced Apr 2026, default for new projects 30 May 2026, all projects 30 Oct 2026.) |

---

## §10. Creative workarounds — the bold plays

These are the moves that turn a competent data layer into a demo that survives contact with the judges. Each one is either verified or explicitly labelled as a recommendation to test on the day.

### 10.1 The demo bunker — freeze prod at 15:00, keep building on dev

Convex has separate dev and prod deployments (`npx convex deploy` pushes to prod; BNA UI deployment page, accessed 2026-11-13). At 15:00: deploy to prod, point the demo phone at prod, export a backup (§7) — then **stop pushing to prod**. Development continues on dev deployments. Any fix after 15:00 goes dev → verify on a second phone → one deliberate prod deploy, never a casual one. The bunker converts "someone pushed a bad migration at 15:40" from a demo-killer into a non-event. (Recommendation; the mechanism is verified, the discipline is the team's.)

### 10.2 The bundled fallback — the demo works with zero network

Ship the seed JSON as a static asset in the app bundle (`assets/demo-fallback.json`), containing the three finished AI results. Rendering order: live query → AsyncStorage last-result cache → bundled JSON. If the café Wi-Fi dies mid-pitch, the judges still see a finished, believable product — and the presenter says plainly "the network just dropped; this is the last result, cached on the phone". Honesty beats a spinner. **Label it clearly in the UI** ("cached result") so nobody mistakes it for a live call. (Recommendation; the AsyncStorage-cache pattern is the mobile report's own, 12/11.)

### 10.3 Share links as the market-expansion story

One `httpAction` GET route (`convex/http.ts`, `httpRouter` + `httpAction`) serves `https://<deployment>.convex.site/share/<code>` — a plain HTML page rendering the AI result, no app install, no account. Verified mechanics: HTTP actions are defined in `convex/http.ts`, served on the `.convex.site` domain — **not** `.convex.cloud`, the single most common misconfiguration — publicly reachable with no built-in auth, so the handler must validate the share code itself; **response size is limited to 100 MiB** per the official HTTP-actions page, and the request has no general limit except `multipart/form-data` bodies at 20 MiB — note the official limits table still says 20 MiB for responses, so treat 20 MiB as the safe design ceiling, not the documented limit; not retried by Convex (official docs https://docs.convex.dev/functions/http-actions, read by the red team 2026-11-13, via the Waymark summary https://mcp.waymark.network/r/26d03460-e3ce-4f61-9f8b-e480a6c69745). The share link is the cheapest possible answer to criterion 3 (25 points: first users + global path) — a judge can forward it to anyone in the room, and it works.

### 10.4 Idempotency keys — the double-tap insurance

Client generates a UUID per AI run, sends it as `idempotencyKey`, server dedups on the indexed lookup inside the mutation transaction (§2.1) — scoped by `(userId, idempotencyKey)`, with an ownership check before returning a saved result. This kills three birds: double-tap duplicates (T6), kill-and-reopen re-submission (the client re-sends the same key on relaunch and gets the existing run back), and retry-after-timeout duplicates. On Supabase the same key is a `UNIQUE (user_id, idempotency_key)` constraint (§2.2). (Pattern verified — TanStack Convex collection docs + Zernio SPEC, §2.1.)

### 10.5 Anonymous auth + persisted session — no login screen, ever

§1 + §3. The phone signs in anonymously once at 11:00; the session persists all day (T9). No login screen is built, no time is spent on it, and the first 30 seconds of the demo are the AI feature. If the idea ever needs real accounts, the anonymous identity converts to a real one with the same user id and no migration (official Convex Auth docs: anonymous users can convert to normal users; Supabase: upgrade via `updateUser` — both red-team verified 2026-11-13; see also the Recurzn session notes, third-party, https://github.com/rishi-ventrapragada/Recurzn-Website/blob/HEAD/docs/sessions/SESSION_3.md).

### 10.6 The 2-minute rebuild — one command, total reset

`npx convex run seed:reset` (internal mutation: delete `isDemo` rows + reseed the 13 rows) or `supabase db reset` (migrations + seed.sql). Any agent, at any hour, can rebuild the demo data in under 2 minutes. Rehearse it once at 13:00 so that at 15:30, when something is wrong, the rebuild is muscle memory, not a debugging session. (Recommendation; both commands are verified in §4.2.)

---

## §11. Decision table — Convex vs Supabase data layer, for the day

| Dimension | Convex (primary) | Supabase (fallback) | Verdict for 14/11 |
|---|---|---|---|
| Schema definition | TypeScript `defineSchema` + `v` validators, in the same repo as the app | SQL migrations in `supabase/migrations/` | Convex — one language, one repo, validators catch typos at write time |
| Auth model | `ctx.auth.getUserIdentity()` inside each function; `internal*` not public; no RLS equivalent — forgetting a check fails OPEN | RLS: deny-all by default; policies per operation; `service_role` bypasses | Supabase fails safer; Convex is faster to write. Mitigate Convex with the `// public:` grep (§3.1) |
| Anonymous / no-sign-up-wall | `@convex-dev/auth` anonymous sign-in | `signInAnonymously()` — but anonymous = `authenticated` role (T2); 30/hour/IP cap (T9) | Tie, with different traps. Either way: sign in once, persist the session |
| Offline on the phone | In-memory last-known state only; offline mutations may reject (contested — see §5.1/T6); resubscribe automatic | No client cache; queries fail offline; realtime missed events not replayed, must refetch | Convex — the warm-app case works; Supabase needs the AsyncStorage bridge |
| Kill-and-reopen | Resubscribe → last `done` run re-renders in 1–3 s | Refetch on foreground → same, if the refetch is wired | Tie, if the refetch is wired; Convex needs less code |
| Idempotency | Index-lookup inside the mutation transaction (serializable) | `UNIQUE (user_id, idempotency_key)` — the DB enforces it | Supabase — the DB does it for you; Convex needs the pattern written by hand |
| Share links | `httpAction` on `.convex.site` — one file, no server | Edge Function or `SECURITY DEFINER` function + public URL | Convex — fewer moving parts |
| Seed loading | `convex import` (JSONL/CSV) or in-code mutation | `seed.sql`, auto-applied on `db reset` | Tie |
| Migrations mid-build | Widen → backfill → narrow; push validates ALL docs, fails if any fail; no rollback | Additive SQL migrations; `db push` migrations-only; dashboard edits are unversioned | Tie — both punish carelessness equally |
| Backup before submission | `npx convex export` → `snapshot_{ts}.zip`, manual backups kept 7 days | `supabase db dump`; no auto-backup on Free; Pro $25/mo = 7 days daily | Convex — export is one command and verified |
| Per-agent isolation | One dev deployment per agent, scoped deploy keys | Free plan: 2 projects only — local `supabase start` per agent, or namespaced rows | Convex — isolation is a first-class feature, not a workaround |
| Realtime | Built-in subscriptions; resync automatic | WebSocket; 200 conn Free / 500 Pro; missed events not replayed | Convex |
| Cost for the day | Free tier 1M calls — unreachable in 5 hours | Free tier — 2 projects, pauses after 1 week inactivity | Tie — both free for the day |
| **Switching cost at 11:00** | — | Schema shapes map 1:1 (§2.2); rewrite functions, not the model | If Convex is unreachable at 11:00, switch — the schema survives |

**Bottom line:** Convex wins on 6 of 14 rows, Supabase on 2 (fail-safe auth, DB-enforced idempotency), 5 ties, 1 conditional (switching cost). The pick stands. The fallback is real because the schema is portable.

---

## §12. Hour-by-hour data-layer runbook for tomorrow

| Time | Owner | Data-layer job | Done when |
|---|---|---|---|
| 10:00–11:00 | Integrator (Muse) | Backend exists BEFORE 11:00 (backend report lever). Create Convex project, deploy schema v1 + seed, verify the three finished results load on the real phone. If Convex unreachable → Supabase fallback, same schema | Three seeded results visible on the phone |
| 11:00–11:30 | Backend agent | Anonymous sign-in wired; `requireUser` helper + `// public:` grep in CI; first AI endpoint live (action → aiRuns row) | One real AI run, stored as a row, renders on the phone |
| 11:30–13:00 | All | Feature building; schema changes additive-optional only; each agent on their own dev deployment / local Supabase | No agent has touched another's rows (check `agent` column) |
| 11:30–13:00 | Backend agent | Share-link httpAction (§10.3) built alongside features — the 15:45 test depends on it | `GET /share/<code>` returns a run from the prod deployment |
| 13:00 | Integrator | Rehearse the 2-minute rebuild (§10.6) on the real phone | Rebuild completes < 2 min, three results back |
| 13:00–14:00 | Frontend agent | Bundled fallback asset (§10.2) built — the 14:00 seed test's airplane-mode step depends on it | `assets/demo-fallback.json` renders the three results with no network |
| 14:00 | Integrator | **Schema freeze.** Seed test (§4.3): fresh install → three results in 3 s → kill → reopen → same screen → airplane mode → same screen (bundled fallback) | All five steps pass |
| 14:45 | Backend agent | Warm-up ping: one real AI run from the real phone against prod, timed | Duration recorded; if >15 s, demo script opens with a seeded result |
| 15:00 | Integrator | **Demo bunker (§10.1):** final deploy to prod, `npx convex export`, phone pointed at prod, no more prod pushes | Backup zip exists; phone shows prod data |
| 15:00–15:30 | All | Humans verify on the real phone + rehearse the pitch. Data is frozen. Any fix goes dev → verify → one deliberate prod deploy | Humans confirm the kill-and-reopen flow live |
| 15:45 | Integrator | Second export. Seed the share link (§10.3) and test it from a second phone with no app install | Share link renders the result in a browser |
| 16:00 | — | Tools down. Submission. The database is now read-only in practice | — |

---

## §13. Sources, verification status, and what is NOT verified

**Access date for all web sources below: 2026-11-13** (unless a source itself is dated in the text). Prior reports relied on: `~/workspace/research_notes/backend-agent-toolkit-20261112/report.md`, `~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md`, `~/workspace/goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md`, `~/frontend-agent-kit/repo/FLEET-MODE.md` (all read 2026-11-13).

**Red-team history:** an independent red team re-verified every load-bearing claim 2026-11-13. First-draft verdict: **FAIL (3 SEVERE / 10 MAJOR / 12 MINOR)** — the Supabase RLS section could not work as written (missing GRANTs, broken identity model), the Convex import path was wrong, and several numbers and failure-mode statements were wrong. **All 25 findings are fixed in this revision** (§3.2 rewritten: grants + identity model + share function; §3.1 import + Owlat rule corrected; idempotency owner-scoped; HTTP limit corrected; seed count corrected; offline-mutation and failed-push statements corrected). Two red-team findings were independently re-confirmed by the author before applying (the grants change against the official changelog; the cross-org project limit against 7 consistent sources).

### Verified — official docs
- Convex schema (defineSchema/defineTable, `v` validators, `_id` + `_creationTime` auto-added, first-push validation of ALL documents, staged validators, `schemaValidation: false`): https://docs.convex.dev/database/schemas
- Convex `useQuery` returns `undefined` while loading; `undefined` is not a valid return type: https://docs.convex.dev/understanding/best-practices/other-recommendations and https://docs.convex.dev/api/modules/react
- Convex backup/restore (`npx convex export` → `snapshot_{ts}.zip` with `<table>/documents.jsonl`; `npx convex import --table`; manual backups 7 days): https://docs.convex.dev/database/backup-restore
- Convex HTTP actions (`.convex.site` domain, not `.convex.cloud`; publicly reachable, no built-in auth; not retried; response limit 100 MiB, multipart/form-data request limit 20 MiB): https://docs.convex.dev/functions/http-actions — official page read by the red team 2026-11-13 (the first draft cited it via Waymark only). Note: the official limits table still says 20 MiB for responses — see §10.3.
- Convex index limits (32/table, 16 fields/index): official limits page, read by the red team 2026-11-13 (the first draft cited it via Waymark only).
- Supabase grants change (new `public` tables get no automatic Data API grants; announced Apr 2026, default for new projects 30 May 2026, all projects 30 Oct 2026; missing grant = 42501; grants checked before RLS): https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically — official changelog, independently confirmed by the author 2026-11-13.
- Supabase seed (`supabase/seed.sql` auto-applied on `supabase db reset` / `supabase start`; `db reset --remote` destructive; `db push` migrations-only): official Supabase CLI reference + local-development guide

### Verified — third-party, consistent across ≥2 sources or tested live
- Convex functions public by default; auth via `ctx.auth.getUserIdentity()`; `internal*` not callable; no RLS equivalent: BNA UI deployment page + https://valentynkorzun.dev (consistent)
- Convex migration pattern (widen → backfill → narrow; deploy doesn't roll back; backend before app): https://stack.convex.dev ("The secret to migrations") + BNA UI deployment page
- Convex seeding (dashboard / CLI import CSV-JSON-JSONL-zip / in-code mutation): https://stack.convex.dev
- Convex offline (conflicting sources — design uses only the intersection): Queuert PITFALLS.md (researched 2026-01-23); BNA UI realtime page; https://tanstack.com/db/latest/docs/collections/convex-collection
- Convex idempotency (index lookup in-transaction; atomic writes; SDK dedup insufficient; serializable mutations): https://tanstack.com/db/latest/docs/collections/convex-collection and the Zernio Convex SPEC https://github.com/zernio-dev/convex-zernio/blob/HEAD/SPEC.md — plus the owner-scoping caveat from the same TanStack section; serializable isolation corroborated by independent OCC teardowns (loams.dev, devtoolsacademy — red-team verified 2026-11-13)
- Convex httpAction mechanics (`.convex.site` not `.convex.cloud`; public, no built-in auth; response limit 100 MiB, multipart/form-data request limit 20 MiB; not retried): official docs https://docs.convex.dev/functions/http-actions, read by the red team 2026-11-13 (first draft cited the Waymark summary only and the wrong limit)
- Convex `// public: <reason>` convention: https://docs.owlat.app/developer/convex/ — Owlat bans bare `query(`/`mutation(`/`action(` builders outright except in one allowlisted file, and puts `// public:` on its wrapper builders; the grep rule in §3.1 is the team's own invention inspired by Owlat, not Owlat's rule (first draft mislabelled it)
- Convex index limits (32/table, 16 fields/index): official limits page, read by the red team 2026-11-13 (first draft cited via Waymark only)
- Convex file storage (`ctx.storage.store`, `generateUploadUrl`, `getUrl`): Convex changelog 1.48, https://www.convex.dev/changelog — OFFICIAL changelog (first draft mislabelled it third-party); the official storage docs page is **CHƯA ĐỌC**
- Supabase RLS mechanics (enable RLS, deny-all default, policy syntax, `(select auth.uid())` form, `service_role` bypass): via https://github.com/rishi-ventrapragada/Recurzn-Website/blob/HEAD/docs/sessions/SESSION_3.md (which quotes the official docs) and the agilesoftlabs RLS guide — THIRD-PARTY provenance; the facts check out, the first draft's "official docs" label was wrong
- Supabase free-project limit follows the user across orgs (2 active projects counted across every organisation where you are Owner or Administrator; creating another organisation does not help; paused projects don't count): https://neon.com/guides/neon-vs-supabase-free-plan — consistent with Supabase's billing docs and six other Nov-2026 sources; red-team verified, author independently confirmed 2026-11-13. Separate orgs is a dead end, not an open question.
- Supabase anonymous auth (anonymous = `authenticated` role; `is_anonymous` restrictive-only; `is false` fails closed; 30/hour/IP cap; storage.objects per-mode policies; bucket_id-only overwrite hole): https://buttondown.com/vibelocked/archive/vibelocked-edition-5-anonymous-supabase-users/ (tested 2026-10-28 on the open-source Auth server) and https://devpost.com/software/livedrop-ixurj1
- Supabase offline/realtime (no client DB; missed events not replayed; 200/500/10,000 connections; 100 channels/connection): RxDB docs + tomodahinata guide + iloveblogs
- Supabase branching/pricing (Pro+ only, $0.01344/branch-hour; Free: no branching, 2 projects, pause after 1 week, no auto-backup; Pro $25/mo, 7 days daily): https://supaclone.io + Medium comparison
- TanStack Query offline (memory-only cache by default; `persistQueryClient` + AsyncStorage/MMKV; `onlineManager`/NetInfo; `networkMode`): https://jared.lynskey.co.nz + https://reactnative.codeguides.io + sheets-and-giggles local-state.md
- Anonymous identity converts to a real account with the same user id: https://github.com/rishi-ventrapragada/Recurzn-Website/blob/HEAD/docs/sessions/SESSION_3.md

### CHƯA ĐỌC (not read — never presented as read)
- Convex official file-storage docs page (changelog cited instead)
- Supabase `db dump` CLI reference details (URL verified to exist; options/flags not read in full)

### UNVERIFIED / open
- Convex MCP availability (conflicted across sources in the backend report — not load-bearing for this brief)
- First-AI-call latency on the team's own endpoint (can only be measured on the day — T10)
- The exact demo phone's behaviour on the café Wi-Fi (test at 14:00, §4.3)

### Settled by the red team (were open in the first draft, now closed)
- Separate Supabase orgs for extra free projects: **verified NOT permitted** — the 2-project limit follows the user across orgs (§8.2).
- Convex official limits page and HTTP-actions page: **read by the red team 2026-11-13** — index caps 32/16 confirmed; HTTP response limit 100 MiB (limits table still says 20 MiB — see §10.3).

---

## Bài học

- Dữ liệu demo phải sống trong database dưới dạng hàng có thể đọc lại, không phải pixels trên màn hình — kill app rồi mở lại vẫn thấy kết quả cũ thì mới lấy được 40 điểm.
- Lỗi nguy hiểm nhất không phải lỗi hiện ra, mà lỗi im lặng: RLS chặn thì trả về rỗng chứ không báo lỗi (chỉ khi đã có GRANT — thiếu GRANT thì lỗi 42501 ầm ĩ), `useQuery` đang load lần đầu thì trả `undefined` chứ không báo lỗi (không phải lúc reconnect) — cả hai đều trông y hệt "chưa có dữ liệu".
- Anonymous auth là cách duy nhất vừa "không có màn hình đăng nhập" vừa "mỗi người chỉ thấy dữ liệu của mình" — nhưng trên Supabase, anonymous lại mang role `authenticated`, nên policy viết theo role là cửa mở toang.
