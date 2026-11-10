# coord/BOARD.md — task board (coordinator-owned)

> **Owner: the coordinator (Muse) ONLY.** No other agent edits this file — ever.
> Other agents claim work by writing `CLAIM <slice-id>` + timestamp in their OWN
> `coord/<name>.md` file; the coordinator merges claims here on its next pass
> (every 30 minutes, or immediately after a slice completes).
> Protocol: `BUFFET-MODE.md` §5. Run log: `coord/run-log.jsonl` (append-only).

## Milestone slices — buffet mode (after the main push)

| Slice | Owner | Status | Notes |
|---|---|---|---|
| B1 — Runbook `BUFFET-MODE.md` + `coord/` scaffold | Muse (W-BUFFET-2) | DONE 2026-11-10 | Runbook v1 from design §5.3 verbatim + §7 addendum (6th role row, change-control rule). Personal info generalised; no closing-lessons section. Report: `build-notes/w-buffet-2.md` (outside the repo). |
| B2 — P20–P24 amendments | Wave-4 worker (separate) | OPEN | NOT part of W-BUFFET-2. Do not start until assigned here. |
| B3 — Figma converter + import scripts (`scripts/figma-tokens-to-css.mjs`, `scripts/figma-import.mjs`) | Unassigned | OPEN | Design §5.5 item 4 — named follow-up. Until built, Figma paths A/B run as human-run procedures; do not claim the scripts exist. |
| B4 — Acceptance test: three-agent cold-clone test (Mie, Migga, Milo) | Unassigned | BLOCKED | Blocked on: push-access answer (§9 blank below) + B1 done. PASS/FAIL per `BUFFET-MODE.md` §9. |
| B5 — Scratch-HOME clone-and-go install check | Muse (W-BUFFET-2) | PASSED 2026-11-10 (clean rerun) | Clone of remote main + plain `./install.sh` exit 0, standalone `./verify.sh` exit 0, 0 failures. 1 warn-only drift (engine 0.1.21 pinned vs 0.1.22 latest); 2 pending: Impeccable hook for codex (npx failed twice, transient network) + Figma MCP (human OAuth, by design). First attempt on /tmp failed on disk-full (512M tmpfs) — environmental, not a kit defect. Caveat: clone predates the buffet files (uncommitted), so this verifies v2 clone-and-go only; new-session reload check not done — both remain for B4. Logs: `~/scratch-home-test/install.log`, `~/scratch-home-test/verify.log`. |

## Open items (human decisions — NOT assumed)

- **§9 blank — GitHub push access for Mie / Migga / Milo:** ______________________ (coordinator records the answer here before test B4 runs; fork + PR fallback per `BUFFET-MODE.md` §5 if no push access).
- **Figma for Education status** (gates runbook path C): UNCONFIRMED — path C stays conditional.
- **`get_variable_defs` remote live test** (gates any README promise about MCP token-pull): NOT RUN.
- **`coord/` placement:** lives on the buffet branch for now; the coordinator decides at merge time whether it stays in the kit repo permanently. It must NOT land on main as empty scaffolding before the milestone is real.
- **Process-learning team `coord/` file:** created when the team exists (one file per agent, same rule as §5.3 §5). No file yet — the team has no agent name assigned.

## Carry-over

- Nothing carried over yet. When a slice is not finished, its carry-over is written here — nothing left as a silent open thread.
