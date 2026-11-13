# Backend — deep implementation brief (muse-fleet hackathon build)

**Date:** 2026-11-13 · **Event:** Codex Community Hackathon Hanoi, Sat 14/11/2026, build 11:00–16:00 (5h) · **Stack (fixed 12/11):** Expo + React Native + TypeScript SDK 57, Convex primary / Supabase fallback · **Access date for every URL below:** 2026-11-13 unless noted.
**Builds on:** `research_notes/backend-agent-toolkit-20261112/report.md`, `research_notes/mobile-agent-toolkit-20261112/report.md`, `goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md`, `FLEET-MODE.md`. Does not re-pick the stack.
**Idea status:** not yet final (humans settle it 12/11 evening; outcome not reported to Muse as of 09:12 13/11). The endpoint spec below is written generically — input = user content, output = structured JSON — with a clearly marked placeholder for the idea-specific shape. Do not invent the idea.

---

## §0 — The answer first (60 seconds)

1. **Persisted-AI-first.** Every AI result is a document in Convex. The phone *subscribes* to it with `useQuery`; it never holds the result only in memory. When the judges kill the app and reopen it (the 40-point test), the last AI result is already on screen with **zero** new AI calls. This is the single highest-value backend decision in the whole build.
2. **Slice 1 (hour 1): non-streaming JSON action.** One Node-runtime Convex action, OpenAI SDK direct, `maxRetries: 0`, key in a Convex env var, client via `useAction`, 30 s timeout, retry once on network error only. It works before lunch.
3. **Slice 2 (hour 3): delta streaming as the primary stream, not raw SSE.** `@convex-dev/agent` `saveStreamDeltas: true` — chunks land in the DB as deltas, clients subscribe via normal queries, the stream **survives a dropped network** and is already persisted when it finishes. Raw `httpAction` SSE is the secondary path, not the primary.
4. **Four agents, four cloud dev deployments, one prod.** Scoped deploy keys per agent; only the Integrator (Muse) touches prod. Never build the demo binary against a dev URL.
5. **Demo insurance is a backend feature, not a hope:** a pre-seeded demo session, a server-side usage counter + circuit breaker, and a 2-minute heartbeat cron during the pitch window. If the AI path dies at 15:47, the pitch still works.

---

## §1 — Three bold recommendations (evidenced, not vibes)

### 1.1 The result is a document, the phone is a subscriber

Convex's own streaming doc states the trade-off explicitly: "`useChat` holds the conversation in the browser tab that made the request… On reload, seed its `messages` from a query over the thread. `useUIMessages` reads the same persisted messages and deltas reactively from the database, so every subscriber sees the stream. Use `useChat` when you need its ecosystem, and `useUIMessages` when you need the conversation to be shared." (https://docs.convex.dev/agents/streaming, accessed 2026-11-13)

For this hackathon the app is killed and reopened. A `useChat`-style in-memory stream is gone on kill; a persisted document is not. So:

- Schema: one `runs` table (see §4). Every AI call writes a run document **before** returning: `{ shareId, status: "pending" | "done" | "error", input, output, createdAt }`.
- The action writes `status: "pending"` first, calls the model, then patches the document with the result. The client fires the action **and** subscribes to the run document. Whichever finishes first, the UI shows it.
- On reopen, `useQuery(api.runs.getByShareId, { shareId })` returns the finished result from the DB. No AI call, no loading spinner, no empty screen. The judge sees the outcome in under a second.
- Bonus: the share link IS the run's `shareId`. No auth, no accounts — the link opens the result. This is the persistence model the 12/11 backend report recommended; this brief makes it the architecture, not an option.

### 1.2 Delta streaming is the primary stream (SSE is the backup)

Two streaming paths exist on Convex (https://docs.convex.dev/agents/streaming, accessed 2026-11-13):

| | Delta streaming (`saveStreamDeltas: true`) | HTTP streaming (`httpAction` + `toUIMessageStreamResponse()`) |
|---|---|---|
| Transport | Normal Convex queries (WebSocket subscription) | Raw HTTP SSE from `https://<deployment>.convex.site/...` |
| Network drop mid-stream | **Survives** — deltas are in the DB, client resubscribes and continues | Stream dies; client must restart the whole generation |
| Result after finish | Already persisted — reopen shows it | Gone unless you save it yourself |
| Multi-client | Every subscriber sees the same stream | Only the one HTTP client |
| Cost on Convex | Each delta batch re-runs subscriber queries, and subscription updates count as function calls (limits page) — the 1:1 batch→call mapping is inference, not stated on the page | One HTTP action call |
| Setup cost | Needs `@convex-dev/agent` component + a deltas query | Needs `convex/http.ts` + CORS router |

**Recommendation: delta streaming first.** It is the only path that is simultaneously live, resumable, and persisted — which is exactly the demo's failure surface (flaky venue Wi-Fi, kill-and-reopen). Raw SSE via `httpAction` is kept as the fallback if the Agent component fights back (see the honest risk in §1.4).

The minimal delta-streaming shape (from the official doc, adapted — no auth in the demo):

```ts
// convex/ai.ts — action (Node runtime, see §3)
await agent.streamText(ctx, { threadId }, { prompt }, { saveStreamDeltas: true });
```

```ts
// convex/ai.ts — query the client subscribes to
export const listRunMessages = query({
  args: { threadId: v.string(), paginationOpts: paginationOptsValidator, streamArgs: vStreamArgs },
  handler: async (ctx, args) => {
    const paginated = await listUIMessages(ctx, components.agent, args);
    const streams = await syncStreams(ctx, components.agent, args);
    return { ...paginated, streams };
  },
});
```

```tsx
// client — stream: true is what turns the subscription into a live stream
const { results, status } = useUIMessages(api.ai.listRunMessages, { threadId }, { initialNumItems: 10, stream: true });
```

Deltas are chunked and debounced under the hood ("chunk up the response and debounce saving the deltas to prevent excessive bandwidth usage"); configure `{ saveStreamDeltas: { chunking: "line", throttleMs: 1000 } }` for the demo — one DB write per second, not per token (https://docs.convex.dev/agents/streaming, accessed 2026-11-13).

### 1.3 Demo insurance, built into the backend (not the pitch script)

Three cheap mechanisms, all built from verified Convex primitives:

- **Pre-seeded demo session.** Before 16:00 the Integrator runs one real AI call against prod and leaves its run document in the DB. The pitch opens on that `shareId`. If the live call fails in front of the judges, the seeded result is already on screen and the pitch continues. Cost: one AI call. (Primitive: ordinary mutation + query.)
- **Server-side usage counter + circuit breaker.** A `usage` table with one document `{ date, aiCalls, blocked }`. The AI action increments it first and throws `ConvexError("USAGE_CAP")` when `aiCalls` exceeds a hard cap (e.g. 200 calls for the day — ~$0.10 of `gpt-4o-mini`, see §8). No HTTP status exists on the `useAction` path, so the refusal is an error code, not a 429 (429 applies only to the `httpAction` path). Why server-side: a retry loop bug on the phone can fire hundreds of calls in a minute, and nothing on the client stops it. The breaker protects the OpenAI budget *and* the 1M Convex function-call cap. (Primitives: mutation + action, §2.)
- **Heartbeat cron during the pitch window.** A cron in `convex/crons.ts` — `crons.cron("heartbeat", "*/2 8 * * *", internal.health.check, {})` — every 2 minutes during 08:00–09:00 UTC (15:00–16:00 ICT), invoking a mutation that runs a trivial liveness read against prod and writes the result to a `health` table. Crons can only invoke a mutation or an action, never a query, and cron times are UTC. The Integrator watches the Convex dashboard; a red heartbeat at 15:30 means fix it before 16:15, not during the pitch. (https://docs.convex.dev/scheduling/cron-jobs, accessed 2026-11-13)

### 1.4 The honest risk on the bold pick

The Agent component's own README is upfront that it is "in early development and not ready for production, and that the API will probably change" (reported in a 2026-11-03 survey quoting the README; the README itself was not re-opened 2026-11-13 — second-hand, treat as a caution, not a verdict; see §9). That is why the build order is **slice 1 non-streaming first, delta streaming second**: if `@convex-dev/agent` costs more than 45 minutes at any point, abandon it and ship slice 2 as hand-rolled SSE through `httpAction` **plus** a mutation that persists the finished result (the persisted-result rule from §1.1 is non-negotiable either way). The component is a convenience, not a dependency. The `DeltaStreamer` class from the same package also lets you save deltas yourself with plain AI SDK `streamText` if the Agent wrapper misbehaves (https://docs.convex.dev/agents/streaming, accessed 2026-11-13).

---

## §2 — Convex deep dive (only what the build touches)

### 2.1 Functions: three types, one rule

| | Query | Mutation | Action |
|---|---|---|---|
| Reads DB | yes | yes | no (`ctx.runQuery` / `ctx.runMutation` instead) |
| Writes DB | no | yes, transactional | via `ctx.runMutation` |
| Cached / realtime | yes | — | no |
| Calls external APIs | no | no | yes (OpenAI, etc.) |
| Auto-retried on failure | — | — | **no — the caller handles errors** |

Source: https://docs.convex.dev/functions (accessed 2026-11-13). The rule that follows: **all AI calls live in actions; all persistence lives in mutations; the client never calls the provider directly.** An action that fails mid-way leaves no partial state unless you wrote it — which is why §3 writes the `pending` run document in a mutation *before* the model call.

### 2.2 Runtimes: Node for AI, always

- Default Convex runtime: faster, no cold start — but **no `setTimeout`** (the runtimes page's supported-timing-API list omits it). The AI SDK's retry backoff uses `setTimeout`, so a default-runtime action with default retries is *expected* to break — this interaction was not independently reproduced (see §9); mitigated either way by `"use node"` + `maxRetries: 0`.
- **A file with the `"use node"` directive may contain actions ONLY.** Queries and mutations cannot live in the same file ("Files with the `"use node"` directive should not contain any Convex queries or mutations since they cannot be run in the Node.js runtime"). So the AI action lives in `convex/ai.ts` (Node) and every run-document read/write lives in `convex/runs.ts` (no directive). Sources: https://docs.convex.dev/functions/runtimes, https://docs.convex.dev/functions/actions (accessed 2026-11-13).
- Node runtime: 512 MiB RAM (vs 64 MiB default), needed for Node-only packages. The OpenAI SDK is run under Node here because its retry/timeout behaviour assumes a Node-like environment; the `"use node"` choice is safe regardless of which exact APIs the SDK touches.
- Action timeout: **10 min for Node actions, 30 min for Convex-runtime actions** (official limits page, resolved by runtime — https://docs.convex.dev/production/state/limits, accessed 2026-11-13). The actions page's flat "10 minutes" is the loose statement. AI actions are Node, so the applicable limit is unambiguously 10 min — a demo call takes seconds.
- Nested same-runtime action calls are discouraged — pull shared logic into a plain TS helper and call it directly; `ctx.runAction` exists only to cross runtimes.

### 2.3 HTTP actions (the SSE fallback path)

Exposed at `https://<deployment>.convex.site` — a public HTTPS URL, reachable from the phone on any network, no tunnel needed. `httpAction` takes a `Request` and returns a `Response` (Fetch API). **No argument validation** — validate with zod yourself or a malformed body is a 500. Response size limit 100 MiB; 64 MiB memory in the Convex runtime — stream large bodies with a `ReadableStream`. Source: https://docs.convex.dev/functions/http-actions (accessed 2026-11-13).

The official CORS pattern (from the streaming doc):

```ts
// convex/http.ts
import { httpRouter } from "convex/server";
import { corsRouter } from "convex-helpers/server/cors";
import { chat } from "./chat";
const http = httpRouter();
const cors = corsRouter(http, { allowedHeaders: ["Authorization", "Content-Type"] });
cors.route({ path: "/chat", method: "POST", handler: chat });
export default http;
```

Trap inside the trap: return 401/403 **from inside the handler** so the client sees a status, not an opaque CORS failure. Preflight must succeed before auth is checked.

### 2.4 Env vars: per deployment, verified, never in the bundle

- `npx convex env set NAME 'value'` (dashboard or CLI); `--prod` / `--deployment <ref>` to target; `env list/get/remove` to verify.
- **Defaults apply when a deployment is created; existing deployments keep their current values unless you explicitly apply the change** (Project Settings → Review changes → Save and apply — updates every existing cloud deployment of the affected types, including overwriting values). So the safe rule stands regardless: set the key explicitly on **every** deployment (each dev deployment + prod) and verify with `env list`. Never assume a default reached prod.
- Declare vars in `convex/convex.config.ts` for type-safe access via the generated `env` object; `process.env` also works. Max 512 vars, 512 KiB total, 8 KiB per value.
- Source: https://docs.convex.dev/production/environment-variables, https://docs.convex.dev/cli/reference/env (accessed 2026-11-13).

### 2.5 Auth: skipped, deliberately

Convex Auth (`@convex-dev/auth`, `authTables` in schema, `ConvexAuthProvider` replacing `ConvexProvider`) exists and is documented (https://labs.convex.dev/auth/setup, accessed 2026-11-13), but the demo has no accounts. **No sign-up wall** (12/11 decision, kept): persistence is by share link only — one random `shareId` per run, and whoever holds the link sees that run. The trade-off is explicit: anyone with the link can read that run, and that is acceptable for a 5-hour demo with no personal data. If the idea ever needs per-user data, auth is a post-hackathon job, not a demo-day job.

### 2.6 Free-tier limits that can kill the demo (official limits page)

Source: https://docs.convex.dev/production/state/limits (accessed 2026-11-13). Free and Starter share the S16 tier.

| Limit | Value | Why it matters tomorrow |
|---|---|---|
| Function calls / month | **1,000,000** — explicit client calls, scheduled executions, **subscription updates**, and file accesses all count | A streaming delta subscription re-runs on every delta batch; throttle deltas (§1.2) and keep one subscription per screen |
| Storage | 0.5 GB | Irrelevant for a day of JSON runs |
| DB I/O / file storage / egress | 1 GB each / month | Irrelevant for the demo |
| Action compute | 20 GB-hours / month | Irrelevant |
| Query / mutation execution | **1 second** (user code only, not DB ops) | No heavy compute or big JSON parsing inside a query/mutation — actions only |
| Concurrency (S16) | queries **16**, mutations **16**, Convex-runtime actions + HTTP actions **64**, Node actions **64**, scheduled jobs **8** | One `useQuery` per list item starves the app; one paginated query per screen |
| Function arg / return | 16 MiB (Node actions 5 MiB arg) / 16 MiB | Keep AI inputs small; images go to file storage, not args |
| Doc max / data read per query | 1 MiB / 16 MiB | Don't return whole histories; paginate |
| Docs scanned / written | 32,000 / 16,000 per query/mutation | Index the `shareId` lookup; never full-table scan |
| Env vars | 512 vars, 512 KiB total, 8 KiB per value | Fine |
| Deployments per team | **40** | 4 agents + prod + a spare is nowhere near the cap |
| HTTP response | 100 MiB | Fine |
| Code size | 230 MB | Fine |

**What happens when Free limits are hit:** "After Free plan limits are hit, new mutations that are inserting or updating may fail" (official limits page) and the pricing FAQ says sustained exceedance means "the deployment may return HTTP errors on function calls" (https://www.convex.dev/pricing/faq, accessed 2026-11-13). In demo terms: the app looks dead with no clear error. Mitigation is the circuit breaker (§1.3) and the pre-seeded session — the pitch never depends on a write succeeding at 16:15.

### 2.7 File storage (only if the idea needs uploads)

Two-step upload: mutation `ctx.storage.generateUploadUrl()` (URL expires in 1 hour) → client POSTs bytes (2-minute timeout) → second mutation stores the storage ID. Single-request upload inside an HTTP action via `ctx.storage.store(blob)` — no specific size limit for a raw-binary body (stream it); only `multipart/form-data` bodies are capped at 20 MiB. Download: `ctx.storage.getUrl(storageId)` returns a URL good for the file's lifetime — **access is enforced at generation time**, so a generated URL is not an auth mechanism; don't treat it as one. Source: https://docs.convex.dev/file-storage/upload-files (accessed 2026-11-13, via the doc's upload/serve pages). **Default for tomorrow: no uploads in slice 1.** Text in, JSON out. Add file storage only if the settled idea demands an image, and only after slice 1 is live.

### 2.8 Scheduling

`ctx.scheduler.runAfter(delayMs, fnRef, args)`, `runAt(timestamp, …)`, `cancel(id)`. Scheduled mutations execute exactly once; scheduled actions at most once with no retry. Scheduling from a mutation is atomic; from an action it is not. Crons live in `convex/crons.ts` via `cronJobs()` — `crons.interval()` for every-N-minutes, `crons.cron()` for a cron expression (times in UTC; there is no 1-minute minimum — seconds-level granularity is supported). A cron can invoke only a mutation or an action, never a query. Scheduled-function results are retained 7 days. Sources: https://docs.convex.dev/scheduling/scheduled-functions, https://docs.convex.dev/scheduling/cron-jobs (accessed 2026-11-13). Uses tomorrow: the heartbeat cron (§1.3) and nothing else — do not build reminder/notification features on day one.

### 2.9 React Native client wiring

`ConvexProvider` + `ConvexReactClient` from `"convex/react"`; `EXPO_PUBLIC_CONVEX_URL` holds the deployment URL; the official quickstart example constructs the client as `new ConvexReactClient(url, { unsavedChangesWarning: false })` — use that shape (the docs don't call the flag required, the example is the blessed form). Source: https://docs.convex.dev/quickstart/react-native, https://docs.expo.dev/guides/using-convex/ (accessed 2026-11-13).

Two client semantics that shape the UI (https://docs.convex.dev/client/react/overview, accessed 2026-11-13):

- **`useQuery` returns `undefined` while first loading**, and also when passed `"skip"`. In this app's usage (never skipped), `undefined` means "loading", never "empty". A component that renders `data ?? []` shows a false empty state on reopen (trap #2, §6). Check `=== undefined` and render a skeleton.
- **A subscription starts on mount and cancels on unmount.** Reopening the app resubscribes automatically; an in-flight `useAction` call does **not** resume — design advice (not a doc fact: the docs state only that actions have no auto-retry and the client auto-reconnects the WebSocket), so the client should re-query the run by `shareId` on `AppState` change to active if the action never returned, and never fire a duplicate call blindly.

---

## §3 — FIRST endpoint spec

### 3.1 Contract (idea-agnostic; the idea fills the placeholder)

The endpoint takes **user content** and returns **structured JSON**. The idea-specific fields are marked `/* IDEA: ... */` — the backend agent fills them in the first 20 minutes from `CONTRACT.md` (FLEET-MODE.md), without changing the envelope.

**Transport, slice 1:** Convex action via `useAction`. **Transport, slice 2:** delta streaming (§1.2); the action below stays as the non-streaming path and the fallback.

**Request (action args, validated with `convex/values` + zod at the boundary):**

```ts
{
  shareId: string,          // client-generated, 8 random chars [a-z0-9]; the share link
  input: {
    text: string,           // 1..4000 chars — the user's content
    /* IDEA: add fields here, e.g. imageStorageId, options, locale */
  },
  /* IDEA: add per-idea options, e.g. tone, length */
}
```

**Response (success, 200-equivalent):**

```ts
{
  runId: string,            // Convex document id of the run
  shareId: string,
  status: "done",
  output: {
    /* IDEA: the structured result, e.g.
       title: string,
       items: Array<{ label: string, detail: string, score: number }>,
       summary: string */
    _placeholder: "replace with the idea's JSON shape; keep it flat, no nesting deeper than 2 levels",
  },
  model: string,            // e.g. "gpt-4o-mini" — from env, echoed for the judges' log
  usage: { inputTokens: number, outputTokens: number },
  tookMs: number,
}
```

**Streaming shape (slice 2, delta streaming):** the client subscribes to `listRunMessages` with `stream: true` (§1.2). Deltas arrive as UI-message chunks, throttled to ~1 write/second (`throttleMs: 1000`, `chunking: "line"`). The final document is the same shape as the slice-1 response, written into the run document when the stream completes. If the stream is interrupted, the partial text is already in the DB and the client shows "interrupted — resume" instead of a blank screen.

**Error cases (every one returns a shape the client can render, never a bare 500):**

| Case | Server behaviour | Client behaviour |
|---|---|---|
| Validation fails (empty text, >4000 chars, bad shareId) | Action throws `ConvexError("INVALID_INPUT: ...")`; httpAction returns 400 with `{ error: "INVALID_INPUT", message }` | Show the message inline; do not retry |
| OpenAI key missing / invalid | Action throws `ConvexError("AI_UNAVAILABLE")`; run document patched to `status: "error"`, `error: "AI_UNAVAILABLE"` | Show "AI is unavailable — showing the last saved result" + the seeded demo run |
| OpenAI rate limit / 5xx | Same as above, `error: "AI_RATE_LIMITED"` | Retry once after 2 s, then show the seeded result |
| Model timeout (>25 s) | Action aborts; run patched to `status: "error"`, `error: "AI_TIMEOUT"` | Retry once; then seeded result |
| Usage cap hit (circuit breaker, §1.3) | Action refuses immediately, `error: "USAGE_CAP"` | Show the seeded result; do not retry |
| Network drop mid-stream (delta path) | Nothing — deltas already in DB | Resubscribe on reconnect; stream continues from the last delta |
| Network drop mid-action (slice 1) | Action may still complete server-side | On `AppState` active, re-query the run by `shareId`; if `status: "done"`, show it — never fire a duplicate call blindly |

**Timeouts / retries / caps (hard numbers):**
- Client timeout on the action: **30 s**. Server-side model call timeout: **25 s** (inside the action, so the client never waits longer than the server).
- Retry policy: **once** — on network error, or once after 2 s on `AI_RATE_LIMITED`. Never on a validation error, never on `USAGE_CAP`, never on a 4xx. Exponential backoff is unnecessary at this scale; a fixed 2 s delay is enough.
- Input cap: **4,000 chars** per call (keeps every call ≈1,500 input tokens, see §8).
- Output cap: **`max_tokens: 800`** on the model call — bounds cost and latency; a demo answer longer than 800 tokens is a worse demo.
- Daily cap: **200 AI calls** via the server-side counter (§1.3).

### 3.2 Minimal code sketch (slice 1 — the whole backend in ~60 lines)

```ts
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";
export default defineSchema({
  runs: defineTable({
    shareId: v.string(),
    status: v.union(v.literal("pending"), v.literal("done"), v.literal("error")),
    inputText: v.string(),
    output: v.optional(v.any()),
    error: v.optional(v.string()),
    model: v.optional(v.string()),
    usage: v.optional(v.object({ inputTokens: v.number(), outputTokens: v.number() })),
    createdAt: v.number(),
  }).index("by_shareId", ["shareId"]),
  usage: defineTable({ date: v.string(), aiCalls: v.number(), blocked: v.boolean() })
    .index("by_date", ["date"]),
  health: defineTable({ checkedAt: v.number(), ok: v.boolean(), detail: v.optional(v.string()) }),
});
```

```ts
// convex/runs.ts — NO "use node" directive: queries + mutations live here, never in ai.ts
import { internalMutation, query } from "./_generated/server";
import { v } from "convex/values";

// Public: the phone subscribes to this. Internal mutations: only the action calls
// them (via `internal.runs.*`), so no client can forge a run or mark one done.
export const getRunByShareId = query({
  args: { shareId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db.query("runs").withIndex("by_shareId", (q) => q.eq("shareId", args.shareId)).first();
  },
});

export const createRun = internalMutation({
  args: { shareId: v.string(), inputText: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db.insert("runs", {
      shareId: args.shareId, status: "pending",
      inputText: args.inputText, createdAt: Date.now(),
    });
  },
});

export const finishRun = internalMutation({
  args: {
    runId: v.id("runs"), output: v.any(), model: v.string(),
    usage: v.object({ inputTokens: v.number(), outputTokens: v.number() }),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.runId, { status: "done", output: args.output, model: args.model, usage: args.usage });
  },
});

export const failRun = internalMutation({
  args: { runId: v.id("runs"), error: v.string() },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.runId, { status: "error", error: args.error });
  },
});
```

```ts
// convex/ai.ts — "use node" MUST be the first line. Actions ONLY in this file.
"use node";
import { action } from "./_generated/server";
import { internal } from "./_generated/api";
import { ConvexError, v } from "convex/values";
import OpenAI from "openai";

export const runAi = action({
  args: { shareId: v.string(), inputText: v.string() },
  handler: async (ctx, args) => {
    if (!args.inputText.trim() || args.inputText.length > 4000) {
      throw new ConvexError("INVALID_INPUT: text must be 1..4000 chars");
    }
    // Plain Error would reach the client as a generic failure on prod — only
    // ConvexError carries the code through, so every throw below is ConvexError.
    const runId = await ctx.runMutation(internal.runs.createRun, { shareId: args.shareId, inputText: args.inputText });
    // Circuit breaker: count first, refuse fast (see §1.3; counter mutation omitted for brevity)
    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY, maxRetries: 0 });
    const started = Date.now();
    try {
      const res = await client.chat.completions.create(
        {
          model: process.env.AI_MODEL ?? "gpt-4o-mini",
          messages: [
            { role: "system", content: "/* IDEA: system prompt — return JSON only, flat structure, max 800 tokens */" },
            { role: "user", content: args.inputText },
          ],
          response_format: { type: "json_object" },
          max_tokens: 800,
        },
        // 25 s server-side timeout (§3.1): AbortSignal.timeout aborts the call;
        // the SDK accepts `signal` in request options.
        { signal: AbortSignal.timeout(25000) },
      );
      const output = JSON.parse(res.choices[0].message.content ?? "{}");
      await ctx.runMutation(internal.runs.finishRun, {
        runId, output, model: res.model,
        usage: { inputTokens: res.usage?.prompt_tokens ?? 0, outputTokens: res.usage?.completion_tokens ?? 0 },
      });
      return { runId, shareId: args.shareId, status: "done", output, model: res.model,
        usage: { inputTokens: res.usage?.prompt_tokens ?? 0, outputTokens: res.usage?.completion_tokens ?? 0 },
        tookMs: Date.now() - started };
    } catch (e: any) {
      // Distinct codes per §3.1 — never collapse them into one generic error.
      // Confirm exact SDK error names against the installed SDK version.
      const code =
        e?.status === 429 ? "AI_RATE_LIMITED"
        : /timeout|abort/i.test(e?.name ?? "") ? "AI_TIMEOUT"
        : "AI_UNAVAILABLE";
      await ctx.runMutation(internal.runs.failRun, { runId, error: code });
      throw new ConvexError(code);
    }
  },
});
```

```tsx
// lib/aiClient.ts — THE transport seam (a hook; swap the inside for Supabase, §7).
// The UI never calls useAction directly — it calls useAiClient().run().
import { useAction } from "convex/react";
import { api } from "@/convex/_generated/api";
export function useAiClient() {
  const runAi = useAction(api.ai.runAi);
  return { run: (args: { shareId: string; inputText: string }) => runAi(args) };
}

// app screen
import { useQuery } from "convex/react";
const { run } = useAiClient();
const saved = useQuery(api.runs.getRunByShareId, { shareId }); // undefined = loading, never "empty"
void run({ shareId, inputText }); // fire-and-forget; the subscription shows the result
```

Notes the sketch deliberately encodes: `"use node"` first line of `ai.ts` only (`runs.ts` has no directive); `maxRetries: 0` + `AbortSignal.timeout(25000)`; key from `process.env` (a Convex env var, never in the bundle); `response_format: json_object` so the client never parses free text; `ConvexError` codes so prod returns the code, not a generic failure; internal mutations for action-only writes; the client goes through `useAiClient()` and subscribes — it never awaits the result for rendering.

### 3.3 What NOT to build on day one

- No Convex Auth, no user table, no roles.
- No AI Gateway (paid plan only — §2.4 of the 12/11 report's finding, verified: "available to teams on a paid plan", https://docs.convex.dev/ai-gateway/overview, accessed 2026-11-13). The OpenAI key in a Convex env var is the free-tier path.
- No file uploads in slice 1 (§2.7).
- No scheduled reminders, no notifications, no background jobs except the heartbeat cron.
- No second model, no model fallback chain — one model, one env var (`AI_MODEL`), one-line swap.

---

## §4 — Recommended backend layout (repo folders + file names)

Product lives in its own repo (`muse-fleet` product repo; the kit repo stays the kit — FLEET-MODE.md). Backend files are owned by role C (Backend/AI); `convex/schema.ts`, `convex/http.ts`, `convex/convex.config.ts`, shared types and env are Integrator-owned (role A) per FLEET-MODE.md file ownership — C proposes, A merges.

```
muse-fleet/
├── app/                          # Expo Router screens (role B)
│   ├── _layout.tsx               # ConvexProvider + ConvexReactClient, unsavedChangesWarning: false
│   ├── index.tsx                 # home: input → fire runAi → subscribe to run
│   └── run/[shareId].tsx         # share-link screen: useQuery(getRunByShareId) only
├── components/
│   ├── RunResult.tsx             # renders output JSON; skeleton while useQuery === undefined
│   └── AiStatusBanner.tsx        # shows error/seeded-result state from run.status
├── lib/
│   ├── aiClient.ts               # THE transport seam: runAi(input) → Convex action today,
│   │                             #   Supabase fetch tomorrow if the fallback fires (§7).
│   │                             #   One function, one request/response shape, both transports.
│   ├── share.ts                  # shareId generation (8 random [a-z0-9] chars), link building
│   └── errors.ts                 # error-code → user message map (INVALID_INPUT, AI_UNAVAILABLE, ...)
├── convex/
│   ├── schema.ts                 # runs + usage tables (§3.2); A-owned
│   ├── ai.ts                     # Node-runtime ACTION ONLY ("use node"); runAi
│   ├── runs.ts                   # getRunByShareId query + internal run mutations
│   ├── streaming.ts              # slice 2: listRunMessages (listUIMessages + syncStreams)
│   ├── agents.ts                 # slice 2: Agent definition (storyAgent equivalent)
│   ├── usage.ts                  # incrementUsage, checkCap — the circuit breaker (§1.3)
│   ├── health.ts                 # heartbeat mutation: liveness probe + writes health table
│   ├── crons.ts                  # crons.cron("heartbeat", "*/2 8 * * *", ...) (§1.3)
│   ├── http.ts                   # slice-2 fallback: /chat route + CORS (A-owned)
│   ├── convex.config.ts          # component mounts (@convex-dev/agent); env declarations
│   └── _generated/               # generated by `npx convex dev` — never hand-edited
├── scripts/
│   ├── seed-demo-run.mjs         # Integrator-only: fires one real AI call against prod,
│   │                             #   prints the shareId for the pitch (run before 16:00)
│   └── check-env.mjs             # verifies OPENAI_API_KEY + AI_MODEL exist on a deployment
│                                 #   (npx convex env list --deployment <ref>) — run before every build
├── CONTRACT.md                   # first 20 min (FLEET-MODE.md): endpoint shape, error codes,
│   │                             #   idea-specific JSON fields — A-owned, C fills §3.1 placeholders
├── .env.local                    # NEVER committed: CONVEX_DEPLOYMENT + CONVEX_DEPLOY_KEY (dev only)
├── .env.example                  # committed template: EXPO_PUBLIC_CONVEX_URL, AI_MODEL (no secrets)
└── app.json                      # Expo config; EXPO_PUBLIC_CONVEX_URL must point at PROD for the demo build
```

**Layout decisions worth defending:**
- `lib/aiClient.ts` is the whole fallback strategy in one file (§7): it exports a `useAiClient()` hook returning `{ run }`. The UI never calls `useAction` directly for the AI call; it calls `useAiClient().run()`. Swapping transports is a one-file change (swap the hook's inside to a Supabase fetch), not a UI rewrite.
- The share-link screen (`run/[shareId].tsx`) does **zero** AI calls — it only subscribes. That is the screen the judges land on after reopen; it cannot fail because of the AI path.
- `scripts/check-env.mjs` exists because trap #9 (env defaults don't auto-apply to existing deployments) is silent until demo time. A 30-second script run before the build is the fix.

---

## §5 — Per-agent dev-deployment workflow (4 agents, zero collisions)

Source for every command: https://docs.convex.dev/cli/agent-mode, https://docs.convex.dev/production/multiple-deployments, https://docs.convex.dev/cli/reference/deployment (accessed 2026-11-13).

### 5.1 Setup (Integrator, once, tonight 13/11 — before the build, not during it)

1. Create the Convex project and the **prod** deployment. Set the secrets on prod:
   `npx convex env set OPENAI_API_KEY '<key>' --prod` and `npx convex env set AI_MODEL 'gpt-4o-mini' --prod`.
2. Run one end-to-end canned call against prod from the real Android phone tonight. If it works tonight, the demo-day risk is the venue network, not the backend.
3. Create one cloud dev deployment per agent (dev deployments are per-agent sandboxes; preview deployments are beta and expire after 5 days on Free/Starter — use dev deployments, not previews):
   `npx convex deployment create --type dev --select team:project:dev/<agent> --expiration <date>` — e.g. `dev/muse`, `dev/milo`, `dev/mie`, `dev/migga`.
4. Per agent, create a **scoped deploy key** that can push only to that agent's deployment — never prod, never another agent's:
   `npx convex deployment token create agent-token --save-env` (run in the agent's checkout; the key lands in that checkout's `.env.local`).
5. Set the OpenAI key on **each** dev deployment too (defaults don't auto-apply to existing deployments, §2.4):
   `npx convex env set OPENAI_API_KEY '<key>' --deployment <dev-ref>` × 4.
6. Record the four deployment URLs + prod URL in `CONTRACT.md` (or the fleet board). Nobody guesses a URL.

### 5.2 Daily loop per agent (each agent, own checkout, own deployment)

```
git pull --ff-only origin main            # trunk-based; branches live <60–90 min (FLEET-MODE.md)
npx convex dev --once                     # push functions ONCE, no watch mode in agent shells
# ... edit convex/*.ts ...
npx convex dev --once                     # push again after each coherent change
npx convex env list --deployment <my-dev> # verify the key is present before testing
# test from Expo Go against MY deployment URL only (EXPO_PUBLIC_CONVEX_URL in my .env.local)
```

- **Watch mode (`npx convex dev`) is for humans.** Agents run `dev --once` per push: deterministic, no background watcher to leak across sessions, and the push is a visible step in the log.
- **Never `npx convex deploy` from an agent checkout.** `deploy` targets prod. Only the Integrator runs it, once per merged slice, after the deterministic gate + independent grade (FLEET-MODE.md).
- **Never commit `.env.local`.** It holds `CONVEX_DEPLOY_KEY`. The repo's `.gitignore` must list it; the Integrator checks this before the first merge.

### 5.3 The local-backend trap (read this before 11:00)

When no deployment is configured and no `CONVEX_DEPLOY_KEY` is set, the CLI **defaults to provisioning a local backend automatically** (Agent Mode doc). An agent that runs `npx convex dev` in a fresh checkout without the key is testing against `http://127.0.0.1` — and will report "it works" while the phone can never reach it. **Check before every test:** the URL in `.env.local` must be a `*.convex.cloud` URL. If it is `127.0.0.1`, stop and fix the key — do not test further.

### 5.4 Promotion to prod (Integrator only)

1. Merge the slice to `main` (sequential, Integrator-only merges — FLEET-MODE.md).
2. `npx convex deploy` from the Integrator's checkout (no `--prod` flag exists for `deploy` — it targets the default prod deployment).
3. `npx convex env list --prod` — confirm `OPENAI_API_KEY` + `AI_MODEL` are present.
4. Fire one real call against prod from the demo phone. Green → build the demo binary against the prod URL. Red → fix before building, never after.
5. Rebuild the Expo binary **only** after prod is green (the URL is baked into the bundle — trap #4, §6).

### 5.5 If two agents must touch the same backend file

They don't, on demo day. File ownership (FLEET-MODE.md): `schema.ts`, `http.ts`, `convex.config.ts`, shared types, env — Integrator only. Role C owns `ai.ts`, `runs.ts`, `streaming.ts`, `agents.ts`, `usage.ts`, `health.ts`, `crons.ts`. If C needs a schema change, C proposes it in the slice PR and the Integrator applies it. Schema changes are the #1 merge-conflict source in a 5-hour build; the rule removes the conflict by removing the sharing.

---

## §6 — Top 10 traps (what breaks at demo time + the fix)

| # | Trap | What breaks at demo time | Fix (do it before 11:00 or in slice order) |
|---|---|---|---|
| 1 | **AI result lives only in phone memory** | Judges kill the app, reopen, main screen is empty — the 40-point flow shows nothing | §1.1: every result is a `runs` document; the phone subscribes; reopen restores it with zero new calls |
| 2 | **`useQuery` returns `undefined` while loading** | First paint after reopen renders the "no data" empty state; the judge sees a blank screen for 2–3 s and concludes it is broken | Check `=== undefined` → render a skeleton. Never `data ?? []`. Source: https://docs.convex.dev/client/react/overview |
| 3 | **Subscription updates burn function calls** | Each delta batch re-runs the subscriber query and counts toward the 1M/month cap (the limits page states subscription updates count; the per-batch mapping is inference, not stated on the page); a per-token stream + several subscribers burns calls fast | `throttleMs: 1000`, `chunking: "line"`; one subscription per screen; never one `useQuery` per list item. Source: https://docs.convex.dev/production/state/limits |
| 4 | **`EXPO_PUBLIC_CONVEX_URL` is baked into the bundle at build time** | The demo binary was built against a dev deployment (or localhost) and can never talk to prod; fixing it needs a rebuild through the 90+ min EAS queue | Build the demo binary **only** against the prod URL, and only after prod is green (§5.4). Keep a dev-URL build for testing, clearly labelled, never on the demo phone |
| 5 | **CLI silently provisions a LOCAL backend** | Agent reports "backend works" against `127.0.0.1`; the phone on venue Wi-Fi can never reach it | §5.3: verify `.env.local` holds a `*.convex.cloud` URL before every test |
| 6 | **1-second query/mutation limit + 16-concurrency cap** | A mutation that parses a big payload or a screen with one `useQuery` per list item throws / starves under load | Compute in actions only; one paginated query per screen; index the `shareId` lookup. Source: https://docs.convex.dev/production/state/limits |
| 7 | **Default runtime has no `setTimeout`** | The OpenAI SDK's retry backoff breaks silently inside a default-runtime action | `"use node"` on every AI action file + `maxRetries: 0` (§3.2) |
| 8 | **HTTP actions have no argument validation; CORS fails opaquely** | A malformed body from the phone is a bare 500; a CORS failure looks identical to an auth failure and wastes 30 min of debugging | zod `safeParse` first, return 400; return 401/403 from inside the handler; CORS router in `convex/http.ts` (§2.3) |
| 9 | **Env defaults don't auto-apply to existing deployments** | Prod silently lacks `OPENAI_API_KEY` → every AI call 500s at demo time, with no error until the first tap | Set the key explicitly per deployment (defaults *can* be applied to existing deployments from Project Settings, but explicit set + verify is the safe path); run `scripts/check-env.mjs` before every build (§5.1, §5.4). Source: https://docs.convex.dev/production/environment-variables |
| 10 | **Free-tier cliff is silent** | After limits are hit, "new mutations that are inserting or updating may fail" — the app looks dead mid-pitch with no clear error | Circuit breaker (§1.3) + pre-seeded demo session + heartbeat cron; the pitch never depends on a write succeeding at 16:15. Source: https://docs.convex.dev/production/state/limits, https://www.convex.dev/pricing/faq |

**Honorable mentions (watch, don't fix pre-emptively):** file-storage URLs enforce access at generation time — never use them as auth (§2.7); action timeout is 10 min for Node actions, 30 min for Convex-runtime actions (§2.2); AI Gateway is paid-only, so no keyless path exists on Free (§3.3); a long agent run can hit the 10-minute Node action timeout — the chaining/continuation pattern is described in https://github.com/get-convex/agent/issues/199 (not independently re-opened for this brief); Supabase free projects pause after 1 week of inactivity — irrelevant for a 1-day demo, lethal for a post-event follow-up (§7).

---

## §7 — Supabase fallback: exact trigger + switch-over cost

### 7.1 The trigger (ANY ONE fires the switch — no debate, no vote)

| # | Condition | How it is observed |
|---|---|---|
| T1 | `npx convex deploy` fails **twice in a row before 13:00** with a Convex-side error (not a code error) | Integrator's terminal |
| T2 | The prod deployment returns HTTP 5xx on the health query for **>5 consecutive minutes** during rehearsal | Manual phone + dashboard checks during rehearsal (the heartbeat cron only covers 15:00–16:00 ICT, so it cannot observe rehearsal) |
| T3 | Dashboard shows function-call usage **>80% of the 1M monthly cap** before 15:00 | Convex dashboard |
| T4 | The `.convex.site` URL is unreachable from the demo phone on **venue Wi-Fi AND on 4G** | Phone test, both networks |

**Decision deadline: T+2:00 (13:00), where T = build start 11:00.** After 13:00 the switch costs more than it saves — ride Convex with the canned fallback (§1.3) instead. The Integrator alone calls the switch; role C executes it.

### 7.2 What the fallback is (already designed, not improvised)

- **Edge Function** (Deno, `Deno.serve`): one function, `ai-run`, same request/response JSON envelope as §3.1. Streaming by piping the upstream SSE: `new Response(upstream.body, { headers: { "Content-Type": "text/event-stream" } })`.
- **Client transport:** `lib/aiClient.ts` swaps its implementation from the Convex action to a direct `fetch` against the Edge Function URL. **Direct fetch with `expo/fetch` is the primary client call** — `supabase-js` `invoke()` streaming support is conflicted (the library source returns the raw `Response` for `text/event-stream`, but at least one real codebase comments that `invoke()` doesn't support streams and uses fetch directly — see §9). Direct fetch works regardless of client version. Note the mobile report's Hermes rule: `response.body` is null in Hermes — use `expo/fetch`, never the global `fetch`, for streaming (carried from the 12/11 mobile report; not re-verified in this brief).
- **Persistence:** one Supabase table `runs` with the same columns as §3.2; the client writes the finished result (or the Edge Function writes it via the `service_role` key — server-side only, never in the bundle).
- **RLS:** the table is readable by anon **only for rows matching the shareId the client presents** — a policy like `USING (share_id = current_setting('request.jwt.claims', true)::json->>'share_id')` is wrong for anon; the correct demo-day shape is: anon `SELECT` with a `share_id = <value from the query>` policy is not expressible in pure RLS, so the demo-day fallback uses a **dedicated Edge Function `get-run`** for reads and keeps RLS **deny-by-default** on the table (no `USING (true)`, ever — that was the 12/11 report's #1 RLS trap). Reads go through the function; the table is never directly readable by anon.
- **Realtime:** Supabase Realtime on the `runs` table can replace the Convex subscription for the streaming view — but for a fallback executed at 13:00, **poll the `get-run` function every 2 s** instead. Realtime setup (publication, RLS interplay) is a second failure surface; polling is ugly and works.

### 7.3 Switch-over cost (honest estimate)

| Step | Time |
|---|---|
| Create Supabase project + `runs` table + deny-by-default RLS | 10 min |
| Write + deploy `ai-run` Edge Function (same envelope as §3.1) | 15 min |
| Write `get-run` read function | 5 min |
| Swap `lib/aiClient.ts` to direct fetch + 2 s polling | 10 min |
| End-to-end test from the demo phone | 10 min |
| **Total** | **~50 min** |

That is why the trigger deadline is 13:00: a 50-minute switch started at 13:00 lands at 13:50, leaving 2 hours for the pitch. A switch started at 15:00 lands at 15:50 — inside the freeze window. **Never switch after 13:00.**

### 7.4 Why this fallback is credible (and what it is not)

Supabase Edge Functions are Deno, 150 s wall-clock per invocation, 150 MB memory, 6 MB max response, 500K invocations/month free (third-party limits summaries, see §9 — the official limits page was not opened; treat these numbers as planning figures, not guarantees). The fallback is a **lifeboat**, not a second home: it preserves the demo, not the architecture. If Convex is healthy, it is never used — but it is designed now so it can be executed in 50 minutes by one agent without design decisions under pressure.

---

## §8 — Model + cost (5-hour build, 1-day demo)

- **Model: `gpt-4o-mini`.** `$0.15/1M input, $0.60/1M output, $0.075 cached input, 128K context, 16K max output` (multiple third-party price trackers, checked 2026-11-12). OpenAI lists a deprecation date of **2027-01-14** with a suggested replacement (third-party trackers) — irrelevant for a 1-day demo, and the model ID is a single env var (`AI_MODEL`) for a one-line swap.
- **Cost math:** ~1,500 input + ~400 output tokens per call ≈ **$0.0005/call**. 200 calls (the circuit-breaker cap) ≈ **$0.10**. 1,000 calls ≈ **$0.50**. The model is never the budget risk; the retry loop is — hence the breaker.
- **Why not a bigger model:** latency. A demo answer must start streaming in <2 s and finish in <10 s. `gpt-4o-mini` is chosen for low latency and low cost at this scale; a larger model buys quality the judges can't score in 5 minutes and costs seconds they will feel.
- **Key handling:** the OpenAI key lives **only** as a Convex env var (and, in the fallback, as a Supabase secret). It never enters the JS bundle, never enters git, never enters a chat message. The 12/11 report's "secrets in bundle" trap is a demo-killer because a leaked key in a public repo is revoked by scanners within minutes.

---

## §9 — CHƯA ĐỌC / unverified (do not present as read)

- **Convex MCP server:** conflicted. The 12/11 report notes the official AI overview references an MCP server while a third-party directory says no official MCP server exists. Not opened by this brief; irrelevant to the build (the `ai-files`/plugin path is the verified one). **CHƯA ĐỌC.**
- **Default runtime `setTimeout` vs OpenAI SDK retry:** mitigated defensively (`"use node"` + `maxRetries: 0`). Harmless either way; the underlying interaction was not independently reproduced. **Unverified interaction, mitigated.**
- **supabase-js `invoke()` SSE support:** source read says the raw `Response` is returned for `text/event-stream`; one real codebase says it doesn't support streams. Recommendation (direct fetch) is safe under either reading. **Conflict noted, not resolved.**
- **Action timeout:** the limits page gives 10 min (Node actions) / 30 min (Convex-runtime actions); the actions page's flat "10 minutes" is a loose statement. Resolved by runtime; AI actions are Node → 10 min.
- **OpenAI SDK request options in the §3.2 sketch** (`signal` in the second argument, error `.status` / `.name` taxonomy): standard SDK RequestOptions behaviour; confirm exact error names against the installed SDK version when wiring.
- **GitHub issue #199 continuation pattern** (long-running agents): not re-opened for this brief.
- **Scheduled-function total arg size 8 MiB vs 16 MiB across sources:** official limits page figure used (16 MiB total); the 8 MiB figure appears in a secondary source. **Conflict noted.**
- **Supabase Edge Function limits** (150 s wall-clock, 150 MB, 6 MB response, 500K invocations/month free): third-party summaries only; the official Supabase limits page was not opened for this brief. **Planning figures, not guarantees.**
- **Agent component "early development" status:** from a 2026-11-03 survey quoting the README; the README itself was not re-opened 2026-11-13. **Second-hand; treat as a caution, not a verdict.**
- **EAS free queue 90+ min, Expo Go SDK 58 store status, Apple Dev / Supabase accounts:** carried from the 12/11 reports, not re-verified here. **Not this brief's topic except as cited.**
- **The idea itself:** not final as of 09:12 13/11. Every `/* IDEA: */` placeholder must be filled from `CONTRACT.md` in the first 20 minutes; nothing in this brief invents the idea.

---

## §10 — Sources (all accessed 2026-11-13 unless noted)

- Convex functions overview — https://docs.convex.dev/functions
- Convex functions: actions — https://docs.convex.dev/functions/actions
- Convex functions: runtimes — https://docs.convex.dev/functions/runtimes
- Convex HTTP actions — https://docs.convex.dev/functions/http-actions
- Convex streaming (delta + HTTP, `useChat` vs `useUIMessages`) — https://docs.convex.dev/agents/streaming
- Convex scheduling / scheduled functions — https://docs.convex.dev/scheduling/scheduled-functions
- Convex cron jobs — https://docs.convex.dev/scheduling/cron-jobs
- Convex AI Gateway overview / setup — https://docs.convex.dev/ai-gateway/overview · https://docs.convex.dev/ai-gateway/setup
- Convex React Native quickstart — https://docs.convex.dev/quickstart/react-native
- Expo + Convex guide — https://docs.expo.dev/guides/using-convex/
- Convex React client (`useQuery` undefined while loading) — https://docs.convex.dev/client/react/overview
- Convex production limits — https://docs.convex.dev/production/state/limits
- Convex pricing FAQ (what happens when Free limits are hit) — https://www.convex.dev/pricing/faq
- Convex Agent Mode / CLI — https://docs.convex.dev/cli/agent-mode
- Convex multiple deployments — https://docs.convex.dev/production/multiple-deployments
- Convex deployment CLI reference — https://docs.convex.dev/cli/reference/deployment
- Convex deploy CLI reference — https://docs.convex.dev/cli/reference/deploy
- Convex environment variables — https://docs.convex.dev/production/environment-variables · https://docs.convex.dev/cli/reference/env
- Convex file storage — https://docs.convex.dev/file-storage/upload-files
- Convex Auth setup — https://labs.convex.dev/auth/setup
- Long-running agents / 10-minute action timeout pattern — https://github.com/get-convex/agent/issues/199
- Convex Agent component survey (early-development status, second-hand) — https://sholajegede.medium.com/how-to-build-ai-agents-that-survive-production-8-npm-packages-for-memory-cost-and-observability-1f22de562c9d (2026-11-03)
- Prior briefs (12/11): `research_notes/backend-agent-toolkit-20261112/report.md` · `research_notes/mobile-agent-toolkit-20261112/report.md` · `goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md` · `FLEET-MODE.md`
- gpt-4o-mini pricing: third-party trackers, checked 2026-11-12 (see §8).
