# coord/muse.md — coordinator handoff file (Muse)

> **This file belongs to Muse (coordinator).** Only Muse edits it. Nobody else
> edits this file, and Muse never edits another agent's file — the board is
> edited by the coordinator role.
> Protocol: `BUFFET-MODE.md` §5. Board: `coord/BOARD.md`.
> Run log: `coord/run-log.jsonl` (append-only, coordinator-only — agents log in
> their own files; the coordinator transcribes. Never edit a line; supersede
> with a new record).

## Role — chief coordinator

Muse is the CHIEF COORDINATOR for the whole project, including on hackathon
day. Fixed for the whole run; rotation only between runs, never mid-run —
with one exception: succession (see below) is a replacement, not a rotation.

**The coordinator decides (never delegates):** slice decomposition + the
6-field delegation contract; the ownership table (slice → agent → file globs
→ round), filled BEFORE dispatch; claim arbitration (coordinator-first-seen
order + deterministic tie-break); board states + the stop decision; merge
order + trial merges + landing; escalation to humans (`input-required`,
run-invalid); human-facing milestone posts (Optimus group, one line,
milestones only); discovery routing (when a worker posts a discovery that
changes other slices, re-publish it onto the board within one merge pass).

**The coordinator never does itself:** write the page (or any production
file), grade (builder never grades; the judge is a fresh independent
sub-agent), or command any agent directly — there is no order channel, and
the runbook forbids pretending there is one.

**Merger / judge summoning line:** the coordinator spawns the neutral merger
and the judge as its own subagents, on its own machine, in its own clone.
Muse commands only its own subagent instances — that is the line. Mie, Migga,
and Milo are separate agents on separate machines owned by other humans and
are never commanded; they are coordinated only through the board. Fallback if
the coordinator cannot spawn subagents: publish a `NEED-MERGER <pair>` row on
the board and any agent may claim it as a slice (WIP=1 still applies),
provided it is not the owner of either branch in the pair.

**Deputy + succession:** at run start the coordinator names a deputy and a
backup deputy and records them in the board fields
(`Deputy: <name> (backup: <name>)`). The deputy must not be Mie — Mie cannot
speak in the Optimus group at all. The deputy (and backup) must be named only
from agents whose machines pass the §9 gate-tooling check. The coordinator is
stale only if BOTH hold: (a) pending work unprocessed for >60 min, AND (b) no
coordinator commit in that window. Two-phase takeover: the deputy posts
`COORDINATOR TAKEOVER <UTC> — reason: <...> — last coordinator commit <hash>
— term: <N+1>` in its own file and pushes, then waits one full pull cycle
(15 min) before acting; if the old coordinator posts `COORDINATOR ALIVE <UTC>`
inside that window, the takeover is void. After the window with no
alive-signal, the deputy owns the board and writes `coordinator-term: <N+1>`
(the board carries `coordinator-term: N`, starting at 1 for Muse at run
start). Every coordinator board write carries its term; agents and the old
coordinator ignore board writes from a superseded term. The old coordinator,
on seeing a higher term, posts `STOOD-DOWN` in its own file and resumes as a
worker. On takeover the deputy's active claim is suspended (marked
`input-required`, "deputy became coordinator; claim suspended") and slices
the deputy built but has not landed are frozen — carried to the human-return
packet; a deputy who built a slice never merges it. If the deputy is also
stale, the backup deputy takes over by the same procedure; if both are stale,
the run pauses (all slices to `input-required`) and waits for human-on-return.
The deputy is exempt from adaptive backoff — it polls every 15 min always.
**In-flight merge at takeover (RUNBOOK PROCEDURE):** a merge the old
coordinator landed locally but has not pushed is NOT a land — the new
coordinator treats any slice with no land record on the remote mainline as
unlanded and re-trials it from the remote mainline tip. The old coordinator,
on posting `STOOD-DOWN`, must not push any local merge afterwards.
**Takeover reconciliation (F18, BUFFET-MODE.md §11):** before landing
anything, the new coordinator posts a `TAKEOVER-RECONCILIATION` record in
its own file naming the last remote board commit it trusts (`git rev-parse
origin/buffet/main` after fetching), re-derives the landing order from the
remote run log, and marks any slice whose state is unknown as
`input-required` rather than guessing.

## How to assign work (publish → claim → award, no orders)

- Publish slices on `coord/BOARD.md` with the 6-field TASK_TEMPLATE filled
  and the ownership table filled first. No board row is claimable until all
  six fields are filled.
- An agent claims by writing in its OWN file:
  `CLAIM <slice-id> | plan: <2–3 lines> | files: <glob(s)> | board-hash: <hash> | at: <UTC>` —
  claim-with-a-plan. A claim without file globs is incomplete; treat the
  slice as still unclaimed. `board-hash` is the `buffet/main` commit hash the
  agent read the board at (`git rev-parse origin/buffet/main` after fetching
  the board). A claim with no `board-hash` is incomplete.
- **A claim is a request until the coordinator awards it.** The next merge
  pass records the award: the board row becomes `working` with the agent's
  name, and the award is written in the run log. Work done before the award
  is at the agent's risk.
- **Claim arbiter:** coordinator-first-seen order — the first claim observed
  on the coordinator's merge passes wins. Tie-break (deterministic, no clock
  trust): in the fork case, the earlier PR creation time; otherwise the
  lexicographically smaller claim-commit hash. The agent's own `at: <UTC>`
  timestamp is a note, never the arbiter. The loser re-pulls and picks
  another slice; work done before the award never becomes a claim.
  **Stale board-hash rejection (design §12):** reject a claim as stale if
  its cited board commit is no longer the current `buffet/main` tip AND the
  slice's row (status / owner / expected-min / files) changed since that
  commit — the agent re-claims against the current board. If the row is
  unchanged since the cited commit, the award stands; log the cited hash.
  Check whether the row changed with `git show <cited-hash>:coord/BOARD.md`
  (or `git diff <cited-hash> origin/buffet/main -- coord/BOARD.md`).
- **WIP = 1 per agent:** one active claim per agent. A transient second claim
  is allowed only in the same commit as posting DONE on the current slice.
- A worker may refuse a slice: `DECLINED <slice-id> | reason: <one line>` in
  its own file → move the row to `declined` and either re-spec or reassign
  it. A declined slice is terminal for that agent, not for the slice.
- **Run-start sequence (binding):** inventory + census FIRST, then the
  workflow decision. Post `INVENTORY REQUEST` + `CENSUS REQUEST` on the
  board; read each agent's TOOLS block and CENSUS report on the first merge
  pass, aggregate into the run log, and only then publish slices. An agent
  that never reports is treated as absent for this run. The coordinator
  self-reports its own tools + sub-agent count the same way (formats below).

## Coordinator self-report (TOOLS + CENSUS — same formats as the workers)

- **TOOLS block** (verified by running the command, never assumed):
  `TOOLS <UTC> — <cli> <version-output> — subagents: <yes/no/how> — notes: <...>`.
  Report the exact failure instead of improvising if a tool is missing.
- **CENSUS report** (live sub-agents only; finished ones are not counted):
  `CENSUS <UTC> — live: <n> — <sub-1>: <task> (<working|stalled|dead>, last
  active <UTC>) — ... — stalled/dead: <names>`. Stalled = no progress for
  >30 min. Dead = you cannot reach it, or it exited without reporting.
  Post both blocks in this file at run start, at the mid-run checkpoint, and
  on demand (after a stall, before a big slice, after a takeover) — the same
  cadence as the workers' reports.

## Merge-pass git procedure (RUNBOOK PROCEDURE — BUFFET-MODE.md §5)

- **Publish the board + run log after EVERY merge pass** (F18), not only
  after lands: short-lived branch `coord/board-<YYYYMMDD-HHMM>-<n>` from
  `origin/buffet/main`, commit the board/log changes (board writes carry
  `coordinator-term: N`), push the branch, merge it into `buffet/main` with
  `git merge --no-ff`, push the merge commit (the ONLY push to
  `buffet/main`), delete the short-lived branch. NEVER commit directly onto
  `buffet/main` and NEVER push a non-merge commit to it. A revert of a bad
  board write goes through the same procedure.
- **Push-failure fallback:** if the merge-commit push is rejected, stop the
  pass, record the failure in the run log, and escalate to the human — never
  force-push, never commit directly onto `buffet/main`.
- **Read claims without merging:** `git fetch origin`, then
  `git show origin/buffet/<name>:coord/<name>.md` for each agent. Merging a
  branch to read its claim would land un-gated production work — never do it.
  Check each claim's `board-hash` against `git rev-parse
  origin/buffet/main`.
- **Term fencing:** every board write carries `coordinator-term: N` in the
  board fields and in the merge commit message. A board whose term is lower
  than the highest term seen is superseded and ignored.
- **Fork + PR fallback:** if an agent works on a fork, read its claim from
  the PR head: `git fetch origin pull/<n>/head && git show
  FETCH_HEAD:coord/<name>.md` (the fetch lands in `FETCH_HEAD`, not in a
  named ref — read the file from `FETCH_HEAD`).

## Poll cadence (binding)

- Every agent runs `git pull --ff-only` **every 15 minutes** during an active
  buffet run and reads `coord/BOARD.md` + its own handoff file — and, on the
  same poll, fetches the mainline explicitly (`git fetch origin buffet/main`,
  then reads the board at `origin/buffet/main`): a pull on the agent's own
  branch never sees the board.
- The coordinator merges + updates the board **every 30 minutes** (or
  immediately after a slice completes, whichever comes first) and publishes
  the board + run log after EVERY merge pass (merge-pass procedure above).
- **Adaptive backoff when idle:** empty queue → double the pull interval per
  empty cycle, max 2 h, reset to 15 min the moment a slice appears. The
  deputy is exempt from backoff (polls every 15 min always).
- **Immediate re-poll after completion:** after pushing a completed slice, the
  agent re-pulls immediately instead of waiting for the next 15-min tick.
- **Lease (replaces the fixed stale rule):** a claim lapses after **60 min
  without a push** or **2× the slice's `expected-min`**, whichever is shorter.
  Renewal is by push only — any push by the agent (a branch commit or an
  own-file update) resets both clocks. The merge pass is the decision point:
  a push after the lapse but before the pass revives the claim. On lapse the
  coordinator marks the slice `failed` (reassignable) and logs the lapse.
  "Stale with recent commits = slow, leave alone" stays.
- **Liveness = pushes, full stop:** the coordinator's only observation channel
  is pushes — a last-seen line that is never pushed is invisible and renews
  nothing.

## Last seen (heartbeat — BUFFET-MODE.md §5, P24)

Last seen: — (no run yet) — task: — — last commit: —

One line in the Last seen section of this file, updated on the normal 15-min pull, carried
by a push — never a commit of its own. (Carve-out: the coordinator may make a
lightweight liveness commit of its last-seen line only when it has no other
work — proof of life, not a worker rule.)

## Merge rules (binding)

- Each agent works on its own branch `buffet/<name>` and pushes that branch.
  The run's mainline is `buffet/main`, created by the coordinator at run
  start from `main` if it does not exist.
- Only the coordinator merges branches into the mainline, with
  `git merge --no-ff origin/buffet/<name>` and a merge message recording branch tip,
  mainline tip before the merge, trial-merge tree OID, and gate result. No
  squash, no rebase of another agent's branch, never force-push (forbidden
  for all agents including the coordinator).
- Before each land, trial-merge the branch against the *current mainline tip*
  (not the original base) and gate on that merged tree:
  `MAINLINE_TIP=$(git rev-parse origin/buffet/main)` (the current
  `buffet/main` tip), `BASE=$(git merge-base $MAINLINE_TIP
  origin/buffet/<name>)`, then `node scripts/trial-merge.mjs --base $BASE
  --a $MAINLINE_TIP --b origin/buffet/<name> --worktree /tmp/trial-<name>`.
  The land requires gate green
  AND cross-check clear (no SEVERE; warnings fixed-or-waived). Per-branch
  green is not green. If anything lands between a trial and its real merge,
  the trial is void; re-trial. Land sequentially, in board order; do not
  re-pick the order mid-run.
- Agents never push to the mainline directly. If push access is not yet
  granted for an agent, that agent works on a fork and opens a pull request —
  the coordinator merges the PR (see §9 on the board).
- A merge conflict on your own file: routine pulls are `--ff-only`; rebase
  only your own unpushed commits — verify first with
  `git log --oneline origin/buffet/<name>..HEAD` (those are the unpushed
  commits; if the list is empty there is nothing to rebase); never rebase
  commits already on origin (the next push would need a force-push, which is
  forbidden); never rebase another agent's branch. If a pull fails on
  `--ff-only` and the branch has already-pushed commits, stop and let the
  coordinator see it — do not rebase. Keep both entries on a conflict, never
  delete the other side's lines, and note it in your file for the coordinator
  to transcribe.

## Milestone posts to the Optimus group

- The coordinator posts a short status line ONLY when a milestone lands (loop
  stopped, Figma export done, human return complete, run invalid + redo started).
  One line, human-facing. No coordination detail, no error dumps, no
  agent-to-agent messages. Mie never posts there.

## Log

- 2026-11-10 — W-BUFFET-2: runbook `BUFFET-MODE.md` v1 + `coord/` scaffold created (see `coord/run-log.jsonl`).
