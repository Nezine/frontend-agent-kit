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

## Blind grading — the D8 whitelist (P9, council decision D8)

The judge grades blind. This whitelist replaces P9's as-written blinding
("screenshots + rubric only"), which forbade inputs P11/P12/P13 require.
It is the complete list of what the judge may and may not receive.

| ALLOWED judge inputs | FORBIDDEN judge inputs |
|---|---|
| Screenshots of the built page (1440 / 768 / 390) | Model / builder identity (who built the page, which model) |
| Locked reference shots (1–3 from the lock, 720px long edge, every round) | Earlier scores (any judge's, any round) |
| Rubric / scope (the rubric + the brief-type scope) | Run log (contains earlier grades — anchors the new grade) |
| Lock text (`design/TASTE.md` + chosen DESIGN.md + `design/tokens.css`) | Gate findings (findings lists, `detect` output, gate-scripts output) |
| Tool measurements (Playwright snapshot / console / geometry) | Builder's transcript, reasoning, plan, or drafts |
| Pairwise A/B inputs (P11: full shots of both versions, labelled A/B only) | Unpicked variants (direction alternatives, not evidence) |
| The single bit `gate: green` (the ONLY gate information the judge receives) | Anything about the builder's model, host, or history |

Gate handled by orchestrator pre-filter: the orchestrator does not spawn a
judge on a red gate, so a red gate never reaches the judge as a grading
task. The single `gate: green` bit is the only exception, enforced by the
orchestrator — the judge never sees gate findings.

There is no builder-graded path, and builder grading can never trigger the
stop rule. Any score without a named independent grader label
(`judge-subagent` / `muse-manager` / `other-model`) is INVALID and cannot
trigger the stop; the run-log script rejects builder-graded entries (exit
2, nothing written). There is no degraded builder-grading rung to fall back
to — if no independent judge is available, the round's grade is exactly
"gate green, vision not available" and the human gate carries the full
taste judgement.

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
| Layout | Section rhythm, one-section-per-screen, alignment, density, scroll rhythm (pinned sections, hero expansion, header condense behaviour) | Sections collide or run long, no grid | Mostly one-section-per-screen, one rhythm break | Every section exactly one (or two) screens, alignment consistent, whitespace follows the locked space scale |
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
score. Evidence comes BEFORE the number in the score table (Evidence column
first, Score second) — number-first-then-justify is how unjustified scores
slip through.

Every evidence line must name the locked reference image the score is
judged against (ref 1 / ref 2 / ref 3, as the orchestrator numbered them).
A score that does not cite the reference is invalid — the judge grades
against the locked reference, and the citation is what proves it looked at
it.

An evidence line about scroll motion also cites the scroll-motion recipe
pattern by number (`references/style-recipes/scroll-motion.md` Pattern N,
e.g. Pattern 2 for the expanding hero card) as well as the reference — a
motion claim with no pattern number is invalid, same as a score with no
reference citation.

Good: `Layout 3 — hero stacks vertically vs ref 2 (Aesop) hero, which holds
one full-viewport image; section rhythm breaks at 768px.`
Good: `Layout 4 — hero card expands to full-bleed over ~300px scroll vs ref 1 (scroll-motion Pattern 2); no second hero moment; sections hold one-per-screen.`
Good: `Type 4 — hero H1 "Steel widgets" is Newsreader roman 64px / -0.03em
tracking per tokens.css; body 16px/1.55, max 68ch.` (Newsreader roman is
gate-clean — verified against `impeccable detect`, engine 0.1.21: exit 0
on a 64px hero. Do NOT use Instrument Serif here: it sits on the
detector's overused-font list and the same hero flags exit 2.)
Bad: `Type 4 — looks good.`
Bad: `Layout 3 — section rhythm breaks at 768px.` (no reference cited)

Evidence must be checkable in the screenshot or the file. "Feels premium",
"nice hierarchy", "good vibe" are not evidence.

## Score table format (show every round)

Evidence first, Score second — the column order is part of the evidence
rule, not formatting preference.

```
Round 2 — grader: judge-subagent (fresh context, no production history)
| Axis   | Evidence (one line, observable, citing the reference)      | Score |
|--------|--------------------------------------------------------------|-------|
| Type   | Hero H1 Newsreader roman 64px/-0.03em vs ref 1; body 16px/1.55 | 4     |
| Layout | Pricing section peeks 24px into the viewport at 768px vs ref 2 | 3     |
| Colour | Accent #d97757 used twice (CTA + footer mark) vs ref 1; body text 12.6:1 | 4     |
| Space  | Section gaps 192px throughout (2×96px section padding, inside the 128–288px band) vs ref 1; card padding 32px per tokens | 5     |
Gate: green
```

**Motion (non-scoring):** if a motion expert was consulted this round, the
report adds one paragraph after the `Gate: green` line, surfacing the
expert's existing 1–5 domain score (`skills/frontend-kit/experts/motion.md`)
— `Motion: <score> (motion-expert) — <the expert's one-line evidence>`.
It never changes any axis score and never affects the stop rule. If no
motion expert was consulted this round, the paragraph is omitted — never
invent a motion score.

## Fix order

Fix the top 2 lowest-scoring axes (top 1 if the evidence is thin), as token
diffs first. A 3 that has a precise, cheap fix outranks a 2 whose fix is
vague — say which you picked and why in the run log.

Every fix instruction must cite a gate finding, a grader evidence line, or
a human instruction — never "improve it". A fix instruction with no
citation is not a fix instruction. The orchestrator's fix prompt must
require the citation field; a fix prompt without it is rejected by the
orchestrator.

## Calibration — one shared pass (P9 + P14, E8)

There is ONE calibration pass, not two: P9 and P14 share it. It is the
precondition for P6 (triggers consume judge scores), P11 (pairwise), P13
(carried-score abolition) and P14 (jury). It measures, and only it
measures, judge–human agreement.

- **What:** the human blind-grades the 3 clean-env probe builds
  (`tests/clean-env/probe-briefs.md`) once, on the same 4 axes
  (Type/Layout/Colour/Space, 1–5), blind to the judge's scores. The judge
  grades the same 3 builds blind (D8-whitelisted inputs, including the
  locked reference shots — the calibration measures the judge as it will
  actually run — no human scores, no gate findings beyond the green bit).
  3 builds × 4 axes = **12 paired scores**.
- **Computed per axis:** exact-match rate, within-1 rate, and mean signed
  overshoot (`judge − human`, in points). Plus overall exact/within-1.
  Cohen's κ is NOT computed at n=12 (unstable) — only when the sample
  reaches n≥32.
- **What it does NOT measure:** pairwise keep/discard agreement, jury
  agreement, agreement on any brief outside the 3 probes, or the
  human–human agreement ceiling (unknown — the 80% headline from Zheng et
  al. is for open-ended chat preference and does not transfer to design).
- **Decision rule:** (a) If mean signed overshoot on any axis is ≥ +1.0pt
  (judge systematically overshoots), the rubric's anchor descriptions for
  that axis are rewritten to the human's anchors immediately, regardless
  of sample size — a bias fix, not a threshold vote. (b) The 80%
  Layout/Space agreement threshold is REPORT-ONLY until the sample reaches
  n≥30 paired scores (council member A) / n≥32 (council member B) — at
  n=12, one score flips 83% to 75%, so the threshold cannot govern the
  stop rule. Between n=30 and n=31 the two counts disagree; until n≥32
  treat the threshold as report-only. (c) Only at n≥32, if Layout/Space
  agreement is <80%, does the judge stop gating the stop rule — and the
  consequence is then: the stop requires a human grade (the human gate
  carries the certification, which it already does as the final step),
  recorded per build. In buffet mode this does not park the run: the loop
  still runs to the human gate, which is where the human already is.
- **Artefact:** `research/judge-calibration.md` (new): gold set (the 3
  probe builds), the human's blind grades, the judge's blind grades,
  per-axis table, overshoot, decision taken under (a)–(c).
  `tests/clean-env/probe-briefs.md` gains one line: "human grades these
  blind (see `research/judge-calibration.md`)".

## Cost table — P12 + P13, Variant B (council member B)

Planning figures, DERIVED, not measured. Replaces the synthesis table and
the grading worker's §2 table. **Variant B (full-page 390) is the adopted
column** — 390 is where defects hide. The ~2,500 figure is Variant A
(390 viewport), not Variant B; do not cite it as the Variant B cost.

**Formula (DERIVED, CLAIMED via convergent secondaries quoting Anthropic's
docs — NOT verified against Anthropic's official docs):** image tokens ≈
`min(width × height / 750, 1,568)` per image, standard tier (long edge
1,568px, cap ~1,568 tokens/image). **Tier assumption, stated on every
number below: standard tier.** On a Claude 4.7+ high-res tier the same
shots cost ~3× per image (same PNG 1,578 → 4,744 tokens; same three
full-page shots ~8,000–9,500). The enforceable defence is downscaling to
1,568px long edge before sending, not a model pin.

| Images per round (standard tier) | Current loop | With P12+P13, Variant A (390 viewport) | With P12+P13, Variant B (390 full-page) |
|---|---|---|---|
| Round 1: build shots (1440 + 768 + 390 full-page) | ~4,700 (1,568 + 1,568 + 1,560) | ~4,700 | ~4,700 |
| Round 1: reference shots (1–3 locked refs, 720px long edge) | 0 (the hole P12 fixes) | +~1,400 (3 refs × ~470) | +~1,400 |
| **Round 1 images total** | **~4,700** | **~6,100** | **~6,100** |
| Rounds 2–3: build images | ~4,700 | ~1,100 (390 viewport 439 + crops 432 + 260) | ~2,250 (390 full-page 1,560 + crops 432 + 260) |
| Rounds 2–3: reference shots | 0 | +~1,400 | +~1,400 |
| **Rounds 2–3 images total (each)** | **~4,700** | **~2,500 (E3's figure — viewport reading only)** | **~3,650** |
| Images / build, 3 rounds | ~14,100 | ~11,100 (−21%) | ~13,400 (−5%) |
| Images / build, 2 rounds (typical, flat-line stop) | ~9,400 | ~8,600 (−9%) | ~9,750 (+4% — MORE than current) |

Reference shots cost **+~1,400 image tokens/round** for 3 downscaled refs
(range ~1,300–2,100 depending on aspect; 1 ref ≈ 470).

**Text-context caveat:** a fresh judge invocation also reloads the judge
skill, TASTE.md + DESIGN.md, `tokens.css`, the HTML, and the brief-type
scope — ~4k text tokens per judge call, unmeasured estimate, same order as
or larger than the image bill. Cropping therefore saves ~10–30% of a
round, not 80%. The synthesis's "~30–40% worst case" and the worker's own
disagreeing figures ("~30–50%", "~10–30%") are retired; the single stated
figure is: **image-token saving on rounds 2–3 is −47% (Variant A) / −22%
(Variant B); whole-round saving is ~10–30% (Variant A) and ~0–12%
(Variant B), because text context dominates.** The largest saving remains
rounds not run (P6 flat-line stop) and judge calls not made — not crops.

**What this table still cannot correct from available evidence:** the ~4k
text-context figure (needs one instrumented probe build — no instrumented
cost run exists); the /750 formula itself (CLAIMED via secondaries, not
Anthropic's official docs); the high-res-tier multiplier for full-page
shots. The first verification step is that one instrumented run, and the
table is then re-issued with measured numbers.
