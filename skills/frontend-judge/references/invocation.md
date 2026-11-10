# frontend-judge — invocation pattern (for the orchestrator)

How `frontend-kit` step 4 dispatches to this skill, and what counts as an
independent invocation. Read this before spawning the judge; a judge
spawned wrong is not a judge.

## The pattern (only correct form)

Spawn a **fresh sub-agent** (or a separate agent instance on hosts without
sub-agents) with:

1. **A fresh context.** The judge's context contains ONLY the inputs listed
   in `SKILL.md` ("What you grade") — the built page, `design/tokens.css`,
   `design/TASTE.md`, the chosen DESIGN.md file(s), the 1440/768/390
   screenshots, the gate result for this round, and the brief-type scope.
   It contains NOTHING else about the build: no builder transcript, no
   builder reasoning, no drafts, no earlier rounds' scores, no variant
   history, no run-log entries.
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
> screenshots `<project>/design/screenshots/{1440,768,390}.png`, gate
> result: <PASS + findings or FAIL + findings>, brief type: <landing |
> dashboard/app | redesign>. Return the score table in the skill's output
> format. Edit nothing. You have not seen this build before; if any of
> these inputs is missing, say so instead of grading around it.

## Fallback order (first available wins)

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
   self-grade and is FORBIDDEN.
4. **No grade.** If none of 1–3 is available, there is no grade: the
   round's grade is exactly "gate green, vision not available" and the
   HUMAN gate carries the full taste judgement. Never fake a 4/5, never
   present the gate result as a design grade.

## Brief-type scope (pass one, exactly)

Pass the brief type to the judge so it applies the right Layout rule:

| Brief type | Layout rule the judge applies |
|---|---|
| `landing` | One section per screen; landing rhythm. |
| `dashboard/app` | One-section-per-screen does NOT apply. Dense multi-panel layout expected; judge panel alignment, scan order, density vs legibility. |
| `redesign` | The Layout rule of the page being redesigned (landing rule / dashboard rule), plus: existing content and links survive. |

The full scoping table lives in `frontend-kit` step 3 /
`references/workflow.md` step 3; this table is the judge-facing summary.

## What the judge never receives

- The builder's transcript, reasoning, or plan.
- Earlier rounds' score tables or the builder's own scores.
- Unpicked variants (they are direction alternatives, not evidence).
- The run log (it contains earlier grades — showing it to the judge
  anchors the new grade).

## Recording the grade

After the judge returns, the orchestrator records the round with
`skills/frontend-kit/scripts/run-log.mjs record` — scores, grader label
(`judge-subagent` / `muse-manager` / `other-model`), and the independence
basis. The basis must state BOTH halves (fresh context AND no production
history); the script rejects a basis that states only one. The run log is
the memory that stops rejected directions from being re-proposed.
