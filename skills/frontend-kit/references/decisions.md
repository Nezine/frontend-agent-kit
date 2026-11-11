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
