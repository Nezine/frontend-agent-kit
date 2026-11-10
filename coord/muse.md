# coord/muse.md — coordinator handoff file (Muse)

> **This file belongs to Muse (coordinator).** Only Muse edits it. Nobody else
> edits this file, and Muse never edits another agent's file or `coord/BOARD.md`
> from another agent's session — the board is edited by the coordinator role.
> Protocol: `BUFFET-MODE.md` §5. Board: `coord/BOARD.md`.
> Run log: `coord/run-log.jsonl` (append-only — append records, never rewrite).

## Role

Coordinator / orchestrator. Owns the run sequence, `coord/BOARD.md`, the merge
protocol, and the stop decision. Assigns slices, merges work, declares the run
done. Does not write the page. Does not grade. Does not command the other three
agents directly — coordination works by this runbook protocol, not by orders.

## How to claim work

- The coordinator does not claim slices — it ASSIGNS them by writing rows on
  `coord/BOARD.md`.
- The other agents claim by writing `CLAIM <slice-id>` + timestamp in their OWN
  file. The coordinator merges claims into the board on its next pass.
- Two agents claiming the same slice: the earlier timestamp in the run log wins;
  the later one picks another slice.

## Poll cadence (binding)

- Every agent runs `git pull --ff-only` **every 15 minutes** during an active
  buffet run and reads `coord/BOARD.md` + its own handoff file.
- The coordinator merges + updates the board **every 30 minutes** (or
  immediately after a slice completes, whichever comes first).

## Last seen (heartbeat — BUFFET-MODE.md §5, P24)

Last seen: — (no run yet) — task: — — last commit: —

Updated on the normal 15-minute pull (same commit as other work — never a
commit of its own). On every 30-minute merge pass the coordinator sweeps the
four last-seen lines: stale >30 min with no commit = stuck (slice failed,
reassignable); stale with recent commits = slow, leave alone; no heartbeat
after 15 min = never started.

## Merge rules (binding)

- Each agent works on its own branch `buffet/<name>` and pushes that branch.
- Only the coordinator merges branches into the buffet mainline (fast-forward or
  merge commit; never rebase someone else's branch, never force-push).
- Agents never push to the mainline directly.
- If push access is not yet granted for an agent, that agent works on a fork and
  opens a pull request — the coordinator merges the PR (see §9 blank on the board).
- A merge conflict on your own file: `git pull --rebase`, keep both entries,
  never delete the other side's lines; note it in the run log.

## Milestone posts to the Optimus group

- The coordinator posts a short status line ONLY when a milestone lands (loop
  stopped, Figma export done, human return complete, run invalid + redo started).
  One line, human-facing. No coordination detail, no error dumps, no
  agent-to-agent messages. Mie never posts there.

## Log

- 2026-11-10 — W-BUFFET-2: runbook `BUFFET-MODE.md` v1 + `coord/` scaffold created (see `coord/run-log.jsonl`).
