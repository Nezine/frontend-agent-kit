# coord/migga.md — handoff file (Migga)

> **This file belongs to Migga.** Only Migga edits it. Never edit another
> agent's file, never edit `coord/BOARD.md` (coordinator-owned), never rewrite
> history in `coord/run-log.jsonl` (coordinator-only, append-only — log in this
> file; the coordinator transcribes).
> Protocol: `BUFFET-MODE.md` §5. Board: `coord/BOARD.md` (read-only for Migga).
> Runbook: `BUFFET-MODE.md` — your role is in §1.

## Role

Migga is one of the four agents in this run (Muse, Mie, Migga, Milo). Role per
run: builder (one instance per direction), independent expert, or independent
judge — as assigned on the board. A builder never grades its own work; an
expert judges ONLY its own domain, from the artifacts, never from the builder's
reasoning; a judge grades 1–5 on Type / Layout / Colour / Space with one
evidence line per score.

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

- Work on your own branch `buffet/migga` and push that branch. Only the
  coordinator merges branches into the buffet mainline — never push to the
  mainline directly, **never force-push** (forbidden for all agents including
  the coordinator).
- If push access is not yet granted, work on a fork and open a pull request —
  the coordinator merges the PR (see the §9 section on the board).
- A merge conflict on your own file: routine pulls are `--ff-only`; rebase
  only your own unpushed commits — verify first with
  `git log --oneline origin/buffet/migga..HEAD` (those are the unpushed
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

## Migga handoff — ongoing development (from 2026-11-12)

> Coordination channel: repo/git, milestone-driven (handoff rules, not buffet-run
> leases/polls). Muse is the coordinator and the ONLY merger; BOARD.md is
> Muse-owned. Discussion lives in PR comments on Migga's PRs. This file is
> append-only below this heading; existing lines above are never rewritten.

- **2026-11-12 16:38 UTC — START.** Fork `Nezine/frontend-agent-kit` created
  from upstream main `98c256b` ("run-log: Milo M2 merged (PR #3, a17a862); M3
  starts"). Main moved since the handoff (a60cced → 98c256b); a17a862 is an
  ancestor of the fork HEAD, so no rebase was needed. Working branch:
  `migga/mig-1`. Git identity (repo-local, verified):
  `phamTuan207 <232407559+phamTuan207@users.noreply.github.com>`.
  Decisions: D15 is the latest entry in
  `skills/frontend-kit/references/decisions.md`; D16–D19 are Milo's M3
  (active); first decision number is D20, shared with Mie (unclaimed by
  either as of this entry — claim the number here first before writing it
  into decisions.md).
- **Machine (MIG-1 host):** Linux x86_64 (`Linux htch-runtime 7.0.0-44-generic`),
  node v24.22.1, npm/npx 10.9.4, python3 3.12.3, git, curl, gh 2.102.0
  (authenticated). No system Chrome/Chromium in PATH (recheck during
  install; install.sh may fetch Playwright browsers). `codex` binary
  present; no host config dirs (`~/.claude`, `~/.codex`, `~/.config/opencode`,
  `~/.gemini`, `~/.hermes`, `~/.commandcode` all absent). 149G free in the
  workspace; /tmp is a 512M tmpfs — scratch clones/probes use workspace
  dirs, never /tmp.
- **CLAIM MIG-1 | plan: fresh clone of main into a scratch dir → ./install.sh
  → ./verify.sh → full Brief-1 loop probe (verbatim brief) → TOOLS + MODELS
  inventory in this file | files: `install.sh`, `verify.sh`,
  `skills/frontend-kit/**` (probe only) | at: 2026-11-12 16:38 UTC**
- **CLAIM MIG-2 | plan: council-decide each of O1, O2, O3, O5, §2e anchor, L2
  (one decision per item, next free D-number) → implement → independent QC +
  dedicated red team → prove with fresh install + verify.sh | files:
  `install.sh`, `verify.sh`, `skills/frontend-kit/SKILL.md` (O3 line only) |
  at: 2026-11-12 16:38 UTC** (queued after MIG-1)
- **CLAIM MIG-3 | plan: council-decide each of F6, L1 option (b), plugin-route
  spot-check → implement → QC + red team → prove with gate runs / real
  plugin-route run | files: `skills/frontend-kit/scripts/gate/**`, `verify.sh`
  | at: 2026-11-12 16:38 UTC** (queued after MIG-2)
- **Optimus urgent-channel check 2026-11-12 ~16:36 UTC:** read the group (new
  messages only). No new @migga direction; the group confirms M2 merged
  (a17a862) and M3 started. No reply posted (coordinator posts milestones).
- **RULE CHANGE 2026-11-12 16:47 UTC (user, Hoàng Anh — overrides the handoff):**
  when Migga finishes something, Migga posts a SHORT milestone update in the
  Optimus Messenger group itself (2–3 lines, Vietnamese, casual — e.g. MIG-1
  done + PR link, MIG-2 done, blocked items). No agent-to-agent coordination
  chatter, no raw logs, no internal detail. No need to ask the user first for
  this category — approved in advance. The handoff's "Migga never posts in
  the group / Muse posts human-facing milestones only" rule is superseded by
  this user instruction for milestone updates only; coordination still lives
  in the repo. Recorded here so the coordinator sees it.
- **2026-11-12 16:57 UTC — MIG-1 install + verify: DONE (remediated).**
  Fresh clone of upstream main 98c256b into a scratch dir → `./install.sh`
  exit 1 (its embedded verify run failed at the time) → remediated →
  standalone `./verify.sh` exit 0: **0 failures, 0 unverified, 1 warning, 1
  pending** (log: `~/workspace/scratch/mig1-verify2.log`, 255 OK lines).
  Hosts installed: codex + muse (codex-cli 0.164.0-alpha.9 detected;
  `~/workspace/custom-skills` present). Skills present in 3 copies
  (`.agents/skills`, `.codex/skills`, `workspace/custom-skills`); engine
  lockstep 0.1.21 verified by hash; vendored-allowlist matches the tree
  hash-for-hash (27 entries, taste v2.5.1); gate leg 1 + leg 2 green on the
  fixture; self-test passes; headless 390px screenshot succeeds via
  chromium (44,696 bytes). Remaining warning (host-state): no system
  Chrome — Playwright chromium covers eyes + gate leg 2 via CHROME_PATH.
  Remaining pending (known O2, non-blocking): Impeccable hook NOT wired
  for codex — `npx impeccable@4.8.2 install` failed 4x total (2x in
  install, 2x manual retries) with the same network error downloading the
  skill bundle from the releases host (TLS peer closed connection).
  Remediation done: (a) `PATH` exported with `~/.local/bin` (gitleaks
  8.30.1 was installed there but the dir is not on this VM's default
  PATH — host-state; every future gate/verify run in this VM must export
  it) — this cleared verify failures 1–3 + the D15 case-(104) unverified;
  (b) Chrome-for-Testing placed via curl + the installer's own fallback
  layout (`~/.cache/ms-playwright/chromium-1254`, binary runs:
  Google Chrome for Testing 158.0.8127.18; headless shell placed the same
  way, `chromium_headless_shell-1254`; `playwright-cli install-browser
  --list` shows both) — this cleared verify failure 4 + the leg-2
  unverified. Install log: `~/workspace/scratch/mig1-install.log`.
  Environment notes: `cp -a` ownership preservation fails on this
  filesystem (installer falls back to `cp -R`; content verified by
  hashes); engine drift warning pinned 0.1.21 vs latest 0.1.22 — NOT
  re-pinned (Muse owns the re-pin).
- **GAP-14 PROPOSAL (awaiting coordinator award — NOT implemented):**
  `install.sh` `playwright_curl_one` URL mapping misses the bare
  `cdn.playwright.dev/builds/cft/...` shape the CLI actually emits.
  Evidence: install log line "curl fallback: unknown artifact URL (no
  cache-layout mapping — not guessing):
  https://cdn.playwright.dev/builds/cft/158.0.8127.18/linux64/chrome-linux64.zip";
  the case patterns only match `cdn.playwright.dev/*/builds/cft/...`
  (needs a path segment between host and `/builds/`) and the
  `storage.googleapis.com/chrome-for-testing-public/...` shape. The same
  URL fetched fine with plain curl (207,460,506 B, exit 0) and the
  browser runs. Proposed fix: add the bare-CDN shapes to the mapping
  (same name/rev/exe_rel as the `*/builds/cft` entries). Awaiting a board
  row before implementing.
