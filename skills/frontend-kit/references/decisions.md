# Council decisions D1–D8 (workflow-optimization, reconciled 2026-11-10)

Source: `research/workflow-optimization/SYNTHESIS.md` §8/§8a (workspace research
note, not shipped in this repo). A proposal is INTEGRATE only on unanimous or
2–1 council agreement with the dissent recorded. These eight decisions are the
reconciled cross-proposal rulings; the P1–P24 / M1–M5 verdict table lives in
that synthesis §8. Where a decision below disagrees with the phase-1 synthesis,
the decision governs.

## D1 — Escalate after the FIRST non-improving round

Unanimous; B's form: one re-grade confirms — the second grade, not a second
round, is the confirmation. Rule (d) and the mid-loop human-escalation sentence
deleted. Flat-line needs a gate-progress exception as noise guard (A). P6(a) is
a direction re-pick until P10 revives (B). Operative form: `references/stop-rules.md`,
`references/grader-rubric.md` (P6).

## D2 — Weaken the variant contract

A+C majority; B dissents, conditions attached (see P10 in the synthesis §8).
New wording: "same content, same copy, same section inventory — structure may
differ; tokens stay locked"; picker `check` becomes inventory + copy; auto-pick
ties break by the plan's preferred structure. Operative form:
`skills/frontend-kit/scripts/variant-picker.mjs`, `references/variant-briefs.md`.

## D3 — Runbook `coord/` scheme wins

Unanimous; no `board/`, no `STATE.md`. P22 contributes only the status column +
append-only rule. Operative form: `coord/BOARD.md`, `BUFFET-MODE.md`.

## D4 — Never rebase someone else's branch

Unanimous; "rebase the rest" deleted; `buffet/<name>` kept; trial merges
overlap-gated; neutral merger = fresh-context agent, not the coordinator (C).
Operative form: `BUFFET-MODE.md` §5, `scripts/trial-merge.mjs`.

## D5 — No second liveness cadence

Unanimous; heartbeat folds into the existing 15-min pull / 30-min merge — one
last-seen line in the agent's own `coord/<name>.md`, no extra commits.

## D6 — P16 struck as written; revival PARKED

Unanimous on the kill of P16 (reverse export) as written. Reworked version
PARKED pending ALL conditions: Education status confirmed, explicit type map,
full-copy themes for export, fonts first-name-only labelled lossy, Starter
single-file import test passes. C's acceptance of the reworked version is the
minority; the stricter condition (test first) governs.

## D7 — Split P3 (annotation INTEGRATE; self-check reworked only)

Unanimous. **Annotation INTEGRATE** — the human's annotated screenshot is a
first-class fix input at the human gate (see `references/human-gate-pack.md`).
**Self-check INTEGRATE WITH CHANGES in the reworked form only: 1 pass,
post-gate, visual-P0-only, report-only.** B killed the self-check *as written*
(unbounded, judgement-based) — the reworked mechanical form satisfies B's
objection. Operative form: `SKILL.md` step 3b, `references/workflow.md` §6,
`references/grader-rubric.md`, `references/human-gate-pack.md`. The self-check
is NEVER a grade, NEVER changes a score, NEVER triggers the stop rule, NEVER
substitutes for the independent grade, and is NEVER a judge input (D8).

## D8 — Reconciled judge-input whitelist

Unanimous in substance. **Allowed:** screenshots + locked reference shots +
rubric/scope + lock text + tool measurements + pairwise A/B inputs.
**Forbidden:** model/builder identity, earlier scores, run log, gate findings.
Gate handled by orchestrator pre-filter: the gate result itself is NOT a judge
input; B's single `gate: green` bit is the only exception, enforced by the
orchestrator. The cross-check reaches the judge the same way, as the single bit
`cross-check: clear` (step 3a). The 80% Layout/Space agreement threshold was
recorded with an A/B disagreement (n≥30 vs n≥32); the rubric resolves it to
**n≥32, report-only until n≥32** (`references/grader-rubric.md`); systematic
overshoot ≥1.0pt on any axis triggers an immediate rubric-anchor rewrite (B).
Buffet mode never parks on low agreement (A). Operative form:
`references/grader-rubric.md`, `skills/frontend-judge/SKILL.md`.

## The "agreement log" (P8)

P8's "agreement log" is not a separate file. It is the per-round record of
(gate verdict, judge scores, human verdict) kept in the run log
(`skills/frontend-kit/scripts/run-log.mjs`, `record` command) plus the
human-gate packet (`references/human-gate-pack.md`); agreement is computed
from those records in `research/judge-calibration.md`. "P8's gate-growth rule"
in `references/anti-cliche.md` is a different thing — the rule that the gate
grows only from observed failures — and is not labelled P8 there.

## D11 — Judge fix drops `100vh`: resolve by minimal token-sum internal growth (candidate-B pattern), never by restoring `100vh` or exempting SR-2

Council (2–1, dissent recorded in `build-notes/sr2-council/decision.md` §5; SR-2 vs judge fix 1, 2026-11-11). **Option (1) — adopt candidate B as-built as the next build / build of record, and its pattern as the standing resolution.**

**Rule.** When a judge fix drops the `100vh` rule on `.section` and SR-2 then fails on short sections, the builder resolves it by growing *internal* spacing by minimal token sums until each section's content reaches the one-screen content window (708px at 1440 with 96px pads), keeping non-hero section pads uniform at `--space-section` and non-hero inter-section gaps uniform at 2× `--space-section`. (The hero is governed by SR-1, not SR-2: in the R3 build the hero keeps 64px pads under the D1 deviation and the hero→about gap is 222px, not 192px.) Restoring `100vh` is forbidden (it undoes the judge fix). A content-height exemption to SR-2 is forbidden. Per-section bottom pads (candidate A) are a fallback only, when a section has no internal spacing that can grow, and must be declared as such in the round record.

**Bound.** Total shortfall **|S| ≤ 72px** (the doctrine's own add/cut number, `layout-v4.md` §2: "add or cut up to 72px"). The bound governs when the B-pattern applies: a shortfall within it (content in the 495–708px window) is filled by the pattern; a shortfall outside it, or content under 495px, is not stretched in a fix round. **All remedies split by who may apply them, whatever the content band:** **fix-round remedies** (builder, D2-compliant — same content, same copy, same section inventory): the B-pattern itself, the candidate-A fallback, `.g2` (structural, inventory unchanged), shrinking internal spacing by token sums. **Direction remedies** (human gate, re-pick — they change content, copy, or inventory): merge, add a picture/content, cut copy, split into two sections. If no remedy in either class fits, escalate — never stretch.

**Minimal-sum rule.** The growth or cut is the token sum landing the section's content closest to 708px, inside the 706–710px band where a token sum reaches it (height 898–902px, i.e. 900px ± SR-2's 2px tolerance); ties prefer the smaller sum. In the ordinary case that is the smallest sum of `--space-*` token values ≥ S for a shortfall, and the smallest sum cutting to the band for an overshoot — a single token step alone is not the rule (e.g. an overshoot of 28px cut by a single 32px step lands at 896px, WARN, where the sum 28 lands exactly at 900px). A single growable gap is grown by the minimal-sum rule like any other — the worked instance grows projects' single row-gap by +68. The builder records, per section, the shortfall, the token sum, and whether the result is exact or passes by SR-2's 2px tolerance — a tolerance pass (e.g. 901px) must be declared, never silent. **Margin collapse:** adjacent-sibling vertical margins collapse to their max, not their sum — when distributing growth across margins, count the collapsed value, not the sum of the two margins. Prefer row-gap (which does not collapse); the gate verifies the result.

**Contingent cap (not a binding bound).** No per-gap cap applies now. IF a full-shot grade penalises a B-pattern build's internal spacing (the trigger in member A's §6), the pattern gains a per-gap cap — the recorded candidate is B's 32px (= one `--space-6`) per gap per round, with shortfalls spread across two or more internal gaps — and this verdict is revisited with that grading evidence in hand. If a cap ever applies, a single growable gap that cannot reach the height within the cap falls back to candidate A for the remainder, or escalates.

**Re-expression rule (supporting change).** A judge fix that repeals a locked structural rule is not sent to the builder as written. The orchestrator re-expresses it as token diffs first (in the SR-2 case: fill the viewports by the SR-2 fill rule). If it cannot be re-expressed within the applicable bound, it is not a fix: it is a direction / escalation item for the human gate (P6(a) path), never a build instruction.

**Token-semantics note.** `--space-section` is per-side section padding; the inter-content gap is 2 × `--space-section` (192px at 96px pads). Measured gaps are compared against 2 × the token, never against the token itself. (Already stated in `layout-doctrine.md` §4; the rubric points at it — the judge's 96px comparison in the R2 fix order mis-read the lock.)

**Worked instance (probe run-2, R3 → candidate B as-built, gate GREEN 0 FAIL 15 WARN — verified, not predicted):** about panel margin 24 → 52 (+28 = 16+12); projects grid row-gap 16 → 84 (+68 = 64+4); tools panel margin 32 → 28 (−4). Contents 708/709/708, heights 900/901/900 — **the 901px projects height is a DECLARED tolerance pass under SR-2's 2px tolerance** (shortfall 67px has no exact token sum; the smallest sum ≥ 67 is 68). **Caveat, recorded not hidden:** the 84px projects row-gap (against a 16px column gap) is a gate-blind cost — the gate measures section heights and inter-section gaps, not internal-gap proportionality. The next full-shot grade is the check on it (see the contingent cap above).

**Operative form.** `references/layout-doctrine.md` §4 (SR-2 fill rule), `references/grader-rubric.md` (Fix order: re-expression rule + 2× note), `SKILL.md` step 5 (pointer), `scripts/gate/consistency.mjs` (section-height / section-tile / SR-2 T-height fix hints name D11 — guidance only, the check is unchanged). Consistent with D2 (tokens stay locked — B composes locked values, changes none).

**Scope.** Candidate B is gate-verified only; it has never been vision-graded, and this decision does not predict the next Space/Layout grade. The 96px gap-vs-padding ambiguity in the judge's wording is resolved by the token-semantics note above.
