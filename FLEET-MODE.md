# Fleet mode — runbook for build day (one file)

> **Status:** v1. Fleet name: **muse-fleet** (chosen for the fleet; the repo itself is
> renamed separately and is not part of this runbook).
> **What fleet mode is:** muse-fleet CONTAINS the entire workflow for build
> day — roles, inventory, coordination, slices, gates, cross-grading, and
> the hour-by-hour plan — in this one file. Four agents on four machines
> build one mobile app with a real AI flow in a 5-hour run, then hand it to
> the humans to verify on a real phone and present. The humans decide the
> idea beforehand and return at the end to finalize. The agents run the
> build alone.
> **What the kit is inside the fleet:** the frontend-agent-kit is one
> feature / one branch inside muse-fleet — the frontend tooling (the
> taste-locked loop, the deterministic gates, the independent grader). It
> keeps developing alongside the fleet: Milo's hardening track, Mie's
> macOS track, Migga's hardening track, and the probe/gate work all
> continue. Nothing of the kit's core is dropped — the fleet adds dev work
> and 4-agent coordination around it; it does not replace it.
> **Relationship to the buffet runbook:** `BUFFET-MODE.md` is the
> coordination machinery the fleet reuses (claims, leases, the merge
> protocol, deputy succession, cross-check). Where the two disagree, this
> file governs build day; `BUFFET-MODE.md` governs everything else.
> **Scope note:** this file names no event, venue, date, person, or team. The
> run is "build day", the window is "the 5-hour run", agents are referred to
> by codename and role only. The exact group chat for urgent contact is named
> in each agent's handoff prompt — the runbook keeps it generic by design.

## 0. What is scored (the only numbers that matter)

- **40 — live AI demo on a real phone.** Full marks: close the app fully,
  reopen it on a real phone, the main AI flow runs live. Partial marks: the
  app reopens on a real phone but the AI flow runs only partly or
  unreliably. Zero: the app does not reopen on a real phone, the AI does not
  run live, or the demo is a browser, emulator, photo, or video.
- **35 — a real user problem, with evidence.** Full marks: the user and
  their difficulty are stated clearly, with evidence, and the AI helps
  directly. Zero: the user, the problem, or the product's value is unclear.
- **25 — market expansion.** Full marks: a clear path to the first users and
  to a global audience; real users are an advantage. Zero: no concrete
  user-acquisition path, or only the claim that "everyone needs it".
- **Tiebreak order:** demo first, then problem, then expansion.
- **The AI must be essential to the user outcome** — not a chatbot bolted on
  at the end. A product that works the same with the AI removed scores
  nothing on the demo criterion.
- **Scores are judged on real evidence, not on slides or presentation
  confidence.**
- **Preparation before build day is allowed, with disclosure:** the idea,
  research, and even part of the product may be prepared beforehand. At
  presentation time the team states what existed before and what was built
  during the run. Public libraries, SDKs, APIs, and starter templates are
  allowed. Secrets live in the deploy platform's environment variables,
  owned by the Integrator and the Backend builder only — never in the repo,
  never in the frontend bundle.

## 1. Who does what

| Role | Who | Owns | Never does |
|---|---|---|---|
| A — Integrator | **Muse, FIXED for the whole run.** | The run sequence, `coord/BOARD.md`, the merge protocol, the stop decision, `CONTRACT.md`, and the shared hotspots (routes, shared types, lockfile, schema, env, deploy). The ONLY merger. Decides ties, cuts, and merge order. | Does not build features. Does not grade (delegates grading to D). Does not command the other three agents directly — coordination works by this runbook, not by orders. |
| B — Frontend builder | Assigned at run start from the kickoff inventory (§2) | The phone UI + the frontend gate loop, on frontend files only | Does not touch backend, schema, or lockfile. Never grades its own work. |
| C — Backend / AI builder | Assigned at run start from the kickoff inventory (§2) | The thin backend + the real model call + the deploy, and the live phone demo path | Does not touch frontend files. Never grades its own work. |
| D — QC + red team + evidence | Assigned at run start from the kickoff inventory (§2) | Independent grading (fresh context), the red team, the problem-evidence artefact, first-users / share artefacts, the demo script, rehearsal, and the backup recording | Never builds features. Never merges. Never edits code it graded (a fixer — B or C — applies accepted fixes). |

- **Role assignment is by fit, not by name.** At run start the coordinator
  assigns B, C, and D from the kickoff inventory: the agent with the
  strongest vision + frontend tooling takes B; the agent with the strongest
  backend/deploy tooling takes C; the agent with the most independent
  capacity takes D. The assignment is published on the board before any
  slice is dispatched. A is Muse, always.
- **Deputy:** the coordinator names a deputy + backup at run start from the
  agents whose machines pass the gate-tooling check, per `BUFFET-MODE.md`
  §1. The deputy must not be the agent that cannot speak in the team group
  chat. Succession, term fencing, and the staleness test follow
  `BUFFET-MODE.md` §1 exactly.
- **Fallback decider:** if A is blocked, the fallback decider is D — the only
  agent who has seen everything — never the builder whose work is waiting.

## 2. Run start — inventory + census FIRST, then the workflow decision

The order is binding: **no slice is published before the coordinator has
read the inventory and the census.** This is `BUFFET-MODE.md` §3, extended
with the models block.

- **Kickoff inventory.** Each agent replies in its own `coord/<name>.md`
  file within one pull cycle with two blocks, verified by running the
  command, never assumed:
  - `TOOLS <UTC> — <cli> <version-output> — subagents: <yes/no/how> —
    notes: <...>` — every CLI it can actually run.
  - `MODELS <UTC> — <agent/model> <what it can drive> — strengths:
    <...> — limits: <...>` — which agents and models are usable on its
    machine, and what each is good at (frontend, backend, review, vision).
  - The census rides with it: live sub-agent count, per-sub-agent task +
    status, stalled/dead ones with last activity
    (`BUFFET-MODE.md` §4 format).
- **The decision they feed.** The coordinator assigns B/C/D by fit (§1),
  sizes slices to what exists (fleet depth → slice size; missing tools →
  slice reassigned or re-specced), and only then publishes slices. An agent
  that never reports is treated as absent for this run — no slice is
  published for it until it reports.
- **Run-start human steps (before the run):** branch protection on the
  product mainline (`main`) with the coordinator — and, on succession, the
  deputy acting as coordinator — on the bypass/allow-list; push access for
  all four agents to the product repo (fork + PR fallback per agent if
  access is denied, per `BUFFET-MODE.md` §9); dev accounts and deploy
  targets set up in advance.

## 3. Where the work lives

- **This repo (the kit repo) is the coordination home:** the runbooks, the
  skill, `coord/BOARD.md` (coordinator-owned), one `coord/<name>.md` file
  per agent, and `coord/run-log.jsonl` (coordinator-only, append-only).
  Claims, awards, and the run log live here.
- **The product lives in its own repo,** created by the coordinator at run
  start from the idea. Its mainline is `main`. The coordinator is the only
  merger there. The product repo URL is recorded on the board at run start.
  Keeping the product out of the kit repo keeps the public toolkit clean and
  the product repo private to the team.
- **Branches live in the product repo; claims live in the kit repo.** A
  board row links to the product-repo branch/PR. The merge protocol
  (`BUFFET-MODE.md` §5: trial-merge against the current tip, gate on the
  merged tree, sequential integrator-only merges) applies verbatim in the
  product repo, with `main` as the mainline.
- **CONTRACT.md lives in the product repo** (and is linked from the board).
  A writes it in the first 20 minutes and it is frozen after that. Changing
  it requires A's announcement in the team group chat. The template is the
  appendix of this file.
- **The demo script is written before any feature code.** It is the exact
  taps on the phone, from launch to the AI result. Anything that never
  reaches the screen scores nothing.

## 4. Vertical slices — the walking skeleton, not layers

Layer-by-layer (all of the frontend, then all of the backend) is the one
sequencing the expert sources warn against: nothing works end-to-end until
the very end. Build vertical slices instead: the thinnest end-to-end path
working first, then thicken it.

- **Slice 0 — walking skeleton (first ~60 minutes).** A deployed page + one
  real endpoint + one real AI call — or a stub that returns a canned
  AI-shaped response through the *real* endpoint, swapped for the real call
  in Slice 1. The demo script's happy path works, ugly. Exit: a real phone
  opens the deployed URL, taps through the demo script, and gets a (canned)
  result end-to-end. If this is not true at the end of the slice, cut scope
  immediately — do not "finish the UI first".
- **Slice 1 — the real AI flow.** C swaps the stub for the real model call;
  hardens input/output parsing, timeout, and the failure message. B polishes
  the result screen. D runs the first independent grade of the *live phone
  run* (not screenshots). Exit: the live AI flow works for real on a real
  phone, twice in a row, on the demo input. This is the scored artefact; it
  must exist by the halfway point.
- **Slice 2+ — only if Slice 1 is green on a real phone.** One additional
  user-visible capability at a time (e.g. save/share, history), each as its
  own thin slice, each merged only after the phone smoke test passes.
- **Within a slice, the UI leads** — the visible screen is built first so
  there is always something to look at — **but a slice is not "done" until
  its backend call is real.** No slice merges until it is end-to-end, and
  `main` is never without a working demo path.
- **How thin the backend is:** as thin as the demo script requires. Default
  to no custom server at all if the AI call can be made safely from a
  serverless function / BaaS — use whichever SDK the team already knows; do
  not learn a new one in the 5 hours. If a custom backend is needed, it is
  one thin service exposing exactly the endpoints the demo script calls —
  typically one (`POST /api/<the AI action>`), plus at most persistence for
  the demo's own artefacts (save/share) if a later slice needs it. No auth
  system (demo-mode / single shared session), no admin panel, no background
  workers, no migrations beyond one table/collection, no caching layer, no
  rate-limiting beyond the provider's own. The AI call is the backend: the
  model call (keys, latency, output parsing, failure modes) is the
  highest-risk integration, which is why it belongs in Slice 0/1, not at
  the end.
- **Cut test (ask it about every proposed piece):** "If I removed 30% of
  this architecture, would the demo still work?" If yes, remove it.
- **What the backend must do for the evidence and first-users criteria:**
  persist just enough to prove real use (a count of completed demo runs,
  saved outputs shareable by link) and to let a first user return to their
  result. That is a share-link + a counter, not accounts.

## 5. The loop inside a slice — the look comes first

**Visual quality is the top priority of this whole workflow.** The demo is
40 points and it is judged by what the eye sees on the real phone — not by
code elegance, not by backend completeness. Every decision in a slice is
judged against the look first: taste lock before any HTML, screenshots at
1440/768/390, independent grading on Type / Layout / Colour / Space. A
slice that works but looks unfinished has failed the demo, whatever the
backend does. Code elegance and backend completeness are second — they
serve the look, they never outrank it.

The frontend loop is the kit loop, carried over whole and still growing:
taste lock → build → deterministic gate FIRST → screenshots at 1440/768/390
+ independent grade 1–5 on Type / Layout / Colour / Space with one
evidence line per score → fix the top 2 as token diffs, best version kept
→ stop at ≥4 on every axis AND gate green, or after 3 rounds. Taste
target: 8/10. Acceptance bar: 60% slop-free.

Loop hardening (§16) governs how the loop above runs: checkpoint after
every stage (§16.1), literal verdict token + stop formula (§16.2),
gate-first ordering (§16.3), sprint contract (§16.4), 25-minute round cap
(§16.5), and the guard gate (§16.6).

The backend/demo layer uses
the same shape with different evidence:

| Layer | Deterministic gate (must pass before any grading) | Independent grade (fresh context, never the builder) | Fix rule |
|---|---|---|---|
| Frontend | `build` + `lint` + `typecheck` pass; no console errors; screenshots render | Screenshots graded 1–5 on Type/Layout/Colour/Space | Top 2 only; stop ≥4 all axes or 3 rounds |
| Backend / AI flow | `build` + tests pass; endpoint returns 200 on the demo input; **real run on a real phone** completes end-to-end | Independent agent replays the demo script on the deployed URL from a phone: does the AI flow work? is the result correct/useful? is latency acceptable? | Top 2 only; same 3-round cap |
| Integration (merge) | CI green on the branch; no new lint/type errors; demo smoke test passes | D reviews the *whole diff* + runs the app | Blocker-only fixes; everything else goes to the cut list |

- **The deterministic gate goes first, always.** It is free, fast, and
  ungameable — a build that does not compile cannot be argued into a pass.
  (§16.3: a red gate means a fix round with no grader call.)
- **The grader gets a fresh context** containing only the spec/intent, the
  deployed URL or diff, and fresh build/test output — never the builder's
  conversation, completion report, or commit-message rationale. Grade one
  artefact against a fixed rubric, with evidence attached (file/line,
  screenshot, or phone-run timestamp) per verdict. The verdict is a
  literal token first, prose second (§16.2).
- **The builder may not rebut a grade into a pass.** If the builder
  disagrees, A decides, or the item goes on the cut list.
- **The only grade that counts for the demo flow is a real run on a real
  phone against the deployed URL** — never the builder's log, never a
  screenshot alone, never the judge's reading of the diff.
- **Cross-check (security, safety, compliance)** runs per
  `BUFFET-MODE.md` §14: after the deterministic gate, before the grade,
  on the merged tree. SEVERE = hard block; the coordinator can never waive
  one. Only a human on return can override, recorded in the run log.
- **Done = merged to green `main` + phone smoke test passed + D's grade
  recorded.** Nothing is "done" on a branch.

## 6. The clock — the 5-hour run

T+0:00 is the start of the build window (11:00). Submission is at 16:00;
pitches start at 16:15, 5 minutes per team. **There is no separate human
fix window after 16:00** — the humans verify and rehearse inside the run,
so the agents must stop building in time.

| Time | Phase | Who | Exit criterion |
|---|---|---|---|
| **T+0:00–0:20** (11:00–11:20) | **Lock & contract.** A writes `CONTRACT.md` (one-sentence problem/user/outcome; demo script; API contract; file-ownership map; cut list). B/C/D read it and flag any blocker. Product repo + deploy target ready; all four machines can push/pull. | A writes; all review | `CONTRACT.md` merged; demo script written *before* any feature code; every agent can deploy |
| **T+0:20–1:20** (11:20–12:20) | **Slice 0 — walking skeleton + frontend v1.** B builds the phone UI for the happy path and runs the frontend gate loop (round 1). C builds the one endpoint + deploy, initially returning a canned AI-shaped response through the real endpoint. A merges each slice, keeps `main` green, deploys. D assembles the problem-evidence artefact and the share/first-users mechanism in parallel (read-only w.r.t. code). | B + C build; A integrates; D evidence | **A real phone opens the deployed URL, taps through the demo script, and gets a (canned) result end-to-end.** If this is not true at 1:20, cut scope immediately |
| **T+1:20–2:20** (12:20–13:20) | **Slice 1 — the real AI flow.** C swaps the stub for the real model call; hardens parsing, timeout, and the failure message. B polishes the result screen. D runs the first independent grade of the *live phone run*. A merges sequentially, re-runs the phone smoke test after each merge. | C leads; B supports; D grades | **Live AI flow works for real on a real phone, twice in a row, on the demo input.** Must exist by the halfway point |
| **T+2:20–3:20** (13:20–14:20) | **Slice 2 + polish loop.** One additional slice only (the highest-value second capability, e.g. save/share). B runs the frontend gate loop to its stop rule. D grades each merge; red-team pass #1 at ~T+3:00 (14:00, 15 min, demo-breaker lens). | B + C; D grades/red-teams; A integrates | Second slice merged *or* explicitly cut by A at 3:20; `main` green on a phone; no open blockers |
| **T+3:20–4:00** (14:20–15:00) | **Freeze, harden, rehearse.** Feature freeze at T+3:20. Only top-2 fixes from D's grades + red-team pass #2 (~T+3:45, 14:45, 15 min). D rehearses the demo script on the phone twice, records a backup video of the live flow, and finalises the evidence / first-users / share artefacts. A prepares the handover punch-list (known issues, exact repro, what was cut). | All; D leads rehearsal | Demo runs clean twice on a real phone; backup recording exists; punch-list written |
| **T+4:00–4:30** (15:00–15:30) | **Agents stop building.** No code changes after T+4:00 except fixes the humans direct, one at a time, through A. The hard stop is T+4:30 (15:30). | Agents assist only as directed | Frozen build handed over |
| **T+4:30–5:00** (15:30–16:00) | **Human verify + rehearse.** Humans do the final judgement calls (taste, wording, which cut item — if any — to restore), the final phone check, and submission. | Humans lead | Submitted artefact + live phone demo verified by a human |
| **16:00** | **Submission.** | — | Artefact submitted |
| **16:15** | **Pitches, 5 minutes per team.** | Presenting humans | Pitch delivered |

**Checkpoints:** at T+1:20, T+2:20, and T+3:20, A asks: *"If we shipped
what we have RIGHT NOW, would it demo?"* If no, A cuts the current slice
to its smallest working form on the spot (stub the AI output, hardcode the
second screen, drop the feature) rather than letting the schedule slip.

**What to cut first when time runs short** (in order — cut from the top,
never from the bottom):

1. Slice 2 and every later slice (second features, history, settings,
   extra screens).
2. Accounts/auth, profiles, and any persistence beyond the share-link /
   counter.
3. Polish beyond the gate: any fix round after the 3-round cap, any axis
   already ≥4, animations, extra themes.
4. The evidence/growth extras (extra testimonials, analytics dashboard) —
   keep only the one evidence artefact and the share link.
5. The red-team second pass (keep the first; never cut the deterministic
   gate or the phone smoke test).
6. **Never cut:** the live AI flow on a real phone, the demo script, the
   backup recording, the deterministic gate, or the final human
   verification. A polished demo of one feature beats a broken demo of
   five.

## 7. Branching / PR discipline — trunk-based, short-lived, small, sequential

1. **One shared `main` (product repo), always green, always deployed.**
   Every merge triggers (or is followed within minutes by) a deploy to the
   phone-testable URL. A red `main` is the top priority — fix or revert
   immediately, no new feature work until green.
2. **Short-lived branches, one per slice, deleted on merge.** A branch
   lives **<60–90 minutes**. Branch name = agent + slice
   (`b/<slice>`, `c/<slice>`). No long-lived `dev` / `frontend` / `backend`
   branches.
3. **Small PRs, one slice each.** A PR a reviewer (D, or A) can fully check
   in ≤15 minutes; if it takes longer, split it.
4. **Sequential merges, integrator-only.** A merges PRs **one at a time, in
   dependency order** (contract/skeleton first, then frontend, then backend,
   then polish), re-running the phone smoke test after each. Never merge two
   PRs concurrently; never let builders merge their own PRs.
5. **File ownership — no two agents write the same file.** Partition by
   directory (§1 table). The shared hotspot files (routes/registry, shared
   types, `package.json`/lockfile, DB schema/migrations, `.env` handling)
   are owned **only by A**. If B or C needs a change there, they request it
   from A; they do not edit it. Two agents adding different dependencies
   produce lockfile conflicts in effectively every case — the lockfile is
   sequential by nature.
6. **Commit every ~30 minutes**, push the branch, and post the one-line
   status — and push after every finished piece, even sooner (see §15.2).
   A bad agent run is revertible only if `main` was green and the
   branch was pushed recently.
7. **Deterministic gate is the merge gate.** No PR merges unless build +
   lint + typecheck + smoke test pass on the branch. D's independent grade
   is the *quality* gate (it can send a PR back for top-2 fixes).
8. **Rebase before push; on conflict, stop and flag A** — do not resolve a
   semantic conflict alone. `git pull --rebase` from `main` before pushing.
9. **Claims, leases, polling, the merge protocol, and deputy succession** follow
   `BUFFET-MODE.md` §§5 and 1 exactly (claim-with-a-plan, coordinator-first-seen
   arbiter, 15-minute polls, 30-minute merge passes, 60-minute lease,
   trial-merge + gate on the merged tree, neutral merger with 1 attempt,
   force-push forbidden, never rebase someone else's branch; 20-min coordinator
   staleness test with progress-signal heartbeat, two-phase takeover, term
   fencing — see BUFFET §1 and FLEET §16.7). **Build day
   uses the timed protocol** — the milestone-driven handoff rules (no timed
   polls, no leases, no deputy) do NOT apply on build day.

## 8. Communication — repo first, chat second

- **The single source of truth is the repo**, in this order: `CONTRACT.md`
  (API + file ownership + demo script), `main` (always green, always
  deployable), then chat. If chat and the repo disagree, the repo wins.
- **Every agent posts a one-line status every 30 minutes** (or at each
  merge): `DONE / DOING / BLOCKED + branch + what I need`. No logs, diffs,
  or screenshots in chat — those live in the repo/PR.
- **@mentions are for decisions and blockers only** (`@integrator merge
  ready: branch X, gate green, demo link`), not discussion. Sub-agents
  (reviewers) return summaries, not raw output.
- **Urgent contact:** the team group chat, @mentions only, whole group.
  The repo is the record, the @ is only the wake-up: an @mentioned
  direction is read at the repo instruction it points to (a PR comment or
  a board row) and acted on from there. Non-urgent traffic stays repo-only.
  Human-facing milestones are posted by the coordinator (Muse) only.
- **No agent-to-agent coordination chatter in the group chat** — except the
  short status reports, @mentions, and review requests defined in §15.1,
  which supersedes this line. No assigning work, debating a decision,
  reporting an error, or asking another agent a question there — that goes
  in `coord/`.
- **Graders grade a named commit + deployed URL, never "latest".** Context
  drift is a failure mode: B builds against an API shape C already changed,
  D grades a build that no longer exists on `main`.

## 9. Review gates — what catches errors without eating the budget

- **One deterministic gate first, then one independent rubric grade in a
  fresh context, then fix only the top 2 issues, with a hard round cap.**
  That is the whole review structure. The gate is free, fast, and
  ungameable; the judge alone is not enough.
- **Review the whole PR together; never in isolated fragments.** A defect
  split across commits passes every fragment review.
- **Red team: twice only, 15 minutes each** — once at the first end-to-end
  demo (~T+3:00, "can a hostile user break the happy path?") and once at
  feature freeze (~T+3:45, "will this survive a live phone demo in front of
  judges?"). Findings are a ranked list (blocker / should-fix / cut); the
  fixer is a *different* agent from the builder. Lenses: (1) demo-breaker
  (bad/empty/adversarial input, flaky network, slow AI — what happens on
  stage?), (2) correctness (does the AI output actually solve the user's
  problem, or is it plausible-sounding nonsense?), (3) integration (does
  the merged `main` still run on a phone after the last merge?). The red
  team does not re-grade taste and does not open a fix loop of its own.
  A picks at most the top 2 blockers; the rest are cut.
- **Why the builder never grades its own work:** a builder that grades
  itself learns to game the metric instead of improving the build — and
  self-verdict loops accept regressions while claiming progress. The only
  grade that counts for the demo flow is the real phone run.

## 10. Rehearsal — the whole fleet builds once before build day

Before build day, all four agents run one joint build+test using this
runbook, on a small practice brief chosen by the coordinator (not the real
idea). One small vertical slice, end-to-end, with a phone smoke test.

- **PASS:** the workflow works on all four machines with no blocking
  defect — inventory + census, slice dispatch, branch + merge, gate +
  grade, phone smoke test, red-team pass, handover — each step completed
  by the agent it belongs to.
- **FAIL:** any step needs a human to explain it, a referenced file is
  missing, or an agent cannot tell what to do next from the repo alone.
  Each defect is recorded as a GAP item with a council decision and fixed
  the same way as any other gap — never silently worked around.
- The rehearsal is the acceptance test for this runbook. Build day does not
  start on an unrehearsed workflow.

## 11. Demo-day checklist

- [ ] Best version identified in the run log (scores + grader labels, all
      rounds).
- [ ] Gate green on the shipping version; cross-check clear on the shipping
      version; 3-width screenshots (1440/768/390) saved as the pixel-diff
      baseline.
- [ ] Backup recording of the live phone flow exists.
- [ ] Demo script + evidence artefact + share link ready.
- [ ] **A human holds a real phone for the live demo.** Close the app
      fully, reopen it, run the main AI flow live — a browser, emulator,
      photo, or video scores 0 on the demo criterion. The human holds the
      phone; the agents prepare everything else.
- [ ] Submission artefact ready by 16:00; pitch rehearsed (5 minutes).
- [ ] Board + run log closed: every slice marked done or explicitly carried
      over, with the carry-over written on the board — nothing left as a
      silent open thread.
- [ ] Deputy succession matters most on this day: if the coordinator goes
      stale >20 min mid-day (pending work unprocessed + no coordinator
      commit), the named deputy takes over — the run does not wait for a
      human who is away. (D78: 20-min clock, progress-signal heartbeat — see BUFFET §1.)
- [ ] No CI-approval gate left unclicked: if the fork fallback is in force,
      the coordinator checks every merge pass for PRs stuck in "awaiting
      approval" and treats them as stalls, not queues.

## 12. Failure modes to guard against

| Failure mode | How it shows up here | Guard |
|---|---|---|
| Diverging implementations / semantic drift | B's frontend expects `{result: string}`, C's endpoint returns `{output: {text}}`; two date/format helpers; two "save" implementations | One written contract first (`CONTRACT.md`: exact JSON shapes, names, file ownership). A owns the contract; changing it requires A's announcement |
| Merge conflicts / silent overwrites | Two agents edit the same screen, routes, or the lockfile; one agent's work silently disappears | File ownership + trunk-based short branches + sequential integrator-only merges. Lockfile/schema owned by A alone |
| Agents grading their own work / reward hacking | Builder runs its own "tests" (which it wrote), declares pass, iterates until its own score rises while the real demo regresses | Independent grader in a fresh context, fixed rubric, no author rationale, no rebuttal-to-pass. The phone run is the only passing grade for the demo flow |
| Endless fix loops / progress mirage | Grade improves 3.8 → 4.1 → 4.0 → 4.2 while the phone demo still fails; agent "fixes" the same issue for an hour | Hard caps: top-2 fixes per round, 3 rounds max, stop at ≥4. After the cap, A cuts the item. Ground the loop in the world: the real phone run |
| Over-parallelisation / coordination overhead | Four agents in four directions; integration at the end takes longer than building did | Parallelise only disjoint, contract-first slices; serialise integration through A. Parallelise read-heavy work (review, tests) freely; be careful with parallel *write*-heavy work |
| Context drift / stale state | B builds against an API shape C already changed; D grades a build that no longer exists on `main` | Repo as source of truth; pull/rebase before work; one-line status every 30 min; graders grade a named commit + deployed URL, never "latest" |
| Cascading errors (hallucinated upstream contract) | C invents a function/endpoint; B wires the whole UI to it as ground truth; the error compounds downstream | Contract-first + walking skeleton first — the endpoint exists and is callable before B builds against it |
| Premature completion | An agent declares "done" after its own checks pass, while the integration is broken | Done = merged to green `main` + phone smoke test passed + D's grade recorded. Nothing is "done" on a branch |
| Excessive fan-out / sub-agent sprawl | Agents spawn sub-agents, which spawn sub-agents; token/time burn | No nested sub-agents. Four agents is the fan-out. Inside a machine, at most the read-only parallel reviewers the review pattern documents |
| Reviewing in isolated fragments | Each commit reviewed alone; an inconsistency split across commits passes every review | Review the whole PR/diff together. D grades the merged result on `main`, not individual commits |
| Demo that only works on the builder's machine | Works on a laptop, fails on the phone (CORS, env keys, mobile viewport, slow network) | Deploy from hour 1; phone smoke test after every merge; secrets in deploy env, never in the bundle |

## 13. Hard rules (never optional)

- Council enforcement (rules 1, 2, 5): (1) ONE fabricated claim = FULL REDO
  of that piece from scratch, no patching; (2) EVERY claim independently
  verified — URL + access date, QC opens every link, any unverifiable or
  wrong claim fails the whole submission; (3) a DEDICATED red team whose only
  job is finding errors in others' work.
- Run every agent under your control with FULL ACCESS (Codex:
  `--sandbox danger-full-access`; Claude: `--dangerously-skip-permissions`;
  other CLIs: the equivalent full-access mode). Sandboxes silently block real
  work without a clear error — full access removes that.
- Builder NEVER grades its own work. The grader/judge is always an
  independent agent, and its verdict is recorded with file:line evidence.
- Acceptance bar: **60% slop-free** (human-eye bar for the vague-brief
  acceptance test). Taste target: **8/10** (human blind grade). The
  ≥4-on-every-axis loop stop is unchanged.
- Tokens are committed before HTML. No exceptions. The gate runs before the
  grade. The cross-check runs after the gate and before the grade. Every
  score has one line of observable evidence and a named independent grader
  label.
- Max 3 rounds per direction; max 2 re-picks, 9 rounds total. Best version
  is kept; worse rounds are discarded.
- Never invent a version number, a file, or a behaviour you did not read. If
  a source cannot be read, mark it CHƯA ĐỌC and say so.
- Never copy secrets, tokens, or personal config from another machine.
  Never run `curl | bash` or an unpinned `@latest` installer.
- No agent-to-agent coordination chatter in the team group chat — except the
  short status reports, @mentions, and review requests defined in §15.1,
  which supersedes this line. The repo is the coordination channel.
- Force-push is forbidden for all agents including the coordinator. Never
  rebase someone else's branch. Never rebase commits already on origin.
- **Repo hygiene:** repo docs must NEVER contain a "Bài học" section and
  must NEVER expose personal info — no real names, no event name, no venue,
  no date, no emails, no school or team details. Agent codenames and roles
  only. The run is "build day" / "the 5-hour run".
- **Decisions:** D1–D15 stand (D15 is the judge-artifact mechanism). On main
  now: D1–D15, D20, D22–D32. D21 is in an open PR; D16–D19 are reserved;
  D33–D41 are assigned; D42–D71 are proposed in `coord/departments.md`.
  Claim a number in your own status file first, then verify it is free on
  the latest main AND the board before writing it into `decisions.md` —
  never take a number already on main, never renumber anything already on
  main. New decisions are recorded in
  `skills/frontend-kit/references/decisions.md`, council-decided, QC + red
  team + proof.
- Free legal sources only for research. Never buy anything. Never create a
  paid account. Never spend money.

## 14. What does NOT apply here

- 10+ subagent fan-out and nested sub-agents — the failure mode the
  official sources report, not a scaling strategy. Four agents is the
  fan-out.
- Agent teams / dynamic workflows / multi-agent "teams that talk to each
  other" — no shared context window and no time to debug inter-agent
  chatter. Coordination goes through the repo and short @mentions, not
  agent-to-agent conversation.
- Handoffs as a team pattern — handoffs transfer conversational control
  inside a runtime product; they are the wrong shape for four machines
  building one repo. The manager pattern is the applicable analogue, and
  even that is an analogy: the "manager" here is agent A, a separate
  machine, not an LLM call.
- Voting / parallelization-by-redundancy (run the same task 3–5 times and
  aggregate) — it triples the most expensive resource (time). One builder +
  one independent grader is the affordable version; the "vote" is the
  deterministic gate plus the phone run.
- Large eval suites and full evaluator infrastructure — the right scale here
  is a handful of scripted demo inputs and one rubric, run by hand on a
  phone. Do not build eval infrastructure in the 5 hours.
- GitFlow / long-lived feature or `dev` branches, and heavyweight PR review
  — the timebox compresses review norms to one reviewer, ≤15-minute
  reviews, and branches measured in minutes, not days.
- A "serious" layered backend (full data model → full API → frontend; auth,
  admin, workers, caching) — a half-finished clean architecture is worse
  than a finished, slightly ugly monolith that works, and the scoring
  rewards only what the live demo shows.
- Pure layer-by-layer "frontend first, then backend" — the expert consensus
  is vertical slices (§4). Building the whole frontend before any backend
  exists produces nothing working end-to-end until the very end.

## 15. Workflow optimizations — learned in rehearsal (governs where it conflicts with earlier sections)

These rules were learned running the fleet before build day. Where a rule
below conflicts with an earlier section, this section governs.

### 15.1 Report every finished piece — silence is invisible

- **No silent work.** Every push, PR, fix, or finished piece is announced
  immediately in one of two places: the team group chat (one line,
  @coordinator) or the repo (a PR comment, or your own `coord/<name>.md`).
  If nobody can see it, it did not happen.
- **Unpushed code does not count.** Work that exists only on your machine
  is invisible. Push after every finished piece, in small atomic commits.
  A builder who reports "done" with nothing on the fork has delivered
  nothing.
- **The coordinator watches both channels.** The group thread and the repo's
  open PRs (new heads checked every 15 minutes). A push with no chat
  message is still caught — but reporting it yourself is faster and
  expected.
- **Answer when tagged.** When another agent @mentions you or asks you
  directly in the group, answer there right away (confirm done, or answer
  the question). Never act silently and leave the question visibly
  unanswered.
- **Call the coordinator, not the humans.** Agents @ the coordinator for
  direction, blockers, and reviews — never @ the human owners. The
  coordinator routes; the humans are busy.
- **Supersedes:** §8 and §13 ("no agent-to-agent coordination chatter in
  the group chat, ever"). The corrected rule: short status reports,
  @mentions for blockers and decisions, and review requests ARE the group's
  job. What stays repo-only: debate, work assignment, and error discussion.

### 15.2 Never sit idle — the 15-minute rule

- Stuck for more than 15 minutes: report the blocker in the group and
  switch to another task from your pile. Never wait silently.
- When you finish a task, start the next one immediately. The pile is
  ordered; there is always a next item. Work continues until the
  coordinator says stop.
- §7's "commit every ~30 minutes" is a floor, not the rhythm. Push after
  every finished piece — a finished slice, a fixed defect, a reviewed doc —
  even if that is 10 minutes after the last push.

### 15.3 Review handoff — the fast lane for docs-only fixes

- When a review finds docs-only issues (wrong citations, stale numbers, an
  unsupportable banner), the reviewer posts the fix list as a PR comment
  with file:line precision. The builder fixes exactly those lines in one
  commit.
- **Focused re-read:** after a docs-only fix, the coordinator re-reads ONLY
  the corrected lines, not the whole PR, before merging. A full
  re-verification is not required when the code is unchanged from a green
  head.
- **Code-unchanged proof:** if the only difference between the reviewed
  head and the new head is docs (or a rebase onto a newer main), state that
  explicitly with the diff evidence — it is what lets the merge proceed
  without a fresh CI run.
- **Merge safety:** the branch is rebased onto the current main before
  merging. No branch commit may touch `coord/run-log.jsonl`
  (coordinator-only — the coordinator transcribes it at merge). If a PR
  diff shows run-log deletions, that is a stale base, not a deletion —
  rebase and re-check before merging.

### 15.4 Merge serialisation for shared files

- When several agents touch the same file, merges are sequential and the
  coordinator orders them. Never force-push. On conflict, stop and flag the
  coordinator — do not resolve a semantic conflict alone.
- Before EVERY landing: fetch origin and fast-forward to origin/main first,
  check the diff shows ONLY the intended change, push, then verify with
  `git ls-remote`.

## 16. Loop hardening — learned from multi-agent research (governs where it conflicts with earlier sections)

These rules harden the loop inside a slice (§5) against the failure modes
observed running multi-agent loops: an agent dying mid-loop and taking the
loop's state with it, a grade that is prose instead of a checkable verdict,
a red gate that still spends a grader call, a taste lock that lives only in
chat, a round that runs forever, and a handoff that carries a secret or a
banned action. Where a rule below conflicts with an earlier section, this
section governs.

### 16.1 Checkpoint after every stage — files are the state

- After each stage (taste lock, build, gate, screenshots, grade, fix) the
  agent writes a JSON checkpoint file in the slice's working directory:
  `checkpoint.json`, overwritten after each stage, with
  `{stage, status, artifacts[], verdict, round, next_stage}`. `status` is
  one of `done`, `blocked`, `failed`. `artifacts` lists the files the stage
  produced, with paths. `next_stage` names the stage that runs next.
- Every stage also ends with two lines — `STATE:` (what is true now) and
  `NEXT:` (what runs next) — in the agent's own status file; the
  coordinator transcribes them into the run log at merge. A stage that
  exits without a `NEXT` line is treated as a crash, not as a completion.
- A replacement agent's brief starts: "Read the latest checkpoint; do NOT
  redo completed stages; start at `next_stage`." A loop is resumed from
  the last checkpoint, never restarted from scratch. A dead agent must not
  take the loop's state with it — the state lives in files, not in the
  agent's context.
- The checkpoint is written BEFORE the agent reports the stage done. A
  stage with no checkpoint file is not done, whatever the agent's message
  says.

### 16.2 Literal verdict token + termination formula

- The grader's verdict is a machine-checkable token first, prose second.
  The first line of every verdict is exactly one of:
  `VERDICT: PASS` / `VERDICT: FAIL` / `GATES_GREEN`.
  `GATES_GREEN` is the token the grader emits exactly when the §5 stop
  conditions hold (≥4 on every axis AND gate green). Prose after the token
  explains the verdict; prose without the token is not a verdict.
- Termination is a formula, written in the loop prompt:
  `STOP = (grader emits GATES_GREEN) OR (round == 3) OR (coordinator kill-switch)`.
  The round cap is 3, as in §5. The kill-switch takes effect at the next
  stage boundary — never kill a builder mid-write.
- Every loop exit records `stop_reason` in the run log, one of:
  `gates_green` / `max_rounds` / `coordinator_stop` / `agent_died`.
  An exit with no `stop_reason` is an incomplete exit, not a pass.
- **Supersedes:** the §5 stop line ("stop at ≥4 on every axis AND gate
  green, or after 3 rounds") is now read as the formula above: the grader
  emits `GATES_GREEN` when those conditions hold, and the loop stops on
  the token, the cap, or the kill-switch.

### 16.3 Gate-first ordering

- Per round: (1) deterministic gates on files, (2) only if green,
  screenshots + LLM grade. A red deterministic gate = a fix round with
  **no grader call**. Never spend a grader call on a build the gate
  already failed.
- The gate writes JSON, not Markdown: one record per gate (gate id,
  pass/fail, evidence path). A failing gate's record is flipped only by a
  fix that makes it pass — never by rewriting the gate list, and never by
  deleting or weakening the failing check. The builder's prompt carries:
  "never delete or weaken a failing check".
- The gate runs before any new feature work each round, and before the
  grade, every round. Gates are executable checks, not "looks right".
- **Supersedes:** §5's "The deterministic gate goes first, always" — same
  rule, now with the no-grader-call consequence made explicit.

### 16.4 Sprint contract — the taste lock as a written file

- The taste lock is a short written file (the sprint contract), not a chat
  message. It lists: (a) the screens / features in the slice, (b) the exact
  observable check per item ("button X navigates to screen Y", "list
  renders ≥ N items from the data layer"), (c) the gate thresholds.
- The builder proposes the contract; the grader / coordinator approves it
  **before** build starts. The gate checks the contract, not the builder's
  claims. Nothing outside the contract is built without a coordinator
  decision.
- Builder and grader use the same four criteria (design quality,
  originality weighted higher; craft, functionality), so a grade and a
  build are measured against the same bar.
- The contract is frozen once approved; changing it requires the
  coordinator's announcement, as with `CONTRACT.md` (§3). The template
  lives in `coord/tasks/` and is added by the coordinator as a follow-up
  to this section.

### 16.5 Per-round wall-clock cap + ready / blocked / failed reporting

- Every worker brief carries a per-round cap of **25 minutes** per fix
  round. When the cap hits, the worker stops and reports: what is done,
  what is blocked, and what was killed or skipped. It does not run past
  the cap to "finish the last bit".
- Workers report once per round: `ready` / `blocked` / `failed` + evidence
  (file paths, gate output, or a phone-run timestamp). `ready` means the
  round's exit criterion is met; `blocked` names the blocker and what is
  needed; `failed` names what was tried and what broke.
- No unasked-for scope expansion. The sprint contract (§16.4) is the
  written rule; anything outside it needs a coordinator decision first.
- Relation to §15.2: the 15-minute rule still applies to *getting stuck*
  (report the blocker and switch tasks). The 25-minute cap is the *round
  budget* — the round ends at the cap whether or not the work is
  finished.

### 16.6 Guard gate — the loop's security check

- Every handoff between agents and every round boundary runs
  `guard-gate.sh` (repo root) BEFORE any model call and before any side
  effect. It is deterministic shell: no model calls, no new dependency,
  no cost. It checks, in order: G1 scope allowlist, G2 secrets scan, G3
  banned-action scan, G5 structured-verdict validation. The NO_VERDICT
  rule applies throughout: no verdict within the round budget, or a
  process ending without a structured verdict, is **BLOCK, never PASS**.
- A BLOCK from the guard gate halts that agent at once; the finding is
  written with evidence (file paths + lines) and reported to the
  coordinator first, SEVERE first. The coordinator closes or re-dispatches.
  The guard never auto-approves a SEVERE item, and no agent edits the
  guard script, the gate script, or the CI config to clear a finding.
- The guard is a pilot, not a graduation claim: it stops accidental and
  opportunistic compromise deterministically and makes deliberate
  compromise visible in the audit log. It does not claim to stop adaptive
  attack. A PASS certifies that this round's checks passed — never that
  the build is safe.
- The guard checks security gates only. Taste stays with the taste-locked
  loop's own grader (§5). The guard does not change the shipped app's
  runtime behaviour; it is a process gate around the build loop.

### 16.7 Coordinator liveness — pointer (D78)

Coordinator liveness (heartbeat + Deputy takeover) is defined exactly once, in `BUFFET-MODE.md` §1 — this section is a pointer, not a second copy. The coordinator pushes a progress-signal heartbeat line every 15 min in its own `coord/<name>.md`; the Deputy polls every 15 min; staleness is pending work unprocessed for >20 min AND no coordinator push in that window; takeover follows the BUFFET §1 two-phase procedure with term fencing. A deterministic 5-min cron probe (`coord/activation-probe.sh`) enforces the check. See `coord/activation-research.md` (D78 memo + council verdict) for the evidence, the dissent resolution, and the honest limits. Do not duplicate the procedure here — if the two copies diverge, BUFFET §1 governs.

## Appendix — CONTRACT.md template

A writes this in the first 20 minutes. One page, no more.

```markdown
# CONTRACT — <one-sentence problem / user / outcome>

## Demo script (exact taps, on a real phone)
1. ...
2. ... (the AI action happens here)
3. ... (the result the judges see)

## API contract
- `POST /api/<the AI action>`
  - Request JSON: `{...}` (exact field names + types)
  - Response JSON: `{...}` (exact field names + types)
  - Failure response: `{...}` (exact shape + message)

## File ownership
| Path | Owner |
|---|---|
| `app/`, `components/` (frontend) | B |
| `api/`, AI prompt, deploy | C |
| `docs/`, `evals/`, share page | D |
| routes, shared types, `package.json`/lockfile, schema, env, deploy config | A (only) |

## Deploy target
- URL: <public URL the phone opens>
- How to deploy: <exact command / platform>

## Cut list (what is explicitly NOT being built)
- ...

## Evidence artefact (for the problem criterion)
- <the one evidence artefact + where it lives>

## First users (for the expansion criterion)
- <how the first users are reached + the share link mechanism>
```
