#!/usr/bin/env node
// token-dictionary.mjs — the frontend-kit token dictionary.
//
// Maps a human's word (a pick, an adjective, a direction) to a token diff,
// so feedback re-enters the loop at step 5 as tokens — never as a rebuild.
// Store: <project>/design/token-dictionary.json (created on first add).
//
// The starter entries below are EXAMPLES, not a standard: they map adjectives
// to token AXES (which variables move, in which direction), not to specific
// hex values. A project's locked tokens always override them. Edit the file
// freely per project; the run log is where entries prove themselves (a
// feedback -> token change -> new score that went up keeps the entry; one
// that went down gets the entry revised or removed).
//
// Node, no dependencies. Usage:
//   node token-dictionary.mjs --project <dir> add --word "<word>" --change "<token diff>" [--note "..."] [--force]
//   node token-dictionary.mjs --project <dir> lookup --word "<word>"
//   node token-dictionary.mjs --project <dir> list
//   node token-dictionary.mjs --project <dir> remove --word "<word>"
//
// Overwriting a SHIPPED starter mapping (one of the STARTER words below,
// still at its shipped value) requires explicit --force — a one-off
// adjective must not silently replace the curated default for that word.
// A forced starter overwrite prints a WARNING and is recorded in the run
// log (<project>/design/run-log.jsonl, kind 'dictionary-overwrite') so the
// change is visible, not silent. Overwriting a word that already holds a
// custom (non-starter) value needs no --force.
//
// Exit codes: 0 ok, 1 usage error / word not found on lookup.

import fs from 'node:fs';
import path from 'node:path';

const STARTER = {
  // word: { change, note } — axes only; the project's tokens supply the values.
  warmer: { change: 'Shift --color-accent and --color-canvas toward warm (raise red, lower blue); keep contrast ≥ WCAG AA.', note: 'Example starter entry — adjust to the locked tokens.' },
  cooler: { change: 'Shift --color-accent and --color-canvas toward cool (raise blue, lower red); keep contrast ≥ WCAG AA.', note: 'Example starter entry — adjust to the locked tokens.' },
  bolder: { change: 'Raise --font-display weight one step; increase --text-display one scale step; reduce --radius on the hero element.', note: 'Example starter entry — adjust to the locked tokens.' },
  quieter: { change: 'Lower --font-display weight one step; reduce accent usage to one element per screen; increase --space-section one step.', note: 'Example starter entry — adjust to the locked tokens.' },
  roomier: { change: 'Increase --space-section and card --space-padding one step each; raise body line-height slightly.', note: 'Example starter entry — adjust to the locked tokens.' },
  denser: { change: 'Decrease --space-section and card --space-padding one step each; tighten body line-height slightly.', note: 'Example starter entry — adjust to the locked tokens.' },
  rounder: { change: 'Raise --radius-card and --radius-button one step each.', note: 'Example starter entry — adjust to the locked tokens.' },
  sharper: { change: 'Lower --radius-card and --radius-button toward --radius-sm; remove card shadows.', note: 'Example starter entry — adjust to the locked tokens.' },
};

function usage(msg) {
  if (msg) console.error(`token-dictionary: ${msg}`);
  console.error(`usage:
  node token-dictionary.mjs --project <dir> add --word "<word>" --change "<token diff>" [--note "..."] [--force]
  node token-dictionary.mjs --project <dir> lookup --word "<word>"
  node token-dictionary.mjs --project <dir> list
  node token-dictionary.mjs --project <dir> remove --word "<word>"`);
  process.exit(1);
}

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      // --force is a boolean flag: it consumes no value. Every other flag
      // consumes the next token unconditionally (a value may legitimately
      // start with '--', e.g. a token diff "--color-accent: ...").
      if (key === 'force') { out.force = true; continue; }
      const val = argv[i + 1];
      if (val === undefined) usage(`--${key} needs a value`);
      out[key] = val;
      i++;
    } else out._.push(a);
  }
  return out;
}

function dictPath(project) {
  return path.join(project, 'design', 'token-dictionary.json');
}

function runLogPath(project) {
  return path.join(project, 'design', 'run-log.jsonl');
}

function recordOverwrite(project, word, previousChange, newChange) {
  const dir = path.dirname(runLogPath(project));
  fs.mkdirSync(dir, { recursive: true });
  const rec = {
    kind: 'dictionary-overwrite', word,
    previousChange, newChange,
    at: new Date().toISOString(),
  };
  fs.appendFileSync(runLogPath(project), JSON.stringify(rec) + '\n');
}

function load(project) {
  const p = dictPath(project);
  if (!fs.existsSync(p)) return { ...STARTER };
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function save(project, d) {
  const dir = path.dirname(dictPath(project));
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(dictPath(project), JSON.stringify(d, null, 2) + '\n');
}

const args = parseArgs(process.argv.slice(2));
const cmd = args._[0];
if (!args.project) usage('--project <dir> is required');

if (cmd === 'add') {
  if (!args.word || !args.change) usage('add needs --word and --change');
  const word = args.word.toLowerCase();
  const d = load(args.project);
  const current = d[word];
  const isStarterAtShippedValue = word in STARTER && current !== undefined
    && JSON.stringify(current) === JSON.stringify(STARTER[word]);
  if (isStarterAtShippedValue && !args.force) {
    console.error(`token-dictionary: REFUSED — "${word}" is a shipped starter mapping (still at its shipped value). Overwriting it needs explicit --force: re-run with --force. No entry written.`);
    process.exit(2);
  }
  d[word] = { change: args.change, note: args.note || '' };
  save(args.project, d);
  if (isStarterAtShippedValue) {
    console.error(`token-dictionary: WARNING — overwrote the shipped starter mapping for "${word}" (--force). Recorded in the run log (design/run-log.jsonl, kind 'dictionary-overwrite').`);
    recordOverwrite(args.project, word, STARTER[word].change, args.change);
  }
  console.log(`token-dictionary: "${word}" -> ${args.change}`);
} else if (cmd === 'lookup') {
  if (!args.word) usage('lookup needs --word');
  const d = load(args.project);
  const e = d[args.word.toLowerCase()];
  if (!e) { console.error(`token-dictionary: no entry for "${args.word.toLowerCase()}"`); process.exit(1); }
  console.log(`${args.word.toLowerCase()} -> ${e.change}${e.note ? ` (${e.note})` : ''}`);
} else if (cmd === 'list') {
  const d = load(args.project);
  for (const [w, e] of Object.entries(d)) console.log(`${w} -> ${e.change}`);
} else if (cmd === 'remove') {
  if (!args.word) usage('remove needs --word');
  const d = load(args.project);
  if (!(args.word.toLowerCase() in d)) { console.error(`token-dictionary: no entry for "${args.word.toLowerCase()}"`); process.exit(1); }
  delete d[args.word.toLowerCase()];
  save(args.project, d);
  console.log(`token-dictionary: removed "${args.word.toLowerCase()}"`);
} else {
  usage(`unknown command "${cmd || ''}" (add | lookup | list | remove)`);
}
