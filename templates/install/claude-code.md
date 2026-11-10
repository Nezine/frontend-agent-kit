# Install prompt — Claude Code

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into Claude Code.

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

Claude Code specifics for this session:
- Install target: ~/.claude/skills/ and ~/.agents/skills/ (install.sh covers both).
- Fast path (same result, one command): /plugin marketplace add phamTuan207/frontend-agent-kit
  then /plugin install frontend-agent-kit@frontend-agent-kit
  (note: a plugin can be installed-but-off via `defaultEnabled` — check /plugin → Installed).
- After install, run /reload-skills (or start a new session) and confirm with /skills.
- Hook (best effort): `npx --yes impeccable@4.8.2 install --providers=claude --scope=global` (pinned — the form `install.sh` runs; never bare `npx impeccable install`), then
  accept the hook; check with `hooks status`.
- Playwright MCP (best effort): `claude mcp add playwright -- npx -y @playwright/mcp@0.0.85`
  (pinned — the version `install.sh` uses; never `@latest`)
  Editing .mcp.json directly does NOT affect a running session — restart or /mcp
  disconnect/reconnect.
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

- Plugin system + `/reload-skills` / `/reload-plugins` behaviour: VERIFIED from Claude Code
  official plugin docs (read 2026-11-10; see `research/worker-self-install.md` §7).
- `claude mcp add` stdio/HTTP forms and scope behaviour: VERIFIED from the same docs.
- Impeccable hook via `npx --yes impeccable@4.8.2 install --providers=claude --scope=global`: VERIFIED from upstream README (pinned form is the one `install.sh` runs).
- The `-y` non-interactive flag for the hook installer: VERIFIED from the installer's own `--help` (`-y, --yes — Accept detected defaults without prompting`, read 2026-11-10).
