# Converge checklist — step 3 (script) + step 4 (judge) + step 6 (human gate)

The converge check answers one question: does the build contain every
section and every state the plan promised? A build can score 4/4/4/4
while silently dropping a planned section; scores cannot catch that
class of failure. This checklist is the human-readable half of the
check; the script half is `scripts/gate/converge-check.mjs`.

## The blocking rule (non-negotiable)

The converge check BLOCKS. It is a gate, not advice:

- **Script half, step 3:** `converge-check.mjs` runs inside `gate.sh`
  leg 1 whenever `design/PLAN.md` exists. A failure exits the gate
  non-zero: no grade is spawned on a build that dropped a planned
  section or state. There is no advisory mode and no OpenSpec-style
  escape hatch (OpenSpec's own docs say its verify "won't block
  archive" — this check does block).
- **Judge half, step 4:** the judge verifies every applicable matrix
  cell has a frame / story / preview AND that the state looks right.
  A missing state is a scored Layout defect, not a gate FAIL — but a
  Layout defect that keeps the build under 4 on that axis blocks the
  stop the same way: the build cannot be presented as done.
- **Step 6:** the human gate is not presented until the converge
  check is green. A red converge sends the round back to step 5; it
  never goes to the human as "mostly done".

When Node is unavailable the script cannot run: run this checklist by
hand instead, record the result in the run log, and label the run
with the degradation (see `stop-rules.md`). A hand-checked converge
is a degradation, not a skip — the human gate still does not open on
an unchecked plan.

## Script half (run it — do not eyeball it)

```
node scripts/gate/converge-check.mjs --plan design/PLAN.md --page index.html
```

- [ ] Every id in PLAN.md `## Section inventory` exists as an
  `id="..."` in the built HTML. (Sections are listed by content, not
  order — reordering never fails convergence.)
- [ ] Every non-N/A cell of PLAN.md `## Screen × state matrix` names
  a file that exists or an `#id` that exists in the HTML.
- [ ] Every matrix row names a section that exists in the inventory
  (the plan must be self-consistent).
- [ ] The script's UNCHECKABLE lines are copied here, not dropped:
  each one is "grader's call" in step 4 — never silently passed.

## Judge half (step 4 — the script cannot do this)

- [ ] For every applicable matrix cell, the state does not just
  exist — it looks right at 1440 / 768 / 390 (loading reads as
  loading, empty reads as empty, error reads as an error).
- [ ] No planned state was "evidenced" by a placeholder that says
  nothing (an empty frame is not a state).
- [ ] No section in the inventory is present but empty (an id with
  no content is a dropped section wearing its name).

## DESIGN-SYSTEM.md no-values check (reviewer, QC pass)

- [ ] `grep -E '^\s*--[a-zA-Z]' design/DESIGN-SYSTEM.md` prints
  nothing. A match means a token value leaked into the rationale-only
  file — move the value to `tokens.css` and leave the rationale here.
  (No script enforces this in v1; this checklist line is the
  enforcement.)

## Human-gate pack line

When the converge check is green, the human-gate pack states it in
one line: "Converge: green — N sections present, M states evidenced,
K uncheckable (judge's call, step 4)". When it is red, there is no
human gate: the round goes back to step 5 with the failing section
or state named.
