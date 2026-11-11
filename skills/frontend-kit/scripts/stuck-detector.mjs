#!/usr/bin/env node
// stuck-detector.mjs — mechanical P6 trigger detector. No judgement.
//
// Reads <project>/design/run-log.jsonl (the last two DISTINCT round
// numbers; a confirmation re-grade recorded against the same round number
// does not count as a second round) + the git diff of design/tokens.css
// and the graded HTML, and prints the P6 trigger (flat-line /
// round-1-repick / none) with its reason. The full trigger set lives in
// skills/frontend-kit/references/stop-rules.md; this script is the
// mechanical check, not the rule.
//
// Rules implemented (stop-rules.md, council D1/D2 2026-11-10):
//   (a) round-1 re-pick — after round 1 only: Layout or Space <= 3 AND
//       the judge's evidence lines cite the failing axis (the detector
//       checks the evidence text names the axis — layout/grid/alignment/
//       section/hero/column/split/wrap/container/overflow/structure, or
//       space/spacing/whitespace/gap/margin/padding/fill/dead-band/
//       density — a bare score never fires it) AND a structural
//       (break-frame) variant exists among the kept variants
//       (design/variants/break-frame/ on disk). If any condition fails,
//       (a) does NOT fire — the reason says which one, and that the
//       action is escalate (present best version + blocker), not re-pick.
//   (b) flat-line — round 2+: no axis improved AND gate findings did not
//       decrease AND no new gate finding appeared. Gate-progress
//       exception: a round where scores are flat but the gate fixed a
//       finding (findings decreased) is NOT flat. Effective scores are
//       the stop-round jury median when recorded (--jury on the record),
//       else the absolute scores.
//   Deleted triggers (c) and (d) are NOT implemented: there is no
//   second-round confirmation and no "same lowest axis stagnates"
//   check — one trigger count, not two.
//
// Fix-class hash: the sha256 of the git diff output (working-tree diff
// against HEAD) of design/tokens.css + the graded HTML. The hash is the
// DIFF hash, never builder self-report. There is NO P5 script classifier
// in this repo (verified: no classifier script exists under
// skills/frontend-kit/scripts/; --fix-class in run-log.mjs is a free-form
// builder-supplied string), so no classifier output is claimed here.
// Precondition: run the detector BEFORE committing the round — the diff
// is the working-tree diff, so a project that commits per round has no
// diff for it to hash. In a non-git project the detector cannot run.
//
// Fail loudly (exit 2, nothing printed to stdout) when: the run log is
// missing; fewer rounds exist than the trigger needs; a round needed for
// the comparison has no grade or (for flat-line) no recorded gate
// findings — a findings value of exactly "none" (sole entry,
// case-insensitive) counts as NO recorded findings, not one finding
// (W-LOOP fix 2026-11-11: run-2's graded records carried the literal
// "none", which the old code counted as 1 finding, so the gate-progress
// exception could fire vacuously on a round whose gate was never
// recorded); the graded page cannot be determined; git is unavailable /
// the project is not a git repo; or the diff is empty. Exit 0 means the
// detector evaluated: the trigger line is the verdict, whatever it is.
//
// Node, no dependencies. Usage:
//   node stuck-detector.mjs --project <dir> [--round N] [--page <built.html>]
//   --round defaults to the latest round in the log. --page defaults to
//   the round record's --page field.
//
// Exit codes: 0 evaluated (trigger printed), 1 usage error, 2 missing
//   input (log / rounds / grade / gate findings / page / git / diff).

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';

const AXES = ['type', 'layout', 'colour', 'space'];

// Observable terms naming a Layout failure / a Space failure in a judge's
// evidence line. Mechanical text check only: the orchestrator still reads
// the lines; this check only establishes that the lines cite the failure
// rather than carrying a bare score.
const AXIS_TERMS = {
  layout: ['layout', 'grid', 'alignment', 'align', 'section', 'hero', 'column', 'split', 'wrap', 'container', 'doctrine', 'overlap', 'overflow', 'structure'],
  space: ['space', 'spacing', 'whitespace', 'white space', 'gap', 'margin', 'padding', 'fill', 'dead band', 'dead-band', 'density', 'breathing'],
};

function fail(msg) {
  console.error(`stuck-detector: FAIL — ${msg}`);
  process.exit(2);
}

function usage(msg) {
  if (msg) console.error(`stuck-detector: ${msg}`);
  console.error(`usage:
  node stuck-detector.mjs --project <dir> [--round N] [--page <built.html>]
  Reads <project>/design/run-log.jsonl + the git diff of design/tokens.css
  and the graded HTML; prints trigger: flat-line | round-1-repick | none.`);
  process.exit(1);
}

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const val = argv[i + 1];
      if (val === undefined) usage(`--${key} needs a value`);
      out[key] = val;
      i++;
    } else out._.push(a);
  }
  return out;
}

function scoresLine(s) {
  return `T${s.type}/L${s.layout}/C${s.colour}/S${s.space}`;
}

// Effective scores for a round record: the stop-round jury median when
// recorded, else the absolute scores (same rule as run-log.mjs `best`).
function effectiveScores(rec) {
  return rec.jury || rec.scores || null;
}

function parseGateFindings(rec) {
  if (rec.gateFindings === null || rec.gateFindings === undefined) return null;
  const raw = String(rec.gateFindings).trim();
  // A findings value of exactly "none" (sole entry, case-insensitive) is
  // MISSING findings, not one finding named "none": nothing about the
  // gate was recorded for the round, so flat-line cannot compare. The
  // gate-progress exception must not fire on it.
  if (raw.toLowerCase() === 'none') return null;
  return raw.split(';').map((f) => f.trim()).filter(Boolean);
}

function gitDiff(project, relPaths) {
  let out;
  try {
    out = execFileSync('git', ['-C', project, 'diff', 'HEAD', '--', ...relPaths], { encoding: 'utf8' });
  } catch (e) {
    fail(`git diff failed for ${relPaths.join(', ')} — is ${project} a git repo with git available? (${(e.message || e).toString().split('\n')[0]})`);
  }
  if (!out.trim()) {
    fail(`no git diff for ${relPaths.join(', ')} against HEAD — nothing changed. Run the detector BEFORE committing the round (the diff is the working-tree diff); a project that commits per round has no diff to hash.`);
  }
  return out;
}

function relativeToProject(project, p) {
  if (path.isAbsolute(p)) {
    const rel = path.relative(project, p);
    if (rel && !rel.startsWith('..')) return rel;
    return p;
  }
  return p;
}

const args = parseArgs(process.argv.slice(2));
if (!args.project) usage('--project <dir> is required');
const project = args.project;

const logFile = path.join(project, 'design', 'run-log.jsonl');
if (!fs.existsSync(logFile)) fail(`run log not found: ${logFile}`);
let records;
try {
  records = fs.readFileSync(logFile, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
} catch (e) {
  fail(`run log unreadable: ${logFile} (${e.message})`);
}

// Last record per distinct round number (a confirmation re-grade recorded
// against the same round number does not count as a second round).
const byRound = new Map();
for (const r of records) {
  if (r.kind !== 'round') continue;
  byRound.set(r.round, r);
}
const roundNumbers = [...byRound.keys()].sort((a, b) => a - b);
if (!roundNumbers.length) fail('run log has no round records — nothing to evaluate');

let target;
if (args.round !== undefined) {
  target = Number(args.round);
  if (!Number.isInteger(target) || target < 1) usage('--round must be a positive integer');
  if (!byRound.has(target)) fail(`round ${target} has no record in the run log`);
} else {
  target = roundNumbers[roundNumbers.length - 1];
}
const targetRec = byRound.get(target);

// The graded page: --page wins, else the round record's page field.
const pageArg = args.page || targetRec.page;
if (!pageArg) fail(`cannot determine the graded HTML for round ${target} — pass --page <built.html> or record the round with --page`);
const pageRel = relativeToProject(project, pageArg);

// Fix-class hash: sha256 of the git diff of tokens.css + the graded HTML.
const diff = gitDiff(project, ['design/tokens.css', pageRel]);
const fixClassHash = crypto.createHash('sha256').update(diff).digest('hex');

function printCommon(lines) {
  console.log(`fix-class-hash: ${fixClassHash}`);
  for (const l of lines) console.log(l);
}

if (target === 1) {
  // (a) Round-1 re-pick — conditional. Decide the verdict first, then
  // print exactly one trigger line.
  const scores = effectiveScores(targetRec);
  if (!scores) fail('round 1 has no grade — (a) needs Layout/Space scores');
  const failing = [];
  if (scores.layout <= 3) failing.push('layout');
  if (scores.space <= 3) failing.push('space');
  let verdict = 'none';
  let reason;
  if (!failing.length) {
    reason = 'round 1 — Layout and Space are both >= 4, so (a) does not apply; fix top 2.';
  } else {
    const evidence = (targetRec.evidence || '').trim();
    if (!evidence) {
      reason = `round 1 — ${failing.join(' / ')} <= 3 but no evidence lines are recorded, so (a) cannot fire: the trigger requires the judge's evidence lines to cite the failure, not a bare score. Escalate (present best version + blocker at the human gate).`;
    } else {
      const evLower = evidence.toLowerCase();
      const cited = failing.filter((axis) => AXIS_TERMS[axis].some((t) => evLower.includes(t)));
      if (!cited.length) {
        reason = `round 1 — ${failing.join(' / ')} <= 3 but the evidence lines do not cite the failing axis ("${evidence}"). (a) requires the evidence lines to cite the failure. Escalate (present best version + blocker at the human gate).`;
      } else {
        const breakFrame = path.join(project, 'design', 'variants', 'break-frame');
        if (!fs.existsSync(breakFrame)) {
          reason = `round 1 — ${cited.join(' / ')} <= 3 and the evidence lines cite the failure ("${evidence}"), but no structural (break-frame) variant exists among the kept variants (design/variants/break-frame/ is absent — tight brief, break-frame skipped). (a) does NOT fire: escalate (present best version + blocker at the human gate) instead of re-picking a colour variant at a structural problem.`;
        } else {
          verdict = 'round-1-repick';
          reason = `round 1 — ${cited.join(' / ')} <= 3 and the evidence lines cite the failure ("${evidence}"); a structural (break-frame) variant exists among the kept variants. Re-pick from the kept variants (consumes one of the 2 re-picks), not fix-top-2.`;
        }
      }
    }
  }
  console.log(`trigger: ${verdict}`);
  console.log('round: 1');
  console.log(`scores: ${scoresLine(scores)}${targetRec.jury ? ' (jury median)' : ''}`);
  printCommon([`reason: ${reason}`]);
  process.exit(0);
}

// (b) Flat-line — needs the last two distinct rounds.
const prevNumber = roundNumbers.filter((n) => n < target).pop();
if (prevNumber === undefined) fail(`round ${target} is the only round in the log — flat-line needs two rounds (use round 1 for the (a) check)`);
const prevRec = byRound.get(prevNumber);
const prevScores = effectiveScores(prevRec);
const currScores = effectiveScores(targetRec);
if (!prevScores) fail(`round ${prevNumber} has no grade — flat-line needs scores for both rounds`);
if (!currScores) fail(`round ${target} has no grade — flat-line needs scores for both rounds`);
const prevFindings = parseGateFindings(prevRec);
const currFindings = parseGateFindings(targetRec);
if (prevFindings === null) fail(`round ${prevNumber} has no recorded gate findings — its --gate-findings is missing or the literal "none" (which means no findings were recorded, not one finding) — flat-line needs the gate comparison`);
if (currFindings === null) fail(`round ${target} has no recorded gate findings — its --gate-findings is missing or the literal "none" (which means no findings were recorded, not one finding) — flat-line needs the gate comparison`);

const improvedAxes = AXES.filter((axis) => currScores[axis] > prevScores[axis]);
const prevSet = new Set(prevFindings);
const currSet = new Set(currFindings);
const newFindings = currFindings.filter((f) => !prevSet.has(f));
const fixedFindings = prevFindings.filter((f) => !currSet.has(f));
const decreased = currFindings.length < prevFindings.length;
const flat = improvedAxes.length === 0 && newFindings.length === 0 && !decreased;

console.log(`trigger: ${flat ? 'flat-line' : 'none'}`);
console.log(`rounds compared: ${prevNumber} -> ${target}`);
console.log(`scores: round ${prevNumber} ${scoresLine(prevScores)}${prevRec.jury ? ' (jury median)' : ''} -> round ${target} ${scoresLine(currScores)}${targetRec.jury ? ' (jury median)' : ''} (${improvedAxes.length ? `improved: ${improvedAxes.join(', ')}` : 'no axis improved'})`);
console.log(`gate findings: round ${prevNumber} (${prevFindings.length}): ${prevFindings.join('; ') || '—'} -> round ${target} (${currFindings.length}): ${currFindings.join('; ') || '—'} (${decreased ? `decreased ${prevFindings.length} -> ${currFindings.length} (gate progress counts)` : 'did not decrease'}; ${newFindings.length ? `new finding: ${newFindings.join('; ')}` : 'no new finding'}${fixedFindings.length ? `; fixed: ${fixedFindings.join('; ')}` : ''})`);
if (flat) {
  printCommon([
    'reason: flat-line — no axis improved AND gate findings did not decrease AND no new gate finding appeared. End work on the direction: re-pick if re-picks remain, else stop and present the best version at the human gate.',
    'confirmation: one re-grade confirms (second grade, not a second round; third only if the two disagree on the flat-line verdict) — jury-of-3 instead if this is the round that would stop the loop.',
  ]);
} else if (improvedAxes.length) {
  printCommon([`reason: not flat — ${improvedAxes.join(', ')} improved (round ${prevNumber} -> ${target}); fix top 2.`]);
} else if (decreased) {
  printCommon(['reason: not flat — scores are flat but the gate fixed a finding (gate findings decreased); gate progress counts. Fix top 2.']);
} else {
  printCommon([`reason: not flat — a new gate finding appeared (${newFindings.join('; ')}); fix top 2.`]);
}
process.exit(0);
