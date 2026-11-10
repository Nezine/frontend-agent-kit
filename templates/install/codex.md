# Install prompt — Codex CLI

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into Codex.

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

Codex specifics for this session:
- Install target: ~/.agents/skills/ AND ~/.codex/skills/ (install.sh covers both — the
  two primary sources disagree on the Codex skills dir, so install to both until the
  clean-env test resolves it).
- Fast path (same result, one command): codex plugin marketplace add phamTuan207/frontend-agent-kit
  then codex plugin add frontend-agent-kit@frontend-agent-kit, then start a NEW session
  with /new before using the plugin's skills.
- After install, confirm with $ or /skills in the new session; check plugins with /plugins.
- MCP config is TOML: ~/.codex/config.toml uses [mcp_servers.<name>] tables. JSON
  `mcpServers` is SILENTLY IGNORED — do not write it. Prefer `codex mcp add <name> -- <cmd>`
  (stdio) or `codex mcp add <name> --url <url>` (remote); verify with `codex mcp list`.
- Hook (best effort): `npx --yes impeccable@4.8.2 install --providers=codex --scope=global` (pinned — the form `install.sh` runs), then open
  /hooks and APPROVE the project hook (again after any update that changes it).
- Sandbox warning: under the default workspace-write sandbox, network is OFF and writes
  are confined to the workspace. Expect approval prompts for git clone / npx / writes
  outside the project dir — ask me to approve them; do not silently fail.
- You MUST ask once before spawning sub-agents (the fresh-context reviewer in the
  critique step needs this permission).
- If a step needs my browser sign-in or a key (Figma, any OAuth), stop and tell me
  exactly what to click — do not proceed past it, do not invent credentials, do not
  paste secrets into chat. (codex mcp login handles MCP OAuth.)

When done, report in this format:
- Install path per skill (full paths)
- Per host: skills listed after restart (yes/no, with the exact list command used)
- Impeccable engine version reported by the launcher
- Hook/MCP status per host (wired / pending with exact command / not supported)
- Anything still pending, with the exact human action needed
```

## What was verified for this host (evidence labels)

- Skills dir `~/.agents/skills/`: VERIFIED (OpenAI docs + impeccable README).
  `~/.codex/skills/`: VERIFIED as claimed by the GSAP README — the two disagree,
  hence the install-to-both hedge (see `research/worker-self-install.md` §10.2).
- Plugin commands + `/new` requirement: VERIFIED from official OpenAI Developers docs.
- MCP TOML schema + `--env` plaintext warning: VERIFIED from Codex docs.
- `codex plugin add` vs `install` version discrepancy: open (taste README says `add`;
  CLI 0.122+ refs say `install`, per SYNTHESIS §4). If `add` fails, try `install` and report which worked.
