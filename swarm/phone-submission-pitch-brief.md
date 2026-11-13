# Phone / Submission / Pitch Brief — Codex Hackathon, Sat 14/11/2026

- **Written:** 2026-11-13 (all source access dates below are the dates the cited reports were read, 2026-11-12, unless stated)
- **Repo:** `phamTuan207/muse-fleet`, VM clone `~/frontend-agent-kit/repo`, HEAD `907aeaa` (verified by `git rev-parse` 2026-11-13)
- **Event:** Sat 14/11/2026, 09:00–19:00, Biblio Book Cafe, 79 Ngụy Như Kon Tum, Thanh Xuân, Hà Nội. Build 11:00–16:00 (5h), submission 16:00, pitches 16:15, 5 min/team.
- **Scoring:** 40 / 35 / 25 — (1) real-phone AI demo, (2) real user problem with evidence, (3) market expansion. Tiebreak 1→2→3.
  - Source: `~/workspace/goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md` ("Hackathon rules verified (2026-11-12, from official Lu.ma page)"), read 2026-11-13.
- **Scope of this brief:** design tokens + phone checklist + submission checklist + pitch story (content only). Testing/rehearsal execution belongs to a separate subagent — this brief does NOT plan rehearsal runs.
- **Council rules:** one fabricated claim voids the submission; free legal sources only; anything not read in full is marked **CHƯA ĐỌC**.

## 0. Two open conflicts — do not paper over them

1. **Demo phone identity conflicts between sources.**
   - Mobile-agent-toolkit report says demo phone is **iPhone 11 Pro Max (iOS 18)** (`~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md`, §0, accessed 2026-11-12).
   - GOAL.md says the team has **1 Android phone (model/OS TBD)** as primary, with iPhone 11 Pro Max as backup (`GOAL.md`, "Backend + mobile stack", read 2026-11-13).
   - **Action:** the human confirms TONIGHT which single phone is the demo phone; every check in §2 is then run on that exact phone. iOS 18 matters: `expo-glass-effect` is iOS 26+ only, so on iOS 18 there is no Liquid Glass — use `expo-blur` instead (see §1.4).
2. **Submission artefact format is CHƯA XÁC MINH.** No source in the read set states the submission portal, file format, or required fields (repo link? video? form?). Do NOT invent one. **Action:** confirm the format with the organisers at the venue before 11:00 and fill §3.1 in by hand. Everything in §3 is therefore written as must-haves that hold under any format, plus the disclosure wording the rules do state.

---

## 1. Mobile design tokens — `theme.ts` structure (tokens before screens)

### 1.1 Source of truth

The token file is `skills/mobile-kit/templates/theme.ts` in the repo (read 2026-11-13, HEAD `907aeaa`). It is a starter: **re-lock every value against the brief's references at taste lock** — same rule as the web kit (tokens first, no hardcoded colours/spacing/fonts in screens). If a screen drifts, fix the token, not the screen.
- The UI/UX-effects report's verdict on this layer: "Nền hygiene: `theme.ts` tokens + safe-area + type scale" — impact 3 (2 when right, −5 when wrong), cost 1, free (`~/workspace/research_notes/mobile-ui-ux-effects-20261112/report.md`, §2 item 8, accessed 2026-11-12). Safe-area: `safe-area-context` "Included in Expo Go" ~5.7.0, docs v57 read in full (same report, §2 item 8).
- Styling decision: **StyleSheet + small `theme.ts`** — zero setup risk. NativeWind v4 ↔ SDK 57 pairing is UNVERIFIED (only the SDK 54 pairing is on record from an official source) — do not switch mid-sprint (`~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md`, §3, accessed 2026-11-12).

### 1.2 Colours (semantic, light-first in the template)

From `templates/theme.ts` (verbatim values):

| Token | Value | Role |
|---|---|---|
| `background` | `#FFFFFF` | App background |
| `surface` | `#F6F6F4` | Cards / grouped surfaces |
| `surfaceRaised` | `#FFFFFF` | Raised card on `surface` |
| `text` | `#0A0F1E` | Primary text |
| `textSecondary` | `#5B6472` | Secondary text |
| `textInverse` | `#FFFFFF` | Text on brand / dark |
| `brand` | `#2547F4` | Primary action / accent |
| `brandSoft` | `#E4E9FE` | Brand tint background |
| `border` | `#E3E5E8` | Hairlines, dividers |
| `success` | `#1F9D63` | AI done / positive |
| `warning` | `#C77D0A` | Caution |
| `error` | `#D92D20` | Failure / destructive |

- **Palette decision still open:** the effects report (§4.2) says chốt palette + gradient 2–3 stops BEFORE the build, via a colour-picker tool (uiGradients / Coolors — those tools were only read via snippet, **CHƯA ĐỌC** full pages). The template's `#2547F4` blue is the default, not a locked brand colour: if the idea's references demand a different brand hex, change `brand`/`brandSoft`/gradient stops in `theme.ts` only, and change them before 11:00.
- **Dark mode:** tokens are semantic; drive them with `useColorScheme` + `userInterfaceStyle: "automatic"` in `app.json` (effects report §3.3, accessed 2026-11-12). Never hard-code colours in `StyleSheet.create` at module scope (freezes at load). **Time-saving call:** if short on time, do NOT build an in-app light/dark toggle — system tokens only, or lock dark for the pitch (effects report §4.2).
- **Gradient (cheapest high-impact visual):** `expo-linear-gradient`, impact 5/5, cost 1/5, "Included in Expo Go" ~57.0.2, docs v57 read in full (effects report §2 item 2). Use for background / CTA / scrim. TypeScript gotcha: `colors` is a readonly tuple — pass inline or `as const` (see `templates/snippets.tsx` §2, source https://docs.expo.dev/versions/latest/sdk/linear-gradient/, read 2026-11-12).

### 1.3 Spacing / radius / type (verbatim from `theme.ts`)

- **Spacing (4-pt grid):** xs 4, sm 8, md 12, lg 16, xl 20, 2xl 24, 3xl 32, 4xl 40, 5xl 48, 6xl 64.
- **Radius:** none 0, xs 4, sm 8, md 12, lg 16, xl 20, 2xl 24, full 999.
- **Type scale:** display 34/40 w700 (−0.5 tracking); title 28/34 w700 (−0.3); headline 20/26 w600; body 16/24 w400; bodySmall 14/20 w400; caption 12/16 w500. Always set `lineHeight` by hand (iOS/Android defaults differ). Max 3 weights (400/500/700). **System font only** (San Francisco / Roboto) — do not load a custom font in 5 hours (effects report §3.3/§4.2, accessed 2026-11-12). Body minimum 16pt.
- **Touch targets:** 44×44pt iOS / 48×48dp Android, contrast ≥ 4.5:1, 8-point grid — from the `app-ui-design` skill gate cited in the effects report §3.5 (SKILL.md mirror read via https://www.skillsdirectory.com/skills/majiayu000-app-ui-design-spellbook, accessed 2026-11-12; licence CHƯA RÕ — do not claim MIT).
- **Shadows:** one token set, `Platform.select` — iOS `shadow*` props, Android `elevation` + mandatory `backgroundColor` (template `theme.ts`; effects report §3.3). `sm`: iOS opacity 0.08 / radius 4, Android elevation 2. `md`: 0.1 / 12, elevation 6. `lg`: 0.14 / 24, elevation 12. Shadow colour `#0A0F1E`. Notes: `boxShadow` (RN 0.76+, New Architecture) is **CHƯA VERIFY in Expo Go SDK 57** — use the legacy token; `overflow: 'hidden'` clips shadows on iOS (outer view holds shadow, inner view holds radius); heavy shadows re-computed per frame on Android can jank during animation (effects report §3.3).
- **Motion tokens (from the effects report §4.1/§4.2):** animate transform + opacity only (GPU); spring default `damping` 120, `stiffness` 900, `mass` 4; micro-interactions 200–500ms; `ease-out` for entering, never `ease-in`; press-scale 0.9 → spring to 1; list stagger `delay(index * 50)`; no `setState` in `onUpdate` (shared values only, `runOnJS` at `onEnd`).

### 1.4 What the taste lock looks like on mobile

The web kit's taste lock is `TASTE.md` + `tokens.css` + references before any build (`~/frontend-agent-kit/repo/AGENTS.md`, §2 step 1, read 2026-11-13). On mobile the equivalent is:

1. **One `theme.ts` file, written first (0:00–0:20 of the sprint), before any screen.** Pure TypeScript, 0 dependencies (effects report §4.2).
2. **A 10–15-line DESIGN.md written by a human from 2–3 references** (hex colours, radius, spacing, element order, button wording, flow) — agents cannot consume raw beauty shots. "Người dành 30 phút đầu mở Mobbin free + Dribbble/Behance, chọn 2–3 reference cho đúng màn hình chính, viết thành DESIGN.md" (effects report §3.5). Do NOT let an agent browse taste sites unsupervised.
3. **Yates reference-sites backbone** (`skills/frontend-kit/references/reference-sites.md`, read 2026-11-13 — restates a Yates TikTok clip; the clip itself was not re-opened, **CHƯA ĐỌC** the original video). Principles, not pixels; one aspect, one teacher; study only the 2–3 aspects the brief needs:

| Mobile need | Teacher site | Principle to steal |
|---|---|---|
| Motion that explains | apple.com | Motion explains, never decorates |
| First-run / onboarding | duolingo.com | Teach by doing, not by telling |
| Dense product UI that stays calm | linear.app | Density without noise — the default for an AI tool screen |
| Finding things fast | airbnb.com | Search & filters without clutter |
| Small responses that make it feel alive | framer.com | Micro-interactions (press-scale, haptics) |
| Structure that carries the argument | stripe.com | Layout order for the pitch/demo flow |

4. **Ban list (gate input, from effects report §4.1):** shared-element transitions (experimental, needs feature flag — https://reactnavigation.org/docs/shared-element-transitions/, read 2026-11-12); drag-to-reorder libs (need dev build); Rive (docs: "not compatible with Expo Go… need a development build" — https://rive.app/docs/runtimes/react-native/adding-rive-to-expo, read 2026-11-12); Skia (Expo Go status contradictory, **CHƯA XÁC MINH**); Tamagui fresh setup; NativeWind v5 / Tailwind v4; HeroUI latest (v1.0.11 = SDK 58 — pin v1.0.5 for SDK 57); RNGH 3.x hook API (`usePanGesture` needs dev build — use RNGH 2.x `Gesture.Pan()`); `boxShadow` (unverified); NativeBase (deprecated — README says so); web patterns (CSS gradient, `box-shadow`, copying a Dribbble shot pixel-for-pixel).
5. **Anti-slop (Anthropic `frontend-design` ban list, effects report §4.1):** cream background + serif + terracotta; near-black + one acid accent; identical rounded cards with the same soft grey shadow; all-caps labels on every heading. A screen that looks AI-generated/generic gets rewritten.
6. **Visual stack, in order (effects report §2/§3.3):** Reanimated 4 presets first (`FadeInDown.delay(i*50)`, `LinearTransition`, `withSpring` — docs https://docs.swmansion.com/react-native-reanimated/docs/layout-animations/entering-exiting-animations/, read 2026-11-12); `expo-linear-gradient`; `@expo/ui` BottomSheet (docs v57, "Included in Expo Go" ~57.0.26 — https://docs.expo.dev/versions/v57.0.0/sdk/ui/universal/bottomsheet/, read 2026-11-12); DIY skeleton pulse (core Animated, opacity 0.4→1 loop, 0 dependencies); `expo-blur` `BlurView` — **Android trap: a bare `<BlurView>` blurs nothing without `BlurTargetView` + `blurMethod`** (docs https://docs.expo.dev/versions/v57.0.0/sdk/blur-view/, read 2026-11-12; template uses `blurMethod="dimezisBlurViewSdk31Plus"`, real blur Android 12+ only, with an `rgba` fallback); `expo-haptics` at exactly 3 call sites (CTA press, AI done, swipe past threshold — docs https://docs.expo.dev/versions/latest/sdk/haptics/, read 2026-11-12; note: that page has **no** "Included in Expo Go" line, so test vibration on the demo phone immediately after install).
7. **What NOT to spend on:** `expo-glass-effect` — "Included in Expo Go" ~57.0.5 but **iPhone iOS 26+ only**, otherwise falls back to a plain `View` (docs https://docs.expo.dev/versions/v57.0.0/sdk/glass-effect/, read 2026-11-12). Demo phone is iOS 18 (toolkit report) or Android (GOAL.md) — either way, GlassView buys nothing; use `BlurView`.

---

## 2. Phone-check checklist

### 2.1 The #1 risk — Expo Go / SDK version trap

- SDK 57 changelog (read in full by the effects-report coordinator, 2026-11-12): *"We're still waiting on approval. Expo Go for SDK 57 is available with `eas go` for iOS devices, and through Expo CLI for Android devices/emulators and iOS simulators."* Source: https://expo.dev/changelog/sdk-57 (accessed 2026-11-12).
- SDK 58 changelog: Expo Go for SDK 58 on the stores "will be released within a few weeks" of 2026-10-15, and the new Expo Go will support **only SDK 58**. Source: https://expo.dev/changelog/sdk-58 (accessed 2026-11-12, per toolkit report §1).
- Consequence: **scaffold SDK 57 unless the run-start phone check proves the store Expo Go is SDK 58.** Each Expo Go release bundles exactly one SDK version. Use `expo >= 57.0.17` (RN 0.86.3) — fixes a Hermes memory regression (57.0.9) and slow startup (57.0.17) (effects report §1).
- **Never depend on a mid-window cloud build:** EAS free tier is 15 Android + 15 iOS builds/month, low-priority queue, waits of 90+ min at peak, 45-min timeout, 1 concurrent build (third-party, checked against Expo docs/pricing Sept 2026: https://newly.app/guides/eas-build, accessed 2026-11-12). A free-tier EAS build started at 14:00 could still be queued at 16:00. Expo Go is the demo path; a development build, if wanted at all, must be kicked off in hour 1 or pre-built before the event.

### 2.2 TONIGHT (Fri 13/11, before sleep) — on the exact demo phone

- [ ] **Confirm which phone is the demo phone** (see §0 conflict: Android primary per GOAL.md vs iPhone 11 Pro Max per toolkit report). Write the answer here: model ___ OS ___.
- [ ] **Install Expo Go from the store on that phone; read its version number aloud** (Settings / Expo Go app info). Record: Expo Go version ___ / SDK ___.
- [ ] **Open a sample SDK 57 project in Expo Go on that phone** (scaffold: `npx create-expo-app@latest --template default@sdk-57` — pin explicitly; docs https://docs.expo.dev/more/create-expo/, accessed 2026-11-12). If it does not open → fallback decision TONIGHT (development build via `npx expo run:android` / `run:ios`, or EAS Build) — not during the sprint.
- [ ] **Kill-and-reopen test on the sample project:** swipe the app away (kill Expo Go), reopen, confirm the app reloads from the still-running Metro server. This is the exact scoring test (40 points).
- [ ] **Tunnel test:** `npx expo start --tunnel`, phone on mobile data (not venue Wi-Fi), confirm the app loads. Venue Wi-Fi is untrusted; tunnel is the demo path (toolkit report §2).
- [ ] **Install-check the five native modules on the sample project:** `npx expo install react-native-reanimated expo-linear-gradient @expo/ui expo-blur expo-haptics` — then open on the phone and confirm: gradient renders, BottomSheet opens, blur visible (Android: with `BlurTargetView`), haptics vibrate on tap (toolkit report §6 item 3; effects report §6.2 item 2).
- [ ] **Decide Lottie / Moti in 15 minutes each, then stop:** Lottie (`.json` file only, never `.lottie`) — sources contradict on Expo Go, test or drop (effects report §2). Moti — official docs are stale (Reanimated 3 / SDK 44); only secondary evidence for Reanimated 4; test `npx expo install moti` or use raw Reanimated presets (effects report §2).
- [ ] **Charger + cable packed:** laptop charger, phone charger, phone cable (GOAL.md: "bring laptop + charger, phone + cable"). Laptop on charger all day; laptop must never sleep (Metro dying = demo dying).
- [ ] **Backup phone identified and charged:** the non-demo phone (the other of Android / iPhone 11 Pro Max) with Expo Go installed, same version check. If the demo phone dies, the backup is the demo phone.
- [ ] **Offline safety:** confirm the app caches the last good AI result locally so a network blip during the pitch does not blank the screen (toolkit report §3 — labelled there as a judgement call, not a sourced fact).
- [ ] **No keys in the bundle:** provider keys live in the backend only (Convex primary / Supabase Edge Function fallback — GOAL.md), never in app code or `EXPO_PUBLIC_` variables; tokens in `expo-secure-store`, never AsyncStorage (plaintext on disk) (toolkit report §3/§6 items 8, 10, accessed 2026-11-12).

### 2.3 Tomorrow 11:00 — run-start gate (before any code)

- [ ] Expo Go version on the demo phone re-checked (store may have updated overnight — SDK 58 trap, §2.1). Scaffold SDK confirmed against it: SDK 57 unless proven 58.
- [ ] `npx expo start --tunnel` running; sample/skeleton project opens on the demo phone; **kill-and-reopen passes**.
- [ ] API base URL is the LAN IP or tunnel URL — never `localhost` (works on simulator, fails on device) (toolkit report §6 item 2).
- [ ] AI streaming uses `import { fetch } from 'expo/fetch'` — Hermes' built-in fetch has no `response.body` stream; web-style `response.body.getReader()` throws on Hermes (toolkit report §6 item 1). NOTE (free-tier verification 13/11): `expo/fetch` streaming itself is UNVERIFIED against Expo docs — ship the demo on plain non-streaming fetch + JSON parse; streaming is a nice-to-have only if verified first.

### 2.4 Tomorrow 13:20 — mid-sprint gate (T+2:20)

- [ ] Slice 1 (the single most important demo flow, real AI live) open on the real phone — twice, kill-and-reopen both times. If not green by T+2:20 (13:20), cut scope, do not add features (toolkit report §5: real AI live by halfway).
- [ ] Metro + laptop alive, on charger, sleep disabled. Tunnel still reachable from the phone on mobile data.
- [ ] No new native module introduced after T+2:20 (13:20) ("Cannot find native module" in Expo Go = drop the package or switch to a dev build — decide in hour 1, not hour 4; toolkit report §6 item 3).

### 2.5 Tomorrow 15:00 — freeze gate (agents stop ~15:00–15:30)

- [ ] **Final kill-and-reopen on the demo phone, in front of a human, with the exact pitch input.** Then do not touch the code.
- [ ] Backup phone has the same build open and kill-and-reopen-passing.
- [ ] Phone battery > 50%, charger + cable at the pitch table; laptop on charger, Metro running, tunnel up.
- [ ] Cached last-good AI result present (offline safety, §2.2).
- [ ] Submission artefact ready per §3 (format confirmed at venue — see §0 item 2).

---

## 3. Submission checklist

### 3.1 Artefact format — CHƯA XÁC MINH, confirm at venue before 11:00

No source in the read set states the submission portal, file format, or required fields. **Do not submit blind.** At the venue (09:00–11:00), get in writing from an organiser: (a) where to submit (link/form/repo?), (b) required artefacts (repo link? APK? video? screenshots?), (c) whether a demo video is required or optional, (d) the exact 16:00 cutoff mechanics (upload timestamp vs form submit). Write the answers here before the build starts:
- Portal: ___
- Required artefacts: ___
- Demo video required? ___
- Cutoff mechanics: ___

### 3.2 What must exist by 16:00 (format-independent)

- [ ] **A working app on the real phone** — the 40-point demo is live, kill-and-reopen-passing, main AI flow running on real data through the real backend endpoint (Convex primary / Supabase fallback). Browser/emulator/photo/video = 0 points for the demo criterion (toolkit report §0; GOAL.md scoring).
- [ ] **Repo / code accessible to judges** (public repo link or as the portal requires — see §3.1). Git history shows day-built work; commits frequent (git is how agent mistakes are undone — toolkit report §3).
- [ ] **Pre-built vs day-built disclosure (wording below, §3.3)** — included in the submission exactly as written.
- [ ] **Evidence pack for the 35 points:** the real-user-problem evidence (interviews / observations / numbers — whatever the idea's evidence is) attached or linked, with sources and dates. Evidence over slides (GOAL.md).
- [ ] **Market-expansion note for the 25 points:** first users + global reach, in one short paragraph + the first-user list if any exist (real users are an advantage — GOAL.md).
- [ ] **Backup screen recording of the full demo flow on the real phone** (owner: rehearsal subagent — listed here only as an artefact, no run planned in this brief). If the live demo fails at pitch time, the recording is the fallback evidence, not the demo itself.
- [ ] **No secrets in the submitted repo:** no provider keys, no `EXPO_PUBLIC_` key variables, `.env` in `.gitignore` (toolkit report §6 item 8).

### 3.3 Pre-built vs day-built disclosure — wording to use verbatim

Prep before the day is explicitly allowed (idea, research, even starting part of the product) and **must be disclosed**; public libraries/SDKs/APIs/templates are allowed (GOAL.md, "Hackathon rules verified", from the official Lu.ma page, 2026-11-12 — the Lu.ma page itself was not re-opened in this pass, **CHƯA ĐỌC** the live page). Use this wording in the submission, filling the brackets:

> "Pre-built before 14/11: [Expo SDK 57 starter + theme tokens + router/store wiring; Convex/Supabase project + one AI endpoint skeleton; design references + DESIGN.md; agent skills and gate scripts]. Built during the 11:00–16:00 sprint on 14/11: [the product screens, the AI feature integration, the demo flow, polish and fixes]. Public libraries/SDKs used: [Expo SDK 57, React Native, Reanimated, expo-linear-gradient, @expo/ui, expo-blur, expo-haptics — list exact versions from package.json]. No other team's code was used."

### 3.4 If the deploy breaks at 15:50 — the 10-minute rule

- [ ] **Do NOT start an EAS build.** Free-tier queue 90+ min at peak; it cannot land before 16:00 (toolkit report §2/§6 item 5).
- [ ] **Freeze the code.** The demo is whatever is currently open on the demo phone via Expo Go + Metro tunnel. Do not rebuild, do not reinstall, do not `npx expo install` anything.
- [ ] **Restart Metro only if it died** (`npx expo start --tunnel`), then kill-and-reopen on the phone once. If Metro will not restart, demo from the cached last-good AI result already on the phone (§2.2) and narrate the flow — a working cached flow beats a broken live one.
- [ ] **Submit what exists at 15:55 at the latest.** A submitted imperfect build beats a perfect unsubmitted one; the 16:00 cutoff is hard (GOAL.md).
- [ ] **If the phone itself fails:** switch to the backup phone (§2.2) — it has the same build open and passing. Do not debug the dead phone at the table.

---

## 4. Pitch story — 5 minutes, mapped to 40/35/25 (content only)

Total 5:00. The demo is the pitch: the judges score what they see on the real phone, not the slides. One speaker, phone in hand, screen visible to the judges throughout. No rehearsal runs are planned in this brief (separate subagent owns rehearsal execution).

| Time | Beat | Criterion | What to say / do |
|---|---|---|---|
| 0:00–0:30 | **Hook — the problem in one sentence** | 35 (sets it up) | Name the real user, the real moment, the real cost — in one sentence, with the number. No company intro, no team intro, no "AI IN YOUR PALM" slogan. Example shape: "[User] spends [X minutes] doing [task] every [day/week], and [concrete cost]." |
| 0:30–1:00 | **Evidence — it is real** | 35 | The evidence, fast: who you talked to / observed, how many, what they said or did — with the source and date. One line per evidence item, max three. "Evidence over slides" (GOAL.md). This is the difference between 35/18/0 and 0. |
| 1:00–1:15 | **The AI-is-essential claim** | 40 (sets it up) | State the removal test out loud: "Remove the AI and this flow breaks — [what becomes impossible, not just slower]." If removing the AI only makes it slower, the AI is decoration (toolkit report §4). Say which user flow the AI sits *inside* — not a new tab with a sparkle icon and an empty chat box (same source). |
| 1:15–3:15 | **LIVE DEMO on the real phone** | **40** | **The scoring beat — 2 full minutes, uninterrupted.** (a) Kill the app on camera, reopen it — the exact scoring test, done first while judges are watching. (b) Run the main AI flow end-to-end on real input: streaming tokens visible as they arrive, progress shown, cancel available; output arrives as an editable draft, one tap to accept, nothing committed silently (toolkit report §4, three interaction rules). (c) One haptic + motion moment the eye can feel (press-scale, stagger, BottomSheet). Narrate only what the phone is doing — no feature list. If the network stutters, the cached last-good result is on screen; say so plainly and keep going. |
| 3:15–3:45 | **Why the AI helps directly** | 35 | Connect the demo back to the evidence: the exact minute/cost from 0:00–0:30, removed by the exact action just shown. One before/after number. No new claims — only numbers already evidenced. |
| 3:45–4:40 | **Market expansion** | **25** | First users, then global — in that order. Who are the first 10 users (named segment, where to reach them), what the wedge is, and why the same flow travels (same phone, same task, new language/market). Real users, if any exist, are an advantage (GOAL.md) — name them. No TAM slide, no "billion-dollar market" claim. |
| 4:40–5:00 | **Close — the ask** | — | One sentence: what you built, who it is for, what happens next (first pilot / first 10 users this week). Stop talking. Leave the phone on the finished screen. |

### 4.1 Demo beats that prove each criterion (checklist for the speaker)

- **40 (demo):** kill-and-reopen first, live, on the real phone; main AI flow on real input; streaming visible; output editable before it matters; the removal test stated out loud.
- **35 (problem):** real user named; evidence with source + date; before/after number tied to the demo action just shown.
- **25 (expansion):** first 10 users named by segment and channel; global path is the same flow in a new market, not a new product.
- **Anti-patterns (score 0):** demo on browser/emulator/photo/video; a bolted-on chatbot tab; slides instead of the phone; a market claim with no first users; a problem claim with no evidence.

### 4.2 What this brief does NOT cover

- Rehearsal runs and their timing (separate subagent).
- The product idea itself (humans decide beforehand — GOAL.md).
- The hour-by-hour build plan (runbook: `FLEET-MODE.md` / GOAL.md §5h plan).

---

## Sources (all accessed 2026-11-12 unless stated)

- `~/workspace/research_notes/mobile-ui-ux-effects-20261112/report.md` — accessed 2026-11-12 (report date); re-read 2026-11-13.
- `~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md` — accessed 2026-11-12 (report date); re-read 2026-11-13.
- `~/workspace/goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md` — read 2026-11-13 (rules verified 2026-11-12 from the official Lu.ma page; the live Lu.ma page was not re-opened in this pass — **CHƯA ĐỌC**).
- `~/frontend-agent-kit/repo/skills/mobile-kit/templates/theme.ts` — read 2026-11-13, HEAD `907aeaa`.
- `~/frontend-agent-kit/repo/skills/mobile-kit/templates/snippets.tsx` — read 2026-11-13, HEAD `907aeaa`.
- `~/frontend-agent-kit/repo/skills/frontend-kit/references/reference-sites.md` — read 2026-11-13 (restates a Yates TikTok clip; original video **CHƯA ĐỌC**).
- `~/frontend-agent-kit/repo/AGENTS.md` — read 2026-11-13.
- External URLs cited inline with access date 2026-11-12: https://expo.dev/changelog/sdk-57, https://expo.dev/changelog/sdk-58, https://docs.expo.dev/versions/v57.0.0/sdk/linear-gradient/, https://docs.expo.dev/versions/v57.0.0/sdk/blur-view/, https://docs.expo.dev/versions/v57.0.0/sdk/glass-effect/, https://docs.expo.dev/versions/v57.0.0/sdk/haptics/, https://docs.expo.dev/versions/v57.0.0/sdk/safe-area-context/, https://docs.expo.dev/versions/v57.0.0/sdk/ui/universal/bottomsheet/, https://docs.swmansion.com/react-native-reanimated/docs/layout-animations/entering-exiting-animations/, https://docs.expo.dev/more/create-expo/, https://reactnavigation.org/docs/shared-element-transitions/, https://rive.app/docs/runtimes/react-native/adding-rive-to-expo, https://newly.app/guides/eas-build, https://www.skillsdirectory.com/skills/majiayu000-app-ui-design-spellbook.

## Bài học

- **Nhãn "đã xác minh" chỉ dùng khi đã mở đọc toàn văn nguồn chính.** Hai khoảng trống lớn nhất của brief này — định dạng artefact nộp bài và danh tính điện thoại demo — đều được ghi rõ là CHƯA XÁC MINH / mâu thuẫn thay vì đoán, vì đoán sai một trong hai là mất điểm trực tiếp (nộp sai định dạng, demo sai máy).
- **Rủi ro lớn nhất không phải code khó mà là tương thích chưa kiểm chứng:** Expo Go SDK 57 chờ phê duyệt store, EAS queue 90+ phút, Hermes streaming — mỗi cái đều có thể đốt nửa sprint nếu chọn sai, và đều rẻ hơn nhiều nếu test trên đúng máy demo tối nay.
- **Tokens trước màn hình:** một file `theme.ts` chốt trước 11:00 rẻ hơn mọi giờ sửa drift sau đó; taste lock trên mobile là DESIGN.md 10–15 dòng do người viết, vì agent không tiêu thụ được ảnh đẹp.
