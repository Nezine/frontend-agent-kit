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

## Milo handoff — ongoing development (from 2026-11-12)

> Coordination channel DECIDED by the user 2026-11-12 10:13: repo/git, buffet-mode pattern. This section is the handoff board; the buffet-run sections above still govern the build-day run only. Buffet-run rules (BUFFET-MODE.md §5 leases, 15-min poll, deputy succession) do NOT apply to the handoff — the handoff is milestone-driven (report at each milestone, no timed polls, no leases, no deputy).
> `coord/` is on main since the buffet-v2 landing (3c45950) — the "lives on the buffet branch" open item above is superseded; the directory now serves the buffet run AND this handoff.
> Milo works fork + PR (§9 FALLBACK — no push access yet; shared-repo branches primary only if/when Milo's owner's GitHub username is known and access is granted). Muse is the coordinator and the ONLY merger; BOARD.md is Muse-owned (no other agent edits it — ever).
> Milo's status lives in `coord/milo.md` (append-only, one entry per milestone; Milo never rewrites existing lines). Discussion lives in PR comments on Milo's PRs. Muse transcribes Milo's milestone entries into `coord/run-log.jsonl` at merge time. Human-facing milestones go to the team group chat, posted by the coordinator only — Milo never posts there.
> Claim rule for NEW items: Milo proposes in `coord/milo.md`; the coordinator awards it here (new row) before Milo implements. The M1–M3 rows below are pre-assigned to Milo by the user — no claim needed.

| Slice | Owner | Status | Expected-min | Files | Notes |
|---|---|---|---|---|---|
| M1 — Self-grading escape hardening | Milo | done | 480 | `skills/frontend-kit/**` (mechanism TBD by council), `references/decisions.md` (D15) | Highest priority. Mechanism (not just skill text) so a round cannot close on self-graded scores. Council → implement → QC → red team → live proof (Brief 1, escape attempt must be blocked). Handoff prompt delivered by the user 2026-11-12 (outside the repo). Council DONE 2026-11-12 (D15 judge-artifact mechanism — judge artifact `design/judge/round-<n>.md` + `judge-report.mjs` prepare + `run-log.mjs` cross-check); implementation LANDED 2026-11-12 as f4c701e (PR #2, fast-forward, 14 commits, identity verified). Coordinator live-verified on the PR branch: no-artifact 5,5,5,5 → exit 2; forged artifact → exit 2; land without round → exit 2; prepare→fill→record → exit 0 (judgeReport/judgeReportSha/pageSha stored); artifact reuse → exit 2; --evidence → exit 2. CI lint green x3; Install step red on pre-existing leg-2 fixture failure (11 FAIL / 4 WARN, identical on main) — M2 territory. Handoff-start PR #1 landed as 4e653ea (cherry-pick, author reset to phamTuan207 per identity rule). SCOPE CAP (user 2026-11-12 15:22): finish the frontend only, then stop — roughly done is enough, no over-perfection, save tokens, don't burn hard. |
| M2 — O4: verify.sh §5 fixture + browser discovery | Milo | done | 240 | `verify.sh` | Council-decide fix (conforming fixture / scope leg 2 out / fix discovery). Prove with fresh install + verify.sh (0 failures except host-state; §5b still 98). Investigation DONE 2026-11-12 (decision (a)+(c): conforming fixture + crop-sections-style discovery port; (b) rejected — re-opens GAP-11); implementation queued after M1 lands locally. (CAP LIFTED 2026-11-12 16:07 for M2 only — user delegated the CI choice to Muse; Muse asked Milo to implement (a)+(c) + the 3 D13 refusal edge cases from the CI log. M3 stays ON HOLD.) Implementation LANDED 2026-11-12 as a17a862 (PR #3, rebase merge onto a60cced, 9 commits, +571/−142; identity verified on the branch; ubuntu-only scope per 2026-11-12 23:02 — macOS stopped, sed fix dropped, macOS CI failures go to Mie; live D13 refusals 8/8; verify.sh --strict green; CI ubuntu-24.04 pass run 43232083472.) |
| M3 — Deferred design decisions (S1, H3, H5, moment-none) | Milo | working | 480 | `skills/frontend-kit/references/scroll-motion.md`, `scripts/gate/consistency.mjs`, `gate.mjs`, `references/decisions.md` (D16+) | Council-decide each with file:line evidence; implement; QC + red team; prove with gate runs. Investigation DONE 2026-11-12 (evidence packs for S1/H3/H5/moment-none; decisions D16–D19 at implementation); implementation queued after M2. (ON HOLD LIFTED 2026-11-12 23:05 — user approved M3 after M2 merges; M2 landed as a17a862, Milo notified to start M3 now, then stops.) |

## Mie handoff — ongoing development (from 2026-11-12)

> Coordination channel DECIDED by the user 2026-11-12 10:13: repo/git, buffet-mode pattern (same as the Milo handoff). Milestone-driven (report at each milestone, no timed polls, no leases, no deputy).
> Mie works fork + PR (§9 FALLBACK — no push access yet). Muse is the coordinator and the ONLY merger; BOARD.md is Muse-owned (no other agent edits it — ever).
> Mie's status lives in `coord/mie.md` (already on main with buffet-run content — Mie appends below a new heading `## Mie handoff — ongoing development (from 2026-11-12)`, never rewrites existing lines). Discussion lives in PR comments on Mie's PRs. Muse transcribes Mie's milestone entries into `coord/run-log.jsonl` at merge time. Human-facing milestones go to the team group chat, posted by the coordinator only — Mie never posts there (her owner is not a group member).
> Claim rule for NEW items: Mie proposes in `coord/mie.md`; the coordinator awards it here (new row) before Mie implements. The MIE-1–MIE-3 rows below are pre-assigned to Mie by the user — no claim needed.
> Decision numbers: D15 = Milo M1, D16–D19 reserved for Milo M3 — Mie's first decision is D20 (verify free on the latest main first).

| Slice | Owner | Status | Expected-min | Files | Notes |
|---|---|---|---|---|---|
| MIE-1 — Real-MacBook clone-and-go (Mie's MacBook) | Mie | submitted | 240 | `install.sh`, `verify.sh`, `skills/frontend-kit/**` (probe only, no code changes unless a gap is found) | Highest priority. THE remaining real-world check before the build-day run. Fresh clone of main on the MacBook → ./install.sh → ./verify.sh → full Brief-1 loop probe. Record chip (Apple Silicon vs Intel), macOS version, node version, install verify result, gate results, screenshots, grader. A gap found is recorded as GAP-13+ with evidence; implemented only after Muse awards it. |
| MIE-2 — Untested macOS bits | Mie | submitted | 480 | `install.sh`, `verify.sh`, `skills/frontend-kit/scripts/gate/**` | Verify (council-decide each if a fix is needed): curl-fallback darwin arms end-to-end, macOS Chrome warn path, OS-dispatch else-branch, `cmd skills list --debug` run. Intel macOS axes: only if the MacBook is Intel — if Apple Silicon, record N/A with reason, never claim Intel coverage. QC + red team + proof (live runs) for any fix. |
| MIE-3 — Buffet prep: MacBook TOOLS inventory | Mie | submitted | 60 | `coord/mie.md` (inventory section), `BUFFET-MODE.md` §2 | Per-machine TOOLS inventory for the MacBook (BUFFET-MODE.md §2): run every command, report exact versions. Feeds the build-day run (sequencing: inventory + census FIRST, then the workflow decision). Fleet kickoff also needs the MODELS block (FLEET-MODE.md §2): which agents/models the machine can drive, strengths + limits. |

## Migga handoff — ongoing development (from 2026-11-12)

> Coordination channel DECIDED by the user 2026-11-12 10:13: repo/git, buffet-mode pattern (same as the Milo handoff). Milestone-driven (report at each milestone, no timed polls, no leases, no deputy).
> Migga works fork + PR (§9 FALLBACK — no push access yet). Muse is the coordinator and the ONLY merger; BOARD.md is Muse-owned (no other agent edits it — ever).
> Migga's status lives in `coord/migga.md` (already on main with buffet-run content — Migga appends below a new heading `## Migga handoff — ongoing development (from 2026-11-12)`, never rewrites existing lines). Discussion lives in PR comments on Migga's PRs. Muse transcribes Migga's milestone entries into `coord/run-log.jsonl` at merge time. Human-facing milestones go to the team group chat, posted by the coordinator only — Migga never posts there.
> Claim rule for NEW items: Migga proposes in `coord/migga.md`; the coordinator awards it here (new row) before Migga implements. The MIG-1–MIG-3 rows below are pre-assigned to Migga by the user — no claim needed.
> Decision numbers: D15 = Milo M1, D16–D19 reserved for Milo M3 — Migga's first decision is D20 (verify free on the latest main first). D20 is shared with Mie: whoever reaches a decision first takes D20, the other takes D21 — claim the number in your own file first and check the board before writing it into decisions.md.

| Slice | Owner | Status | Expected-min | Files | Notes |
|---|---|---|---|---|---|
| MIG-1 — Clone-and-go on Migga's machine + TOOLS inventory | Migga | submitted | 240 | `install.sh`, `verify.sh`, `skills/frontend-kit/**` (probe only) | Highest priority. Buffet prep before build day. Detect OS first (Linux / macOS / Windows-WSL — kit supports Linux + macOS; if Windows, use WSL2 Ubuntu if available, else mark BLOCKED with exactly what's missing). Fresh clone → install → verify → Brief-1 loop probe. Record OS, chip, versions, results. TOOLS inventory (§2) for the machine. Fleet kickoff also needs the MODELS block (FLEET-MODE.md §2): which agents/models the machine can drive, strengths + limits. |
| MIG-2 — Install/verify polish wave (O1, O2, O3, O5, §2e anchor, L2) | Migga | submitted | 480 | `install.sh`, `verify.sh`, `skills/frontend-kit/SKILL.md` (O3 line only) | Council-decide each, implement, QC + red team, prove with fresh install + verify.sh. O1 gitleaks --no-same-owner container fix candidate; O2 hook/MCP PENDINGs; O3 --page must resolve inside design/ (one skill-text line); O5 stale "no system Chrome" WARN even with CHROME_PATH set; §2e anchor weakness (substring grep matches comments); L2 §2f anchor strengthening. |
| MIG-3 — Gate residuals (F6, L1 option (b), plugin-route spot-check) | Migga | submitted | 480 | `skills/frontend-kit/scripts/gate/**`, `verify.sh` | Council-decide each, implement, QC + red team, prove with gate runs. F6 mtime-touch forgery residual; L1 option (b) drop the clone exclusion from the sec_11 find — needs a false-positive check over the kit's own files first; plugin-route runtime spot-check (still owed from D13). |

## Fleet run — build day (muse-fleet)

> Runbook: `FLEET-MODE.md` governs build day (roles A–D, kickoff inventory
> with TOOLS + MODELS blocks, vertical slices, the 5-hour clock, rehearsal,
> demo-day checklist). `BUFFET-MODE.md` governs the frontend loop inside
> slices and the coordination machinery (claims, leases, merge protocol,
> deputy succession, cross-check). Build day uses the TIMED protocol
> (15-minute polls, 30-minute merge passes, 60-minute leases) — the
> milestone-driven handoff rules do NOT apply on build day.
> A = Muse, fixed. B (Frontend), C (Backend/AI), D (QC/Red-team/Evidence)
> are assigned by the coordinator at run start from the kickoff inventory
> (model + capability fit) and published here before any slice is
> dispatched. Coordination home is this repo; the product lives in its own
> repo, created at run start, mainline `main`, coordinator-only merger.
> Claim rule for NEW items: any agent proposes in its own file; the
> coordinator awards it here (new row) before implementation.

| Slice | Owner | Status | Expected-min | Files | Notes |
|---|---|---|---|---|---|
| FLEET-1 — Fleet runbook `FLEET-MODE.md` | Muse | completed | n/a (completed) | `FLEET-MODE.md` | Roles A–D, kickoff inventory (TOOLS + MODELS), vertical slices / walking skeleton, 5-hour clock (agents stop building 15:00, hard stop 15:30; submission 16:00; pitches 16:15), rehearsal, demo-day checklist. Fleet name muse-fleet noted; the repo rename is a separate pass. |
| FLEET-2 — Fleet rehearsal: 4-agent joint build+test | Unassigned (coordinator runs it) | submitted | 240 | — | All four agents, one small vertical slice end-to-end + phone smoke test, using FLEET-MODE.md, on a small practice brief chosen by the coordinator (not the real idea). PASS = the workflow works on all four machines with no blocking defect; defects become GAP items with council decisions. |
| FLEET-3 — Run start: product repo + access + CONTRACT.md | Muse (coordinator) | submitted | 60 | — | Create the product repo at run start, record its URL on the board, branch protection on `main` with the coordinator on the bypass/allow-list, push access for all four agents (fork + PR fallback per agent if denied), CONTRACT.md written in the first 20 minutes. |
