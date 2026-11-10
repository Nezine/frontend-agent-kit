#!/usr/bin/env node
// detect.mjs — the frontend-kit `impeccable detect` wrapper (step 3, gate 1).
//
// Runs the Impeccable deterministic detector (62 rules: 31 slop / 31 quality;
// registry lives in the ENGINE, crates/live/assets/antipatterns.json at tag
// skill-v4.8.2 — VERIFIED) and prints its output UNABRIDGED, then exits with
// the detector's own exit code. The gate result is printed, not summarised.
//
// Resolution order (fixed 2026-11-10, probe G-9b): `impeccable` on PATH,
// else the INSTALLED launcher the kit writes (the pinned engine —
// ~/.agents/skills/impeccable/scripts/impeccable, then the Claude-dir
// copy, the same two paths gate.sh tries). NEVER a silent npx download:
// the old `npx --yes impeccable@4.8.2` fallback downloaded the pinned CLI
// into the npx cache mid-gate, so a gate could pass on an engine nobody
// installed. If neither resolves, exit 3 with the exact install command.
// The kit pin (4.8.2 / engine 0.1.21) is still the version the install
// command pins — never @latest (AGENTS.md §3 hard rule).
// Never installs anything silently: if neither resolves, exit 3 with the
// exact error and the command the human/agent should run instead.
//
// Usage:
//   node detect.mjs <path|url> [detect args...]
//   node detect.mjs --list-rules
//   node detect.mjs --version
//
// N7 — directory targets are approximate: the detector scans a directory
// with regex matching only (its own words: "Rules that need a parsed page
// (tiny-text, low-contrast and other element rules) did not run on them;
// findings are an undercount, not a clean bill of health"). This wrapper
// prints that warning up front whenever the target is an existing
// directory, so a clean directory result is never read as a clean bill of
// health. For the full check, point detect at a single built .html file
// (or the running dev server URL). gate.sh never runs directory mode: it
// detects per built file instead (F15).
//
// Exit codes are the detector's own: 0 = no findings, 2 = findings,
// 1 = unscannable (per the Impeccable README, VERIFIED in phase-1 research).
// This wrapper adds exit 3 when no detector binary can be found at all.
//
// Node, no dependencies (spawns the detector binary only).

import { spawnSync } from 'node:child_process';
import { existsSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import path from 'node:path';

// Kit pin — must match vendor/impeccable/SOURCE.txt (tag skill-v4.8.2,
// engine 0.1.21). The npx fallback installs exactly this version.
const IMPECCABLE_PIN = '4.8.2';

const args = process.argv.slice(2);
if (!args.length) {
  console.error('usage: node detect.mjs <path|url> [detect args...] | --list-rules | --version');
  process.exit(1);
}

// N7: warn up front when the target is a directory — the detector's
// directory mode is regex-only, so its findings undercount (see header).
// The first non-option arg is the target (detect takes no valued flags
// before it in this wrapper's usage); --list-rules/--version have none.
const targetArg = args.find((a) => !a.startsWith('-'));
if (targetArg && !/^https?:\/\//i.test(targetArg)) {
  try {
    if (existsSync(targetArg) && statSync(targetArg).isDirectory()) {
      console.error(`detect.mjs: WARNING — directory target (${targetArg}): the detector scans directories with regex matching only; rules that need a parsed page do not run, so findings are an undercount, not a clean bill of health. For the full check, scan a single built .html file (or the running dev server URL).`);
    }
  } catch { /* a stat failure is the detector's problem, not this warning's */ }
}

function tryRun(cmd, argv) {
  return spawnSync(cmd, argv, { stdio: 'inherit', shell: false });
}

// Installed launcher candidates (same paths gate.sh tries, in order).
function installedLauncher() {
  const home = homedir();
  for (const cand of [
    path.join(home, '.agents', 'skills', 'impeccable', 'scripts', 'impeccable'),
    path.join(home, '.claude', 'skills', 'impeccable', 'scripts', 'impeccable'),
  ]) {
    try { if (existsSync(cand) && statSync(cand).isFile()) return cand; } catch { /* next */ }
  }
  return null;
}

let res = tryRun('impeccable', ['detect', ...args]);
if (res.error && res.error.code === 'ENOENT') {
  const launcher = installedLauncher();
  if (launcher) {
    console.error(`detect.mjs: \`impeccable\` not on PATH — using the installed launcher (${launcher}); no download.`);
    res = tryRun(launcher, ['detect', ...args]);
  } else {
    console.error('detect.mjs: no Impeccable detector found: `impeccable` is not on PATH and no installed launcher exists under ~/.agents/skills/impeccable/scripts/ or ~/.claude/skills/impeccable/scripts/.');
    console.error(`detect.mjs: install it first — \`npx --yes impeccable@${IMPECCABLE_PIN} install --providers=<detected> --scope=global\` (or ./install.sh, which warms the engine) — then re-run this wrapper. No silent download is attempted.`);
    process.exit(3);
  }
}
if (res.error) {
  console.error(`detect.mjs: could not run the detector: ${res.error.message}`);
  console.error(`detect.mjs: install it first — \`npx --yes impeccable@${IMPECCABLE_PIN} install --providers=<detected> --scope=global\` — then re-run this wrapper.`);
  process.exit(3);
}
process.exit(res.status ?? 1);
