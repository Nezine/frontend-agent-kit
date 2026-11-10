#!/usr/bin/env node
// variant-picker.mjs — the frontend-kit variant picker (step 2a).
//
// Lists the structurally divergent variants in <project>/design/variants/
// (each variant is a folder with its own tokens.css and a screenshot at the
// same width), prints a pick table, and records the human's pick in the run
// log so the pick IS the feedback — never re-argued in prose.
//
// VARIANT CONTRACT (D2, council decision 2026-11-10 — WEAKENED from the
// old CSS-only contract; the old "same content, same copy, same semantic
// HTML — only CSS changes" wording is SUPERSEDED):
//   "same content, same copy, same section inventory — structure may
//    differ; tokens stay locked"
// Variants MUST differ in structure — layout doctrine, section order,
// hero form — not only in CSS. One variant is deliberately divergent
// ("break-frame", see skills/frontend-kit/references/variant-briefs.md
// §6). Generate all variants before any critique ("play first, critique
// later"); score them blind in random order (see
// skills/frontend-kit/references/variant-scoring.md).
//
// Expected layout (stated here AND in skills/frontend-kit/SKILL.md step 2;
// the skill used to state no layout at all, so a flat layout of
// <name>.html + <name>-tokens.css + <name>-1440.png was rejected):
//   design/variants/<name>/tokens.css
//   design/variants/<name>/screenshot-1440.png   (same width for every variant)
//   design/variants/<name>/index.html            (same content, same copy,
//                                                 same section inventory —
//                                                 structure MAY differ)
// The five canonical names: editorial, dark, warm-brutalist, glassy, minimal.
// A sixth variant, break-frame, is required by the brief (variant-briefs.md
// §6); `check` reports its presence but does not fail when it is absent —
// presence is a brief-completeness matter, enforced at generation time.
// Extra names are listed, not rejected; the human picks one.
//
// What `check` enforces (the contract, mechanically):
//   - every variant has tokens.css + a screenshot + index.html;
//   - all five canonical variants are present;
//   - SECTION INVENTORY: the set of <section id="..."> ids is identical
//     across variants (order may differ — reordering sections never fails
//     the check). A variant that drops (or adds) a section FAILS.
//   - COPY: the visible body copy is identical across variants as a
//     MULTISET of text lines (order-insensitive, so a reordered or
//     re-tagged section still passes; a changed, added, or dropped line
//     FAILS). Tags, classes, and section order are ignored — only the
//     words must match.
//   - STRUCTURE is NOT checked for sameness: structurally different
//     variants with identical inventory + copy PASS by design. `check`
//     prints each variant's structural signature (section order + hero
//     form) so divergence is visible, but sameness of structure is never
//     a failure — the brief, not the picker, requires divergence.
// Tokens stay locked: a variant's tokens.css must reproduce the locked
// design/tokens.css direction (the auto-pick scores exactly that); a
// variant that contradicts the locked tokens is a different direction,
// not a variant.
//
// Deterministic pick for human-less runs (probe G-5, SKILL.md step 2a):
// `pick --auto` picks the variant whose tokens match the LOCKED
// design/tokens.css most closely — the count of locked `--name: value`
// declarations the variant reproduces exactly. Ties break by the plan's
// preferred structure: design/PLAN.md records it as a line
// `Preferred structure: <variant name>` (the plan template gains that
// field with the P2/LOOP-1 work; until it exists the picker tolerates its
// absence and falls back to alphabetical). The preferred structure only
// breaks ties among the top scorers — it never outranks a higher token
// match. A byte-identical tokens file scores a perfect match. The rule is
// stated BEFORE picking, needs no human, and gives no quality verdict: it
// only says which variant is closest to the locked direction.
// Unpicked variants are NOT deleted and NOT discarded: `pick` records
// them in the run-log entry (`unpicked: [...]`) and they stay on disk
// under design/variants/ for the round-1 re-pick (P6). The re-pick logic
// itself is NOT in this script — it belongs to the P6 worker.
//
// Node, no dependencies. Usage:
//   node variant-picker.mjs --project <dir> list
//   node variant-picker.mjs --project <dir> pick --variant <name> [--note "..."]
//   node variant-picker.mjs --project <dir> pick --auto
//   node variant-picker.mjs --project <dir> check
//
// `check` exits non-zero and names the problem when variants are missing
// tokens, missing screenshots, missing sections, or differ in inventory
// (a dropped/added section) or copy (a changed/added/dropped line).
// Exit codes: 0 ok, 1 usage error / check failure / unknown variant on pick.

import fs from 'node:fs';
import path from 'node:path';

const CANONICAL = ['editorial', 'dark', 'warm-brutalist', 'glassy', 'minimal'];
const BREAK_FRAME = 'break-frame';

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

// The plan's preferred structure, if design/PLAN.md records one: a line
// `Preferred structure: <variant name>` (case-insensitive label). Returns
// the name or null. The PLAN.md template gains this field with the P2
// work; until then its absence is normal and the caller falls back to
// alphabetical tie-breaking — never an error.
function preferredStructure(project) {
  const plan = path.join(project, 'design', 'PLAN.md');
  if (!fs.existsSync(plan)) return null;
  const text = fs.readFileSync(plan, 'utf8');
  const m = text.match(/^\s*preferred structure\s*:\s*([A-Za-z0-9][A-Za-z0-9_-]*)\s*$/im);
  return m ? m[1] : null;
}

// Section inventory of one variant's HTML: the ids of its <section>
// elements, in document order. The INVENTORY is the sorted set; the ORDER
// is the variant's structure (reported, never failed on).
function extractSections(html) {
  const ids = [];
  for (const m of html.matchAll(/<section\b[^>]*?\bid\s*=\s*["']([^"']+)["']/gi)) {
    ids.push(m[1]);
  }
  return ids;
}

// Visible body copy of one variant's HTML as a SORTED array of text lines
// (a multiset: duplicates kept, order dropped). Tags, classes, attribute
// values, and section order are all ignored — only the words must match
// across variants. Script/style blocks and the <head> are excluded;
// a small entity table covers the entities hand-written HTML uses.
function extractCopy(html) {
  const body = html.match(/<body\b[^>]*>([\s\S]*?)<\/body\s*>/i);
  let text = body ? body[1] : html;
  text = text.replace(/<script\b[^>]*>[\s\S]*?<\/script\s*>/gi, ' ');
  text = text.replace(/<style\b[^>]*>[\s\S]*?<\/style\s*>/gi, ' ');
  text = text.replace(/<[^>]+>/g, '\n');
  text = text.replace(/&nbsp;/gi, ' ').replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<').replace(/&gt;/gi, '>').replace(/&quot;/gi, '"')
    .replace(/&#39;/g, "'").replace(/&apos;/gi, "'");
  return text.split('\n').map((l) => l.trim()).filter(Boolean).sort();
}

// Structural signature of one variant's HTML (informational only): the
// section order plus the first section's class list (its hero form in
// miniature). Printed by `list` and `check` so divergence is visible;
// never a pass/fail input.
function structureSignature(html) {
  const order = extractSections(html);
  // Hero form = the class list of the section whose id is "hero" (not the
  // first section in the document — a reordered variant may open on
  // another section).
  const hero = html.match(/<section\b[^>]*?\bid\s*=\s*["']hero["'][^>]*>/i);
  const cls = hero ? (hero[0].match(/\bclass\s*=\s*["']([^"']+)["']/i) || [])[1] || '(no class)' : '(no hero section)';
  return { order, heroClass: cls };
}

function readHtml(project, name) {
  const p = path.join(variantsDir(project), name, 'index.html');
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : null;
}

// Deterministic auto-pick (probe G-5): score each variant by how many of
// the LOCKED design/tokens.css declarations it reproduces exactly
// (same --name, same value). Highest score wins; ties break by the plan's
// preferred structure when it names one of the tied variants, else
// alphabetically (listVariants returns sorted names). A byte-identical
// tokens file scores a perfect match (all locked declarations).
function autoPick(project) {
  const locked = parseTokens(path.join(project, 'design', 'tokens.css'));
  if (!locked.size) usage('pick --auto needs a locked design/tokens.css with at least one --name: value declaration');
  const names = listVariants(project);
  if (!names.length) usage('pick --auto found no variants — generate the 5 structural variants first');
  const preferred = preferredStructure(project);
  const scored = names.map((n) => {
    const mine = parseTokens(path.join(variantsDir(project), n, 'tokens.css'));
    let match = 0;
    for (const [k, v] of locked) if (mine.get(k) === v) match++;
    return { name: n, match, total: locked.size };
  });
  const bestMatch = Math.max(...scored.map((s) => s.match));
  const tied = scored.filter((s) => s.match === bestMatch).map((s) => s.name).sort();
  let tieBreak = 'alphabetical (no preferred structure in design/PLAN.md)';
  let best = tied[0];
  if (preferred && tied.includes(preferred)) {
    best = preferred;
    tieBreak = `plan's preferred structure (${preferred})`;
  } else if (preferred) {
    // A preferred structure that is not among the tied top scorers never
    // outranks a higher token match — the tie falls back to alphabetical.
    tieBreak = `alphabetical (plan's preferred structure ${preferred} is not among the tied variants)`;
  }
  scored.sort((a, b) => (b.match - a.match) || (a.name < b.name ? -1 : 1));
  return { scored, best, bestMatch, tied, preferred: preferred || null, tieBreak };
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
  if (!names.length) { console.log('variant-picker: no variants yet — generate the 5 structural variants first.'); process.exit(0); }
  console.log('variants (same content, same copy, same section inventory — structure may differ; tokens stay locked):');
  for (const n of names) {
    const s = status(args.project, n);
    const mark = CANONICAL.includes(n) ? '' : (n === BREAK_FRAME ? ' (break-frame)' : ' (non-canonical name)');
    const html = readHtml(args.project, n);
    const sig = html ? structureSignature(html) : null;
    console.log(`  ${n}${mark} — tokens: ${s.tokens ? 'yes' : 'MISSING'}, screenshot: ${s.shot || 'MISSING'}, html: ${s.html ? 'yes' : 'MISSING'}${sig ? `, sections: ${sig.order.join(' > ') || '(none)'}` : ''}`);
  }
  if (!names.includes(BREAK_FRAME)) console.log(`  note: no ${BREAK_FRAME} variant — the brief (variant-briefs.md §6) requires one.`);
} else if (cmd === 'pick') {
  let name = args.variant;
  if (args.auto !== undefined || (!name && args._.includes('auto'))) {
    // pick --auto: deterministic, no human. (parseArgs consumes the value
    // after --auto as its value, so `--auto` alone is the trigger: any
    // --auto flag, or a bare `auto` positional, means auto-pick.)
    const { scored, best, tied, tieBreak } = autoPick(args.project);
    name = best;
    const table = scored.map((s) => `${s.name} ${s.match}/${s.total}`).join(', ');
    const autoNote = `deterministic auto-pick (no human): closest to locked tokens — ${scored.find((s) => s.name === best).match}/${scored[0].total} locked token values reproduced exactly; ${tied.length > 1 ? `tie among ${tied.join(', ')} broken by ${tieBreak}` : 'no tie'} [${table}]`;
    args.note = args.note ? `${args.note} — ${autoNote}` : autoNote;
    console.log(`variant-picker: auto-pick scores (locked-token matches): ${table}`);
    if (tied.length > 1) console.log(`variant-picker: tie among ${tied.join(', ')} broken by ${tieBreak}`);
  }
  if (!name) usage('pick needs --variant <name> or --auto');
  const names = listVariants(args.project);
  if (!names.includes(name)) {
    console.error(`variant-picker: unknown variant "${name}" (have: ${names.join(', ') || 'none'})`);
    process.exit(1);
  }
  // Unpicked variants stay available for the round-1 re-pick (P6): record
  // them in the log entry and keep them on disk — a pick never deletes a
  // variant.
  const unpicked = names.filter((n) => n !== name);
  const log = path.join(args.project, 'design', 'run-log.jsonl');
  fs.mkdirSync(path.dirname(log), { recursive: true });
  fs.appendFileSync(log, JSON.stringify({ kind: 'variant-pick', variant: name, unpicked, note: args.note || null, at: new Date().toISOString() }) + '\n');
  console.log(`variant-picker: picked "${name}"${args.note ? ` — ${args.note}` : ''}. The pick IS the feedback; build on this variant only.`);
  console.log(`variant-picker: unpicked (kept on disk for the round-1 re-pick): ${unpicked.join(', ') || '(none)'}`);
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
  // Inventory check: the SET of <section id="..."> ids must be identical
  // across variants. Order may differ — reordering never fails. A dropped
  // or added section fails, naming the variant and the ids.
  const inventories = new Map();
  for (const n of names) {
    const html = readHtml(args.project, n);
    if (html !== null) inventories.set(n, [...new Set(extractSections(html))].sort());
  }
  const invList = [...inventories.values()];
  if (invList.length > 1) {
    const base = JSON.stringify(invList[0]);
    for (const [n, inv] of inventories) {
      if (JSON.stringify(inv) !== base) {
        const missing = invList[0].filter((id) => !inv.includes(id));
        const extra = inv.filter((id) => !invList[0].includes(id));
        problems.push(`${n}: section inventory differs from ${names[0]} — missing: ${missing.join(', ') || '(none)'}, extra: ${extra.join(', ') || '(none)'} (same section inventory required; structure may differ)`);
      }
    }
  }
  // Copy check: the visible body copy must be identical across variants
  // as a multiset of text lines (order-insensitive). A changed, added, or
  // dropped line fails, with a sample of the differing lines.
  const copies = new Map();
  for (const n of names) {
    const html = readHtml(args.project, n);
    if (html !== null) copies.set(n, extractCopy(html));
  }
  const copyList = [...copies.values()];
  if (copyList.length > 1) {
    const base = JSON.stringify(copyList[0]);
    for (const [n, copy] of copies) {
      if (JSON.stringify(copy) !== base) {
        const baseSet = copyList[0];
        const onlyInBase = baseSet.filter((l) => !copy.includes(l)).slice(0, 3);
        const onlyInVariant = copy.filter((l) => !baseSet.includes(l)).slice(0, 3);
        problems.push(`${n}: copy differs from ${names[0]} — lines only in ${names[0]}: ${onlyInBase.map((l) => JSON.stringify(l)).join(', ') || '(none)'}; lines only in ${n}: ${onlyInVariant.map((l) => JSON.stringify(l)).join(', ') || '(none)'} (same copy required; structure may differ)`);
      }
    }
  }
  if (problems.length) {
    console.error('variant-picker: CHECK FAILED');
    for (const p of problems) console.error(`  - ${p}`);
    process.exit(1);
  }
  // Structural signatures are informational: divergence is visible here,
  // but sameness of structure is never a failure.
  console.log(`variant-picker: OK — ${names.length} variants, all with tokens + screenshot + identical section inventory + identical copy.`);
  for (const n of names) {
    const html = readHtml(args.project, n);
    if (html === null) continue;
    const sig = structureSignature(html);
    console.log(`  structure — ${n}: sections ${sig.order.join(' > ') || '(none)'}; hero class: ${sig.heroClass}`);
  }
  if (!names.includes(BREAK_FRAME)) console.log(`  note: no ${BREAK_FRAME} variant — the brief (variant-briefs.md §6) requires one.`);
} else {
  usage(`unknown command "${cmd || ''}" (list | pick | check)`);
}
