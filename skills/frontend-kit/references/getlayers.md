# GetLayers — free-layer reference + free AI design tools

A vendored reference for the taste lock (`skills/frontend-kit/SKILL.md`
step 1) and the motion recipe
(`references/style-recipes/scroll-motion.md`).
GetLayers is an optional reference direction and an optional effect
source — never a mandatory step, never a substitute for the locked
`tokens.css`, and never a grading input. The kit works fully without
it, and without any paid GetLayers plan.

**Verification basis.** Every claim below was checked against the live
site on **2026-11-11** by two independent passes (live verification +
red-team re-verification, `build-notes/w-getlayers-verify.md` and
`build-notes/w-getlayers-redteam.md`). Each claim carries its source
URL and the access date. Where the two passes disagreed, the
red-team correction governs and is noted inline. Nothing in this file
was copied from a GetLayers prompt: no free prompt's text was
observable by text fetch (see §2.3), so no prompt text, length,
structure, or sample prompt appears anywhere in this file.

## 1. What GetLayers is

GetLayers is a library of hand-designed visual pieces ("layers") by
Textura, a small design studio. Each layer copies as one prompt;
a coding agent rebuilds it in the user's stack.

- "Every layer here was designed by hand first — whole templates, 3D
  scenes, motion, gradients"; "We're Textura, a small design studio."
  — https://www.getlayers.ai/about (accessed 2026-11-11).
- "A prompt tells your AI how to recreate a layer as one
  self-contained HTML file… Use a prompt when you want the layer in
  your own stack (Vue, Astro, Svelte, WordPress or anything else)."
  — https://www.getlayers.ai/docs (accessed 2026-11-11).
- "It builds a self-contained HTML file by default; add one line and
  your AI builds it in Next.js, Astro, Vue, WordPress, whatever you
  are already in." — https://www.getlayers.ai/ (homepage FAQ,
  accessed 2026-11-11).
- "can be copied as a single prompt and rebuilt by an AI coding agent
  in any stack" — https://www.getlayers.ai/llms.txt (accessed
  2026-11-11).

### 1.1 The five layer types (counts from llms.txt only)

| Type | Count (llms.txt, 2026-11-11) |
| --- | --- |
| Templates | 59 |
| 3D scenes | 221 |
| Sections | 10 |
| Backgrounds | 530 |
| Gradients | 1,088 |

Source: https://www.getlayers.ai/llms.txt (accessed 2026-11-11).
Do NOT use the Figma page's counts as library totals (templates 50+,
3D scenes 300+, backgrounds 270+, gradients 1,000+): they conflict
with llms.txt (most sharply 3D scenes "300+" vs 221 and backgrounds
"270+" vs 530) and are stale/rounded marketing figures — the Figma
page was last updated 2026-10-11. llms.txt is the count source.

## 2. The free set — how to pick a free layer

### 2.1 The offer (official FAQ wording)

"A curated set of free layers with the full prompt, no card needed."
— https://www.getlayers.ai/pricing (pricing FAQ, accessed
2026-11-11); same wording on the homepage FAQ
(https://www.getlayers.ai/, accessed 2026-11-11) and the About FAQ
(https://www.getlayers.ai/about, accessed 2026-11-11).

### 2.2 How to pick one

1. Open the library (https://www.getlayers.ai/templates, accessed
   2026-11-11) and use the "Try for free" strip. Named free entries
   on that strip include Soda, Kimi, Lumora, Laocoon, Baseline,
   Lumière, and Relay.
2. A named example: **Soda** — "Soda — a free website template from
   the GetLayers library", first entry in the "Try for free" strip,
   published 2026-06-07 — https://www.getlayers.ai/layer/soda
   (accessed 2026-11-11).
3. Copy the layer's prompt and paste it into any coding agent; the
   agent recreates the layer as one self-contained HTML file by
   default. Name your stack when you paste the prompt if you want it
   in that stack — https://www.getlayers.ai/docs (accessed
   2026-11-11).
4. In the kit loop, a free layer is used as a **reference direction
   only**: its motion, depth, and atmosphere inform the taste lock
   (step 1) the same way a reference screenshot does. The locked
   tokens are still written by hand from the brief + references; the
   layer is never pasted in as the build, and the layer's prompt is
   never the build's source. Record the chosen layer (name + URL) in
   the run log and in the Design Read.

### 2.3 Honest limits — read before citing the free tier

- **No prompt text was observed.** The prompt lives behind the
  interactive "Copy prompt" button, which a text fetch cannot click.
  The Soda page, the templates page, the docs, llms.txt, and the
  published skill were all read in full and none prints a layer
  prompt body. Do NOT claim any free prompt's text, length,
  structure, sections, wording, or completeness was read or verified.
  Completeness is attested only by the official FAQ wording ("full
  prompt included"), not by inspection. Do NOT embed a sample prompt
  presented as a real GetLayers prompt.
- **No per-day numbers.** Only the Terms' general rule is confirmed:
  "Free content is available without purchase. Without an account,
  free content is subject to a small daily limit; creating a free
  account removes that limit for free content."
  — https://www.getlayers.ai/terms-of-use ("Subscription plans &
  pricing", accessed 2026-11-11). A "1 free prompt + 1 free
  background/day" figure circulated in an earlier verification pass
  but does NOT appear in the complete docs fetch — do not build on
  it, do not cite it.
- **Prompt free, source not.** A free layer's downloadable source
  files come with Full Stack only; the prompt is free, the source is
  not — see §7.

## 3. The 13 free AI design tools (effect sources)

Count confirmed by the `/tools` header ("13 tools · New tools
monthly"), the docs, llms.txt, and the sitemap's 13 `/tools/*` URLs.
— https://www.getlayers.ai/tools, https://www.getlayers.ai/docs,
https://www.getlayers.ai/llms.txt, https://www.getlayers.ai/sitemap.xml
(all accessed 2026-11-11).

"13 free AI design tools… Every tool is free to run, tune, copy and
download, signed out included. Saving looks needs a free account."
— https://www.getlayers.ai/docs (accessed 2026-11-11). "Every tool is
free to run, tune, copy and download." — https://www.getlayers.ai/llms.txt
(accessed 2026-11-11).

| # | Tool | /tools slug | What it is for (by name) |
| --- | --- | --- | --- |
| 1 | Text Animations | `text-animations` | Animated text effects |
| 2 | Custom Cursors | `custom-cursors` | Custom cursor effects |
| 3 | ASCII Studio | `ascii-studio` | ASCII-art effects |
| 4 | Particle Forms | `particle-forms` | Particle-form effects |
| 5 | Holographic Cloth | `holographic-cloth` | Holographic cloth effect |
| 6 | Image Compressor | `image-compressor` | Compress images (utility — see note) |
| 7 | Image Motion | `image-motion` | Motion applied to an image |
| 8 | SVG to 3D | `svg-to-3d` | 3D from an SVG |
| 9 | Refract | `refract` | Refraction effect |
| 10 | Liquid Colour | `liquid-colour` | Liquid colour effect |
| 11 | Orb Studio | `orb-studio` | Orb effects |
| 12 | Dither Art | `dither-art` | Dithered-art effects |
| 13 | Shader Backgrounds | `shader-backgrounds` | Shader backgrounds |

How to use one in the kit loop: pick a preset in the tool in the
browser, preview it, and copy the prompt that rebuilds it (e.g. the
text-animations tool page: "Pick a text-animation preset, preview
it…, and copy a prompt that rebuilds it" —
https://www.getlayers.ai/tools/text-animations, accessed 2026-11-11).
The copied prompt is an **effect source** for the motion recipe
(`references/style-recipes/scroll-motion.md`): it supplies one effect,
which still counts as one of the recipe's 1–2 dealt moments per page
and still obeys every restraint rule there (transform/opacity only,
once-and-short reveals, reduced motion, mobile calmer). The tool's
prompt text itself is behind the tool's interactive copy control and
was not observed — same limit as §2.3; do not describe it.

Notes:

- **Image Compressor is browser-only.** It is the one tool NOT
  exposed via the MCP ("The 12 AI design tools that work through the
  MCP (all but Image Compressor)" —
  https://www.getlayers.ai/mcp, accessed 2026-11-11). Its output is
  the compressed file; it has no saved looks. Do not claim 13 MCP
  tools — 13 in the browser, 12 via MCP.
- **Saving a look needs a free account** (docs, §3 above); running,
  tuning, copying, and downloading do not.
- Agent use of these tools via the MCP is paid-only (Full Stack
  Lifetime) — see §9. The browser tools themselves are free, and the
  kit uses the browser route only.

## 4. The published skill (reference only — not invoked by the kit)

Source: https://storage.getlayers.ai/skill/getlayers/SKILL.md
(accessed 2026-11-11; read in full, 399 lines; frontmatter
`name: getlayers`). A mirror exists in the public GitHub repo
`textura-agency/getlayers-plugin`
(`plugins/getlayers/skills/getlayers/SKILL.md`). What follows is a
**summary, not a copy**.

- **Trigger:** load it BEFORE calling any `getlayers_*` tool,
  whenever the user wants to build/design with GetLayers, rebuild a
  favourited/saved layer, build from a Figma-edited template, make an
  effect with the AI design tools, or mentions GetLayers/MCP.
- **Step 0 — always call `getlayers_start` first**, before discussing
  layouts or writing UI. It returns the eight modes + guide /
  vocabulary / environment info.
- **Eight modes:** (1) build a website from scratch — search & pick a
  template, extend a named template, or build unique from
  compositions; (2) design a unique 3D scene via `getlayers_scene_lab`;
  (3) browse & pull an asset; (4) add a video background; (5) add
  motion/3D to an existing project (read its code first); (6) rebuild
  something saved/favourited (`getlayers_my_favourites` → confirm →
  `getlayers_reproduce`, 1:1, don't redesign); (7) build from a
  Figma-edited template (Figma MCP + `getlayers_figma_match`, port
  only the edits); (8) make an effect with the AI design tools
  (`getlayers_tools` → preset → `getlayers_tool_look`, follow the
  returned prompt verbatim).
- **Non-negotiables (summarised):** never strict-filter by tags
  (judge fit by description/vibe); compositions are the layout layer
  under everything — never a generic centered stack; establish the
  environment first (fresh project from
  `textura-agency/next16-claude-starter`, Node 22.13+, `yarn install`,
  `.env` from example, `yarn dev`); commit ONE Style early and pass
  its `styleId` to every materialize; tint scenes through CONFIG,
  never the shader; re-dress via `getlayers_palettes` /
  `getlayers_fonts` (one palette per surface, one type system per
  site); show previews via the site (`getlayers.ai/?layer=<id>`),
  never hotlink watermarked `storage.getlayers.ai` media; download
  background video/poster into the project, never hotlink; gather the
  brief first (five axes for scenes: dimensionality, mood, tone,
  motionEnergy, density); keep state in `getlayers.json` (read before
  / write after each section).
- **Materialize targets:** `target: 'starter' | 'next'` on a Next
  template → real Next tree; `target: 'react' | 'other'` or non-Next
  → portable single-HTML master. If the stack is unknown, omit
  `target` and ask. Heavy media (video, `.glb`, textures) is
  referenced, not embedded — download into `public/` and repoint;
  never ship hotlinking the bucket.

**Kit boundary:** the skill describes a **paid-MCP** workflow (the
`getlayers_*` tools need the MCP, which needs Full Stack Lifetime —
§9). This kit does NOT invoke `getlayers_*` tools and does NOT follow
the skill's environment setup (starter repo, `getlayers.json`,
materialize targets). The skill is vendored here as a reference for
what the layer-prompt workflow looks like and what "follow the
returned prompt verbatim" means for tool effects — nothing more.

## 5. llms.txt (machine-readable map)

Source: https://www.getlayers.ai/llms.txt (accessed 2026-11-11;
fetched in full, 80 lines). Contents: intro, the five library
categories with the live counts in §1.1, core pages (library,
pricing, docs, MCP, tools, Figma, about, affiliate), key facts, and
machine-readable pointers (sitemap, structured data). It is public
and free to read and reference.

`/llms-full.txt` does not exist: a direct fetch of
https://www.getlayers.ai/llms-full.txt returns HTTP 404 (reproduced
2026-11-11), and llms.txt references no such file. Do not cite it.

## 6. Figma plugin (free for free layers)

Source: https://www.getlayers.ai/figma (accessed 2026-11-11);
corroborated by the docs FAQ — https://www.getlayers.ai/docs
(accessed 2026-11-11).

- "The plugin is free. Your plan sets the rest." — Figma page.
- "Free in Figma Community", published 2026-09-17, updated
  2026-10-11.
- **Free, signed in or not:** browse; free templates/sections as
  Figma design (frames, text, auto-layout, styles, with tablet and
  phone frames next to desktop); configure free gradients; any
  scene/gradient/background as an image; prompts for free layers.
  "It's free in Figma Community, and free layers work without an
  account." — docs FAQ.
- **Paid (Unlimited Plus & Full Stack, yearly or lifetime):**
  premium templates/sections as Figma design; clean (unwatermarked)
  backgrounds; configure premium gradients; every premium prompt.
- **Caveats:** only layers with the Figma mark place as design;
  images work on any Figma plan; video needs a paid Figma team (a
  free Starter team gets the still).

The plugin is an optional step-1 input route (a free layer's Figma
design can sit alongside the screenshot references); it is not part
of the gate and never replaces the taste lock.

## 7. Free / paid boundary

**Plan contents are cited from the pricing FAQ, not the pricing
cards.** The two pricing cards as fetched list identical feature
bullets (the text fetch drops the check/cross marks), so the cards do
not support any per-plan feature split. The split below is the FAQ's.

| Plan | Price (live page, 2026-11-11) | What it adds (pricing FAQ) |
| --- | --- | --- |
| Free | $0 | Curated free layers, full prompt, no card (§2) |
| Unlimited | **$139** lifetime (one-time) | Every premium template, 3D scene, and section prompt |
| Unlimited Plus | **$199** lifetime (one-time) | + premium backgrounds (4K), premium gradients, live preview & tuning, gradient roller, Figma designs |
| Full Stack | **NOT directly visible on /pricing as fetched** — see §9 | Everything in Unlimited Plus + downloadable source code for every layer + the GetLayers MCP + private Discord; no usage limits; lifetime only |

Sources: https://www.getlayers.ai/pricing (accessed 2026-11-11 —
Unlimited $139 and Unlimited Plus $199 are direct price lines on
the live page; the Full Stack card does not appear in the fetched
page text); https://www.getlayers.ai/docs (accessed 2026-11-11);
https://www.getlayers.ai/llms.txt (accessed 2026-11-11).

Fair use (live pricing page, 2026-11-11): Unlimited — 10 prompt
copies per type / day; Unlimited Plus — 20 prompt copies per type,
20 video downloads / day. Full Stack — no usage limits (per FAQ).

**Yearly prices: unverified live.** The fetched pricing page shows
only the two lifetime cards; no yearly price appears in it. The
Terms confirm yearly billing exists (Unlimited / Unlimited Plus are
"available as an annual subscription or a one-time lifetime
purchase") but give no amounts. Do not record any yearly price as
current. (A September 2026 third-party review said Unlimited
$99/year — stale, unverified live.)

## 8. Licence (the Terms govern)

Source: https://www.getlayers.ai/terms-of-use (accessed 2026-11-11;
operator: DZIANIS KRAUCHUN, ul. Chmielna 2 lok. 31, 00-020 Warszawa,
Poland; payments via Stripe; all purchases final and non-refundable).

- **Commercial licence, free layers included.** "You may use that
  content, free and premium alike, to generate content for personal
  or commercial projects… Every layer, including free layers, is
  licensed for commercial use. There are no restrictions on the
  number of projects or clients, and no requirement to credit
  getlayers.ai." (Terms, "License & permitted use"; same wording in
  the pricing FAQ and docs FAQ.) All plans are personal-use licences
  subject to fair use.
- **"Extend, don't ship as-is" is FAQ guidance, not a Terms clause.**
  Homepage + pricing FAQ: "Free layers are for trying the product —
  extend them into your own thing rather than shipping one as-is."
  That sentence does NOT appear in the Terms (read in full, 147
  lines). The Terms' binding licence is broader: free layers ARE
  commercially licensed, with no project cap. Label the line as
  guidance whenever it is cited, never as a binding clause.
  - Tension, flagged: the homepage FAQ also says "Yes, on any paid
    plan: a commercial licence…" — read literally that would exclude
    free layers. It is contradicted by the Terms, the pricing FAQ,
    and the docs FAQ, all of which explicitly include free layers.
    **Terms governs**; treat the homepage line as loose wording, not
    a restriction.
- **Licence covers generated output, not the prompts.** "The license
  granted in the License & Permitted Use section applies only to the
  output you generate using the prompts — not to the prompts
  themselves. You may not copy, redistribute, sublicense, or sell
  the prompt templates as standalone products." (Terms,
  "Intellectual property".)
- **No scraping / redistribution / resale.** "scrape, copy, or
  redistribute the prompt library itself (in whole or in part) for
  resale or as a competing product" is prohibited (Terms,
  "Prohibited use").
- **Bulk / automated extraction → restriction.** The licence grants
  no right to "duplicate, archive, or extract the library (or a
  substantial part of it) in bulk, whether manually or through
  automation." Detection of abnormal copying/downloading may lead to
  the account being temporarily restricted by disabling prompt
  copying and file downloads, regardless of plan, at the operator's
  sole discretion, without prior notice; appeal via the contact page
  / team@getlayers.ai; repeated/egregious violations may lead to
  termination. (Terms, "Fair use & account restrictions".)

Consequence for the kit: use one named free layer at a time as a
reference; never bulk-copy the library, never redistribute prompt
text, never ship a layer as-is when the FAQ guidance says extend it
(see §2.2 step 4).

## 9. Paid MCP path — OPTIONAL only

The kit works fully without the MCP. Nothing in the loop needs it,
and no step in this kit creates a GetLayers account, enters
credentials, or purchases anything. This section exists so the option
is documented accurately — not so the loop uses it.

- **What it is:** a remote MCP server exposing the library to a
  coding agent — **17 tools in five groups**, counted from the MCP
  table: Start & plan 3 (`getlayers_start`, `getlayers_plan`,
  `getlayers_state_schema`) + Find 3 (`getlayers_search`,
  `getlayers_browse`, `getlayers_explore`) + Build 4
  (`getlayers_materialize`, `getlayers_source`,
  `getlayers_figma_match`, `getlayers_scene_lab`) + Tools &
  favourites 4 (`getlayers_tools`, `getlayers_tool_look`,
  `getlayers_my_favourites`, `getlayers_reproduce`) + Restyle 3
  (`getlayers_compositions`, `getlayers_palettes`, `getlayers_fonts`) —
  https://www.getlayers.ai/mcp (accessed 2026-11-11). (Do NOT cite
  the docs for the "17 tools" figure — the complete docs fetch
  contains no such sentence; the count stands on the MCP table
  alone.)
- **Endpoint:** `https://mcp.getlayers.ai/mcp`. Recorded as
  **third-party-corroborated only**: the /mcp page text does not
  display the endpoint URL, and a fetch of the URL returns HTTP 401
  (auth-gated — consistent with a live endpoint, not proof it serves
  MCP). The URL is corroborated by the September 2026 Atlas review
  (https://atlas.justcallmebryan.com/sites/getlayers, reviewed
  2026-09-25). No API key; sign in with a GetLayers account.
- **Clients:** Claude Code, the Claude app, Cursor, and Codex have
  their own setup steps on the MCP page; ChatGPT, Windsurf, and Cline
  connect as a custom connector; the page also lists Gemini, Kimi,
  and DeepSeek as supported — https://www.getlayers.ai/mcp (accessed
  2026-11-11).
- **Setup (as documented on the MCP page):** follow the per-client
  steps on https://www.getlayers.ai/mcp (accessed 2026-11-11) to add
  the server and sign in with a GetLayers account; then load the
  published skill (§4) before calling any `getlayers_*` tool — the
  skill's Step 0 is `getlayers_start` first. Setup is a human step:
  it needs a paid plan and a sign-in, so the kit never performs it
  unattended.
- **Gate: Full Stack Lifetime only.** MCP FAQ: "Which plan do I
  need? A: Full Stack Lifetime." Pricing FAQ: "It is included with
  Full Stack Lifetime." Docs FAQ: "the GetLayers MCP, which comes
  with Full Stack Lifetime." — https://www.getlayers.ai/mcp,
  https://www.getlayers.ai/pricing, https://www.getlayers.ai/docs
  (all accessed 2026-11-11).
- **Price: $249 (indirect evidence only; re-check in a real browser
  before any purchase).** No Full Stack price line appears on the
  pricing page as fetched 2026-11-11. The $249 figure rests on two
  indirect signals: the MCP page's structured data ("Price: 249
  USD", attached to the MCP product, not labelled "Full Stack") and
  the pricing page's JSON-LD range ("Price: 99 to 249 USD", a
  ceiling, not a price tag). **Never present $249 as verified, and
  never use $199** — $199 was the September 2026 third-party price
  (Atlas review, 2026-09-25) and is superseded: that same review is
  demonstrably wrong about the current tier split. Re-check the live
  pricing page in a real browser before any purchase.

## High-end bar fit — verdict (2026-11-11)

Judged against the kit's high-end bar (workflow.md §1): the loop aims
at an 8/10 human feel — refined and high-end, motion + 3D as plus
points, neither bland nor gaudy. **Verdict: MIXED — the free layers
fit the bar when used as a restrained reference; the gaudiness risk
sits in the gradient/effect-heavy end of the library, and the kit's
existing restraint rules are what keep it on the right side.**

What was observed:

- **The free Soda layer's preview reads high-end, not gaudy.**
  `w-getlayers-exercise/design/references/soda-preview.jpg` (the
  layer's public preview, viewed 2026-11-11): dark green ground, one
  large 3D-ish can as the single hero moment, large italic serif
  display type, floating cherries, one red accent against cream type.
  One strong hero idea, a restrained palette, big typography — the
  same shape as the kit's "one hero moment" direction. Its public
  description names exactly three behaviours (floating
  cursor-following can; berries scattering from a touch; whole-world
  colour shift per flavour) — motion, depth, and atmosphere, i.e.
  the "motion + 3D as plus points" side of the bar.
- **The exercise used it that way.** The GetLayers exercise
  (`w-getlayers-exercise/`, `index.html` built, gate green — see
  `build-notes/w-getlayers-exercise.md`) locked Soda as its reference
  direction with motion Med, pointer tilt + scatter + flavour-shift
  (Pattern 5 reveals were removed in fix round 2 — the gate bans
  them), one easing family, and a generated product photo
  (hero-can.png) in place of the CSS can stand-in. The layer fed a
  restrained direction; it did not become the build.
- **The library's positioning supports the bar.** Hand-designed
  layers by a studio (About page, §1), with the two biggest
  motion/depth categories being 3D scenes (221) and backgrounds
  (530) — depth and atmosphere are the library's stock in trade, not
  an afterthought.

What was NOT observed: no layer was seen rendered live in a browser
(text fetch only — the prompt sits behind the interactive Copy
button, §2.3), and no GetLayers-derived build has been graded by the
judge or the human yet. This verdict is about the library's
positioning, the public descriptions/categories, the one preview
image seen, and the exercise's taste lock — not about rendered
output.

Where it risks gaudiness (restraint applies):

- **Gradients are the largest category (1,088) and backgrounds
  second (530).** A gradient-led layer is the fastest route to the
  "diêm dúa" side of the bar — a full-page gradient wash or a
  stacked gradient background reads as decoration, not refinement.
  A gradient layer is usable as atmosphere only when it stays a
  background (never behind body text) and the page's one accent
  stays functional.
- **The high-energy tools.** Holographic Cloth, Liquid Colour,
  Particle Forms, ASCII Studio, Custom Cursors (§3) are loud effects
  by design. Any one of them is at most ONE dealt moment — never
  stacked with a scroll pattern in the same or a neighbouring
  section, never looped, never on mobile beyond a calmer form.
- **A loud product visual transplanted to the wrong brief.** Soda's
  glossy can + floating fruit is on-brief for a soda brand; the
  same energy on a SaaS or dashboard brief would be gaudy. The
  layer's fit is judged per brief, never in the abstract.

Restraint that already covers this (no new rule needed): the
scroll-motion restraint rules (`references/style-recipes/scroll-motion.md`
— at most 1–2 dealt moments per page, one moving thing per viewport,
transform/opacity only, reveals once and short, mobile calmer), the
1–2 dealt moments rule the kit already applies to GetLayers effects
(getlayers.md §3, scroll-motion.md "Effect sources"), and the FAQ
guidance to extend a free layer rather than ship it as-is (§8). A
GetLayers layer that needs more than 1–2 dealt moments to read as
itself does not fit the bar — pick a calmer layer or drop it.

## 10. Do NOT build on

- The MCP itself, any premium prompt/source, or bulk copying of the
  library (paid gate / Terms prohibition, §8).
- Full Stack Lifetime $249 as a verified price — record only as
  "$249 (indirect evidence only; re-check in a real browser before
  any purchase)". Never freeze $199.
- Any yearly price (none observed live).
- "1 free prompt + 1 free background/day" signed-out figures (not
  observed; only the Terms' general "small daily limit" is
  confirmed).
- Any claim about a prompt's text, length, structure, or
  completeness (never observed — §2.3).
- Figma-page category counts as library totals (stale; use llms.txt
  — §1.1).
- The pricing-card feature bullets as a source for plan contents
  (identical lists under both cards in the text fetch; use the FAQ
  — §7).
- The MCP endpoint URL as primary-observed (third-party-corroborated
  only — §9).
- The "extend, don't ship as-is" line as a Terms clause (FAQ
  guidance only — §8).

## Deliberately excluded (do not re-add without a council vote)

- Any sample prompt presented as a real GetLayers prompt.
- Any per-plan feature split sourced from the pricing cards.
- Any yearly price, any "1/day" free-tier figure, any Figma-page
  count as a library total.
- MCP invocation inside the loop (paid gate; the kit's free
  integration is the browser route only: free layers + the 13 free
  in-browser tools).
