# coord/milo.md — handoff file (Milo)

> **This file belongs to Milo.** Only Milo edits it. Never edit another agent's
> file, never edit `coord/BOARD.md` (coordinator-owned), never rewrite history
> in `coord/run-log.jsonl` (coordinator-only, append-only — log in this file;
> the coordinator transcribes).
> Protocol: `BUFFET-MODE.md` §5. Board: `coord/BOARD.md` (read-only for Milo).
> Runbook: `BUFFET-MODE.md` — your role is in §1.

## Role

Milo is one of the four agents in this run (Muse, Mie, Migga, Milo). Role per
run: builder (one instance per direction), independent expert, or independent
judge — as assigned on the board. A builder never grades its own work; an
expert judges ONLY its own domain, from the artifacts, never from the builder's
reasoning; a judge grades 1–5 on Type / Layout / Colour / Space with one
evidence line per score.

**Figma path C (MCP read) is available only on hosts in Figma's MCP catalog**
(`BUFFET-MODE.md` §6) — Hermes / Muse Code / CommandCode are not in the
catalog. If your host is outside the catalog, use paths A/B only; check your
host against the catalog, do not assume. (No file in the repo states which
host Milo runs on, so this is a per-host rule, not a Milo-specific claim.)

## Deputy + succession (you may be named deputy — read this before the run)

- You may be named deputy (or backup deputy) at run start; the board's
  `Deputy` field names you. The deputy (and backup) is named only from
  agents whose machines pass the §9 gate-tooling check — a deputy that
  cannot run the merged-tree gate cannot land anything (F29). The deputy is
  never Mie.
- **Backoff exemption:** if you are the deputy, you are EXEMPT from adaptive
  backoff — poll every 15 min always, even with an empty queue. (A deputy
  pulling every 2 h could not detect a 60-min staleness until hours later;
  the detection bound is 60–75 min after the coordinator's last commit.)
- **Staleness test (what "the coordinator is dead" means):** the coordinator
  is stale only if BOTH hold: (a) there is pending work — a claim, a
  completion, or a slice awaiting merge — unprocessed for >60 min, AND (b)
  no coordinator commit in that window. An idle coordinator with an empty
  queue is idle, not stale: no pending work means no takeover, whatever the
  clock says.
- **Two-phase takeover (fencing):** (1) post `COORDINATOR TAKEOVER <UTC> —
  reason: <pending work unprocessed since X> — last coordinator commit
  <hash> — term: <N+1>` in this file and push; (2) wait one full pull cycle
  (15 min) before acting as coordinator. If the old coordinator posts
  `COORDINATOR ALIVE <UTC>` in its own file and pushes inside that window,
  the takeover is void — post `TAKEOVER VOID — coordinator alive` and stand
  down. (3) After the window with no alive-signal, you own the board: write
  `coordinator-term: <N+1>` in the board (the board carries
  `coordinator-term: N`, starting at 1 for Muse at run start; each takeover
  increments it). **Every coordinator board write carries its term; agents
  and the old coordinator ignore board writes from a superseded term.** The
  old coordinator, on seeing a higher term, posts `STOOD-DOWN` in its own
  file and resumes as a worker. Publish board writes through the merge-pass
  procedure (short-lived `coord/board-…` branch + merge into `buffet/main`,
  `BUFFET-MODE.md` §5) — never by direct push to `buffet/main`.
- **Your own work on takeover:** your active claim is **suspended** — marked
  `input-required` with the note "deputy became coordinator; claim
  suspended", and reassigned by you (as the new coordinator) to another
  agent or re-listed. **Slices you built but have not landed are frozen** —
  they stay `working` under your name but you do not land or stop-decide
  them; they are carried to the human-return packet. A deputy who built a
  slice never merges it.
- **Fallback if the deputy is also stale:** if you are the backup deputy and
  the deputy is also stale, take over by the same procedure (same staleness
  test, same two-phase takeover, same term increment). If both deputies are
  stale, the run **pauses**: all slices go to `input-required` with the
  blocker named, and the run waits for human-on-return. There is no third
  deputy and no silent continuation without a coordinator.
- **In-flight merge at takeover (RUNBOOK PROCEDURE):** a merge the old
  coordinator landed locally but has not pushed is NOT a land — treat any
  slice with no land record on the remote mainline as unlanded and re-trial
  it from the remote mainline tip before landing it. The old coordinator, on
  posting `STOOD-DOWN`, must not push any local merge afterwards.
- **Takeover reconciliation (F18, BUFFET-MODE.md §11):** before landing
  anything, post a `TAKEOVER-RECONCILIATION` record in this file naming the
  last remote board commit you trust (`git rev-parse origin/buffet/main`
  after fetching), re-derive the landing order from the remote run log, and
  mark any slice whose state is unknown as `input-required` rather than
  guessing.

## How to claim work

- Read `coord/BOARD.md` for open slices (one row per slice: Slice, Owner,
  Status, Expected-min, Files, Notes — Notes links to the filled task file at
  `coord/tasks/<slice-id>.md`). No row is claimable until all six task fields
  are filled; if you find an unfilled row, write `BLOCKED — template
  incomplete` in this file and do not start.
- Claim a slice by writing in THIS file — never by editing the board:
  `CLAIM <slice-id> | plan: <2–3 lines> | files: <glob(s)> | board-hash: <hash> | at: <UTC>` —
  claim-with-a-plan. A claim without file globs is incomplete. `board-hash`
  is the `buffet/main` commit hash you read the board at
  (`git rev-parse origin/buffet/main` after fetching the board — see Poll
  cadence below). A claim with no `board-hash` is incomplete.
- **A claim is a request until the coordinator awards it.** The coordinator's
  next merge pass records the award (board row becomes `working` with your
  name). Work done before the award is at your risk. The arbiter is the
  coordinator's first-seen order; tie-break is the lexicographically smaller
  claim-commit hash (in the fork case, the earlier PR creation time). Your own
  `at: <UTC>` timestamp is a note, never the arbiter.
- **WIP = 1:** one active claim at a time. A transient second claim is allowed
  only in the same commit as posting DONE on the current slice.
- To refuse a slice: `DECLINED <slice-id> | reason: <one line>` in this file.
  A declined slice is terminal for you, not for the slice.
- If you disagree with an assignment, write the objection in this file and keep
  working on the last agreed slice — do not stall the run waiting for an answer.

## Poll cadence (binding)

- During an active buffet run, run `git pull --ff-only` **every 15 minutes**
  and read `coord/BOARD.md` + this file. On the same poll, fetch the
  mainline explicitly — `git fetch origin buffet/main`, then read the board
  at `origin/buffet/main`: a pull on your own branch never sees the board,
  which lives on `buffet/main`.
- Between polls, work from your local copy and write only to this file.
- **Term check:** on every fetch, compare the board's `coordinator-term`
  against the highest term you have seen — record it in this file as
  `Highest board term seen: <N>` (under Last seen). A board whose term is
  lower than the highest seen is superseded — ignore it.
- **Adaptive backoff when idle:** empty queue → double the pull interval per
  empty cycle, max 2 h, reset to 15 min the moment a slice appears. **UNLESS
  you are the deputy** (see Deputy + succession above) — the deputy is exempt
  from backoff and polls every 15 min always.
- **Immediate re-poll after completion:** after pushing a completed slice,
  re-pull immediately instead of waiting for the next 15-min tick.
- **Lease:** a claim lapses after **60 min without a push** or **2× the slice's
  `expected-min`**, whichever is shorter. Renewal is by push only — any push
  (a branch commit or an own-file update) resets both clocks. The merge pass
  is the decision point: a push after the lapse but before the pass revives
  the claim. On lapse the coordinator marks the slice `failed` (reassignable)
  and logs the lapse. "Stale with recent commits = slow, leave alone" stays.
- **Liveness = pushes, full stop:** the coordinator's only observation channel
  is pushes — a last-seen line that is never pushed is invisible to the
  coordinator and renews nothing.

## Last seen (heartbeat — BUFFET-MODE.md §5, P24)

Last seen: — (no run yet) — task: — — last commit: —

One line in the Last seen section of this file, updated on your normal 15-minute pull,
carried by a push — never a commit of its own. For research / no-commit
slices this is the renewal path: push your own-file update (last-seen line +
progress note) and that push renews the lease.

## Inventory + census (at run start, on demand)

- **TOOLS block** (verified by running the command, never assumed):
  `TOOLS <UTC> — <cli> <version-output> — subagents: <yes/no/how> — notes: <...>`.
  Report the exact failure instead of improvising if a tool is missing.
- **Census report** (live sub-agents only; finished ones are not counted):
  `CENSUS <UTC> — live: <n> — <sub-1>: <task> (<working|stalled|dead>, last
  active <UTC>) — ... — stalled/dead: <names>`. Stalled = no progress for
  >30 min. Dead = you cannot reach it, or it exited without reporting.
  The coordinator posts `CENSUS REQUEST <UTC>` on the board; report in this
  file and push.

## Merge rules (binding)

- Work on your own branch `buffet/milo` and push that branch. Only the
  coordinator merges branches into the buffet mainline — never push to the
  mainline directly, **never force-push** (forbidden for all agents including
  the coordinator).
- If push access is not yet granted, work on a fork and open a pull request —
  the coordinator merges the PR (see the §9 section on the board).
- A merge conflict on your own file: routine pulls are `--ff-only`; rebase
  only your own unpushed commits — verify first with
  `git log --oneline origin/buffet/milo..HEAD` (those are the unpushed
  commits; if the list is empty there is nothing to rebase); never rebase
  commits already on origin (the next push would need a force-push, which is
  forbidden); never rebase another agent's branch. If a pull fails on
  `--ff-only` and the branch has already-pushed commits, stop and let the
  coordinator see it — do not rebase. Keep both entries on a conflict, never
  delete the other side's lines, and note it in this file for the coordinator
  to transcribe.

## The Optimus group

- The group is for HUMAN-FACING MILESTONES ONLY. No agent-to-agent
  coordination chatter there, ever. Only the coordinator (Muse) posts
  milestone lines.

## Log

- (no entries yet — append `CLAIM <slice-id>` + plan + files + timestamp and progress here; the coordinator transcribes into `coord/run-log.jsonl`.)
