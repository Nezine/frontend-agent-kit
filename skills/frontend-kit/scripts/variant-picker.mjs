#!/usr/bin/env node
// variant-picker.mjs — the frontend-kit variant picker (step 2a).
//
// Lists the 5 CSS-only variants in <project>/design/variants/ (each variant
// is a folder with its own tokens.css and a screenshot at the same width),
// prints a pick table, and records the human's pick in the run log so the
// pick IS the feedback — never re-argued in prose.
//
// Expected layout (stated here AND in skills/frontend-kit/SKILL.md step 2,
// probe G-6: the skill used to state no layout at all, so a flat layout
// of <name>.html + <name>-tokens.css + <name>-1440.png was rejected):
//   design/variants/<name>/tokens.css
//   design/variants/<name>/screenshot-1440.png   (same width for every variant)
//   design/variants/<name>/index.html            (same content, same copy,
//                                                 same semantic HTML — only CSS changes)
// The five canonical names: editorial, dark, warm-brutalist, glassy, minimal.
// Extra names are listed, not rejected; the human picks one.
//
// Deterministic pick for human-less runs (probe G-5, SKILL.md step 2a):
// `pick --auto` picks the variant whose tokens match the LOCKED
// design/tokens.css most closely — the count of locked `--name: value`
// declarations the variant reproduces exactly; ties broken alphabetically.
// A byte-identical tokens file scores a perfect match. The rule is stated
// BEFORE picking, needs no human, and gives no quality verdict: it only
// says which variant is closest to the locked direction.
// Node, no dependencies. Usage:
//   node variant-picker.mjs --project <dir> list
//   node variant-picker.mjs --project <dir> pick --variant <name> [--note "..."]
//   node variant-picker.mjs --project <dir> pick --auto
//   node variant-picker.mjs --project <dir> check
//
// `check` exits non-zero and names the problem when variants are missing
// tokens, missing screenshots, or differ in content (a rough check: the
// index.html files must be identical except for the linked stylesheet).
// Exit codes: 0 ok, 1 usage error / check failure / unknown variant on pick.

import fs from 'node:fs';
import path from 'node:path';

const CANONICAL = ['editorial', 'dark', 'warm-brutalist', 'glassy', 'minimal'];

function usage(msg) {
  if (msg) console.error(`variant-picker: ${msg}`);
  console.error(`usage:
  node variant-picker.mjs --project <dir> list
  node variant-picker.mjs --project <dir> pick --variant <name> [--note "..."]
  node variant-picker.mjs --project <dir> pick --auto
  node variant-picker.mjs --project <dir> check`);
  process.exit(1);
}

// Parse a tokens.css file into a Map of --name -> value (comments and
// everything outside :root blocks included: token declarations are
// --name: value; wherever they sit in the file).
function parseTokens(file) {
  const map = new Map();
  if (!fs.existsSync(file)) return map;
  const text = fs.readFileSync(file, 'utf8');
  for (const m of text.matchAll(/(--[a-zA-Z][a-zA-Z0-9_-]*)\s*:\s*([^;]+);/g)) {
    map.set(m[1], m[2].trim());
  }
  return map;
}

// Deterministic auto-pick (probe G-5): score each variant by how many of
// the LOCKED design/tokens.css declarations it reproduces exactly
// (same --name, same value). Highest score wins; ties break
// alphabetically (listVariants returns sorted names). A byte-identical
// tokens file scores a perfect match (all locked declarations).
function autoPick(project) {
  const locked = parseTokens(path.join(project, 'design', 'tokens.css'));
  if (!locked.size) usage('pick --auto needs a locked design/tokens.css with at least one --name: value declaration');
  const names = listVariants(project);
  if (!names.length) usage('pick --auto found no variants — generate the 5 CSS-only variants first');
  const scored = names.map((n) => {
    const mine = parseTokens(path.join(variantsDir(project), n, 'tokens.css'));
    let match = 0;
    for (const [k, v] of locked) if (mine.get(k) === v) match++;
    return { name: n, match, total: locked.size };
  });
  scored.sort((a, b) => (b.match - a.match) || (a.name < b.name ? -1 : 1));
  return scored;
}

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      if (key === 'auto') { out[key] = true; continue; } // boolean flag: no value
      // Value flags consume the next token unconditionally: a value may
      // legitimately start with '--' (e.g. a token diff "--color-accent: ...").
      const val = argv[i + 1];
      if (val === undefined) usage(`--${key} needs a value`);
      out[key] = val;
      i++;
    } else out._.push(a);
  }
  return out;
}

function variantsDir(project) {
  return path.join(project, 'design', 'variants');
}

function listVariants(project) {
  const dir = variantsDir(project);
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();
}

function status(project, name) {
  const dir = path.join(variantsDir(project), name);
  const tokens = fs.existsSync(path.join(dir, 'tokens.css'));
  const shot = fs.readdirSync(dir).find((f) => /^screenshot.*\.png$/i.test(f));
  const html = fs.existsSync(path.join(dir, 'index.html'));
  return { tokens, shot: shot || null, html };
}

const args = parseArgs(process.argv.slice(2));
const cmd = args._[0];
if (!args.project) usage('--project <dir> is required');

if (cmd === 'list') {
  const names = listVariants(args.project);
  if (!names.length) { console.log('variant-picker: no variants yet — generate the 5 CSS-only variants first.'); process.exit(0); }
  console.log('variants (same content, same copy, same HTML — only CSS changes):');
  for (const n of names) {
    const s = status(args.project, n);
    const mark = CANONICAL.includes(n) ? '' : ' (non-canonical name)';
    console.log(`  ${n}${mark} — tokens: ${s.tokens ? 'yes' : 'MISSING'}, screenshot: ${s.shot || 'MISSING'}, html: ${s.html ? 'yes' : 'MISSING'}`);
  }
} else if (cmd === 'pick') {
  let name = args.variant;
  if (args.auto !== undefined || (!name && args._.includes('auto'))) {
    // pick --auto: deterministic, no human. (parseArgs consumes the value
    // after --auto as its value, so `--auto` alone is the trigger: any
    // --auto flag, or a bare `auto` positional, means auto-pick.)
    const scored = autoPick(args.project);
    const best = scored[0];
    name = best.name;
    const table = scored.map((s) => `${s.name} ${s.match}/${s.total}`).join(', ');
    const autoNote = `deterministic auto-pick (no human): closest to locked tokens — ${best.match}/${best.total} locked token values reproduced exactly; ties broken alphabetically [${table}]`;
    args.note = args.note ? `${args.note} — ${autoNote}` : autoNote;
    console.log(`variant-picker: auto-pick scores (locked-token matches): ${table}`);
  }
  if (!name) usage('pick needs --variant <name> or --auto');
  const names = listVariants(args.project);
  if (!names.includes(name)) {
    console.error(`variant-picker: unknown variant "${name}" (have: ${names.join(', ') || 'none'})`);
    process.exit(1);
  }
  const log = path.join(args.project, 'design', 'run-log.jsonl');
  fs.mkdirSync(path.dirname(log), { recursive: true });
  fs.appendFileSync(log, JSON.stringify({ kind: 'variant-pick', variant: name, note: args.note || null, at: new Date().toISOString() }) + '\n');
  console.log(`variant-picker: picked "${name}"${args.note ? ` — ${args.note}` : ''}. The pick IS the feedback; build on this variant only.`);
} else if (cmd === 'check') {
  const names = listVariants(args.project);
  const problems = [];
  for (const n of names) {
    const s = status(args.project, n);
    if (!s.tokens) problems.push(`${n}: missing tokens.css`);
    if (!s.shot) problems.push(`${n}: missing screenshot`);
    if (!s.html) problems.push(`${n}: missing index.html`);
  }
  for (const n of CANONICAL) if (!names.includes(n)) problems.push(`missing canonical variant: ${n}`);
  // Content check: index.html files must be identical except the stylesheet link.
  const htmls = names.map((n) => {
    const p = path.join(variantsDir(args.project), n, 'index.html');
    return fs.existsSync(p) ? fs.readFileSync(p, 'utf8').replace(/<link[^>]*stylesheet[^>]*>/gi, '<LINK>') : null;
  }).filter(Boolean);
  if (htmls.length > 1 && new Set(htmls).size > 1) {
    problems.push('variant index.html files differ beyond the stylesheet link — variants must share content, copy, and semantic HTML');
  }
  if (problems.length) {
    console.error('variant-picker: CHECK FAILED');
    for (const p of problems) console.error(`  - ${p}`);
    process.exit(1);
  }
  console.log(`variant-picker: OK — ${names.length} variants, all with tokens + screenshot + identical HTML.`);
} else {
  usage(`unknown command "${cmd || ''}" (list | pick | check)`);
}
