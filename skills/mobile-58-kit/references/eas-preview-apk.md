# EAS Build preview APK — full procedure

Read before the first build, not during the build. All sources
accessed 2026-11-13 unless stated.

## Why a preview APK at all

Expo Go is for iteration. In Expo Go the phone reloads JS from Metro
on every reopen, so a dead laptop, dead tunnel, or dead venue Wi-Fi
at 16:15 = a blank screen in front of the judges. A preview build
embeds the JS in the binary: "In production apps, there is one
main.js bundle that is shipped with the app itself."
Source: https://docs.expo.dev/develop/development-builds/faq/
(CARRIED from research/mobile-deep-20261113.md §0.2.)

**Rule: build the preview APK tonight (Friday evening), install it
on the demo Android phone, kill-and-reopen-test it twice tonight.
Use Expo Go + Metro for iteration all day Saturday; run the judged
demo on the preview APK.**

Do NOT follow the preview-builds tutorial at
https://docs.expo.dev/tutorial/cicd/preview-builds/ as the
preview-build guide — it is about Expo Workflows PR previews, needs
`expo-updates` configured, and its "no dev server" line is about PR
reviewers, not the embedded bundle. (CARRIED from
research/mobile-deep-20261113.md §0.2.)

## Prerequisites (tonight, on the build laptop)

```bash
node -v            # must be >= 22.13 for SDK 58
npm i -g eas-cli   # 27.9.0 verified 2026-11-13
eas login          # Expo account needed before any build
eas whoami         # confirm you are logged in
```

The first build also prompts for project linking + Android keystore
generation — do this tonight, not Saturday. EAS CLI can generate and
manage the Android keystore for you (select "Generate new keystore");
the keystore is stored securely on Expo servers.
Source: https://docs.expo.dev/build/setup/ (read 2026-11-13).

## eas.json — copy verbatim

Run `eas build:configure` once; it creates `eas.json`. Then make the
preview profile exactly this:

```json
{
  "cli": {
    "version": ">= 3.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal",
      "android": {
        "buildType": "apk"
      }
    },
    "production": {}
  }
}
```

Schema facts (official eas.json reference,
https://docs.expo.dev/build-reference/eas-json/, read 2026-11-13):

- `distribution` (enum: `store`, `internal`): `internal` lets you
  share build URLs with anyone and install straight from the Expo
  website. "When using `internal`, make sure the build produces a
  .apk or .ipa file. Otherwise, the shareable URL will not work."
- `android.buildType` (enum: `app-bundle`, `apk`): `apk` runs
  `:app:assembleRelease`; `app-bundle` runs `:app:bundleRelease`
  and produces an `.aab` that **cannot be installed on a device**.
  The default is `app-bundle` — forgetting `buildType: apk` is the
  most common way to get a useless preview build.
- `developmentClient: true` produces a development build and
  requires `expo-dev-client` installed. Only for the `development`
  profile, never for `preview`.
- `resourceClass`: `large` is **not available on the free plan**.
  Do not set it.
- `env`: environment variables set during the build. "It should only
  be used for values that you would commit to your git repository
  and not for passwords or secrets."

## Build command

```bash
eas build --profile preview --platform android
```

The command waits for the build by default; you can interrupt it
and watch progress at the build details page (`eas build:list` or
the dashboard). When it finishes, open the build page and click
"Install" to get the APK onto the phone.
Source: https://docs.expo.dev/build/setup/ (read 2026-11-13).

## Free-tier limits — the queue is the cost ($0.00)

EAS Build Free plan: **$0**, up to **15 Android + 15 iOS builds per
month**, **low-priority queue**, **1 concurrent build**, **45-minute
build timeout**, **no overage** — when the quota is used, builds wait
until the 1st of next month. "At peak times, you may experience wait
times of 90+ minutes with the low-priority queue", vs ~zero on the
paid high-priority queue. Android build itself typically 10–20 min
(first build 10–30+ min incl. queue + download + install); with a
free-tier queue at peak, total can exceed 2 hours.

**Exact-count provenance (honest):** these numbers were NOT legibly
confirmed on `expo.dev/pricing` in this pass — the fetched pricing
page returned garbled JS-rendered text that confirms "Free / Low
priority" but does not legibly show the build counts. They rest on
three independent secondary sources that each cite
`expo.dev/pricing` and were re-checked 2026-11-07 to 2026-11-09:
https://cadrant.ai/blog/eas-build ("checked again on November 9,
2026"), https://newly.app/guides/eas-build,
https://dawloom.com/blog/eas-build-pricing-vs-codemagic/ ("rechecked
2026-11-07"). The 90+ minute peak-queue warning is Expo's own
wording as quoted by those sources. Paid plans (Starter $19/mo with
$45 build credit, Production $199/mo with $225 credit) buy the
high-priority queue — **do not buy anything; the free tier is the
plan.**

**Consequences (hard rules):**

- Build the preview APK **tonight**. If the EAS queue is long, start
  it FIRST tonight and keep iterating in Expo Go while it builds.
- **Never start a cloud build mid-window.** A free-tier build started
  at 14:00 can still be queued at 16:00. **Do not start any EAS
  build after 15:00. The build on the phone at 15:00 is the build
  that demos.**
- If a Saturday rebuild is unavoidable, start it the moment the
  native set freezes and keep Expo Go as the live demo path meanwhile.
- If the preview APK is already on the phone and working, a Saturday
  rebuild is a luxury, not a need.

## The env-var trap — the one that silently kills the demo

`.env.local` is NOT available to remote EAS builds: "These files are
generally excluded from the project's version control… so they are
not available for jobs that run on a remote server, for example,
Expo Build."
Source: https://docs.expo.dev/eas/environment-variables/ (CARRIED
from research/mobile-deep-20261113.md §2.1, opened by the red team
2026-11-13.)

A preview APK built without the backend URL ships with
`EXPO_PUBLIC_CONVEX_URL === undefined` and the AI call fails with a
network error in front of the judges. Run ONE of these before the
build:

```bash
# Option A — Convex integration (recommended for the Convex primary path)
eas integrations:convex:connect
# Writes EXPO_PUBLIC_CONVEX_URL to .env.local AND to EAS env vars.
# Source: https://docs.expo.dev/guides/using-convex/ (CARRIED)

# Option B — set the variable directly
eas env:set EXPO_PUBLIC_CONVEX_URL <url> --environment preview
# And add "environment": "preview" to the preview profile in eas.json.
```

**Verification (mandatory, on the phone, Metro STOPPED):** the AI
flow must complete end-to-end. Cold-open alone does NOT prove the
demo works — the backend URL must be baked into the cloud build.
The phone reaches Convex over the public internet
(`https://<deployment>.convex.cloud`) — no tunnel needed for the
backend. Same for the Supabase fallback URL.

Never put a provider key or service-role key in the app or in an
`EXPO_PUBLIC_` variable. Keys live in the backend only (Convex
primary / Supabase Edge Function fallback).

## Sideloading the APK on the demo phone

- Install from the build page's "Install" button, or download the
  `.apk` and install it on the phone. Android will show an
  unknown-source gate and a Play Protect scan warning — allow time
  for it. (Exact Play Protect warning text/flow: CHƯA ĐỌC from an
  official Google source — expect a scan warning and allow time.)
- Faster, bypasses the on-phone toggle: `adb install <file>.apk`
  with USB debugging enabled.
- Declare camera/mic permissions BEFORE building — permissions
  declared at build time only take effect after a rebuild. In Expo
  Go you get Expo Go's own permission text; on the preview APK you
  get yours.

## Local build — queue bypass (optional, untested)

`eas build --local` runs the same pipeline on your own machine and
bypasses the cloud queue. Source:
https://docs.expo.dev/build/introduction/ (read 2026-11-13: "Use
local builds with eas build --local to run builds on your machine").
It needs Android Studio + JDK installed. CHƯA ĐỌC on the build
laptop — if the laptop has Android Studio, try it tonight on a
throwaway profile; if it works, it is the fastest Saturday rebuild
path. Do not rely on it until tested.

## Development build — only if the idea needs it

If tonight's import test shows the idea needs a native module outside
Expo Go's fixed set (custom native code, `@react-native-firebase/*`,
config plugin adding native code, remote push, custom-scheme deep
link needing your own bundle ID), build a dev build TONIGHT:

```bash
npx expo install expo-dev-client
eas build -p android --profile development
```

With a `development` profile of `developmentClient: true`,
`distribution: internal`, `android: { buildType: apk }`. Install the
dev APK, verify `npx expo start --dev-client` opens it. Keep Expo Go
as the live fallback. (Command form: official tutorial
https://docs.expo.dev/tutorial/eas/android-development-build/;
apk note per worker verification 2026-11-13, CARRIED from
research/mobile-deep-20261113.md §2.2.)
