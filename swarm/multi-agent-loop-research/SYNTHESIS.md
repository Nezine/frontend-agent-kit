# Synthesis — Multi-Agent Loop Research: Ranked Integration Proposals

**Date:** 2026-11-13 · **Access date for all source claims:** 2026-11-13
**Sources:** 7 briefs in this directory (`anthropic-brief.md`, `openai-brief.md`,
`deepseek-brief.md`, `google-brief.md`, `frameworks-brief.md`,
`guard-security-brief.md`, `tomorrow-stack-brief.md`). Every claim below traces to
a brief section; the briefs carry the URL + access date per claim.
**Purpose:** what to integrate into FLEET-MODE.md / the kit / tomorrow's runbook
for the Codex Hackathon (Sat 14/11, build 11:00–16:00, demo on a real phone = 40/100).
**Constraints:** free-only $0.00; nothing paid; nothing that needs a new account.

## 1. Convergent findings — the same pattern, from independent sources

C1–C5, C7–C8 appear in **three or more** briefs independently. C6 appears in two
(Anthropic + OpenAI, both legs primary-confirmed) and is kept with that qualifier.
Convergence is the evidence; a pattern found in only one brief is not a convergence
finding — the tomorrow-stack checklist (formerly C9) is therefore listed separately
in §2 (H6/H7), not in this table.

| # | Pattern | Sources agreeing |
|---|---|---|
| C1 | **The driver owns the loop, not the agent.** Control flow (round counter, stage list, transitions) lives in coordinator code/prompts. Each agent invocation is one-shot, one stage. | Google 2.1 (ADK Sequential/Loop); OpenAI T1/T2 (code-orchestrated `while`, assistant message = termination signal); Anthropic T5/S6 (hard caps enforced by harness, not prompting); Frameworks T3/T6 (gate as post-step hook) |
| C2 | **Files are the state; checkpoint after every stage.** A dead agent must not take the loop's state with it. JSON checkpoint per stage; resume from the last checkpoint, never restart. | Anthropic T4 (files-as-memory, progress file + git); Frameworks T3 (CrewAI per-task JSON checkpoints, primary-confirmed; LangGraph checkpoint-per-superstep — secondary dossier only, official docs CHƯA ĐỌC); DeepSeek T1 (super-agent restart protocol, store-first); OpenAI T2 (deliverable = files on disk); Google 2.2 (named state keys / `output_key`) |
| C3 | **Literal verdict token + two-part termination.** Grader emits a machine-checkable token (`GATES_GREEN` / `VERDICT: PASS`); stop = token OR round cap OR coordinator kill-switch; record a `stop_reason` on every exit. | Frameworks T1/T2 (AutoGen `APPROVE`, `stop_reason`); Google 2.3 (ADK `escalate`/`PASS`); OpenAI T1/T13 (counted bound — the `max_turns` default-infinity point is Swarm-specific and Swarm is deprecated; the counted-bound point stands via T1) |
| C4 | **Builder never grades; the grader is separate, skeptical, and evidence-gated.** Same criteria for both, grader calibrated. Design rule (not a sourced finding): the grader works from the artifact + gate output, not the builder's working notes — no primary source states grader blindness; Anthropic S3 gives the same criteria to both agents (red team F4). | Anthropic T1 (skeptical evaluator, few-shot calibration, S3 criteria); Google 2.4 (generator–critic split, checklist rubric); OpenAI T3/T7 (agents-as-tools, separate evaluator); Frameworks T1 (AutoGen reflection, independent critic) |
| C5 | **Gate first, deterministic gates before any LLM grading.** A red deterministic gate = fix round with no grader call. Gates are executable checks, not "looks right". | Anthropic T3 (gate first, JSON gate file, never weaken a failing check); OpenAI T6 (code orchestration more deterministic); Frameworks T6 (post-step hook decides whether the step counts); DeepSeek T6/T10 (final-output checks alone cannot prove success; cheapest-first verification) |
| C6 | **Freeze prompts and gates mid-sprint; improve the harness only between runs.** One change at a time, measured on a held-out task. | Anthropic T8/N6 (S2 principle 5, S3 one-component-at-a-time); OpenAI T8 (static prefix first, never mutate). 2-source finding: the DeepSeek leg is an analogy, not a stated rule — DeepSeek T4 ("act only when asked, or when a written rule allows it") is a scope rule, not a prompt-freeze rule (red team F2). |
| C7 | **Structured, compact handoffs; one agent = one round; Ticket discipline.** Self-contained briefs, `ready`/`blocked`/`failed` reporting, no scope expansion beyond the written rule. | OpenAI T4/T9 (self-contained brief, fresh context per round); Anthropic T10 (summaries 1,000–2,000 tokens); Google 2.6 (agent cards + task states, `input-required` instead of guessing); DeepSeek T2/T4 (one Ticket = one worker + one directory; act only when asked or when a written rule allows) |
| C8 | **Guard = containment + least privilege + Rule of Two, not filtering.** Prompt injection is unsolved; cap what a fooled model *can* do. Fail closed: no verdict = BLOCK. | Guard brief §1 (§1.1 Nasr et al. >90% bypass of 12 defenses; §1.3 containment; §1.5 Rule of Two; §2.4 NO_VERDICT rule); Anthropic N8 (harness-enforced caps, never prompt-only); Google 2.8 (model proposes, runtime disposes); OpenAI T12 (guardrails fail fast, before the build) |

## 2. Ranked integration proposals

Ranking criteria: (a) increases tomorrow's automation, (b) does NOT lower success
probability, (c) effort fits before 20:00 tonight, (d) free-only $0.
Effort is wall-clock for one person (or one agent) unless noted.

### HIGH — do before 20:00 tonight

| # | Proposal | What exactly | Effort | Integration point | Owner (suggested) |
|---|---|---|---|---|---|
| H1 | **JSON checkpoint after every stage + resume-from-checkpoint rule** | After each stage (taste lock, build, gate, screenshots, grade, fix) the agent writes `{stage, status, artifacts[], verdict, round, next_stage}`. A replacement agent's brief starts: "Read the latest checkpoint; do NOT redo completed stages; start at `next_stage`." Every stage also ends with `STATE:` + `NEXT:` lines in the run-log; a stage exiting without `NEXT` is treated as a crash. | ~30 min | FLEET-MODE.md §5 (loop) + loop prompt template | Coordinator (Muse) — edits FLEET-MODE.md |
| H2 | **Literal verdict token + termination formula + stop_reason** | Grader verdict is a machine-checkable token first, prose second: `VERDICT: PASS` / `VERDICT: FAIL` (or `GATES_GREEN`). Termination written as a formula in the loop prompt: `STOP = (grader emits GATES_GREEN) OR (round == 3) OR (coordinator kill-switch)`. Every loop exit records `stop_reason` in the run-log: `gates_green` / `max_rounds` / `coordinator_stop` / `agent_died`. Kill-switch takes effect at the next stage boundary — never kill a builder mid-write. | ~15 min | Grader prompt + FLEET-MODE.md §5 + run-log schema | Coordinator |
| H3 | **Gate-first ordering** | Per round: (1) deterministic gates on files, (2) only if green, screenshots + LLM grade. A red deterministic gate = fix round with **no grader call**. Gate JSON (not Markdown): flags flipped only, never rewrite the list; builder prompt carries "never delete or weaken a failing check". Gate runs before any new feature work each round. | ~15 min | FLEET-MODE.md §5 (reorder loop steps) | Coordinator |
| H4 | **Sprint contract (taste lock as a written contract)** | The taste lock becomes a short written file listing (a) screens/features, (b) the exact observable check per item ("button X navigates to screen Y", "list renders ≥ N items from Convex"), (c) gate thresholds. Builder proposes it, grader/coordinator approves it **before** build; the gate checks the contract, not the builder's claims. Same four criteria for builder and grader (design quality, originality weighted higher; craft, functionality). | ~20 min | FLEET-MODE.md §5 + contract template in `coord/tasks/` | Coordinator |
| H5 | **Minimal shippable guard: G1+G2+G3+G5 + NO_VERDICT rule** | One shell script (`guard-gate.sh`, ~100 lines) run at every handoff and round boundary: G1 scope allowlist, G2 secrets scan, G3 banned-action scan, G5 structured-verdict validation — plus the NO_VERDICT rule (no verdict within round budget, or process ends without a structured verdict = BLOCK, never PASS). Add G4 regex injection scan second, G0 provenance labels third if time allows. Includes the 6-probe 15-minute red-team smoke test before 11:00. $0, no extra model calls. | 30–45 min | New file `guard-gate.sh` + guard section in FLEET-MODE.md | Coordinator (or one fleet agent, if the coordinator is busy with H1–H4) |
| H6 | **Tomorrow-stack Tier S (before 11:00 / first hour)** | S1 read live Gemini limits in AI Studio for the actual project (human-only; decides the whole AI budget); S2 freeze `eas.json` + preview env (`"environment": "preview"`, `EXPO_PUBLIC_CONVEX_URL` verified by `eas env:list`); S3 Convex deploy + seed + read-back (`npx convex data` shows rows, not just exit 0); S4 Supabase function deploy + secret-presence probe (one real-AI curl only after the stub passes); S5 first preview APK build started by ~12:30 (`--non-interactive --wait --json`, never `--no-wait`). | ~60 min across tonight + first hour | Tomorrow's runbook (`coord/tasks/`) + human steps tonight | Humans (keys/projects/phone) + coordinator (scripts) |
| H7 | **Two-429 handling + visible call-budget counter in the Edge Function** | Parse `quota_exceeded`/`PerDay` vs `rate_limit_exceeded`/`PerMinute`: per-minute → backoff 1s→2s→4s + jitter, max 3, then Groq; per-day → **never retry**, fail over to Groq/stub immediately (retries burn the daily budget). **Sourcing note (red team F5): the code split is secondary-sourced (continuumcode.ai quoting Google's api-errors doc; the primary api-errors page is CHƯA ĐỌC), and `limit: 0` is an unverified heuristic — treat as unconfirmed; confirm against the first live 429 or ai.google.dev/api-errors before the sprint. Do not present the parse rules as Google-published.** Convex counter incremented per provider call; UI footer shows `LIVE (Gemini)` / `FALLBACK (Groq)` / `STUBBED`. Must be coded and tested **tonight** (before 20:00) or it becomes tomorrow-morning work. Overlaps Milo's Backend track (D49–D52) — fold in, do not duplicate. | 30–60 min code + test | Skeleton: `supabase/functions/ai/index.ts` + Convex counter + UI footer (buffet/main) | Milo (Backend track) — coordinator to confirm scope |
| H8 | **Per-round wall-clock cap + ready/blocked/failed reporting** | Every worker brief carries a per-round cap (25 min per fix round) after which the worker must report what is done, what is blocked, and what was killed/skipped. Workers report once per round: `ready` / `blocked` / `failed` + evidence. No unasked-for scope expansion; the taste lock is the written rule, anything outside it needs a coordinator decision. | ~10 min | Worker brief template + FLEET-MODE.md §5 | Coordinator |

Total HIGH effort: ~3–3.5 hours, mostly coordinator writing (H1–H5, H8 ≈ 2h) plus
Milo's H7 code (30–60 min) plus human Tier-S steps (H6, tonight). Fits before 20:00
if sequenced: H1–H4 + H8 first (loop rules), H5 guard script second, H7 in parallel
by Milo, H6 human steps tonight.

### MEDIUM — do if the HIGH set is done and time remains before 20:00

| # | Proposal | What exactly | Effort | Integration point |
|---|---|---|---|---|
| M1 | **Grader few-shot calibration** | Before the sprint, feed the grader 2–3 scored examples (a good screen, a slop screen, a broken screen) with the score each should receive and why. Cheapest calibration available; Anthropic needed several rounds of it before the evaluator graded reasonably — so do it before the sprint, not during. | ~30 min | Grader prompt (examples appendix) |
| M2 | **Agent cards + task states (A2A-shaped file contract)** | One-page card per assistant (name, skills with input/output file paths, won't-dos) + a `status` field on every handoff (`submitted → working → completed / failed`, plus `input-required` with one specific question instead of guessing). Terminal states are terminal — a `completed` handoff is never re-edited in place. (Secondary explainer only — canonical A2A spec CHƯA ĐỌC; do not cite A2A spec details as spec fact. Red team F6.) | ~30 min | `coord/` cards + handoff template |
| M3 | **Trajectory grading (grade the trajectory AND the response)** | Grader checks a short trajectory list first (gate ran before screenshots: yes/no, evidence: gate log file) and fails the round on a trajectory violation even if the artifact looks fine. Rubric = yes/no items with cited evidence; no free-form scores. Fix-top-2 = the two failed rubric items with highest severity. Grading dimensions may fan out in parallel (one-shot agents, unique verdict files, grader synthesizes) — the build itself stays sequential. (Brief-attested only — the ADK eval pages were not re-opened by the red team; re-verify criteria.md before citing, or do a 5-minute re-check before FLEET-2.) | ~20 min | Grader prompt (trajectory checklist) |
| M4 | **JSONL gate log (`gates.jsonl`)** | One row per gate per round (gate id, pass/fail, evidence path). The coordinator's stop decision reads the table, not a chat message. Past failing cases kept as regression rows for the next sprint. | ~20 min | Run-log schema (`coord/run-log.jsonl` + gate table) |
| M5 | **Maestro kill-reopen flow, conditional** | Flow file + `maestro test` run, **only if Maestro is installed and green before 12:00**; otherwise drop to the adb script (`adb install -r`, `force-stop`, `start -W -n`), then to the paper manual checklist. testIDs on every interactive/asserted element (cheap if added as you go, expensive as retrofit). (Maestro claims rest on a third-party skill doc — secondary; keep the 12:00 drop-deadline.) | ~30 min setup | `maestro/kill-reopen.yaml` + adb script |
| M6 | **Guard G4 + G0 (second wave)** | If H5's reduced set is in and time remains: add G4 regex injection scan (quarantine, not auto-block) and G0 provenance labels (three-line header the coordinator pastes by hand). | ~20 min | `guard-gate.sh` + handoff envelope |

### LOW — explicitly NOT for tomorrow (deferred or rejected)

| # | Proposal | Why not tomorrow |
|---|---|---|
| L1 | Supervisor/router agent, peer-to-peer agent messaging, multi-agent debate/voting | The briefs recommend against these for this 5-hour sprint: fixed sequential pipeline, coordinator as single point of control. (The sources themselves document router/coordinator patterns as valid elsewhere — Anthropic S2, OpenAI multi-agent docs, Google ADK pattern #2 — so this is a sprint recommendation, not a unanimity claim.) A router LLM call per stage costs tokens/latency and can misroute; peer messaging removes deterministic control. (Frameworks T4, Anthropic N4, DeepSeek N7, Google §3) |
| L2 | Harness self-improvement mid-sprint (agents rewriting prompts/gates) | Improvement happens **between** runs, one component at a time, measured on a held-out task. Mid-sprint self-modification is an uncontrolled change to the deterministic loop. Post-hackathon only. (Anthropic T8/N6) |
| L3 | Adopting any framework runtime (LangGraph, AutoGen, ADK, Agent SDK, `dsh`, Swarm) | Patterns, not code. Every brief agrees: adopting a runtime mid-sprint costs the sprint and (for the paid ones) breaks the $0 budget. (All briefs §3) |
| L4 | Full CaMeL / VM sandbox / classifier guardrails / per-action HITL | Does not fit a 5-hour $0 sprint; the pilot guard (H5) is the shippable subset. (Guard brief §3) |
| L5 | Parallel fan-out of the build; multi-agent research-style scale-up (10+ subagents, the +90.2% claim) | Build is sequential and interdependent; the +90.2% gain is research-only at ~15× tokens with inverted economics for us. Only grading dimensions may fan out (M3). (Anthropic N1/N2, Google 2.5) |
| L6 | OpenAI Evals platform, fine-tuning, prompt caching as a feature, hosted sandboxes | Evals platform is read-only since 31 Oct 2026 and shuts down 30 Nov 2026; the rest is paid/hosted. Take only the shape (dataset + graders, T10) locally as JSONL. (OpenAI N3/N4/N12) |
| L7 | CaMeL-style deterministic provenance gating of the shipped app's runtime input | Out of scope for the loop guard; the shipped app reading untrusted user input at runtime is a post-hackathon hardening task. (Guard brief §2.7/§3) |

## 3. Automation vs success — where supervised beats fully automated

Stated explicitly, because the whole point of the ranking is that a fully
automated loop that fails is worse than a supervised one:

1. **Kill-and-reopen verification is human-by-eye, twice.** No script result
   substitutes for a human seeing the reopened app on the real phone — once after
   install, once 10 minutes before the pitch. This is the 40-point gate.
   (Tomorrow-stack B3.)
2. **The 16:00 submit is the single human-in-the-loop point.** No human approval
   inside the loop (it would stall the sprint); everything else — including a
   `FAIL` verdict on round 3 — is handled by the driver and the agents.
   (Google 2.9.)
3. **STUBBED vs LIVE vs Groq for the pitch is a human judgement call** from the
   live AI Studio numbers + remaining budget. A script cannot weigh "judges value
   a live call" against "we have 2 calls left". (Tomorrow-stack C1.)
4. **A guard that auto-approves is worse than a supervised one.** Approval
   fatigue is measured (93% auto-approve); per-action HITL inside the sprint
   reproduces that failure. The guard blocks deterministically and the
   coordinator clears HIGH/SEVERE items — it never auto-approves them.
   (Guard brief §1.10, §2.5.)
5. **Do not debug a test harness after 12:00.** If Maestro is not green by then,
   drop it for the adb script, then the paper checklist. A flaky "verification"
   is worse than manual verification. (Tomorrow-stack A3/A4, P23.)
6. **A fully automated loop with no checkpoint is worse than a slower
   supervised loop with checkpoints.** The probe-4 yield death killed loops
   that had no durable state; H1's checkpointing costs ~30 min to write and
   saves whole rounds. Automation without durability is the failure mode, not
   the goal.

## 4. Suggested sequencing before 20:00 tonight

1. H1–H4 + H8 (loop rules + contract + caps) — coordinator, ~1.5 h, FLEET-MODE.md.
2. H5 guard script + smoke test — coordinator or one agent, 30–45 min.
3. H7 two-429 + counter — Milo, in parallel with (1)–(2), 30–60 min.
4. H6 human steps — the human owner + team tonight (AI Studio limits, projects/keys, phone check).
5. M1–M6 only if (1)–(4) are done and time remains.
6. 20:00 FLEET-2 rehearsal validates the whole set on the practice slice.

## 5. Caveats — what bounds these proposals

- **CHƯA ĐỌC items that must not be encoded as fact:** Google A2A canonical spec (a2a-protocol.org) — CHƯA ĐỌC, A2A claims rest on the restfulapi explainer; LangGraph official concepts docs — CHƯA ĐỌC (secondary dossier only); DeepSeek-R1 full text — CHƯA ĐỌC; Google SAIF PDF tail (§05) — CHƯA ĐỌC; EAS free build quota numbers — CHƯA ĐỌC; Groq gpt-oss-120b limits — secondary sources only.
- **Corrected (red team F8): OpenAI SDK guardrail scoping rules are VERIFIED, not CHƯA ĐỌC** — the guard brief read the page and the red team re-verified every rule on the primary page (input-first-agent-only, output-last-agent-only, tripwire names, handoffs excluded); the openai-brief's CHƯA ĐỌC status for this page was stale.
- **Google removed per-model free-tier RPM/TPM/RPD tables (removal confirmed on the AI Studio page; the "August 2026" date is secondary-only, via continuumcode.ai).**
  The widely quoted "15 RPM / 1,500 RPD" and the "~20 calls" cap are not
  Google-published numbers; the only authority is AI Studio's Rate Limit page
  for the actual project (H6/S1).
- **The GUARD pilot is NOT a graduation claim.** GUARD graduation stays BLOCKED
  pending red-team verification and a CI gate (guard brief §2, §5).
- **No proposal here requires a paid account, a new account, or a model swap.**
  The stack stays Gemini free tier primary + Groq fallback.

## 6. Tóm tắt tiếng Việt (Vietnamese summary)

Đã đọc 7 brief (Anthropic, OpenAI, DeepSeek, Google, LangGraph/AutoGen/CrewAI,
Guard/Security, stack ngày mai) và rút ra 8 điểm đồng thuận + 1 checklist stack ngày mai (1 nguồn): (1) vòng lặp phải nằm
ở driver/coordinator, không nằm trong agent; (2) state phải lưu ở file, checkpoint
JSON sau mỗi stage — đây là cách sửa trực tiếp lỗi probe-4 (agent chết là mất vòng
lặp); (3) grader phải trả verdict dạng token máy đọc được (`GATES_GREEN` /
`VERDICT: PASS`) và luật dừng viết thành công thức + ghi `stop_reason`; (4) builder
không bao giờ tự chấm, grader độc lập và hoài nghi, có ví dụ mẫu; (5) gate xác
định (deterministic) chạy trước khi chấm bằng LLM, gate đỏ thì sửa luôn không tốn
lượt chấm; (6) đóng băng prompt/gate trong sprint, chỉ cải tiến harness giữa các
lượt; (7) handoff ngắn gọn, có cấu trúc, một agent một vòng; (8) guard là
containment + least privilege + Rule of Two, không phải lọc — injection chưa có
lời giải, nên fail closed (không có verdict = BLOCK); (9) ngày mai: đọc limit thật
ở AI Studio, đóng băng env, build APK sớm, xử lý 2 loại 429 khác nhau, kiểm tra
kill-reopen bằng mắt người hai lần. (Mục 9 là checklist riêng từ 1 brief, không phải điểm đồng thuận.) Đề xuất HIGH (làm trước 20:00): H1 checkpoint
JSON, H2 verdict token + công thức dừng, H3 gate-first, H4 sprint contract,
H5 guard tối thiểu G1+G2+G3+G5 + luật NO_VERDICT, H6 Tier S của stack, H7 xử lý
2 loại 429 + counter, H8 cap 25 phút/vòng + báo cáo ready/blocked/failed.
MEDIUM: calibrate grader bằng ví dụ mẫu, agent card + task state, chấm cả
trajectory, log gate JSONL, Maestro có điều kiện, guard G4+G0. LOW/không làm ngày
mai: supervisor/router, agent tự sửa prompt giữa sprint, dùng framework runtime,
debate/bỏ phiếu, CaMeL/sandbox đầy đủ, Evals/fine-tuning, scale 10+ agent.
Nguyên tắc: vòng lặp tự động hoàn toàn mà fail thì tệ hơn vòng lặp có giám sát —
kill-reopen, submit 16:00, và quyết định STUBBED/LIVE/Groq đều giữ người làm.
