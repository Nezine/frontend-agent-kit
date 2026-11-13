# Feasibility — Cost — Backup Brief (muse-fleet, Codex Hackathon 14/11/2026)

**Scope:** METHOD + machinery only. This brief does **not** validate any specific idea candidate — a separate subagent owns idea validation. Do not use this brief as evidence that any particular idea works.
**FREE-ONLY CORRECTION (2026-11-13, parent 09:41): the paid-model cost table (§2.2) and the $5 spend cap (§2.3) are SUPERSEDED and kept here only as a record of the retired plan. The demo path is $0: Supabase Edge Function free tier + free-tier model API (Gemini free tier primary). OUT: Convex AI Gateway (paid), GPT-5 mini/nano, GPT-5, Sonnet 4.5/5.5, Haiku, any OpenAI/Anthropic key, any paid model API, paid EAS builds. The $50 attendee OpenAI credit is NOT planned on (paid API). The binding constraint is now free-tier rate limits (Gemini free tier fails rather than bills), not money. See `swarm/free-tier-ai-path.md` for the verified free-only path. Also: `gemini-2.5-flash` is deprecated, shutdown 1 Dec 2026 — do NOT pin it; primary is `gemini-3.5-flash-lite` (verified free of charge), fallback Groq `openai/gpt-oss-120b`.**
**Event:** Sat 14/11/2026, 09:00–19:00, Biblio Book Cafe, 79 Ngụy Như Kon Tum, Thanh Xuân, Hà Nội; build 11:00–16:00, submission 16:00, pitches 16:15 (5 min/team). Source: Lu.ma Codex Community calendar, accessed 2026-11-13 — https://luma.com/codex-community?utm_source=oaidevs
**Scoring (as recorded in the goal file, verified 2026-11-12 from the official Lu.ma page):** 40 = live AI demo on a real phone (kill + reopen, main AI flow live; browser/emulator/photo/video = 0); 35 = real user problem WITH EVIDENCE, AI helps directly; 25 = market expansion (first users + global; real users an advantage). Tiebreak 1→2→3. AI must be ESSENTIAL, not a bolted-on chatbot. Prep before the day is allowed, must disclose pre-built vs day-built. Source: `~/workspace/goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md` (internal record, 2026-11-12). The full Lu.ma scoring text was **CHƯA ĐỌC** in this pass — re-read the event page on the morning of 14/11 before the pitch.
**Council rules applied:** one fabricated claim voids the submission; free legal sources only; anything not read is marked **CHƯA ĐỌC**. All prices accessed 2026-11-13 unless stated otherwise. Prices move — re-check the provider pricing page on the morning of 14/11 before spending.

---

## 1. The 15-minute idea-feasibility triage (run on ANY idea, by any human)

**Setup (2 min, before the clock starts):** one person reads the idea aloud in one sentence — *"[User] does [action] in the app and gets [AI-produced outcome] that they could not get without the AI."* If that sentence cannot be written, the idea fails triage immediately. Write it at the top of `CONTRACT.md`. No code is written during triage.

### Step 1 — The user-evidence test (3 min) — maps to the 35 points
Ask, and demand a named answer, not a vibe:
1. **Who exactly?** Name one real person (or one named group) who has this problem *today*. "Everyone" = fail.
2. **What did they do last time?** A real workaround they already use (a spreadsheet, a chat group, paying someone, skipping the task). No workaround = the pain may not exist.
3. **What is the evidence in hand?** One of: a message/screenshot/quote from that person, a count (e.g. "spends ~40 min/day on this"), or a public source the team has actually opened. A claim with no artefact = 0 evidence.
4. **Would they use it tomorrow?** The test is a *return* test, not a "cool!" test: would the named person open it a second time without being asked?

**Pass bar:** Q1 + Q2 + Q3 all have a concrete answer. **Fail =** any answer is "users in general", "probably", or "we'll find out later". If it fails, do not proceed to Step 2 — fix the evidence first (message one real person) or kill the idea. This is the scoring rule in the goal file: 35 points need evidence, not slides.

### Step 2 — The AI-essentiality test (3 min) — maps to the 40 points
The question, verbatim: **"Does the product work the same with the AI removed?"**
- Run the core flow mentally with the AI replaced by (a) a fixed template, (b) a lookup table / a human-written rule, (c) a canned answer. If the user still gets ~the same outcome, the AI is decoration — fail.
- The AI must do one of these, and the demo must *show* it: generate something the user did not type (draft, summary, plan, diagnosis, ranking); decide something that varies per input (classify, prioritise, personalise); or transform unstructured input the user already has (photo, voice, messy text) into structured output they act on.
- Design rule from the mobile toolkit research: AI sits *inside* a flow the user already does (a "Summarise" action on content they have, a pre-filled form they confirm) — not a new tab with a sparkle icon and an empty chat box. Source: https://digital.moburst.com/how-to-add-an-ai-feature-to-an-existing-mobile-app/ — accessed 2026-11-12.
- **Pass bar:** removing the AI breaks the core flow or makes it pointless — not just slower. (Judgement call derived from the sources above + the hackathon's own "AI is essential" rule, per the mobile toolkit report, accessed 2026-11-12.)

### Step 3 — The scoring-fit scorecard (4 min) — 40 / 35 / 25 as checkable questions
Score each line 0 / 1 / 2. **Proceed only if total ≥ 4/6 and no line is 0.**

| # | Points | Checkable question | 2 = | 1 = | 0 = |
|---|---|---|---|---|---|
| A | 40 — live phone demo | Can a judge kill the app, reopen it, tap ≤3 times, and see the AI do its thing live in under ~30 s? | Yes, on the demo phone, already rehearsed | Yes in theory, untested on the phone | Needs signup, needs a second device, needs >1 min, or needs the laptop screen |
| B | 35 — real problem + evidence | Is there a named user + a real artefact of their pain (message, count, photo) the pitch can show? | Named person + artefact in hand | Named person, artefact promised | "Everyone has this problem" |
| C | 25 — first users + global | Can one stranger use it tomorrow without the team in the room, and does it work outside Vietnam? | Share link works, no Vietnamese-only dependency | Works, but needs hand-holding or local-only content | Needs the team to demo it for each user |

**Kill rule:** A = 0 kills the idea outright (40 points is the biggest bucket and it is binary: live phone or 0). B = 0 means "go get evidence in 30 min or kill it" — do not build on a promise of evidence.

### Step 4 — The cut test (1 min)
Verbatim, from the backend-research sources: **"If I removed 30% of this architecture, would the demo still work?"** Source: https://medium.com/@work.jdattani/i-tried-to-build-a-serious-backend-in-24-hours-and-broke-everything-0251ed25c717 — accessed 2026-11-12.
List the idea's parts; cross out the weakest 30% (second feature, history, settings, auth, analytics). If the demo still works, those parts were never needed — cut them *now*, in `CONTRACT.md`, not at 15:00. If removing 30% kills the demo, the idea is too coupled / too big for 5 hours — simplify the idea, not the schedule. AngelHack's version of the same rule: "Scope to one demoable path. One user, one action, one visible result… Anything that never reaches the screen scores nothing." Source: https://angelhack.com/blog/5-steps-from-idea-to-hackathon-winning-app/ — accessed 2026-11-12.

### Step 5 — Pre-mortem (2 min) — "how this idea dies on stage"
Each person names ONE way the demo dies in the 5-minute pitch, then the team writes the one-line countermeasure next to it. The standing list to check against (from the fleet research, accessed 2026-11-12):
1. **AI returns garbage / wrong answer on the judge's input** → counter: constrain output to structured JSON, cap output length, show the AI result as an editable draft the user confirms (never a silent decision). Source for the draft rule: https://digital.moburst.com/how-to-add-an-ai-feature-to-an-existing-mobile-app/ — accessed 2026-11-12.
2. **AI call is slow (>10 s) or times out on stage** → counter: cheapest fast model (see §2), `max_tokens` cap, non-streaming JSON first, visible progress + cancel.
3. **Venue Wi-Fi dies / Metro dies** → counter: preview build with bundled JS (see §3, Rung 1); backend/AI over mobile data, verified before the pitch.
4. **Expo Go / SDK mismatch — app won't open** → counter: scaffold SDK 57 unless the store Expo Go is proven SDK 58 on the demo phone (see §3). Source: https://expo.dev/changelog/sdk-58 — accessed 2026-11-12.
5. **Judge's input is empty / adversarial / in Vietnamese with diacritics the prompt never saw** → counter: one empty-input test + one adversarial-input test in the rehearsal; a graceful "I couldn't do that — try…" message, never a crash or a blank screen.
6. **The evidence story falls apart under one question** ("who exactly?") → counter: Step 1 artefact on the pitch slide, with the person's own words.

### Step 6 — Kill-switch criteria (when to abandon an idea mid-build)
Decide these **before** 11:00 and write them in `CONTRACT.md`. The Integrator calls them; no vote, no debate on the day.
- **T+1:20 checkpoint:** if the walking skeleton (phone opens the deployed URL, taps the demo script, gets a result — even canned) does not work, cut the idea to its smallest working form on the spot. Source for the checkpoint discipline: https://dev.to/whaiman/zero-to-demo-in-5-hours-a-survival-guide-for-your-first-ai-hack-day-3h4d — accessed 2026-11-12.
- **T+2:20 checkpoint (halfway):** if the REAL AI flow has not run live on the real phone twice in a row, abandon the current idea and fall back to the pre-agreed simpler idea — do not "finish the UI first".
- **Any time:** if the AI-essentiality test fails on the real build (the canned/template version gives the same result as the AI version), kill the AI feature as designed and re-scope to the one sub-flow where the AI genuinely changes the outcome; if there is none, kill the idea.
- **Fallback idea rule:** the team must pick ONE simpler fallback idea the night before (same user, same evidence, one AI action, no second feature). The fallback is not a second idea to build in parallel — it is the lifeboat, used only when a kill-switch fires.

**Triage output (one page, 15 min):** the one-sentence idea, Step 1 evidence artefact, Step 2 verdict, scorecard A/B/C, the 30% cut list, the top-3 pre-mortem deaths + countermeasures, the fallback idea name. If any section is blank, triage is not done.

---

## 2. Cost budget — AI API spend during build + demo

### 2.1 What the attendee credits cover
- Each checked-in attendee gets a credit pack totalling $150 in AI credits: **$100 Codex + $50 OpenAI API**. Source: Apero Technologies Group Facebook post, 2026-11-03 — https://www.facebook.com/aperogroup/posts/pfbid06LpXc2VNu9pVNDPxCCybU3jtPbCoAD8436X6DGcjykxcBmVEdXenf1jcbMHoSB1rl — accessed 2026-11-13. Same figure in the Codex Community Hanoi post, 2026-11-01 — https://www.facebook.com/permalink.php?story_fbid=pfbid02z9JAjTYaV5k357JyDs4BdVgEaNB9BGuWY9QYrEHZSvGUEGUk7ohTzvjHCKWhVykJl&id=61596072208681 — accessed 2026-11-13.
- Prizes (per the goal file): 1st $1,000 / 2nd $500 / 3rd $250 API credits per team + ChatGPT Pro 3 months/member. **CHƯA ĐỌC** — prize terms were not re-verified in this pass; do not budget on winning.
- **Pooling is UNVERIFIED:** whether the 4 members' $50 API credits can be pooled into one key/billing account was not verified — **CHƯA ĐỌC**. Budget on ONE person's $50 unless the team confirms pooling on the day. Even one $50 covers the demo need ~180× at the recommended model (mini) and ~900× at nano (see §2.3).

### 2.2 Per-call cost table — one standard demo call = 1,000 input + 500 output tokens
Arithmetic is shown so the team can recompute it; rates are third-party pages verified against the providers' own pricing pages on the dates stated. **Re-check the provider pricing page on 14/11 morning — model IDs and prices change, and two model families retire in Dec 2026 / Nov 2026 (see notes).**

| Model (provider) | Input / 1M | Output / 1M | Cost of 1 demo call (1k in + 500 out) | Source |
|---|---|---|---|---|
| GPT-5 nano (OpenAI) | $0.05 | $0.40 | **$0.00025** | https://geroundtable.com/openai-api-explained/ — checked 2026-11-06, accessed 2026-11-13; cross-check https://www.llm-cost.io/model/openai--gpt-5-nano/ — verified 2026-11-12 |
| GPT-5.4 nano (OpenAI) | $0.20 | $1.25 | **$0.00083** | https://apicost.app/pricing/openai/ — updated 2026-11-03, accessed 2026-11-13 |
| GPT-5 mini (OpenAI) | $0.25 | $2.00 | **$0.00125** | https://geroundtable.com/openai-api-explained/ — checked 2026-11-06, accessed 2026-11-13 |
| Gemini 2.5 Flash-Lite (Google) | $0.10 | $0.40 | **$0.00030** | https://creditforstartups.com/pricing/gemini-api-pricing — accessed 2026-11-13 (rates from Google pricing page, Sept 2026) |
| Gemini 2.5 Flash (Google) | $0.30 | $2.50 | **$0.00155** | https://creditforstartups.com/pricing/gemini-api-pricing — accessed 2026-11-13 |
| Claude Haiku 4.5 (Anthropic) | $1.00 | $5.00 | **$0.00350** | https://www.agent37.com/blog/claude-code-cost — accessed 2026-11-13 (Anthropic list prices) |
| GPT-5.4 mini (OpenAI) | $0.75 | $4.50 | **$0.00300** | https://apicost.app/pricing/openai/ — updated 2026-11-03, accessed 2026-11-13 |
| GPT-5 (OpenAI) | $1.25 | $10.00 | **$0.00625** | https://geroundtable.com/openai-api-explained/ — checked 2026-11-06, accessed 2026-11-13 |
| Claude Sonnet 5.5 (Anthropic) | $2.00 | $10.00 | **$0.00700** | https://www.glamdringresearch.com/post/claude-sonnet-api-pricing — checked 2026-09-28, accessed 2026-11-13; https://greenlightmyapp.com/blog/claude-api-pricing — checked 2026-10-21 |
| Claude Sonnet 4.5 (Anthropic) | $3.00 | $15.00 | **$0.01050** | https://apicost.app/pricing/claude-sonnet-4-5/ — updated 2026-11-03, accessed 2026-11-13 |

**Model-lifecycle warnings (do not build on a retiring model without a fallback ID):**
- GPT-5 / GPT-5 mini / GPT-5 nano retire **11 Dec 2026**; OpenAI names GPT-5.6 replacements, and the 5.6 promo pricing ends 30 Nov 2026 with the post-promo rate unpublished. Source: https://ecorpit.com/openai-gpt-5-o3-shutdown-december-2026-migration/ — checked 2026-11-11, accessed 2026-11-13. They are alive on 14/11, but the team should have the GPT-5.4 ID as the drop-in fallback.
- Claude Sonnet 4.5 retires **30 Nov 2026**; Anthropic recommends Claude Sonnet 5.5 ($2/$10). Source: https://aisignalhq.com/posts/claude-sonnet-4-5-retires-november-30-2026-cost-of-moving/ — updated 2026-10-23, accessed 2026-11-13.
- Gemini 2.5 Flash retirement was reported for Oct 2026 in one source, with Gemini 3.5/3.1 Flash-Lite named as replacements — **conflicting / CHƯA ĐỌC against Google's own lifecycle page**. Source: https://fastrouter.ai/feeds/blog/gemini-2-5-flash-pricing — accessed 2026-11-13. Do not rely on 2.5 Flash as the only Gemini option; verify the model ID answers a test call on 13/11.

### 2.3 The budget (hard caps — write these in `CONTRACT.md`)
- **Total demo-day AI spend cap: $5.00.** At the recommended model (below) that buys ~4,000 demo calls; at the most expensive model in the table (Sonnet 4.5, $0.0105/call) it still buys ~475 calls. The realistic day uses ~200 test calls during the build + ~20 calls in rehearsal/pitch = ~220 calls ≈ **$0.06–$2.31** depending on model. The $50 attendee credit is therefore not the constraint — **rate limits and latency are**.
- **Per-call caps (enforce in code, not by discipline):** `max_tokens` set so one call cannot exceed ~1,500 output tokens; system prompt kept short and cached where the provider supports it (OpenAI cached input for GPT-5 nano is $0.005/1M — source https://www.priceper1m.com/model/openai-gpt-5-nano — dataset 2026-11-12, accessed 2026-11-13); one retry maximum; 15-second timeout; abort the request when the user navigates away or backgrounds the app (a stream nobody reads still bills — mobile toolkit report, accessed 2026-11-12).
- **Recommended demo model (cheapest that still demos well): GPT-5 mini ($0.00125/call) as primary, GPT-5 nano ($0.00025/call) as the cost floor.** Rationale: mini is 5× the price of nano for the same call but is the smallest model the pricing sources describe as handling "classification, summarising, drafting, simple question-answering" — source https://geroundtable.com/openai-api-explained/ — checked 2026-11-06, accessed 2026-11-13. **Rule:** if the demo output is short structured JSON (a label, a rank, a 2–3-field object), nano is enough and the team should use it; if the output is free-form prose the judge reads, use mini. **Do not use GPT-5 / Sonnet 4.5 / Sonnet 5.5 for the demo path** — 5–40× the cost of nano for no scored benefit in a 5-minute pitch, and Sonnet 4.5 retires 30 Nov 2026. Gemini 2.5 Flash ($0.00155/call) is the equivalent fallback if the OpenAI key fails; its free tier is $0 subject to rate limits (see §2.4).
- **Backend (non-AI) cost: $0 on the day.** Convex free tier: 1M function calls/month, 0.5 GB DB storage, no inactivity pause. Supabase free tier: 500 MB DB, 50K MAU, 500K edge-function invocations — but free projects pause after 7 days of inactivity. Sources: https://www.guides.reviews/developer-tools/best-backend-as-a-service-baas-platforms-startups-2026 — numbers from vendor pricing pages, Nov 2026, accessed 2026-11-13; https://www.13labs.au/compare/supabase-vs-convex — updated 2026-10-05, accessed 2026-11-13. Consequence: Convex primary (no pause trap); if Supabase is used, the project must be created close to build day and verified live on the morning of 14/11. No paid tier is needed for the demo — do not enter a card on the day.

### 2.4 Rate limits and throttling — what happens if the provider throttles mid-demo
- **Gemini free tier:** free input/output tokens, rate-limited instead of billed; exceeding the limit makes requests **fail rather than being billed**. Source: https://creditforstartups.com/pricing/gemini-api-pricing — accessed 2026-11-13. That is the safe failure mode for a demo — but it is still a failure on stage, so the free tier is a *fallback*, not the primary, unless the team has load-tested it with the exact demo input.
- **OpenAI / Anthropic exact RPM/TPM for this team's tier: CHƯA ĐỌC.** No verified per-tier rate-limit number for the team's account was found in this pass — do not quote one. **Morning-of check (13/11 or 14/11 09:00):** open the provider dashboard, confirm the key, the model ID, and the usage/limit page; run 10 rapid demo calls in a row and confirm none is throttled.
- **Throttling defences (all in code before 15:00):** (1) one retry max, with a 2-second back-off, then show the cached last-good result (see §3); (2) a 15-second timeout that falls to the stub response with an honest on-screen label (see §3.3); (3) never fire two AI calls for one tap (no double-submit, no background re-fetch during the pitch); (4) keep the demo input short — a long prompt is what burns the input-token budget and trips per-minute token limits.
- **If throttled mid-demo:** do not tap again live. Say the one rehearsed line ("the live call is rate-limited right now — here is the result from 2 minutes ago, same input"), show the cached result, and move on. A calm fallback beats a second failed tap in front of judges.

---

## 3. Backup plan — fallback rungs (in order; each rung is a decision, not a hope)

**Principle:** each rung is strictly worse than the one above and strictly better than nothing. The Integrator calls the rung; the pitch never pretends a lower rung is a higher one.

| Rung | State | What the judges see | Trigger to drop to this rung |
|---|---|---|---|
| **Rung 0 — the plan** | Live AI on the real phone, Expo Go + Metro tunnel, Convex/Supabase backend, real provider call | Kill + reopen, tap, AI answers live | — |
| **Rung 1 — same phone, bundled JS** | Preview/dev build with JS bundled (no Metro dependency); backend + AI still live over mobile data | Same live flow, no laptop needed | Metro dies, laptop sleeps, venue Wi-Fi drops, tunnel fails |
| **Rung 2 — same phone, cached last-good** | App opens; AI endpoint unreachable; the app shows the last good AI result for the demo input, labelled "last live result, [time]" | The real UI + a real AI output from minutes earlier, honestly labelled | AI provider throttled / down, backend down, mobile data dead |
| **Rung 3 — backup video** | The pre-recorded video of the live flow (see §3.1) played on the phone/laptop | The live flow as it ran, with the recording's timestamp visible | Phone dies, app won't open at all |
| **Rung 4 — canned-response stub, honestly labelled** | The stub endpoint returns the pre-written response for the demo input; the UI says "demo mode — canned response" | The full flow, end to end, with the AI step visibly stubbed | Provider dead AND no cached result AND no video — last resort |
| **Rung 5 — pitch without the phone** | Evidence + scorecard story only; no demo claim | The problem, the evidence, the first-users plan | Nothing runs. Score the 35 + 25 honestly; do not claim the 40. |

**Failure-specific notes (from the fleet research, accessed 2026-11-12):**
- **Phone dies:** Rung 3 immediately. The backup phone (iPhone 11 Pro Max, per GOAL.md's Android-primary framing — NOT per the mobile report, which names it the demo phone) must have Expo Go installed and the app opened *before* 11:00 — do not install it during the pitch. Source for the Expo Go path: https://agentvera.dev/en/blog/build-mobile-app-with-ai/ — accessed 2026-11-12.
- **Network dies:** Rung 1 (bundled JS) + mobile data for the AI call. Verify the AI endpoint over mobile data, not just venue Wi-Fi, before the pitch — backend toolkit report, accessed 2026-11-12. A preview build bundles the JS, so only the backend/AI calls need internet — backend report, §4.2, accessed 2026-11-12.
- **AI provider dies:** Rung 2, then Rung 4. The stub must already exist — it is Slice 0's canned response, kept in the repo, not written in a panic at 15:50.
- **Expo Go fails (SDK mismatch / won't load):** scaffold SDK 57 unless the run-start check proves the store Expo Go is SDK 58. Expo's changelog: "Expo Go for SDK 58 on the Apple App Store and Google Play Store will be released within a few weeks" (from 2026-10-15) and the new Expo Go will support only SDK 58. Source: https://expo.dev/changelog/sdk-58 — accessed 2026-11-12. As of 2026-11-12 the SDK 58 store status was **UNVERIFIED** (mobile toolkit report) — re-check on the demo phone on 14/11 morning. Never depend on a mid-window cloud build: EAS free-tier low-priority queue waits "90 minutes or more at peak", 45-min timeout, 1 concurrent build. Source: https://newly.app/guides/eas-build — accessed 2026-11-12. EAS Build is a hosted service producing installable binaries — source: https://docs.expo.dev/build/introduction/ — accessed 2026-11-12.

### 3.1 The backup video — how/when to record it
- **When:** twice — once at T+3:20 (feature freeze, first clean run) and once at T+4:15 (final rehearsal). The T+4:15 take is the submission copy. Never record it for the first time after 15:30.
- **How:** screen-record the REAL phone (not the laptop, not an emulator) while a human — not the builder — kills the app, reopens it, and taps the demo script. One continuous take, no cuts. The recording must show: the kill, the reopen, the tap, the AI working (streaming/progress visible), the result. Keep it under 90 seconds.
- **Where:** on the demo phone AND copied to a second device (a laptop) before 16:00. A video that lives only on a dead phone is not a backup.
- **Honesty rule:** the video is labelled with the time it was recorded and introduced as "recorded live at [time] today" — never presented as happening live in the pitch. The judges' rule scores a video as 0 *as the demo*; the video's job is to save the pitch when the live demo cannot run, not to replace it.

### 3.2 The canned-response stub — how to make it honest, not faked
- The stub is the Slice 0 artefact: the real endpoint returning a pre-written, AI-shaped response for the exact demo input. It is honest **iff** all three hold: (1) the UI visibly labels it — "demo mode — canned response" on the result screen; (2) the presenter says so out loud before tapping; (3) the stub response is one the real model actually produced earlier in the day for that input (paste a real output in, do not hand-write a perfect one).
- It is faked — and must never be used — if the label is hidden, the presenter implies it is live, or the response was hand-written to look better than the model. The red-team lens for this is the correctness check in the workflow report: "does the AI output actually solve the user's problem, or is it plausible-sounding nonsense?" — workflow report §2c, accessed 2026-11-12.
- The stub exists in the repo from hour 1 (it is how Slice 0 ships). Deleting it "to be safe" removes the last rung — keep it, label it.

### 3.3 The cached last-good result
- The app caches the last successful AI result locally (non-sensitive data only) so a network blip during the pitch does not blank the screen — mobile toolkit report §3, accessed 2026-11-12 (labelled there as a judgement call, not a sourced claim).
- On screen it must show the time it was produced and the input it answers. A cached result shown without its timestamp is a misrepresentation; with its timestamp it is evidence the flow worked minutes ago.

---

## 4. Demo insurance — the 5 things recorded/captured BEFORE the build

Capture all five **before 11:00 on 14/11** (ideally the night before). If the build catastrophically fails at 15:00, these five are still a submittable artefact: a real problem, real evidence, and a real plan — the 35 + part of the 25, honestly claimed, with the 40 conceded rather than faked.

1. **The evidence artefact (35 points).** One named user + their own words about the problem: a screenshot of their message, a 30-second voice note, or a photo of their current workaround — saved as a file in the repo (`docs/evidence/`), with the date. No artefact = no 35.
2. **The one-sentence idea + the scorecard (A/B/C from §1, Step 3).** Written in `CONTRACT.md` before any code. This is the pitch spine if there is no product to show.
3. **The demo script, on paper.** The exact taps on the phone, the exact demo input, and the expected AI output — written before the build (AngelHack rule, source §1 Step 4). A script written after the build describes what was built; a script written before it is what the build is judged against.
4. **The "before" capture.** A 30-second video or photo set of the user doing the task the painful way today (their workaround from Step 1). This is the before/after pair: before = their workaround, after = the app. It also proves the problem exists even if the app does not.
5. **The fallback contact + first-users list.** Names (not "target segments") of 3 real people who will try the app tomorrow, with how to reach them, plus the share link / install path they will use. This is the 25-point seed: "first users" means named humans, not a market size. **CHƯA ĐỌC** — no source in this pass verified a first-users tactic for this event; this is a design judgement, labelled as such.

**Insurance checklist (tick before 11:00):** ☐ evidence file in repo ☐ one-sentence idea + scorecard in CONTRACT.md ☐ demo script on paper ☐ before-capture saved ☐ 3 named first users + contact path. If any box is unticked at 11:00, the first 20 minutes of the build fix that box — not code.

---

## 5. What this brief does NOT cover / UNVERIFIED list

- **No specific idea is validated here** — that is the separate subagent's job. Nothing in §1 is evidence for any candidate.
- Exact OpenAI/Anthropic per-tier rate limits (RPM/TPM) for the team's account — **CHƯA ĐỌC**; check the provider dashboard on the morning of 14/11.
- Whether the 4 members' $50 API credits can be pooled — **CHƯA ĐỌC**.
- Whether the App Store / Google Play Expo Go is SDK 58 yet — **UNVERIFIED** as of 2026-11-12 (mobile toolkit report); re-check on the demo phone on 14/11 morning.
- Gemini 2.5 Flash retirement — **RESOLVED 13/11 (Google deprecations page [P]: deprecated, shutdown 1 Dec 2026, API requests auto-route to `gemini-3.5-flash-lite`). Do NOT pin it; primary is `gemini-3.5-flash-lite`.**
- Full Lu.ma scoring text — **CHƯA ĐỌC** in full in this pass (goal-file summary used); re-read the event page 14/11 morning.
- Prize terms ($1,000/$500/$250 + ChatGPT Pro) — **CHƯA ĐỌC**; do not budget on winning.
- All prices: re-check the provider pricing page on 14/11 morning. GPT-5/mini/nano retire 11 Dec 2026; Sonnet 4.5 retires 30 Nov 2026.

## Sources (all accessed 2026-11-13 unless stated)
- Goal file (internal): `~/workspace/goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md` — scoring/rules, accessed 2026-11-13.
- Workflow report: `~/workspace/research_notes/multi-agent-workflow-5h-hackathon-20261112-0550/report.md` — accessed 2026-11-12.
- Backend report: `~/workspace/research_notes/backend-agent-toolkit-20261112/report.md` — accessed 2026-11-12.
- Mobile report: `~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md` — accessed 2026-11-12.
- Lu.ma: https://luma.com/codex-community?utm_source=oaidevs
- Apero/Facebook credits: https://www.facebook.com/aperogroup/posts/pfbid06LpXc2VNu9pVNDPxCCybU3jtPbCoAD8436X6DGcjykxcBmVEdXenf1jcbMHoSB1rl and https://www.facebook.com/permalink.php?story_fbid=pfbid02z9JAjTYaV5k357JyDs4BdVgEaNB9BGuWY9QYrEHZSvGUEGUk7ohTzvjHCKWhVykJl&id=61596072208681
- OpenAI pricing: https://geroundtable.com/openai-api-explained/ ; https://www.llm-cost.io/model/openai--gpt-5-nano/ ; https://apicost.app/pricing/openai/ ; https://www.priceper1m.com/model/openai-gpt-5-nano ; https://ecorpit.com/openai-gpt-5-o3-shutdown-december-2026-migration/
- Anthropic pricing: https://apicost.app/pricing/claude-sonnet-4-5/ ; https://www.agent37.com/blog/claude-code-cost ; https://www.glamdringresearch.com/post/claude-sonnet-api-pricing ; https://greenlightmyapp.com/blog/claude-api-pricing ; https://aisignalhq.com/posts/claude-sonnet-4-5-retires-november-30-2026-cost-of-moving/
- Gemini pricing: https://creditforstartups.com/pricing/gemini-api-pricing ; https://fastrouter.ai/feeds/blog/gemini-2-5-flash-pricing
- BaaS pricing: https://www.guides.reviews/developer-tools/best-backend-as-a-service-baas-platforms-startups-2026 ; https://www.13labs.au/compare/supabase-vs-convex
- Expo: https://expo.dev/changelog/sdk-58 ; https://docs.expo.dev/build/introduction/ ; https://newly.app/guides/eas-build ; https://agentvera.dev/en/blog/build-mobile-app-with-ai/
- Method sources: https://digital.moburst.com/how-to-add-an-ai-feature-to-an-existing-mobile-app/ ; https://medium.com/@work.jdattani/i-tried-to-build-a-serious-backend-in-24-hours-and-broke-everything-0251ed25c717 ; https://angelhack.com/blog/5-steps-from-idea-to-hackathon-winning-app/ ; https://dev.to/whaiman/zero-to-demo-in-5-hours-a-survival-guide-for-your-first-ai-hack-day-3h4d
