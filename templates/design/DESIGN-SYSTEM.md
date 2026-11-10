# DESIGN-SYSTEM.md — template

<!-- Copy this file into a project as design/DESIGN-SYSTEM.md and fill it
in at step 1, AFTER tokens.css is written and BEFORE the build. This
file is the human-readable companion to tokens.css, adapted from
garden-skills `web-design-engineer` (SKILL.md Step 3, "Declare the
Design System Before Writing Code", read in full 2026-11-10, commit
08150e75, MIT).

HARD RULE — RATIONALE ONLY, ZERO TOKEN VALUES. This file records WHY
the system is what it is: which reference each token family comes
from, the do/don't rules, the rationale. It must not contain a single
token value — no hex codes, no pixel sizes, no font names with sizes,
no custom property definitions. tokens.css is the single source of
truth for every value. If this file disagrees with tokens.css,
tokens.css governs and this file is stale. Fix rounds touch tokens.css
only; this file is never hand-maintained after the lock — it is
re-read, not re-written.

Check (run by the reviewer in the QC pass, and listed in
skills/frontend-kit/references/converge-checklist.md):
  grep -E '^\s*--[a-zA-Z]' design/DESIGN-SYSTEM.md
must print nothing. A match is a violation of this file's own rule.
Delete these comments as you fill the file in. -->

## Reference mapping

<!-- Which DESIGN.md file / reference site each token family comes from.
Name the source, not the value. -->

- Type roles: [e.g. "display serif from the locked reference's
  editorial voice; body sans from its UI text"]
- Colour roles: [e.g. "canvas and ink from the reference's light
  ground; accent from its single brand colour"]
- Space and radius: [e.g. "section rhythm from the reference's
  vertical spacing; card radius from its panel language"]
- Motion: [e.g. "durations from the reference's reveal behaviour"]

## Do / don't rules

<!-- The rules the build must not break, stated without values. -->

- Do: [e.g. "one accent, used twice per screen at most"]
- Do: [e.g. "type is the design — no decorative gradient ever"]
- Don't: [e.g. "no second button recipe for a 'special' block"]
- Don't: [e.g. "no colour outside the token file, ever"]

## Rationale

<!-- Why this system, in two or three sentences: what the brief asked
for, what the reference gave, what was deliberately left out. If a
later round wants to change direction, it argues against this section
— it does not silently edit the values. -->

[Write the rationale here.]

## Drift rule

<!-- Do not edit this section. It is the rule, not a fill-in. -->

If a fix round changes a value, it changes tokens.css and records the
change in design/rounds/<n>/delta.md and in PLAN.md § Amendments. It
does not edit this file to match. If this file and tokens.css disagree,
tokens.css governs; this file is stale until the next re-lock, when a
new lock version re-quotes the mapping above.
