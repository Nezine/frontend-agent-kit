# Buffet mode — runbook (one file)

> **Status:** milestone after the main push. Build order is binding: finish the phase-2 loop first (probe-4, judge-3, QC-2 + redteam-2, commit, push main), THEN build this milestone in the same repo. This runbook is written so any of the four agents can pick it up cold — no tribal knowledge, no human relay needed to start.
> **What buffet mode is:** the humans hand over a brief, leave the machines, and go eat. The agents run the frontend loop autonomously (code + design together, no human in the loop). The humans come back and edit/finish directly on the Figma the agents made — or directly on the built product.

## 1. Who does what

| Role | Who | Does | Never does |
|---|---|---|---|
| Coordinator | One agent per round — Muse holds the role in this run; the role may rotate between rounds, never mid-round. (P20, council-approved 2026-11-10.) | Owns the run sequence, `coord/BOARD.md`, the merge protocol, and the stop decision. Assigns slices, declares the run done. Is the ONLY merger (see §5). Owns the delegation contract (§5): no slice is dispatched until its `coord/TASK_TEMPLATE.md` fields are filled and its ownership row is on the board. | Does not write the page. Does not grade. Does not command the other three agents directly — coordination works by this runbook protocol, not by orders. |
| Builder | Any of the four, one instance per direction | Writes the one HTML file + `design/tokens.css`, tokens-first. | Never grades its own work. |
| Independent experts | The expert pack: `skills/frontend-kit/experts/` (typography, layout, colour, copy, imagery, motion, accessibility, design-systems, performance, responsive) | Judge ONLY their domain, from the artifacts (page + tokens + screenshots + gate result), never from the builder's reasoning. Advise; do not edit the build. | Never judge outside their domain; never see the builder's transcript. |
| Independent judge | `frontend-judge` (fresh sub-agent, no production history) | Grades 1–5 on Type / Layout / Colour / Space, one evidence line per score. Fallback: other-model judge → `muse-manager` judge → no grade ("gate green, vision not available"). | Never the builder; never a self-grade. |
| QC + red team | Independent QC agent + dedicated red team | QC verifies every claim against the primary source / built artifacts. Red team's only job is finding errors in others' work. One fabricated claim voids the submission — full redo, no patching. Red team has a second target: it challenges the process-learning team's findings, not just the build's output. | Never the builder or the judge of the same round. |
| Process-learning team | Independent subagents | Reads the run log + outside sources; proposes process improvements only. Never edits the loop, the skill, or a build directly — proposals go in its own `coord/` file. | Never writes to the repo directly; never edits the loop, the skill, or a build. |

The four agents in this run are **Muse, Mie, Migga, Milo**. Each owns exactly one file in `coord/` (see §3). A fifth agent joining later gets its own `coord/<name>.md` file and a row on the board — the protocol does not change.

## 2. The coordination channel (binding)

**The real coordination channel is the REPO (git).** Task board + handoff logs + run log live as files in this repo: `coord/BOARD.md` (coordinator-owned), one file per agent (`coord/muse.md`, `coord/mie.md`, `coord/migga.md`, `coord/milo.md`), and append-only `coord/run-log.jsonl`. GitHub is public, so every agent can clone/pull/push from any machine. This is the only channel all four agents can read/write without a human relay and without spamming anyone.

**The Optimus Messenger group is for HUMAN-FACING MILESTONES ONLY.** Short status lines a human can glance at from the buffet — e.g. "xong phần X, đang làm Y". No agent-to-agent coordination chatter in the group, ever: it floods the team chat, each message goes out as the human owner, and agents only see the group when pinged or during checks (no push, high latency, no addressing). Never use the group to assign work, debate a decision, report an error, or ask another agent a question — that goes in `coord/`.

**Mie cannot speak in the Optimus group at all — Mie's human owner is not an Optimus member. Do NOT propose adding Mie's human owner to the team group just for this.** Mie coordinates through `coord/mie.md` + the repo only. If a milestone needs to reach the humans, the coordinator (Muse) posts it.

**The coordinator cannot command the other three agents directly.** There is no order channel. Coordination works because all four follow this runbook: the coordinator writes assignments into `coord/BOARD.md`, each agent reads its own handoff file, does the slice, logs it, and the coordinator merges. If an agent disagrees with an assignment, it writes the objection in its own handoff file and keeps working on the last agreed slice — it does not stall the run waiting for an answer.

## 3. Where the work lives

- **This repo (the kit):** the skill, the loop, the runbook, `coord/`. Clone-and-go: `git clone https://github.com/phamTuan207/frontend-agent-kit.git`, follow the README paste-prompt, run `./install.sh` then `./verify.sh`.
- **The project being built:** `design/` (TASTE.md, tokens.css, demo.html, references/, screenshots/, variants/), `design/figma-ground-truth/` (frame PNG + context JSON + SOURCE.md), `design/figma-export/` (SOURCE.md + SKIPPED.md if the export was skipped), `design/run-log.jsonl` (the per-project run log — not the same file as `coord/run-log.jsonl`).
- **The Figma file:** one file per project, Pages 01 Cover / 02 Design System / 03 Screens (structure in §6). The Figma file URL + node IDs live in `design/figma-ground-truth/SOURCE.md` and `design/figma-export/SOURCE.md`.

## 4. The run sequence

**Trigger:** a human starts a buffet run with a brief + (optionally) a Figma file link, then LEAVES. The trigger names: the brief, the Figma link (or "none"), the target (landing / dashboard / redesign), and the return time. No human input is expected again until the return. Starting a run without a human present to answer OAuth is valid ONLY if Figma paths A/B are pre-seeded (exported JSON/PNGs already in the project) or MCP is already authenticated in that session; otherwise the run starts in Figma-degraded mode — it does NOT wait for a human.

0. **Setup:** create `design/` from `templates/design/` + `design/figma-ground-truth/` + `design/figma-export/`. Figma input in order: (A) native-export DTCG JSON → converter → `tokens.css` draft; (B) PAT one-shot import → PNGs into `design/references/` + token draft; (C) MCP read — ONLY on catalog hosts AND only after the user's Figma for Education status is confirmed. **A8 hard rule:** no Figma-derived value enters `tokens.css` or a grade unless its source output is saved under `design/figma-ground-truth/` with URL + version + access date. A value with no saved source file is fabricated; the round is invalid. On ANY Figma auth/quota failure: stop the Figma path, log the exact human step, continue WITHOUT Figma.
1. **Taste lock:** builder + experts advise; coordinator records the lock (`run-log.mjs lock`). `tokens.css` + references committed BEFORE any HTML.
2. **Build:** one HTML file, tokens only. Vague brief → 5 CSS-only variants; human-less pick uses the deterministic auto-pick (`variant-picker.mjs pick --auto`). Figma frames may INSPIRE a variant; a variant is never imported from a frame.
3. **Gate:** `impeccable detect` + gate scripts + html-validate/pa11y. FAIL blocks the round. NO Figma in the gate (no comparison tool exists); advisory Figma-baseline pixel-diff may be printed, never FAIL-blocking.
4. **Eyes + grade:** Playwright screenshots 1440/768/390; independent judge grades with evidence lines. If a Figma file exists: Figma-as-ground-truth — "Figma \<value\> vs built \<value\>" per score, from the CACHED ground-truth files (re-pull only on Figma version change). Mobile scores without a Figma frame say so explicitly.
5. **Fix top 2 as token diffs** (`tokens.css` first). Fixes NEVER go to Figma mid-loop.
6. **Stop + prepare the human gate:** stop at ≥4 on every axis AND gate green, or after 3 rounds per direction (max 2 re-picks, 9 rounds total). Best version kept across re-picks. The human-gate packet is PREPARED (score table + 3-width screenshots + questions + recommended next command) and the run ends in "awaiting human" state.
7. **Figma handoff export (once, after the loop stops):** export the shipped state to Figma (§6). If write-back is unavailable, write `design/figma-export/SKIPPED.md` (tool attempted, exact error, seat/host) and end the run successfully with the HTML/CSS artifacts.
8. **Return:** humans come back — see §7.

**Stop conditions:** (a) ≥4 all axes + gate green; (b) 3 rounds in a direction → re-pick (max 2); (c) 9th round ends regardless — present the best version; (d) Figma failure → degrade, do not stop the run; (e) QC/red-team SEVERE finding (fabrication, invented Figma data, builder self-grade) → run invalid, redo from the last valid lock, never patch over it.

**Parallelise the portfolio, not the loop (P23, council-approved 2026-11-10 — INTEGRATE, unanimous, clean).** Four agents are faster than one only if the parallel work is independent. The loop's steps are coupled — one agent's output is the next step's input — so they stay sequential; the portfolio around the loop is where parallelism pays.

| SEQUENTIAL — one agent, in order, per page | PARALLEL — across agents, at the same time |
|---|---|
| Taste lock → build → deterministic gate → grade → fix (the §4 steps, in order). No step starts until the previous step's artifact exists. | Different pages (each page runs its own sequential loop). |
| A fix round waits for its grade; a grade waits for its gate. | The 5 CSS variants (same content/copy/HTML, only CSS changes — §4 step 2). |
| The stop decision waits for the grade + gate of the current round. | Independent research angles (each angle is its own slice on the board). |
| | Expert-pack reviews — each expert judges ONLY its own domain, from the artifacts, in parallel (§1). |

The independent grader stays a separate role and **never grades its own branch** — a grader is a fresh sub-agent (or a different agent instance) with no production history of the build it grades (§1, §10). Parallelism never overrides that rule: if the only available grader built the branch, the grade is "gate green, vision not available" and the human gate carries the taste judgement.

Guardrails (direction, not a buffet-mode forecast): Kim et al. report **+80.8%** on decomposable tasks and **−70.0%** on sequential tasks when adding agents (v3 abstract, confirmed by the red team — SYNTHESIS §6 erratum E6; the primary, arXiv:2512.08296, is CHƯA ĐỌC — these figures are Kim et al.'s benchmarks, read via secondaries, not measurements of this loop and not a forecast for buffet mode). The loop above is the sequential case, so getting this table wrong makes buffet mode *slower* than solo. And Cognition's rule, attributed to Cognition (not to Kim): **don't add agents to a step that already works** — if a single agent already completes a step well, leave it alone.

## 5. Handoff protocol (how four agents work without talking)

**One file per agent, coordinator merges.** Each agent edits ONLY its own `coord/<name>.md` file and appends to `coord/run-log.jsonl`. NOBODY edits another agent's file. NOBODY edits `coord/BOARD.md` except the coordinator. `coord/run-log.jsonl` is append-only: NEVER edit a line already written — a stale or wrong record is superseded by appending a new record that says what it supersedes (P22). This is what makes concurrent work safe: there is no file two agents both write. Git is the transport in v1 — the repo is the coordination channel; there is no A2A/MCP layer (P22).

**Claiming work:** the coordinator lists open slices on `coord/BOARD.md` (one line per slice: id, brief slice, owner, status). An agent claims a slice by writing `CLAIM <slice-id>` + timestamp in its OWN file — never by editing the board. The coordinator merges claims into the board on its next pass. Two agents claiming the same slice: the earlier timestamp in the run log wins; the later one picks another slice.

**Delegation contract (P20, binding).** Every slice is dispatched with a filled `coord/TASK_TEMPLATE.md` — six mandatory fields: (1) objective, (2) output format, (3) tools/sources, (4) boundaries, (5) effort scale, (6) definition of done. **No board row is claimable until all six fields are filled** — an agent that finds an unfilled row writes `BLOCKED — template incomplete` in its own file and does not start. **Ownership before dispatch:** the coordinator fills the ownership table on `coord/BOARD.md` (file → agent → round) BEFORE dispatching, and **deterministically rejects claims on owned files** — a claim on a file another agent already owns for that round is refused, no judgement call, no negotiation; the claimant picks another slice. Why this exists: the largest measured failure category in multi-agent work is "system design issues" — **44.2% (MAST v3 Fig 1, summed per-mode shares)**. That number is SECONDARY-SOURCED (secondary summaries; the primary, arXiv:2503.13657, is CHƯA ĐỌC — never cite the figure as primary-verified). Retired wordings, never use: the "~42–44%" range (conflates paper versions) and "specification"/"FC1" as the category name (SYNTHESIS §6 erratum E2).

**Board states (P22, binding).** Every board row carries one explicit state — `submitted → working → completed / failed / canceled`, plus `input-required` for a slice that is blocked and needs input (the coordinator resolves it or escalates it to the human; the Notes column names whose input is awaited). The runbook's `coord/` scheme wins: there is no `board/` directory and no `STATE.md` — P22 contributes only this status column and the append-only rule above (council decision D3).

**Polling cadence (binding):** during an active buffet run, every agent runs `git pull --ff-only` **every 15 minutes** and reads `coord/BOARD.md` + its own handoff file. The coordinator merges + updates the board **every 30 minutes** (or immediately after a slice completes, whichever comes first). Between polls, agents work from their local copy and write only to their own file. A merge conflict on your own file: `git pull --rebase`, keep both entries, never delete the other side's lines — your file is append-mostly by construction, so conflicts should be rare; if one happens, keep everything and note it in the run log.

**Liveness — heartbeat folded into the cadence, no second cadence (P24, binding; council decision D5).** There is NO separate heartbeat schedule and NO extra commits for heartbeats. Each agent keeps one last-seen line at the top of its own `coord/<name>.md`, updated on its normal 15-minute pull (same commit as its other work, never a commit of its own):

`Last seen: <UTC timestamp> — task: <slice-id or —> — last commit: <short hash or —>`

On each 30-minute merge pass the coordinator sweeps the four last-seen lines: **stale >30 min with no commit = stuck** → the slice is marked `failed` on the board and is reassignable; **stale with recent commits = slow, leave alone** (do not reassign, do not nudge); **no heartbeat after 15 min = never started** (the agent has not picked up the run — the coordinator reassigns or escalates). The 10/15/30-minute numbers are DESIGN JUDGEMENT, not sourced — no published cadence exists for file-based agent liveness; tune them on the first buffet run.

**Branches (binding):** each agent works on its own branch `buffet/<name>` and pushes that branch. Only the coordinator merges branches into the buffet mainline (fast-forward or merge commit; never rebase someone else's branch, never force-push). Agents never push to the mainline directly. If push access is not yet granted for an agent, that agent works on a fork and opens a pull request — the coordinator merges the PR. (Whether the three other agents have push access is a human decision — see §9.)

**Trial merges — gate on the MERGED tree (P21, binding; council decision D4).** Before landing any two branches, the coordinator trial-merges the pair — never land on per-branch green alone:

```
BASE=$(git merge-base buffet/<a> buffet/<b>)
node scripts/trial-merge.mjs --base $BASE --a buffet/<a> --b buffet/<b> --worktree /tmp/trial-<a>-<b>
```

`scripts/trial-merge.mjs` runs `git merge-tree --write-tree` (exit 0 = clean, 1 = conflicts, 2 = usage/git error) and, with `--worktree`, checks the merged tree out into a detached worktree for gating. The gate runs ON the merged tree — `impeccable detect` + Playwright screenshots at 1440/768/390 — and the worktree is removed after (`git worktree remove /tmp/trial-<a>-<b>`). Record the merged tree OID in the run log so the gate run is traceable to the exact tree. The trial merge writes one tree object and never moves a branch. **Conflicts go to a neutral merger — a fresh-context agent, NOT the coordinator — capped at 1 attempt, then escalate to human-on-return.** "Rebase the rest" does not appear in this runbook and must never be added: the binding rule is "never rebase someone else's branch" (D4 wins over the proposal's wording). Scale note (SYNTHESIS §6 erratum E7): only **0.5%** of co-active pairs are cross-agent — **41.7%** is the conflict rate *given* a cross-agent pair, which is rare; treat the 41.7% as a warning about cross-agent pairs, not as the expected conflict rate for this run.

**Milestone posts to the Optimus group:** the coordinator posts a short status line ONLY when a milestone lands (loop stopped, Figma export done, human return complete, run invalid + redo started). One line, e.g. "xong vòng build, Figma đã xuất — đang chờ người về sửa". No coordination detail, no error dumps, no agent-to-agent messages. Mie never posts there.

## 6. Figma handoff (the shared design surface)

**Input paths (in order):** (A) native variable export (DTCG JSON → converter → `tokens.css`); (B) PAT one-shot import (frame PNGs → `design/references/` + token draft); (C) MCP read (catalog hosts only, Education-confirmed only). **Output (once, after the loop stops):** the shipped state exported to Figma — `use_figma` where available (it can create variables/components), `html_to_figma` only as a labelled flat snapshot.

**File structure the agents must produce (handoff check runs before the run is declared done):**

- **Page 01 — Cover:** project name, brief one-liner, run-log pointer (repo + run id), export date, limits note.
- **Page 02 — Design System:** variable collection "Tokens" (same names as `tokens.css` custom properties, 1:1); text styles (Display/H1/H2/Body/Mono); colour styles (one per token role); effect styles (shadows); components with Auto Layout (Button/Primary, Button/Secondary, Card, Nav, Section-Hero, Footer) — every fill/text BOUND to the Tokens variables and styles, never hard-coded hex. Token sheet frame: a visual specimen of every token.
- **Page 03 — Screens:** frames "Landing / Desktop 1440", "Landing / Tablet 768", "Landing / Mobile 390" (tablet/mobile only if drawn — never claim a desktop frame grounds a mobile score). Built from Page-02 components (instances, not detached copies). Layers NAMED (Hero/H1, Hero/CTA…) — no "Rectangle 47". Real copy, same assets as the built page. A pasted screenshot of the page inside a frame is a picture, not an editable design, and must be labelled as such.

**Handoff check (QC runs it):** (1) ≥10 spot-checked values in Page 03 bound to Page-02 variables/styles (any hard-coded hex = FAIL, fix or label); (2) no unnamed layers in Page 03 (spot-check); (3) Tokens names match `tokens.css` 1:1; (4) `design/figma-export/SOURCE.md` exists (file URL, node IDs, tool, seat, date, limits note). A file failing (1) ships ONLY as a labelled "flat snapshot" — never silently.

**Honest limits (in this runbook, not a footnote):** MCP write-back is beta, remote-only, needs a Full seat outside drafts, and will become usage-based paid at an unannounced price. `html_to_figma` gives plain layers, not components/variables. The Variables REST API is Enterprise-only. Figma has no comparison tool (never in the gate). Hermes / Muse Code / CommandCode are not in Figma's MCP catalog — Milo cannot use path C. Starter gives ~20 MCP reads/month. Figma edits never auto-update the running app.

## 7. Human return (what the humans do when they come back)

**Option R1 — edit in Figma, agents regenerate code.** The human edits variables/components/frames in Figma (Page 02 is built for this), then says one line: "Figma changed, regenerate". The agents: (1) re-pull Figma (A first — human re-exports the changed variable modes; B/C only if already set up); re-pull is human-triggered or version-triggered (Figma `version` changed since SOURCE.md), never on a timer. (2) Re-lock `tokens.css` (new lock entry; old lock kept in history). (3) Rebuild → re-gate → re-grade against the NEW Figma values. (4) Re-export to Figma. **What regenerates:** `tokens.css`, the HTML, ground-truth files, the score table. **What does NOT happen:** the running app does not auto-update — re-serve/rebuild the page and refresh the browser. Copy edits in Figma flow back only if the copy is in a text layer the agent re-reads; Figma components do not become code components automatically.

**Option R2 — edit directly on the built product.** The human edits `tokens.css` and/or the HTML directly (or describes the change in words). The change enters at step 5 (token diff) or step 1 (re-lock), then gate → grade → stop. This needs no Figma at all and is the fallback whenever Figma write-back is unavailable. **Never both on the same round without a re-lock:** if the human edited BOTH Figma and the CSS, the Figma re-lock wins for token values and the direct CSS edit is re-applied after, logged as a conflict in the run log.

## 8. Demo-day checklist

- [ ] Best version identified in the run log (scores + grader labels, all rounds).
- [ ] Gate green on the shipping version; 3-width screenshots (1440/768/390) saved as the pixel-diff baseline.
- [ ] Figma file exported (or `SKIPPED.md` written with the exact reason) and the Cover page states the limits.
- [ ] **A HUMAN holds a real phone for the live demo.** Agents cannot do this part: the live demo must run on a real phone (close the app fully, reopen it, run the main AI flow live) — a browser, emulator, photo, or video scores 0 on the demo criterion. The human holds the phone; the agents prepare everything else.
- [ ] The human has the runbook's §7 in front of them (what to edit, where, and what happens next).
- [ ] Milestone line posted to the Optimus group by the coordinator (one line, human-facing).
- [ ] Run log + board closed: every slice marked done or explicitly carried over, with the carry-over written in the board — nothing left as a silent open thread.

## 9. Clone-and-go + acceptance test

**Clone-and-go:** a fresh agent clones the repo, follows the README paste-prompt + `./install.sh`, runs `./verify.sh`, opens this runbook, and is working. No missing pieces, no tribal knowledge. Verified with a scratch-HOME run if possible; at minimum every file referenced by this runbook and the README must exist (the build worker checks this by listing them before inviting the other agents).

**Acceptance test for this milestone:** the other three agents — **Mie, Migga, Milo** — clone the repo and start working with no other setup. PASS = all three, cold, can (i) clone, (ii) run `./install.sh` + `./verify.sh` (or report the exact failure), (iii) open this runbook and find their role + their file + the merge protocol without asking a human, (iv) complete one assigned slice (one builder round / one expert review / one judge grade) with the run log updated. FAIL = any one of the three needs a human to explain a step, finds a referenced file missing, or cannot tell what to do next from the repo alone. Open item, NOT assumed: whether Mie, Migga, and Milo have GitHub push access to this repo (or work via fork + PR, §5). The coordinator records the answer here before the test runs: ______________________.

## 10. Hard rules (never optional)

- Tokens are committed before HTML. No exceptions. The gate runs before the grade. Every score has one line of observable evidence and a named independent grader label. A builder self-grade is FORBIDDEN.
- Max 3 rounds per direction; max 2 re-picks, 9 rounds total. Best version is kept; worse rounds are discarded.
- Human words become token diffs, never rebuilds. A degradation is labelled at every step. A missing capability is reported, never silently worked around.
- Never invent a version number, a file, or a behaviour you did not read. If a source cannot be read, mark it CHƯA ĐỌC and say so.
- Never copy secrets, tokens, or personal config from another machine. Never run `curl | bash` or an unpinned `@latest` installer. Figma OAuth/PAT steps are human-only: stop, report precisely what the human must do, resume after.
- No agent-to-agent coordination chatter in the Optimus Messenger group. The repo is the coordination channel. Mie never speaks there.
- Change control for process-learning proposals (binding): a learning-team finding goes to the red team for a refutation attempt. If refuted, it is dropped with the refutation logged. If NOT refuted, it goes to the COUNCIL (council rules 1/2/5 — full redo on slop, independent verification of every claim, dedicated red team); only after council approval is it integrated into the loop, the runbook, or the skill. Nothing the learning team proposes enters the kit without passing council. The learning team never writes to the repo directly — it writes proposals into its own `coord/` file.
