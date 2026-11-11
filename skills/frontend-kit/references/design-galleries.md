# Design galleries — Grainient, Freefaces, Supahero

Shortlist source: Sergey Lyubavsky's reel "Amazing Websites You Should
Know as a Designer" (facebook.com/reel/1666470368366970). The reel named
the three sites; every fact below rests on a live read of the site itself
(primary) or a named secondary source — never on the reel's voiceover.
Verified 2026-11-11. Evidence labels, as in `workflow.md`: **VERIFIED** =
a primary source was read (URL + date); **CLAIMED** = a secondary source
says so, not independently checked; **CHƯA ĐỌC** = not read, never
presented as read.

These are optional step-1 reference sources for the taste lock (SKILL.md
step 1.1), same standing as GetLayers (`references/getlayers.md`) and
animated icons (`references/animated-icons.md`): conditional only ("when
one fits the brief"), never mandatory, never a substitute for the locked
tokens, never the build's source, never a grading input.

Three galleries, three jobs: Grainient = the background (depth /
atmosphere), Supahero = the first screen's structure, Freefaces = the
type. One independent roundup covers all three (Surf Skills, 2026-06-27)
and is cited as a secondary throughout (§8, source 5).

## 1. Grainient.supply — gradients & backgrounds

### 1.1 What it is

VERIFIED (homepage, grainient.supply, 2026-11-11): "Grainient combines
Grainy and smooth Gradients, Animated Gradients, AI backgrounds, and a
shader tool to help you design interfaces that move, engage, and
convert." The site calls itself "The Internet's #1 Gradient &
Background Hub" — its own tagline, not an independent ranking. Animated
backgrounds are "2K-4K animated gradients (30–60 fps)". "Drop new
collections every week." The site claims "More than 70,000 of creative
people loved Grainient's customized Gradients ... every month" — a site
claim, self-reported, not independently verified.

### 1.2 Counts

CLAIMED (multiple secondaries): "over a thousand" / "1000+" gradients
and backgrounds (Surf Skills 2026-06-27; creati.ai, updated 2026-06-16;
aipure.ai). No count is stated on the primary homepage. The reel's
collection counts — "Hero Gradients V2 — 32" and "Shadeshifter — 28" —
are UNVERIFIED: the collection NAMES appear in the reel (post summary,
read 2026-11-11) but no source states the counts. Do not cite them.

### 1.3 Free vs paid

Paid. VERIFIED (pricing page, grainient.supply/pricing, 2026-11-11):
"Since subscription plans can be unreliable, we offer only lifetime
deals, ideal for Freelancers, Solo designers and small teams."
CONFLICT: the homepage says "Access premium gradients and design tools
with flexible yearly plans or a one-time lifetime purchase" — yearly
plans are named on the homepage and denied on the pricing page. Treat
the pricing page as the current offer and the homepage line as stale;
do not resolve the conflict by guessing.

Prices: CHƯA ĐỌC on primary — the pricing page's prices are
JavaScript-rendered and did not appear in the text read. Two
secondaries disagree: creati.ai (updated 2026-06-16) lists Go Unlimited
$69 lifetime and Premium $159, "Has free plan: No"; Surf Skills
(2026-06-27) says Pro is "around $59/year or $299 lifetime". Do not
quote any dollar price from this file — check the pricing page at build
time.

Free tier: CLAIMED by one secondary only — Surf Skills says "there's a
free Freebies section to grab a few without paying". Not confirmed on
the primary site (no Freebies link appeared in the homepage or
pricing-page reads). Treat as unconfirmed; never promise a free tier.
Note: the reel presents all three sites as free; for Grainient that
does not match the pricing page — paid, lifetime deals, free tier
unconfirmed.

### 1.4 Licence

VERIFIED (homepage, 2026-11-11): "One license, endless use. Create
freely with Boundless commercial access for personal and client work."
And: "fully licensed for your projects." The licence NAME "Boundless
License" is CLAIMED (aipure.ai). No attribution requirement
is stated anywhere read. Full licence / terms text: CHƯA ĐỌC — no terms
page was found or read. The kit's use (§1.5) stays inside the
homepage's own wording: reference and recreation, never redistribution
of the files.

### 1.5 How the agent uses it

Reference-only. The agent browses the library, picks ONE gradient whose
depth / atmosphere fits the brief, and recreates its feel as CSS tokens
(colour stops, grain via SVG turbulence, mesh via layered radial
gradients) — it never copies or downloads a Grainient file into the
build, and never ships a Grainient image as a page background. The
loop's use needs no purchase and no download (the agent recreates the
gradient as CSS tokens). No paywall was observed on the homepage read;
whether the full library browses without an account was not tested —
if the library demands an account, the agent uses the homepage-visible
gradients only and says so. A human who owns a Grainient licence may
substitute a downloaded file, but that is their call, outside the loop.

A still gradient is a background token, not a moment (§4): placement
is hero only, never on every section. An animated gradient is the
motion moment (§4): one budget unit, obeys restraint rules 1–2, and
replaces (never adds to) a scroll-motion moment. Neither satisfies the
gate's dealt-moment requirement (§4 gate caveat): the page still needs
a mounted moments.js moment to clear moment-none. The real-time shader tool exists
(homepage, VERIFIED) but its output format is CHƯA ĐỌC — do not claim
the agent can export shader code from it. No API, MCP, or llms.txt was
observed. Download formats for members: CHƯA ĐỌC.

### 1.6 Worked example

`Gradient source: Grainient — dark violet mesh, heavy grain — recreated as CSS tokens, hero background only`

For an animated gradient, the Effect source line instead:

`Effect source: Grainient dark violet mesh, heavy grain (animated) — recreated as CSS tokens, no file copied`

Record the gradient's name / URL when the library page gives one; if
the page gives no name, describe it ("dark violet mesh, heavy grain")
and record the library URL.

## 2. Freefaces.gallery — free typefaces

### 2.1 What it is

VERIFIED (homepage, www.freefaces.gallery, 2026-11-11): "Free typefaces
and fonts." A curated gallery of free typefaces, organised into six
categories — Cursive, Display, Monospace, Sans Serif, Serif, Slab
(category list CLAIMED via Surf Skills 2026-06-27; the category labels
appear on the font pages themselves, VERIFIED). Curator: Simon Foster
(CLAIMED, Surf Skills). Four faces on page 1 of the homepage's
"Latest typefaces" list include, VERIFIED: Façade (Display), Oi
(Display), Getai Grotesk (Display), Memoir (Display, Serif). (Page 1
lists 12 faces; the four named are among them.) Familiar
workhorses on the same list: Space Grotesk (Sans Serif), Martian Mono
(Monospace), Commit Mono, Hyperlegible (Sans Serif).

### 2.2 Counts

Counted live on the category pages, 2026-11-11: Cursive 10 (Comico,
Skyscapers, Shadow Hand, Relieve, Kaushan Script, Grandstander, Gluten,
Finesse, Bispo, Alex Brush); Monospace 11 (Commit Mono, Martian Mono,
Departure Mono, PT Mono, Miso, Major Mono, Jet Brains, Inconsolata, Fira
Mono, Droid Sans Mono, Anonymous Pro). Total across all six categories:
CHƯA ĐỌC — no total is stated on the homepage and the remaining four
categories were not counted. The "Latest typefaces" list is paginated
(1/8 pages × 12 per page, observed) — that is the latest list, not a
total; do not cite 96 as the total.

### 2.3 Free

All free. VERIFIED on two detail pages (2026-11-11): Comico and Space
Grotesk both show Price 0 USD. No account, no purchase, no paywall
observed.

### 2.4 Licence — per font, read the font's own page

Each font's page states its own licence — there is no site-wide
licence. VERIFIED examples (2026-11-11): Comico — ITF Free Font
License, 1 style; Space Grotesk — SIL Open Font License 1.1, 5 styles +
Variable. Rule: before locking any Freefaces face, read the Licence line
on that font's page and record it in the Design Read; a face whose
licence you have not read is not locked. OFL-licensed faces (Space
Grotesk and others under OFL) may be embedded once downloaded from
their source: the OFL explicitly permits embedding, provided each copy
contains the copyright notice and the licence (OFL 1.1 §2, verified
2026-11-11) — the loop meets this by inlining the licence text as a
CSS comment alongside the inlined font (§2.5). Other licences (ITF and
the rest) must be checked per font before any embedding — if the
licence does not permit embedding / redistribution, the face stays
reference-only; do not assume OFL terms apply to them.

Gate warning: Space Grotesk is on the gate's overused-font list for
PRIMARY use (AGENTS.md decision (e) — it flags alongside Inter, Roboto,
Montserrat, Open Sans). Do not lock it, or any Freefaces face that the
gate flags, as the primary / body face. The safe slot for a Freefaces
face is the display slot (hero H1, wordmark). This is an inference,
not a verified gate behaviour: AGENTS.md decision (e) establishes only
that Space Grotesk et al. flag as PRIMARY fonts — no gate run has yet
shown a display-slot use passing (see §7). The template's clean
primary faces are Newsreader / IBM Plex Sans / IBM Plex Mono (AGENTS.md
decision (e)).

### 2.5 How the agent uses it

Pick at most two faces per build: one display face for the H1 / wordmark
(the personality) and, only if the brief needs it, one workhorse sans
for body / UI. Record name + licence + URL in the Design Read.
Delivery — one mechanism only: the agent downloads the font file from
the source linked on the font's page at build time and base64-inlines
it into the single HTML file's @font-face — inline only the weights
the build actually uses (a display face: typically one) — with the
licence text as a CSS comment alongside it. The download is transient
(build-time only): no loose font file is ever shipped beside the HTML,
and no font file is ever vendored into the repo. OFL faces may be
inlined this way (embedding permitted, licence text included — §2.4);
any other licence only after reading it and confirming embedding is
permitted, otherwise the face stays reference-only. Download-button /
source-link detail on the font pages: CHƯA ĐỌC in the text reads (no
download control text appeared); the instruction is "open the font's
page, read its licence, follow its source link" — if the page gives no
source link, say so and stop, do not guess one. The agent never invents
a download URL.

A display face is a token choice, not an effect: it does NOT consume
the dealt-moment budget (§4). But a loud display face + a gradient
background + motion together can still read gaudy — the judge's Type
and Colour axes are the check, not the budget.

### 2.6 Worked example

`Display typeface: Freefaces Getai Grotesk (Display) — licence per its font page, read before locking`

`Body typeface: IBM Plex Sans (template default, gate-clean) — no Freefaces body face locked`

## 3. Supahero.io — hero-section library

### 3.1 What it is

VERIFIED (homepage, supahero.io, 2026-11-11): "Website hero section
library" — a single scrolling page of real websites' hero sections
(screenshot + link to the live site each). Counted live: 573 entries
(indices 0–572). Includes Better Stack, Lando Norris, Linear, Stripe,
Raycast, Attio, Resend, and Grainient itself. CLAIMED (Surf Skills
2026-06-27) "1,000+ real examples" — WRONG on the live count; the live
count (573) governs. Design Atlas (reviewed 2026-09-25) says "About
570", consistent with the live count. Each hero has a detail page with
the site's tagline and the date added (VERIFIED on the sampled Lando
Norris detail page, 2026-11-11; "each hero" per Atlas — "A detail page
per hero with the site's tagline, the date it was added"; e.g.
supahero.io/hero/lando-norris). No filters or tags — browsing is a long
scroll or a name search (CLAIMED, Atlas). No MCP, llms.txt, API, or
export (CLAIMED, Atlas). Sampled entries dated October 2024–December
2025 (CLAIMED, Atlas) — newer trends may be missing.

### 3.2 Free

Free to browse. VERIFIED: no paywall observed on the homepage read
(2026-11-11). CLAIMED: Product Hunt lists price 0 USD; Surf Skills
"free to browse". Paid placements exist for featured listings ($79–$279
per 30 days, CLAIMED, Atlas) — that is the site's revenue, not a cost to
the browser.

### 3.3 Licence — none stated: look, don't copy

No reuse licence is stated anywhere (CLAIMED, Atlas: "No reuse licence
is stated"; Atlas also notes an "all rights reserved" footer; no terms
/ about page was found on the primary site). The
heroes are screenshots of third-party sites' work. Rule: study the
structure — layout, copy placement, imagery, CTA hierarchy — and build
ORIGINAL work in that structure. Never lift a hero's screenshot, copy,
or assets into the shipped BUILD. A reference screenshot in the
project's design/references/ folder is excepted (§3.5) — it is a
reference, never shipped. Never present a Supahero entry as the build's
source. A Supahero reference is a structure reference, never a dealt
moment (§4), and never a grading input.

### 3.4 ScreensDesign

VERIFIED on the site itself: the Lando Norris detail page
(supahero.io/hero/lando-norris) states "supahero is now part of
screensdesign 🎉 the biggest UX app library in the world." Atlas
(2026-09-25) confirms a banner on every page promoting ScreensDesign.
The ScreensDesign library itself is out of scope for this file — no
claim is made about it.

### 3.5 How the agent uses it

Before designing a landing page's hero, scroll the library and pick 1–2
heroes whose STRUCTURE fits the brief (not whose copy or visuals —
those stay behind). For each borrowed hero: (1) capture its screenshot
with Playwright (first-viewport screenshot of the live site, linked
from the Supahero entry) into the project's design/references/ as
supahero-<site>.png — this occupies one of the 1–3 locked reference
slots, so the source hero is judge-visible through the locked reference
shots (grader-rubric.md: allowed judge inputs); (2) record the hero
name + URL in the Design Read, with a structural-difference note — one
line on what structure is borrowed AND one line on what the build
changes (copy, arrangement, visual). If the brief is not a landing
page, skip Supahero entirely. Never browse it to copy a hero; never
cite a hero count other than the live 573. Residual, stated plainly:
the judge grades fidelity to the locked references, not originality —
it sees the source hero but has no rubric line to fail clones. The
originality check is the HUMAN gate, which receives the score table,
the screenshots, and the Design Read note: a build that reproduces the
source hero's layout + copy arrangement is caught there, not by the
judge.

### 3.6 Worked example

`Hero reference: Supahero — Lando Norris (https://supahero.io/hero/lando-norris) — structure only: full-bleed visual hero, headline over imagery, single CTA; differs from source: centred headline over still product shot (no F1 motion), two-column feature row below; screenshot: design/references/supahero-lando-norris.png`

## 4. Shared restraint — what counts, and what does not

**Rule decision (recorded 2026-11-11, from the red-team review): the
1–2 dealt-moment budget counts MOTION / attention effects only. A
still gradient background is a background token, not a moment — it
consumes no budget. An animated gradient is a motion moment and
consumes one unit.** The earlier draft counted a still gradient as one
dealt moment; that was a category error — a still gradient does not
move, and the budget exists to limit moving / attention effects, not
static backgrounds. The still gradient is restrained instead by
placement (§1.5: hero only, never every section) and by the judge's
Colour axis.

The page total is 1–2 dealt moments, shared across every motion /
attention source in the kit: scroll patterns
(`style-recipes/scroll-motion.md`) + GetLayers effect
(`getlayers.md`) + animated icons (`animated-icons.md` §4) + animated
Grainient gradient (this file §1) + the mounted moments.js moment that
clears the moment-none WARN (below). The new sources do NOT each get their own
budget.

- A still Grainient gradient background = a background token (0
  budget units). Placement: hero only, never on every section (§1.5).
  It is ambient depth, not a located moment: restraint rule 1's
  section-separation ("never two moments in one section") does not
  apply to it, because it occupies no section.
- An animated Grainient gradient = the motion dealt moment (1 budget
  unit). It obeys restraint rules 1 and 2 like a scroll moment (one
  moving thing per viewport; it replaces, not adds to, a scroll-motion
  moment).
- A Freefaces display face = NOT a dealt moment (token choice, §2.5) —
  but it still counts toward gaudiness in the judge's eyes; a loud face
  plus a gradient plus motion is three risks even if the budget says
  one. Too loud, worked: a display face at body sizes, or two display
  faces on one page — the judge's Type axis catches it. The rule is
  one display face, display sizes only.
- A Supahero hero structure = NOT a dealt moment (structure, §3.3).
- One background treatment per page: a Grainient gradient background
  and a GetLayers background effect do not stack — pick one.
- A page with a GetLayers effect carries neither an animated icon nor
  an animated Grainient gradient. (Same rule shape as
  animated-icons.md §4.)

**Gate caveat (verified in-repo): a gradient — still or animated —
does not satisfy the dealt-moment requirement. The gate counts
only `[data-moment]` / `[data-scroll-moment]` sections mounted by
moments.js. The checker emits moment-none as WARN
(`scripts/gate/consistency.mjs:1199-1201`); no gate code promotes it to
FAIL — `scripts/gate/gate.mjs` (351 lines) contains no moment handling
at all, and a WARN-only page exits 0 (`consistency.mjs:11521`), so a
page whose only effects are gradients and/or animated icons passes
leg 2 with moment-none WARN outstanding. (The checker's own prose
strings at `consistency.mjs:358,381` say the gate "holds it as a FAIL"
— that promotion does not exist in code; do not cite it.) Requiring a
mounted moments.js moment is therefore a house rule, not a gate FAIL.
Same caveat the animated icon already carries (SKILL.md step 1.2). A
page whose only effects are gradients and/or animated icons carries
moment-none; clear it with a mounted moments.js moment in its own
section (`moments.mjs pick`), which is itself one of the page's 2
budget units.** Consequence, stated plainly: a page cannot carry BOTH
an animated Grainient gradient and an animated icon AND satisfy the
house rule within budget — animated gradient (1) + icon (1) +
house-rule moment (1) = 3. Pick two of the three. (A still gradient
costs 0, so still gradient + icon + house-rule moment = 2 and is valid
— see worked budget B.)

Worked budget A: hero with a Grainient mesh background (background
token, hero only) + Pattern 2 hero-card expand (the hero's section
moment, 1 unit) + one mounted moments.js moment in its own section
elsewhere (2nd unit — the house-rule `[data-moment]`, clearing the
moment-none WARN; a calm section between it and the hero; both moments
in the front two-thirds, back third calm) = budget spent (2 units); no animated
icon, no GetLayers effect, no animated gradient.

Worked budget B: display face Getai Grotesk (0 units) + still gradient
(background token, hero only) + one animated icon (1 unit) + one
mounted moments.js moment in its own section (2nd unit, house-rule
moment, clearing the moment-none WARN; the icon's section and the
moment's section separated by a calm section; both moments in the front
two-thirds, back third calm) = budget spent (2 units); no GetLayers effect, no animated
gradient.

Worked budget C (animated gradient): animated Grainient gradient (1
unit — the motion moment, replacing the scroll moment) + one mounted
moments.js moment in its own section (2nd unit, house-rule moment,
clearing the moment-none WARN; a calm section between it and the hero;
both moments in the front two-thirds, back third calm) = budget spent
(2 units); no
scroll-pattern moment, no icon, no GetLayers effect. The animated
gradient obeys rules 1–2: one moving thing per viewport, calm sections
around it, never under dense copy.

## 5. High-end bar verdict

All three fit the bar when restrained — each supplies one thing the loop
otherwise invents badly: Grainient supplies depth without a drawn
stand-in (the restrained-depth pattern: one gradient + one soft shadow,
not a gradient on every section); Freefaces supplies a display face with
real personality instead of the default system stack; Supahero supplies
proven first-screen structures instead of a blank-canvas guess. The
gaudiness risks are source-specific: Grainient — gradient on every
section (placement rule: hero only), animated background under dense
copy; Freefaces — two display faces fighting, or a display face at body
sizes (rule: one display face, display sizes only, §4); Supahero —
copying a famous hero's copy / layout so closely the build reads as a
clone (caught at the human gate via the structural-difference note,
§3.5 — the judge grades fidelity, not originality). The judge's Type,
Layout, and Colour axes are the check for all three; none of the three
is a grading input.

## 6. Do NOT build on

- Do not copy, download, or vendor Grainient gradient files into the
  repo or the build. Grainient is reference-only: recreate as CSS
  tokens, never ship a Grainient file.
- Do not ship loose font files beside the HTML, and do not vendor font
  files into the repo. The only Freefaces delivery route is
  base64-inline into the single HTML file with the licence text
  alongside it (§2.5); any face whose licence does not permit embedding
  stays reference-only.
- Do not lift a Supahero hero's screenshot, copy, or assets into the
  shipped build. The one exception is the reference screenshot in the
  project's design/references/ folder (§3.5) — never shipped,
  judge-visible. Do not borrow a Supahero hero without saving its
  reference screenshot and recording the structural-difference note.
- Do not claim a still gradient is a dealt moment, and do not claim any
  gradient satisfies the gate's dealt-moment requirement (§4).
- Do not quote a Grainient price from this file — prices were not
  readable on primary and secondaries disagree (§1.3).
- Do not cite the reel's "Hero Gradients V2 — 32" or "Shadeshifter —
  28" counts, or Surf Skills' "1,000+" Supahero count — all three are
  unverified or contradicted by the live count.
- Do not claim the Grainient shader tool exports code, or that any of
  the three sources has an API / MCP / llms.txt — none was observed.
- Do not lock a Freefaces face without reading its licence line, and do
  not lock a gate-flagged face (Space Grotesk et al., AGENTS.md decision
  (e)) as the primary face.
- Do not present a Supahero hero as the build's source or lift its
  copy / assets.

## 7. Deliberately excluded / CHƯA ĐỌC

- Grainient: exact prices; the Freebies section's existence on primary;
  the "Hero Gradients V2" and "Shadeshifter" collections and their
  counts; the shader tool's output format; member download formats; the
  full licence / terms text.
- Freefaces: the total font count; the Sans Serif / Serif / Display /
  Slab category counts (only Cursive 10 and Monospace 11 were counted);
  the download-button / source-link route on font pages; per-font
  licences beyond Comico (ITF) and Space Grotesk (OFL 1.1); whether a
  display-slot face passes the gate (no gate run yet — §2.4 is an
  inference).
- Supahero: any terms / licence page (none found); the ScreensDesign
  library itself; the Framer templates list (~20, CLAIMED, Atlas);
  entries newer than December 2025 (CLAIMED, Atlas sampling window).

## 8. Sources

| # | Source | What it establishes | Accessed |
|---|--------|---------------------|----------|
| 1 | https://grainient.supply/ | What Grainient is; Boundless commercial access wording; animated 2K–4K 30–60 fps; weekly collections; 70,000/month site claim | 2026-11-11 |
| 2 | https://grainient.supply/pricing | Lifetime-only deals; FAQ includes a commercial-use question (answers not rendered) | 2026-11-11 |
| 3 | https://creati.ai/ai-tools/grainient/ | Secondary: $69 / $159 lifetime, "Has free plan: No", 1000+ assets (updated 2026-06-16) | 2026-11-11 |
| 4 | https://aipure.ai/products/grainient | Secondary: "Boundless License" name; commercial licence; 1000+ | 2026-11-11 |
| 5 | https://surfskills.surf/blog/design-resource-galleries | Secondary roundup of all three (published 2026-06-27): Freebies claim, $59/yr or $299 lifetime claim, six Freefaces categories, Simon Foster, Supahero "1,000+" | 2026-11-11 |
| 6 | https://www.freefaces.gallery/ | "Free typefaces and fonts"; latest list incl. Façade, Oi, Getai Grotesk, Memoir, Space Grotesk, Martian Mono; 1/8 pages | 2026-11-11 |
| 7 | https://www.freefaces.gallery/typefaces/comico | Comico: Cursive, 1 style, ITF Free Font License, $0 | 2026-11-11 |
| 8 | https://www.freefaces.gallery/typefaces/space-grotesk | Space Grotesk: Sans Serif, 5 styles + Variable, SIL OFL 1.1, $0 | 2026-11-11 |
| 9 | https://supahero.io/ | 573 entries counted live; Better Stack, Lando Norris, Linear, Stripe, Raycast, Attio, Resend, Grainient | 2026-11-11 |
| 10 | https://supahero.io/hero/lando-norris | "supahero is now part of screensdesign"; detail-page format (tagline + date added) | 2026-11-11 |
| 11 | https://atlas.justcallmebryan.com/sites/supahero | Secondary review (2026-09-25): ~570 heroes, no reuse licence, $79–$279 placements, no filters / tags / API / MCP, ScreensDesign banner | 2026-11-11 |
| 12 | https://www.ProductHunt.com/products/supahero | Secondary: price 0 USD; published 2025-01-10 | 2026-11-11 |
| 13 | https://www.facebook.com/reel/1666470368366970 | Shortlist source (the reel that named the three sites); post page read 2026-11-11 (author Sergey Lyubavsky, posted 2026-09-24, "Amazing Websites You Should Know as a Designer"; summary confirms the three sites + "Hero Gradients V2" / "Shadeshifter" collection names + the Lando Norris example); the video itself was not watched — no fact in §§1–3 rests on the voiceover | 2026-11-11 |
