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
run-log script (`skills/frontend-kit/scripts/run-log.mjs`) enforces this: a grader entry is
accepted only with an independence basis stating BOTH fresh context AND
no production history — "fresh context" alone is NOT enough.

**Any score without a named independent grader label is INVALID.** A score
table that lists a grader of `builder`, `self`, or no grader at all must be
thrown out and re-graded by an allowed judge. The run-log script
(`skills/frontend-kit/scripts/run-log.mjs`) rejects log entries whose grader is the builder.

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
| The single bit `cross-check: clear` (the ONLY cross-check information the judge receives) | Cross-check findings (finding lists, severity counts, report contents, checker identity) |

Gate handled by orchestrator pre-filter: the orchestrator does not spawn a
judge on a red gate, so a red gate never reaches the judge as a grading
task. The single `gate: green` bit is the only exception, enforced by the
orchestrator — the judge never sees gate findings.

Cross-check clear is a PRECONDITION for grading, like gate green: the
orchestrator does not spawn a judge until the gate is green AND the
cross-check is clear, so a SEVERE-blocked build never reaches the judge as
a grading task. The single `cross-check: clear` bit is the only cross-check
information the judge receives — no findings, no severity counts, no report
text, no checker identity. The D8 whitelist is unchanged by this:
cross-check findings are forbidden judge inputs, exactly as gate findings
are.

**Not judge inputs.** The builder's step-3b self-check (P3 reworked form —
1 pass, post-gate, visual-P0-only, report-only) is never a judge input, and
never appears in the score table. A human annotated screenshot from the
human gate is a fix instruction to the builder (via the token dictionary
into the step-5 fix list, `references/human-gate-pack.md`), never a judge
input — the judge grades the rebuilt page fresh.

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
still stops at ≥4 on every axis AND gate green AND cross-check clear, or after 3 rounds.

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

An evidence line about UX also cites the UX checklist item by number
(`UX-<n>`, the criterion number in the UX expert brief,
`skills/frontend-kit/experts/ux.md`) as well as the reference — a UX
claim with no UX-N tag is invalid, same as a motion claim with no
pattern number.

UX evidence is cited under the axis the defect belongs to — the
per-defect axis. Layout-only is STRUCK: E3's own tells span Layout,
Space, and Type-adjacent defects (vanishing nav under Layout and dead
bands under Space in the probe judges' own reports; unreadable chart
labels at 390 under Type), so the axis follows the defect — no UX
evidence is cited under an axis the defect does not belong to. An
evidence line resting on a UX defect carries both the reference
citation and the UX-N tag.

HTML-dependent tags are confined to the expert paragraph: per-element
control checks and `display: none` rules are the expert's evidence,
not the judge's — the judge grades from the screenshots and cites the
UX-N tag for what the screenshots show.

Good: `Layout 3 — hero stacks vertically vs ref 2 (Aesop) hero, which holds
one full-viewport image; section rhythm breaks at 768px.`
Good: `Layout 4 — hero card expands to full-bleed over ~300px scroll vs ref 1 (scroll-motion Pattern 2); no second hero moment; sections hold one-per-screen.`
Good: `Layout 3 — nav section links vanish entirely at 768/390 with no hamburger (UX-6) vs ref 1.`
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
Cross-check: clear
```

**Motion (non-scoring):** if a motion expert was consulted this round, the
report adds one paragraph after the `Gate: green` and `Cross-check: clear` lines, surfacing the
expert's existing 1–5 domain score (`skills/frontend-kit/experts/motion.md`)
— `Motion: <score> (motion-expert) — <the expert's one-line evidence>`,
plus one line per named pattern used: `Pattern N: PASS/FAIL — <one line>`.
It never changes any axis score and never affects the stop rule. If no
motion expert was consulted this round, the paragraph is omitted — never
invent a motion score.

**UX (non-scoring):** if a UX expert was consulted this round, the report
adds one paragraph after the `Gate: green` and `Cross-check: clear` lines (after the Motion
paragraph when both are present), surfacing the expert's existing 1–5
domain score (`skills/frontend-kit/experts/ux.md`) — `UX: <score>
(ux-expert) — <the expert's one-line evidence>`, plus one line per FAILED
UX-N item only: `UX-N: FAIL — <one line>`. PASS items are omitted. It
never changes any axis score and never affects the stop rule. If no UX
expert was consulted this round, the paragraph is omitted — never invent
a UX score.

Example (brief 3 as it would have read — FAIL lines only):

```
Gate: green
UX: 1 (ux-expert) — Nav links vanish below 820px with no menu, and no project card links to its repo.
UX-1: FAIL — Zero github.com links; project cards carry no outbound link
UX-6: FAIL — Nav section links vanish at 768/390 with no hamburger
UX-10: FAIL — Project mocks end in bare $ prompts with no input
UX-13: FAIL — Fixed 320px mocks ~40% empty black below the last terminal line
```

**Comparability — broken by this change (E3 §3(c) as written is STRUCK):**
UX adds no fifth axis and changes no stop rule. The loop still stops at
≥4 on every axis AND gate green AND cross-check clear, or after 3 rounds per direction (max 2
re-picks, 9 rounds total). The 60% slop-free human-eye bar is unchanged.
The UX domain score is advisory to the judge, exactly as the Motion
domain score is: it surfaces defects for the fix order and never moves
an axis score. But E3 §3(c)'s claim that probe scores stay comparable
is false as written and is struck: the tells the probe judges missed
(brief 1 navigation vanishing below 820px; brief 2 "End of day"
restating Low stock — E3 T1 and T7) are deductions the judge did not
make, and the capped top-2 fix order means UX defects displace judge
defects in the fix list. Comparability is broken. Pre-UX and post-UX
rounds are not comparable. Probes must be re-baselined: the new baseline
is the first UX-graded round. The three probe scores (Type 4, Layout 3,
Colour 4, Space 3 on each of briefs 1–3) stand as pre-UX scores and must
not be compared against post-UX rounds.

## Fix order

Fix the top 2 across judge + experts (top 1 if the evidence is thin), as token
diffs first. A 3 that has a precise, cheap fix outranks a 2 whose fix is
vague — say which you picked and why in the run log.

Every fix instruction must cite a gate finding, a grader evidence line, or
a human instruction — never "improve it". A fix instruction with no
citation is not a fix instruction. A UX paragraph FAIL line is itself a
citable fix-order entry — a UX defect with no axis evidence line (e.g. UX-1,
the primary-task destination) enters the fix order by citing its
`UX-N: FAIL` line. The orchestrator's fix prompt must
require the citation field; a fix prompt without it is rejected by the
orchestrator.

**Re-expression rule (D11).** A judge fix that repeals a locked structural
rule is not sent to the builder as written. The orchestrator re-expresses
it as token diffs first (in the SR-2 case: fill the viewports by the SR-2
fill rule, `references/layout-doctrine.md` §4). If it cannot be
re-expressed within the applicable bound, it is not a fix: it is a
direction / escalation item for the human gate (P6(a) path), never a build
instruction.

**Token-semantics note.** `--space-section` is per-side section padding;
the inter-content gap is 2× the token. The token-consistent gap is 2× the
`--space-section` token (2×96px = 192px) — see `layout-doctrine.md` §4.
Measured gaps are compared against 2× the token, never against the token
itself.

## Pairwise keep/discard + defect-first (P11)

Every graded round outputs BOTH:

1. Absolute 1–5 per-axis scores with evidence lines (unchanged — P6's
   flat-line and stagnation triggers need the per-axis deltas, and the
   stop threshold needs them).
2. A pairwise keep/discard verdict vs the incumbent (new) — but ONLY when
   the trigger below holds.

**Trigger.** The pairwise verdict is sought ONLY on a round where the
build actually changed AND |Δ lowest axis vs incumbent| ≤ 1 — the
absolute-score change on the round's lowest axis, versus the incumbent's
score on that axis, is at most 1 point in either direction, so the
keep/discard decision is actually in doubt. A clear improvement or
regression is decided by the absolute scores alone. This bounds the
3-call cost to the rounds that matter. There is no "cheapest sharpness"
claim: a triggered round costs up to 3 judge calls (1 absolute + 2
pairwise, both orders — see the judge skill's pairwise procedure).

**What the verdict feeds.** The pairwise verdict feeds keep/discard ONLY,
never the stop threshold — a pairwise win has no floor (a version can
beat the incumbent on every comparison and still be unusable). The stop
threshold is decided by the absolute scores (≥4 on every axis AND gate
green AND cross-check clear — see `stop-rules.md`). A split pairwise
verdict (one order keeps the incumbent, the other keeps the challenger)
is a tie, and a tie keeps the incumbent.

**Defect-first format.** Locatable defects are listed BEFORE any number.
Evidence comes BEFORE the number in the score table (Evidence column
first, Score second — already the evidence rule above; P11 makes the
ordering load-bearing for the verdict). Each score cites a defect or
states "no defect found on this axis". A score without an
observable-evidence line does not count.

**Evidence honesty — analogy, not design evidence.** Two numbers are
sometimes cited for this mechanism. Both are labelled here as ANALOGY /
TRANSFER from other domains, NOT design evidence, and must never be
cited as support for design grading:

- CriticGPT 63% — human preference for CriticGPT's critiques over human
  critiques of CODE bugs. Code-bug critiques, not defect-first grading
  output.
- Remeli & Hardt Spearman >0.9 — ranking MODELS on QA accuracy. QA model
  ranking, not design-variant comparison.

P11 is justified as an experiment, not a supported fact: the loop's own
decision is comparative (keep round N or N−1?), so the loop answers it
comparatively and measures whether that helped.

**The experiment (first 3 builds).** The first 3 builds that use pairwise
record, per triggered round, whether the pairwise verdict and the
absolute-score keep/discard agreed. The run log carries this with the
`--pairwise` / `--pairwise-agrees` flags (added by the P6 worker —
`skills/frontend-kit/scripts/run-log.mjs` is not this file's to edit;
the flags are documented here for their use). If the verdicts disagree,
the pairwise verdict governs keep/discard and the disagreement is
reported in the run log. (Agreement measurement lives in the run log;
the shared calibration file `research/judge-calibration.md` does NOT
measure pairwise agreement — see its "What this pass does NOT measure"
section.)

**Precedence with P13.** When pairwise triggers, the round is a FULL-SHOT
round: full 1440 + full 390 shots of BOTH versions, order randomized.
P13's crops apply to the absolute grade only when no pairwise is
triggered. A round never gets both crops and a pairwise verdict.

**Sequencing (rounds 2–3): cheap grade first, full-shot re-take on
trigger (W-LOOP fix, 2026-11-11).** The trigger (|Δ lowest axis vs
incumbent| ≤ 1) can only be evaluated AFTER the cheap absolute grade
exists, so rounds 2–3 take the cheap absolute grade FIRST (390 full +
crops + tool checks). If the trigger fires, the pairwise triggers AND the
absolute grade is RE-TAKEN from full shots (full 1440 + full 390 of both
versions — the same full-shot set the pairwise uses): the cheap grade is
superseded for scoring purposes, and BOTH grades are recorded in the run
log (the cheap grade's record carries `superseded-by-full-shot` in its
notes; the full-shot grade is the round's standing grade for P6
flat-line detection and the stop rule). The pairwise verdict then decides
keep/discard against the full-shot absolute grade — never against the
superseded cheap grade. This follows council-A ("pairwise triggers →
full-shot round; crops apply only when no pairwise is triggered") and
council-C ("no crops on pairwise rounds"). Council-B's "both input sets
in one spawn" is explicitly NOT adopted: one spawn cannot carry both
input sets, because the trigger — which decides whether the full-shot
set is needed at all — cannot be computed before the cheap grade exists.

## Cheap-grade ladder (P13)

**Round 1: full 3-width grade.** Round 1 is graded from the full 1440 /
768 / 390 shots (plus the locked reference shots, every round — see the
cost table below).

**Rounds 2–3: cheap grade.** A round that gets a grade in rounds 2–3 is
graded from: the full 390 shot + crops of the changed sections only +
tool checks (Playwright snapshot / console / geometry). Tool checks come
FIRST, pixels second: a score contradicting a tool measurement is invalid
(e.g. Layout 5 while the snapshot shows horizontal overflow). The crop
helper is `skills/frontend-kit/scripts/crop-sections.mjs` (council-A's
name; council-B's `crop-helper.mjs` is the not-used alias).

**Fresh scores every round — carried scores are abolished.** Every graded
round re-judges the four per-axis integers FRESH from that round's inputs
(the 390 full-page shot + changed-section crops + tool checks). The cheap
grade sends fewer PIXELS, not fewer scores. The whole page IS freshly
observed every round at 390 (Variant B is a full-page 390 shot). A section
the round does not re-examine at pixel level at 1440/768 (unchanged since
an earlier round — its 390 rendering was still freshly observed that round)
is marked `not re-graded (unchanged since round N)` in the score table —
an explicit ABSENCE, never a score. The run log records such sections via
`--not-regraded "<#section,#section>"` on the round's record
(`skills/frontend-kit/scripts/run-log.mjs`); `--scores` always carries four
fresh integers or `none` — a `not re-measured` value in `--scores` is
rejected by the tool (W-LOOP fix, 2026-11-11: the rubric's old
"run-log value `not re-measured`" could not be executed as written).
P6 flat-line detection and the agreement log (P8, defined in
`references/decisions.md`) consume the four fresh integers only. The
stop round is always a full fresh grade — that rule lives in
`stop-rules.md` (cross-referenced here, not restated as a second rule).

**Precedence.** P5's classification runs first: a token-only fix gets
gate-only, no grade. P13's cheap grade applies ONLY to rounds that get a
grade (structural rounds 2–3). A round never gets both "no grade" and
"cheap grade". When P11's pairwise triggers, the round is a full-shot
round (see P11 above) — no crops that round; sequencing is P11's (cheap
grade first, full-shot re-take on trigger).

**Downscale rule.** Downscale ALL judge images to 1,568px long edge
BEFORE sending (host note for Claude Code: this avoids the high-res
tier). The downscale is a loop rule; model selection is not — the loop
cannot select a judge's model tier across hosts, so there is no
model-tier pin.

**"Changed sections" is mechanical.** The changed sections are
determined by the git diff of `design/tokens.css` + the HTML between
rounds (the crop helper parses that diff), cross-checked against the
builder's fix list. The builder's self-report is NEVER the determiner.
Note: P5's script classifier does not exist in this repo (verified on
disk — no classifier script in `skills/frontend-kit/scripts/` or
`scripts/gate/`); the diff is the determiner, not a classifier that is
assumed to exist.

**Cost.** See the cost table below (Variant B adopted — full-page 390).
The table was DERIVED until the W-LOOP exercise probe (2026-11-11) ran
the instrumented measurement; it is now corrected from those measured
numbers where the derived figures were outside ±25% (see the table's
per-row DERIVED / MEASURED labels). The probe ran TWICE (run-1, then a
rebuild as run-2 after the VM restart wiped /tmp — same probe build,
same lock, same 2 refs); every MEASURED figure below is labelled by
run, and where the runs differ both figures are given.

## Jury-of-3 on the stop round (P14)

**Convening.** The jury convenes ONLY on the round that would stop the
loop. 3 judges from disjoint model families, median per axis.
Independent votes + aggregation only — NEVER debate (ChatEval 34.00% on
JudgeBench, below chance). Jurors never see each other's votes; each
juror gets the D8-whitelisted inputs independently (same whitelist as
the single judge — screenshots + locked reference shots + rubric/scope +
lock text + tool measurements + the single `gate: green` bit; never
model/builder identity, earlier scores, run log, or gate findings). The
jury verdict governs the final-round stop.

**No stacking.** The jury REPLACES P6(e) median-of-3 on the stop round —
never both. Maximum 3 judge calls on a stop round.

**Disagreement.** A ≥2-point disagreement on any axis escalates to the
human gate with all three scores shown. In buffet mode the run parks in
"awaiting human".

**Fallback ladder (exact, in order).** (1) 3 judges from disjoint families
(median per axis). (2) If the host cannot provide 3 families, 3 fresh
contexts of the single available judge (median per axis), run-log label
`jury-degraded: single-family jury (median-of-3)`. (3) If the host cannot
spawn subagents, a single grade and the human gate carries the stop. A
degraded jury is labelled in the run log, never silent.

**Dependency — the calibration pass exists.** The P9/P14 shared
calibration pass EXISTS as an artefact: `research/judge-calibration.md`
— judge side complete 2026-11-10; human OVERALL grades 6/10 for all 3
builds landed 2026-11-11; human PER-AXIS grades still pending, so no
per-axis agreement rate and no per-axis overshoot can be computed yet.
The jury may convene (the pass exists); the jury's own agreement is
measured in that file once the jury has run. The 80% Layout/Space
agreement threshold is REPORT-ONLY below n≥30 paired scores (council
member A) / n≥32 (council member B) — both counts are recorded here
because the members disagree; until n≥32 treat the threshold as
report-only. No per-axis human score is ever invented to fill the
pending table.

**Numbers labelled.** PoLL "7× less expensive" is April-2024 TEXT-QA
pricing, never a projected saving. PoLL κ +0.136 is text-QA transfer,
unproven for vision design grading. The justification for the jury is
stop-decision sharpness, not cost.

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

Planning figures: DERIVED except where a row is labelled MEASURED — the
W-LOOP exercise probe (2026-11-11, one portfolio build, n=1 build × 2
runs; run-1 in `build-notes/w-loop-exercise/EXERCISE.md` §9, run-2 in
`EXERCISE-RUN2.md` §9) ran the instrumented measurement and this table is
re-issued from it. Replaces the synthesis table and the grading worker's
§2 table. **Variant B (full-page 390) is the adopted column** — 390 is
where defects hide. The ~2,500 figure is Variant A (390 viewport), not
Variant B; do not cite it as the Variant B cost.

**Formula (DERIVED, CLAIMED via convergent secondaries quoting Anthropic's
docs — NOT verified against Anthropic's official docs):** image tokens ≈
`min(width × height / 750, 1,568)` per image, standard tier (long edge
1,568px, cap ~1,568 tokens/image). **Formula input dimensions are SENT
dimensions** — width × height of the image as sent, after the loop's
downscale rules: full 3-width shots are downscaled to 1,568px long edge
before sending, per the Downscale rule (ALL judge images — the earlier
"sent as captured" reading was the error corrected below); locked refs are
downscaled to 720px long edge before sending; the cheap 390 full shot and
crops are downscaled to 1,568px long edge before sending. The old table
applied the formula to as-captured dims on the R2 390-full line (1,560)
while the cheap-grade rule downscales that shot first (97×1568 → 203) —
and on the R1 full-shot lines (4,704) while the Downscale rule downscales
those too. The R1 Variant B lines below are RE-DERIVED from the sensitivity
note's exacts (2,584.6 run-1 / 2,647.3 run-2 on a 2-ref basis, incl. 864
refs) — a derivation, not a fresh instrumented run: the probe sent
as-captured, so a re-measurement with downscaled sends is still owed (one
instrumented probe build). **Tier assumption, stated on every number below:
standard tier.** On a Claude 4.7+ high-res tier the same shots cost ~3×
per image (same PNG 1,578 → 4,744 tokens; same three full-page shots
~8,000–9,500). The enforceable defence is downscaling to 1,568px long
edge before sending, not a model pin.

| Images per round (standard tier) | Current loop | With P12+P13, Variant A (390 viewport) | With P12+P13, Variant B (390 full-page) |
|---|---|---|---|
| Round 1: build shots (1440 + 768 + 390 full-page) | ~4,700 DERIVED (1,568 + 1,568 + 1,560) | ~4,700 | Run-1 1,721 / run-2 1,783 RE-DERIVED (full shots downscaled to 1,568px long edge before sending; run-1 components 1,050 + 468 + 203, exact 1,720.6; run-2 exact 1,783.3, rounded components 1,050 + 510 + 224 sum to 1,784) |
| Round 1: reference shots (1–3 locked refs, 720px long edge) | 0 (the hole P12 fixes) | +~1,400 (3 refs × ~470) | +~1,400 (3 refs × ~470 DERIVED; MEASURED 432 per ref in both runs, −8%) |
| **Round 1 images total** | **~4,700** | **~6,100** | **Run-1 3,017 / run-2 3,079 RE-DERIVED (3-ref basis: build 1,721/1,783 + 1,296 refs at 432 each; 2-ref: 2,585 / 2,647)** |
| Rounds 2–3: build images | ~4,700 | ~1,100 (390 viewport 439 + crops 432 + 260) | Run-1 913 MEASURED (390 full 203 + 1 outermost crop 710; pre-dedupe 1,436 = 203 + 1,233) · run-2 836 MEASURED (390 full 224 + 1 crop 612; exact 835.2) |
| Rounds 2–3: reference shots | 0 | +~1,400 | +~1,400 (3 refs × ~470 DERIVED; MEASURED 432 each in both runs) |
| **Rounds 2–3 images total (each)** | **~4,700** | **~2,500 (E3's figure — viewport reading only)** | **Run-1 2,209 / run-2 2,132 MEASURED (3-ref basis: build + 1,296 refs at 432 each; 2-ref: 1,777 / 1,700)** |
| Images / build, 3 rounds | ~14,100 | ~11,100 (−21%) | Run-1 7,435 / run-2 7,343 RE-DERIVED (3-ref; −47.3% / −47.9% vs current 14,100) |
| Images / build, 2 rounds (typical, flat-line stop) | ~9,400 | ~8,600 (−9%) | Run-1 5,226 / run-2 5,211 RE-DERIVED (3-ref; −44.4% / −44.6% vs current 9,400) |

**Crops counting rule (MEASURED, W-LOOP fix 2026-11-11, confirmed in
run-2).** The old table assumed 2 crops (432 + 260 = 692). The exercise
probe's helper emitted 4 crops in run-1 (1,233 measured — exact 710.3 +
3×174.2 = 1,233.0 from 390×1366 and 3× 358×365 at /750; the rounded
components 710 + 174 + 174 + 174 sum to 1,232, so the total 1,233 is
correct from the exact values, not from the rounded ones) — the changed
section plus its 3 nested articles. The helper now emits only the
OUTERMOST changed section (`crop-sections.mjs` nested-change dedupe): 1
crop for the probe diff in both runs, `#projects` 390×1366 → 710 measured
in run-1 and 390×1176 → 612 measured in run-2 (exact 611.5). Counting
rule, stated explicitly: one crop per outermost changed section; a changed
section inside another changed section gets no separate crop and is
recorded in the crop manifest as `nested-under`. The R2 build lines above
(913 / 836) are the post-dedupe figures; the pre-dedupe run-1 measurement
was 1,436 (203 + 1,233). The Variant A column is NOT re-derived in this
correction: its 390-viewport line is unaffected by the sent-dims
definition (390×844 sits below the 1,568px long edge, so 439 stands
either way) and its crops line still carries the old 2-crop assumption —
the same outermost-only rule would apply to it; only the adopted
Variant B column is corrected here.

Reference shots cost **+~1,400 image tokens/round** for 3 downscaled refs
(range ~1,300–2,100 depending on aspect; 1 ref ≈ 470 DERIVED, 432
MEASURED in both runs). Table totals are labelled for 3 refs; the probe
locked 2 refs in both runs, so its measured round totals are 864 for refs
(R1 images 2,585 run-1 / 2,647 run-2 on the 2-ref basis, downscaled full
shots — the old as-captured 5,568 is superseded; R2 images run-1 pre-dedupe 2,300,
post-dedupe 1,777; run-2 1,700).

**Text context (MEASURED, replacing the old ~4k estimate — a range by
run, same lock type).** A fresh judge invocation also reloads the judge
skill, TASTE.md + DESIGN.md, `tokens.css`, the HTML, and the brief-type
scope — **~31–36k text tokens per judge call, measured in two runs**,
not ~4k as previously estimated (~8–9× low). Run-1: R2 35,784, R1
35,631. Run-2: R2 31,414, R1 30,573. Method (both runs): tiktoken 0.14.0,
`cl100k_base`, over the exact text files a judge call loads. Run-1
breakdown (R2): judge prompt 691; `frontend-judge/SKILL.md` 6,458;
`design/TASTE.md` 722; locked DESIGN.md (`vercel.md`) 11,068;
`design/tokens.css` 4,173; `index.html` (version B) 6,928; snapshots
(1440 + 390) 4,993; console + geometry 751. Run-2 breakdown (R2): judge
prompt 686; SKILL.md 6,464; TASTE.md 336; vercel.md 11,068; tokens.css
4,173; `index.html` (version B) 6,109; snapshots 1,182; console +
geometry 1,396. Why the runs differ: run-2's TASTE.md is shorter (336 vs
722 tokens) and its snapshots are compact structured dumps (1,182 vs
4,993 tokens). The locked DESIGN.md is the largest single input in both
runs — it is the repo's vendored 42KB third-party analysis, so both
figures are the expensive end for a lock built from that reference
material; a purpose-written DESIGN.md would be smaller. NOT counted:
`grader-rubric.md` (run-1 8,496, run-2 10,164 — its P11/P13/P14 sections
already live in the judge skill, so the judge does not receive it as a
separate input) and the crop manifest (run-1 1,527, run-2 1,214 — the
orchestrator's spawn list, not sent to the judge). Text is **~94–95% of
the measured round** in both runs (run-1: 35,784 of 38,084 pre-dedupe,
35,784 of 37,561 post-dedupe; run-2: 31,414 of 33,114), not ~50% as the
old caveat implied. The synthesis's "~30–40% worst case" and the worker's
own disagreeing figures ("~30–50%", "~10–30%") are retired; the single
stated figure is: **image-token saving on rounds 2–3 is −47% (Variant A,
not re-derived) / −53% to −55% (Variant B, total images 4,700 → 2,132–
2,209 on a 3-ref basis; −62% to −64% on a 2-ref basis, 4,700 → 1,700–
1,777); whole-round saving is ~0–12% (Variant B), measured run-1 5.9%
(pre-dedupe, 2-ref: current-loop round 40,484 = 4,700 images + 35,784
text; Variant B round 38,084 = 2,300 + 35,784) and 7.2% after the Fix-3
crop dedupe (37,561 = 1,777 + 35,784, 2 refs; 6.2% on a 3-ref basis,
37,993 = 2,209 + 35,784) and run-2 8.3% (2-ref: current-loop round
36,118 = 4,704 images + 31,414 text; Variant B round 33,114 = 1,700 +
31,414) and 7.1% (3-ref: 33,546 = 2,132 + 31,414, against the same
36,118 current-loop round, which sends no refs).** (Run-1's current-loop
figure uses the derived 4,700 images, run-2's the measured 4,704; the
4-token difference moves no saving by more than 0.1pp.) The largest
saving remains rounds not run (P6 flat-line stop) and judge calls not
made — not crops — and that conclusion is now STRONGER than stated:
with text at ~94–95% of a round, cropping pixels moves the total by
only a few percent.

**What this table still cannot correct from available evidence:** the
/750 formula itself (CLAIMED via secondaries, not Anthropic's official
docs); the high-res-tier multiplier for full-page shots; and the sample
itself — every MEASURED figure above is n=1 build × 2 runs (one probe
build, one lock from the vendored DESIGN.md, 2 locked refs), not a
multi-build average. Sensitivity note on the R1 line (retired as a
hypothetical — now the adopted reading): the table's basis WAS full shots
sent as captured (no downscale rule stated for them). The Downscale rule
(ALL judge images) now states it explicitly: full shots are downscaled to
1,568px before sending, and the R1 Variant B lines above are re-derived
from that reading — R1 total 2,585 in run-1 (exact 2,584.6; rounded
components 1,050 + 468 + 203 + 864) and 2,647 in run-2 (exact 2,647.3;
rounded components 1,050 + 510 + 224 + 864 sum to 2,648). Under the old
as-captured reading R1 measured would have been 4,704 build shots
(3 × 1,568 capped) and R1 total 5,568 (2-ref) / 6,000 (3-ref) — those
figures are superseded.
