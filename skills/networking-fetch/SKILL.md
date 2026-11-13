---
name: networking-fetch
description: "Hackathon fetch rules for the Expo SDK 58 app: named expo/fetch import, non-streaming JSON AI calls, 30 s client timeout with AbortSignal.timeout, retry-once-on-network-error-only, exponential backoff with Retry-After on Gemini 429, and the real Convex/Supabase platform ceilings. Use when writing or debugging any AI call or backend request. Composed from verified official sources (Expo, Convex, Supabase, Google AI) — no upstream skill covers this exact combination."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Node 22+, Expo SDK 58, expo 58.0.25. No full Expo app is built or run by this skill alone.
metadata:
  version: "0.1.0"
---

# networking-fetch — expo/fetch, timeouts, retries, backoff

You are the builder for a mobile hackathon app (Expo + React Native +
TypeScript, SDK 58). Every AI call and every backend request in the app
goes through the single wrapper in `templates/fetch-with-timeout.ts`.
Never call `fetch` directly in a screen, never invent a second wrapper,
never add axios.

## 0. Pins — read first, never drift

- `expo` 58.0.25 (npm `latest`, verified 2026-11-13 via `npm view expo`
  and by inspecting the published tarball: `package.json` exports
  `"./fetch"` to `./build/winter/fetch/index.js`, with native and web
  implementations plus tests under `src/winter/fetch/`).
  Source: https://docs.expo.dev/versions/latest/sdk/expo/
- `expo/fetch` is a WinterCG-compliant Fetch API that "works consistently
  across web and mobile environments". Named import:
  `import { fetch } from 'expo/fetch'`. On Android and iOS,
  `expo/fetch` is also installed as the global `fetch`; setting
  `EXPO_PUBLIC_USE_RN_FETCH=1` restores React Native's built-in fetch
  as the global, but "Named imports from `expo/fetch` continue to work
  regardless of this flag".
  Source: https://docs.expo.dev/versions/latest/sdk/expo/ (read 2026-11-13)
- SDK 58 bundles React Native 0.88; the `expo` package rewrote
  `TextDecoder` for speed in SDK 58 — do not attribute it to Hermes.
  Source: https://expo.dev/changelog/sdk-58 (read 2026-11-13)
- Convex limits (official): Node-runtime action execution time **10 min**;
  Convex-runtime action **30 min**; query/mutation **1 s** (user code
  only, database operations excluded). Free plan: 1,000,000 function
  calls/month, 20 GB-hours/month action compute.
  Source: https://docs.convex.dev/production/state/limits (read 2026-11-13)
- Supabase Edge Functions limits (official, updated 2026-10-29): free
  plan maximum duration (wall clock) **150 s**; request idle timeout
  **150 s** (otherwise `504 Gateway Timeout`).
  Source: https://supabase.com/docs/guides/functions/limits (read 2026-11-13)
- Gemini API rate limits (official): exceeding a limit returns
  `429 RESOURCE_EXHAUSTED`; resolution is "Wait and retry after a short
  period" and reduce the rate of expensive requests. Per-model free-tier
  RPM/TPM/RPD vary by model and tier and are shown in AI Studio — never
  hardcode a per-model number from memory.
  Source: https://ai.google.dev/gemini-api/docs/rate-limits (read 2026-11-13)

## 1. The fetch rule — named import, non-streaming demo path

1. **Always** `import { fetch } from 'expo/fetch'` for AI calls. Never
   rely on the bare global `fetch` for streaming: React Native's
   built-in (global) fetch is an XHR polyfill with no `response.body`,
   so streaming silently degrades — the request resolves once with the
   whole answer, no throw, no warning.
2. **The demo ships non-streaming fetch + JSON parse.** One Convex
   action returns one JSON document; the client awaits it and renders.
   Streaming is NOT the demo path.
3. **Streaming smoke test only:** assert `res.body !== null` once
   (against a streaming endpoint) to prove the named import streams.
   A final-text-only test cannot catch the silent-degradation trap.
4. Never set `EXPO_PUBLIC_USE_RN_FETCH=1`. It only affects the global
   fetch and buys nothing once rule 1 is followed.

## 2. Timeouts and retries — the build's own numbers

These numbers are the build's design decisions (from the backend brief
§3.1), NOT platform limits. Do not confuse them with §3.

| Budget | Value | Where enforced |
| --- | --- | --- |
| Server-side model call | 25 s | Inside the Convex action (`AbortSignal.timeout(25000)` on the model call) |
| Client wait on the action | 30 s | In `fetchWithTimeout` (`AbortSignal.timeout(30000)`); the client never waits longer than the server |
| Retry | Once, on network error only | In `fetchWithTimeout`; never retry a 4xx, never retry a timeout |

Rules:

- **Timeout:** `AbortSignal.timeout(ms)` on every request. A request
  with no timeout can hang the demo indefinitely on a dead network.
- **Retry once, network errors only** (`TypeError` / fetch failure,
  i.e. the request never reached the server). A timeout is NOT retried:
  the model call may already be running server-side, and a retry would
  burn a second Gemini call against the free-tier quota.
- **429 handling:** on HTTP 429, wait with exponential backoff
  (`2^attempt * 1000` ms) AND honor a `Retry-After` response header
  when present (take the longer of the two). Maximum 2 retries on 429.
  After that, surface the error state — never loop forever.
- **5xx handling:** one retry with the same backoff as 429, then
  surface the error. A 5xx may be transient; two attempts is the cap.
- **4xx (other than 429):** no retry. It is a client bug (bad URL, bad
  body, bad key handling) — retrying cannot fix it.
- **No retries inside the server action:** the model client runs with
  `maxRetries: 0` so the server never silently re-spends quota.
- **Abort on unmount:** pass the component's `AbortController` signal
  through; on unmount abort, and ignore the resulting `AbortError`
  (see `expo-data-fetching` reference `offline-and-cancellation.md`).

## 3. Platform ceilings — what the servers actually enforce

These are the real limits. The 25 s / 30 s numbers in §2 sit far
inside them; a timeout fired by the platform means the build's own
budgets were bypassed, not that the platform is at fault.

- **Convex (primary):** a Node-runtime AI action may run up to 10 min.
  A demo AI call takes seconds. If an action ever approaches minutes,
  the design is wrong (chunk the work, write progress to a table, let
  the client subscribe) — do not raise any timeout to compensate.
- **Supabase Edge Function (fallback):** 150 s wall clock on the free
  plan, 150 s idle timeout → `504 Gateway Timeout`. The same 25 s /
  30 s client budgets apply unchanged on the fallback path.
- **Gemini (free tier):** RPM / TPM / RPD limits per model; exceeding
  any returns 429. The demo makes at most a handful of calls, so the
  binding risk is a retry storm, not the quota itself — which is why
  §2 caps retries.

## 4. Ban list — the builder MUST NOT use these for network calls

| Banned | Why |
| --- | --- |
| axios (or any HTTP client library) | Unneeded dependency; `expo/fetch` is the platform fetch. Upstream Expo skill preference, kept. |
| Bare global `fetch` for AI calls | Silent streaming loss on the XHR polyfill if the flag is ever set; named import is free. |
| `localhost` / `127.0.0.1` as an API base URL | On the phone, `localhost` is the phone itself. Base URL is always the public Convex/Supabase URL. See `networking-demo-preflight`. |
| Retrying timeouts or 4xx errors | Burns Gemini free-tier quota and cannot fix the underlying cause. |
| Infinite / unbounded retry loops | A retry storm is the fastest way to exhaust the Gemini free tier mid-demo. |
| `setTimeout`-based backoff inside a Convex default-runtime action | The default runtime has no `setTimeout`; AI actions run on the Node runtime (`"use node"`) with `maxRetries: 0`. |

## 5. File map

| File | What it is |
| --- | --- |
| `SKILL.md` (this file) | Fetch rule, timeout/retry policy, platform ceilings, ban list. |
| `templates/fetch-with-timeout.ts` | The single wrapper: timeout + retry-once-on-network-error + 429/5xx backoff + typed errors. Copy verbatim; do not fork it per screen. |

## 6. Verification status (read 2026-11-13)

- `expo/fetch` API page read in full (official Expo docs, `latest`
  = SDK 58): named import, global-fetch note, `EXPO_PUBLIC_USE_RN_FETCH=1`
  behaviour, streaming example with `resp.body.getReader()`.
- `expo` 58.0.25 tarball downloaded from npm and inspected:
  `package.json` `exports["./fetch"]` resolves to
  `./build/winter/fetch/index.js`; native (`ExpoFetchModule`,
  `FetchResponse`) and web implementations present; test files present
  under `src/winter/fetch/__tests__/`.
- The draft wrapper `templates/fetch-with-timeout.ts` was executed
  against a local HTTP server with a stubbed `expo/fetch` (Node
  v24.22.1 type-stripping, 2026-11-13): `fetchJson` success; timeout
  fired at 1204 ms for a 1200 ms budget; 429 → 429 → 200 with the
  `Retry-After: 1` header respected (3014 ms total, ≈ 1000 + 2000 ms
  backoff); 404 → `ApiError` with status 404. All four passed. The
  first run caught a real issue (Node strip-only mode rejects TS
  parameter properties) and the template was fixed to plain field
  assignment before the passing run.
- Node smoke test run 2026-11-13 (Node v24.22.1, same WinterCG
  semantics): GET `https://docs.convex.dev/` → 200; slow endpoint
  (`https://httpbin.org/delay/5`, 1500 ms timeout) aborted as
  `TIMEOUT after 1500ms`; 429 endpoint retried twice with 500 ms +
  1000 ms backoff (elapsed 4077 ms total); GET
  `https://supabase.com/docs` → 200. All four checks passed.
  (Node's `fetch` and `expo/fetch` share the WinterCG surface used by
  the wrapper — `fetch`, `Response.ok`, `status`, `AbortController` —
  so the timeout/retry logic is verified; the native streaming path is
  NOT verified here and must be smoke-tested on the real phone.)
- Convex limits page and Supabase Edge Functions limits page read in
  full 2026-11-13; Gemini rate-limits page read 2026-11-13 (429 +
  retry guidance verified; per-model free-tier numbers NOT quoted —
  they vary by model and must be read in AI Studio for the chosen
  model).
- CORRECTION to the brief: there is no "25 s Convex action timeout".
  The Convex platform limit for Node actions is 10 minutes. The 25 s
  is the build's own server-side model-call timeout and 30 s is the
  build's own client timeout (backend brief §3.1). This skill records
  the distinction in §2/§3.
- CHƯA ĐỌC: the native streaming path (`res.body.getReader()` on a
  real Android phone in Expo Go / preview APK) — phone smoke test only.
  CHƯA ĐỌC: the exact per-model Gemini free-tier RPM/RPD for the model
  the settled idea uses — read in AI Studio on build day, do not guess.
