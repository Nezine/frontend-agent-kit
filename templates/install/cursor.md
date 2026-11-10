# Install prompt — Cursor

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into Cursor.

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

Cursor specifics for this session:
- Install target: ~/.agents/skills/ (install.sh covers it). Cursor reads
  .agents/skills/ natively — no plugin manifest is shipped (.cursor-plugin/
  holds only a README explaining why: the marketplace schema was not
  verified against a primary Cursor source), and none is required.
- After install, confirm the skills are listed in the NEW session (reload the window
  if needed).
- Hook (best effort): `npx --yes impeccable@4.8.2 install --providers=cursor --scope=global` (pinned — the form `install.sh` runs for claude/codex; for Cursor this is a manual step, since `install.sh` only auto-wires the `claude`/`codex` providers).
- MCP: VS Code-style .vscode/mcp.json root key is `servers` (NOT `mcpServers`).
  Prefer the host CLI over hand-editing JSON.
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

- Native `.agents/skills/` reading: carried from the synthesis matrix (SYNTHESIS §4).
- No `.cursor-plugin/` marketplace manifest is shipped (deliberate — the
  schema was not verified against a primary Cursor source, CHƯA ĐỌC); do not
  treat its absence as an install failure.
