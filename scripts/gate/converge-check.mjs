#!/usr/bin/env node
// converge-check.mjs — P2 script half of the converge check.
//
// The converge check answers one question: does the build contain every
// section and every state the plan promised? A build can score 4/4/4/4
// while silently dropping a planned section; scores cannot catch that
// class of failure, and this script exists to catch it.
//
// The check is split by executor (council A/B/C, P2):
//   * SCRIPT half (this file): section presence — every id in PLAN.md's
//     section inventory has a matching id in the built HTML — and state
//     evidence — every non-N/A cell of the screen x state matrix names
//     a file that exists or an id that exists in the HTML.
//   * JUDGE half (not this file): whether a state looks right is a
//     judgement; it lives in skills/frontend-kit/references/
//     converge-checklist.md and is scored as a Layout defect in step 4.
//     Anything this script cannot check is listed as UNCHECKABLE —
//     "grader's call" — never silently passed.
//
// BLOCKING: a failure here blocks the grade (it runs inside gate.sh leg 1
// when a PLAN.md exists) and blocks the human gate (step 6): a build that
// drops a planned section or state is not presented as done. There is no
// advisory mode and no OpenSpec-style escape hatch (OpenSpec's own docs
// say its verify "won't block archive" — this check does block).
//
// PLAN.md format this script reads (see templates/design/PLAN.md):
//   * `## Section inventory` — a Markdown table whose FIRST column is the
//     section id (e.g. `hero`, `pricing`). Sections are listed by CONTENT,
//     not by order: reordering sections never fails convergence.
//   * `## Screen x state matrix` — a table: first column the section id,
//     other columns the states (default / loading / empty / error /
//     partial). A cell is `N/A` (static section, state does not apply),
//     `#id` (the state lives in that element of the HTML), a file path
//     (the state's frame / story / preview file, relative to the project
//     root), or free text (uncheckable — grader's call).
//   * A matrix row naming a section with no inventory entry is a FAIL:
//     the plan must be self-consistent.
//
// Usage:
//   node converge-check.mjs --plan design/PLAN.md --page index.html
//       [--project <project-dir>]
// Exit codes: 0 = converged; 1 = a planned section/state is missing
// (FAIL — blocks the grade and the human gate); 2 = usage error (plan or
// page missing/unreadable, or no section inventory found in the plan).
// Findings are printed in full, never summarised. Node, no dependencies.

import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

function usage(msg) {
  if (msg) console.error(`converge-check: ${msg}`);
  console.error('usage: node converge-check.mjs --plan <design/PLAN.md> --page <built.html> [--project <dir>]');
  process.exit(2);
}

function opt(argv, name, def = null) {
  const i = argv.indexOf(`--${name}`);
  if (i === -1) return def;
  if (argv[i + 1] === undefined) usage(`--${name} needs a value`);
  return argv[i + 1];
}

const argv = process.argv.slice(2);
const planPath = opt(argv, 'plan');
const pagePath = opt(argv, 'page');
let projectDir = opt(argv, 'project');
if (!planPath) usage('--plan is required');
if (!pagePath) usage('--page is required');
if (!existsSync(planPath)) usage(`plan file does not exist: ${planPath}`);
if (!existsSync(pagePath)) usage(`page file does not exist: ${pagePath}`);

const planAbs = path.resolve(planPath);
const pageAbs = path.resolve(pagePath);
if (!projectDir) {
  // The plan lives at <project>/design/PLAN.md; the project is two levels up.
  const parent = path.dirname(planAbs);
  projectDir = path.basename(parent) === 'design' ? path.dirname(parent) : parent;
}
projectDir = path.resolve(projectDir);

const planText = readFileSync(planAbs, 'utf8');
const pageText = readFileSync(pageAbs, 'utf8');

// --- parse: lines of the table under a heading --------------------------------
// Returns the table rows (arrays of cell strings) under the first heading
// whose text matches `headingRe`, or null when no such heading exists.
function tableUnder(headingRe) {
  const lines = planText.split('\n');
  let start = -1;
  for (let i = 0; i < lines.length; i++) {
    if (/^#{1,6}\s/.test(lines[i]) && headingRe.test(lines[i])) { start = i + 1; break; }
  }
  if (start === -1) return null;
  const rows = [];
  let inTable = false;
  for (let i = start; i < lines.length; i++) {
    const line = lines[i];
    if (/^#{1,6}\s/.test(line)) break; // next heading ends the section
    if (!line.trim().startsWith('|')) { if (inTable) break; continue; }
    inTable = true;
    const cells = line.split('|').slice(1, -1).map((c) => c.trim().replace(/^`|`$/g, '').trim());
    if (cells.length === 0) continue;
    if (/^[\s:-]+$/.test(cells.join(''))) continue; // separator row
    rows.push(cells);
  }
  return rows;
}

const inventoryRows = tableUnder(/section inventory/i);
if (!inventoryRows || inventoryRows.length === 0) {
  usage(`no section inventory table found under '## Section inventory' in ${planPath} — the plan has no sections to converge against`);
}
// Drop the header row (first cell names the column, e.g. `id`).
const inventory = inventoryRows
  .map((cells) => cells[0])
  .filter((id) => id && !/^(id|section(\s+id)?)$/i.test(id));
const sectionIds = [...new Set(inventory)];
if (sectionIds.length === 0) {
  usage(`section inventory in ${planPath} has no ids — fill the table before the build`);
}

// All ids present in the built HTML.
const htmlIds = new Set([...pageText.matchAll(/id\s*=\s*["']([^"']+)["']/g)].map((m) => m[1]));

let fails = 0;
let uncheckable = 0;
const fail = (msg) => { fails += 1; console.log(`CONVERGE FAIL: ${msg}`); };
const ok = (msg) => console.log(`CONVERGE OK: ${msg}`);

// --- section presence -------------------------------------------------------
for (const id of sectionIds) {
  if (htmlIds.has(id)) ok(`section '${id}' present in ${path.basename(pageAbs)}`);
  else fail(`section '${id}' is in PLAN.md but has no matching id in ${pageAbs} — the build dropped a planned section`);
}

// --- screen x state matrix ---------------------------------------------------
const matrixRows = tableUnder(/screen.*state.*matrix/i);
if (!matrixRows || matrixRows.length === 0) {
  console.log(`CONVERGE NOTE: no '## Screen x state matrix' table in ${planPath} — state evidence is unchecked (add the matrix; P5 owns the state rules)`);
} else {
  const header = matrixRows[0];
  const states = header.slice(1);
  for (const row of matrixRows.slice(1)) {
    const section = row[0];
    if (!section) continue;
    if (!sectionIds.includes(section)) {
      fail(`matrix row '${section}' has no entry in the section inventory — the plan is self-inconsistent (add the section to the inventory or drop the row)`);
      continue;
    }
    for (let c = 1; c < row.length; c++) {
      const state = states[c - 1] || `column ${c}`;
      const cell = (row[c] || '').trim();
      if (!cell || /^n\/a$/i.test(cell) || cell === '—' || cell === '-') continue; // state does not apply
      if (cell.startsWith('#')) {
        const id = cell.slice(1);
        if (htmlIds.has(id)) ok(`state '${state}' for '${section}' present as #${id} in ${path.basename(pageAbs)}`);
        else fail(`state '${state}' for '${section}' names #${id}, which has no matching id in ${pageAbs}`);
      } else if (cell.includes('/') || /\.(png|jpe?g|webp|html|md)$/i.test(cell)) {
        const evidence = path.resolve(projectDir, cell);
        if (existsSync(evidence)) ok(`state '${state}' for '${section}' evidenced by ${cell}`);
        else fail(`state '${state}' for '${section}' names evidence file ${cell}, which does not exist under ${projectDir}`);
      } else {
        // Free text (a story, a description): no mechanical check exists.
        // Listed, never silently passed; the judge decides in step 4.
        uncheckable += 1;
        console.log(`CONVERGE UNCHECKABLE: state '${state}' for '${section}' — '${cell}' (no file or id to check; grader's call in step 4)`);
      }
    }
  }
}

if (fails > 0) {
  console.log(`CONVERGE RESULT: FAIL (${fails} missing) — fix the build; the human gate is not presented until this is green.`);
  process.exit(1);
}
console.log(`CONVERGE RESULT: PASS (${sectionIds.length} sections present${uncheckable ? `; ${uncheckable} state(s) uncheckable — grader's call` : ''})`);
process.exit(0);
