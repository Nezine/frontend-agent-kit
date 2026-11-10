# SOURCE — frontend-design (vendored Anthropic skill)

## What this is

A verbatim vendored copy of Anthropic's `frontend-design` skill
(`SKILL.md`, 71 lines + `LICENSE.txt`, Apache 2.0) from the
`anthropics/skills` repo. It is the direction-setter for step 1 of the
`frontend-kit` loop: plan-first (4–6 named colours, type roles, ASCII
wireframes), then the counterfactual plan check ("worked through a similar
prompt, would you arrive somewhere similar?").

## Provenance (VERIFIED, fetched fresh 2026-11-10)

- Source: https://github.com/anthropics/skills — `skills/frontend-design/`
- Commit: `2c5958ecac7cee2b583967a2c4981d0f4a75c579` ("Move Office skills to
  the Apache 2.0 license (#2146)", 2026-11-06)
- `SKILL.md`: 71 lines, fetched fresh by sparse clone on 2026-11-10.
- Licence: Apache License 2.0 (`LICENSE.txt` in this directory, copied
  verbatim from upstream). Upstream frontmatter says
  `license: Complete terms in LICENSE.txt`.

## Why vendored, not referenced

The direction-setter must work offline on every host, including Hermes and
local text-only models. A reference (link / install command) would fail on
hosts without network access or without the skill installed. The file is 71
lines and zero-dependency, so vendoring costs almost no context and removes
a whole class of install failure.

## Corrections vs phase-1 research

Phase 1 (SYNTHESIS.md §1, §9) reports this SKILL.md as **157 lines**.
The file fetched fresh on 2026-11-10 is **71 lines**. The content matches
phase 1's description (calibration list of AI defaults, plan-first process,
counterfactual check, restraint rule) — only the line count was wrong, or
the upstream file changed since. The 71-line count above is the verified
one; do not re-cite 157.

## Name / directory note (name == dir, resolved 2026-11-10)

Upstream's frontmatter is `name: frontend-design`, and this copy preserves
it verbatim — vendored files are never fork-rewritten. The kit directory is
therefore also `frontend-design`, so frontmatter name == directory name, as
the kit's §3.2 rule (enforced by `verify.sh` §1) requires. The previous directory name
violated that rule and failed verification; it was retired by renaming the
directory, not by editing the vendored `SKILL.md`.

Trade-off, recorded explicitly: this directory now has exactly the same name
as Anthropic's upstream skill. That only matters if the user installs the
official skill alongside the kit — and installing it alongside is redundant,
because the kit already vendors that same skill verbatim. If both are
installed, the two copies would collide by directory/name on hosts that key
on either; in that case the kit copy wins as the pinned one (same content,
pinned to upstream commit `2c5958e`, verified 2026-11-10), and the user
should remove the redundant official install rather than the kit copy.

## Override note — vendored self-critique passage (kit precedence, 2026-11-10)

`SKILL.md:57–59` ("Critique your own work as you build, taking screenshots
to review if your environment supports it…") is upstream Anthropic text,
vendored verbatim — this file is never fork-rewritten, so the passage stays
as written. Inside this kit it is OVERRIDDEN by the orchestrator's grader
rule (`skills/frontend-kit/SKILL.md` Step 4.4 and
`references/grader-rubric.md`): the builder NEVER grades its own work, and
a self-critique must never be presented as a grade. A grade comes only from
an independent judge (`judge-subagent`, `muse-manager`, or `other-model`);
with no independent judge available the grade is exactly "gate green,
vision not available". A `⚠️ DEGRADED: single-context` banner is NOT an
accepted grade anywhere in this kit. Read the passage as "notice problems
while building and fix them", never as permission to score your own work.
