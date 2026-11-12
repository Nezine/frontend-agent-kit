---
name: mobile-kit
description: "Expo + React Native + TypeScript hackathon integration for the frontend-agent-kit fleet workflow (SDK 57, Expo Go + Metro tunnel demo on a real phone). Router order: Expo Skills -> design-system -> native-ui/animation. Hard ban list: shared-element transitions, drag-reorder, Rive, Skia, Tamagui-new, NativeWind v5, RNGH 3.x. Use when building a mobile hackathon app with the kit's taste-locked loop, or when the team needs the SDK 57 snippet pack, theme tokens, or the build-day runbook."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Node 22+, Expo SDK 57, and a real phone for the demo-day smoke test. No full Expo app is built or run by this skill alone; it is the integration package (skill + tokens + snippets + runbook) the hackathon builders copy from.
metadata:
  version: "0.1.0"
---

# mobile-kit — Expo SDK 57 hackathon integration

You are the builder for a mobile hackathon app (Expo + React Native +
TypeScript, SDK 57). You work inside the frontend-agent-kit fleet workflow:
taste lock before code, build, gate first, fix the top 2, stop at the human
gate. This skill only adds the mobile routing, the ban list, the token file,
and the verified snippet pack. It never replaces the kit loop, and it never
grades its own work: grading is done by a separate grader agent in a fresh
context, with a NAMED grader. Never invent a score, a grader, or a waiver.

## 0. Pins — read first, never drift

- `expo >= 57.0.17` (React Native 0.86.3; 57.0.17 fixes the Hermes V1
  development-startup regression and 57.0.9 fixed the Hermes V1 memory
  regression — both hit apps importing `react-native-reanimated`).
  Source: https://expo.dev/changelog/sdk-57
- SDK 57 bundles `react-native-reanimated` 4.3–4.5, `react-native-worklets`
  0.8–0.10, `react-native-gesture-handler` 2.31–2.32.
  Source: https://expo.dev/changelog/sdk-57
- `@expo/ui ~57.0.17`, `expo-blur ~57.0.2` (SDK 57 pins).
- Install everything with `npx expo install <package>` so the version is
  resolved against SDK 57. Never install `latest` by hand: the "latest"
  docs pages already recommend SDK 58 versions (e.g. `@expo/ui ~58.0.28`),
  which do NOT belong in an SDK 57 project.

## 1. Router order — load in this order, never skip step 1

1. **Expo Skills (official, MIT)** — the entry point. Install once:
   - Claude Code: `claude plugin install expo@claude-plugins-official`
   - Codex: `codex plugin add expo@openai-curated`
   - Other agents: `npx skills@latest add expo/skills --skill '*'`
   - Source: https://docs.expo.dev/skills/
   - Start with `expo-overview` (the router skill), then load only the
     Expo skill the step needs. Never copy Expo Skills into this repo:
     Expo revises them per SDK release and a vendored copy rots.
2. **Design system** — `expo-design-system` + `templates/theme.ts` in this
   skill. Re-lock the starter tokens in `theme.ts` against the brief's
   references at taste lock (same rule as the web kit: tokens first, no
   hardcoded colors/spacing/fonts in screens). If a screen drifts
   (hardcoded color, magic spacing), fix the token, not the screen.
3. **Native UI / animation** — `expo-native-ui` for platform styling rules,
   `expo-animation` + `expo-ui` for motion and native components. All
   motion comes from `templates/snippets.tsx` in this skill. If a motion
   idea is not in the snippet pack, check `expo-animation` / the linked
   docs first; never improvise an API from memory.

## 2. Ban list — the builder MUST NOT use these

| Banned | Why (hackathon scope) |
| --- | --- |
| Shared-element transitions | Unproven in the 5-hour budget; a half-working transition eats the demo. |
| Drag-reorder | Gesture + layout edge cases; out of scope for a one-day build. |
| Rive | Extra runtime + asset pipeline; not in the snippet pack. |
| Skia (`@shopify/react-native-skia`) | Heavy native dependency; not in Expo Go, needs a dev build. |
| Tamagui (new / latest) | Unverified against SDK 57 in this package; no time to validate. |
| NativeWind v5 | Unverified against SDK 57 in this package; no time to validate. |
| `react-native-gesture-handler` 3.x | Off-SDK: SDK 57 bundles RNGH 2.32. Use the bundled version via `npx expo install`. |

If a brief seems to need a banned item, cut the feature or replace it with
a snippet-pack primitive (e.g. a plain `FadeInDown` stagger instead of a
shared-element hero). Record the cut in the run log; do not silently swap
in a banned library.

## 3. Allowed stack (only this)

- Navigation: `expo-router` (file-based routing, per Expo Skills).
- Motion: `react-native-reanimated` 4.x presets only — see
  `templates/snippets.tsx` §1.
- Gradients: `expo-linear-gradient` — §2.
- Sheets: `@expo/ui` universal `BottomSheet` — §3.
- Loading states: DIY skeleton pulse with core `Animated` — §4.
- Blur: `expo-blur` — §5 (Android needs `BlurTargetView` + `blurMethod`).
- Haptics: `expo-haptics`, exactly the three call sites in §6.
- Everything else: plain React Native core components + `theme.ts` tokens.

## 4. Build budget (build day, 11:00–16:00)

- Total build window: 5 hours. Motion/visual polish budget: ~2.5–3 hours.
- Agents stop building ~15:00–15:30. After that: demo rehearsal only, no
  new features, no dependency changes.
- Loop stop (same as the web kit): ≥4 on every axis AND gate green, or
  3 rounds — then the human gate decides. Human-eye acceptance bar is
  60% slop-free; taste target 8/10. Never raise the bar to 80%.
- Demo: Expo Go + Metro tunnel on the real phone. Full checklist in
  `runbook-build-day.md` — read it before the build day, not on the build day.

## 5. File map

| File | What it is |
| --- | --- |
| `SKILL.md` (this file) | Router order, ban list, pins, budget. |
| `templates/theme.ts` | Semantic colors, spacing scale, radius scale, `Platform.select` shadows, type scale. Starter values — re-lock at taste lock. |
| `templates/snippets.tsx` | Copy-paste snippets, each with its verified source URL in a comment above it. |
| `runbook-build-day.md` | Pre-build-day Expo Go test, demo-day timeline, go/no-go, dev-build fallback. |

## 6. Verification status (read 2026-11-12)

- Snippet sources were read in full from the official docs (Expo,
  Reanimated) or an SDK-57-targeted reference; each snippet carries its
  source URL. Anything not verified is marked CHƯA VERIFY in the snippet
  file — never present it as verified.
- Expo Go on the store may still be an older SDK: the SDK 57 changelog
  says "We'd like to release a new version for SDK 57, but we're still
  waiting on approval." Test on the real demo phone BEFORE the build day
  (runbook §1). A third-party note (2026-09-17) claims Expo Go 57.0.9
  reached the App Store on 2026-09-02 — CHƯA VERIFY against an official
  source, so it does not replace the real-phone test.
- No full Expo app is built or run in this repo: there is no real phone
  here. The `.ts` / `.tsx` files are syntax- and type-checked only (see
  `RECORD.md` in the delivery). The real-phone smoke test is a runbook
  step for the team, not something this skill can claim.
