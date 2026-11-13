# Free-only AI path — verification report

**Access date for every claim below: 2026-11-13.** Verification levels:
**[P]** = read on the vendor's own page by this researcher on 2026-11-13.
**[S]** = NOT read on the vendor page directly; corroborated by ≥2 independent
secondary sources that cite the vendor page (with their check dates). Re-check
in the dashboard before relying on it. **[U]** = UNVERIFIED / CHƯA ĐỌC.

**Hard constraint (user, 2026-11-13 09:41): $0 spend. No paid plan, no card
on file, anywhere.** Anything that needs a card or a billing account is OUT,
even if its base price is "$0/month" (see the Convex Starter trap below).

## (a) Recommended free-only AI path

One paragraph: the app calls a **Supabase Edge Function (Free tier)** that
holds the Gemini API key as a Supabase secret and calls the Gemini API
server-side; the primary model is **`gemini-3.5-flash-lite`** (free of charge
on the Gemini free tier, no shutdown date announced), with
**`gemini-3.8-flash`** tried first only if the morning-of AI Studio check
confirms it is free-tier-eligible for the team's project (it is the
higher-quality Flash model); if Gemini fails, the Edge Function falls back to
**Groq `openai/gpt-oss-120b`** (free tier, OpenAI-compatible API, does
structured JSON + short prose); Convex stays in the stack **only as the data
layer (results table + counter) on its Free plan — never for AI**; the demo
runs on **one Android phone via Expo Go (free) or an EAS Free Android build**,
so no Apple Developer account is needed.

Why this shape: the AI Gateway route is dead on free (see §3), so the key
must live in the Edge Function, not in a Convex action. The Edge Function is
a thin proxy — no heavy compute in it (2 s CPU cap, see §2).

## (b) Verified free-tier limits

| Service / thing | Limit (free tier) | Source (accessed 2026-11-13) |
|---|---|---|
| Gemini `gemini-3.5-flash-lite` — input tokens | **Free of charge** (Standard) | [P] https://ai.google.dev/gemini-api/docs/pricing (§ Gemini 3.5 Flash-Lite) |
| Gemini `gemini-3.5-flash-lite` — output tokens | **Free of charge** (Standard) | [P] same page |
| Gemini `gemini-3.5-flash-lite` — shutdown | **No shutdown date announced** | [P] https://ai.google.dev/gemini-api/docs/deprecations (§ Gemini 3 models) |
| Gemini `gemini-2.5-flash` — status | **Deprecated; shutdown 1 Dec 2026; API requests auto-route to `gemini-3.5-flash-lite`**; no longer selectable in AI Studio; access limited to past users | [P] https://ai.google.dev/gemini-api/docs/deprecations (§ Gemini 2.5 Flash models) + https://ai.google.dev/gemini-api/docs/pricing (§ Gemini 2.5 Flash) |
| Gemini `gemini-2.5-flash-lite` — status | **Not deprecated**, remains available via API until further notice | [P] https://ai.google.dev/gemini-api/docs/deprecations |
| Gemini `gemini-2.5-pro` — status | Deprecated; shutdown 1 Dec 2026; routes to `gemini-3.8-flash` | [P] https://ai.google.dev/gemini-api/docs/deprecations |
| Gemini `gemini-4-carbon` / `gemini-4-argon` — free tier | **Not available** on Free tier | [P] https://ai.google.dev/gemini-api/docs/pricing |
| Gemini free tier — what happens over limit | Exceeding RPM/TPM/RPD triggers a rate-limit error (`429 RESOURCE_EXHAUSTED`), **not a charge**; spend-based limits are N/A on Free | [P] https://ai.google.dev/gemini-api/docs/rate-limits |
| Gemini free tier — qualification / billing | Free = active project or free trial; Tier 1 (paid) requires setting up and linking an active billing account. Limits are **per project, not per API key**; RPD resets midnight Pacific; "specified rate limits are not guaranteed" | [P] https://ai.google.dev/gemini-api/docs/rate-limits |
| Gemini free tier — data use | Free-tier content **is used to improve Google's products** (Yes); paid tier No | [P] https://ai.google.dev/gemini-api/docs/pricing (per-model tables) |
| Gemini `gemini-3.8-flash` — free tier | **Free of charge** input/output; paid $0.75/$3.75 per 1M tokens thru 31 Dec 2026, then $1.50/$7.50 | [S] pricing page as read Oct–Nov 2026 by usagebox.com, apidog.com, digintoai.com — vendor page section not directly opened in this pass; confirm in AI Studio morning-of |
| Supabase Free — price / projects | **$0/mo**; 2 active projects; 500 MB DB; 5 GB egress (+5 GB cached); 1 GB file storage; 50,000 MAU; unlimited API requests | [P] https://supabase.com/pricing |
| Supabase Free — pause | **"Free projects are paused after 1 week of inactivity"** | [P] https://supabase.com/pricing |
| Supabase Edge Functions — invocations | **500,000 included / month** (Free) | [P] https://supabase.com/pricing (§ Edge Functions) |
| Supabase Edge Functions — timeouts | Wall clock **150 s Free** / 400 s paid; **CPU 2 s/request** (excl. async I/O); request idle timeout **150 s → 504**; memory **256 MB**; max 100 functions on Free; secrets max 100/project | [P] https://supabase.com/docs/guides/functions/limits (updated 29 Oct 2026) |
| Supabase Free — over-quota billing | "You will not be charged while using the Free Plan"; overuse brings restrictions (read-only / 402 / pause), not a bill | [S] Supabase cost-control / billing FAQ as cited by engineerfoodie.in (checked 23 Oct 2026) and freetier.wiki (10 Nov 2026) |
| Convex AI Gateway — paid gate | **"The AI Gateway is available to teams on a paid plan"**; Free plan (or gateway disabled) → token fetch fails with **`AiGatewayDisabled`** → "Upgrade" | [P] https://docs.convex.dev/ai-gateway/overview |
| Convex AI Gateway — pricing | Billed at OpenRouter rates ("Same as OpenRouter"); pricing page lists AI Gateway under Starter/Professional only | [P] https://docs.convex.dev/ai-gateway/overview + https://www.convex.dev/pricing (AI row: "Same as OpenRouter (Starter plan only)") |
| Convex Free — function calls / storage | **1M function calls/mo, 0.5 GB DB storage, 1 GB file storage** (Free & Starter share allowances) | [S] https://www.convex.dev/pricing as read Aug–Nov 2026 by anygen.io, prisma.io/compare/convex, guides.reviews, freetier.co — this pass's direct open of the pricing page returned no numbers (table extraction failed), so treat as secondary until dashboard-checked |
| Convex Starter trap | Starter is **$0/month but pay-as-you-go** (e.g. $2.20 per extra 1M calls) — it counts as a paid plan for AI Gateway purposes and needs a payment method | [S] stack.convex.dev/convex-ai-gateway ("only on paid plans. Starter counts tho, and that's $0 a month and pay as you go") + [S] convex.dev/pricing via prisma.io / anygen.io |
| Groq `openai/gpt-oss-120b` + `openai/gpt-oss-20b` | **30 RPM, 1,000 RPD, 8,000 TPM, 200,000 TPD**; limits at org level, not per key; over limit → **429 Too Many Requests** | [P] https://console.groq.com/docs/rate-limits (table rows read 2026-11-13) |
| Groq — paid vs free | Rate-limits page says base limits shown are for the **Developer plan** and to upgrade for higher limits; free-tier no-card signup | [S] no-card + free-tier framing per eesel.ai, layer3labs.io, ampm-aiops.com (Oct 2026, citing console.groq.com/docs/rate-limits) — **card requirement NOT confirmed on the primary page I read; verify at signup and enter no card** |
| OpenRouter `:free` models | **20 RPM; 50 RPD** if < $10 credits purchased (all time); **1,000 RPD** once ≥ $10 purchased; free models cost $0/token; lineup churns (models lose `:free` status) | [S] https://openrouter.ai/docs/use-cases/limits as cited by aifree.dev (10 Nov 2026), dev.to (27 Oct 2026), grabaicredits.com (17 Oct 2026) — direct open of the limits page on 2026-11-13 returned the table with blanked numbers, so these figures are secondary; the $10 top-up is PAID and therefore OUT |
| Hugging Face Inference API | Free = **$0.10 of credit/month**, not a standing free tier; old per-hour free scheme gone | [S] klymentiev.com/blog/huggingface-inference-api (11 Sep 2026, checked against HF docs/pricing) — **rejected as fallback** (credit pool, provider-dependent limits) |
| EAS Build Free | **15 Android + 15 iOS builds/month, low-priority queue (90+ min waits at peak), 1 concurrent build, 45-min build timeout**; quota resets 1st of calendar month; builds failing within 3 min don't count (max 10 waived/mo) | [S] https://expo.dev/pricing as read Sep–Nov 2026 by newly.app, cadrant.ai (9 Nov 2026), github.com/selftend/selftend/issues/521 (30 Jul 2026, verified against page markup) — direct open of expo.dev/pricing on 2026-11-13 returned a garbled table with no usable numbers, so these are secondary until dashboard-checked |
| Expo Go / Expo SDK / CLI | **Free and open source**; "The Expo Go app … is also free from the app stores"; Expo Services free if Free-plan quotas suffice | [S] https://docs.expo.dev/faq/ ("How much does Expo cost?") as quoted in search results — direct page open not done in this pass; confirm in-app morning-of |
| Expo Go on iPhone, SDK 57 | Since Sep 2026, physical iPhone requires the **same Expo account signed in to Expo CLI and to Expo Go**; simulators / dev builds exempt | [S] cadrant.ai/blog/expo-go + expo.dev/blog/apple-developer-program-explained-free-vs-paid (2 Nov 2026) |
| Apple Developer Program | **$99/year**; needed to share/publish, cloud-sign iOS, TestFlight; NOT needed to develop in Expo Go or to build/install Android | [S] expo.dev/blog/apple-developer-program-explained-free-vs-paid (2 Nov 2026) — **not needed for this demo (one Android phone)** |

### Demo-call cost (the question the brief asked directly)

A 1,000-in + 500-out-token demo call on the free tier costs **$0** on
`gemini-3.5-flash-lite` (input "Free of charge", output "Free of charge" [P],
pricing page) and on `gemini-3.8-flash` ([S], same page). With **no billing
account linked, there is nothing to bill against** — Tier 1 requires linking
one [P, rate-limits page]. If the limit is hit the call **fails with 429**,
it does not silently become a paid call [P].

## (c) NOT verified / still risky

1. **Gemini per-model free-tier RPM/TPM/RPD for the team's exact project —
   UNVERIFIED and unverifiable from public docs.** Google no longer publishes
   a per-model free-tier table: the rate-limits page says limits "depend on a
   variety of factors" and must be viewed in AI Studio, and "specified rate
   limits are not guaranteed and actual capacity may vary" [P]. Any number
   quoted from old articles (e.g. 2.5 Flash 10 RPM / 250 RPD) is stale —
   do not plan around it. The morning-of AI Studio check is the only source.
2. **Whether `gemini-3.8-flash` is free-tier-eligible for THIS project —
   UNVERIFIED until the AI Studio rate-limit page is opened.** Secondary
   sources agree it is "Free of charge", but the team's project may show
   different limits. Default to `gemini-3.5-flash-lite` (primary-verified)
   if the check is ambiguous.
3. **Whether `gemini-3.5-flash-lite` handles the demo's structured-JSON +
   short-prose quality bar — UNVERIFIED.** It is the cheapest/lightest
   current Flash model; no live test was run in this pass (read-only task,
   no keys). The 10-call morning test (§d) is the quality gate.
4. **Groq `llama-3.3-70b-versatile` limits (30 RPM / 1,000 RPD / 12,000 TPM /
   100,000 TPD) — SECONDARY ONLY.** The Groq rate-limits page I opened lists
   `gpt-oss-120b/20b` but the extracted table did not include the Llama rows.
   Do not pin the Llama ID; the verified Groq fallback is `gpt-oss-120b`.
5. **Groq signup needs no card — UNVERIFIED on a primary page.** Secondary
   sources say no card; if signup asks for a card, STOP — do not enter one,
   fall through to OpenRouter `:free` (50/day, no card per secondary sources).
6. **OpenRouter `:free` model IDs — UNVERIFIED / churn.** The lineup turns
   over every few weeks; any pinned `:free` ID may 404 on demo day. Check the
   live list morning-of; never hard-code one the night before.
7. **Convex Free numbers (1M calls / 0.5 GB) — SECONDARY** (pricing-page
   extraction failed this pass). Confirm in the Convex dashboard; the demo
   (results table + counter, a few hundred calls) is orders of magnitude
   below either way, so risk is low but the number itself is not primary.
8. **EAS Free numbers (15+15 / 45 min / low priority) — SECONDARY**
   (pricing-page extraction garbled this pass). Confirm in the Expo
   dashboard; plan the final Android build the night before, not in the
   5-hour window, because a 90+ min low-priority queue wait is possible.
9. **`expo/fetch` streaming — UNVERIFIED.** Not checked against Expo docs in
   this pass. Ship the demo on plain non-streaming `fetch` + JSON parse;
   treat streaming as a nice-to-have only if verified against docs.expo.dev
   before the sprint.
10. **Supabase free-project pause timing for THIS project — dashboard-only.**
    The rule (7 days inactivity [P]) is confirmed; whether this project is
    currently paused is not. Wake it ≥24 h before demo day and ping it daily.
11. **GPT-6 Luna (the old brief's model pick) — CHƯA ĐỌC / not found.** No
    primary source in this pass confirms a model by that name on any free
    tier; do not reference it in code or docs.
12. **Free-tier data use:** Gemini free-tier prompts/responses may be used to
    improve Google's products and seen by human reviewers [P]. Demo content
    only — never send secrets, PII, or credentials through it.

## (d) Morning-of checklist (demo day, adapted to free tiers)

**Dashboard checks (do these the night before AND morning-of):**
1. Supabase dashboard: project status = Active (not Paused — unpause and
   wait; then make one DB write so the 7-day clock resets). Edge Function
   deployed; secret `GEMINI_API_KEY` present; check invocations used this
   month ≪ 500,000.
2. Google AI Studio → rate-limit page for the team's project: screenshot the
   limits for `gemini-3.5-flash-lite` and `gemini-3.8-flash`; note which of
   the two is listed and its RPD. If 3.8 is absent/limited, primary =
   3.5-flash-lite, no debate.
3. Convex dashboard: plan = **Free** (not Starter), no payment method on
   file; confirm no AI Gateway usage row / no `AiGatewayDisabled` errors in
   logs (there should be no gateway calls at all).
4. Groq console → Limits page: confirm `openai/gpt-oss-120b` limits for this
   org; confirm no card on file.
5. OpenRouter: open the live `:free` models list; write down ONE currently
   listed `:free` chat ID as the last-resort fallback (do not pin it in code
   before this check). Confirm daily counter is at/near 0 (50/day unfunded).
6. Expo dashboard: EAS Free builds remaining (Android) ≥ 1; Expo Go on the
   demo Android phone signed in to the same Expo account as the CLI
   (iPhone same-account rule does not apply to Android, but verify the app
   opens in Expo Go anyway).
7. Confirm **no billing account is linked** to the Gemini project and **no
   card is on file** anywhere (Gemini, Supabase, Convex, Groq, OpenRouter,
   Expo). If any is found, remove it or use a different account — $0 rule.

**10 rapid test calls (sequential, ~10 s apart — never parallel; free-tier
RPM is unknown, so spacing is the protection):**
1–3. Edge Function → `gemini-3.5-flash-lite` (or 3.8 if §d.2 confirmed it):
   one short-prose prompt, one strict-JSON prompt (parse + validate keys),
   one prompt matching the exact demo input shape. All must return 200 +
   valid JSON where required.
4–5. Same two prompts via the Groq fallback (`openai/gpt-oss-120b`) through
   the Edge Function's fallback branch — proves the fallback path, not just
   the key.
6. One OpenRouter `:free` call (the ID from §d.5) — proves the last resort.
7. One call with a deliberately oversized prompt (or 11th rapid call) to
   observe the failure mode: expect **429**, confirm the app shows the
   cached/fallback answer instead of crashing or charging.
8. End-to-end: phone → Edge Function → model → Convex results table +
   counter increments; verify the row appears in Convex and the counter +1.
9. Kill-switch test: with the model key temporarily pointed at a bad value
   in a staging Edge Function (never prod), confirm the app degrades to the
   pre-baked cached answer.
10. Cold-start timing: time one full round trip on the demo phone on venue
    Wi‑Fi; if > 8 s, switch the demo to the pre-generated cached answer for
    the live moment and run the live call only as a backup.

**Budget for the day:** Gemini free RPD is project-specific and unpublished
— assume the worst (tens of calls/day, not hundreds). Keep ALL demo-day
Gemini calls (rehearsal + live) under ~20; every rehearsal call beyond that
goes to Groq (1,000 RPD verified [P]) or the cached answer.

## (e) Paid assumptions in the old plan — now OUT

| Old assumption | Status | Why |
|---|---|---|
| Convex AI Gateway as the AI endpoint (GPT-6 Luna via gateway) | **OUT** | Gateway is paid-plan-only; Free → `AiGatewayDisabled` [P, docs.convex.dev/ai-gateway/overview]. GPT-6 Luna model ID itself unverified [U]. |
| GPT-5 mini / nano via gateway | **OUT** | Same paid gate; no free-tier path through Convex. |
| Claude Sonnet / Haiku via gateway | **OUT** | Same paid gate. |
| "$5 spend cap" as the budget | **OUT — replaced by a $0 spend rule** | No card, no billing account, no top-up anywhere. The $5 cap assumed paid usage was acceptable; it is not. |
| Convex Starter ($0/mo) as a way to unlock the gateway | **OUT** | Starter is $0 base but pay-as-you-go and counts as a paid plan for gateway access [S]; it requires a payment method and bills per-token at OpenRouter rates [P]. |
| OpenRouter $10 one-time top-up for 1,000 free RPD | **OUT** | Paid. Unfunded OpenRouter stays at 50 RPD [S] — usable as last resort only. |
| Supabase Pro ($25/mo) / EAS Starter ($19/mo) as fallbacks | **OUT** | Paid; not needed for a 5-hour demo inside free quotas. |
| Apple Developer Program ($99/yr) for the demo | **OUT / not needed** | Demo is on one Android phone [S, expo.dev blog]; Expo Go + EAS Free Android cover it. Only needed if iOS distribution is added later. |
| Hugging Face Inference API as a free fallback | **OUT** | Free tier is $0.10/mo credit, not a standing free tier [S]. |
| Gemini 2.5 Flash as the pinned model | **OUT** | Deprecated; shutdown 1 Dec 2026; auto-routes to 3.5-flash-lite [P]. Pin `gemini-3.5-flash-lite` (or 3.8 if confirmed). |

**Bottom line for the builders:** Edge Function + Gemini free tier +
Groq fallback, Convex for data only, $0 everywhere, no card anywhere. If any
step in §(d) asks for a card, stop that step — the free path has a fallback
for every leg except a card itself.
