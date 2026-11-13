# OpenAI — Agents SDK, Swarm, Codex Loops, Evals & Self-Critique

**Area:** 2 of 7 — OpenAI (Agents SDK, Swarm patterns, Codex agent loops, evals and self-critique)
**Project:** muse-fleet / Codex Hackathon Hanoi, Sat 14/11/2026 — 5-hour build sprint (11:00–16:00), demo on a real phone = 40/100 points
**Our stack (for transfer judgements):** Expo SDK 58, Convex Free, Supabase Edge Function Free, gemini-3.5-flash-lite (free) primary, Groq `openai/gpt-oss-120b` fallback. Taste-locked deterministic-gate loop (frontend-agent-kit): taste lock → build → gate first → screenshots + independent grading → fix top 2 → stop when gates green or after 3 rounds. Known failure: agents die mid-loop (`-p` mode treats the agent's final response as process end — probe-4 yield death). GUARD/security training is NOT ship-ready (pilot only). Budget $0.00.
**Access date for all claims below: 2026-11-13.**
**Method:** free legal sources only; every claim below was READ on its primary page unless marked **CHƯA ĐỌC**. Search snippets were never used as evidence. A claim marked CHƯA ĐỌC is not verified — do not build on it.

## Sources read (primary)

| # | Source | URL | Read status |
|---|--------|-----|-------------|
| S1 | OpenAI Agents SDK docs — home | https://openai.github.io/openai-agents-python/ | Read in full (2026-11-13) |
| S2 | OpenAI Agents SDK — Agent orchestration | https://openai.github.io/openai-agents-python/multi_agent/ | Read in full (2026-11-13) |
| S3 | OpenAI Swarm — GitHub README | https://github.com/openai/swarm | Read in full (2026-11-13) |
| S4 | OpenAI Cookbook — Orchestrating Agents: Routines and Handoffs | https://developers.openai.com/cookbook/examples/orchestrating_agents | Read lines 0–581 of 994 — PARTIAL (handoff implementation tail not read) |
| S5 | OpenAI — Unrolling the Codex agent loop (Michael Bolin) | https://openai.com/index/unrolling-the-codex-agent-loop/ | Read in full (2026-11-13) |
| S6 | OpenAI Platform — Working with evals | https://platform.openai.com/docs/guides/evals | Read lines 0–529 of 640 — PARTIAL (results analysis / iteration tail not read) |

## Sources NOT read (CHƯA ĐỌC — rate-limited, 429, at the end of the session)

- Agents SDK **Guardrails** doc page and **Handoffs** doc page (`openai.github.io/openai-agents-python/…`) — fetch blocked by rate limit; guardrail scoping rules below are marked CHƯA ĐỌC.
- Agents SDK **Running agents** doc page (sessions, `max_turns`, resume) — CHƯA ĐỌC.
- OpenAI — Introducing the Agents API (public beta, 10 Sep 2026), https://openai.com/index/introducing-the-agents-api/ — CHƯA ĐỌC.
- OpenAI — Unlocking the Codex harness (companion post to S5) — CHƯA ĐỌC.
- `openai/evals` open-source framework README (https://github.com/openai/evals) — CHƯA ĐỌC.
- Cookbook S4 lines 582–994 and evals guide S6 lines 530–640 — CHƯA ĐỌC.

---

## 1. What OpenAI actually does

### 1.1 Agents SDK — three primitives, nothing more

- The Agents SDK "enables you to build agentic AI apps in a lightweight, easy-to-use package with very few abstractions" and is "a production-ready upgrade of our previous experimentation for agents, Swarm". Its primitives are exactly three: **Agents** (LLMs equipped with instructions and tools), **Agents as tools / Handoffs** (agents delegating to other agents), and **Guardrails** (validation of agent inputs and outputs). It also ships built-in **tracing** "that lets you visualize and debug your agentic flows, as well as evaluate them and even fine-tune models for your application." (S1, accessed 2026-11-13)
- Two design principles: "Enough features to be worth using, but few enough primitives to make it quick to learn" and "Works great out of the box, but you can customize exactly what happens." (S1, accessed 2026-11-13)
- Feature list (S1): agents with "a built-in loop that continues until the task is complete"; **sandbox agents** ("Run specialists inside real isolated workspaces… resumable sandbox sessions"); realtime/voice agents; function tools with automatic schema generation and Pydantic validation; MCP server tool calling; **sessions** ("a persistent memory layer for maintaining working context within an agent loop"); **human in the loop**; tracing.
- **SDK vs Responses API (S1):** "Use the Responses API directly when you want to own the loop, tool dispatch, and state handling yourself" and your workflow is short-lived. "Use the Agents SDK when you want the runtime to manage turns, tool execution, guardrails, handoffs, or sessions", when the agent "should produce artifacts or operate across multiple coordinated steps", or when you "need a real workspace or resumable execution". "You do not need to choose one globally."
- The SDK uses the Responses API by default for OpenAI models but wraps model calls in a higher-level runtime (S1).

### 1.2 Orchestration — LLM-decided vs code-decided, and the two multi-agent patterns

- "Orchestration refers to the flow of agents in your app. Which agents run, in what order, and how is the next step decided? There are two main ways to orchestrate agents: (1) Allowing the LLM to make decisions… (2) Orchestrating via code: determining the flow of agents via your code. You can mix and match these patterns." (S2, accessed 2026-11-13)
- **Agents as tools vs handoffs (S2):** "Agents as tools — A manager agent keeps control of the conversation and calls specialist agents through `Agent.as_tool()`. Best when you want one agent to own the final answer, combine outputs from multiple specialists, or enforce shared SDK guardrails in one place." "Handoffs — A triage agent routes the conversation to a specialist, and that specialist becomes the active agent for the rest of the turn. Best when you want the specialist to respond directly, keep prompts focused, or have the handoff switch the active instructions without requiring the manager to narrate the result." Rule of thumb: "Use agents as tools when a specialist should help with a bounded subtask but should not take over the user-facing conversation. Use handoffs when routing itself is part of the workflow." The two combine: "A triage agent might hand off to a specialist, and that specialist can still call other agents as tools for narrow subtasks." (S2, accessed 2026-11-13)
- **Tactics for LLM-orchestrated work (S2):** (1) "Invest in good prompts. Make it clear what tools are available, how to use them, and what constraints the agent must follow." (2) "Monitor your app and iterate on it. See where things go wrong, and iterate on your prompts." (3) "Allow the agent to introspect and improve. For example, run it in a loop, and let it critique itself; or, provide error messages and let it improve." (4) "Have specialized agents that excel in one task, rather than having a general purpose agent that is expected to be good at anything." (5) "Invest in evals. This lets you train your agents to improve and get better at tasks." (S2, accessed 2026-11-13)
- **Code-orchestrated patterns (S2):** "While orchestrating via LLM is powerful, orchestrating via code makes tasks more deterministic and predictable, in terms of speed, cost and performance." The documented patterns are: structured outputs to classify then pick the next agent in code; chaining agents by transforming one output into the next input ("do research, write an outline, write the blog post, critique it, and then improve it"); **"In each iteration of a `while` loop, run the task agent to produce an output, then run an evaluator agent to assess that output and provide feedback; stop when the evaluator says the output passes the required criteria"**; and running multiple agents in parallel (e.g. `asyncio.gather`) for independent tasks. (S2, accessed 2026-11-13)

### 1.3 Swarm — the pattern ancestor (experimental, superseded)

- "Swarm is now replaced by the OpenAI Agents SDK, which is a production-ready evolution of Swarm. The Agents SDK features key improvements and will be actively maintained by the OpenAI team. We recommend migrating to the Agents SDK for all production use cases." (S3, accessed 2026-11-13)
- "Swarm focuses on making agent coordination and execution lightweight, highly controllable, and easily testable. It accomplishes this through two primitive abstractions: `Agent`s and handoffs. An `Agent` encompasses `instructions` and `tools`, and can at any point choose to hand off a conversation to another `Agent`." (S3, accessed 2026-11-13)
- "Swarm Agents are not related to Assistants in the Assistants API… Swarm is entirely powered by the Chat Completions API and is hence stateless between calls." It "runs (almost) entirely on the client and, much like the Chat Completions API, does not store state between calls." (S3, accessed 2026-11-13)
- The core loop, `client.run()` (S3): "1. Get a completion from the current Agent. 2. Execute tool calls and append results. 3. Switch Agent if necessary. 4. Update context variables, if necessary. 5. If no new function calls, return." `run()` "takes `messages` and returns `messages` and saves no state between calls", but "also handles Agent function execution, hand-offs, context variable references, and can take multiple turns before returning to the user." (S3, accessed 2026-11-13)
- Boundedness: `max_turns` — "The maximum number of conversational turns allowed" — defaults to `float("inf")`, i.e. **unbounded unless the developer sets it**. (S3, accessed 2026-11-13)
- Handoff mechanics (S3): "If a function returns an `Agent`, execution will be transferred to that `Agent`." A function may also return a `Result` carrying a value, a new agent, and updated `context_variables` together. "If an `Agent` calls multiple functions to hand-off to an `Agent`, only the last handoff function will be used." Only the active agent's `instructions` are present as the system prompt at any time: "if there is an `Agent` handoff, the `system` prompt will change, but the chat history will not." (S3, accessed 2026-11-13)
- Error recovery (S3): "If an `Agent` function call has an error (missing function, wrong argument, error) an error response will be appended to the chat so the `Agent` can recover gracefully." (S3, accessed 2026-11-13)
- Evals in Swarm (S3): "Evaluations are crucial to any project, and we encourage developers to bring their own eval suites to test the performance of their swarms. For reference, we have some examples for how to eval swarm in the `airline`, `weather_agent` and `triage_agent` quickstart examples." No eval framework ships with Swarm. (S3, accessed 2026-11-13)

### 1.4 Cookbook — routines and handoffs (the idea Swarm implements)

- A **routine** is "a list of instructions in natural language (which we'll represent with a system prompt), along with the tools necessary to complete them." Routines contain conditionals "much like a state machine or branching in code" and "LLMs can actually handle these cases quite robustly for small and medium-sized routines, with the added benefit of 'soft' adherence – the LLM can naturally steer the conversation without getting stuck in dead-ends." (S4, accessed 2026-11-13)
- The execution loop `run_full_turn` (S4): call the model, append the response, execute any tool calls and append their results, repeat "in a loop until there are no more tool calls". (S4, accessed 2026-11-13)
- A **handoff** is "an agent (or routine) handing off an active conversation to another agent, much like when you get transferred to someone else on a phone call. Except in this case, the agents have complete knowledge of your prior conversation!" (S4, accessed 2026-11-13)
- Scaling limit (S4): growing one routine with too many tasks makes it struggle; the fix is multiple routines with handoffs between them — "Dynamically swapping system instructions and tools… if we view 'routines' as 'agents', then this notion of handoffs allow us to represent these swaps simply – as one agent handing off a conversation to another." (S4, accessed 2026-11-13)
- Note: S4 lines 582–994 (the concrete handoff code and worked example) are CHƯA ĐỌC.

### 1.5 Codex — the agent loop, termination, caching, compaction

- Definition (S5): "At the heart of every AI agent is something called 'the agent loop'"; it orchestrates "the interaction between the user, the model, and the tools the model invokes to perform meaningful software work." The loop: build a prompt from user input → inference → the model either produces a final response or requests a tool call → execute the tool, append its output to the prompt, re-query → repeat "until the model stops emitting tool calls and instead produces a message for the user (referred to as an *assistant message*)". (S5, accessed 2026-11-13)
- **The assistant message is a termination signal, not the deliverable (S5):** "Because the agent can execute tool calls that modify the local environment, its 'output' is not limited to the assistant message. In many cases, the primary output of a software agent is the code it writes or edits on your machine. Nevertheless, each turn always ends with an assistant message — such as 'I added the `architecture.md` you asked for' — which signals a termination state in the agent loop. From the agent's perspective, its work is complete and control returns to the user." (S5, accessed 2026-11-13)
- One turn ("a *thread* in Codex") can include many inference/tool iterations; every new message re-sends the full conversation history, so prompt length grows with the conversation and "context window management is one of the agent's many responsibilities". An agent "could decide to make hundreds of tool calls in a single turn, potentially exhausting the context window." (S5, accessed 2026-11-13)
- Inference runs over the **Responses API**; the endpoint is configurable (ChatGPT backend, `https://api.openai.com/v1/responses`, local `gpt-oss` via Ollama/LM Studio, or Azure). The request carries `instructions` (system/developer message), `tools`, and `input` (text/image/file items). Roles have decreasing priority: `system`, `developer`, `user`, `assistant`. (S5, accessed 2026-11-13)
- Initial-prompt construction (S5): Codex inserts, before the user message, a `developer` message describing the sandbox (applies only to the Codex-provided `shell` tool; MCP tools "are not sandboxed by Codex and are responsible for enforcing their own guardrails"); optional `developer_instructions` from config; user instructions aggregated from `AGENTS.md` / `AGENTS.override.md` files from the project root up to the cwd (subject to a 32 KiB default limit), plus skill metadata; and a `user` message describing the local environment (cwd, shell). (S5, accessed 2026-11-13)
- **Prompt caching (S5):** the old prompt is "an exact prefix" of the new prompt by design, which enables prompt caching. "Cache hits are only possible for exact prefix matches within a prompt. To realize caching benefits, place static content like instructions and examples at the beginning of your prompt, and put variable content, such as user-specific information, at the end. This also applies to images and tools, which must be identical between requests." Cache misses are caused by: changing the tools mid-conversation, changing the model, changing sandbox configuration / approval mode / cwd. Codex handles mid-conversation config changes "by appending a *new* message to `input` to reflect the change rather than modifying an earlier message". Even an MCP tool-list ordering bug once caused cache misses. (S5, accessed 2026-11-13)
- **Quadratic cost, linear sampling (S5):** "the agent loop [is] *quadratic* in terms of the amount of JSON sent to the Responses API over the course of the conversation". Codex deliberately does NOT use `previous_response_id`, "primarily to keep requests fully stateless and to support Zero Data Retention (ZDR) configurations". "Generally, the cost of sampling the model dominates the cost of network traffic… When we get cache hits, *sampling the model is linear rather than quadratic*." (S5, accessed 2026-11-13)
- **Compaction (S5):** "Our general strategy to avoid running out of context window is to *compact* the conversation once the number of tokens exceeds some threshold. Specifically, we replace the `input` with a new, smaller list of items that is representative of the conversation." The Responses API now has a `/responses/compact` endpoint that "returns a list of items that can be used in place of the previous `input`… This list includes a special `type=compaction` item with an opaque `encrypted_content` item that preserves the model's latent understanding of the original conversation. Now, Codex automatically uses this endpoint to compact the conversation when the `auto_compact_limit` is exceeded." (S5, accessed 2026-11-13)

### 1.6 Evals — dataset + graders, and a platform that is shutting down

- "Evaluations (often called **evals**) test model outputs to ensure they meet style and content criteria that you specify. Writing evals… is an essential component to building reliable applications." Building an eval has three steps: "1. Describe the task to be done as an eval. 2. Run your eval with test inputs (a prompt and input data). 3. Analyze the results, then iterate and improve on your prompt." The guide compares this to behavior-driven development: "you begin by specifying how the system should behave before implementing and testing the system." (S6, accessed 2026-11-13)
- An eval has two ingredients (S6): `data_source_config` — "A schema for the test data you will use along with the eval" — and `testing_criteria` — "The graders that determine if the model output is correct." Test data is a JSONL file of items, each with inputs plus a human-provided ground-truth label; a run generates a model response for every row, grades each row, and aggregates into pass/fail counts (`result_counts`: total / errored / failed / passed). Graders include `string_check` (exact match against the reference). Runs are asynchronous (queued → in_progress → completed/failed) and report via webhooks (`eval.run.succeeded`, `eval.run.failed`, `eval.run.canceled`). (S6, accessed 2026-11-13)
- **Deprecation — read on the live page (S6):** "OpenAI is deprecating the Evals platform. Existing evals content remains available during the transition window. Evals will become read-only for existing users on October 31, 2026, and the platform is scheduled to shut down on November 30, 2026… If you're new to evaluations, or want a more iterative environment to experiment in as you build your eval, consider trying Datasets instead." (S6, accessed 2026-11-13)
- S6 lines 530–640 (result analysis / iteration guidance) are CHƯA ĐỌC.

### 1.7 Self-critique / self-improvement — what OpenAI documents, and what it does not

- Documented (S2): "Allow the agent to introspect and improve. For example, run it in a loop, and let it critique itself; or, provide error messages and let it improve." And: "Invest in evals. This lets you train your agents to improve and get better at tasks." (S2, accessed 2026-11-13)
- Documented as a code pattern (S2): the `while`-loop with a **separate evaluator agent** that assesses output and gives feedback, stopping "when the evaluator says the output passes the required criteria"; and the chained critique step ("write the blog post, critique it, and then improve it"). (S2, accessed 2026-11-13)
- Documented as error-driven recovery (S3): on a failed tool call, "an error response will be appended to the chat so the Agent can recover gracefully" — i.e. the loop improves from tool-error feedback, not from self-praise. (S3, accessed 2026-11-13)
- **Not found in the sources read:** any OpenAI claim that a single agent reliably grades its own output, any "self-critique beats independent grading" result, and any reinforcement/self-training loop that runs inside the SDK. The documented self-improvement mechanisms are: (a) a loop with a separate evaluator, (b) error messages fed back in, (c) prompt iteration driven by monitoring and by eval scores. Claims about evaluator skepticism / self-grading unreliability from other labs are CHƯA ĐỌC (seen only in a secondary blog snippet, not verified against a primary source — do not cite).

### 1.8 Guardrails — only the thin verified layer

- Verified (S1): "Guardrails: Run input validation and safety checks in parallel with agent execution, and fail fast when checks do not pass." Guardrails are one of the three SDK primitives, "which enable validation of agent inputs and outputs". (S1, accessed 2026-11-13)
- **CHƯA ĐỌC — do not treat as verified:** the widely repeated rules that input guardrails run only on the first agent in a chain, output guardrails only on the agent producing the final output, and that a tripwire raises `GuardrailTripwireTriggered` / `InputGuardrailTripwireTriggered`. These appear in secondary write-ups, but the SDK guardrails doc page itself was not read (rate-limited). Verify before encoding them in any gate design.

---

## 2. What transfers to our loop — and how

Our loop: taste lock → build → deterministic gates first → screenshots + independent grading → fix top 2 → stop when gates green or after 3 rounds. Coordinator (Muse) drives four CLI subagents; the harness is prompts + files, not a Python SDK.

| # | OpenAI pattern (source) | Transfer to frontend-agent-kit | Concrete change |
|---|---|---|---|
| T1 | **Code-orchestrated `while` loop with a separate evaluator; stop when the evaluator passes** (S2) | This is already our loop's shape — OpenAI documents it as the deterministic option. Keep the loop in the *coordinator's code/prompt*, not inside any single agent's turn. | No change to shape. Write the stop condition as a counted bound in the coordinator prompt: "round counter starts at 1; stop after round 3 even if red." Never let the builder decide it is done. |
| T2 | **Assistant message = termination signal, NOT the deliverable; the deliverable is the files on disk** (S5) | Direct diagnosis of probe-4 yield death: `-p` mode ends the process when the agent emits its final message, so a builder that "finishes" by talking kills the loop. The fix is architectural, not motivational. | Harness rule: after every agent process exits, the coordinator verifies *files + gates*, never the final text. The agent's closing message is logged and ignored as proof. Spawn the next round as a fresh process with a fresh, compact brief. Do not ask an agent to "continue" in the same turn. |
| T3 | **Agents-as-tools: the manager owns the final answer; specialists do bounded subtasks** (S2) | Fits our coordinator + builder/grader better than peer handoffs. The coordinator keeps control and combines results; the grader is a bounded check, not a co-owner of the conversation. | Keep grading as a separate agent invoked by the coordinator with a fixed input (build output + gate results + screenshots) and a fixed output schema (pass/fail per gate + top-2 fixes). The grader never talks to the builder directly. |
| T4 | **Handoff = transfer with full prior conversation; only the active agent's instructions are live** (S3, S4) | Our "handoffs" are coordinator-written briefs to fresh subagents. The Swarm rule that matters: the receiving agent sees history but only its own instructions are active. | Every round brief must be self-contained: restate the taste lock, the gate list, and the top-2 fixes in the brief itself. Never rely on the previous agent's context surviving. Pass a compact handoff (spec + diff + gate results), not the full transcript. |
| T5 | **Routine = natural-language steps + tools; "soft adherence"** (S4) | The taste lock is a routine: a written sequence (lock → build → gate → grade → fix) with its tools (gate script, screenshot, grader). "Soft adherence" is why the routine alone cannot enforce gates — see T6. | Keep the taste lock as one short written routine at the top of every brief. Keep it static across rounds (see T8). |
| T6 | **Code orchestration is "more deterministic and predictable, in terms of speed, cost and performance" than LLM orchestration** (S2) | Justifies gate-first: deterministic checks (build passes, files exist, screens render) run before any LLM grading, and a deterministic gate failure blocks the round without spending a grading call. | Order per round: (1) deterministic gates, (2) only if green, screenshots + LLM grade. A red deterministic gate = fix round with no grader call. |
| T7 | **Evaluator separate from generator; error messages fed back for recovery** (S2, S3) | Corroborates "builder never self-grades". The feedback channel is structured gate output, not free-form self-review. | Grader input = gate results + screenshots + the brief's acceptance criteria. Builder's next brief = grader's top-2 fixes + failing gate output verbatim. Never ask the builder "did you do a good job?" |
| T8 | **Prompt caching: static content first, variable content last; never mutate earlier messages; append changes as new messages** (S5) | Our models (Gemini free tier, Groq) do not offer the Responses API's exact-prefix cache, so the cost claim does NOT transfer — but the *discipline* does: a stable prompt prefix keeps behaviour stable and keeps the brief short. | Freeze the taste lock + gate spec verbatim across all rounds of one sprint. Put the round-specific part (top-2 fixes, failing gate output) at the end of the brief. Never rewrite the lock mid-loop; if the lock must change, start a new loop with a new brief. |
| T9 | **Compaction when the context grows; fresh subagent = fresh context** (S5) | Codex compacts or delegates to keep turns short; our equivalent is cheap because spawning is free: never let one agent accumulate the whole sprint. | One agent = one round, one bounded task. Coordinator carries only: taste lock, current gate table, last screenshots, top-2 fixes. Drop everything else between rounds. This also bounds the quadratic prompt-growth problem (S5) on our side. |
| T10 | **Eval = dataset + graders; JSONL rows with ground truth; per-row pass/fail aggregated** (S6) | Our gate suite is a tiny eval. Treating it as one makes regressions visible across rounds. | Keep a `gates.jsonl`-style log: one row per gate per round (gate id, pass/fail, evidence path). The coordinator's stop decision reads the table, not a chat message. Keep past failing cases as regression rows for the next sprint. |
| T11 | **Tracing: every run, tool call, handoff and guardrail is a recorded span** (S1) | Our run-log is the same idea at $0. | Keep the append-only run log (one JSON object per line, trailing newline — the known JSONL glue bug). Log: brief hash, agent, round, gate table, grader verdict. The log is the audit trail if a round is disputed. |
| T12 | **Guardrails run in parallel and fail fast** (S1) | Our GUARD is a cheap pre-check, not a post-mortem. Even in pilot form, a fail-fast check before the build saves the most expensive step (the build + grade round). | Run GUARD (prompt-injection / scope check on the brief) before spawning the builder each round. A GUARD trip = hard stop for that round, logged, no build. Do not let the builder re-judge the GUARD verdict. |
| T13 | **`max_turns` defaults to infinity in Swarm — always set an explicit bound** (S3) | Our 3-round cap is the same lesson, stated as a number. | State the bound in the coordinator prompt and enforce it in the coordinator's own counting, not by asking the model to count. |

## 3. What does NOT transfer — and why

| # | OpenAI thing | Why it does not transfer to our sprint |
|---|---|---|
| N1 | **Agents SDK as a runtime** (S1, S2) | It is a Python library over OpenAI's Responses API. Our agents are Muse CLI subagents driven by prompts; there is no shared runtime, no `Runner`, no `Agent.as_tool()`. Import the *patterns* (T1–T13), not the library. Rewriting our harness on the SDK would cost the sprint and need a paid OpenAI key. |
| N2 | **Swarm as a framework** (S3) | Deprecated, educational, unmaintained, "not intended to be used in production". Cite it only as the origin of the routines/handoffs vocabulary. Do not install or build on it. |
| N3 | **OpenAI Evals platform** (S6) | Read-only since 31 Oct 2026, **shutting down 30 Nov 2026**. Do not adopt it, do not create an account for it, do not cite it as a live dependency. Take only the *shape* (dataset + graders + per-row aggregation, T10), implemented locally as JSONL + scripts at $0. |
| N4 | **Prompt caching / `/responses/compact` / `previous_response_id`** (S5) | Responses-API mechanics. Gemini free tier and Groq do not expose them the same way; the linear-vs-quadratic cost claim is OpenAI-specific and must not be quoted as our cost model. The transferable part is prompt discipline (T8) and fresh-context-per-round (T9), not the API features. |
| N5 | **Hosted sandboxes / sandbox agents / Agents API hosted harness** (S1; Agents API announcement CHƯA ĐỌC) | Paid, OpenAI-hosted, needs an OpenAI account and key. Our isolation is git branches/worktrees and separate processes on the VM/laptop. Do not claim parity with a sandbox; a builder agent on our machine can touch anything its process can reach, which is exactly why GUARD + gate-first matter more for us, not less. |
| N6 | **Sessions / resumable execution / human-in-the-loop as SDK features** (S1) | We have no session layer; "resume" for us means "re-spawn with a compact brief" (T4, T9). Human-in-the-loop for us is the coordinator reading the gate table between rounds — do not design a flow that assumes the SDK will pause and resume an agent for us. |
| N7 | **Self-critique as a sufficient quality mechanism** (S2 tactic 3) | OpenAI lists "let it critique itself" as one tactic among five, and its stronger documented pattern is the *separate* evaluator loop. It is not evidence that self-grading works. Keep the independent grader; never downgrade it to builder self-review to save a call. Any claim that self-grading is unreliable (or reliable) from other labs is CHƯA ĐỌC — do not cite it either way. |
| N8 | **Codex's ZDR / statelessness tradeoff** (S5) | A privacy/compliance choice (not using `previous_response_id` so requests stay stateless for Zero Data Retention customers). Irrelevant to a $0 local sprint; our state lives in files and the run log by design. |
| N9 | **Long-running cloud sessions, Goals, automations** (not read in primary sources) | Long-horizon Codex features assume a hosted product and an account. Our sprint is 5 hours, local, bounded by T13. Do not plan a "let it run overnight" path on OpenAI's cloud. |
| N10 | **Guardrail scoping rules (input-only-first-agent / output-only-last-agent / tripwire exception names)** | **CHƯA ĐỌC.** They appear in secondary write-ups but the SDK guardrails page was not read. Do not encode them as facts in GUARD or gate design until the primary page is read. What is verified is only the thin layer in §1.8. |
| N11 | **Tracing dashboard (`platform.openai.com/traces`)** (S1) | Needs an OpenAI Platform account. Our equivalent is the local run log (T11). Do not promise a dashboard. |
| N12 | **"Train your agents to improve" via evals + fine-tuning** (S1, S2) | "Invest in evals. This lets you train your agents to improve" — in OpenAI's world that road leads to fine-tuning/distillation on their platform (paid, needs data volume). In a 5-hour $0 sprint, "improvement" means prompt iteration between rounds, not model training. Do not propose fine-tuning. |

## 4. Recommended loop shape (synthesis — derived from §2, not an OpenAI quote)

```
coordinator (code/prompt, owns counter + gate table)
  round = 1..3
    1. GUARD brief (fail-fast; trip = stop round, log)
    2. spawn BUILDER with frozen brief: [taste lock + gate spec (static prefix)]
       + [round fixes + failing gate output (variable suffix)]
    3. process exits -> IGNORE final message as proof (S5: termination signal only)
    4. deterministic gates on files (no LLM call if red) -> update gate table
    5. if gates green: screenshots -> spawn GRADER (separate agent, fixed schema)
       -> top-2 fixes; if pass, STOP
    6. round += 1; carry forward ONLY: lock, gate table, screenshots, top-2 fixes
  stop: gates green OR round > 3. Log every step append-only (JSONL).
```

Three rules that fall straight out of the sources: **(a)** the loop lives in the coordinator, never inside one agent's turn (S2, S5); **(b)** the deliverable is files + gate table, never the agent's closing words (S5); **(c)** the evaluator is a different agent from the builder, fed structured evidence (S2, S3).

## 5. Gaps / what still needs reading

- SDK Guardrails + Handoffs + Running-agents doc pages (rate-limited 429 on 2026-11-13) — needed to verify guardrail scoping/tripwire rules before encoding them.
- Agents API announcement (10 Sep 2026 public beta) — to confirm what the hosted harness actually covers vs the SDK.
- Cookbook S4 lines 582–994 and evals guide S6 lines 530–640 (tails not read).
- `openai/evals` OSS README — the offline, $0-relevant eval framework; likely the closest thing to a reusable local eval harness, but unverified.
- "Unlocking the Codex harness" (companion to S5) — app-server / parallelism layer, possibly relevant to running our four agents concurrently.

---

## Tóm tắt tiếng Việt

**OpenAI làm gì (đã đọc nguồn chính, ngày 13/11/2026):**

- **Agents SDK** chỉ có 3 khái niệm gốc: Agent (LLM + hướng dẫn + công cụ), Handoff / Agents-as-tools (ủy quyền giữa các agent), Guardrail (kiểm tra đầu vào/đầu ra, fail nhanh). Kèm theo tracing sẵn có. Đây là bản production thay thế Swarm.
- **Điều phối có 2 cách:** để LLM tự quyết định, hoặc điều phối bằng code. OpenAI nói rõ điều phối bằng code "xác định và dự đoán được hơn về tốc độ, chi phí và hiệu năng". Hai mẫu chính: *agents-as-tools* (manager giữ quyền trả lời cuối, gọi chuyên gia làm việc nhỏ) và *handoff* (chuyển hẳn cuộc hội thoại cho chuyên gia).
- **Mẫu lặp có evaluator riêng:** chạy agent làm việc, rồi chạy một evaluator agent khác chấm, lặp trong vòng `while` cho tới khi evaluator nói đạt. Ngoài ra có chiến thuật "để agent tự phê bình chính nó", nhưng mẫu được tài liệu hóa mạnh nhất vẫn là evaluator tách riêng.
- **Swarm** (tiền thân) đã bị thay thế, chỉ mang tính giáo dục, không dùng production. Vòng lặp của nó: gọi model → chạy tool → đổi agent nếu cần → lặp tới khi hết tool call. `max_turns` mặc định là vô cực — phải tự đặt giới hạn.
- **Codex agent loop:** prompt → suy luận → gọi tool hoặc trả lời cuối. Tin nhắn cuối của agent chỉ là *tín hiệu kết thúc*, không phải sản phẩm — sản phẩm thật là code ghi ra đĩa. Prompt dài lên theo từng lượt (tăng bậc hai), Codex chống lại bằng prompt caching (nội dung tĩnh đặt trước, nội dung thay đổi đặt sau, không sửa tin nhắn cũ) và compaction (nén hội thoại khi vượt ngưỡng).
- **Evals:** một eval = bộ dữ liệu kiểm tra (JSONL, có đáp án đúng) + grader chấm từng dòng, tổng hợp tỉ lệ pass/fail. Lưu ý quan trọng: **nền tảng Evals của OpenAI đang bị khai tử — chỉ đọc từ 31/10/2026, đóng hẳn 30/11/2026**, nên không dùng nó, chỉ học theo hình dạng dataset + grader.
- **Guardrail:** chỉ xác minh được lớp mỏng — kiểm tra chạy song song và fail nhanh. Các quy tắc chi tiết (guardrail đầu vào chỉ chạy ở agent đầu, v.v.) chưa đọc được nguồn chính nên đánh dấu CHƯA ĐỌC, không dùng làm căn cứ.

**Chuyển được sang loop của chúng ta:**

- Giữ vòng lặp ở coordinator (đếm vòng, bảng gate), không để trong một lượt của agent — đây là cách chữa trực tiếp lỗi probe-4 (agent "nói xong" là process kết thúc).
- Sau mỗi lần agent thoát, chỉ tin file trên đĩa + kết quả gate, không tin lời kết của agent.
- Builder không bao giờ tự chấm; grader là agent riêng, nhận đầu vào có cấu trúc (kết quả gate + screenshot).
- Gate xác định chạy trước, chỉ khi xanh mới gọi grader (tiết kiệm lượt gọi).
- Brief mỗi vòng tự chứa đầy đủ (taste lock + gate + 2 lỗi cần sửa), phần tĩnh đặt trước, phần thay đổi theo vòng đặt sau; mỗi agent chỉ làm một vòng rồi thôi, không tích lũy hội thoại dài.
- Log append-only dạng JSONL (một object một dòng) như tracing của OpenAI.

**Không chuyển được:**

- SDK, Responses API, prompt caching, `/responses/compact`, sandbox host, Agents API, tracing dashboard — tất cả đều gắn với tài khoản/trả phí OpenAI, không có trong stack $0 (Gemini free + Groq) của chúng ta.
- Nền tảng Evals đã đóng; Swarm đã bị thay thế.
- Không dùng "tự phê bình" thay cho grader độc lập; không đề xuất fine-tune model trong sprint 5 giờ.
