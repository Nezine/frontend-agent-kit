#!/usr/bin/env node
// gate.mjs — the frontend-kit deterministic gate (step 3, gate leg 2).
//
// Runs the vendored taste-skill-style checks on one page and PRINTS every
// finding in full — never summarised. Exit non-zero on any FAIL: a FAIL
// blocks the round and no vision round is spent until the gate is green.
//
// THE GATE IS TWO LEGS, BOTH REQUIRED (reconciled 2026-11-10, probe 2):
// leg 1 is gate.sh (taste lock + impeccable detect + static checks) and
// leg 2 is this file (copy-lint + consistency browser leg). A "gate pass"
// means BOTH legs green on the same build. A gate.sh PASS on its own is
// only leg 1 — it never means the gate passed. The two legs check
// different things by design (detect's 62 slop/quality rules vs the
// checker's layout/copy rules); when they disagree, the build is not
// green, the gate is — fix the build, do not pick the greener leg.
//
//   1. copy-lint.mjs (static, no browser, <1s) — copy FAILs: residue, old
//      slop words, stock phrases, budgeted devices used as tics.
//   2. security stage (static, no browser) — the page-level subset of the
//      deterministic Stage 1 checks (synthesis §3): 1.2–1.5 sink greps +
//      1.9 weak crypto, run on the target page file. The FULL Stage 1
//      section (1.1–1.12, incl. secret scan, deps/CVE/licence/headers)
//      runs in gate.sh §6 on the whole project; this leg runs only the
//      checks that are meaningful on a single page, so the two legs never
//      disagree about a verdict neither of them owns. Per-check PASS/FAIL,
//      fail-closed: a sink found here FAILS leg 2. External local scripts
//      are covered by gate.sh §6's project scan.
//   3. consistency.mjs --quick (headless system Chrome via CDP) — overflow /
//      collide / tap-size, section height, one-section-per-screen, at the
//      kit checker widths.
//
// ARTIFACT POLLUTION (fixed 2026-11-10, probe G-7): consistency.mjs writes
// its crops + report.json + rendered.html to --out, defaulting to
// .taste-skill/consistency beside the page — inside the project it gates.
// gate.sh then scanned that rendered.html and failed on the checker's own
// artifact. This wrapper therefore defaults --out to a folder under the OS
// temp dir (never inside the project) unless --out is given explicitly.
// gate.sh ALSO excludes .taste-skill/ from its scan (defence in depth).
//
// SCOPE — what this leg does and does not demand (stated, not silent;
// the same table lives in skills/frontend-kit/SKILL.md step 3 and in
// references/grader-rubric.md, so no future reader re-discovers it):
//   * SR-1–SR-8 layout doctrine (hero-screen, section-height, section-air,
//     one-section, one-heading, container-edges, row-lines, split-pair)
//     APPLIES to landing pages. It is TAUGHT, not assumed: see
//     skills/frontend-kit/references/layout-doctrine.md (one .wrap, no
//     horizontal padding on it at desktop widths and 20px side MARGINS
//     below the 1240px container breakpoint, nav in the same .wrap with no
//     extra padding, 12-column splits with the right column on the shared
//     k=5/6/7 line, overlay nav, section fill >=55% or merge).
//     Dashboards / app screens are scoped OUT of the one-section-per-screen
//     + landing-rhythm checks (brief-type table in SKILL.md step 3).
//   * PHONE GUTTER (F-2/F-9, probe 3 + judge W-JUDGE-2): below 1240px the
//     .wrap carries 20px side margins — without them text touches the
//     screen edges below 1248px (measured x=0 at 390px in all three probe
//     builds; brief 1's hero clips mid-glyph at 390). MARGIN, not padding:
//     the checker reads the container from the .wrap's BOX, so padding
//     leaves the box at the edge while the text sits inside it. The
//     probe's `.nav-wrap { padding: 0 25px; }` fix is SUPERSEDED by the
//     shared 20px edge. No box-based check catches mid-glyph ink clipping
//     at the edge (doctrine §8) — the step-4 eyes catch it.
//   * DEAD-BAND CEILING (judge W-JUDGE-2, kit patch 2026-11-10): section
//     gaps are 128-288px at desktop widths; a content-to-content gap over
//     288px at vw >= 1024 FAILs `section-gaps` as a dead band (the old
//     480px ceiling passed brief 1's 297/350/398px and brief 3's 350/371px
//     gaps at 1440). Fill >=55% does NOT catch dead bands. The ceiling is
//     scoped to desktop widths: below 1024px gaps inflate with the
//     viewport (F-3). Implemented as a documented kit patch in
//     consistency.mjs (T-gap band + section-gaps loop) — see
//     scripts/gate/README.md.
//   * F-3 (viewport-driven gaps): the gap check measures content-to-content
//     air INCLUDING a 100svh section's empty bottom, so at tablet widths a
//     short-content 100svh section inflates the gap (brief 3: hero/projects
//     520px, +67% FAIL at 768; about/footer 492px at 820 — the 398px is
//     section#about's empty bottom, measured, not the footer's top). The fix
//     is structural — below 820px NO section is 100svh
//     (`section, footer.closing { min-height: 0; }`) so every section's height
//     follows its content. Cutting the meeting paddings is a workaround, not
//     the fix — and it masks the footer gap by holding the median up. At tablet
//     widths hero-fill and section-gaps are mutually exclusive with short
//     hero content (proven: 100svh hero FAILs the gap, content-height hero
//     FAILs hero-fill), so `hero-fill` is scoped to vw >= 1024 in
//     consistency.mjs (kit patch) — the peek of the next section is normal
//     tablet/phone UX, the ~500px of dead air inside a 100svh hero is the
//     defect. At 1024/1440 the hero stays 100svh and hero-fill still fires.
//   * F-5 (text-only mocks are bands): a [data-ui] mock on its own ground
//     that holds only text FAILs `one-section` as a band (SR-4 T-dom, >=80%
//     wide, >=48px tall, desktop widths). Give every text-only mock a small
//     svg in its header bar (or mark it [data-visual], or use <pre> for
//     terminal text). The svg is load-bearing for the gate, not decoration.
//   * F-1 (leg 1, gate.sh): mailto:, tel:, javascript:, data:, #anchors
//     and http(s): are NOT file references and are exempt from gate.sh's
//     file-existence check — a legitimate mailto: CTA never fails leg 1.
//     Exactly those schemes are exempt, no others.
//   * no-visual APPLIES to every feature section: a visual covering >=25%
//     of the section — a photograph (<img> with alt) or a [data-ui] UI
//     mock >=120x80px. Small inline SVG icons (32px) do NOT count. For a
//     digital product the app's own UI mock IS the visual; mark it
//     [data-ui] and make it large. Taught in layout-doctrine.md.
//   * product-shown applies ONLY to PHYSICAL-product pages (kind
//     "product"): a page whose brief is a physical thing with client
//     photographs (or a 3D render the brief asks for). It does NOT apply
//     to software / service / app pages — mark those data-type="software"
//     or "service" (gate.mjs --kind / consistency --page) and the check
//     does not fire. A language-learning app marked data-type="product"
//     is a mis-mark, not a product page: fix the kind, do not fake photos.
//     The kit vendors no photo pipeline (no photos.mjs, no
//     assets/objects/product-render): a physical-product brief with no
//     client photographs cannot pass product-shown, and that is a stated
//     kit limit, not a build failure to fix by inventing photos.
//   * CONTRAST / the coral case (probe G-9c): a vendored reference's
//     component that fails the contrast rule is NOT shippable verbatim.
//     Claude's callout-card-coral (white text on coral #d97757, 3.12:1)
//     fails WCAG AA (4.5:1) and the kit's 7:1 body-text rule. The taught
//     rule: copy the reference's LOOK, not its literal component — coral
//     stays DECORATIVE ONLY (brand mark, rule, no text on it); text-bearing
//     surfaces use the darkened functional accent (#a9583e, white 5.06:1,
//     passes AA). The checker (text-contrast) enforces this; the skill
//     teaches it in layout-doctrine.md. Body/muted text keeps the kit's
//     7:1 rule; CTA text passes at WCAG AA 4.5:1.
//
// CHROME (probe G-3): consistency.mjs needs system Chrome; when none is
// installed but the kit-installed Playwright chromium exists, run with
// CHROME_PATH pointed at it:
//   CHROME_PATH=$HOME/.cache/ms-playwright/chromium-*/chrome-linux64/chrome
// Note the path is chrome-linux64, not chrome-linux. See SKILL.md step 3.
//
// BROWSER NETWORK (probe G-2): in this sandbox the browser has no usable
// network even though curl works — the egress proxy needs auth Chrome
// cannot supply headlessly (see build-notes/w-fix-gates.md). That is
// environmental, not a gate failure: the browser leg still runs on local
// files; only live reference screenshots and webfonts degrade (fallbacks).
//
// Usage:
//   node gate.mjs <page.html> [--kind <kind>] [--category "<what is sold>"]
//     [--primary "<main action>"] [--widths 1440,1024,820,768,390]
//     [--rhythm-widths 1440,768,390] [--profile <chrome profile dir>]
//     [--out <dir>] [--json] [--skip-browser] [--root <dir>]
//
// The target is a LOCAL .html file — never a URL, never a directory (N3).
// copy-lint reads files only: it fails a URL with `cannot read
// http://…: ENOENT`, exit 2. Serve the page locally (or download it) and
// pass the file. --profile is the CHROME PROFILE dir consistency.mjs runs
// with (a folder of its own in the OS temp folder or the project's
// .taste-skill folder — a --profile that leads outside the project is
// redirected there by consistency.mjs, with a warning); it does NOT
// redirect output. Output (crops/report) goes to --out <dir> (default:
// .taste-skill/consistency beside the page file) — that is the flag that
// redirects output, and this wrapper passes it through.
//
// --skip-browser runs copy-lint only (for hosts with no Chrome); the report
// then says "browser checks skipped — Chrome unavailable" and the grade rung
// drops accordingly. It never claims the browser checks passed — and it FAILS
// CLOSED (exit 2, H13): a skipped browser leg is never a green gate.
// --json prints each checker's JSON output verbatim, then a one-line verdict.
// --out redirects the consistency crops/report (default: a fresh folder
// under the OS temp dir — never inside the project; see header, G-7).
//
// Exit codes: 0 = gate green, 1 = FAIL in any checker, 2 = usage error or a
// checker could not run (with the exact error printed) — including a skipped
// browser leg (--skip-browser).
//
// Node, no dependencies beyond the vendored checkers + system Chrome.

import { spawnSync } from 'node:child_process';
import { existsSync, statSync, mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// H14 — ONE number, everywhere: Node 22+. consistency.mjs needs the
// built-in WebSocket (Node 22+); running this gate on an older Node fails
// opaquely inside the checker, so fail closed up front with the reason.
const _nodeMajor = Number(process.versions.node.split('.')[0]);
if (!Number.isInteger(_nodeMajor) || _nodeMajor < 22) {
  console.error(`gate: Node ${process.versions.node} found; this gate requires Node 22+ (consistency.mjs needs the built-in WebSocket). Install Node 22+.`);
  process.exit(2);
}

const HERE = path.dirname(fileURLToPath(import.meta.url));
const COPY_LINT = path.join(HERE, 'copy-lint.mjs');
const CONSISTENCY = path.join(HERE, 'consistency.mjs');

// Kit checker widths (VERIFIED — taste-skill 2.5.1 consistency.mjs L5/L73/L4506,
// SKILL.md L261) and rhythm widths (the CODE default — see README.md).
const DEFAULT_WIDTHS = '1440,1024,820,768,390';
const DEFAULT_RHYTHM_WIDTHS = '1440,768,390';

function usage(msg) {
  if (msg) console.error(`gate: ${msg}`);
  console.error(`usage: node gate.mjs <page.html> [--kind <kind>] [--category "..."] [--primary "..."] [--widths ${DEFAULT_WIDTHS}] [--rhythm-widths ${DEFAULT_RHYTHM_WIDTHS}] [--profile <chrome profile dir>] [--out <dir>] [--json] [--skip-browser] [--root <dir>]`);
  process.exit(2);
}

function opt(argv, name, def = null) {
  const i = argv.indexOf(`--${name}`);
  if (i === -1) return def;
  if (argv[i + 1] === undefined) usage(`--${name} needs a value`); // value may start with '--'
  return argv[i + 1];
}

function run(cmd, argv, label) {
  console.log(`\n===== gate: ${label} =====`);
  console.log(`$ ${cmd} ${argv.join(' ')}`);
  const res = spawnSync(cmd, argv, { stdio: 'inherit' });
  if (res.error) {
    console.error(`gate: ${label} could not run: ${res.error.message}`);
    return 2;
  }
  console.log(`----- ${label}: exit ${res.status} -----`);
  return res.status ?? 2;
}

const argv = process.argv.slice(2);
const positional = argv.filter((a) => !a.startsWith('--'));
const page = positional[0];
if (!page) usage('a page file or URL is required');
if (/^https?:\/\//i.test(page)) {
  // N3: copy-lint reads files only — a URL dies inside it with
  // `cannot read http://…: ENOENT`, exit 2. Reject up front with the fix,
  // instead of advertising <page.html|url> and failing obscurely.
  usage(`URLs are not accepted: copy-lint cannot read ${page} (ENOENT, exit 2). Serve the page locally or download it, then pass the local .html file.`);
}
if (!existsSync(page)) usage(`page file does not exist: ${page}`);
if (statSync(page).isDirectory()) {
  // consistency.mjs takes a page file (or a URL); a directory is not a
  // page. Gate one built .html file per run (gate.sh does this per file).
  usage(`a directory is not a page: pass a single built .html file, not ${page}`);
}
if (!existsSync(COPY_LINT) || !existsSync(CONSISTENCY)) {
  console.error('gate: vendored checkers missing from scripts/gate/ (copy-lint.mjs, consistency.mjs). Re-run ./install.sh; do not substitute another checker silently.');
  process.exit(2);
}

const kind = opt(argv, 'kind');
const category = opt(argv, 'category');
const primary = opt(argv, 'primary');
const widths = opt(argv, 'widths', DEFAULT_WIDTHS);
const rhythmWidths = opt(argv, 'rhythm-widths', DEFAULT_RHYTHM_WIDTHS);
const profile = opt(argv, 'profile');
const out = opt(argv, 'out');
const root = opt(argv, 'root');
const asJson = argv.includes('--json');
const skipBrowser = argv.includes('--skip-browser');

let worst = 0;

// 1. copy-lint (static, always runs).
const lintArgs = [COPY_LINT, page];
if (kind) lintArgs.push('--kind', kind);
if (asJson) lintArgs.push('--json');
worst = Math.max(worst, run(process.execPath, lintArgs, 'copy-lint'));

// 2. security stage — page-level deterministic Stage 1 checks (1.2–1.5, 1.9).
// Static, no browser, always runs (including --skip-browser). The full
// Stage 1 section (1.1–1.12) runs in gate.sh §6; this leg runs only the
// checks meaningful on a single page file, with per-check PASS/FAIL
// output, fail-closed: any FAIL here fails leg 2 (worst >= 1).
console.log('\n===== gate: security (Stage 1 page subset: 1.2–1.5, 1.9) =====');
let secPageText;
try {
  secPageText = readFileSync(page, 'utf8');
} catch (e) {
  console.error(`gate: security stage could not read ${page}: ${e.message} — fail closed (exit 2)`);
  process.exit(2);
}
const secLines = secPageText.split('\n');
function secGrepLines(re) {
  const out = [];
  secLines.forEach((line, i) => { if (re.test(line)) out.push(`${page}:${i + 1}: ${line.trim().slice(0, 160)}`); });
  return out;
}
const secFailed = [];
function secCheck(id, passLabel, failLabel, hits) {
  if (hits.length) {
    console.log(`SECURITY ${id}: FAIL — ${failLabel}`);
    for (const h of hits.slice(0, 10)) console.log(`  ${h}`);
    secFailed.push(id);
  } else {
    console.log(`SECURITY ${id}: PASS — ${passLabel}`);
  }
}
// 1.2 — HTML sinks without DOMPurify sanitization (same rule as gate.sh §6:
// a file using DOMPurify.sanitize passes with a note; the per-occurrence
// taint check is checklist territory).
const secSinkHits = secGrepLines(/dangerouslySetInnerHTML|innerHTML\s*=|outerHTML\s*=|document\.write\s*\(/);
if (secSinkHits.length && !/DOMPurify\.sanitize/.test(secPageText)) {
  secCheck('1.2', 'no unsanitized HTML sink', 'HTML sink (innerHTML/outerHTML/document.write/dangerouslySetInnerHTML) without DOMPurify sanitization', secSinkHits);
} else if (secSinkHits.length) {
  console.log('SECURITY 1.2: PASS — page uses an HTML sink but also DOMPurify.sanitize (per-occurrence taint check is checklist territory)');
} else {
  console.log('SECURITY 1.2: PASS — no unsanitized HTML sink');
}
// 1.3 — eval / Function / string timers.
secCheck('1.3', 'no eval / Function / string-timer sink',
  'code-execution sink (eval / new Function / setTimeout|setInterval with a string argument)',
  secGrepLines(/(^|[^A-Za-z0-9_])eval\s*\(|new\s+Function\s*\(|setTimeout\s*\(\s*['"]|setInterval\s*\(\s*['"]/));
// 1.4 — template-interpolated data into a SQL/shell/query call.
secCheck('1.4', 'no template-interpolated data in SQL/shell/query calls',
  'template-interpolated data fed to a code/SQL/shell call — parameterise it',
  secGrepLines(/(\.query|exec|spawn|execSync|spawnSync)\s*\(\s*`[^`]*\$\{/));
// 1.5 — javascript: URLs in href/src/action.
secCheck('1.5', 'no javascript: URL in href/src/action',
  'javascript: URL in href/src/action — allow-list http/https only',
  secGrepLines(/(href|src|action)\s*=\s*['"]javascript:/));
// 1.9 — weak crypto (W-APPSEC BLOCK per synthesis §3; W-OWASP rates it
// WARN — the gate follows W-APPSEC). Math.random() only on lines that
// also name a security use.
const secWeakHits = secGrepLines(/createHash\s*\(\s*['"]?(md5|sha1)['"]?|(^|[^A-Za-z0-9_])MD5\s*\(|(^|[^A-Za-z0-9_])SHA1\s*\(|createCipher\s*\(/)
  .concat(secGrepLines(/Math\.random\s*\(\)/).filter((h) => /token|secret|password|passwd|key|nonce|salt|otp|session|auth|crypt/i.test(h)));
secCheck('1.9', 'no weak crypto (no MD5/SHA1-for-security, no createCipher, no Math.random() for secrets/tokens)',
  'weak crypto (MD5/SHA1 for security, deprecated createCipher, or Math.random() for a secret/token)', secWeakHits);
if (secFailed.length) {
  console.log(`----- security: FAIL (${secFailed.join(', ')}) — full Stage 1 (1.1–1.12) runs in gate.sh §6 -----`);
  worst = Math.max(worst, 1);
} else {
  console.log('----- security: page subset clean (full Stage 1 runs in gate.sh §6) -----');
}

// 3. consistency --quick (needs system Chrome).
if (skipBrowser) {
  // H13 (fail-closed, 2026-11-10): a skipped browser leg used to leave
  // `worst` at 0, so a clean copy-lint exited 0 with a "GREEN" verdict —
  // exit-code consumers (and the orchestrator's own "Exit non-zero means
  // fix" rule) read that as a pass. A gate that did not run its browser
  // leg is NOT green: fail closed with exit 2 (checker could not run),
  // and say so in the verdict. Contrast gate.sh, which already FAILS
  // when its detect leg is skipped.
  console.log('\n===== gate: consistency SKIPPED (--skip-browser) =====');
  console.log('browser checks skipped — Chrome unavailable. This is a degradation: the grade rung drops (see skills/frontend-kit/references/stop-rules.md). It is NOT a pass, and this run FAILS CLOSED (exit 2): a skipped browser leg is never a green gate.');
  worst = Math.max(worst, 2);
} else {
  const cArgs = [CONSISTENCY, page, '--quick', '--widths', widths, '--rhythm-widths', rhythmWidths];
  if (profile) cArgs.push('--profile', profile);
  // Default --out: a fresh folder under the OS temp dir. consistency.mjs
  // defaults --out to .taste-skill/consistency beside the page — inside
  // the project it gates — and gate.sh then fails on the checker's own
  // rendered.html (probe G-7). An explicit --out is honoured as given.
  const outDir = out || mkdtempSync(path.join(tmpdir(), 'taste-skill-consistency-'));
  cArgs.push('--out', outDir);
  console.log(`gate: consistency output goes to ${outDir}${out ? ' (explicit --out)' : ' (default: OS temp dir — never inside the project, probe G-7)'}`);
  if (root) cArgs.push('--root', root);
  if (kind) cArgs.push('--page', kind);
  if (category) cArgs.push('--category', category);
  if (primary) cArgs.push('--primary', primary);
  if (asJson) cArgs.push('--json');
  worst = Math.max(worst, run(process.execPath, cArgs, 'consistency --quick'));
}

console.log(`\n===== gate verdict: ${worst === 0 ? 'GREEN' : 'FAIL (exit ' + worst + ')'}${skipBrowser ? ' — copy-lint only; browser checks were SKIPPED, not passed (fail-closed, H13)' : ''} =====`);
process.exit(worst);
