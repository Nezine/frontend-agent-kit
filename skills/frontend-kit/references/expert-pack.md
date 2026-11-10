# Expert pack — index + call rules

The expert pack is the kit's pre-packaged set of independent domain
specialists. Each expert is one Markdown brief in
`skills/frontend-kit/experts/<domain>.md`. The orchestrator (`frontend-kit`)
and the judge (`frontend-judge`) call them as fresh sub-agents when a round
needs domain expertise — never the builder, never in the build thread.

## The pack (10 domains)

| Domain | File | Judges | Call it when |
|---|---|---|---|
| Typography | `experts/typography.md` | Faces, roles, scale, leading, measure, hierarchy, Vietnamese diacritics | The judge's Type score is uncertain, or type is the suspected defect |
| Colour | `experts/colour.md` | Colour roles, contrast, accent discipline, flat grounds | Contrast or accent use is disputed, or a vendored colour fails the rule |
| Layout | `experts/layout.md` | Section rhythm, grid, gaps, alignment, brief-type rule | The judge's Layout score is uncertain, or rhythm/dead bands are suspected |
| Motion / interaction | `experts/motion.md` | Durations, reveals, states, reduced motion, jank | The brief has motion, reveals, or interactive states worth a second eye |
| Accessibility | `experts/accessibility.md` | Keyboard, screen-reader structure, contrast, touch, zoom | Any a11y doubt — pa11y findings, unnamed controls, focus or target issues |
| Copy / UX-writing | `experts/copy.md` | Headline, one idea per block, word budget, labels, voice | Copy reads generic, or a CTA/label is vague, or the page is overweight in words |
| Imagery | `experts/imagery.md` | Real vs stock, product-shown, weight budget, diagrams, icons | Any image doubt — stock-looking hero, tiny product, overweight hero |
| Design systems | `experts/design-systems.md` | One system, tokens-only, component recipes, token/reference match | Drift is suspected — ad-hoc values, two button recipes, tokens not matching the lock |
| Performance | `experts/performance.md` | Page/image/font/script budgets, layout shift, loading behaviour | The page is overweight, fonts shift, or loading behaviour is un-designed |
| Responsive | `experts/responsive.md` | Overflow, clipped glyphs, stacking order, tap targets, breakpoints | Anything width-specific — the desktop looks fine and the phone is suspect |

## When to call an expert (and when not to)

- **Default: the judge decides.** The judge (`frontend-judge`) may call a
  specialist second opinion when its own 4-axis grade is uncertain on a
  domain, or when it suspects a domain defect outside its confidence. The
  orchestrator may also call one at step 4 when the brief itself carries a
  domain risk (e.g. a motion-heavy brief → motion expert; a copy-heavy
  landing → copy expert; a dashboard → responsive + accessibility).
- **Never before the gate is green.** No expert grades a red-gate build:
  the gate result is an input to every expert, and a red gate means there
  is nothing to grade.
- **Never more than 2 experts per round.** If three or more domains are
  suspect, the build has a direction problem — re-pick the variant, not a
  third expert. Experts are a second opinion, not a committee.
- **Never the builder, never in the build thread.** Experts are spawned
  exactly like the judge (see "Spawn pattern" below). The builder never
  calls an expert on its own work, and an expert never sees the builder's
  reasoning.
- **The Muse app cannot call experts.** The app has no sub-agents, so the
  paste packet (`templates/install/muse-app-pack.md`) has no expert step —
  the human is the judge there.

## Spawn pattern (same as the judge — only correct form)

Spawn a **fresh sub-agent** (or a separate agent instance on hosts without
sub-agents) with:

1. **A fresh context.** The expert's context contains ONLY the inputs its
   brief lists — the built page, `design/tokens.css`, `design/TASTE.md`,
   the chosen DESIGN.md file(s), the 1440/768/390 screenshots, the gate
   result, and the brief type. It contains NOTHING else about the build:
   no builder transcript, no builder reasoning, no drafts, no earlier
   rounds' scores, no variant history, no run-log entries, no judge
   scores.
2. **The expert brief, by path.** The spawn instruction names the expert
   file explicitly (`skills/frontend-kit/experts/<domain>.md`) and tells
   the sub-agent to read it and follow it. Do not paste a summary of the
   brief into the spawn message — the file is the brief.
3. **No production history.** The expert instance has never built, edited,
   or reviewed any part of this page before. An expert that graded round 1
   must not grade round 2 of the same build: spawn a new one per round.
4. **No shared context with the builder.** The expert is not the builder
   instance, not a continuation of the builder thread, and not a "fresh
   pass" inside the build thread.

Example spawn instruction (adapt the paths; keep the constraints verbatim):

> You are a fresh sub-agent with no history of this build. Read
> `skills/frontend-kit/experts/typography.md` and follow it exactly.
> Grade this round only. Inputs: page `<project>/index.html`, tokens
> `<project>/design/tokens.css`, taste `<project>/design/TASTE.md`,
> reference `<project>/design/references/DESIGN.md/<brand>.md`,
> screenshots `<project>/design/screenshots/{1440,768,390}.png`, gate
> result: <PASS + findings or FAIL + findings>, brief type: <landing |
> dashboard/app | redesign>. Return the score table in the brief's output
> format. Edit nothing. You have not seen this build before; if any of
> these inputs is missing, say so instead of grading around it.

## How an expert verdict is used

- **Advisory to the judge, never a replacement.** The judge keeps the
  final Type/Layout/Colour/Space scores. An expert's domain score and top
  defects inform the judge's fix order: a domain FAIL the judge missed
  becomes a fix; a domain PASS the judge doubted confirms the score.
- **Recorded in the run log.** The orchestrator records each expert verdict
  with the expert label (`<domain>-expert`, e.g. `typography-expert`) and
  the independence basis (fresh/separate context AND no production
  history). The run-log script rejects a grader entry whose basis states
  only one half — the same rule as for the judge.
- **Disagreement rule.** If an expert and the judge disagree, the judge's
  4-axis score stands for the stop condition (≥4 on every axis AND gate
  green), but the expert's defects still enter the fix list: the builder
  fixes the top 2 across judge + experts, as token diffs first. A
  disagreement is recorded in the run log, not silently resolved.
- **An accessibility REWORK can block shipping.** If the accessibility
  expert returns REWORK (1–2), the build does not ship even when the
  judge's 4 axes are ≥4 — say so in the human gate. Every other expert's
  REWORK is a direction signal (re-pick the variant), not a ship-blocker.

## What the pack does not contain (deliberately)

- **3D/WebGL expert** — threeui is opt-in only and brief-conditional; the
  GSAP skills and `threeui` already own motion-3D. A standing expert
  would rarely fire.
- **SEO/semantic-HTML expert** — the gate checks validity deterministically
  (`html-validate`); no vision judgement is left to grade.
- **Figma-to-code expert** — Figma is human-gated/opt-in with no
  unattended path; there is no live material to grade in the default loop.
- **Vietnamese-typography expert** — a sub-criterion of typography (the
  diacritic-subset hard gate in `experts/typography.md`), not a standalone
  brief.
- **Data-visualisation expert** — covered by layout (structure) + imagery
  (visual weight); the 27 diagram presets are a lookup, not a judgement
  domain.
- **Brand/identity expert** — overlaps design-systems + the taste lock;
  the locked DESIGN.md already is the identity standard.
