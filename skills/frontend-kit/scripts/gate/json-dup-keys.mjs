// json-dup-keys.mjs — duplicate JSON key detection on RAW text (RR2-03,
// fix round 3, 2026-11-11). Shared by seed-structural.mjs and
// runlog-check.mjs so both checks detect duplicates identically.
//
// JSON.parse keeps the LAST duplicate key and silently discards earlier
// ones, so a check that only reads the parsed object is blind to exactly
// the bytes an attacker adds as duplicates: {"key": "<64-hex>", "key":
// "<32-legit>"} parses to the pinned shape while the raw bytes still
// hold the secret. This scanner runs on the raw text AFTER JSON.parse
// has validated it, and reports the first duplicated key within any
// single object, or null when there is none.
//
// Keys are DECODED before comparison, so an escaped key ("\u006bey")
// counts as "key" — a literal raw-text count of `"key"` occurrences
// would miss that variant (it has exactly one literal `"key"`), which is
// why the scanner decodes instead of counting substrings.
//
// Method: a small scanner tracking string boundaries and container
// depth. A string is a key iff the next non-whitespace character is ':'
// and the innermost open container is an object (in valid JSON no
// string value can be followed by ':'), so values are never mistaken
// for keys. Each open object gets a Set of its decoded keys; a repeat
// in the same Set is a duplicate. Nested objects get their own Sets, so
// the same key in two different objects is NOT a duplicate.
export function findDuplicateKey(text) {
  // frames: one per open container; an object frame is a Set of its
  // decoded keys, an array frame is null (arrays have no keys).
  const frames = [];
  let i = 0;
  const n = text.length;
  // Decode one JSON string starting at text[i] === '"'. Returns the
  // decoded value and advances i past the closing quote. Assumes valid
  // JSON (the caller runs JSON.parse first, so no unterminated string
  // or bad escape can reach here).
  const readString = () => {
    i++; // opening quote
    let out = '';
    while (i < n) {
      const ch = text[i];
      if (ch === '"') {
        i++;
        return out;
      }
      if (ch === '\\') {
        const esc = text[i + 1];
        if (esc === 'u') {
          out += String.fromCharCode(parseInt(text.slice(i + 2, i + 6), 16));
          i += 6;
          continue;
        }
        const simple = {
          '"': '"', '\\': '\\', '/': '/',
          b: '\b', f: '\f', n: '\n', r: '\r', t: '\t',
        };
        out += Object.prototype.hasOwnProperty.call(simple, esc) ? simple[esc] : esc;
        i += 2;
        continue;
      }
      out += ch;
      i++;
    }
    return out; // unterminated — unreachable after a successful parse
  };
  while (i < n) {
    const c = text[i];
    if (c === '"') {
      const str = readString();
      let j = i;
      while (j < n && /\s/.test(text[j])) j++;
      if (text[j] === ':' && frames.length > 0) {
        const top = frames[frames.length - 1];
        if (top !== null) {
          if (top.has(str)) return str;
          top.add(str);
        }
      }
      continue;
    }
    if (c === '{') {
      frames.push(new Set());
      i++;
      continue;
    }
    if (c === '[') {
      frames.push(null);
      i++;
      continue;
    }
    if (c === '}' || c === ']') {
      frames.pop();
      i++;
      continue;
    }
    i++;
  }
  return null;
}
