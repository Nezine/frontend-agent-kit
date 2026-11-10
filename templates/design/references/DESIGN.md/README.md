# DESIGN.md reference library — provenance + how to use it

## What is in this folder

Three vendored DESIGN.md files, fetched fresh 2026-11-10 from
VoltAgent/awesome-design-md (MIT, Copyright (c) 2026 VoltAgent),
commit `fcc70284932276d085f01ef9f83edde90b1258cb` (2026-10-28):

| File | Brand | Lines as vendored* | Character |
|---|---|---|---|
| `vercel.md` | Vercel | 736 | Monochrome + hairline + workflow gradients as the only colour moments |
| `claude.md` | Claude / Anthropic | 589 | Warm cream canvas + coral accent, editorial serif display |
| `linear.md` | Linear | 548 | Dark-first: near-black canvas `#010102`, lavender-blue accent `#5e6ad2` |

\* Line counts are the vendored files WITHOUT the kit label header prepended
at the top of each file. (Correction: phase-1 research reported 1,432 lines
for Vercel and 1,158 for Claude — those counts do not match the files fetched
fresh on 2026-11-10. The fresh counts above are the verified ones.)

Each file carries the kit label header at its top: **third-party analysis,
not official**. The upstream repo describes itself as a "curated collection
of DESIGN.md analysis" — these files are analysts' reconstructions of a
brand's system, not the brand's own spec.

## The known hex conflict (VERIFIED)

- `claude.md` says the primary coral is **`#cc785c`** (frontmatter L7 and
  throughout).
- Anthropic's own `brand-guidelines` skill (anthropics/skills) and the
  live-site values use **`#d97757`**.
- The official `#d97757` wins. Do NOT ship `#cc785c` as "Anthropic's coral".

## How the orchestrator must use these files

1. Copy the FILE SHAPE (frontmatter tokens + prose rationale + components +
   do/don't), not the hex values.
2. VERIFY any copied hex against the brand's live site before shipping.
   A hex that was never checked is CLAIMED, never VERIFIED.
3. Treat the commercial fonts named inside (Copernicus, Tiempos, StyreneB,
   Berkeley Mono) as unshippable references — substitute freely-licensed
   faces that keep the same roles, and say so in the run log. The substitute
   must ALSO be gate-clean: the detector's overused-font list flags Inter,
   Roboto, Fraunces, Geist (any variant), Instrument Serif/Sans, Montserrat,
   Open Sans, Arial, Helvetica, Mona Sans, Plus Jakarta Sans and Space
   Grotesk, so a locked reference that picks one of those as its body/display
   face fails the kit's own gate. The template defaults in
   `templates/design/tokens.css` (Newsreader / IBM Plex Sans / IBM Plex Mono,
   each verified against engine 0.1.21 — re-checked 2026-11-10) are the safe starting point; any
   other substitute needs the same one-line check before the taste lock.
4. More brands live upstream at
   https://github.com/VoltAgent/awesome-design-md (84 DESIGN.md files at
   fetch time). Add more by the same rule: vendor, label, verify hexes.
