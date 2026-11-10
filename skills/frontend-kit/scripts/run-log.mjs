#!/usr/bin/env node
// run-log.mjs — the frontend-kit run log.
//
// Appends one JSON record per grading round to <project>/design/run-log.jsonl
// and prints the log as a score table. The log is the memory that stops
// rejected directions from being re-proposed: scores per round, grader
// identity + independence basis per round, gate result, and every
// feedback -> token change -> new score.
//
// GRADER RULE (user direction, 2026-11-10, non-negotiable): the builder NEVER
// grades its own work. A builder self-grade is FORBIDDEN. This script REJECTS
// any log entry whose grader is the builder (exit 2, nothing written).
// Allowed graders: judge-subagent | muse-manager | other-model.
// A round with no independent judge is logged with --grader none
// --scores none (fixed 2026-11-10, probe G-4: the old code rejected every
// no-grade record because the grader check ran before the scores check,
// so the ladder's rung-3 "gate green, vision not available" round could
// not be recorded at all). A no-grade record stores grader: null and
// grade: exactly "gate green, vision not available", with NO invented
// grader label and NO independence basis. --grader none WITH scores is
// still REJECTED: a score IS a grade and needs an independent judge.
//
// INDEPENDENCE BASIS (coordinator decision 2026-11-10, recorded in the repo
// AGENTS.md, superseding the old rubric exception): `muse-manager` — a
// DIFFERENT agent instance from the builder, with no production history of
// the build — IS a valid independent grader. What is forbidden is the SAME
// agent instance/context grading its own work, in any guise. The basis must
// establish BOTH halves of independence: (1) fresh/separate context (or a
// different agent instance) AND (2) no production history of the build.
// "Fresh context" alone is NOT enough (rubric A1: fresh context alone does
// not change the weights — a fresh context shown the builder's reasoning is
// not independent). A basis stating only one half is REJECTED (exit 2).
// Accepted phrasings include "fresh context, no production history",
// "a different agent from the builder, no production history of this build",
// "trained separately as a design critic, with no production history".
//
// TASTE LOCK: `lock` records the step-1 taste lock — the "commit" of the
// locked tokens + chosen references BEFORE any HTML (see frontend-kit
// SKILL.md step 1.5). "Commit" = files saved under design/ in the project
// AND this lock entry in the run log; git commit only if the project is a
// git repo.
//
// P7 RUN STATE (no separate run.json file — council decision, 2026-11-10):
// the machine-readable run state lives IN this append-only log, not in a
// mutable JSON file (a mutable file is the overwrite hazard the
// long-running-harness lesson warns against). Schema, per record kind:
//   taste-lock: { kind, lockVersion, tokens, tokensHash, references,
//     approvedBy, notes, at }. lockVersion auto-increments (1, 2, …);
//     --version N records an explicit version (a re-pick creates a NEW
//     version; re-using an existing version is REJECTED, exit 2).
//     tokensHash is the sha256 of the tokens file when it resolves on
//     disk, else null. approvedBy carries the step-1.7 approval basis for
//     human-less runs ("converge-check + round-1 grade (no human
//     present)"); solo runs record human approval in PLAN.md instead.
//   round: { kind, round, grader, independenceBasis, scores, grade,
//     evidence, gate, gateFindings, variant, tokensHash, fixClass,
//     outcome, page, notes, at }. variant is the PICKED variant.
//     tokensHash is --tokens-hash, or the sha256 of
//     <project>/design/tokens.css when present, else null. fixClass is a
//     free-form fix class (e.g. "tokens:colour"); outcome is one of
//     kept | discarded | re-pick | stopped | escalated | pending
//     (default pending). gateFindings is the gate output for the round
//     (;-separated). page is the built HTML file the round graded.
//   feedback: { kind, round, from, tokenChange, scoreAfter, grader,
//     independenceBasis, evidence, fixClass, at }.
// The round-brief generator (skills/frontend-kit/scripts/round-brief.mjs)
// reads ONLY this log + the locked files; no round ever reads the full
// log as context. `brief` below delegates to it.
//
// Node, no dependencies. Usage:
//   node run-log.mjs --project <dir> record --round N --grader <label>
//     --basis "<why this judge counts as independent>"
//     --scores <type,layout,colour,space | none>
//     --evidence "<one line of observable evidence per score, ;-separated>"
//     --gate <pass|fail> [--variant <name>] [--notes "..."]
//     [--tokens-hash <sha256 hex>] [--fix-class "<class>"]
//     [--outcome <kept|discarded|re-pick|stopped|escalated|pending>]
//     [--gate-findings "<gate output, ;-separated>"] [--page <built.html>]
//   --tokens-hash defaults to the sha256 of <project>/design/tokens.css
//   when that file exists; --page is the built HTML the round graded
//   (the round-brief generator needs it to find the best HTML).
//   record enforces the same evidence bar as feedback --score-after:
//   --evidence, when given, must be 10+ characters naming an observable
//   element (same evidenceNamesObservable rule); a bare --evidence "x"
//   with a score is REJECTED (exit 2, nothing written). A score IS a
//   grade, whichever command records it.
//   No-grade record (ladder rung 3 — gate green, vision not available):
//   node run-log.mjs --project <dir> record --round N --grader none
//     --scores none --gate <pass|fail> [--variant <name>] [--notes "..."]
//   --grader none is accepted ONLY with --scores none (and no --evidence
//   score). It records grader: null, grade: "gate green, vision not
//   available". --grader none with scores is REJECTED (a score needs an
//   independent judge); omitting --grader entirely is still a usage error.
//   node run-log.mjs --project <dir> feedback --from "<human words>"
//     --change "<token diff>" --round N [--score-after <t,l,c,s>
//     --grader <judge-subagent|muse-manager|other-model>
//     --basis "<why this judge counts as independent, 10+ chars>"
//     --evidence "<one line naming an observable element, 10+ chars>"]
//   --score-after REQUIRES --grader + --basis + --evidence (exit 2,
//   nothing written, otherwise): a post-feedback score IS a grade, and
//   only an independent judge may grade. --basis must not merely restate
//   the grader name; --evidence must name an observable element, not a
//   generic impression such as "looks good".
//   node run-log.mjs --project <dir> lock --tokens <tokens.css path>
//     --refs "<chosen DESIGN.md + reference screenshots>"
//     [--version N] [--approved-by "<approval basis>"]
//   lock records the step-1 taste lock (the "commit" of tokens + chosen
//   references BEFORE any HTML). It appends {kind:'taste-lock'} to the run
//   log; --tokens is required, --refs is required (name the locked
//   direction — a lock with no references is not a lock). --version
//   defaults to (existing lock count + 1); a re-pick records a NEW
//   version. --approved-by records the human-less approval basis
//   (step 1.7); omit it on solo runs (approval lives in PLAN.md).
//   node run-log.mjs --project <dir> brief [--round N] [--out <file>]
//   brief assembles the minimal round brief for round N (default: the
//   next round) from this log + the locked files, via round-brief.mjs —
//   locked tokens + best HTML + gate findings + grader evidence lines +
//   run state, never the full run log. Prints to stdout, or writes
//   --out when given.
//   node run-log.mjs --project <dir> show
//   node run-log.mjs --project <dir> best
//
// Exit codes: 0 ok, 1 usage error (including a brief that fails its schema
//   check — lock, best HTML, gate findings, or evidence lines missing),
//   2 rejected entry (grader == builder, scores without a named
//   independent grader, or a duplicate lock version).

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const ALLOWED_GRADERS = ['judge-subagent', 'muse-manager', 'other-model'];
const FORBIDDEN_GRADERS = ['builder', 'self', 'self-grade', 'builder-grade'];

// Feedback --score-after validation: a post-feedback score is a grade, so
// it needs the same independent-judge proof as a round grade. --basis must
// carry substance beyond the grader label itself; --evidence must name an
// observable element (a digit/measurement, or a named page element), not a
// generic impression such as "looks good".
const OBSERVABLE_WORDS = [
  'hero', 'header', 'footer', 'nav', 'button', 'card', 'section',
  'heading', 'h1', 'h2', 'h3', 'text', 'image', 'icon', 'link', 'menu',
  'form', 'input', 'margin', 'padding', 'gap', 'contrast', 'font', 'size',
  'grid', 'alignment', 'whitespace', 'spacing', 'breakpoint', 'viewport',
  'screenshot', 'layout', 'colour', 'color', 'space', 'type', 'tokens',
  'background', 'border', 'radius', 'shadow', 'width', 'height',
];
const GENERIC_EVIDENCE = new Set([
  'looks good', 'looks better', 'looks great', 'looks nice', 'looks good now',
  'much better', 'better now', 'feels good', 'feels premium', 'nice',
  'good', 'fixed', 'fixed it', 'done', 'improved', 'looks fine', 'fine now',
]);

function reject(msg) {
  console.error(`run-log: REJECTED — ${msg} No entry written.`);
  process.exit(2);
}

function basisRestatesGrader(basis, grader) {
  const norm = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, '');
  if (norm(basis) === norm(grader)) return true;
  // Remove every occurrence of the grader label (any separator spelling)
  // and require >= 10 characters of other substance to remain.
  const labelPattern = grader.replace(/-/g, '[-_ ]?');
  const stripped = basis
    .replace(new RegExp(labelPattern, 'gi'), '')
    .replace(/[^A-Za-z0-9]+/g, ' ')
    .trim();
  return stripped.length < 10;
}

// Independence basis must establish BOTH halves (see header): (1) fresh /
// separate context, or a different agent instance; AND (2) no production
// history of the build. Either half alone is rejected — "fresh context"
// alone does not change the weights (rubric A1), and "no production
// history" alone does not help if the judge shares the builder's context.
const FRESH_SIGNALS = [
  /fresh context/,
  /separate context/,
  /new context/,
  /fresh sub-?agent/,
  /no shared context/,
  /different agent/,
  /different model/,
  /separate agent/,
  /independent agent/,
  /different instance/,
  /separate instance/,
  /trained separately/,
  /separately trained/,
];
const NO_HISTORY_SIGNALS = [
  /no production history/,
  /no history of (this|the) build/,
  /never (shown|seen).*?(draft|build)/,
  /not involved in.*build/,
  /no prior involvement/,
];

function basisEstablishesIndependence(basis) {
  const b = basis.toLowerCase();
  const fresh = FRESH_SIGNALS.some((re) => re.test(b));
  const noHistory = NO_HISTORY_SIGNALS.some((re) => re.test(b));
  return { fresh, noHistory, ok: fresh && noHistory };
}

function checkIndependenceBasis(basis, grader) {
  if (!basis || basis.trim().length < 10) {
    reject('--basis must state why this judge counts as independent (10+ characters).');
  }
  if (basisRestatesGrader(basis.trim(), grader)) {
    reject('--basis must not merely restate the grader name: state the independence basis (e.g. "fresh context, no production history").');
  }
  const { fresh, noHistory } = basisEstablishesIndependence(basis.trim());
  if (!fresh || !noHistory) {
    const missing = [!fresh ? 'fresh/separate context (or a different agent instance)' : null, !noHistory ? 'no production history of the build' : null].filter(Boolean).join(' AND ');
    reject(`--basis must establish BOTH halves of independence — missing: ${missing}. "Fresh context" alone is NOT enough (rubric A1). Example: "fresh context, no production history".`);
  }
}

function evidenceNamesObservable(evidence) {
  const ev = evidence.trim();
  if (ev.length < 10) return false;
  const flat = ev.toLowerCase().replace(/[^a-z0-9 ]+/g, '').replace(/\s+/g, ' ').trim();
  if (GENERIC_EVIDENCE.has(flat)) return false;
  if (/\d/.test(ev)) return true;
  const words = ev.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean);
  return words.some((w) => OBSERVABLE_WORDS.includes(w));
}

function usage(msg) {
  if (msg) console.error(`run-log: ${msg}`);
  console.error(`usage:
  node run-log.mjs --project <dir> record --round N --grader <label> --basis "<why independent>" --scores <t,l,c,s|none> --evidence "<...>" --gate <pass|fail> [--variant <name>] [--notes "..."] [--tokens-hash <hex>] [--fix-class "<class>"] [--outcome <kept|discarded|re-pick|stopped|escalated|pending>] [--gate-findings "<...>"] [--page <built.html>]
  node run-log.mjs --project <dir> record --round N --grader none --scores none --gate <pass|fail> [--variant <name>] [--notes "..."]  (no-grade round: grade is exactly "gate green, vision not available")
  node run-log.mjs --project <dir> feedback --from "<human words>" --change "<token diff>" --round N [--score-after <t,l,c,s> --grader <label> --basis "<why independent>" --evidence "<observable element>"] [--fix-class "<class>"]
  node run-log.mjs --project <dir> lock --tokens <path> --refs "<locked direction>" [--version N] [--approved-by "<approval basis>"]
  node run-log.mjs --project <dir> brief [--round N] [--out <file>]
  node run-log.mjs --project <dir> show
  node run-log.mjs --project <dir> best`);
  process.exit(1);
}

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
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

function logPath(project) {
  return path.join(project, 'design', 'run-log.jsonl');
}

function readLog(project) {
  const p = logPath(project);
  if (!fs.existsSync(p)) return [];
  return fs.readFileSync(p, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
}

function appendLog(project, rec) {
  const dir = path.dirname(logPath(project));
  fs.mkdirSync(dir, { recursive: true });
  fs.appendFileSync(logPath(project), JSON.stringify(rec) + '\n');
}

function parseScores(s) {
  if (s === 'none') return null;
  const parts = s.split(',').map((v) => Number(v.trim()));
  if (parts.length !== 4 || parts.some((v) => !Number.isInteger(v) || v < 1 || v > 5)) {
    usage('--scores must be four integers 1-5 (type,layout,colour,space) or "none"');
  }
  return { type: parts[0], layout: parts[1], colour: parts[2], space: parts[3] };
}

// P7: sha256 of a file's bytes, or null when the path does not resolve.
// The hash is what ties a round back to the exact locked tokens — a
// round whose tokensHash differs from the lock's ran against different
// tokens, and the round-brief generator says so instead of assuming.
function sha256File(file) {
  try {
    return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  } catch {
    return null;
  }
}

function resolveTokensPath(project, tokensArg) {
  if (!tokensArg) return path.join(project, 'design', 'tokens.css');
  return path.isAbsolute(tokensArg) ? tokensArg : path.join(project, tokensArg);
}

// P7: explicit --tokens-hash wins; otherwise hash the project's locked
// tokens.css when it exists; otherwise null (never invent a hash).
function resolveTokensHash(project, tokensArg, explicitHash) {
  if (explicitHash !== undefined) {
    if (!/^[0-9a-f]{64}$/i.test(explicitHash)) usage('--tokens-hash must be a 64-character lowercase hex sha256');
    return explicitHash.toLowerCase();
  }
  return sha256File(resolveTokensPath(project, tokensArg));
}

const OUTCOMES = ['kept', 'discarded', 're-pick', 'stopped', 'escalated', 'pending'];

function parseOutcome(s) {
  if (s === undefined) return 'pending';
  if (!OUTCOMES.includes(s)) usage(`--outcome must be one of ${OUTCOMES.join(' | ')}`);
  return s;
}

const args = parseArgs(process.argv.slice(2));
const cmd = args._[0];
if (!args.project) usage('--project <dir> is required');

if (cmd === 'record') {
  const round = Number(args.round);
  if (!Number.isInteger(round) || round < 1) usage('--round must be a positive integer');
  const grader = (args.grader || '').trim();
  if (FORBIDDEN_GRADERS.includes(grader.toLowerCase())) {
    console.error(`run-log: REJECTED — grader "${grader}" is the builder. The builder NEVER grades its own work (user direction 2026-11-10). No entry written.`);
    process.exit(2);
  }
  // No-grade record (probe G-4): --grader none is accepted ONLY with
  // --scores none. It records grader: null and grade exactly "gate green,
  // vision not available" — no invented grader label, no basis. A score
  // with grader none is a grade without a judge: REJECTED.
  const scores = parseScores(args.scores || 'none');
  const noGrade = grader.toLowerCase() === 'none';
  if (noGrade) {
    if (scores) {
      console.error('run-log: REJECTED — --grader none goes with --scores none only. A score IS a grade and needs an independent judge (judge-subagent | muse-manager | other-model). No entry written.');
      process.exit(2);
    }
    if (args.grade !== undefined && args.grade !== 'none') usage('--grader none goes with --scores none and no grade; use a graded record for scores');
    if (!['pass', 'fail'].includes(args.gate)) usage('--gate must be pass or fail');
    const rec = {
      kind: 'round', round, grader: null, independenceBasis: null,
      scores: null, grade: 'gate green, vision not available',
      evidence: null, gate: args.gate,
      gateFindings: args['gate-findings'] || null,
      variant: args.variant || null,
      tokensHash: resolveTokensHash(args.project, undefined, args['tokens-hash']),
      fixClass: args['fix-class'] || null,
      outcome: parseOutcome(args.outcome),
      page: args.page || null,
      notes: args.notes || null,
      at: new Date().toISOString(),
    };
    appendLog(args.project, rec);
    console.log(`run-log: recorded round ${round} (grader: none; grade: gate green, vision not available; gate: ${args.gate})`);
    process.exit(0);
  }
  if (!ALLOWED_GRADERS.includes(grader)) {
    console.error(`run-log: REJECTED — grader "${grader}" is not an allowed independent judge (allowed: ${ALLOWED_GRADERS.join(', ')}; use --grader none with --scores none for a no-grade round). No entry written.`);
    process.exit(2);
  }
  // The basis must establish BOTH halves of independence (fresh/separate
  // context AND no production history) — "fresh context" alone is NOT
  // enough (rubric A1). muse-manager is accepted here exactly when its
  // basis proves it is a DIFFERENT instance with no production history.
  checkIndependenceBasis(args.basis, grader);
  if (scores && (!args.evidence || !args.evidence.trim())) {
    console.error('run-log: REJECTED — scores without evidence are not scores. Pass --evidence with one observable line per score. No entry written.');
    process.exit(2);
  }
  // Same evidence bar as feedback --score-after: a score IS a grade, so
  // evidence attached to a score must name an observable element (10+
  // chars, not a generic impression such as "x" or "looks good").
  if (args.evidence !== undefined && !evidenceNamesObservable(args.evidence)) {
    console.error('run-log: REJECTED — --evidence (10+ characters) must name an observable element, e.g. a named element or a measurement — not a generic impression like "x" or "looks good". No entry written.');
    process.exit(2);
  }
  if (!scores && args.grade !== undefined && args.grade !== 'none') usage('--scores "none" goes with no grade; use --scores t,l,c,s for a graded round');
  if (!['pass', 'fail'].includes(args.gate)) usage('--gate must be pass or fail');
  const rec = {
    kind: 'round', round, grader, independenceBasis: args.basis.trim(),
    scores, grade: scores ? 'graded' : 'gate green, vision not available',
    evidence: args.evidence || null, gate: args.gate,
    gateFindings: args['gate-findings'] || null,
    variant: args.variant || null,
    tokensHash: resolveTokensHash(args.project, undefined, args['tokens-hash']),
    fixClass: args['fix-class'] || null,
    outcome: parseOutcome(args.outcome),
    page: args.page || null,
    notes: args.notes || null,
    at: new Date().toISOString(),
  };
  appendLog(args.project, rec);
  console.log(`run-log: recorded round ${round} (grader: ${grader}; grade: ${rec.grade}; gate: ${args.gate})`);
} else if (cmd === 'feedback') {
  const round = Number(args.round);
  if (!Number.isInteger(round) || round < 1) usage('--round must be a positive integer');
  if (!args.from || !args.change) usage('feedback needs --from "<human words>" and --change "<token diff>"');
  let scoreAfter = null;
  let grader = null;
  if (args['score-after']) {
    // A post-feedback score IS a grade: only an independent judge may give it.
    grader = (args.grader || '').trim();
    if (FORBIDDEN_GRADERS.includes(grader.toLowerCase())) {
      reject(`--score-after needs an independent grader, not "${grader}". The builder NEVER grades its own work (user direction 2026-11-10).`);
    }
    if (!ALLOWED_GRADERS.includes(grader)) {
      reject(`--score-after requires --grader <${ALLOWED_GRADERS.join('|')}>, got "${grader || '(none)'}".`);
    }
    // Same two-half bar as record: fresh/separate context AND no
    // production history; either half alone is rejected.
    checkIndependenceBasis(args.basis, grader);
    if (!args.evidence || !evidenceNamesObservable(args.evidence)) {
      reject('--score-after requires --evidence (10+ characters) naming an observable element, e.g. a named element or a measurement — not a generic impression like "looks good".');
    }
    scoreAfter = parseScores(args['score-after']);
  }
  const rec = {
    kind: 'feedback', round, from: args.from, tokenChange: args.change,
    scoreAfter,
    grader: scoreAfter ? grader : null,
    independenceBasis: scoreAfter ? args.basis.trim() : null,
    evidence: scoreAfter ? args.evidence.trim() : null,
    fixClass: args['fix-class'] || null,
    at: new Date().toISOString(),
  };
  appendLog(args.project, rec);
  console.log(`run-log: recorded feedback for round ${round}: "${args.from}" -> ${args.change}${scoreAfter ? ` (re-graded by ${grader}: T${scoreAfter.type}/L${scoreAfter.layout}/C${scoreAfter.colour}/S${scoreAfter.space})` : ''}`);
} else if (cmd === 'lock') {
  // Taste lock (step 1 "commit"): files saved under design/ AND this entry
  // in the run log. Git commit is separate (only if the project is a git
  // repo) — this command is the run-log half of the commit, and it is
  // required even in a git repo (a git commit without this entry is not a
  // taste lock by the workflow's definition).
  if (!args.tokens || !args.refs) usage('lock needs --tokens <path> and --refs "<locked direction>"');
  // P7 lock version (LOOP-1 follow-up — SKILL.md step 1.8 used to say
  // "record the version number in the run log's notes by hand"): the
  // version is a script field now. Default is (existing lock count + 1);
  // --version N records an explicit version. A re-pick creates a NEW
  // version; re-using an existing version is REJECTED (exit 2) — two
  // locks with one version would make the round brief ambiguous about
  // which lock it restates.
  const existingLocks = readLog(args.project).filter((r) => r.kind === 'taste-lock');
  let lockVersion;
  if (args.version !== undefined) {
    lockVersion = Number(args.version);
    if (!Number.isInteger(lockVersion) || lockVersion < 1) usage('--version must be a positive integer');
    if (existingLocks.some((r) => r.lockVersion === lockVersion)) {
      console.error(`run-log: REJECTED — lock version ${lockVersion} already exists in the run log. A re-pick creates a NEW version (next: ${existingLocks.length + 1}). No entry written.`);
      process.exit(2);
    }
  } else {
    lockVersion = existingLocks.length + 1;
  }
  const rec = {
    kind: 'taste-lock', lockVersion,
    tokens: args.tokens,
    tokensHash: resolveTokensHash(args.project, args.tokens, undefined),
    references: args.refs,
    approvedBy: args['approved-by'] || null,
    notes: args.notes || null,
    at: new Date().toISOString(),
  };
  appendLog(args.project, rec);
  console.log(`run-log: taste locked (version ${lockVersion}) — tokens: ${args.tokens}${rec.tokensHash ? ` (sha256 ${rec.tokensHash.slice(0, 12)}…)` : ' (tokens file not on disk — no hash recorded)'}; refs: ${args.refs}${rec.approvedBy ? `; approved-by: ${rec.approvedBy}` : ''}`);
} else if (cmd === 'show') {
  const rows = readLog(args.project);
  if (!rows.length) { console.log('run-log: no entries yet.'); process.exit(0); }
  for (const r of rows) {
    if (r.kind === 'round') {
      const s = r.scores ? `T${r.scores.type}/L${r.scores.layout}/C${r.scores.colour}/S${r.scores.space}` : 'no grade';
      const g = r.grader ? `grader: ${r.grader} (${r.independenceBasis})` : 'grader: none (gate green, vision not available)';
      console.log(`round ${r.round} | ${g} | ${s} | grade: ${r.grade} | gate: ${r.gate}${r.variant ? ` | variant: ${r.variant}` : ''}${r.tokensHash ? ` | tokens: ${r.tokensHash.slice(0, 12)}…` : ''}${r.fixClass ? ` | fix-class: ${r.fixClass}` : ''}${r.outcome ? ` | outcome: ${r.outcome}` : ''}${r.page ? ` | page: ${r.page}` : ''}${r.notes ? ` | ${r.notes}` : ''}`);
      if (r.gateFindings) console.log(`  gate findings: ${r.gateFindings}`);
      if (r.evidence) console.log(`  evidence: ${r.evidence}`);
    } else if (r.kind === 'feedback') {
      console.log(`feedback (round ${r.round}): "${r.from}" -> ${r.tokenChange}${r.scoreAfter ? ` | after: T${r.scoreAfter.type}/L${r.scoreAfter.layout}/C${r.scoreAfter.colour}/S${r.scoreAfter.space} (grader: ${r.grader || 'MISSING'})` : ''}`);
      if (r.scoreAfter && r.evidence) console.log(`  evidence: ${r.evidence}`);
    } else if (r.kind === 'variant-pick') {
      console.log(`variant pick: "${r.variant}"${r.note ? ` — ${r.note}` : ''}`);
    } else if (r.kind === 'taste-lock') {
      console.log(`taste lock v${r.lockVersion ?? '?'}: tokens: ${r.tokens}${r.tokensHash ? ` (sha256 ${r.tokensHash.slice(0, 12)}…)` : ''}; refs: ${r.references}${r.approvedBy ? `; approved-by: ${r.approvedBy}` : ''}${r.notes ? `; notes: ${r.notes}` : ''} (${r.at})`);
    } else if (r.kind === 'dictionary-overwrite') {
      console.log(`dictionary overwrite: "${r.word}" — was: ${r.previousChange} — now: ${r.newChange} (${r.at})`);
    } else {
      console.log(JSON.stringify(r));
    }
  }
} else if (cmd === 'brief') {
  // P7 (council-C form): the brief command assembles the minimal round
  // brief from this log + the locked files, via round-brief.mjs. The
  // generator is the authority; this command is the single entry point
  // the skill cites, so the orchestrator never has to remember which
  // script builds the brief.
  const { buildBrief } = await import('./round-brief.mjs');
  const round = args.round !== undefined ? Number(args.round) : undefined;
  if (round !== undefined && (!Number.isInteger(round) || round < 1)) usage('--round must be a positive integer');
  let brief;
  try {
    brief = buildBrief(args.project, {
      round,
      page: args.page,
      allowMissing: args['allow-missing'] === 'true' || args['allow-missing'] === '1',
    });
  } catch (e) {
    console.error(`run-log: brief failed — ${e.message}`);
    process.exit(1);
  }
  if (args.out) {
    fs.mkdirSync(path.dirname(path.resolve(args.out)), { recursive: true });
    fs.writeFileSync(args.out, brief + '\n');
    console.log(`run-log: round brief written to ${args.out}`);
  } else {
    console.log(brief);
  }
} else if (cmd === 'best') {
  const rounds = readLog(args.project).filter((r) => r.kind === 'round' && r.scores);
  if (!rounds.length) { console.log('run-log: no graded rounds yet.'); process.exit(0); }
  const total = (s) => s.type + s.layout + s.colour + s.space;
  const best = rounds.reduce((a, b) => (total(b.scores) > total(a.scores) ? b : a));
  console.log(`best: round ${best.round} (grader: ${best.grader}) — T${best.scores.type}/L${best.scores.layout}/C${best.scores.colour}/S${best.scores.space}, total ${total(best.scores)}/20, gate: ${best.gate}`);
} else {
  usage(`unknown command "${cmd || ''}" (record | feedback | lock | brief | show | best)`);
}
