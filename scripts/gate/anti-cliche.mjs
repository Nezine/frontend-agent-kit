#!/usr/bin/env node
// anti-cliche.mjs — P1 script-checkable anti-cliché seed checks.
//
// The anti-cliché blocklist (skills/frontend-kit/references/anti-cliche.md)
// is a step-1 reference the builder reads. Two of its items are
// mechanically checkable, so they run here, inside gate.sh leg 1:
//
//   AC-1  Aggressive purple -> pink -> blue gradient — the "tech vibe"
//         formula the training data converged on. A gradient whose stops
//         draw on two or more of the purple / pink / blue hue families.
//   AC-2  Emoji as icon substitute — emoji characters in the page text
//         where an icon belongs.
//
// Everything else on the blocklist (left-border accent cards, SVG-drawn
// imagery, CSS silhouettes for real product imagery, cyber-neon on
// #0D1117, fabricated stats / fake logo walls / dummy testimonials,
// overused display faces) is a judgement: it lives in anti-cliche.md as
// a step-1 / step-4 checklist item, and the overused-font half is already
// enforced by `impeccable detect`'s overused-font list.
//
// SEEDED, not observed: these two checks are a labelled seed list from
// garden-skills `web-design-engineer` (SKILL.md "Avoid AI-Style Clichés"
// table, read in full 2026-11-10, commit 08150e75, MIT). They did NOT
// grow from an observed failure in this kit's probe builds. The gate
// grows only from observed failures (P8's gate-growth rule governs);
// this seed list is the exception, labelled as such in every finding,
// and a seeded item that never fires on a real build is a candidate for
// removal, not for promotion.
//
// WAIVER (the only legitimate exception, per garden-skills): "the brand
// spec uses it". A finding is waived only when the project's
// design/TASTE.md hard rules explicitly allow that item, written as a
// line containing `allow` and the item id, e.g.
//   Anti-cliche allow: AC-2 (the brand uses emoji throughout its product)
// Waivers are printed, never silent, and the orchestrator records them
// in the run log. The script reads TASTE.md itself; there is no flag
// to waive a finding from the command line, so a waiver always leaves
// a trace in the project's own taste file.
//
// Usage:
//   node anti-cliche.mjs <page.html> [<page2.html> ...] [--project <dir>]
//   (gate.sh passes the built pages and --project <project-dir>.)
// Exit codes: 0 = clean (or only waived findings); 1 = an unwaived
// finding (FAIL — blocks the round, like any leg-1 finding); 2 = usage
// error. Findings are printed in full, never summarised. Node, no deps.

import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

function usage(msg) {
  if (msg) console.error(`anti-cliche: ${msg}`);
  console.error('usage: node anti-cliche.mjs <page.html> [<page2.html> ...] [--project <dir>]');
  process.exit(2);
}

const argv = process.argv.slice(2);
let projectDir = null;
const pages = [];
for (let i = 0; i < argv.length; i++) {
  if (argv[i] === '--project') {
    if (argv[i + 1] === undefined) usage('--project needs a value');
    projectDir = argv[++i];
  } else if (argv[i].startsWith('--')) {
    usage(`unknown argument: ${argv[i]}`);
  } else {
    pages.push(argv[i]);
  }
}
if (pages.length === 0) usage('at least one .html file is required');
for (const p of pages) {
  if (!existsSync(p)) usage(`page file does not exist: ${p}`);
}
if (!projectDir) projectDir = process.cwd();
projectDir = path.resolve(projectDir);

// --- waiver: TASTE.md hard rules explicitly allowing an item --------------
const allowed = new Set();
const tastePath = path.join(projectDir, 'design', 'TASTE.md');
if (existsSync(tastePath)) {
  for (const line of readFileSync(tastePath, 'utf8').split('\n')) {
    if (/allow/i.test(line)) {
      for (const m of line.matchAll(/AC-[12]/g)) allowed.add(m[0]);
    }
  }
}

// --- AC-1: purple/pink/blue gradient ---------------------------------------
const HUE_FAMILIES = {
  purple: /\bpurple\b|violet|#8b5cf6|#a855f7|#c084fc|#7c3aed|#6d28d9/i,
  pink: /\bpink\b|fuchsia|magenta|#ec4899|#db2777|#d946ef|#e879f9/i,
  blue: /\bblue\b|#3b82f6|#2563eb|#6366f1|#4f46e5|#60a5fa/i,
};

// --- AC-2: emoji in page text ----------------------------------------------
const EMOJI_RE = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]/u;

let fails = 0;
let waived = 0;

function report(id, file, lineNo, detail, waivable) {
  const tag = `ANTI-CLICHE ${id} (SEEDED from garden-skills, not an observed failure)`;
  if (allowed.has(id)) {
    waived += 1;
    console.log(`${tag} WAIVED: ${file}:${lineNo}: ${detail} — TASTE.md explicitly allows ${id}`);
  } else {
    fails += 1;
    console.log(`${tag} FAIL: ${file}:${lineNo}: ${detail}${waivable ? ' — waive only if the brand spec uses it (TASTE.md hard rule: "Anti-cliche allow: ' + id + '")' : ''}`);
  }
}

// Collect the CSS a page actually uses: inline <style> blocks plus local
// linked stylesheets (relative hrefs that resolve beside the page).
function pageCss(pageAbs) {
  const html = readFileSync(pageAbs, 'utf8');
  const chunks = [];
  for (const m of html.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/gi)) chunks.push(m[1]);
  for (const m of html.matchAll(/<link[^>]*rel=["']stylesheet["'][^>]*href=["']([^"']+)["']/gi)) {
    const href = m[1];
    if (/^(https?:|data:|\/\/)/i.test(href)) continue;
    const cssPath = path.resolve(path.dirname(pageAbs), href.split('?')[0].split('#')[0]);
    if (existsSync(cssPath)) chunks.push(readFileSync(cssPath, 'utf8'));
  }
  return { html, css: chunks.join('\n') };
}

for (const page of pages) {
  const pageAbs = path.resolve(page);
  const { html, css } = pageCss(pageAbs);

  // AC-1: every gradient declaration drawing on >= 2 hue families.
  const cssLines = css.split('\n');
  cssLines.forEach((line, idx) => {
    for (const m of line.matchAll(/[a-z-]*gradient\s*\([^;}{]*\)/gi)) {
      const decl = m[0];
      const families = Object.keys(HUE_FAMILIES).filter((f) => HUE_FAMILIES[f].test(decl));
      if (families.length >= 2) {
        report('AC-1', page, idx + 1, `gradient uses ${families.join(' + ')}: ${decl.slice(0, 120)}${decl.length > 120 ? '…' : ''}`, true);
      }
    }
  });

  // AC-2: emoji in visible text (script/style blocks and comments stripped).
  const text = html
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ');
  text.split('\n').forEach((line, idx) => {
    const m = line.match(EMOJI_RE);
    if (m) report('AC-2', page, idx + 1, `emoji '${m[0]}' in page text (use a real icon or a placeholder, not an emoji as an icon)`, true);
  });
}

if (fails > 0) {
  console.log(`ANTI-CLICHE RESULT: FAIL (${fails} unwaived finding(s)${waived ? `, ${waived} waived via TASTE.md` : ''}) — fix the build; a seeded finding is still a finding.`);
  process.exit(1);
}
console.log(`ANTI-CLICHE RESULT: PASS (no unwaived findings${waived ? `; ${waived} waived via TASTE.md` : ''})`);
process.exit(0);
