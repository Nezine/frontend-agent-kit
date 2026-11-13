---
name: expo-data-fetching
description: "Official Expo skill for ANY network request, API call, or data fetching in the hackathon app. Router only — install via the Expo Skills plugin, never vendor a copy. Covers fetch API, React Query, SWR, error handling, caching, offline support, loading/empty/error screen states, and Expo Router data loaders. Use when implementing or debugging any network request. Hackathon pins: prefer expo/fetch (never axios); load this skill before any networking work; the hackathon-specific timeout, streaming, and demo-connectivity rules live in networking-fetch, networking-offline, and networking-demo-preflight."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Node 22+, Expo SDK 58, and the Expo Skills plugin (see §1). No full Expo app is built or run by this skill alone.
metadata:
  version: "0.1.0"
---

# expo-data-fetching — official Expo networking skill (router)

You are the builder for a mobile hackathon app (Expo + React Native +
TypeScript, SDK 58). This file is a ROUTER, not a copy of the upstream
skill: Expo revises its skills per SDK release and a vendored copy rots.
Install the official skill, then follow the hackathon pins in §2 — they
override the upstream skill wherever the two disagree.

## 0. Pins — read first, never drift

- Upstream skill: `expo-data-fetching`, MIT, in the `expo/skills` repo at
  `plugins/expo/skills/expo-data-fetching/SKILL.md`, with reference
  `references/offline-and-cancellation.md`.
  Source: https://github.com/expo/skills/blob/main/plugins/expo/skills/expo-data-fetching/SKILL.md
  (read in full 2026-11-13)
- Upstream skill index (all official Expo skills, install commands):
  Source: https://docs.expo.dev/skills/ (read 2026-11-13)
- `expo` 58.0.25 (npm `latest`, verified 2026-11-13 via `npm view expo`).
  React Native 0.88, React 19.3.0.
  Source: https://expo.dev/changelog/sdk-58
- `@tanstack/react-query` 5.107.1, MIT (npm `latest`, verified 2026-11-13).
  Only install it if the build actually needs caching/state management;
  the default for the 5-hour build is the plain `expo/fetch` wrapper in
  `networking-fetch` — do not add React Query "just in case".

## 1. Install — plugin route only, never vendor

- Claude Code: `claude plugin install expo@claude-plugins-official`
- Codex: `codex plugin add expo@openai-curated`
- Other agents: `npx skills@latest add expo/skills --skill '*'`
- Then load `expo-overview` first (the router skill), then
  `expo-data-fetching` for any networking step.
  Source: https://docs.expo.dev/skills/
- Never copy the upstream SKILL.md into this repo. If the upstream file
  changes, the installed plugin copy is the current one; this router only
  records the version it was checked against (see §5).

## 2. Hackathon pins — these override the upstream skill

| # | Rule | Why |
| --- | --- | --- |
| 1 | Use the named `import { fetch } from 'expo/fetch'` for EVERY AI call. Never rely on the bare global `fetch` for streaming. | Upstream examples use bare `fetch(...)`. In SDK 58 `expo/fetch` is the global by default, but `EXPO_PUBLIC_USE_RN_FETCH=1` restores React Native's XHR fetch as the global while named imports keep working. The named import is the only form that cannot silently lose streaming. Source: https://docs.expo.dev/versions/latest/sdk/expo/ |
| 2 | Never use axios. | Upstream preference, kept: "Avoid axios, prefer expo/fetch". |
| 3 | Every AI call goes through the timeout/retry wrapper in `networking-fetch` (30 s client timeout, retry once on network error only). Do not copy the upstream retry snippet verbatim — it retries 3 times with no timeout and no 429 handling. | The upstream `fetchWithRetry` has no timeout and retries all errors; a Gemini 429 retried 3 times burns the free-tier quota. See `networking-fetch` §2. |
| 4 | The demo ships NON-STREAMING fetch + JSON parse. Streaming (`res.body.getReader()`) is a smoke-test assertion only (`res.body !== null`), not the demo path. | Streaming silently degrades to whole-answer-at-once on the global XHR fetch; the non-streaming path cannot fail that way. Source: mobile-deep §4 trap #6. |
| 5 | Every screen that loads data implements the four states: loading, error, empty, content. A refresh error coexists with cached content. | Upstream §"Every Screen Has Four States", kept verbatim. |
| 6 | Offline behaviour comes from `networking-offline`, not from this skill alone. | Upstream offline coverage is one reference file (NetInfo hook + React Query `onlineManager`); the hackathon needs the cached-last-result rule and the pending-AI-call queue, which live in `networking-offline`. |

## 3. What the upstream skill covers (verified by reading it in full)

- Basic fetch GET/POST with `response.ok` checks and a typed `ApiError`.
- React Query v5 setup (`QueryClient`, `staleTime` 5 min, `retry: 2`),
  `useQuery`/`useMutation` patterns, `isLoading` vs `isFetching`.
- Retry with exponential backoff (`2^i * 1000` ms) — see pin #3 before
  using it.
- Token management via `expo-secure-store` (never AsyncStorage for
  tokens) and a token-refresh flow.
- Environment variables: `EXPO_PUBLIC_` prefix, inlined at build time,
  never secrets in `EXPO_PUBLIC_` vars.
- Request cancellation: `AbortController` on unmount; React Query cancels
  automatically. Full reference:
  `references/offline-and-cancellation.md` (read 2026-11-13).
- Decision tree: route-level loaders (web, SDK 55+) / basic fetch /
  caching / auth / error handling / offline / env config / performance.
- Common mistakes: no error handling, tokens in AsyncStorage.

## 4. What the upstream skill does NOT cover (gaps — see sibling skills)

- No timeout on any request (no `AbortSignal.timeout`, no per-call
  budget). Covered by `networking-fetch`.
- No `expo/fetch` named-import rule and no streaming assertion.
  Covered by `networking-fetch`.
- No 429 / rate-limit handling (Gemini free tier returns
  `429 RESOURCE_EXHAUSTED`). Covered by `networking-fetch`.
- No Convex / Supabase endpoint limits or reachability rules
  (Convex Node-action 10 min, Supabase Edge Function 150 s free).
  Covered by `networking-fetch` §3.
- No Metro tunnel vs LAN vs preview APK connectivity and no demo-phone
  pre-flight. Covered by `networking-demo-preflight`.
- No cached-last-result labelling rule and no pending-AI-call queue.
  Covered by `networking-offline`.

## 5. Verification status (read 2026-11-13)

- Upstream `SKILL.md` read in full (478 lines — corrected from the
  finder's "746 lines" by the coordinator's re-check of the raw file on
  `main`, 2026-11-13) from the `expo/skills` repo `main` branch,
  2026-11-13. License MIT stated in the skill frontmatter (confirmed).
  Reference file `offline-and-cancellation.md` fetched and read in full
  (1400 bytes, confirmed) the same day. The `EXPO_PUBLIC_USE_RN_FETCH=1`
  token is confirmed present on the Expo fetch docs page (2026-11-13);
  the full sentence was not re-read verbatim.
- The upstream skill is versioned by the repo, not by a release number:
  no version string is published for it. "Current" means the `main`
  branch as read on 2026-11-13. Re-check `main` before the build if the
  SDK moves.
- No full Expo app is built or run by this skill: there is no real phone
  here. The real-phone smoke test is a runbook step for the team, not
  something this skill can claim.
- CHƯA ĐỌC: whether a newer upstream revision of this skill exists after
  2026-11-13 (the build-day team should re-open the GitHub page once).
