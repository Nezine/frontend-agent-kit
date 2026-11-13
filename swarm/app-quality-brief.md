# App-Quality Brief — Accessibility + Performance + State (Expo SDK 57 demo app)

- **Repo:** phamTuan207/muse-fleet (VM clone `~/frontend-agent-kit/repo`, HEAD 907aeaa)
- **Context:** Codex Hackathon, Sat 14/11/2026, build 11:00–16:00. Stack: Expo + React Native + TypeScript SDK 57, Convex primary / Supabase fallback. Demo on the real demo phone (identity unresolved — see phone brief §0: Android primary per GOAL.md vs iPhone 11 Pro Max per mobile toolkit report) — kill + reopen, main AI flow live.
- **Inputs read:** `~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md`, `~/workspace/research_notes/mobile-ui-ux-effects-20261112/report.md`, `~/workspace/research_notes/backend-agent-toolkit-20261112/report.md` (all accessed 2026-11-12 by their authors), and `skills/mobile-kit/templates/theme.ts` (existing token template, audited below).
- **Web verification in this brief:** 2026-11-13. Every factual claim carries a URL + access date. Numbers labelled **[BUDGET]** are team decisions for the 5-hour sprint, NOT measured facts — do not quote them as benchmarks. Numbers labelled **[CALC]** were computed by the author from the cited formula and the token values in `theme.ts`.
- **Free legal sources only.** Nothing in this brief was taken from a paywalled or pirated source. Items marked **CHƯA ĐỌC** were not opened in full — do not present them as verified.

## 0. The one honest correction first — pa11y does NOT test a native app

The kit's web gate runs `npx pa11y --standard WCAG2AA` (pa11y README: `--standard` accepts `WCAG2A`, `WCAG2AA` (default), `WCAG2AAA`; https://raw.githubusercontent.com/TheSlideFactory/pa11y-accessability/master/README.md — accessed 2026-11-13). [PROVENANCE NOTE: this URL is a fork README (misspells "accessibility") — re-cite from the official pa11y docs before quoting; the `--standard` values themselves are correct.] Pa11y runs accessibility tests **on web pages via the command line / Node.js** against a URL or HTML file. A React Native app rendered by Expo Go has no URL and no DOM for pa11y to scan.

**Consequence for the gate:** pa11y WCAG2AA stays in the gate ONLY for web surfaces (landing page / docs / any web fallback). The native-app a11y gate is the manual checklist in §1 below, run on the real demo phone with VoiceOver/TalkBack + the 200%-text test. Any claim of "pa11y passed the app" is false — pa11y never saw the app. Automated tools catch only ~30–50% of WCAG violations in any case (https://github.com/tyler-r-kendrick/agent-skills/blob/HEAD/skills/testing/accessibility-testing/SKILL.md — accessed 2026-11-13); the rest is manual.

---

## 1. ACCESSIBILITY — checklist (WCAG 2.1 AA, native-mapped)

### 1.1 Contrast — exact numbers

WCAG 2.1 Level AA, Success Criterion 1.4.3 Contrast (Minimum): **normal text ≥ 4.5:1, large text (≥18pt / 24px, or ≥14pt / 18.66px bold) ≥ 3:1**; SC 1.4.11 Non-text Contrast: **UI components and meaningful graphics ≥ 3:1** against adjacent colours. AAA raises these to 7:1 / 4.5:1 (not required). (https://www.accessitool.com/blog/color-contrast-guide-wcag-21-aa-standards-examples-2026 — accessed 2026-11-13; corroborated https://pikkit.net/guides/wcag-contrast-ratio-explained/ — accessed 2026-11-13.)

#### Audit of the existing `theme.ts` tokens — [CALC], WCAG relative-luminance formula `(L1+0.05)/(L2+0.05)`

| Pair (from `theme.ts`) | Ratio | AA verdict |
|---|---|---|
| `text` #0A0F1E on `background` #FFFFFF | **19.09:1** | ✅ PASS normal text |
| `textSecondary` #5B6472 on #FFFFFF | **5.98:1** | ✅ PASS normal text |
| `textSecondary` #5B6472 on `surface` #F6F6F4 | **5.53:1** | ✅ PASS normal text |
| `text` #0A0F1E on `surface` #F6F6F4 | **17.64:1** | ✅ PASS |
| `brand` #2547F4 on #FFFFFF | **6.39:1** | ✅ PASS normal text |
| `textInverse` #FFFFFF on `brand` #2547F4 | **6.39:1** | ✅ PASS normal text (white button text on brand is safe) |
| `brand` #2547F4 on `brandSoft` #E4E9FE | **5.29:1** | ✅ PASS normal text |
| `error` #D92D20 on #FFFFFF | **4.83:1** | ✅ PASS normal text (just above the line — do not lighten it) |
| `success` #1F9D63 on #FFFFFF | **3.46:1** | ❌ **FAIL normal text** — passes only large text / icons (≥3:1). Never use for body-size text. Fix before the demo: darken to ≈ #157347 or use it only for ≥18pt text and icons. |
| `warning` #C77D0A on #FFFFFF | **3.30:1** | ❌ **FAIL normal text** — same rule as success. Darken to ≈ #8A5A00 for body text, or restrict to large text/icons. |
| `border` #E3E5E8 on #FFFFFF | **1.26:1** | ❌ **FAIL non-text 3:1** — a border this faint may never be the *only* indicator of anything (input boundary, focus, selected state). Pair every bordered control with a label, icon, or background change. Decorative-only use is fine. |

**Gate rule:** every text colour in the app must be measured against its actual background before 15:00. The two failing tokens above are the known failures — fix them, don't re-measure them hoping for a different number.

### 1.2 Tap targets — exact numbers

- **iOS (Apple Human Interface Guidelines): minimum 44×44 pt.** **Android (Material Design): minimum 48×48 dp.** WCAG 2.2 AA floor (SC 2.5.8 Target Size Minimum) is lower — **24×24 CSS px** — but that is the legal floor, not the design goal; WCAG 2.2 AAA (SC 2.5.5) is 44×44. (https://www.html-hunter.com/touch-target-size-guidelines-how-big-should-mobile-buttons-be-in-2026/ — accessed 2026-11-13; https://www.humanstandards.org/ergonomics/targets-spacing/ — accessed 2026-11-13.)
- **Team rule [BUDGET]: 48×48 minimum for every tappable element on both platforms** (covers iOS 44 and Android 48 with one number). The *visible* icon may be 16–24px; the *hit area* is what counts — add padding/`hitSlop` to reach 48. Minimum **8dp spacing** between neighbouring targets (same sources).
- Primary CTA: **≥56px tall** [BUDGET] — the demo judge taps it while nervous, holding the phone, talking. Bigger is free; a missed tap on camera is not.

### 1.3 Screen reader — props and order

React Native maps accessibility props to native VoiceOver (iOS) / TalkBack (Android) (https://reactnative.dev/docs/0.86/accessibility — accessed 2026-11-13):

| Prop | Rule for this app |
|---|---|
| `accessible` | `true` on every composite control (card, row, custom button) so children group into one focusable element. |
| `accessibilityLabel` | **Mandatory on every icon-only control.** A screen reader verbalises this string; without it an icon button announces nothing useful. Visible-text buttons may rely on their text. |
| `accessibilityRole` | Set on everything that is not plain `Text`/`View`: `button`, `header`, `link`, `image`, `search`, `switch`, `checkbox`, `progressbar`, `adjustable`. |
| `accessibilityState` | Keep in sync with visual state: `{ disabled, selected, checked, busy, expanded }`. The AI "thinking" state MUST set `busy: true` — otherwise a screen-reader user hears a dead button. |
| `accessibilityHint` | Short outcome statement where the result isn't obvious from the label ("Sends the prompt and shows the answer"). Skip where the label already says it. |
| `accessibilityLiveRegion` (Android) / `AccessibilityInfo.announceForAccessibility` | AI answer arrival and error arrival must be **announced** — a blind user gets no visual streaming cue. Announce once on completion, not per token. |
| `accessibilityValue` | `{ min, max, now }` on any progress/slider. |

**Focus order:** logical reading order = visual order, top to bottom. No focus traps: the BottomSheet (`@expo/ui`, verified in the UI/UX report) must return focus to its trigger on dismiss. **CHƯA ĐỌC:** the exact `@expo/ui` BottomSheet focus-return behaviour was not verified against its docs in this pass — test it on the phone, don't assume it.

### 1.4 Dynamic type — text must survive 200%

- WCAG 2.1 AA SC 1.4.4 Resize Text: **text must remain readable and functional when resized to 200%** without loss of content or functionality (https://www.audioeye.com/post/wcag-checklist/ — accessed 2026-11-13; mobile mapping: support Dynamic Type / font scaling up to 200% minimum, https://accessibility.arizona.edu/web-apps/mobile-app-accessibility-roadmap — accessed 2026-11-13).
- React Native: `allowFontScaling` defaults to `true`; **never set `allowFontScaling={false}` globally** (https://reactnative.codeguides.io/accessibility/dynamic-type-and-font-scaling/ — accessed 2026-11-13; https://copyprogramming.com/howto/how-to-disable-font-scaling-in-react-native-for-ios-app — accessed 2026-11-13). Cap selectively with `maxFontSizeMultiplier`: body text **uncapped**, buttons **1.3–1.5**, tab labels **1.1–1.2**, chips/badges **1.1** (same codeguides source). `maxFontSizeMultiplier={0}` = unlimited; `1` = no scaling.
- **Test:** iOS Settings → Accessibility → Display & Text Size → Larger Text → maximum; Android Settings → Display → Font size → largest. Layout must reflow (wrap, grow vertically) — **no fixed heights on any text container**, no clipped text, no overlapping elements. `lineHeight` must scale with `fontSize` — use the token pairs in `theme.ts` (16/24, 20/26…), never a bare `fontSize`.
- **Reduced motion:** honour the system setting — check `AccessibilityInfo.isReduceMotionEnabled()` and skip/disable spring + stagger animations when on (the UI/UX report's motion budget assumes motion is on; the a11y gate requires the off-path to exist). **CHƯA ĐỌC:** the exact `AccessibilityInfo` API surface for SDK 57 was not re-opened in this pass — verify the import before wiring it.

### 1.5 The 30-second judge test (what a judge can spot without trying)

A judge holding the phone for 30 seconds can see, in order: (1) **can I read it?** — body text is ≥16pt (`theme.ts` body 16/24, minimum 16pt per UI/UX report) and not light-grey-on-white; (2) **can I tap it?** — the main CTA is big, thumb-reachable (bottom half of the screen), and gives instant feedback (press-scale + haptics); (3) **do I know what happened?** — every tap produces a visible state change within ~100ms, the AI state is labelled ("Thinking…", not a bare spinner); (4) **does it survive my thumb?** — no text clipped at the notch, no button under the home indicator (safe-area insets on every screen). If any of these four fails, the app reads as unfinished regardless of the AI quality. None of the four needs a screen reader to check — but all four are also the screen-reader prerequisites.

### 1.6 A11y gate checklist (run 15:00–15:30 on the demo phone)

- [ ] Contrast: every text pair measured; `success`/`warning` fixed or restricted to large text/icons; `border` never the sole indicator.
- [ ] Tap targets: every interactive element ≥48×48 hit area, ≥8dp apart (measure the two smallest icons by hand).
- [ ] Labels: every icon-only button has `accessibilityLabel`; every control has `accessibilityRole`; AI busy state sets `accessibilityState={{ busy: true }}`.
- [ ] Dynamic type: largest system text — no clipping, no overlap, no fixed-height truncation on the main flow.
- [ ] Screen reader: VoiceOver/TalkBack walkthrough of the main flow — can a blind user trigger the AI action and hear the result announced?
- [ ] Reduced motion: toggle it on — animations off, content identical.
- [ ] Safe area: notch + home indicator clear on every screen; nothing tappable under the system gesture zones.
- [ ] pa11y WCAG2AA run on any **web** surface only (see §0) — record "N/A — native app" for the app itself, do not fake a pass.

---

## 2. PERFORMANCE — budget

### 2.1 The budget table ([BUDGET] = team decision; sourced rows marked)

| Metric | Budget | Basis |
|---|---|---|
| Cold start: kill → first interactive screen (Expo Go + Metro tunnel, demo phone) | **≤ 2.0 s** perceived; hard fail > 3.5 s | [BUDGET]. Context: Hermes precompiles JS to bytecode ahead of time, eliminating JIT warm-up; RN 0.71 release notes cited for ~30% smaller bundle and ~20% faster cold start vs JSC on mid-range Android (https://dev.to/techamit95ch/startup-time-budget-for-react-native-apps-using-hermes-2epo — accessed 2026-11-13). A 5 MB JS bundle takes 2–3 s just to parse on older devices (https://dev.to/eira-wexford/improving-startup-time-in-large-scale-react-native-apps-134p — accessed 2026-11-13) — so the bundle cap below is what buys the 2 s. Note: in Expo Go the JS loads from Metro over the tunnel, so venue Wi-Fi/tunnel latency is inside this number; measure it on the venue network, not the office. |
| JS bundle (compressed `.hermes`) | **≤ 5 MB** | Sourced budget figure from the Hermes startup-budget guide above (≤5 MB compressed, total cold start ≤1,500 ms target on Pixel 5). Treat as a cap, not a measured fact for this app. |
| Images | **≤ 200 KB each, ≤ 1 MB total on the first screen**; `expo-image` only, never RN `Image` (disk+memory cache, 2–3× faster lists — mobile-agent-toolkit report §3, accessed 2026-11-12) | [BUDGET] for the caps; `expo-image` rule sourced from the toolkit report. No remote image may block first paint — blurhash/placeholder first. |
| AI first token | **≤ 3 s** after tap on venue Wi-Fi / mobile data | [BUDGET]. Streaming via `import { fetch } from 'expo/fetch'` — Hermes' built-in fetch has no `response.body` stream (toolkit report §6 failure #1, accessed 2026-11-12). If first token hasn't arrived by 3 s, the UI must already be showing the waiting state from §2.2 — the user must never stare at a dead screen. |
| AI full answer | **≤ 15 s**; abort + retry offered at 15 s | [BUDGET]. Abort on navigate-away, background, and Stop-button tap — a stream nobody reads still bills tokens (toolkit report §6 failure #12). |
| Interaction response | **≤ 100 ms** visual feedback on every tap (press-scale / opacity) | [BUDGET]. Animate transform + opacity only (GPU); never animate layout (UI/UX report §3.3). |
| List scroll | **60 fps, no dropped frames on the demo phone**; `FlashList` for any list > 20 rows | [BUDGET] for the fps target; FlashList rule from Vercel RN skills via UI/UX report §3.5. |

### 2.2 What the screen shows while waiting (exact)

The waiting state is a product decision, not a spinner choice. Rule: **never a bare spinner, never a blank screen.**

| Wait | Show |
|---|---|
| 0–300 ms after tap | Instant press feedback (scale 0.9 → spring to 1, 120 ms) + button enters `busy` state (disabled, label changes to verb, e.g. "Thinking…"). |
| 300 ms – first token | **Skeleton, not spinner.** DIY pulse skeleton (Animated core, opacity 0.4 → 1 loop, cost 1/5, 0 dependencies — UI/UX report §2 #7, accessed 2026-11-12) shaped like the answer (title line + 3 body lines). Skeleton = the user can already see *where* the answer will land. |
| First token → complete | **Streamed tokens as they arrive**, rendered progressively. Show a Stop button from the first token. Do not wait for the full response to render anything. |
| > 3 s, no token yet | Keep the skeleton; add one line of honest status: "Still thinking — the connection is slow." No fake progress bar (a fake bar is a lie the judge will notice). |
| > 15 s or error | Replace skeleton with a real error card: what happened in plain words + **Retry** (primary, 56px) + **Use the saved example** (secondary — loads the canned result, see §4 rung 1). Never leave the skeleton up forever. |
| Offline (no network at tap) | Do not attempt the call. Show the offline banner + the last good result if one exists (§3), with "Saved — from 12:40" timestamped. |

### 2.3 What to cut first when slow (cut order — do not debate, cut in this order)

1. **Lottie / heavy animations** — test-or-drop in the first 15 minutes of the sprint (UI/UX report §2: Lottie-in-Expo-Go is unresolved between sources).
2. **Blur / glass effects** — `expo-blur` is cheap on iOS, a trap on Android without `BlurTargetView` + `blurMethod` (UI/UX report §3.3); cut Android blur first, keep the `rgba` fallback.
3. **Images beyond the first screen** — lazy-load; nothing off-screen may compete with first paint.
4. **Second AI feature / second slice** — the demo is one AI flow done well; a second half-working flow costs the pitch.
5. **Dark-mode token variants** — lock dark for the pitch if time is short (UI/UX report §4.2 decision) rather than shipping two half-tested themes.
6. **Never cut:** the skeleton/loading states, the error + retry path, the 48px targets, the contrast fixes. Cutting those is cutting the demo's floor.

---

## 3. STATE MANAGEMENT — Zustand + TanStack Query

Pattern (from the mobile-agent-toolkit report §3, accessed 2026-11-12): **local `useState` for component state; Zustand for global client state; TanStack Query for server state — never duplicate server caches in Zustand; Context only for infrequent updates (auth, theme).**

### 3.1 The split (which state lives where)

| State | Owner | Why |
|---|---|---|
| Current input / draft, selected item, sheet open, AI streaming text (in-flight) | Zustand (in-memory) or `useState` | Client-owned, ephemeral; dies with the screen. |
| Last good AI result, history list | **TanStack Query cache, persisted** | Server-owned data; the cache is the copy, the server is the truth. |
| Theme, onboarding-done flag, demo seed choice | Zustand + `persist` middleware | Small, serialisable, must survive kill/reopen. |
| Tokens / secrets | `expo-secure-store` ONLY | AsyncStorage is plaintext on disk (toolkit report §3). Never AsyncStorage, never `EXPO_PUBLIC_` vars, never in the bundle. |
| Queued user actions made while offline | Durable outbox queue (see §3.3) | Must survive kill/reopen; a plain in-memory array does not. |

### 3.2 Zustand — exact pattern

- `persist` middleware + `createJSONStorage(() => AsyncStorage)` writes the store on every change and rehydrates on launch (https://dev.to/james_mugambi_494c7da2b07/mastering-state-management-in-react-native-with-zustand-a-modern-guide-1bfd — accessed 2026-11-13; https://www.soumitrasaha.com/blogs/react-native-state-management/ — accessed 2026-11-13).
- **`partialize` is mandatory:** persist only the fields that must survive (theme, draft, last result id) — never loading flags, never in-flight streams, never functions (non-serialisable values are silently absent after hydration — same sources).
- **Hydration is async:** the first render or two happens before rehydration finishes — the store may briefly hold its initial (empty) state (https://codeversecreatives.shop/courses/react-native/week-06.html — accessed 2026-11-13). Gate on `useStore.persist.hasHydrated()` / `onFinishHydration` before rendering real content; never flash an empty state that then populates — the judge will read the flash as a bug.
- Selectors per component (`useStore(s => s.draft)`) — no whole-store subscriptions, no re-render storms.
- AsyncStorage has a **~6 MB limit on iOS** (dev.to Zustand guide above) — keep persisted state small; large history belongs in the TanStack persisted cache or the backend, not in Zustand.

### 3.3 TanStack Query — offline queue, optimistic updates

- **Online detection is not automatic on React Native:** `onlineManager` has no default event source on RN — wire it to NetInfo (`@react-native-community/netinfo`) or mutations *reject* instead of pausing (https://npm.io/package/query-outbox — accessed 2026-11-13, describing TanStack issue #4170; corroborated https://jared.lynskey.co.nz/en/posts/2026/2026-05-05-zustand-vs-react-query/ — accessed 2026-11-13). **This wiring is a pre-demo checklist item, not an assumption.**
- **Offline behaviour, exactly:** with `networkMode: 'offlineFirst'`, mutations pause while offline and the optimistic update shows immediately; the real call fires on reconnect (same jared.lynskey source). Queries refetch when stale on reconnect; paused mutations resume.
- **The kill/reopen trap:** only mutation *state* is persisted, not the `mutationFn` — functions cannot be serialised. After a restart, a resumed mutation needs its function re-registered via `queryClient.setMutationDefaults(key, { mutationFn })` **at module load, before** `resumePausedMutations()` runs, or resumption throws `No mutationFn found` (https://npm.io/package/query-outbox — accessed 2026-11-13; https://dev.to/nainikmehta/offline-first-react-tanstack-query-indexeddb-patterns-13o4 — accessed 2026-11-13). **Rule for this app: register every mutation default at module load; persist only mutations you know how to rebuild (`shouldDehydrateMutation` filter); use client-generated UUIDs for anything created offline so a create-then-edit offline still works.**
- **Optimistic updates — the pattern:** `onMutate` writes the optimistic value into the cache (with a client UUID) and returns a rollback context; `onError` restores from context; `onSettled` invalidates the query. **No optimistic update without a rollback.** An optimistic write that cannot roll back is a lie the user cannot undo — worse than no optimistic update.
- **Cache persistence:** persist the query cache (queries + paused mutations) with `@tanstack/react-query-persist-client` + an AsyncStorage persister; restored data respects `staleTime` (https://copyprogramming.com/howto/react-query-mutation-and-use-query-persist — accessed 2026-11-13). Set `gcTime` to 24 h for the demo so a kill/reopen within the pitch still finds warm data.
- **Convex caveat [UNVERIFIED]:** Convex's reactive `useQuery` is the primary backend path (backend-agent-toolkit report §1, accessed 2026-11-12), but **Convex's offline behaviour on a killed-and-reopened Expo Go app was not verified in any source in this pass.** If the demo relies on Convex reactivity for the kill/reopen proof, test it on the real phone before 15:00 — do not assume TanStack's persistence semantics transfer to Convex's client. The TanStack cache is the safety net either way: the last good result must be readable from the persisted cache even if Convex is unreachable.

### 3.4 Kill-and-reopen matrix (the judge's test, mapped to state)

| State | After kill + reopen | How |
|---|---|---|
| Last AI result (the demo's proof) | **Survives** | Persisted TanStack cache (24 h `gcTime`) + persisted Zustand `lastResultId`. Screen renders from cache instantly, then refetches in the background. |
| Draft input | **Survives** | Zustand `persist` + `partialize` (draft only). |
| Theme / demo seed choice | **Survives** | Zustand `persist`. |
| Offline-queued actions | **Survive, replay in order** | Durable outbox (mutation defaults registered at module load); replay only after hydration. |
| In-flight AI stream | **Does NOT survive** (correct) | Stream is cancelled on kill; on reopen the screen shows the last *completed* result + a "Resume" affordance that re-runs the call. Never pretend a half-stream is a result. |
| Server data freshness | **Re-fetched** | Cache is stale-checked on mount; `staleTime` 60 s for the demo screen [BUDGET] — fresh enough to be live, long enough not to flash. |
| Auth/session | **N/A — no auth in the demo** | No sign-up wall before the judge sees the product (backend-agent-toolkit report §3.2). |

### 3.5 What to do when the network drops mid-demo (script, not hope)

1. NetInfo fires → banner appears ("You're offline — showing the saved result") within 1 s; the AI button stays tappable but explains on tap ("Needs connection — your draft is saved").
2. Any action taken offline goes into the outbox with a client UUID and an optimistic UI update; the item is visibly marked "Queued — will send when you're back".
3. On reconnect: outbox replays in order, each item flips from "Queued" to "Sent"; any failure rolls back with the error shown on that item, not a global toast.
4. If the drop happens *during* an AI stream: abort the stream, keep the partial tokens visible labelled "Partial — connection dropped", offer **Resume** (re-runs from the draft) — never silently discard partial output the judge already read.

---

## 4. DEGRADED MODE — the app stays demoable with no network, no AI, and no backend

Three rungs, each strictly worse than the one above, each still showing something **real** — never a fake loading screen, never a mocked screenshot. The presenter announces the rung out loud ("We're on the offline rung — here's what the app does with no connection") and the demo continues.

### Rung 1 — No AI (backend up, model down / key missing / provider error)

- **What works:** the full UI, the full input flow, the real backend endpoint (Convex action / Supabase Edge Function answers with a **canned result** — the same JSON shape, labelled "Example result" in the UI).
- **What is real:** the canned result is a genuine, pre-written example of the exact output shape (same fields, same rendering path). The user can edit it, accept it, and see the downstream flow. The label is honest — the judge sees "Example" and knows the live model is down, instead of being fooled.
- **Trigger:** provider error, timeout > 15 s, or missing backend secret. Automatic — the app falls back without the presenter touching anything, and says so on screen.
- **Kill/reopen:** works — the canned result is cached like a real one (§3.4).

### Rung 2 — No network (venue Wi-Fi dead, phone on no data)

- **What works:** everything Rung 1 does, plus the **last good result** from the persisted cache (timestamped: "Saved — 12:40, from when you were online"), the draft, and the full offline queue (§3.5). New inputs queue visibly.
- **What is real:** the saved result is a real result from a real earlier run, not a placeholder. The queue is a real queue — reconnect and it replays.
- **Trigger:** NetInfo offline, or every request failing. The offline banner is permanent while offline; the app never retries in a tight loop (backoff, not hammering).
- **Kill/reopen:** works — cache + queue are persisted (§3.4). This is the rung the kill/reopen test lands on if the venue network dies mid-pitch.

### Rung 3 — No backend at all (Convex/Supabase unreachable, Metro tunnel dead, fresh install with nothing cached)

- **What works:** a **bundled seed dataset** shipped in the app bundle (3–5 complete, real example records + 1 complete example AI result, as static JSON in the repo — no network, no backend, no Metro). The app boots to a working product: browse the seed data, run the input flow, see the example result, edit it. Every screen renders; every button does something true.
- **What is real:** the seed data is real content written for the demo (not lorem ipsum, not a screenshot). The flow is the real flow with a local data source swapped in — one `dataSource` flag, not a second app.
- **Trigger:** manual — a "Demo offline" toggle in settings, or automatic after 2 consecutive backend failures at startup. The presenter can switch to it *before* the pitch if the venue is known-dead.
- **Kill/reopen:** works trivially — the seed is in the bundle; there is nothing to lose.
- **Cost to build:** ~30 minutes [BUDGET] — one seed JSON file + the `dataSource` switch + the honest "Offline demo data" label. It is the cheapest insurance in the whole brief: it converts a total demo failure (0/40) into a degraded-but-real demo.

### Degraded-mode gate (15:00 rehearsal — rehearse all three, not just the happy path)

- [ ] Rung 1: kill the provider key (or point at a dead endpoint) — canned result appears, labelled, within the normal latency.
- [ ] Rung 2: airplane mode on the demo phone — saved result + banner + queued action; kill + reopen in airplane mode, everything still there.
- [ ] Rung 3: airplane mode + clear app data — seed data boots, full flow works, label visible.
- [ ] The presenter can name the current rung in one sentence at any moment. If they can't, the rung isn't ready.

---

## 5. Sources

All web sources accessed **2026-11-13** unless noted. The three research reports were accessed **2026-11-12** by their authors (their own source lists apply).

- WCAG contrast (AA 4.5:1 / 3:1, large-text definition, non-text 3:1): https://www.accessitool.com/blog/color-contrast-guide-wcag-21-aa-standards-examples-2026 ; corroboration: https://pikkit.net/guides/wcag-contrast-ratio-explained/
- Tap targets (44pt iOS / 48dp Android / WCAG 2.2 AA 24px / AAA 44px, 8dp spacing): https://www.html-hunter.com/touch-target-size-guidelines-how-big-should-mobile-buttons-be-in-2026/ ; https://www.humanstandards.org/ergonomics/targets-spacing/
- React Native accessibility props: https://reactnative.dev/docs/0.86/accessibility (official)
- WCAG 1.4.4 resize 200% + 2.5.8 target size: https://www.audioeye.com/post/wcag-checklist/ ; mobile mapping: https://accessibility.arizona.edu/web-apps/mobile-app-accessibility-roadmap
- Dynamic type / `maxFontSizeMultiplier` caps: https://reactnative.codeguides.io/accessibility/dynamic-type-and-font-scaling/ ; https://copyprogramming.com/howto/how-to-disable-font-scaling-in-react-native-for-ios-app
- pa11y CLI / `--standard WCAG2AA`: https://raw.githubusercontent.com/TheSlideFactory/pa11y-accessability/master/README.md ; automated-tools catch 30–50%: https://github.com/tyler-r-kendrick/agent-skills/blob/HEAD/skills/testing/accessibility-testing/SKILL.md
- Hermes startup / ≤5 MB compressed bundle: https://dev.to/techamit95ch/startup-time-budget-for-react-native-apps-using-hermes-2epo ; 5 MB bundle ≈ 2–3 s parse: https://dev.to/eira-wexford/improving-startup-time-in-large-scale-react-native-apps-134p
- Zustand `persist` + AsyncStorage + `partialize` + async hydration: https://dev.to/james_mugambi_494c7da2b07/mastering-state-management-in-react-native-with-zustand-a-modern-guide-1bfd ; https://www.soumitrasaha.com/blogs/react-native-state-management/ ; https://codeversecreatives.shop/courses/react-native/week-06.html
- TanStack Query offline (onlineManager/NetInfo, `setMutationDefaults`, `resumePausedMutations`, functions-not-serialised): https://npm.io/package/query-outbox ; https://dev.to/nainikmehta/offline-first-react-tanstack-query-indexeddb-patterns-13o4 ; https://jared.lynskey.co.nz/en/posts/2026/2026-05-05-zustand-vs-react-query/
- TanStack cache persistence / `gcTime`: https://copyprogramming.com/howto/react-query-mutation-and-use-query-persist
- Stack & failure modes (Expo Go, `expo/fetch` streaming, secrets in `expo-secure-store`, no auth wall): `~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md` (2026-11-12)
- Motion, skeleton, blur/Android trap, `theme.ts` type scale: `~/workspace/research_notes/mobile-ui-ux-effects-20261112/report.md` (2026-11-12)
- Backend (Convex primary / Supabase fallback, one AI endpoint, share-link persistence): `~/workspace/research_notes/backend-agent-toolkit-20261112/report.md` (2026-11-12)
- Token values audited: `~/frontend-agent-kit/repo/skills/mobile-kit/templates/theme.ts` (repo HEAD 907aeaa)

### CHƯA ĐỌC / UNVERIFIED (do not present as verified)

- `expo/fetch` streaming — UNVERIFIED against Expo docs (free-tier verification 13/11); ship the demo on plain non-streaming fetch + JSON parse; streaming is a nice-to-have only if verified first.
- `@expo/ui` BottomSheet focus-return behaviour on dismiss.
- `AccessibilityInfo.isReduceMotionEnabled()` exact API surface on SDK 57.
- Convex `useQuery` offline behaviour on a killed-and-reopened Expo Go app.
- Whether the App Store / Play Store Expo Go is SDK 57 on 14/11 (from the UI/UX report §1 — test on the demo phone).
- Any claim in this brief labelled [BUDGET] is a team decision, not a measured benchmark.

---

## Bài học

- **The gate must match the platform:** pa11y tests web pages, not native apps — importing the web gate verbatim would have produced a fake "pass". A checklist is only a gate if it can actually see the thing it gates.
- **Measure the tokens you already have before adding new ones:** the existing `theme.ts` already passes AA for body text — except `success` and `warning`, which fail at 3.46:1 and 3.30:1. Two small darkening fixes buy the whole contrast story; no palette redesign needed.
- **Persistence is not one thing:** Zustand `persist`, TanStack cache persistence, and the mutation outbox each survive kill/reopen differently — and the mutation function itself never survives serialisation. The kill/reopen test passes only if each layer's rule (defaults at module load, `partialize`, `gcTime`) is wired deliberately.
- **A degraded mode is not a backup video:** each rung shows something real through the real UI. The cheapest 30 minutes in the sprint (bundled seed data) is what stands between a dead venue network and 0/40.
