# coord/milo.md — handoff file (Milo)

> **This file belongs to Milo.** Only Milo edits it. Never edit another agent's
> file, never edit `coord/BOARD.md` (coordinator-owned), never rewrite history
> in `coord/run-log.jsonl` (append-only).
> Protocol: `BUFFET-MODE.md` §5. Board: `coord/BOARD.md` (read-only for Milo).
> Runbook: `BUFFET-MODE.md` — your role is in §1.

## Role

Milo is one of the four agents in this run (Muse, Mie, Migga, Milo). Role per
run: builder (one instance per direction), independent expert, or independent
judge — as assigned on the board. A builder never grades its own work; an
expert judges ONLY its own domain, from the artifacts, never from the builder's
reasoning; a judge grades 1–5 on Type / Layout / Colour / Space with one
evidence line per score.

**Figma path C (MCP read) is NOT available to Milo** — Hermes / Muse Code /
CommandCode are not in Figma's MCP catalog (`BUFFET-MODE.md` §6). Use paths
A/B only.

## How to claim work

- Read `coord/BOARD.md` for open slices (one line per slice: id, brief slice,
  owner, status).
- Claim a slice by writing `CLAIM <slice-id>` + timestamp in THIS file — never
  by editing the board. The coordinator merges claims into the board on its
  next pass.
- Two agents claiming the same slice: the earlier timestamp in the run log wins;
  the later one picks another slice.
- If you disagree with an assignment, write the objection in this file and keep
  working on the last agreed slice — do not stall the run waiting for an answer.

## Poll cadence (binding)

- During an active buffet run, run `git pull --ff-only` **every 15 minutes**
  and read `coord/BOARD.md` + this file.
- Between polls, work from your local copy and write only to this file
  (plus appends to `coord/run-log.jsonl`).

## Merge rules (binding)

- Work on your own branch `buffet/milo` and push that branch. Only the
  coordinator merges branches into the buffet mainline — never push to the
  mainline directly, never force-push.
- If push access is not yet granted, work on a fork and open a pull request —
  the coordinator merges the PR (see the §9 blank on the board).
- A merge conflict on your own file: `git pull --rebase`, keep both entries,
  never delete the other side's lines; note it in the run log.

## Log

- (no entries yet — append `CLAIM <slice-id>` + timestamp + progress here, and append records to `coord/run-log.jsonl`.)
