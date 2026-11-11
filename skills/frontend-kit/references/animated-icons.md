# Animated icons — free-source reference + embedding

A vendored reference for the taste lock (`skills/frontend-kit/SKILL.md`
step 1) and the motion recipe
(`references/style-recipes/scroll-motion.md`).
Animated icons are an optional effect source — never a mandatory step,
never a substitute for the locked `tokens.css`, and never a grading
input. The kit works fully without them, and without any paid plan on
any source below.

**Verification basis.** Every claim below was checked against the live
sites on **2026-11-11** by four independent verification passes
(`build-notes/w-icons-verify-lottiefiles.md`,
`build-notes/w-icons-verify-lordicon.md`,
`build-notes/w-icons-verify-lottieflow-iconsax.md`,
`build-notes/w-icons-verify-useanimations-mechanics.md`). Each claim
carries its source URL and the access date. One fix-pass read postdates
the four passes: the raw useAnimations `LICENSE` file (repo + npm) was
read on 2026-11-11 and is MIT text, not CC BY — see §1.2. Anything marked CHƯA ĐỌC
or CONFLICTING in those reports does not appear here as a verified
claim — see §"Do NOT build on". Counts that move day to day are quoted
as of 2026-11-11, not as stable facts.

## 1. What animated icons are in this kit

An animated icon is a micro-animation at interface scale — one small
Lottie JSON (typically 1–15 kB) played inside a button, a nav item, a
loader, or a state change — not an illustration and not a page-level
animation. Lottie is a JSON-based animation format: small files,
vector-based, infinitely scalable without pixelation
— https://lottiefiles.com/what-is-lottie?via=footer_nav (accessed
2026-11-11). dotLottie (.lottie) is a compressed ZIP-based bundle of
one or more Lottie JSON animations plus assets (images, fonts, themes,
state machines) in a single file — same source (accessed 2026-11-11).

The kit's build shape is a single self-contained HTML file. The
preferred embedding (§3) inlines one icon's JSON as `animationData`
with a pinned lottie-web build — no external icon fetch, no CORS
dependency. That is why the sources below are judged on three things:
whether their files are free, whether their licence permits the kit's
use, and whether an agent can fetch a plain Lottie JSON file.

### 1.1 The per-source table

| Source | Free animated icons (2026-11-11) | Licence | Formats | Agent path |
| --- | --- | --- | --- | --- |
| useAnimations | **300** — "300 hand-crafted micro animations", "300 free animated icons" — https://useanimations.com/ ; `icons.json` `"count": 300`, `"updated": "2026-10-11"` — https://useanimations.com/icons.json | **MIT** — "The icons and the react-useanimations package are MIT licensed: use, modify and redistribute them in personal and commercial work. Attribution is appreciated but not required." — https://useanimations.com/ ; full MIT text, Copyright (c) 2018-2026 useAnimations — https://Useanimations.com/licencing-and-terms.html ; `icons.json` licence block `"name": "MIT"` — https://useanimations.com/icons.json | Lottie JSON, still SVG per state, React component, shadcn — https://useanimations.com/ ; file list `icons/<id>.json`, `icons/<id>.zip`, `icons/<id>/<state>.svg`, `icons.json` — https://useanimations.com/lottie-icons | npm `react-useanimations` 3.1.1 (React 18+, ~8 kB player, ~2 kB median/icon) — https://github.com/useAnimations/react-useanimations ; shadcn `npx shadcn@latest add https://useanimations.com/r/<id>.json` — https://useanimations.com/lottie-icons ; direct files `https://useanimations.com/icons/<id>.json` + agent-readable `https://useanimations.com/icons.json` — https://useanimations.com/lottie-icons |
| LottieFiles | **≈5,900** — live page counter read **5,929 Free Icon Animations** (a search snippet the same day read 5,931; counts drift daily — quote as ≈5,900, 2026-11-11) — https://lottiefiles.com/free-animations/icon?page=11 | **Lottie Simple License** — "Free for personal and commercial use under the Lottie Simple License" — https://lottiefiles.com/free-animations/icon?page=11 ; commercial use and modification allowed, attribution NOT required but strongly encouraged; derivatives stay under the same licence; no collecting/compiling files to build a competing service — https://help.lottiefiles.com/animation-licensing-basics- and https://lottiefiles.com/page/license | Lottie JSON, dotLottie, GIF, MP4 — https://lottiefiles.com/free-animations/icon?page=11 | Current player `<dotlottie-wc>` (see §3.2); legacy npm `@lottiefiles/lottie-player` — **BANNED, see §3.5** — whose `player.load()` accepts an inline JSON string/object — https://app.unpkg.com/@lottiefiles/lottie-player@2.0.8/files/README.md (an npm/unpkg mirror of the README, v2.0.8 — not lottiefiles.com itself). A free account is required to download — https://lottiefiles.com/free-animations/gif |
| Lordicon | **9,700+ free** of **49,000+** total — https://lordicon.com/ | **Free licence based on CC BY-ND 4.0, modified** — https://lordicon.com/license-terms/archive/v2026-02-26 (archived ToS, accessed 2026-11-11) — attribution REQUIRED: exact link `<a href="https://lordicon.com/">Animated icons by Lordicon.com</a>` (footer on websites) — https://lordicon.com/docs/license/attribution ; free use allowed in personal AND commercial projects, but only with that attribution — same source | Lottie JSON (default), GIF, MP4, WebP, APNG, PNG, SVG, plus AEP/MOGRT source files — https://lordicon.com/ ; https://lordicon.com/docs/customization-formats | npm `npm install @lordicon/element`, `defineElement()`, then `<lord-icon trigger="hover" src="/my-icon.json">` — https://lordicon.com/docs/web ; Lordicon recommends self-hosting icons and scripts over CDN embeds — https://lordicon.com/terms-of-service |
| Iconsax | **0 free animated icons** — the 1,000 animated icons are Premium-only (see §2.3). As a STATIC library: 6,000–7,000 free icons (official pages disagree — never cite a single exact count) — https://docs.iconsax.io/docs/intro ; https://app.iconsax.io/pricing | **Proprietary** (not open source) — free use commercial-OK, no attribution in final products, mandatory attribution in sold/distributed UI kits/templates; no resale/sublicensing, no redistribution of loose icons, non-transferable, single user — https://docs.iconsax.io/license-and-terms/license | Static: SVG, PNG, WebP, font icon (WOFF, WOFF2, TTF) — https://docs.iconsax.io/getting-started ; animated formats (Premium only): GIF and Lottie JSON — https://docs.iconsax.io/license-and-terms/license | Web-app manual download, Figma plugin (free icons, no login), copy-paste framework code — https://docs.iconsax.io/getting-started ; official npm integration is "coming soon" — https://app.iconsax.io/pricing |
| Lottieflow | **Not recommended** — no licence/terms text exists on any readable primary page (see §2.4). "Absolutely FREE" pricing is verified, but a free price is not a licence. | **Unknown — CHƯA ĐỌC.** No licence or terms text found on any primary page read — https://finsweet.com/lottieflow/legal-bologna/privacy (accessed 2026-11-11). Do NOT claim the Lottie Simple License covers its files. | Lottie JSON only — https://finsweet.com/lottieflow/index.html ; https://webflow.com/integrations/lottieflow | No API ("Lottieflow itself has no API" — https://webflow.com/integrations/lottieflow); a free account is required to download — same source |

### 1.2 useAnimations — the default source

useAnimations is the kit's default animated-icon source: the only one
of the five that is MIT-licensed, has an agent-readable catalog, and
supplies a still SVG per state for the no-JavaScript fallback.

- **Count:** 300, verified three ways — homepage, `icons.json`
  (`"count": 300`, `"updated": "2026-10-11"`), GitHub README ("300
  free animated icons") — https://useanimations.com/ ;
  https://useanimations.com/icons.json ;
  https://github.com/useAnimations/react-useanimations (all accessed
  2026-11-11).
- **Licence:** MIT on every current primary surface (homepage FAQ,
  live licencing page with full MIT text, `icons.json` licence block,
  GitHub header + README §License), and MIT in the raw `LICENSE` file
  itself, read 2026-11-11: MIT text, Copyright (c) 2018-2026
  useAnimations, no CC BY text —
  https://raw.githubusercontent.com/useAnimations/react-useanimations/main/LICENSE ;
  the identical file ships in `react-useanimations@3.1.1` on npm (md5
  `7dbace1564e20277600a7c19e6679e1f`, 1,103 bytes) —
  https://unpkg.com/react-useanimations@3.1.1/LICENSE (accessed
  2026-11-11): commercial use, modification and
  redistribution allowed, including inside icon packs, templates,
  themes, UI kits and component registries; attribution not required
  but appreciated; keep the licence notice when redistributing the
  files themselves — https://useanimations.com/licencing-and-terms.html ;
  https://useanimations.com/icons.json (accessed 2026-11-11).
- **Scope:** micro-interface icons only; one stroke style
  (Feather-like, 24/32 px grid); no illustrations, no large scenes
  — https://useanimations.com/ ;
  https://useanimations.com/lottie-icons (accessed 2026-11-11).
- **Files:** standard Lottie JSON (Bodymovin format, shape layers
  only: no images, fonts or external assets; each icon drawn on a 24
  or 32 px artboard), 1 kB to 14 kB, 2 kB median; the SVG files are
  still images of the icon at rest, one per state, "for places where
  nothing should move: emails, documents, design tools or a
  no-JavaScript fallback" — https://useanimations.com/lottie-icons ;
  https://useanimations.com/ (accessed 2026-11-11).
- **Interactions built in (6 kinds):** `hover-replay` (plays once on
  hover), `click-replay` (replays on every click), `click-toggle`
  (toggles between two states), `loop` (plays continuously —
  restricted by §4: do not use except a loader), `hover`
  (forward on hover, backward on leave), `hover-loop` (loops while
  hovered — restricted by §4: do not use) — https://github.com/useAnimations/react-useanimations ;
  https://useanimations.com/icons.json (accessed 2026-11-11).
- **Theming:** "Icons use currentColor: they pick up text color,
  hover states and dark mode on their own." — https://useanimations.com/
  (accessed 2026-11-11). The React component's `strokeColor`
  defaults to `'currentColor'` — https://github.com/useAnimations/react-useanimations
  (accessed 2026-11-11). The knockout/gap colour defaults to white
  on light / dark on `color-scheme: dark` pages; override with
  `--ua-knockout` — same source.
- **Reduced motion (React component):** "When the user prefers
  reduced motion (prefers-reduced-motion: reduce), icons stay still:
  looping icons show their first frame, hover and replay animations
  don't play, and toggles switch to their new state immediately."
  — https://github.com/useAnimations/react-useanimations (accessed
  2026-11-11). Hover animations also play on keyboard focus; icons
  are `aria-hidden` by default — same source.
- **Consumption paths (all verified live):** npm
  `npm install react-useanimations` — version **3.1.1**, requires
  React 18 or newer, "lottie-web is no longer a dependency" in v3;
  the player is "about 8 kB gzipped with no dependencies, and each
  icon is its own module of 1 to 15 kB (2 kB median)"
  — https://useanimations.com/ ;
  https://github.com/useAnimations/react-useanimations (accessed
  2026-11-11). shadcn: `npx shadcn@latest add
  https://useanimations.com/r/<id>.json`
  — https://useanimations.com/lottie-icons (accessed 2026-11-11).
  Direct files: `https://useanimations.com/icons/<id>.json` (Lottie
  JSON, CORS-enabled — `icons.json` field note: "Use it as path in
  lottie.loadAnimation or download it into the project"),
  `https://useanimations.com/icons/<id>.zip` (JSON + static SVGs),
  `https://useanimations.com/icons/<id>/<state>.svg`, and the
  agent-readable catalog `https://useanimations.com/icons.json`
  ("lists every icon with its id, title, category, keywords,
  interaction, size, duration and file URLs, which makes it easy to
  pick icons by keyword in a script or let a coding agent choose
  one") — https://useanimations.com/lottie-icons ;
  https://useanimations.com/icons.json (accessed 2026-11-11).
- **Flags — read before picking an icon:**
  - **Error + Twitter need the full lottie-web build.** "2 icons use
    After Effects expressions (loopOut or wiggle): Error, Twitter. On
    the web they need lottie-web's full build; lottie_light ignores
    expressions." — https://useanimations.com/lottie-icons (accessed
    2026-11-11). `icons.json` marks `requiresFullPlayer: true` only
    for `error` (and by the page text, `twitter`) — https://useanimations.com/icons.json
    (accessed 2026-11-11). The kit's preferred route already uses
    the full build (§3.1), so this is a note, not a blocker.
  - **6 icons have no static SVG:** `calendar`, `loading`,
    `loading2`, `loading3`, `zoomIn`, `zoomOut`
    — https://github.com/useAnimations/react-useanimations (accessed
    2026-11-11). For those six the static-SVG fallback (§3.4) is
    unavailable; use the Lottie first frame instead. Never pick one
    of the six for a build that needs the SVG fallback.
  - **`delete` and `package` are reserved words** in imports:
    `import deleteIcon from 'react-useanimations/lib/delete'`
    — https://github.com/useAnimations/react-useanimations (accessed
    2026-11-11).

### 1.3 LottieFiles — the large free library

- **Free icons:** ≈5,900 as of 2026-11-11 (live page read 5,929;
  counts drift daily) — https://lottiefiles.com/free-animations/icon?page=11.
  Each downloadable as Lottie JSON, dotLottie, GIF or MP4 — same
  source. The total library is **800,000+ free and premium combined**
  — https://docs.lottiefiles.com/en/creator/09_assets-and-importing/library
  (accessed 2026-11-11) — never quote 800,000+ as a free-only total.
- **Licence:** Lottie Simple License — free download, commercial use
  in business projects/websites/apps/products, modification
  (derivative works), publish and distribute as part of products /
  services; attribution NOT required but strongly encouraged (if
  credited, the credit must be visible to end users); modifications
  are derivative works distributed under the same terms; **no right
  to collect or compile Files to replicate or develop a similar or
  competing service** — https://help.lottiefiles.com/animation-licensing-basics-
  ; https://lottiefiles.com/page/license (accessed 2026-11-11).
- **Limits:** free-plan downloads are **up to 10 public animations
  per month; quota resets at the beginning of each month**
  — https://lottiefiles.com/features/premium-lottie-animations (FAQ
  "Can I use LottieFiles for free?", accessed 2026-11-11). A free
  account is required to download — https://lottiefiles.com/free-animations/gif
  (accessed 2026-11-11). Premium animations are locked behind a paid
  plan (preview still possible); paid plans start at Individual
  $19.99 and Team $24.99 as shown on the pricing page 2026-11-11
  (billing period not shown in the fetched text)
  — https://lottiefiles.com/pricing?via=top_nav (accessed
  2026-11-11). Free public animations may be used commercially on
  any plan — but commercial use of LottieFiles' *services* (work
  created/edited with them) is a Team/Enterprise matter per the
  plan-choosing help page; do not conflate the two
  — https://help.lottiefiles.com/choosing-the-right-plan-for-you
  (accessed 2026-11-11).
- **Use when:** the brief needs an icon useAnimations does not have
  (its 300 cover micro-interface only) and the 10/month download
  limit is acceptable. Prefer useAnimations first — MIT, no account,
  no monthly cap, agent-readable catalog.

### 1.4 Lordicon — large library, attribution required

- **Library:** 49,000+ animated icons, of which 9,700+ are free,
  explorable with no login — https://lordicon.com/ (accessed
  2026-11-11). Free tier is ~20% of the whole library
  — https://lordicon.com/docs/license/free (accessed 2026-11-11).
- **Licence:** free licence based on CC Attribution-NoDerivatives
  4.0 International, modified (download limited to Account
  duration; 1M CDN requests/month for Embed HTML icons)
  — https://lordicon.com/license-terms/archive/v2026-02-26 (archived
  ToS, last edited 2026-03-26, accessed 2026-11-11). **Attribution
  is REQUIRED** for free use: exact link `<a
  href="https://lordicon.com/">Animated icons by Lordicon.com</a>`
  — footer on websites; About page + store description for apps;
  description/credits for YouTube; URL anywhere in documents
  — https://lordicon.com/docs/license/attribution (accessed
  2026-11-11). Free use is allowed in personal AND commercial
  projects, but only with that attribution — same source.
- **Free-tier limits:** ~20% of the library; 1 collection only; no
  bulk download; no sharing collections; 1M CDN requests/month for
  Embed HTML icons; no use as the core of an icon product; no
  standalone resale/redistribution — https://lordicon.com/docs/license/free
  (accessed 2026-11-11).
- **Formats:** Lottie JSON (default), GIF, MP4, WebP, APNG, PNG, SVG,
  plus AEP/MOGRT source files — https://lordicon.com/ ;
  https://lordicon.com/docs/customization-formats (accessed
  2026-11-11). Colours, stroke, speed, size and animation state
  (Intro/Hover/Morph/Loop, etc.) are customisable on the site before
  download, and also via `<lord-icon>` attributes / CSS variables
  — same sources.
- **Agent route:** `npm install @lordicon/element`,
  `import { defineElement } from "@lordicon/element"; defineElement();`
  then `<lord-icon trigger="hover" src="/my-icon.json">` with
  `colors` / `stroke` / `speed` / `trigger` attributes; a bundler is
  recommended — https://lordicon.com/docs/web (accessed 2026-11-11).
  Lordicon recommends self-hosting icons and scripts; Embed HTML
  "may not ensure a seamless display"; no uptime guarantee for
  CDN-hosted embeds — https://lordicon.com/terms-of-service (accessed
  2026-11-11).
- **Use when:** the brief needs an icon neither useAnimations nor
  LottieFiles has, AND the build can carry the footer attribution
  link. A build that cannot show the attribution must not use a
  Lordicon free icon. PRO unlocks the full library and removes the
  attribution requirement — but the PRO price was CHƯA ĐỌC on the
  primary pricing page (see §"Do NOT build on"); never print a PRO
  price from this file.

## 2. When to use animated icons — and when not to

### 2.1 When one earns its place

An animated icon consumes dealt-moment budget (§4) but does NOT satisfy
the gate's dealt-moment requirement — the gate counts only
`[data-moment]` sections mounted by moments.js, and an icon is not one,
so a page whose only motion is an icon still carries the gate's
moment-none WARN. It must earn its place like any other effect: it clarifies a state change (a checkmark that
draws itself on success, a menu that morphs on click), it answers a
pointer (a nav arrow that nudges on hover), or it is the loader. One
icon, in one place, doing one job, is the whole use case. The
exercise (`build-notes/w-icons-exercise/`) proves the wiring with
one useAnimations arrow on one CTA — nothing more.

### 2.2 When to use a static icon instead

- The icon never moves in the user's flow (a label, a list marker, a
  decorative glyph): a static SVG is the whole answer. Motion with
  no job is decoration, and decoration is what the high-end bar
  forbids.
- The page already has its 1–2 dealt moments (§4): the icon stays
  static.
- The icon is one of the six useAnimations icons with no static SVG
  and the build needs the SVG fallback (§1.2): pick a different icon.
- The brief is a dashboard or dense app screen: one loader or one
  state-change icon at most; nav icons stay static.

### 2.3 Iconsax — static only, never a free animated-icons source

Iconsax is listed here so the kit never mistakes it for one. Its
**1,000 animated icons are Premium-only**: Getting Started lists
"Accessing the animated icons!" under what requires an account +
Premium subscription; the platform filter reads "Icon Type: Static
or Animated (Premium)" — https://docs.iconsax.io/getting-started ;
https://docs.iconsax.io/features/iconsax-platform (accessed
2026-11-11). Pro prices verified on the pricing page: $9.99/month,
$39.99/annually, $199.99 for life — https://app.iconsax.io/pricing
(accessed 2026-11-11). **Never list Iconsax as a free animated-icons
source.**

As a free STATIC library it is usable: 6,000–7,000 free icons
(official pages disagree — never cite a single exact count), free
icons need NO account — https://docs.iconsax.io/getting-started
(accessed 2026-11-11). Proprietary licence: free use is commercial-OK
with no attribution in final products, but attribution becomes
mandatory in sold/distributed UI kits/templates; no resale /
sublicensing, no redistribution of loose icons (not even modified
ones), derivatives may not be distributed as new icon sets, licences
are non-transferable, single user — https://docs.iconsax.io/license-and-terms/license
(accessed 2026-11-11). An agent must inline Iconsax icons into the
built product, never ship the icon files loose or as a pack. Official
npm integration is "coming soon" — https://app.iconsax.io/pricing
(accessed 2026-11-11) — not a verified channel.

### 2.4 Lottieflow — do not recommend

Lottieflow (Finsweet) is a free Lottie animation library built for
Webflow — "Hundreds of Lottie files", 21 categories incl. arrows,
CTAs, loading indicators, menu navigation icons, scroll prompts;
"Absolutely FREE — Sign up for free once and use it forever"; JSON
download only; a free account is required to download
— https://finsweet.com/lottieflow/index.html ;
https://webflow.com/integrations/lottieflow (accessed 2026-11-11).
**The kit must not recommend it: no licence or terms text exists on
any readable primary page.** The privacy page only says "This Privacy
Policy, together with the Terms and conditions posted on our Website,
set forth the general rules…" but contains no licence terms and no
readable link to a terms page in the fetched text
— https://finsweet.com/lottieflow/legal-bologna/privacy (accessed
2026-11-11). An unreadable licence = do not recommend. Do NOT claim
the Lottie Simple License covers Lottieflow files — it is
LottieFiles' licence. (One Lottieflow-origin animation re-hosted on
LottieFiles is labelled "Free to use under the Lottie Simple License"
— https://lottiefiles.com/free-animation/infinity-symbol-ljC4RTgwh9
— that covers that file on LottieFiles, not the Lottieflow library.)

## 3. Embedding — the kit's single-HTML shape

### 3.1 Preferred route: lottie-web 5.13.0, pinned, SVG renderer, inline animationData

For the kit's single-file build, the verified-preferred route is:

1. **Player: lottie-web 5.13.0 full build, pinned jsDelivr, SVG
   renderer — prescribed, not yet exercised end-to-end in a real
   browser** — `https://cdn.jsdelivr.net/npm/lottie-web@5.13.0/build/player/lottie.min.js`
   — https://useanimations.com/lottie-icons (accessed 2026-11-11),
   which also says "Use the full build (lottie.min.js): the light
   build skips expressions". `loadAnimation` takes `path` or
   `animationData` (mandatory at least one; the two are mutually
   exclusive) and `renderer` (default is svg; "svg has the most
   features") — https://github.com/airbnb/lottie-web ;
   https://github.com/airbnb/lottie-web/wiki/loadAnimation-options
   (accessed 2026-11-11). Example: `lottie.loadAnimation({
   container: element, renderer: 'svg', loop: true, autoplay: true,
   path: 'data.json' })` — same sources.
2. **Icon data: inline the useAnimations JSON as `animationData`**
   — paste the JSON object into a `<script>` block and pass it as
   `animationData`: no fetch, no external file, no CORS dependency.
   `animationData` takes "an Object with the exported animation
   data" and is mutually exclusive with `path`
   — https://github.com/airbnb/lottie-web (accessed 2026-11-11).
   useAnimations icons are "shape layers only: no images, fonts or
   external assets" — https://useanimations.com/lottie-icons
   (accessed 2026-11-11) — so inlining one icon's JSON is
   self-contained. If an animation contains repeaters and
   `loadAnimation` is called multiple times with the same animation
   object, deep-clone the object before passing it
   — https://github.com/airbnb/lottie-web (accessed 2026-11-11).
   **Offline vendoring (exercise-proven for the vendored variant
   only).** The canonical route is the pinned CDN URL above —
   prescribed, not yet exercised end-to-end in a real browser: no CDN
   load has been recorded in this environment, so the exercise proves
   the vendored variant only, not the CDN route. In a build
   environment whose browser cannot reach any CDN, the same pinned
   file may be vendored locally at the same version instead: the
   animated-icons exercise (`build-notes/w-icons-exercise/`) downloads
   `https://cdn.jsdelivr.net/npm/lottie-web@5.13.0/build/player/lottie.min.js`
   (305,704 bytes, md5 cf10acbee2ab923a5245681550a9dd0d, version
   string "5.13.0" present in the file, fetched 2026-11-11) as
   `node_modules/lottie-web-5.13.0.min.js` beside the page, because
   the sandbox browser failed the CDN load with
   ERR_TUNNEL_CONNECTION_FAILED and the gate's assets check fails an
   unloadable script. Vendoring is a same-version stand-in for the
   CDN, not a different player — and the file stays beside the
   exercise page, never in the public repo's vendored tree. Vendoring
   rule: record the pinned URL + md5 + version string (done above for
   this file); the vendored player is lottie-web, MIT-licensed
   (Copyright (c) 2015 Bodymovin —
   https://raw.githubusercontent.com/airbnb/lottie-web/master/LICENSE.md,
   accessed 2026-11-11), and an OSV query for lottie-web 5.13.0 (npm)
   returned no known vulnerabilities (https://api.osv.dev/v1/query,
   accessed 2026-11-11). Known gap, not a technique: the gate's
   security stage does not scan files under `node_modules/`, so a
   vendored player there receives no licence scan, no CVE scan and no
   pin/lockfile check from the gate — placing it there does not make
   it verified, and must never be presented as a way to pass the
   gate. A vendored player must never be edited in place:
   re-download the pinned file instead.
   Caveat, stated plainly: this inline route was verified at the
   API-documentation level in the verification pass; the exercise
   (`build-notes/w-icons-exercise/`) is the kit's first end-to-end
   render of it — of the vendored variant — see its report for the
   render proof.
3. **Why SVG renderer:** lottie-web's SVG renderer "writes the
   colors as attributes, so a CSS rule on the paths recolors the
   icon" — https://useanimations.com/lottie-icons (accessed
   2026-11-11). That is what preserves `currentColor` theming: the
   icon picks up text colour, hover states and dark mode on its own
   (§1.2). The player cost is roughly 60–75 kB gzip — secondary
   measurements only, no primary bundle-size figure was read; say
   "roughly 60–75 kB gzip (secondary measurements; verify against
   the pinned build)", never an exact figure
   — https://uithings.com/lottie-animations ;
   https://iamvector.com/blog/svg-vs-lottie-animation (secondary,
   accessed 2026-11-11).
4. **Interaction: wire it manually.** "lottie-web plays and stops,
   but the interactions are up to you." — https://useanimations.com/lottie-icons
   (accessed 2026-11-11). Hover = `mouseenter` → `play()`; click-toggle
   = `setDirection` + `play()`; loop/autoplay only for loaders. Copy
   the per-icon `snippet` from `icons.json` rather than inventing
   one — https://useanimations.com/icons.json (accessed 2026-11-11).
   The exercise uses the arrow-right snippet's shape (hover-replay,
   `playSegments([0, totalFrames], true)` on `mouseenter`, gated on
   reduced motion).
5. **Licence notice beside the inlined JSON (mandatory).** Copy the
   licence notice into a comment beside the inlined JSON — for
   useAnimations, `Copyright (c) 2018-2026 useAnimations` plus the MIT
   permission notice; for LottieFiles, a `Lottie Simple License`
   notice naming the source file. Inlining a JSON file into a shipped
   HTML file is a copy of a substantial portion of it, and the MIT
   notice belongs with the copy. A footer line saying only "MIT
   licensed" is not a substitute for the notice.

### 3.2 dotLottie-wc — LottieFiles' current web component, not for a single micro-icon

"LottieFiles now recommends the dotLottie Player, exposed on the web
as the `<dotlottie-wc>` custom element. It's built on top of the new
@lottiefiles/dotlottie-web runtime and works with both classic Lottie
JSON and the newer .lottie format."
— http://lottiefiles.com/blog/working-with-lottie-animations/how-to-add-lottie-animation-in-web-page-html
(updated 3 Dec 2025, accessed 2026-11-11). Attributes: `src`,
`autoplay`, `loop`, `speed`, `mode` (`forward` / `bounce`),
`backgroundColor`, `segment`, `marker`, `animationId`, `themeId`,
`stateMachineId` — same source. Pinned example (from useAnimations,
not `@latest`): `<script type="module"
src="https://cdn.jsdelivr.net/npm/@lottiefiles/dotlottie-wc@0.10.0/dist/dotlottie-wc.js"></script>`
then `<dotlottie-wc src="https://useanimations.com/icons/loading.json"
autoplay loop style="width: 48px; height: 48px"></dotlottie-wc>`
— https://useanimations.com/lottie-icons (accessed 2026-11-11).

**Do NOT use it for a single micro-icon in a single HTML file.**
Two verified reasons: (a) WASM cost — "DotLottie.preload() starts
the WASM download (~500 KB compressed) before any player is
constructed." — https://docs.lottiefiles.com/en/runtimes/distributions/js/v0.x/api/reference
(accessed 2026-11-11); the WASM engine dwarfs a 2 kB icon. (b)
Canvas colour loss — "LottieFiles' player renders with a
WebAssembly engine to a canvas and plays plain Lottie JSON as well
as .lottie files. A canvas keeps the colors of the file, so the
icons stay black unless you recolor the JSON."
— https://useanimations.com/lottie-icons (accessed 2026-11-11).
dotLottie-wc does not recolor with `currentColor`. Use it only when
the build genuinely needs .lottie / WASM features — never as the
default icon player. Its `src` is documented only as a URL; the
verified inline route is the `DotLottie` JS API (`data`: "Animation
data as a Lottie JSON string, an ArrayBuffer for .lottie files, or a
pre-parsed JSON object") — https://docs.lottiefiles.com/en/runtimes/distributions/js/v0.x/api/reference
(accessed 2026-11-11) — not the bare `<dotlottie-wc src=…>` tag. No
reduced-motion handling was found in the dotLottie docs read — wire
it manually, same as lottie-web (§3.4).

### 3.3 Lordicon element

`npm install @lordicon/element`,
`import { defineElement } from "@lordicon/element"; defineElement();`
then `<lord-icon trigger="hover" src="/my-icon.json">` with `colors`
(`"primary:#ff0000,secondary:#00ff00"`), `stroke`
(light/regular/bold), `speed` (default 1), `trigger`
(in/click/hover/loop/loop-on-hover/morph/boomerang/sequence),
`target`, `state`, and CSS variables `--lord-icon-primary` /
`--lord-icon-secondary`; a bundler (Webpack/Rollup) is recommended
— https://lordicon.com/docs/web (accessed 2026-11-11). This is a
bundled-app route, not the kit's single-HTML shape: use it only when
the project already has a bundler. Self-host the JSON files;
Lordicon recommends self-hosting over CDN embeds (§1.4). The CDN
script routes (`cdn.lordicon.com/lordicon.js`, the jsDelivr
self-contained build) are secondary sources only — not verified on
lordicon.com itself; do not present them as Lordicon-documented.

### 3.4 Reduced motion + fallback (mandatory, not optional)

- **Reduced motion is manual in plain HTML.** lottie-web does NOT
  handle it automatically. The verified pattern (useAnimations'
  own lottie-web snippets): `const motion =
  matchMedia('(prefers-reduced-motion: reduce)'); …
  a.goToAndStop(0, true); if (!motion.matches) a.play();` and
  `motion.addEventListener('change', …)`; click-toggle variant: `if
  (motion.matches) a.goToAndStop(isOn ? 0 : a.totalFrames - 1, true);
  else { a.setDirection(…); a.play(); }`
  — https://useanimations.com/lottie-icons ;
  https://useanimations.com/icons.json (accessed 2026-11-11).
  "prefers-reduced-motion does not pause Lottie. Wire matchMedia,
  skip autoplay, and goToAndStop the last frame."
  — https://uithings.com/lottie-animations (secondary, accessed
  2026-11-11). The React component, by contrast, handles this
  internally (§1.2) — plain HTML does not.
- **Fallback: render the static SVG in the container first, replace
  on `DOMLoaded`, keep it on load error.** No player documentation
  read describes an automatic poster/fallback image when the JSON
  fetch fails — the kit must implement that itself (e.g. render the
  static SVG in the container first, replace it on `DOMLoaded` /
  `load`, keep it on error). The static SVG per state is the vendor's
  stated fallback — "The SVG files are still images of the icon at
  rest … for places where nothing should move: emails, documents,
  design tools or a no-JavaScript fallback."
  — https://useanimations.com/ (accessed 2026-11-11). Reduced-motion
  still: `goToAndStop(0, true)` shows frame 0 — https://useanimations.com/icons.json
  (accessed 2026-11-11); or the last frame for toggles
  (`goToAndStop(totalFrames - 1)`) — https://useanimations.com/lottie-icons
  (accessed 2026-11-11). Do not claim any player "shows a poster on
  failure" — no such behaviour was found in any doc read. The error
  branch is exercised, not merely present: the exercise
  (`build-notes/w-icons-exercise.md`, fix 2026-11-11) records a live run
  with the player script blocked — the static SVG stays in the DOM.

### 3.5 BANNED — never emit

- **NEVER use `@lottiefiles/lottie-player` / `<lottie-player>`.**
  Deprecated: "older tutorials … used the lottie-player web
  component. LottieFiles has deprecated that player and recommends
  the @lottiefiles/dotlottie-wc web component instead"
  — https://www.dreamhost.com/blog/add-lottie-animations/ (accessed
  2026-11-11); "LottieFiles now recommends the dotLottie Player"
  — http://lottiefiles.com/blog/working-with-lottie-animations/how-to-add-lottie-animation-in-web-page-html
  (accessed 2026-11-11). Compromised: "@lottiefiles/lottie-player
  2.0.5, 2.0.6 and 2.0.7 on 2024-10-30 … Sites loading the 'latest'
  build from CDNs like unpkg and jsDelivr showed a wallet-connect
  popup that tried to drain visitors' crypto wallets. LottieFiles
  unpublished the versions and released 2.0.8, a copy of 2.0.4."
  — https://pwn.watch/t/supply-chain ;
  https://cybernoz.com/supply-chain-attack-targets-javascripts-lottie-player/
  (both accessed 2026-11-11).
- **NEVER emit any `@latest` CDN URL — always pin exact versions.**
  The rule follows directly from the incident above. Pinned in this
  file: lottie-web 5.13.0
  (`https://cdn.jsdelivr.net/npm/lottie-web@5.13.0/build/player/lottie.min.js`),
  dotLottie-wc 0.10.0
  (`https://cdn.jsdelivr.net/npm/@lottiefiles/dotlottie-wc@0.10.0/dist/dotlottie-wc.js`).
  Do not copy the LottieFiles blog's `@latest` dotLottie-wc URL.
  (dotLottie-wc 0.11.1 was listed on npm.io as published 1 week ago
  — https://npm.io/package/@lottiefiles/dotlottie-wc — but its
  release notes / changelog were CHƯA ĐỌC; do not claim 0.11.1 is
  safe without reading them.)

## 4. The RESTRAINT RULE

An animated icon is an effect that consumes dealt-moment budget but
does NOT satisfy the gate's dealt-moment requirement: the gate counts
only `[data-moment]` sections mounted by moments.js, and an animated
icon is not one — a page whose only motion is an icon still carries
the gate's moment-none WARN. **At most 1–2 animated icons per
build — a button, a nav item, a loader, a state
change — never a page of bouncing icons.** The page total is 1–2 dealt
moments across ALL sources (scroll patterns + GetLayers effect +
animated icons); a page that already has a scroll dealt moment may
carry at most one icon, and a page with a GetLayers effect may carry
none; a second icon needs a calm section between the two icons'
sections and neither may sit in the back third. An animated icon must earn
its place like any other effect; each counts as one unit of the page's
1–2 dealt-moment budget under the scroll-motion restraint rules
(`references/style-recipes/scroll-motion.md` — at most 1–2 dealt
moments per page, one moving thing per viewport, transform/opacity
only, reveals once and short, reduced motion, mobile calmer). Naming
an icon source never exempts its icon from the bar.

Concretely:

- One animated icon per build is the default. A second is allowed
  only when the two icons' sections are separated by a calm section,
  per restraint rule 1 — never two icons animating in the same
  viewport at the same time, and never either icon in the back third
  of the page.
- Loop only loaders. A looping icon anywhere else is a second dealt
  moment that never stops dealing — it reads as gaudy, not alive.
  (Scroll-motion restraint rule 4 now reads "nothing loops except a
  hero video or a loader icon".)
- Hover/click icons play once per trigger and stop. No icon
  autoplays on page load except a loader.
- Mobile is calmer: treat hover icons as static on touch; do not rely
  on hover there. The static SVG fallback is the mobile experience,
  not a degraded one.
- Prefer the static SVG whenever nothing needs to move (§2.2). The
  restraint rule is a cap, not a quota: most builds need zero
  animated icons.

## High-end bar fit — verdict (2026-11-11)

Judged against the kit's high-end bar (workflow.md §1): the loop aims
at an 8/10 human feel — refined and high-end, motion + 3D as plus
points, neither bland nor gaudy. **Verdict: FITS — when used as one
restrained micro-moment; the gaudiness risk sits entirely in
quantity, and the RESTRAINT RULE (§4) is what keeps it on the right
side.**

What was observed:

- **The useAnimations set reads high-end by construction.** One
  stroke style, 24/32 px grid, `currentColor` theming, 1–14 kB
  files, 2 kB median — the icons are drawn to disappear into the
  interface, not to be looked at. A hover arrow that nudges once is
  the same shape as the kit's "one hero moment" direction: one small
  behaviour, restrained, functional.
- **The exercise used it that way.** The animated-icons exercise
  (`build-notes/w-icons-exercise/`, one useAnimations arrow-right on
  one CTA, gate green — see `build-notes/w-icons-exercise.md`)
  used the icon as the page's one unit of dealt-moment budget:
  hover-replay, plays once, stops, static SVG first, reduced-motion
  still. The icon does not satisfy the gate's dealt-moment
  requirement — the exercise page carries a moment-none WARN for
  exactly that reason; the icon consumes budget, it does not deal a
  gate-counted moment. The
  icon changed one button's behaviour; it did not become the build.
- **The licence position supports the bar.** MIT (useAnimations) and
  the Lottie Simple License (LottieFiles) both permit commercial use
  without attribution, so a restrained icon costs the build nothing
  in footer clutter — unlike Lordicon, whose mandatory attribution
  link is a visible cost the brief must be willing to pay.

What was NOT observed: no animated-icon build has been graded by the
judge or the human yet. This verdict is about the sources' positioning,
the verified file sizes and theming, and the exercise's taste lock —
not about rendered output at scale.

Where it risks gaudiness (restraint applies):

- **Quantity is the whole risk.** One icon is a moment; three
  looping icons is a toy. The §4 cap (1–2 per build, loop only
  loaders) is the entire defence — there is no subtler version of
  it.
- **A LottieFiles library icon transplanted without curation.**
  LottieFiles' 800,000+ combined library contains loud, illustrative
  animations that are not micro-icons. An icon picked from it must
  be judged as a micro-icon (small, single-stroke, one job) or it
  breaks the bar no matter how free it is.
- **Lordicon attribution as visual noise.** A footer attribution
  link on a minimal page is a second visual element the design did
  not ask for. If the brief cannot carry it, use useAnimations
  instead.

Restraint that already covers this (no new rule needed beyond §4):
the scroll-motion restraint rules (at most 1–2 dealt moments per
page, one moving thing per viewport, reduced motion, mobile calmer),
and the §2.2 rule to prefer the static SVG whenever nothing needs to
move. An animated icon that needs more than 1–2 dealt moments to
read as itself does not fit the bar — drop it.

## Do NOT build on

- **LottieFiles:** a free-only library total (e.g. "800,000 free
  animations") — 800,000+ is free + premium combined; no free-only
  total is published. A single premium-library total — the site says
  "650,000+" on the premium page and "1 Million+" on the pricing
  page. "50 downloads/day", "5 files / 20 MB free workspace", or
  "10 lifetime uploads" — none verified on a primary page (the
  50/day figure belongs to Mosso). A Lottie Creator free-export
  number — search-result text for the Creator page says both 5 and
  50; the page itself was not opened. "No resale of
  original files" as a term of the Lottie Simple License — the
  licence text read does not say that; its verified restrictions are
  share-alike on redistribution and no collecting/compiling to build
  a competing service. A fully offline single self-contained HTML
  file with the current `<dotlottie-wc>` player — its `src` is
  documented only as a URL; inline JSON is verified only for the
  legacy `lottie-player`. `lottie-web` being deprecated, or
  `@dotlottie/player-component` being the current recommendation —
  not verified on a primary LottieFiles page. Individual ($19.99)
  covering commercial work — per the plan-choosing help page,
  commercial use of LottieFiles services needs Team/Enterprise; only
  the free public animations themselves are commercially usable on
  any plan. Downloads working without an account — the GIF FAQ says
  a free account is all you need. The search-snippet count 5,931 as
  the live count — the live page read 5,929.
- **Lordicon:** PRO costing "$8/month billed annually" (or
  "$99/year") as verified — the primary pricing page was unreadable
  by text fetch; secondary-corroborated only. "154 free / 849 total
  icons" or any figure from SpotSaaS/Techimply/SaaSworthy — stale
  May-2026 snapshot. Webflow's "9,100 free / 37,300 PRO" split —
  conflicts with the live homepage. "Unlimited icon collections"
  for PRO (contradicted by the "10 collections" bullet on the same
  page). A single self-contained HTML file embed — not verified on
  any primary page. The legacy `cdn.lordicon.com/lordicon.js` embed
  or the jsDelivr self-contained build as Lordicon-documented —
  secondary sources only. The Embed HTML export being available to
  new users, or closed in Aug 2026 — secondary only (Webflow).
  "No download limit" on the free plan — secondary only. dotLottie
  export — CHƯA ĐỌC on primary. The API PRO price ($149/month) as
  the website PRO subscription price — the API plan is separate.
  The free licence's positive permission list as read — it is an
  image on the free-licence page; commercial use on the free tier is
  verified only via the attribution page's "personal or commercial
  projects" sentence. Every format being free for every icon —
  per-icon PRO gating in the editor was not tested.
- **Lottieflow:** files being licensed for commercial use, needing no
  attribution, or being redistributable/resold — no primary licence
  text was read. The Lottie Simple License covering Lottieflow files
  — it is LottieFiles' licence. dotLottie, GIF, SVG, MP4, a CDN, an
  API, or an npm package — none stated on any primary page read (and
  the Webflow guide explicitly says Lottieflow has no API). "Free
  with no account" — a free account is required to download. Do NOT
  claim either site was "fully" verified beyond the pages listed
  above — the Iconsax JS app gallery and the Lottieflow
  explore/download pages were not rendered (text fetch only; no
  login, no account, no download performed).
- **Iconsax:** animated icons being free — they are Premium-only.
  Icons being MIT-licensed or open source — the icon licence is
  proprietary; MIT tags belong to community wrapper code. Iconsax
  allowing redistribution or resale of icons (loose, packed, or
  modified) — both are expressly forbidden. Team-plan prices or
  daily download limits — not read. The MCP server, `iconsax` npm
  package, or `npx iconsax sync` as verified official agent channels
  — third-party claims only. A single exact icon count — official
  pages disagree (6,000 vs 7,000 free; 40,000+ vs 44,250 total;
  category totals 70 vs 32+47).
- **useAnimations / embedding:** the icons being CC BY 4.0,
  attribution-required, or barred from redistribution/resale in
  templates — that is the stale pre-v3 text (Design Atlas
  2026-09-25; DeepWiki licence page; 208-day-old search cache of the
  licencing URL). The raw repo `LICENSE` file — READ 2026-11-11 (see
  §1.2): MIT text, Copyright (c) 2018-2026 useAnimations, no CC BY
  text, in the repo and in `react-useanimations@3.1.1` on npm. "79 icons" or "87 icons" — v2-era counts; the verified
  current count is 300. `react-useanimations` still depending on
  lottie-web, or working on React <18 — v3 removed the lottie-web
  dependency and requires React 18+. A precise lottie-web gzip size
  (e.g. "60 kB") as a primary fact — only secondary measurements of
  ~60–75 kB were found. dotLottie-wc respecting
  `prefers-reduced-motion` natively, or accepting inline JSON via a
  `data` attribute — neither was found in the docs read. Any player
  showing a poster/static fallback automatically when the JSON fetch
  fails — no such behaviour was found; the fallback must be
  implemented by the kit. A numeric per-page icon cap or measured CPU
  cost — no primary doc read states one. The single-file inline build
  having been tested/rendered (in the verification pass) — the
  mechanism was verified from API docs only; the exercise is the
  first end-to-end render. The contents of `llms.txt` or
  `documentation.md` — CHƯA ĐỌC.

## Deliberately excluded (do not re-add without a council vote)

- Lottieflow as a recommended source (unreadable licence).
- Iconsax as a free animated-icons source (animated icons are
  Premium-only); Iconsax stays in this file only as a static library
  with its Premium-only animated tier flagged.
- Any Lordicon PRO price printed as verified.
- Any single exact Iconsax icon count.
- Any use of `@lottiefiles/lottie-player` / `<lottie-player>` or any
  `@latest` CDN URL in a build.
- dotLottie-wc as the default icon player (WASM cost + canvas colour
  loss); it stays documented only for builds that genuinely need
  .lottie / WASM features.
- Any claim that the icons are CC BY 4.0. (The raw repo `LICENSE`
  file's contents have now been read — MIT, see §1.2 — so the old
  exclusion of any such claim no longer applies.)
