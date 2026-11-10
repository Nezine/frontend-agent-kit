---
name: frontend-kit
description: "Build or redesign a frontend from a vague brief through a taste-locked loop: lock tokens against references, generate 5 CSS-only variants, then build, run the deterministic gate, grade 1–5 on Type/Layout/Colour/Space, fix the top 2, and stop at the human gate. Use for landing pages, dashboards, and redesigns when the user wants a verified result, not a first draft."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Hermes Agent, Muse Code, CommandCode, Cursor. Full loop needs a shell, Node 22+, and system Chrome; without them it degrades per references/stop-rules.md, never by faking a grade.
metadata:
  version: "0.1.0"
---

# frontend-kit — the taste-locked deterministic-gate loop

You are the orchestrator for one frontend build. You do not write the final
page in one shot, and you never grade your own work and call it done. You run
the loop below, in order, delegating each step to the sub-skill or script named
for it. You never duplicate a sub-skill's content in this file: when a step
names another skill, read that skill and follow it.

The full loop spec lives in `references/workflow.md`. The grade rubric lives in
`references/grader-rubric.md`. The stop rules and the degradation ladder live
in `references/stop-rules.md`. The expert pack (10 independent domain
specialists + call rules) lives in `references/expert-pack.md` and
`experts/<domain>.md`. The 5 variants as concrete token directions live in
`references/variant-briefs.md`; the human-gate question bank lives in
`references/human-gate-pack.md`. The converge checklist lives in
`references/converge-checklist.md`; the anti-cliché blocklist in
`references/anti-cliche.md`; the anchored style recipes in
`references/style-recipes/` (read the INDEX first, then only the one
recipe file the brief names — never the whole catalog). Read workflow,
rubric, and stop-rules before starting step 0. If they disagree with this
file, they win — they are the detailed record; this file is the route map.

## Precedence — READ THIS FIRST (before step 1.4 delegates anything)

The orchestrator's grader rule (Step 4.4, `references/grader-rubric.md`)
OVERRIDES any vendored `critique.md` / `new-work.md` / degraded-agent
text that permits single-context self-critique — including upstream
Impeccable `reference/critique.md` (which requires a
`⚠️ DEGRADED: single-context` banner on degraded runs), upstream
Impeccable `reference/new-work.md` (which substitutes a fresh in-thread
finish-reviewer pass and a Verdict Pass from
`degraded/finish-reviewer.md` when no subagent capability exists — no such file exists in the vendored tree), and
`skills/frontend-design/SKILL.md:57–59` ("Critique your own work"). Those
passages are upstream text the kit vendors verbatim in the canonical
copies and does not rewrite there (the generator transforms only the
generated copies — see `scripts/generate-host-variants.sh`); inside this
kit they are overridden and must not be followed as grading instructions. A
`⚠️ DEGRADED: single-context` banner is NOT an accepted grade anywhere in
this kit: a degraded run has no grade, and the round's grade is exactly
"gate green, vision not available".

This rule sits here, before any step, on purpose: step 1.4 delegates to
`frontend-design`, whose own text tells the agent to critique its own work
as it builds. That sentence is overridden by this section — you meet the
override BEFORE you meet the delegation, so following the steps in order
never leads you to self-critique first and discover the override later.

## When to use this skill

Use when the user asks for a landing page, a dashboard or app screen, a
redesign, or anything phrased like "make it look good", "build me a page for
…", "redesign this", or a vague brief with no visual direction. Use it for the
whole build, not for a single tweak: a one-line CSS fix does not need the loop.

Do not use it for backend work, for copy-only edits, or when the user has
already locked the design and only wants an implementation. Do not use it to
re-argue a direction the human already picked — a pick is feedback, not a
prompt for discussion.

## Step 0 — Setup (once per project, before any build)

1. Create the taste folder from the kit template. Copy
   `templates/design/` into the project as `design/`:
   `design/TASTE.md`, `design/tokens.css`, `design/demo.html` (the 1-page
   taste-lock demo, step 1.3), `design/primitives.css` (the primitive-layer
   template — optional split-out, NOT linked by default; see the
   token-naming contract below),
   `design/references/DESIGN.md/` (Vercel, Claude, Linear — each labelled
   third-party analysis, not official), plus empty `design/references/`,
   `design/screenshots/`, and `design/variants/` folders. The plan
   template `design/PLAN.md`, the Design Read template
   `design/DESIGN-READ.md`, the design-system declaration template
   `design/DESIGN-SYSTEM.md`, and the round-folder scaffold
   `design/rounds/` (README + `_template/`) are copied with them and
   filled in at step 1 (plan, Design Read, declaration) and step 5
   (one `design/rounds/<n>/` per fix round).
2. Fill in `design/TASTE.md` from the brief and from the user: one-paragraph
   intent, likes, dislikes, hard rules. If the user names sites they love,
   save 8–15 screenshots of them in `design/references/`, named by site
   (`linear.png`, `stripe.png`) — screenshots, not links. If the browser
   has no external network in this environment (probe 2: the sandbox's
   egress proxy needs auth Chrome cannot supply headlessly — curl works,
   the browser gets `ERR_TUNNEL_CONNECTION_FAILED`), reference
   screenshots degrade to the vendored DESIGN.md files alone: record that
   degradation in the run log and continue; do not fake screenshots, and
   do not treat the missing step as run. Webfonts likewise render as
   fallbacks in that environment — same cause, same degradation note.
3. Confirm the tools for the loop exist in this environment: Node 22+,
   system Chrome, `playwright-cli`, and `impeccable detect` (via the kit's
   `scripts/gate/detect.mjs`). If any is missing, note which degradation rung
   of the ladder applies (`references/stop-rules.md`) and continue on that
   rung — do not pretend the missing step ran. **No system Chrome, but the
   kit-installed Playwright chromium exists:** the browser leg still runs —
   point `CHROME_PATH` at it
   (`CHROME_PATH=$HOME/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`;
   note `chrome-linux64`, not `chrome-linux`). `detect.mjs` never downloads
   anything: if `impeccable` is not on PATH it uses the installed launcher
   and otherwise fails loudly (exit 3) — a silent npx download mid-gate
   was removed in the probe-2 reconciliation.

## Step 1 — Brief → taste lock (no build yet)

1. Read the brief, `design/TASTE.md`, and the chosen DESIGN.md file. Pick the
   reference direction: which sites, which DESIGN.md, and why — in one short
   paragraph, written into the run log. If the brief names an anchor
   ("Linear-style", "Aesop feeling"), read ONLY that one recipe file in
   `references/style-recipes/` (INDEX.md first, then the one file) — never
   the whole catalog. Read `references/anti-cliche.md` before writing
   anything: the blocklist names the generic patterns this step must not
   lock in.
2. **Design Read (end of step 1, before tokens).** Summarise the brief in
   `design/DESIGN-READ.md` (template: `templates/design/DESIGN-READ.md`):
   artifact, audience, visual language (a specific family, not "modern /
   clean"), mode (greenfield / extension / preserve / overhaul), anchor /
   recipe if any, and the five dials — visual variance, motion intensity,
   information density, asset dependence, brand fidelity — each as a
   categorical position (Low / Med / High) with a one-line anchor. The
   dials are INTENT, not scores: they must affect real decisions (layout
   variation, motion, content per viewport, real-asset effort,
   preservation strictness) or they are decorative labels. No dial value
   may be cited as evidence for any grade or stop decision, and the judge
   NEVER receives the dials. Copy the dials into `design/PLAN.md`
   § Design Read. (Adapted from garden-skills `web-design-engineer`
   Step 2b — five dials, categorical here instead of its 1–10 numbers;
   see SOURCES.md for the no-vendoring note.)
3. Write `design/tokens.css`: type scale, colour roles, space scale, radius,
   motion. Name every token per the token-naming contract below (P19):
   two layers, primitives value-named, semantic roles only in HTML/CSS,
   on-* pairing for every surface. Start from the template's values only
   as a starting point; the locked reference overrides them. If the
   project has a Figma file with Variables, the export is an optional
   step-1 input — see "Figma input" below; it replaces the handwriting
   of the token values, not the taste judgement.
4. Build a 1-page demo proving the tokens work. Use the demo file at
   `templates/design/demo.html` (copied into the project as
   `design/demo.html` by step 0) — the same content every time so tokens
   stay comparable across briefs. The demo exercises every expected token
   (display/body/mono type, hero scale, colour roles incl. accent, space
   scale, radius, motion) against the LOCKED `tokens.css`, not the
   template's starting values. **Pass criterion:** the demo renders every
   listed token visibly AND passes the step-3 gate when gated on its own
   (`gate.sh --target design/demo.html`: `detect` 0 findings, static
   checks pass). The every-listed-token half is scripted, not asserted:
   `gate.sh` §1b reads the demo header's EXPECTED TOKENS block and fails
   the gate when any listed token is undefined in `tokens.css` or
   unreferenced in the demo body. A demo that fails the gate proves the tokens — not the
   demo — are wrong: fix the tokens, not the demo file.
5. Direction-setting: delegate to `frontend-design`. Read its SKILL.md
   and follow its plan-first process exactly: 4–6 named colours, type roles,
   ASCII wireframes, then the counterfactual plan check — worked through a
   similar prompt, would you arrive somewhere similar? If yes, the plan is
   generic: fix the plan, not the build. Say what changed and why.
   **Note:** `frontend-design`'s own sentence "Critique your own work as
   you build" (its SKILL.md:57–59) is OVERRIDDEN by the Precedence section
   at the top of this file — do not follow it. Direction-setting from that
   skill is plan-first only; no self-critique, no self-grade.
6. **Design-system declaration.** Write `design/DESIGN-SYSTEM.md` from
   `templates/design/DESIGN-SYSTEM.md`: reference mapping (which
   DESIGN.md / reference site each token family comes from), do/don't
   rules, rationale. RATIONALE ONLY — it must not contain a single token
   value (no hex codes, no pixel sizes, no custom property definitions);
   `tokens.css` is the single source of truth for every value and governs
   on any drift. Fix rounds touch `tokens.css` only and never
   hand-maintain this file after the lock. (Adapted from garden-skills
   Step 3 — "declare the design system in Markdown before writing code";
   the no-values rule and the tokens-govern drift rule are the kit's
   answer to the two-sources-of-truth problem.)
7. **Plan + approval.** Write `design/PLAN.md` from
   `templates/design/PLAN.md`: decisions, assumptions, section inventory
   (by content, not order), EARS acceptance criteria (5–8 WHEN / THE
   SYSTEM SHALL lines, including the 390px no-overflow rule and the
   three-width rule), the screen × state matrix, the Design Read dials
   (copied from step 1.2), and the design-system pointer section. Then
   the approval gate:
   - **Solo run:** the human approves `design/PLAN.md` before ANY build.
     No build starts on an unapproved plan. Record the approval in
     PLAN.md § Approval record.
   - **Human-less / buffet run:** there is no human to approve, so the
     plan proceeds WITHOUT human approval. The approval substitute is
     the blocking converge check (step 3 / step 6) plus the
     first-round independent grade; record that basis as a field on the
     lock entry — `run-log.mjs lock ... --approved-by "converge-check
     + round-1 grade (no human present)"` (step 1.8). Coordinator
     approval is NOT an approval and is never recorded as
     one — a coordinator approving a plan its own run wrote is
     self-approval, the same back door as builder self-grading.
   The plan never moves the lock: round deltas merge into PLAN.md
   § Amendments, the token dictionary, and the run log's notes — never
   into TASTE.md or `tokens.css` mid-loop (see step 5.5).
8. **Verifiable artifact:** commit `design/tokens.css` and the chosen
   references BEFORE any page HTML is written. If the finished page's tokens
   do not match the locked references, the workflow has a hole, not a feature.
   **"Commit" means exactly this (no more, no less):** (a) the files are
   saved under `design/` in the project, AND (b) the lock is recorded in
   the run log with `node scripts/run-log.mjs --project <dir> lock
   --tokens design/tokens.css --refs <chosen DESIGN.md + reference
   screenshots> [--version N] [--approved-by "<approval basis>"]`. If
   the project is a git repo, ALSO run `git add design/
   && git commit -m "Taste lock: <direction>"`; if it is not a git repo,
   (a) + (b) alone ARE the commit — never create a repo just for this, and
   never treat "saved the file" without the run-log lock as committed.
   The lock is immutable within a direction: a re-pick creates a NEW lock
   version, recorded by a new `run-log.mjs lock` entry. The version is a
   script field, not a hand-written note: `--version N` records an
   explicit version (default: existing lock count + 1); re-using an
   existing version is rejected. The lock entry also records the sha256
   of the tokens file automatically, and `--approved-by` carries the
   step-1.7 approval basis on human-less runs (omit it on solo runs —
   human approval lives in PLAN.md § Approval record). The 5-line lock
   summary at the top of `design/TASTE.md` is filled from the brief the
   generator emits (see "Round briefs + per-role context budgets"
   below), never hand-written.

## Token-naming contract (P19 — read before writing tokens.css)

Names survive palette refreshes; values don't. A token's name must say
what the value is FOR, never what it IS — so a rebrand touches one layer
and every role keeps working. Sources (read 2026-11-10): Nathan Curtis,
"Naming Tokens in Design Systems"
(https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676);
Material Design 3, "Design tokens"
(https://m3.material.io/foundations/design-tokens/overview/).

**Two layers (Material ref/sys/comp mapped onto the kit).**
- Layer 1 — primitives (`--primitive-*`): raw values, VALUE-named
  (category + scale, e.g. `--primitive-neutral-600`). A rebrand touches
  ONLY this layer. This is Material's `ref` class. Lives in
  `design/tokens.css` (Layer 1 block) or, split out, in
  `design/primitives.css` — exactly ONE definition per primitive per
  project, never both.
- Layer 2 — semantic roles (`--color-*`, `--text-*`, `--space-*`,
  `--radius-*`, `--motion-*`, `--font-*`, `--leading-*`, `--tracking-*`,
  `--border-*`): purpose-named, the ONLY thing HTML/CSS references. A
  role aliases a primitive (`var(--primitive-...)`), never a literal.
  This is Material's `sys` class.
- Material's `comp` class (per-component tokens) is deliberately absent:
  components read semantic roles directly. Promote a comp token only
  when 3+ components share the decision (Curtis's rule of thumb) — never
  for one component, never pre-emptively ("don't globalize decisions
  prematurely").
- FORBIDDEN: component CSS referencing a primitive (`var(--primitive-*)`)
  anywhere outside `tokens.css`/`primitives.css`. Enforced by
  `scripts/gate/lint-tokens.mjs` (step-3 gate FAIL).

**Curtis levels, in order — namespace → object → base → modifiers.**
- Base (backbone, always present): category (`color`, `font`, `space`,
  `radius`, `motion`) + concept (`action`, `feedback`, `heading`,
  `body`, `card`) + property (`background`, `text`, `size`, `radius`).
- Modifiers (appended last, mode last): variant (`primary`, `secondary`),
  state (`hover`, `disabled`), scale (`1`, `2`, `100`, `xs`, `lg`), mode
  (`on-dark`).
- Object (component / nested element / component group): only when the
  decision belongs to components, subordinate to the namespace and
  preceding base/modifiers (e.g. `--color-card-surface`).
- Namespace (system/theme/domain): this kit has none — the `--` prefix is
  the namespace slot. Do not invent one (no `--kit-*` prefix).
- COMPLETENESS: include ONLY the levels needed to describe and
  distinguish the intent. Never dogmatically include every level —
  Curtis: `$esds-shape-tile-corner-radius`, not
  `$esds-shape-tile-corner-radius-default-on-light`.
- HOMONYMS: never use `type` as a category (typography vs data type).
  Never coin a new `--text-*` name for anything but a font size — the
  kit's `--text-*` scale is font sizes, locked since v1 (a `text` homonym:
  content vs typography vs property).
- MODE vs THEME: a mode is a context value (light/dark); a theme is the
  whole set. Name modes explicitly (`on-dark`); never rely on an implied
  light default — the dark block in `tokens.css` is sparse overrides
  (diffs only, see the Figma input section).

**On-* pairing.** Every surface role has an `on-*` text role defined
beside it in the same edit (`--color-canvas` → `--color-on-canvas`,
`--color-surface` → `--color-on-surface`, `--color-accent` →
`--color-on-accent`). The template's pre-contract text names
(`--color-ink`, `--color-body`, `--color-mute`) are the on-canvas roles
under their locked names — the on-* roles alias them
(`--color-on-canvas: var(--color-ink)`). A surface without its on-*
role fails `lint-tokens.mjs`. Text on a surface always uses the paired
on-* role, never a bare primitive and never another surface's text role.

**Examples.** Good: `--color-feedback-error` (category color, concept
feedback, property implied), `--color-button-primary-hover-background`
(variant + state modifiers), `--space-section` (category + concept).
Bad: `--color-red-500` as a role (that's a primitive's name, in the
wrong layer), `--type-heading` (`type` homonym), `--color-button`
(every level below the concept missing — which button, which property?),
`--text-heading-color` (mixes the locked font-size scale with a colour
role — use `--color-heading`).

**What the linter enforces (mechanical) vs what you judge.** `lint-tokens.mjs`
checks kebab-case names, the primitive/component-CSS separation, and the
on-* pairing — the parts a regex can prove. Homonyms, completeness, and
the 3-component promotion rule are judgement calls: apply them when you
write the name, and say so in the round log when you coin a new one.

## Figma input — optional step-1 module (P15/P17/P18)

Applies when the brief's Figma file has Variables (a Tokens collection).
The pull happens in step 1, between "pick the reference direction" and
"write tokens.css" — it replaces the HANDWRITING of the token values,
not the taste judgement. The agent still chooses which references and
which tokens survive (a Figma file with 400 variables must not become a
400-line tokens.css), and still builds the demo proving the tokens work.

**Human-gated export.** Figma is human-gated only (AGENTS.md §4): the
human exports from Variables view (Export mode(s) → DTCG JSON, one file
per mode) and hands the files to the agent. The agent reads the files;
it never calls the Variables REST API (Enterprise-only — 403 otherwise)
and never promises MCP live pull (`get_variable_defs` is
selection-scoped, remote-vs-desktop unresolved — experimental, test at
build time, not in the kit).

**Input contract — DTCG 2025.10 (P15).** Pin: SOURCES.md, "Design Tokens
Format Module 2025.10", Final Community Group Report 2025-10-28,
https://www.designtokens.org/TR/2025.10/format/ (read 2026-11-10).
Never cite the `tr.designtokens.org` draft URL. The spec is "considered
stable" and "intended for implementation"; it is NOT a W3C Standard and
not on Standards Track.
- Parse OBJECT-VALUED tokens: color (`{colorSpace, components, alpha,
  hex}`), dimension (`{value, unit: px|rem}`), duration (`{value, unit:
  ms|s}`), fontWeight (1–1000 or named alias), fontFamily (string or
  array), cubicBezier ([P1x, P1y, P2x, P2y]), number (a JSON number).
  `$value` is the only required property; a token's type is its `$type`,
  or the closest parent group's `$type` (inherited).
- REJECT type-less tokens — NEVER GUESS. A token with no `$type` and no
  inherited group `$type` is a hard error ("Tools MUST NOT attempt to
  guess the type"). No default, no inference from the value shape.
- ERROR LOUDLY (fail the step, do not continue with a partial token set)
  on: circular references (detect BEFORE resolution — "Tools MUST detect
  and report this as an error affecting all tokens in the circular
  chain"), dangling/unresolvable references, type mismatches (a reference
  whose target type differs from the expected type), and post-normalisation
  name collisions (two Figma names that normalise to the same token name —
  Figma import silently drops duplicates; the converter must not).
- WARN (continue, record in the round log) on `$deprecated` tokens —
  include them, flagged, so the human can see what is dying; never
  silently drop them.
- STRICT/LEGACY SPLIT. The strict path above is the default. Legacy
  string shapes (plain `"#ffffff"` / `"16px"` strings, Tokens Studio
  legacy export) are accepted ONLY as an explicit fallback: the file must
  be marked legacy (per file, noted in the round log), the converter
  prints a warning per legacy token, and a legacy token is never silently
  promoted to strict. If a file mixes strict and legacy shapes, the legacy
  tokens are listed in the log and the strict tokens are unaffected. The
  legacy path is explicit, warned, and opt-in per file — never silent.
  That is how the never-guess rule and the legacy fallback coexist.
- Output: `design/tokens.css` in the kit's two-layer shape (Layer 1
  primitives from the Figma raw values, Layer 2 semantic roles from the
  Figma roles/aliases, named per the token-naming contract above).
  Aliases in the Figma file become `var(--...)` references in Layer 2.
- Plan gate: Figma Starter has ONE variable mode; modes (light/dark)
  need Pro+. Never tell a Starter user to "just add a Dark mode"
  (verified 2026-11-10, see `research/figma-integration/SYNTHESIS.md`).

**Converter status — honest.** The converter script
(`scripts/figma-tokens-to-css.mjs`) is NOT built yet (recorded in
`coord/BOARD.md` — do not claim it exists). Until it lands, the agent
applies this contract BY HAND when reading an exported JSON file: same
rules, same errors, same warnings, recorded in the round log. The
contract is the spec the converter will implement; the spec is done, the
script is not.

**$extensions is the sanctioned channel for Figma metadata (P17).**
DTCG's `$extensions` object is where tool- and vendor-specific data
lives — the converter reads Figma metadata ONLY from there, never from
a guessed field name. The pattern is Primer's (`org.primer.figma`
carrying `collection` / `mode` / `scopes` — Primer primitives README,
https://raw.githubusercontent.com/primer/primitives/main/README.md,
read 2026-11-10): a token's `$extensions["org.primer.figma"]` (or the
equivalent vendor key for the file at hand) records which Figma
collection and mode it came from and which scopes it applies to. The
converter MUST preserve `$extensions` through the parse (it is part of
the token, not decoration) and MUST NOT invent an `$extensions` key
that the file does not carry. Token names in the file must be camelCase
or kebab-case and contain only letters, numbers and `-` (Primer's
validation rule, enforced by their `npm run lint:tokens` — the same
shape as this kit's T1 kebab-case check; the kit's T1 is stricter,
kebab-case only).

**Dark themes are sparse overrides (P17).** A dark theme lists ONLY the
roles whose values change from light (diffs, not a full copy) —
Primer's `overrides` pattern (a mode made "by only including the
changes from the main mode", in `src/tokens/functional/color/[light|dark]/overrides/`).
The template's `[data-theme="dark"]` block already follows it: every
dark override still aliases a Layer 1 primitive, and the on-* roles
follow the same pairing as light. When a Figma export brings a dark
mode, the converter emits the dark-mode diffs only — a full second copy
of the token set is a failure of the step, not a style choice.

**What P17 did NOT build (council, unanimous): the per-mode contrast
gate is DROPPED.** Primer's README carries an accessibility-contrast
badge, but its contrast-check workflow was not read — do not claim
Primer contrast CI exists, and do not add a contrast gate to step 3.
Contrast is checked by the existing WCAG2AA pa11y validator (§4),
not by a new per-mode gate.

**Converter upgrade (P18) — Terrazzo first, Style Dictionary second.**
The vendored converter (or the hand application of its contract, until
the script is built) is the DEFAULT. Upgrade only when the project
keeps tokens in a repo with many modes/themes. An upgrade never
replaces the taste judgement — it only replaces the handwriting.
- **Recommended: Terrazzo `@terrazzo/cli` 2.10.0, MIT** (VERIFIED — npm
  registry, read 2026-11-10). DTCG-first: it speaks the DTCG format
  natively. The CSS plugin maps modes → any selector via `permutations`
  (default → `:root`; dark → `@media (prefers-color-scheme: dark)`
  and/or `[data-theme="dark"]`; a `size: desktop` mode → `@media (width
  >= 600px)`). Aliases must be redeclared inside each mode block
  ("duplication is not a bug"). `include` / `exclude` token globs
  per-plugin or per-permutation. Color Module 4: P3 / Rec2020 / OKLCH
  auto-downconverted with Color.js gamut mapping, 30-bit color depth
  default. The Tailwind plugin generates Tailwind v4 `@theme` from
  DTCG; composite typography becomes paired `--text-xs--line-height`
  tokens. Setup: `npm i -D @terrazzo/cli @terrazzo/plugin-css` +
  `terrazzo.config.ts` + `npx tz build`. Sources:
  https://terrazzo.app/docs/integrations/css/ and
  https://terrazzo.app/docs/integrations/tailwind/ (read 2026-11-10).
  No Node minimum is stated here — the Terrazzo docs say only
  "Requires Node.js" and the registry entry carries no `engines` field;
  the kit already requires Node 22+, which is the binding floor.
- **Second: Style Dictionary 5.8.0, Apache-2.0, engines node >=
  22.0.0** (VERIFIED — npm registry, read 2026-11-10).
  `css/variables` + `outputReferences: true`, `options.selector`
  overrides `:root`; a custom format via `registerFormat` emits the
  kit's `tokens.css` shape. CAVEAT: DTCG first-class since v4, BUT the
  latest format 2025.10 does not have full support yet in Style
  Dictionary — a work in progress in v5
  (https://styledictionary.com/info/dtcg/, read 2026-11-10). A project
  whose tokens use 2025.10 features must not assume Style Dictionary
  round-trips them — prefer Terrazzo until the v5 work lands.

## Round briefs + per-role context budgets (P7 — fresh context per round)

Every round after round 1 starts from a FRESH context assembled by
script — never from the previous round's context, and never from the
full run log. The full log stays in a file, not in context: quality
falls as input length grows, and the lock sits mid-context where
attention sags. The judge is ALREADY fresh per round (a judge that
graded round 1 must not grade round 2 — see `frontend-judge`
`references/invocation.md`); P7 adds the builder/fixer half only.
There is no separate `run.json` file: run state lives in the
append-only run log (`run-log.mjs` — tokens hash, picked variant,
per-round gate/scores/evidence/fix-class/outcome), and the brief is
assembled from it.

1. **Assemble the brief with the generator, every round.**
   `node scripts/run-log.mjs --project <dir> brief [--round N]` (or
   `node scripts/round-brief.mjs --project <dir> [--round N]` directly).
   The brief contains, and nothing else: the 5-line lock summary, the
   locked `tokens.css` verbatim, the best HTML verbatim, the latest
   round's gate findings, grader evidence lines (latest + best round
   only), and a one-line-per-round run-state table. **All axes start
   "ungraded" for the new round** — no score is ever carried from an
   earlier round; a score only moves when an independent judge writes
   evidence for it. The lock is restated at the end of every brief,
   immediately before the output instruction.
2. **The generator fails loudly, it never drops signal silently.** If
   the lock, the best-HTML path, the latest round's gate findings, or a
   graded round's evidence lines are missing, the brief command exits 1
   and prints nothing — fix the log (re-record the round with
   `--gate-findings` / `--evidence` / `--page`), do not work around it.
   `--allow-missing` (round-brief only) downgrades a gap to an explicit
   "NOT RECORDED" line; it never invents the missing field.
3. **Fallback when the generator cannot run (no Node).** Hand-assemble
   the same field list from the run log's LAST record + the locked
   tokens — same sections, same order, same "ungraded" axes. Last
   resort only, the brief is the full run log, labelled
   `brief: full-log (generator unavailable)` — labelled, never silently
   pasted. The generator is a convenience for assembling the brief, not
   a load-bearing dependency: a round without a brief does not run.
4. **Per-role context budgets — what each role may load.** The brief
   the generator emits IS the builder/fixer budget in full: nothing
   beyond it goes into a builder or fixer prompt except the fix
   instruction itself (which cites a gate finding, a grader evidence
   line, or a human instruction — step 5.4). Anything else in the
   prompt violates the budget.

   | Role | May load | Must never load |
   |---|---|---|
   | Orchestrator | The run log file, PLAN.md, the briefs; the full project on disk | Pastes the full run log into any subagent prompt |
   | Builder (round N) | The round brief only: locked tokens + best HTML + gate findings + grader evidence lines + run-state table | The full run log, earlier HTML versions, its own reasoning from a prior round |
   | Fixer (round N+1) | Same as the builder — the new round's brief | Same as the builder |
   | Judge | Screenshots + the 1–3 locked reference shots + rubric/scope + the 5-line lock text + tool measurements (+ pairwise A/B inputs when the stop round calls for them) | Model/builder identity, earlier scores, the run log, gate findings — the single `gate: green` bit from the orchestrator's pre-filter is the only gate information the judge receives |
   | Expert (second opinion) | Same as the judge, plus the one domain question it was asked | Same as the judge |

   Measurable check: the builder/fixer prompt is the generator's brief
   output plus one fix instruction. If a prompt to the builder contains
   anything beyond that, the budget is broken — stop and rebuild the
   prompt from the brief.

## Step 2 — Build (one HTML file, tokens only)

1. Content first, then sections — one section per screen for landing pages;
   dashboards / app screens use the dense multi-panel layout instead (see the
   brief-type scoping table in step 3 — it governs both the build shape and
   the gate). No inline style drift: every visual value comes from
   `design/tokens.css`. A new token is added to the file first, then used.
2. If the brief is vague on direction, generate the 5 CSS-only variants
   before building further: same content, same copy, same semantic HTML —
   only CSS changes. The five are Editorial, Dark, Warm brutalist, Glassy,
   Minimal — each as a concrete token direction in
   `references/variant-briefs.md` (do not invent five directions from
   priors). Each gets its own tokens and its own screenshot at the same
   width. **Variant folder layout (the picker requires this exact layout):**
   `design/variants/<name>/tokens.css`,
   `design/variants/<name>/screenshot-1440.png` (same width for every
   variant), `design/variants/<name>/index.html` (same content, same copy,
   same semantic HTML — only the stylesheet link differs). A flat layout
   (`<name>.html` + `<name>-tokens.css` + `<name>-1440.png`) is rejected
   by `variant-picker.mjs check`. Run `scripts/variant-picker.mjs` to list
   them and record the pick.
3. **Step 2a — the human picks one variant.** The pick IS the feedback.
   Never re-argue direction in prose. Build on the picked variant only.
   **Human-less runs (no human to pick):** use the deterministic pick —
   run `variant-picker.mjs pick --auto`, which picks the variant whose
   tokens match the LOCKED `design/tokens.css` most closely (count of
   locked `--name: value` declarations reproduced exactly; ties broken
   alphabetically). State the rule before picking, record the pick with
   its scores in the run log, and give no quality verdict: the auto-pick
   says only which variant is closest to the locked direction.
   **"Play first, critique later" governs variant generation:** all five
   variants are generated before any critique. The v0 checkpoint below
   governs the PICKED variant's build only — never mid-generation.
4. **v0 draft checkpoint (inside step 2, on the picked variant only).**
   Before writing full components, build a viewable v0 skeleton at
   `design/v0.html`: core structure (every section from PLAN.md's
   inventory, in order) + the locked tokens + key module placeholders
   with explicit markers (`[image]`, `[icon]`) + the list of design
   assumptions. It does NOT include content details, the complete
   component set, all states, or motion. Placeholders use `[image]` /
   `[icon]` markers only — never `[NEED]` or `[insert]`, which the
   copy-lint leg fails as residue. A v0 with assumptions and
   placeholders is more valuable than a polished v1 that took three
   times the work: if the direction is wrong, the v1 has to be scrapped
   entirely.
   - **Solo run:** show the v0 to the human and wait for the nod
     before the full build. The nod is the course-correction point:
     tone, layout direction, variant directions.
   - **Human-less / buffet run:** there is no human to nod, and no
     coordinator nod either — a coordinator nodding at its own run's
     skeleton is self-approval, which defeats the checkpoint. The
     autonomous form is a DETERMINISTIC SKELETON GATE: run
     `gate.sh --target design/v0.html` (leg 1: no overflow, tokens
     resolve, no missing files) AND
     `node scripts/gate/converge-check.mjs --plan design/PLAN.md
     --page design/v0.html` (every planned section present as a
     placeholder section). Both must be green before the full build
     proceeds. The skeleton gate is a gate check, not a grade — the
     builder never judges its own skeleton. Record the skeleton, the
     tokens, and the skeleton-gate result in the run log as the
     direction receipt. (On a host with no Chrome the browser leg of
     the skeleton gate fails closed per H13; the checkpoint then
     degrades to the leg-1 static checks + the converge check, labelled
     as such in the run log — the full build still waits for the
     human gate to carry the visual judgement.)
   `design/v0.html` is a skeleton, not the deliverable: `gate.sh`
   excludes it from project-dir scans (like `design/demo.html`), and
   it is gated explicitly on its own file only.

## Step 3 — Deterministic gate (before any vision grade)

**The gate is TWO legs, BOTH required — a pass means both green on the
same build.** Leg 1 is `gate.sh` (taste lock + `impeccable detect` + static
checks, including a static visual-marker check). Leg 2 is `gate.mjs`
(copy-lint + the consistency browser leg). A `gate.sh` PASS on its own is
only leg 1 — it never means the gate passed. When the legs disagree, the
build is not green: fix the build, do not pick the greener leg, and never
lower a gate to green a bad page.

Run, in this order, and print every result in full — never summarise a gate
result. Leg 1 (`gate.sh`) also runs three newer checks: the anti-cliché
seed checks (`scripts/gate/anti-cliche.mjs`, §3c — AC-1 gradient,
AC-2 emoji), the token-naming lint (`scripts/gate/lint-tokens.mjs`, §3d
— T1 kebab-case names, T2 no primitive references in component CSS, T3
on-* text role for every `--color-*` used as a background, T4 colour
roles alias primitives, never literals), and, whenever `design/PLAN.md`
exists, the converge check (`scripts/gate/converge-check.mjs`, §5 —
every planned section/state exists in the build). All three fail the
gate like any leg-1 finding; the converge check additionally blocks
the human gate (step 6.1). The token-naming lint runs on the demo
target too — the template must pass its own lint.

1. `node scripts/gate/detect.mjs <page or dir>` — the `impeccable detect`
   wrapper (62 deterministic rules: 31 slop / 31 quality). Exit codes:
   0 = clean; **2 = findings — fix them**; **1 = the scan could not run**
   (missing file, bad target) — there are no findings to fix, so fix the
   invocation/target and re-run instead. **3 = no detector found** (no
   `impeccable` on PATH, no installed launcher) — install it, do not
   expect a download: the wrapper never downloads anything. No vision round is spent on a
   build the gate already fails.
2. `node scripts/gate/gate.mjs <page.html> [--kind <kind>]` — the kit gate. It runs the
   vendored taste-skill-style checks: `copy-lint.mjs` (copy FAILs) and
   `consistency.mjs --quick` (overflow / collide / tap-size, section height,
   one-section-per-screen) at checker widths 1440, 1024, 820, 768, 390.
   Exit codes: 0 = green; **1 = FAIL (findings — fix them)**;
   **2 = the checker could not run** (usage error, skipped browser leg,
   unreadable target) — there are no findings to fix, so fix the
   invocation/environment and re-run instead.
   **Pass `--kind` for the page** (`software`, `service`, `product`,
   `place` — see `references/layout-doctrine.md` §0): it decides which
   checks fire. An app marked `product` gets the physical-product checks
   it cannot pass; mark apps `software`/`service`. **No system Chrome:**
   run the browser leg with `CHROME_PATH` pointed at the kit-installed
   Playwright chromium (`$HOME/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`
   — `chrome-linux64`, not `chrome-linux`). The gate writes its crops and
   report to the OS temp dir by default, never into the project — and
   `gate.sh` excludes `.taste-skill/` from its scan, so one leg's output
   can never fail the other leg (probe G-7).
   **What the checker demands is TAUGHT, not assumed:** read
   `references/layout-doctrine.md` before building — one `.wrap` with no
   horizontal padding at desktop widths and 20px side MARGINS (not
   padding) below the 1240px container breakpoint (F-2/F-9: without them
   text touches the screen edges below 1248px and the hero clips
   mid-glyph at 390), the nav in the same `.wrap` with no extra padding
   and the CTA pushed right with `margin-left: auto`, 12-column splits on
   the shared k=5/6/7 line (SR-8), overlay nav, section fill ≥55% or
   merge (SR-3) — fill alone does NOT catch dead bands — section gaps
   128–288px at desktop widths, a gap over 288px at vw ≥ 1024 FAILs as a
   dead band (kit patch, probe 3 + judge), and below 820px NO section is
   `100svh` — every section's height follows its content (F-3: cutting the
   meeting paddings is a workaround, not the fix; `hero-fill` is scoped to
   desktop widths because at tablet widths it contradicts the gap rule), a
   visual covering ≥25% of
   every feature section (a photograph, or a `[data-ui]` UI mock ≥120×80px — small inline SVG
   icons do not count; a text-only mock also needs a small svg in its
   header bar or it FAILs as a band, F-5). A build that follows the
   doctrine can pass; a build that does not will fail leg 2,
   and that is a build failure.
   **Contrast — decorative vs functional accent:** a vendored reference's
   component that fails the contrast rule is NOT shippable verbatim.
   Claude's `callout-card-coral` (white text on coral #d97757, 3.12:1)
   fails WCAG AA and the kit's 7:1 body-text rule: keep coral DECORATIVE
   ONLY (never behind text) and use the darkened functional accent
   (#a9583e, white 5.06:1, passes AA) for text-bearing surfaces. Body /
   muted text keeps the kit's 7:1 rule; CTA text passes at WCAG AA 4.5:1.
3. `npx html-validate` and `npx pa11y --standard WCAG2AA` where available.
   A FAIL blocks the round.

**Brief-type scope — the landing-page gate does NOT apply unchanged to
every brief.** Apply the gate by brief type:

| Gate check | Landing page | Dashboard / app screen | Redesign |
|---|---|---|---|
| `detect` (62 rules) | Applies | Applies | Applies (to the NEW page) |
| copy-lint | Applies | Applies | Applies |
| overflow / collide / tap-size | Applies | Applies | Applies |
| one-section-per-screen + landing rhythm | Applies | Does NOT apply — dense multi-panel layout is expected; judge panel alignment, scan order, density vs legibility instead | Applies only if the page being redesigned is a landing page; otherwise use its own type's rule |
| section height | Applies | Applies per panel/card, not per screen | Same as its type |
| no-visual (visual ≥25% per feature section) | Applies — a photograph, or a `[data-ui]` UI mock ≥120×80px | Applies per panel/card (a panel's own UI is its visual; mark mocks `[data-ui]`) | Same as its type |
| section-gaps (dead-band ceiling) | Applies — no content-to-content gap over 288px at desktop widths (vw ≥ 1024); below 1024px gaps inflate with the viewport, so the structural hero-height rule governs instead (F-3) | Applies per panel/card gaps where the layout has them; a dashboard's dense panels are not dead bands | Same as its type |
| `mailto:` / `tel:` / `javascript:` links (leg 1 static check) | Applies — non-file schemes are exempt from the file-reference check; a legitimate `mailto:` CTA never fails leg 1 as "referenced file missing" (F-1) | Applies | Applies |
| product-shown | Applies ONLY to physical-product pages (kind `product`); does NOT apply to software/service/app pages — mark those `software`/`service`, do not fake photographs | Does NOT apply | Same as its type |
| html-validate / pa11y WCAG2AA | Applies | Applies | Applies, plus: existing content and links survive (dropped content / dead links = FAIL) |

The judge grades Layout by the same table (see `frontend-judge`).
`taste-reference` stays the default taste lens on every build; what is
scoped here is the GATE checks, not the lens.

FAIL blocks the round. Fix, then re-run the gate from the top. Do not proceed
to step 4 with a red gate.

## Step 4 — Eyes + grade (Playwright CLI)

1. Serve the page over http (never `file://` — module scripts do not run).
2. Screenshot at 1440 / 768 / 390 with Playwright CLI. Use `playwright-cli
   console` for errors and `snapshot` for structure (cheap, no image tokens).
   1024 is an optional fourth width; every extra width costs image tokens
   per round, so do not add widths casually.
   **At 390, look for glyphs cut at the viewport edges** (doctrine §8):
   brief 1's hero clipped mid-glyph at 390 while every DOM measurement
   reported "fits" — no box-based gate check catches ink overhang, so the
   eyes are the instrument here and the §1 phone gutter is the prevention.
   A 390 screenshot with text touching x=0 is a defect even when the gate
   is green.
3. Grade 1–5 on Type / Layout / Colour / Space against the locked reference,
   following `references/grader-rubric.md`. EVERY score carries ONE LINE of
   observable evidence — a named element, a measured contrast ratio, a pixel
   value. A score without evidence is not a score. Show the score table
   every round.
4. **The grade step MUST dispatch to an independent judge. The builder NEVER
   grades its own work — a builder self-grade is FORBIDDEN, not merely
   discouraged.** Dispatch to the judge skill by name: spawn a fresh
   sub-agent running **`frontend-judge`** (see
   `skills/frontend-judge/references/invocation.md` for the exact spawn
   pattern: fresh context, no production history, no shared context with
   the builder; pass only the built page, locked tokens + the 1–3 locked reference screenshots,
   screenshots, the single bit `gate: green`, and brief-type scope — never the builder's
   reasoning or earlier scores). The judge reads the page + locked
   references + screenshots and returns the score table with evidence.
   **Fallback order, first available wins:** (1) fresh judge sub-agent
   (`frontend-judge`); (2) `other-model` judge (a different agent/model
   from the builder, same fresh-context / no-history constraints);
   (3) `muse-manager` judge — Muse grading directly as a DIFFERENT agent
   instance from the builder with no production history of this build
   (valid under the coordinator decision in the repo `AGENTS.md`: the
   user's rule authorises Muse grading; what is forbidden is the SAME
   agent instance/context grading its own work); (4) no grade — the
   round's grade is exactly "gate green, vision not available" and the
   HUMAN gate carries the full taste judgement. Never fake a 4/5.
   Allowed grader labels only: `judge-subagent`, `muse-manager`, or
   `other-model`, plus the independence basis (which must state BOTH fresh
   context AND no production history — "fresh context" alone is NOT
   enough). **Any score without a named independent grader label is
   INVALID.** If no independent judge is available, there is no grade:
   the round's grade is exactly "gate green, vision not available" and the
   HUMAN gate carries the full taste judgement. Never fake a 4/5.
   `taste-reference` is the default taste layer: the orchestrator uses it on
   every build as a lens for the grade (it is a lens, not the judge — the
   independent judge still scores).
   **Specialist second opinion (expert pack):** when the judge's grade is
   uncertain on a domain, or the brief carries a domain risk (motion-heavy,
   copy-heavy, dashboard), the judge or the orchestrator may spawn the
   matching expert from `references/expert-pack.md` /
   `experts/<domain>.md` as a fresh sub-agent — same fresh-context /
   no-production-history spawn pattern as the judge, never before the gate
   is green, max 2 experts per round. The expert verdict is ADVISORY to
   the judge: the judge keeps the final Type/Layout/Colour/Space scores;
   the expert's top defects enter the fix list. An accessibility REWORK
   (1–2) blocks shipping even when the 4 axes are ≥4.
5. Record the round with `scripts/run-log.mjs`: scores per round, grader
   identity + independence basis per round, gate result, gate findings
   (`--gate-findings`), fix class (`--fix-class`), outcome
   (`--outcome kept|discarded|re-pick|stopped|escalated|pending`), and
   the built page (`--page`) — the tokens hash is recorded automatically
   from `design/tokens.css`. The run-log script
   REJECTS any entry whose grader is the builder. The log is the memory
   that stops rejected directions from being re-proposed, and it is the
   only run state the next round's brief is assembled from — record the
   findings and the page every round, or the next brief fails its schema
   check. **No independent
   judge available (no-grade path):** record the round with
   `run-log.mjs record --round N --grader none --scores none --gate <pass|fail>`
   — the grade is recorded as exactly "gate green, vision not available",
   with no invented grader label. `--grader none` with scores is rejected.

## Step 5 — Fix top 2, as token diffs

1. Fix the top 2 findings (top 1 if the evidence is thin). Fixes go to
   `design/tokens.css` first. HTML or layout changes only if the gate still
   fails after the token change.
2. Keep the best-scoring version. A round that scores lower is discarded, not
   iterated on (best-version-kept).
3. Re-run step 3 (gate), then step 4 (grade). That is one round. Each
   fix round starts from a FRESH context: assemble the round brief first
   (`run-log.mjs brief`, see "Round briefs + per-role context budgets"
   above) and send the fixer the brief + the fix instruction — never the
   full run log, never the previous round's context.
4. Every fix instruction cites its source — a gate finding, a grader evidence line, or a human instruction — never "improve it". The fix prompt the orchestrator sends must require the citation field; a fix prompt without it is rejected by the orchestrator (not sent). A fix instruction with no citation is not a fix instruction.
5. **Round folders + archive.** Each fix round is a change folder, not a
   free-form log line: before fixing, copy
   `templates/design/rounds/_template/` to `design/rounds/<n>/` and fill
   in `proposal.md` (bugfix-spec shape: current behaviour / expected
   behaviour / UNCHANGED behaviour — the third line names what must not
   move), `delta.md` (token diffs, ADDED / MODIFIED / REMOVED), and
   `tasks.md` (the top-2 list, each task citing its source). After the
   round, the ARCHIVE step merges the delta into PLAN.md § Amendments,
   into the token dictionary (`scripts/token-dictionary.mjs`), and into
   the run log's notes — NEVER into TASTE.md or `tokens.css` mid-loop.
   The lock is immutable within a direction. A lessons merge into
   TASTE.md happens only once, after the human gate approves the build
   (step 6.4). The re-run gate + `converge-check.mjs` run against the
   round's output before any re-grade: no archive without
   converge-green.

## Step 6 — Stop + human gate

1. **Converge check (before the human gate — BLOCKING).** Before the
   human gate is presented, the build must converge against the plan:
   - Script half: `converge-check.mjs` already ran inside `gate.sh`
     leg 1 at step 3 whenever `design/PLAN.md` exists — a failure
     there blocked the grade. Re-run it directly here against the
     final build (`node scripts/gate/converge-check.mjs --plan
     design/PLAN.md --page <built.html>`) and confirm it is green.
     When Node is unavailable, run the checklist in
     `references/converge-checklist.md` by hand instead and record
     the result in the run log with the degradation labelled.
   - Judge half: the step-4 grade already verified the screen ×
     state matrix — every applicable cell has a frame / story /
     preview AND the state looks right. A missing state is a scored
     Layout defect; a Layout defect that keeps the build under 4 on
     that axis blocks the stop the same way.
   A build that drops a planned section or state is NOT presented as
   done: the human gate does not open, and the round goes back to
   step 5 with the failing section or state named. There is no
   advisory mode. The converge result is recorded in the run log.
2. Stop when every axis is ≥ 4 AND the gate is green — or after 3 rounds,
   whichever comes first. A build that cannot reach ≥ 4 in 3 rounds is a
   direction problem (wrong reference, wrong tokens): re-pick a variant
   (step 2a), not a 4th round. **Re-pick cap: max 2 re-picks, 9 rounds
   total** — 3 rounds in the initial direction + at most 2 re-picks × 3
   rounds each. After the 9th round, stop regardless of scores and present
   the human gate with the best version so far. **Best-version-kept
   survives a re-pick:** the best-scoring version across ALL directions
   stays the version that ships; a re-pick starts a new direction from
   scratch but never discards the previous best — if no later round beats
   it, the earlier best is what the human gate sees. A re-pick creates a
   NEW lock version (step 1.8): the new direction is locked, not merged
   into the old lock.
3. Present the human gate: the score table, the 3-width screenshots, 2–4
   targeted questions with concrete options (pick them from
   `references/human-gate-pack.md` — never an open-ended "what do you
   think?"), and the recommended next command, ending with `polish`. The
   human-eye acceptance bar is **60% slop-free** (user-ordered 2026-11-10;
   the ≥4-on-every-axis stop above is unchanged — the % is the human-eye
   bar for the vague-brief acceptance test, the 4-axis scores are the
   per-round gate). The human's pick or adjective maps through
   the token dictionary (`scripts/token-dictionary.mjs`) and re-enters at
   step 5 — never as a rebuild. The human-gate pack states the converge
   result in one line: "Converge: green — N sections present, M states
   evidenced, K uncheckable (judge's call, step 4)".
4. After human approval: save the 3-width screenshots as the pixel-diff
   baseline so later feedback rounds cannot silently regress it.
   **Post-approval archive (the only TASTE.md merge):** now — and only
   now — merge the rounds' lessons into TASTE.md (what the rounds
   learned about the direction, in one short section). Nothing merges
   into TASTE.md mid-loop, ever.
5. Record in the run log: scores per round, grader label per round, the
   converge result per round, the plan's approval basis (human approval
   in PLAN.md, or the `approved-by` field on the lock entry for
   human-less runs), and every feedback → token change → new score, so
   the dictionary grows.

## Step 6a — Buffet mode (autonomous run + Figma handoff)

Buffet mode is the autonomous form of this loop: the run starts from a brief (+ an optional Figma link), the orchestrator splits the work across the builder, the independent experts in `experts/`, the independent judge, and QC + red team with no human in the loop, and the run ends in "awaiting human" state with the score table + 3-width screenshots prepared. Figma is the handoff surface, via the figma-reference module (planned in the buffet milestone — `references/figma-reference.md`, see `BUFFET-MODE.md`): step 1 pulls Figma in (paths A/B/C — native export, PAT import, MCP where available), step 4 may grade against the cached Figma ground truth, step 7 (after the loop stops, once) exports the shipped state back to Figma as Pages 01 Cover / 02 Design System / 03 Screens — and a human's Figma edits return only by re-pull + regeneration (re-lock `tokens.css`, rebuild, re-gate, re-grade). Figma never enters step 3 (no comparison tool exists), fixes never go to Figma mid-loop, and if Figma is unavailable the loop degrades to the screenshot-references flow and still ships the HTML/CSS artifacts. MCP write-back is beta, remote-only, Full-seat-gated outside drafts, and will become usage-based paid at an unannounced price; `html_to_figma` yields plain layers, not components — see `BUFFET-MODE.md` for the runbook and the full honest-limits list.

## Precedence — see the top of this file

The grader-rule override lives at the TOP of this file ("Precedence —
READ THIS FIRST"), before step 1.4, so an agent following the steps in
order meets the override before the delegation that needs it. It is not
repeated here: one copy, at the top, is the rule.

## Delegation table

| Need | Delegate to | Never do here |
|---|---|---|
| Direction, plan-first, genericness check | `frontend-design` | Invent a direction from priors |
| Slop rules, craft floor, `detect` | Impeccable skill + `scripts/gate/detect.mjs` | Re-list the 62 rules from memory |
| Landing-page checker + finish gate | `taste-reference` (default taste layer, every build) + `scripts/gate/gate.mjs` | Re-implement the checker |
| Component/system lookup | `ui-ux-pro-max-reference`, `threeui`, GSAP skills | Paste a catalog into this file |
| Motion | GSAP skills | Hand-roll animation advice |
| Grading rubric, stop rules, ladder | `references/grader-rubric.md`, `references/stop-rules.md` | Grade by feel |
| Domain expertise (specialist second opinion) | `references/expert-pack.md` + `experts/<domain>.md` (fresh sub-agent, never the builder) | Ask the builder or the judge to cover a domain outside its confidence |
| Variant directions (concrete token briefs) | `references/variant-briefs.md` | Invent five directions from priors |
| Human-gate questions + next commands | `references/human-gate-pack.md` | Ask open-ended "what do you think?" |
| Plan, Design Read, design-system declaration | `templates/design/PLAN.md`, `DESIGN-READ.md`, `DESIGN-SYSTEM.md` (filled in at step 1) | Build on an unapproved plan; put token values in DESIGN-SYSTEM.md |
| Converge check (section/state presence) | `references/converge-checklist.md` + `scripts/gate/converge-check.mjs` | Present a human gate on a red converge; silently pass an uncheckable item |
| Round brief (fresh context per round) | `scripts/run-log.mjs brief` / `scripts/round-brief.mjs` (lock + best HTML + gate findings + evidence lines + run state) | Paste the full run log into a builder/fixer prompt; carry a score from an earlier round |
| Anti-cliché blocklist | `references/anti-cliche.md` + `scripts/gate/anti-cliche.mjs` (AC-1, AC-2) | Promote a checklist item to the gate without a script that checks it |
| Anchored style recipes (one file only) | `references/style-recipes/` (INDEX first, then the one named file) | Load the whole recipe catalog; invent a direction from priors |

## Rules that are never optional

- Tokens are committed before HTML. No exceptions.
- The plan is written and approved before any build (step 1.7). No
  build starts on an unapproved plan.
- The converge check blocks the human gate (step 6.1). A build that
  drops a planned section or state is not presented as done.
- DESIGN-SYSTEM.md holds rationale only — no token values; `tokens.css`
  governs on drift.
- The gate runs before the grade. No vision round on a red gate.
- Every score has one line of observable evidence and a named independent
  grader label. A builder self-grade is FORBIDDEN. A score without a named
  independent grader label is INVALID. If no independent judge exists, the
  grade is "gate green, vision not available" and the human gate carries the
  full taste judgement.
- Max 3 rounds per direction; max 2 re-picks, 9 rounds total.
  Best version is kept across re-picks; worse rounds are discarded.
- Human words become token diffs, never rebuilds.
- A degradation is labelled at every step (see `references/stop-rules.md`).
  The "builder-graded loop" rung is DELETED: there is no accepted loop in
  which the builder grades its own work. A missing capability is reported,
  never silently worked around.
- Precedence: the grader rule overrides any vendored `critique.md` /
  `new-work.md` / degraded-agent text (see "Precedence" above). A
  `⚠️ DEGRADED: single-context` banner is NOT an accepted grade anywhere in
  this kit.
- Never invent a version number, a file, or a behaviour you did not read. If
  a source cannot be read, mark it CHƯA ĐỌC and say so.
