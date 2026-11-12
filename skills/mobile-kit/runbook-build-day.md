# Runbook — mobile hackathon, build day (build 11:00–16:00)

Stack: Expo + React Native + TypeScript, SDK 57. Demo: Expo Go + Metro
tunnel on a real phone. Skill: `skills/mobile-kit/SKILL.md`. Snippets:
`skills/mobile-kit/templates/snippets.tsx`. Tokens:
`skills/mobile-kit/templates/theme.ts`.

## 0. Versions (do not drift)

- `expo >= 57.0.17` — React Native 0.86.3. 57.0.17 fixes the Hermes V1
  development-startup regression; 57.0.9 fixed the Hermes V1 memory
  regression. Both hit apps importing `react-native-reanimated`.
  Source: https://expo.dev/changelog/sdk-57
- Install with `npx expo install <package>` (SDK-pinned). Never hand-install
  `latest`: the "latest" docs pages already recommend SDK 58 versions.
- SDK 57 bundles Reanimated 4.3–4.5, Worklets 0.8–0.10, RNGH 2.31–2.32.
  Source: https://expo.dev/changelog/sdk-57

## 1. BEFORE the build day — test Expo Go on the real demo phone

This is the highest-risk item. Do it before the build day, not on the build day.

- [ ] Install Expo Go from the store on the exact phone used for the demo.
- [ ] Check the installed Expo Go version (Expo Go runs exactly one SDK).
      The SDK 57 changelog says: "We'd like to release a new version for
      SDK 57, but we're still waiting on approval. Expo Go for SDK 57 is
      available with `eas go` for iOS devices, and through Expo CLI for
      Android devices/emulators and iOS simulators."
      Source: https://expo.dev/changelog/sdk-57
- [ ] Open a minimal SDK 57 project in that Expo Go (scan the QR from
      `npx expo start --go`). If it opens, the Expo Go path is GO.
- [ ] A third-party note (2026-09-17) claims Expo Go 57.0.9 reached the
      App Store on 2026-09-02 — CHƯA VERIFY against an official source.
      It does NOT replace this real-phone test.
- [ ] If the SDK 57 project does NOT open in store Expo Go → prepare a
      development build IN ADVANCE (see §4). Do not discover this at 11:00
      on the build day.

## 2. Demo-day timeline (build day)

| Time | What |
| --- | --- |
| 11:00–11:15 | `npx expo start --tunnel`, phone loads the app, smoke test (§3). |
| 11:15–13:30 | Build core screens (taste-locked tokens first). |
| 13:30–14:30 | Motion/visual polish — budget ~2.5–3 h total, this is inside it. |
| 14:30–15:00 | Freeze features. Fix top 2 issues only. Re-run smoke test. |
| 15:00–15:30 | Agents STOP building. Demo rehearsal only. |
| 15:30–16:00 | Rehearsal + buffer. No new features, no dependency changes. |

## 3. Smoke test (run on the real phone, every time before a demo)

- [ ] `npx expo start --tunnel` prints a tunnel URL; phone loads the app.
      Prerequisite: `npm i -g @expo/ngrok` (tunnel needs it).
      Source: https://docs.expo.dev/more/expo-cli/
- [ ] Tunnel is flaky by design (shared ngrok account, no SLA). If it
      fails to connect, retry once, then fall back to LAN
      (`npx expo start`, same Wi-Fi) or the dev build (§4).
- [ ] App opens, no red screen. Main CTA works. Sheet opens/closes.
- [ ] Blur renders on Android (not a flat grey box) — if not, check
      `BlurTargetView` + `blurMethod` (snippets §5).
- [ ] Haptics fire on CTA press (real device only — simulators do not
      vibrate).

## 4. Fallback — development build (prepare BEFORE the build day if §1 fails)

- [ ] `npx expo install expo-dev-client`
- [ ] `eas build --platform android --profile development`
      (iOS: `--platform ios`; needs an Apple developer account for a
      device build — confirm before the build day.)
- [ ] Install the dev client on the demo phone, then drive it with
      `npx expo start --dev-client --tunnel`.
- [ ] Re-run the §3 smoke test against the dev client.

## 5. Go / no-go (15:00)

- GO: app loads on the real phone, main flow works, no red screen.
- NO-GO on Expo Go: switch to the prebuilt dev client (§4). Do not debug
  the store review status live.
- NO-GO on tunnel: switch to LAN (same Wi-Fi) or the dev client.
- If neither works: demo from a screen recording taken during rehearsal.
  Record it at 15:00 while the app still works — do not wait for 16:00.

## 6. Hard stops

- 15:00–15:30: agents stop building. After that, rehearsal only.
- Ban list (SKILL.md §2) stays in force all day: no shared-element
  transitions, drag-reorder, Rive, Skia, Tamagui-new, NativeWind v5,
  RNGH 3.x. A cut feature is recorded in the run log, never silently
  replaced with a banned library.
- Acceptance bar: 60% slop-free, taste target 8/10. Never raise it to 80%.
