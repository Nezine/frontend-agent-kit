# Frameworks Brief — Multi-Agent Loop Patterns

**Area:** 5 of 7 — FRAMEWORKS (LangGraph / LangChain, Microsoft AutoGen, CrewAI)
**Project:** muse-fleet / Codex Hackathon — taste-locked deterministic-gate loop (frontend-agent-kit)
**Access date for all sources below:** 2026-11-13
**Author:** research worker (subagent), reported to coordinator
**Sources policy:** FREE LEGAL SOURCES ONLY. Every factual claim below carries a URL + access date.
Pages marked **READ** were opened and read in full with `browser.open` in this session.
Pages marked **CHƯA ĐỌC** were NOT read in full in this session (see §5) — nothing from
them is presented as an established claim; search-snippet content is never quoted as fact.

## Read ledger (this session)

| # | Source | Status |
|---|--------|--------|
| R1 | AutoGen — Teams tutorial (microsoft.github.io) | READ |
| R2 | CrewAI — Crews (docs.crewai.com) | READ |
| R3 | CrewAI — Processes (docs.crewai.com) | READ |
| R4 | Argus research dossier on LangChain/LangGraph (github.com/x32studio/argus) — secondary source that quotes LangGraph source code (`StateGraph`, `Command`) and the LangChain maintainer blog | READ (secondary — see caveat in §1.1) |
| R5 | Automatic.co — AutoGen framework page (third-party consultancy page) | READ (secondary) |
| — | LangGraph official multi-agent concepts docs (langchain-ai.github.io/langgraph → redirects to docs.langchain.com) | CHƯA ĐỌC — the redirect target returned HTTP 429 on `browser.open` at the end of this session |
| — | CrewAI — Flows (docs.crewai.com) | CHƯA ĐỌC — `browser.open` returned HTTP 429 at the end of this session |
| — | AutoGen — Termination tutorial (microsoft.github.io) | CHƯA ĐỌC — only its search-result listing was seen, not the page |

---

## 1. Loop patterns actually documented

### 1.1 LangGraph / LangChain

**Caveat on evidence.** The official LangGraph multi-agent concepts page was not
directly readable in this session (see read ledger). The claims below rest on R4, a
research dossier that was read in full and that grounds its statements in the LangGraph
source (`libs/langgraph/langgraph/graph/state.py`) and the LangChain maintainer blog
*langgraph-multi-agent-workflows*. Treat these as **read-via-secondary-source**, not as
direct primary-doc reads; the coordinator should re-verify against
`https://langchain-ai.github.io/langgraph/` (now redirecting to `https://docs.langchain.com`)
before citing them in repo-facing material.

**Core execution model.**

- LangGraph's kernel is `StateGraph`: "a graph whose nodes communicate by reading and
  writing to a shared state. The signature of each node is `State -> Partial<State>`.
  Each state key can optionally be annotated with a reducer function" (R4, quoting the
  `StateGraph` class docstring).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.
- Execution is Pregel-style supersteps over state channels; compiling with
  `graph.compile(checkpointer=..., store=..., interrupt_before=..., interrupt_after=...)`
  returns a runnable that "streams, invokes, and persists a checkpoint after every
  superstep. That checkpoint-per-step is the foundation of every higher-level feature:
  replay, time-travel, HITL interrupts, and crash-resume" (R4).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.
- `create_react_agent(model, tools, prompt=..., checkpointer=...)` wraps `StateGraph`
  into a two-node ReAct loop (`agent` → `tools` → `agent` …) (R4).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.

**The one handoff primitive, four topologies.** All four topologies are built on the
same `StateGraph` primitive plus the `Command` handoff primitive: "`langgraph.types.Command`
is a special return value from a node *or tool* that bundles a state update with a `goto`
target, allowing control to jump to a named node without a pre-declared edge" (R4).
URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.

- **Supervisor.** "A router node (often an LLM agent whose tools *are* the workers)
  inspects the shared state and dispatches to one worker subgraph per superstep.
  Implemented as `add_conditional_edges(supervisor, route_fn, path_map={...})` with each
  worker as a node — or as a subgraph node" (R4).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.
- **Swarm.** "Peer agents are nodes in one StateGraph; each agent has *handoff tools*
  whose implementation returns `Command(goto="other_agent", update={...})`. Control jumps
  to a peer directly; no central router. Packaged as `langgraph-swarm`" (R4).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.
- **Hierarchical.** "A worker node is itself a compiled `StateGraph` —
  supervisor-of-supervisors. Outer and inner state schemas compose via the optional
  `input_schema` / `output_schema` of the constructor" (R4).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.
- **Network.** "Every agent has handoff tools targeting every other agent; a
  fully-connected swarm. Useful when no clear hierarchy exists" (R4).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.

**How loops terminate.** R4 does not document a dedicated termination primitive; in
the LangGraph model a loop ends when the graph reaches a node with no outgoing edge
(END), when a routing function returns no next node, or when the run hits the
recursion/step limit. **The exact recursion-limit mechanism and the supervisor
`FINISH` convention were NOT verified by a direct read in this session — CHƯA ĐỌC.**
Do not cite a specific `recursion_limit` default from this brief.

**Checkpointing / surviving a dying agent.**

- "Because checkpointing runs at every superstep boundary, `interrupt()` can pause the
  graph and `compile(interrupt_before=[...], interrupt_after=[...])` declares HITL pause
  points; humans can inspect or mutate state and resume from the last step" (R4).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.
- "Short-term memory is just the graph state, persisted by a `Checkpointer` (Memory,
  SQLite, Postgres, Redis)" (R4).
  URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.
- The official LangGraph persistence doc (checkpoint = snapshot of graph state saved at
  every step, organised into threads keyed by `thread_id`; `getState` / `getStateHistory` /
  `updateState`) was **CHƯA ĐỌC** in this session — do not cite its details from this brief.

**Graph vs. conversation framing.** The LangChain maintainer blog, as quoted in R4:
"LangGraph prefers an approach where you explicitly define different agents and
transition probabilities, preferring to represent it as a graph. Autogen frames it more
as a 'conversation'... this 'graph' framing makes it more intuitive and provides better
developer experience for constructing more complex and opinionated workflows" (R4,
quoting the blog *langgraph-multi-agent-workflows*).
URL: https://github.com/x32studio/argus/blob/HEAD/test/topics/open-source-agent-frameworks/records/works_md/langchain.md — accessed 2026-11-13.

### 1.2 Microsoft AutoGen

All claims in this section are from R1, the official AutoGen Teams tutorial, READ in full.

- **What a team is.** "A team is a group of agents that work together to achieve a
  common goal." "Teams are for complex tasks that require collaboration and diverse
  expertise. However, they also demand more scaffolding to steer compared to single
  agents… start with a single agent for simpler tasks, and transition to a multi-agent
  team when a single agent proves inadequate" (R1).
  URL: https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html — accessed 2026-11-13.
- **Round-robin group chat.** "`RoundRobinGroupChat` is a simple yet effective team
  configuration where all agents share the same context and take turns responding in a
  round-robin fashion. Each agent, during its turn, broadcasts its response to all other
  agents, ensuring that the entire team maintains a consistent context" (R1).
  URL: https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html — accessed 2026-11-13.
- **Reflection pattern (critic loop).** "The two-agent team implements the *reflection*
  pattern, a multi-agent design pattern where a critic agent evaluates the responses of
  a primary agent" (R1). In the worked example the critic's system message is:
  "Provide constructive feedback. Respond with 'APPROVE' to when your feedbacks are
  addressed" (R1).
  URL: https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html — accessed 2026-11-13.
- **Termination by keyword.** "We will begin by creating a team with two `AssistantAgent`
  and a `TextMentionTermination` condition that stops the team when a specific word is
  detected in the agent's response" (R1); the example uses
  `text_termination = TextMentionTermination("APPROVE")` and
  `team = RoundRobinGroupChat([primary_agent, critic_agent], termination_condition=text_termination)`
  (R1). "The team runs the agents until the termination condition was met" (R1).
  URL: https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html — accessed 2026-11-13.
- **Stop reason is observable.** "When the team stops, it returns a `TaskResult` object
  with all the messages produced by the agents in the team" (R1); "you can determine the
  reason why the team stopped by checking the `stop_reason` attribute" (R1) — e.g.
  `stop_reason="Text 'APPROVE' mentioned"` (R1).
  URL: https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html — accessed 2026-11-13.
- **Streaming / observability.** "You can stream the team's messages while it is running
  by calling the `run_stream()` method. This method returns a generator that yields
  messages produced by the agents in the team as they are generated, with the final item
  being the `TaskResult` object" (R1).
  URL: https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html — accessed 2026-11-13.
- **External stop (coordinator kill-switch).** "Apart from automatic termination
  conditions such as `TextMentionTermination` … you can also stop the team from outside
  by using the `ExternalTermination`. Calling `set()` on `ExternalTermination` will stop
  the team when the current agent's turn is over. Thus, the team may not stop
  immediately. This allows the current agent to finish its turn and broadcast the final
  message to the team before the team stops, keeping the team's state consistent" (R1).
  Conditions compose with the bitwise OR operator:
  `termination_condition=external_termination | text_termination` (R1).
  URL: https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html — accessed 2026-11-13.
- **Reset vs. resume.** "You can reset the team by calling the `reset()` method. This
  method will clear the team's state, including all agents" (R1). "Teams are stateful
  and maintains the conversation history and context after each run, unless you reset
  the team. You can resume a team to continue from where it left off by calling the
  `run()` or `run_stream()` method again without a new task. `RoundRobinGroupChat` will
  continue from the next agent in the round-robin order" (R1). "It is usually a good
  idea to reset the team if the next task is not related to the previous task. However,
  if the next task is related to the previous task, you don't need to reset and you can
  instead resume the team" (R1).
  URL: https://microsoft.github.io/autogen/0.4.0//user-guide/agentchat-user-guide/tutorial/teams.html — accessed 2026-11-13.
- **No built-in durability (secondary source).** R5, a third-party page read in full,
  states AutoGen "is not, by itself, a workflow engine. It has no built-in durable
  state, no native scheduling, and no answer for what happens when a process dies
  mid-conversation" and advises wrapping conversations "inside a durable layer — Temporal
  or a queue — so that retries, timeouts, and human approvals survive process restarts"
  (R5). Treat as a vendor-neutral secondary claim, not an official-doc claim.
  URL: https://automatic.co/autogen — accessed 2026-11-13.
- **Not verified in this session (CHƯA ĐỌC):** the full list of built-in termination
  conditions (`MaxMessageTermination`, `TimeoutTermination`, `TokenUsageTermination`,
  etc.), `SelectorGroupChat` (LLM-chosen next speaker), `Swarm`, `MagenticOneGroupChat`,
  and `save_state()` / `load_state()` semantics. The official Termination tutorial page
  exists but was not read. Claims about AutoGen being in maintenance mode, and about a
  Microsoft Agent Framework successor, also appeared only in secondary coverage and were
  **not verified by a direct read — CHƯA ĐỌC**.

### 1.3 CrewAI

All claims in this section are from R2 (Crews) and R3 (Processes), the official CrewAI
docs, READ in full. CrewAI Flows were **CHƯA ĐỌC** (see ledger) and are not covered as
established fact.

- **What a crew is.** "A crew in crewAI represents a collaborative group of agents
  working together to achieve a set of tasks. Each crew defines the strategy for task
  execution, agent collaboration, and the overall workflow" (R2).
  URL: https://docs.crewai.com/v1.15.32/en/concepts/crews — accessed 2026-11-13.
- **Sequential process (the default).** "The process flow (e.g., sequential,
  hierarchical) the crew follows. Default is `sequential`" (R2). "Tasks are executed one
  after another, allowing for a linear flow of work" (R2). "Task execution follows the
  predefined order in the task list, with the output of one task serving as context for
  the next. To customize task context, utilize the `context` parameter in the `Task`
  class to specify outputs that should be used as context for subsequent tasks" (R3).
  URLs: https://docs.crewai.com/v1.15.32/en/concepts/crews and https://docs.crewai.com/v1.15.28/en/concepts/processes — accessed 2026-11-13.
- **Hierarchical process (manager pattern).** "A manager agent coordinates the crew,
  delegating tasks and validating outcomes before proceeding. **Note**: A `manager_llm`
  or `manager_agent` is required for this process and it's essential for validating the
  process flow" (R2). "This agent oversees task execution, including planning,
  delegation, and validation. Tasks are not pre-assigned; the manager allocates tasks to
  agents based on their capabilities, reviews outputs, and assesses task completion"
  (R3).
  URLs: https://docs.crewai.com/v1.15.32/en/concepts/crews and https://docs.crewai.com/v1.15.28/en/concepts/processes — accessed 2026-11-13.
- **Only two processes exist.** "The `Process` class is implemented as an enumeration
  (`Enum`), ensuring type safety and restricting process values to the defined types
  (`sequential`, `hierarchical`)" (R3).
  URL: https://docs.crewai.com/v1.15.28/en/concepts/processes — accessed 2026-11-13.
- **Structured output contract per task.** Each task carries an `expected_output` (the
  quality bar and format) — established in R2/R3's task model and in the Crews doc's
  `CrewOutput` contract: "The `CrewOutput` includes the results from the final task
  output, token usage, and individual task outputs" (R2).
  URL: https://docs.crewai.com/v1.15.32/en/concepts/crews — accessed 2026-11-13.
- **Checkpointing / resume (the closest analogue to our crash-resume need).**
  "Checkpointing lets a crew automatically save its state after key events (e.g. task
  completion) so that long-running or interrupted runs can be resumed exactly where they
  left off without re-executing completed tasks" (R2). "Pass `checkpoint=True` to enable
  checkpointing with sensible defaults (saves to `.checkpoints/` after every task)"
  (R2). `CheckpointConfig` controls "location, trigger events, storage backend, and
  retention"; defaults are location `"./.checkpoints"`, `on_events` `["task_completed"]`,
  provider `JsonProvider()` (plain JSON files), `max_checkpoints` `None` (R2). Resume:
  "Use `Crew.from_checkpoint()` to restore a crew from a saved checkpoint file, then
  call `kickoff()` to resume" (R2).
  URL: https://docs.crewai.com/v1.15.32/en/concepts/crews — accessed 2026-11-13.
- **Replay from a task.** "You can now replay from a specific task using our CLI command
  `replay`. … By running the command `crewai replay -t <task_id>`, you can specify the
  `task_id` for the replay process. Kickoffs will now save the latest kickoffs returned
  task outputs locally for you to be able to replay from" (R2).
  URL: https://docs.crewai.com/v1.15.32/en/concepts/crews — accessed 2026-11-13.
- **Hooks between steps.** A `step_callback` "is called after each step of every agent.
  This can be used to log the agent's actions"; a `task_callback` "is called after the
  completion of each task. Useful for monitoring or additional operations post-task
  execution" (R2). `output_log_file` saves logs as `logs.txt` / JSON (R2).
  URL: https://docs.crewai.com/v1.15.32/en/concepts/crews — accessed 2026-11-13.
- **Memory and caching.** "Crews can utilize memory (short-term, long-term, and entity
  memory)"; "Caches can be employed to store the results of tools' execution, making the
  process more efficient by reducing the need to re-execute identical tasks" (R2).
  URL: https://docs.crewai.com/v1.15.32/en/concepts/crews — accessed 2026-11-13.
- **Planning step.** `planning` "adds planning ability to the Crew. When activated
  before each Crew iteration, all Crew data is sent to an AgentPlanner that will plan
  the tasks and this plan will be added to each task description" (R2).
  URL: https://docs.crewai.com/v1.15.32/en/concepts/crews — accessed 2026-11-13.
- **Not verified in this session (CHƯA ĐỌC):** CrewAI Flows (`@start` / `@listen` /
  `@router` / `@persist` / `@human_feedback`), agent `max_iter` defaults, task
  guardrails and `guardrail_max_retries`, and delegation defaults. Do not cite them
  from this brief.

---

## 2. What transfers to our loop — and how

Our loop (taste lock → build → gate first → screenshots + independent grading → fix
top 2 → stop when gates green or 3 rounds) is a **fixed sequential pipeline with a
bounded critic loop**, run by shell-driven CLI agents, not by any of these frameworks.
The transferable items are therefore *patterns*, not code. Each transfer point below
names the source pattern, the kit analogue, and a concrete implementation step.

### T1. Critic loop = AutoGen reflection, with a literal approval token (HIGHEST VALUE)

- **Source:** AutoGen reflection — primary produces, critic reviews, loop ends when the
  critic emits `APPROVE`; termination is `TextMentionTermination("APPROVE")` (R1).
- **Kit analogue:** builder → independent grader. The grader is the critic; the builder
  is the primary.
- **Concrete transfer:**
  1. Give the grader one literal verdict token, e.g. `GATES_GREEN`, that it must emit
     **only** when every gate passes — mirroring `APPROVE` (R1). Any other verdict
     text means "keep looping".
  2. Give the builder a matching instruction: revise only the top-2 graded issues,
     then re-submit; never self-grade (our existing rule already matches the
     primary/critic split).
  3. Keep the critic **independent**: separate agent/process, no shared working notes
     with the builder — the AutoGen pattern works because the critic is a different
     agent with its own system message (R1), not the same agent re-reading its own work.

### T2. Two-part termination: semantic stop OR hard round cap (HIGHEST VALUE)

- **Source:** AutoGen composes conditions with OR — semantic stop (`TextMentionTermination`)
  **or** an external/hard stop (`external_termination | text_termination`) (R1); the
  Teams tutorial also shows the team stopping cleanly and reporting *why* via
  `TaskResult.stop_reason` (R1).
- **Kit analogue:** our existing "stop when gates green or 3 rounds" is exactly this
  shape — but it should be written as an explicit rule, not left implicit.
- **Concrete transfer:**
  1. Write the termination rule as a formula in the loop prompt:
     `STOP = (grader emits GATES_GREEN) OR (round == 3) OR (coordinator kill-switch)`.
  2. Record a `stop_reason` in the run-log on every loop exit — one of
     `gates_green` / `max_rounds` / `coordinator_stop` / `agent_died` — mirroring
     AutoGen's `stop_reason` (R1). A loop that ends without a recorded reason is a bug.
  3. The coordinator kill-switch must let the current agent finish its turn and write
     its state before stopping — AutoGen's `ExternalTermination.set()` "will stop the
     team when the current agent's turn is over… keeping the team's state consistent"
     (R1). Our equivalent: never kill a builder mid-write; the stop takes effect at
     the next stage boundary.

### T3. Checkpoint after every completed stage, resume from the last one (HIGHEST VALUE — directly addresses probe-4 yield death)

- **Source:** LangGraph — "persists a checkpoint after every superstep… the foundation
  of… crash-resume" (R4). CrewAI — checkpoint "after every task" by default
  (`on_events: ["task_completed"]`, JSON files in `.checkpoints/`), resume with
  `Crew.from_checkpoint()` + `kickoff()` "without re-executing completed tasks" (R2).
- **Kit analogue:** our run-log + per-stage output files are the checkpoint store; a
  fresh agent process is the "resume".
- **Concrete transfer:**
  1. After **each** stage (taste lock, build, gate, screenshots, grade, fix), the agent
     writes a small JSON checkpoint: `{stage, status, artifacts[], verdict, round,
     next_stage}` — mirroring CrewAI's per-task JSON checkpoints (R2).
  2. The resume prompt for a replacement agent starts with: "Read the latest
     checkpoint; do NOT redo completed stages; start at `next_stage`" — mirroring
     CrewAI's "resumed exactly where they left off without re-executing completed
     tasks" (R2).
  3. This is the fix for the `-p` yield death: the loop's state must live in **files**,
     not in the dead process's memory. LangGraph's lesson is that durability comes
     from persisting state at every step boundary (R4) — in our case the step boundary
     is the stage boundary, and the store is the filesystem, not Postgres.
  4. Keep checkpoints small (paths + verdicts, not full file contents) — LangGraph's
     model checkpoints the whole state each step (R4); at our scale, pointers suffice
     and stay cheap.

### T4. Fixed sequential pipeline, not supervisor routing (VALIDATES our current design)

- **Source:** CrewAI sequential is the default: "Tasks are executed one after another…
  Task execution follows the predefined order in the task list, with the output of one
  task serving as context for the next" (R3). AutoGen likewise advises: "start with a
  single agent for simpler tasks, and transition to a multi-agent team when a single
  agent proves inadequate" (R1). LangGraph's supervisor adds an LLM routing call every
  turn (R4).
- **Kit analogue:** our loop's stage order is fixed in the prompt, not chosen by an LLM
  router.
- **Concrete transfer:** Do **not** add a supervisor/router agent in the 5-hour sprint.
  A router LLM call per stage costs tokens and latency and can misroute; the fixed
  sequence (taste lock → build → gate → grade → fix) already encodes the routing
  decision. Keep the `context` discipline from CrewAI: each stage's prompt must include
  the previous stage's output (taste-lock file, gate report, grade report) as context
  (R3) — that is the handoff.

### T5. Handoff = state update + explicit next step (from LangGraph `Command`)

- **Source:** LangGraph `Command` "bundles a state update with a `goto` target" (R4);
  a handoff is one atomic move: write state, then go to the next node.
- **Kit analogue:** stage transitions in the run-log.
- **Concrete transfer:** every stage ends with two lines in the run-log — `STATE: <what
  changed / artifact paths>` and `NEXT: <next stage + its input>` — written by the
  finishing agent before it exits. A stage that exits without a `NEXT` line is treated
  as a crash, and the coordinator resumes from the last checkpoint (T3). This removes
  the failure mode where a dead agent leaves the coordinator guessing what was done.

### T6. Post-step hooks for logging and gating (from CrewAI callbacks)

- **Source:** CrewAI `step_callback` (after each step, "used to log the agent's
  actions") and `task_callback` (after each task, "for monitoring or additional
  operations post-task execution") (R2).
- **Kit analogue:** gate-first check + run-log append after each stage.
- **Concrete transfer:** make the gate check a **hook that runs after the build stage
  regardless of what the builder claims** — the builder's "done" message never advances
  the loop by itself; only the gate hook's verdict does. This is the deterministic-gate
  half of our loop, and CrewAI's callback model is the precedent for "code, not the
  agent, decides whether the step counts" (R2).

### T7. Resume, don't reset, for related work (from AutoGen)

- **Source:** "You can resume a team to continue from where it left off… `RoundRobinGroupChat`
  will continue from the next agent in the round-robin order" and "if the next task is
  related to the previous task, you don't need to reset" (R1).
- **Kit analogue:** fix rounds 2–3.
- **Concrete transfer:** a fix round reuses the same checkpoint thread (same run-log,
  same taste-lock file) and continues from the grade report; only a genuinely new
  design direction resets the loop (new taste lock, round counter back to 1). Write
  this reset-vs-resume rule into the loop prompt so a replacement agent does not
  restart from scratch after a death.

### T8. Replay from a specific stage (from CrewAI)

- **Source:** CrewAI `crewai replay -t <task_id>` replays "from a specific task";
  "Kickoffs will now save the latest kickoffs returned task outputs locally for you to
  be able to replay from" (R2).
- **Kit analogue:** re-running the grade/fix stages without rebuilding.
- **Concrete transfer:** because each stage's output is saved as a file (T3), the
  coordinator can re-run just the grading stage against a saved build (e.g. to
  double-check a disputed grade) without paying for a rebuild. Keep stage outputs
  addressable by stage + round so replay is a one-line instruction.

---

## 3. What does NOT transfer — and why

| # | Pattern / piece | Why it does not transfer to our kit |
|---|---|---|
| N1 | LangGraph runtime itself (`StateGraph`, Pregel engine, `langgraph-supervisor` / `langgraph-swarm` packages) | We run CLI agents via shell prompts in a 5-hour sprint; there is no Python graph runtime in the loop, and adding one (dependency install, graph code, debugging) costs more time than the loop it would run. Take the *pattern* (T3/T5), not the package. |
| N2 | LangGraph checkpointer backends (Postgres / Redis / SQLite) and LangSmith tracing | Overkill for a one-day hackathon loop: our checkpoint store is a handful of JSON files (T3). LangSmith is also a commercial service — out of scope for a $0.00, free-only build. |
| N3 | LangGraph supervisor routing (LLM decides next worker every turn) | Adds an LLM call, latency, and a misrouting risk per stage for a pipeline whose order is already known. Our fixed sequence (T4) is cheaper and more predictable. Supervisor routing only earns its keep when the next step genuinely cannot be known in advance. |
| N4 | LangGraph swarm / network (peer-to-peer handoffs, any agent → any agent) | No peer-to-peer negotiation exists in our loop: stages are ordered, and the grader never hands work directly to the builder. A swarm would let agents route around the gate — the exact failure our deterministic gates exist to prevent. |
| N5 | AutoGen actor runtime, `SelectorGroupChat`, `MagenticOneGroupChat` | Same reason as N1 (no runtime in the loop), plus: a selector LLM choosing the next speaker per turn is supervisor routing under another name (see N3). Magentic-One was **CHƯA ĐỌC** in this session in any case — do not adopt it on the basis of this brief. |
| N6 | AutoGen's in-process state (`save_state` / `load_state`, resume in the same process) | AutoGen's own docs show resume happening inside a living team object (R1), and secondary coverage notes AutoGen "has no built-in durable state… and no answer for what happens when a process dies mid-conversation" (R5). Our failure mode is precisely process death (`-p` yield death) — so in-process resume does not help us. File checkpoints (T3) are the only resume mechanism that survives our failure mode. |
| N7 | CrewAI framework itself (Crews/Flows, `kickoff()`, manager LLM) | Python framework, not our stack (Expo + Convex + Supabase + CLI agents). The hierarchical process also needs a `manager_llm` (R2) — an extra model call per decision — for a team of two roles (builder, grader) that do not need a manager. |
| N8 | CrewAI Flows (`@start` / `@listen` / `@router` / `@persist` / `@human_feedback`) | **CHƯA ĐỌC** — not verified in this session, and in any case a Python event-driven framework, not our shell-prompt loop. The *idea* (deterministic code owns order; agents own judgement) already matches our loop design and is captured in T6. |
| N9 | CrewAI memory (short/long-term/entity) and tool-result caching | Our loop is single-day and single-app; there is no cross-run learning to store, and caching tool results adds state that can go stale. The run-log is the only memory we need. |
| N10 | Any paid tier in any framework (LangGraph Platform, CrewAI AMP/cloud, hosted AutoGen) | Hard constraint of this project: $0.00 spend, free-only. All three frameworks' free/open-source cores are usable as *references*; none of their hosted/durable offerings are. |

---

## 4. Recommended loop shape (synthesis, 5-hour sprint)

```
taste-lock ──► build ──► GATE (hook, not agent claim) ──► screenshots
     ▲                                                        │
     │                 fix top-2 ◄── grade (independent critic, emits GATES_GREEN or issues)
     └────────────────────── STOP when: GATES_GREEN | round==3 | coordinator stop
After EVERY stage: write JSON checkpoint {stage, status, artifacts, verdict, round, next_stage}
On agent death: fresh agent reads latest checkpoint, resumes at next_stage, never redoes completed stages.
Run-log records stop_reason on every exit.
```

This shape is: CrewAI-sequential order + AutoGen-reflection critic + AutoGen two-part
termination + LangGraph/CrewAI per-step checkpointing — implemented as files and prompts,
not as framework code.

---

## 5. Gaps and honest limits of this brief

1. **LangGraph official docs — CHƯA ĐỌC.** `https://langchain-ai.github.io/langgraph/`
   redirects to `https://docs.langchain.com`; the redirect target returned HTTP 429 on
   `browser.open` late in this session. All LangGraph claims above rest on R4 (a
   secondary dossier quoting LangGraph source and the maintainer blog). Re-verify the
   supervisor/swarm reference pages before citing them repo-facing.
2. **CrewAI Flows — CHƯA ĐỌC.** `https://docs.crewai.com/v1.15.32/en/concepts/flows`
   returned HTTP 429 on `browser.open`. Flows claims (`@start`/`@listen`/`@router`/
   `@persist`/`@human_feedback`), agent `max_iter`, and task guardrails are therefore
   absent from §1 and must not be cited from this brief.
3. **AutoGen Termination page — CHƯA ĐỌC.** Only the Teams tutorial (R1) was read;
   the full termination-condition list and `SelectorGroupChat`/`MagenticOne`/
   `save_state`/`load_state` pages were not read. The OR-composition pattern in T2 is
   grounded in R1 alone and is sufficient for our needs.
4. **AutoGen maintenance-mode / Microsoft Agent Framework successor — CHƯA ĐỌC.**
   Secondary coverage asserts it; it was not verified by a direct read and is not
   asserted anywhere in this brief.
5. **No benchmarks cited.** None of the pages read in this session publish a
   head-to-head loop-quality or cost benchmark for these patterns; no performance
   numbers are claimed here.

---

## 6. Tóm tắt tiếng Việt

**Mẫu vòng lặp có thật trong tài liệu (đã đọc, kèm URL + ngày 2026-11-13):**

- **LangGraph:** mọi agent chạy trên một đồ thị trạng thái chung (`StateGraph`); chuyển
  quyền bằng `Command(goto=..., update=...)`; có 4 kiểu tổ chức — supervisor (một
  agent điều phối trung tâm), swarm (agent chuyền tay trực tiếp cho nhau), hierarchical
  (supervisor của supervisor), network (ai cũng chuyền cho ai được). Điểm mạnh nhất:
  **checkpoint sau mỗi bước** — chết giữa chừng vẫn resume được từ đúng bước đó, và
  `interrupt_before/after` để dừng chờ người duyệt.
- **AutoGen:** team chat theo vòng (`RoundRobinGroupChat`); mẫu **reflection** — một
  agent chính làm, một agent critic chê, lặp tới khi critic nói `APPROVE`; dừng bằng
  điều kiện chữ (`TextMentionTermination`) hoặc nút dừng từ bên ngoài
  (`ExternalTermination`); team có trạng thái, resume được, và luôn trả về lý do dừng
  (`stop_reason`).
- **CrewAI:** crew chạy **sequential mặc định** (task nối task, output trước làm context
  cho task sau) hoặc **hierarchical** (manager agent phân công + kiểm tra, cần
  `manager_llm`); có **checkpoint sau mỗi task** (file JSON, resume bằng
  `from_checkpoint()`), replay từ một task bất kỳ, và callback sau mỗi bước/task để
  log và kiểm soát.

**Cái gì chuyển được sang loop của mình (vòng taste-lock → build → gate → chấm →
sửa tối đa 3 vòng):**

1. **Critic độc lập + token duyệt duy nhất** (`GATES_GREEN`, như `APPROVE` của AutoGen).
2. **Luật dừng 2 phần:** hết gate xanh HOẶC hết 3 vòng HOẶC coordinator dừng — và
   **ghi `stop_reason` vào run-log mỗi lần thoát**.
3. **Checkpoint JSON sau mỗi stage** (stage, trạng thái, file, verdict, vòng, stage
   tiếp theo) — agent mới đọc checkpoint rồi làm tiếp, **không làm lại từ đầu**.
   Đây là cách sửa trực tiếp lỗi agent chết giữa vòng (probe-4).
4. **Giữ pipeline cố định, đừng thêm agent điều phối (supervisor/router)** — tốn
   token, chậm, lại có thể chọn sai đường.
5. **Handoff = ghi state + ghi rõ stage tiếp theo** trước khi agent thoát; stage nào
   thoát mà không có dòng `NEXT` thì coi như crash.
6. **Gate là hook chạy sau stage build**, không phải lời builder tự nhận là xong.

**Cái gì KHÔNG chuyển được:** bản thân các framework (LangGraph/AutoGen/CrewAI đều
là Python runtime — loop của mình chạy bằng CLI agent + file, không có runtime đó);
checkpointer Postgres/Redis, LangSmith, bản trả phí (dự án $0.00); supervisor routing
và swarm (cho agent tự chọn đường đi sẽ vòng qua gate); resume trong cùng process
của AutoGen (chết process là mất — chỉ có file checkpoint mới cứu được).

**Chưa đọc (CHƯA ĐỌC):** trang concepts chính thức của LangGraph, trang Flows của
CrewAI, trang Termination đầy đủ của AutoGen — đều bị lỗi 429 cuối buổi; cần đọc lại
trước khi trích dẫn.
