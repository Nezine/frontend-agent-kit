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
// not be recorded at all). A no-grade record stores grader: null and a
// gate-reflecting grade label — "gate green, vision not available" when
// --gate pass, "gate red, no grade" when --gate fail (W-LOOP fix
// 2026-11-11: the old code wrote the green label regardless of --gate,
// so a gate-red round read as green in the grade field) — with NO invented
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
//     purpose, approvedBy, notes, at }. lockVersion auto-increments (1, 2, …);
//     --version N records an explicit version (a re-pick creates a NEW
//     version; re-using an existing version is REJECTED, exit 2).
//     tokensHash is the sha256 of the tokens file when it resolves on
//     disk, else null. approvedBy carries the step-1.7 approval basis for
//     human-less runs ("converge-check + round-1 grade (no human
//     present)"); solo runs record human approval in PLAN.md instead.
//     purpose is the PLAN.md "Purpose + primary user task" section,
//     recorded with the lock (UX-B council decision 2026-11-10); null
//     when the lock was recorded without --purpose.
//   purpose-fail: { kind, action, purpose, notes, at }. action is
//     re-plan (re-derive the section inventory from the revised
//     purpose) or re-pick (record a NEW taste-lock version via `lock`);
//     purpose is the revised purpose from the re-derived plan.
//   crosscheck: { kind, slice, round, severe, warning, waived, verdict,
//     report, checker, independenceBasis, notes, at }. verdict is DERIVED
//     (clear iff severe == 0 and warning == waived), never asserted. The
//     checker must be independent of the builder AND the judge for the
//     slice: basis states BOTH fresh/separate context AND no production
//     history (same two-half rule as a grader basis). report is the
//     cross-check report file (coord/crosscheck/<slice-id>-<n>.md in
//     buffet mode). A blocked verdict is recorded, not rejected — the
//     land is what a blocked verdict stops.
//   land: { kind, slice, round, gate, gateLeg1, gateLeg2, gateLeg1Sha,
//     gateLeg2Sha, page, crosscheckReport, notes, at }.
//     Recorded only when --gate pass AND the LATEST crosscheck verdict
//     for the same slice/round is clear; otherwise REJECTED (exit 2,
//     nothing written). crosscheckReport is copied from that verdict.
//     --gate pass ALSO requires the two gate-leg artifacts (see the
//     --gate-leg1/--gate-leg2 rule below); a land asserting a pass with
//     no artifacts is rejected the same way.
//   round: { kind, round, grader, independenceBasis, scores, grade,
//     evidence, gate, gateLeg1, gateLeg2, gateLeg1Sha, gateLeg2Sha,
//     gateFindings, variant, tokensHash, fixClass,
//     outcome, page, trigger, pairwise, pairwiseAgrees, jury, juryMode,
//     juryVotes, notRegraded, expertMotion, expertMotionEvidence,
//     expertUx, expertUxEvidence, notes, at }. variant is the PICKED variant.
//     tokensHash is --tokens-hash, or the sha256 of
//     <project>/design/tokens.css when present, else null. fixClass is a
//     free-form fix class (e.g. "tokens:colour"); outcome is one of
//     kept | discarded | re-pick | stopped | escalated | pending
//     (default pending). gateFindings is the gate output for the round
//     (;-separated). page is the built HTML file the round graded.
//     trigger (P6) records why the direction ended on this round:
//     flat-line | round-1-repick; stagnation is a RETIRED value for the
//     deleted trigger (c) — accepted so old logs still parse, never
//     emitted by the new rules. pairwise (P11) is the pairwise
//     keep/discard verdict vs the incumbent (keep-incumbent |
//     keep-challenger | tie); pairwiseAgrees is whether that verdict
//     agrees with the absolute-score comparison (true/false). jury (P14)
//     is the stop-round jury median per axis {type,layout,colour,space};
//     juryMode is disjoint-3 | single-family | single; juryVotes is the
//     three per-judge votes (each {type,layout,colour,space}), and when
//     both jury and juryVotes are given the jury MUST be the per-axis
//     median of the votes (otherwise the record is REJECTED).
//     notRegraded (P13, W-LOOP fix 2026-11-11) is the list of section ids
//     the round did NOT re-score because they were unchanged since an
//     earlier round (e.g. ["#hero", "#footer"]) — SECTIONS, not axes:
//     the cheap grade still produces fresh per-axis scores for the whole
//     page; only unchanged sections are not re-scored. Recorded via the
//     --not-regraded flag; --scores always carries four fresh integers
//     or "none" (a "not re-measured" value in --scores is REJECTED —
//     parseScores only accepts integers 1-5). The rubric's score table
//     marks such sections `not re-graded (unchanged since round N)`.
//     expertMotion / expertUx (Wave 6) are the Motion and UX expert
//     second-opinion scores (rubric Motion:/UX: lines — `Motion: <1-5>
//     (motion-expert) — <one-line evidence>`, `UX: <1-5> (ux-expert) —
//     <one-line evidence>`), each an integer 1-5 with one line of
//     observable evidence (expertMotionEvidence / expertUxEvidence).
//     Recorded via --expert-motion / --expert-ux +
//     --expert-motion-evidence / --expert-ux-evidence on ANY round
//     record, graded or no-grade (experts can be consulted even when no
//     independent judge grade exists). ADVISORY to the judge — the judge
//     keeps the final 4-axis scores; expert scores never change a score,
//     never trigger the stop rule, and are never a grade.
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
//     [--gate-leg1 <path> --gate-leg2 <path>]  # REQUIRED with --gate pass (D13, below)
//     [--tokens-hash <sha256 hex>] [--fix-class "<class>"]
//     [--outcome <kept|discarded|re-pick|stopped|escalated|pending>]
//     [--gate-findings "<gate output, ;-separated>"] [--page <built.html>]
//     [--trigger <flat-line|round-1-repick|stagnation>]
//     [--pairwise <keep-incumbent|keep-challenger|tie>]
//     [--pairwise-agrees <yes|no>]
//     [--jury "<type,layout,colour,space median>"]
//     [--jury-mode <disjoint-3|single-family|single>]
//     [--jury-votes "<t,l,c,s; t,l,c,s; t,l,c,s>"]
//     [--not-regraded "<#section,#section>"]   # sections not re-scored
//       (unchanged since an earlier round); --scores stays four fresh
//       integers or "none" — never "not re-measured"
//     [--expert-motion <1-5>] [--expert-motion-evidence "<observable>"]
//     [--expert-ux <1-5>] [--expert-ux-evidence "<observable>"]
//       # Motion/UX expert second opinions (advisory only); allowed on
//       graded and no-grade records alike
//   --tokens-hash defaults to the sha256 of <project>/design/tokens.css
//   when that file exists; --page is the built HTML the round graded
//   (the round-brief generator needs it to find the best HTML).
//   GATE ARTIFACTS (D13, GAP-11 — REQUIRED with --gate pass, on `record`
//   AND `land`): a pass is recorded only with the two leg outputs on
//   disk — leg 1: `design/gate-leg1.log` (gate.sh output, redirected);
//   leg 2: `design/gate-leg2.log` (gate.mjs output, redirected). Pass
//   `--gate-leg1 design/gate-leg1.log --gate-leg2 design/gate-leg2.log`
//   (paths relative to the project, inside design/ — absolute paths and
//   `..` escapes are rejected). Each file must exist, be non-empty, and
//   contain its leg's PASS marker (`GATE RESULT: PASS` / `===== gate
//   verdict: GREEN =====`) as the verdict line itself, and contain no
//   FAIL verdict for their leg; and be at least as new as the page
//   (`--page`, when given) or `design/tokens.css` (when not). `--page`
//   itself must be the built page — an `.html` file inside
//   `design/` (or `design/tokens.css` itself), a real file, never an
//   absolute outside path, never a symlink, never one of the artifact
//   files — and at least as new as `design/tokens.css` (the enforced
//   chain is tokens <= page <= artifacts); it is stored as the
//   canonical project-relative path. Any failure is REJECTED (exit 2,
//   nothing written). `--gate fail` needs no artifact: a bad `--page`
//   there only warns and is recorded as `page: null`. Degraded rungs
//   record `--gate fail` + notes, never a pass. The record stores the
//   relative paths (`gateLeg1`/`gateLeg2`)
//   plus their sha256 (`gateLeg1Sha`/`gateLeg2Sha` — the `*Sha` suffix
//   is mandatory: runlog-check.mjs rule 3 fails bare 64-hex under any
//   other key).
//   --trigger records the P6 trigger that ended the direction on this
//   round (flat-line | round-1-repick); stagnation is RETIRED (deleted
//   trigger (c)) — accepted so old logs still parse, never emitted by
//   the new rules. --pairwise / --pairwise-agrees record the P11
//   pairwise keep/discard verdict and whether it agrees with the
//   absolute-score comparison. --jury / --jury-mode / --jury-votes
//   record the P14 stop-round jury: the per-axis median, the jury mode,
//   and the three per-judge votes; when --jury and --jury-votes are
//   both given, --jury must equal the per-axis median of the votes.
//   Pairwise and jury fields need a graded round: they are REJECTED on
//   a --grader none record (a no-grade round has no scores to compare
//   or to take a median of); --trigger is accepted on any record.
//   record enforces the same evidence bar as feedback --score-after:
//   --evidence, when given, must be 10+ characters naming an observable
//   element (same evidenceNamesObservable rule); a bare --evidence "x"
//   with a score is REJECTED (exit 2, nothing written). A score IS a
//   grade, whichever command records it.
//   No-grade record (ladder rung 3 — "gate green, vision not available"
//   on --gate pass, "gate red, no grade" on --gate fail):
//   node run-log.mjs --project <dir> record --round N --grader none
//     --scores none --gate <pass|fail> [--variant <name>] [--notes "..."]
//     [--gate-leg1 <path> --gate-leg2 <path>]  # REQUIRED with --gate pass (D13)
//     [--expert-motion <1-5>] [--expert-motion-evidence "<observable>"]
//     [--expert-ux <1-5>] [--expert-ux-evidence "<observable>"]
//   --grader none is accepted ONLY with --scores none (and no --evidence
//   score). It records grader: null, grade: "gate green, vision not
//   available". --grader none with scores is REJECTED (a score needs an
//   independent judge); omitting --grader entirely is still a usage error.
//   Expert scores ARE allowed on a no-grade record: an expert second
//   opinion is not a grade, and experts can be consulted even when no
//   independent judge grade exists.
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
//     [--purpose "<PLAN.md Purpose + primary user task section>"]
//   lock records the step-1 taste lock (the "commit" of tokens + chosen
//   references BEFORE any HTML). It appends {kind:'taste-lock'} to the run
//   log; --tokens is required, --refs is required (name the locked
//   direction — a lock with no references is not a lock). --version
//   defaults to (existing lock count + 1); a re-pick records a NEW
//   version. --approved-by records the human-less approval basis
//   (step 1.7); omit it on solo runs (approval lives in PLAN.md).
//   --purpose records the PLAN.md "Purpose + primary user task"
//   section with the lock (UX-B council decision 2026-11-10): the
//   purpose is a lock field, not a plan note. It is optional so
//   existing lock invocations keep working; omit it only when the plan
//   has no Purpose section yet, and record it on the next lock.
//   node run-log.mjs --project <dir> replan --action <re-plan|re-pick>
//     --purpose "<revised purpose from PLAN.md>" [--notes "..."]
//   node run-log.mjs --project <dir> crosscheck --slice <id> [--round N]
//     --severe N --warning N [--waived N] --report <path>
//     --checker <security-expert|crosscheck-subagent|crosscheck-team>
//     --basis "<why this checker counts as independent>"
//   crosscheck records a security/compliance cross-check verdict
//   (BUFFET-MODE.md §14, SKILL.md step 3a). The verdict is DERIVED:
//   clear iff severe == 0 and every warning is fixed-or-waived
//   (warning == waived). The checker must be independent of the builder
//   AND the judge for the slice (same two-half basis as a grader).
//   node run-log.mjs --project <dir> land --slice <id> [--round N]
//     --gate pass [--gate-leg1 <path> --gate-leg2 <path>] [--page <built.html>] [--notes "..."]
//   land records a land/ship decision. It is REJECTED (exit 2, nothing
//   written) unless --gate pass AND the LATEST crosscheck verdict for
//   the same slice/round is clear. A land without a cross-check verdict
//   is never recorded — landing without a cross-check is forbidden,
//   exactly as landing without a gate is (F32).
//   replan records a purpose failure's resolution: re-plan re-derives
//   the section inventory from the revised purpose; re-pick records a
//   NEW taste-lock version (via `lock`). The decision is recorded in
//   the run log; a purpose failure is never resolved by an unenforced
//   plan note, and the inventory is never patched in place to fit a
//   changed purpose.
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
//   independent grader, a duplicate lock version, a checker without a
//   two-half independence basis, a land without a clear cross-check
//   verdict, or a --gate pass without both gate-leg artifacts).

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const ALLOWED_GRADERS = ['judge-subagent', 'muse-manager', 'other-model'];
const ALLOWED_CHECKERS = ['security-expert', 'crosscheck-subagent', 'crosscheck-team'];
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
  node run-log.mjs --project <dir> record --round N --grader <label> --basis "<why independent>" --scores <t,l,c,s|none> --evidence "<...>" --gate <pass|fail> [--gate-leg1 <path> --gate-leg2 <path>] [--variant <name>] [--notes "..."] [--tokens-hash <hex>] [--fix-class "<class>"] [--outcome <kept|discarded|re-pick|stopped|escalated|pending>] [--gate-findings "<...>"] [--page <built.html>] [--trigger <flat-line|round-1-repick|stagnation>] [--pairwise <keep-incumbent|keep-challenger|tie>] [--pairwise-agrees <yes|no>] [--jury "<t,l,c,s median>"] [--jury-mode <disjoint-3|single-family|single>] [--jury-votes "<v1;v2;v3>"] [--not-regraded "<#section,#section>"] [--expert-motion <1-5>] [--expert-motion-evidence "<observable>"] [--expert-ux <1-5>] [--expert-ux-evidence "<observable>"]
  node run-log.mjs --project <dir> record --round N --grader none --scores none --gate <pass|fail> [--gate-leg1 <path> --gate-leg2 <path>] [--variant <name>] [--notes "..."] [--expert-motion <1-5>] [--expert-motion-evidence "<observable>"] [--expert-ux <1-5>] [--expert-ux-evidence "<observable>"]  (no-grade round: grade is "gate green, vision not available" when --gate pass, "gate red, no grade" when --gate fail; expert scores allowed)
  node run-log.mjs --project <dir> feedback --from "<human words>" --change "<token diff>" --round N [--score-after <t,l,c,s> --grader <label> --basis "<why independent>" --evidence "<observable element>"] [--fix-class "<class>"]
  node run-log.mjs --project <dir> lock --tokens <path> --refs "<locked direction>" [--version N] [--approved-by "<approval basis>"] [--purpose "<purpose from PLAN.md>"]
  node run-log.mjs --project <dir> replan --action <re-plan|re-pick> --purpose "<revised purpose from PLAN.md>" [--notes "..."]
  node run-log.mjs --project <dir> crosscheck --slice <id> [--round N] --severe N --warning N [--waived N] --report <path> --checker <security-expert|crosscheck-subagent|crosscheck-team> --basis "<why independent>"
  node run-log.mjs --project <dir> land --slice <id> [--round N] --gate pass [--gate-leg1 <path> --gate-leg2 <path>] [--page <built.html>] [--notes "..."]
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
      // Boolean flags take no value (currently only --allow-missing on
      // `brief`); every other --flag consumes the next token.
      if (key === 'allow-missing') { out[key] = true; continue; }
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

// D13 (GAP-11): a --gate pass is a CLAIM about two gate runs, and a claim
// with no artifact behind it is a self-assertion — the exact defect the
// installed skill could not close (the gate scripts were not in the
// installed copy, so no artifact could exist). `record` and `land` refuse
// --gate pass unless BOTH leg artifacts are cited and check out:
//   --gate-leg1 <path> --gate-leg2 <path>, each a path relative to the
//     project, resolving inside <project>/design/ (absolute paths and
//     `..` escapes are rejected);
//   each file exists, is a non-empty real file (symlinks rejected —
//     F2), and contains its leg's PASS marker as its verdict line —
//     leg 1: `GATE RESULT: PASS` (gate.sh prints it only on its exit-0
//     path); leg 2: `===== gate verdict: GREEN =====` (gate.mjs prints
//     it only when worst === 0) — and no FAIL verdict for its leg (F5:
//     a comment mentioning PASS, or an appended old PASS above a new
//     FAIL, is not a pass; R4: the FAIL check is per-line with a word
//     boundary, so FAILURE/FAILED do not match); the two legs must be
//     two distinct files, by resolved path and by device+inode (F4 —
//     a hardlink pair is one file, not two legs); `design/` itself
//     must resolve inside the project (R1 — a symlinked `design/`
//     pointing outside the project is rejected; pointing inside is
//     accepted); `--page`, when given, must be the built page — an
//     `.html` file inside `design/` (or `design/tokens.css` itself),
//     a real file, never an artifact file (R2 — compared by
//     device+inode as well as realpath, so a hardlink to a leg is
//     caught), and at least as new as `design/tokens.css` (R3 — the
//     enforced chain is tokens <= page <= artifacts; the fallback
//     `design/tokens.css` must itself be a non-symlink regular file),
//     and is stored canonically project-relative, never verbatim;
//   freshness: each artifact's mtime must be >= the built page's mtime
//     when --page is given, else >= design/tokens.css's mtime (equal
//     mtimes allowed — same-second writes). A stale artifact is a claim
//     about a different build.
// On any failed check: REJECTED (exit 2, nothing written). --gate fail
// needs no artifact — and a bad --page on the fail path only warns
// (R5): the fail is recorded with page: null instead of refused.
// The recorded paths are project-relative; the sha256
// pins the bytes. The `*Sha` suffix is MANDATORY: runlog-check.mjs rule 3
// fails a bare >=32-hex value under any other key, so `gateLeg1Hash`
// would make the NEXT gate run fail §6 1.1 on the run log itself.
// Residual, stated openly: deliberate fabrication of the artifact files
// is still possible. The mechanism converts the defect from
// accidental-and-invisible to deliberate-and-auditable (the artifact is
// on disk; QC re-running the gate reproduces or contradicts it).
// Signing gate output is out of scope.
const GATE_LEG_MARKERS = {
  leg1: 'GATE RESULT: PASS',
  leg2: '===== gate verdict: GREEN =====',
};
// A leg artifact that also carries its leg's FAIL verdict is not a pass,
// however the PASS string got in there (a comment, an appended old run).
// Checked per line with a word boundary (R4): a trimmed line matches
// the FAIL marker only when FAIL is NOT followed by a letter, so
// FAILURE/FAILED do not match but `FAIL (...)`, `FAIL (exit 1)` and
// bare FAIL do.
const GATE_LEG_FAIL_MARKERS = {
  leg1: 'GATE RESULT: FAIL',
  leg2: 'gate verdict: FAIL',
};
// Fix round 5 (F2/F3/F4) + fix round 6 (F7/F9): verdict lines are
// canonicalised before comparison by stripInvisible(), which first
// NFD-normalises the line (canonical decomposition: a precomposed
// letter becomes base letter + combining mark) and then deletes
// every invisible character, comparing what remains. The strip set:
//   \s  — all Unicode White_Space (U+0009–U+000D, U+0020, U+00A0,
//         U+1680, U+2000–U+200A, U+2028, U+2029, U+202F, U+205F,
//         U+3000, U+FEFF)
//   \p{C} — all controls, formats, surrogates, private-use and
//         unassigned (Cc, Cf, Cs, Co, Cn) — this is the whole
//         zero-width set, the whole Cf set (U+2060, U+200E/U+200F,
//         bidi controls, U+00AD, U+2061–U+2064), U+180E, and U+FEFF
//   \p{M} — all marks (Mn, Mc, Me) — this is the variation selectors
//         (U+FE00–U+FE0F, U+E0100–U+E01EF) and every combining mark
//   U+FFFD — REPLACEMENT CHARACTER: the footprint of a byte that did
//         not survive copying, where it was INSERTED as extra noise
//         between letters. It does NOT recover a byte that REPLACED
//         a letter — the letter is gone (F8 residual, below).
//   F7 denylist — blank-rendering characters in the Lo/So classes,
//         which no property class above covers: U+115F HANGUL
//         CHOSEONG FILLER, U+1160 HANGUL JUNGSEONG FILLER, U+3164
//         HANGUL FILLER, U+FFA0 HALFWIDTH HANGUL FILLER, U+2800
//         BRAILLE PATTERN BLANK, U+303F IDEOGRAPHIC HALF FILL SPACE,
//         U+13441 EGYPTIAN HIEROGLYPH FULL BLANK, U+13442 EGYPTIAN
//         HIEROGLYPH HALF BLANK. Found by a sweep of all Lo/So code
//         points (Python unicodedata, names containing FILLER or
//         BLANK, plus supplementary probes for SPACE, EMPTY, NULL,
//         INVISIBLE and ZERO WIDTH, with U+303F found by the SPACE
//         probe); the sweep found no other blank-rendering Lo/So
//         code point except U+2422 BLANK SYMBOL, which renders
//         visibly (a control picture) and is deliberately NOT stripped.
// One canonicalisation replaces the round-4 two-variant design
// (strip vs map-to-space): mapping an invisible character to a space
// splits words (an exotic space inside FAIL hid the FAIL verdict;
// a ZWSP inside FAILURE made the R4 boundary match), while stripping
// alone missed a character substituting for a space. Deleting every
// invisible character subsumes both variants — `GATE RESULT: PASS`
// strips to `GATERESULT:PASS` on both sides of the comparison, and
// so does every line either variant accepted — and strictly more.
// Visible characters are NEVER stripped: a line differing from the
// marker by a visible character still rejects, and a comment line
// still cannot match the marker (the `#` survives stripping).
// What this does NOT cover (honest boundary, fix round 6):
//   — Substitution (F8): stripping recovers INSERTED noise only.
//     When a stripped character REPLACES a letter (F<FFFD>IL, or a
//     real invalid byte 0xFF in place of the A), the word is a
//     different, shorter word and no normaliser can recover it —
//     such a line records as a pass. Known limitation, pinned by
//     §5b cases (80)–(81); do NOT attempt fuzzy/near-miss matching.
//   — Blank Lo/So outside the denylist: none known after the sweep
//     above, but the denylist is a list, not a property — a future
//     blank-rendering character in an uncovered class would escape
//     it. This is NOT a closed set: round 5 claimed no future
//     invisible code point could escape \s, \p{C} or \p{M}, and
//     the F7 Lo/So characters disproved it.
//   — Homoglyphs (visible letters, e.g. Cyrillic A in FAIL): by
//     design — a visible character difference is not invisible
//     unicode, and no invisible-character normaliser folds it.
//   — NFD is canonical decomposition only (NOT NFKD): it does not
//     fold ligatures or fullwidth letters, which stay visible and
//     still reject.
// The line AND the marker go through the same canonicalisation
// (the marker is data too): the FAIL check strips the marker the
// same way as the line, or the check is dead code that still passes
// the PASS side. The regex itself is ASCII property escapes plus
// backslash-u escapes (four-digit and braced forms); no literal
// invisible characters in source.
const stripInvisible = (line) => line.normalize('NFD').replace(/[\s\p{C}\p{M}\uFFFD\u115F\u1160\u2800\u303F\u3164\uFFA0\u{13441}\u{13442}]/gu, '');

function validateGateArtifacts(project, args) {
  // Returns { gateLeg1, gateLeg2, gateLeg1Sha, gateLeg2Sha, page } when
  // --gate is pass; when --gate is fail the gate fields are null (no
  // artifact required, none recorded) but `page` is still the validated,
  // canonicalised --page (or null when --page is absent — or when it
  // fails validation, R5, with a stderr warning) — so a stored page
  // is never an absolute outside path on either path. Rejects
  // (exit 2, nothing written) on any failed check on the pass path.
  //
  // Rules (fix round 1, red-team F2–F5):
  //   F2 — no symlinks, no realpath escape: each leg is lstat-checked
  //     (a symlink is rejected outright, matching gate.sh's own stance)
  //     and its realpath must lie inside the realpath of <project>/design/.
  //     Lexical containment alone is not containment.
  //   F3 — --page, when given, must be a regular file (not a symlink)
  //     resolving inside the project (realpath), must not be either leg
  //     artifact file, and is stored as the canonical project-relative
  //     path — never verbatim, never absolute-outside. The freshness
  //     reference is that validated page; without --page it is
  //     design/tokens.css, which must likewise resolve inside design/.
  //     (Fix round 2, re-red-team R2/R3/R5: the artifact check also
  //     compares device+inode, so a hardlink to a leg is caught; the
  //     page must be the built page — an .html file inside design/,
  //     or tokens.css itself — and at least as new as tokens.css, so
  //     the chain tokens <= page <= artifacts holds; on --gate fail a
  //     bad --page only warns and is recorded as page: null.)
  //   F4 — the two legs must be two files: the resolved paths must
  //     differ AND the device+inode pairs must differ (a hardlink pair
  //     shares one inode and is rejected too).
  //   F5 — the PASS marker must be the verdict line itself (a line whose
  //     trimmed content equals the marker exactly — a comment mentioning
  //     the string does not count), and a file containing its leg's FAIL
  //     marker is rejected even if a PASS string also appears in it
  //     (an appended re-run concatenating an old PASS and a new FAIL
  //     is a FAIL, not a pass). (Fix round 2, R4: the FAIL check is
  //     per-line with a word boundary — FAILURE/FAILED do not match.)
  //     (Fix round 5, F2/F3/F4 + fix round 6, F7/F9: both verdict
  //     lines are canonicalised first — stripInvisible() NFD-normalises
  //     then deletes every invisible character (\s White_Space,
  //     \p{C} controls/formats, \p{M} marks, U+FFFD, the F7 Lo/So
  //     denylist) and the comparison runs on what remains, so invisible
  //     unicode in a copied verdict line neither false-rejects a PASS
  //     nor hides a FAIL, in any position. The R4 word boundary is
  //     evaluated on the stripped string. S2: --page needs a non-empty
  //     basename before `.html`. S1: the --page anchor below also
  //     requires tokens.css to be a regular file, mirroring the
  //     fallback.)
  //   R1 (fix round 2) — design/ itself must resolve inside the
  //     project: a symlinked design/ pointing outside the project is
  //     rejected; pointing inside is accepted (containment, not
  //     outright rejection). Checked on the --gate pass path, on both
  //     `record` and `land` (the validator is shared).
  const projectReal = (() => { try { return fs.realpathSync(project); } catch { return path.resolve(project); } })();
  const designDir = path.resolve(project, 'design');
  let designReal;
  try { designReal = fs.realpathSync(designDir); } catch { designReal = path.join(projectReal, 'design'); }
  const inside = (realPath, realDir) => realPath === realDir || realPath.startsWith(realDir + path.sep);
  // Canonical leg-artifact locations, for the --page must-not-be-an-artifact
  // rule (applies on both gate values, even when no legs are cited).
  const canonicalLegReals = ['gate-leg1.log', 'gate-leg2.log'].map((n) => {
    try { return fs.realpathSync(path.join(designDir, n)); } catch { return path.join(designReal, n); }
  });
  const legs = {};
  if (args.gate === 'pass') {
    // R1: design/ itself must resolve inside the project — a symlinked
    // design/ pointing outside would make every "inside design/" check
    // pass for outside files. A symlinked design/ pointing INSIDE the
    // project is accepted (containment, not outright rejection).
    if (!inside(designReal, projectReal)) reject(`<project>/design/ resolves outside the project (real path ${designReal}) — a design/ directory outside the project cannot hold gate artifacts.`);
    for (const [leg, flag, marker, failMarker] of [
      ['leg1', 'gate-leg1', GATE_LEG_MARKERS.leg1, GATE_LEG_FAIL_MARKERS.leg1],
      ['leg2', 'gate-leg2', GATE_LEG_MARKERS.leg2, GATE_LEG_FAIL_MARKERS.leg2],
    ]) {
      const legName = leg === 'leg1' ? 'gate.sh' : 'gate.mjs';
      const given = args[flag];
      if (!given) reject(`--gate pass needs --${flag} <path> (the ${legName} output file under design/). A gate pass with no artifact is a self-assertion, not a record.`);
      if (path.isAbsolute(given)) reject(`--${flag} must be a path relative to the project, inside design/ — absolute paths are rejected (got "${given}").`);
      const resolved = path.resolve(project, given);
      if (resolved !== designDir && !resolved.startsWith(designDir + path.sep)) reject(`--${flag} must resolve inside <project>/design/ (got "${given}" — '..' escapes are rejected).`);
      let lstat;
      try { lstat = fs.lstatSync(resolved); } catch { reject(`--${flag} file does not exist: ${given} (run the ${legName} leg first and save its output there).`); }
      if (lstat.isSymbolicLink()) reject(`--${flag} file ${given} is a symlink — gate artifacts must be real files inside <project>/design/, not links to files elsewhere.`);
      let stat;
      try { stat = fs.statSync(resolved); } catch { reject(`--${flag} file does not exist: ${given} (run the ${legName} leg first and save its output there).`); }
      if (!stat.isFile() || stat.size === 0) reject(`--${flag} file is empty or not a file: ${given}.`);
      let real;
      try { real = fs.realpathSync(resolved); } catch { reject(`--${flag} file cannot be resolved: ${given}.`); }
      if (!inside(real, designReal)) reject(`--${flag} file ${given} resolves outside <project>/design/ (real path ${real}) — a link or mount escaping design/ is rejected.`);
      const text = fs.readFileSync(resolved, 'utf8');
      // R4: per-line FAIL check with a word boundary — a stripped line
      // matches the stripped FAIL marker only when FAIL is NOT followed
      // by a letter, so FAILURE/FAILED do not match but `FAIL (...)`,
      // `FAIL (exit 1)` and bare FAIL do. (Fix round 5, F2/F3/F4 + fix
      // round 6, F7/F9: line and marker are NFD-normalised and stripped
      // first — every invisible character deleted — so a FAIL verdict
      // copied with invisible unicode still rejects, and the boundary
      // is evaluated on the stripped string, so a split FAILURE does
      // not match.)
      const hasFailVerdict = text.split('\n').some((line) => {
        const stripped = stripInvisible(line);
        const strippedMarker = stripInvisible(failMarker);
        let idx = stripped.indexOf(strippedMarker);
        while (idx !== -1) {
          const next = stripped[idx + strippedMarker.length];
          if (next === undefined || !/[A-Za-z]/.test(next)) return true;
          idx = stripped.indexOf(strippedMarker, idx + 1);
        }
        return false;
      });
      if (hasFailVerdict) reject(`--${flag} file ${given} contains its leg's FAIL verdict ("${failMarker}") — the gate leg did not pass on this build, even if a PASS string also appears in the file.`);
      // (Fix round 5, F2/F3/F4 + fix round 6, F7/F9: the PASS line is
      // NFD-normalised and stripped the same way as the FAIL check
      // above and compared by exact equality, so invisible unicode in
      // a copied verdict line does not false-reject a real pass, in
      // any position.)
      const verdictLine = text.split('\n').some((line) => stripInvisible(line) === stripInvisible(marker));
      if (!verdictLine) reject(`--${flag} file ${given} does not contain its leg's PASS marker ("${marker}") as the verdict line — the gate leg did not pass on this build.`);
      const field = leg === 'leg1' ? 'Leg1' : 'Leg2';
      legs[leg] = {
        resolved, real, stat,
        rel: path.relative(project, resolved),
        sha: crypto.createHash('sha256').update(fs.readFileSync(resolved)).digest('hex'),
        field,
      };
    }
    // F4: two legs, two files — same resolved path, or same device+inode
    // (a hardlink pair), is one file cited twice, not two legs.
    if (legs.leg1.resolved === legs.leg2.resolved) reject('--gate-leg1 and --gate-leg2 cite the same file — the two legs must be two separate artifact files.');
    if (legs.leg1.stat.dev === legs.leg2.stat.dev && legs.leg1.stat.ino === legs.leg2.stat.ino) reject('--gate-leg1 and --gate-leg2 are the same file (same device+inode — a hardlink pair) — the two legs must be two separate artifact files.');
  }
  // F3 (fix round 1) + R2/R3/R5 (fix round 2): --page validation —
  // runs on both gate values, whenever --page is given, so the stored
  // page is always a canonical in-project path. On --gate pass a failed
  // check REJECTS (exit 2, nothing written). On --gate fail a failed
  // check only warns (R5): the fail is recorded with page: null,
  // because a fail record needs no artifact at all and refusing it
  // would lose the record of the failure itself.
  let pageRel = null;
  let refStat = null;
  let refLabel = 'design/tokens.css';
  // tokens.css identity, best-effort (for the --page == tokens.css
  // exception in the shape rule, and for the R3 anchor / fallback on
  // the pass path — a missing tokens.css is rejected there, below).
  const tokensPath = path.join(designDir, 'tokens.css');
  let tokensReal = null;
  let tokensStat = null;
  let tokensLstat = null;
  try { tokensReal = fs.realpathSync(tokensPath); } catch { /* missing: pass path rejects below */ }
  try { tokensStat = fs.statSync(tokensPath); } catch { /* missing: pass path rejects below */ }
  try { tokensLstat = fs.lstatSync(tokensPath); } catch { /* missing: pass path rejects below */ }
  if (args.page) {
    // pageFail: hard reject on the pass path; throw (caught below, warn
    // + drop the page) on the fail path. reject() exits, so the throw
    // only ever happens on the fail path.
    const pageFail = (msg) => { if (args.gate === 'fail') throw new Error(msg); reject(msg); };
    try {
      const given = args.page;
      const resolved = path.resolve(project, given);
      let lstat;
      try { lstat = fs.lstatSync(resolved); } catch { pageFail(`--page file does not exist: ${given} (the built page of this project).`); }
      if (lstat.isSymbolicLink()) pageFail(`--page file ${given} is a symlink — the built page must be a real file inside the project, not a link to a file elsewhere.`);
      let real;
      try { real = fs.realpathSync(resolved); } catch { pageFail(`--page file cannot be resolved: ${given}.`); }
      if (!inside(real, projectReal)) pageFail(`--page must resolve inside the project (got "${given}" — an outside file cannot be the freshness reference for this build).`);
      let stat;
      try { stat = fs.statSync(real); } catch { pageFail(`--page file does not exist: ${given}.`); }
      if (!stat.isFile()) pageFail(`--page must be a regular file (got "${given}").`);
      // R2: an artifact cannot be its own freshness reference — compare
      // by device+inode as well as realpath string (a hardlink shares
      // the inode but has a different realpath).
      const sameFile = (a, b) => a && b && a.dev === b.dev && a.ino === b.ino;
      let isArtifact = canonicalLegReals.includes(real)
        || (legs.leg1 && legs.leg1.real === real) || (legs.leg2 && legs.leg2.real === real)
        || (legs.leg1 && sameFile(stat, legs.leg1.stat)) || (legs.leg2 && sameFile(stat, legs.leg2.stat));
      if (!isArtifact) {
        for (const legReal of canonicalLegReals) {
          try { const legStat = fs.statSync(legReal); if (sameFile(stat, legStat)) { isArtifact = true; break; } } catch { /* canonical leg file absent */ }
        }
      }
      if (isArtifact) pageFail(`--page ${given} is one of the gate artifact files — an artifact cannot be its own freshness reference.`);
      // R3 shape: --page must be the built page — an .html file inside
      // <project>/design/. The one exception is design/tokens.css
      // itself (by path, realpath, or device+inode — including a
      // hardlink to it): it IS the no---page fallback reference, so
      // citing it is citing the reference, not an attacker-chosen one.
      const isTokensRef = resolved === tokensPath || real === tokensReal || sameFile(stat, tokensStat);
      if (!isTokensRef) {
        if (!inside(real, designReal)) pageFail(`--page ${given} must resolve inside <project>/design/ — the freshness reference is the built page (got "${given}").`);
        // Fix round 3 (S2): the basename must have at least one
        // character before `.html` — a dotfile named exactly `.html`
        // is not a built page. The extension stays case-insensitive
        // (uppercase `.HTML` is HTML and still passes).
        if (!real.toLowerCase().endsWith('.html') || path.basename(real).length <= 5) pageFail(`--page ${given} must be an .html file inside <project>/design/ — the freshness reference is the built page (got "${given}").`);
      }
      // R3 anchor (pass path only): the reference must be at least as
      // new as tokens.css — the enforced chain is
      // tokens <= page <= artifacts. tokens.css is written at
      // taste-lock time, before the build, so any genuine built page
      // is at least as fresh as the tokens it was built from. A
      // missing/unreadable or symlinked tokens.css cannot anchor:
      // fail closed. (The anchor check also runs when the page IS
      // tokens.css, where it holds trivially — same mtime.)
      if (args.gate === 'pass') {
        if (!tokensStat) pageFail(`--page freshness cannot be anchored: design/tokens.css does not exist or cannot be read.`);
        if (tokensLstat && tokensLstat.isSymbolicLink()) pageFail(`design/tokens.css is a symlink — the freshness anchor must be the real tokens file, not a link.`);
        // Fix round 3 (S1): the anchor must be a regular file, mirroring
        // the no---page fallback below — a directory named tokens.css
        // is not the tokens file, even with a fresh-looking mtime.
        if (!tokensStat || !tokensStat.isFile()) pageFail(`design/tokens.css is not a regular file — the freshness anchor must be the real tokens file, not a directory.`);
        if (tokensStat && stat.mtimeMs < tokensStat.mtimeMs) pageFail(`--page ${given} is older than design/tokens.css — a page older than the locked tokens is a claim about a different build. Rebuild and re-gate.`);
      }
      pageRel = path.relative(projectReal, real);
      refStat = stat;
      refLabel = `--page ${pageRel}`;
    } catch (e) {
      // R5: on --gate fail, a bad --page only warns and is dropped.
      if (args.gate === 'fail') {
        console.error(`run-log: WARNING — --page "${args.page}" ignored: ${e.message} Recording the fail with page: null.`);
        pageRel = null;
        refStat = null;
      } else {
        throw e;
      }
    }
  }
  if (args.gate !== 'pass') {
    return { gateLeg1: null, gateLeg2: null, gateLeg1Sha: null, gateLeg2Sha: null, page: pageRel };
  }
  // Freshness: each artifact must be at least as new as the build it
  // claims to cover — the validated page when --page is given, else
  // design/tokens.css (which must itself resolve inside design/).
  if (!refStat) {
    // R3 fallback: the reference IS design/tokens.css — it must be a
    // non-symlink regular file inside design/ (a symlinked tokens.css
    // pointing at an old in-design file is not the tokens file). The
    // anchor rule is trivially satisfied on this path (the reference
    // IS tokens.css), so the lstat rejection is what closes A8b.
    if (tokensLstat && tokensLstat.isSymbolicLink()) reject(`design/tokens.css is a symlink — the freshness reference must be the real tokens file, not a link.`);
    if (!tokensStat || !tokensStat.isFile()) reject(`--gate-leg1 freshness cannot be checked: design/tokens.css does not exist or is not a regular file.`);
    if (!tokensReal || !inside(tokensReal, designReal)) reject(`design/tokens.css resolves outside <project>/design/ — it cannot be the freshness reference.`);
    refStat = tokensStat;
  }
  for (const leg of ['leg1', 'leg2']) {
    const legName = leg === 'leg1' ? 'gate.sh' : 'gate.mjs';
    const flag = leg === 'leg1' ? 'gate-leg1' : 'gate-leg2';
    if (legs[leg].stat.mtimeMs < refStat.mtimeMs) reject(`--${flag} file ${legs[leg].rel} is older than ${refLabel} — a stale artifact is a claim about a different build. Re-run the ${legName} leg.`);
  }
  return {
    gateLeg1: legs.leg1.rel, gateLeg2: legs.leg2.rel,
    gateLeg1Sha: legs.leg1.sha, gateLeg2Sha: legs.leg2.sha,
    page: pageRel,
  };
}

const OUTCOMES = ['kept', 'discarded', 're-pick', 'stopped', 'escalated', 'pending'];

function parseOutcome(s) {
  if (s === undefined) return 'pending';
  if (!OUTCOMES.includes(s)) usage(`--outcome must be one of ${OUTCOMES.join(' | ')}`);
  return s;
}

// P6 trigger (stop-rules.md): which trigger ended the direction on this
// round. `stagnation` is the RETIRED value for the deleted trigger (c) —
// accepted so old logs still parse, never emitted by the new rules.
const TRIGGERS = ['flat-line', 'round-1-repick', 'stagnation'];

function parseTrigger(s) {
  if (s === undefined) return null;
  if (!TRIGGERS.includes(s)) usage(`--trigger must be one of ${TRIGGERS.join(' | ')} (stagnation is retired — accepted for old logs only, never emitted by the new rules)`);
  return s;
}

// P11 pairwise verdict vs the incumbent (best-version-kept is decided by
// this verdict when pairwise runs, by absolute scores otherwise).
const PAIRWISE_VERDICTS = ['keep-incumbent', 'keep-challenger', 'tie'];

function parsePairwise(s) {
  if (s === undefined) return null;
  if (!PAIRWISE_VERDICTS.includes(s)) usage(`--pairwise must be one of ${PAIRWISE_VERDICTS.join(' | ')}`);
  return s;
}

function parsePairwiseAgrees(s) {
  if (s === undefined) return null;
  if (s === 'yes') return true;
  if (s === 'no') return false;
  usage('--pairwise-agrees must be yes or no');
  return null;
}

// P14 stop-round jury: a "t,l,c,s" score set (same 1–5 shape as --scores).
function parseJuryScores(s, flag) {
  const parts = s.split(',').map((v) => Number(v.trim()));
  if (parts.length !== 4 || parts.some((v) => !Number.isInteger(v) || v < 1 || v > 5)) {
    usage(`${flag} must be four integers 1-5 (type,layout,colour,space)`);
  }
  return { type: parts[0], layout: parts[1], colour: parts[2], space: parts[3] };
}

function parseJury(s) {
  if (s === undefined) return null;
  return parseJuryScores(s, '--jury');
}

const JURY_MODES = ['disjoint-3', 'single-family', 'single'];

function parseJuryMode(s) {
  if (s === undefined) return null;
  if (!JURY_MODES.includes(s)) usage(`--jury-mode must be one of ${JURY_MODES.join(' | ')}`);
  return s;
}

function parseJuryVotes(s) {
  if (s === undefined) return null;
  const votes = s.split(';').map((v) => v.trim()).filter(Boolean);
  if (votes.length !== 3) usage('--jury-votes must be three votes, ";"-separated, each four integers 1-5 (type,layout,colour,space)');
  return votes.map((v) => parseJuryScores(v, '--jury-votes'));
}

// P13 --not-regraded (W-LOOP fix 2026-11-11): comma-separated SECTION ids
// the round did not re-score because they were unchanged since an earlier
// round (e.g. "#hero,#footer"). Sections, not axes — the cheap grade still
// produces fresh per-axis scores for the whole page. --scores always
// carries four fresh integers or "none"; a "not re-measured" value in
// --scores is rejected by parseScores.
function parseNotRegraded(s) {
  if (s === undefined) return null;
  const ids = s.split(',').map((v) => v.trim()).filter(Boolean);
  if (!ids.length) usage('--not-regraded needs at least one section id, e.g. "#hero,#footer"');
  for (const id of ids) {
    if (!/^#[A-Za-z][\w-]*$/.test(id)) usage(`--not-regraded section ids must look like "#hero" (got "${id}")`);
  }
  return [...new Set(ids)];
}

// Wave 6 — expert second-opinion scores (Motion/UX, rubric Motion:/UX:
// lines). One integer 1-5 each; a score without its one-line evidence is
// a usage error, and evidence without its score is too. Same observable
// bar as --evidence (evidenceNamesObservable), checked by the caller.
function parseExpertScore(s, flag) {
  if (s === undefined) return null;
  const v = Number(s);
  if (!Number.isInteger(v) || v < 1 || v > 5) usage(`${flag} must be an integer 1-5`);
  return v;
}

function parseExpert(s, evidence, flag, evidenceFlag) {
  const score = parseExpertScore(s, flag);
  if (score === null && evidence !== undefined) usage(`${evidenceFlag} needs its ${flag} score`);
  if (score !== null && evidence === undefined) usage(`${flag} needs its ${evidenceFlag} (one line naming an observable element)`);
  if (score !== null && !evidenceNamesObservable(evidence)) {
    console.error(`run-log: REJECTED — ${evidenceFlag} (10+ characters) must name an observable element, e.g. a named element or a measurement — not a generic impression like "x" or "looks good". No entry written.`);
    process.exit(2);
  }
  return { score, evidence: evidence === undefined ? null : evidence.trim() };
}

function median3(a, b, c) {
  return [a, b, c].sort((x, y) => x - y)[1];
}

// The jury median is definitional (P14: median per axis): a --jury that is
// not the per-axis median of --jury-votes is an inconsistent record.
function checkJuryMedian(jury, juryVotes) {
  if (!jury || !juryVotes) return;
  for (const axis of ['type', 'layout', 'colour', 'space']) {
    const median = median3(juryVotes[0][axis], juryVotes[1][axis], juryVotes[2][axis]);
    if (jury[axis] !== median) {
      reject(`--jury ${axis} is ${jury[axis]} but the per-axis median of --jury-votes is ${median}. The jury median is definitional (P14) — record the median, not a different number.`);
    }
  }
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
  // --scores none. It records grader: null and a gate-reflecting grade
  // label — "gate green, vision not available" on --gate pass, "gate red,
  // no grade" on --gate fail — no invented grader label, no basis. A score
  // with grader none is a grade without a judge: REJECTED.
  const scores = parseScores(args.scores || 'none');
  const noGrade = grader.toLowerCase() === 'none';
  // P6/P11/P14 record fields. Pairwise and jury need a graded round (a
  // no-grade round has no scores to compare or to take a median of);
  // --trigger is accepted on any record. --not-regraded likewise needs
  // a graded round: a no-grade round scored nothing, so "sections not
  // re-scored" is meaningless on it.
  const trigger = parseTrigger(args.trigger);
  const pairwise = parsePairwise(args.pairwise);
  const pairwiseAgrees = parsePairwiseAgrees(args['pairwise-agrees']);
  const jury = parseJury(args.jury);
  const juryMode = parseJuryMode(args['jury-mode']);
  const juryVotes = parseJuryVotes(args['jury-votes']);
  const notRegraded = parseNotRegraded(args['not-regraded']);
  checkJuryMedian(jury, juryVotes);
  // Wave 6 — expert second opinions (Motion/UX). Allowed on any record,
  // graded or no-grade: an expert opinion is not a grade, and experts can
  // be consulted even when no independent judge grade exists. NOT added
  // to the no-grade rejection below.
  const expertMotion = parseExpert(args['expert-motion'], args['expert-motion-evidence'], '--expert-motion', '--expert-motion-evidence');
  const expertUx = parseExpert(args['expert-ux'], args['expert-ux-evidence'], '--expert-ux', '--expert-ux-evidence');
  if (noGrade && (pairwise || pairwiseAgrees !== null || jury || juryMode || juryVotes || notRegraded)) {
    console.error('run-log: REJECTED — --pairwise / --pairwise-agrees / --jury / --jury-mode / --jury-votes / --not-regraded need a graded round. A --grader none record has no scores to compare, to take a median of, or to mark sections not re-scored on. No entry written.');
    process.exit(2);
  }
  if (noGrade) {
    if (scores) {
      console.error('run-log: REJECTED — --grader none goes with --scores none only. A score IS a grade and needs an independent judge (judge-subagent | muse-manager | other-model). No entry written.');
      process.exit(2);
    }
    if (args.grade !== undefined && args.grade !== 'none') usage('--grader none goes with --scores none and no grade; use a graded record for scores');
    if (!['pass', 'fail'].includes(args.gate)) usage('--gate must be pass or fail');
    // D13: a --gate pass without both leg artifacts is refused (exit 2).
    const gateArtifacts = validateGateArtifacts(args.project, args);
    const rec = {
      kind: 'round', round, grader: null, independenceBasis: null,
      scores: null, grade: args.gate === 'fail' ? 'gate red, no grade' : 'gate green, vision not available',
      evidence: null, gate: args.gate,
      gateLeg1: gateArtifacts ? gateArtifacts.gateLeg1 : null,
      gateLeg2: gateArtifacts ? gateArtifacts.gateLeg2 : null,
      gateLeg1Sha: gateArtifacts ? gateArtifacts.gateLeg1Sha : null,
      gateLeg2Sha: gateArtifacts ? gateArtifacts.gateLeg2Sha : null,
      gateFindings: args['gate-findings'] || null,
      variant: args.variant || null,
      tokensHash: resolveTokensHash(args.project, undefined, args['tokens-hash']),
      fixClass: args['fix-class'] || null,
      outcome: parseOutcome(args.outcome),
      page: gateArtifacts ? gateArtifacts.page : null,
      trigger,
      pairwise: null, pairwiseAgrees: null, jury: null, juryMode: null, juryVotes: null,
      notRegraded: null,
      expertMotion: expertMotion.score, expertMotionEvidence: expertMotion.evidence,
      expertUx: expertUx.score, expertUxEvidence: expertUx.evidence,
      notes: args.notes || null,
      at: new Date().toISOString(),
    };
    appendLog(args.project, rec);
    console.log(`run-log: recorded round ${round} (grader: none; grade: ${rec.grade}; gate: ${args.gate})`);
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
  // D13: a --gate pass without both leg artifacts is refused (exit 2).
  const gateArtifacts = validateGateArtifacts(args.project, args);
  const rec = {
    kind: 'round', round, grader, independenceBasis: args.basis.trim(),
    scores, grade: scores ? 'graded' : (args.gate === 'fail' ? 'gate red, no grade' : 'gate green, vision not available'),
    evidence: args.evidence || null, gate: args.gate,
    gateLeg1: gateArtifacts ? gateArtifacts.gateLeg1 : null,
    gateLeg2: gateArtifacts ? gateArtifacts.gateLeg2 : null,
    gateLeg1Sha: gateArtifacts ? gateArtifacts.gateLeg1Sha : null,
    gateLeg2Sha: gateArtifacts ? gateArtifacts.gateLeg2Sha : null,
    gateFindings: args['gate-findings'] || null,
    variant: args.variant || null,
    tokensHash: resolveTokensHash(args.project, undefined, args['tokens-hash']),
    fixClass: args['fix-class'] || null,
    outcome: parseOutcome(args.outcome),
    page: gateArtifacts ? gateArtifacts.page : null,
    trigger, pairwise, pairwiseAgrees, jury, juryMode, juryVotes,
    notRegraded,
    expertMotion: expertMotion.score, expertMotionEvidence: expertMotion.evidence,
    expertUx: expertUx.score, expertUxEvidence: expertUx.evidence,
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
    purpose: args.purpose || null,
    approvedBy: args['approved-by'] || null,
    notes: args.notes || null,
    at: new Date().toISOString(),
  };
  appendLog(args.project, rec);
  console.log(`run-log: taste locked (version ${lockVersion}) — tokens: ${args.tokens}${rec.tokensHash ? ` (sha256 ${rec.tokensHash.slice(0, 12)}…)` : ' (tokens file not on disk — no hash recorded)'}; refs: ${args.refs}${rec.purpose ? `; purpose: ${rec.purpose}` : ''}${rec.approvedBy ? `; approved-by: ${rec.approvedBy}` : ''}`);
} else if (cmd === 'replan') {
  // Purpose-fail execution path (UX-B council decision 2026-11-10): a
  // purpose failure (grade-time P1–P5 check, or a purpose change
  // mid-loop) is resolved by re-planning the inventory from the
  // revised purpose or re-picking the direction — never by patching
  // the inventory in place, and never by an unenforced plan note. The
  // decision is recorded here in the run log; a re-pick records a NEW
  // taste-lock version via `lock` (this command records the decision
  // only, it does not lock).
  const action = args.action;
  if (!['re-plan', 're-pick'].includes(action)) usage('replan needs --action <re-plan|re-pick>');
  if (!args.purpose || !args.purpose.trim()) usage('replan needs --purpose "<revised purpose from PLAN.md>"');
  const rec = {
    kind: 'purpose-fail', action, purpose: args.purpose.trim(),
    notes: args.notes || null,
    at: new Date().toISOString(),
  };
  appendLog(args.project, rec);
  console.log(`run-log: purpose fail recorded — action: ${action}; revised purpose: ${rec.purpose}`);
} else if (cmd === 'crosscheck') {
  // Security/compliance cross-check verdict (BUFFET-MODE.md §14,
  // SKILL.md step 3a). The coordinator transcribes the checker's verdict
  // here BEFORE any land is recorded; `land` below refuses to record
  // without a prior clear verdict for the same slice/round.
  // Verdict is DERIVED, never asserted: clear iff severe == 0 AND every
  // warning is fixed-or-waived (warning == waived). A blocked verdict is
  // still recorded — it is the record of the block, and the next
  // cross-check after the fix supersedes it (land reads the LATEST
  // verdict for the slice/round).
  const slice = (args.slice || '').trim();
  const round = args.round !== undefined ? Number(args.round) : null;
  if (!slice && (round === null || !Number.isInteger(round) || round < 1)) usage('crosscheck needs --slice <id> and/or --round N');
  if (round !== null && (!Number.isInteger(round) || round < 1)) usage('--round must be a positive integer');
  const severe = Number(args.severe);
  const warning = Number(args.warning);
  const waived = args.waived !== undefined ? Number(args.waived) : 0;
  if (!Number.isInteger(severe) || severe < 0) usage('--severe must be a non-negative integer');
  if (!Number.isInteger(warning) || warning < 0) usage('--warning must be a non-negative integer');
  if (!Number.isInteger(waived) || waived < 0 || waived > warning) usage('--waived must be a non-negative integer no greater than --warning');
  if (!args.report || !args.report.trim()) usage('crosscheck needs --report <path to the cross-check report>');
  const checker = (args.checker || '').trim();
  if (!ALLOWED_CHECKERS.includes(checker)) {
    console.error(`run-log: REJECTED — checker "${checker}" is not an allowed independent cross-checker (allowed: ${ALLOWED_CHECKERS.join(', ')}). The checker must be independent of the builder AND of the judge for that slice. No entry written.`);
    process.exit(2);
  }
  // Same two-half independence bar as a grader basis (fresh/separate
  // context AND no production history) — a checker that shares the
  // builder's context or history is not independent (synthesis §2 C5:
  // the generator cannot be the validator).
  checkIndependenceBasis(args.basis, checker);
  const verdict = (severe === 0 && warning === waived) ? 'clear' : 'blocked';
  const rec = {
    kind: 'crosscheck', slice: slice || null, round,
    severe, warning, waived, verdict,
    report: args.report.trim(), checker, independenceBasis: args.basis.trim(),
    notes: args.notes || null,
    at: new Date().toISOString(),
  };
  appendLog(args.project, rec);
  console.log(`run-log: cross-check recorded for slice ${slice || '(no slice)'}${round !== null ? ` (round ${round})` : ''} — verdict: ${verdict} (SEVERE ${severe}, WARNING ${warning}, waived ${waived}); report: ${rec.report}`);
} else if (cmd === 'land') {
  // Land / ship decision (coordination design §3 / BUFFET-MODE.md §14, SKILL.md step 3a):
  // requires gate green AND a clear cross-check verdict already in the
  // log. A land without a prior clear verdict is REJECTED (exit 2,
  // nothing written) — landing without a cross-check is forbidden,
  // exactly as landing without a gate is (F32). The verdict read is the
  // LATEST cross-check for the slice/round: a blocked verdict after a
  // clear one supersedes it (fix → fresh re-check).
  const slice = (args.slice || '').trim();
  const round = args.round !== undefined ? Number(args.round) : null;
  if (!slice && (round === null || !Number.isInteger(round) || round < 1)) usage('land needs --slice <id> and/or --round N');
  if (round !== null && (!Number.isInteger(round) || round < 1)) usage('--round must be a positive integer');
  if (args.gate !== 'pass') {
    console.error('run-log: REJECTED — land requires --gate pass. A land on a red gate is forbidden (the gate is the first half of the land rule; the cross-check is the second). No entry written.');
    process.exit(2);
  }
  // D13: a --gate pass without both leg artifacts is refused (exit 2) —
  // the land path must not be the bypass around the record refusal.
  const gateArtifacts = validateGateArtifacts(args.project, args);
  const checks = readLog(args.project).filter((r) => r.kind === 'crosscheck'
    && (slice ? r.slice === slice : true)
    && (round !== null ? r.round === round : true));
  const latest = checks[checks.length - 1];
  if (!latest) {
    console.error(`run-log: REJECTED — land for slice ${slice || '(no slice)'}${round !== null ? ` (round ${round})` : ''} has no cross-check verdict in the log. Record it first (run-log.mjs crosscheck ...), then land. No entry written.`);
    process.exit(2);
  }
  if (latest.verdict !== 'clear') {
    console.error(`run-log: REJECTED — the latest cross-check verdict for slice ${slice || '(no slice)'}${round !== null ? ` (round ${round})` : ''} is ${latest.verdict.toUpperCase()} (SEVERE ${latest.severe}, WARNING ${latest.warning}, waived ${latest.waived}; report: ${latest.report}). A SEVERE finding blocks the land like a gate FAIL; fix and re-check first. No entry written.`);
    process.exit(2);
  }
  const rec = {
    kind: 'land', slice: slice || null, round,
    gate: 'pass',
    gateLeg1: gateArtifacts.gateLeg1, gateLeg2: gateArtifacts.gateLeg2,
    gateLeg1Sha: gateArtifacts.gateLeg1Sha, gateLeg2Sha: gateArtifacts.gateLeg2Sha,
    page: gateArtifacts.page,
    crosscheckReport: latest.report,
    notes: args.notes || null,
    at: new Date().toISOString(),
  };
  appendLog(args.project, rec);
  console.log(`run-log: LAND recorded for slice ${slice || '(no slice)'}${round !== null ? ` (round ${round})` : ''} (gate: pass; cross-check: clear; report: ${latest.report})${rec.page ? `; page: ${rec.page}` : ''}`);
} else if (cmd === 'show') {
  const rows = readLog(args.project);
  if (!rows.length) { console.log('run-log: no entries yet.'); process.exit(0); }
  for (const r of rows) {
    if (r.kind === 'round') {
      const s = r.scores ? `T${r.scores.type}/L${r.scores.layout}/C${r.scores.colour}/S${r.scores.space}` : 'no grade';
      const g = r.grader ? `grader: ${r.grader} (${r.independenceBasis})` : `grader: none (${r.grade})`;
      const j = r.jury ? ` | jury: T${r.jury.type}/L${r.jury.layout}/C${r.jury.colour}/S${r.jury.space} (${r.juryMode || 'mode not recorded'})` : '';
      const p = r.pairwise ? ` | pairwise: ${r.pairwise}${r.pairwiseAgrees !== null && r.pairwiseAgrees !== undefined ? ` (agrees with absolute: ${r.pairwiseAgrees ? 'yes' : 'no'})` : ''}` : '';
      const nr = r.notRegraded && r.notRegraded.length ? ` | not re-graded: ${r.notRegraded.join(', ')}` : '';
      const ga = r.gateLeg1 ? ` | gate artifacts: ${r.gateLeg1}${r.gateLeg1Sha ? ` (${r.gateLeg1Sha.slice(0, 12)}…)` : ''}, ${r.gateLeg2 || '?'}${r.gateLeg2Sha ? ` (${r.gateLeg2Sha.slice(0, 12)}…)` : ''}` : '';
      console.log(`round ${r.round} | ${g} | ${s} | grade: ${r.grade} | gate: ${r.gate}${ga}${r.variant ? ` | variant: ${r.variant}` : ''}${r.tokensHash ? ` | tokens: ${r.tokensHash.slice(0, 12)}…` : ''}${r.fixClass ? ` | fix-class: ${r.fixClass}` : ''}${r.outcome ? ` | outcome: ${r.outcome}` : ''}${r.trigger ? ` | trigger: ${r.trigger}` : ''}${p}${j}${nr}${r.page ? ` | page: ${r.page}` : ''}${r.notes ? ` | ${r.notes}` : ''}`);
      if (r.gateFindings) console.log(`  gate findings: ${r.gateFindings}`);
      if (r.evidence) console.log(`  evidence: ${r.evidence}`);
      if (r.expertMotion !== null && r.expertMotion !== undefined) console.log(`  Motion: ${r.expertMotion} (motion-expert) — ${r.expertMotionEvidence || ''}`);
      if (r.expertUx !== null && r.expertUx !== undefined) console.log(`  UX: ${r.expertUx} (ux-expert) — ${r.expertUxEvidence || ''}`);
    } else if (r.kind === 'feedback') {
      console.log(`feedback (round ${r.round}): "${r.from}" -> ${r.tokenChange}${r.scoreAfter ? ` | after: T${r.scoreAfter.type}/L${r.scoreAfter.layout}/C${r.scoreAfter.colour}/S${r.scoreAfter.space} (grader: ${r.grader || 'MISSING'})` : ''}`);
      if (r.scoreAfter && r.evidence) console.log(`  evidence: ${r.evidence}`);
    } else if (r.kind === 'variant-pick') {
      console.log(`variant pick: "${r.variant}"${r.note ? ` — ${r.note}` : ''}`);
    } else if (r.kind === 'taste-lock') {
      console.log(`taste lock v${r.lockVersion ?? '?'}: tokens: ${r.tokens}${r.tokensHash ? ` (sha256 ${r.tokensHash.slice(0, 12)}…)` : ''}; refs: ${r.references}${r.purpose ? `; purpose: ${r.purpose}` : ''}${r.approvedBy ? `; approved-by: ${r.approvedBy}` : ''}${r.notes ? `; notes: ${r.notes}` : ''} (${r.at})`);
    } else if (r.kind === 'purpose-fail') {
      console.log(`purpose fail: action: ${r.action}; revised purpose: ${r.purpose}${r.notes ? `; notes: ${r.notes}` : ''} (${r.at})`);
    } else if (r.kind === 'crosscheck') {
      console.log(`cross-check (slice ${r.slice || '—'}${r.round !== null && r.round !== undefined ? `, round ${r.round}` : ''}): verdict: ${r.verdict} (SEVERE ${r.severe}, WARNING ${r.warning}, waived ${r.waived}) | checker: ${r.checker} (${r.independenceBasis}) | report: ${r.report} (${r.at})`);
    } else if (r.kind === 'land') {
      const ga = r.gateLeg1 ? ` | gate artifacts: ${r.gateLeg1}${r.gateLeg1Sha ? ` (${r.gateLeg1Sha.slice(0, 12)}…)` : ''}, ${r.gateLeg2 || '?'}${r.gateLeg2Sha ? ` (${r.gateLeg2Sha.slice(0, 12)}…)` : ''}` : '';
      console.log(`LAND (slice ${r.slice || '—'}${r.round !== null && r.round !== undefined ? `, round ${r.round}` : ''}): gate: ${r.gate}${ga} | cross-check: clear | report: ${r.crosscheckReport}${r.page ? ` | page: ${r.page}` : ''} (${r.at})`);
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
      allowMissing: args['allow-missing'] === true,
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
  // Effective scores: the stop-round jury median, when recorded, is the
  // round's score for keep/discard purposes (P14 replaces the single
  // grade on the stop round); otherwise the absolute scores.
  const effScores = (r) => r.jury || r.scores;
  const rounds = readLog(args.project).filter((r) => r.kind === 'round' && effScores(r));
  if (!rounds.length) { console.log('run-log: no graded rounds yet.'); process.exit(0); }
  const total = (s) => s.type + s.layout + s.colour + s.space;
  const best = rounds.reduce((a, b) => (total(effScores(b)) > total(effScores(a)) ? b : a));
  const bs = effScores(best);
  console.log(`best: round ${best.round} (grader: ${best.grader}) — T${bs.type}/L${bs.layout}/C${bs.colour}/S${bs.space}, total ${total(bs)}/20, gate: ${best.gate}${best.jury ? ' (jury median)' : ''}`);
} else {
  usage(`unknown command "${cmd || ''}" (record | feedback | lock | replan | crosscheck | land | brief | show | best)`);
}
