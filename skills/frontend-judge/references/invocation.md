# frontend-judge — invocation pattern (for the orchestrator)

How `frontend-kit` step 4 dispatches to this skill, and what counts as an
independent invocation. Read this before spawning the judge; a judge
spawned wrong is not a judge.

## Step 0 — prepare the judge report file (D15, orchestrator duty)

BEFORE spawning the judge, run:

```
node skills/frontend-kit/scripts/judge-report.mjs --project <dir> prepare \
  --round N --kind absolute --grader <label> \
  --brief-type <landing|dashboard/app|redesign> --mode <full|cheap> \
  --page <built.html>
```

`prepare` stamps a skeleton at `design/judge/round-<n>.md` with the
sha256 of the page, `design/tokens.css`, and the round's screenshots,
and derives the `gate: green` / `cross-check: clear` header bits from
the project's own gate-leg artifacts + run log — it REFUSES (exit 2,
no file) when it cannot verify them, so a skeleton's existence is
itself evidence the pre-filter ran. It never overwrites an existing
report. One file per judge call: `--kind pairwise --index <1|2>`,
`--kind jury --index <1|2|3> --family <name>`, `--kind regrade`
(feedback re-grades), `--kind expert-motion` / `expert-ux` (expert
second opinions). The judge fills the skeleton in the file itself;
the run-log record then transcribes the file (see "Recording the
grade"). **The orchestrator never writes or edits the report file** —
transcribing a chat reply into the file is forbidden, because a
transcription is indistinguishable from a fabrication.

## The pattern (only correct form)

Spawn a **fresh sub-agent** (or a separate agent instance on hosts without
sub-agents) with:

1. **A fresh context.** The judge's context contains ONLY the D8-whitelisted
   inputs listed in `SKILL.md` ("What you grade") — the built page,
   `design/tokens.css`, `design/TASTE.md`, the chosen DESIGN.md file(s),
   the 1440/768/390 screenshots, the 1–3 locked reference screenshots
   (downscaled to 720px long edge, every round), the single bit
   `gate: green`, the single bit `cross-check: clear`, tool measurements where provided, and the brief-type
   scope. It contains NOTHING else about the build: no builder transcript,
   no builder reasoning, no drafts, no earlier rounds' scores, no variant
   history, no run-log entries, no gate findings, no cross-check findings, no builder / model
   identity.
2. **The judge skill, by name.** The spawn instruction names
   `frontend-judge` explicitly and tells the sub-agent to read
   `skills/frontend-judge/SKILL.md` and follow it. Do not paste a summary
   of the rubric into the spawn message — the skill file is the rubric.
3. **No production history.** The judge instance has never built, edited,
   or reviewed any part of this page before. A judge that graded round 1
   must not grade round 2 of the same build: spawn a new one per round.
4. **No shared context with the builder.** The judge is not the builder
   instance, not a continuation of the builder thread, and not a "fresh
   pass" inside the build thread. Same instance, new message, is NOT a
   fresh sub-agent.

Example spawn instruction (adapt the paths; keep the constraints verbatim):

> You are a fresh sub-agent with no history of this build. Read
> `skills/frontend-judge/SKILL.md` and follow it exactly. Grade this round
> only. Inputs: page `<project>/index.html`, tokens
> `<project>/design/tokens.css`, taste `<project>/design/TASTE.md`,
> reference `<project>/design/references/DESIGN.md/<brand>.md`,
> locked reference shots (from the taste lock, downscaled to 720px long
> edge): ref 1 `<project>/design/references/<ref1>.png`, ref 2
> `<project>/design/references/<ref2>.png` (1–3 refs, as the lock names),
> screenshots `<project>/design/screenshots/{1440,768,390}.png`, gate:
> green, cross-check: clear, brief type: <landing | dashboard/app | redesign>.
> Your judge report file is `<project>/design/judge/round-<n>.md`,
> already prepared: fill its `basis:` line, the four evidence cells,
> the four score cells and the Fix order IN THE FILE, and return the
> same body as your reply. Evidence first, every evidence line citing
> its reference image; evidence cells contain no `|` and no newline.
> Edit nothing else. You have not seen this
> build before; if any of these inputs is missing, say so instead of
> grading around it.

## Gate pre-filter (orchestrator duty, D8)

The gate is handled by orchestrator pre-filter, not by the judge. Do NOT
spawn a judge on a red gate: run the gate first, and only spawn the judge
when the gate is green. The judge never receives gate findings — no
findings list, no `detect` output, no gate-scripts output. The only gate
information the judge receives is the single bit `gate: green`, and the
orchestrator enforces that. If the gate is red, there is no grade: fix the
gate first. (The judge skill's former red-gate rule lived in the judge;
under D8 it is this pre-filter duty instead.)

## Fallback order (first available wins)

**Write-access requirement (D15, applies to every rung):** the grader
must be able to WRITE its judge report file in the project. A grader
that can only chat — including the Muse app (chat) and any paste-packet
route — cannot grade under D15, however independent it is: its scores
could only reach the record through the orchestrator's transcription,
which is forbidden. Such a grader is "not available" for this order.

1. **Fresh judge sub-agent** (`frontend-judge`, as above) — the default.
2. **`other-model` judge** — a different agent/model from the builder,
   invoked with the same inputs and the same fresh-context / no-history
   constraints. Label `other-model`.
3. **`muse-manager` judge** — Muse grading directly, as a DIFFERENT agent
   instance from the builder with no production history of this build.
   Label `muse-manager`. Valid under the coordinator decision recorded in
   the repo `AGENTS.md` (2026-11-10): the user's standing rule authorises
   Muse grading; what is forbidden is the SAME agent instance/context
   grading its own work. A `muse-manager` invocation that shares the
   builder's context or history is NOT this fallback — it is a builder
   self-grade and is FORBIDDEN. (Its independence remains
   attestation-based — a stated D15 residual.)
4. **No grade.** If none of 1–3 is available, there is no grade: the
   round's grade is exactly "gate green, vision not available" and the
   HUMAN gate carries the full taste judgement. Never fake a 4/5, never
   present the gate result as a design grade. There is no builder-graded
   fallback: no degraded rung, no ladder step, in which the builder grades
   its own work — the run-log script rejects builder-graded entries
   (exit 2, nothing written).

## Brief-type scope (pass one, exactly)

Pass the brief type to the judge so it applies the right Layout rule:

| Brief type | Layout rule the judge applies |
|---|---|
| `landing` | One section per screen; landing rhythm. |
| `dashboard/app` | One-section-per-screen does NOT apply. Dense multi-panel layout expected; judge panel alignment, scan order, density vs legibility. |
| `redesign` | The Layout rule of the page being redesigned (landing rule / dashboard rule), plus: existing content and links survive. |

The full scoping table lives in `frontend-kit` step 3 /
`references/workflow.md` step 3; this table is the judge-facing summary.

## What the judge never receives (D8 forbidden inputs)

- The builder's transcript, reasoning, or plan.
- Earlier rounds' score tables or the builder's own scores.
- Unpicked variants (they are direction alternatives, not evidence).
- The run log (it contains earlier grades — showing it to the judge
  anchors the new grade).
- Gate findings (findings lists, `detect` output, gate-scripts output).
  The judge receives only the single bit `gate: green`.
- Cross-check findings (finding lists, severity counts, report contents,
  checker identity). The judge receives only the single bit
  `cross-check: clear` — a SEVERE-blocked build never reaches the judge,
  because the orchestrator spawns a judge only when the gate is green
  AND the cross-check is clear.
- The builder's or the model's identity (who built the page, which model).

## Recording the grade

After the judge has filled its report file, the orchestrator records
the round with `skills/frontend-kit/scripts/run-log.mjs record`,
citing the artifact: `--judge-report design/judge/round-<n>.md`. The
record is a **transcription, verified by the script**: the flags'
scores, grader label (`judge-subagent` / `muse-manager` /
`other-model`) and independence basis must equal the artifact's, the
recorded evidence is DERIVED from the artifact's evidence cells
(`--evidence` is not accepted on a graded record), and the artifact's
hashes must still match the page / tokens / screenshots on disk. The
basis must state BOTH halves (fresh context AND no production
history); the script rejects a basis that states only one. A report
backs exactly one grade event — re-citing it is refused. The same
rule covers every score in the log: pairwise verdicts cite
`--pairwise-reports` (two files), jury votes cite `--judge-reports`
(three files), expert scores cite their `--expert-*-report`, and a
feedback `--score-after` cites a `--kind regrade` artifact. The run
log is the memory that stops rejected directions from being
re-proposed.

## Calibration (P9 + P14 — one shared pass, E8)

The judge is calibrated against the human once, on the 3 clean-env probe
builds (`tests/clean-env/probe-briefs.md`) — one shared pass for P9 and
P14, not two. The human grades the same 3 builds blind on the same 4
axes; the judge grades them blind with the D8 inputs above, including the
locked reference shots (the calibration measures the judge as it will
actually run). 3 builds × 4 axes = 12 paired scores. Results live in
`research/judge-calibration.md` (per-axis exact/within-1 rates, mean
signed overshoot; the decision rule is in `grader-rubric.md`
§ "Calibration").
