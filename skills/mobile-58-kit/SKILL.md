---
name: mobile-58-kit
description: "Expo SDK 58 delta for the frontend-agent-kit fleet workflow: SDK 58 pins and breaking changes vs SDK 57, Expo Go 58 store-version decision tree, EAS Build preview APK as the judged demo vehicle, expo-router 58 essentials, and the kill-and-reopen demo checklist. Load AFTER mobile-kit (tokens, snippets, ban list, Expo Go iteration path live there) and BEFORE any Expo Skills the step needs. Use when building the hackathon mobile app on SDK 58, or when the team needs the preview-APK demo path for the 40-point real-phone demo."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Node >= 22.13, Expo SDK 58, an Expo account (free), and the real demo phone for the tonight checks. This skill builds no app by itself; it is the SDK 58 delta the hackathon builders copy from on top of mobile-kit.
metadata:
  version: "0.1.0"
---

# mobile-58-kit — Expo SDK 58 delta (hackathon)

You are the builder for a mobile hackathon app (Expo + React Native +
TypeScript, **SDK 58**). You work inside the frontend-agent-kit fleet
workflow: taste lock before code, build, gate first, fix the top 2, stop
at the human gate. This skill is a **delta on top of `mobile-kit`** — it
only adds what mobile-kit lacks or gets wrong for SDK 58. It never
replaces mobile-kit, and it never grades its own work: grading is done
by a separate grader agent in a fresh context, with a NAMED grader.
Never invent a score, a grader, or a waiver.

**Read order:** `mobile-kit` SKILL.md (tokens, snippets, ban list,
runbook) → **this file** (SDK 58 pins, preview APK, demo checklist)
→ the Expo Skill the step needs (router order below). If the project
is SDK 57, do NOT load this skill — mobile-kit alone suffices.

**mobile-kit is stale on versions.** It pins SDK 57 throughout
(`expo >= 57.0.17`, RN 0.86.3) and warns that the "latest" docs pages
already recommend SDK 58 versions. For any SDK 58 project, the pins
in §0 below supersede mobile-kit §0, §5, and runbook §0–§1. Never mix
SDK 57 pins with an SDK 58 project: the SDK versions must match
exactly, or the app will not open.

## 0. Pins — read first, never drift

Verified 2026-11-13 (see §10). All versions below were confirmed three
ways: the official versions table, `npm view`, and a real scaffold
smoke test.

| Package | SDK 58 pin | Source |
| --- | --- | --- |
| `expo` | `~58.0.25` (npm latest 58.0.25) | https://docs.expo.dev/versions/latest/ ; `npm view expo dist-tags` |
| `react-native` | `0.88.1` | https://docs.expo.dev/versions/latest/ (SDK 58.0.0 = RN 0.88) |
| `react` | `19.3.0` (npm latest 19.3.1) | https://docs.expo.dev/versions/latest/ (SDK 58.0.0 = React 19.3.0) |
| `expo-router` | `~58.0.31` | scaffold smoke test, `npm view expo-router version` |
| `react-native-reanimated` | `4.7.1` | scaffold smoke test (`tabs@sdk-58` template) |
| `react-native-worklets` | `0.13.0` | scaffold smoke test |
| `react-native-safe-area-context` | `~5.11.1` | scaffold smoke test |
| `react-native-screens` | `~4.30.1` | scaffold smoke test |
| `@expo/ui` | `~58.0.28` | `npm view @expo/ui version` |
| `expo-blur` | `~58.0.6` | `npm view expo-blur version` |
| `expo-linear-gradient` | `~58.0.4` | `npm view expo-linear-gradient version` |
| `expo-haptics` | `~58.0.8` | `npm view expo-haptics version` |
| `eas-cli` | `27.9.0` | `npm view eas-cli version` |
| Node.js | `>= 22.13` (22 line) / `>= 24.3` (24 line) / 26+ | https://expo.dev/changelog/sdk-58 |
| TypeScript | `~6.0.3` (template pin) | scaffold smoke test |

SDK 58 platform floors: Android 7+, `compileSdkVersion` 37,
`targetSdkVersion` 36; iOS 16.4+, Xcode 26.4+.
Source: https://docs.expo.dev/versions/latest/

Install everything with `npx expo install <package>` so the version
is resolved against SDK 58. Never hand-install `latest` by hand for
Expo packages — `npx expo install` is the resolver; `npm install
<package>@latest` is not.

## 1. Scaffold and upgrade — the only two entry commands

**Fresh project (the build-day path — use this):**

```bash
npx create-expo-app@latest my-app --template tabs@sdk-58 --yes
cd my-app
# Verify the pin: package.json "expo" must be major 58.
# Fresh templates pin ~58.0.x (e.g. ~58.0.25), tilde, patch-pinned —
# NOT ^58.0.0. A correct scaffold FAILS a literal ^58.0.0 check,
# so do not "re-pin" a good project.
```

**Existing SDK 57 project (recovery path only):**

```bash
npx expo install expo@^58.0.0 --fix
npx expo-doctor@latest
```

Source: https://expo.dev/blog/how-to-upgrade-to-sdk-58 and
https://expo.dev/changelog/sdk-58. Or hand the upgrade to the agent
with the official `expo-upgrade` skill: install Expo Skills, commit,
then tell the agent "Upgrade this project to the latest Expo SDK".
Source: https://docs.expo.dev/skills/

**Warning — the official docs contradict each other on the scaffold.**
The SDK 58 changelog still says "Until then, `npx create-expo-app`
creates SDK 57 projects" and "use a development build to run your new
project", while the upgrade blog (2026-10-21) says "`npx create-expo-app`
recommends SDK 58". The scaffold smoke test run 2026-11-13 proves
`--template tabs@sdk-58` works today and pins `expo ~58.0.25`.
Always pass `--template` explicitly and check `expo` in
`package.json` afterwards — never bare `npx create-expo-app@latest`.

## 2. Breaking changes vs SDK 57 — the ones that bite in 5 hours

Read in full from the official SDK 58 changelog and upgrade blog,
2026-11-13. Sources: https://expo.dev/changelog/sdk-58,
https://expo.dev/blog/how-to-upgrade-to-sdk-58.

- **Strict TypeScript API is now the default** (React Native 0.87).
  Deep imports from `react-native/Libraries/*` are now type errors.
  Refs must use instance types (`ViewInstance`, `TextInputInstance`).
  Run the type check early. Escape hatch (do not rely on it):
  `"customConditions": ["react-native",
  "react-native-legacy-deep-imports"]` in `tsconfig.json` — the
  opt-out is set to be removed after React Native 0.89.
- **Removed React Native APIs:** `InteractionManager` (use
  `requestIdleCallback`); the `Touchable` root export (use `ViewProps`
  if you extended `Touchable` as a type); the `Modal` `animated` prop;
  the deprecated `StatusBar` `backgroundColor`, `translucent`, and
  `networkActivityIndicatorVisible` props.
- **`ImageBackground` is deprecated** — use a `View` with an
  absolutely positioned `Image`. (mobile-kit snippets do not use it;
  do not introduce it.)
- **`expo-file-system`: `File.write()` is now async** and returns a
  promise; use `File.writeSync()` for the previous behavior.
- **`expo-sqlite`: libSQL support is removed** — `syncLibSQL()` and
  `libSQLOptions` are gone. Do not use libSQL.
- **R8 is now enabled by default in Android release builds**
  (`android.enableMinifyInReleaseBuilds=true`). Libraries that rely on
  reflection may need ProGuard keep rules. To opt out, set
  `android.enableMinifyInReleaseBuilds` to `false` with
  `expo-build-properties`. This affects the preview APK: a release
  build that crashes on launch with a reflection-dependent library is
  an R8 suspect, not a code suspect.
- **Node floor:** Expo tooling now requires Node 22.13+ (22 line),
  24.3+ (24 line), or 26+. Odd-numbered releases (23, 25) are not
  supported. Check `node -v` before the build day — a Node 20 machine
  fails an SDK 58 scaffold in a confusing way.
- **SDK 58 does not support macOS yet.** Support returns when
  `react-native-macos` reaches at least React Native 0.86.
- **iOS scene-based life cycle (iOS 27):** `npx expo prebuild` now
  generates `SceneDelegate.swift`. Only matters if the project manages
  the `ios` directory by hand — the hackathon project does not.
- **`@expo/ui` and `expo-symbols` are now optional peer
  dependencies.** On Android, install `expo-symbols` if you use
  `NativeTabs.Trigger.Icon` with the `md` prop, and `@expo/ui` if you
  use `Stack.Toolbar`.

## 3. Router order — load in this order, never skip step 1

1. **This skill's pins (§0–§2)** — SDK 58 versions and breaking
   changes. Nothing else in the fleet pins them.
2. **Expo Skills (official, MIT)** — the per-task playbooks.
   Install once:
   - Claude Code: `claude plugin install expo@claude-plugins-official`
   - Codex: `codex plugin add expo@openai-curated`
   - Other agents: `npx skills@latest add expo/skills --skill '*'`
   - Source: https://docs.expo.dev/skills/
   - Start with `expo-overview` (the router skill), then load only
     the Expo skill the step needs: `expo-router` for navigation,
     `expo-animation` for motion, `expo-native-ui` for platform
     styling, `expo-ui` for native components, `eas-app-stores` for
     eas.json / build / submit, `eas-update` for OTA, `expo-upgrade`
     for SDK upgrades. Never copy Expo Skills into this repo: Expo
     revises them per SDK release and a vendored copy rots.
3. **Design system** — mobile-kit `templates/theme.ts`. Re-lock the
   starter tokens in `theme.ts` against the brief's references at
   taste lock (same rule as the web kit: tokens first, no hardcoded
   colors/spacing/fonts in screens).
4. **Native UI / animation** — mobile-kit `templates/snippets.tsx`.
   All motion comes from the snippet pack. If a motion idea is not in
   the snippet pack, check `expo-animation` / the linked docs first;
   never improvise an API from memory.

## 4. Ban list — mobile-kit's, unchanged

The ban list lives in mobile-kit §2 and stays in force all day:
shared-element transitions, drag-reorder, Rive, Skia, Tamagui-new,
NativeWind v5, `react-native-gesture-handler` 3.x. Nothing in SDK 58
rehabilitates any of these for a 5-hour build. If a brief seems to
need a banned item, cut the feature or replace it with a snippet-pack
primitive. Record the cut in the run log; do not silently swap in a
banned library.

Two SDK 58 additions to the "do not use" list (from §2 above):
libSQL in `expo-sqlite` (removed), and `ImageBackground` (deprecated
— use `View` + absolute `Image`).

## 5. Expo Go 58 — the store-version conflict and the decision tree

**The conflict, stated plainly.** The official SDK 58 changelog still
says today: "Expo Go for SDK 58 on the Apple App Store and Google Play
Store will be released within a few weeks." But four independent store
mirrors agree the stores already serve **Expo Go 58.0.5** (AppBrain,
data updated 2026-11-06; APKMirror, uploaded 2026-10-22; APKFab;
Aptoide — all checked 2026-11-13). The official docs lag the stores;
the docs also contradict each other (§1). **The phone arbitrates.
Never trust a docs page over the phone in front of you.**

**The rule is exact-match, not minimum-version:** "Each build of Expo
Go includes one Expo SDK version. The `expo` package version in
package.json sets the project's SDK version. The project and Expo Go
SDK versions must match." Mismatch shows `Project is incompatible
with this version of Expo Go`.
Source: https://docs.expo.dev/troubleshooting/expo-go-version-mismatch/
(CARRIED from research/mobile-deep-20261113.md §0.1, accessed
2026-11-13.)

**Decision tree — run TONIGHT on the exact demo phone:**

```
1. What Expo Go version is installed?
   Settings → Apps → Expo Go → version at the bottom
   ├─ 58.x  → scaffold SDK 58 (default@sdk-58 / tabs@sdk-58). Go to 2.
   ├─ 57.x  → EITHER update Expo Go via Play Store to 58.0.5, then scaffold SDK 58;
   │           OR scaffold SDK 57 and FREEZE Expo Go (no Play update Saturday).
   │           Decide once, record it, do not flip-flop.
   └─ not installed → install from Play Store (will be 58.0.5) → scaffold SDK 58.
2. Does the idea need a native module outside Expo Go's fixed set?
   (custom native code, @react-native-firebase/*, config plugin adding
   native code, remote push, custom-scheme deep link needing your own
   bundle ID, react-native-maps / Skia IF tonight's import test fails)
   ├─ NO  → Expo Go path. Go to 3.
   └─ YES → dev build TONIGHT: eas build -p android --profile development
            (developmentClient: true, distribution: internal, buildType: apk).
            Install the dev APK, verify `npx expo start --dev-client` opens it.
            Keep Expo Go as the live fallback. Go to 3.
3. Build the preview APK TONIGHT (always, either path) — see §6.
4. SATURDAY MORNING re-verification (09:00–11:00, before the window):
   open the scaffold on the phone. If "Project is incompatible with
   this version of Expo Go": check the Expo Go version FIRST — did it
   auto-update overnight? Then sideload the matching Expo Go APK
   (npx expo-go download android <sdk>) — the supported recovery.
   Downgrading the project (npx expo install expo@^57.0.0 --fix) is NOT
   a documented recovery — treat it as a last resort and expect
   breakage (RN 0.88→0.86 + all expo packages).
   Do NOT debug anything else until the SDK versions match.
```

**Freeze Expo Go after tonight's test.** Do NOT update/install Expo
Go on Saturday without re-testing the scaffold immediately after.
Record the version number in the run log tonight.

**Same Expo account in CLI and Expo Go.** Since 3 Sep 2026 Expo
requires the same Expo account in the CLI and in Expo Go on physical
iPhone for SDK 57; Android was said to get the same rule "later".
Sign in with the same account anyway — 30 seconds, removes a whole
failure class. (CARRIED from research/mobile-deep-20261113.md §6.7.)

## 6. EAS Build preview APK — the judged demo vehicle

Expo Go is for **iteration**, not for the judged kill-and-reopen.
In Expo Go the phone reloads JS from Metro on every reopen, so a dead
laptop, dead tunnel, or dead venue Wi-Fi at 16:15 = a blank screen in
front of the judges. A preview build embeds the JS in the binary:
"In production apps, there is one main.js bundle that is shipped with
the app itself."
Source: https://docs.expo.dev/develop/development-builds/faq/
(CARRIED from research/mobile-deep-20261113.md §0.2.)

**Rule: build the preview APK tonight (Friday evening), install it on
the demo Android phone, and kill-and-reopen-test it twice tonight.
Use Expo Go + Metro for iteration all day Saturday; run the judged
demo on the preview APK.**

Full procedure, eas.json, free-tier limits, env-var trap, and sideload
notes: `references/eas-preview-apk.md` — read it before the first
build, not during the build. The short form:

```bash
npm i -g eas-cli          # 27.9.0 verified 2026-11-13
eas login                 # Expo account needed before any build
eas build:configure       # creates eas.json; run once before the first build
eas build --profile preview --platform android
```

`eas.json` preview profile (copy verbatim):

```json
{
  "build": {
    "preview": {
      "distribution": "internal",
      "android": { "buildType": "apk" }
    }
  }
}
```

Why `apk`, not the default `.aab`: `distribution: internal` shares
the build by URL, and the URL only installs on a device when the
build produces an `.apk` (default is `.aab`, which cannot be
installed on a device).
Source: https://docs.expo.dev/build-reference/eas-json/ and
https://docs.expo.dev/build/introduction/ (read 2026-11-13).

**Free-tier reality (EAS Build Free plan, $0):** up to 15 Android +
15 iOS builds/month, low-priority queue, 1 concurrent build,
45-minute build timeout, no overage — once the quota is used, builds
wait until the 1st of next month. "At peak times, you may experience
wait times of 90+ minutes with the low-priority queue." Paid plans buy the high-priority queue —
**do not buy anything; the free tier is the plan.** Exact counts
rest on secondary sources citing `expo.dev/pricing`, re-checked
2026-11-07–2026-11-09 (see §10) — the pricing page fetch returned
garbled JS-rendered text and did not legibly confirm the counts.
**Consequence: never depend on a mid-window cloud build. Do not start
any EAS build after 15:00. The build on the phone at 15:00 is the
build that demos.** `eas build --local` bypasses the cloud queue
(needs Android Studio + JDK) — CHƯA ĐỌC on the build laptop; test
tonight if the laptop has Android Studio, do not rely on it.

**Env-var trap (the one that silently kills the demo):** `.env.local`
is NOT available to remote EAS builds, so a preview APK built without
the backend URL ships with `EXPO_PUBLIC_CONVEX_URL === undefined`
and the AI call fails. Run ONE of these before the build (CARRIED
from research/mobile-deep-20261113.md §2.1, official sources cited
there — https://docs.expo.dev/eas/environment-variables/,
https://docs.expo.dev/guides/using-convex/):

```bash
eas integrations:convex:connect   # writes EXPO_PUBLIC_CONVEX_URL to .env.local AND to EAS env vars
# OR:
eas env:set EXPO_PUBLIC_CONVEX_URL <url> --environment preview
# (and add "environment": "preview" to the preview profile in eas.json)
```

Verify on the phone with Metro STOPPED: the AI flow must complete
end-to-end. Cold-open alone does NOT prove the demo works.

## 7. expo-router 58 essentials for the demo flow

- **Native tabs import renamed:** `expo-router/unstable-native-tabs`
  is now `expo-router/native-tabs`. Hand-written tab code from SDK 57
  memory breaks. Source:
  https://expo.dev/blog/how-to-upgrade-to-sdk-58.
- **Server output is now the default:** when `web.output` is not set,
  projects use `"server"`. The scaffold's `app.json` shows
  `"web": { "bundler": "metro", "output": "server" }`. This is a web
  concern; the native demo is unaffected — do not "fix" it. To keep
  SDK 57 behaviour, set `web.output` to `"static"` and enable the
  `apiRoutes` option of the `expo-router` config plugin.
- **Custom navigators:** use `createStandardRouterNavigator` or
  `integrateWithRouter` instead of `withLayoutContext` (deprecated).
  Do not import from `expo-router/react-navigation` — those exports
  are removed.
- **Typed routes are on by default** in the scaffold
  (`experiments.typedRoutes: true` in `app.json`). Use `Link href`
  with typed route names; a typo is a type error, not a runtime 404.
- **Deep-link entry to the AI flow (demo saver):** ship a deep link
  as a second entry point so the judged reopen lands directly on the
  AI flow — `myapp://ai` (dev/preview build, scheme in `app.json`)
  or `exp://<metro-host>:8081/--/ai` (Expo Go). The scaffold
  auto-generates `scheme` from the slug (e.g. `"scheme":
  "sdk58smoke"`); set it deliberately in `app.json` before building
  the preview APK. Test with `npx uri-scheme open <url> --android`.
  (CARRIED from research/mobile-deep-20261113.md §6.3; the `exp://` +
  `--android` combination is the direct analogue of the documented
  `--ios` example, not verbatim verified.)
- **State does not survive kill-and-reopen unless persisted.**
  In-memory state (React state / Context / Zustand without persist)
  is gone on kill. Pre-seed the AI flow's last good result in
  AsyncStorage so the reopen shows it instantly — but label it
  honestly as cached/offline with a retry button; never present
  cached output as a live AI result.
- **Streaming:** `expo/fetch` streaming itself is UNVERIFIED against
  Expo docs — ship the demo on plain non-streaming fetch + JSON
  parse; streaming is a nice-to-have only if verified first. Never
  rely on the global fetch for streaming (React Native's built-in
  fetch is an XHR polyfill with no `response.body`); if streaming is
  attempted, use the named `import { fetch } from 'expo/fetch'` and
  assert `res.body !== null` in a smoke test. (CARRIED from
  research/mobile-deep-20261113.md §4 trap 6 and
  swarm/phone-submission-pitch-brief.md §2.3.)

## 8. App config for a standalone build

The scaffold's `app.json` already sets the essentials; change these
deliberately before the preview build, never by accident:

| Field | Scaffold default | Before the preview APK |
| --- | --- | --- |
| `expo.name` / `slug` | project name | The product name; `scheme` is auto-generated from the slug — set `scheme` explicitly if the deep link must be a chosen word |
| `expo.version` | `1.0.0` | Leave; bump only if a second preview build needs distinguishing |
| `expo.icon` | `./assets/images/icon.png` | Replace with the product icon (1024×1024 PNG). In Expo Go you see Expo Go's icon; your icon only appears on the preview APK — test it tonight |
| `expo.android.adaptiveIcon` | foreground + background images, `#E6F4FE` background | Replace foreground/background with the product assets; set `backgroundColor` to the brand colour |
| `expo.splash` (via `expo-splash-screen` plugin) | splash icon, `resizeMode: contain`, `#ffffff` | Set `backgroundColor` to the brand colour |
| `expo.orientation` | `portrait` | Keep portrait for the demo |
| `expo.userInterfaceStyle` | `automatic` | Keep; drives the semantic tokens' light/dark |
| `expo.ios.supportsTablet` | `true` | Irrelevant for the Android demo phone |

Permissions (camera/mic) declared at build time only take effect
after a rebuild — declare them BEFORE building the preview APK.
(CARRIED from research/mobile-deep-20261113.md §4 trap 10.)

## 9. Kill-and-reopen demo checklist

Full checklist with the 13:00 and 15:00 gates:
`references/demo-checklist.md` — read it tonight, run it on the
exact demo phone. The short form:

- [ ] Expo Go version recorded; SDK decision made per §5 and written
      in the run log.
- [ ] Scaffold opens on the phone; no "incompatible" error.
- [ ] Kill-and-reopen ×2 in Expo Go (swipe from Recents → reopen →
      main screen loads from cold).
- [ ] Tunnel QR scan works from a non-home network; LAN is first try
      at the venue.
- [ ] AI flow runs end-to-end on mobile data (Wi-Fi OFF).
- [ ] Preview APK built tonight, installed, kill-and-reopen ×2 with
      Metro STOPPED, AI flow completing end-to-end.
- [ ] `EXPO_PUBLIC_CONVEX_URL` set; phone loads backend data.
- [ ] Deep link tested: `npx uri-scheme open <url> --android`
      lands on the AI flow.
- [ ] Phone charged, charger + cable packed; laptop charger packed;
      sleep disabled on the laptop.
- [ ] Same Expo account signed in on CLI and in Expo Go.
- [ ] Expo Go NOT updated/installed again after tonight's test
      without re-testing the scaffold immediately after.

**Hard stops:** 15:00–15:30 agents stop building. No new features, no
dependency changes, no EAS build started after 15:00. At 13:00 the
real AI flow must be live on the real phone twice in a row on the
demo input over mobile data — if not green, cut Slice 2 and harden
Slice 1. The 15:00 build on the phone is the build that demos.

## 10. File map

| File | What it is |
| --- | --- |
| `SKILL.md` (this file) | SDK 58 pins, breaking changes, Expo Go decision tree, preview-APK rule, router essentials, app config, demo checklist. |
| `references/eas-preview-apk.md` | Full EAS preview-APK procedure: eas.json, commands, free-tier limits, env-var trap, sideload + Play Protect notes, local-build option. |
| `references/demo-checklist.md` | Full kill-and-reopen checklist: tonight's phone checks, 13:00 gate, 15:00 freeze gate, recovery paths. |

## 11. Verification status (read 2026-11-13)

- **Verified today against official sources:** SDK 58 version table
  (https://docs.expo.dev/versions/latest/); SDK 58 changelog
  (https://expo.dev/changelog/sdk-58) and upgrade blog
  (https://expo.dev/blog/how-to-upgrade-to-sdk-58) read in full;
  Expo Skills catalog (https://docs.expo.dev/skills/, updated
  2026-11-02) and LICENSE (MIT,
  https://github.com/expo/skills/blob/main/LICENSE); EAS Build
  introduction + first-build guide
  (https://docs.expo.dev/build/introduction/,
  https://docs.expo.dev/build/setup/, updated 2026-11-02); eas.json
  reference (https://docs.expo.dev/build-reference/eas-json/ — page
  crawl dated 2024-04-26; schema properties cited are long-stable).
- **Verified today by running commands:** `npm view` for expo
  58.0.25, react-native 0.88.1, react 19.3.1, eas-cli 27.9.0,
  @expo/ui 58.0.28, expo-router 58.0.31, expo-blur 58.0.6,
  expo-linear-gradient 58.0.4, expo-haptics 58.0.8; scaffold smoke
  test `npx create-expo-app@latest sdk58-smoke --template
  tabs@sdk-58 --yes --no-install` (exit 0; pins recorded in §0;
  throwaway directory deleted). Node on the verifying machine:
  v24.22.1 (satisfies the SDK 58 floor).
- **Verified today against secondary sources (official docs lag):**
  store Expo Go is 58.0.5 — AppBrain (data updated 2026-11-06),
  APKMirror (uploaded 2026-10-22), APKFab, Aptoide. The official
  changelog still says "within a few weeks" — the conflict is real
  and the phone arbitrates (§5).
- **CHƯA ĐỌC / not verified — never present as verified:**
  - Exact EAS free-tier counts (15+15 builds, 45-min timeout, 1
    concurrent) were NOT legibly confirmed on `expo.dev/pricing`
    in this pass (fetched page returned garbled JS-rendered text);
    they rest on three secondary sources citing the pricing page,
    re-checked 2026-11-07–2026-11-09. Re-confirm on the rendered
    pricing page if the numbers matter.
  - No live EAS build was run (needs an Expo account, consumes
    free-tier quota). The first real build — including tonight's
    queue time — is untested.
  - No real phone is available to this skill. Every phone check in
    §5, §6, and `references/demo-checklist.md` is a runbook step
    for tonight, not a completed verification.
  - `eas build --local` on the build laptop: untested (needs
    Android Studio + JDK).
  - `expo/fetch` streaming: UNVERIFIED against Expo docs — ship
    non-streaming unless verified first (§7).
  - `react-native-maps` / Skia in Expo Go, Expo Go offline cached
    bundle, exact Play Protect warning flow: CHƯA ĐỌC — test on
    the phone tonight if the idea needs them.
  - Per-file currency of individual Expo Skills against SDK 58 was
    not verified; they are installed live from Expo's repo, so
    staleness is Expo's to fix.
- **CARRIED claims** (from research/mobile-deep-20261113.md and
  swarm/phone-submission-pitch-brief.md, both read 2026-11-13, with
  their own cited official URLs) are labelled CARRIED inline. If a
  CARRIED claim contradicts a page read today, the page read today
  governs and the contradiction is stated in place.
