# GEMINI.md — Install + use contract for frontend-agent-kit v2

> **This file is the Gemini extension context pointer.** It carries the same contract as
> `AGENTS.md` (repo root). If the two ever disagree, `AGENTS.md` wins — report the
> disagreement instead of picking a side silently.

## Install (Gemini CLI)

1. Read `README.md`, `SOURCES.md` and `AGENTS.md` in this repo.
2. Clone or pull (idempotent):
   ```bash
   git clone https://github.com/phamTuan207/frontend-agent-kit.git
   # — or, if already cloned: cd frontend-agent-kit && git pull --ff-only
   ```
   Fallback without `git`: download the `main` tarball and extract it.
3. Run the non-interactive installer, then the verifier:
   ```bash
   cd frontend-agent-kit
   ./install.sh
   ./verify.sh
   ```
   `install.sh` copies skills to `~/.gemini/skills/` **and** `~/.agents/skills/`
   (`.agents/skills/` takes precedence over `.gemini/skills/` within a tier, per the
   Gemini CLI docs — VERIFIED). It also installs reference data under
   `~/.local/share/agent-design-references/` and the OpenCode command (harmless here).
   `--no-warm` skips the first-run Impeccable engine download.
   **Accelerator (same result, one command):**
   `gemini skills install https://github.com/phamTuan207/frontend-agent-kit.git --consent`
   — activation requires a UI consent prompt per skill (human step, not install).
   Antigravity users: Antigravity reads `~/.gemini/antigravity-cli/skills/` +
   `.agents/skills/` — the `~/.agents/skills/` copy covers both.
4. **RESTART, then re-verify in the NEW session (mandatory).** Skills load at session
   start; testing in the same session you installed in is the #1 false-failure mode.
   In the new session run `/skills list` (or `gemini skills list --all`) and confirm
   all skills appear. `/skills reload` refreshes the skill list without a full restart.
   Do not report success until this step passes.
5. MCP (Playwright eyes): Gemini settings live in `~/.gemini/settings.json` under
   `mcpServers`. **Streamable HTTP uses `httpUrl`; `url` means SSE** and will fail on
   servers without an `/sse` endpoint. Prefer the CLI — `gemini mcp add <name> <command|url>`
   (`--transport http`, `--scope user` default project) — over hand-editing JSON, and
   verify with `gemini mcp list` / in-session `/mcp`. **Restart `gemini` after editing
   `settings.json`** (it is read at startup).
6. **No Impeccable hook is evidenced for Gemini CLI.** The hook list (Claude Code,
   Cursor, Codex, Copilot, Grok, Hermes) does not name Gemini. Critique runs via
   manual invocation + `impeccable detect` on this host — report that honestly instead
   of claiming the hook is wired.
7. Human-auth handoff: if a step needs browser sign-in or a key (Figma OAuth, Gemini
   skill-activation consent), stop, report exactly what the human must do, resume after.
   Never invent credentials or paste secrets into chat.

Report format (same as `AGENTS.md` §1 step 6): install paths per skill; per-host
listed yes/no with the exact list command used; Impeccable engine version; hook/MCP
status (wired / pending with exact command / not supported); backup dir; pending human
steps; failures with exact errors.

## Use (after install)

The default path is the **taste-locked deterministic-gate loop**, driven by the
`frontend-kit` orchestrator skill — see `AGENTS.md` §2 for the full 7-step contract
(setup `design/` taste folder → taste lock with `tokens.css` committed before any HTML
→ build → deterministic gate with `impeccable detect` → eyes + grade via Playwright
screenshots at 1440/768/390 → fix top 2 as token diffs → stop at ≥4 on every axis or
after 3 rounds → human gate).

On Gemini CLI specifically:
- `taste-reference` is the **default taste layer** (v2 removed the "only when explicitly
  asked" guard) — the orchestrator uses it on every build.
- `impeccable detect` is the gate: run it before every vision grade, never spend a
  vision round on a build the gate already fails.
- **Grader rule (non-negotiable): the builder NEVER grades its own work.** The grade
  step MUST dispatch to an independent judge: (a) an independently-trained expert judge
  sub-agent with NO production history of the build; (b) Muse (the manager agent)
  grading directly; or (c) a different agent/model from the builder. A builder
  self-grade is FORBIDDEN; any score without a named independent grader label is
  INVALID. Degradation ladder applies and must be labelled: full loop (shell + vision
  + independent-judge sub-agent) → independent-judge loop without sub-agent spawning
  where the host can't spawn (judge = Muse-manager or a different model, labelled) →
  gate-only ("gate green, vision not available", never a faked 4/5) → static-only.
  There is NO builder-graded rung: if no independent judge is available, the grade is
  "gate green, vision not available" and the HUMAN gate carries the full taste judgement.

## Honest limits

- Linux-first; macOS/Windows paths are open work.
- Figma is human-gated only (OAuth wall).
- img2threejs is opt-in only; JP's MCP command for it is wrong — no MCP server exists.
- The Muse **app** (chat) has no install path — paste packet only. That is a different
  host from Muse Code, which reads `~/.agents/skills/` natively.
