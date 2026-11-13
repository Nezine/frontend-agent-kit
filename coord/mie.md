# coord/mie.md — handoff file (Mie)

> **This file belongs to Mie.** Only Mie edits it. Never edit another agent's
> file, never edit `coord/BOARD.md` (coordinator-owned), never rewrite history
> in `coord/run-log.jsonl` (coordinator-only, append-only — log in this file;
> the coordinator transcribes).
> Protocol: `BUFFET-MODE.md` §5. Board: `coord/BOARD.md` (read-only for Mie).
> Runbook: `BUFFET-MODE.md` — your role is in §1.

## Role

Mie is one of the four agents in this run (Muse, Mie, Migga, Milo). Role per
run: builder (one instance per direction), independent expert, or independent
judge — as assigned on the board. A builder never grades its own work; an
expert judges ONLY its own domain, from the artifacts, never from the builder's
reasoning; a judge grades 1–5 on Type / Layout / Colour / Space with one
evidence line per score.

**Mie cannot speak in the Optimus group at all.** Coordination is through this
file + the repo only. If a milestone needs to reach the humans, the coordinator
(Muse) posts it.

**Mie is never deputy and never backup deputy** — a Mie coordinator would
either stop milestone posting for the rest of the run or post in violation
of the rule above. If the board ever names Mie as deputy, that is an error:
write it in this file and keep working as a worker; do not take over.

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
  empty cycle, max 2 h, reset to 15 min the moment a slice appears.
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

- Work on your own branch `buffet/mie` and push that branch. Only the
  coordinator merges branches into the buffet mainline — never push to the
  mainline directly, **never force-push** (forbidden for all agents including
  the coordinator).
- If push access is not yet granted, work on a fork and open a pull request —
  the coordinator merges the PR (see the §9 section on the board).
- A merge conflict on your own file: routine pulls are `--ff-only`; rebase
  only your own unpushed commits — verify first with
  `git log --oneline origin/buffet/mie..HEAD` (those are the unpushed
  commits; if the list is empty there is nothing to rebase); never rebase
  commits already on origin (the next push would need a force-push, which is
  forbidden); never rebase another agent's branch. If a pull fails on
  `--ff-only` and the branch has already-pushed commits, stop and let the
  coordinator see it — do not rebase. Keep both entries on a conflict, never
  delete the other side's lines, and note it in this file for the coordinator
  to transcribe.

## The Optimus group

- **Mie never speaks in the Optimus group at all.** The group is for
  HUMAN-FACING MILESTONES ONLY, posted by the coordinator (Muse). Do NOT
  propose adding Mie to it.

## Log

- (no entries yet — append `CLAIM <slice-id>` + plan + files + timestamp and progress here; the coordinator transcribes into `coord/run-log.jsonl`.)

## Mie handoff — ongoing development (from 2026-11-12)

- 2026-11-13 01:08 UTC — START. Main moved: the brief's d92fbda / 80d04a5 are stale; work starts from aa93e75 (`git ls-remote` HEAD = aa93e750766fbb507f9ae334b5cdc391cad74285, "board: PR #4 review (NOT LANDABLE yet — D23/D30 cites +9, CI approved), D33=F6, D34=L1, D35=GAP-14 awarded"). First decision number is D21 (D20 taken by Migga via PR #4, D20–D32; verified free on main: decisions.md holds D1–D15 only, D16–D19 reserved for Milo M3).
- CLAIM MIE-1 | plan: real-MacBook clone-and-go (fresh clone → ./install.sh → ./verify.sh → Brief-1 probe) | files: install.sh, verify.sh, skills/frontend-kit/** (probe only) | board-hash: aa93e75 | at: 2026-11-13 01:08 UTC | status: BLOCKED — the MacBook has not been opened by its owner yet, so SSH cannot reach it. NOT a Tailscale fault (owner-confirmed via coordinator, 2026-11-13); no Tailscale check needed. Waits for the owner to open the machine.
- CLAIM MIE-2 | plan: verify the macOS CI failures live, council-decide the fix (D21), implement on fork branch, QC + red team, prove with a CI run on the branch (macOS jobs green), open a PR to upstream main | files: install.sh, verify.sh, skills/frontend-kit/scripts/gate/** | board-hash: aa93e75 | at: 2026-11-13 01:08 UTC | status: IN PROGRESS — council of 3 experts done; CI-log verification done (see milestone below).
- CLAIM MIE-3 | plan: MacBook TOOLS inventory (BUFFET-MODE.md §2) + MODELS block (FLEET-MODE.md §2) | files: coord/mie.md (inventory section) | board-hash: aa93e75 | at: 2026-11-13 01:08 UTC | status: BLOCKED — same as MIE-1: waits for the owner to open the MacBook.
- 2026-11-13 01:08 UTC — MILESTONE: fork ready. Fork: https://github.com/ashley8127/frontend-agent-kit (parent phamTuan207/frontend-agent-kit). Branch: mie/mie-2-macos, from aa93e75. gh authenticated on the VM as ashley8127 (device flow, owner-approved). Commit identity configured repo-local: phamTuan207 <232407559+phamTuan207@users.noreply.github.com>.
- 2026-11-13 01:08 UTC — MILESTONE: MIE-2 council verdict (D21, one decision, both halves, with a severability clause — see the D21 entry in the PR). Council (3 independent experts, reports in the coordinator's workspace): (A) install.sh forensics — install.sh itself is unchanged since 1464fbb (green then); the Install step fails at its fatal tail (install.sh:2137 runs ./verify.sh, default mode, and exits 1 on failure), so the embedded verify.sh is the failing code. (B) §5c sed audit — the sed hypothesis is CONFIRMED for both site classes by the FreeBSD sed man page + source: `sed -i -e …` (4 fill-helper sites) dies on `lstat("-e")`, leaving the PENDING skeleton line; bare `sed -i 's/…/…/'` (10 sites) dies on `invalid command code`, file unchanged; the three `\x..` sites need real UTF-8 bytes (`$'\xe2\x80\x8b'`, `$'\xd0\xb0'`) because BSD sed has no `\x` escape; a second blocker in the same section is 18 bare `sha256sum` uses with no `shasum` fallback. Recommended fix: one OS-dispatched `sedi` helper + one `sha256_file` helper + the byte variables; `sed -i ''` unconditionally is disproved on GNU (rc=2). (C) scope — D21 is free; one decision covering both halves; the "19 §5c cases" figure was unverified from files alone; the §5c region sits inside Milo's §5 fixture, so the PR states the owner's "macOS is yours" authorisation and requests Milo/Muse review.
- 2026-11-13 01:08 UTC — MILESTONE: CI-log verification (run 43315591520, main HEAD, fetched with authenticated gh). PROVEN on the log: exactly 19 FAIL lines per macOS job (19 macos-15 + 19 macos-26), all `judge-artifact (D15)` §5c cases downstream of the fill failure — the "19 §5c cases" figure is now confirmed on main, not a PR #3 snapshot. The log shows 22× `sed: -e: No such file or directory` and 4× `invalid command code`, matching the council's two predicted failure modes. The §3b hypothesis (H1, `sha256sum` with no `shasum` fallback) is REFUTED on the CI runners: the log shows `OK: vendored-allowlist.txt matches the vendored taste tree hash-for-hash (27 entries)` — the runner image provides `sha256sum` (Homebrew on the image). H1 stays a real defect for a stock MacBook only (no `sha256sum` there); the §5c `sha256_file` fix is included in D21 for the MacBook target, not for CI green. Next: implement D21 on this branch.
- 2026-11-13 — NOTE (user instruction, 2026-11-13, relayed by the coordinator): milestones are ALSO reported to the Optimus group as human-facing reports, posted by the main agent as relay; the repo remains the coordination record. The "Mie never posts in the Optimus group" lines in the Role section above are superseded for milestone reporting by this instruction. The @mie reply rule also applies in the group and in the 1-to-1 DM thread: when called, Mie answers there.
- 2026-11-13 01:16 UTC — MILESTONE: D21 implemented (commit 76c7042, pushed to fork branch mie/mie-2-macos; identity verified). verify.sh: OS-dispatched `sedi` helper + `sha256_file` helper + `zwsp`/`cyr_a` byte variables; §3b hash loop uses the helper; all 14 `sed -i` sites → `sedi` (three `\x..` sites use the byte variables); all 18 bare `sha256sum` uses in §5c → `sha256_file`; loud-fill adjunct on the four fill sites. decisions.md: D21 entry appended after D15. Verification: `bash -n` passes on all five CI scripts; CI lint grep clean; local `./verify.sh --strict` on Linux: §5b 103 OK / 0 FAIL, §5c 126 OK / 0 FAIL — exactly the M2 baseline (overall exit 1 from 198 environmental failures outside §5b/§5c: no installed kit copy, no Chrome, no playwright-cli on the bare VM). One §5c UNVERIFIED: case (104)'s gitleaks half (no gitleaks on the VM). Two deliberate deviations recorded as residuals in D21: (1) the 3181 loud-fill message names the file path explicitly (`$1` is unset at top level under `set -u`); (2) `sha256_file` accepts a no-argument stdin form, used only by the two `printf`-piped sites. Independent QC + dedicated red team launched (separate agents); macOS proof (fork CI macos-15/macos-26 green) still owed before the PR.
- 2026-11-13 01:23 UTC — MILESTONE: red-team verdict FAIL (report in the coordinator's workspace). SEVERE S-1: `jr_prep` aborts on bash 3.2 at the first expert kind — CI log (run 43315591520, both macOS jobs): `verify.sh: line 2959: grader_args[@]: unbound variable`, right after case (29)'s OK line; verify.sh dies with no summary, cases (30)–(106) never ran on macOS. Cause: `grader_args=()` for expert kinds + `"${grader_args[@]}"` under `set -u` throws on bash ≤4.3 (fixed upstream in 4.4); first expert call is `jr_prep 6 expert-motion`. D21 as implemented does not fix this — macOS would still abort at the same point. Also M-1/M-2 (D21 entry overclaims CI proof for the 8 unreached bare-sed sites and the §5c sha256sum sites), M-3 (gate.sh:1120–1121 bare `sha256sum` — follow-up, out of D21 scope), 5 MINORs (per-job vs whole-log sed counts, +20 line shift, `sedi` `--` guard, loud-fill double-reporting, 3-file range note). What survived: diff scope, Darwin multi-`-e` form, all 18 `sha256sum` replacements, `sha256_file` correctness, `\x` bytes exact, lint/`bash -n` clean, §5c counts re-verified (103/126). Next: fix round (`jr_prep` + D21 entry corrections) after the independent QC verdict lands; then re-QC + re-red-team the fix. QC still running at this entry.
- 2026-11-13 01:24 UTC — MILESTONE: independent QC verdict FAIL (report in the coordinator's workspace), confirming the red team independently. The implementation code PASSED every QC check: scope exactly 2 files; all 14 sed + 18 sha256sum sites complete; helper unit checks run by QC; `bash -n` + exact lint grep clean; `./verify.sh --strict` run TWICE by QC: §5b 103 OK / 0 FAIL, §5c 126 OK / 0 FAIL / 1 UNVERIFIED (case 104 gitleaks half); CI-log claims verified (19 FAILs/job, 22×/4× sed errors as cross-job totals, §3b OK, 0 `cannot hash`); hygiene verified (identity, linear history, fork-only). FAIL reasons (same as the red team, found independently): SEVERE-1 — omitted fatal bash-3.2 abort (`jr_prep`, CI log lines 584/1189); SEVERE-2 — Defect 3 "these pass on the CI runners" is unobserved (cases (51)+ never ran); MEDIUM-1 — "ten bare sites fail compilation" presented as CI-proven (only the case-(27) pair observed); MINOR-1 — residual (c) calls `$1` "(unset)" without qualifying "when invoked with no arguments". Fix round dispatched (separate agent): `jr_prep` branch-on-kind fix + D21 entry corrections + GAP-15 proposal (gate.sh:1120–1121, M-3 follow-up, awaiting award — not implemented); then re-QC + re-red-team on the fix.
- 2026-11-13 01:29 UTC — MILESTONE: D21 fix round done (commit 2687d70, pushed to fork branch mie/mie-2-macos; identity verified). `jr_prep` fix (verify.sh:2975–2991): the `grader_args` array is gone entirely (grep confirms zero hits); branch on kind — expert branch calls node without `--grader judge-subagent`, non-expert branch with it; no empty array is ever expanded under `set -u` on any path; covers both `jr_prep 6 expert-motion` and `jr_prep 9 expert-ux`; `fail` message and log redirect byte-identical. D21 entry corrections: Defect 4 added (`jr_prep`, CI log lines 584/1189, base `verify.sh:2959`, cases (30)–(106) unexecuted); Defect 3 corrected to EXPECTED-to-pass / UNOBSERVED; Defect 2 corrected to per-job figures (11×/2× per job) with the eight unexecuted bare sites (cases 34, 35, 42, 66, 68, 69, 70, 72) marked as mechanism predictions; residual (c) qualified; new residuals (f) line shifts (+20/+8), (g) loud-fill double-reporting measurement note, (h) `sedi` `--` guard NOT added (BSD form unverified, no current call site affected). coord/mie.md: PROPOSED GAP-15 line (gate.sh:1120–1121, verified free; gate.sh NOT touched). Verification: `bash -n` passes on all five CI scripts; exact CI lint grep clean; local `./verify.sh --strict`: §5b 103 OK / 0 FAIL, §5c 126 OK / 0 FAIL / 1 UNVERIFIED — identical to baseline, no regression. Fresh re-QC + re-red-team launched (new agents, round 2); macOS proof (fork CI) still owed after they pass.
- 2026-11-13 01:37 UTC — MILESTONE: re-QC round 2 verdict PASS, no findings (report in the coordinator's workspace). Verified independently from primary sources on fix commit 2687d70 (exactly 3 files vs 6ffbe67): `jr_prep` fix — `grader_args` gone (grep: 0 hits), no array declared in the helper, branch predicate identical to base, both expert calls covered, token comparison proves expert line = base minus the grader token and non-expert line = base with the token in the same position, `fail` message + log redirect byte-identical (source lines sit 2 spaces deeper from nesting — Observation 1), bash-3.2-safe, ≤4.3 mechanism re-verified from upstream bash CHANGES 4.4-rc2 §3a and COMPAT item 54. D21 entry — Defect 4 citations read directly from the log (case-(29) OK at 583/1188 immediately before the abort, zero `RESULT:` lines, zero OK lines after), Defect 3 reworded (EXPECTED/UNOBSERVED, §3b OK at CI lines 412/1017, 0 `cannot hash`), Defect 2 per-job figures re-counted (11×/2× per job, 19 FAILs/job), eight bare sites each mapped to cases 34, 35, 42, 66, 68, 69, 70, 72; residuals (c) qualified, (f) shifts verified (+20, +8, +28 total), (g) consistent with the 4 adjuncts, (h) no `--` guard added and all 14 call sites pass absolute paths. GAP-15 free on main; gate.sh and coord/BOARD.md untouched. Independent re-run: `./verify.sh --strict` exit 1, §5b 103 OK / 0 FAIL, §5c 126 OK / 0 FAIL / 1 UNVERIFIED (case 104 gitleaks half); all 198 failures outside §5b/§5c explained. Regression spot-check: helpers intact (`sedi` 16 hits, `sed -i` only at :96/:98; `sha256_file` 20 hits). Hygiene verified (identity, linear history, fork-only). Darwin/bash-3.2 execution remains CHƯA ĐỌC — the fork CI macOS run is still owed. Re-red-team round 2 still running at this entry; no PR until it lands.
- PROPOSED GAP-15 | gate.sh:1120–1121 bare sha256sum with no shasum fallback (D9 vendored exemption never applies on a sha256sum-less Mac) | evidence: red-team d21-redteam.md M-3 | status: proposed, awaiting coordinator award — do not implement before award.
