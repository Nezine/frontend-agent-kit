# design/rounds/ — fix-round folders (OpenSpec change-folder shape)

<!-- This folder holds one subfolder per fix round: design/rounds/<n>/.
Copy _template/ to <n>/ at the start of the round (round 1 is the
first fix round after the first grade; the initial build is not a
round). The shape is adapted from OpenSpec (Fission AI, MIT; README
read in full 2026-11-10): a change folder with a proposal, a delta,
and tasks — reviewable and archivable, instead of a free-form log
line. One difference from OpenSpec is deliberate and binding: where
OpenSpec's verify "won't block archive", this loop's converge check
DOES block — no archive without converge-green, and no human gate
on a red converge. -->

## Shape

```
design/rounds/<n>/
  proposal.md   — what this round fixes + why (bugfix-spec shape:
                  current behaviour / expected behaviour / unchanged
                  behaviour — the third line is the one the loop used
                  to lack: a fix round must not regress what was fine)
  delta.md      — the token diffs, ADDED / MODIFIED / REMOVED
  tasks.md      — the top-2 list (top 1 if the evidence is thin),
                  each task citing its source
```

## Rules

- A round starts by writing `proposal.md` (the fix is proposed before
  it is made — the proposal is what the reviewer reads, not the diff).
- Every fix instruction cites its source — a gate finding, a grader
  evidence line, or a human instruction — never "improve it". A fix
  prompt without a citation is rejected by the orchestrator, not sent.
- Fixes go to `tokens.css` first; HTML / layout only if the gate still
  fails after the token change.
- After the round, the archive step merges the delta into PLAN.md
  § Amendments, into the token dictionary, and into the run log's
  notes — NEVER into TASTE.md or `tokens.css` mid-loop. The lock is
  immutable within a direction. A lessons merge into TASTE.md happens
  only once, after the human gate approves the build.
- The round folder is the unit the converge check re-verifies: the
  re-run gate + `converge-check.mjs` run against the round's output
  before any re-grade.
