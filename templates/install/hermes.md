# Install prompt — Hermes Agent

Copy everything in the code block below, paste it together with the repo link
`https://github.com/phamTuan207/frontend-agent-kit` into Hermes Agent.

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

Hermes specifics for this session:
- Install target: ~/.hermes/skills/ (install.sh covers it). Alternatively
  skills.external_dirs in ~/.hermes/config.yaml can point at the shared
  ~/.agents/skills — install.sh also copies there.
- Project-local skills in .hermes/ need ONE trust step: `hermes skills trust` from the
  project root. Global skills need no trust step.
- After install, confirm with `hermes skills list` in the new session.
- Hook (VERIFIED available): `hermes plugins enable impeccable-design-hook` once
  (Impeccable 4.8.1 changelog + README). Run it and confirm the hook is enabled.
- MCP: mcp_servers: in ~/.hermes/config.yaml; `hermes mcp` handles install/config/OAuth 2.1.
- Vision caveat: the full loop (screenshot grading) depends on whether the model
  Hermes is pointed at has vision — that is NOT verified for this host. If your model
  cannot view images, say so and run the gate-only degradation (label it, do not fake
  vision grades).
- Small-local-model caveat (secondary guides): local servers need ≥64K context, and
  small local models often falsely claim to have saved a memory without calling the
  tool. Use a stronger model for setup if the setup steps misbehave.
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

- Skills dir `~/.hermes/skills/`, `skills.external_dirs`, trust step, `hermes skills list`:
  VERIFIED from Hermes docs/guides (see `research/worker-self-install.md` §7).
- Hook command: VERIFIED (Impeccable 4.8.1 changelog + README).
- Vision capability: NOT verified (open question — see SYNTHESIS §6).
- ≥64K-context / false-memory-claim warnings: CLAIMED from secondary guides
  (checked against repo/docs 2026-09-28/30) — re-verify against current Hermes docs.
