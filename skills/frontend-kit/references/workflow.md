# Workflow spec — the taste-locked deterministic-gate loop (condensed §1)

Source: `research/SYNTHESIS.md` §1 (frontend-agent-kit v2, 2026-11-10).
Evidence labels: **VERIFIED** = a primary source was read (URL + date);
**CLAIMED** = a source says so, not independently checked; **CHƯA ĐỌC** =
not read, never presented as read. This file condenses the loop; the
orchestrator SKILL.md is the route map and this file is the detailed record.

**Grader rule (user direction, 2026-11-10, non-negotiable — resolves
red-team risk A1): the builder NEVER grades its own work.** The grade step
MUST dispatch to an independent judge. A builder self-grade is FORBIDDEN.
Any score without a named independent grader label is INVALID. See
`grader-rubric.md` for the allowed graders and `stop-rules.md` for the
revised degradation ladder (the "builder-graded loop" rung is deleted).

## 0. Setup (once per project, before any build)

Taste folder — the reference, committed before any HTML:

```
design/TASTE.md          — one-paragraph intent + likes/dislikes + hard rules
design/tokens.css        — the token file; the ONLY file feedback may touch first
design/references/       — 8–15 screenshots of sites the user loves, named by
                           site (linear.png, stripe.png… — never screenshot-1.png;
                           screenshots, not links)
design/references/DESIGN.md/<brand>.md — 2–3 vendored DESIGN.md files
                           (Vercel + Claude + Linear), each labelled
                           "third-party analysis, not official"
design/PLAN.md           — the plan (step 1.7): decisions, assumptions,
                           section inventory (by content, not order), EARS
                           acceptance criteria, screen × state matrix,
                           Design Read dials, design-system pointer
design/DESIGN-READ.md    — the Design Read (step 1.2): artifact, audience,
                           visual language, mode, anchor / recipe, the
                           five dials (Low / Med / High + anchor each)
design/DESIGN-SYSTEM.md  — the design-system declaration (step 1.6):
                           reference mapping, do/don't rules, rationale —
                           rationale only, no token values
design/rounds/           — one folder per fix round (step 5.5):
                           `rounds/<n>/proposal.md` / `delta.md` / `tasks.md`
design/screenshots/      — this build's shots (Playwright output)
design/variants/         — structural variants (+ 1 break-frame) + their screenshots
```

The plan, Design Read, and declaration templates are copied with the
taste folder and filled in at step 1; round folders are filled in at
step 5 (one `design/rounds/<n>/` per fix round).

Install (by the kit): Playwright CLI pinned + vendored gate scripts
(`impeccable detect` + taste-skill-style consistency/gate scripts) + skills.

## 1. Brief → taste lock (no build yet)

- Read the brief + TASTE.md + the chosen DESIGN.md. Pick the reference
  direction (which sites, which DESIGN.md, and why — one short paragraph,
  written into the run log). If the brief names an anchor, read ONLY that
  one recipe file in `references/style-recipes/` (INDEX first, then the
  one file) — never the whole catalog. Read `references/anti-cliche.md`
  before writing anything: the blocklist names the generic patterns this
  step must not lock in. **GetLayers (optional).** When a free GetLayers
  layer's motion, depth, or atmosphere matches the brief, it may serve
  as an additional reference direction alongside the screenshot
  references — see `references/getlayers.md`; record the chosen layer
  (name + URL) in the run log and in the Design Read. Conditional only
  ("when a free layer fits the brief") — never mandatory, never a
  substitute for the locked tokens, never the build's source; free tier
  only, no account, no purchase, no MCP.
- **Design Read (step 1.2, before tokens).** Summarise the brief in
  `design/DESIGN-READ.md`: artifact, audience, visual language (a
  specific family, not "modern / clean"), mode (greenfield / extension /
  preserve / overhaul), anchor / recipe if any, and the five dials —
  visual variance, motion intensity, information density, asset
  dependence, brand fidelity — each a categorical position (Low / Med /
  High) with a one-line anchor. The dials are INTENT, not scores: they
  must affect real decisions (layout variation, motion, content per
  viewport, real-asset effort, preservation strictness) or they are
  decorative labels. No dial value may be cited as evidence for any
  grade or stop decision, and the judge NEVER receives the dials. When
  a free GetLayers layer is the reference direction, name it here
  (name + URL); when a free GetLayers AI design tool supplies an
  effect, name the tool here on its own line (`Effect source:
  GetLayers <tool name> — free in-browser tool`,
  `references/getlayers.md` §3). Copy
  the dials into `design/PLAN.md` § Design Read.
- **High-end bar (human-feel target, recorded 2026-11-11).** On top
  of the gates above, the loop aims at the human's feel target: **8/10
  overall — not slop AND beautiful/refined, with motion and 3D as plus
  points, like the Anthropic/Apple sites he sent.** The feeling:
  refined and high-end ("High-end rất quan trọng" — high-end is very
  important); "Ko nhạt nhào mà lại ko diêm dúa" — not bland, but not
  gaudy either. His human grades on the 3 probe builds are 6/10 overall
  for all three (see `research/judge-calibration.md`); the judge's mean
  was 3.5/5 (≈7/10), so the judge runs ~1 point hot versus his feel.
  The bar is a direction for the taste lock and the Design Read (record
  one line per build: how this build aims at it), never a score the
  loop grades itself and never a stop input. **UNCHANGED by this bar:**
  the 60% slop-free acceptance bar, the 4 grading axes (Type / Layout /
  Colour / Space), and the stop rule (≥4 on every axis AND gate green AND cross-check clear,
  or 3 rounds). The scroll-motion recipe
  (`references/style-recipes/scroll-motion.md`) already encodes the
  restraint half of this bar (1–2 dealt moments, one moving thing per
  viewport, small distances, short durations) — the high-end bar is
  the feel that restraint is in service of, not a second gate.
  **Canonical example of restrained depth (user, 2026-11-11 11:51;
  verified in the image by the manager and re-verified here):** the
  Vercel reference shot (`brief3/ref-1-vercel.png` — the locked
  reference for probe build 3, sha256
  `d57e1a98506a1038d25c4848817dd7b2fd034cad9ccfc998aefcde1f23a7827f`)
  has ONE big black triangle in the middle of the hero with a soft
  blurred shadow beneath it, making it feel like it floats in 3D.
  ONE geometric shape + ONE soft blurred shadow = 3D feel. The
  triangle is in the Vercel REFERENCE, not in the Alex Nguyen build
  — the build has NO such depth cue anywhere (flat), which is why it
  reads bland. **The depth rule, in his words:** "lồng ghép tinh tế
  vừa đủ như các web công ty tỷ đô" (weave effects in subtly, just
  enough, like billion-dollar companies' sites); "ko diêm dúa nhưng
  phải tinh tế" (not gaudy, but must be refined); "đừng nhét hiệu ứng
  vô tội vạ" (don't stuff effects in indiscriminately); flat = bland.
  So the loop's depth rule is: a few purposeful, well-placed depth
  cues — never flat, never overloaded.
- Write `design/tokens.css`: type scale, colour roles, space scale,
  radius, motion. Start from the template's values only as a starting
  point; the locked reference overrides them.
- Build a 1-page demo proving the tokens work (same content every time, so
  tokens are comparable across briefs). The demo file is
  `templates/design/demo.html` (copied into the project as
  `design/demo.html`); it exercises every expected token (display/body/mono
  type, hero scale, colour roles incl. accent, space scale, radius, motion)
  against the LOCKED `tokens.css`. **Pass criterion:** the demo renders
  every listed token visibly AND passes the step-3 gate when gated on its
  own (`gate.sh --target design/demo.html`: `detect` 0 findings, static
  checks pass). The every-listed-token half is scripted, not asserted:
  `gate.sh` §1b reads the demo header's EXPECTED TOKENS block and fails
  the gate when any listed token is undefined in `tokens.css` or
  unreferenced in the demo body. A demo that fails the gate proves the tokens are wrong:
  fix the tokens, not the demo file.
- Counterfactual plan check (Anthropic `frontend-design`, VERIFIED — SKILL.md
  read in full, fetched fresh 2026-11-10, 71 lines, anthropics/skills repo,
  HEAD `2c5958e`): plan first (4–6 named colours, type roles, ASCII
  wireframes), then ask — worked through a similar prompt, would you arrive
  somewhere similar? If yes, the plan is generic; fix the plan, not the build.
  NOTE: `frontend-design`'s "Critique your own work" sentence is OVERRIDDEN
  by the orchestrator's Precedence rule (top of `frontend-kit/SKILL.md`,
  before the step that delegates to `frontend-design`) — plan-first only,
  no self-critique, no self-grade.
- **Design-system declaration (step 1.6).** Write
  `design/DESIGN-SYSTEM.md` from `templates/design/DESIGN-SYSTEM.md`:
  reference mapping (which DESIGN.md / reference site each token family
  comes from), do/don't rules, rationale. RATIONALE ONLY — it must not
  contain a single token value (no hex codes, no pixel sizes, no custom
  property definitions); `tokens.css` is the single source of truth for
  every value and governs on any drift. Fix rounds touch `tokens.css`
  only and never hand-maintain this file after the lock.
- **Plan + approval (step 1.7).** Write `design/PLAN.md` from
  `templates/design/PLAN.md`: decisions, assumptions, section inventory
  (by content, not order), EARS acceptance criteria (5–8 WHEN / THE
  SYSTEM SHALL lines, including the 390px no-overflow rule and the
  three-width rule), the screen × state matrix, the Design Read dials
  (copied from step 1.2), and the design-system pointer section. Then
  the approval gate:
  - **Solo run:** the human approves `design/PLAN.md` before ANY build.
    No build starts on an unapproved plan. Record the approval in
    PLAN.md § Approval record.
  - **Human-less / buffet run:** there is no human to approve, so the
    plan proceeds WITHOUT human approval. The approval substitute is
    the blocking converge check (step 3 / step 6) plus the
    first-round independent grade; the run log labels the plan
    "approved-by: converge-check + round-1 grade (no human present)".
    Coordinator approval is NOT an approval and is never recorded as
    one — a coordinator approving a plan its own run wrote is
    self-approval, the same back door as builder self-grading.
  The plan never moves the lock: round deltas merge into PLAN.md
  § Amendments, the token dictionary, and the run log's notes — never
  into TASTE.md or `tokens.css` mid-loop.
- **VERIFIABLE ARTIFACT (step 1.8):** tokens.css + the chosen references are committed
  BEFORE any HTML is written. If the output's tokens do not match the locked
  references, the workflow has a hole, not a feature. **"Commit" means
  exactly:** (a) the files are saved under `design/` in the project, AND
  (b) the lock is recorded in the run log (`node scripts/run-log.mjs
  --project <dir> lock --tokens design/tokens.css --refs <chosen DESIGN.md
  + reference screenshots> [--version N] [--approved-by "<approval basis>"]`).
  `--version` defaults to the existing lock count + 1; a re-pick records a NEW
  version, and re-using an existing version is rejected (exit 2). The lock
  entry also records the sha256 of the tokens file automatically.
  `--approved-by` carries the step-1.7 approval basis on human-less runs;
  omit it on solo runs (human approval lives in PLAN.md). If the project is a git repo, ALSO `git add
  design/ && git commit -m "Taste lock: <direction>"`; if it is not a git
  repo, (a) + (b) alone ARE the commit — never create a repo just for this,
  and never treat "saved the file" without the run-log lock as committed.
- **Metric-locked loop (step 1.8 / step 3):** the lock defines the
  metric/eval before any builder runs, the gate IS the eval, and the
  gate's job is the last 10% — see `references/metric-locked-loop.md`
  for the mapping, the binding wording discipline, and what stays out
  of the kit.

## 2. Build (one HTML file, tokens only — no inline style drift)

- Content first, then sections — one section per screen for landing pages;
  dashboards / app screens use the dense multi-panel layout instead (see the
  brief-type scoping table in step 3 — it governs both the build shape and
  the gate).
- If the brief is vague on direction: generate the 5 structural variants
  (same content, same copy, same section inventory — structure may
  differ; tokens stay locked) + 1 break-frame variant = 6 variants
  (Editorial / Dark / Warm brutalist / Glassy / Minimal — each as a
  concrete token + structural direction in
  `references/variant-briefs.md`), each with its own tokens,
  screenshot each at the same width. **Variant folder layout** (the picker
  requires it): `design/variants/<name>/tokens.css`,
  `design/variants/<name>/screenshot-1440.png`,
  `design/variants/<name>/index.html`. The human picks one (step 2a). The pick
  IS the feedback — never re-argue direction in prose. **Human-less runs:**
  the deterministic pick — `variant-picker.mjs pick --auto`: the variant
  whose tokens match the locked `design/tokens.css` most closely (count of
  locked `--name: value` declarations reproduced exactly; ties broken
  alphabetically). No quality verdict. **"Play first, critique later":**
  all five variants are generated before any critique. The v0 checkpoint
  below governs the PICKED variant's build only — never mid-generation.
- **v0 draft checkpoint (step 2.4, on the picked variant only).** Before
  writing full components, build a viewable v0 skeleton at
  `design/v0.html`: core structure (every section from PLAN.md's
  inventory, in order) + the locked tokens + key module placeholders
  with explicit markers (`[image]`, `[icon]`) + the list of design
  assumptions. It does NOT include content details, the complete
  component set, all states, or motion. Placeholders use `[image]` /
  `[icon]` markers only — never `[NEED]` or `[insert]`, which the
  copy-lint leg fails as residue. A v0 with assumptions and placeholders
  is more valuable than a polished v1 that took three times the work: if
  the direction is wrong, the v1 has to be scrapped entirely.
  - **Solo run:** show the v0 to the human and wait for the nod
    before the full build. The nod is the course-correction point:
    tone, layout direction, variant directions.
  - **Human-less / buffet run:** there is no human to nod, and no
    coordinator nod either — a coordinator nodding at its own run's
    skeleton is self-approval, which defeats the checkpoint. The
    autonomous form is a DETERMINISTIC SKELETON GATE: run
    `gate.sh --target design/v0.html` (leg 1: no overflow, tokens
    resolve, no missing files) AND
    `node scripts/gate/converge-check.mjs --plan design/PLAN.md
    --page design/v0.html` (every planned section present as a
    placeholder section). Both must be green before the full build
    proceeds. The skeleton gate is a gate check, not a grade — the
    builder never judges its own skeleton. Record the skeleton, the
    tokens, and the skeleton-gate result in the run log as the
    direction receipt. (On a host with no Chrome the browser leg of
    the skeleton gate fails closed; the checkpoint then degrades to
    the leg-1 static checks + the converge check, labelled as such
    in the run log — the full build still waits for the human gate
    to carry the visual judgement.)
  `design/v0.html` is a skeleton, not the deliverable: `gate.sh`
  excludes it from project-dir scans (like `design/demo.html`), and
  it is gated explicitly on its own file only.

## 3. Deterministic gate (runs BEFORE any vision grade)

**The gate is TWO legs, BOTH required — a pass means both green on the
same build.** The gate IS the eval (`references/metric-locked-loop.md`
§3): the lock defines the metric before any builder runs, and the gate's
job is the last 10% — a build that passes at 90% still fails the gate.
Leg 1 is `gate.sh` (taste lock + `impeccable detect` + static
checks); leg 2 is `gate.mjs` (copy-lint + consistency browser leg). A
`gate.sh` PASS alone is only leg 1, never a gate pass.

- `impeccable detect` — 62 deterministic rules (31 slop / 31 quality; 16
  advisory, 2 error, 44 no-severity → warning-default; registry lives in the
  ENGINE, `crates/live/assets/antipatterns.json` at tag skill-v4.8.2 —
  VERIFIED). Exit codes: 0 = clean; 2 = findings, fix them; 1 = the scan
  could not run (missing file, bad target) — no findings to fix, fix the
  invocation/target and re-run. **3 = no detector found** — install it;
  `detect.mjs` never downloads anything (it uses the installed launcher
  when `impeccable` is not on PATH, else fails loudly). No vision round is spent on a
  build the gate already fails.
- Taste-skill-style gate scripts: overflow / collide / tap-size, section
  height, one-section-per-screen, copy-lint FAILs. Checker widths
  1440, 1024, 820, 768, 390 (VERIFIED — taste-skill 2.5.1 `consistency.mjs`
  L5/L73/L4506, SKILL.md L261). Rhythm widths are the code default
  1440, 768, 390 — see `scripts/gate/README.md` for the resolution.
  **Pass `--kind`** (`software` / `service` / `product` / `place`) — it
  decides which checks fire; apps are `software`/`service`, never
  `product`. **What the checker demands is taught** in
  `references/layout-doctrine.md` (one `.wrap`, no horizontal padding at
  desktop widths, 20px side MARGINS below the 1240px container breakpoint,
  nav in the same `.wrap` with no extra padding, 12-column splits on the
  shared k=5/6/7 line, overlay nav, fill ≥55% or merge, section gaps
  128–288px at desktop widths with a 288px dead-band ceiling at vw ≥ 1024,
  no section is `100svh` below 820px — every section's height follows its
  content (F-3; `hero-fill` is scoped to desktop widths because at tablet
  widths it contradicts the gap rule), a visual ≥25% per feature section — photograph or
  `[data-ui]` mock ≥120×80px, and a text-only mock needs a small svg in
  its header bar or it FAILs as a band). **No system Chrome:** run with
  `CHROME_PATH` pointed at the
  kit-installed Playwright chromium
  (`$HOME/.cache/ms-playwright/chromium-*/chrome-linux64/chrome` —
  `chrome-linux64`, not `chrome-linux`). The gate writes crops/report to
  the OS temp dir by default, never into the project (probe G-7).
  **Contrast:** a reference component that fails the contrast rule is not
  shippable verbatim — Claude's `callout-card-coral` (white on coral
  #d97757, 3.12:1) fails WCAG AA and the kit's 7:1 body rule; coral stays
  decorative only, text-bearing surfaces use the darkened functional
  accent (#a9583e, white 5.06:1, passes AA).
- Anti-cliché seed checks (`gate.sh` §3c,
  `scripts/gate/anti-cliche.mjs`): AC-1 purple→pink→blue gradient, AC-2
  emoji as icon substitute. SEEDED from garden-skills, not grown from an
  observed failure — the gate grows only from observed failures, and
  this seed list is the labelled exception. A finding still fails the
  gate like any leg-1 finding. Waived only by an explicit
  `Anti-cliche allow: AC-<n>` hard rule in `design/TASTE.md`; waivers
  print, never silent. Skipped with a warning when node is absent, and
  never on the demo or v0 single-file targets.
- Converge check (`gate.sh` §5, `scripts/gate/converge-check.mjs`,
  whenever `design/PLAN.md` exists): every planned section id exists in
  the built HTML, and every non-N/A screen × state matrix cell names a
  file that exists or an id in the HTML. Free-text cells are UNCHECKABLE
  — the judge's call in step 4, never silently passed. BLOCKING: a
  failure fails the gate (no grade) and blocks the human gate (step 6.1);
  there is no advisory mode. Absence of PLAN.md skips with a note, never
  a failure; skipped with a warning when node is absent (then run
  `references/converge-checklist.md` by hand before the human gate).
- `npx html-validate` + `npx pa11y --standard WCAG2AA` where available.
- FAIL blocks the round. The gate result is printed, not summarised.

**Brief-type scope — the landing-page gate does NOT apply unchanged to
every brief:**

| Gate check | Landing page | Dashboard / app screen | Redesign |
|---|---|---|---|
| `detect` (62 rules) | Applies | Applies | Applies (to the NEW page) |
| copy-lint | Applies | Applies | Applies |
| overflow / collide / tap-size | Applies | Applies | Applies |
| one-section-per-screen + landing rhythm | Applies | Does NOT apply — dense multi-panel layout is expected; judge panel alignment, scan order, density vs legibility instead | Applies only if the page being redesigned is a landing page; otherwise use its own type's rule |
| section height | Applies | Applies per panel/card, not per screen | Same as its type |
| no-visual (visual ≥25% per feature section) | Applies — a photograph, or a `[data-ui]` UI mock ≥120×80px | Applies per panel/card | Same as its type |
| section-gaps (dead-band ceiling) | Applies — no content-to-content gap over 288px at desktop widths (vw ≥ 1024); below 1024px gaps inflate with the viewport, so the structural hero-height rule governs instead (F-3) | Applies per panel/card gaps where the layout has them | Same as its type |
| `mailto:` / `tel:` / `javascript:` links (leg 1 static check) | Applies — non-file schemes are exempt from the file-reference check; a legitimate `mailto:` CTA never fails leg 1 as "referenced file missing" (F-1) | Applies | Applies |
| product-shown | Applies ONLY to physical-product pages (kind `product`); does NOT apply to software/service/app pages | Does NOT apply | Same as its type |
| html-validate / pa11y WCAG2AA | Applies | Applies | Applies, plus: existing content and links survive (dropped content / dead links = FAIL) |

`taste-reference` stays the default taste lens on every build; what is
scoped here is the GATE checks, not the lens.

## 4. Eyes + grade (Playwright CLI)

- Serve the page over http (never file:// — module scripts don't run).
- Screenshot at 1440 / 768 / 390. (390 is the kit standard — JP's 370 is
  CLAIMED and not adopted; taste-skill and the Playwright CLI examples both
  use 390. 1024 is an optional fourth width; every extra width is an extra
  image-token cost per round.)
- **At 390, look for glyphs cut at the viewport edges** (doctrine §8):
  brief 1's hero clipped mid-glyph at 390 while every DOM measurement
  reported "fits" — no box-based gate check catches ink overhang, so the
  eyes are the instrument here and the §1 phone gutter is the prevention.
  A 390 screenshot with text touching x=0 is a defect even when the gate
  is green.
- `playwright-cli console` for errors; `snapshot` for structure (cheap, no
  image tokens).
- Grade 1–5 on Type / Layout / Colour / Space vs the locked reference. EVERY
  score carries ONE LINE of observable evidence. Show the score table every
  round. Grader: an INDEPENDENT judge only — see `grader-rubric.md`. The
  builder never grades its own work. The executable grader is
  `skills/frontend-judge/`, dispatched by name as a fresh sub-agent
  (fallback order: fresh judge sub-agent → `other-model` judge →
  `muse-manager` judge → no grade, "gate green, vision not available").
  **Specialist second opinion (expert pack):** the judge or the
  orchestrator may spawn a matching expert from
  `references/expert-pack.md` / `experts/<domain>.md` as a fresh sub-agent
  when the grade is uncertain on a domain or the brief carries a domain
  risk — same spawn pattern as the judge, never before the gate is green,
  max 2 experts per round. The expert verdict is ADVISORY: the judge keeps
  the final 4-axis scores; the expert's top defects enter the fix list. An
  accessibility REWORK (1–2) blocks shipping even when the 4 axes are ≥4.
- **Cheap-grade ladder (P13, rounds 2–3).** Round 1 is a full 3-width
  grade. Rounds 2–3 that get a grade are cheap grades: the full 390 shot
  + crops of the changed sections only + tool checks (snapshot / console /
  geometry) FIRST, pixels second — a score contradicting a tool
  measurement is invalid. The cost table (Variant B adopted — full-page
  390) is in `references/grader-rubric.md`; it is MEASURED in two
  instrumented runs (W-LOOP exercise, run-1 + run-2 — see the rubric's
  cost table for the per-run figures: R2 build 913 run-1 / 836 run-2,
  R2 images total 1,777 run-1 / 1,700 run-2 on a 2-ref basis; text
  context 35,784 run-1 / 31,414 run-2; whole-round saving 5.9–7.2%
  run-1 / 7.1–8.3% run-2). Downscale ALL judge images to
  1,568px long edge before sending (host note for Claude Code: this avoids
  the high-res tier); model selection is not a loop rule. Every round
  produces FRESH per-axis scores for the whole page from the new
  screenshots, for every axis it grades — carried scores are abolished;
  an unchanged SECTION not re-scored is marked `not re-graded (unchanged
  since round N)` in the score table and recorded in the run log via
  `--not-regraded "<section ids>"`, an explicit absence, never a score. P6 flat-line detection and P8's agreement log
  use fresh scores only. The stop round is always a full fresh grade
  (rule in `references/stop-rules.md`). Precedence: P5's classification
  runs first (token-only fix → gate-only, no grade); P13's cheap grade
  applies only to rounds that get a grade (structural rounds 2–3); when
  P11's pairwise triggers, the round is a full-shot round (full 1440 +
  full 390 of both versions, order randomized) and no crops apply.
  Changed sections are determined mechanically by the git diff of
  `design/tokens.css` + the HTML between rounds, cross-checked against
  the builder's fix list — the builder's self-report is never the
  determiner. The crop helper is
  `skills/frontend-kit/scripts/crop-sections.mjs`; it outputs the input
  manifest (JSON) for the judge spawn listing the 390 full shot + crops +
  tool-check outputs, and fails loudly (full shots for that round,
  labelled in the run log) when its image backend is absent — never
  silently send full shots as if they were crops.

## 5. Fix top 2, as token diffs (or top 1 if the evidence is thin)

- Fixes go to tokens.css first. HTML/layout changes only if the gate still
  fails after the token change.
- Keep the best-scoring version; a round that scores lower is discarded, not
  iterated on (best-version-kept).
- Re-run step 3 (gate), then step 4 (grade).
- **Round folders + archive (step 5.5).** Each fix round is a change
  folder, not a free-form log line: before fixing, copy
  `templates/design/rounds/_template/` to `design/rounds/<n>/` and fill
  in `proposal.md` (bugfix-spec shape: current behaviour / expected
  behaviour / UNCHANGED behaviour — the third line names what must not
  move), `delta.md` (token diffs, ADDED / MODIFIED / REMOVED), and
  `tasks.md` (the top-2 list, each task citing its source). Every fix
  instruction cites its source — a gate finding, a grader evidence line,
  or a human instruction — never "improve it". After the round, the
  ARCHIVE step merges the delta into PLAN.md § Amendments, into the
  token dictionary (`scripts/token-dictionary.mjs`), and into the run
  log's notes — NEVER into TASTE.md or `tokens.css` mid-loop. The lock
  is immutable within a direction. A lessons merge into TASTE.md happens
  only once, after the human gate approves the build (step 6.4). The
  re-run gate + `converge-check.mjs` run against the round's output
  before any re-grade: no archive without converge-green.

## 6. Stop + human gate

- **6.1 Converge check (before the human gate — BLOCKING).** Script
  half: `converge-check.mjs` already ran inside `gate.sh` leg 1 at step
  3 whenever `design/PLAN.md` exists — a failure there blocked the
  grade. Re-run it directly here against the final build (`node
  scripts/gate/converge-check.mjs --plan design/PLAN.md --page
  <built.html>`) and confirm it is green. When Node is unavailable, run
  the checklist in `references/converge-checklist.md` by hand instead
  and record the result in the run log with the degradation labelled.
  Judge half: the step-4 grade already verified the screen × state
  matrix — every applicable cell has a frame / story / preview AND the
  state looks right. A missing state is a scored Layout defect; a Layout
  defect that keeps the build under 4 on that axis blocks the stop the
  same way. A build that drops a planned section or state is NOT
  presented as done: the human gate does not open, and the round goes
  back to step 5 with the failing section or state named. There is no
  advisory mode. The converge result is recorded in the run log.
- **6.2 Stop when:** ≥4 on every axis AND gate green AND cross-check clear — or a P6 trigger
  ends work on the direction (step 5 decision tree) — or after 3 rounds per direction,
  whichever comes first. A build that cannot reach ≥4 in 3 rounds is a direction problem
  (wrong reference, wrong tokens) — re-pick a variant (step 2a),
  not a 4th round. (Bias grows with rounds — Huang et al. 2024, VERIFIED
  from the primary PDF Tables 2–6.) **Re-pick cap: max 2 re-picks, 9 rounds
  total** — 3 rounds in the initial direction + at most 2 re-picks × 3
  rounds each. After the 9th round, stop regardless of scores and present
  the human gate with the best version so far. **Best-version-kept survives
  a re-pick:** the best-scoring version across ALL directions stays the
  version that ships; a re-pick starts a new direction from scratch but
  never discards the previous best. Best-version-kept is decided by the pairwise verdict
  when pairwise runs, by absolute scores otherwise; a tie keeps the incumbent.
  **P6 triggers (D1/D2, 2026-11-10; full text in `references/stop-rules.md`):** the loop
  ends work on a direction on the FIRST non-improving round — one trigger count, not two.
  (a) After round 1, if Layout or Space ≤ 3 AND the judge's evidence lines cite the failure
  (not a bare score), re-pick from the kept variants — ONLY if a structural (break-frame)
  variant exists among them; if all kept variants are CSS-only, (a) does NOT fire and the
  loop escalates instead (present the best version + blocker at the human gate). An early
  re-pick under (a) consumes one of the 2 re-picks. (b) Flat-line: a fix round that improves
  NO axis AND the gate adds no new finding ends work on the direction — flat-line test: no
  axis improved AND gate findings did not decrease AND no new gate finding appeared; a
  round where scores are flat but the gate fixed a finding is NOT flat (gate progress
  counts). One re-grade confirms (second grade, not a second round; third only if the two
  disagree). Rules (c) and (d) are DELETED, and the mid-loop human-escalation sentence is
  DELETED: "escalate" means end work on the direction and present the best version +
  blocker at the existing human gate; in buffet mode the run parks in "awaiting human" as
  designed behaviour. Median-of-3 (e) applies on non-final rounds only; on the round that
  would stop the loop, P14's jury-of-3 applies INSTEAD — never both; max 3 judge calls on
  a stop round. **Stop-round grade:** the round that would stop the loop gets a FULL fresh
  grade (1440/768/390 + references); no carried / not-re-graded axes at the stop decision.
  Stated effect is the mechanism only (no full grade round is spent on a direction after a
  flat round — derived estimate, unmeasured); no quantified round saving is claimed.
- **6.3 Human gate:** score table + the 3-width screenshots + 2–4 targeted questions
  with concrete options (pick them from `references/human-gate-pack.md` —
  never open-ended "what do you think?") + recommended next command,
  ending with `polish`. The human-eye acceptance bar is **60% slop-free**
  (user-ordered 2026-11-10; the ≥4-on-every-axis stop above is unchanged —
  the % is the human-eye bar for the vague-brief acceptance test, the
  4-axis scores are the per-round gate).
  The human's pick or adjective maps through the token dictionary and
  re-enters at step 5 — never as a rebuild. The human-gate pack states
  the converge result in one line: "Converge: green — N sections
  present, M states evidenced, K uncheckable (judge's call, step 4)".
- **6.4 After human approval:** save the 3-width screenshots as the pixel-diff
  baseline so later feedback rounds cannot silently regress it.
  **Post-approval archive (the only TASTE.md merge):** now — and only
  now — merge the rounds' lessons into TASTE.md (what the rounds
  learned about the direction, in one short section). Nothing merges
  into TASTE.md mid-loop, ever.
- **6.5 Record in the run log (P7 run state, in the append-only log — no
  separate run file):** per round — scores, grader identity + independence
  basis, converge result, gate findings (`--gate-findings`, `;`-separated),
  fix class (`--fix-class`), the P6 trigger that ended a direction
  (`--trigger flat-line | round-1-repick`; `stagnation` is a RETIRED value,
  accepted for old logs only, never emitted by the new rules), the pairwise
  verdict (`--pairwise keep-incumbent | keep-challenger | tie` +
  `--pairwise-agrees yes | no`), the stop-round jury (`--jury "<t,l,c,s
  median>"` + `--jury-mode disjoint-3 | single-family | single` +
  `--jury-votes "<v1;v2;v3>"`), outcome (`--outcome kept | discarded | re-pick |
  stopped | escalated | pending`, default `pending`), and the built page
  graded (`--page`); `tokensHash` is recorded automatically as the sha256
  of `design/tokens.css` when present, else null. The plan's approval basis
  (human approval, or "approved-by: converge-check + round-1 grade (no human
  present)") and feedback → token change → new score are recorded the same
  way, so the dictionary grows and rejected directions are never re-proposed.
  The lock is a run-log entry too: `lock --version N` (default: existing lock
  count + 1; a re-pick records a NEW version; re-using an existing version is
  rejected, exit 2) with `--approved-by` carrying the step-1.7 approval basis
  on human-less runs (omit on solo runs — approval lives in PLAN.md).
  **Round brief (fresh context per round):** each round after round 1 starts
  from the minimal brief assembled by `node scripts/run-log.mjs --project
  <dir> brief [--round N]` (or `node scripts/round-brief.mjs` directly) —
  lock + best HTML + gate findings + grader evidence lines + one-line-per-round
  run state, and nothing else; all axes start "ungraded", the lock is restated
  at the end. Never paste the full run log into a builder/fixer prompt.
