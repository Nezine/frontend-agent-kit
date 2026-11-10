# Install prompt — GitHub Copilot

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into Copilot (VS Code agent mode
or Copilot CLI — see the scope note below).

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

Copilot specifics for this session:
- Copilot does NOT load Claude/Cursor SKILL.md files (VERIFIED via the GSAP README).
  Do NOT just copy SKILL.md files and call it done. The kit's Copilot surface is
  one instruction file: .github/copilot-instructions.md (always-on pointer to the
  orchestrator). install.sh writes that artifact; confirm it exists and is loaded.
- Skills work ONLY in VS Code agent mode / Copilot CLI / cloud agent — NOT inline
  completion or plain chat. If you are running in plain chat or inline completion,
  say so and stop: this kit cannot install there.
- After install, RELOAD the VS Code window, then confirm the instructions are active.
- MCP: VS Code .vscode/mcp.json root key is `servers` (NOT `mcpServers` — that key is
  silently ignored). Copilot CLI also reads ~/.copilot/mcp-config.json / .mcp.json /
  .github/mcp.json (CLAIMED — not verified against Copilot CLI docs in this phase;
  prefer `copilot mcp add --transport http <name> <url>`).
- Hook (best effort): `npx --yes impeccable@4.8.2 install --providers=copilot --scope=global` (pinned — the form `install.sh` runs for claude/codex; for Copilot this is a manual step, since `install.sh` only auto-wires the `claude`/`codex` providers).
  Note: the Impeccable VS Code extension (renaissance-geek.impeccable) installs the
  skill WITHOUT the hook — do not present the extension as the hook.
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

- "Copilot doesn't load Cursor/Claude skill files": VERIFIED via GSAP README
  (see `research/worker-self-install.md` §3.8).
- VS Code `mcp.json` root key `servers`: VERIFIED (msp-skills docs + GSAP pattern).
- Copilot is one of the two least-verified hosts in this kit — the clean-env test must
  include it explicitly before the compatibility claim is stated without qualification.
