# Variant briefs — the 5 structural variants as concrete directions (+ break-frame)

When the brief is vague on direction, the orchestrator generates the 5
structural variants before building further (same content, same copy,
same section inventory — structure may differ; tokens stay locked;
Editorial / Dark / Warm brutalist / Glassy / Minimal, plus one
deliberately divergent break-frame variant, §6). Each gets its own
tokens and its own screenshot at the same width; the human picks one,
and the pick IS the feedback.

**The contract (D2, council decision 2026-11-10): "same content, same
copy, same section inventory — structure may differ; tokens stay
locked".** The old CSS-only contract ("same content, same copy, same
semantic HTML — only CSS changes") is SUPERSEDED. Variants MUST differ
in structure — layout doctrine, section order, hero form — not only in
CSS. A set of five variants that share one structure is one direction
worn five ways, not five directions.

**Why structural (F11, design fixation):** once a first draft exists,
later work orbits it — the first structure's features get reproduced,
flaws included. CSS-only variants share one structure, so the loop
could spend 3 rounds polishing the wrong direction and then restart.
Structural divergence is the only divergence mechanism that prevents
that whole-loop cost. Evidence note: the design-fixation primary (Jansson & Smith, "Design fixation", Design Studies 12(1), 3–11, 1991, doi:10.1016/0142-694X(91)90003-F) was read in full 2026-11-10 (user-supplied copy; verification report `build-notes/w-p10-primary.md`). Definition: "a blind, and sometimes counterproductive, adherence to a limited set of ideas in the design process" (p. 4). Four control-vs-example experiments (n = 25 / 31 / 35 / 13 professionals): total output barely changes while conformity to the example's features jumps sharply (e.g. suction cups 6%→54%, straws 1%→17% despite an explicit no-straws instruction; flexibility 0.95→0.85, originality 0.64→0.53), including in professionals. The paper demonstrates fixation; it does not test structural-variant generation as a remedy — the variant mechanism remains a design decision inferred from these findings. No significance tests are reported in the paper (descriptive means/percentages only).

This file is the kit's ready-to-use brief for each variant: what it
means as tokens AND as structure, so the builder does not invent five
directions from priors. These are kit-authored starter directions,
derived from the variant names in the workflow (JP seed,
CLAIMED-via-local-summary) and the kit's own token scales (VERIFIED
in-repo in `templates/design/tokens.css`). The locked reference
overrides every starter value below; a variant that contradicts the
locked `tokens.css` is not a variant, it is a different direction and
must be re-picked, not argued.

Folder layout (the picker requires this exact layout):
`design/variants/<name>/tokens.css`,
`design/variants/<name>/screenshot-1440.png` (same width for every
variant), `design/variants/<name>/index.html` (same content, same copy,
same section inventory — structure may differ).

## 1. Editorial

- **Structure:** Container doctrine — one centred column, sections in
  brief order (hero → features → pricing → footer). Hero form: stacked
  — display headline over a full-width visual, copy below, one CTA.
- **Type:** Display serif roman (kit starter: Newsreader) at the top of
  the scale; body serif or quiet sans; tight display tracking (−0.03em);
  generous measure, calm line length (~68ch).
- **Colour:** Paper ground (`#ffffff` / `#f6f6f4`), near-black ink
  (`#0a0f1e`), one restrained accent used twice per screen at most.
- **Space:** Large section gaps (upper end of 128–288px), airy card
  padding; hairline rules instead of borders or shadows.
- **Radius / motion:** Small radii (2/6px); still, quiet motion
  (120/220ms, no parallax, no reveal beyond a single fade).
- **Feels like:** A printed magazine page. Pick it when the brief's content
  is the argument (long-form, report, portfolio of writing).

## 2. Dark

- **Structure:** Split doctrine — hero as a two-column split (copy left,
  visual right); sections in brief order, but features as a dense
  two-column grid instead of Editorial's single column. Hero form:
  split, visual-led on the right.
- **Type:** Same scale as the locked tokens; display face kept, weights
  one step lighter than the light variants (dark grounds make heavy type
  shout).
- **Colour:** Inverted roles — dark bg, light ink; muted text re-measured
  (the 7:1 body rule still applies, against the dark ground); accent kept
  single and slightly brightened so it survives the inversion.
- **Space:** Same gaps as the locked tokens; panels as flat dark surfaces
  with hairline borders, never glow.
- **Radius / motion:** Same radii as the locked tokens; motion unchanged.
- **Feels like:** A developer tool at night. Pick it when the audience
  lives in dark UIs (developers, dashboards, evening reading).

## 3. Warm brutalist

- **Structure:** Stacked-blocks doctrine — every section a full-bleed
  bordered block, no container inset; section order reordered so the
  offer lands first (hero → pricing → features → footer: the price is
  the argument, the features are the proof). Hero form: poster — huge
  display type, no visual, CTA as a solid bordered block.
- **Type:** Heavy display weight, large display sizes, tight leading;
  mono labels in all-caps where the locked voice allows them.
- **Colour:** Warm ground (cream/paper-warm), ink near-black, one loud
  warm accent (ochre/rust) used sparingly — loud does not mean everywhere.
- **Space:** Tighter section gaps (lower end of 128–288px), dense cards,
  visible borders (1–2px solid ink), no shadows, no rounding beyond 2px.
- **Radius / motion:** Radius 2px throughout; motion minimal and blunt
  (120ms, no easing theatre).
- **Feels like:** A poster on a wall. Pick it when the brief wants
  attitude and the content is short and punchy — never for long-form
  reading.

## 4. Glassy

- **Structure:** Asymmetric doctrine — hero offset to one side with a
  large translucent panel overlapping the visual; section order
  reordered so social proof / features lead (hero → features → pricing
  → footer stays, but features open with the visual first, copy second
  — the reverse of Editorial). Hero form: overlapping panel — copy
  floats over the visual instead of sitting above or beside it.
- **Type:** Light display weight, airy tracking; body sans with generous
  leading.
- **Colour:** Light ground with one cool accent; panels as translucent
  surfaces over a flat ground (no gradient grounds — flat colour only,
  per the taste rules; translucency is a panel treatment, never a
  background).
- **Space:** Large gaps, large radii (12/20px), soft hairlines, generous
  card padding.
- **Radius / motion:** Radii at the top of the scale; motion smooth and
  slow (220/420ms), one reveal per section at most.
- **Feels like:** A calm consumer product. Pick it when the brief is a
  consumer app or a service that should feel effortless — never when the
  content needs density.

## 5. Minimal

- **Structure:** Single-column manifesto doctrine — one narrow column,
  sections separated by whitespace alone (no cards, no rules, no
  panels); section order reordered so the single action closes the page
  (hero → features → pricing → footer, but pricing is one line and the
  footer carries the CTA — the page is one decision, stated last).
  Hero form: type-only — headline + one line + one CTA, no visual at all.
- **Type:** One family only (display + body from the same family, weight
  doing the hierarchy work); smallest scale that still reads; no display
  face for decoration.
- **Colour:** Two colours total (ink + one accent) on a flat ground; muted
  text is ink at reduced opacity only where contrast still passes 7:1.
- **Space:** The most air of the five; one visual beat per page at most
  (or zero — the page must also work with zero).
- **Radius / motion:** Radius 2/6px; motion 120ms or none.
- **Feels like:** A blank page with one decision on it. Pick it when the
  brief's one action matters more than the page (signup, waitlist, single
  offer).

## 6. Break-frame (deliberately divergent)

One variant in every set must deliberately break the frame the other
five share. Its job is to make the pick a real choice: if the
break-frame looks wrong, the five canonical directions are confirmed;
if it looks right, the brief's real direction was outside the frame.

- **Structure:** No hero at all — the page opens directly on the
  content (features first, then pricing, then a closing statement that
  does the hero's job last; footer last). Doctrine: content-first,
  inverted order (features → pricing → hero-as-closing → footer).
  Copy is unchanged — the same words, in a different order and shape.
  Hero form: none — there is no hero section treatment; the closing
  statement section carries the headline copy.
- **Tokens:** Same locked tokens as the other variants (tokens stay
  locked — divergence is structural, never a token escape).
- **Rule:** The break-frame variant is REQUIRED in every vague-brief
  set (5 canonical + 1 break-frame = 6 variants). `variant-picker.mjs
  check` reports its presence; a set without it is incomplete per this
  brief even though the picker does not fail on it. Do not soften it
  into a sixth canonical direction: if it looks like the other five,
  it is not a break-frame — rebuild it further from the frame.
- **Feels like:** The page the brief would be if the obvious shape were
  wrong. Pick it when the brief's content reads better without a hero.

## What a variant is NOT

- Not a redesign: same content, same copy, same section inventory —
  structure may differ. A variant that changes copy or drops a section
  is invalid and the picker rejects it (`variant-picker.mjs check`:
  inventory + copy). A variant that merely re-skins the same structure
  is a duplicate, not a variant — the brief requires structural
  divergence (doctrine, order, hero form), and the scoring procedure
  (`variant-scoring.md`) is what catches a set that never diverged.
- Not a vote: the human picks one; the pick is feedback, never re-argued
  in prose. Human-less runs use the deterministic pick
  (`variant-picker.mjs pick --auto`): the variant whose tokens match the
  LOCKED `design/tokens.css` most closely; ties break by the plan's
  preferred structure (`design/PLAN.md`, `Preferred structure:` line),
  else alphabetically.
- Not a grade: a variant screenshot is never scored 1–5. Scores belong to
  built rounds, after the gate is green. Variant selection is a blind
  comparative pick, not a grade — see `variant-scoring.md`.
