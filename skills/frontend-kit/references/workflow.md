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
design/screenshots/      — this build's shots (Playwright output)
design/variants/         — CSS-only variants + their screenshots
```

Install (by the kit): Playwright CLI pinned + vendored gate scripts
(`impeccable detect` + taste-skill-style consistency/gate scripts) + skills.

## 1. Brief → taste lock (no build yet)

- Read the brief + TASTE.md + the chosen DESIGN.md.
- Pick the reference direction (which sites, which DESIGN.md) and write
  tokens.css: type scale, colour roles, space scale, radius, motion.
- Build a 1-page demo proving the tokens work (same content every time, so
  tokens are comparable across briefs). The demo file is
  `templates/design/demo.html` (copied into the project as
  `design/demo.html`); it exercises every expected token (display/body/mono
  type, hero scale, colour roles incl. accent, space scale, radius, motion)
  against the LOCKED `tokens.css`. **Pass criterion:** the demo renders
  every listed token visibly AND passes the step-3 gate when gated on its
  own (`gate.sh --target design/demo.html`: `detect` 0 findings, static
  checks pass). A demo that fails the gate proves the tokens are wrong:
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
- **VERIFIABLE ARTIFACT:** tokens.css + the chosen references are committed
  BEFORE any HTML is written. If the output's tokens do not match the locked
  references, the workflow has a hole, not a feature. **"Commit" means
  exactly:** (a) the files are saved under `design/` in the project, AND
  (b) the lock is recorded in the run log (`node scripts/run-log.mjs
  --project <dir> lock --tokens design/tokens.css --refs <chosen DESIGN.md
  + reference screenshots>`). If the project is a git repo, ALSO `git add
  design/ && git commit -m "Taste lock: <direction>"`; if it is not a git
  repo, (a) + (b) alone ARE the commit — never create a repo just for this,
  and never treat "saved the file" without the run-log lock as committed.

## 2. Build (one HTML file, tokens only — no inline style drift)

- Content first, then sections — one section per screen for landing pages;
  dashboards / app screens use the dense multi-panel layout instead (see the
  brief-type scoping table in step 3 — it governs both the build shape and
  the gate).
- If the brief is vague on direction: generate the 5 CSS-only variants (same
  content, same copy, same semantic HTML — only CSS changes; Editorial /
  Dark / Warm brutalist / Glassy / Minimal — each as a concrete token
  direction in `references/variant-briefs.md`), each with its own tokens,
  screenshot each at the same width. **Variant folder layout** (the picker
  requires it): `design/variants/<name>/tokens.css`,
  `design/variants/<name>/screenshot-1440.png`,
  `design/variants/<name>/index.html`. The human picks one (step 2a). The pick
  IS the feedback — never re-argue direction in prose. **Human-less runs:**
  the deterministic pick — `variant-picker.mjs pick --auto`: the variant
  whose tokens match the locked `design/tokens.css` most closely (count of
  locked `--name: value` declarations reproduced exactly; ties broken
  alphabetically). No quality verdict.

## 3. Deterministic gate (runs BEFORE any vision grade)

**The gate is TWO legs, BOTH required — a pass means both green on the
same build.** Leg 1 is `gate.sh` (taste lock + `impeccable detect` + static
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

## 5. Fix top 2, as token diffs (or top 1 if the evidence is thin)

- Fixes go to tokens.css first. HTML/layout changes only if the gate still
  fails after the token change.
- Keep the best-scoring version; a round that scores lower is discarded, not
  iterated on (best-version-kept).
- Re-run step 3 (gate), then step 4 (grade).

## 6. Stop + human gate

- Stop when: ≥4 on every axis AND gate green — or after 3 rounds, whichever
  comes first. A build that cannot reach ≥4 in 3 rounds is a direction
  problem (wrong reference, wrong tokens) — re-pick a variant (step 2a),
  not a 4th round. (Bias grows with rounds — Huang et al. 2024, VERIFIED
  from the primary PDF Tables 2–6.) **Re-pick cap: max 2 re-picks, 9 rounds
  total** — 3 rounds in the initial direction + at most 2 re-picks × 3
  rounds each. After the 9th round, stop regardless of scores and present
  the human gate with the best version so far. **Best-version-kept survives
  a re-pick:** the best-scoring version across ALL directions stays the
  version that ships; a re-pick starts a new direction from scratch but
  never discards the previous best.
- Human gate: score table + the 3-width screenshots + 2–4 targeted questions
  with concrete options (pick them from `references/human-gate-pack.md` —
  never open-ended "what do you think?") + recommended next command,
  ending with `polish`. The human-eye acceptance bar is **60% slop-free**
  (user-ordered 2026-11-10; the ≥4-on-every-axis stop above is unchanged —
  the % is the human-eye bar for the vague-brief acceptance test, the
  4-axis scores are the per-round gate).
  The human's pick or adjective maps through the token dictionary and
  re-enters at step 5 — never as a rebuild.
- After human approval: save the 3-width screenshots as the pixel-diff
  baseline so later feedback rounds cannot silently regress it.
- Record in the run log: scores per round, grader identity + independence
  basis per round, feedback → token change → new score (so the dictionary
  grows and rejected directions are never re-proposed).
