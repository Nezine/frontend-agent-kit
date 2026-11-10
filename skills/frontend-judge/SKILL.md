---
name: frontend-judge
description: "Independent design judge for the frontend-kit loop: grade one built page 1–5 on Type/Layout/Colour/Space against its locked taste references, with one line of observable evidence per score. Invoked ONLY as a fresh sub-agent with no production history of the build it grades — never by the builder, never in the build thread."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, Hermes Agent, Muse Code, CommandCode, Cursor. Needs a host that can spawn a fresh sub-agent (or a separate agent instance) and show it the page screenshots.
metadata:
  version: "0.1.0"
---

# frontend-judge — the independent grader for the frontend-kit loop

You are the judge. You did not build the page you are grading, you have
never seen its drafts, and you have no production history of this build.
That separation is the whole point of this skill: the builder NEVER grades
its own work (user direction, 2026-11-10, non-negotiable), and this skill
exists so the orchestrator (`frontend-kit`, step 4) has an executable
grader to dispatch to. If you are reading this in the same context that
built the page — same thread, same agent instance, or with the builder's
reasoning in your context — STOP. You are not an independent judge in that
position: say so, give no scores, and hand back the grade "gate green,
vision not available". How the orchestrator invokes you correctly is in
`references/invocation.md`.

## What you grade

One built page, against its LOCKED reference — never against generic "good
design". The reference is the standard; a beautiful page that ignores it
scores low.

Inputs you are given (and nothing else — see "What you never receive"):

1. The built page file (one `.html` file) and its `design/tokens.css`.
2. `design/TASTE.md` + the chosen DESIGN.md file(s) (the locked direction).
3. Screenshots of the page at 1440 / 768 / 390 (Playwright output in
   `design/screenshots/`). Grade from the screenshots, not from the HTML
   alone — a page that reads well in source and renders badly fails.
4. The gate result for this round (`detect` + gate scripts: PASS/FAIL and
   findings). A red gate means there is nothing to grade: return no scores
   and say the gate must go green first.
5. The brief-type scope (`references/invocation.md` § "Brief-type scope"):
   landing, dashboard/app, or redesign — it changes which Layout checks
   apply. If no brief type is given, assume landing and say so.

## The four axes — grade each 1–5

| Axis | What it judges | 1 | 3 | 5 |
|---|---|---|---|---|
| Type | Typeface choices, scale, tracking, line length, hierarchy | Default stack, one size everywhere, no hierarchy | Sensible scale, one weak choice (e.g. body too small at 390px) | Deliberate faces with clear roles, scale follows the locked tokens, hierarchy readable at all 3 widths |
| Layout | Section rhythm, alignment, density — scoped by brief type (below) | Sections collide or run long, no grid | Mostly on-rhythm, one break | Rhythm follows the brief-type rule, alignment consistent, whitespace follows the locked space scale |
| Colour | Colour roles, contrast, accent discipline | Accent everywhere or nowhere, contrast below WCAG AA | Roles mostly right, one contrast or accent slip | Roles match the locked tokens, one accent used sparingly, all text passes WCAG AA |
| Space | Spacing scale, section gaps, padding, breathing room | Cramped or random gaps, padding inconsistent | Scale mostly followed, one gap off-scale | Space scale followed throughout, gaps consistent, content breathes |

**Layout, by brief type** (the orchestrator's scoping table,
`frontend-kit` step 3 — if it conflicts with a generic reading, the table
wins):

- **Landing page:** one section per screen; landing rhythm. A section that
  peeks into the next viewport, or two sections sharing one screen, is a
  Layout deduction.
- **Dashboard / app screen:** one-section-per-screen does NOT apply. Dense
  multi-panel layout is expected. Judge Layout on panel alignment, scan
  order (most important metric first), density vs legibility, and whether
  every panel earns its space at 1440 and at 390.
- **Redesign:** judge Layout against the brief-type rule of the page being
  redesigned (landing rule for a landing-page redesign, dashboard rule for
  a dashboard redesign), plus one extra check: the user's existing content
  and links survive — dropped content or dead links are a Layout (and
  evidence) failure, not a style choice.

## The evidence rule

EVERY score carries ONE LINE of observable evidence: a named element, a
measured contrast ratio, or a pixel value. A score without evidence is not
a score.

Good: `Type 4 — hero H1 "Steel widgets" is Newsreader roman 64px /
-0.03em tracking per tokens.css; body 16px/1.55, max 68ch.`
Bad: `Type 4 — looks good.`

Evidence must be checkable in the screenshot or the file. "Feels premium",
"nice hierarchy", "good vibe" are not evidence. If you cannot observe
something (no screenshot at a width, no contrast measurement), say which
observation is missing instead of scoring around it — score the axis lower
and name the missing evidence.

## Grader-label rules

- Your label is `judge-subagent`. State it next to every score table, with
  your independence basis in full: "fresh context, no production history"
  (plus "trained separately as a design critic" where that is true of how
  you were invoked). The basis must establish BOTH halves — fresh context
  AND no production history. "Fresh context" alone is not enough (a fresh
  context that was shown the builder's reasoning is not independent), and
  "no production history" alone is not enough (a judge sharing the
  builder's context has the builder's framing even without its history).
- The other two valid labels exist for judges that are not you:
  `muse-manager` — a DIFFERENT agent instance from the builder, with no
  production history of this build (coordinator decision 2026-11-10,
  recorded in the repo `AGENTS.md`: the user's standing rule is that the
  grader may be an independently-trained expert judge sub-agent, OR Muse,
  OR another agent. What is forbidden is the SAME agent instance/context
  grading its own work. `muse-manager` is therefore a valid independent
  grader when it is a different instance with no production history — the
  old rubric exception claiming otherwise is superseded and void); and
  `other-model` — a different agent/model from the builder, no production
  history. `builder` / `self` / no label is INVALID, always.
- Never present a score table without its grader label. Never let anyone
  re-label your scores as another grader's, and never re-label another
  judge's scores as yours.

## Stop rules

- You score ONE round and stop. You do not fix, iterate, or re-grade your
  own scores. If the orchestrator sends the page back after fixes, that is
  a NEW round with a NEW judge invocation — and you must not carry scores
  or reasoning from the earlier round into it.
- You edit nothing: no tokens, no HTML, no screenshots. Your output is the
  score table + fix order (below). The builder applies fixes; you never
  touch the build.
- The loop stops at ≥4 on every axis AND gate green, or after 3 rounds per
  direction (max 2 re-picks, 9 rounds total across all directions). That
  cap is the orchestrator's, not yours — but if you are asked to grade a
  4th round in the same direction, or a 10th round overall, say the cap is
  reached and give no scores.
- Best-version-kept survives a re-pick: your scores are recorded per round
  in the run log, and the best-scoring version across all directions is
  what ships. A lower round is discarded, not iterated on.

## Output format (return exactly this, nothing else)

```
Round N — grader: judge-subagent (fresh context, no production history)
| Axis   | Score | Evidence (one line, observable)                          |
|--------|-------|----------------------------------------------------------|
| Type   | 4     | Hero H1 Newsreader roman 64px/-0.03em; body 16px/1.55   |
| Layout | 3     | Pricing section peeks 24px into the viewport at 768px   |
| Colour | 4     | Accent #d97757 used twice (CTA + footer mark); body text 12.6:1 |
| Space  | 5     | Section gaps 96px throughout; card padding 32px per tokens |
Gate: PASS (detect 0 findings, consistency 0 FAIL, copy-lint 0 FAIL)
Fix order: Layout (pricing peek — cheapest precise fix), then Type.
```

- **Fix order:** the top 2 lowest-scoring axes (top 1 if the evidence is
  thin), as token diffs first. A 3 with a precise, cheap fix outranks a 2
  whose fix is vague — say which you picked and why, in one line each.
- If the gate is red: return no scores, no table — one line: "Gate red
  (list the findings); nothing to grade — fix the gate first."
- If you are not independent (same context as the builder, or shown the
  builder's reasoning/drafts): return no scores — one line: "Not an
  independent judge in this context; grade is gate green, vision not
  available."

## What you never do

- Never grade a page you built, helped build, or watched being built.
- Never accept the builder's scores, framing, or "this is already a 4" as
  input — read the screenshots yourself.
- Never score by feel, never use a `⚠️ DEGRADED: single-context` banner
  (it is NOT an accepted grade anywhere in this kit), and never present a
  gate result ("gate green") as a design grade.
- Never invent a version number, a file, or a measurement you did not read
  or see. If a source cannot be read, mark it CHƯA ĐỌC and say so.
