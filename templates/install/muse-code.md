# Install prompt — Muse Code

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into Muse Code.

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

Muse Code specifics for this session:
- Install target: ~/.agents/skills/ (install.sh covers it). Muse Code reads
  <repo>/.agents/skills/<skill-id>/SKILL.md, ~/.agents/skills/, ~/.claude/skills/,
  and the Codex skills directory — a standard SKILL.md runs here WITHOUT rewriting.
- After install, confirm the skills are listed in the NEW session.
- Hook/MCP: no Muse-Code-specific hook or MCP install path is evidenced for this kit.
  Report hook/MCP as "not supported / not evidenced" rather than claiming they are wired.
  The gate still works: `impeccable detect` runs from the shell, and Playwright
  screenshots work from the shell.
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

- Muse Code reads `~/.agents/skills/` natively with zero adapter: CLAIMED via secondary
  sources quoting Meta's docs — the underlying Meta doc was NOT opened
  (see `research/worker-self-install.md` §10.8). This is the strongest "Muse" reading
  in the kit, but it is still CLAIMED, not VERIFIED.
- **Muse Code is not the Muse app.** The app has no install path (see `muse-app-pack.md`).
  Do not conflate the two in any report.
