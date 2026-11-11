---
name: taste-reference
description: Default taste layer for frontend work — use for every landing page, company, product, shop, cafe, hotel, studio, SaaS, AI, developer-tool or game site build, redesign, restyle, polish or review, and for the checker and finish gate that enforce it in a real browser. Plain copy in a voice of its own, one system, one section per screen, equal edges, real photographs, a hero entrance and dealt moments, with deterministic checks (overflow, collide, tap-size, copy-lint) before any vision grade.
---

# Taste — the default taste layer

Taste is the default taste layer of this kit, not an on-request alternative.
The orchestrator (`frontend-kit`) uses it on every visual build; use it
directly whenever the brief is a landing page, company/product site, shop,
cafe, hotel, studio, SaaS, AI, developer-tool or game site — as static
HTML/CSS or inside an existing React, Next.js, Vue, Svelte, Astro or
Tailwind project.

The vendored pipeline is taste-skill 2.5.1 (full tree in
`vendor/taste/`; source revision in `vendor/taste/SOURCE.txt`). Read the
skill itself before building — this wrapper does not duplicate its content:

> **Name mapping — do not be misled:** upstream calls this skill
> `design-taste-frontend` — that is its install name, its `SKILL.md`
> frontmatter `name:`, and the directory name in its hook paths (e.g.
> `.claude/skills/design-taste-frontend/scripts/gate.mjs`). The kit
> installs the same skill under the name `taste-reference`
> (`skills/taste-reference/SKILL.md`). Same skill, two names:
> `design-taste-frontend` is the upstream name you will see in vendored
> paths and hook output; `taste-reference` is the kit name you invoke.
> Do not rename anything upstream.

- Skill: `vendor/taste/skills/taste-skill/SKILL.md` (381 lines)
- References: `vendor/taste/skills/taste-skill/references/` — `system.md`,
  `sections.md`, `layout-v4.md`, `gate.md`, `copy.md` (+ `copy-voice.md`,
  `copy-registers.md`, `copy-moves.md`, `copy-tells.md`), `photos.md`,
  `motion.md`, `moments.md`, `diagrams.md` (27 named diagram presets in
  `assets/diagrams/presets.json`), `perf.md`
- Library: `vendor/taste/skills/taste-skill/library/` — `palettes.json`,
  `type.json`
- Scripts: `vendor/taste/skills/taste-skill/scripts/` — `start.mjs`,
  `consistency.mjs` (checker), `gate.mjs` (finish gate),
  `copy-lint.mjs`, `photos.mjs`, `shoot.mjs`, `perf.mjs`, `icons.mjs`,
  `moments.mjs`, `effects.mjs`

## How to use it in the loop

1. **Deal, don't invent.** `start.mjs deal` deals a palette, type
   pairing, hero and moments for the brief's trade; take the first deal
   and write one sentence on why it fits the trade.
2. **Arm the gate first.** `gate.mjs --start` at the first step (or
   `start.mjs deal`, which arms it too). The gate runs the checker plus
   `assets/layout/check.mjs` at 1440 and 390, holds two checker WARNs
   (`hero-enter`, `moment-none`) as FAILs, lints the copy, and ends on
   exactly one line: `GATE: PASS`, `GATE: FAIL`, `GATE: OPEN` (three
   rounds used up), `GATE: SETUP` or `GATE: ERROR`. A FAIL blocks the
   round; a false FAIL is waived in `.taste-skill/waivers.json` with its
   reason (five at most). Close with `gate.mjs --done "<what was said>"`.
3. **Checker widths are 1440 / 390** (gate also walks 320 for collide,
   tap-size and off-viewport). A page that passes at 1440 but breaks at
   390 has not passed.
4. **Real photographs, not renders.** A product without the client's own
   pictures is shown in licensed stand-in photographs of the same kind
   of thing (`photos.mjs search` — Wikimedia Commons, CC0 / CC BY /
   CC BY-SA / public-domain JPEGs only, no NC or ND); list each stand-in
   in the report. A product render only when the brief asks for 3D.

## Scope

Taste-skill 2.5.1 is built for landing/product sites. Dashboards, data
tables and multi-step product UI are outside its core: use the
orchestrator's spine (Impeccable + tokens + fresh-context grade) there
and take only taste's checker/gate and copy-lint, not its section
library. Never present a taste-skill claim (scores, timings) as measured
by this kit — the author's blind-test numbers are self-reported.

Vendoring scope (D9; see `frontend-kit` SKILL.md Step 2.1b, which
governs): taste governs WHICH runtime code is used — the motion layer
is "not optional" — and frontend-kit governs HOW MUCH is copied: only
the runtime files the page loads, as separate files under `assets/`,
never the whole `assets/` tree and never lab/demo/catalog tooling.
Byte-identical vendored runtime files pass gate 1.2 by path + sha256
against `scripts/gate/vendored-allowlist.txt`; vendored JS is never
inlined into the page.
