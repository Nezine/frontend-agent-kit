# Variant briefs — the 5 CSS-only variants as concrete token directions

When the brief is vague on direction, the orchestrator generates the 5
CSS-only variants before building further (same content, same copy, same
semantic HTML — only CSS changes; Editorial / Dark / Warm brutalist /
Glassy / Minimal). Each gets its own tokens and its own screenshot at the
same width; the human picks one, and the pick IS the feedback.

This file is the kit's ready-to-use brief for each variant: what it means
as tokens, so the builder does not invent five directions from priors.
These are kit-authored starter directions, derived from the variant names
in the workflow (JP seed, CLAIMED-via-local-summary) and the kit's own
token scales (VERIFIED in-repo in `templates/design/tokens.css`). The
locked reference overrides every starter value below; a variant that
contradicts the locked `tokens.css` is not a variant, it is a different
direction and must be re-picked, not argued.

Folder layout (the picker requires this exact layout):
`design/variants/<name>/tokens.css`,
`design/variants/<name>/screenshot-1440.png` (same width for every
variant), `design/variants/<name>/index.html` (same content, same copy,
same semantic HTML — only the stylesheet link differs).

## 1. Editorial

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

## What a variant is NOT

- Not a redesign: same content, same copy, same semantic HTML — only the
  stylesheet link differs. A variant that changes copy or structure is
  invalid and the picker rejects the layout.
- Not a vote: the human picks one; the pick is feedback, never re-argued
  in prose. Human-less runs use the deterministic pick
  (`variant-picker.mjs pick --auto`): the variant whose tokens match the
  LOCKED `design/tokens.css` most closely.
- Not a grade: a variant screenshot is never scored 1–5. Scores belong to
  built rounds, after the gate is green.
