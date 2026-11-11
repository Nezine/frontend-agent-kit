# Muse-app paste packet — frontend-agent-kit v2 (slim)

> **Read this first — the honest limit.**
>
> **The Muse app has no custom-skill install.** No file you paste here persists to the
> next chat; a new chat starts clean until this packet is pasted again. This packet is
> the ONLY Muse-app path that exists. That claim is high-confidence CLAIMED — 5 convergent
> third-party sources (aiagentslibrary.com, builtwithmuse.com, openaimaster.com,
> metaflow.life, ai-supremacy.com) all agree Meta documents no user-installable skill
> path for the app; **Meta primary not read**.
>
> **Do NOT expect the 60% slop-free target from this packet.** The full kit reaches
> for that target with a deterministic detector (`impeccable detect`, 62 rules), a
> screenshot loop, gate scripts, and a fresh-context grader — none of which run inside
> the Muse app. What this packet plausibly supports: a competent first draft that
> follows the taste-locked loop in prose, with explicit anti-slop rules and a
> hand-run checklist in place of the gate. Expect a useful draft, not a verified 60% build.
> If you need the full loop, use Muse Code or a CLI host (see `README.md`).
>
> **What was cut to make this slim (and why):** the full taste SKILL.md is 381 lines —
> pasting it plus the 41-file Impeccable reference set plus the brief would blow chat
> context before the brief is given. (Count: 41 `.md` files in
> `vendor/impeccable/skill/reference/`; 45 only if you also count the 4
> `agents/*.md` files.) Cut: all 27 diagram presets, the 64-palette /
> 39-type-pairing tables, the checker and gate scripts (they cannot run here), the
> variant screenshot machinery, and the full Impeccable rule registry. Kept: the loop
> order, the taste-lock rules, the token discipline, the anti-slop checklist, and the
> stop rule — the parts that change decisions, not the parts that need a shell.
>
> **How to use:** paste this whole file into a Muse chat, then paste your brief in the
> same chat. For every new build, paste this packet again in a fresh chat.

---

## The loop (follow in order, do not skip steps)

0. **Setup.** Before any HTML, create the taste folder in your answer's working files:
   `design/TASTE.md` (one paragraph: intent + likes + dislikes + hard rules),
   `design/tokens.css` (see below — the ONLY file feedback may touch first),
   `design/references/` (name 8–15 sites you love; describe each in one line — you
   cannot see pasted screenshots unless I attach them, so ask me to attach them).
1. **Brief → taste lock (no build yet).** Read my brief + TASTE.md. Pick ONE reference
   direction and write `tokens.css` FIRST. Build a 1-page demo proving the tokens work.
   Counterfactual check: plan first (4–6 named colours, type roles, ASCII wireframes),
   then ask — worked through a similar prompt, would you arrive somewhere similar?
   If yes, the plan is generic; fix the plan, not the build. **Do not write page HTML
   until the tokens are locked and shown to me.**
2. **Build.** One HTML file, tokens only — no inline styles, no ad-hoc colours or sizes.
   If my brief is vague on direction: give me **5 structural variants + 1 break-frame = 6 variants** (same content,
   same copy, same section inventory — structure may differ; tokens stay locked: Editorial / Dark / Warm brutalist / Glassy /
   Minimal + break-frame) and let me pick one. My pick IS the feedback — never re-argue direction
   in prose.
3. **Hand checklist (by hand — no scripts run here; this is a human
   checklist, NOT a deterministic gate).** Before showing me a
   "final", check every item in the anti-slop checklist below and list PASS/FAIL per
   item. A FAIL blocks the round — fix it, do not show me the build as finished.
   Report the result as "hand checklist: all items pass" (or list the FAILs) —
   never as "gate green": no gate ran here.
4. **Eyes, NO self-grade.** Look at the rendered page at desktop and mobile widths (ask me to
   attach screenshots if you cannot render them). **Do NOT score your own work 1–5:
   the builder NEVER grades its own work, and no independent judge exists inside this
   app.** Instead, list what you observe against each axis (Type / Layout / Colour /
   Space), with ONE LINE of observable evidence per observation (a named element, a
   measured contrast ratio, a pixel value) — and leave the judgement to me. The grade
   here is "gate green, vision not available"; I am the judge, in the human gate step.
   Never present a 1–5 score: a score without a named independent grader is invalid.
5. **Fix top 2 as token diffs** (top 1 if evidence is thin). Fixes go to `tokens.css`
   first; touch HTML/layout only if the gate still fails after the token change. Keep
   the best version so far; discard a worse round, do not iterate on it.
6. **Stop + human gate.** Stop when the hand checklist passes AND I approve what I see —
   or after 3 rounds, whichever comes first. A build I am not happy with after 3 rounds
   is a direction problem: re-pick a variant, not a 4th round. End with: the hand-checklist
   result + your per-axis observations (with evidence) + 2–4 targeted
   questions with concrete options + your recommended next step, ending with `polish`.

## Tokens (starting point, not a standard — adjust to the locked reference)

- Type: Newsreader (display, roman only — an italic serif hero is a slop tell
  the detector flags) / IBM Plex Sans (body) / IBM Plex Mono (code). Scale
  12→64px. Display tracking −0.03em. Do NOT default to Inter, Roboto,
  Fraunces, Geist (any variant), Instrument Serif/Sans, Montserrat,
  Open Sans, Arial, Helvetica, Mona Sans, Plus Jakarta Sans or Space Grotesk
  — all sit on the detector's overused-font list and fail the gate on sight
  (verified against engine 0.1.21; re-checked 2026-11-10 — see `skills/frontend-kit/templates/design/tokens.css`).
- Every text element whose size differs from body text needs its OWN explicit
  line-height (never inherit): an inherited unitless leading measures as
  1.24x on 20px text and fails the gate. And never set line-height on a bare
  element selector (p, li) alongside a class rule for the same element — the
  same 1.24x failure appears even when both rules say 1.55. Display sizes
  (≥24px) are exempt, so the tight 1.05/1.1 display/heading leading is fine —
  but only because it is explicit and the sizes are ≥24px.
- Colour: light `#ffffff` / `#f6f6f4` / ink `#0a0f1e`; dark variant inverted. Pick 4–6
  NAMED colours with roles (bg / surface / ink / muted / accent / accent-ink) — never
  an unnamed hex in the HTML.
- Space: 4→96px scale. Radius 2 / 6 / 12 / 20px. Motion 120 / 220 / 420ms.
  Max content width 1120px.
- Rule: every colour, size, radius and space value in the HTML must come from
  `tokens.css`. If a value appears in the HTML that is not a token, that is a gate FAIL.

## Anti-slop checklist (the hand checklist — run before every "final")

- [ ] No purple/blue linear gradient hero (the #1 slop tell).
- [ ] No generic Inter/Roboto/Geist/Instrument-everywhere body with no display face.
- [ ] No centred hero + three feature cards + generic footer as the whole page.
- [ ] No emoji as iconography; no lorem ipsum; no stock-photo-looking hero that says nothing.
- [ ] Real copy, written for the actual audience — no "Lorem", no "Welcome to…".
- [ ] One clear hierarchy: one display headline, one supporting line, one primary action.
- [ ] Mobile: no horizontal overflow, tap targets ≥44px, one section per screen where
      the design intends it.
- [ ] Contrast: body text ≥4.5:1 against its background (state the measured ratio).
- [ ] Every section earns its place — if removing it changes nothing, remove it.
- [ ] The page could not have been produced by swapping the brand name on a template.

## Taste rules (condensed — the full taste skill is NOT pasted here)

- Pick a direction and commit: a page with two personalities is worse than a page
  with one imperfect one.
- Typography carries the design: if the type is generic, no amount of colour or
  spacing saves it. Spend the first decisions on the type pairing.
- Restraint beats decoration: remove one element per round until removing more hurts.
- Match the reference, not the average: compare every section against the locked
  reference sites, not against "what landing pages usually look like".
- Never present a score, a claim about a measurement, or a "fixed" item you did not
  actually check. If you cannot see the rendered page, say so and ask me for a
  screenshot — do not grade blind.

## What this packet cannot do (say so, do not pretend otherwise)

- No `impeccable detect` (no shell, no detector binary) — the checklist above is a
  prose substitute, not the 62-rule gate.
- No Playwright screenshots, no headless Chrome, no `npx html-validate` / `pa11y`.
- No independent judge (no sub-agents, no separate grader) — so this packet produces
  NO 1–5 scores at all. The grade is "gate green, vision not available"; you are the
  judge, in the human gate step. Never present a self-score as a grade.
- No persistence: next chat, paste this packet again.
