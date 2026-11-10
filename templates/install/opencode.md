# Install prompt — OpenCode

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into OpenCode.

```text
Install the frontend-agent-kit for yourself from https://github.com/phamTuan207/frontend-agent-kit.
Read AGENTS.md in the repo first and follow it exactly.
Clone the repo (or `git pull --ff-only` if you already have it), run `./install.sh`,
then `./verify.sh`. Detect which hosts are installed on this machine and confirm each
skill is listed by that host AFTER a new session.

IMPORTANT — the restart/re-verify rule: skills, MCP servers and plugins load at session
start. Testing in the SAME session you installed in is the #1 false-failure mode. You
MUST restart (or reload) and re-verify in the NEW session before concluding anything
is missing.

OpenCode specifics for this session:
- Install target: ~/.config/opencode/skills/ and ~/.agents/skills/ (install.sh covers both).
  OpenCode also reads ~/.claude/skills/.
- The /impeccable command is a separate file: install.sh copies
  opencode/commands/impeccable.md to ~/.config/opencode/commands/impeccable.md,
  and .opencode/commands/frontend-kit.md to ~/.config/opencode/commands/frontend-kit.md
  (the orchestrator shim — `/frontend-kit` calls the `frontend-kit` skill).
  Commands are NOT skills in OpenCode — keep the command files and the skills both installed.
- After install, RESTART OpenCode, then confirm the skills appear in the new session
  and /impeccable responds (and /frontend-kit calls the orchestrator).
- MCP config is v2 schema ONLY: opencode.json under mcp.servers.<name> with
  type "local" + command [...] or type "remote" + url, and `disabled: true/false`.
  There is NO `enabled` flag in v2. The v1 shape (mcp.<name> + enabled) is STALE —
  do not copy it from third-party guides. Prefer `opencode mcp add <name> --url …` /
  `--global` / `-- npx …`; verify with `opencode mcp list` and in-TUI /mcp.
  (One known quirk: `opencode mcp list` can print "No MCP servers configured" right
  after a correct write — a display/refresh quirk; the file may still be fine. Restart
  and re-check before concluding failure.)
- Hook (best effort): `npx --yes impeccable@4.8.2 install --providers=opencode --scope=global` (pinned — the form `install.sh` runs for claude/codex). NOTE: `install.sh` only auto-wires the `claude`/`codex` providers, and the vendored upstream hook list (hooks.md) names Claude Code, Codex, Cursor, Grok, Copilot and Hermes — NOT OpenCode — so the `opencode` provider token is unverified in this round. If the command errors or reports an unknown provider, report the exact error and treat the hook as pending; the gate still works via `impeccable detect` from the shell.
- If a step needs my browser sign-in or a key (Figma, any OAuth), stop and tell me
  exactly what to click — do not proceed past it, do not invent credentials, do not
  paste secrets into chat.

When done, report in this format:
- Install path per skill (full paths)
- Per host: skills listed after restart (yes/no, with the exact list command used)
- Impeccable engine version reported by the launcher
- Hook/MCP status per host (wired / pending with exact command / not supported)
- Anything still pending, with the exact human action needed
```

## What was verified for this host (evidence labels)

- Skills dirs + v2 MCP schema: VERIFIED from official OpenCode docs
  (opencode.ai/docs/mcp-servers, read in full 2026-11-10).
- Restart-after-change requirement + `opencode mcp list` quirk: VERIFIED from multiple
  sources (see `research/worker-self-install.md` §7).
