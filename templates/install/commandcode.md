# Install prompt — CommandCode (`cmd`)

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into CommandCode.

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

CommandCode specifics for this session:
- Install target: ~/.agents/skills/ (install.sh covers it). CommandCode reads
  ~/.agents/skills/ natively.
- Fast path (same result, one command): `cmd skills add <repo>` — report whether it
  worked; if it does not exist on your version, use ./install.sh and say so.
- After install, confirm with `cmd skills list --debug` in the new session.
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

- `~/.agents/skills/` read natively: carried from v1 (already a target of v1's install.sh).
- `cmd skills list --debug`: **CHƯA ĐỌC** — the list command is unverified
  (see `research/worker-self-install.md` §10 + SYNTHESIS §7 carried items).
  If it fails, report the exact error and the command that did list the skills, if any.
- `cmd skills add <repo>`: CLAIMED from the kit's own v1-era notes — not verified
  against current `cmd` docs in this phase.
