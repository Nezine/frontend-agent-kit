# RED TEAM — Independent Verification of SYNTHESIS.md

**Scope:** `SYNTHESIS.md` + 7 briefs in `~/workspace/frontend-agent-kit/swarm/multi-agent-loop-research/`
**Red-team date / access date for every verdict below:** 2026-11-13
**Method:** every load-bearing claim was traced synthesis → brief section → primary URL, and the
primary URL was opened and read by the red team in this session. Briefs were NOT trusted.
Free legal sources only. No file in this directory was edited.

## 1. Method + coverage

### Primary URLs actually opened and read (2026-11-13)

| # | URL opened | Used to verify |
|---|---|---|
| 1 | https://www.anthropic.com/engineering/multi-agent-research-system | +90.2%, ~15× tokens, coding poor fit, 8 prompt principles, ~20-query eval start |
| 2 | https://www.anthropic.com/engineering/harness-design-long-running-apps (lines 0–203, incl. find "several rounds") | 4 criteria (both agents, design/originality weighted), few-shot calibration, sprint contract, evaluator tuning took "several rounds" |
| 3 | https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html | `APPROVE` token, `TextMentionTermination`, `stop_reason="Text 'APPROVE' mentioned"`, `ExternalTermination` |
| 4 | https://arxiv.org/abs/2510.09023 | Nasr et al.: 12 defenses bypassed, ASR >90% for most, majority originally near-zero |
| 5 | https://arxiv.org/abs/2609.22978 and https://arxiv.org/pdf/2609.22978v1.pdf (find "Final-output checks alone") | DSec scale (160 nodes, ~3M sandboxes/day, 380k concurrent), 4 backends, RL loop via execution signals, "Final-output checks alone cannot reliably establish whether the agent solved the task as intended" (§6.4, PDF L1169) |
| 6 | https://github.com/deepseek-ai/dsh-superagent-prototype/blob/main/docs/003-execution.md | Ticket stages, `ready`/`blocked`/`failed` reports, worker slots + 1 reserved slot, 30-min background cap, retry 3× backoff, restart recovery note, "stored first, done afterwards" |
| 7 | https://platform.openai.com/docs/guides/evals | Evals read-only 31 Oct 2026, shutdown 30 Nov 2026; dataset + graders; JSONL test data |
| 8 | https://openai.github.io/openai-agents-python/multi_agent/ | Code orchestration "more deterministic and predictable"; `while`-loop + separate evaluator; agents-as-tools; self-critique as one tactic |
| 9 | https://openai.github.io/openai-agents-python/guardrails/ | Input guardrails first agent only; output guardrails last agent only; tool guardrails every invocation; handoffs excluded; hosted tools excluded; blocking vs parallel; `InputGuardrailTripwireTriggered` / `OutputGuardrailTripwireTriggered` |
| 10 | https://aistudio.google.com/docs/rate-limits | Only gemini-omni-1.2-flash (Not supported) and gemini-decision-1 (200 RPM / 50,000 TPM / 10,000 RPD) tables remain; no per-model table for gemini-3.5-flash-lite; per-project not per-key; RPD resets midnight Pacific; Free spend limit N/A |
| 11 | https://continuumcode.ai/guides/gemini-resource-exhausted/ (secondary) | Two 429 codes (`rate_limit_exceeded` vs `quota_exceeded`) quoted from ai.google.dev; per-model tables removed Aug 2026 (secondary claim); per-project; midnight Pacific |
| 12 | https://www.anthropic.com/research/how-we-contain-claude | 93% approval of permission prompts; 84% prompt reduction via OS sandbox; 24/25 exfiltration retries; containment; "if credentials never enter the sandbox, they can't be exfiltrated" |
| 13 | https://ai.meta.com/blog/practical-ai-agent-security/ | Rule of Two verbatim (A/B/C, max two per session, supervision if all three); "Prompt injection is a fundamental, unsolved weakness in all LLMs"; limits of the rule |
| 14 | https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ | Sequential + `output_key`; LoopAgent `max_iterations=3`; `escalate=True` early exit; Generator–Critic `PASS` + `exit_condition="PASS"`; Coordinator/Dispatcher as a first-class pattern; HITL for irreversible actions |
| 15 | https://docs.crewai.com/v1.15.32/en/concepts/crews | Checkpoint after every task (`.checkpoints/`, JSON), `Crew.from_checkpoint()` resume, `crewai replay -t`, `step_callback`/`task_callback`, sequential default |
| 16 | https://docs.expo.dev/eas/environment-variables/usage/ | `environment` field in eas.json; auto-detection (`preview` for everything else); `EXPO_PUBLIC_*` inlined at build/export time |
| 17 | https://restfulapi.net/a2a-protocol/ (secondary explainer) | Agent Card fields; 8 task states incl. `INPUT_REQUIRED`; final states terminal, accept no more messages |

### NOT re-opened by the red team (brief-attested only — see §4)

- Anthropic S1 "Building effective agents", S4 "Effective harnesses", S5 "Context engineering",
  S6 sub-agent caps page (`code.claude.com/docs/en/agent-sdk/sub-agents`).
- OpenAI S5 "Unrolling the Codex agent loop" (assistant-message-as-termination, prompt caching,
  compaction), S3 Swarm README (`max_turns` default infinity), S4 Cookbook routines.
- Google ADK eval docs (trajectory vs response, rubric criteria) — mirror + `criteria.md`.
- DeepSeek V3.1/V3.2 pages, Harness README/architecture, super-agent `000-philosophy.md`.
- Convex CLI docs, Supabase secrets/deploy docs, EAS CLI reference, Maestro skill doc,
  OWASP LLM01/LLM06, CaMeL / Spotlighting / Self-Refine / debate abstracts.
- The guard brief's internal reference `GUARD.md` (not a public source).

Where a synthesis claim depends *solely* on one of these, the verdict says so. Nothing below
treats "brief says so" as verification.

### Headline result

**No SEVERE findings. No HIGH proposal is BLOCKED.** The synthesis's load-bearing facts are
overwhelmingly accurate against the primary sources: the +90.2% / 15× figures, the Evals
shutdown dates, the Nasr >90% bypass, the 93% approval-fatigue figure, the ADK/AutoGen
termination mechanics, the CrewAI checkpointing, the DSec quote, the Rule of Two, and the
Gemini "no published per-model numbers" claim all check out verbatim. The failures found are
**overstatement and misattribution in the synthesis's own framing** — chiefly §1's convergence
labels (C6, C9), one false unanimity claim (L1), one misattributed design rule (C4), and
secondary-sourced load-bearing detail (H7, M2). All are fixable by rewording; none falsifies a
proposal's substance.

## 2. Findings table

| # | Finding | Severity | Evidence | Affects |
|---|---|---|---|---|
| F1 | **C9 is not a convergence finding.** §1 defines the table as "findings that appear in three or more briefs independently". C9 ("Tomorrow's stack…") cites exactly one brief (tomorrow-stack §2 + §3). It is a single-source checklist, not a convergence. | MAJOR | SYNTHESIS.md §1 header vs C9 row (1 source listed). Content itself verified where checked (Expo env page, AI Studio page). | §1 framing; H6/H7 content unaffected, but their "convergent" backing is overstated |
| F2 | **C6's DeepSeek leg is "implied", not stated.** Synthesis cites "DeepSeek (no self-modifying prompts mid-sprint, implied by T4 written-rule discipline)". DeepSeek T4 is "acts only when asked, or when a written rule allows it" (003-execution / philosophy) — a scope rule, not a freeze-prompts-mid-sprint rule. Verified 003-execution.md contains no freeze/prompts language. C6 is really 2-source (Anthropic + OpenAI), below §1's own 3+ threshold. | MAJOR | 003-execution.md read in full (lines 0–232): no prompt-freeze statement. Anthropic T8/N6 and OpenAI T8 legs are genuine. | C6; L2 rationale (L2 itself still stands on Anthropic) |
| F3 | **L1 "All sources agree: fixed sequential pipeline, coordinator as single point of control" is false as stated.** The sources document the opposite as valid patterns: Anthropic S2 is an orchestrator-worker system with a lead agent dynamically delegating ("a linear, one-shot pipeline cannot handle these tasks", multi-agent-research-system L13–19, L52–53); Anthropic S1 documents routing and orchestrator-workers; OpenAI documents LLM-orchestrated routing as a coequal pattern (multi_agent/ L2–9, L11–26); Google documents Coordinator/Dispatcher as pattern #2 (ADK blog L92–103). What the *briefs* agree on is a *recommendation for this 5-hour sprint*, not that the sources agree. | MAJOR | Anthropic multi-agent page L13–19, L52–53; OpenAI multi_agent/ L2–9; ADK blog L92–103. | L1 rationale (rejection itself still justified on cost/control grounds, but the unanimity premise is wrong) |
| F4 | **C4 "grader never sees builder's notes" is a design invention misattributed as sourced convergence.** No primary source says this. Anthropic S3 gives the *same four criteria to both* generator and evaluator (harness page L58) — the opposite of information withholding. Google 2.4's "grader never sees the builder's prompt, working notes, or history" is the Google brief's own application of A2A opacity, not a Google quote (ADK blog says nothing about grader blindness; the A2A "opaque" wording is about *agents across teams*, restfulapi.net L46–48). The rule is sound design, but it is not a finding "from" Anthropic/Google/OpenAI/Frameworks. | MAJOR | Harness page L58–75; ADK blog (no grader-blindness passage); restfulapi.net L46–48 (opacity = cross-team agents). | C4; H4-adjacent wording ("grader/coordinator approves", independence framing) |
| F5 | **H7's 429 parsing rests on secondary evidence, and one discriminator token is unverified.** The `rate_limit_exceeded` vs `quota_exceeded` split is quoted from Google's api-errors doc *via* continuumcode.ai (secondary); the primary ai.google.dev/api-errors page was CHƯA ĐỌC in the brief and was not opened by the red team either. The `limit: 0` discriminator in H7 ("`quota_exceeded`/`PerDay`/`limit: 0`") appears in **no** source the red team opened (not in continuumcode.ai lines 0–279, not in the AI Studio page). The per-project enforcement and midnight-Pacific reset *are* primary-confirmed (AI Studio page L44–46). | MAJOR | continuumcode.ai L92–100 (verbatim quotes, attributed to ai.google.dev); AI Studio page L44–46; `limit: 0` absent from all opened sources. | H7 — PASS WITH REWORDING (see §3) |
| F6 | **M2's A2A leg is secondary-only.** All A2A detail (Agent Card fields, 8 task states, `INPUT_REQUIRED`, terminal-state rule) comes from the restfulapi.net explainer; the canonical spec (a2a-protocol.org) is CHƯA ĐỌC (synthesis §5 correctly flags this). The red team verified the explainer's claims match what the brief says (restfulapi.net L56–116), but the explainer remains a secondary source, and the synthesis presents M2 without that qualifier in §2. | MAJOR | restfulapi.net read (L0–260); google-brief §4 (spec CHƯA ĐỌC, 429-blocked). | M2 — PASS WITH REWORDING |
| F7 | **C2's LangGraph leg is secondary-only.** Frameworks T3's "LangGraph checkpoint-per-superstep" rests on the Argus research dossier (secondary, quoting LangGraph source); the official LangGraph docs are CHƯA ĐỌC (frameworks-brief §5.1; synthesis §5 flags it). C2 still has 4 primary legs (Anthropic, CrewAI, DeepSeek, OpenAI), so convergence stands — but the LangGraph citation must be labelled secondary. | MINOR | frameworks-brief §1.1 caveat + §5.1; CrewAI checkpointing primary-confirmed (crews page L183–198). | C2 citation |
| F8 | **§5 caveat is stale/wrong: OpenAI guardrail scoping rules are NOT "CHƯA ĐỌC".** Synthesis §5 lists "OpenAI SDK guardrail scoping rules (input-only-first-agent / output-only-last-agent / tripwire exception names) — CHƯA ĐỌC". The guard-security-brief *did* read that page (S4, lines 0–312), and the red team verified every rule on the primary page today (guardrails/ L18–23, L39, L68, L131–133). The synthesis copied the openai-brief's CHƯA ĐỌC status without reconciling with the guard brief, which read the same page. Correction direction: the caveat is over-cautious, not dangerous — the rules are verified. | MINOR | openai.github.io/openai-agents-python/guardrails/ L18–23, L39, L68, L131–133; guard-brief §1.7 vs openai-brief §5 (internal inconsistency between briefs). | §5 caveats |
| F9 | **§5 "Google removed per-model free-tier tables in Aug 2026" — removal confirmed, month is secondary-only.** The current AI Studio page confirms the removal (only omni-flash and decision-1 tables remain; no table for gemini-3.5-flash-lite; "viewed in Google AI Studio", rate-limits L164–174, L177–304). But the page itself does not date the removal; "August 2026" comes only from continuumcode.ai (L3, L15–16, L230–232). The operative claim (no citable numbers; AI Studio is the authority) is primary-confirmed. | MINOR | AI Studio rate-limits page; continuumcode.ai L3, L230–232. | §5 caveats |
| F10 | **C8's parenthetical "(authors from OpenAI, Anthropic and Google DeepMind)" is unverified.** The Nasr abstract (arxiv.org/abs/2510.09023 L39–43) confirms "bypass 12 recent defenses… attack success rate above 90% for most; the majority of defenses originally reported near-zero attack success rates" — but lists author names without affiliations. Affiliation claim not checked. Does not affect C8's substance. | MINOR | arxiv.org/abs/2510.09023 L21–22 (authors), L39–43 (abstract). | C8 |
| F11 | **Vietnamese summary: "9 điểm đồng thuận" is wrong.** There are 8 convergence points + 1 single-source item (C9, see F1). The rest of §6 is accurate against the English body (HIGH/MEDIUM/LOW lists match §2; kill-reopen twice matches tomorrow-stack B3; STUBBED/LIVE/Groq human call matches §3.3). | MINOR | SYNTHESIS.md §6 vs §1 table (C9 has 1 source). | §6 |
| F12 | **C3's "OpenAI T1/T13 (counted bound, `max_turns` defaults to infinity)" overgeneralises.** `max_turns` defaulting to infinity is Swarm-specific (openai-brief §1.3, Swarm README); Swarm is deprecated/educational. The Agents SDK "Running agents" page (the live `max_turns` behaviour) was CHƯA ĐỌC. The counted-bound point itself stands via T1 (primary-confirmed, multi_agent/ L71–72). | MINOR | openai-brief §1.3, §5; multi_agent/ L71–72. | C3 citation |
| F13 | **Primary-source typo (observation, not a synthesis error).** The AutoGen Teams tutorial itself is internally inconsistent: its prose says the team stops "when the word 'TERMINATE' was detected" (L140–144) while its code uses `TextMentionTermination("APPROVE")` and the run output shows `stop_reason="Text 'APPROVE' mentioned"` (L89, L134). The synthesis correctly uses APPROVE. No action; noted so nobody "fixes" the synthesis toward TERMINATE. | MINOR | AutoGen Teams page L89, L134 vs L140–144. | None (informational) |

### Claims spot-checked and CONFIRMED (no finding)

- **+90.2% / ~15× tokens / coding poor fit** (L5): verbatim on the Anthropic research page
  (L31–34, L43–47). The synthesis's "research-only" framing in L5 is exactly what the page says.
- **Four criteria, both agents, design/originality weighted; sprint contract; few-shot calibration;
  evaluator tuning took "several rounds"** (H4, M1): harness page L58–78, L141–148, L202–203.
- **`APPROVE` token, `stop_reason`, external kill-switch letting the turn finish** (H2, C3):
  AutoGen Teams page L83, L89, L134, L204–208; external-termination semantics in the brief
  (page tail beyond L322 not re-opened — the `ExternalTermination.set()` "when the current
  agent's turn is over" wording is brief-attested only).
- **ADK LoopAgent: `max_iterations=3`, `escalate=True`, critic `PASS`** (C1, C3, H2): ADK blog
  L319–341, L359–361, L405–413.
- **CrewAI checkpoint-per-task, JSON, resume without re-executing** (H1, C2): crews page L183–212.
- **DSec: scale, 4 backends, decoupling, "Final-output checks alone…" quote** (C2, C5):
  arXiv abs + PDF L96–103, L123–135, find at PDF L1169.
- **Super-agent restart protocol, store-first, ready/blocked/failed, 30-min cap** (H1, H8, C2, C7):
  003-execution.md L19–21, L52–54, L88–89, L182–183, L209–210, L222–225.
- **Evals read-only 31 Oct 2026 / shutdown 30 Nov 2026; JSONL dataset + graders** (L6, M4):
  platform.openai.com/docs/guides/evals L9–17, L264–275.
- **Nasr >90% / 12 defenses** (C8): abstract L39–43.
- **Rule of Two** (C8, H5): Meta page L41–52, L134–141.
- **93% approval fatigue; 84% prompt reduction; 24/25 exfiltration** (§3.4, C8): contain-claude
  L11–15, L100–104, L127–130.
- **No published per-model Gemini numbers; per-project; midnight Pacific; Free spend N/A**
  (§5, H6, H7): AI Studio page L44–46, L94, L164–174.
- **Expo `environment` field; auto-detection; `EXPO_PUBLIC_*` inlined at build time** (H6 S2):
  docs.expo.dev/eas/environment-variables/usage/ L10–11, L62–68, L125–127, L135–136.
- **A2A card/states content as described** (M2, C7): restfulapi.net L56–116 — accurate as a
  secondary account; see F6.
- **§5 CHƯA ĐỌC list** (except F8): OpenAI guardrail rules aside, every item checks out against
  the briefs — A2A spec, LangGraph docs, DeepSeek-R1, SAIF §05 tail, EAS quota, Groq limits
  are all genuinely unread/secondary-only in the briefs.

## 3. Per-proposal verdicts

| # | Verdict | Basis |
|---|---|---|
| H1 | **PASS** | Checkpoint-after-every-stage: CrewAI primary-confirmed; DeepSeek restart protocol primary-confirmed; Anthropic files-as-memory brief-attested (S4 not re-opened — coverage note only). |
| H2 | **PASS** | Verdict token + formula + `stop_reason`: AutoGen + ADK + OpenAI all primary-confirmed. |
| H3 | **PASS** | Gate-first: OpenAI T6 primary-confirmed (multi_agent/ L62–63); Frameworks T6 primary-confirmed via CrewAI callbacks (crews L38–42); Anthropic T3 (S1 gates, S4 JSON "never edit" rule) brief-attested — S1/S4 not re-opened. |
| H4 | **PASS** | Sprint contract + four criteria: primary-confirmed verbatim from the harness page. |
| H5 | **PASS** | Minimal guard G1+G2+G3+G5 + NO_VERDICT + 6-probe smoke test: matches guard-brief §2.8/§2.6; every load-bearing primary behind it re-verified (Nasr, Meta, contain-claude, OpenAI guardrails). G4/G0 ordering is the brief's own design, correctly presented as such. |
| H6 | **PASS** | Tier S: S1/S2 primary-confirmed (AI Studio authority; Expo env field + inlining). S3/S4/S5 (Convex deploy/seed, Supabase deploy + secret probe, EAS `--wait --json`) are brief-attested only — Convex/Supabase/EAS-CLI pages not re-opened. No contrary evidence found; wording is accurate as written. |
| H7 | **PASS WITH REWORDING** | Core branch logic (per-minute backoff vs per-day fail-over) is supported — but only via a secondary source quoting Google (F5), and the `limit: 0` discriminator is unverified. Reword: mark the code split as secondary-sourced, drop or hedge `limit: 0` ("treat as unverified heuristic; confirm against the first live 429 or ai.google.dev/api-errors before the sprint"), keep the backoff/fail-over behaviour. Do not present the parse rules as Google-published. |
| H8 | **PASS** | 25-min cap + ready/blocked/failed: DeepSeek 003 primary-confirmed (30-min cap adapted to 25; the 25 is a stated choice, not a misquote). |
| M1 | **PASS** | Few-shot calibration; "several rounds" primary-confirmed (harness L202–203). |
| M2 | **PASS WITH REWORDING** | Agent cards + task states: content verified against the explainer, but the A2A leg is secondary-only (F6). Reword to "A2A-shaped file contract (secondary explainer; canonical spec CHƯA ĐỌC)" and do not cite A2A spec details as spec fact. |
| M3 | **PASS WITH REWORDING** | Trajectory grading: proposal is sound and consistent with the brief, but the red team did NOT re-open the ADK eval pages (trajectory-vs-response, rubric criteria) — brief-attested only. Keep the proposal; add the same "brief-attested, re-verify criteria.md before citing" qualifier, or do a 5-minute re-check of `google/adk-docs` criteria.md before FLEET-2. |
| M4 | **PASS** | JSONL gate log: OpenAI evals page primary-confirms JSONL rows + per-row pass/fail. |
| M5 | **PASS WITH REWORDING** | Maestro conditional: the conditional wording ("only if installed and green before 12:00") already bounds the risk, but the underlying Maestro claims (`killApp`/`stopApp` semantics, testID advice) rest on a third-party skill doc the red team did not re-open. Reword to cite it as secondary and keep the 12:00 drop-deadline. |
| M6 | **PASS** | G4 + G0 second wave: matches guard-brief §2.8 ordering; correctly sequenced after H5. |
| L1 | **PASS WITH REWORDING** | Rejection of supervisor/router/peer-messaging/debate stands on cost + determinism grounds, but the stated premise "All sources agree" is false (F3). Reword to "the briefs recommend against…" and keep the rejection. |
| L2 | **PASS** | Freeze mid-sprint: Anthropic T8/N6 genuine (S2 principle 5, S3 one-at-a-time ablation — brief-attested; S2 page's principle 5 confirmed in the research post, L93–96). |
| L3 | **PASS** | No framework runtime: consistent across all five briefs' §3 sections; each rejection is a brief-level judgement, accurately summarised. |
| L4 | **PASS** | No full CaMeL/VM/sandbox/classifier/HITL: guard-brief §3, consistent with the verified ceiling (Nasr, contain-claude). |
| L5 | **PASS** | No 10+ agent scale-up; +90.2% research-only at ~15× tokens: primary-confirmed (Anthropic research page L31–47). |
| L6 | **PASS** | No Evals platform / fine-tuning: shutdown dates primary-confirmed verbatim. |
| L7 | **PASS** | No CaMeL-style runtime gating of the shipped app: guard-brief §2.7/§3 scope judgement, accurately summarised. |

**Blocked: none.** Every HIGH proposal is shippable as written except H7, which needs the
one-paragraph rewording in F5 before it is coded (the `limit: 0` token must not ship as a
documented discriminator until it is seen in a live error or on ai.google.dev).

## 4. What was NOT verified (red-team coverage gaps)

- Anthropic S1, S4, S5, S6 pages; OpenAI Codex-loop page (S5), Swarm README, Cookbook tail;
  ADK eval docs; DeepSeek V3.1/V3.2/Harness/philosophy pages; Convex CLI, Supabase, EAS CLI
  reference, Maestro skill doc, OWASP pages, CaMeL/Spotlighting/Self-Refine/debate abstracts;
  internal `GUARD.md`; internal incident claims (probe-4 yield death, "~20 free Gemini calls"
  planning cap, D49–D52 Milo track overlap, 16:00 submit rule, demo-bunker rule) — these are
  internal/task-brief facts, not source claims, and were not independently checked.
- The AutoGen `ExternalTermination.set()` "turn finishes first" wording and the AutoGen
  `MaxMessageTermination`/`TimeoutTermination` list were not re-opened (Teams page tail beyond
  L322 not read).
- No URL in the synthesis or briefs was found fabricated: every cited URL the red team opened
  resolved to the claimed page. No 429/timeout blocked a red-team open in this session.

## 5. Recommended fixes for the coordinator (in priority order)

1. **§1:** move C9 out of the convergence table (or relabel the table) and fix C6 to 2-source
   (drop the DeepSeek leg or mark it "analogy, not stated"). These are the only two rows that
   violate §1's own "three or more briefs" definition.
2. **H7:** apply the F5 rewording before Milo codes it.
3. **L1:** replace "All sources agree" with "the briefs recommend".
4. **C4:** present "grader never sees builder's notes" as a design rule, not a sourced finding.
5. **§5:** correct the OpenAI guardrail caveat (F8 — the rules ARE verified) and attribute the
   "August 2026" removal date to the secondary source (F9).
6. **§6:** "9 điểm đồng thuận" → "8 điểm đồng thuận + 1 checklist stack ngày mai".
7. **M2/M3/M5:** add secondary/brief-attested qualifiers as in §3.

## 6. Tóm tắt tiếng Việt

Đã kiểm chứng độc lập toàn bộ SYNTHESIS.md và 7 brief bằng cách mở lại từng URL gốc trong
ngày 13/11/2026. Kết quả: **không có lỗi SEVERE nào, không có đề xuất HIGH nào bị BLOCK.**
Hầu hết các con số và khẳng định quan trọng đều đúng nguyên văn so với nguồn chính: +90,2%
và ~15× token của Anthropic, ngày đóng nền tảng Evals của OpenAI (chỉ đọc 31/10/2026, đóng
30/11/2026), Nasr et al. vượt qua 12 lớp phòng thủ với tỉ lệ trên 90%, người dùng bấm đồng ý
tới 93% các hộp thoại xin phép (Anthropic), cơ chế dừng `APPROVE`/`stop_reason` của AutoGen,
`PASS`/`escalate`/`max_iterations=3` của ADK, checkpoint sau mỗi task của CrewAI, câu "chỉ
kiểm tra output cuối là không đủ" của DeepSeek DSec, Rule of Two của Meta, và việc Google
không còn công bố bảng giới hạn free-tier theo từng model.

Có 6 lỗi MAJOR (đều sửa được bằng cách viết lại, không làm sập đề xuất nào): (1) C9 chỉ có
1 nguồn nhưng lại nằm trong bảng "đồng thuận từ 3 brief trở lên"; (2) C6 ghi DeepSeek ủng hộ
việc "đóng băng prompt giữa sprint" nhưng thực ra DeepSeek chỉ nói "chỉ làm khi được yêu cầu
hoặc có quy tắc viết sẵn" — đó là suy luận, không phải lời nguồn; (3) L1 nói "mọi nguồn đều
đồng ý pipeline cố định" là sai — chính Anthropic, OpenAI và Google đều ghi nhận
router/coordinator là mẫu hợp lệ, chỉ là các brief *khuyên không dùng* cho sprint 5 giờ;
(4) C4 nói "grader không bao giờ thấy ghi chú của builder" như một phát hiện có nguồn, nhưng
không nguồn nào nói vậy — đó là quy tắc thiết kế do brief tự đặt ra; (5) H7 xử lý 2 loại 429
dựa vào nguồn thứ cấp (một blog trích lại tài liệu Google) và token phân biệt `limit: 0`
không tìm thấy trong bất kỳ nguồn nào đã mở — cần ghi rõ là chưa kiểm chứng trước khi code;
(6) M2 (agent card + task state kiểu A2A) dựa hoàn toàn vào một bài giải thích thứ cấp, chưa
đọc spec chính thức của A2A.

Lỗi MINOR: mục §5 ghi nhầm quy tắc guardrail của OpenAI là CHƯA ĐỌC trong khi thực ra brief
guard đã đọc và red-team đã kiểm chứng trực tiếp; tháng "8/2026" Google gỡ bảng giới hạn chỉ
có trong nguồn thứ cấp; phần tóm tắt tiếng Việt ghi "9 điểm đồng thuận" trong khi chỉ có 8
điểm đồng thuận thật + 1 checklist riêng. Kết luận: H1–H6, H8, M1, M4, M6, L2–L7 đạt
(PASS); H7, M2, M3, M5, L1 đạt với điều kiện viết lại (PASS WITH REWORDING) theo mục 5.
