# Kill-and-reopen demo checklist

Run on the **exact demo phone** — the one phone the judges will
see. Adapted from research/mobile-deep-20261113.md §1/§7 and
swarm/phone-submission-pitch-brief.md §2, both read 2026-11-13.
Times are the hackathon clock (build 11:00–16:00, Sat 14/11).

## Tonight (Fri 13/11, before sleep)

- [ ] **Confirm which phone is the demo phone.** (Open conflict in
      the sources: GOAL.md says 1 Android phone primary, iPhone 11
      Pro Max backup; the 12/11 toolkit report says iPhone 11 Pro
      Max. Write the answer here: model ___ OS ___.)
- [ ] **Expo Go version recorded** (Settings → Apps → Expo Go →
      version at the bottom). SDK decision made per SKILL.md §5 and
      written in the run log.
- [ ] **`eas login` done; `eas.json` created** via
      `eas build:configure`; Android keystore generated (first-build
      prompt handled tonight, not Saturday).
- [ ] **`node -v` ≥ 22.13** on the build laptop (SDK 58 requirement).
- [ ] **Scaffold opens on the phone** (pinned `--template
      tabs@sdk-58`, or `@sdk-57` if the phone is 57). No
      "incompatible" error.
- [ ] **Kill-and-reopen ×2 in Expo Go** (swipe the app away from
      Recents → reopen from Expo Go → main screen loads from cold).
- [ ] **Tunnel QR scan works from a non-home network** (phone
      hotspot, or venue-like network); note the slowness vs LAN.
- [ ] **Mobile-data AI call:** with the backend live, Wi-Fi OFF on
      the phone (mobile data on), run one full AI request
      end-to-end. A streamed answer completing on mobile data alone
      proves the backend URL is public, not a LAN address.
- [ ] **Preview APK built + installed** (SKILL.md §6,
      references/eas-preview-apk.md), kill-and-reopen ×2 with Metro
      STOPPED. **The AI flow must complete end-to-end with Metro
      stopped** — cold-open alone does NOT prove the demo works.
- [ ] **`EXPO_PUBLIC_CONVEX_URL` set; phone loads backend data**
      (or Supabase fallback — key names copied from Dashboard →
      Connect, not guessed: older docs use
      `EXPO_PUBLIC_SUPABASE_ANON_KEY`, the newer quickstart uses
      `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY`).
- [ ] **Streaming smoke test (only if streaming is attempted):**
      `import { fetch } from 'expo/fetch'` in the AI call;
      `res.body !== null` asserted; never rely on the global fetch
      for streaming. Default: ship non-streaming fetch + JSON parse
      (`expo/fetch` streaming is UNVERIFIED against Expo docs).
- [ ] **Deep link tested:** `npx uri-scheme open <url> --android`
      lands on the AI flow.
- [ ] **If a local notification is kept:** notification permission
      granted on Android 13+, one fires in Expo Go. (Remote push is
      CUT — unavailable in Expo Go on Android from SDK 53; a dev
      build + FCM setup is 60–120 min first time and earns 0 of the
      40 demo points.)
- [ ] **If EAS Update is attempted at all:** channel +
      runtimeVersion confirmed in the Expo dashboard, a trivial text
      change published, verified after two cold restarts. If that
      fails once, abandon OTA and use Metro. (OTA is NOT a 15:30 fix
      lever on the Expo Go path — it does nothing for the running
      Metro bundle.)
- [ ] **Expo Go NOT updated/installed again** after tonight's test
      without re-testing the scaffold immediately after.
- [ ] **Phone charged, charger + cable packed; laptop charger
      packed; sleep disabled on the laptop.**
- [ ] **Same Expo account signed in on CLI and in Expo Go.**

## Saturday 09:00–11:00 — run-start gate (before any code)

- [ ] Expo Go version on the demo phone re-checked (store may have
      updated overnight — SDK 58 trap). Scaffold SDK confirmed
      against it.
- [ ] `npx expo start --tunnel` running; skeleton project opens on
      the demo phone; **kill-and-reopen passes**.
- [ ] API base URL is the public Convex/Supabase URL — never
      `localhost` (works on simulator, fails on device).
- [ ] AI streaming uses `import { fetch } from 'expo/fetch'` if
      streaming at all (see tonight's note); default is
      non-streaming.

## At 13:00 — T+2:00, the halfway checkpoint

- [ ] **The real AI flow is live on the real phone, twice in a row,
      on the demo input, over mobile data.** This is the 40-point
      artefact; it must exist by halfway. Test it on the preview APK
      if one exists for the current build, otherwise Expo Go +
      tunnel.
- [ ] Kill-and-reopen the app on the phone, then run the full AI flow
      again from cold. If it fails, the next 30 minutes are debugging
      the demo path only — no new features.
- [ ] **Decision point:** if the AI flow is not green at 13:00, cut
      Slice 2 entirely and harden Slice 1. Do not let the schedule
      slip for a second feature.
- [ ] Confirm the demo script's exact taps still match the build
      (screens renamed? flow reordered?). The demo script is the
      contract; the build follows it, not the reverse.

## At 15:00 — T+4:00, agents stop building

- [ ] **Agents stop.** No code changes after 15:00 except fixes the
      humans direct, one at a time, through the coordinator. Hard
      stop 15:30.
- [ ] Humans verify kill-and-reopen on the real phone (preview APK),
      rehearse the 5-minute pitch twice, record the backup video of
      the live flow.
- [ ] Final checks: backup recording exists; demo script + evidence
      artefact + share link ready; the phone is charged and on mobile
      data as well as venue Wi-Fi; Metro laptop is on charger with
      sleep disabled (only needed if the demo falls back to Expo Go).
- [ ] **Do not start any EAS build after 15:00.** A free-tier build
      started at 15:00 can still be queued at 16:00. The build on the
      phone at 15:00 is the build that demos.

## If the deploy breaks at 15:50 — the 10-minute rule

- [ ] **Do NOT start an EAS build.** Free-tier queue 90+ min at
      peak; it cannot land before 16:00.
- [ ] **Freeze the code.** The demo is whatever is currently open on
      the demo phone via Expo Go + Metro tunnel (or the preview APK).
      Do not rebuild, do not reinstall, do not `npx expo install`
      anything.
- [ ] **Restart Metro only if it died** (`npx expo start --tunnel`),
      then kill-and-reopen on the phone once. If Metro will not
      restart, demo from the cached last-good AI result already on
      the phone and narrate the flow — a working cached flow beats a
      broken live one.
- [ ] **Submit what exists at 15:55 at the latest.** A submitted
      imperfect build beats a perfect unsubmitted one; the 16:00
      cutoff is hard.
- [ ] **If the phone itself fails:** switch to the backup phone — it
      has the same build open and passing. Do not debug the dead
      phone at the table.

## Traps this checklist guards against (one line each)

1. **SDK mismatch** — exact-match rule; store Expo Go is 58.0.5,
   an SDK 57 project fails in it (and vice versa).
2. **Expo Go auto-updates Saturday morning** — freeze it after
   tonight's test.
3. **Metro dies / tunnel drops mid-demo** — demo on the preview APK;
   Metro is the backup, not the vehicle.
4. **Tunnel ngrok limit** — shared ngrok, no SLA; LAN first at the
   venue, tunnel only if LAN/QR fails.
5. **EAS free queue eats the window** — build tonight, never
   mid-window.
6. **Streaming silently doesn't stream (Hermes)** — named
   `expo/fetch` import, `res.body !== null` asserted; default is
   non-streaming.
7. **`localhost` API URL** — public Convex/Supabase URL, proven by
   the Wi-Fi-off test.
8. **Remote push in Expo Go is dead (SDK 53+)** — CUT remote push;
   local notifications only.
9. **OTA two-cold-boots trap** — EAS Update is not a 15:30 lever on
   the Expo Go path.
10. **Deep-link scheme + sideload friction** — right link form per
    vehicle; allow time for the Play Protect screen or use
    `adb install`.
