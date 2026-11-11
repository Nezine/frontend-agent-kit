#!/usr/bin/env node
// seed-structural.mjs — node replacement for the python3 seeds structural
// check (RR-07, fix round 2, 2026-11-11). Same pattern as dompurify-call.mjs:
// node is the gate's existing scripting runtime, so there is no second
// interpreter dependency and no fallback to be inequivalent.
//
// Usage: node seed-structural.mjs <file>
// Exit 0: the file is exactly the legitimate shape.
// Exit 1: structural FAIL — the message is printed on stdout. This covers
//   every shape that used to get "no structural verdict": unparseable JSON,
//   a UTF-8 BOM prefix (RR-05 — read with BOM stripping, i.e. the utf-8-sig
//   equivalent, so a BOM no longer switches the check off; a BOM-prefixed
//   file with an extra field still FAILS on shape), trailing garbage after
//   the JSON value (JSON.parse requires exactly one value), a bare string
//   instead of an object, and any deviation from the pinned shape.
// Exit 2: usage/read error.
//
// Pinned shapes (the engine writes exactly one shape per file):
//   seeds/*.json: exactly {"key": "<32-lower-hex>"} and nothing else.
//   seed-salt:    exactly one 32-lower-hex line (one trailing newline
//                 allowed; CRLF is normalised, as before — a double
//                 trailing newline FAILS, fail-closed).
// If upstream ever changes the seed format, this check fails loudly and
// the kit must update the pinned shape — the same class of pinned
// assumption as the gitleaks allowlist paths themselves.
import { readFileSync } from 'node:fs';
import { basename } from 'node:path';
import { findDuplicateKey } from './json-dup-keys.mjs';

export function checkSeedFile(text, isSalt) {
  // Strip one leading UTF-8 BOM (the utf-8-sig equivalent). A BOM alone
  // never fails the check — it only must not disable it (RR-05).
  if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
  if (isSalt) {
    const norm = text.replace(/\r\n/g, '\n');
    if (!/^[0-9a-f]{32}\n?$/.test(norm)) {
      return 'seed-salt is not exactly one 32-lower-hex line';
    }
    return null;
  }
  let obj;
  try {
    obj = JSON.parse(text);
  } catch (e) {
    return `seeds file does not parse as JSON (${e.message}) — fail closed, never a silent pass`;
  }
  // RR2-03 (fix round 3): duplicate keys in the raw text. JSON.parse
  // keeps the LAST duplicate and discards the earlier ones, so
  // {"key": "<64-hex>", "key": "<32-legit>"} would otherwise parse to
  // the pinned shape while the raw bytes still hold the secret. The
  // check is the shared raw-text scanner (keys decoded, so an escaped
  // "\u006bey" counts as "key" — a literal count of `"key"` occurrences
  // would miss that variant, since it has exactly one literal `"key"`).
  const dup = findDuplicateKey(text);
  if (dup !== null) {
    return `seeds file has a duplicate JSON key "${dup}" — fail closed`;
  }
  if (
    obj === null ||
    typeof obj !== 'object' ||
    Array.isArray(obj) ||
    Object.keys(obj).length !== 1 ||
    !Object.prototype.hasOwnProperty.call(obj, 'key') ||
    typeof obj.key !== 'string' ||
    !/^[0-9a-f]{32}$/.test(obj.key)
  ) {
    return 'seeds file is not exactly {"key": "<32-lower-hex>"}';
  }
  return null;
}

const invokedDirectly =
  process.argv[1] != null && process.argv[1].endsWith('seed-structural.mjs');
if (invokedDirectly) {
  const file = process.argv[2];
  if (!file) {
    console.error('usage: seed-structural.mjs <file>');
    process.exit(2);
  }
  let text;
  try {
    text = readFileSync(file, 'utf8');
  } catch (e) {
    console.error(`seed-structural.mjs: cannot read ${file}: ${e.message}`);
    process.exit(2);
  }
  const problem = checkSeedFile(text, basename(file) === 'seed-salt');
  if (problem) {
    console.log(`${file}: ${problem}`);
    process.exit(1);
  }
  process.exit(0);
}
