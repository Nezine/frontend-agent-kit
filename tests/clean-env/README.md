# Clean-env self-install test — spec (NOT run)

**Status: specification only.** No test in this directory has been executed. This spec is
what build/QC runs, per SYNTHESIS §5 and `research/worker-self-install.md` §9.
It is the single most likely failure point of v2 (red-team A3: no clean-env self-install
has been run by anyone) — and the first-failure list it produces IS the phase-2 worklist.

## 1. Matrix

**Hosts (7):** Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot (VS Code),
Hermes Agent, Muse Code.

**Environment per host:** one fresh VM/container with **only that host installed**,
plus `git`, `bash`, `python3`. **Node 22.20+ installed on half the matrix, absent on the
other half** (to test the Node gate — `npx skills add` requires Node 22.20+, the
file-copy path must not).

| Run | Host | Node 22.20+ |
|---|---|---|
| 1 | Claude Code | present |
| 2 | Codex CLI | present |
| 3 | OpenCode | present |
| 4 | Gemini CLI | absent |
| 5 | GitHub Copilot (VS Code) | absent |
| 6 | Hermes Agent | present |
| 7 | Muse Code | absent |

(Assignment of Node present/absent to hosts is arbitrary; what matters is that half
the matrix runs without Node. Record the actual assignment when the test runs.)

**Input (identical every run):** the repo link
`https://github.com/phamTuan207/frontend-agent-kit` + the verbatim paste-prompt from
`templates/install/<host>.md` (variant A) or the one-command accelerator where one
exists (variant B — see §4). **No human intervention beyond the paste**, except
approval/auth dialogs the prompt explicitly predicts. Record every approval dialog shown.

**Two variants per host:**
- **(A) Primary path** — paste-prompt + `./install.sh`.
- **(B) Accelerator path** — the one-command plugin / `npx skills add` route where one
  exists (Claude Code plugin, Codex plugin, Gemini `gemini skills install`, `cmd skills add`).
  Variant B exists to feed the distribution tie-break (§5).

## 2. Assertions (each is pass/fail, recorded per host)

Record per host, with the exact command output or error attached:

1. **(a) Files land.** All skills land in a directory the host actually reads:
   - `frontend-kit`, `frontend-judge`, `frontend-design`, `impeccable`, 8× `gsap-*`, `threeui`, `ui-ux-pro-max-reference`,
     `taste-reference` — each with `SKILL.md` at the skill-folder root, `name` field
     matching the folder name. (15 skills total; `frontend-design` is Anthropic's
     skill vendored verbatim — see `skills/frontend-design/SOURCE.md`. If the
     user also has the official `frontend-design` installed, the kit copy wins
     as the pinned one and the official install should be removed.)
   - Codex: check **both** `~/.agents/skills/` and `~/.codex/skills/` (unresolved
     discrepancy — record which one the host actually reads).
   - Reference data exists under `~/.local/share/agent-design-references/`
     (`ui-ux-pro-max`, `taste`).
   - OpenCode command files exist at `~/.config/opencode/commands/impeccable.md`
     and `~/.config/opencode/commands/frontend-kit.md`.
   - No pre-existing skill was destroyed: stage a same-named dummy skill before the
     run; the backup dir must exist and be non-empty afterwards.
2. **(b) Host lists the skills after restart/reload.** The host's skill-list command
   shows all skill names **after the documented restart/reload**:
   - Claude Code `/skills`; Codex `$` / `/skills` (new plugin → `/new` first);
     OpenCode session after restart; Gemini `/skills list` / `gemini skills list --all`;
     Copilot instructions files present in `.github/` (agent mode only);
     Hermes `hermes skills list`; Muse Code / Cursor skill list in a new session.
   - A skill with a wrong `name`/folder mismatch counts as a FAILURE, not a pass.
   - **False-success rule:** any host that reports success while assertion (b) fails
     is a KIT FAIL (the §8.2 false-success mode exists to catch exactly this).
3. **(c) `verify.sh` passes.** v2 `verify.sh` exits 0 (or its per-host equivalent
   assertions): skills present per host, `playwright-cli --help` runs, a headless
   390px screenshot succeeds, `impeccable detect` runs, gate scripts run, installed
   engine version matches the skill's expected engine (mismatch = loud failure).
4. **(d) Probe build with the hook firing at least once unprompted.** From a vague
   brief (see `probe-briefs/` — landing page, dashboard, redesign, plus Brief 4:
   landing page with motion + 3D hero), the agent runs
   the taste-locked loop and produces a page. Record:
   - Did the Impeccable hook / detector fire at least once **without being manually invoked**?
   - Was `taste-reference` consulted before building (taste lock)?
   - Was a Playwright screenshot taken and reviewed at 1440 / 768 / 390?
   - Score the output against the kit's Definition of Done (set by the council — this
     spec does not invent the rubric). Every score recorded under (d) carries the
     named independent grader label; a builder self-grade is FORBIDDEN and invalid,
     and does not count.
   - Delegation (Brief 4 only, artifact-checkable — not builder self-report): does
     the built HTML contain a ScrollTrigger scrub/pin call matching the Design
     Read's named pattern, and does the run log name the skill file + the pattern
     number? Does the built HTML import the named ThreeUI catalog component, and
     does the run log name `skills/threeui/SKILL.md` + the component? A probe run
     that passes (d) while failing this bullet has the delegation still only on
     paper. Probe-set note: Brief 4 changes the probe set — scores from the
     original 3-brief set are a separate vintage from 4-brief runs.
5. **Hook present where supported.** `hooks status` (Claude) / `/hooks` approval state
   (Codex) / `hermes plugins enable` state shows the Impeccable design hook wired.
   On hosts without hook support (Gemini CLI — no evidence), the report says so
   explicitly rather than silently omitting it.
6. **MCP present where configured.** Playwright appears in `<host> mcp list` / `/mcp`
   and connects. Figma is explicitly NOT installed (human-OAuth pending) and the
   report names the exact command for the user.
7. **Failure behaviour.** If any step fails, the agent's report names the failed step,
   the error, and the exact human action needed — no silent skip, no invented fix.

## 3. Pass / fail criteria

- **Per-host PASS:** assertions 1–3 pass; 4–6 pass **or** are explicitly reported as
  unsupported/pending with the exact follow-up command; 7 holds on any failure.
- **Kit PASS:** per-host PASS on Claude Code, Codex, and OpenCode, plus at least 2 of
  the remaining 4 hosts. **Kit FAIL otherwise, or if any host silently reports success
  while assertion (b) fails.**
- **Loop promise gate:** assertion (d) on at least the Claude/Codex/OpenCode subset is
  required before the README may promise the loop. Until then, file-copy is primary
  on the evidence — it is the only approach with positive evidence on all seven hosts.

## 4. Tie-break readout (distribution: file-copy vs `npx skills add`)

Compare variant A vs B per host on assertions (a)–(c) and on the count of human
interventions. **If `npx skills add` passes (a)–(c) on ≥6/7 hosts including
Muse Code/Hermes/Copilot, it displaces file-copy as primary** and `install.sh` becomes the
fallback for Node-less machines. Until that experiment runs, file-copy is primary.

## 5. First-failure record (the phase-2 worklist)

For each host, record the **first failure with the exact error** — that list IS the
worklist. (Note, fixed 2026-11-10: the red-team's already-known instance — the stale
`${CLAUDE_PLUGIN_ROOT}` path in the vendored Pro Max SKILL.md — is CLOSED: the 11
refs were replaced by `<skill-dir>/scripts/search.py` and zero `${CLAUDE_PLUGIN_ROOT}`
refs remain in the vendored tree, verified 2026-11-10. Do not re-list it as a live
first failure; the most-likely-first-failure pick is re-made at run time.)

| Host | First failure (exact error) | Variant | Node present? |
|---|---|---|---|
| Claude Code | _to fill_ | | |
| Codex CLI | _to fill_ | | |
| OpenCode | _to fill_ | | |
| Gemini CLI | _to fill_ | | |
| GitHub Copilot | _to fill_ | | |
| Hermes Agent | _to fill_ | | |
| Muse Code | _to fill_ | | |

## 6. What this spec deliberately does NOT test

- No performance benchmarks; no design-quality judging beyond assertion (d)'s process
  checks (quality judging belongs to the council/red team with its own rubric).
- No Windows/macOS paths until `install.sh` gains them (v1 is Linux-only — the test
  matrix is Linux until the script changes).
- No CommandCode (`cmd`) or Cursor clean-env runs: the matrix is the synthesis §5
  seven, but `install.sh` also targets both — their install paths are untested until
  a run is added for them.
- No Muse-app install test: there is no install path to test. The Muse-app paste packet
  gets its own end-to-end test in the app (paste packet → probe build → human rating);
  if it cannot reach 60%, the Muse app is dropped from the headline claim.
