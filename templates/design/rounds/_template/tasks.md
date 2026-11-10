# Round <n> — tasks

<!-- The top-2 list (top 1 if the evidence is thin). Each task cites its
source — a gate finding, a grader evidence line, or a human
instruction. A task with no citation is not a task: the orchestrator
rejects the fix prompt that carries it. -->

## Tasks

- [ ] 1. [Fix, e.g. "Tighten the section gap token so hero/projects
  passes the 288px dead-band ceiling"] — source: [gate finding /
  grader evidence line / human instruction, quoted]
- [ ] 2. [Fix] — source: [quoted]

## Done when

- [ ] The re-run gate is green (both legs, same build).
- [ ] `converge-check.mjs` is green against the round's output.
- [ ] The re-grade is recorded in the run log with its grader label.
- [ ] `delta.md` is filled in from the actual diff.
