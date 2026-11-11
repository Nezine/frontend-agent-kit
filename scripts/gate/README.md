# scripts/gate/ — vendored gate scripts

## Files

| File | Origin | What it does |
|---|---|---|
| `detect.mjs` | Kit-authored | Wrapper around `impeccable detect` (resolves `impeccable` on PATH, else the installed launcher under `~/.agents/skills/impeccable/scripts/`; NEVER downloads — no detector found exits 3 with the install command, probe G-9b); prints detector output unabridged, exits with the detector's exit code (0 clean, 2 findings, 1 unscannable). Warns up front on a directory target: directory mode is regex-only, findings undercount (N7) |
| `gate.mjs` | Kit-authored | Runs `copy-lint.mjs` + `consistency.mjs --quick` on one LOCAL `.html` file and prints every finding in full; exit 0 green, 1 FAIL, 2 usage/checker error. URLs are rejected (copy-lint reads files only — N3); `--out <dir>` redirects the consistency crops/report (default: a fresh folder under the OS temp dir, never inside the project — probe G-7); `--profile` is the Chrome profile dir, not output. `--kind <software\|service\|product\|place>` is forwarded to consistency as `--page` and decides which checks fire (notably `product-shown`, physical products only). `gate.mjs` has no `--self-test` (unlike `gate.sh`); test it manually with `node gate.mjs <page.html> --skip-browser` (copy-lint + page security subset only; exit 2 is the fail-closed skipped-browser leg, not a pass) |
| `gate.sh` | Kit-authored | The deterministic gate, LEG 1 of 2 (leg 2 is `gate.mjs`; a gate pass needs BOTH legs green — see "Gate scope" below). Taste lock + per-file `impeccable detect` + static checks (viewport, no file:// links, local refs resolve, per-section visual-marker proxy) + anti-cliché seed checks (§3c, P1) + token-naming lint (§3d, P17) + converge check (§5, P2, when `design/PLAN.md` exists) + optional validators. Excludes `design/variants/`, `design/demo.html`, `design/v0.html`, and `.taste-skill/` from project-dir scans. Exit 0 pass, 2 findings/fail, 1 usage error |
| `anti-cliche.mjs` | Kit-authored (P1) | Script-checkable anti-cliché seed checks: AC-1 (purple-pink-blue gradient) and AC-2 (emoji as icon) over the built pages + their local CSS. SEEDED from garden-skills, not observed failures; waived only by an explicit `Anti-cliche allow: AC-<n>` hard rule in `design/TASTE.md`. Exit 0 clean (or only waived), 1 findings, 2 usage error. Node, no deps |
| `lint-tokens.mjs` | Kit-authored (P17) | Token-naming lint for the P19 naming contract: T1 kebab-case token names, T2 no primitive references in component CSS, T3 on-* text role for every `--color-*` used as a background, T4 colour roles alias primitives, never literals. Runs on the built pages + `design/tokens.css`. Exit 0 clean, 1 findings (gate FAIL), 2 usage error. Node, no deps |
| `converge-check.mjs` | Kit-authored (P2) | Script half of the converge check: every id in PLAN.md's section inventory exists in the built HTML; every non-N/A cell of the screen × state matrix names a file that exists or an `#id` that exists. Uncheckable cells are listed, never silently passed. Findings carry their PLAN.md row as `<plan>:<line>:` (M3). Exit 0 converged, 1 missing (FAIL — blocks the grade and the human gate), 2 usage error. Node, no deps |
| `consistency.mjs` | Vendored, taste-skill 2.5.1, + three documented kit patches | Headless-Chrome checker: overflow / collide / tap-size, section height, one-section-per-screen, rhythm, and more. 11,485 lines. Node 22+ (built-in WebSocket) + system Chrome, no npm deps |
| `copy-lint.mjs` | Vendored verbatim, taste-skill 2.5.1 | Static copy linter: residue, old slop words, stock phrases, device budgets. 463 lines. Node, no browser, <1s. Exit 0 no FAIL, 1 FAIL, 2 usage/unreadable |

Provenance (VERIFIED): vendored from the local taste-skill 2.5.1 clone at
`~/workspace/report-design-council-20261109/sources/taste-skill/`
(tag `v2.5.1`, HEAD `f6b7657`), `skills/taste-skill/scripts/`. Licence: see
the taste-skill tree (MIT).
- `copy-lint.mjs` is byte-identical to that clone (diff clean, re-checked
  2026-11-10) — no kit edits.
- `consistency.mjs` is vendored verbatim EXCEPT three documented kit patches
  (N4 — the old "byte-identical … except nothing" claim was stale):
  (1) the `--no-sandbox` patch. Upstream spawns Chrome directly
  (`consistency.mjs` L4620–4626 in the clone: `spawn(exe, [...])`); the kit
  file (`scripts/gate/consistency.mjs` L4620–4630) builds a `chromeArgs`
  array and pushes `'--no-sandbox'` only when `process.geteuid() === 0`,
  because Chrome refuses to run as root without it — never for normal
  users (the sandbox stays on for them).
  (2) the dead-band ceiling patch (2026-11-10, probe 3 + judge W-JUDGE-2).
  Upstream's SR-3 T-gap PASS band was 128–480px at desktop widths and its
  per-width `section-gaps` loop flagged only deviation from the page's own
  median — so a page whose gaps were ALL dead (brief 1: 297/350/398px,
  brief 3: 350/371px at 1440, measured first-hand) passed the gate while
  the independent judge failed all three pages on the same voids. The kit
  file tightens the desktop T-gap band to 128–288px (WARN band 64–288px;
  the phone band 112–420px is unchanged) and adds an absolute FAIL to the
  `section-gaps` loop: any content-to-content gap over 288px at vw ≥ 1024
  FAILs as a dead band (288px = 1.5× the token-consistent gap of 2×96px
  section padding). Scoped to desktop widths because below 1024px gaps
  inflate with the viewport (F-3). Every changed line is marked
  `KIT PATCH` in the file, and the checker's own `what`/`fix` strings state
  the new band.
  (3) the hero-fill desktop-scope patch (2026-11-10, F-3, probe 3).
  Upstream's `heroFill()` fires at every sweep width, including the 768 and
  820 tablet widths — where it is mutually exclusive with the section-gaps
  rule for a short-content hero: a 100svh hero leaves ~500px of empty
  bottom that the gap check reads as a spacing decision (brief 3: 520px,
  +67% FAIL at 768), while a content-height hero lets the next section peek
  onto the first screen (hero-fill FAIL). The kit file returns early when
  `vw < 1024`, so hero-fill fires only at desktop widths; below 1024px the
  hero's height follows its content (doctrine §4) and the peek is normal
  tablet/phone UX. Those three patches are the ONLY kit edits to the file.
`consistency.mjs` optionally reads `../assets/moments/index.json` (two
`try/catch` reads); the file is absent here, so those reads fail silently
and the checker runs without the moments data. That is upstream behaviour,
not a kit patch.

What was NOT vendored, and why: taste-skill's own `gate.mjs` (891 lines) is
a state machine around `.taste-skill/build.json`, `start.mjs` markers, and
`assets/layout/check.mjs` — it cannot run without the full taste-skill tree.
The kit's `gate.mjs` is a fresh, thin wrapper for the single-run gate the
orchestrator needs. If a project installs the full taste-skill 2.5.1 tree,
its `gate.mjs` remains the finish gate; this kit's `gate.mjs` is the
portable equivalent for hosts that only have the kit.

## Finding format (M3, 2026-11-10)

Every gate finding that knows its location prints it as
`<file>:<line>: <message>` — the line is read from the file, never
guessed. A finding about a whole file (no single line) prints as
`<file>: <message>`, with no invented line number.
- `gate.sh` §3 (static checks): a missing local reference fails as
  `<page>:<line>: referenced file missing: <ref>` — the line is the
  line of the `src`/`href` attribute in the page.
- `converge-check.mjs`: every FAIL carries its PLAN.md row as
  `<plan>:<line>:` — the 1-based line of the inventory/matrix row the
  finding is about (a dropped section points at its inventory row; a
  bad matrix cell points at its matrix row).
- `anti-cliche.mjs` (P1): already printed `<file>:<line>` — unchanged.
- `lint-tokens.mjs` (P17): prints `<file>:<line>` for every finding
  (token definition lines in `design/tokens.css`, declaration lines in
  the built pages).
- NOT converted, deliberately: `copy-lint.mjs` is vendored verbatim
  (byte-identical to taste-skill 2.5.1 — editing it breaks provenance,
  and its findings are computed on joined block text, so no line
  numbers exist in its data); `consistency.mjs` is vendored + three
  documented patches (a format change there is out of scope); `detect.mjs`
  prints the upstream detector's output unabridged, which is not the
  kit's to reformat.

## Gate scope (`gate.sh` — F6, F15, N7; fixed 2026-11-10)

- **THE GATE IS TWO LEGS (reconciled 2026-11-10, probe 2).** Leg 1 is
  `gate.sh`; leg 2 is `gate.mjs`. A gate pass needs BOTH legs green on the
  same build. A `gate.sh` PASS alone is only leg 1 — probe 2's brief-1 build
  passed leg 1 and failed leg 2 (53 FAIL / 26 WARN), and the loop correctly
  stopped: the legs check different things (detect's 62 slop/quality rules
  vs the checker's layout/copy rules) and a disagreement means the build
  is not green. Never lower a gate to green a bad page; fix the build.
- **What the checker demands is taught** in
  `skills/frontend-kit/references/layout-doctrine.md` (SR-1–SR-8, overlay
  nav, section fill ≥55% or merge, visuals ≥25% per section, page-kind
  table, decorative-vs-functional accent). The scope that is NOT taught but
  scoped out lives in `gate.mjs`'s header, in `frontend-kit/SKILL.md`
  step 3, and in `references/grader-rubric.md` — all three.
- **Artifact pollution is fixed two ways (probe G-7).** `gate.mjs`
  defaults consistency's `--out` to a fresh folder under the OS temp dir,
  never inside the project; `gate.sh` ALSO excludes `.taste-skill/` from
  every scan, so a checker's own `rendered.html` can never fail the next
  `gate.sh` run. Re-run `gate.sh` twice in a row to prove it.
- **Visual-marker static check (probe 2 tightening).** `gate.sh` fails a
  built page that has `<section>` elements but no real visual marker
  (`<img>`, `<picture>`, `<video>`, `<canvas>`, or `[data-ui]` mock).
  Small inline SVG icons do not count. Static proxy only: per-section
  ≥25% coverage is measured by leg 2 in the browser. Fires on project-dir
  scans only — never on the single-file demo target, never on a page with
  no sections (verify.sh / self-test fixtures).
- **Dead-band ceiling (2026-11-10, probe 3 + judge W-JUDGE-2).** Section
  gaps are 128–288px at desktop widths; a content-to-content gap over 288px
  at vw ≥ 1024 FAILs `section-gaps` as a dead band (kit patch in
  `consistency.mjs`: T-gap band + loop ceiling). The old 480px ceiling
  passed brief 1's 297/350/398px and brief 3's 350/371px gaps at 1440 while
  the independent judge failed all three pages on the same voids — and
  fill ≥55% does not catch them either (brief 1's sections fill 56–67%).
  Below 1024px the ceiling does not apply: gaps inflate with the viewport
  there (F-3), and the structural hero-height rule governs instead.
- **Phone gutter (F-2/F-9, 2026-11-10).** Below the 1240px container
  breakpoint `.wrap` carries 20px side MARGINS (not padding — the checker
  reads the container from the `.wrap`'s box). Without them text touches
  the screen edges below 1248px (x=0 at 390px in all three probe builds;
  brief 1's hero clips mid-glyph at 390). The nav lives in the same
  `.wrap` with no extra padding; the probe's `.nav-wrap { padding: 0 25px; }`
  fix is superseded. Mid-glyph ink clipping at the edge is caught by the
  step-4 eyes, not by any box-based check (doctrine §8).
- **Text-only mocks are bands (F-5, 2026-11-10).** A `[data-ui]` mock on
  its own ground that holds only text FAILs `one-section` as a band at
  desktop widths — give it a small svg in its header bar (or mark it
  `[data-visual]`, or use `<pre>` for terminal text). The svg is
  load-bearing for the gate, not decoration.
- **Non-file schemes are exempt from leg 1's ref check (F-1, 2026-11-10).**
  `mailto:`, `tel:`, `javascript:`, `data:`, `#anchors` and `http(s):` are
  not file references; a legitimate `mailto:` CTA never fails `gate.sh` as
  "referenced file missing". Exactly those schemes are exempt, no others.
- **Viewport-driven gaps (F-3, 2026-11-10).** The gap check measures
  content-to-content air including a 100svh section's empty bottom, so at
  tablet widths a short-content 100svh section inflates the gap (brief 3:
  hero/projects 520px, +67% FAIL at 768; about/footer 492px at 820 — the
  398px is section#about's empty bottom, measured, not the footer's top).
  The fix is structural: below 820px NO section is 100svh
  (`section, footer.closing { min-height: 0; }`), so every section's height
  follows its content. Cutting the meeting paddings is a workaround, not
  the fix — and it masks the footer gap by holding the median up. At tablet widths hero-fill and
  section-gaps are mutually exclusive with short hero content (proven:
  100svh hero FAILs the gap, content-height hero FAILs hero-fill), so
  `hero-fill` is scoped to vw ≥ 1024 in `consistency.mjs` (kit patch) —
  the peek of the next section is normal tablet/phone UX, the ~500px of
  dead air inside a 100svh hero is the defect. At 1024/1440 the hero stays
  100svh and hero-fill still fires.
- **Taste lock is mandatory (F6).** `gate.sh` FAILS (exit 2) when
  `design/tokens.css` is missing under the project dir — whether or not a
  `design/` dir exists. A project with no taste lock gets no pass. (The
  old check only failed when `design/` existed without `tokens.css`, so a
  project with no `design/` at all passed with `GATE RESULT: PASS`.)
- **Anti-cliché seed checks (P1, 2026-11-10).** `gate.sh` §3c runs
  `anti-cliche.mjs` on the built pages (AC-1 purple-pink-blue gradient,
  AC-2 emoji as icon). SEEDED from garden-skills, not grown from an
  observed failure — the gate grows only from observed failures (P8's
  gate-growth rule governs) and this seed list is the labelled
  exception. A finding still fails the gate. Waived only by an explicit
  `Anti-cliche allow: AC-<n>` hard rule in `design/TASTE.md`, read by
  the script itself; waivers print, never silent. Skipped with a warning
  when node is absent, and never on the demo or v0 single-file targets.
- **Converge check (P2, 2026-11-10).** `gate.sh` §5 runs
  `converge-check.mjs` against every built page when `design/PLAN.md`
  exists under the project dir. BLOCKING: a missing planned section or
  state fails the gate (no grade) and blocks the human gate. Absence of
  PLAN.md skips with a note, never a failure (the verify.sh fixture has
  no plan); skipped with a warning when node is absent (the orchestrator
  then runs the converge checklist by hand before the human gate). Never
  on a variants-dir target or the demo single-file target.
- **`design/v0.html` is excluded from project-dir scans (P1).** The v0
  skeleton carries `[image]` / `[icon]` placeholders and is not the
  deliverable; like `design/demo.html` it is gated explicitly on its own
  file only (`gate.sh --target design/v0.html` as the skeleton gate in
  step 2).
- **A skipped detect is "gate not run", never a pass (F6).** When no
  Impeccable launcher is reachable, `gate.sh` FAILS instead of warning
  and passing on static checks alone. A detect that exits with anything
  other than a completed scan (0 clean, 2 findings, 1 unscannable) fails
  the same way.
- **Scoping decision (recorded): `design/screenshots/` and
  `design/variants/` are NOT required by the gate.** The build loop
  creates them, so their absence is not a gate failure. Templates that
  lack them are a template matter, not a gate matter — only the missing
  `design/tokens.css` fails.
- **Detect scans the build output only (F15).** The detect leg runs
  `impeccable detect` once per built `.html` file, never on a directory:
  the earlier fix (excluding `design/variants/` from the static-check
  `find` only) did not hold, because the detect leg still passed the whole
  project dir to the engine — a discarded variant's slop failed the build
  gate live (cream-palette `[marketing-buzzword]` FAIL on a discarded
  variant). Per-variant gating stays explicit: gate the variants dir
  itself to scan the variants.
- **Directory-mode detect is approximate (N7).** When the detector is
  given a directory it scans with regex matching only; rules that need a
  parsed page do not run, so its findings are an undercount, not a clean
  bill of health (the engine's own words). `detect.mjs` prints that
  warning up front on a directory target; `gate.sh` never runs directory
  mode at all — it detects per built file, which gets the full parsed-page
  rules.
- **Secret-scan allowlist, run-log `tokensHash` only (1.1, 2026-11-11,
  W-LOOP fix).** `gate.sh` runs gitleaks with the kit config
  `scripts/gate/.gitleaks.toml`, which extends gitleaks' defaults
  (`[extend] useDefault = true`) and allowlists ONLY
  `design/run-log.jsonl` — the run log's `tokensHash` sha256 content hash
  trips `generic-api-key`, a false positive that failed the exercise
  probe's version-B leg 1. The scope is path-only on purpose: gitleaks'
  allowlist fields combine with OR (verified against 8.30.1 — a 64-hex
  regex would suppress 64-hex secrets in EVERY file, and no line-context
  AND exists in the mechanism), so no 64-hex regex is in the config; a
  `--config` without `[extend]` would REPLACE the defaults and disable
  every rule, so never ship one without it. Backstop: the built-in 1.1
  grep also scans `design/run-log.jsonl` for the high-confidence patterns,
  so a real secret in the run log still FAILS. Verified 2026-11-11 via
  `gate.sh --security-only` on scratch projects (gitleaks 8.30.1): run log
  with a `tokensHash` line → 1.1 PASS, exit 0; planted fake AKIA key in a
  scratch file → 1.1 FAIL via gitleaks, exit 2; same key planted inside
  `run-log.jsonl` → 1.1 FAIL via the built-in grep, exit 2. Residual hole,
  stated in the config: a generic high-entropy string on a
  non-`tokensHash` line in the run log, matching neither built-in pattern,
  would be missed by both layers.

## Widths — the rhythm-widths ambiguity, resolved from the code

SYNTHESIS.md §9 carried this open item: "`consistency.mjs` L8 comment lists
rhythm widths without 820 while SKILL.md L261 includes it: resolve by
reading the code default before the kit hardcodes either list."

Resolution (read 2026-11-10, taste-skill 2.5.1 clone):

- **Checker widths** (which viewports are checked at all):
  `1440,1024,820,768,390`. The code default at `consistency.mjs` L4506 is
  `opt('widths', '1440,1024,820,768,390')`; the usage line (L5), the header
  comment (L73), SKILL.md L261, and the README table (L147) all agree.
  This is what `gate.mjs` passes as `--widths`.
- **Rhythm widths** (which viewports the section-rhythm rules run at):
  the CODE default is `1440,768,390` — flag definition at L1852
  (`default: '1440,768,390'`, "the widths the section-rhythm rules run at
  (written for 1440x900 and 390x844; 768x1024 is the tablet width, run by
  default)"), the fallback at L1859, and the usage lines (L8, L4542) all
  say `1440,768,390`. SKILL.md L261's invocation
  (`--rhythm-widths 1440,820,768,390`) adds 820, but that is the SKILL's
  invocation, not the code default — and L1772/L1800 explain the rules are
  written for 1440x900 / 768x1024 / 390x844, so an 820 rhythm run applies
  rules tuned for other viewports.
- **Decision:** `gate.mjs` defaults `--rhythm-widths` to the code default
  `1440,768,390` and `--widths` to `1440,1024,820,768,390`. The flag can
  still be overridden per run; the override is recorded nowhere silently —
  the command line is printed in the gate output.

## Training regression corpus

The deterministic gate consumes ASVS 5.0.0 requirement IDs (`v5.0.0-x.y.z`, L1 floor / L2 for auth/PII/money/secrets) as its pass/fail checklist, the XSS/DOM-XSS cheat sheets as its sink rules, and the 77 ground-truth training cases in `research/security-ai/training/ground-truth.md` (25 code pairs, 24 agent-loop cases, 28 supply-chain/licence/ToS cases) as its regression corpus — the gate's own tests must run them. Training cases only: the 20 held-out cases are sealed, checker-only, and never enter the gate's tests.

**Status: ASSEMBLED — awaiting dedicated red-team verification before delivery. Do not use for graduation until the red team passes it.** The training material is wired in, but GRADUATION USE IS BLOCKED until the package passes its dedicated red-team verification (still owed — open item).

## Requirements

- Node 22+ (`consistency.mjs` throws if `WebSocket` is not built in).
- System Chrome for `consistency.mjs` (it searches standard install paths
  including `/usr/bin/google-chrome`, `/usr/bin/chromium`, snap Chromium).
  **No system Chrome (probe G-3):** when the kit-installed Playwright
  chromium exists, the browser leg runs with `CHROME_PATH` pointed at it:
  `CHROME_PATH=$HOME/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`
  — the path is `chrome-linux64`, not `chrome-linux`.
- `copy-lint.mjs` needs neither: it runs anywhere Node runs.
- `detect.mjs` needs the Impeccable CLI (`impeccable` on PATH or the
  installed launcher under `~/.agents/skills/impeccable/scripts/`); it
  never downloads anything (probe G-9b).

## Browser network (probe G-2 — environmental, not a kit gap)

In this sandbox the browser has no usable network even though curl works:
direct egress is blocked (direct curl fails, exit 35) and the only way out
is the authenticated egress proxy in the `*_PROXY` env vars. Chrome DOES
read those vars — with them set it fails `ERR_TUNNEL_CONNECTION_FAILED`,
with them unset the error changes to `ERR_SSL_PROTOCOL_ERROR` — but the
tunnel fails because the proxy demands auth Chrome cannot supply
headlessly: there is no CLI flag for a proxy password, and embedding
credentials in `--proxy-server` is rejected (`ERR_NO_SUPPORTED_PROXIES`).
Passing proxy env through to the browser launch therefore does NOT fix it
(Chrome already reads the env). Consequence, and the kit's standing
degradation: live reference screenshots (step 0.2) and webfonts fall back
to vendored DESIGN.md files and system fonts in this environment; the
browser leg still runs on local files. On a normal machine with direct
internet none of this bites. A local auth-forwarding proxy (127.0.0.1
forwarder adding Proxy-Authorization from env) could in principle fix it;
it is NOT built here — it would handle a runtime credential, is VM-only,
and is out of scope for the gate reconciliation (see
`build-notes/w-fix-gates.md`).

## Verified behaviour (2026-11-10, this VM, Node v24.22.1)

- `node --check` passes on all four scripts.
- `copy-lint.mjs` on a slop page ("Revolutionary solution that unlocks
  seamless synergy", "Elevate your workflow") exits 1 with
  `FAIL copy-slop-word`; on a clean page exits 0 with `0 FAIL, 0 WARN`.
  Findings are printed, not summarised.
- `consistency.mjs` could NOT be run end-to-end here: no system Chrome is
  installed on this VM. Its syntax check passes and its Chrome-discovery
  paths were read, but a live run is CHƯA ĐỌC — the clean-env test must run
  `gate.mjs` on a machine with Chrome before the gate is claimed working.
- `detect.mjs` HAS been run end-to-end here (2026-11-10, engine 0.1.21
  warmed in a scratch HOME): on a single `.html` file it exits 0 with no
  warning; on a directory it prints the N7 undercount warning up front
  and the engine itself reports "2 files scanned with regex matching
  only (.css) … findings are an undercount". `gate.sh` on the F15
  fixture (broken discarded variant, no viewport meta, dangling CSS ref)
  PASSes the project root (exit 0) and FAILs the variants dir (exit 2);
  on a project with no `design/` dir and an empty HOME it FAILs (exit 2,
  F6) instead of the old `GATE RESULT: PASS`.
- `gate.mjs` URL/dir rejection (N3) verified 2026-11-10: a URL target
  exits 2 with the copy-lint-ENOENT explanation; a directory target exits
  2; a clean local file with `--skip-browser` exits 2 (copy-lint only —
  fail-closed, H13: a skipped browser leg is never a green gate).
- `detect.mjs` (probe-2 fix, verified 2026-11-10): with `impeccable` not on
  PATH and the installed launcher present, it uses the launcher (exit 0,
  no download, no npx message); with no launcher anywhere it exits 3
  with the install command.
