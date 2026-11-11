# coord/crosscheck/ — cross-check reports

> **Coordinator-owned directory.** The cross-check agent writes here as the
> coordinator's subagent (summoned by the coordinator on its own machine).
> No other agent writes here. Reports are never edited after they are filed;
> a re-check produces a new report with an incremented `<n>`.

## Report filename pattern

`coord/crosscheck/<slice-id>-<n>.md` — one report per check, where
`<slice-id>` is the board slice (e.g. `B6`) and `<n>` is a counter starting
at 1, incremented per re-check of the same slice (a fresh cross-check run
after a fix writes `<slice-id>-2.md`, then `-3.md`, and so on). The pre-ship
report covers the shipping version, which has no slice id — it is filed as
`coord/crosscheck/ship-<n>.md` (same counter, incremented per re-check of
the shipping version).

## What a report carries

Every finding carries **severity** (SEVERE / WARNING / OK) **+ evidence**:
file:line, what, why, and a suggested fix. A report with no findings states
OK explicitly — silence is not a clear verdict. The coordinator transcribes
the verdict (SEVERE count, WARNING count, OK) into the run log before
landing; the pre-ship report is attached to the human-gate packet.

Checklist: `coord/CROSSCHECK.md` (seed only — NOT YET BINDING; the full
checklist is pending the gen-11 build from the delivered security-AI swarm
synthesis and red-team verification).
