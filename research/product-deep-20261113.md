# Product / idea validation for the muse-fleet 5-hour build — research report (final — red-team fixes applied 2026-11-13)

**Context:** Codex Community Hackathon Hanoi, Sat 14/11/2026, build 11:00–16:00 (5h). Scoring (verified from the official Lu.ma page 2026-11-12, recorded in the fleet GOAL.md and FLEET-MODE.md): **40/20/0** real-phone AI demo (kill + reopen, main AI flow live; browser/emulator/photo/video = 0); **35/18/0** real user problem WITH evidence + AI helps directly; **25/13/0** market expansion (first users + global path; real users an advantage). Tiebreak 1→2→3. AI must be ESSENTIAL, not a bolted-on chatbot. Prep before the day is explicitly allowed, with disclosure of pre-built vs day-built. The team idea is NOT yet final — this brief must work for ANY idea the humans pick.

**Method:** Originators' writing via concordant third-party summaries first (Y Combinator library summaries, Paul Graham essays via multiple concordant summaries, Steve Blank's customer development model, Rob Fitzpatrick's Mom Test via five concordant summaries), then hackathon judging rubrics and validation guides. Every claim carries a source label (OFFICIAL / THIRD-PARTY), a URL, and access date 2026-11-13. Anything not verified is marked UNVERIFIED or CHƯA ĐỌC. No claim is made from training data alone. Recommendations are labelled **synthesis** where they are the team's method, not a sourced fact.

---

## Answer first

**The 35-point criterion is won tonight, not tomorrow.** The demo (40) is won by code; the problem-with-evidence criterion (35) is won by conversations that happen BEFORE 11:00. A team that starts building at 11:00 with no named user, no verbatim quote, and no workaround cost is capped at partial marks on 35 points no matter how good the app is — and the tiebreak order (demo → problem → expansion) means a tied demo loses to the team with the better-evidenced problem.

**The three levers, in order:**
1. **Tonight: the evidence sprint (50 minutes, 5 interviews).** Five 10-minute Mom Test conversations, async by voice message if needed. Output: one named hero user, one verbatim quote, one workaround with a cost. That is the evidence artefact.
2. **T+0:00–0:20 tomorrow: the 20-minute enrichment + kill decision.** Score the idea on four YC criteria, run the past-behavior check, write the kill criteria into CONTRACT.md — which freezes at 0:20 per FLEET-MODE.md, so the kill decision MUST land by 0:20, before any code is written. An idea that fails the kill test is pivoted BEFORE building starts.
3. **During the build: evidence stays inside the product, not only in the pitch.** The strongest form of the 35-point case is a screen in the app that shows the real user's problem and the AI fixing it — the judge sees the evidence while watching the demo, not only while listening to slides.

---

## 1. The 20-minute idea-enrichment method (run at T+0:00–0:20, before any code)

This is the method the Idea & Feasibility department runs. It is a synthesis of Paul Graham ("How to Get Startup Ideas", 2012), YC partner Jared Friedman's Startup School talk on evaluating ideas, and the Mom Test — compressed to fit the 20-minute window before CONTRACT.md freezes at T+0:20 and Slice 0 building starts (FLEET-MODE.md §6). The original draft timetabled this as 30 minutes (0:00–0:30) with the kill decision at 0:25–0:30 — that was unexecutable, because the contract freezes at 0:20 and code starts at 0:20. This version compresses every step into 0:00–0:20; nothing in the method may run past the freeze.

### Step 0 (0:00–0:05) — Write the idea down in one sentence each

Each candidate idea gets exactly one line in this shape (adapted from the hackathon scoring guide's first-sentence shape — THIRD-PARTY, https://github.com/harkro753/officeos/blob/HEAD/HackathonScoring.md):

> We help **[specific user]** do **[specific painful job]** because today they are stuck with **[bad current workaround]**.

Rules: no adjectives, no market size, no technology words. If the sentence needs "everyone" or "people", the user is not specific enough — rewrite it or drop the idea. YC's guidance is the same test in different words: the best application answers are "matter-of-fact" and "marketing-speak is actually just noise" (THIRD-PARTY summary of YC guidance — https://www.befreed.ai/podcast/apply-with-clarity). **Synthesis — team rule:** generate at most 3 candidates; more than 3 cannot be scored honestly in 20 minutes.

### Step 1 (0:05–0:12) — Score each idea on four criteria (Friedman)

Jared Friedman's Startup School talk systematised YC's evaluation into four criteria (THIRD-PARTY summary — https://www.zachsimms.com/startups/advice/y-combinator/): (1) how big could it be; (2) founder–market fit (do we understand these users from our own life?); (3) how sure are we the problem is big; (4) whether we have a new, important insight. **Synthesis — team scoring rule (the source gives the four criteria with no scale and no threshold):** score each criterion 0–2 (0 = no, 1 = maybe, 2 = yes, with one evidence line). Total out of 8. An idea needs ≥5 to survive, and criterion (3) must score ≥1 — a problem we are not sure is big cannot win 35 points.

Then run Paul Graham's two filters in reverse (THIRD-PARTY, via concordant summaries — https://glasp.co/articles/how-to-get-startup-ideas, https://dev.to/moeed_ul_hassan/how-to-get-startup-ideas-in-2025-paul-graham-was-right-and-heres-the-update-3l3k, https://buffermint.com/articles/how-to-get-successful-startup-ideas): **schlep blindness** (are we avoiding this idea only because it involves tedious work? If yes, that is a point FOR it — "A company is defined by the schleps it will undertake") and the **unsexy filter** (are we avoiding it because it sounds boring? Boring problems are the least competed). If the top-scoring idea was nearly discarded for being tedious or boring, say so out loud and keep it.

Also check Friedman's four mistakes (same source): (a) believing you need an amazing idea; (b) jumping on the first idea without thought; (c) starting with a **solution in search of a problem (SISP)** — if the sentence from Step 0 starts with the technology instead of the user, it is a SISP, kill it; (d) believing ideas are hard to find.

### Step 2 (0:12–0:17) — The past-behavior check (Mom Test, compressed)

For the surviving idea, each team member answers from their own life, out loud (THIRD-PARTY, Mom Test summaries — https://jetthoughts.com/course/tech-for-non-technical-founders-2026/mom-test-ask-about-past-not-future/, https://www.koji.so/docs/startup-idea-validation-guide, https://www.pmharshit.com/books/the-mom-test/, https://www.ghostlaunch.so/guides/the-mom-test, https://github.com/kalyvask/entrepreneurship-lessons/blob/HEAD/frameworks/the_mom_test.md — all five concordant on the three rules):

1. **Talk about their life, not your idea.** Never pitch the idea in this check.
2. **Ask about specifics in the past, not generics or hypotheticals.** "Tell me about the last time [problem] happened" — not "would you use this?"
3. **Talk less, listen more.**

The check passes only if the team can name **three real people who had this problem, and what each of them actually did about it** (their workaround, what it cost in time/money/sanity). **Synthesis — team bar (no cited Mom Test source imposes a time window or a 3-person pass threshold):** the three people are the minimum gate for a 5-hour hackathon, not a validation program — one source recommends 15–20 interviews per segment before drawing conclusions for a real program (THIRD-PARTY — https://www.pmharshit.com/books/the-mom-test/), and the pattern heuristic the sources do give is that the same insight surfacing in three independent conversations is a pattern (THIRD-PARTY — https://github.com/kalyvask/entrepreneurship-lessons/blob/HEAD/frameworks/the_mom_test.md). "Everyone has this problem" is a fail. "My friend said they'd use it" is a fail — that is a polite yes, and Fitzpatrick's whole point is that "everyone will lie to you at least a little" when you ask about your idea (THIRD-PARTY — https://www.koji.so/docs/startup-idea-validation-guide). The three people are the seed of the evidence kit (§3) and the hero user (§3.4).

### Step 3 (0:17–0:20) — Kill / pivot / proceed, in writing

Apply the kill criteria in §2. The decision is written into CONTRACT.md before the 0:20 freeze (one line: idea, score, kill-criteria verdict, pivot if any). **Synthesis — team rule:** the kill criteria are written into CONTRACT.md at T+0:20 BEFORE building starts, so a pivot later is a decision the team already agreed to, not a failure anyone has to admit to. If no idea survives, pivot to the narrowest slice of the best-scoring problem that CAN demo (the "one hero user + one journey" pattern — see §2, rule K6).

**Outputs of the 20 minutes (the department's deliverables):** ranked idea + one-sentence problem line; the 4-criteria score table; three named people + their workarounds; three falsifiable hypotheses in Blank's form ("We believe [specific user] has [specific problem] and currently solves it by [workaround]") — THIRD-PARTY, Steve Blank customer development summaries (https://www.startupsuperschool.com/concepts/customer-development, https://resources.rework.com/libraries/startup-fundamentals/customer-discovery); the kill-criteria verdict; the evidence plan (§3).

---

## 2. Feasibility kill criteria — when to kill an idea and pivot

An idea is killed (or pivoted to a narrower slice) if ANY of these fires. These are written into CONTRACT.md at T+0:20 so the pivot is pre-agreed, not debated mid-build. Criteria K1–K4 are adapted from the fleet's own clock (FLEET-MODE.md §6 checkpoints) and the backend/mobile research; K5–K7 are synthesis from the sources in §1.

| # | Kill criterion | Test (takes ≤5 min) | Source |
|---|---|---|---|
| K1 | **The AI is removable.** Remove the AI from the flow: if the app still does its job, the AI is decoration and the idea fails the 40-point essential-AI test. | The "remove the AI" test (mobile report §4, derived from the event's "AI is essential" rule). | FLEET-MODE.md §0; mobile report §4 |
| K2 | **No live AI flow by the T+2:20 checkpoint.** The demo needs a real model call on a real phone by the end of Slice 1 (T+2:20). If the flow needs an account, key, approval, or dataset the team does not already hold, it cannot be built in 5h. | Can the Backend builder name the exact endpoint + key + model in one sentence at T+0:20? If not, kill. | Backend report §3–§4; FLEET-MODE.md §6 |
| K3 | **Needs native code the demo path cannot run.** The app needs a custom native module (not in Expo Go) and no development build exists on the demo phone. | Check the module list against Expo Go at T+0:20. Native module + no dev build started in hour 1 (or pre-built before the event) = cut the feature. The mobile report requires the dev build to be started in hour 1 or pre-built, not necessarily on the phone at 0:20. | Mobile report §2, §6 |
| K4 | **No reachable user.** Nobody on the team can name and reach 3 people with the problem tonight/tomorrow morning. Without them there is no evidence for the 35-point criterion — and no hero user for the demo. | The Step 2 check (§1). Zero named people = kill. | Mom Test sources (§1); Blank ("there are no facts inside the building") — THIRD-PARTY, https://resources.rework.com/libraries/startup-fundamentals/customer-discovery |
| K5 | **The problem has no cost.** Nobody pays anything for the problem today — no money, no time, no workaround, no visible frustration. A problem with no existing cost has no proven willingness to pay. | "What did the workaround cost you — in time, money, or sanity — the last time?" If the answer is "nothing, it's fine", kill. | Mom Test question rewrites — THIRD-PARTY, https://jetthoughts.com/course/tech-for-non-technical-founders-2026/mom-test-ask-about-past-not-future/; validation guides — THIRD-PARTY, https://1mil.app/learn/validate-startup-idea/ |
| K6 | **Too broad to demo in one journey.** The idea needs 3+ screens or 2+ user roles before ANY value appears. A 5-hour demo has exactly one journey. | Can the demo script be written as 3–5 taps ending in the AI result? If not, pivot to the narrowest slice: one hero user, one journey, one AI action (the pattern in the hackathon-winning-patterns research: "one default hero member and one rejection-repair journey… small, honest user-validation evidence" — THIRD-PARTY, https://github.com/melkizedekict/buildwhatmovesindia/blob/HEAD/docs/research/hackathon-winning-patterns.md). | Winning-patterns research (qualitative synthesis, not a statistical study — the source says so itself) |
| K7 | **No "why now".** Nothing changed recently (model capability, regulation, platform, price) that makes this possible TODAY and not five years ago. Without a why-now, the judges' first question — "why hasn't this been done?" — has no answer. | YC presses founders on "why now" in recent batches (THIRD-PARTY — https://cdn.sanity.io/files/nhc04xln/production/1854cc942e03f5f1ed1e627bb7b865944af449b6.pdf?dl=tinyfish-what-does-it-really-take-to-get-into-y-combinator.pdf). If the team cannot name the change in one sentence, the idea is weak — pivot or strengthen the insight. | YC guidance summary (secondary) |

**Pivot rule (synthesis):** never pivot to a different problem — pivot to a NARROWER slice of the same problem. The problem evidence survives the pivot; only the scope shrinks. A pivot to a new problem at T+1:20 or later throws away the night's evidence work and restarts the clock with nothing. The FLEET-MODE.md checkpoint question governs the pivot moment: at T+1:20, T+2:20, T+3:20, "If we shipped what we have RIGHT NOW, would it demo?" If no, cut the current slice to its smallest working form on the spot.

**Pre-mortem (synthesis — team method, not a sourced claim):** at T+0:20, before building, each agent writes one sentence: "This idea fails because ___." The most plausible failure becomes an extra kill criterion for the day. It costs 3 minutes and it is the cheapest insurance against the sunk-cost lock-in that kills hackathon teams at T+3:00.

---

## 3. The evidence kit — what to collect, how, by when

### 3.1 What counts as evidence (ranked, strongest first)

The ranking is a synthesis of three concordant sources: the hackathon scoring guide's "What Counts As Evidence" list (THIRD-PARTY — https://github.com/harkro753/officeos/blob/HEAD/HackathonScoring.md), the validation guides' "real validation = the person gives up something" rule (THIRD-PARTY — https://www.galleira.studio/insights/validate-startup-idea, https://1mil.app/learn/validate-startup-idea/, https://www.requestproduct.com/blog/validate-product-idea-demand-first-playbook), and Steve Blank's "validation means a purchase order, not a compliment" (THIRD-PARTY — https://www.startupkit.pro/frameworks/customer-development). **Strength = what the person gave up.** A compliment costs nothing, so it proves nothing.

| Tier | Evidence | What the person gave up | How to get it in hours |
|---|---|---|---|
| 1 | **A signed commitment** — letter of intent, pre-order, paid pilot, a message saying "I will pay / I will use this on Monday" with their name on it | Money or a public commitment | Ask the 3 named people from §1 Step 2, in writing, tonight. One sentence + name + date. |
| 2 | **A verbatim quote + workaround + cost** — a named real person, their exact words about the last time the problem happened, what they did, what it cost (minutes, money, errors) | Time + honesty (they described a real failure) | 5 Mom Test interviews (§3.2). The quote goes on the evidence artefact and, ideally, in the app. |
| 3 | **A recording of the painful workflow** — screen recording / photo of the current workaround (the spreadsheet, the 14-step process, the paper form) | Effort (they showed you, not told you) | Ask one hero user to screen-record themselves doing it the old way, tonight. 2 minutes of video beats 2 slides of claims. |
| 4 | **Behavioural traces** — the same complaint in competitor reviews (App Store / Google Play / Reddit / G2), search volume for the problem, public posts asking for help | Nothing (public data), but it is unprompted — nobody was being polite to you | Mine 10–20 reviews/posts tonight; keep the 3 sharpest quotes with links. Public posts asking for help are "unprompted descriptions of past behavior: exactly what a good interview tries to draw out" (THIRD-PARTY — https://www.ghostlaunch.so/guides/the-mom-test). |
| 5 | **Public data / statistics** — a citable number (official statistics, published reports) that sizes the pain | Nothing | One number, cited, never invented. "A small amount of reliable evidence is more convincing than an unsupported market estimate" (THIRD-PARTY — https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure). |
| 6 | **The live demo itself** — the AI doing the job on a real phone, on the hero user's real input | — (this is product evidence, not problem evidence) | Slice 1, by T+2:20. |
| — | **NOT evidence** — "everyone agrees", friends saying "I'd use it", a survey of classmates, a big TAM number alone, "the market is $X billion" | Nothing | Never lead with these. If the pitch contains only these, the 35-point criterion is empty. |

**What the scoring guide itself accepts (THIRD-PARTY — https://github.com/harkro753/officeos/blob/HEAD/HackathonScoring.md):** "Evidence does not need to be perfect. It does need to be real enough to change how judges see the project." A specific customer, a conversation/quote/pain point, domain knowledge from lived experience, a small market scan (competitors, alternatives, current workflows, why existing tools fail), a working demo, a commit history from the day, and a clear next step. Note the pattern: every item is specific and checkable. Nothing on the list is a generic claim.

### 3.2 The evidence sprint — tonight, 50 minutes, 5 interviews

The standard guidance says 5–10 interviews per customer segment (THIRD-PARTY — https://1mil.app/learn/validate-startup-idea/) and 20–50 conversations for a real validation program (THIRD-PARTY — https://www.startupsuperschool.com/concepts/customer-development, https://www.galleira.studio/insights/validate-startup-idea). A hackathon team has one evening, not a program — so the sprint is **5 interviews, 10 minutes each, by voice message if live calls are impossible**. This async adaptation is synthesis (the sources assume live interviews); the Mom Test rules still apply to written/voice answers — past behavior, no pitching, specifics.

**Script (5 questions, all past-behavior — adapted from the Mom Test question rewrites, THIRD-PARTY — https://jetthoughts.com/course/tech-for-non-technical-founders-2026/mom-test-ask-about-past-not-future/):**
1. "Tell me about the last time [problem] happened. Walk me through what happened."
2. "What did you do about it? Show me if you can."
3. "What did that cost you — time, money, or sanity?"
4. "What have you already tried, paid for, or built to deal with it?"
5. "What happened the time you did NOT deal with it?" **(Synthesis — team addition, not one of jetthoughts' five rewrites; their fifth is a 1–10 priority ranking.)**

**Rules for the sprint:** never mention the idea or the app; never ask "would you use this?"; if the answer is thin, excavate ("and then what happened?"); record or transcribe verbatim — a paraphrase is not a quote. After each interview, score the hypotheses 1–3 (Blank's method: after 20 conversations patterns emerge — the 20-conversation program bar is "18 out of 20 people said the problem is real and urgent, that is signal" (THIRD-PARTY, https://www.startupsuperschool.com/concepts/customer-development). For this 5-interview sprint, use the other sourced heuristic: once 3 out of 5 people describe the same problems, that is a pattern (THIRD-PARTY — https://www.koji.so/docs/startup-idea-validation-guide)).

**Who does it:** the humans tonight (founders do the interviews — Blank: "founders themselves — not hired researchers — do the interviews, because the goal isn't data collection, it's founders updating their own mental model" — THIRD-PARTY, https://www.startupkit.pro/frameworks/customer-development). The Idea & Feasibility department (agent D) writes the script, collects the transcripts, and builds the artefact. If the humans cannot do 5 interviews tonight, the fallback is Tier 4 (review mining) + Tier 5 (one cited statistic) — weaker, but honest, and disclosed as such.

### 3.3 The evidence artefact — one page, owned by D

Per FLEET-MODE.md §1, role D owns "the problem-evidence artefact". It is assembled in parallel from T+0:20 (read-only w.r.t. code) and finalised by T+3:20. **Contents (one page, no more):** the hero user's name + one verbatim quote; the workaround + its cost; the interview count + the pattern (e.g. "3 of 5 described the same workaround"); one public-data number with citation; one competitor/workaround failure line; the next test (who we would test with next, what we would charge). **Creative recommendation (synthesis):** put the evidence INSIDE the product, not only on a slide — one screen in the app that shows the hero user's problem and the AI resolving it, using the hero user's real input. The judges then see the evidence while watching the demo, which is when the 40-point and 35-point criteria are scored together.

### 3.4 The hero user

**Synthesis — the highest-leverage creative move in this brief:** build the demo around ONE named real person (with their permission), not a segment. The winning-patterns research states the same pattern independently: "one default hero member and one rejection-repair journey… small, honest user-validation evidence" and "a two-minute presentation in which a judge sees the outcome before hearing the architecture" (THIRD-PARTY — https://github.com/melkizedekict/buildwhatmovesindia/blob/HEAD/docs/research/hackathon-winning-patterns.md). Judges remember one person; they forget segments. The hero user is the person from §1 Step 2 with the sharpest quote and the highest workaround cost. The demo input is their real case. The pitch opens with them ("Last Tuesday, [name] spent 40 minutes doing [X]") and closes with them ("today it takes 40 seconds"). If the hero user cannot be named (privacy), use a first name + role only — never invent a name or a quote.

---

## 4. The market-expansion template (for the 25-point criterion)

The criterion (FLEET-MODE.md §0): full marks = "a clear path to the first users and to a global audience; real users are an advantage." Zero = "no concrete user-acquisition path, or only the claim that 'everyone needs it'." The template below is a synthesis of Geoffrey Moore's beachhead strategy (*Crossing the Chasm*, via concordant third-party summaries — https://medium.com/@hello_966/how-do-i-know-which-market-vertical-to-enter-first-when-my-product-could-serve-multiple-807d7638d7f0, https://github.com/lazarenkod/agents/blob/HEAD/plugins/startup-founder/skills/niche-discovery/SKILL.md, https://github.com/ashstep2/pm-playbook/blob/HEAD/skills/vertical-market-assessment/SKILL.md, https://www.productquant.dev/blog/tam-sam-som-beachhead-market/) and the TAM/SAM/SOM sizing discipline.

### 4.1 Beachhead first, TAM last

A beachhead is "the smallest market you can fully dominate and point to as proof" — specific enough that you can name roughly 50 companies or 500 users in it (THIRD-PARTY — https://medium.com/@hello_966/how-do-i-know-which-market-vertical-to-enter-first-when-my-product-could-serve-multiple-807d7638d7f0). Moore's bowling-pin strategy: win one narrow segment completely, then use the reference customers and credibility to knock over the adjacent segment, and the one after that (same source). Bill Aulet's version, paraphrased from the summary (not a verbatim quote): find the smallest market you can dominate first, then use that dominance as a wedge into the next one (THIRD-PARTY — https://github.com/ashstep2/pm-playbook/blob/HEAD/skills/vertical-market-assessment/SKILL.md).

**The template (fill in one line each, in the pitch and in the repo):**
1. **Beachhead:** [named group, ~50 companies or ~500 users, why we can win them first — existing connections, domain expertise, or referenceable customers].
2. **Why this beachhead, not the biggest market:** [unfair advantage in this segment].
3. **Pin 2 and Pin 3:** [the adjacent segments, in order, and what the beachhead win gives us to enter them — references, data, credibility].
4. **First 10 users:** [where they come from, by name/channel, what they do on day 1]. The strongest signal is market pull: "If users in a vertical are already trying to solve the problem with workarounds, duct tape, and manual processes, you have pull" (THIRD-PARTY — https://github.com/ashstep2/pm-playbook/blob/HEAD/skills/vertical-market-assessment/SKILL.md).
5. **Global path:** [what changes for the next country/language — language, payments, regulation — and what does NOT change (the problem and the AI flow)].
6. **Numbers (bottom-up only):** TAM / SAM / SOM, where SOM is computed bottom-up (customers × price), never top-down. Definitions (THIRD-PARTY — https://www.productquant.dev/blog/tam-sam-som-beachhead-market/): TAM = everyone who could theoretically buy; SAM = everyone reachable with current channels; SOM = everyone winnable in the next 18 months. Sanity benchmarks cited by the sources (not a hard bar): $1B+ TAM, $100M+ SAM, $10M+ SOM — and "a $50M TAM you can own outright beats a $5B TAM where you're the 40th vendor" (THIRD-PARTY — https://medium.com/@hello_966/how-do-i-know-which-market-vertical-to-enter-first-when-my-product-could-serve-multiple-807d7638d7f0).

### 4.2 What kills the 25 points

- "Everyone needs it" with no named first user.
- A TAM number with no SOM and no first-10 plan. "TAM gets you a meeting. SOM gets you a check" (THIRD-PARTY — https://conception-labs.com/blog/say-my-name-a-breaking-bad-inspired-guide-to-saas-growth-and-competitive-advantage).
- Expanding before winning the beachhead: "the most common GTM error" (THIRD-PARTY — https://www.productquant.dev/blog/tam-sam-som-beachhead-market/).
- A global path that is just "translate the app" with no mention of payments, regulation, or distribution in the next market.

---

## 5. The pitch narrative — 5 minutes, weighted by the scoring

The structure below adapts the hackathon pitch-deck structure (THIRD-PARTY — https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure) to THIS event's weights: the demo gets the longest block because it is 40 points and tiebreak #1; evidence gets the second block because it is 35 points; market gets a short block because it is 25 points and tiebreak #3. "Do not give every topic equal time. Use the weighting to decide what the judges most need to see" (same source). **On demo share — reconciling two sources:** one guide (a Solana/Colosseum crypto-hackathon guide) recommends "Spend 60% of your time on the demo, 40% on slides" (THIRD-PARTY — https://github.com/sendaifun/solana-new/blob/HEAD/skills/launch/create-pitch-deck/references/investor-audience-guide.md) — that is 3 minutes of a 5-minute pitch, which leaves too little room for the problem, evidence, market and close this event scores separately. This brief does NOT adopt the 60% rule literally: the demo gets the longest single block (90 seconds, 30%), and the demo-anchored blocks around it (solution 0:30–1:00, value + evidence 2:30–3:15) are also demo-led, so roughly half the pitch is the product in action rather than slides about it.

| Time | Block | What the judges must understand | Criterion |
|---|---|---|---|
| 0:00–0:30 | **Problem + hook** | Who has the problem, when it occurs, why it matters. Open with the hero user: "Last Tuesday, [name] spent 40 minutes doing [X]." | 35 |
| 0:30–1:00 | **Solution** | What you built and how it addresses the problem — one sentence, then the AI's exact role. No architecture. | 40/35 |
| 1:00–2:30 | **Live demo** | The core user journey on the real phone: kill the app, reopen it, run the main AI flow live on the hero user's real input. The longest block. | 40 |
| 2:30–3:15 | **Value + evidence** | Why the solution is useful and what supports it: the verbatim quote, the workaround cost, the interview count (3 of 5), the one public number. | 35 |
| 3:15–4:00 | **Market + execution** | Beachhead + pins + first 10 users; what was built today vs pre-built (disclosure — prep is allowed, hiding it is not). (Hacktribe calls this block "Execution and differentiation"; renamed here because this event scores market expansion separately.) | 25 |
| 4:00–4:30 | **Next step** | The one test after today: who we test with next, what we charge. | 25/35 |
| 4:30–5:00 | **Close + buffer** | The one sentence judges should remember (hero user + before/after). Finish early, never run over. | — |

**Pitch rules (from the sources):** 5–7 slides maximum — "more slides do not create a stronger presentation" (THIRD-PARTY — https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure). "Do not invent numbers to make the problem look larger. A small amount of reliable evidence is more convincing than an unsupported market estimate" (same source). Answer the five questions every pitch must answer — problem, who, solution, why you / why now, what you want (THIRD-PARTY — https://speakerdeck.com/afroboy/pitching-101). Rehearse twice on the real phone (FLEET-MODE.md §6) and record a backup video of the live flow — a backup recording is a never-cut item.

---

## 6. Top 8 traps — what breaks at demo time, and the fix

| # | Trap | What breaks | Fix |
|---|---|---|---|
| 1 | **SISP — solution in search of a problem.** The team fell in love with a technology (a model, a feature) and went looking for a user. | The 35-point criterion is empty: no named user, no evidence, and the judges' first question ("who is this for?") has no answer. | The Step 0 sentence (§1): if it starts with the technology instead of the user, kill it. Friedman lists SISP as one of the four idea mistakes (THIRD-PARTY — https://www.zachsimms.com/startups/advice/y-combinator/). |
| 2 | **Polite-yes evidence.** Asking friends "would you use this?" and counting yeses. | The evidence artefact is fiction. One sharp judge question ("what did they do last time?") collapses it. | Mom Test rules (§1): past behavior only, never pitch, never ask hypotheticals. "You shouldn't ask anyone if your business is a good idea… It's your responsibility to find [the truth]" (THIRD-PARTY — https://www.koji.so/docs/startup-idea-validation-guide). |
| 3 | **The AI is decoration.** The app works fine with the AI removed; the AI is a chatbot tab with a sparkle icon. | The 40-point criterion fails its own rule: "A product that works the same with the AI removed scores nothing on the demo criterion" (FLEET-MODE.md §0). | K1 kill criterion (§2) at T+0:20. The AI must sit inside a flow the user already does — "a 'Summarise' action on the document viewer, a suggested reply above the keyboard" — not a new tab with an empty chat box (THIRD-PARTY — https://digital.moburst.com/how-to-add-an-ai-feature-to-an-existing-mobile-app/). |
| 4 | **"Everyone" as the user.** No beachhead, no first 10, no named group. | The 25-point criterion scores zero ("no concrete user-acquisition path, or only the claim that 'everyone needs it'" — FLEET-MODE.md §0). | Beachhead template (§4): name the ~50 companies / ~500 users. |
| 5 | **Invented numbers.** A TAM, a statistic, or a "90% of users" claim with no source. | One judge question ("where did that number come from?") destroys credibility for the whole pitch. | One cited number or none. "Do not invent numbers to make the problem look larger" (THIRD-PARTY — https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure). |
| 6 | **Evidence gathered after the build.** The team builds first and looks for evidence at 15:00. | The evidence cannot shape the product — and there is no time left to collect it. The artefact is assembled from memory, not from interviews. | D assembles the evidence artefact in parallel from T+0:20 (FLEET-MODE.md §1, §6); the sprint happens tonight (§3.2). |
| 7 | **Inverted pitch weights.** 4 minutes of slides, 1 minute of demo — or the demo squeezed into the final seconds. | The 40-point criterion gets 20% of the pitch. Judges score what they see; a rushed demo reads as a broken demo. | The §5 clock: demo is 1:00–2:30, the longest block. "A simple structure… prevents the demonstration from being squeezed into the final seconds" (THIRD-PARTY — https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure). |
| 8 | **Sunk-cost lock-in.** The idea was chosen by vibe at 11:00, no kill criteria were written, and by 14:00 nobody will say it is not working. | The team ships a demo that does not demo, because cutting feels like failing. | Kill criteria in CONTRACT.md at T+0:20 + the pre-mortem (§2) + the checkpoint question at T+1:20/T+2:20/T+3:20 ("If we shipped what we have RIGHT NOW, would it demo?"). A pivot to a narrower slice is a decision, not a failure. |

---

## 7. Sources

All web sources accessed **2026-11-13** unless noted. Labels: OFFICIAL = vendor/primary documentation; THIRD-PARTY = independent guides, rubrics, summaries — **including concordant summaries of originators' writing (Graham, Fitzpatrick, Blank, Moore, Friedman), whose originals were NOT re-opened in this pass; see §8**. No source in this report is labelled PRIMARY, because no originator's own text was re-opened here. Event rules come from the fleet GOAL.md and FLEET-MODE.md (verified from the official Lu.ma page 2026-11-12).

**THIRD-PARTY (concordant summaries of originators' writing — originals not re-opened; see §8)**
- Paul Graham, "How to Get Startup Ideas" (Nov 2012) — via https://glasp.co/articles/how-to-get-startup-ideas, https://dev.to/moeed_ul_hassan/how-to-get-startup-ideas-in-2025-paul-graham-was-right-and-heres-the-update-3l3k, https://buffermint.com/articles/how-to-get-successful-startup-ideas
- Paul Graham, "Schlep Blindness" (Jan 2012) — via the same three summaries
- Rob Fitzpatrick, *The Mom Test* (2013) — via five concordant summaries (see Mom Test list below)
- Steve Blank, *The Four Steps to the Epiphany* / Customer Development Manifesto — via https://resources.rework.com/libraries/startup-fundamentals/customer-discovery, https://www.startupsuperschool.com/concepts/customer-development, https://www.startupkit.pro/frameworks/customer-development
- Geoffrey Moore, *Crossing the Chasm* (beachhead / bowling pin) — via https://medium.com/@hello_966/how-do-i-know-which-market-vertical-to-enter-first-when-my-product-could-serve-multiple-807d7638d7f0, https://github.com/lazarenkod/agents/blob/HEAD/plugins/startup-founder/skills/niche-discovery/SKILL.md, https://github.com/ashstep2/pm-playbook/blob/HEAD/skills/vertical-market-assessment/SKILL.md, https://www.productquant.dev/blog/tam-sam-som-beachhead-market/
- Jared Friedman, YC Startup School talk "How to Get Startup Ideas" — via https://www.zachsimms.com/startups/advice/y-combinator/ (the 4 criteria and the 4 mistakes; the 0–2 scale and ≥5/8 threshold in §1 are the team's synthesis, not Friedman's)

**THIRD-PARTY**
- YC guidance summaries — https://www.befreed.ai/podcast/apply-with-clarity, https://cdn.sanity.io/files/nhc04xln/production/1854cc942e03f5f1ed1e627bb7b865944af449b6.pdf?dl=tinyfish-what-does-it-really-take-to-get-into-y-combinator.pdf
- Mom Test summaries — https://jetthoughts.com/course/tech-for-non-technical-founders-2026/mom-test-ask-about-past-not-future/, https://www.koji.so/docs/startup-idea-validation-guide, https://www.pmharshit.com/books/the-mom-test/, https://www.ghostlaunch.so/guides/the-mom-test, https://github.com/kalyvask/entrepreneurship-lessons/blob/HEAD/frameworks/the_mom_test.md
- Validation guides — https://1mil.app/learn/validate-startup-idea/, https://www.requestproduct.com/blog/validate-product-idea-demand-first-playbook, https://www.galleira.studio/insights/validate-startup-idea
- Hackathon judging — https://github.com/harkro753/officeos/blob/HEAD/HackathonScoring.md, https://github.com/melkizedekict/buildwhatmovesindia/blob/HEAD/docs/research/hackathon-winning-patterns.md
- Pitch structure — https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure, https://github.com/sendaifun/solana-new/blob/HEAD/skills/launch/create-pitch-deck/references/investor-audience-guide.md (Solana/Colosseum crypto-hackathon guide — see §5 note on the 60% demo rule), https://speakerdeck.com/afroboy/pitching-101
- Market sizing / beachhead — https://www.productquant.dev/blog/tam-sam-som-beachhead-market/, https://conception-labs.com/blog/say-my-name-a-breaking-bad-inspired-guide-to-saas-growth-and-competitive-advantage
- AI-feature design (bolted-on vs essential) — https://digital.moburst.com/how-to-add-an-ai-feature-to-an-existing-mobile-app/

**INTERNAL (already verified, no URL needed)**
- Fleet GOAL.md (`~/workspace/goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md`) — event rules, scoring, tiebreak, prep-allowed-with-disclosure
- FLEET-MODE.md (`~/frontend-agent-kit/repo/FLEET-MODE.md`) — runbook: roles, slices, clock, checkpoints, cut list, CONTRACT.md template
- Backend report 12/11 (`~/workspace/research_notes/backend-agent-toolkit-20261112/report.md`) — stack, hour plan, failure modes
- Mobile report 12/11 (`~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md`) — Expo SDK 57, Expo Go path, streaming trap, AI-essential test

---

## 8. Gaps / what this research could not verify

- **The YC Library page "How to Evaluate Startup Ideas" returned HTTP 404 when opened 2026-11-13** — no content from that page is used in this report. The Friedman 4-criteria score and the 4 mistakes are cited via the zachsimms summary only, not the YC transcript itself. No content from that page, and no Kevin Hale content, is used anywhere in this report.
- **Paul Graham's essays and Fitzpatrick's *The Mom Test* book were not re-opened in this pass** — the claims rest on multiple independent summaries that agree verbatim on the quoted lines. If a quote is load-bearing for the pitch, re-check it against paulgraham.com / momtestbook.com before printing it on a slide.
- **CB Insights failure statistics:** the only figure used in this report is from a secondary summary of CB Insights' 2024 analysis of 431 failed VC-backed companies — 43% failed due to poor product-market fit (THIRD-PARTY — https://www.koji.so/docs/startup-idea-validation-guide). The draft's earlier "42% 'no market need' / 2026 cut" pairing was wrong (42% is the old 2019 "no market need" number; no "2026 cut" exists in the cited sources) and has been removed. Treat the 43% as directional, not as pitch evidence; do not put it on a slide.
- **The "5 interviews in 50 minutes by voice message" sprint is a synthesis adaptation** — the sources assume live interviews (5–10 per segment; 20–50 for a program). The async form is untested; the Mom Test rules are what carry over, not the format.
- **The hackathon-winning-patterns research is a qualitative synthesis, not a statistical study** — its own words: "A winner page proves that a project won; it does not prove which single feature caused the win." The hero-user pattern is a strong recommendation, not a proven cause.
- **No source tested exactly this setup** (4 agents, 4 machines, 5 hours, idea undecided the night before). The 20-minute method and the kill criteria are adapted to this clock from longer-cycle methods — they are the team's method (labelled synthesis), not a tested result. The draft's original 30-minute timetable was unexecutable against the T+0:20 CONTRACT.md freeze and was corrected to 20 minutes after red-team review (2026-11-13).
