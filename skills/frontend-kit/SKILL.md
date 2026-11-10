---
name: frontend-kit
description: "Build or redesign a frontend from a vague brief through a taste-locked loop: lock tokens against references, generate 5 CSS-only variants, then build, run the deterministic gate, grade 1–5 on Type/Layout/Colour/Space, fix the top 2, and stop at the human gate. Use for landing pages, dashboards, and redesigns when the user wants a verified result, not a first draft."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Hermes Agent, Muse Code, CommandCode, Cursor. Full loop needs a shell, Node 22+, and system Chrome; without them it degrades per references/stop-rules.md, never by faking a grade.
metadata:
  version: "0.1.0"
---

# frontend-kit — the taste-locked deterministic-gate loop

You are the orchestrator for one frontend build. You do not write the final
page in one shot, and you never grade your own work and call it done. You run
the loop below, in order, delegating each step to the sub-skill or script named
for it. You never duplicate a sub-skill's content in this file: when a step
names another skill, read that skill and follow it.

The full loop spec lives in `references/workflow.md`. The grade rubric lives in
`references/grader-rubric.md`. The stop rules and the degradation ladder live
in `references/stop-rules.md`. The expert pack (10 independent domain
specialists + call rules) lives in `references/expert-pack.md` and
`experts/<domain>.md`. The 5 variants as concrete token directions live in
`references/variant-briefs.md`; the human-gate question bank lives in
`references/human-gate-pack.md`. Read workflow, rubric, and stop-rules
before starting step 0. If they disagree with this file, they win — they are
the detailed record; this file is the route map.

## Precedence — READ THIS FIRST (before step 1.4 delegates anything)

The orchestrator's grader rule (Step 4.4, `references/grader-rubric.md`)
OVERRIDES any vendored `critique.md` / `new-work.md` / degraded-agent
text that permits single-context self-critique — including upstream
Impeccable `reference/critique.md` (which requires a
`⚠️ DEGRADED: single-context` banner on degraded runs), upstream
Impeccable `reference/new-work.md` (which substitutes a fresh in-thread
finish-reviewer pass and a Verdict Pass from
`degraded/finish-reviewer.md` when no subagent capability exists), and
`skills/frontend-design/SKILL.md:57–59` ("Critique your own work"). Those
passages are upstream text the kit vendors verbatim in the canonical
copies and does not rewrite there (the generator transforms only the
generated copies — see `scripts/generate-host-variants.sh`); inside this
kit they are overridden and must not be followed as grading instructions. A
`⚠️ DEGRADED: single-context` banner is NOT an accepted grade anywhere in
this kit: a degraded run has no grade, and the round's grade is exactly
"gate green, vision not available".

This rule sits here, before any step, on purpose: step 1.4 delegates to
`frontend-design`, whose own text tells the agent to critique its own work
as it builds. That sentence is overridden by this section — you meet the
override BEFORE you meet the delegation, so following the steps in order
never leads you to self-critique first and discover the override later.

## When to use this skill

Use when the user asks for a landing page, a dashboard or app screen, a
redesign, or anything phrased like "make it look good", "build me a page for
…", "redesign this", or a vague brief with no visual direction. Use it for the
whole build, not for a single tweak: a one-line CSS fix does not need the loop.

Do not use it for backend work, for copy-only edits, or when the user has
already locked the design and only wants an implementation. Do not use it to
re-argue a direction the human already picked — a pick is feedback, not a
prompt for discussion.

## Step 0 — Setup (once per project, before any build)

1. Create the taste folder from the kit template. Copy
   `templates/design/` into the project as `design/`:
   `design/TASTE.md`, `design/tokens.css`, `design/demo.html` (the 1-page
   taste-lock demo, step 1.3),
   `design/references/DESIGN.md/` (Vercel, Claude, Linear — each labelled
   third-party analysis, not official), plus empty `design/references/`,
   `design/screenshots/`, and `design/variants/` folders.
2. Fill in `design/TASTE.md` from the brief and from the user: one-paragraph
   intent, likes, dislikes, hard rules. If the user names sites they love,
   save 8–15 screenshots of them in `design/references/`, named by site
   (`linear.png`, `stripe.png`) — screenshots, not links. If the browser
   has no external network in this environment (probe 2: the sandbox's
   egress proxy needs auth Chrome cannot supply headlessly — curl works,
   the browser gets `ERR_TUNNEL_CONNECTION_FAILED`), reference
   screenshots degrade to the vendored DESIGN.md files alone: record that
   degradation in the run log and continue; do not fake screenshots, and
   do not treat the missing step as run. Webfonts likewise render as
   fallbacks in that environment — same cause, same degradation note.
3. Confirm the tools for the loop exist in this environment: Node 22+,
   system Chrome, `playwright-cli`, and `impeccable detect` (via the kit's
   `scripts/gate/detect.mjs`). If any is missing, note which degradation rung
   of the ladder applies (`references/stop-rules.md`) and continue on that
   rung — do not pretend the missing step ran. **No system Chrome, but the
   kit-installed Playwright chromium exists:** the browser leg still runs —
   point `CHROME_PATH` at it
   (`CHROME_PATH=$HOME/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`;
   note `chrome-linux64`, not `chrome-linux`). `detect.mjs` never downloads
   anything: if `impeccable` is not on PATH it uses the installed launcher
   and otherwise fails loudly (exit 3) — a silent npx download mid-gate
   was removed in the probe-2 reconciliation.

## Step 1 — Brief → taste lock (no build yet)

1. Read the brief, `design/TASTE.md`, and the chosen DESIGN.md file. Pick the
   reference direction: which sites, which DESIGN.md, and why — in one short
   paragraph, written into the run log.
2. Write `design/tokens.css`: type scale, colour roles, space scale, radius,
   motion. Start from the template's values only as a starting point; the
   locked reference overrides them.
3. Build a 1-page demo proving the tokens work. Use the demo file at
   `templates/design/demo.html` (copied into the project as
   `design/demo.html` by step 0) — the same content every time so tokens
   stay comparable across briefs. The demo exercises every expected token
   (display/body/mono type, hero scale, colour roles incl. accent, space
   scale, radius, motion) against the LOCKED `tokens.css`, not the
   template's starting values. **Pass criterion:** the demo renders every
   listed token visibly AND passes the step-3 gate when gated on its own
   (`gate.sh --target design/demo.html`: `detect` 0 findings, static
   checks pass). The every-listed-token half is scripted, not asserted:
   `gate.sh` §1b reads the demo header's EXPECTED TOKENS block and fails
   the gate when any listed token is undefined in `tokens.css` or
   unreferenced in the demo body. A demo that fails the gate proves the tokens — not the
   demo — are wrong: fix the tokens, not the demo file.
4. Direction-setting: delegate to `frontend-design`. Read its SKILL.md
   and follow its plan-first process exactly: 4–6 named colours, type roles,
   ASCII wireframes, then the counterfactual plan check — worked through a
   similar prompt, would you arrive somewhere similar? If yes, the plan is
   generic: fix the plan, not the build. Say what changed and why.
   **Note:** `frontend-design`'s own sentence "Critique your own work as
   you build" (its SKILL.md:57–59) is OVERRIDDEN by the Precedence section
   at the top of this file — do not follow it. Direction-setting from that
   skill is plan-first only; no self-critique, no self-grade.
5. **Verifiable artifact:** commit `design/tokens.css` and the chosen
   references BEFORE any page HTML is written. If the finished page's tokens
   do not match the locked references, the workflow has a hole, not a feature.
   **"Commit" means exactly this (no more, no less):** (a) the files are
   saved under `design/` in the project, AND (b) the lock is recorded in
   the run log with `node scripts/run-log.mjs --project <dir> lock
   --tokens design/tokens.css --refs <chosen DESIGN.md + reference
   screenshots>`. If the project is a git repo, ALSO run `git add design/
   && git commit -m "Taste lock: <direction>"`; if it is not a git repo,
   (a) + (b) alone ARE the commit — never create a repo just for this, and
   never treat "saved the file" without the run-log lock as committed.

## Step 2 — Build (one HTML file, tokens only)

1. Content first, then sections — one section per screen for landing pages;
   dashboards / app screens use the dense multi-panel layout instead (see the
   brief-type scoping table in step 3 — it governs both the build shape and
   the gate). No inline style drift: every visual value comes from
   `design/tokens.css`. A new token is added to the file first, then used.
2. If the brief is vague on direction, generate the 5 CSS-only variants
   before building further: same content, same copy, same semantic HTML —
   only CSS changes. The five are Editorial, Dark, Warm brutalist, Glassy,
   Minimal — each as a concrete token direction in
   `references/variant-briefs.md` (do not invent five directions from
   priors). Each gets its own tokens and its own screenshot at the same
   width. **Variant folder layout (the picker requires this exact layout):**
   `design/variants/<name>/tokens.css`,
   `design/variants/<name>/screenshot-1440.png` (same width for every
   variant), `design/variants/<name>/index.html` (same content, same copy,
   same semantic HTML — only the stylesheet link differs). A flat layout
   (`<name>.html` + `<name>-tokens.css` + `<name>-1440.png`) is rejected
   by `variant-picker.mjs check`. Run `scripts/variant-picker.mjs` to list
   them and record the pick.
3. **Step 2a — the human picks one variant.** The pick IS the feedback.
   Never re-argue direction in prose. Build on the picked variant only.
   **Human-less runs (no human to pick):** use the deterministic pick —
   run `variant-picker.mjs pick --auto`, which picks the variant whose
   tokens match the LOCKED `design/tokens.css` most closely (count of
   locked `--name: value` declarations reproduced exactly; ties broken
   alphabetically). State the rule before picking, record the pick with
   its scores in the run log, and give no quality verdict: the auto-pick
   says only which variant is closest to the locked direction.

## Step 3 — Deterministic gate (before any vision grade)

**The gate is TWO legs, BOTH required — a pass means both green on the
same build.** Leg 1 is `gate.sh` (taste lock + `impeccable detect` + static
checks, including a static visual-marker check). Leg 2 is `gate.mjs`
(copy-lint + the consistency browser leg). A `gate.sh` PASS on its own is
only leg 1 — it never means the gate passed. When the legs disagree, the
build is not green: fix the build, do not pick the greener leg, and never
lower a gate to green a bad page.

Run, in this order, and print every result in full — never summarise a gate
result:

1. `node scripts/gate/detect.mjs <page or dir>` — the `impeccable detect`
   wrapper (62 deterministic rules: 31 slop / 31 quality). Exit codes:
   0 = clean; **2 = findings — fix them**; **1 = the scan could not run**
   (missing file, bad target) — there are no findings to fix, so fix the
   invocation/target and re-run instead. **3 = no detector found** (no
   `impeccable` on PATH, no installed launcher) — install it, do not
   expect a download: the wrapper never downloads anything. No vision round is spent on a
   build the gate already fails.
2. `node scripts/gate/gate.mjs <page.html> [--kind <kind>]` — the kit gate. It runs the
   vendored taste-skill-style checks: `copy-lint.mjs` (copy FAILs) and
   `consistency.mjs --quick` (overflow / collide / tap-size, section height,
   one-section-per-screen) at checker widths 1440, 1024, 820, 768, 390.
   Exit codes: 0 = green; **1 = FAIL (findings — fix them)**;
   **2 = the checker could not run** (usage error, skipped browser leg,
   unreadable target) — there are no findings to fix, so fix the
   invocation/environment and re-run instead.
   **Pass `--kind` for the page** (`software`, `service`, `product`,
   `place` — see `references/layout-doctrine.md` §0): it decides which
   checks fire. An app marked `product` gets the physical-product checks
   it cannot pass; mark apps `software`/`service`. **No system Chrome:**
   run the browser leg with `CHROME_PATH` pointed at the kit-installed
   Playwright chromium (`$HOME/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`
   — `chrome-linux64`, not `chrome-linux`). The gate writes its crops and
   report to the OS temp dir by default, never into the project — and
   `gate.sh` excludes `.taste-skill/` from its scan, so one leg's output
   can never fail the other leg (probe G-7).
   **What the checker demands is TAUGHT, not assumed:** read
   `references/layout-doctrine.md` before building — one `.wrap` with no
   horizontal padding at desktop widths and 20px side MARGINS (not
   padding) below the 1240px container breakpoint (F-2/F-9: without them
   text touches the screen edges below 1248px and the hero clips
   mid-glyph at 390), the nav in the same `.wrap` with no extra padding
   and the CTA pushed right with `margin-left: auto`, 12-column splits on
   the shared k=5/6/7 line (SR-8), overlay nav, section fill ≥55% or
   merge (SR-3) — fill alone does NOT catch dead bands — section gaps
   128–288px at desktop widths, a gap over 288px at vw ≥ 1024 FAILs as a
   dead band (kit patch, probe 3 + judge), and below 820px NO section is
   `100svh` — every section's height follows its content (F-3: cutting the
   meeting paddings is a workaround, not the fix; `hero-fill` is scoped to
   desktop widths because at tablet widths it contradicts the gap rule), a
   visual covering ≥25% of
   every feature section (a photograph, or a `[data-ui]` UI mock ≥120×80px — small inline SVG
   icons do not count; a text-only mock also needs a small svg in its
   header bar or it FAILs as a band, F-5). A build that follows the
   doctrine can pass; a build that does not will fail leg 2,
   and that is a build failure.
   **Contrast — decorative vs functional accent:** a vendored reference's
   component that fails the contrast rule is NOT shippable verbatim.
   Claude's `callout-card-coral` (white text on coral #d97757, 3.12:1)
   fails WCAG AA and the kit's 7:1 body-text rule: keep coral DECORATIVE
   ONLY (never behind text) and use the darkened functional accent
   (#a9583e, white 5.06:1, passes AA) for text-bearing surfaces. Body /
   muted text keeps the kit's 7:1 rule; CTA text passes at WCAG AA 4.5:1.
3. `npx html-validate` and `npx pa11y --standard WCAG2AA` where available.
   A FAIL blocks the round.

**Brief-type scope — the landing-page gate does NOT apply unchanged to
every brief.** Apply the gate by brief type:

| Gate check | Landing page | Dashboard / app screen | Redesign |
|---|---|---|---|
| `detect` (62 rules) | Applies | Applies | Applies (to the NEW page) |
| copy-lint | Applies | Applies | Applies |
| overflow / collide / tap-size | Applies | Applies | Applies |
| one-section-per-screen + landing rhythm | Applies | Does NOT apply — dense multi-panel layout is expected; judge panel alignment, scan order, density vs legibility instead | Applies only if the page being redesigned is a landing page; otherwise use its own type's rule |
| section height | Applies | Applies per panel/card, not per screen | Same as its type |
| no-visual (visual ≥25% per feature section) | Applies — a photograph, or a `[data-ui]` UI mock ≥120×80px | Applies per panel/card (a panel's own UI is its visual; mark mocks `[data-ui]`) | Same as its type |
| section-gaps (dead-band ceiling) | Applies — no content-to-content gap over 288px at desktop widths (vw ≥ 1024); below 1024px gaps inflate with the viewport, so the structural hero-height rule governs instead (F-3) | Applies per panel/card gaps where the layout has them; a dashboard's dense panels are not dead bands | Same as its type |
| `mailto:` / `tel:` / `javascript:` links (leg 1 static check) | Applies — non-file schemes are exempt from the file-reference check; a legitimate `mailto:` CTA never fails leg 1 as "referenced file missing" (F-1) | Applies | Applies |
| product-shown | Applies ONLY to physical-product pages (kind `product`); does NOT apply to software/service/app pages — mark those `software`/`service`, do not fake photographs | Does NOT apply | Same as its type |
| html-validate / pa11y WCAG2AA | Applies | Applies | Applies, plus: existing content and links survive (dropped content / dead links = FAIL) |

The judge grades Layout by the same table (see `frontend-judge`).
`taste-reference` stays the default taste lens on every build; what is
scoped here is the GATE checks, not the lens.

FAIL blocks the round. Fix, then re-run the gate from the top. Do not proceed
to step 4 with a red gate.

## Step 4 — Eyes + grade (Playwright CLI)

1. Serve the page over http (never `file://` — module scripts do not run).
2. Screenshot at 1440 / 768 / 390 with Playwright CLI. Use `playwright-cli
   console` for errors and `snapshot` for structure (cheap, no image tokens).
   1024 is an optional fourth width; every extra width costs image tokens
   per round, so do not add widths casually.
   **At 390, look for glyphs cut at the viewport edges** (doctrine §8):
   brief 1's hero clipped mid-glyph at 390 while every DOM measurement
   reported "fits" — no box-based gate check catches ink overhang, so the
   eyes are the instrument here and the §1 phone gutter is the prevention.
   A 390 screenshot with text touching x=0 is a defect even when the gate
   is green.
3. Grade 1–5 on Type / Layout / Colour / Space against the locked reference,
   following `references/grader-rubric.md`. EVERY score carries ONE LINE of
   observable evidence — a named element, a measured contrast ratio, a pixel
   value. A score without evidence is not a score. Show the score table
   every round.
4. **The grade step MUST dispatch to an independent judge. The builder NEVER
   grades its own work — a builder self-grade is FORBIDDEN, not merely
   discouraged.** Dispatch to the judge skill by name: spawn a fresh
   sub-agent running **`frontend-judge`** (see
   `skills/frontend-judge/references/invocation.md` for the exact spawn
   pattern: fresh context, no production history, no shared context with
   the builder; pass only the built page, locked tokens/references,
   screenshots, gate result, and brief-type scope — never the builder's
   reasoning or earlier scores). The judge reads the page + locked
   references + screenshots and returns the score table with evidence.
   **Fallback order, first available wins:** (1) fresh judge sub-agent
   (`frontend-judge`); (2) `other-model` judge (a different agent/model
   from the builder, same fresh-context / no-history constraints);
   (3) `muse-manager` judge — Muse grading directly as a DIFFERENT agent
   instance from the builder with no production history of this build
   (valid under the coordinator decision in the repo `AGENTS.md`: the
   user's rule authorises Muse grading; what is forbidden is the SAME
   agent instance/context grading its own work); (4) no grade — the
   round's grade is exactly "gate green, vision not available" and the
   HUMAN gate carries the full taste judgement. Never fake a 4/5.
   Allowed grader labels only: `judge-subagent`, `muse-manager`, or
   `other-model`, plus the independence basis (which must state BOTH fresh
   context AND no production history — "fresh context" alone is NOT
   enough). **Any score without a named independent grader label is
   INVALID.** If no independent judge is available, there is no grade:
   the round's grade is exactly "gate green, vision not available" and the
   HUMAN gate carries the full taste judgement. Never fake a 4/5.
   `taste-reference` is the default taste layer: the orchestrator uses it on
   every build as a lens for the grade (it is a lens, not the judge — the
   independent judge still scores).
   **Specialist second opinion (expert pack):** when the judge's grade is
   uncertain on a domain, or the brief carries a domain risk (motion-heavy,
   copy-heavy, dashboard), the judge or the orchestrator may spawn the
   matching expert from `references/expert-pack.md` /
   `experts/<domain>.md` as a fresh sub-agent — same fresh-context /
   no-production-history spawn pattern as the judge, never before the gate
   is green, max 2 experts per round. The expert verdict is ADVISORY to
   the judge: the judge keeps the final Type/Layout/Colour/Space scores;
   the expert's top defects enter the fix list. An accessibility REWORK
   (1–2) blocks shipping even when the 4 axes are ≥4.
5. Record the round with `scripts/run-log.mjs`: scores per round, grader
   identity + independence basis per round, gate result. The run-log script
   REJECTS any entry whose grader is the builder. The log is the memory
   that stops rejected directions from being re-proposed. **No independent
   judge available (ladder rung 3):** record the round with
   `run-log.mjs record --round N --grader none --scores none --gate <pass|fail>`
   — the grade is recorded as exactly "gate green, vision not available",
   with no invented grader label. `--grader none` with scores is rejected.

## Step 5 — Fix top 2, as token diffs

1. Fix the top 2 findings (top 1 if the evidence is thin). Fixes go to
   `design/tokens.css` first. HTML or layout changes only if the gate still
   fails after the token change.
2. Keep the best-scoring version. A round that scores lower is discarded, not
   iterated on (best-version-kept).
3. Re-run step 3 (gate), then step 4 (grade). That is one round.

## Step 6 — Stop + human gate

1. Stop when every axis is ≥ 4 AND the gate is green — or after 3 rounds,
   whichever comes first. A build that cannot reach ≥ 4 in 3 rounds is a
   direction problem (wrong reference, wrong tokens): re-pick a variant
   (step 2a), not a 4th round. **Re-pick cap: max 2 re-picks, 9 rounds
   total** — 3 rounds in the initial direction + at most 2 re-picks × 3
   rounds each. After the 9th round, stop regardless of scores and present
   the human gate with the best version so far. **Best-version-kept
   survives a re-pick:** the best-scoring version across ALL directions
   stays the version that ships; a re-pick starts a new direction from
   scratch but never discards the previous best — if no later round beats
   it, the earlier best is what the human gate sees.
2. Present the human gate: the score table, the 3-width screenshots, 2–4
   targeted questions with concrete options (pick them from
   `references/human-gate-pack.md` — never an open-ended "what do you
   think?"), and the recommended next command, ending with `polish`. The
   human-eye acceptance bar is **60% slop-free** (user-ordered 2026-11-10;
   the ≥4-on-every-axis stop above is unchanged — the % is the human-eye
   bar for the vague-brief acceptance test, the 4-axis scores are the
   per-round gate). The human's pick or adjective maps through
   the token dictionary (`scripts/token-dictionary.mjs`) and re-enters at
   step 5 — never as a rebuild.
3. After human approval: save the 3-width screenshots as the pixel-diff
   baseline so later feedback rounds cannot silently regress it.
4. Record in the run log: scores per round, grader label per round, and every
   feedback → token change → new score, so the dictionary grows.

## Precedence — see the top of this file

The grader-rule override lives at the TOP of this file ("Precedence —
READ THIS FIRST"), before step 1.4, so an agent following the steps in
order meets the override before the delegation that needs it. It is not
repeated here: one copy, at the top, is the rule.

## Delegation table

| Need | Delegate to | Never do here |
|---|---|---|
| Direction, plan-first, genericness check | `frontend-design` | Invent a direction from priors |
| Slop rules, craft floor, `detect` | Impeccable skill + `scripts/gate/detect.mjs` | Re-list the 62 rules from memory |
| Landing-page checker + finish gate | `taste-reference` (default taste layer, every build) + `scripts/gate/gate.mjs` | Re-implement the checker |
| Component/system lookup | `ui-ux-pro-max-reference`, `threeui`, GSAP skills | Paste a catalog into this file |
| Motion | GSAP skills | Hand-roll animation advice |
| Grading rubric, stop rules, ladder | `references/grader-rubric.md`, `references/stop-rules.md` | Grade by feel |
| Domain expertise (specialist second opinion) | `references/expert-pack.md` + `experts/<domain>.md` (fresh sub-agent, never the builder) | Ask the builder or the judge to cover a domain outside its confidence |
| Variant directions (concrete token briefs) | `references/variant-briefs.md` | Invent five directions from priors |
| Human-gate questions + next commands | `references/human-gate-pack.md` | Ask open-ended "what do you think?" |

## Rules that are never optional

- Tokens are committed before HTML. No exceptions.
- The gate runs before the grade. No vision round on a red gate.
- Every score has one line of observable evidence and a named independent
  grader label. A builder self-grade is FORBIDDEN. A score without a named
  independent grader label is INVALID. If no independent judge exists, the
  grade is "gate green, vision not available" and the human gate carries the
  full taste judgement.
- Max 3 rounds per direction; max 2 re-picks, 9 rounds total.
  Best version is kept across re-picks; worse rounds are discarded.
- Human words become token diffs, never rebuilds.
- A degradation is labelled at every step (see `references/stop-rules.md`).
  The "builder-graded loop" rung is DELETED: there is no accepted loop in
  which the builder grades its own work. A missing capability is reported,
  never silently worked around.
- Precedence: the grader rule overrides any vendored `critique.md` /
  `new-work.md` / degraded-agent text (see "Precedence" above). A
  `⚠️ DEGRADED: single-context` banner is NOT an accepted grade anywhere in
  this kit.
- Never invent a version number, a file, or a behaviour you did not read. If
  a source cannot be read, mark it CHƯA ĐỌC and say so.
