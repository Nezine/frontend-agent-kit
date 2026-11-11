#!/usr/bin/env node
// lint-tokens.mjs — step-3 gate check for the token-naming contract (P17/P19).
//
// Usage:
//   node lint-tokens.mjs <page.html> [...] --project <dir>
//
// Checks (all findings print as `LINT-TOKENS FAIL: <file>:<line>: <detail>`,
// the M3 gate-output format — a line number is only ever printed when it was
// actually read from that file):
//   T1 kebab-case: every `--name` DEFINED in design/tokens.css must match
//      `--[a-z][a-z0-9]*(-[a-z0-9]+)*` (lowercase, digits, '-' only).
//      Catches `--colorPrimary`, `--color_primary`, `--color.primary`.
//   T2 no-primitive-use: component CSS (the page's <style> blocks and
//      style attributes, plus linked local .css files except tokens.css /
//      primitives.css) must never reference `var(--primitive-...)`.
//      Primitives are the token file's business; pages read semantic
//      roles only (P19 two-layer rule).
//   T3 on-* pairing: every `--color-<name>` used as a `background` /
//      `background-color` value in component CSS must have its
//      `--color-on-<name>` text role DEFINED in design/tokens.css.
//      `on-*` roles themselves are excluded (a text role used as a
//      background is not a surface). Define the on-* role even for
//      decorative surfaces — one line, and it stays correct when text
//      is added later.
//   T4 no-literal-colour-roles: every `--color-*` definition in
//      design/tokens.css must alias a primitive (`var(--primitive-...)`)
//      or another colour role (`var(--color-...)`), never a literal
//      (#hex / rgb() / ...). Type/space/radius/motion roles keep literal
//      values — this check is colour-only, because only colour has a
//      primitive layer in this kit.
//
// Limits (deliberate, documented — not bugs): the scan is line-based,
// so a finding's line is the line the offending declaration starts on.
// A `var(--primitive-...)` inside an HTML comment or text node is
// flagged the same as one in CSS — do not write token references in
// prose. `color-mix()` colour roles are out of scope for v1 (a role
// whose value does not start with `var(` fails T4). `background-image`
// gradients are not treated as surfaces (only `background` /
// `background-color` trigger T3).
//
// Exit codes (mirrors anti-cliche.mjs): 0 clean, 1 findings (gate FAIL),
// 2 could not run (bad args, unreadable tokens.css, missing page).
// The check is skipped by gate.sh (never fatal) when node is absent,
// when the script is missing from the kit install, or when the project
// has no design/tokens.css.

import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname, basename, join } from 'node:path';

const KEBAB = /^--[a-z][a-z0-9]*(-[a-z0-9]+)*$/;
const DEF_SEGMENT = /(--[A-Za-z0-9_-]+)\s*:\s*(.*)$/;
const PRIMITIVE_USE = /var\(\s*(--primitive-[a-z0-9-]+)\s*\)/;
const COLOR_USE = /var\(\s*(--color-[a-z0-9-]+)\s*\)/g;

const args = process.argv.slice(2);
const pages = [];
let project = null;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--project') { project = args[++i]; continue; }
  if (args[i].startsWith('--project=')) { project = args[i].slice('--project='.length); continue; }
  pages.push(args[i]);
}

if (!project || pages.length === 0) {
  console.error('Usage: node lint-tokens.mjs <page.html> [...] --project <dir>');
  process.exit(2);
}

const tokensPath = join(project, 'design', 'tokens.css');
let tokensRaw;
try {
  tokensRaw = readFileSync(tokensPath, 'utf8');
} catch {
  console.error(`LINT-TOKENS: cannot read ${tokensPath}`);
  process.exit(2);
}

// Strip /* ... */ comments, keeping newlines so line numbers stay true.
const tokensStripped = tokensRaw.replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' '));

const findings = [];
const fail = (file, line, detail) => findings.push(`LINT-TOKENS FAIL: ${file}:${line}: ${detail}`);

// --- T1 + T4: definitions in design/tokens.css ---------------------------
const definedColor = new Set();
let tokenCount = 0;
tokensStripped.split('\n').forEach((line, idx) => {
  const lineno = idx + 1;
  // A line may hold several declarations (`:root { --bg: #fff; --ink: #000; }`).
  for (const segment of line.split(';')) {
    const m = segment.match(DEF_SEGMENT);
    if (!m) continue;
    const name = m[1];
    const value = m[2].trim();
    tokenCount++;
    if (!KEBAB.test(name)) {
      fail(tokensPath, lineno, `token '${name}' is not kebab-case (token names are lowercase letters, digits and '-' only)`);
    }
    if (name.startsWith('--color-')) {
      definedColor.add(name);
      if (!value.startsWith('var(')) {
        fail(tokensPath, lineno, `colour role '${name}' holds a literal value '${value}' — colour roles must alias a primitive (var(--primitive-...)) or another colour role (var(--color-...))`);
      }
    }
  }
});

// --- T2 + T3: component CSS in each page (+ linked local .css) -------------
// T3 splits each line into `;`-separated declarations and only inspects
// the VALUE of a `background` / `background-color` declaration — a
// `color: var(--color-ink)` sitting on the same line as a background
// must NOT trigger the pairing rule (that was a v1 bug, caught by test).
const scanCssLines = (file, lines) => {
  lines.forEach((line, idx) => {
    const lineno = idx + 1;
    const prim = line.match(PRIMITIVE_USE);
    if (prim) {
      fail(file, lineno, `component CSS references primitive ${prim[1]} — semantic roles only (see the token-naming contract in skills/frontend-kit/SKILL.md)`);
    }
    for (const segment of line.split(';')) {
      const bg = segment.match(/background(?:-color)?\s*:\s*(.*)$/);
      if (!bg) continue;
      const seen = new Set();
      for (const m of bg[1].matchAll(COLOR_USE)) {
        const name = m[1];
        if (name.startsWith('--color-on-') || seen.has(name)) continue;
        seen.add(name);
        const short = name.slice('--color-'.length);
        const onName = `--color-on-${short}`;
        if (!definedColor.has(onName)) {
          fail(file, lineno, `background uses ${name} but ${onName} is not defined in design/tokens.css — every surface needs its on-* text role`);
        }
      }
    }
  });
};

for (const page of pages) {
  if (!existsSync(page)) {
    console.error(`LINT-TOKENS: page not found: ${page}`);
    process.exit(2);
  }
  const html = readFileSync(page, 'utf8');
  scanCssLines(page, html.split('\n'));
  // Linked local stylesheets (excluding the token files themselves).
  const pageDir = dirname(resolve(page));
  const hrefs = new Set();
  for (const m of html.matchAll(/href\s*=\s*["']([^"']+\.css)["']/g)) hrefs.add(m[1]);
  for (const href of hrefs) {
    if (/^(https?:|data:|mailto:|tel:|javascript:|\/\/)/i.test(href)) continue;
    if (basename(href) === 'tokens.css' || basename(href) === 'primitives.css') continue;
    const cssPath = resolve(pageDir, href);
    if (!existsSync(cssPath)) continue;
    scanCssLines(cssPath, readFileSync(cssPath, 'utf8').split('\n'));
  }
}

if (findings.length > 0) {
  for (const f of findings) console.log(f);
  console.log(`LINT-TOKENS: ${findings.length} finding(s)`);
  process.exit(1);
}
console.log(`LINT-TOKENS: clean (${tokenCount} tokens in ${tokensPath}, ${pages.length} page(s))`);
process.exit(0);
