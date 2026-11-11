# coord/BOARD.md — task board (coordinator-owned)

> **Owner: the coordinator (Muse) ONLY.** No other agent edits this file — ever.
> Other agents claim work by writing in their OWN `coord/<name>.md` file; the
> coordinator merges claims here on its next pass (every 30 minutes, or
> immediately after a slice completes).
> Protocol: `BUFFET-MODE.md` §5. Run log: `coord/run-log.jsonl` (append-only,
> coordinator-only — agents log in their own files; the coordinator transcribes.
> Never edit a line; supersede with a new record).
> **Board row schema:** `Slice | Owner | Status | Expected-min | Files | Notes`.
> `Expected-min` is the numeric effort estimate in minutes, written by the
> coordinator at dispatch (defaults S=60 / M=240 / L=480); it drives the §5
> lease. `Notes` links to `coord/tasks/<slice-id>.md` — one coordinator-written
> file per slice holding the six TASK_TEMPLATE fields.
> **Task states (binding):** every row carries one state —
> `submitted → working → completed / failed / canceled`, plus
> `input-required` for a slice blocked awaiting input (the coordinator
> resolves it or escalates it to the human; the Notes column names whose
> input is awaited), plus `declined` for a slice an agent refused
> (`DECLINED <slice-id> | reason: <one line>` in its own file — terminal for
> that agent, not for the slice; the coordinator may re-list it for another
> agent). **Ownership table (binding):** the file → agent → round table below
> is filled BEFORE dispatch; the coordinator deterministically rejects claims
> on owned files.

## Board fields

- **Mainline:** `buffet/main`
- **Deputy:** TBD by coordinator at run start (backup: TBD by coordinator at run start) — deputy and backup are named only from agents whose machines pass the §9 gate-tooling check (a deputy that cannot run the merged-tree gate cannot land anything, F29); the deputy must not be Mie.
- **coordinator-term:** 1
- **Flagged files:** — (none; the coordinator lists hot/shared files here when flagging them, F13 — a slice that touched a flagged file outside its ownership is refused landing)

## Run trigger

*(Empty until a run starts. At run start, before the humans leave, the
coordinator records here verbatim: the brief, the Figma link (or "none"),
the target (landing / dashboard / redesign), and the return time. If the
brief lives only in a human's message, the coordinator copies it verbatim
into this section. The brief-compliance checks judge against this section
and the slice task files — never against a human's message no agent can
re-read.)*

- **Brief:** —
- **Figma link:** —
- **Target:** —
- **Return time:** —

## Milestone slices — buffet mode (after the main push)

| Slice | Owner | Status | Expected-min | Files | Notes |
|---|---|---|---|---|---|
| B1 — Runbook `BUFFET-MODE.md` + `coord/` scaffold | Muse (W-BUFFET-2) | completed 2026-11-10 | n/a (completed) | `BUFFET-MODE.md`, `coord/` | Runbook v1 from design §5.3 verbatim + §7 addendum (6th role row, change-control rule). Personal info generalised; no closing-lessons section. Report: `build-notes/w-buffet-2.md` (outside the repo). |
| B2 — P20–P24 amendments | Wave-4 worker (separate) | completed 2026-11-10 | n/a (completed) | `BUFFET-MODE.md`, `coord/TASK_TEMPLATE.md`, `scripts/trial-merge.mjs` | P20–P24 amended into BUFFET-MODE.md (139 lines) + coord/TASK_TEMPLATE.md + scripts/trial-merge.mjs (verified: node --check + real merges). Coordinator-verified. Report: `build-notes/w-buffet.md` (outside the repo). [Historical note: §9 was undecided when B2 completed; decided 2026-11-11 — see §9 section below; B4 is no longer blocked.] |
| B3 — Figma converter + import scripts (`scripts/figma-tokens-to-css.mjs`, `scripts/figma-import.mjs`) | Unassigned | submitted | n/a (not dispatched) | `scripts/figma-tokens-to-css.mjs`, `scripts/figma-import.mjs` | Follow-up named in the v1 design (§5.5 item 4 in v1 numbering; Figma paths live in the v2 design §6). Until built, Figma paths A/B run as human-run procedures; do not claim the scripts exist. |
| B4 — Acceptance test: three-agent cold-clone test (Mie, Migga, Milo) | Unassigned | submitted | n/a (not dispatched) | — | §9 DECIDED 2026-11-11 (shared-repo branches primary, fork+PR fallback) — blocker resolved; ready to schedule. PASS/FAIL per `BUFFET-MODE.md` §9. (Was `input-required` on the §9 answer; B1 done.) |
| B5 — Scratch-HOME clone-and-go install check | Muse (W-BUFFET-2) | completed 2026-11-10 (clean rerun) | n/a (completed) | — | Clone of remote main + plain `./install.sh` exit 0, standalone `./verify.sh` exit 0, 0 failures. 1 warn-only drift (engine 0.1.21 pinned vs 0.1.22 latest); 2 pending: Impeccable hook for codex (npx failed twice, transient network) + Figma MCP (human OAuth, by design). First attempt on /tmp failed on disk-full (512M tmpfs) — environmental, not a kit defect. Caveat: clone predates the buffet files (uncommitted), so this verifies v2 clone-and-go only; new-session reload check not done — both remain for B4. Logs: `~/scratch-home-test/install.log`, `~/scratch-home-test/verify.log`. |
| B6 — Buffet-mode coordination v2 build (runbook + coord/ + trial-merge.mjs) | Muse (gen-10) | working | 240 | `BUFFET-MODE.md`, `coord/BOARD.md`, `coord/TASK_TEMPLATE.md`, `coord/tasks/TEMPLATE.md`, `coord/tasks/B6.md`, `coord/CROSSCHECK.md`, `coord/crosscheck/README.md`, `coord/muse.md`, `coord/milo.md`, `coord/mie.md`, `coord/migga.md`, `scripts/trial-merge.mjs` | Design: `research/coordination/buffet-mode-coordination-v2.md` (workspace research note, not shipped in this repo), approved 2026-11-11, built on branch `buffet-v2`. Task file: `coord/tasks/B6.md`. |

## Ownership (file → agent → round) — filled BEFORE dispatch (P20)

| File | Agent | Round |
|---|---|---|
| *(no rows yet — the coordinator fills this before dispatching the first slice; a claim on a file listed here is refused deterministically)* | — | — |

## §9 — GitHub push access for Mie / Migga / Milo (DECIDED 2026-11-11)

- **Decision: shared-repo branches = PRIMARY path.** All four humans grant
  write access to the one repo; agents work on shared branches
  `buffet/<name>`. Decided by Muse 2026-11-11 at 12:23 per the user's
  delegation ("ông thấy sao tốt nhất thì ông chọn"). The design (§10) reserved this decision to the user;
  the user delegated it to Muse on 2026-11-11 12:23, and the decision taken
  was shared-repo branches primary, fork+PR fallback. Recorded here and in
  `BUFFET-MODE.md` §9.
- **Fork + PR = FALLBACK.** If push access is denied for any agent, that agent
  works in its own fork and opens a PR; the coordinator remains the only
  merger and merges the PRs. Fork-specific rules (CI-approval check per merge
  pass via `gh pr checks` / `gh run list`; fork-aware claim arbiter — same
  coordinator-first-seen rule, PR creation time as tie-break) per
  `BUFFET-MODE.md` §5.
- **Run-start human step (both outcomes):** before the run, a human enables
  branch protection on the mainline (`buffet/main`) and puts the coordinator
  — and, on succession, the deputy acting as coordinator — on the
  bypass/allow-list (the only actors permitted to push to `buffet/main`).
  "Merge commits only" is a runbook convention (agents ignore any board
  write that is not a merge commit landing through the `BUFFET-MODE.md` §5
  procedure), not a protection setting — GitHub protection cannot
  distinguish a merge commit from any other commit. If a merge-commit push
  is rejected, the coordinator stops the pass, records the failure in the
  run log, and escalates to the human; it never force-pushes and never
  commits directly onto `buffet/main`.

## Open items (human decisions — NOT assumed)

- **Figma for Education status** (gates runbook path C): UNCONFIRMED — path C stays conditional.
- **`get_variable_defs` remote live test** (gates any README promise about MCP token-pull): NOT RUN.
- **`coord/` placement:** lives on the buffet branch for now; the coordinator decides at merge time whether it stays in the kit repo permanently. It must NOT land on main as empty scaffolding before the milestone is real.
- **Process-learning team `coord/` file:** created when the team exists (one file per agent, same rule as runbook §5). No file yet — the team has no agent name assigned.

## Carry-over

- Nothing carried over yet. When a slice is not finished, its carry-over is written here — nothing left as a silent open thread.
