---
name: maestro-smoke
description: "One Maestro E2E smoke flow for the hackathon demo day: the golden path (demo input -> AI result) plus the kill-and-reopen state assertion, run with the free Maestro CLI against the dev/preview build on the real Android phone. Use when the team needs one automated repeat of the exact demo taps during the 5-hour build. Hard rule: CLI local runs only — Maestro Cloud is banned (paid). Expo Go runs are smoke checks only, never the real test."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Java 17+, the Maestro CLI 2.12.1, a real Android phone with USB debugging, and the dev/preview build installed on that phone (APK sideload). Physical iOS devices are not supported by Maestro. No full test suite is built by this skill — one flow, one journey.
metadata:
  version: "0.1.0"
---

# maestro-smoke — one Maestro flow for demo day

You are the QC agent (role D) for a 5-hour hackathon build: Expo SDK 58,
React Native 0.88, preview APK demo on one real Android phone. Your job is
one automated repeat of the exact demo taps — the golden path plus the
kill-and-reopen state assertion — so the team knows the demo survives a
cold relaunch. You write ONE flow. You do not build a test suite.

## 0. Pins — read first, never drift

- Maestro CLI **2.12.1** (released 2026-11-02).
  Source: https://github.com/mobile-dev-inc/maestro/releases/latest
- Maestro is Apache 2.0, open source. The CLI, Studio, Viewer and MCP are
  free; Maestro Cloud is a paid service (pricing page + free 7-day trial
  on the vendor site) and is BANNED in this skill — never use it, never
  configure it, never pass it an API key.
  Source: https://github.com/mobile-dev-inc/maestro
- Maestro requires **Java 17 or higher**.
  Source: https://github.com/mobile-dev-inc/maestro
- Official docs claim the first test runs in five minutes.
  Source: https://docs.maestro.dev/get-started/quickstart.md
- Expo officially documents Maestro on EAS Workflows with a `.maestro/`
  convention; E2E tests require a built app file (.apk for Android).
  The Maestro job type in EAS Workflows is in alpha.
  Source: https://docs.expo.dev/eas/workflows/examples/e2e-tests/
- Expo SDK 58 = React Native 0.88, `expo@^58.0.0`.
  Source: https://expo.dev/changelog/sdk-58
- **SDK 58 + Expo Go warning (verified 2026-11-13):** the SDK 58
  changelog states "Expo Go for SDK 58 on the Apple App Store and Google
  Play Store will be released within a few weeks." Store Expo Go does NOT
  yet support SDK 58. The demo-day path for an SDK 58 app is therefore a
  preview/dev build (APK sideload), not store Expo Go. Do not plan the
  Maestro run (or the demo) around Expo Go until the store release lands.

## 1. Install — before 11:00, or not at all

Install takes ~10–15 minutes total (Java check + CLI + device check). It
must happen BEFORE the build window opens, or inside Slice 0 at the
latest. Installing after 13:30 steals freeze/rehearsal time: do not start
it then — the manual rehearsal (demo-rehearsal skill) is the fallback.

1. `java -version` — needs Java 17+. If Java is missing, install it first
   (that install time counts against the 15-minute budget; if it does not
   fit, abandon Maestro and use the manual rehearsal only).
2. Install the CLI from the release archive `maestro.zip` (release
   `cli-2.12.1`, https://github.com/mobile-dev-inc/maestro/releases/tag/cli-2.12.1
   — asset name verified 2026-11-13), unzip, add `bin` to `PATH`.
   Do NOT use the `curl | bash` installer: the kit's install contract
   (AGENTS.md section 3) bans `curl | bash`. On macOS, Homebrew is the
   documented alternative (`brew tap mobile-dev-inc/tap`, then
   `brew install mobile-dev-inc/tap/maestro`).
3. `maestro --version` — must print 2.12.1 (or newer; if newer, record
   the exact version in the run log and do not assume the commands
   changed).
4. Connect the demo phone over USB, enable USB debugging, accept the
   RSA prompt on the phone, then `adb devices` must list it. Maestro
   drives the phone through adb; no device in `adb devices` means no
   Maestro run.

## 2. The one flow — `.maestro/demo-golden-path.yaml`

Copy `templates/demo-golden-path.yaml` into the project as
`.maestro/demo-golden-path.yaml` and fill in every `REPLACE` marker from
the team's demo script (the exact taps, the one demo input, the golden
response text). One flow = one user journey. Do not add a second flow,
do not re-test component rendering, hooks, or query logic here.

Commands used (all verified in the official QuickStart, see pin above):
`launchApp` (with `clearState: true`), `tapOn`, `inputText`,
`assertVisible`, `takeScreenshot`, `killApp`, `launchApp` (relaunch).

The flow asserts, in order: the AI result appears for the demo input;
the app is killed; the app relaunches; the saved state is still there
(the kill-and-reopen assertion — the scored move, 40 points).

## 3. The Expo Go trap — read this before running

Under Expo Go, the app's JavaScript runs inside the Expo container, so
`launchApp` with the app's own `appId` targets an app that is not
installed and the flow fails at line one. The documented workaround is
to open the dev URL instead (`openLink` to the Metro URL) — that is a
smoke check, not a real test. The real run is always against the
dev/preview build, by `appId`, on the real phone. If the preview build
does not exist yet, do NOT burn time forcing Maestro onto Expo Go:
run the manual kill-and-reopen rehearsal (demo-rehearsal skill) instead
and retry Maestro once the preview APK is installed.

## 4. When to run it

- First green run: as soon as Slice 1 is green on the real phone
  (~12:20–13:20). A red flow here is a P0/P1 bug, not a test problem —
  fix the app, not the flow.
- Re-run at feature freeze (14:20) and after each top-2 fix. A flow
  that goes red after a fix means the fix broke the demo: revert the
  fix, do not patch the flow to match the breakage.
- Never run it during the pitch. Agents stop at 15:30; the flow's job
  is done by then.

## 5. Ban list — this skill MUST NOT use these

| Banned | Why |
| --- | --- |
| Maestro Cloud (`maestro cloud`, `maestro-cloud` job type, any Cloud API key) | Paid service; free-only rule. Local CLI runs only. |
| Maestro Studio as a build-day dependency | Desktop IDE; the 5-hour budget has no room for a GUI flow authoring session. YAML only. |
| Detox | Separate evaluation (see the testing-finder report): official React Native support ends at 0.84, first-time setup takes hours. |
| A second flow, a full suite, CI wiring | Out of scope in 5 hours. One flow, run by hand, on the real phone. |
| `curl \| bash` install | Banned by the kit's install contract (AGENTS.md section 3). Release archive or Homebrew only. |

## 6. File map

| File | What it is |
| --- | --- |
| `SKILL.md` (this file) | Pins, install, the one flow, the Expo Go trap, ban list. |
| `templates/demo-golden-path.yaml` | The flow template. Every `REPLACE` marker must be filled in from the demo script before running. |

## 7. Verification status (read 2026-11-13)

- Maestro CLI 2.12.1, Apache 2.0, Java 17+ requirement, physical-Android
  support / physical-iOS unsupported, and the 5-minute first-test claim
  were read on the official GitHub repo and official docs today
  (sources in section 0). The Expo E2E guide and its `.maestro/`
  convention were read on docs.expo.dev today.
- The flow template's YAML syntax was validated with PyYAML in this
  environment (2 documents, 10 commands, all command names from the
  official QuickStart except `killApp`, which is confirmed in the
  Maestro command references — see the testing-finder report).
- NOT run end to end: there is no real phone and no Java in this
  environment, and the Maestro CLI was not installed here. The first
  real run is a build-day task on the demo phone, not an assumption.
  If that first run fails on the device, the manual rehearsal
  (demo-rehearsal skill) is the fallback — do not debug Maestro during
  the freeze window.
- CHƯA ĐỌC: the demo phone's Android API level. Maestro's QuickStart
  states support for API levels 29, 30, 31, 33 and 34, with API 35/36
  support "arriving in Q2 2026". If the demo phone runs API 35 or 36,
  local Maestro runs are untested — check `adb shell getprop
  ro.build.version.sdk` before relying on the flow.
- Coordinator check 2026-11-13: Java 17+ requirement confirmed from
  the Maestro README ("Maestro requires Java 17 or higher"). The
  Homebrew alternative (`brew tap mobile-dev-inc/tap`) was NOT found in
  the README fetched the same day — CHƯA ĐỌC: verify against maestro.dev
  docs before using it; the release-archive install above is the
  verified path.
