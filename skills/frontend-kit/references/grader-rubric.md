# Grader rubric — 4-axis 1–5 with evidence rule and independent-grader rule

## The grader rule (user direction, 2026-11-10, non-negotiable)

**The builder NEVER grades its own work. A builder self-grade is FORBIDDEN,
not merely discouraged.**

Allowed graders only:

| Label | Who | Independence basis (record one per round) |
|---|---|---|
| `judge-subagent` | An independently-trained expert judge sub-agent | Trained separately as a design critic, with NO production history of the build it grades — fresh context, never shown the build's drafts or the builder's reasoning |
| `muse-manager` | Muse (the manager agent) grading directly | A different agent from the builder, no production history of this build |
| `other-model` | A different agent/model from the builder | Different model family (or different agent) from the builder; no production history of this build |

**What is FORBIDDEN is the SAME agent instance/context grading its own
work.** `muse-manager` IS a valid independent grader when it is a
DIFFERENT agent instance from the builder, with no production history of
this build: the user's standing rule (2026-11-10) is that the grader may
be an independently-trained expert judge sub-agent, OR Muse, OR another
agent — Muse grading is explicitly authorised. The old exception ("when
the builder is Muse, `muse-manager` is NOT a valid independent grader")
is SUPERSEDED by coordinator decision, recorded in the repo `AGENTS.md`
(decision (f), 2026-11-10), and is void. What stays invalid, in any
guise, is the builder instance grading its own work: same instance, same
thread, a "fresh pass" inside the build thread, or a `muse-manager`
invocation that shares the builder's context or production history. The
run-log script (`scripts/run-log.mjs`) enforces this: a grader entry is
accepted only with an independence basis stating BOTH fresh context AND
no production history — "fresh context" alone is NOT enough.

**Any score without a named independent grader label is INVALID.** A score
table that lists a grader of `builder`, `self`, or no grader at all must be
thrown out and re-graded by an allowed judge. The run-log script
(`scripts/run-log.mjs`) rejects log entries whose grader is the builder.

**The executable grader is `skills/frontend-judge/`** — a complete judge
skill (SKILL.md + `references/invocation.md` with the fresh-sub-agent
invocation pattern). The orchestrator dispatches step 4 to it by name, as
a fresh sub-agent; the fallback order is fresh judge sub-agent →
`other-model` judge → `muse-manager` judge → no grade ("gate green,
vision not available").

If no independent judge is available, there is no grade. The round's grade
is exactly **"gate green, vision not available"** and the HUMAN gate carries
the full taste judgement. Never fake a 4/5, never present a gate result as a
design grade.

## Human-eye acceptance bar: 60% slop-free (user-ordered 2026-11-10 19:23)

The human-eye acceptance bar for a vague brief is **60% slop-free**,
superseding the old 70–80% figure everywhere it appeared as the acceptance
figure (README, AGENTS.md, muse-app-pack, plugin manifests, clean-env
test). The ≥4-on-every-axis stop rule is UNCHANGED: the % is the human-eye
bar for the acceptance test, the 4-axis scores are the per-round gate. A
build passes the human eye when it reads ≥60% slop-free; the probe loop
still stops at ≥4 on every axis AND gate green, or after 3 rounds.

Why: intrinsic self-correction degrades reasoning (Huang et al. 2024,
VERIFIED from the primary PDF Tables 2–6: GPT-4 GSM8K 95.5 → 91.5 → 89.0
across self-correction rounds). "Fresh context" alone does not change the
weights — only a genuinely independent judge breaks the self-grading loop.
This is red-team risk A1, closed by the user's own fix.

## Precedence over vendored text

This rubric and the orchestrator's grader rule OVERRIDE any vendored
`critique.md` / `new-work.md` / degraded-agent text that permits
single-context self-critique — including upstream Impeccable
`reference/critique.md` (which requires a `⚠️ DEGRADED: single-context`
banner on degraded runs), upstream Impeccable `reference/new-work.md`
(which substitutes a fresh in-thread finish-reviewer pass and a Verdict
Pass from `degraded/finish-reviewer.md` when no subagent capability
exists), and `skills/frontend-design/SKILL.md:57–59` ("Critique your own
work"). Those files are vendored verbatim in the canonical copies and are
not rewritten there (the generator transforms only the generated copies —
see `scripts/generate-host-variants.sh`); inside this kit their
self-critique passages are overridden and must not be followed as grading
instructions. A `⚠️ DEGRADED: single-context` banner is NOT an accepted
grade anywhere in this kit: a degraded run has no grade, and the round's
grade is exactly "gate green, vision not available".

## The four axes

Grade each axis 1–5 against the LOCKED reference (taste folder + tokens.css +
chosen DESIGN.md), not against generic "good design". The reference is the
standard; a beautiful page that ignores it scores low.

| Axis | What it judges | 1 | 3 | 5 |
|---|---|---|---|---|
| Type | Typeface choices, scale, tracking, line length, hierarchy | Default stack, one size everywhere, no hierarchy | Sensible scale, one weak choice (e.g. body too small at 390px) | Deliberate faces with clear roles, scale follows the locked tokens, hierarchy readable at all 3 widths |
| Layout | Section rhythm, one-section-per-screen, alignment, density | Sections collide or run long, no grid | Mostly one-section-per-screen, one rhythm break | Every section exactly one (or two) screens, alignment consistent, whitespace follows the locked space scale |
| Colour | Colour roles, contrast, accent discipline | Accent everywhere or nowhere, contrast below WCAG AA | Roles mostly right, one contrast or accent slip | Roles match the locked tokens, one accent used sparingly, all text passes WCAG AA |

**Contrast — decorative vs functional accent (probe G-9c, third place this
is stated; see also `gate.mjs` header and `frontend-kit/SKILL.md` step 3):**
a vendored reference's component that fails the contrast rule is NOT
shippable verbatim. Claude's `callout-card-coral` (white text on coral
#d97757, 3.12:1) fails WCAG AA and the kit's 7:1 body-text rule: coral stays
DECORATIVE ONLY (never behind text); text-bearing surfaces use the darkened
functional accent (#a9583e, white 5.06:1, passes AA). Body/muted text keeps
the kit's 7:1 rule; CTA text passes at WCAG AA 4.5:1. A page that ships the
reference's coral callout card verbatim scores Colour low AND fails the
gate's `text-contrast` check — the two agree; adapt the component, never
lower the rule.

**Gate scope the judge shares:** `product-shown` applies ONLY to
physical-product pages (kind `product`); it does not apply to
software/service/app pages. `no-visual` (a visual ≥25% per feature section)
applies to landing pages; the visual is a photograph or a `[data-ui]` UI
mock ≥120×80px — small inline SVG icons do not count. A text-only mock on
its own ground also needs a small svg in its header bar or it FAILs as a
band (F-5). **Section gaps:** no content-to-content gap over 288px at
desktop widths (vw ≥ 1024) — a dead band, and the gate FAILs it (kit patch,
probe 3 + judge W-JUDGE-2); fill ≥55% alone does not catch dead bands
(brief 1's sections fill 56–67% yet carry 297–398px gaps). **Phone gutter:**
below the 1240px container breakpoint `.wrap` carries 20px side margins —
text touching the screen edges at 390px is a defect even when the gate is
green, and mid-glyph clipping at the edge is caught by the eyes, not by any
box-based check (doctrine §8). The layout doctrine
(`references/layout-doctrine.md`) is the taught standard the Layout axis is
judged against.
| Space | Spacing scale, section gaps, padding, breathing room | Cramped or random gaps, padding inconsistent | Scale mostly followed, one gap off-scale | Space scale followed throughout, section gaps 128–288px at desktop widths with no gap over 288px (a dead band), content breathes |

**Layout is scoped by brief type** (the step-3 scoping table in
`frontend-kit` SKILL.md / `workflow.md` governs): the one-section-per-screen
cells above are the LANDING rule. For a dashboard / app screen,
one-section-per-screen does NOT apply — judge panel alignment, scan order,
and density vs legibility instead. For a redesign, use the rule of the page
being redesigned, plus: existing content and links survive. The judge skill
(`skills/frontend-judge/`) states the same scoping in its Layout section.

## The evidence rule

EVERY score carries ONE LINE of observable evidence: a named element, a
measured contrast ratio, or a pixel value. A score without evidence is not a
score.

Good: `Type 4 — hero H1 "Steel widgets" is Newsreader roman 64px / -0.03em
tracking per tokens.css; body 16px/1.55, max 68ch.` (Newsreader roman is
gate-clean — verified against `impeccable detect`, engine 0.1.21: exit 0
on a 64px hero. Do NOT use Instrument Serif here: it sits on the
detector's overused-font list and the same hero flags exit 2.)
Bad: `Type 4 — looks good.`

Evidence must be checkable in the screenshot or the file. "Feels premium",
"nice hierarchy", "good vibe" are not evidence.

## Score table format (show every round)

```
Round 2 — grader: judge-subagent (fresh context, no production history)
| Axis   | Score | Evidence (one line, observable)                          |
|--------|-------|----------------------------------------------------------|
| Type   | 4     | Hero H1 Newsreader roman 64px/-0.03em; body 16px/1.55   |
| Layout | 3     | Pricing section peeks 24px into the viewport at 768px   |
| Colour | 4     | Accent #d97757 used twice (CTA + footer mark); body text 12.6:1 |
| Space  | 5     | Section gaps 192px throughout (2×96px section padding, inside the 128–288px band); card padding 32px per tokens |
Gate: PASS (detect 0 findings, consistency 0 FAIL, copy-lint 0 FAIL)
```

## Fix order

Fix the top 2 lowest-scoring axes (top 1 if the evidence is thin), as token
diffs first. A 3 that has a precise, cheap fix outranks a 2 whose fix is
vague — say which you picked and why in the run log.
