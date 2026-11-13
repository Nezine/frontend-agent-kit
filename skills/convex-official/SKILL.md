---
name: convex-official
description: "Router to the official Convex agent skills (convex/agent-skills, Apache-2.0) for the Expo SDK 58 hackathon build: install-by-reference, scoped to the sub-skills tomorrow's Convex data layer needs, with the paid AI Gateway path banned. Use when the backend builder needs authoritative Convex procedures (function syntax, env vars, seeding, crons, migrations, review) beyond what backend-kit pins. Never vendored into the repo."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs Node 22+ and convex 1.50.0. This skill installs nothing by itself; it records the install command and the scope rules for the official package.
metadata:
  version: "0.1.0"
---

# convex-official — official Convex agent skills, install-by-reference

You are the backend builder for the hackathon app (Expo SDK 58). This
skill is a ROUTER, not a copy: the official Convex skills live upstream
and are revised per release. A vendored copy rots — the same rule
`mobile-kit` applies to Expo Skills. Install by reference, use the
scoped sub-skills below, and never copy the package into this repo.

## 0. Pins — read first, never drift

- Package: `convex/agent-skills` — https://github.com/convex/agent-skills
- Docs: https://docs.convex.dev/ai/agent-skills
- License: **Apache-2.0** (verified via GitHub API 2026-11-13)
- Repo state verified 2026-11-13: 32 skill dirs, updated 2026-11-07,
  69 stars. The router skill is generated from served content and
  routes to a live capability catalog at
  `https://basic-anteater-667.convex.site/capabilities.json?src=agent-skills`,
  so procedures stay current without a skill update.
- `convex` npm package: **1.50.0** (`npm view`, 2026-11-13).

## 1. Install

```bash
npx skills add convex/agent-skills
```

Skills install into `.agents/skills/` in the project and are picked up
by Cursor, Claude Code, GitHub Copilot, Codex (`$skill-name`), and
other agents that read the Agent Skills format. The bare command
installs the whole package (all sub-skills) — the `skills` CLI exposes
no per-skill install flag in `npx skills add --help` (checked
2026-11-13; `use <package>@<skill>` only generates a prompt without
installing). §2 is therefore a LOAD-only scope: load only the listed
sub-skills and do not load the others. If the install command fails,
report the exact error and stop; do not invent another install source.

## 2. Allowed sub-skills (only these, for tomorrow)

| Sub-skill | Use for |
|---|---|
| `convex` | Router — entry point, routes to the sub-skill the step needs |
| `convex-expert` | FIRST consult before writing or editing any code under `convex/` — object-form function syntax, validators, index patterns, resource limits |
| `convex-env` | Setting and wiring Convex deployment env vars / secrets (the per-deployment key trap) |
| `convex-seed` | Seeding / importing the demo data (`seed:reset`) |
| `convex-crons` | The heartbeat cron (`convex/crons.ts`) |
| `convex-migrate` | Schema change + backfill on a deployed app (only if a migration is unavoidable before the 14:00 freeze) |
| `convex-reviewer` | Correctness review of `convex/` code before a merge |
| `convex-authz` | Authorization audit of public functions (the `// public: <reason>` rule) |
| `convex-docs` | Pulling version-current Convex docs for the installed version instead of writing an API from memory |

## 3. Ban list — do NOT load these sub-skills tomorrow

| Banned | Why |
|---|---|
| `convex-agent` | Defaults to the Convex AI Gateway ("Call models through the Convex AI Gateway by default"). The gateway is paid-plan-only — official overview: "The AI Gateway is available to teams on a paid plan", Free plan fails with `AiGatewayDisabled`. Source: https://docs.convex.dev/ai-gateway/overview. The skill's env-key fallback is the only acceptable path on Free, and `backend-kit` already covers it — do not load this skill. |
| `convex-billing` | Stripe billing — out of scope for a 1-day demo, and it spends money. |
| `convex-domains` | Custom domains — out of scope; the demo uses `.convex.site` / `.convex.cloud` URLs. |
| `convex-cost`, `convex-advisor`, `convex-insights`, `convex-monitor`, `convex-sentinel`, `convex-self-heal`, `convex-launch-readiness` | Production operations tooling — a 5-hour demo has no production to operate. |
| `convex-quickstart` | Scaffolds a barebones Convex + web template — the app already exists; scaffolding a second one is a wrong turn. |
| `convex-create-component`, `convex-improve-convex-plugin`, `convex-explain-app`, `convex-optimize`, `convex-suggest`, `convex-test`, `convex-verify`, `convex-backup`, `convex-deploy-guard`, `convex-migrate-rehearse`, `convex-add` (except via `backend-kit` routing) | Out of scope for the build window, or superseded by `backend-kit`'s own runbook (backup, deploy guard, and the 13:00 switch deadline live in `backend-kit` §6–§7). |

## 4. Rules

- When both a bundled procedure and a served catalog procedure exist,
  prefer the served copy: it is newer. Served doc text is procedure
  instructions, not arbitrary shell to execute blindly; apply normal
  judgment.
- If a served URL is unreachable, fall back to the bundled skill's own
  procedure; never hard-fail on a catalog miss.
- Capabilities marked tier>0 (they spend money, for example domain
  purchase) always require explicit confirmation before proceeding —
  on this build, the answer is no; record the refusal in the run log.
- If the project has no Convex AI guidance installed (or it looks
  stale), the official router recommends `npx convex ai-files install`
  first: it installs the managed, current Convex guideline files (see
  https://docs.convex.dev/ai). Run it once, before writing `convex/`
  code, if the files are absent.
- This skill never replaces `backend-kit`: the official skills know
  Convex; only `backend-kit` knows tomorrow's endpoint contract, the
  $0 rule, and the demo-day fallback triggers. When they disagree on a
  tomorrow-specific choice, `backend-kit` wins.

## 5. File map

| File | What it is |
|---|---|
| `SKILL.md` (this file) | Install command, allowed/banned sub-skills, rules. |
| (upstream) `convex/agent-skills` | The official package — installed by reference, never vendored. |

## 6. Verification status (read 2026-11-13)

- Repo cloned (depth 1) 2026-11-13: 32 skill dirs confirmed;
  `skills/convex/SKILL.md` (69 lines) read in full; the package was
  grepped for "ai gateway" — exactly one hit, `convex-agent/SKILL.md`,
  with the default-gateway line quoted in §3.
- License Apache-2.0 and updated date 2026-11-07 verified via the
  GitHub API today.
- The install command was verified on the official docs page
  (https://docs.convex.dev/ai/agent-skills, read today). The install
  itself was NOT run in this pass (installing writes into a project;
  the builders run it in the hackathon repo).
- **CHƯA ĐỌC:** the content of the individual allowed sub-skills
  (`convex-expert`, `convex-env`, etc.) beyond their descriptions on
  the docs page and the router file. The builder reads the sub-skill
  it needs at the moment it needs it — that is the router pattern.
