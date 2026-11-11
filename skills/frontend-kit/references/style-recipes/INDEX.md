# Style recipes — anchored direction index

Progressively loaded: read the INDEX first, then read ONLY the one
recipe file the brief's anchor names. Never load the whole catalog —
the catalog exists so the agent does not invent a direction on the
fly, not so it can read seven directions at once. (Garden-skills
`web-design-engineer`, SKILL.md "References Routing", read in full
2026-11-10, commit 08150e75, MIT: "Load only the one recipe file
you're using, not the whole catalog.")

## What this index adds that the expert pack does not

The expert pack (`references/expert-pack.md`, 12 domain briefs) JUDGES:
typography, colour, layout, motion, accessibility, copy, imagery,
design systems, performance, responsive, UX, security. A judge needs a direction to
judge against; it does not supply one. These recipes SUPPLY named
directions: an anchor (a real design language with a known character),
a school, a best-for, signature moves, and anti-patterns — so step 1
can lock a direction by name instead of by vague adjective. No recipe
duplicates an expert brief: the experts carry criteria, the recipes
carry direction. If a recipe ever duplicates an expert brief, the
recipe is dropped.

## What the vendored DESIGN.md files already cover

The kit already vendors third-party analyses of three directions
(`templates/design/references/DESIGN.md/`): Linear (dark developer
tool), Vercel (developer platform), Claude (warm editorial AI).
Those three anchors are NOT repeated here — a recipe is written only
for an anchor the kit has no direction source for. Anchors in the
garden-skills catalog (25 recipes) that are NOT yet adapted here:
Linear, Vercel, Claude (vendored DESIGN.md covers them), Pentagram,
Y2K retrofuturism, Bloomberg Businessweek covers, Active Theory,
Vercel mesh, and the rest of the 25. Add one only when a brief names
it and no existing source covers it.

## Provenance (read before citing a recipe)

Every recipe in this folder is a KIT-AUTHORED adaptation: the anchor
name and best-for come from the garden-skills README catalog
(github.com/conardli/garden-skills, README read 2026-11-10, commit
08150e75), and the school comes from the same skill's SKILL.md school
library (read in full 2026-11-10). NO garden-skills recipe file was
read — the recipe files themselves (`references/style-recipes/*.md`
upstream) are CHƯA ĐỌC — and NO garden-skills content is vendored
verbatim here (see SOURCES.md). Each recipe therefore gives direction
in qualitative terms (school, character, signature moves,
anti-patterns) and a method for deriving concrete values from the
project's own locked reference. It does NOT give the anchor's real
hex values, font files, or spacing numbers: any value presented as
"the anchor's real token" without checking the live site would be
fabricated. Concrete values come from `design/tokens.css` after the
taste lock — the recipe tells the lock what to look for, it does not
replace the lock.

## The recipes

| File | Anchor | School | Best for |
| --- | --- | --- | --- |
| `aesop.md` | Aesop | Editorial / minimalist | Apothecary pages, quiet premium commerce |
| `muji-kenya-hara.md` | MUJI / Kenya Hara | Editorial / minimalist | Object catalogues, quiet product pages |
| `monocle-magazine.md` | Monocle magazine | Editorial / minimalist | Magazine contents, editorial indexes |
| `stripe-press.md` | Stripe Press | Warm humanist | Book detail, long-form reading pages |
| `bloomberg-terminal.md` | Bloomberg Terminal | Information architecture | Trading dashboards, dense data screens |
| `tufte-dataink.md` | Edward Tufte / data-ink | Information architecture | Data narratives, charts that let data speak |
| `mid-century-modern.md` | Mid-century modern | Editorial poster / graphic | Poster homages, bold graphic landings |
| `scroll-motion.md` | Scroll motion (Anthropic / Apple / SpaceX + award sites) | Restraint / motion | **Cross-cutting, not an anchor:** the motion direction for any brief — read alongside the anchor recipe, never instead of it |

## The motion recipe is not an anchor

`scroll-motion.md` supplies no visual direction (no palette, no faces,
no layout) and therefore has no "best for" in the anchor sense. It
supplies the motion system — 8 named scroll patterns with measured
technique, motion tokens, and hard restraint rules — that any anchor
recipe can pair with. Step 1 reads at most one anchor recipe AND the
motion recipe; the brief names the motion patterns by number
(e.g. "Pattern 2 + Pattern 5"). A build with no pattern named has no
motion beyond the fixed header and hover states.

## How to use a recipe (step 1)

1. The brief names an anchor (or the Design Read points at one):
   read that ONE file.
2. Paste its direction into the Design Read (DESIGN-READ.md) and the
   design-system declaration (DESIGN-SYSTEM.md) — character and
   signature moves, not values.
3. Derive the concrete values from the locked reference (the vendored
   DESIGN.md or the reference screenshots) into `tokens.css`. The
   recipe's anti-patterns are the check on that derivation: if the
   locked tokens reproduce an anti-pattern, the lock is wrong, not
   the recipe.
