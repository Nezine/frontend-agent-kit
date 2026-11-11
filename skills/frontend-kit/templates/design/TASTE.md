# TASTE.md — template

<!-- Copy this file into a project as design/TASTE.md and fill it in BEFORE any
HTML is written. One paragraph of intent, then likes / dislikes / hard rules.
TASTE.md wins over the brief when they conflict — say so in the run log if
that ever happens. Delete these comments as you fill the file in.

Gate notes (from the kit's own templates — keep these in mind while locking
taste, so the locked tokens can pass the kit's own gate):
- Default faces in tokens.css are gate-clean (Newsreader / IBM Plex Sans /
  IBM Plex Mono, verified against `impeccable detect` engine 0.1.21 —
  re-verified 2026-11-10 from the 0.1.21 check). If the
  locked reference uses another face, check it against the detector's
  overused-font list first — Inter, Roboto, Fraunces, Geist (any variant),
  Instrument Serif/Sans and the rest of that list fail the gate on sight.
  Display serif is ROMAN only (italic hero trips italic-serif-display).
- Every text element whose size differs from body text needs its OWN
  explicit line-height (see tokens.css LEADING RULE): inherited unitless
  leading measures as 1.24x on 20px text and fails the gate. --leading-lg
  exists for the 20px roles. And never set line-height on a bare element
  selector (p, li) — one class rule per element, or the same 1.24x failure
  appears even when both rules say 1.55.
- Interactive elements need >= 44px height (--tap-min); display type size
  (--text-display) is hero-only, never for a stat or a section number. -->

## Lock summary (5 lines — fill from the round-brief generator's output, never hand-written)

<!-- The same five lines, in the same order, are emitted by
`skills/frontend-kit/scripts/round-brief.mjs` at the top of every round
brief and restated at the end of it. Fill this block from the generator
(`run-log.mjs brief`) at lock time; the lock version and tokens hash
come from the lock entry in the run log. -->

1. Direction: [chosen DESIGN.md + reference screenshots]
2. Tokens: design/tokens.css (sha256 [first 12 of the locked hash]…)
3. Lock version: [1 — immutable within a direction; a re-pick creates a new version]
4. Picked variant: [none yet / name]
5. Stop: >=4 on Type/Layout/Colour/Space + gate green, or after 3 rounds; every axis starts ungraded.

## Intent (one paragraph)

<!-- What is this page for, who is it for, and what should it feel like in one
breath? Example: "A landing page for a small Hanoi coffee roaster selling
subscriptions to offices. It should feel like the roastery itself: warm,
unhurried, a little rough around the edges — never like a SaaS dashboard." -->

[Write the intent here.]

## Likes

<!-- Sites, pages, or details the user loves. Name the site and the specific
thing (not "nice design"). Screenshots go in design/references/, named by
site: linear.png, stripe.png — never screenshot-1.png. -->

- [Site + what exactly you like about it]
- [Site + what exactly you like about it]

## Dislikes

<!-- What to avoid, named concretely. "No generic AI slop" is not concrete;
"no purple-blue gradient hero, no identical rounded cards, no all-caps
eyebrow above every heading" is. -->

- [Concrete dislike]
- [Concrete dislike]

## Hard rules

<!-- 3–6 rules that are never broken, even if the brief asks. Examples from
the JP seed: no gradients ever; left-aligned throughout; type is the design;
one accent used twice; no border/shadow on cards. -->

1. [Hard rule]
2. [Hard rule]
3. [Hard rule]

## Reference direction (filled in at step 1 — taste lock)

<!-- Which DESIGN.md file and which reference sites were chosen, and why, in
one short paragraph. This is the verifiable artifact: tokens.css + these
references are committed BEFORE any HTML is written. -->

- DESIGN.md: [e.g. design/references/DESIGN.md/vercel.md]
- Reference sites: [e.g. linear.png, stripe.png]
- Why: [one short paragraph]
