# AGENTS.md — Install + use contract for frontend-agent-kit v2

> **This file is the machine-readable install contract.** If a user gave you only the repo link
> (`https://github.com/phamTuan207/frontend-agent-kit`), this file is your instruction set.
> Follow it in order. Do not improvise replacements for a failing command — report the exact
> error and stop at that step.

## 0. What this repo is

A vendored, pinned frontend skill kit (Linux-first) for Claude Code, Codex, OpenCode,
Gemini CLI, GitHub Copilot, Hermes Agent, Muse Code, CommandCode (`cmd`) and Cursor.
Contents: orchestrator skill `frontend-kit`, Impeccable 4.8.2 (engine 0.1.21),
8 official GSAP skills, `threeui`, `ui-ux-pro-max-reference` (2.15.0),
`taste-reference` (taste-skill 2.5.1 — thin wrapper; full pipeline in the
installed taste tree), `frontend-design`
(Anthropic's skill, vendored verbatim — see `skills/frontend-design/SOURCE.md`).
15 skills total (14 + the new judge skill `frontend-judge`). Pins + licences: `SOURCES.md`.

**Built for daily use.** The flow first: drop the repo link → the agent
installs the kit for itself → vague brief → build → your feedback. Acceptance test:
vague brief → 60% slop-free output → your feedback. Host breadth matters, but
where a trade-off appears, usability wins over a marginal host's compatibility.

## Decisions (recorded 2026-11-10, v2 fix round R3)

Short record of the worker contradictions decided here. The phase-1
`research/SYNTHESIS.md` is a historical record and is NOT edited — where it
disagrees with a decision below, the decision below governs and the synthesis
sentence is marked SUPERSEDED here.

- **(a) Taste is the DEFAULT taste layer on every build.** The orchestrator
  uses `taste-reference` always (taste lock in step 1, checker/gate in
  step 3), not only for landing pages and not only on request. SYNTHESIS §2
  ("Taste-skill stays as the conditional module for the job it is actually
  built for (landing/product sites)") is SUPERSEDED: that sentence is the
  phase-1 comparison outcome; the v2 build decision — the orchestrator
  implementation plus this file's §2 house rule — made taste default, and
  README / HUONG-DAN / GEMINI.md already state it as default.
- **(b) `frontend-design` name collision.** The kit vendors Anthropic's
  skill verbatim under `skills/frontend-design/` (see
  `skills/frontend-design/SOURCE.md`). If the user also installs the
  official skill, the copies collide by directory/name and the KIT copy wins
  as the pinned one (same content, pinned to upstream commit `2c5958e`,
  verified 2026-11-10); the user should remove the redundant official
  install, not the kit copy.
- **(c) `allowed-tools`: OpenCode-variant-only.** Canonical skills OMIT
  `allowed-tools` (safety comes from the host's permission system, not the
  skill file). Only the generated OpenCode variant of the Impeccable skill
  emits it. SYNTHESIS §3.2 ("Genuine pre-approval needs go in the
  Claude-adapter copy only") is SUPERSEDED: upstream omits the field for
  Claude Code because Claude blocks skill activation in non-interactive
  sessions when the field is present (impeccable issue #736, as recorded in
  `scripts/generate-host-variants.sh`, which implements the OpenCode-only
  rule). Provenance: the generator rule is VERIFIED in-repo; the upstream
  OpenCode-only pattern is CLAIMED via a third-party summary of upstream's
  outputs (DeepWiki); issue #736 itself was not re-opened in this round.
- **(d) Impeccable re-pinned to 4.8.2 / engine 0.1.21 (2026-11-10).**
  SYNTHESIS §0 ("0.1.21 does not exist anywhere … must never reappear") and
  §3.4 ("latest *released* engine = 0.1.19") are SUPERSEDED: upstream released
  tag `skill-v4.8.2` + `engine-v0.1.21` on 2026-11-09, after the phase-1
  research. VERIFIED 2026-11-10 via `git ls-remote` (tag objects
  `3a2a4a38…` for skill-v4.8.2 and the engine-v0.1.21 tag both exist) and
  in-repo (`vendor/impeccable/skill/scripts/VERSION` reads `0.1.21`,
  `SOURCE.txt` engine `0.1.21`). All docs now say 4.8.2 / 0.1.21.
- **(e) Template tokens use Newsreader / IBM Plex Sans / IBM Plex Mono,
  not the synthesis §3.1 faces (Instrument Serif/Sans, Geist Mono).**
  SYNTHESIS §3.1's font names are SUPERSEDED as the default: all three
  synthesis faces sit on the detector's overused-font list, so any build
  from them started the gate with findings. Re-verified 2026-11-10 against
  engine 0.1.21 (`impeccable detect`, local engine): Instrument Serif,
  Instrument Sans, Geist, Geist Mono, Inter, Roboto, Fraunces, Montserrat,
  Open Sans, Arial, Helvetica, Mona Sans, Plus Jakarta Sans and Space
  Grotesk all flag as primary fonts; Newsreader / IBM Plex Sans /
  IBM Plex Mono are clean; italic Newsreader/Spectral h1 at 64px flags
  (italic-serif-display); inherited unitless 1.55 on 20px text measures
  1.24x and flags (tight-leading). `templates/design/tokens.css` records
  this; the numeric scales (12→64px, tracking −0.03em, light
  #ffffff/#f6f6f4/#0a0f1e, space 4→96px, radius 2/6/12/20px, motion
  120/220/420ms, max-width 1120px) still match §3.1 exactly.
- **(f) `muse-manager` IS a valid independent grader — the old rubric
  exception is SUPERSEDED (coordinator decision, 2026-11-10, H7).** The
  user's standing rule is that the grader may be an independently-trained
  expert judge sub-agent, OR Muse, OR another agent — Muse grading is
  explicitly authorised. What is FORBIDDEN is the SAME agent
  instance/context grading its own work. Therefore `muse-manager` (a
  DIFFERENT agent instance from the builder, with no production history of
  that build) IS a valid independent grader; the rubric sentence "when the
  builder is Muse, `muse-manager` is NOT a valid independent grader" is
  void. The executable grader is the new skill `skills/frontend-judge/`
  (SKILL.md + `references/invocation.md`: fresh sub-agent, no production
  history, no shared context with the builder). The orchestrator's grade
  step dispatches to it by name; fallback order: fresh judge sub-agent →
  `other-model` judge → `muse-manager` judge → no grade ("gate green,
  vision not available"). `scripts/run-log.mjs` enforces the rule: a
  grader entry is accepted only with an independence basis stating BOTH
  fresh/separate context (or a different agent instance) AND no production
  history — "fresh context" alone is NOT enough.
- **(g) The `muse` host, defined precisely (H12).** `install.sh`'s `muse`
  host is the **Muse agent runtime with workspace access** — install
  target `~/workspace/custom-skills/` ONLY, never `~/.agents/skills/`.
  That dir IS a working install path for this runtime (VERIFIED in this
  environment: the runtime loads custom skills from
  `~/workspace/custom-skills/` — this session's own skill list includes
  skills from that dir). **Muse Code is a different product:** it reads
  `~/.agents/skills/` natively (CLAIMED via secondary sources quoting
  Meta's docs; underlying Meta doc not opened) and has NO dedicated
  `--hosts` value (`--hosts=muse-code` and `--hosts=cursor` both error:
  known hosts are `claude codex opencode gemini hermes copilot muse cmd`).
  Muse Code and Cursor are served by `~/.agents/skills/`, which install.sh
  writes whenever any host sharing that dir is installed (codex / opencode
  / gemini / hermes / cmd) or by the no-host fallback (all hosts). The
  **Muse app (chat)** — a user chatting with no workspace/file access —
  still has no install path: paste packet only
  (`templates/install/muse-app-pack.md`). Do not conflate the three:
  `muse` (agent runtime → `custom-skills/`) ≠ Muse Code (CLI →
  `~/.agents/skills/`) ≠ Muse app (chat → paste packet only).
- **(h) Shared `~/.agents/skills` variant collision: first host wins
  (H20, recorded 2026-11-10).** `install.sh` normalises host order to
  `claude codex opencode gemini hermes copilot muse cmd` and dedupes shared
  dirs (`DONE_DIRS`): the first host in that order to claim a dir wins it,
  and the Impeccable variant written there is that host's variant
  (`impeccable_source_for_host`: claude → claude-code variant, opencode →
  opencode variant, gemini → gemini variant, everything else → agents
  variant). So on a machine with codex installed,
  `~/.agents/skills/impeccable` is ALWAYS the agents (Codex-style,
  `$`-prefix) variant — codex precedes opencode/gemini/hermes/cmd in the
  order — even though opencode/gemini/hermes also read that dir; their own
  variants land only in their own dirs (`~/.config/opencode/skills`,
  `~/.gemini/skills`, `~/.hermes/skills`). If codex is NOT installed, the
  first of opencode/gemini/hermes/cmd in that order claims the shared dir
  with ITS variant. Which dir each host prefers when both its own dir and
  the shared dir hold the skill:
  - Gemini CLI: VERIFIED from the primary docs
    (`geminicli.com/docs/cli/skills`, read 2026-11-10): within one tier,
    `~/.agents/skills/` takes precedence over `~/.gemini/skills/`.
    Consequence: on a codex+gemini machine Gemini reads the agents variant
    from the shared dir, NOT the gemini variant in its own dir — the gemini
    variant is shadowed. Known wrong-variant exposure, not an installer
    bug: the installer cannot make both dirs hold one variant without
    breaking the other host.
  - OpenCode: CHƯA ĐỌC against the stable primary docs — the stable docs
    publish no precedence rule between the six discovery dirs
    (third-party analysis of the stable docs: skillsboard.sh; the
    OpenCode 2 beta docs publish later-wins — built-in → Claude paths →
    neutral paths → OpenCode global → project → config entries — which
    would put `~/.config/opencode/skills` above `~/.agents/skills`, but
    that is beta only and NOT relied on here). Treat a same-name collision
    on OpenCode as untested.
  - Codex: CHƯA ĐỌC — which of `~/.agents/skills` vs `~/.codex/skills`
    wins is the unresolved §5 discrepancy.
  - Hermes, CommandCode, Muse Code, Cursor: CHƯA ĐỌC — no precedence
    statement found in this round.
- **(i) Human-eye acceptance bar is 60% slop-free (user-ordered 2026-11-10
  19:23).** The old 70–80% figure is SUPERSEDED everywhere it appeared as
  the acceptance figure (this file §0 + §5, README, muse-app-pack, plugin
  manifests, clean-env test). The ≥4-on-every-axis loop stop is UNCHANGED:
  the % is the human-eye bar for the vague-brief acceptance test, the
  4-axis scores are the per-round gate. The bar is stated in the rubric
  (`skills/frontend-kit/references/grader-rubric.md`), the stop rules
  (`stop-rules.md`), the orchestrator SKILL.md step 6, `workflow.md` §6,
  and the probe briefs (`tests/clean-env/probe-briefs.md`). The phase-1
  SYNTHESIS.md is a historical record and is NOT edited for this change;
  this decision governs where it disagrees.

## 1. Install contract

Execute exactly these steps, in order. Report after step 6 using the format in §3.

### Step 1 — Read
Read `README.md` and `SOURCES.md` in this repo. Check `bash`, `python3`, `git`,
CPU architecture, and which hosts are actually installed on this machine
(check for the binaries/config dirs: `~/.claude/`, `~/.codex/`, `~/.config/opencode/`,
`~/.gemini/`, `~/.hermes/`, `cmd`, `cursor`).

### Step 2 — Clone or pull (idempotent)
```bash
git clone https://github.com/phamTuan207/frontend-agent-kit.git
# — or, if the repo already exists locally:
cd frontend-agent-kit && git pull --ff-only
```
Fallback if `git` is missing or the clone fails: download the `main` tarball
(`https://github.com/phamTuan207/frontend-agent-kit/archive/refs/heads/main.tar.gz`),
extract it, and continue from the extracted directory. If neither works, stop and
report the exact error — do not invent another download source.

### Step 3 — Run the installer (non-interactive)
```bash
cd frontend-agent-kit
./install.sh
./verify.sh
```
- `install.sh` detects installed hosts, copies skills to **every applicable skills dir**
  (`~/.agents/skills/` — the cross-agent default — plus `~/.claude/skills/`,
  `~/.config/opencode/skills/`, `~/.gemini/skills/`, `~/.hermes/skills/`,
  `~/.codex/skills/` as a hedge against the unresolved Codex-dir discrepancy,
  Copilot `.github/` instruction artifacts, and `~/workspace/custom-skills/` for the
  `muse` host only — the Muse agent runtime, never for Muse Code; see Decisions (g)
  in this file and the README host table for the per-host dirs, verified against
  `install.sh --dry-run` per host), installs the OpenCode `/impeccable` and `/frontend-kit` commands, installs reference data
  under `~/.local/share/agent-design-references/`, backs up same-named existing skills
  first, runs `verify.sh`, and warms the Impeccable engine best-effort.
- Flags: `--no-warm` skips the first-run engine download (engine downloads on first use);
  `--hosts=<list>` limits install targets; `--dry-run` prints planned actions without writing;
  `--skip-hooks` / `--skip-mcp` / `--skip-eyes` skip the hook install, the Playwright MCP
  adds, and the Playwright CLI + browser install respectively (each skipped step is
  reported as pending with its exact manual command).
- If there is no network for the engine download, use `./install.sh --no-warm` and report
  that the engine still needs downloading later. Do **not** substitute `curl | bash` or an
  unpinned `@latest` install for any step.
- Best-effort extras inside the same script (failures reported, never fatal):
  Impeccable hook via `npx --yes impeccable@4.8.2 install --providers=<detected> --scope=global`
  (pinned — never bare `npx impeccable install`; `install.sh` auto-wires the hook only
  where a `claude`/`codex` provider is detected — other hosts use the per-host command
  in `templates/install/`);
  Playwright MCP adds via the host's own CLI (`claude mcp add`, `codex mcp add`,
  `gemini mcp add`, `opencode mcp add`). Prefer host CLIs over hand-editing config files:
  wrong keys are silently ignored (Codex TOML needs `[mcp_servers.<name>]`, not JSON
  `mcpServers`; VS Code `mcp.json` root key is `servers`, not `mcpServers`;
  OpenCode v2 uses `mcp.servers.<name>` + `disabled`, never v1 `mcp.<name>` + `enabled`;
  Gemini streamable HTTP uses `httpUrl`, `url` means SSE and will fail on servers without /sse).
- **Plugin-route scope (from `.claude-plugin/plugin.json` / `.codex-plugin/plugin.json`):**
  Plugin route delivers only the 6 canonical skills in `./skills/`; GSAP skills,
  Impeccable variants, reference data and OpenCode commands are install.sh-only.
  For the full 15 skills + reference data + the OpenCode `/impeccable` and
  `/frontend-kit` commands, run `./install.sh`.
- **Figma is excluded from unattended install.** It needs human OAuth. See §4.

### Step 4 — RESTART, then re-verify in the NEW session (mandatory)

> **Skills, MCP servers and plugins load at session start almost everywhere. Testing in
> the same session you installed in is the #1 false-failure mode. An install that
> "succeeded" but is tested in the same session will look broken — that is not evidence
> the install failed.**

1. Start a **new session** of each host (or use its reload command where one exists:
   Claude Code `/reload-skills` / `/reload-plugins`; Codex `/new` for a new plugin;
   Gemini CLI `/skills reload`; OpenCode restart; VS Code/Copilot reload window).
2. In the **new** session, run that host's skill-list command and confirm the skills appear:
   - Claude Code: `/skills`
   - Codex: `$` or `/skills` (and `/plugins` for the plugin route)
   - OpenCode: skill appears in the session after restart; `/mcp` for MCP
   - Gemini CLI: `/skills list` (or `gemini skills list --all`)
   - Copilot: instructions files present in `.github/`; skills work only in VS Code
     agent mode / Copilot CLI / cloud agent — NOT inline completion or plain chat
   - Hermes Agent: `hermes skills list`
   - Muse Code: list skills in the new session
   - CommandCode: `cmd skills list --debug` (CHƯA ĐỌC — unverified claim, see §5)
   - Cursor: list skills in the new session
3. Run `./verify.sh` again from the new session if your host allows it. v2 `verify.sh`
   verifies the **loop**, not just files: skills present per host, `playwright-cli --help`
   runs, a headless 390px screenshot succeeds, `impeccable detect` runs, gate scripts
   run, and the installed engine version matches the skill's expected engine
   (mismatch = loud failure, never silent).
4. **Do not report success until step 4.2 has passed in a new session.** Any "skill not
   found" report made without a restart having happened is suspect until the restart is done.

### Step 5 — Human-auth handoff
If a step needs the human's browser sign-in or a key (Figma OAuth; any API-key wizard;
Gemini CLI skill-activation consent prompt), **stop at that step, report precisely what
the human must do, and resume after**. Never proceed past auth silently, never invent
credentials, never paste secrets into chat. For Figma, the exact follow-up is:
`claude mcp add --transport http figma https://mcp.figma.com/mcp --scope user`
(Claude Code) or `codex mcp add figma --url https://mcp.figma.com/mcp` (Codex),
then a new session → authenticate in the browser when prompted.

### Step 6 — Report (format)
```
Install paths: <full path per skill, per host>
Per host (after NEW session): <host> — listed yes/no — <exact list command used>
Impeccable engine version: <from launcher/engine-probe>
Hook/MCP status per host: wired / pending <exact command> / not supported
Backup dir: <path, or "none — no collisions">
Pending human steps: <exact action needed, or "none">
Failures: <step, exact error, what you did — no silent skips, no invented fixes>
```

## 2. Use contract (after install — how to do frontend work with this kit)

The default path is the **taste-locked deterministic-gate loop**, driven by the
`frontend-kit` orchestrator skill. Do not skip steps; do not re-argue direction in prose.

0. **Setup (once per project):** create `design/` — `TASTE.md` (one-paragraph intent +
   likes/dislikes + hard rules), `tokens.css` (the ONLY file feedback may touch first),
   `design/references/` (8–15 screenshots of sites the user loves, named by site —
   screenshots, not links), 2–3 vendored `DESIGN.md` files labelled
   "third-party analysis, not official", `design/screenshots/`, `design/variants/`.
1. **Brief → taste lock (no build yet):** read brief + `TASTE.md` + chosen DESIGN.md;
   pick the reference direction; write `tokens.css`; build a 1-page demo proving the
   tokens work (`templates/design/demo.html` → `design/demo.html`; pass criterion:
   every expected token renders visibly AND the demo passes the gate on its own).
   Counterfactual plan check: plan first (4–6 named colours, type roles,
   ASCII wireframes), then ask — worked through a similar prompt, would you arrive
   somewhere similar? If yes, the plan is generic; fix the plan, not the build.
   **Verifiable artifact:** `tokens.css` + chosen references committed BEFORE any HTML.
   "Commit" means exactly: files saved under `design/` in the project AND the lock
   recorded in the run log (`run-log.mjs lock`); `git commit` only if the project is
   a git repo (see `frontend-kit` SKILL.md step 1.5).
2. **Build (one HTML file, tokens only — no inline style drift).** If the brief is vague
   on direction: generate the 5 CSS-only variants (same content/copy/HTML, only CSS
   changes — Editorial / Dark / Warm brutalist / Glassy / Minimal), screenshot each at
   the same width. The human picks one; the pick IS the feedback.
3. **Deterministic gate (BEFORE any vision grade):** `impeccable detect` (62 rules);
   taste-style gate scripts (overflow / collide / tap-size, section height,
   one-section-per-screen, copy-lint); `npx html-validate` + `npx pa11y --standard WCAG2AA`
   where available. FAIL blocks the round. Print the gate result, do not summarise it.
4. **Eyes + grade (Playwright CLI first):** serve over http (never `file://`); screenshot
   at 1440 / 768 / 390; `playwright-cli console` for errors, `snapshot` for structure.
   Grade 1–5 on Type / Layout / Colour / Space vs the locked reference. EVERY score
   carries ONE LINE of observable evidence (named element, measured contrast ratio,
   pixel value) — a score without evidence is not a score. Show the score table every
   round. **Grader rule (non-negotiable): the builder NEVER grades its own work.**
   The grade step MUST dispatch to an independent judge: (a) an independently-trained
   expert judge sub-agent with NO production history of the build it grades;
   (b) Muse (the manager agent) grading directly; or (c) a different agent/model from
   the builder. A builder self-grade is FORBIDDEN, not merely discouraged. Any score
   without a named independent grader label is INVALID — label every score with its
   grader.
5. **Fix top 2 as token diffs** (top 1 if evidence is thin). Fixes go to `tokens.css`
   first; HTML/layout only if the gate still fails after the token change. Keep the
   best-scoring version; a lower-scoring round is discarded, not iterated on.
   Re-run step 3, then step 4.
6. **Stop + human gate:** stop at ≥4 on every axis AND gate green — or after 3 rounds,
   whichever comes first. A build that cannot reach ≥4 in 3 rounds is a direction
   problem: re-pick a variant, not a 4th round. Human gate: score table + 3-width
   screenshots + 2–4 targeted questions with concrete options + recommended next
   command, ending with `polish`. After approval, save the 3-width screenshots as the
   pixel-diff baseline.

**Degradation ladder (label every degradation, never silently):** full loop
(shell + vision + independent-judge sub-agent) → independent-judge loop without
sub-agent spawning where the host can't spawn (judge = Muse-manager or a different
model, labelled) → gate-only loop (shell, no vision — grade is exactly "gate green,
vision not available", never a faked 4/5) → static-only (no shell: MCP fallback for
eyes, `detect` for gate). There is NO builder-graded rung: if no independent judge
is available, the grade is "gate green, vision not available" and the HUMAN gate
carries the full taste judgement.

**Skill roles:** `frontend-kit` orchestrates and delegates; it never duplicates
sub-skill content. Impeccable leads design/build/review. `frontend-design`
is the direction-setter for step 1: plan-first (4–6 named colours, type
roles, ASCII wireframes) + the counterfactual plan check. `taste-reference` is the
**default taste layer** (v2 removed the "only when explicitly asked" guard) — the
orchestrator uses it on every build, not on request. `ui-ux-pro-max-reference` is a
lookup (styles/palettes/fonts/charts). GSAP skills apply only when the work needs
motion. `threeui` applies only for a ThreeUI component. Do not apply three design
systems at once.

**`impeccable detect` is the gate.** It is mentioned here because v1's docs never
mentioned it: run it before every vision grade, and never spend a vision round on a
build the gate already fails.

## 3. Hard rules for the installing agent

- Never copy secrets, tokens, personal config, or project files from another machine.
  Never copy GUI config from another machine (`computer-use` / `chromium-cdp` are not
  in this kit for that reason); survey the receiving machine's own browser/GUI instead.
- Never run `curl | bash`, `bash <(curl …)`, or an unpinned `@latest` installer.
  The kit is vendored and pinned; `git clone` needs no bootstrap script.
- Never claim a skill is installed because files exist. Only the new-session list
  command (§1 step 4) proves loading.
- Never claim the Muse **app** can self-install from the repo link. It cannot — see §5.
  If you are running inside the Muse app, use `templates/install/muse-app-pack.md`
  (paste packet) and say so in your report.
- If a command fails, report the exact error and the step it failed at. Do not improvise
  a replacement command, do not silently skip the step, do not invent a fix.
- Version-check, never auto-upgrade: if a pinned upstream is newer than the vendored
  copy, warn and report it; never upgrade at install time.

## 4. Human-gated only

- **Figma:** remote MCP server + human OAuth on first connect. Unattended install is
  impossible; see §1 step 5 for the exact follow-up commands.
- **img2threejs:** opt-in only. JP's `claude mcp add img2threejs …` is wrong — no MCP
  server exists. The skill-clone form is
  `git clone https://github.com/img2threejs/img2threejs.git ~/.claude/skills/img2threejs`
  (invoke `/img2threejs …`). No harness command is shipped in this kit — img2threejs
  is NOT tested end-to-end and NO pinned command exists for it: the user must verify
  upstream's install + `doctor` flow before use. Do not present it as verified, and
  never write an unpinned `@latest` install command for it (AGENTS.md §3 hard rule).

## 5. Honest scope limits (say these, do not soften them)

- **Muse app (chat): no install path exists.** High-confidence CLAIMED — 5 convergent
  third-party sources (aiagentslibrary.com, builtwithmuse.com, openaimaster.com,
  metaflow.life, ai-supremacy.com); **Meta primary not read**. The only Muse-app path
  is the paste packet in `templates/install/muse-app-pack.md`, which is per-conversation
  and non-persistent. Do not promise 60% slop-free output for the Muse app.
  (This is the chat app with no workspace/file access — not the `muse` host below.)
- **The `muse` host ≠ Muse Code ≠ Muse app (see Decisions (g)).** `install.sh`
  `--hosts=muse` installs ONLY to `~/workspace/custom-skills/` — the working install
  path of the Muse agent runtime with workspace access (VERIFIED in this environment:
  the runtime loads custom skills from that dir). Muse Code is a separate CLI product
  that reads `~/.agents/skills/` natively (CLAIMED via secondary sources quoting
  Meta's docs; underlying Meta doc not opened) and has no dedicated `--hosts` value —
  it is served by `~/.agents/skills/`, written for codex/opencode/gemini/hermes/cmd or
  by the no-host fallback. Repo-link self-install works for Muse Code and for the
  Muse agent runtime; it does not work for the Muse app (chat).
- **Linux-first.** macOS/Windows install paths are open work; `install.sh` v1 refuses
  non-Linux and nothing in the research verifies those paths.
- **Codex skills dir discrepancy (unresolved):** `~/.agents/skills/` (OpenAI docs,
  impeccable README) vs `~/.codex/skills/` (GSAP README). Install to both until the
  clean-env test resolves it.
- **`cmd skills list --debug`: CHƯA ĐỌC** — the list command for CommandCode is unverified.
- **Gemini CLI hook: no evidence of an Impeccable hook for Gemini CLI.** Critique runs
  via manual invocation + `detect` on that host.
- **Hermes vision capability: NOT verified.** The full loop on Hermes depends on whether
  the pointed-at model has vision.
- **Copilot + Gemini CLI are the least-verified hosts** in this kit; the clean-env test
  must include them explicitly before the compatibility claim is stated without qualification.
