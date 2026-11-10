# Recipe: Bloomberg Terminal — trading dashboards

## Sources (read 2026-11-10)

- Anchor + best-for: garden-skills `web-design-engineer` README
  gallery — "bloomberg-terminal: trading dashboards"
  (github.com/conardli/garden-skills, commit 08150e75, MIT).
- School: the same skill's SKILL.md school library — Information
  architecture: "Rational, data-driven, restrained", sample anchors
  "Pentagram, Edward Tufte, Massimo Vignelli, Bloomberg Terminal".
- This file is a KIT-AUTHORED adaptation. The upstream recipe file
  itself is CHƯA ĐỌC; no upstream content is vendored verbatim.
  Concrete values come from the project's own locked reference —
  see "Values" below.

## School

Information architecture. The data is the design: density is a
feature, and every pixel that is not data is overhead.

## Best for

Trading dashboards, dense data screens, monitoring / operations
views, any page where a professional reads numbers all day.

## Visual language

- Dark ground, dense tabular data, tabular numerals aligned on the
  decimal. Rows, not cards: the table is the layout.
- Monospace for figures and tickers; a neutral sans for labels.
  Hierarchy comes from weight and position, not from size jumps.
- Colour is SEMANTIC, not decorative: one colour means up, one
  means down, one means attention. No colour is used "for energy".
- Almost no whitespace as decoration: air exists only where it
  separates two different data groups. Borders are hairlines; panels
  are flat.

## Signature moves

- The ticker strip: a single dense line of symbols and figures,
  always visible, always current.
- State colours applied consistently to every figure of that state —
  the same "up" everywhere, the same "down" everywhere.
- Keyboard-first density: everything reachable, nothing hidden
  behind a hover that a professional cannot afford to wait for.

## Anti-patterns (do not do these in this direction)

- Rounded "friendly" cards, shadows, gradients, or illustration —
  all contradict the direction's premise.
- A marketing hero on a data screen; a large display face where a
  table belongs.
- Colour used decoratively (a rainbow of category colours with no
  meaning) — in this direction an unexplained colour is a defect.
- Fabricated figures: never invent numbers. Real data or an honest
  "real data needed" placeholder.

## Values

Derive them from the locked reference, not from memory — in
particular the state colours and the ground tone, which are the
whole system. Check them against the reference screenshots before
locking, and verify the contrast of every figure colour on the
ground before shipping.
