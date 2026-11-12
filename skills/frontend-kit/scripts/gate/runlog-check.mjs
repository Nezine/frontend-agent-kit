#!/usr/bin/env node
// runlog-check.mjs — per-line JSON validation of design/run-log.jsonl
// (RR-06, fix round 2, 2026-11-11; hardened fix round 3).
//
// The run log is gitleaks-allowlisted (tokensHash is a 64-hex content hash),
// so gate.sh's line-based grep is the only layer there — and the grep misses
// the same shapes the seeds structural check closes: a unicode-escaped
// keyword (G3), a multi-line key/value split (G4), an escaped-quote value
// (G10). run-log.mjs writes exactly one JSON object per line
// (JSON.stringify(record) + '\n'), so each line can be parsed and checked
// against the log's known schema — the same structural idea as the seeds
// check, applied to the run log.
//
// Usage: node runlog-check.mjs <file>
// Exit 0: clean. Exit 1: hit — each offending line is printed as
//   <file>:<line>: <reason>. Exit 2: usage/read error.
//
// Rules, per non-blank line (blank lines are skipped — the trailing
// newline after the last record produces one):
//   1. The line MUST parse as a JSON object. A line that does not parse
//      FAILS (fail closed): a multi-line key/value split cannot survive
//      one-JSON-value-per-line, so it surfaces here as an unparseable
//      line instead of slipping past the grep. A non-object JSON value
//      also FAILS — run-log.mjs writes objects only.
//   1b. The line MUST NOT contain a duplicate JSON key in any object
//      (RR2-03): JSON.parse keeps the last duplicate and discards the
//      earlier ones, so a secret as the first value of a duplicated key
//      would otherwise survive. Detected on the raw text by
//      json-dup-keys.mjs (keys decoded, so "\u006bey" counts as "key").
//   2. Any key matching the secret-keyword set (api_key/apikey/secret/
//      passwd/password/access_token, case-insensitive) with a string value
//      of length >= 16 FAILS. Keys and values are checked DECODED, so a
//      unicode-escaped keyword ("api\u005fkey") and an escaped-quote
//      value ("<8-hex>\"<20-hex>") are both caught. The keyword match is
//      a PREFIX match with a guarded continuation (RR2-04, widened
//      RR3-02): after the keyword the next character must be '_', a
//      digit, '-', or '.' — or a space/tab starting a spaced continuation
//      ("secret key", "secret<TAB>key") — so api_key2, secret_key,
//      secret-key, secret.key, "api key", password-hash and api-key-2
//      all match, while secretary (a bare letter continuing the word)
//      does NOT. A trailing space/tab also matches (consistent with the
//      trailing-space behaviour); the dotted separator inside the base
//      keyword (api.key, access.token) is accepted too — dotted names
//      occur in config-style keys.
//   3. Any string value that is exactly one run of >= 32 hex characters
//      under a key OTHER than "tokensHash" FAILS (bare high-entropy
//      string). tokensHash is the log's one legitimate 64-hex field (the
//      sha256 of the public tokens.css) and is exempt by exact key name.
//      One narrow exemption, named: a run of exactly 40 or 64 hex chars
//      under a key ending in "sha" (branch_sha, commit_sha — the coord
//      log's branch_sha holds a 40-hex commit id and must stay clean).
//      A git SHA is 40 hex (SHA-1) or 64 hex (SHA-256), never 32 — so a
//      32-hex value under a *sha key FAILS (RR2-06), and a 40-hex value
//      in ANY other field FAILS too (a 40-hex value is also the shape of
//      a legacy GitHub OAuth token, so the old length-only exemption is
//      gone: the exemption is now key-AND-length, not length alone).
//   4. Any string value matching a high-confidence secret pattern
//      (ghp_/gho_/github_pat_/sk-/AKIA/private-key header) FAILS —
//      a known-shaped token pasted into a notes/evidence/gateFindings
//      field is a real leak, not a hash. The sk- family covers the
//      current vendor formats (RR2-05): OpenAI project keys sk-proj-,
//      service-account keys sk-svcacct- and admin keys sk-admin-, and
//      Anthropic keys sk-ant- (api03/admin01/oat01 and later).
//   5. KEYS are inspected too, not just values (RR2-11): a key that
//      itself matches a high-confidence pattern or is a bare >= 32-hex
//      run FAILS — a secret pasted as a JSON key is still a secret in
//      the file. (The keyword rule does not apply to keys as keys: a
//      field NAMED api_key is normal; the rule bites on its value.)
//   6. JUDGE ARTIFACT citation (D15, GAP-13; extended in the D15
//      red-team rounds 1–5): a round or feedback line carrying SCORES
//      (a non-null `scores` object on a round, a non-null `scoreAfter`
//      on a feedback) is a grade claim, and run-log.mjs only writes
//      one behind a validated judge artifact. So on a scored line:
//      (a) `grader` null OR ABSENT is itself a violation — the writer
//      never produces a score with no grader (a no-grade line carries
//      scores: null); (b) with a grader, the line must ALSO carry
//      `judgeReport` (a non-empty string) AND `judgeReportSha`
//      (exactly 64 hex); (c) when the checker runs on a log FILE (the
//      CLI — the gate's path), the citation is VERIFIED, not merely
//      present — by the SHARED verifiers in judge-report.mjs
//      (verifyGradedLine / verifyFeedbackLine / verifyJuryLine), the
//      same functions run-log.mjs's read paths use: the cited file
//      must exist relative to the project root (the log lives at
//      <project>/design/run-log.jsonl, so the project root is two
//      directories up from the log file), must not be a SYMLINK
//      (lstat — the writer refuses symlink citations at record time;
//      NA8), must resolve inside the project's design/ (round 4, F6:
//      containment is design/ in every consumer — a citation at the
//      project root verifies nowhere), must hash (sha256) to the
//      stored judgeReportSha, and must PARSE as the line's own
//      report — header round == the line's round, kind absolute/
//      cheap (regrade on a feedback line), parsed score table ==
//      the line's scores, header grader == the line's grader (B5),
//      header page-sha256 == the line's pageSha (B1/B6) — so a
//      citation copied from ANOTHER round's genuine line (C3) fails
//      even though its hash verifies. A missing/unreadable file is a
//      violation message, never a crash. (f) a scored round line's
//      `juryReportShas`, when present and non-null, must be exactly
//      three 64-hex values joined with ';' (NA2), and its
//      `pairwiseReportShas`, when present and non-null, exactly two
//      (round 5, N5b — the same shape rule for the pairwise
//      citation set). Round 5 (N1/N2/N3/N5/N6) extended the
//      shared verifier's field coverage inside verifyGradedLine:
//      the graded shape requires gate exactly "pass" (N1), the
//      line's evidence must equal the cited report's derived
//      evidence (N2), juror artifacts bind the round's page (N3),
//      a pairwise transcription re-derives from its two artifacts
//      — swap proof and verdict, tie rule included (N5), and
//      expert evidence transcribes like expert scores (N6).
//      Round 6 (X1–X5): the graded line's own cited gate legs
//      verify on disk against their stored shas (X2), juror and
//      expert artifacts bind the line's tokensHash (X3/X4), the
//      line's notRegraded transcribes its artifact's not-regraded
//      header set (X5) — and rule 6 now covers CROSSCHECK lines
//      too (X1): a crosscheck line verifies through the shared
//      verifyCrosscheckLine (verdict re-derived from its own
//      counts, checker on the record-time allowlist, independence
//      basis, and — on the CLI path — its cited report existing
//      inside design/), because land and prepare act on the latest
//      stored verdict and a hand-appended "clear" line over a
//      genuine blocked verdict was verified by nobody.
//      A scored JURY
//      round line's jury verifies as a jury (B2 — the recorded
//      median is no longer trusted on the absolute citation alone):
//      its three juror artifacts at the conventional paths hash to
//      juryReportShas and parse, the parsed votes equal the line's
//      juryVotes as a set, the parsed median equals the line's
//      jury, and the family rule holds. (i) there is NO fallback
//      parser: when the sibling judge-report.mjs cannot be imported,
//      every scored line's citation check produces the violation
//      "citation cannot be verified — judge-report parser
//      unavailable" (B4 — the round-2 minimal local parser accepted
//      VOID-carrying and duplicate-key headers the real grammar
//      rejects, so a partial copy passed logs the full checker
//      fails; a partial copy now flags graded logs as unverifiable
//      rather than passing them, while rules 1–5 still run).
//      Round 4 (F1–F7) is the parity round: rounds 1–3 implemented
//      (c)–(i) TWICE — once in run-log.mjs's shared verifier and
//      once as private copies in this file (citationParseProblem /
//      juryParseProblem) — and the copies drifted: the parse half
//      here never applied the header basis independence check or
//      the body Round line agreement (F1), no copy verified juror
//      device+inode distinctness (F2) or juror bases (F3), this
//      file verified a jury only when jury/juryVotes were present
//      (F4), the line's own independenceBasis / tokensHash fields
//      were compared against their artifact by nobody (F5),
//      containment differed (this file: the project root; run-log:
//      design/ — F6), and expert citations were opened by no read
//      path at all (F7). The copies are deleted; rule 6 calls the
//      shared verifiers, which also gained the F2/F3/F5/F7 halves,
//      and the one jury-line definition (isJuryRoundLine: any of
//      jury / juryVotes / juryReportShas present and non-null)
//      governs every consumer. SCORELESS lines are shape-checked
//      too (round 2): the writer couples `pageSha` and judge
//      citations to a grade, so a scoreless round/feedback line
//      carrying a non-null pageSha (the NA4 poison shape) or a
//      citation is a violation, and so is a grader on a scoreless
//      line (a no-grade round stores grader null; feedback without
//      a regrade stores grader null — grader null on a scoreless
//      line is legitimate ONLY with no grade-coupled fields beside
//      it); a scoreless round line carrying expert scores has its
//      expert citations verified too (round 4, F7). Lock/other line
//      kinds are not round lines and are untouched. This is the
//      downstream tripwire for the self-grading escape: a line
//      failing any of (a)–(f) was hand-appended or written by a
//      pre-D15 script — either way the next gate run fails loudly on
//      it instead of letting it stand as a grade. checkRunLogLine
//      called WITHOUT a project root (a pure line-local caller)
//      applies the line-local halves only; the CLI always passes the
//      root, so the gate path always verifies.
// MAINTENANCE HAZARD, stated plainly: the high-confidence pattern below
// is a DUPLICATE of gate.sh's sec_11_pat (same alternation, JS syntax
// vs bash ERE) — the two must be changed together. They are kept as two
// copies rather than centralised because one lives in a bash script and
// the other in a node module; a shared file would make both depend on a
// third file's presence at gate time.
// What stays open, by name: a NON-hex high-entropy string (e.g. base64-ish)
// in a free-text field under a non-keyword key — no keyword, no known
// token shape, not a bare hex run. That is the narrowed remainder of the
// old run-log residual hole (iii): it now needs a secret pasted into a
// free-text field in a shape no pattern recognises, where before it also
// covered the G3/G4/G10 shapes, which are closed here.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { findDuplicateKey } from './json-dup-keys.mjs';

// Citation VERIFICATION (D15 red-team round 2; round 3 removed the
// fallback; round 4 removed the re-implementations): the shared
// judge-report module lives one directory up
// (scripts/judge-report.mjs) and is import-safe (its CLI runs only
// when invoked directly). It holds the report parser AND the
// read-path verifiers (verifyGradedLine / verifyJuryLine /
// verifyFeedbackLine / verifyExpertCitations / isJuryRoundLine) —
// the same functions run-log.mjs's read paths (best, land,
// feedback) use. Round 3 left this file with private
// re-implementations of those verifiers (citationParseProblem /
// juryParseProblem), and round 4 proved the copies had drifted
// (F1–F7): this file's parse half never applied the independence-
// basis check or the body-Round-line agreement, verified a jury
// only when jury/juryVotes were present, and never opened expert
// citations at all. The copies are DELETED: rule 6 now calls the
// shared verifiers, so a citation verdict here is the verdict every
// consumer reaches. The module is loaded dynamically so this file
// can DETECT its absence: round 2 shipped a minimal local fallback
// parser for that case, and round 3 (B4) proved a fallback is a
// hole, not a degradation — it accepted header shapes the real
// grammar rejects, so a partial copy of the checker PASSED logs the
// full checker fails. There is NO fallback: if the sibling cannot
// be imported or fails to load, judgeMod stays null and rule 6's
// citation check FAILS CLOSED — every scored line's citation
// produces the violation "citation cannot be verified —
// judge-report parser unavailable" — while the secret-scan rules
// (1–5) continue to run. A partial copy therefore flags graded logs
// as unverifiable rather than passing them; the repair is to restore
// the sibling file (re-run ./install.sh), not to weaken the check.
let judgeMod = null;
try {
  judgeMod = await import('../judge-report.mjs');
} catch {
  judgeMod = null;
}

// Keyword test (RR2-04, widened RR3-02): base keyword, then an optional
// continuation that must start with '_', a digit, '-', or '.' — never a
// bare letter — or with a space/tab starting a spaced continuation.
// Matches: api_key, api_key2, api-key, api-key-2, apikey, secret,
// secret_key, secret-key, secret.key, secret_key-2, "api key",
// "secret key", password, password_hash, password-hash, access_token2,
// access_token-2, api.key, access.token, secret<TAB>key, secret<TAB>.
// Does NOT match: secretary, secretariat, passworder (the word
// continues in letters). The same widening lives in gate.sh's two
// assign patterns — change both together.
const KEYWORD_RE = /^(api[ _.-]?key|apikey|secret|passwd|password|access[ _.-]?token)(?:[_0-9.-][A-Za-z0-9_.-]*|[ \t][A-Za-z0-9_ \t.-]*)?$/i;
// High-confidence secret patterns (RR2-05). DUPLICATE of gate.sh
// sec_11_pat — change both together (see the header hazard note).
// Case-insensitive (RR3-06, fix round 4B): the sk- arms must agree
// with KEYWORD_RE and the assign patterns, which are already
// case-insensitive — so SK-PROJ- / SK-ANT- / SK-LIVE- match too. The
// `i` flag applies to the whole alternation (AKIA / ghp_ / private-key
// header included); that is fail-closed, not a widening of any live
// credential shape — issued keys are lowercase, and an uppercased
// prefix is not a usable credential, but the two layers must agree.
// sk- prefixes, verified 2026-11-11: OpenAI project keys sk-proj-,
// service-account keys sk-svcacct- and admin keys sk-admin- (the OpenAI API
// reference, developers.openai.com, confirms the three key *types* —
// ProjectAPIKey object, service-account API key endpoint, AdminAPIKey
// object — but the literal `sk-svcacct-` string is NOT printed there, the
// example value being redacted; the literal prefixes are verified via the
// gitleaks/TruffleHog OpenAI rules, which key on the same three prefixes
// plus the T3BlbkFJ marker, and via independent secondary sources);
// Anthropic keys sk-ant-api03- (current), plus
// sk-ant-admin01- / sk-ant-oat01- (Anthropic docs, via docs.anthropic.com
// as cited by the key-format summaries) — covered here by the open
// sk-ant-[A-Za-z0-9-]{10,} arm so later sk-ant-* generations match too.
const HIGH_CONF_RE =
  /(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-(live|test)-[A-Za-z0-9]{16,}|sk-(proj|svcacct|admin)-[A-Za-z0-9_-]{20,}|sk-ant-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)/i;
const BARE_HEX_RE = /^[0-9A-Fa-f]{32,}$/;

export function checkRunLogLine(line, ctx) {
  let obj;
  try {
    obj = JSON.parse(line);
  } catch (e) {
    return `line does not parse as JSON (${e.message}) — fail closed`;
  }
  if (obj === null || typeof obj !== 'object' || Array.isArray(obj)) {
    return 'line is not a JSON object (run-log.mjs writes one object per line)';
  }
  // RR2-03: duplicate keys in the raw text — JSON.parse above kept only
  // the last value, so check the raw line before trusting the object.
  const dup = findDuplicateKey(line);
  if (dup !== null) {
    return `line has a duplicate JSON key "${dup}" — fail closed`;
  }
  const problems = [];
  // Rule 6 (D15 + red-team rounds 1–4): a scored round/feedback line
  // must carry a grader AND its judge artifact citation — judgeReport
  // (non-empty string) + judgeReportSha (exactly 64 hex) — and, when
  // a project root is known (the CLI path), the citation must VERIFY.
  // The verification is delegated to the SHARED verifiers in
  // judge-report.mjs — verifyGradedLine for a round line,
  // verifyFeedbackLine for a feedback line, verifyJuryLine for a jury
  // line (per the ONE shared definition, isJuryRoundLine) — the same
  // functions run-log.mjs's read paths use, so the verdict reached
  // here cannot drift from theirs (rounds 1–3 kept private copies of
  // the parse/jury halves in this file; round 4 deleted them after
  // the drift was proven, F1–F7). When the sibling module cannot be
  // imported the citation is unverifiable (B4, fail closed, no
  // fallback parser). Scoreless lines are shape-checked too (round
  // 2): the writer couples pageSha and citations to a grade, so a
  // scoreless line carrying either is a hand-appended shape (the NA4
  // poison), and a grader on a scoreless round/feedback line is never
  // written either (a no-grade round stores grader null; feedback
  // without a regrade stores grader null). A scoreless ROUND line's
  // expert citations, when it carries expert scores, verify through
  // the same shared verifyExpertCitations (round 4, F7). See the
  // header for the rule.
  if (obj.kind === 'round' || obj.kind === 'feedback') {
    const carriedScores = obj.kind === 'round'
      ? obj.scores !== null && obj.scores !== undefined
      : obj.scoreAfter !== null && obj.scoreAfter !== undefined;
    const hasPageSha = obj.pageSha !== null && obj.pageSha !== undefined;
    const hasCitation = (typeof obj.judgeReport === 'string' && obj.judgeReport.length > 0)
      || (typeof obj.judgeReportSha === 'string' && obj.judgeReportSha.length > 0);
    if (!carriedScores) {
      if (hasPageSha) {
        problems.push(`scoreless ${obj.kind} line carries a pageSha — run-log.mjs couples pageSha to a grade (a no-grade round line and an ungraded feedback line both store pageSha null), so this line was hand-appended or pre-D15 (D15)`);
      }
      if (hasCitation) {
        problems.push(`scoreless ${obj.kind} line carries a judge artifact citation — run-log.mjs cites a judge artifact only behind a grade, so this line was hand-appended or pre-D15 (D15)`);
      }
      if (obj.grader !== null && obj.grader !== undefined) {
        problems.push(`${obj.kind} line carries grader "${obj.grader}" but no ${obj.kind === 'round' ? 'scores' : 'regrade score'} — run-log.mjs never writes a grader without a grade (a no-grade round and an ungraded feedback both store grader null), so this line was hand-appended or pre-D15 (D15)`);
      }
      // Round 4 (F7): expert scores on a scoreless (no-grade) round
      // line are scores too — when the root is known, their
      // citations verify through the shared verifier, exactly as a
      // graded line's do inside verifyGradedLine.
      if (obj.kind === 'round' && ctx && ctx.projectRoot
        && ((obj.expertMotion !== null && obj.expertMotion !== undefined)
          || (obj.expertUx !== null && obj.expertUx !== undefined))) {
        if (!judgeMod) {
          problems.push('scoreless round line carries expert scores whose citations cannot be verified — judge-report parser unavailable (D15)');
        } else {
          const ev = judgeMod.verifyExpertCitations(ctx.projectRoot, obj);
          if (!ev.ok) {
            problems.push(`scoreless round line's expert citations do not verify: ${ev.reasons.join('; ')} (D15)`);
          }
        }
      }
    }
    if (carriedScores) {
      if (obj.grader === null || obj.grader === undefined) {
        problems.push(`scored ${obj.kind} line carries no grader — run-log.mjs never writes a score without an independent grader, so this line was hand-appended or pre-D15 (D15)`);
      } else {
        const hasReport = typeof obj.judgeReport === 'string' && obj.judgeReport.length > 0;
        const hasSha = typeof obj.judgeReportSha === 'string' && /^[0-9a-f]{64}$/i.test(obj.judgeReportSha);
        if (!hasReport) {
          problems.push(`scored ${obj.kind} line with grader "${obj.grader}" carries no judgeReport — a grade without a judge artifact is a self-assertion (D15)`);
        }
        if (!hasSha) {
          problems.push(`scored ${obj.kind} line with grader "${obj.grader}" carries no valid judgeReportSha (exactly 64 hex) — a grade without a judge artifact is a self-assertion (D15)`);
        }
        // Round 2 (NA2): a scored round line's juryReportShas, when
        // present and non-null, is the writer's `;`-join of exactly
        // three juror sha256 values — anything else is not a shape
        // the writer produces. (Line-local: it applies with or
        // without a project root; with a root, verifyJuryLine
        // checks the same shape again on the way to the artifacts.)
        if (obj.kind === 'round' && obj.juryReportShas !== null && obj.juryReportShas !== undefined) {
          const parts = String(obj.juryReportShas).split(';');
          if (parts.length !== 3 || parts.some((s) => !/^[0-9a-f]{64}$/i.test(s))) {
            problems.push(`scored round line carries juryReportShas "${obj.juryReportShas}" — not exactly three 64-hex sha256 values joined with ';', the only shape run-log.mjs writes (D15)`);
          }
        }
        // Round 5 (N5b): the same shape rule for the pairwise
        // citation set — a scored round line's pairwiseReportShas,
        // when present and non-null, is the writer's `;`-join of
        // exactly TWO pairwise sha256 values. (Line-local, like
        // the jury rule above; with a root, the shared
        // verifyGradedLine -> verifyPairwiseLine checks the shape
        // again on the way to re-deriving the verdict from the
        // artifacts themselves.)
        if (obj.kind === 'round' && obj.pairwiseReportShas !== null && obj.pairwiseReportShas !== undefined) {
          const parts = String(obj.pairwiseReportShas).split(';');
          if (parts.length !== 2 || parts.some((s) => !/^[0-9a-f]{64}$/i.test(s))) {
            problems.push(`scored round line carries pairwiseReportShas "${obj.pairwiseReportShas}" — not exactly two 64-hex sha256 values joined with ';', the only shape run-log.mjs writes (D15)`);
          }
        }
        if (hasReport && hasSha && ctx && ctx.projectRoot) {
          // Citation verification (fail-closed, never crashy),
          // delegated to the shared verifiers in judge-report.mjs:
          // the cited file must not be a symlink, must resolve
          // inside <project>/design/, must exist, must hash to the
          // stored judgeReportSha, and must PARSE as the line's own
          // report — header round / kind / grader / page-sha256,
          // the parsed score table, the header basis independence
          // check, the body Round line agreement, and (round 4, F5)
          // the line's own independenceBasis / tokensHash
          // transcription fields — plus, inside verifyGradedLine,
          // the line's expert citations (F7). Round 3 (B4): when
          // the shared judge-report module could not be imported
          // there is NO fallback — the citation is reported as
          // unverifiable, fail closed, while the secret-scan rules
          // continue below.
          if (!judgeMod) {
            problems.push(`scored ${obj.kind} line cites judgeReport "${obj.judgeReport}", which cannot be verified — judge-report parser unavailable — the citation does not verify (D15)`);
          } else {
            const v = obj.kind === 'feedback'
              ? judgeMod.verifyFeedbackLine(ctx.projectRoot, obj)
              : judgeMod.verifyGradedLine(ctx.projectRoot, obj);
            if (!v.ok) {
              problems.push(`scored ${obj.kind} line cites judgeReport "${obj.judgeReport}", which does not verify: ${v.reasons.join('; ')} (D15)`);
            }
            // A jury line's JURY verifies as a jury too, not only
            // its absolute citation (B2) — the recorded median is
            // trusted only when the juror artifacts derive it
            // (votes as a set, median, family rule, and round 4's
            // juror distinctness + basis halves). Round 4 (F4):
            // ONE jury-line definition — isJuryRoundLine (any of
            // jury / juryVotes / juryReportShas present and
            // non-null) — replaces this file's old jury/juryVotes-
            // only trigger, under which a juryReportShas-only line
            // passed unchecked.
            if (obj.kind === 'round' && judgeMod.isJuryRoundLine(obj)) {
              const jv = judgeMod.verifyJuryLine(ctx.projectRoot, obj);
              if (!jv.ok) {
                problems.push(`scored round line's jury does not verify: ${jv.reasons.join('; ')} (D15)`);
              }
            }
          }
        }
      }
    }
  }
  // Rule 6, crosscheck half (round 6, X1): a crosscheck line is a
  // verdict other consumers act on (land, prepare's cross-check
  // bit), and before round 6 this checker never looked at one — a
  // hand-appended "clear" line whose own counts derive "blocked",
  // naming an unlisted checker or a report that does not exist,
  // passed here while land and prepare trusted it. The check is
  // delegated to the SAME shared verifyCrosscheckLine: with a
  // project root the full verification runs (verdict re-derived
  // from the counts, checker allowlist, independence basis, cited
  // report on disk inside design/); without a root the line-local
  // halves run (derivation + shapes — there is no project to
  // resolve the report against). Fail-closed like the citation
  // half: with a root and no sibling module, the line is
  // unverifiable and is flagged, never passed.
  if (obj.kind === 'crosscheck') {
    if (!judgeMod) {
      if (ctx && ctx.projectRoot) {
        problems.push('crosscheck line cannot be verified — judge-report parser unavailable (D15)');
      }
    } else {
      const cv = judgeMod.verifyCrosscheckLine(ctx && ctx.projectRoot ? ctx.projectRoot : null, obj);
      if (!cv.ok) {
        problems.push(`crosscheck line does not verify: ${cv.reasons.join('; ')} (D15)`);
      }
    }
  }
  const walk = (value, key) => {
    if (typeof value === 'string') {
      if (key !== null && KEYWORD_RE.test(key) && value.length >= 16) {
        problems.push(`secret-keyword field "${key}" holds a ${value.length}-char string value`);
      } else if (key !== 'tokensHash' && BARE_HEX_RE.test(value) && !isShaExempt(key, value)) {
        problems.push(`bare ${value.length}-hex string value under non-tokensHash field "${key}"`);
      }
      if (HIGH_CONF_RE.test(value)) {
        problems.push(`high-confidence secret pattern in field "${key ?? '(value)'}"`);
      }
      return;
    }
    if (Array.isArray(value)) {
      value.forEach((v) => walk(v, key));
      return;
    }
    if (value !== null && typeof value === 'object') {
      for (const [k, v] of Object.entries(value)) {
        // RR2-11: keys are strings in the file too — a secret-shaped
        // key (high-confidence pattern or bare >= 32-hex run) FAILS.
        if (HIGH_CONF_RE.test(k)) {
          problems.push(`high-confidence secret pattern in key "${k}"`);
        } else if (BARE_HEX_RE.test(k)) {
          problems.push(`bare ${k.length}-hex string as key "${k}"`);
        }
        walk(v, k);
      }
    }
  };
  walk(obj, null);
  return problems.length ? problems.join('; ') : null;
}

// RR2-06: the *sha exemption is key-AND-length. A git SHA is 40 hex
// (SHA-1) or 64 hex (SHA-256), never 32 — so a 32-hex value under a *sha
// key is NOT exempt, and a 40-hex value under any other key is NOT
// exempt either (the old length-only exemption would also have passed a
// legacy GitHub OAuth token, which is 40 hex, in a notes field).
function isShaExempt(key, value) {
  return /sha$/i.test(key ?? '') && (value.length === 40 || value.length === 64);
}

const invokedDirectly =
  process.argv[1] != null && process.argv[1].endsWith('runlog-check.mjs');
if (invokedDirectly) {
  const file = process.argv[2];
  if (!file) {
    console.error('usage: runlog-check.mjs <file>');
    process.exit(2);
  }
  let text;
  try {
    text = readFileSync(file, 'utf8');
  } catch (e) {
    console.error(`runlog-check.mjs: cannot read ${file}: ${e.message}`);
    process.exit(2);
  }
  // Rule 6's citation verification needs the project root: the log
  // lives at <project>/design/run-log.jsonl, so the root is two
  // directories up from the log file.
  const projectRoot = path.dirname(path.dirname(path.resolve(file)));
  let failed = false;
  text.split('\n').forEach((line, i) => {
    if (line.trim() === '') return;
    const problem = checkRunLogLine(line, { projectRoot });
    if (problem) {
      console.log(`${file}:${i + 1}: ${problem}`);
      failed = true;
    }
  });
  process.exit(failed ? 1 : 0);
}
