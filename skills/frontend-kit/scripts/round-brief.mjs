#!/usr/bin/env node
// round-brief.mjs — P7 round-brief generator (fresh context per round).
//
// Assembles the minimal brief for one round from the append-only run log
// (design/run-log.jsonl, via skills/frontend-kit/scripts/run-log.mjs) +
// the locked files — and NEVER from the full run log. A round starts from
// this brief, not from the previous round's context: the full log stays
// in a file, not in context (context rot: quality falls as input length
// grows, and the lock sits mid-context where attention sags — see the
// P7 evidence in research/workflow-optimization/worker-failure-modes.md
// (workspace research note, not shipped in this repo)
// F4/F6/F15; the Liu "Lost in the Middle" primary itself is CHƯA ĐỌC,
// cited via convergent secondaries, never presented as read).
//
// What the brief contains, and nothing else:
//   - the 5-line lock summary (also at the top of templates/design/TASTE.md)
//   - the Purpose lock field (the run-log lock record's `purpose`, else the
//     Purpose section of design/PLAN.md) + the Design Read's motion/3D routing lines
//     (patterns + implementation skill, 3D component + threeui) — W3:
//     the builder budget is the brief only (SKILL.md per-role table), so
//     routing that lives only in Step 1/2 reaches no builder without this
//     section
//   - the locked tokens.css, verbatim
//   - the best HTML (best-scoring graded round's page), verbatim
//   - the latest round's gate findings
//   - grader evidence lines (latest round + best round only)
//   - a one-line-per-round run-state table (round, gate, scores,
//     fix-class, outcome — state, not the log)
// All axes start "ungraded" for the new round; no score is ever carried
// from an earlier round. The lock is restated at the end of every brief,
// immediately before the output instruction, so the highest-signal
// tokens are also the most recent.
//
// Schema check (council-B): for round N > 1 the brief FAILS LOUDLY
// (exit 1, nothing printed) when the lock, the best-HTML path, the
// latest round's gate findings, or a graded round's evidence lines are
// missing. A silent signal-dropping generator is worse than no
// generator. --allow-missing downgrades missing gate findings /
// evidence to explicit "NOT RECORDED" lines (the absence stays visible);
// it never invents them. Round 1 has no prior round, so no gate
// findings or evidence are required for it — the brief is lock + tokens.
//
// Round 7 (F1, D15): the lock of record is the LATEST taste-lock line,
// and only when it verifies (verifyLockLine in judge-report.mjs —
// the tokens file it names on disk inside design/, not a symlink,
// still hashing to the stored tokensHash). A latest line that does
// not verify makes the brief fail loudly with the verification
// reasons as the notice, and its references/tokens/version are
// never built on — the pre-round-7 behaviour (adopting the
// highest-version line verbatim) let a hand-appended line become
// the lock every brief restated.
//
// W3 (Design-Read check, fires at round 1 too): the brief FAILS LOUDLY
// when design/DESIGN-READ.md names a scroll-motion pattern (or a 3D
// component) without its implementation skill or an explicit 'none'
// (same fail-loud pattern as the lock/evidence checks; --allow-missing
// downgrades it to an explicit "NOT RECORDED" line, never an invented
// skill). A missing DESIGN-READ.md is NOT a failure — it degrades to
// explicit "NOT RECORDED" routing lines (older projects predate the
// field); a missing Purpose field likewise degrades, never fails.
//
// Fallback (council-A/B): if this script cannot run (no Node), the
// orchestrator hand-assembles the same field list from the run log's
// last record + the locked tokens (see SKILL.md "Round briefs +
// per-role context budgets"). Last resort only, the brief is the full
// run log, labelled `brief: full-log (generator unavailable)` —
// labelled, never silently pasted.
//
// No run.json file exists in this loop (council decision, 2026-11-10):
// run state lives in the append-only run log; this script reads it, it
// never writes it.
//
// Node, no dependencies. Usage:
//   node round-brief.mjs --project <dir> [--round N] [--page <built.html>]
//     [--out <file>] [--allow-missing]
//   node run-log.mjs --project <dir> brief [--round N] [--out <file>]
//     (same brief, via the run-log entry point the skill cites)
// --round defaults to the next round (highest recorded round + 1, or 1).
// --page overrides the best-HTML path (otherwise the best round's
// recorded `page`, else the latest round's, else <project>/index.html).
//
// Exit codes: 0 ok, 1 usage error or schema-check failure.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
// Round 7 (F1): the shared taste-lock verifier lives in
// judge-report.mjs, next to the judge-report parser and the other
// read-path verifiers — the same verifyLockLine run-log.mjs's lock
// command and gate/runlog-check.mjs consult, so the brief's lock
// verdict cannot drift from theirs.
import { verifyLockLine } from './judge-report.mjs';

const AXES = ['Type', 'Layout', 'Colour', 'Space'];

function usage(msg) {
  if (msg) console.error(`round-brief: ${msg}`);
  console.error(`usage:
  node round-brief.mjs --project <dir> [--round N] [--page <built.html>] [--out <file>] [--allow-missing]
  node run-log.mjs --project <dir> brief [--round N] [--out <file>]`);
  process.exit(1);
}

function fail(msg) {
  console.error(`round-brief: SCHEMA CHECK FAILED — ${msg} Nothing printed.`);
  process.exit(1);
}

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      if (key === 'allow-missing') { out[key] = true; continue; }
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
  const lines = fs.readFileSync(p, 'utf8').split('\n').filter(Boolean);
  return lines.map((l, i) => {
    try {
      return JSON.parse(l);
    } catch {
      throw new Error(`run log line ${i + 1} is not valid JSON: ${l.slice(0, 80)}`);
    }
  });
}

function sha256(text) {
  return crypto.createHash('sha256').update(text).digest('hex');
}

function resolveInProject(project, p) {
  return path.isAbsolute(p) ? p : path.join(project, p);
}

function scoresTotal(s) {
  return s.type + s.layout + s.colour + s.space;
}

function scoresLine(s) {
  return s ? `T${s.type}/L${s.layout}/C${s.colour}/S${s.space}` : 'no grade';
}

function designReadPath(project) {
  return path.join(project, 'design', 'DESIGN-READ.md');
}

function planPath(project) {
  return path.join(project, 'design', 'PLAN.md');
}

// W3: the Design Read's motion/3D routing lines, in the stated format
// (SKILL.md step 1.2): `Motion: Pattern 2 + Pattern 5 — implementation
// skill: vendor/gsap/gsap-scrolltrigger/SKILL.md` and
// `3D: <component from the ThreeUI catalog> — implementation skill:
// skills/threeui/SKILL.md` (or `Motion: none` / `3D: none`). The
// generator reads the file from disk — the run log carries no
// Design-Read field, and free-text prose is never parsed as a routing
// decision beyond the lines this function recognises.
// Returns { present, motion, threeD, motionGap, threeDGap } where
// motion/threeD are the verbatim routing lines (or null), and the *Gap
// flags mark a fail-loud check downgraded by --allow-missing. Throws on
// component) named without an implementation skill or an explicit
// 'none', unless opts.allowMissing, in which case the caller emits an
// explicit NOT RECORDED line instead.
function readMotionRouting(project, opts = {}) {
  const p = designReadPath(project);
  if (!fs.existsSync(p)) return { present: false, motion: null, threeD: null };
  const text = fs.readFileSync(p, 'utf8');
  const lines = text.split('\n');
  const patterns = [...new Set([...text.matchAll(/Pattern\s+([1-8])\b/g)].map((m) => Number(m[1])))].sort((a, b) => a - b);
  const skillLines = lines.filter((l) => /implementation skill/i.test(l));
  const motionLine = skillLines.find((l) => /Pattern|Motion/i.test(l)) || null;
  const threeDLine = skillLines.find((l) => /threeui|3D/i.test(l)) || null;
  const namesThreeD = lines.some((l) => /^3D:/i.test(l.trim())) || /threeui/i.test(text);
  const noneMotion = /Motion:\s*none/i.test(text);
  const noneThreeD = /3D:\s*none/i.test(text);
  const fail = (msg) => {
    if (opts.allowMissing) return null;
    throw new Error(msg);
  };

  let motion = null;
  let motionGap = false;
  if (patterns.length) {
    if (motionLine) {
      if (!/vendor\/gsap\/[\w-]+\/SKILL\.md/i.test(motionLine) && !/\bnone\b/i.test(motionLine)) {
        fail(`Design Read names Pattern ${patterns.join(' + ')} but its implementation-skill line names neither a vendor/gsap skill path nor 'none': "${motionLine.trim()}" (record the skill per SKILL.md step 1.2, or pass --allow-missing to label the gap explicitly)`);
        motion = null; // allow-missing: caller emits NOT RECORDED
        motionGap = true;
      } else {
        motion = motionLine.trim();
      }
    } else if (noneMotion) {
      motion = 'Motion: none';
    } else {
      const msg = `Design Read names Pattern ${patterns.join(' + ')} with no implementation skill recorded (record it per SKILL.md step 1.2, or pass --allow-missing to label the gap explicitly)`;
      fail(msg);
      motion = null; // allow-missing: caller emits NOT RECORDED
      motionGap = true;
    }
  } else if (motionLine) {
    motion = motionLine.trim();
  } else if (noneMotion) {
    motion = 'Motion: none';
  }

  let threeD = null;
  let threeDGap = false;
  if (namesThreeD) {
    if (threeDLine) {
      if (!/skills\/threeui\/SKILL\.md/i.test(threeDLine) && !/\bnone\b/i.test(threeDLine)) {
        fail(`Design Read names a 3D component but its implementation-skill line names neither skills/threeui/SKILL.md nor 'none': "${threeDLine.trim()}" (record the skill per SKILL.md step 1.2, or pass --allow-missing to label the gap explicitly)`);
        threeD = null; // allow-missing: caller emits NOT RECORDED
        threeDGap = true;
      } else {
        threeD = threeDLine.trim();
      }
    } else if (noneThreeD) {
      threeD = '3D: none';
    } else {
      fail('Design Read names a 3D component with no implementation skill recorded (record skills/threeui/SKILL.md per SKILL.md step 1.2, or pass --allow-missing to label the gap explicitly)');
      threeD = null; // allow-missing: caller emits NOT RECORDED
      threeDGap = true;
    }
  } else if (threeDLine) {
    threeD = threeDLine.trim();
  } else if (noneThreeD) {
    threeD = '3D: none';
  }

  return { present: true, motion, threeD, motionGap, threeDGap };
}

// W3: the Purpose lock field. The run-log lock record's `purpose` wins
// (BUILD-2's lock field, recorded at lock time); else the Purpose
// section of design/PLAN.md. Returns the purpose text, or null when
// neither exists yet (the caller emits an explicit NOT RECORDED line).
function readPurpose(project, lock) {
  if (lock.purpose && String(lock.purpose).trim()) return String(lock.purpose).trim();
  const p = planPath(project);
  if (!fs.existsSync(p)) return null;
  const text = fs.readFileSync(p, 'utf8');
  const m = text.match(/^##\s+Purpose[^\n]*\n([\s\S]*?)(?=^##\s|\Z)/m);
  if (!m) return null;
  const body = m[1].split('\n').map((s) => s.trim()).filter((s) => s && !s.startsWith('<!--')).join(' ');
  return body || null;
}

// The 5-line lock summary. The same five lines, in the same order, sit
// at the top of templates/design/TASTE.md and are restated at the end of
// every brief — one canonical shape, three places, no drift.
function lockSummary({ references, tokensPath, tokensHash, lockVersion, variant }) {
  return [
    `1. Direction: ${references}`,
    `2. Tokens: ${tokensPath} (sha256 ${tokensHash ? tokensHash.slice(0, 12) + '…' : 'not recorded'})`,
    `3. Lock version: ${lockVersion} — immutable within a direction; a re-pick creates a new version.`,
    `4. Picked variant: ${variant || 'none yet'}`,
    '5. Stop: >=4 on Type/Layout/Colour/Space + gate green, or after 3 rounds; every axis starts ungraded.',
  ];
}

export function buildBrief(project, opts = {}) {
  const rows = readLog(project);
  const locks = rows.filter((r) => r.kind === 'taste-lock');
  if (!locks.length) {
    throw new Error('no taste lock in the run log — run `run-log.mjs lock` (SKILL.md step 1.8) before any round brief');
  }
  // Round 7 (F1): the lock of record is the LATEST lock line, and
  // only if it verifies (shared verifyLockLine: lockVersion a
  // positive integer; the tokens file it names on disk inside
  // design/, not a symlink, and still hashing to the stored
  // tokensHash). Before round 7 the brief adopted whichever stored
  // line carried the HIGHEST version number — references, tokens
  // path and version restated verbatim — so a hand-appended line
  // (version 99, attacker-chosen references, a tokensHash copied
  // from the real file so the mismatch warning below stayed
  // silent) became the lock every round brief restated. A latest
  // line that does not verify is NOT adopted, and the brief does
  // NOT fall back to an earlier line: falling back would let a
  // stale or fake latest line be quietly buried (the same
  // no-fallback stance land takes with an unverifiable latest
  // cross-check, round 6). The brief fails loud — its established
  // contract for an unreconstructable lock — with the verification
  // reasons as the notice, and nothing is built on the line.
  const lock = locks[locks.length - 1];
  const lockVerify = verifyLockLine(project, lock);
  if (!lockVerify.ok) {
    throw new Error(`the stored taste lock (v${lock.lockVersion ?? '?'}) could not be verified and is NOT adopted as the lock of record: ${lockVerify.reasons.join('; ')}. Re-lock (run-log.mjs lock) before building.`);
  }
  const rounds = rows.filter((r) => r.kind === 'round').sort((a, b) => a.round - b.round);
  const maxRound = rounds.length ? rounds[rounds.length - 1].round : 0;
  const targetRound = opts.round ?? maxRound + 1;

  const tokensPath = lock.tokens;
  const tokensFile = resolveInProject(project, tokensPath);
  if (!fs.existsSync(tokensFile)) {
    throw new Error(`locked tokens file not found on disk: ${tokensFile} (lock v${lock.lockVersion ?? '?'})`);
  }
  const tokensText = fs.readFileSync(tokensFile, 'utf8');
  const tokensHash = sha256(tokensText);
  const hashMismatch = lock.tokensHash && lock.tokensHash !== tokensHash;

  // Picked variant: the latest round's variant, else the latest
  // variant-pick record, else none.
  const latestRound = rounds.length ? rounds[rounds.length - 1] : null;
  const picks = rows.filter((r) => r.kind === 'variant-pick');
  const variant = latestRound?.variant || (picks.length ? picks[picks.length - 1].variant : null);

  const summary = lockSummary({
    references: lock.references,
    tokensPath,
    tokensHash,
    lockVersion: lock.lockVersion ?? '?',
    variant,
  });

  const out = [];
  out.push(`# Round ${targetRound} brief`);
  out.push('');
  out.push('## Lock summary');
  out.push(...summary);
  if (hashMismatch) {
    out.push('');
    out.push(`WARNING: tokens on disk do NOT match the locked hash (lock v${lock.lockVersion ?? '?'} recorded sha256 ${lock.tokensHash.slice(0, 12)}…, disk is ${tokensHash.slice(0, 12)}…). The lock moved mid-loop — re-lock before building; do not build against unlocked tokens.`);
  }
  // W3: Purpose + motion/3D routing. The builder's budget is the brief
  // only, so this is the one place the routing reaches a builder — in
  // any round, including round 1. readMotionRouting throws (fail loud)
  // when the Design Read names a pattern or a 3D component without its
  // implementation skill; --allow-missing downgrades that to NOT
  // RECORDED, never to an invented skill.
  const routing = readMotionRouting(project, opts);
  const purpose = readPurpose(project, lock);
  out.push('');
  out.push('## Purpose + motion/3D routing');
  out.push(`Purpose: ${purpose || 'NOT RECORDED — no Purpose lock field in the run log and no Purpose section in design/PLAN.md yet.'}`);
  if (!routing.present) {
    out.push('Motion: NOT RECORDED — design/DESIGN-READ.md not found; no motion beyond the fixed header and hover states.');
    out.push('3D: NOT RECORDED — design/DESIGN-READ.md not found; no 3D component.');
  } else {
    out.push(routing.motion ? routing.motion : (routing.motionGap ? 'Motion: NOT RECORDED — the Design Read names a pattern but no implementation skill (run with --allow-missing to label the gap explicitly). No motion beyond the fixed header and hover states until the skill is recorded.' : 'Motion: none — no motion pattern named in the Design Read; no motion beyond the fixed header and hover states.'));
    out.push(routing.threeD ? routing.threeD : (routing.threeDGap ? '3D: NOT RECORDED — the Design Read names a 3D component but no implementation skill (run with --allow-missing to label the gap explicitly). No 3D component until the skill is recorded.' : '3D: none — no 3D component named in the Design Read.'));
  }
  out.push('Before writing any motion or 3D code, read the implementation skill named above (SKILL.md step 2.1a). Do not hand-roll what the named skill covers, and do not substitute another animation library without a recorded reason in the run log.');
  out.push('');
  out.push('## Your task');
  if (!rounds.length) {
    out.push('Build round 1 from the locked tokens below. No prior build exists: there is no best HTML, no gate findings, and no grader evidence yet. Build one HTML file, tokens only — every visual value comes from the locked tokens.css.');
  } else if (targetRound === 1) {
    out.push(`Re-pick restart: round 1 of the new direction (lock v${lock.lockVersion ?? '?'}). The prior direction's rounds below are state only — do not build on them and do not carry their scores. Build one HTML file from the locked tokens; the best version from the earlier direction stays kept separately and is what ships if no later round beats it.`);
  } else {
    out.push(`Fix round ${targetRound}: apply at most the top 2 fixes below, as token diffs against the locked tokens. Each fix cites its source — a gate finding, a grader evidence line, or a human instruction — never "improve it". Do not re-read the full run log; this brief is your whole context for the round.`);
  }
  out.push('');
  out.push('## Locked tokens');
  out.push(`File: ${tokensPath} (${tokensText.split('\n').length} lines, sha256 ${tokensHash.slice(0, 12)}…)`);
  out.push('```css');
  out.push(tokensText.replace(/\n$/, ''));
  out.push('```');

  if (targetRound > 1 && rounds.length) {
    // Best HTML: best-scoring graded round; if no round was ever graded,
    // the latest round's page (the only build there is).
    const graded = rounds.filter((r) => r.scores);
    const best = graded.length
      ? graded.reduce((a, b) => (scoresTotal(b.scores) > scoresTotal(a.scores) ? b : a))
      : null;
    const bestRound = best || latestRound;
    let bestPage = opts.page || bestRound.page || latestRound.page;
    if (!bestPage && fs.existsSync(path.join(project, 'index.html'))) bestPage = 'index.html';
    if (!bestPage) {
      throw new Error(`best-HTML path unknown: no round recorded a --page and <project>/index.html does not exist (re-record the round with --page, or pass --page)`);
    }
    const bestFile = resolveInProject(project, bestPage);
    if (!fs.existsSync(bestFile)) {
      throw new Error(`best HTML file not found on disk: ${bestFile} (round ${bestRound.round}${bestRound.page ? '' : ' — page fell back to the latest round'})`);
    }
    const bestText = fs.readFileSync(bestFile, 'utf8');
    out.push('');
    out.push(`## Best HTML (round ${bestRound.round}${best ? `, ${scoresLine(bestRound.scores)}, total ${scoresTotal(bestRound.scores)}/20` : ', ungraded — no graded round yet'})`);
    out.push(`File: ${bestPage} (${bestText.split('\n').length} lines) — edit this file, or a copy of it; a lower-scoring round is discarded, not iterated on.`);
    out.push('```html');
    out.push(bestText.replace(/\n$/, ''));
    out.push('```');

    // Gate findings + grader evidence: latest round only (plus the best
    // round's evidence line when it differs). Never the full log.
    out.push('');
    out.push(`## Gate findings (round ${latestRound.round}, gate: ${latestRound.gate})`);
    if (latestRound.gateFindings) {
      out.push(latestRound.gateFindings);
    } else if (opts.allowMissing) {
      out.push('NOT RECORDED — the round was logged without --gate-findings. Record the gate output on the next round; do not guess at findings.');
    } else {
      throw new Error(`gate findings missing for round ${latestRound.round} (re-record the round with --gate-findings, or pass --allow-missing to label the gap explicitly)`);
    }
    out.push('');
    out.push('## Grader evidence lines');
    const evidenceRounds = [latestRound];
    if (best && best.round !== latestRound.round) evidenceRounds.push(best);
    for (const r of evidenceRounds) {
      if (r.scores) {
        if (r.evidence) {
          out.push(`Round ${r.round} (${scoresLine(r.scores)}, grader: ${r.grader}): ${r.evidence}`);
        } else if (opts.allowMissing) {
          out.push(`Round ${r.round} (${scoresLine(r.scores)}): NOT RECORDED — the round was logged without --evidence.`);
        } else {
          throw new Error(`grader evidence missing for round ${r.round} (re-record the round with --evidence, or pass --allow-missing to label the gap explicitly)`);
        }
      } else {
        out.push(`Round ${r.round}: no grade — grade is exactly "gate green, vision not available"; the human gate carries the taste judgement.`);
      }
    }
    if (latestRound.fixClass) {
      out.push('');
      out.push(`## Fix class tried last round (round ${latestRound.round}): ${latestRound.fixClass}`);
      out.push('Do not repeat this fix class unchanged — if the round did not improve the lowest axis, change strategy or revert to the best-kept version.');
    }
  }

  out.push('');
  out.push('## Run state');
  if (!rounds.length) {
    out.push('No rounds recorded yet.');
  } else {
    for (const r of rounds) {
      out.push(`- round ${r.round} | gate: ${r.gate} | scores: ${scoresLine(r.scores)} | fix-class: ${r.fixClass || '—'} | outcome: ${r.outcome || 'pending'} | variant: ${r.variant || '—'} | tokens: ${r.tokensHash ? r.tokensHash.slice(0, 12) + '…' : '—'}`);
    }
    out.push(`Rounds used: ${rounds.length} of 3 per direction. Best version: round ${(() => { const g = rounds.filter((r) => r.scores); return g.length ? g.reduce((a, b) => (scoresTotal(b.scores) > scoresTotal(a.scores) ? b : a)).round : 'none graded yet'; })()}.`);
  }
  out.push('');
  out.push(`## Scores for round ${targetRound} — all axes start ungraded`);
  for (const a of AXES) out.push(`- ${a}: ungraded`);
  out.push('No score is carried from an earlier round. A score only moves when an independent judge writes evidence for it.');
  out.push('');
  out.push('## Lock restated — read this last, it governs');
  out.push(...summary);
  out.push('');
  out.push(`Now do round ${targetRound} under the lock above, and nothing outside it.`);
  return out.join('\n');
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname);
if (isMain) {
  const args = parseArgs(process.argv.slice(2));
  if (!args.project) usage('--project <dir> is required');
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
    fail(e.message);
  }
  if (args.out) {
    fs.mkdirSync(path.dirname(path.resolve(args.out)), { recursive: true });
    fs.writeFileSync(args.out, brief + '\n');
    console.log(`round-brief: round brief written to ${args.out}`);
  } else {
    console.log(brief);
  }
}
