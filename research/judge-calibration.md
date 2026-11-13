# Judge calibration — one shared pass (P9 + P14, E8)

There is ONE calibration pass, not two: P9 and P14 share it. It is the
precondition for P6 (triggers consume judge scores), P11 (pairwise), P13
(carried-score abolition) and P14 (jury). It measures, and only it
measures, judge–human agreement.

**Status: judge side complete 2026-11-10; human OVERALL grades landed
2026-11-11 (6/10 for all 3 builds); human per-axis grades still pending.**
Until the human per-axis grades land, no per-axis agreement rate and no
per-axis overshoot can be computed — the tables below carry the judge's
side only, and the computation section is a template.

## Gold set — the 3 probe builds

The 3 builds of the briefs in `tests/clean-env/probe-briefs.md`
(briefs 1–3, pasted verbatim). Each was graded in its final gate-green
form. Paths are relative to the repo root for kit files and to
`.tmp-probe4-projects/` (probe working area, not shipped) for builds.

| # | Build | Brief | Built page | Tokens | Taste lock | Chosen DESIGN.md | Build screenshots | Locked reference shot |
|---|-------|-------|-----------|--------|-----------|------------------|-------------------|----------------------|
| 1 | Fifteen — language-learning landing page | Probe brief 1 (landing page) | `.tmp-probe4-projects/brief1-landing/index.html` | `brief1-landing/design/tokens.css` | `brief1-landing/design/TASTE.md` | `brief1-landing/design/references/DESIGN.md/claude.md` | `brief1-landing/design/screenshots/{1440,768,390}-full.png` | `brief1-landing/design/references/ref-1-claude.png` — claude.com, captured 2026-11-10 21:33:40 +07, sha256 `91ab3eb8dc325a097976b1df5762b66f2084e0a2edeac73d0228e6786ec5a72a` |
| 2 | Hilltop Grocery — shop-owner dashboard | Probe brief 2 (dashboard) | `.tmp-probe4-projects/brief2-dashboard/index.html` | `brief2-dashboard/design/tokens.css` | `brief2-dashboard/design/TASTE.md` | `brief2-dashboard/design/references/DESIGN.md/linear.md` | `brief2-dashboard/design/screenshots/{1440,768,390}-full.png` | `brief2-dashboard/design/references/ref-1-linear.png` — linear.app, captured 2026-11-10 21:34:26 +07, sha256 `9844726e81be8984d8a47275f265e1950d5993c649b53b5ab2c1bf2f48f88e97` |
| 3 | Alex Nguyen — portfolio homepage | Probe brief 3 (portfolio) | `.tmp-probe4-projects/brief3-portfolio/index.html` | `brief3-portfolio/design/tokens.css` | `brief3-portfolio/design/TASTE.md` | `brief3-portfolio/design/references/DESIGN.md/vercel.md` | `brief3-portfolio/design/screenshots/{1440,768,390}-full.png` | `brief3-portfolio/design/references/ref-1-vercel.png` — vercel.com, captured 2026-11-10 21:34:43 +07, sha256 `d57e1a98506a1038d25c4848817dd7b2fd034cad9ccfc998aefcde1f23a7827f` |

**Reference shots are post-hoc captures.** No reference screenshots
existed at lock time — the lock was against the vendored DESIGN.md
analyses, and the live-site capture step failed then
(`ERR_TUNNEL_CONNECTION_FAILED`). The shots above were captured after
the builds, from the same locked sites, downscaled to 720px long edge
per P12. They are labelled post-hoc, never claimed to exist at lock
time. Both judge and human grade against the same shots, so the pairing
stays valid.

**Live-site drift (shot vs vendored analysis).** The judge graded
against the shot, and recorded where shot and analysis disagree:
- Build 1: shot headline "Question what's next" (analysis: "Meet your
  thinking partner"); shot hero is a photo (analysis: dark product
  mockup); shot CTA is a dark button (analysis: coral CTA).
- Build 2: shot's prominent CTA is a white inverse "Sign up" pill
  (analysis's primary is lavender); shot hero is screenshot-led with an
  app sidebar (build is type-led with a chart mock); shot has one tall
  empty band inside the hero.
- Build 3: shot headline "Agentic Infrastructure" (analysis: "Build and
  deploy on the AI Cloud."); no mesh gradient is visible in the shot
  although the analysis calls it "the entire decorative system" —
  whether that is the current design or a blocked asset was NOT
  verified; shot hero is a horizontal three-part composition (analysis:
  stacked hero-band); shot has a logo strip the build lacks.

## Judge's blind grades (complete 2026-11-10)

Each build was graded by a separate fresh judge sub-agent
(`judge-subagent`, fresh context, no production history of its build),
on D8-whitelisted inputs only: built page + tokens.css + TASTE.md +
chosen DESIGN.md + build screenshots 1440/768/390 + the locked
reference shot + brief-type scope + the single bit `gate: green`. No
judge received the run log, gate logs/findings, earlier scores, the
builder's reasoning or identity, or any other build. Gate: green on all
three. No judge stated a slop-free % (the 60% human-eye bar is the
human's instrument, not the judge's).

| Build | Type | Layout | Colour | Space |
|-------|------|--------|--------|-------|
| 1 — Fifteen landing | 4 | 3 | 4 | 3 |
| 2 — Hilltop dashboard | 4 | 3 | 4 | 3 |
| 3 — Alex Nguyen portfolio | 4 | 3 | 4 | 3 |

Evidence (one line per score, transcribed below; the judges' full reports were filed only in the probe working area `.tmp-probe4-projects/`, which was not shipped and has since been wiped, so the full evidence lines are no longer available):

- **Build 1.** Type 4: H1 Newsreader roman 64px/−0.03em vs ref 1's
  roman serif; H1 line 1 cut at the right edge at 390 (ink x=1→389).
  Layout 3: four sections, each exactly 100svh, 5/7 splits consistent
  vs ref 1; zero side gutter below 1240px, content flush to both edges
  at 768/390. Colour 4: canvas #faf9f5, ink #141413, functional coral
  #a9583e on one CTA per screen vs ref 1; bright #d97757 repeats in
  mocks while ref 1's coral is only the tiny spike mark and its CTA is
  dark; contrasts recomputed, match tokens.css. Space 3: desktop gaps
  209/239px inside the 128–288px band; 0px side gutter at 390/768
  (expected 20px). Fix order: add a 20px side gutter to `.wrap` below
  1240px — one change clears Layout, Space, and the Type deduction.
- **Build 2.** Type 4: H1 IBM Plex Sans 600 48px/−0.02em, body
  16px/1.55, mono 12px labels vs ref 1; 7-day chart labels render ~4px
  and unreadable at 390. Layout 3: scan order right (Revenue first, 4
  stat cards, chart, table, low stock); every section
  `min-height: 100svh` + 96px padding — a landing rhythm, not ref 1's
  dense product-UI density, on a dashboard; "Ground coffee" row wraps
  "Order today" at 390. Colour 4: canvas #010102, surface #0f1011,
  lavender #5e6ad2 scarce vs ref 1; body 14.28:1, mute 7.93:1,
  white-on-accent 4.70:1, all pass AA; green "up %" / amber status text
  departs from ref 1's near-monochrome. Space 3: dead bands over the
  128–288px band between every section at 1440, larger at 768/390.
  Fix order: Layout then Space — one shared fix (remove
  `min-height: 100svh`, cut section padding toward the 96px token).
- **Build 3.** Type 4: H1 IBM Plex Sans 600 48px/−0.05em,
  sentence-case period-terminated, body 16px/1.5 max 68ch, mono 12px
  eyebrows + 13px code vs ref 1; readable at all 3 widths. Layout 3:
  hero stacks vertically vs ref 1's horizontal hero; nav section links
  vanish entirely at 768/390 with no hamburger; content flush to the
  edge at 768/390. Colour 4: ink #171717 on #fafafa, body #4d4d4d
  8.10:1, mute #525252 7.49:1, white-on-ink CTA 17.93:1, dark band
  #d4d4d4 on #171717 12.09:1 vs ref 1; red/amber/green terminal dots add
  colour absent from ref 1's pure monochrome. Space 3: 96px section /
  32px card padding per tokens, but `min-height: 100svh` + fixed 320px
  project mocks leave ~40% empty black below the last terminal line in
  every mock at all 3 widths, plus a large empty white band below the
  footer legal line at 1440. Fix order: Layout first (restore nav
  ≤820px + side gutter), then Space (drop 100svh minimums + fixed
  320px mock height).

**Observed pattern (not a verdict):** all three builds score 4/3/4/3 —
Type and Colour at 4, Layout and Space at 3, on every build. The shared
deductions are the `100svh` section minimums (all three builds), the
missing phone gutter (builds 1 and 3), and dead empty bands (all
three). Whether this is judge consistency or a real property of the
builds is what the human side will test.

## Human's blind grades (PER-AXIS PENDING — overall landed 2026-11-11)

### Human's overall grades (landed 2026-11-11)

The human graded all 3 builds **6/10 overall** — by feel, not as an
expert (recorded 2026-11-11 11:49–11:50). His target is 8/10: not slop
AND beautiful/refined, with motion and 3D as plus points, like the
Anthropic/Apple sites he sent — refined and high-end, "not bland, but
not gaudy". The judge's mean across the 4 axes is 3.5/5 on every build
((4+3+4+3)/4), i.e. ≈7/10 — so **the judge runs ~1 point hot versus
his feel**. This is an overall-only comparison: no per-axis human
scores were given, and none are invented here — the per-axis table
below stays BLANK until he grades per axis.

| Build | Human overall | Judge mean (4 axes) | Gap (judge − human, ≈/10) |
|-------|---------------|---------------------|---------------------------|
| 1 — Fifteen landing | 6/10 | 3.5/5 (≈7/10) | ≈ +1 |
| 2 — Hilltop dashboard | 6/10 | 3.5/5 (≈7/10) | ≈ +1 |
| 3 — Alex Nguyen portfolio | 6/10 | 3.5/5 (≈7/10) | ≈ +1 |

The human grades the same 3 builds once, on the same 4 axes, blind to
the judge's scores above — do not read this file's judge table before
grading. One evidence line per score, plus a 60% slop-free verdict per
build (yes/no + one line). The grading packet (build screenshots +
reference shots + blank table) is kept with the coordinator's working
notes, not in the repo.

| Build | Type | Layout | Colour | Space | ≥60% slop-free? |
|-------|------|--------|--------|-------|-----------------|
| 1 — Fifteen landing | _ | _ | _ | _ | _ |
| 2 — Hilltop dashboard | _ | _ | _ | _ | _ |
| 3 — Alex Nguyen portfolio | _ | _ | _ | _ | _ |

## Computed agreement (PENDING — template until the human per-axis grades land)

The landed overall grades (6/10 for all 3 builds) do NOT enable this
computation — it needs per-axis human scores, which are still pending.
Computed per axis: exact-match rate, within-1 rate, and mean signed
overshoot (`judge − human`, in points). Plus overall exact/within-1.
Cohen's κ is NOT computed at n=12 (unstable) — only when the sample
reaches n≥32.

| Axis | Exact-match | Within-1 | Mean signed overshoot (judge − human) |
|------|-------------|----------|---------------------------------------|
| Type | _ / 3 | _ / 3 | _ |
| Layout | _ / 3 | _ / 3 | _ |
| Colour | _ / 3 | _ / 3 | _ |
| Space | _ / 3 | _ / 3 | _ |
| **Overall (n=12)** | _ / 12 | _ / 12 | _ |

## Decision taken under (a)–(c)

- **(a)** If mean signed overshoot on any axis is ≥ +1.0pt (judge
  systematically overshoots), the rubric's anchor descriptions for
  that axis are rewritten to the human's anchors immediately,
  regardless of sample size — a bias fix, not a threshold vote.
- **(b)** The 80% Layout/Space agreement threshold is REPORT-ONLY
  until the sample reaches n≥30 paired scores (council member A) /
  n≥32 (council member B) — at n=12, one score flips 83% to 75%, so
  the threshold cannot govern the stop rule. Between n=30 and n=31 the
  two counts disagree; until n≥32 treat the threshold as report-only.
- **(c)** Only at n≥32, if Layout/Space agreement is <80%, does the
  judge stop gating the stop rule — and the consequence is then: the
  stop requires a human grade (the human gate carries the
  certification, which it already does as the final step), recorded per
  build. In buffet mode this does not park the run: the loop still runs
  to the human gate, which is where the human already is.

Decision: _pending human grades._

## What this pass does NOT measure

Pairwise keep/discard agreement, jury agreement, agreement on any
brief outside the 3 probes, or the human–human agreement ceiling
(unknown — the 80% headline from Zheng et al. is for open-ended chat
preference and does not transfer to design).
