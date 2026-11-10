# Install prompt — Gemini CLI

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into Gemini CLI.

```text
Install the frontend-agent-kit for yourself from https://github.com/phamTuan207/frontend-agent-kit.
Read AGENTS.md in the repo first and follow it exactly. (GEMINI.md in the repo root
is the Gemini-specific pointer to the same contract.)
Clone the repo (or `git pull --ff-only` if you already have it), run `./install.sh`,
then `./verify.sh`. Detect which hosts are installed on this machine and confirm each
skill is listed by that host AFTER a new session.

IMPORTANT — the restart/re-verify rule: skills, MCP servers and plugins load at session
start. Testing in the SAME session you installed in is the #1 false-failure mode. You
MUST restart (or reload) and re-verify in the NEW session before concluding anything
is missing.

Gemini CLI specifics for this session:
- Install target: ~/.gemini/skills/ and ~/.agents/skills/ (install.sh covers both;
  .agents/skills/ takes precedence over .gemini/skills/ within a tier).
- Fast path (same result, one command):
  gemini skills install https://github.com/phamTuan207/frontend-agent-kit.git --consent
  Activation requires a UI consent prompt per skill (skill name, purpose, directory) —
  that is a HUMAN approval step at activation, not install. Tell me when it appears.
- After install, confirm with /skills list (or `gemini skills list --all`) in the new
  session; /skills reload refreshes the list without a full restart.
- MCP: settings live in ~/.gemini/settings.json under mcpServers. Streamable HTTP uses
  `httpUrl`; `url` means SSE and will FAIL on servers without an /sse endpoint. Prefer
  `gemini mcp add <name> <command|url>` (--transport http, --scope user default project);
  verify with `gemini mcp list` / in-session /mcp. RESTART gemini after editing
  settings.json (it is read at startup).
- NO Impeccable hook is evidenced for Gemini CLI. Do NOT claim the hook is wired.
  Critique runs via manual invocation + `impeccable detect` on this host — report that.
- If a step needs my browser sign-in or a key (Figma, any OAuth), stop and tell me
  exactly what to click — do not proceed past it, do not invent credentials, do not
  paste secrets into chat. (/mcp auth <name> handles MCP OAuth.)

When done, report in this format:
- Install path per skill (full paths)
- Per host: skills listed after restart (yes/no, with the exact list command used)
- Impeccable engine version reported by the launcher
- Hook/MCP status per host (wired / pending with exact command / not supported)
- Anything still pending, with the exact human action needed
```

## What was verified for this host (evidence labels)

- Skills dirs, `gemini skills install`, consent prompt, `/skills reload`, MCP
  `httpUrl` vs `url`: VERIFIED from official Gemini CLI docs (geminicli.com/docs/cli/skills,
  read in full 2026-11-10).
- No-hook finding: VERIFIED — the Impeccable hook list names Claude Code, Cursor, Codex,
  Copilot, Grok, Hermes; Gemini CLI is absent.
- Gemini CLI → Antigravity cutover (2026-06-18): CLAIMED from a single secondary source.
  Antigravity reads ~/.gemini/antigravity-cli/skills/ + .agents/skills/ — the
  ~/.agents/skills/ copy covers it either way.
