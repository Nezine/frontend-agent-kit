# Mobile deep brief — Expo SDK 57/58, Expo Go vs dev build, and the real-phone demo

**Context:** Codex Community Hackathon Hanoi, Sat 14/11/2026, build window 11:00–16:00 (5h). Mobile app where AI is ESSENTIAL (not a bolted-on chatbot). Demo on ONE real Android phone (app killed + reopened, main AI flow live = 40 points); iPhone 11 Pro Max is the backup. Stack: Expo + React Native + TypeScript, Convex primary / Supabase fallback. Four agents (Muse coordinator, Milo, Mie, Migga) + four humans.

**Date accessed:** 2026-11-13 for all claims in this report unless stated otherwise (2026-11-12 for claims carried from the 12/11 reports). Labels: OFFICIAL = vendor's own docs; SECONDARY = everything else. Anything not read is marked CHƯA ĐỌC.

**Builds on (does not redo):** `research_notes/mobile-agent-toolkit-20261112/report.md` (the 12/11 pick: Expo Go + Metro tunnel, SDK 57), `research_notes/backend-agent-toolkit-20261112/report.md` (Convex primary, Supabase fallback), `FLEET-MODE.md` (vertical slices, walking skeleton, 5h clock), the buffet-run GOAL.md.

---

## 0. Headline — two decisions that CHANGE the 12/11 plan

### 0.1 The SDK trap has flipped: scaffold SDK 58, not SDK 57 — gated by tonight's phone check

The 12/11 report said "scaffold SDK 57 unless the run-start check proves the store Expo Go is SDK 58", because Expo Go for SDK 58 was "within a few weeks" of release. That window has now elapsed:

- Latest SDK today is **58.0.0** (RN 0.88, React 19.3.0, min Node 22.13.x). SDK 57 = RN 0.86, React 19.2.3. (OFFICIAL — https://docs.expo.dev/versions/latest/, accessed 2026-11-13)
- Store Expo Go is now **58.0.5**: Google Play "Updated on Oct 19, 2026" (Play page itself shows no version string — see §8); AppBrain (Play mirror): "The latest version available is 58.0.5. The last update was on October 19, 2026." (SECONDARY — https://www.appbrain.com/app/expo-go/host.exp.exponent); APKMirror: Expo Go 58.0.5, uploaded 22 Oct 2026. (SECONDARY — https://www.apkmirror.com/apk/expo-project/expo-go/)
- The rule is exact-match, not minimum-version: "Each build of Expo Go includes one Expo SDK version. The `expo` package version in package.json sets the project's SDK version. The project and Expo Go SDK versions must match." Mismatch shows `Project is incompatible with this version of Expo Go`. (OFFICIAL — https://docs.expo.dev/troubleshooting/expo-go-version-mismatch/, accessed 2026-11-13)

**Consequence:** a fresh SDK 57 project is now the one that will FAIL in a store-updated Expo Go. **Default: scaffold SDK 58** (`npx create-expo-app@latest my-app --template tabs@sdk-58 --yes`), then verify the `expo` entry in `package.json` is major 58 — fresh templates pin `~58.0.x` (e.g. `~58.0.25`, tilde, patch-pinned), NOT `^58.0.0`; a correct scaffold FAILS a literal `^58.0.0` check, so do not "re-pin" a good project on Friday night — and verify on the actual phone tonight (see §3 decision tree).

**Honest conflict, stated plainly:** the official create-a-project page (updated 2026-11-02) still says *"During the SDK 58 transition period, `create-expo-app@latest` without the `--template` flag creates an SDK 57 project. If you plan to use Expo Go on a physical device, use an SDK 57 project."* (OFFICIAL — https://docs.expo.dev/get-started/create-a-project/) And the counter-evidence is stronger than a stale page: the SDK 58 upgrade blog (published 2026-10-21) still says "**The new Expo Go comes to the App Store and Google Play in the next few weeks**, and it supports only SDK 58… **use a development build to run your new project. If you want to stay on Expo Go until the new version ships, pick SDK 57**." (OFFICIAL — https://expo.dev/blog/how-to-upgrade-to-sdk-58) The SDK 58 changelog **still says today**: "Expo Go for SDK 58 on the Apple App Store and Google Play Store will be released within a few weeks." (OFFICIAL — https://expo.dev/changelog/sdk-58) So the flip is NOT settled by the docs — three independent store mirrors agreeing on 58.0.5 + dates is strong, but the official pages still point the other way. Expo's own troubleshooting page is also stale in the other direction — it still says "Expo Go on the Apple App Store stops at SDK 54" (updated 2026-09-03), which the 58.0.5 App Store listing contradicts. **Expo docs lag the stores in both directions; the phone itself is the arbiter.** The decision tree in §3 is built so that either store reality leads to a working setup — never trust a docs page over the phone in front of you.

**SDK 58 costs if you go 58 (know them, don't fear them):** RN 0.86 → 0.88, Strict TypeScript API now default, `InteractionManager` / `Touchable` root export / `Modal animated` prop / some `StatusBar` props removed, `ImageBackground` deprecated, `File.write()` now async, libSQL removed from `expo-sqlite`, R8 on by default in Android release builds, Node ≥22.13 (22 line) / ≥24.3 (24 line) / 26+. (OFFICIAL — https://expo.dev/changelog/sdk-58 and https://expo.dev/blog/how-to-upgrade-to-sdk-58, accessed 2026-11-13) Check `node -v` tonight — a Node 20 machine will fail an SDK 58 scaffold in a confusing way.

**Fallback that keeps SDK 57 viable:** `npx expo-go download android 57` sideloads the exact SDK 57 Expo Go APK (official `expo-go` CLI — https://github.com/expo/expo-go-cli). Android APKs cache under `~/.expo/android-apk-cache`. Use it only if the phone cannot be moved to Expo Go 58.

### 0.2 The demo vehicle: build a preview APK TONIGHT — Expo Go is for iteration, not for the judged kill-and-reopen

The 12/11 plan made Expo Go the demo path. That still works, but it has a structural weakness the judges will hit: in Expo Go the phone reloads JS from Metro on every reopen, so a dead laptop, dead tunnel, or dead venue Wi-Fi at 16:15 = a blank screen in front of the judges. A preview/release build embeds the JS in the binary: "In production apps, there is one main.js bundle that is shipped with the app itself." (OFFICIAL — https://docs.expo.dev/develop/development-builds/faq/, accessed 2026-11-13) Kill-and-reopen on a preview APK works with Metro dead — only the AI call still needs internet (Convex/Supabase + LLM). (Citation correction: the preview-builds tutorial at https://docs.expo.dev/tutorial/cicd/preview-builds/ is about Expo Workflows PR previews — it needs `expo-updates` configured and its "no dev server" line is about PR reviewers, not the embedded bundle. Do not follow that page as the preview-build guide.)

**Recommendation (bold, evidenced):** build the preview APK tonight (Friday evening), install it on the demo Android phone, and kill-and-reopen-test it twice tonight. Use Expo Go + Metro for iteration all day Saturday; run the judged demo on the preview APK. If a last-minute JS fix is needed Saturday, rebuild the preview APK only if the queue allows — otherwise fall back to Expo Go + Metro (see §3).

---

## 1. Hour-by-hour phone plan

### Before 11:00 — tonight (Fri) + Sat 09:00–11:00

| Check | Exact action | Pass |
|---|---|---|
| Expo Go version on the phone | Settings → Apps → Expo Go → version at the bottom; record the number | Version recorded; SDK decision made per §3 (58.x → SDK 58; 57.x → update Expo Go or scaffold 57) |
| Scaffold opens on the phone | `npx create-expo-app@latest my-app --template tabs@sdk-58 --yes`, `npx expo start --tunnel`, scan QR in Expo Go | App opens, no "incompatible" error |
| Kill-and-reopen ×2 (Expo Go) | Swipe the app away from Recents → reopen from Expo Go → main screen loads | Loads from cold twice |
| Tunnel from a non-home network | Start Metro with `--tunnel` on a network that is NOT the home Wi-Fi (phone hotspot, or venue-like network); scan + load | Loads; note the slowness vs LAN |
| Mobile-data AI call | With the backend live, Wi-Fi OFF on the phone (mobile data on), run one full AI request end-to-end | Streamed answer completes on mobile data alone — proves the backend URL is public, not a LAN address |
| Preview APK built + installed | `eas build --profile preview --platform android` (see §2 — including the EAS env-var step, or the APK ships without the backend URL), install APK, kill-and-reopen ×2 | Opens cold twice with Metro STOPPED **and the AI flow completes end-to-end with Metro stopped** (cold-open alone does NOT prove the demo works — the backend URL must be baked into the cloud build) |
| Laptop ready | Charger packed, sleep disabled, `node -v` ≥22.13, Metro + `npx convex dev` both start cleanly | Both processes run; no auth prompts pending |
| Expo Go frozen | Do NOT update/install Expo Go again after tonight's test without re-testing the scaffold immediately after | Version tonight = version Saturday morning |

### At 13:00 — T+2:00, the halfway checkpoint

- **The real AI flow must be live on the real phone, twice in a row, on the demo input, over mobile data.** This is the 40-point artefact; it must exist by halfway (FLEET-MODE §6). Test it on the preview APK if one exists for the current build, otherwise Expo Go + tunnel.
- Kill-and-reopen the app on the phone, then run the full AI flow again from cold. If it fails, the next 30 minutes are debugging the demo path only — no new features.
- **Decision point:** if the AI flow is not green at 13:00, cut Slice 2 entirely and harden Slice 1. Do not let the schedule slip for a second feature.
- Confirm the demo script's exact taps still match the build (screens renamed? flow reordered?). The demo script is the contract; the build follows it, not the reverse.

### At 15:00 — T+4:00, agents stop building

- **Agents stop.** No code changes after 15:00 except fixes the humans direct, one at a time, through the coordinator. Hard stop 15:30.
- Humans verify kill-and-reopen on the real phone (preview APK), rehearse the 5-minute pitch twice, record the backup video of the live flow.
- Final checks: backup recording exists; demo script + evidence artefact + share link ready; the phone is charged and on mobile data as well as venue Wi-Fi; Metro laptop is on charger with sleep disabled (only needed if the demo falls back to Expo Go).
- **Do not start any EAS build after 15:00.** A free-tier build started at 15:00 can still be queued at 16:00. The build on the phone at 15:00 is the build that demos.

---

## 2. Scaffold command sequence + repo layout

### 2.1 From zero to a phone-openable app (SDK 58 default)

```bash
# 0. Prerequisites — tonight, on the build laptop
node -v            # must be >= 22.13 for SDK 58 (OFFICIAL — https://expo.dev/changelog/sdk-58)
npm i -g eas-cli @expo/ngrok   # ngrok global install is required for --tunnel (OFFICIAL — https://docs.expo.dev/more/expo-cli/)
eas login          # Expo account needed before any build; the first build also prompts for project linking + Android keystore generation — do this tonight, not Saturday

# 1. Scaffold — pin the SDK explicitly, never bare `npx create-expo-app@latest`
npx create-expo-app@latest my-app --template tabs@sdk-58 --yes
cd my-app
# Verify the pin: package.json "expo" must be major 58 (fresh templates pin ~58.0.x, e.g. ~58.0.25 — NOT ^58.0.0)
eas build:configure   # creates eas.json; run once before the first build

# 2. Minimal dependency set (none of these needs a dev build — see §2.2)
npx expo install expo-router expo-image expo-secure-store expo-linking
npm install zustand @tanstack/react-query convex
# Supabase fallback only (not both): npx expo install @supabase/supabase-js @react-native-async-storage/async-storage react-native-url-polyfill

# 3. Backend — Convex primary
npx convex dev   # prompts GitHub login, creates project + convex/ folder, keeps running to sync functions
# CRITICAL for the cloud-built preview APK: .env.local is NOT available to remote EAS builds
# ("These files are generally excluded from the project's version control… so they are not
#  available for jobs that run on a remote server, for example, Expo Build" — OFFICIAL, https://docs.expo.dev/eas/environment-variables/)
# Run ONE of these so the preview APK ships with the backend URL, or the AI call fails with EXPO_PUBLIC_CONVEX_URL === undefined:
eas integrations:convex:connect   # writes EXPO_PUBLIC_CONVEX_URL to .env.local AND to EAS env vars (OFFICIAL — https://docs.expo.dev/guides/using-convex/)
# OR: eas env:set EXPO_PUBLIC_CONVEX_URL <url> --environment preview  (and add "environment": "preview" to the preview profile in eas.json)
# The phone reaches Convex over the public internet — no tunnel needed for the backend

# 4. Start Metro and open on the phone
npx expo start --tunnel
# Scan the QR inside Expo Go (Android). First try on the same Wi-Fi is LAN; --tunnel crosses networks and is slower.
```

Template contents: the default/tabs template ships Expo Router + TypeScript; entry is `app/_layout.tsx` (no `App.js`); `app/` = file-based routes, `components/` = non-routes, `assets/`, `app.json`, `tsconfig.json`. (OFFICIAL — https://docs.expo.dev/get-started/create-a-project/, accessed 2026-11-13) SDK 58 rename to know: `expo-router/unstable-native-tabs` → `expo-router/native-tabs` (OFFICIAL — https://expo.dev/blog/how-to-upgrade-to-sdk-58). The template is fine, but agents hand-writing tab code from SDK 57 memory will break.

### 2.2 What needs a dev build vs what works in Expo Go (SDK 57/58)

Expo Go is "a playground app… comes with a fixed set of native libraries built in". A development build is "a fully featured development environment" — your own debug binary with `expo-dev-client`. (OFFICIAL — https://docs.expo.dev/develop/development-builds/faq/, accessed 2026-11-13) Any library with native code not already in Expo Go fails at runtime — e.g. `react-native-webview` IS included in Expo Go, `react-native-firebase` is NOT and "will immediately error… There is no way to get the native code into the Expo Go app unless it was already included in the bundle that was uploaded to the app stores." (Same source.)

**In Expo Go (no dev build):** `expo-router`, `expo-image` (Included in Expo Go, `~57.0.5` — OFFICIAL — https://docs.expo.dev/versions/v57.0.0/sdk/image/), `expo-secure-store` (badge "Included in Expo Go", ~57.0.4 — verified by a red-team read of the official SDK page, 2026-11-13), `zustand` + `@tanstack/react-query` (pure JS, no native code), `convex/react` (Convex quickstart is `npx create-expo-app` + `npm install convex`, no dev-build step — OFFICIAL — https://docs.convex.dev/quickstart/react-native), `@supabase/supabase-js` + AsyncStorage + `react-native-url-polyfill` (Supabase quickstart ends "Run the development server and scan the QR code with the Expo Go app" — OFFICIAL — https://supabase.com/docs/guides/getting-started/quickstarts/expo-react-native), `react-native-reanimated` + `react-native-gesture-handler` + `react-native-screens` + `expo-image-picker` (per a secondary audit of `expo@57.0.23 bundledNativeModules.json` — audit-only, the file was not read directly; spot-check by import tonight) + `expo-camera` (badge "Included in Expo Go", ~58.0.14 — verified by a red-team read, 2026-11-13).

**Needs a dev build:** any custom native module, `@react-native-firebase/*`, any library with a config plugin that adds native code, remote push notifications, custom-scheme deep links that need your own bundle ID, testing your own icon/name/splash (native assets are immutable once installed in Expo Go), App Links / Universal Links. (OFFICIAL — https://docs.expo.dev/develop/development-builds/faq/)

**Conflict to test, not to trust:** one SDK 57 cookbook says `react-native-maps` and Skia "need a development build" / "Not supported" in Expo Go (SECONDARY — https://reactnative.codeguides.io/media-camera/media-basics/), while the bundled-modules audit above says both ARE in Expo Go. `bundledNativeModules.json` itself was not read directly. **Rule: if the idea needs maps or Skia, test the import on the phone tonight; if it errors, cut the library or build a dev build tonight — never discover it at 11:00.**

**Dev build command (only if needed):** `eas build -p android --profile development` with an `eas.json` development profile (`developmentClient: true`, `distribution: internal`, `android: { buildType: apk }` — Android output must be `.apk`; default `.aab` cannot be installed on a device) and `expo-dev-client` installed. (OFFICIAL command form — https://docs.expo.dev/tutorial/eas/android-development-build/; apk note per worker verification 2026-11-13.)

**Preview build command (the demo vehicle, §0.2):** `eas build --profile preview --platform android` with `"preview": { "distribution": "internal", "android": { "buildType": "apk" } }` in `eas.json`. Install the APK on the phone (sideload — see trap #10).

### 2.3 Repo layout (product repo — recommendation, not a doc claim)

```
my-app/
  app/                 # Expo Router routes: _layout.tsx, (tabs)/, + feature screens
  components/          # reusable UI (not routes)
  lib/                 # convex client helper, query client, store setup, supabase.ts (fallback only)
  convex/              # schema.ts, actions (AI call server-side), _generated/
  assets/              # icon, splash, images
  app.json  eas.json  .env.local (gitignored)  CONTRACT.md  docs/demo-script.md
```

File ownership (4 agents, one owner per directory — FLEET-MODE §7): Frontend owns `app/` + `components/`; Backend owns `convex/` (+ `lib/supabase.ts` fallback); QC owns `CONTRACT.md` + `docs/demo-script.md` + the kill-and-reopen checklist; the 4th agent floats (demo phone + Metro/tunnel operator). No cross-edits without a PR/mention. `CONTRACT.md` at repo root; demo script at `docs/demo-script.md` — both versioned, both read aloud once before 16:00.

### 2.4 Convex + Expo wiring (primary) and Supabase fallback

**Convex:** `npx convex dev` prompts GitHub login, creates a project, saves production + deployment URLs, creates a `convex/` folder, and keeps running to sync functions to the cloud dev deployment. (OFFICIAL — https://docs.convex.dev/quickstart/react-native, accessed 2026-11-13) Client in `app/_layout.tsx`:

```ts
import { ConvexProvider, ConvexReactClient } from "convex/react";
const convex = new ConvexReactClient(process.env.EXPO_PUBLIC_CONVEX_URL!, { unsavedChangesWarning: false });
// wrap the tree in <ConvexProvider client={convex}>
```

Shortcut: `eas integrations:convex:connect` installs `convex` and writes `EXPO_PUBLIC_CONVEX_URL` to `.env.local` and Expo env vars. (OFFICIAL — https://docs.expo.dev/guides/using-convex/) **The phone needs nothing special for the backend:** the deployment URL is a public `https://<deployment>.convex.cloud` URL — internet only, no tunnel/LAN for backend calls. `npx convex dev` must stay running on the laptop while editing backend functions, or function changes do not sync.

**Supabase (fallback), one paragraph:** install per the current quickstart — **verify against the live page / Connect panel tonight rather than installing blind**: the current quickstart (updated 2026-10-22) now says "The code below uses **Expo's localStorage polyfill** to persist authentication sessions", pointing away from the AsyncStorage adapter the older guides prescribed, so the older dependency list (`@supabase/supabase-js` + `@react-native-async-storage/async-storage` + `react-native-url-polyfill`) may be outdated. Create `lib/supabase.ts` with `createClient(process.env.EXPO_PUBLIC_SUPABASE_URL, <publishable key>, …)`; `EXPO_PUBLIC_` prefix required for Expo to expose env vars. The Supabase URL is a public hosted URL — same as Convex, no tunnel needed for the backend. Never put the service-role key in the app. (OFFICIAL — https://supabase.com/docs/guides/getting-started/quickstarts/expo-react-native, accessed 2026-11-13; code blocks were stripped in the fetch — exact install/client lines rest on the search snippet + GitHub docs mirror, see §8.) **Key-name warning:** older docs/examples use `EXPO_PUBLIC_SUPABASE_ANON_KEY`, newer quickstart uses `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY`. Copy the exact names from the project's Dashboard → Connect panel tonight; do not guess.

---

## 3. Decision tree — Expo Go vs dev build (exact checks)

```
START TONIGHT, on the exact demo Android phone
│
├─ 1. What Expo Go version is installed?
│    Settings → Apps → Expo Go → version at the bottom
│    ├─ 58.x  → scaffold SDK 58 (default@sdk-58 / tabs@sdk-58). Go to 2.
│    ├─ 57.x  → EITHER update Expo Go via Play Store to 58.0.5, then scaffold SDK 58;
│    │           OR scaffold SDK 57 and FREEZE Expo Go (no Play update Saturday).
│    │           Decide once, record it, do not flip-flop.
│    └─ not installed → install from Play Store (will be 58.0.5) → scaffold SDK 58.
│
├─ 2. Does the idea need a native module outside Expo Go's fixed set?
│    (custom native code, @react-native-firebase/*, config plugin adding native code,
│     remote push, custom-scheme deep link needing your own bundle ID,
│     react-native-maps / Skia IF tonight's import test fails)
│    ├─ NO  → Expo Go path. Go to 3.
│    └─ YES → dev build TONIGHT: eas build -p android --profile development
│             (developmentClient: true, distribution: internal, buildType: apk).
│             Install the dev APK, verify `npx expo start --dev-client` opens it.
│             Keep Expo Go as the live fallback. Go to 3.
│
├─ 3. Build the preview APK TONIGHT (always, either path):
│    eas build --profile preview --platform android
│    (distribution: internal, buildType: apk). Install, kill-and-reopen ×2
│    with Metro STOPPED. If it opens cold twice, the judged demo has a
│    Metro-independent vehicle. If the EAS queue is long, start it FIRST
│    tonight and keep iterating in Expo Go while it builds.
│
└─ 4. SATURDAY MORNING re-verification (09:00–11:00, before the window):
     open the scaffold on the phone. If "Project is incompatible with
     this version of Expo Go": check the Expo Go version FIRST — did it
     auto-update overnight? Then sideload the matching Expo Go APK
     (npx expo-go download android <sdk>) — the supported recovery.
     Downgrading the project (npx expo install expo@^57.0.0 --fix) is NOT
     a documented recovery — the mismatch page offers only a compatible
     Expo Go or an UPGRADE — so treat a downgrade as a last resort and
     expect breakage (RN 0.88→0.86 + all expo packages).
     Do NOT debug anything else until the SDK versions match.
```

**EAS free-tier numbers (SECONDARY, citing expo.dev/pricing — pricing page not opened directly, see §8):** 15 Android + 15 iOS builds/month, low-priority queue, 1 concurrent build, 45-minute build timeout; no overage on Free — when quota is used, builds wait until the 1st of next month. "At peak times, you may experience wait times of 90+ minutes with the low-priority queue", vs ~zero target on paid high-priority queue. Peak = middle of US business day. Android build itself typically 10–20 min (first build 10–30+ min incl. queue + download + install); with a free-tier queue at peak, total can exceed 2 hours. (SECONDARY — https://cadrant.ai/blog/eas-build; https://newly.app/guides/eas-build) **Rule: never depend on a mid-window cloud build. The build on the phone at 15:00 is the build that demos.**

**Creative workaround for the queue (untested here — test tonight, don't assume):** `eas build --local` runs the same pipeline on your own machine and bypasses the cloud queue, but needs Android Studio + JDK installed. SECONDARY only, not verified in this pass — if the laptop has Android Studio, try it tonight on a throwaway profile; if it works, it is the fastest rebuild path on Saturday.

---

## 4. Top 10 traps — what breaks at demo time, and the fix

| # | Trap | What breaks at demo time | Fix |
|---|---|---|---|
| 1 | **SDK mismatch — the flipped trap** | `Project is incompatible with this version of Expo Go`; the app will not open at all. Store Expo Go is 58.0.5; an SDK 57 project fails in it (and vice versa — exact match, not minimum). | §3 step 1 tonight: record the phone's Expo Go version, scaffold the matching SDK, verify `expo` in `package.json`. Never bare `npx create-expo-app@latest` — pin `--template tabs@sdk-58` (or `@sdk-57` if the phone is 57). |
| 2 | **Expo Go auto-updates on Saturday morning** | Friday's working setup breaks overnight: Play auto-updates Expo Go 57 → 58, the SDK 57 project stops opening at 09:00, and the team debugs the wrong thing. | Freeze Expo Go after tonight's test. Do NOT update/install Expo Go on Saturday without re-testing the scaffold immediately after. Record the version number in the run log tonight. |
| 3 | **Metro dies / tunnel drops mid-demo (Expo Go)** | The phone cannot fetch the bundle — "Something went wrong" / `exp://… could not be loaded`. Recovery is restart Metro + re-scan — minutes, not seconds, in front of judges. | Demo on the preview APK (§0.2) — JS is embedded, Metro-independent. Keep the laptop on charger, sleep disabled, Metro running as backup. Recovery: `npx expo start --tunnel --clear` and re-open. |
| 4 | **Tunnel ngrok limit — no SLA** | Tunnel uses Expo's shared ngrok authtoken; in Feb 2026 it hit ngrok's 5,000 simultaneous-session limit and failed for many devs at once; an Expo maintainer called it "neither a paid service (no service-level guarantees), nor meant as a permanent solution". Saturday is a hackathon day globally. Tunnel reloads are also "considerably slower than on LAN or Local". (SECONDARY — https://www.localcan.com/blog/react-native-expo-localcan-tutorial) | LAN first at the venue (same Wi-Fi, device-to-device traffic allowed); tunnel only if LAN/QR fails. There is NO automatic fallback — LAN / localhost / tunnel are explicit flags, you must stop and restart with a different flag. Preview APK is the ultimate fallback (no Metro at all). Check ngrok status at https://status.ngrok.com if the tunnel fails. |
| 5 | **EAS free queue eats the window** | A build started at 14:00 can still be queued at 16:00 (90+ min at peak, 1 concurrent build, 45-min timeout). | Never start a cloud build mid-window. Build the preview APK tonight; if a Saturday rebuild is unavoidable, start it the moment the native set freezes and keep Expo Go as the live demo path meanwhile. |
| 6 | **Streaming silently doesn't stream (Hermes)** | No throw, no warning — the request resolves once with the whole answer. The UI shows nothing for seconds, then the full text appears at once; token streaming "silently ceases to exist while every assertion about the final text still passes". Cause: React Native's built-in (global) fetch is an XHR polyfill with no `response.body`; `expo/fetch` is native-backed and streams. Correction to the usual telling: `EXPO_PUBLIC_USE_RN_FETCH=1` only restores the XHR fetch as the GLOBAL fetch — "Named imports from `expo/fetch` continue to work regardless of this flag" (OFFICIAL `expo/fetch` API — https://docs.expo.dev/versions/latest/sdk/expo/). So the flag cannot break the named import; the danger is agents using the global fetch (or code that captured the old global). XHR-polyfill mechanism SECONDARY — https://github.com/ankur2194/knowledgebot-ai/blob/HEAD/.claude/skills/expo-react-native/SKILL.md | Always use the named `import { fetch } from 'expo/fetch'` for every AI call; never rely on the global fetch for streaming; assert `res.body !== null` in a smoke test — a final-text-only test cannot catch this. |
| 7 | **`localhost` API URL** | Works on the simulator, fails on the phone: `localhost` on the phone is the phone itself. The AI call fails with a network error in front of the judges. | API base URL = public Convex/Supabase URL (or LAN IP / tunnel URL for a local server), never `localhost`. Prove it with the Wi-Fi-off mobile-data test (§1). |
| 8 | **Remote push in Expo Go is dead (SDK 53+)** | `expo-notifications` remote push "is unavailable in Expo Go on Android from SDK 53. A development build is required… Local notifications (in-app notifications) remain available in Expo Go." (OFFICIAL — https://docs.expo.dev/versions/v57.0.0/sdk/notifications/) A push-based demo flow simply never fires. | CUT remote push (§5). Local notifications only (`scheduleNotificationAsync`), if a reminder demo is wanted — cheap, no FCM, no build. |
| 9 | **OTA two-cold-boots trap** | EAS Update downloads in the background on launch and applies on the NEXT restart — a 15:30 "fix" needs two cold boots to appear, and on the Expo Go path OTA does nothing at all for the running Metro bundle. Wrong channel, wrong runtimeVersion, or a native-dep change silently = stale build on stage. | CUT EAS Update as a 15:30 lever (§5). On the Expo Go path, Metro reload is the fix lever. Only use OTA if the demo runs on a pre-built binary with channel + runtime pinned — and verify the fix with two cold restarts well before 16:00. |
| 10 | **Deep-link scheme + sideload friction** | Custom scheme (`myapp://`) needs a dev build — in Expo Go the link form is `exp://<metro-host>:8081/--/path`, and Metro must be alive. Separately, sideloading the preview APK hits Android's unknown-source gate + a Play Protect scan warning; camera/mic permissions declared at build time only take effect after a rebuild (in Expo Go you get Expo Go's own permission text). | Use the right link form per vehicle (Expo Go: `exp://…/--/ai`; dev/preview: `myapp://ai`, scheme in `app.json`). Test with `npx uri-scheme open <url> --android` (package-scheme form verified verbatim — OFFICIAL — https://docs.expo.dev/linking/into-your-app/; the `exp://` + `--android` combination is the direct analogue of the documented `--ios` example, not verbatim verified). For sideload: allow time for the Play Protect screen; or `adb install <file>.apk` with USB debugging (bypasses the on-phone toggle). Declare camera/mic permissions BEFORE building. |

---

## 5. Push notifications + OTA updates — verdicts (cut both, keep the cheap parts)

### Push notifications — CUT remote push

- Remote push is unavailable in Expo Go on Android from SDK 53 (trap #8). A dev build is required, and FCM setup is the real cost driver: create a Firebase project → generate a Google Service Account Key → upload via `eas credentials` (Android > Google Service Account Key for Push Notifications, FCM V1) → download `google-services.json`, place at project root, set `expo.android.googleServicesFile` in `app.json`. "This file is required for your Android app to be registered with FCM." Mismatched sender ID / restricted API key → `403 PERMISSION_DENIED`, no push token. (OFFICIAL — https://docs.expo.dev/push-notifications/fcm-credentials/, accessed 2026-11-13) Android 13+ needs a runtime permission prompt, and a notification channel must be created via `setNotificationChannelAsync` before `getDevicePushTokenAsync` / `getExpoPushTokenAsync`, or no token is issued. (OFFICIAL — https://docs.expo.dev/versions/v57.0.0/sdk/notifications/)
- **Time cost (judgement, not a doc claim):** Firebase + EAS credentials + first cloud build + token debugging is realistically 60–120 min first time, with queue time unverified. No doc gives a push-specific time.
- **Verdict:** CUT remote push. It forces a dev build, breaks the Expo Go + Metro `--tunnel` primary demo path, and earns 0 of the 40 demo points (the AI flow is the scorer). **Local notifications only** (`scheduleNotificationAsync`, works in Expo Go) if a reminder demo is wanted — cheap, no FCM, no build.

### EAS Update (OTA) — TRAP as a 15:30 fix lever on the Expo Go path

- Setup: `eas update:configure` installs `expo-updates`, sets `updates` + `runtimeVersion` in app config, adds a `channel` per build profile in `eas.json` (profile name = channel name by default). Publish: `eas update --channel [channel] --message "[msg]" --environment [env]` — `--environment` is required in SDK 55+. (OFFICIAL — https://docs.expo.dev/eas-update/getting-started/, accessed 2026-11-13)
- What it updates: JS, styling and image assets only — "Fixing bugs and quickly updating non-native parts of a project instead of creating a new build". Native code, new native modules, permissions, SDK upgrades, icon/splash need a new `eas build`. Build and update must match on platform AND `runtimeVersion` exactly. (OFFICIAL — https://docs.expo.dev/eas-update/getting-started/ and https://docs.expo.dev/eas-update/how-it-works/) Correction: neither cited page states the default `runtimeVersion` policy, and the fingerprint policy is NOT "experimental" — the runtime-versions page presents it positively ("If you want to make incompatible updates extremely unlikely… use the `fingerprint` policy" — OFFICIAL — https://docs.expo.dev/eas-update/runtime-versions/). Read the actual `runtimeVersion` value in `app.json` tonight; do not assume it.
- **The trap:** by default it checks for an update when the app opens; if one is found it downloads in the background and runs on the NEXT launch. Expo's own download guide: the user "will only load the update when they cold boot the app after an update has been published, and then at some point kill and restart the app" — i.e. **two cold boots** to see a fix. (Nuance: if the manifest + assets download within `fallbackToCacheTimeout`, the update runs on first launch — but the default timeout is 0, so the two-boot case is the default.) (OFFICIAL — https://docs.expo.dev/eas-update/how-it-works/ and https://docs.expo.dev/eas-update/download-updates/) A manual fast path exists (`Updates.checkForUpdateAsync()` → `fetchUpdateAsync()` → `reloadAsync()`), but only in a real build.
- **Expo Go limitation:** the `expo-updates` page header says "Included in Expo Go", but "most of the Updates API is unavailable when running in Expo Go" and testing an update there "only simulates what an update will look like". `checkForUpdateAsync()` "rejects in Expo Go or if the app is in development mode." In dev builds most of the Updates API is also unavailable; the full API only works in release builds. (OFFICIAL — https://docs.expo.dev/versions/v57.0.0/sdk/updates/)
- **Verdict: DO NOT rely on it at 15:30.** On the Expo Go + Metro path, OTA does nothing for the running Metro bundle — Metro reload is faster and certain. EAS Update is useful ONLY if the demo runs on a pre-built dev/preview/release build with `expo-updates` baked in, channel + runtime pinned, and the fix is published + verified with two cold restarts well before 16:00. Free Update limits (SECONDARY, citing expo.dev/pricing): 1,000 MAU, 100 GiB bandwidth — irrelevant at hackathon scale (1 phone).

---

## 6. Creative workarounds — bold, but evidenced

1. **Preview APK as the demo vehicle (§0.2).** The single biggest robustness upgrade over the 12/11 plan. Evidence: a release build ships its JS bundle with the app, so no dev server is needed at demo time (OFFICIAL — https://docs.expo.dev/develop/development-builds/faq/).
2. **Sideload the exact Expo Go for your SDK** (`npx expo-go download android 57|58`). If the phone's Play Store is slow, the account can't update, or the team deliberately stays on SDK 57, the matching Expo Go APK removes the store from the critical path. (OFFICIAL CLI — https://github.com/expo/expo-go-cli)
3. **Deep-link entry to the AI flow.** Ship a deep link as a second entry point so the judged reopen lands directly on the AI flow — `myapp://ai` (dev/preview build, scheme in `app.json`) or `exp://<metro-host>:8081/--/ai` (Expo Go). Saves taps in the 5-minute pitch and removes one human-error step. Pre-seed the AI flow's state in AsyncStorage so the reopen shows the last good result instantly — **but label it honestly as cached/offline with a retry button; never present cached output as a live AI result.** AsyncStorage is "an asynchronous, unencrypted, persistent key-value storage… a good choice for storing… user preferences or app state" and survives kill-and-reopen. (OFFICIAL — https://docs.expo.dev/develop/user-interface/store-data/) In-memory state (React state/Context/Zustand without persist) is gone on kill — a killed app relaunches with a fresh JS runtime; only disk-persisted state survives.
4. **Two-phone redundancy.** Run the same SDK's Expo Go on the Android demo phone AND the iPhone 11 Pro Max backup, and check both versions tonight. If the Android phone dies, the iPhone runs the same project with zero rework — but only if both Expo Go builds are the same SDK (exact-match rule applies per phone).
5. **`eas build --local` as a queue bypass.** If the laptop has Android Studio + JDK, the local build runs the same pipeline on your own machine and skips the cloud queue. SECONDARY only, not verified in this pass — test tonight on a throwaway profile; if it works, it is the fastest Saturday rebuild path.
6. **The Wi-Fi-off test as the acceptance test.** At 13:00 and 15:00, run the AI flow with venue Wi-Fi OFF (mobile data on). If it passes, the demo survives the venue network failing — the most likely live-demo failure after the SDK trap. If it fails, the backend URL is a LAN/localhost address and must be fixed before anything else.
7. **Same Expo account in CLI and Expo Go.** Since 3 Sep 2026 Expo requires the same Expo account in the CLI and in Expo Go on physical iPhone for SDK 57; Android was said to get the same rule "later". (SECONDARY — https://cadrant.ai/blog/expo-go) Do not assume it applies to Android tomorrow — sign in with the same account anyway. It costs 30 seconds and removes a whole failure class.

---

## 7. Pre-event phone checklist — tonight (Fri 13/11, exact Android phone)

- [ ] Expo Go version recorded (Settings → Apps → Expo Go). SDK decision made per §3 and written in the run log.
- [ ] `eas login` done; `eas.json` created via `eas build:configure`; Android keystore generated (first-build prompt handled tonight, not Saturday).
- [ ] `node -v` ≥ 22.13 on the build laptop (SDK 58 requirement).
- [ ] Scaffold opens on the phone (pinned `--template tabs@sdk-58`, or `@sdk-57` if the phone is 57). No "incompatible" error.
- [ ] Kill-and-reopen ×2 in Expo Go (swipe from Recents → reopen → main screen loads from cold).
- [ ] Tunnel QR scan works from a non-home network; note tunnel slowness; LAN is first try at the venue.
- [ ] AI flow runs end-to-end on mobile data (Wi-Fi OFF). Streamed answer completes — proves the backend URL is public.
- [ ] Preview APK built tonight, installed, kill-and-reopen ×2 with Metro STOPPED.
- [ ] `EXPO_PUBLIC_CONVEX_URL` set; phone loads Convex data (or Supabase fallback — key names copied from Dashboard → Connect, not guessed).
- [ ] Streaming smoke test: `import { fetch } from 'expo/fetch'` in the AI call; `res.body !== null` asserted; never rely on the global fetch for streaming (the `EXPO_PUBLIC_USE_RN_FETCH=1` flag only affects the global fetch, not the named import).
- [ ] Deep link tested: `npx uri-scheme open <url> --android` lands on the AI flow.
- [ ] If a local notification is kept: notification permission granted on Android 13+, one fires in Expo Go.
- [ ] If EAS Update is attempted at all: channel + runtimeVersion confirmed in the Expo dashboard, a trivial text change published, verified after two cold restarts. If that fails once, abandon OTA and use Metro.
- [ ] Expo Go NOT updated/installed again after tonight's test without re-testing the scaffold immediately after.
- [ ] Phone charged, charger + cable packed; laptop charger packed; sleep disabled on the laptop.
- [ ] Same Expo account signed in on CLI and in Expo Go.

---

## 8. What could NOT be verified (CHƯA ĐỌC — do not present as read)

- **Store Expo Go version on 2026-11-13 (the headline conflict):** official docs (2026-11-02) still advise SDK 57 for Expo Go on a physical device; secondary mirrors (AppBrain data updated 2026-11-06; APKMirror 22 Oct; vibeview.io checked 2026-11-07) say the stores serve 58.0.5. No live Play Store check returning a version string was done — the fetched Play page shows "Updated on Oct 19, 2026" but no version number. **Must be verified on the phone tonight; the phone arbitrates.**
- **What bare `npx create-expo-app@latest` scaffolds today:** docs (Nov 2) say SDK 57 without `--template`; npm `latest` is `expo@58.0.25` (`npm view expo dist-tags`, checked 2026-11-13). Always pass `--template` explicitly and check `expo` in `package.json` afterwards.
- **expo.dev/go SDK selector contents:** the bare fetched page returned only headings/carousel images (JS-rendered). The parametrized SDK-57 Android page (expo.dev/go?sdkVersion=57&platform=android) was opened live and offers a direct Expo Go .apk download — that part is verified; the full selector table was not read.
- **Exact EAS free-tier numbers** (15+15 builds/month, 90+ min peak queue, 45-min timeout, 1,000 Update MAU): from secondary pages citing expo.dev/pricing (Sep–Nov 2026); the pricing page itself was not opened.
- **Exact wall-clock for `eas build -p android --profile development` on Free tier tonight:** no live build was run; 10–30 min build + up to 90+ min queue is secondary guidance only.
- **`react-native-maps` / Skia in Expo Go SDK 57:** conflicting secondary sources; `bundledNativeModules.json` was not read directly. Test the import on the phone tonight.
- **`expo-secure-store` "Included in Expo Go" badge:** verified — badge "Included in Expo Go", ~57.0.4, read on the official SDK page by the red team 2026-11-13. (This corrects the draft's earlier provenance note.)
- **Supabase quickstart code blocks:** official page text was read, but code blocks were stripped in the fetch; exact install/client lines rest on the search snippet + GitHub docs mirror. The current page (updated 2026-10-22) points to Expo's localStorage polyfill for session persistence, away from the AsyncStorage adapter older guides prescribed — verify the dependency list against the live page tonight. Publishable-key vs anon-key naming must be copied from the Dashboard.
- **Expo Go offline cached bundle:** whether Expo Go reopens the last-loaded JS bundle with Metro/internet fully off. Only a low-quality third-party FAQ claimed it. Treat as unverified — assume Metro must be alive in Expo Go.
- **Expo Go in-app version display:** no official Expo doc found describing where Expo Go shows its own version on the phone; the Settings → Apps check is generic Android procedure, not Expo-verified.
- **Android swipe-vs-force-stop saved-state semantics:** from a third-party testing blog, not developer.android.com (not opened).
- **Battery optimisation / Doze effect on a live Metro tunnel connection:** no official source read; mitigation (foreground, charging, prefer preview APK) is precautionary, not verified.
- **Convex/Supabase offline behaviour and exact mobile-data behaviour of the chosen backend:** not read in this pass; the Wi-Fi-off test is the empirical check, not a doc claim.
- **Exact Play Protect warning text/flow for an EAS preview APK:** not read from an official Google source; expect a scan warning and allow time for it.
- **The `exp://…/--/path --android` form of `uri-scheme open`:** official docs show the `exp://` example with `--ios` only; the `--android` variant is the direct analogue, not verbatim verified.
- **Node minimum:** SDK 57 min Node is 22.13.x per the official versions table (OFFICIAL — https://docs.expo.dev/versions/latest/) — no conflict; SDK 58 needs Node ≥22.13 (22 line) / ≥24.3 (24 line) / 26+ per the changelog.
- **Expo Push Service cost/limits and FCM end-to-end setup time:** FAQ page not opened directly, only via search snippet.
- **Venue Wi-Fi reachability of `*.convex.cloud` / `*.supabase.co` and tunnel reliability:** needs a live test on the phone, cannot be verified from docs.
- **`eas build --local` bypass:** secondary only, not verified in this pass.
- **Background tasks in Expo Go SDK 57:** official confirmation not read; only a secondary project README. Do not demo a background-task flow in Expo Go without a device test.

---

## 9. Sources (all accessed 2026-11-13 unless noted)

**OFFICIAL**
- Expo — SDK version table (SDK 58 latest): https://docs.expo.dev/versions/latest/
- Expo — SDK 58 changelog: https://expo.dev/changelog/sdk-58
- Expo — SDK 57 changelog: https://expo.dev/changelog/sdk-57
- Expo — How to upgrade to SDK 58: https://expo.dev/blog/how-to-upgrade-to-sdk-58
- Expo — Create a project: https://docs.expo.dev/get-started/create-a-project/
- Expo — Expo Go version mismatch troubleshooting: https://docs.expo.dev/troubleshooting/expo-go-version-mismatch/
- Expo — Expo CLI (incl. `--tunnel`, ngrok): https://docs.expo.dev/more/expo-cli/
- Expo — Development builds FAQ: https://docs.expo.dev/develop/development-builds/faq/
- Expo — Development builds introduction: https://docs.expo.dev/develop/development-builds/introduction/
- Expo — Preview builds: https://docs.expo.dev/tutorial/cicd/preview-builds/
- Expo — Android development build tutorial: https://docs.expo.dev/tutorial/eas/android-development-build/
- Expo — EAS Update getting started: https://docs.expo.dev/eas-update/getting-started/
- Expo — EAS Update how it works / download updates / deployment: https://docs.expo.dev/eas-update/how-it-works/ ; https://docs.expo.dev/eas-update/download-updates/ ; https://docs.expo.dev/eas-update/deployment/
- Expo — Notifications SDK (v57): https://docs.expo.dev/versions/v57.0.0/sdk/notifications/
- Expo — Push notification FCM credentials: https://docs.expo.dev/push-notifications/fcm-credentials/
- Expo — Updates SDK (v57): https://docs.expo.dev/versions/v57.0.0/sdk/updates/
- Expo — expo/fetch API: https://docs.expo.dev/versions/latest/sdk/expo/
- Expo — expo-image SDK (v57): https://docs.expo.dev/versions/v57.0.0/sdk/image/
- Expo — EAS Update runtime versions: https://docs.expo.dev/eas-update/runtime-versions/ (opened by red team 2026-11-13)
- Expo — EAS environment variables: https://docs.expo.dev/eas/environment-variables/ (opened by red team 2026-11-13)
- Expo — SecureStore SDK (v57): https://docs.expo.dev/versions/v57.0.0/sdk/securestore/ (badge "Included in Expo Go" verified by red-team read 2026-11-13)
- Expo — Store data (AsyncStorage): https://docs.expo.dev/develop/user-interface/store-data/
- Expo — Deep linking: https://docs.expo.dev/linking/into-your-app/
- Expo — Permissions: https://docs.expo.dev/guides/permissions/
- Expo — Camera SDK: https://docs.expo.dev/versions/latest/sdk/camera/
- Expo — Using Convex: https://docs.expo.dev/guides/using-convex/
- Expo — SDK 53 changelog (push deprecation in Expo Go): https://expo.dev/changelog/sdk-53
- Expo Go CLI (GitHub): https://github.com/expo/expo-go-cli
- Convex — React Native quickstart: https://docs.convex.dev/quickstart/react-native
- Supabase — Expo React Native quickstart: https://supabase.com/docs/guides/getting-started/quickstarts/expo-react-native

**SECONDARY**
- AppBrain — Expo Go Play listing mirror: https://www.appbrain.com/app/expo-go/host.exp.exponent
- APKMirror — Expo Go: https://www.apkmirror.com/apk/expo-project/expo-go/
- VibeView — Expo Go incompatible SDK guide: https://vibeview.io/guides/expo-go-incompatible-sdk/
- LocalCan — Expo tunnel / ngrok limits: https://www.localcan.com/blog/react-native-expo-localcan-tutorial
- Cadrant — Expo Go account rule + EAS Build: https://cadrant.ai/blog/expo-go ; https://cadrant.ai/blog/eas-build
- Newly.app — EAS Build profiles/queues/cost: https://newly.app/guides/eas-build
- Bitrise — CodePush alternatives (EAS Update limits): https://bitrise.io/blog/post/codepush-alternatives
- Codeguides — Expo Router / CLI / templates / OTA: https://reactnative.codeguides.io/expo-router/expo-router-basics/ ; https://reactnative.codeguides.io/expo-cli/local-development-basics/ ; https://reactnative.codeguides.io/project-setup/create-expo-app-templates/ ; https://reactnative.codeguides.io/ota-updates/ota-updates-basics/ ; https://reactnative.codeguides.io/media-camera/media-basics/
- Expo docs preview mirror — Router installation: https://pr-49938.expo-docs.pages.dev/router/installation/
- Launchpad — Expo scaffolder patterns: https://github.com/builtform/launchpad/blob/HEAD/plugins/launchpad/scaffolders/expo-pattern.md
- Expo 57 skill — animation/gesture deps audit: https://github.com/mahdi-salmanzade/expo57-skill/blob/HEAD/expo-57/skills/expo-57/references/17-animation-gesture-deps.md
- Coto2ba — Expo SDK research: https://github.com/nu-chotech/coto2ba-next/blob/HEAD/docs/research/expo-sdk.md
- TestMuAI — Expo Android build time: https://www.testmuai.com/blog/expo-android-setup-build-time/
- Tutorialpedia — Expo "Something went wrong": https://www.tutorialpedia.org/blog/can-t-load-expo-app-something-when-wrong/
- WhistleOut — Android sideloading: https://www.whistleout.com/CellPhones/Guides/how-to-sideload-apps-on-android
- BetaDrop — Safe Android sideloading: https://betadrop.app/blog/safe-android-sideloading-guide/
- FreeVPNPlanet — Install APK on Android: https://freevpnplanet.com/blog/how-to-install-apk-on-android/
- CodeVerse — React Native week 06 (state persistence): https://codeversecreatives.shop/courses/react-native/week-06.html
- Ankur2194 — Expo React Native skill (Hermes fetch): https://github.com/ankur2194/knowledgebot-ai/blob/HEAD/.claude/skills/expo-react-native/SKILL.md
- oRPC — Expo adapter (streaming): https://ab9a1ccc-orpc.dinwwwh.workers.dev/docs/adapters/expo
- Busabase — background tasks note: https://github.com/busabase/busabase/blob/HEAD/apps/busabase-mobile/README.md
- React Native AsyncStorage docs: https://react-native-async-storage.github.io/async-storage/docs/usage/

**Carried from the 12/11 reports (accessed 2026-11-12):** `research_notes/mobile-agent-toolkit-20261112/report.md` and `research_notes/backend-agent-toolkit-20261112/report.md` — stack pick (Expo + RN + TS, Convex primary / Supabase fallback), EAS queue guidance, Hermes streaming trap, key-safety rules.
