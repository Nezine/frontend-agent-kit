---
name: networking-offline
description: "Offline behaviour for the Expo SDK 58 hackathon app: NetInfo network-state detection (Included in Expo Go), the four screen states, last-good-result cache labelled as cached (never presented as live), and the pending-AI-call rule (no blind auto-retry of actions; mutations auto-retry, actions do not). Use when building any screen that loads data or any flow that must survive the venue Wi-Fi dying. Composed from verified official sources (Expo, Convex) — the upstream expo-data-fetching skill covers only the NetInfo hook."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Node 22+, Expo SDK 58, @react-native-community/netinfo 12.0.1. No full Expo app is built or run by this skill alone.
metadata:
  version: "0.1.0"
---

# networking-offline — detection, cached results, pending AI calls

You are the builder for a mobile hackathon app (Expo + React Native +
TypeScript, SDK 58). The judged demo runs on one real phone in a venue
with unknown Wi-Fi. The app must degrade gracefully when the network
dies: show the state honestly, keep the last good result visible, and
never present cached output as a live AI result.

## 0. Pins — read first, never drift

- `@react-native-community/netinfo` **12.0.1** — "Included in Expo Go",
  recommended version for SDK 58. Install with
  `npx expo install @react-native-community/netinfo` (never bare npm,
  so the version resolves against SDK 58).
  Source: https://docs.expo.dev/versions/latest/sdk/netinfo/ (read 2026-11-13)
- NetInfo API (official README, MIT license, read 2026-11-13):
  `NetInfo.fetch()` (one-shot state), `NetInfo.addEventListener()`
  (subscribe), `useNetInfo()` hook. State fields: `type`
  (`none` | `unknown` | `wifi` | `cellular` | ...), `isConnected`
  (boolean, null when unknown), `isInternetReachable` (boolean, null
  when unknown), `details`.
  Source: https://github.com/react-native-netinfo/react-native-netinfo
- `expo-network` ~58.0.5 — "Included in Expo Go". Alternative one-shot
  check: `Network.getNetworkStateAsync()` →
  `{ type, isConnected, isInternetReachable }`, plus `useNetworkState()`
  hook. Use NetInfo as the default (it is what the upstream Expo skill
  references); `expo-network` is the fallback if NetInfo misbehaves on
  the demo phone.
  Source: https://docs.expo.dev/versions/latest/sdk/network/
- Convex React client (official): "If the internet connection drops,
  the client will handle reconnecting and re-establishing the Convex
  session automatically." "Convex React automatically retries mutations
  until they are confirmed to have been written to the database."
  "Actions do not support automatic retries or optimistic updates."
  Convex "will automatically handle intermittent network blips" but
  "doesn't currently provide a full offline sync mechanism".
  Source: https://docs.convex.dev/client/react/overview and
  https://www.convex.dev/sync (read 2026-11-13)
- Upstream Expo skill reference (NetInfo hook + React Query
  `onlineManager`): `references/offline-and-cancellation.md` in
  `expo-data-fetching`. Read it; this skill extends it, it does not
  replace it.
  Source: https://github.com/expo/skills/blob/main/plugins/expo/skills/expo-data-fetching/references/offline-and-cancellation.md

## 1. Detection — NetInfo, and what each field means

- Use `useNetInfo()` in the root layout (see
  `templates/use-network-status.ts`) and pass `isOnline` down. Do not
  call `NetInfo.fetch()` in every screen.
- **Online means `isInternetReachable === true`.** `isConnected` alone
  is NOT enough: a phone on venue Wi-Fi with no internet behind it
  reports `isConnected: true` and every request still fails.
- Treat `null` (unknown) as online for UI purposes but do NOT suppress
  the error state: if a request then fails, the error state shows.
  Never treat `null` as proof of offline.
- `type` is for display only ("Offline — Wi-Fi lost" vs "Offline —
  mobile data lost"). Never branch logic on `type === 'cellular'`
  (no behaviour difference is specified for the demo).
- Re-check with `NetInfo.refresh()` after the user taps Retry — the
  cached state can be stale after a network change.

## 2. The four screen states (mandatory, every data screen)

From the upstream `expo-data-fetching` skill, kept verbatim in intent:

| State | When | UI |
| --- | --- | --- |
| Loading | First fetch running, no data yet | Skeleton (known layout) or spinner |
| Error | Fetch failed, no data | Inline error + Retry button; Retry re-checks NetInfo first |
| Empty | Resolved with zero items | Designed empty state with the next action, not a blank list |
| Content | Data present | Render it; a failed refresh keeps stale content visible with a nonblocking "Could not refresh. Showing saved data." + Retry |

Additional hackathon rule: **a refresh error must never blank the
screen.** If cached content exists, keep it and show the nonblocking
error. Blank-screen-on-refresh is a demo failure.

## 3. Cached last result — show it, label it, never fake it

- Persist the last successful AI result (and its input) to AsyncStorage
  when it arrives. On cold start (kill-and-reopen), render the cached
  result immediately while the live call runs in the background.
- **The cached result MUST be labelled "Cached — from <time>" with a
  visible Retry/Refresh button.** Never present cached output as a live
  AI result. A judge who reopens the app and sees a stale answer with
  no label is being misled; a labelled cache is a feature.
- AsyncStorage is "an asynchronous, unencrypted, persistent key-value
  storage… a good choice for storing… user preferences or app state"
  and survives kill-and-reopen.
  Source: https://docs.expo.dev/develop/user-interface/store-data/
- Cache only the last result, not a history. One key, one JSON blob,
  overwritten on each success. No cache invalidation policy is needed
  for a one-day demo.
- If there is no cached result and no network, the screen shows the
  error state with "You're offline" copy — not an empty state.

## 4. Pending AI calls — what happens, exactly

The Convex client splits behaviour by function type. The app must
respect the split; do not paper over it.

| Case | Behaviour |
| --- | --- |
| Query subscription drops (offline) | Convex client reconnects and re-establishes the session automatically. The UI keeps rendering the last state the client had. Nothing to write. |
| Mutation made while offline | Convex React retries it automatically until confirmed written. The UI may show it as pending; it will land. Nothing to write. |
| AI **action** in flight when the network drops | Actions have NO automatic retry. The client promise rejects. The run row (if the backend wrote one) keeps its last status; the client shows the error state with Retry. Retry re-runs the action from scratch — a second Gemini call. That is why `networking-fetch` never auto-retries a timeout. |
| User taps "Generate" while offline | Do NOT fire the action. Disable the button (or show the offline banner + "will run when you're back online" copy) and queue the *request* (prompt text) locally in AsyncStorage. When NetInfo reports online again, show "Back online — Run now?" and let the user tap to run. Never auto-fire a queued AI call on reconnect: an auto-fired call the user did not ask for burns Gemini quota and can surprise the demo. |
| Queued request + app killed while offline | The queued prompt survives (AsyncStorage). On next launch, if online, offer to run it. If still offline, keep it queued. |

## 5. Ban list — the builder MUST NOT use these for offline behaviour

| Banned | Why |
| --- | --- |
| Treating `isConnected` as "internet works" | Venue Wi-Fi with no internet passes `isConnected` and fails every request. Gate on `isInternetReachable`. |
| Presenting a cached AI result as live | Misleads the judges on reopen; the label is mandatory (§3). |
| Auto-firing a queued AI call on reconnect | Burns Gemini free-tier quota on a call nobody asked for in that moment. |
| Auto-retrying a failed AI action in a loop | Actions have no server-side retry; a client loop is a retry storm. One manual Retry, then stop. |
| A full offline-sync library (e.g. a queue/sync framework) | Out of scope for a 5-hour build. Convex already auto-retries mutations and auto-reconnects queries; the app only needs the queue rule in §4. |
| Storing tokens in AsyncStorage | Tokens go in `expo-secure-store` (upstream skill rule). AsyncStorage is unencrypted and is for the cached result and the queued prompt only — neither is secret. |

## 6. File map

| File | What it is |
| --- | --- |
| `SKILL.md` (this file) | Detection rules, four states, cache labelling, pending-call table, ban list. |
| `templates/use-network-status.ts` | Root-layout hook: `useNetInfo()` → `{ isOnline, type, refresh }` + an offline banner component. Copy verbatim. |

## 7. Verification status (read 2026-11-13)

- NetInfo SDK page (latest = SDK 58) read in full: "Included in Expo
  Go", recommended version 12.0.1, `npx expo install` command,
  `fetch()` / `addEventListener()` examples.
- NetInfo GitHub README read in full: MIT license, API surface
  (`fetch`, `addEventListener`, `useNetInfo`, `refresh`,
  `useNetInfoInstance`), state fields including `isInternetReachable`.
  `npm view @react-native-community/netinfo` 2026-11-13: version
  12.0.1, license MIT.
- `expo-network` SDK page verified via search result (official docs):
  "Included in Expo Go", recommended version ~58.0.5,
  `getNetworkStateAsync()` example. `npm view expo-network` 2026-11-13:
  58.0.5.
- Convex React overview page read in full 2026-11-13: "If the internet
  connection drops, the client will handle reconnecting and
  re-establishing the Convex session automatically"; "Convex React
  automatically retries mutations until they are confirmed to have been
  written to the database"; "Actions do not support automatic retries or
  optimistic updates." Convex sync page (verified via search result on
  the official site, 2026-11-13): intermittent blips handled
  automatically, no full offline sync mechanism — that sentence is
  second-hand and should be re-verified from the page itself before
  being quoted elsewhere.
- Upstream `expo-data-fetching` reference
  `offline-and-cancellation.md` fetched and read in full (1400 bytes).
- CHƯA ĐỌC: NetInfo behaviour on the exact demo phone (Wi-Fi-off and
  airplane-mode transitions) — phone test only, tonight. CHƯA ĐỌC:
  whether `isInternetReachable` flips promptly on the venue network
  (it depends on the network's captive-portal behaviour) — the Wi-Fi-off
  mobile-data test in `networking-demo-preflight` is the empirical check.
