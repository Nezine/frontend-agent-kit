#!/usr/bin/env node
// crop-sections.mjs — P13 crop helper (cheap-grade ladder).
//
// Determines the changed sections of a fix round MECHANICALLY from the git
// diff of design/tokens.css + the HTML between rounds, captures the full
// 390 shot + one crop per changed section (downscaled to 1,568px long
// edge), and writes the input manifest (JSON) for the judge spawn.
//
// NAME CHOICE (council decision, 2026-11-10): this file is council-A's
// `crop-sections.mjs`. Council-B's `crop-helper.mjs` is the NOT-USED
// alias — do not create it, do not reference it.
//
// IMAGE BACKEND (verified 2026-11-11 against @playwright/cli 0.1.24, the
// kit's pinned Playwright CLI): the CLI's `screenshot` command takes an
// element ref or the whole page and offers NO clip rectangle and NO
// downscale flag, so it cannot produce a scaled crop in one
// non-interactive run. This helper therefore drives the SAME Chromium the
// kit installs (the Playwright browser cache) over CDP, using Node's
// built-in WebSocket client — Node stdlib only, NO new runtime
// dependency — and uses Page.captureScreenshot `clip.scale` for the
// 1,568px downscale. The full-page 1440/768 shots themselves still come
// from the normal step-4 `playwright-cli screenshot` flow; this helper
// owns only the cheap-grade set (390 full + crops).
//
// DETERMINER (council-B/C, P13): the git diff is the determiner. The
// builder's fix list is cross-checked against the diff and NEVER used as
// the determiner. P5's script classifier does not exist in this repo
// (verified on disk — no classifier script in skills/frontend-kit/scripts/
// or scripts/gate/) and is not assumed here.
//
// NESTED-CHANGE DEDUPE (W-LOOP fix, 2026-11-11): only the OUTERMOST
// changed section gets a crop. A changed section inside another changed
// section (e.g. changed <article>s inside a changed <section>) gets NO
// separate crop — the parent crop already contains it, so the nested
// crops are redundant tokens. Deduped-away sections are recorded in the
// manifest under "nested-under" (with the parent section's label), not
// dropped silently. Section nesting is DOM nesting (matching close tag),
// not line order: findSections records each section's closing line.
//
// FAIL-LOUD RULE (council-A/B, P13): if the image backend is absent, if
// git is absent, if the project is not a git repo in git mode, or if the
// diff shows no change at all, this script exits 2 with the exact missing
// piece on stderr plus the fallback label for the run log — full shots
// for that round, labelled `cheap-grade: full-shots (<reason>)`. It NEVER
// silently sends full shots as if they were crops: a manifest is only
// written when the crops it lists were actually captured (or, in
// --dry-run, when it explicitly marks them "not captured (dry run)").
//
// Usage:
//   node crop-sections.mjs --project <dir> --round N --url <http://...>
//     [--html <rel-or-abs path, default: index.html>]
//     [--tokens <rel-or-abs path, default: design/tokens.css>]
//     [--git-base <ref>]                      # git mode (default): diff <ref> vs working tree
//     [--prev-html <path> --prev-tokens <path>]  # file mode instead of --git-base:
//                                                # diff the previous round's saved files
//     [--out-dir <dir, default: <project>/design/screenshots/round-<N>-cheap>]
//     [--manifest <path, default: <out-dir>/manifest.json>]
//     [--snapshot <path> --console <path> --geometry <path>]  # tool-check outputs to list
//     [--fix-list <path>]                     # builder's fix list (tasks.md/delta.md) — cross-check only
//     [--chrome <path>]                       # Chromium binary override (else CHROME_PATH / Playwright cache / PATH)
//     [--dry-run]                             # diff + manifest only, no browser launch, no captures
//
// Exit codes: 0 = manifest written (captures done, or dry run);
// 2 = fail-loud (usage error, no diff, missing backend/git/files);
// 1 = unexpected error.
// No lessons section in this file: repo docs do not carry one (user rule, 2026-11-10).

'use strict';

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';
import { spawn, spawnSync } from 'node:child_process';

const LONG_EDGE = 1568;
const VIEWPORT_WIDTH = 390;
const SECTION_TAGS = ['section', 'header', 'footer', 'nav', 'main', 'article', 'aside'];
const SECTION_SELECTOR = SECTION_TAGS.join(', ') + ', [data-section]';
const CROP_PAD_PX = 8;

function usage() {
  return [
    'crop-sections.mjs — P13 crop helper (cheap-grade ladder)',
    'Usage: node crop-sections.mjs --project <dir> --round N --url <http://...> [options]',
    '  --html <path>        built HTML (default: <project>/index.html)',
    '  --tokens <path>      tokens.css (default: <project>/design/tokens.css)',
    '  --git-base <ref>     git mode: diff <ref> vs working tree (default mode)',
    '  --prev-html <path> --prev-tokens <path>   file mode (instead of --git-base)',
    '  --out-dir <dir>      crop output dir (default: <project>/design/screenshots/round-<N>-cheap)',
    '  --manifest <path>    manifest JSON path (default: <out-dir>/manifest.json)',
    '  --snapshot/--console/--geometry <path>    tool-check outputs to list in the manifest',
    '  --fix-list <path>    builder fix list — cross-checked against the diff, never the determiner',
    '  --chrome <path>      Chromium binary override',
    '  --dry-run            diff + manifest only; no browser launch, no captures',
  ].join('\n');
}

function failLoud(message, fallbackReason) {
  console.error(`crop-sections: FAIL — ${message}`);
  console.error(
    'crop-sections: FALLBACK — use full shots for this round (full 1440 + full 390); ' +
    `record in the run log: cheap-grade: full-shots (${fallbackReason})`,
  );
  process.exit(2);
}

function parseArgs(argv) {
  const args = { _: [] };
  const valueFlags = new Set([
    'project', 'round', 'url', 'html', 'tokens', 'git-base',
    'prev-html', 'prev-tokens', 'out-dir', 'manifest',
    'snapshot', 'console', 'geometry', 'fix-list', 'chrome',
  ]);
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') { args['dry-run'] = true; continue; }
    if (a === '--help' || a === '-h') { console.log(usage()); process.exit(0); }
    const m = a.match(/^--([^=]+)(?:=(.*))?$/);
    if (!m) { args._.push(a); continue; }
    const key = m[1];
    if (!valueFlags.has(key)) {
      console.error(`crop-sections: unknown flag ${a}\n${usage()}`);
      process.exit(2);
    }
    if (m[2] !== undefined) args[key] = m[2];
    else if (i + 1 < argv.length) args[key] = argv[++i];
    else {
      console.error(`crop-sections: flag ${a} needs a value\n${usage()}`);
      process.exit(2);
    }
  }
  return args;
}

function relToProject(project, p) {
  const abs = path.isAbsolute(p) ? p : path.join(project, p);
  const rel = path.relative(project, abs);
  if (rel.startsWith('..')) {
    failLoud(
      `path ${p} is outside the project ${project} — the diff is scoped to the project`,
      'path outside project',
    );
  }
  return { abs, rel: rel.split(path.sep).join('/') };
}

function runGit(project, gitArgs) {
  const r = spawnSync('git', gitArgs, { cwd: project, encoding: 'utf8' });
  if (r.error) {
    if (r.error.code === 'ENOENT') {
      failLoud(
        'git binary not found on PATH — the diff determiner needs git',
        'git missing',
      );
    }
    failLoud(`git failed: ${r.error.message}`, 'git failed');
  }
  return r;
}

// ---------------------------------------------------------------------------
// Diff parsing (unified diff -> changed new-file line ranges per file)
// ---------------------------------------------------------------------------

function parseUnifiedDiff(diffText) {
  // Returns [{ path, changedLines: [new-file line numbers] }].
  // Only '+' lines (and, for a pure-deletion hunk, its anchor line) count
  // as changed — context lines (' ') inside a hunk are NOT changes, even
  // though they sit inside the hunk's @@ range.
  const files = [];
  let current = null;
  let newLine = null;
  let hunkHasAddition = false;
  let hunkAnchor = null;
  const flushHunk = () => {
    if (current && newLine !== null && !hunkHasAddition && hunkAnchor !== null) {
      current.changedLines.push(hunkAnchor);
    }
    newLine = null;
    hunkHasAddition = false;
    hunkAnchor = null;
  };
  for (const line of diffText.split('\n')) {
    if (line.startsWith('diff --git ')) {
      flushHunk();
      current = { path: null, changedLines: [] };
      files.push(current);
      continue;
    }
    if (!current) continue;
    const plus = line.match(/^\+\+\+ (?:b\/)?(.*)$/);
    if (plus && plus[1] !== '/dev/null') { current.path = plus[1].trim(); continue; }
    if (line.startsWith('--- ')) continue;
    const hunk = line.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@/);
    if (hunk) {
      flushHunk();
      newLine = parseInt(hunk[1], 10);
      hunkAnchor = newLine;
      continue;
    }
    if (newLine === null) continue;
    if (line.startsWith('+')) {
      current.changedLines.push(newLine);
      hunkHasAddition = true;
      newLine++;
    } else if (line.startsWith(' ')) {
      newLine++;
    } else if (line.startsWith('\\')) {
      // "\ No newline at end of file" — no line advance.
    }
    // '-' lines do not advance the new-file line number.
  }
  flushHunk();
  return files.filter((f) => f.path);
}

function hunkLines(hunks) {
  // Kept for callers that pass hunk objects; parseUnifiedDiff now returns
  // changedLines directly (see above).
  const lines = [];
  for (const h of hunks) {
    for (let n = h.newStart; n < h.newStart + h.newCount; n++) lines.push(n);
  }
  return lines;
}

function changedTokenNames(diffText, tokensRel) {
  // Added/changed custom-property names in the tokens.css diff only.
  const names = new Set();
  let inTokens = false;
  for (const line of diffText.split('\n')) {
    if (line.startsWith('diff --git ')) { inTokens = line.includes(tokensRel); continue; }
    if (!inTokens) continue;
    if (line.startsWith('+') && !line.startsWith('+++')) {
      const m = line.match(/--([\w-]+)\s*:/);
      if (m) names.add(`--${m[1]}`);
    }
  }
  return [...names].sort();
}

// ---------------------------------------------------------------------------
// Section mapping (mechanical: changed line -> enclosing section-like element)
// ---------------------------------------------------------------------------

function findSections(htmlText) {
  const lines = htmlText.split('\n');
  const sections = [];
  const tagRe = new RegExp(`<(${SECTION_TAGS.join('|')})\\b([^>]*)>`, 'g');
  const dataSectionRe = /<([a-zA-Z][\w-]*)\b[^>]*\bdata-section\b[^>]*>/g;
  const idRe = /\bid=["']([^"']+)["']/;
  const headingRe = /<h[12][^>]*>([^<]{1,80})<\/h[12]>/;
  lines.forEach((line, idx) => {
    const seen = new Set();
    for (const re of [tagRe, dataSectionRe]) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(line)) !== null) {
        if (seen.has(m.index)) continue;
        seen.add(m.index);
        const tag = m[1].toLowerCase();
        const attrs = m[2] || '';
        const id = (attrs.match(idRe) || [])[1] || null;
        let heading = null;
        for (let j = idx; j < Math.min(idx + 6, lines.length); j++) {
          const hm = lines[j].match(headingRe);
          if (hm) { heading = hm[1].trim(); break; }
        }
        const ordinal = sections.filter((s) => s.tag === tag).length + 1;
        sections.push({
          index: sections.length,
          tag,
          id,
          label: id ? `#${id}` : `${tag} #${ordinal}`,
          heading,
          startLine: idx + 1,
        });
      }
    }
  });
  for (let i = 0; i < sections.length; i++) {
    // endLine is the section's MATCHING CLOSE TAG (DOM nesting), not the
    // next section's opening tag: a section contains its nested articles,
    // so its span runs to </section>, past the articles' opening tags.
    // Fallback to the old next-start-1 / end-of-file rule when no close
    // tag is found (unclosed element).
    const s = sections[i];
    const openRe = new RegExp(`<${s.tag}\\b[^>]*>`, 'g');
    const closeRe = new RegExp(`</${s.tag}\\s*>`, 'g');
    let depth = 0;
    let closedAt = null;
    for (let j = s.startLine - 1; j < lines.length; j++) {
      depth += (lines[j].match(openRe) || []).length - (lines[j].match(closeRe) || []).length;
      if (depth <= 0) { closedAt = j + 1; break; }
    }
    sections[i].endLine = closedAt ?? (i + 1 < sections.length
      ? sections[i + 1].startLine - 1
      : lines.length);
  }
  return { lines, sections };
}

function mapLinesToSections(changedLines, sections) {
  const mapped = new Map(); // section index -> lines[]
  const unsectioned = [];
  for (const line of changedLines) {
    // Innermost section whose [startLine, endLine] span CONTAINS the line
    // (greatest startLine among the containing sections). A line in the
    // gap between two nested articles belongs to the parent section, not
    // to the article that merely precedes it.
    const containing = sections.filter((s) => s.startLine <= line && line <= s.endLine);
    let best = null;
    for (const s of containing) {
      if (!best || s.startLine > best.startLine) best = s;
    }
    if (best) {
      if (!mapped.has(best.index)) mapped.set(best.index, []);
      mapped.get(best.index).push(line);
    } else {
      unsectioned.push(line);
    }
  }
  return { mapped, unsectioned };
}

function slugify(label) {
  return label.replace(/^#/, '').replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-+|-+$/g, '').toLowerCase().slice(0, 40) || 'section';
}

// ---------------------------------------------------------------------------
// Chromium discovery + CDP driver (Node stdlib only: child_process, net,
// global fetch, global WebSocket — no new dependency)
// ---------------------------------------------------------------------------

function findChrome(override) {
  const tried = [];
  const check = (p) => {
    if (!p) return null;
    tried.push(p);
    try {
      if (fs.existsSync(p) && fs.statSync(p).isFile()) return p;
    } catch { /* not usable */ }
    return null;
  };
  if (override) {
    const found = check(override);
    if (!found) {
      failLoud(
        `Chromium binary not found at --chrome ${override} (searched exactly that path)`,
        'chromium missing (--chrome path does not exist)',
      );
    }
    return found;
  }
  const foundEnv = check(process.env.CHROME_PATH);
  if (foundEnv) return foundEnv;
  // Playwright browser cache (the kit installs Chromium here).
  try {
    const cache = path.join(os.homedir(), '.cache', 'ms-playwright');
    for (const dir of fs.readdirSync(cache)) {
      for (const sub of ['chrome-linux', 'chrome-linux64']) {
        const found = check(path.join(cache, dir, sub, 'chrome'));
        if (found) return found;
      }
    }
  } catch { /* cache dir absent — falls through to PATH lookup */ }
  for (const name of ['chromium', 'chromium-browser', 'google-chrome', 'google-chrome-stable']) {
    const r = spawnSync('sh', ['-c', `command -v ${name}`], { encoding: 'utf8' });
    if (r.status === 0 && r.stdout.trim()) {
      const found = check(r.stdout.trim());
      if (found) return found;
    }
  }
  failLoud(
    'no Chromium binary found — searched CHROME_PATH, ~/.cache/ms-playwright/*/chrome-linux{,64}/chrome, ' +
    'and chromium / chromium-browser / google-chrome / google-chrome-stable on PATH. ' +
    'Install the kit browser with ./install.sh (Playwright CLI + browser) or set CHROME_PATH.',
    'chromium missing (no browser backend)',
  );
  return null; // unreachable — failLoud exits
}

function freePort() {
  return new Promise((resolve, reject) => {
    const s = net.createServer();
    s.once('error', reject);
    s.listen(0, '127.0.0.1', () => {
      const port = s.address().port;
      s.close(() => resolve(port));
    });
  });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function withTimeout(promise, ms, what) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(`timed out after ${ms}ms: ${what}`)), ms);
  });
  try {
    return await Promise.race([promise, timeout]);
  } finally {
    clearTimeout(timer);
  }
}

class CDP {
  constructor(wsUrl) {
    this.ws = new WebSocket(wsUrl);
    this.nextId = 1;
    this.pending = new Map();
    this.eventWaiters = [];
    this.ws.addEventListener('message', (ev) => {
      let msg;
      try { msg = JSON.parse(ev.data); } catch { return; }
      if (msg.id !== undefined && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(new Error(`CDP ${msg.error.code}: ${msg.error.message}`));
        else resolve(msg.result || {});
      } else if (msg.method) {
        for (const w of this.eventWaiters) {
          if (w.predicate(msg)) { this.eventWaiters.splice(this.eventWaiters.indexOf(w), 1); w.resolve(msg); }
        }
      }
    });
  }

  async connect(timeoutMs = 15000) {
    if (this.ws.readyState === WebSocket.OPEN) return;
    await withTimeout(new Promise((resolve, reject) => {
      this.ws.addEventListener('open', resolve, { once: true });
      this.ws.addEventListener('error', reject, { once: true });
    }), timeoutMs, 'CDP WebSocket connect');
  }

  send(method, params = {}, sessionId = undefined, timeoutMs = 30000) {
    const id = this.nextId++;
    const payload = { id, method, params };
    if (sessionId) payload.sessionId = sessionId;
    return withTimeout(new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify(payload));
    }), timeoutMs, `CDP ${method}`);
  }

  waitForEvent(predicate, timeoutMs = 30000) {
    return withTimeout(new Promise((resolve) => {
      this.eventWaiters.push({ predicate, resolve });
    }), timeoutMs, 'CDP event');
  }

  close() { try { this.ws.close(); } catch { /* already closed */ } }
}

async function launchChrome(chromePath) {
  const port = await freePort();
  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'crop-sections-'));
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--disable-dev-shm-usage',
    `--remote-debugging-port=${port}`,
    `--user-data-dir=${userDataDir}`,
    '--hide-scrollbars',
    'about:blank',
  ], { stdio: 'ignore' });
  const cleanup = () => {
    try { chrome.kill('SIGTERM'); } catch { /* already dead */ }
    setTimeout(() => { try { chrome.kill('SIGKILL'); } catch { /* already dead */ } }, 3000);
    try { fs.rmSync(userDataDir, { recursive: true, force: true }); } catch { /* best effort */ }
  };
  const deadline = Date.now() + 20000;
  let version = null;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`http://127.0.0.1:${port}/json/version`);
      if (res.ok) { version = await res.json(); break; }
    } catch { /* not up yet */ }
    await sleep(250);
  }
  if (!version) {
    cleanup();
    failLoud(
      `Chromium at ${chromePath} did not expose DevTools on port ${port} within 20s`,
      'chromium DevTools unreachable',
    );
  }
  return { port, version, cleanup };
}

async function captureCheapSet({ chromePath, url, changedSections, outDir }) {
  const { version, cleanup } = await launchChrome(chromePath);
  const cdp = new CDP(version.webSocketDebuggerUrl);
  try {
    await cdp.connect();
    const { targetId } = await cdp.send('Target.createTarget', { url: 'about:blank' });
    const { sessionId } = await cdp.send('Target.attachToTarget', { targetId, flatten: true });
    await cdp.send('Page.enable', {}, sessionId);
    await cdp.send('Emulation.setDeviceMetricsOverride', {
      width: VIEWPORT_WIDTH, height: 844, deviceScaleFactor: 1, mobile: true,
    }, sessionId);
    const loadPromise = cdp.waitForEvent(
      (m) => m.method === 'Page.loadEventFired' && m.sessionId === sessionId, 30000,
    );
    await cdp.send('Page.navigate', { url }, sessionId);
    await loadPromise;
    await sleep(800); // fonts / layout settle
    const measure = await cdp.send('Runtime.evaluate', {
      expression: `(() => {
        window.scrollTo(0, 0);
        const els = [...document.querySelectorAll('${SECTION_SELECTOR}')];
        return {
          scrollWidth: document.documentElement.scrollWidth,
          scrollHeight: document.documentElement.scrollHeight,
          sections: els.map((el, i) => {
            const r = el.getBoundingClientRect();
            return { index: i, x: r.x + window.scrollX, y: r.y + window.scrollY,
                     width: r.width, height: r.height };
          }),
        };
      })()`,
      returnByValue: true,
    }, sessionId);
    if (measure.exceptionDetails) {
      throw new Error(`measurement failed: ${measure.exceptionDetails.text || 'Runtime.evaluate exception'}`);
    }
    const m = measure.result.value;
    const fullScale = Math.min(1, LONG_EDGE / Math.max(VIEWPORT_WIDTH, m.scrollHeight));
    const full = await cdp.send('Page.captureScreenshot', {
      format: 'png',
      captureBeyondViewport: true,
      clip: { x: 0, y: 0, width: VIEWPORT_WIDTH, height: m.scrollHeight, scale: fullScale },
    }, sessionId);
    const fullFile = '390-full.png';
    fs.writeFileSync(path.join(outDir, fullFile), Buffer.from(full.data, 'base64'));
    const full390 = {
      file: fullFile, width: VIEWPORT_WIDTH, height: m.scrollHeight,
      scale: fullScale, status: 'captured',
    };

    const crops = [];
    for (const [n, section] of changedSections.entries()) {
      const rect = m.sections[section.index];
      if (!rect) {
        crops.push({ ...section, file: null, status: 'section not found in rendered page — check the section mapping' });
        continue;
      }
      const x = Math.max(0, Math.floor(rect.x) - CROP_PAD_PX);
      const y = Math.max(0, Math.floor(rect.y) - CROP_PAD_PX);
      const width = Math.min(Math.ceil(rect.width) + 2 * CROP_PAD_PX, VIEWPORT_WIDTH - x);
      const height = Math.ceil(rect.height) + 2 * CROP_PAD_PX;
      if (width <= 0 || height <= 0) {
        crops.push({ ...section, file: null, status: 'section has zero size in the rendered page' });
        continue;
      }
      const scale = Math.min(1, LONG_EDGE / Math.max(width, height));
      const shot = await cdp.send('Page.captureScreenshot', {
        format: 'png',
        captureBeyondViewport: true,
        clip: { x, y, width, height, scale },
      }, sessionId);
      const file = `crop-${String(n + 1).padStart(2, '0')}-${slugify(section.label)}.png`;
      fs.writeFileSync(path.join(outDir, file), Buffer.from(shot.data, 'base64'));
      crops.push({
        ...section,
        clip: { x, y, width, height, scale },
        file,
        status: 'captured',
      });
    }
    await cdp.send('Target.closeTarget', { targetId });
    return { full390, crops, pageHeight: m.scrollHeight, pageWidth: m.scrollWidth };
  } finally {
    cdp.close();
    cleanup();
  }
}

// ---------------------------------------------------------------------------
// Main: diff -> sections -> captures -> manifest
// ---------------------------------------------------------------------------

function toolCheckEntry(p) {
  if (!p) return { path: null, status: 'not provided' };
  return fs.existsSync(p)
    ? { path: p, status: 'provided' }
    : { path: p, status: 'missing — file does not exist' };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const project = args.project ? path.resolve(args.project) : null;
  const round = args.round ? parseInt(args.round, 10) : NaN;
  if (!project || !fs.existsSync(project) || !fs.statSync(project).isDirectory()) {
    console.error(`crop-sections: --project must name an existing directory\n${usage()}`);
    process.exit(2);
  }
  if (!Number.isInteger(round) || round < 1) {
    console.error(`crop-sections: --round must be a positive integer\n${usage()}`);
    process.exit(2);
  }
  const dryRun = !!args['dry-run'];
  const url = args.url || null;
  if (!dryRun && !url) {
    console.error(`crop-sections: --url is required unless --dry-run\n${usage()}`);
    process.exit(2);
  }

  const html = relToProject(project, args.html || 'index.html');
  const tokens = relToProject(project, args.tokens || 'design/tokens.css');
  for (const f of [html, tokens]) {
    if (!fs.existsSync(f.abs)) {
      failLoud(`file not found: ${f.abs} — the diff needs both the HTML and design/tokens.css`,
        `missing input file ${f.rel}`);
    }
  }

  // --- Determine the diff (the mechanical determiner) ---------------------
  let diffText;
  let determiner;
  if (args['prev-html'] || args['prev-tokens']) {
    if (!args['prev-html'] || !args['prev-tokens']) {
      console.error('crop-sections: file mode needs BOTH --prev-html and --prev-tokens\n' + usage());
      process.exit(2);
    }
    const prevHtml = path.resolve(args['prev-html']);
    const prevTokens = path.resolve(args['prev-tokens']);
    for (const f of [prevHtml, prevTokens]) {
      if (!fs.existsSync(f)) {
        failLoud(`previous-round file not found: ${f}`, 'missing previous-round file');
      }
    }
    const parts = [];
    for (const [prev, cur] of [[prevHtml, html.abs], [prevTokens, tokens.abs]]) {
      const r = spawnSync('git', ['diff', '--no-index', '--', prev, cur], { encoding: 'utf8' });
      if (r.error) {
        if (r.error.code === 'ENOENT') {
          failLoud('git binary not found on PATH — the diff determiner needs git', 'git missing');
        }
        failLoud(`git diff failed: ${r.error.message}`, 'git failed');
      }
      // git diff --no-index exits 1 when files differ, 0 when identical.
      if (r.status !== 0 && r.status !== 1) {
        failLoud(`git diff --no-index failed (exit ${r.status}): ${(r.stderr || '').trim()}`, 'git diff failed');
      }
      parts.push(r.stdout || '');
    }
    diffText = parts.join('');
    determiner = `git diff --no-index (previous round's saved files vs current ${html.rel} + ${tokens.rel})`;
  } else {
    if (!args['git-base']) {
      console.error('crop-sections: need --git-base <ref> (git mode) or --prev-html + --prev-tokens (file mode)\n' + usage());
      process.exit(2);
    }
    const repo = runGit(project, ['rev-parse', '--git-dir']);
    if (repo.status !== 0) {
      failLoud(
        `project ${project} is not a git repo (git rev-parse failed) — git mode needs a repo; ` +
        'use file mode with --prev-html + --prev-tokens instead',
        'not a git repo (git mode)',
      );
    }
    const baseCheck = runGit(project, ['rev-parse', '--verify', '--quiet', args['git-base']]);
    if (baseCheck.status !== 0) {
      failLoud(
        `git base ref ${args['git-base']} does not exist in ${project} — pass the ref of the previous round`,
        `unknown git base ${args['git-base']}`,
      );
    }
    const r = runGit(project, ['diff', args['git-base'], '--', html.rel, tokens.rel]);
    if (r.status !== 0) {
      failLoud(`git diff failed (exit ${r.status}): ${(r.stderr || '').trim()}`, 'git diff failed');
    }
    diffText = r.stdout || '';
    determiner = `git diff ${args['git-base']} -- ${html.rel} ${tokens.rel}`;
  }

  const parsed = parseUnifiedDiff(diffText);
  const htmlEntry = parsed.find((f) => f.path === html.rel || f.path.endsWith(`/${html.rel}`));
  const tokensEntry = parsed.find((f) => f.path === tokens.rel || f.path.endsWith(`/${tokens.rel}`));
  const otherFiles = parsed
    .filter((f) => f !== htmlEntry && f !== tokensEntry)
    .map((f) => f.path);
  const htmlLines = htmlEntry ? [...htmlEntry.changedLines].sort((a, b) => a - b) : [];
  const changedTokens = changedTokenNames(diffText, tokens.rel);

  if (htmlLines.length === 0 && changedTokens.length === 0 && !tokensEntry) {
    failLoud(
      'no changes detected between rounds (empty diff for the HTML and design/tokens.css) — ' +
      'there is nothing to re-grade; this round gets no grade (see P5/P6)',
      'no changes between rounds',
    );
  }

  // --- Map changed HTML lines to sections ----------------------------------
  const htmlText = fs.readFileSync(html.abs, 'utf8');
  const { sections } = findSections(htmlText);
  const { mapped, unsectioned } = mapLinesToSections(htmlLines, sections);
  const allChangedSections = [...mapped.entries()]
    .map(([index, lines]) => ({ ...sections[index], lines }))
    .sort((a, b) => a.index - b.index);
  // Nested-change dedupe (W-LOOP fix, 2026-11-11): only the OUTERMOST
  // changed section gets a crop. A changed section inside another changed
  // section gets no separate crop — the parent crop already contains it.
  // Deduped-away sections are recorded in the manifest as "nested-under"
  // (with the parent section's label), not dropped silently.
  const nestedUnder = [];
  const changedSections = [];
  for (const s of allChangedSections) {
    const parent = allChangedSections.find((p) => p !== s && p.startLine < s.startLine && s.endLine <= p.endLine);
    if (parent) nestedUnder.push({ ...s, nestedUnder: parent.label });
    else changedSections.push(s);
  }
  const tokensOnly = htmlLines.length === 0 && changedTokens.length > 0;

  // --- Cross-check against the builder's fix list (never the determiner) ---
  let fixListCheck;
  if (args['fix-list']) {
    const fixPath = path.resolve(args['fix-list']);
    if (!fs.existsSync(fixPath)) {
      fixListCheck = { path: fixPath, status: 'missing — file does not exist, cross-check skipped' };
    } else {
      const fixText = fs.readFileSync(fixPath, 'utf8').toLowerCase();
      const inDiffNotInFix = allChangedSections
        .filter((s) => {
          const needle = (s.id || s.label).toLowerCase();
          return !fixText.includes(needle) && !(s.heading && fixText.includes(s.heading.toLowerCase()));
        })
        .map((s) => s.label);
      const inFixNotInDiff = [];
      for (const s of sections) {
        if (allChangedSections.some((c) => c.index === s.index)) continue;
        const needle = (s.id || s.label).toLowerCase();
        if (needle.length > 2 && fixText.includes(needle)) inFixNotInDiff.push(s.label);
      }
      fixListCheck = {
        path: fixPath,
        status: 'checked',
        'sections-in-diff-not-in-fix-list': inDiffNotInFix,
        'sections-in-fix-list-not-in-diff': inFixNotInDiff,
        note: 'The fix list is a cross-check only. Sections in the fix list but not in the diff ' +
          '(builder claims a change the diff does not show) get NO crop — the diff is the determiner.',
      };
    }
  } else {
    fixListCheck = { status: 'not provided — cross-check skipped (builder self-report is never the determiner)' };
  }

  // --- Output dir + manifest path ------------------------------------------
  const outDir = args['out-dir']
    ? path.resolve(args['out-dir'])
    : path.join(project, 'design', 'screenshots', `round-${round}-cheap`);
  fs.mkdirSync(outDir, { recursive: true });
  const manifestPath = args.manifest
    ? path.resolve(args.manifest)
    : path.join(outDir, 'manifest.json');

  // --- Captures (or dry run) ------------------------------------------------
  let full390;
  let crops;
  let imageBackend;
  if (dryRun) {
    imageBackend = { kind: 'not launched (dry run)', chrome: null };
    full390 = {
      file: null, width: VIEWPORT_WIDTH, height: null, scale: null,
      status: 'not captured (dry run)',
    };
    crops = changedSections.map((s) => ({
      ...s, clip: null, file: null, status: 'not captured (dry run)',
    }));
  } else {
    const chromePath = findChrome(args.chrome);
    imageBackend = { kind: 'chromium-cdp', chrome: chromePath };
    const captured = await captureCheapSet({
      chromePath, url, changedSections, outDir,
    });
    full390 = captured.full390;
    crops = captured.crops;
  }

  const manifest = {
    tool: 'crop-sections.mjs (P13)',
    mode: dryRun ? 'dry-run' : 'full',
    round,
    project,
    url,
    generatedAt: new Date().toISOString(),
    determiner,
    base: args['git-base'] || null,
    changedTokens,
    tokensOnly,
    changedSections: crops,
    'nested-under': nestedUnder,
    unsectionedChanges: {
      htmlLines: unsectioned,
      note: unsectioned.length
        ? 'Changed HTML lines outside any section-like element (head/preamble) — no crop; the full 390 shot covers them.'
        : 'none',
    },
    otherFilesChanged: otherFiles,
    full390,
    toolChecks: {
      snapshot: toolCheckEntry(args.snapshot),
      console: toolCheckEntry(args.console),
      geometry: toolCheckEntry(args.geometry),
    },
    fixListCheck,
    imageBackend,
    fallback: null,
    judgeSpawnInputs: [
      full390.file ? path.join(outDir, full390.file) : '390 full shot — not captured (dry run)',
      ...crops.filter((c) => c.file).map((c) => path.join(outDir, c.file)),
      'tool-check outputs above (snapshot / console / geometry — mandatory, ordered before pixels)',
      'the 1–3 locked reference shots (every round, from the lock — not this helper\'s job)',
    ],
  };
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');

  const missingTools = ['snapshot', 'console', 'geometry']
    .filter((k) => manifest.toolChecks[k].status !== 'provided');
  if (missingTools.length) {
    console.error(
      `crop-sections: warning — tool-check outputs not provided: ${missingTools.join(', ')}. ` +
      'They are mandatory judge inputs (P13, tool checks first); the manifest records them as ' +
      'not provided so the judge spawn does not silently proceed without them.',
    );
  }
  console.log(`crop-sections: round ${round} — ${changedSections.length} changed section(s)` +
    `${nestedUnder.length ? ` + ${nestedUnder.length} nested-under (no separate crop: ${nestedUnder.map((s) => s.label).join(', ')})` : ''}` +
    `${tokensOnly ? ' (tokens-only diff: no crops, full 390 only)' : ''}` +
    `, ${changedTokens.length} changed token(s)`);
  console.log(`crop-sections: manifest ${manifestPath}`);
  if (!dryRun) console.log(`crop-sections: full 390 ${full390.file} (scale ${full390.scale}), ${crops.filter((c) => c.file).length} crop(s) in ${outDir}`);
}

main().catch((err) => {
  console.error(`crop-sections: ERROR — ${err && err.message ? err.message : String(err)}`);
  process.exit(1);
});
