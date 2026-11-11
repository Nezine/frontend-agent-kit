# DESIGN-READ.md — template

<!-- Copy this file into a project as design/DESIGN-READ.md and fill it in
at the end of step 1, BEFORE tokens are locked. The Design Read is a
one-block summary of the brief that makes the direction DISCUSSABLE
("variance High, motion Low") before anything is built — cheaper than
six variants and earlier than the v0 checkpoint. It is adapted from
garden-skills `web-design-engineer` (SKILL.md Step 2b, read in full
2026-11-10, commit 08150e75, MIT): the five dials are the same five
(variance / motion / density / asset / fidelity), but the scale is
categorical — Low / Med / High with a one-line anchor each — not
garden-skills' 1–10 numbers. Uncalibrated 1–10 self-scores would
manufacture false direction confidence the same way uncalibrated
grades manufacture false "ship it" verdicts; a named position with an
anchor does not pretend to be a measurement.

DIALS ARE INTENT, NOT SCORES. Nothing in the loop reads them as a
grade; the judge NEVER receives them. They must affect real decisions
— layout variation, motion, content per viewport, real-asset effort,
preservation strictness — or they are decorative labels; the
pre-delivery checklist (garden-skills Step 6, same source) asks
exactly that. Delete these comments as you fill the file in. -->

## Design Read

- Artifact: [landing / dashboard / prototype / slides / visualization]
- Audience: [primary audience, in one line]
- Visual language: [specific family, not "modern / clean" — e.g.
  "dark developer-tool canvas, single lavender accent" or "warm
  apothecary editorial, parchment ground"]
- Mode: [greenfield / extension / preserve / overhaul — classify
  before touching an existing product]
- Anchor / recipe (if any): [e.g. "aesop" →
  skills/frontend-kit/references/style-recipes/aesop.md, or "custom",
  or "none". Load only the ONE recipe file you use, never the catalog.]
- High-end bar: [one line — how this build aims at the refined,
  high-end 8/10 feel: motion + 3D as plus points, neither bland nor
  gaudy; e.g. "one hero moment, restrained palette, Pattern 2". See
  skills/frontend-kit/references/workflow.md §1.]
- GetLayers layer (if any): [name + URL of the free layer used as a
  reference direction, or "none". See
  skills/frontend-kit/references/getlayers.md.]
- Effect source (if any): [e.g. "GetLayers Text Animations — free
  in-browser tool", or "useAnimations arrow-right — MIT, Lottie JSON
  inlined via lottie-web 5.13.0", or "LottieFiles <icon name> —
  Lottie Simple License, Lottie JSON via dotLottie-wc / DotLottie JS
  API", or "Lordicon <icon name> — free licence based on CC BY-ND
  4.0 (modified), @lordicon/element, self-hosted JSON", or "none".
  Format: `Effect source: <source> <icon name> — <licence>,
  <player/route>`.]
- Animated icon (if any): [e.g. "useAnimations arrow-right
  (https://useanimations.com/icons/arrow-right) — hover-replay, one
  unit of the page's dealt-moment budget", or "none". See
  skills/frontend-kit/references/animated-icons.md.]
- Attribution (if any): [exact link + where it is placed, or "none" —
  e.g. Lordicon: `<a href="https://lordicon.com/">Animated icons by
  Lordicon.com</a>` in the footer; useAnimations / LottieFiles:
  "none" (attribution not required, though appreciated/encouraged).]

## The five dials

<!-- Pick one position per dial and keep its anchor line. The anchor
names a reference so the position means something concrete. If the
brief gives no signal for a dial, say so and pick Med — never invent
a confident position from nothing. -->

| Dial | Position | Anchor (what this position means here) |
| --- | --- | --- |
| Visual variance | [Low / Med / High] | Low: one idea per screen, generous whitespace (Aesop). Med: one strong hero idea, restrained sections. High: dense multi-panel, layered, convention-breaking (Bloomberg Terminal). |
| Motion intensity | [Low / Med / High] | Low: still; opacity-only transitions (Aesop). Med: restrained reveals, one easing family. High: choreographed entrances, scrubbed timelines (Active Theory). |
| Information density | [Low / Med / High] | Low: one idea per screen, long measure (MUJI). Med: standard landing rhythm. High: dense data tables, tabular numerals (Bloomberg Terminal). |
| Asset dependence | [Low / Med / High] | Low: type and layout carry it; honest placeholders (Tufte). Med: some real imagery, mocks where the brief has none. High: real product photography required — no CSS silhouettes, no drawn stand-ins. |
| Brand fidelity | [Low / Med / High] | Low: direction inspired, values free. Med: the brand's palette and faces, adapted to the lock. High: preserve the brand's exact system; extension mode, nothing re-invented. |

## What the dials decide

<!-- One line per dial that actually moved a decision. If a dial moved
nothing, delete its line — a dial that decides nothing is decoration. -->

- Variance → [e.g. "High: hero breaks the grid; sections stay on it"]
- Motion → [e.g. "Low: no entrance choreography; 220ms opacity only"]
- Density → [e.g. "Med: three features per row at 1440, one at 390"]
- Asset dependence → [e.g. "High: hero needs the real product shot;
  build stops without it — no silhouette substitute"]
- Brand fidelity → [e.g. "High: the brand's accent stays decorative
  only; functional text uses the darkened accent"]
