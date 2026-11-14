# Liquid Glass / light refraction — council synthesis (Mie + Migga)

**Date:** 2026-11-14 (overnight, before build day) · **Council:** Mie (lead, general angle) + Migga (implementation angle)
**Demo:** Expo SDK 58 app, judged live on a real phone. Main vehicle: Android preview APK on the OPPO A60. Backup phone: iPhone 11 Pro Max.
**Budget:** $0.00 — every path below is free; nothing needs an account or a key.

## Sources (both verified on their forks)

- **Mie — general angle:** `research/2026-11-14/liquid-glass-research-20261114.md`, branch `mie/liquid-glass-20261114` @ `648e6d4` (ashley8127 fork), 146 lines, in Vietnamese. Verdict: CONDITIONAL.
- **Migga — implementation angle:** `research/liquid-glass-implementation-20261114.md` (this PR), 302 lines, 10 searches, 3 primary sources opened (Expo glass-effect + blur-view docs, official Skia shader docs). Verdict: cheap fake now; spike real glass only if a build slot is free; skip everything iOS-only.

## Agreed facts (both angles verified independently)

1. **Real Liquid Glass is iOS-only.** `expo-glass-effect` ~58.0.5 (official Expo, in Expo Go) and `@callstack/liquid-glass` render as a plain `View` on Android. Zero effect on the OPPO A60 / preview APK.
2. **Skia v2.14.0 is the pin.** `@shopify/react-native-skia` 2.14.0 is in Expo Go (official Expo docs, `docs.expo.dev/versions/latest/sdk/skia/` — 'Included in Expo Go', recommended version 2.14.0, verified 2026-11-14). v3 (`react-native-skia`, Graphite/WebGPU) needs a dev build and is NOT in Expo Go — do not upgrade.
3. **Skia cannot see live React Native views.** It can only lens content drawn inside its own canvas (an image/gradient) or a snapshotted child, which is then static (no scroll, no interaction) while the effect runs. Glass over live scrolling/interactive content is impossible with Skia.
4. **Glass never touches the AI main flow** (the 40-point artefact) or the content layer. Floating controls only, no glass-on-glass, respect Reduce Transparency / Reduce Motion.
5. **$0.00 on every path.** No accounts, keys, or paid services anywhere.

## Reconciled differences

- **R1 — Skia's role.** Mie's Route B (Skia shader, "the only route with a visible effect on Android") and Migga's "Skia is the wrong tool for glass-over-app" agree once scoped: Skia is viable ONLY as a **static showcase** — one card/panel lensing a static image/gradient background (or a snapshotted child, frozen while the effect runs). It is NOT glass over live app content. Mie's 1-hour time-box + cut rule stands.
- **R2 — The default ship.** Mie's fallback ("plain blur + rim highlight") and Migga's Path 1 (expo-blur fake) are the same move — and it is the **DEFAULT, not the fallback**: `expo-blur` ~58.0.6 (already installed) + tint + `expo-linear-gradient` specular wash + 1px rim, one hero surface. Android trap, verified in the official docs: a bare `BlurView` blurs nothing (`blurMethod` defaults to `'none'`); real blur needs `BlurTargetView` + `blurTarget` ref + `blurMethod="dimezisBlurViewSdk31Plus"` (A60 is API 34, works).
- **R3 — The AGSL fork.** `@sbaiahmed1/react-native-blur` 6.0.2 `LiquidGlassView` appears only in Migga's angle: the only candidate for REAL refraction over live RN content on Android 13+. Council: **parallel spike ONLY, never the plan** — 7-week-old one-maintainer fork, pulls a dependency from JitPack at build time, build under SDK 58 unverified. If the spike fails, the fallback is the blur fake.
- **R4 — The rebuild cost (Migga only).** Even the zero-native-code fake needs **one EAS rebuild (~90 min free-tier queue)** because the scaffold has no `expo-updates` — the current APK cannot take JS-only changes. If we rebuild once, add `expo-updates` to that build so later tweaks go OTA (standard Expo flow — verify against this project's config before relying on it).

## Council decision (build day, 5 hours)

1. **Step 0 (5 min, first thing):** check the iOS version on the backup iPhone 11 Pro Max (Settings → General → About). If < iOS 26, Route A is dead for this demo.
2. **Default ship (regardless of phone):** the expo-blur fake on ONE hero surface. Costs one EAS rebuild; add `expo-updates` to that build.
3. **Stretch (Android demo vehicle):** Skia Route B static showcase, time-boxed **1 hour max**; cut without mercy at the mid-day checkpoint if unconvincing; fall back to the blur fake.
4. **Spike (only if a build slot is free):** AGSL fork `LiquidGlassView`; verify the SDK 58 build first; never the plan.
5. **If the iPhone is on iOS 26 AND the judges accept the iPhone as the demo phone:** Route A (`expo-glass-effect`, ~30 min for one floating bar/FAB + fallback). This is a **HUMAN decision** (which phone is judged), not a technical one — the council cannot make it.
6. **Never:** Skia v3 upgrade, `expo-liquid-glass-view` (needs dev build), glass on the content layer or the AI flow, glass-on-glass, `opacity < 1` on a `GlassView`.

## Open items (human-side, not verifiable by the agents)

- iPhone 11 Pro Max iOS version (decides Route A).
- Which phone the judges accept as the demo phone (OPPO A60 APK is the planned vehicle; iPhone is backup).
- EAS iOS toolchain on Xcode 26 / iOS 26 SDK (only matters if Route A; unverified).
- Expo Go 58 check on the real demo phone before 09:00 (already open, human-side).

## Honest limits

- No fps / frame-time numbers on the Snapdragon 680 for any path; the phone test is the only measurement.
- No Skia or AGSL-fork build has been run under SDK 58 / RN 0.88; shader sketches are uncompiled.
- The iPhone door is entirely unverified until a human checks the phone.

## Addendum — Skia prototype exists (PR #25, 2026-11-14)

Mie delivered the Skia static-showcase prototype (PR #25, head `cae7f35`, branch `mie/liquid-glass-prototype-20261114`; verified via `gh` at 02:24: OPEN, draft, MERGEABLE; CI ubuntu PASS 5m14s, macOS runners pending at check time. **Correction 2026-11-14 06:57 (Milo's PR #21 review): PR #25 has since MERGED (02:27:42Z, main 1775d96) — the 'OPEN, draft' status above was stale at write time; it was correct when written and wrong by morning, owned plainly.**) What it is: `examples/liquid-glass-prototype/` on the same Expo SDK 58 scaffold + `@shopify/react-native-skia` 2.14.0, one static screen (bundled background, 1 lens card + 1 plain tint pill for comparison), Skia RuntimeEffect displacement shader (bend 0 at centre, max 20px at the edge + chromatic aberration + dark edge + rim stroke + sheen). Labels are RN Text over the canvas, not distorted. Reduce Transparency disables displacement.

What it proved (off-device only): the 1-hour time-box produced a keepable v2 (strength 20, aberration 0.40, rim 34px) that reads as a glass lens, not a blur — verified by re-implementing the shader formula in numpy and viewing a 390×844 render. Her MacBook checks all green (tsc 0, eslint 0, `expo export web` 0, `expo export android` 0, `expo-doctor` 20/20). So the "no Skia build under SDK 58" limit above is now partly closed: an SDK 58 export builds. The AGSL fork is still unbuilt and the shader sketches in the implementation report are still uncompiled.

What it did NOT prove: real-phone rendering. It has NOT run on a real phone or a dev build — the off-device render is not a phone render. The prototype must be checked visually on the real demo phone before demo day. (The 'must not be merged before that step' advice in the original addendum is moot — the prototype was merged at 02:27:42Z, the coordinator's call; the real-phone check is still required before the demo *uses* it.) Skia's APK weight is still unmeasured.

**Decision unchanged.** The blur fake is still the default ship; the Skia static showcase stays a stretch — now prototype-backed off-device, still gated on the real-phone check. Route A still needs the iPhone iOS 26 check (human-side).
