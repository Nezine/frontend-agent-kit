# Google brief — ADK, A2A, Gemini agent docs, evaluation

**Area:** Google (4 of 7) — ADK multi-agent orchestration, A2A protocol, Gemini agent docs, agents whitepaper / evaluation.
**Access date for all claims below:** 2026-11-13.
**Rule applied:** every factual claim carries its source URL. Anything not read is marked **CHƯA ĐỌC** — no claim is made from search snippets.

---

## 1. What Google actually does

### 1.1 ADK — three deterministic workflow primitives + LLM agents

Google's Agent Development Kit (ADK) separates two kinds of agents: `LlmAgent`, which decides what to do, and workflow agents, which decide *in what order things happen* regardless of what any model thinks. The workflow primitives are `SequentialAgent`, `ParallelAgent`, and `LoopAgent`.

- **SequentialAgent — the assembly line.** "Agent A finishes a task and hands the baton directly to Agent B. It is linear, deterministic, and refreshingly easy to debug because you always know exactly where the data came from." State passes between stages via `output_key`: each agent writes its result to `session.state` under a named key, and the next agent reads it by that key.
  - Source: https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ (accessed 2026-11-13)
- **ParallelAgent — fan-out / gather.** Multiple agents run simultaneously for independent work ("Security Auditor," "Style Enforcer," "Performance Analyst" reviewing one pull request), then a final synthesizer agent combines their outputs. Two warnings from Google: parallel agents run in separate threads but **share the session state**, so "to prevent race conditions, make sure each agent writes its data to a unique key"; and the fan-out is normally wrapped in a `SequentialAgent` with the synthesizer (`SequentialAgent(sub_agents=[parallel_reviews, pr_summarizer])`).
  - Source: https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ (accessed 2026-11-13)
- **LoopAgent — repeat until a termination condition.** Two distinct uses in Google's guide:
  - *Generator and Critic (correctness, pass/fail):* a `SequentialAgent` manages the draft-and-review interaction and a parent `LoopAgent` "enforces the quality gate and exit condition." The critic checks the draft against specific criteria and outputs `PASS` or error details; on failure the feedback is routed back to the generator.
  - *Iterative refinement (quality, not pass/fail):* generator → critique → refiner, repeated. Exit has two mechanisms: a hard limit (`max_iterations=3` in Google's example) **and** an early-exit signal — "an agent can trigger an exit by signaling `escalate=True` within its `EventActions` if the quality threshold is met before the maximum iterations are reached."
  - Source: https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ (accessed 2026-11-13)
- **Coordinator / Dispatcher.** A central intelligent agent routes by intent to specialist sub-agents, using "LLM-driven delegation" via ADK's AutoFlow mechanism, driven by the descriptions of the children. Google positions this for routing work (e.g. billing vs. tech support), not for fixed pipelines.
  - Source: https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ (accessed 2026-11-13)
- **Hierarchical decomposition.** A sub-agent can be wrapped in `AgentTool`, so "the parent agent can call it explicitly, effectively treating the sub-agent's entire workflow as a single function call."
  - Source: https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ (accessed 2026-11-13)
- **Human-in-the-loop.** Agents do the groundwork, but a human must authorize "high-stakes actions — specifically those that are irreversible or carry significant consequences," e.g. financial transactions, deploying code to production, or acting on sensitive data. Implemented via an approval tool that pauses execution and waits for a human "Yes"/"No."
  - Source: https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ (accessed 2026-11-13)
- **Composite patterns.** "Real-world enterprise applications rarely fit into a single box" — production systems combine the patterns above.
  - Source: https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ (accessed 2026-11-13)
- **Why multi-agent at all (Google's framing).** "A single agent tasked with too many responsibilities becomes a 'Jack of all trades, master of none.' As the complexity of instructions increases, adherence to specific rules degrades, and error rates compound." The fix is "decentralization and specialization" — one role per agent (Parser, Critic, Dispatcher), which makes the system "inherently more modular, testable, and reliable."
  - Source: https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/ (accessed 2026-11-13)

### 1.2 A2A (Agent2Agent) — the agent-to-agent contract

- **What it is.** "The A2A (Agent2Agent) protocol is an open standard that lets one AI agent find another agent, send it a task, and get back status updates and results over HTTP, without either agent seeing the other's prompts, tools or memory." Google created A2A in 2025; the Agentic AI Foundation at the Linux Foundation maintains it next to MCP; version 1.0 of the specification defines the messages, the task lifecycle, and three wire formats (JSON-RPC 2.0, gRPC, and HTTP+JSON).
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)
- **Opaque agents.** "A2A is a protocol between two agents that do not share code" and the specification "calls the agents 'opaque', which means the client sees only the inputs and outputs, never the model, prompts or tools behind them."
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)
- **Agent Card — discovery.** "An A2A server must publish an Agent Card, a JSON document with the agent's name, description, version, endpoints, capabilities, skills and security requirements. The standard location is the well-known URI `https://{server_domain}/.well-known/agent-card.json`." The card's four parts a client reads before the first request: `supportedInterfaces` (endpoint URL, `protocolBinding`, `protocolVersion`, in preference order); `capabilities` (streaming, pushNotifications, extendedAgentCard); `skills` (each with `id`, `name`, `description`, `tags`, `examples`, "so a client agent's model can decide which agent fits a request"); `securitySchemes` / `securityRequirements` (API keys, HTTP bearer, OAuth 2.0, OpenID Connect, mutual TLS). Cards change rarely, so the spec recommends `Cache-Control` with `max-age` and an `ETag`; a card can also carry signatures.
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)
- **Tasks, Messages, Artifacts.** A message is one turn (with `messageId`, a role of `ROLE_USER` / `ROLE_AGENT`, and parts holding text, Base64 raw bytes, a URL, or structured JSON data). A task is the unit of work: it has an `id`, a `contextId` grouping related tasks and messages, a `status` with a `state`, a `history` of messages, and `artifacts` (results such as a report or JSON object, built from parts like a message).
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)
- **Task lifecycle — 8 states.** `SUBMITTED` (accepted, not started), `WORKING` (processing), `INPUT_REQUIRED` (needs more input; interrupted, not final), `AUTH_REQUIRED` (needs authentication; interrupted, not final), `COMPLETED`, `FAILED`, `CANCELED`, `REJECTED` (all four final). "A task can pause for input or authentication any number of times, but a final state ends the task," and "a task in a final state accepts no more messages or cancel requests." The canonical `INPUT_REQUIRED` example: the server does not fail when a parameter is missing — it moves the task to `INPUT_REQUIRED` with a message asking for it, and the client sends a second message with the same `taskId` to continue.
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)
- **Operations.** With the JSON-RPC binding, every operation is a JSON-RPC 2.0 request; the client "must send the `A2A-Version` header on every request, because a server reads a missing or empty header as version 0.3." Core operations: `SendMessage` (`POST /message:send`), `SendStreamingMessage` (`POST /message:stream`), `GetTask` (`GET /tasks/{id}`), `ListTasks` (`GET /tasks`), `CancelTask` (`POST /tasks/{id}:cancel`), `SubscribeToTask` (`POST /tasks/{id}:subscribe`); the spec's method-mapping table lists eleven operations in total. A2A-specific JSON-RPC error codes run from -32001 to -32099 (e.g. `TaskNotFoundError` -32001, `TaskNotCancelableError` -32002, `VersionNotSupportedError` -32009).
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)
- **Long tasks — three update mechanisms.** Polling with `GetTask` (short tasks / no persistent connection); streaming with `SendStreamingMessage` (server-sent events, one event per task/message/statusUpdate/artifactUpdate); push notifications to a registered webhook (minutes-to-hours tasks). Security note: "A server that accepts webhook URLs should validate them, because an attacker could otherwise make the server call internal systems (server-side request forgery)."
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)
- **A2A vs MCP — complementary, not competing.** "MCP connects an agent to tools and data sources, and the agent's model decides which tool to call. A2A connects an agent to another agent, which decides on its own how to do the task." MCP's unit of work is a tool call; A2A's is a task with states, history, and artifacts. "A real system uses both protocols."
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)
- **When A2A is worth it.** "A2A adds an Agent Card, a task store (a database of task objects) and a second protocol to the system, so the cost is worth paying only when the other side is a real agent."
  - Source: https://restfulapi.net/a2a-protocol/ (accessed 2026-11-13)

### 1.3 ADK evaluation — two axes, rubrics, and always-on efficiency

- **Why evaluate, and what.** "Due to the probabilistic nature of models, deterministic 'pass/fail' assertions are often unsuitable for evaluating agent performance. Instead, we need qualitative evaluations of both the final output and the agent's trajectory — the sequence of steps taken to reach the solution." Agent evaluation breaks into two components: (1) evaluate trajectory and tool use (choice of tools, strategies, efficiency — compare actual steps against the expected steps, the ground truth); (2) evaluate the final response (quality, relevance, correctness). Before automating, define success, identify critical tasks, and choose relevant metrics.
  - Source: https://github.com/overlorddc/adk-docs/blob/HEAD/docs/evaluate/index.md (accessed 2026-11-13; mirror of the official ADK docs)
- **Two file formats.** `*.test.json` test files are unit-style: one session, one or more turns, each turn holding the user query, expected tool-use trajectory, expected intermediate (sub-agent) responses, and the final response, plus `session_input` (`app_name`, `user_id`, `state`). `*.evalset.json` evalsets are integration-style: multiple, potentially lengthy sessions, suited to multi-turn conversations; an eval can alternatively define a *conversation scenario* that dynamically simulates a user. Test files are backed by a formal Pydantic data model (`EvalSet` / `EvalCase`); `AgentEvaluator.migrate_eval_data_to_new_schema` migrates legacy files.
  - Source: https://github.com/overlorddc/adk-docs/blob/HEAD/docs/evaluate/index.md (accessed 2026-11-13)
- **Built-in criteria (ADK Python).** `tool_trajectory_avg_score` (exact match of the tool-call trajectory; match types `EXACT`, `IN_ORDER`, `ANY_ORDER`; per-invocation score 1.0/0.0, averaged); `response_match_score` (ROUGE-1 similarity to a reference response); `final_response_match_v2` (LLM-as-judge semantic match to a reference; judge rates each invocation "valid"/"invalid", repeated for `num_samples`, majority vote); `rubric_based_final_response_quality_v1` / `rubric_based_tool_use_quality_v1` / `rubric_based_multi_turn_trajectory_quality_v1` (LLM-as-judge against user-written rubrics, `yes`/`no` per rubric, majority vote, averaged — "particularly useful when no single reference response exists, or when quality depends on multiple subjective factors"); `hallucinations_v1` (LLM-judged groundedness against context); `safety_v1` (safety/harmlessness; "unlike other metrics implemented natively within ADK, `safety_v1` delegates the evaluation to the Agent Platform Eval SDK" and "requires a Google Cloud Project" with `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` set); `multi_turn_task_success_v1`, `multi_turn_trajectory_quality_v1`, `multi_turn_tool_use_quality_v1` (multi-turn, LLM-judged). Thresholds are floats 0.0–1.0 set per criterion in `EvalConfig`.
  - Source: https://github.com/google/adk-docs/blob/main/docs/evaluate/criteria.md (accessed 2026-11-13)
- **Efficiency criteria are informational only.** Four criteria "measure how expensive an agent is to run," "report a value, but never pass or fail an eval case," are "always on" for every eval, and "cannot be turned off": `tool_call_count_v1` (count), `inference_call_count_v1` (count), `token_usage_v1` (tokens), `invocation_duration_v1` (seconds).
  - Source: https://github.com/google/adk-docs/blob/main/docs/evaluate/criteria.md (accessed 2026-11-13)
- **Trajectory vs. response, in ADK's own words.** "Evaluating an agent's performance requires comparing its actual trajectory to an expected, or ideal, one. This comparison can reveal errors and inefficiencies in the agent's process." Intermediate sub-agent responses "may or may not be of interest to the end user, but for a developer/owner of the system, are of critical importance, as they give you the confidence that the agent went through the right path to generate [the] final response."
  - Source: https://github.com/overlorddc/adk-docs/blob/HEAD/docs/evaluate/index.md (accessed 2026-11-13)

### 1.4 Gemini agent docs — function calling (the model proposes, the runtime disposes)

- **Definition.** "Function calling, also known as *tool use*, provides the LLM with definitions of external tools… When processing a prompt, the model intelligently determines if a tool is needed and, if so, outputs structured data specifying the tool to call and its parameters… Your application then executes this tool, feeds the result back to the model." Use cases: fetching data, and "taking action: perform external operations like submitting forms, updating application state, or orchestrating agentic workflows (e.g., conversation handoffs)."
  - Source: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/tools/function-calling (accessed 2026-11-13)
- **Directly relevant to our stack.** The supported-models list on that page includes **Gemini 3.5 Flash-Lite** and **Gemini 3.5 Flash** (our primary model family), and, under open models, **OpenAI gpt-oss 120B** (our Groq fallback). Functions are declared in OpenAPI schema format; the Google Gen AI SDK is the unified client (same code targets the Gemini API and Vertex AI).
  - Source: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/tools/function-calling (accessed 2026-11-13)

### 1.5 Agents whitepaper (Google / Kaggle) — the agent definition

- The whitepaper *Agents* (Julia Wiesinger, Patrick Marlow, Vladimir Vuskovic) defines an agent as a program that extends a standalone generative model: like humans using tools, a model uses tools "to access real-time information or suggest a real-world action," and "must not only have access to a set of external tools, it needs the ability to plan and execute any task in a self-directed fashion. This combination of reasoning, logic, and access to external information that are all connected to a Generative AI model invokes the concept of an agent."
  - Source: https://www.kaggle.com/whitepaper-agents (accessed 2026-11-13 — landing page intro only; full PDF **CHƯA ĐỌC**, see §4)

---

## 2. What transfers to our loop — and how

Our loop today: taste lock before HTML → build → gate first → screenshots + independent grading → fix top 2 → stop when gates green or 3 rounds. Known failure: agents die mid-loop (probe-4 yield death — the `-p` mode treats the agent's final response as process end).

### 2.1 The single biggest transfer: the driver owns the loop, not the agent (ADK Sequential + Loop)

ADK's core design decision is that **control flow lives in code, not in the model**. A `SequentialAgent` runs stages in a fixed order; a `LoopAgent` repeats them until a termination condition; the LLM inside each stage never decides whether the loop continues. Our probe-4 death is exactly what happens when the loop lives inside the agent process: when the agent ends, the loop ends.

**How to apply (concrete, $0):**
- Make the loop a dumb deterministic driver (shell script / small Node script / cron-style stepper), not a long-lived agent session. The driver owns: the round counter (max 3), the stage list, and the transitions.
- Each agent invocation is **one-shot, one stage**: it reads named input files, writes named output files, exits. If it dies mid-stage, the driver re-invokes the *same stage with the same inputs* — resume, not restart.
- This mirrors ADK's `session.state` + `output_key`: state must live in files (the repo), never in an agent's live context.

### 2.2 Named state keys between stages (ADK SequentialAgent / `output_key`)

Google's "secret sauce" is that each stage writes its result to `session.state` under a named `output_key` and the next stage reads it by key.

**How to apply:** give every loop artifact a fixed path/key and make each stage read only its declared inputs:
- `taste_lock` → the taste-lock doc (frozen before HTML; never rewritten mid-loop)
- `build_artifact` → the built app / HTML
- `gate_verdict` → gate result (pass/fail per gate, machine-readable)
- `grade_report` → grader findings (numbered, see §2.3)
- `fix_list` → top-2 findings only

A stage that cannot find its input key fails loudly with "missing input X" instead of guessing or re-doing the previous stage's work.

### 2.3 LoopAgent termination: add the missing early-exit signal

Our loop already has ADK's hard limit (`max_iterations=3`). What it lacks is ADK's second mechanism: the `escalate` / `PASS` early exit. Google's Generator-Critic loop breaks the moment the critic outputs `PASS`; the iterative-refinement loop lets an agent signal `escalate=True` before the max is reached.

**How to apply:**
- The grader's verdict must be a **machine-checkable token first, prose second**: `VERDICT: PASS` or `VERDICT: FAIL`, followed by numbered findings. The driver parses the token; on `PASS` it stops immediately — round 3 is never burned on an already-green build.
- The fix agent may only address the numbered findings the critic listed (top 2), in order. This is Google's Generator-Critic contract: "if the review passes, the loop breaks… if it fails, specific feedback is routed back to the Generator."
- Keep `max_iterations=3` as the hard backstop for the fail path.

### 2.4 Generator–Critic split = builder never grades (already our rule; Google gives it teeth)

Google separates creation from validation into two agents with different instructions and makes the critic check "specific, hard-coded criteria or logical checks" rather than vibes.

**How to apply:** the grader prompt is a checklist, not an essay brief — each gate is a yes/no item with the evidence the grader must cite (screenshot file, gate output). The grader never sees the builder's prompt, working notes, or history — only the artifact + the taste lock. That is A2A's opacity rule applied inside one team (§2.6), and it is the operational form of "builder never self-grades."

### 2.5 Parallel fan-out / gather — for grading dimensions, not for the build

Google's ParallelAgent runs independent workers simultaneously and gathers them with a synthesizer; each worker must write to a **unique key** because they share state.

**How to apply:** the build itself is sequential (each round depends on the last — it cannot be fanned out). What *can* fan out is the gate/grade phase of one round: independent checks (build passes / screenshots render / taste-lock compliance / copy legibility) run as parallel one-shot agents, each writing its own verdict file, then the grader synthesizes them into one `grade_report`. In a 5-hour sprint with 4 assistants, this is the only safe parallelism — it shortens the slowest phase without creating ordering hazards.

### 2.6 A2A's contract, as files — agent cards + task states for the 4 assistants

We do **not** need A2A's wire protocol (§3). We do need its contract shape, because our 4 assistants are exactly A2A's "agents that do not share code" — they share only a repo.

**How to apply — a one-page card per assistant** (a small JSON/MD file in the repo, written once before the sprint):
- `name`, `skills` (what it accepts, each with id + description + expected input format — A2A's skill fields), `input` / `output` (file paths, not prose), and what it will **not** do (e.g. grader: "never edits the artifact").
- The card is the public contract: a coordinator routes a task to an assistant only if the task matches a listed skill. If no card lists the skill, the task is out of scope — it is not improvised.

**How to apply — task states on every handoff file:**
- Every delegated task carries a `status` field using A2A's states: `submitted → working → completed / failed`, plus `input-required` and `canceled` / `rejected`.
- The `input-required` state is the fix for silent failure: a worker that lacks a required input **returns `input-required` with one specific question** instead of guessing, stalling, or producing a plausible-looking wrong artifact. The coordinator answers with the same task id and the task resumes.
- Terminal states are terminal: "a task in a final state accepts no more messages" — a `completed` handoff is never re-edited in place; a new round is a new task. This directly prevents the "fix on top of a finished verdict" drift.
- Opaque agents: the grader sees only the Agent Card inputs (artifact + taste lock + gate output), never the builder's internal reasoning. Independence is enforced by what is *withheld*, not by asking nicely.

### 2.7 ADK evaluation — grade the trajectory AND the response; track efficiency as info only

- **Two-axis grading.** Our current grading is response-only (is the artifact good?). ADK grades two things: the trajectory (did the agent take the expected steps — gates before screenshots, taste lock before HTML?) and the final response (is the artifact good?). **Apply:** the grader checks a short trajectory list first (e.g. "gate ran before screenshots: yes/no, evidence: gate log file") and fails the round on a trajectory violation even if the artifact looks fine — a build that skipped its gate is not a pass.
- **Rubric-based judging.** ADK's `rubric_based_*` criteria are LLM-as-judge against user-written rubrics, one `yes`/`no` verdict per rubric, majority vote across samples. **Apply:** our grader rubric is a list of yes/no items (taste-lock items, gate items), each with a cited evidence file. No free-form scores. The existing "fix top 2" is then just "the two failed rubric items with the highest severity."
- **Evalset = regression set.** ADK's `*.test.json` (unit) / `*.evalset.json` (integration) idea: the taste-lock checklist *is* our evalset. Every fix round re-runs the same checklist against the new artifact; a previously-passing item that now fails is a regression and blocks the round. Keep the checklist frozen during the sprint (it is the golden set; editing it mid-loop is moving the goalposts).
- **Efficiency as informational only.** ADK's four efficiency criteria (tool calls, inference calls, tokens, wall-clock duration) "report a value, but never pass or fail an eval case." **Apply:** log tokens + minutes per round in the run log as info. Never fail a round for being expensive — in a 5-hour sprint, a slow pass still beats a fast fail. (This also matches our free-tier reality: the budget is time, not money.)
- **What we cannot borrow:** ADK's LLM-judge criteria that need the Vertex Gen AI Evaluation Service / a Google Cloud project (`safety_v1` and friends) — see §3. Our grader is a plain agent prompt doing the same rubric job; same shape, no managed service.

### 2.8 Function calling — the model proposes, the runtime disposes

Google's function-calling contract is that the model only *proposes* a tool call with structured arguments; "your application then executes this tool." **Apply to the app we build (Expo + Convex + Supabase Edge Function):** the Gemini agent inside the Edge Function must never execute a side effect itself — every proposed action goes through runtime validation (auth, idempotency, allow-list) before it touches Convex data. This is also the correct answer to our GUARD gap in miniature: the guard is a runtime check on proposed calls, not a hope that the model behaves. And the docs confirm our stack choice is sound: Gemini 3.5 Flash-Lite (primary) and gpt-oss 120B (Groq fallback) are both listed as function-calling-capable models.

### 2.9 Human-in-the-loop — one gate only

Google reserves human approval for irreversible, high-consequence actions. In a 5-hour sprint, the only irreversible action is the 16:00 submit. **Apply:** no human approval inside the loop (it would stall the sprint); the single HITL point is the submit decision. Everything else — including a `FAIL` verdict on round 3 — is handled by the driver and the agents.

---

## 3. What does NOT transfer — and why

| Google thing | Why it does not transfer to the 14/11 sprint |
|---|---|
| **ADK itself (Python framework, `adk run` / `adk web` / `adk eval`, Agent Engine / Cloud Run deploy)** | Our agents are Muse CLI sessions, our app is Expo + Convex + Supabase. Adopting ADK would cost sprint hours on setup, needs a GCP project and credentials, and its managed paths are paid beyond free tiers. The *patterns* transfer; the *runtime* does not. Free-only, $0.00. |
| **ADK 2.0 graph Workflow Runtime** | **CHƯA ĐỌC** from a primary source (only secondary summaries seen); version/GA status not verified. Do not bet the sprint on it. The 1.x `Sequential` / `Parallel` / `Loop` primitives, read in Google's own blog, are sufficient. |
| **A2A wire protocol (JSON-RPC server, Agent Card HTTP endpoint, SSE streaming, push webhooks, signed cards, OAuth/mTLS)** | Massive overkill for 4 assistants on one team sharing one repo in 5 hours. A2A is built for agents across team/company boundaries "without shared memory, tools, or internal context" — we share all three. Implement the *contract shape* (cards + task states as files, §2.6), not the HTTP machinery. Also note A2A's own warning: adding the card + task store + second protocol "is worth paying only when the other side is a real agent." |
| **ADK managed evaluation (Vertex Gen AI Evaluation Service, `safety_v1`, Agent Platform Eval SDK)** | Requires a Google Cloud project (`GOOGLE_CLOUD_PROJECT` / `GOOGLE_CLOUD_LOCATION`) and managed-service calls. Our grader is a plain agent prompt applying the same rubric idea — same shape, zero setup, zero cost. |
| **Coordinator/Dispatcher as the sprint's main structure** | LLM-driven routing is the wrong tool when the order is fixed and time is short. Our loop is a deterministic pipeline; routing by model judgment adds a failure mode (wrong branch) with no benefit. Keep routing scripted; use the dispatcher pattern only if a genuinely ambiguous triage task appears. |
| **Multi-agent fan-out of the build itself** | The build is inherently sequential: round N+1 depends on round N's grade. Parallelism applies only to independent checks within one round (§2.5). Fanning out the build would produce divergent artifacts with no merge rule. |
| **Routine human-in-the-loop inside the loop** | Would stall a 5-hour sprint. One HITL point only: the 16:00 submit (§2.9). |
| **MCP as a separate layer** | A2A vs MCP: MCP connects an agent to *tools*; our agents already have their tools (file writes, screenshots, shell). No MCP server is needed in the sprint. |
| **"More agents = better" (implicit in multi-agent hype)** | Our loop's value comes from *specialization + deterministic order*, not agent count. Google's own framing is that a single overloaded agent degrades; the fix is roles and order, not headcount. Four assistants with crisp cards beat eight with overlapping skills. |

---

## 4. Sources — read vs. not read

**Read in full (primary sources), accessed 2026-11-13:**
- Google Developers Blog, "Developer's guide to multi-agent patterns in ADK", 2025-12-16 — 8 patterns, pseudocode for Sequential / Parallel / Loop / Coordinator / Hierarchical / Generator-Critic / Iterative refinement / HITL / Composite. https://developers.googleblog.com/en/developers-guide-to-multi-agent-patterns-in-adk/
- ADK docs (official repo), "Evaluation Criteria" — criteria table, trajectory vs. response, rubric-based judging, safety, efficiency criteria. https://github.com/google/adk-docs/blob/main/docs/evaluate/criteria.md
- ADK docs (mirror), "Why evaluate agents" — trajectory + final response, `*.test.json` vs `*.evalset.json`, conversation scenarios, Pydantic EvalSet/EvalCase. https://github.com/overlorddc/adk-docs/blob/HEAD/docs/evaluate/index.md
- Google Cloud docs, "Introduction to function calling" (Gemini Enterprise Agent Platform) — model proposes / app executes; supported models incl. Gemini 3.5 Flash-Lite and gpt-oss 120B. https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/tools/function-calling
- Kaggle, "Agents" whitepaper landing page (Wiesinger, Marlow, Vuskovic) — intro text only. https://www.kaggle.com/whitepaper-agents
- A2A Protocol Explained (restfulapi.net) — Agent Card, task lifecycle, operations, A2A vs MCP, SSRF warning. Secondary explainer, but it quotes the specification throughout; used as the source for §1.2 because the canonical spec could not be opened this session (see below). https://restfulapi.net/a2a-protocol/

**CHƯA ĐỌC (not read — no claims made from these):**
- A2A canonical specification, a2a-protocol.org — open attempted 2026-11-13, blocked by a browser rate limit (HTTP 429) after earlier fetches; not retried per the rate-limit instruction. All A2A claims above come from the restfulapi.net explainer, not from the spec itself.
- Kaggle whitepaper PDFs: *Agents* (full text), *Agents Companion*, *Agent Quality*, *Introduction to Agents and Agent Architectures* — only the *Agents* landing-page intro was read.
- ADK reference pages on adk.dev / google.github.io/adk-docs (`agents/workflow-agents/`, `a2a/intro/`, `evaluate/` index) — not directly opened this session; workflow-agent behavior is sourced from Google's Developers Blog instead.
- arXiv:2512.08296, "Towards a Science of Scaling Agent Systems" (Google Research / Google DeepMind / MIT) — pointer only; findings NOT read and NOT cited.
- ADK 2.0 graph Workflow Runtime, GA dates, and A2A v1.0 release date — seen only in secondary summaries that disagree with each other; treated as unverified, no dates stated in this brief.
- `browser.open` rate limit note: after the first four successful fetches, a batch of four further opens returned HTTP 429; subsequent single opens (spaced ~60–75 s apart) succeeded. Two of the four batched URLs (Kaggle Companion landing, adk.dev home) were therefore never read and are listed above as CHƯA ĐỌC.

---

## Tóm tắt tiếng Việt

Google làm multi-agent theo hai lớp tách biệt: **workflow agent quyết định thứ tự** (Sequential chạy nối tiếp, Parallel chạy song song rồi gom lại, Loop lặp tới khi đạt điều kiện dừng), còn **LLM agent chỉ quyết định nội dung** trong từng bước. Điểm mấu chốt cho loop của chúng ta: **vòng lặp phải nằm trong code điều khiển (driver), không nằm trong tiến trình của agent** — đó là cách sửa lỗi agent chết giữa chừng (probe-4): mỗi stage chạy một lần, đọc/ghi file theo tên khóa cố định, chết thì driver chạy lại đúng stage đó. Thứ hai, **cần tín hiệu dừng sớm**: grader phải trả `VERDICT: PASS/FAIL` dạng máy đọc được, PASS thì dừng ngay, đừng đốt hết 3 round; fixer chỉ sửa đúng top-2 lỗi đã liệt kê. Thứ ba, **hợp đồng kiểu A2A nhưng viết bằng file**: mỗi assistant có một "card" ghi rõ kỹ năng + input/output, mỗi task có trạng thái (`submitted → working → input-required → completed/failed`); thiếu dữ liệu thì trả `input-required` kèm một câu hỏi cụ thể, tuyệt đối không đoán mò. Thứ tư, **chấm hai trục như ADK**: vừa chấm quỹ đạo (có chạy gate trước screenshot không) vừa chấm sản phẩm, rubric là danh sách yes/no có trích dẫn bằng chứng; còn token/thời gian chỉ ghi log tham khảo, không dùng để đánh trượt. Những thứ **không** mang sang được: bản thân framework ADK, wire protocol A2A đầy đủ (JSON-RPC/SSE/webhook), và bộ đánh giá quản lý của Vertex AI — tất cả đều tốn thời gian setup, cần tài khoản GCP, và không cần thiết khi 4 agent đã chung một repo. Chỉ lấy mẫu hình (pattern) và hình dạng hợp đồng, không lấy hạ tầng.
