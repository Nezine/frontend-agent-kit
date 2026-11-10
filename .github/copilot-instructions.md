# Copilot instructions — frontend-agent-kit

> Copilot does NOT load Claude/Cursor skill files (GSAP README, VERIFIED).
> This file is the Copilot surface for the kit. It points at the orchestrator
> skill; it does not duplicate it.

## The workflow (always on)

When the user asks for frontend work — design, build, redesign, critique, or
polish of any UI — follow the **frontend-kit orchestrator**:

1. Read the orchestrator skill first:
   - in a repo with the kit: `skills/frontend-kit/SKILL.md`
   - otherwise, if installed: `~/.agents/skills/frontend-kit/SKILL.md`
   - if neither exists, the kit is not installed in this environment — say so
     and point at the repo (`https://github.com/phamTuan207/frontend-agent-kit`,
     `./install.sh`), instead of improvising a workflow.
2. Taste lock before any HTML: `design/TASTE.md` + `design/tokens.css` +
   `design/references/` are committed BEFORE the build. Fixes go to
   `tokens.css` first.
3. Deterministic gate before any grade — and the builder NEVER grades its
   own work: run `scripts/gate/gate.sh --target <dir>` (repo root) — FAIL
   blocks the round. Then screenshot at 1440 / 768 / 390 and grade 1–5 on
   Type / Layout / Colour / Space through an independent judge only
   (`judge-subagent`, `muse-manager`, or `other-model`), one line of
   observable evidence per score. If no independent judge is available,
   there is no grade: "gate green, vision not available".
4. Stop at ≥4 on every axis with the gate green, or after 3 rounds —
   whichever comes first. A build that cannot reach ≥4 in 3 rounds is a
   direction problem: re-pick a variant, do not run a 4th round.
5. Never present a score without evidence, and never claim a browser check
   you did not run.

## Sub-skills (load on demand, never all at once)

- `impeccable` — design direction, critique, audit, polish (the lead skill).
- `gsap-*` — motion/timelines/scroll effects, only when the work needs them.
- `threeui` — a specific ThreeUI 3D/shader component, only when asked.
- `ui-ux-pro-max-reference` — style/palette/typography lookup.
- `taste-reference` — the default taste layer on every build (taste lock
  before any HTML, checker/gate before any grade), not only for landing
  pages and not only on request.
- Pro Max is a reference, not a default; do not apply three design
  systems at once.

## Copilot-specific notes

- Skills work ONLY in VS Code agent mode / Copilot CLI / cloud agent — not
  inline completion or plain chat.
- MCP servers: VS Code `.vscode/mcp.json` uses the root key `servers`
  (NOT `mcpServers`). Prefer the host CLI over hand-editing JSON — a wrong
  key is silently ignored. Playwright MCP (fallback eyes when no shell
  browser is available): add a `playwright` server running
  `npx -y @playwright/mcp@0.0.85`.
- The Impeccable hook on Copilot is installed by `npx impeccable install`
  (interactive); this repo's `./install.sh` attempts it best-effort and
  reports it as PENDING when it cannot.
- Figma is human-gated: it needs a browser OAuth sign-in the agent cannot
  do unattended. If the user asks for Figma, stop and tell them exactly what
  to connect; never invent Figma data. (Claude Code form, VERIFIED from
  Figma's docs: `claude mcp add --transport http figma https://mcp.figma.com/mcp --scope user`.)
- img2threejs is opt-in only. There is no img2threejs MCP server — never
  write a `claude mcp add img2threejs …` / MCP form of it anywhere.
