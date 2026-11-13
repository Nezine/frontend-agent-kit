---
name: networking-demo-preflight
description: "Demo-phone connectivity for the Expo SDK 58 hackathon app: Metro LAN vs tunnel (ws-tunnel default in SDK 58, ngrok legacy) vs preview APK (Metro-independent), the public-URL-only rule, Supabase/Convex reachability on mobile data AND Wi-Fi, and the connectivity pre-flight checklist for the demo phone. Use on build day before the judged demo and at the 13:00 and 15:00 checkpoints. Composed from verified official sources (Expo, Convex, Supabase) — no upstream skill covers the demo-vehicle connectivity decision."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Node 22+, Expo SDK 58, expo 58.0.25, one real Android phone. No full Expo app is built or run by this skill alone.
metadata:
  version: "0.1.0"
---

# networking-demo-preflight — LAN vs tunnel vs preview APK

You are the builder for a mobile hackathon app (Expo + React Native +
TypeScript, SDK 58). The judged demo is one real Android phone, killed
and reopened, main AI flow live (40 points). The phone's connection to
the JS bundle and to the backend are two separate links, and each can
fail independently. This skill decides which vehicle carries the demo
and proves each link before the judges see it.

## 0. Pins — read first, never drift

- `expo` 58.0.25 (npm `latest`, verified 2026-11-13). SDK 58 bundles
  React Native 0.88.
  Source: https://expo.dev/changelog/sdk-58
- **Tunnel (SDK 58):** "Expo CLI has a new tunnel implementation built
  on `@expo/ws-tunnel`. It connects faster, holds the connection more
  reliably, and no longer needs `@expo/ngrok`. This is now the default
  when running `expo start` with a tunnel: `expo start --tunnel`."
  "You'll need to be signed in to your Expo account (`expo login`) to
  use it. You can still use the legacy `@expo/ngrok` tunnels by passing
  `--tunnel ngrok`."
  Source: https://expo.dev/changelog/sdk-58 (read 2026-11-13)
- `@expo/ws-tunnel` 2.0.1, MIT (npm `latest`, verified 2026-11-13 via
  `npm view`).
- **Dev-server URL modes (official Expo CLI docs):** "By default, the
  project is served over a LAN connection." `--localhost` serves
  localhost-only. Tunneling serves "a public URL" for restrictive
  networks; "Tunneling is slower than local connections because
  requests must be forwarded to a public URL"; "Tunnel URLs are public
  and can be accessed by any device with a network connection"; "Tunnels
  require a network connection on both devices" and cannot be used with
  `--offline`.
  Source: https://docs.expo.dev/more/expo-cli/ (read 2026-11-13)
- **Preview APK (Metro-independent):** "In production apps, there is
  one main.js bundle that is shipped with the app itself."
  Source: https://docs.expo.dev/develop/development-builds/faq/
- **EAS env vars:** "These files are generally excluded from the
  project's version control… so they are not available for jobs that
  run on a remote server, for example, Expo Build." `.env.local` does
  NOT reach a cloud-built APK — set `EXPO_PUBLIC_CONVEX_URL` with
  `eas env:set` (or `eas env:push`) for the preview environment, or the
  APK ships without the backend URL.
  Source: https://docs.expo.dev/eas/environment-variables/
- Convex free limits (official): 1,000,000 function calls/month,
  20 GB-hours/month action compute, Node action 10 min.
  Source: https://docs.convex.dev/production/state/limits
- Supabase Edge Functions free limits (official, updated 2026-10-29):
  150 s wall clock, 150 s idle timeout → 504.
  Source: https://supabase.com/docs/guides/functions/limits

## 1. The three vehicles — pick by checkpoint, not by habit

| Vehicle | JS bundle source | Needs at demo time | When to use |
| --- | --- | --- | --- |
| Expo Go + Metro LAN | Laptop Metro over venue Wi-Fi | Laptop alive, same Wi-Fi, device-to-device traffic allowed | Iteration all day; FIRST try at the venue |
| Expo Go + Metro tunnel (`--tunnel`, ws-tunnel) | Laptop Metro via Expo's tunnel service | Laptop alive, internet on both, Expo account signed in (`expo login`) | Only if LAN fails (restrictive venue Wi-Fi / firewall). Slower than LAN. |
| Preview APK (EAS `--profile preview`) | Embedded in the binary | Internet only (for the AI call to Convex/Supabase) — Metro dead is fine | **The judged demo.** Build it tonight (Fri 13/11), install it, kill-and-reopen-test it twice with Metro STOPPED. |

Rules:

1. **Demo on the preview APK.** In Expo Go the phone reloads JS from
   Metro on every reopen, so a dead laptop, dead tunnel, or dead venue
   Wi-Fi at 16:15 = a blank screen in front of the judges. The preview
   APK embeds the bundle; only the AI call still needs internet.
2. **LAN first at the venue, tunnel only if LAN fails.** There is NO
   automatic fallback — LAN / localhost / tunnel are explicit flags;
   switching means stop Metro and restart with a different flag.
3. **Never start a cloud build mid-window.** EAS free-queue waits at
   peak are unverified in exact minutes but the queue is a single
   concurrent build; a build started at 14:00 can still be queued at
   16:00. Build the preview APK tonight. If a Saturday rebuild is
   unavoidable, start it the moment the native set freezes and keep
   Expo Go as the live demo path meanwhile.
4. **Tunnel is a single point of failure and a security exposure for
   the pitch:** the tunnel URL is public (mitigated only by entropy in
   the URL). Do not demo on the tunnel if the preview APK works.

## 2. The public-URL rule — the most common demo failure

- API base URL = the public Convex URL (`https://<deployment>.convex.cloud`)
  or the public Supabase project URL. **Never `localhost`, never a LAN
  IP baked into the app.** `localhost` on the phone is the phone itself.
- The backend URL must be baked into the cloud-built APK via EAS env
  vars (§0), not `.env.local`. Verify after install: kill Metro, open
  the APK, run the AI flow end-to-end. Cold-open alone proves nothing —
  the backend URL must be proven live with Metro stopped.
- Supabase fallback: copy the URL and key names from Dashboard →
  Connect, never guess them. Publishable/anon key naming must be copied
  from the Dashboard (the naming changed across docs generations).

## 3. Reachability — prove it on mobile data AND Wi-Fi

The backend URL must be reachable from the phone on both transports.
Run these at 13:00 and 15:00 on build day:

1. **Wi-Fi OFF, mobile data ON:** run one full AI request end-to-end.
   Pass = the answer completes. This proves the backend URL is public,
   not a LAN address. Fail = fix the URL before anything else.
2. **Wi-Fi ON (venue Wi-Fi):** run the same request. Pass = completes.
   Fail on venue Wi-Fi but pass on mobile data = the venue network
   blocks `*.convex.cloud` / `*.supabase.co` (or its captive portal
   breaks the connection). Demo on mobile data.
3. **Kill-and-reopen ×2 on the preview APK with Metro STOPPED:** main
   screen loads from cold twice AND the AI flow completes. This is the
   exact judged sequence.
4. **Tunnel check (only if the Expo Go path is the fallback):** start
   Metro with `--tunnel` from a non-home network, scan, load. Note the
   slowness vs LAN. `expo login` must already be done — the SDK 58
   tunnel requires a signed-in Expo account.
5. **Expo Go version freeze:** record the phone's Expo Go version
   tonight; do NOT update/install Expo Go on Saturday without
   re-testing the scaffold immediately after (a store auto-update can
   flip the SDK and break the project at 09:00).

## 4. Failure decision tree (in the moment, no debate)

| Symptom | Diagnosis | Fix (in order) |
| --- | --- | --- |
| Expo Go: "Project is incompatible with this version of Expo Go" | SDK mismatch (exact match, not minimum) | Scaffold the SDK matching the phone's Expo Go version; never bare `npx create-expo-app@latest` without `--template` |
| Expo Go: "Something went wrong" / bundle cannot load | Metro dead or tunnel dropped | Preview APK is the demo (Metro-independent). Backup: `npx expo start --tunnel --clear`, re-scan |
| AI call fails on Wi-Fi, works on mobile data | Venue network blocks/captive-portals the backend host | Demo on mobile data; do not debug the venue network mid-pitch |
| AI call fails on both | Backend URL wrong / env var missing from the APK / backend down | Check `EXPO_PUBLIC_CONVEX_URL` is set for the preview environment; check the Convex dashboard; fall back to Supabase only on the pre-agreed trigger (backend brief §7) |
| Tunnel will not connect | Tunnel service issue (ws-tunnel) or not signed in | Verify `expo login`; restart with `--tunnel`; if it still fails, LAN, then preview APK. (The legacy ngrok status page at https://status.ngrok.com applies ONLY to `--tunnel ngrok`, not to the SDK 58 default tunnel.) |
| Preview APK install blocked | Android unknown-source gate / Play Protect scan | Allow time for the Play Protect screen, or `adb install <file>.apk` with USB debugging |

## 5. Ban list — the builder MUST NOT do these on demo day

| Banned | Why |
| --- | --- |
| Demoing on Expo Go + Metro tunnel as the first choice | Single point of failure + public URL + slower; the preview APK exists precisely to remove Metro from the demo. |
| `localhost` as the API base URL | Fails on the phone by definition. |
| Starting an EAS cloud build after 13:00 | Queue risk eats the demo window; build tonight. |
| Updating Expo Go on Saturday morning | Store auto-update can flip the SDK and break the project before the build starts. |
| Debugging the venue network during the pitch | If mobile data works, demo on mobile data. Venue Wi-Fi is not the product. |

## 6. File map

| File | What it is |
| --- | --- |
| `SKILL.md` (this file) | Vehicle decision, public-URL rule, reachability tests, failure tree, ban list. |
| `references/preflight-checklist.md` | Copy-paste checklist for tonight (Fri 13/11) and the 13:00 / 15:00 build-day checkpoints. |

## 7. Verification status (read 2026-11-13)

- SDK 58 changelog read in full (official): ws-tunnel default,
  `@expo/ngrok` no longer needed, `--tunnel ngrok` legacy, `expo login`
  required, relative manifest URLs for proxied/tunnelled dev servers,
  React Native 0.88, Node ≥22.13.
- Expo CLI docs page read in full (official): LAN default, `--tunnel`
  / `--localhost` / `--port` flags, tunnel drawbacks (slower, public
  URL, needs network on both devices, no `--offline`), ngrok outage
  note. **Discrepancy noted:** the CLI docs page still documents
  tunneling via `@expo/ngrok` (`npm i -g @expo/ngrok`) and does not
  mention `@expo/ws-tunnel`. The SDK 58 changelog (newer, SDK-specific)
  governs: ws-tunnel is the SDK 58 default. Do not install
  `@expo/ngrok` for an SDK 58 project unless falling back to
  `--tunnel ngrok` deliberately.
- Development-builds FAQ (embedded bundle) and EAS environment-variables
  page (`.env.local` unavailable to remote builds) verified from the
  mobile-deep brief's official citations (accessed 2026-11-13 by that
  brief); not re-opened in this pass — re-open both before the build if
  the preview-APK step is disputed.
- `npm view @expo/ws-tunnel` 2026-11-13: version 2.0.1, license MIT.
  `npm view expo` 2026-11-13: 58.0.25.
- Node smoke test run 2026-11-13: GET `https://docs.convex.dev/` →
  200, GET `https://supabase.com/docs` → 200 (reachability of the
  vendors' public hosts from this VM; not a substitute for the phone
  test).
- CHƯA ĐỌC: venue Wi-Fi reachability of `*.convex.cloud` /
  `*.supabase.co` — needs the live phone test, cannot be verified from
  docs. CHƯA ĐỌC: exact EAS free-tier queue time on Saturday — no live
  build was run; "build tonight" is the mitigation, not a measured
  number. CHƯA ĐỌC: exact Play Protect warning text/flow for an EAS
  preview APK — allow time for it, do not quote the wording.
- Legacy ngrok status page `https://status.ngrok.com` verified
  resolving (HTTP 200, coordinator check 2026-11-13). It applies ONLY
  to the `--tunnel ngrok` fallback path, not to the SDK 58 default
  tunnel.
