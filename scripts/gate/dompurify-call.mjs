#!/usr/bin/env node
// dompurify-call.mjs — RT-02 helper for gate.sh check 1.2 (and gate.mjs leg 2).
//
// Usage: node dompurify-call.mjs <file>
// Exit 0 if the file contains a genuine DOMPurify.sanitize CALL outside
// comments and string literals; exit 1 otherwise; exit 2 on usage/read error.
//
// Why this exists: the old 1.2 exception was a substring test
// (grep 'DOMPurify.sanitize'), so a file passed if the string appeared
// anywhere — including in a comment, a string literal, or dead code —
// with no requirement that it is called, let alone that it wraps the
// sink. This helper strips HTML comments (<!-- ... -->), JS line/block
// comments, quoted string/template literals, and regex literals (replaced
// by spaces, newlines preserved), then tests for a genuine call site.
//
// The call-site test is ANCHORED (RR-01, fix round 2; RR2-01, fix round 3;
// RR3-01, fix round 4 — the anchor is Unicode-aware: \p{ID_Continue}
// with the u flag, so éDOMPurify / CJK-prefixed DOMPurify no longer
// match). The DOMPurify identifier must be the identifier itself — not a
// property access on another object (x.DOMPurify.sanitize), not part of a
// longer identifier (notDOMPurify.sanitize, $DOMPurify.sanitize). The only
// allowed prefix is a genuine global alias (window./globalThis./self., dot
// or bracket form — RR2-08), itself anchored the same way. Bracket notation
// (DOMPurify['sanitize']() — RR-10) counts as a genuine call. Spread and
// optional chaining count too (fix round 4): [...DOMPurify.sanitize(q)],
// f(...DOMPurify.sanitize(q)), DOMPurify?.sanitize(q),
// window?.DOMPurify.sanitize(q), DOMPurify.sanitize?.(q).
// WHITESPACE-AWARE ANCHOR (RR2-01): JS allows whitespace around the dot,
// so the stripped text is NORMALISED (\s*\.\s* -> '.', \s*\[ -> '[',
// \s+\] -> ']') BEFORE the call regex runs. Without that, the anchor was
// checked at the wrong position: in `x. DOMPurify.sanitize(q)` the match
// started at the space after the dot, which satisfied the one-character
// negated anchor class, and a foreign-object smuggle passed 1.2.
// After normalisation `x. DOMPurify` becomes `x.DOMPurify` (anchor char
// is '.' -> no match) while genuine `window . DOMPurify` becomes
// `window.DOMPurify` (still CALL) and `foo . window . DOMPurify` becomes
// `foo.window.DOMPurify` (still NO-CALL). The anchor also rejects a
// preceding quote character, so a kept 'DOMPurify' bracket key on a
// foreign object (x['DOMPurify']) can never match.
//
// Regex literals are tracked with a regex-vs-division heuristic (RR-02,
// fix round 2; RR2-02, fix round 3): a '/' starts a regex literal when
// the preceding significant token cannot end an expression (start of
// input, '(', ',', '=', ':', '[', '!', '&', '|', '?', '{', '}', ';', an
// operator, or a keyword such as return/typeof/case); after an
// identifier, number, string, ')', ']' or '++'/'--' it is division.
// A regex literal is consumed whole (escapes and [...] character classes
// handled, so a '//' inside a regex never starts a comment — RR-10),
// then stripped. This is a heuristic, not a parser: the ambiguous cases
// fail CLOSED. A '{'/'}' is treated as regex-allowed (object-literal vs
// block ambiguity), so a division after an object literal could be
// misread as a regex and strip to the next '/' — possibly eating a
// genuine call on the same span and FAILING the gate, never passing a
// smuggled one. A regex literal in a genuinely ambiguous position is
// stripped the same way.
// STATEMENT POSITION (RR2-02): ')' does NOT unconditionally mean "value
// position". The stripper tracks a paren stack: a '(' that follows
// if/while/for/with opens a statement-keyword paren, and its matching ')'
// leaves the parser at statement start, where '/' begins a regex
// literal — so `if(x)/DOMPurify.sanitize(foobar)/.test(y);` is a regex
// statement, not a division. Any other ')' leaves value position, so
// `f() / DOMPurify.sanitize(q)` is still division and still CALL.
// The `.` lookback for that keyword test (RR3-05, fix round 4) runs on
// the stripped text, so a comment between `.` and the word
// (`x. /*c*/ if(y)`) still finds the dot — the word stays a property
// and the following `/` stays division.
// WHITESPACE IS NEUTRAL (RR2-02): whitespace never changes prevValue —
// only a real token may — so `if (x) /re/` and `if(x)/re/` classify the
// same way. A regex literal's flags are consumed as [dgimsuvy] only
// (RR2-10): the old [a-z] loop ate a following identifier.
//
// Limits, stated honestly:
// - A call inside a template-literal ${...} interpolation is stripped
//   with the template, so it does NOT count — fail-closed (move the call
//   out of the template and the gate passes).
// - Aliasing (const s = DOMPurify.sanitize; s(x)) does NOT count — the
//   gate requires a visible call site.
// - This proves a call site EXISTS, not that it wraps the sink: the
//   per-occurrence taint check (is THIS sink fed by untrusted data?)
//   is still checklist territory, as before.
import { readFileSync } from 'node:fs';

const REGEX_AFTER_KEYWORDS = new Set([
  'return', 'typeof', 'case', 'delete', 'void', 'in', 'of', 'new',
  'instanceof', 'yield', 'await', 'throw', 'else', 'do',
]);

// The '(' keywords whose matching ')' leaves statement position.
const STATEMENT_PAREN_KEYWORDS = new Set(['if', 'while', 'for', 'with']);

const isWs = (ch) =>
  ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r' || ch === '\f' || ch === '\v';

export function stripCommentsAndStrings(src) {
  let out = '';
  let i = 0;
  const n = src.length;
  // prevValue: true if the last significant token can end an expression
  // (identifier, number, string/template literal, ')', ']' in value
  // position, '++', '--', a regex literal). A '/' after such a token is
  // division; otherwise it may start a regex literal (or a comment).
  // '{' and '}' set prevValue false (ambiguous — see the header: the
  // fail-closed direction is chosen). Whitespace NEVER changes prevValue
  // (RR2-02): only a real token may.
  let prevValue = false;
  // parenStack: one entry per open '(', true when the '(' followed
  // if/while/for/with (its ')' is statement position), else false.
  const parenStack = [];
  // lastWord: the most recent bare identifier, or null when the last
  // significant token was not a bare identifier. Whitespace and comments
  // do not clear it (if (x) has a space before the paren); a '.' before
  // the word makes it a property (x.if), not a keyword.
  let lastWord = null;
  const blank = (from, to) => {
    for (let j = from; j < to; j++) out += src[j] === '\n' ? '\n' : ' ';
  };
  while (i < n) {
    const c = src[i];
    // Whitespace: neutral — it neither ends an expression nor starts
    // one, and it must not reset the regex/division classification.
    if (isWs(c)) {
      out += c;
      i++;
      continue;
    }
    // HTML comment <!-- ... -->
    if (src.startsWith('<!--', i)) {
      const end = src.indexOf('-->', i + 4);
      const stop = end === -1 ? n : end + 3;
      blank(i, stop);
      i = stop;
      continue;
    }
    // JS line comment // ... (a '//' always starts a comment in JS;
    // a '//' inside a regex literal never reaches here — the regex
    // branch below consumes the whole literal first).
    if (c === '/' && src[i + 1] === '/') {
      const start = i;
      while (i < n && src[i] !== '\n') i++;
      blank(start, i);
      continue;
    }
    // JS block comment /* ... */
    if (c === '/' && src[i + 1] === '*') {
      const end = src.indexOf('*/', i + 2);
      const stop = end === -1 ? n : end + 2;
      blank(i, stop);
      i = stop;
      continue;
    }
    // Regex literal vs division: '/' here is a lone slash (not // or /*).
    if (c === '/') {
      if (!prevValue) {
        // Regex literal: consume to the closing '/' (escapes and [...]
        // classes handled), then flags. Unterminated (newline first) is
        // invalid JS — stop stripping and leave the rest in place.
        const start = i;
        i++;
        let inClass = false;
        let closed = false;
        while (i < n) {
          const ch = src[i];
          if (ch === '\n') break;
          if (ch === '\\') { i += 2; continue; }
          if (ch === '[') inClass = true;
          else if (ch === ']') inClass = false;
          else if (ch === '/' && !inClass) { closed = true; i++; break; }
          i++;
        }
        if (closed) {
          // Flags are only d g i m s u v y (RR2-10): consuming any
          // letter ate a following identifier in the old [a-z] loop.
          while (i < n && /[dgimsuvy]/.test(src[i])) i++;
          blank(start, i);
          prevValue = true; // a regex literal is a value
          lastWord = null;
          continue;
        }
        // Unterminated: emit the '/' as code and carry on.
        out += c;
        i = start + 1;
        prevValue = false;
        lastWord = null;
        continue;
      }
      out += c;
      i++;
      prevValue = false; // division operator
      lastWord = null;
      continue;
    }
    // Quoted string or template literal '...' "..." `...`
    if (c === "'" || c === '"' || c === '`') {
      const q = c;
      const start = i;
      i++;
      while (i < n) {
        if (src[i] === '\\') { i += 2; continue; }
        if (src[i] === q) { i++; break; }
        i++;
      }
      // A string literal that is exactly 'sanitize' is kept verbatim:
      // it is the bracket-notation key in DOMPurify['sanitize'](q), and
      // blanking it would make a genuine call unrecognisable (RR-10).
      // A string literal that is exactly 'DOMPurify' is kept verbatim
      // for the same reason: it is the bracket-notation key in
      // window['DOMPurify'].sanitize(q) (RR2-08). Nothing else is kept
      // — a kept 'sanitize' on its own can never complete the call
      // pattern, which needs DOMPurify + '[' before it, and a kept
      // 'DOMPurify' can never match either, because the anchor rejects
      // a preceding quote character (so x['DOMPurify'] stays NO-CALL).
      const span = src.slice(start, i);
      if (span === "'sanitize'" || span === '"sanitize"' || span === '`sanitize`' ||
          span === "'DOMPurify'" || span === '"DOMPurify"' || span === '`DOMPurify`') {
        out += span;
      } else {
        blank(start, i);
      }
      prevValue = true; // a string/template literal is a value
      lastWord = null;
      continue;
    }
    // Identifier / keyword.
    if (/[A-Za-z_$]/.test(c)) {
      const start = i;
      while (i < n && /[A-Za-z0-9_$]/.test(src[i])) i++;
      const word = src.slice(start, i);
      out += word;
      // Property access (x.if, x . if): the word is a property name,
      // never the if/while/for/with keyword. Look back past whitespace
      // for a '.'; anything else leaves the word as a bare identifier.
      // RR3-05: the lookback runs on `out` (the stripped text so far),
      // not `src`. Comments are already blanked to spaces in `out`, so
      // `x. /*c*/ if(y)` and `x. //c\n if(y)` find the '.' through the
      // comment exactly as the parser does, while a real keyword `if`
      // never has a '.' before it through a comment. `out` stays
      // position-aligned with `src` (every branch appends exactly as
      // many chars as it consumes), so index `start` means the same
      // place in both; a '.' inside a blanked string/regex/comment can
      // never false-trigger, because it is a space in `out`.
      let j = start - 1;
      while (j >= 0 && isWs(out[j])) j--;
      lastWord = (j >= 0 && out[j] === '.') ? null : word;
      prevValue = !REGEX_AFTER_KEYWORDS.has(word);
      continue;
    }
    // Number literal (consumed verbatim; only the value-ness matters).
    if (/[0-9]/.test(c)) {
      const start = i;
      while (i < n && /[0-9A-Za-z_.$]/.test(src[i])) i++;
      out += src.slice(start, i);
      prevValue = true;
      lastWord = null;
      continue;
    }
    // '++' / '--' are values (postfix); any other two-char operator is not.
    if ((c === '+' && src[i + 1] === '+') || (c === '-' && src[i + 1] === '-')) {
      out += c + src[i + 1];
      i += 2;
      prevValue = true;
      lastWord = null;
      continue;
    }
    // '(' opens a paren context: statement-keyword when it follows
    // if/while/for/with (RR2-02), call/grouping otherwise.
    if (c === '(') {
      parenStack.push(STATEMENT_PAREN_KEYWORDS.has(lastWord));
      out += c;
      i++;
      prevValue = false;
      lastWord = null;
      continue;
    }
    // ')' closes a paren context: statement position (regex may follow)
    // iff it closes a statement-keyword paren, else value position
    // (division follows). An unmatched ')' (invalid JS) falls back to
    // value position, the old behaviour.
    if (c === ')') {
      const kw = parenStack.pop();
      out += c;
      i++;
      prevValue = kw === true ? false : true;
      lastWord = null;
      continue;
    }
    out += c;
    i++;
    prevValue = c === ']';
    lastWord = null;
  }
  return out;
}

// Normalise the stripped text before the call-site test (RR2-01):
// collapse whitespace around '.' and brackets, so the anchor below is
// tested against the property-access structure JS actually parses, not
// against the formatting. `x. DOMPurify` -> `x.DOMPurify`,
// `window . DOMPurify` -> `window.DOMPurify`,
// `DOMPurify ['sanitize'] (q)` -> `DOMPurify['sanitize'](q)`.
export function normaliseCallText(stripped) {
  return stripped
    .replace(/\s*\.\s*/g, '.')
    .replace(/\s*\[\s*/g, '[')
    .replace(/\s+\]/g, ']');
}

// Anchored call-site test (RR-01 + RR-10 + RR2-01 + RR2-08 + RR3-01 +
// spread/optional-chaining, fix round 4), run on the NORMALISED stripped
// text. The character before the subject must be the start of input or a
// non-identifier, non-'.', non-quote character, so x.DOMPurify,
// notDOMPurify and $DOMPurify never match, while
// window./globalThis./self.DOMPurify do — in dot form or bracket form
// (window['DOMPurify'], globalThis["DOMPurify"]) — and a foreign object's
// bracket access (x['DOMPurify']) never matches, because the kept bracket
// key is preceded by a quote. UNICODE-AWARE ANCHOR (RR3-01): the negated
// class is [^\p{ID_Continue}$."'`] with the u flag — JS identifiers may
// start with any Unicode ID_Start letter, so an ASCII-only class let
// éDOMPurify / CJK-prefixed DOMPurify match. $ is not ID_Continue, so it
// is listed explicitly. The subject is bare DOMPurify, an alias in dot
// form (alias.DOMPurify), or an alias in bracket form (alias['DOMPurify']
// — the DOMPurify is already consumed as the key, so .sanitize follows
// directly). SPREAD + OPTIONAL CHAINING (fix round 4): an optional `...`
// may precede the subject ([...DOMPurify.sanitize(q)],
// f(...DOMPurify.sanitize(q))), and `?.` may join the alias to the
// subject (window?.DOMPurify), the subject to sanitize
// (DOMPurify?.sanitize), the alias/subject to a bracket key
// (window?.['DOMPurify'], DOMPurify?.['sanitize']), and sanitize to the
// call paren (DOMPurify.sanitize?.(q)). Both .sanitize( and
// ['sanitize']( count. The call-paren alternative is `?.(` or plain `(` —
// a bare `? (` (ternary) does NOT match, so `sanitize ? (q) : r` is not
// a call.
const SANITIZE_CALL_RE =
  /(?:^|[^\p{ID_Continue}$."'`])(?:\.\.\.)?(?:DOMPurify|(?:window|globalThis|self)(?:(?:\?\.|\.)DOMPurify|(?:\?\.)?\[[`'"\x60]DOMPurify['"`]\]))(?:(?:\?\.|\.)sanitize|(?:\?\.)?\[[`'"\x60]sanitize['"`]\])(?:\?\.\s*\(|\s*\()/u;

export function hasSanitizeCall(src) {
  return SANITIZE_CALL_RE.test(normaliseCallText(stripCommentsAndStrings(src)));
}

// CLI entry point: only runs when this file is invoked directly
// (node dompurify-call.mjs <file>). When imported (gate.mjs leg 2),
// only hasSanitizeCall/stripCommentsAndStrings are used and no exit
// happens here.
const invokedDirectly =
  process.argv[1] != null && process.argv[1].endsWith('dompurify-call.mjs');
if (invokedDirectly) {
  const file = process.argv[2];
  if (!file) {
    console.error('usage: dompurify-call.mjs <file>');
    process.exit(2);
  }
  let text;
  try {
    text = readFileSync(file, 'utf8');
  } catch (e) {
    console.error(`dompurify-call.mjs: cannot read ${file}: ${e.message}`);
    process.exit(2);
  }
  process.exit(hasSanitizeCall(text) ? 0 : 1);
}
