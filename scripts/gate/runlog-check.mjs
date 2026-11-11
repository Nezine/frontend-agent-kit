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
import { findDuplicateKey } from './json-dup-keys.mjs';

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

export function checkRunLogLine(line) {
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
  let failed = false;
  text.split('\n').forEach((line, i) => {
    if (line.trim() === '') return;
    const problem = checkRunLogLine(line);
    if (problem) {
      console.log(`${file}:${i + 1}: ${problem}`);
      failed = true;
    }
  });
  process.exit(failed ? 1 : 0);
}
