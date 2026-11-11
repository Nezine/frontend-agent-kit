#!/usr/bin/env bash
# Deterministic gate for frontend-agent-kit (SYNTHESIS.md §1 step 3),
# LEG 1 of 2 (reconciled 2026-11-10, probe 2): leg 1 is this file (taste
# lock + impeccable detect + static checks); leg 2 is gate.mjs (copy-lint
# + consistency browser leg). A "gate pass" means BOTH legs green on the
# same build. A PASS from this file on its own is only leg 1 — it never
# means the gate passed. When the legs disagree, the build is not green.
#
# Runs BEFORE any vision grade: a gate cannot lie to itself, and no vision
# round is ever spent on a build the gate already fails. FAIL blocks the round.
#
# What it checks, in order:
#   1. Taste lock (F6/H8): design/tokens.css MUST exist in the project dir —
#      the tokens are committed BEFORE any HTML (§1 step 1). A project with
#      no taste lock gets no pass, even if every other check is green.
#      Existence is not enough: the file must be NON-EMPTY and define at
#      least one custom property (--*) that the page's CSS/HTML actually
#      references (var(--*) or a literal use). An empty tokens file, or a
#      file whose tokens the page never uses, FAILS. The file's own
#      definitions do not count as use.
#      design/screenshots/ and design/variants/ are NOT required here: the
#      build loop creates them, so their absence is not a gate failure
#      (see scripts/gate/README.md, "Gate scope" — a template matter, not
#      a gate matter).
#   1b. Demo pass criterion, scripted (H15(1)): when the target IS
#      design/demo.html, the prose criterion "renders every listed token
#      visibly" becomes a check — every token in the demo header's
#      EXPECTED TOKENS block must be defined in design/tokens.css AND
#      referenced in the demo body (after the header comment, which names
#      the tokens and so cannot count as use). A demo exercising only
#      some of its listed tokens proves nothing about the rest.
#   2. impeccable detect (62 deterministic rules) — run per BUILT .html file
#      (F15), never on a directory: directory mode is regex-only and
#      approximate (see N7), and a whole-directory scan also sweeps in
#      design/variants/ — unpicked alternatives the human never chose. A
#      broken variant must never fail the build gate. Per-variant gating
#      stays explicit: gate the variants dir itself to scan the variants.
#      If no engine is reachable via --launcher (or the installed
#      ~/.agents/skills copy), the detect leg is SKIPPED — and a skipped
#      detect is "gate not run", never a pass (F6): the gate FAILS.
#   3. Static checks (no browser needed): every .html under the target has a
#      viewport meta; no file:// links; every local <img src>/stylesheet
#      reference resolves to a file. Non-file schemes are exempt (F-1,
#      probe 3): mailto:, tel:, javascript:, data:, #anchors, http(s): —
#      they are not file references, so a legitimate mailto: CTA must not
#      fail as "referenced file missing". Exactly those schemes are
#      exempt, no others (a protocol-relative // URL or an unknown scheme
#      still has to resolve — see the F-1 note in gate.mjs's header).
#      References are extracted in all three
#      quoting forms — double-quoted, single-quoted, and unquoted
#      (src='x.png', src=x.png) — not double-quoted only (H8). A missing
#      reference fails with its exact line (`<file>:<line>: referenced
#      file missing: <ref>`, M3) — the line is the line of the src/href
#      attribute in the page. design/variants/
#      is excluded from the build-output scan (same reason as step 2) — unless
#      the target IS a variants dir (an explicit per-variant gate).
#      design/demo.html is likewise excluded from project-dir scans (it is
#      the taste-lock proof artifact, gated explicitly on its own file) —
#      unless the target IS the demo file itself.
#      .taste-skill/ is excluded from every scan (probe G-7): gate.mjs's
#      consistency run used to write rendered.html + crops there, inside
#      the project, and this file then failed on the checker's own
#      artifact. gate.mjs now defaults its output to the OS temp dir; the
#      exclusion here is defence in depth.
#   3b. Visual-marker check (tightened 2026-11-10, probe 2): a built page
#      that contains <section> elements must contain at least one real
#      visual marker — <img>, <picture>, <video>, <canvas>, or a [data-ui]
#      UI mock. Small inline SVG icons do NOT count (the browser leg
#      measures them at 32px and they cover ~0% of a section). This is a
#      STATIC PROXY for gate.mjs's no-visual check (which measures >=25%
#      coverage per section in the browser); coverage itself is leg 2's
#      job, not this file's. It fires only on project-dir scans of pages
#      with sections — never on the single-file demo target (a token
#      proof, not a page) and never on a page with no sections (e.g. the
#      verify.sh fixture).
#   3c. Anti-cliché seed checks (P1, 2026-11-10): scripts/gate/
#      anti-cliche.mjs on the built pages — AC-1 (purple-pink-blue
#      gradient) and AC-2 (emoji as icon). SEEDED from garden-skills,
#      not grown from an observed failure (see anti-cliche.md); a
#      finding still fails the gate. Waived only by an explicit
#      "Anti-cliche allow: AC-<n>" hard rule in design/TASTE.md. Runs
#      when node is available; skipped with a warning otherwise (same
#      pattern as the optional validators below). Never on the demo or
#      v0 single-file targets (a token proof / a skeleton, not a page).
#   3d. Token-naming lint (P17, 2026-11-10): scripts/gate/
#      lint-tokens.mjs on the built pages + design/tokens.css — T1
#      kebab-case token names, T2 no primitive references in component
#      CSS, T3 on-* text role for every --color-* used as a background,
#      T4 colour roles alias primitives, never literals. A finding
#      fails the gate. Runs when node is available and design/tokens.css
#      exists; skipped with a note otherwise (the verify.sh fixture's
#      tokens are not --color-* roles, so it stays green). Runs on the
#      demo target too — the template must pass its own lint.
#   4. Optional validators when installed: html-validate, pa11y
#      (--standard WCAG2AA). Absent = skipped with a warning, never fatal.
#   5. Converge check (P2, 2026-11-10): scripts/gate/converge-check.mjs
#      against every built page — but ONLY when design/PLAN.md exists
#      under the project dir (step 1 writes the plan; a build without a
#      plan cannot be converge-checked, and the verify.sh fixture has
#      none — so absence skips with a note, never a failure). A missing
#      planned section/state FAILS the gate and blocks the human gate.
#      Runs when node is available; skipped with a warning otherwise —
#      in that case the orchestrator runs the converge checklist by hand
#      before the human gate (see skills/frontend-kit/references/
#      converge-checklist.md). Never on a variants-dir target (the
#      unpicked alternatives are not the deliverable) and never on the
#      demo single-file target.
#   6. Security stage (2026-11-11, cross-check §13): the deterministic
#      Stage 1 checks 1.1–1.12 from research/security-ai/SYNTHESIS.md §3
#      — 1.1 secret scan (gitleaks/trufflehog), 1.2–1.5 sink greps
#      (innerHTML/eval/template-injection/unvalidated URLs), 1.6
#      dependency existence + pinning + lockfile + integrity (npm view),
#      1.7 CVE (osv-scanner, else npm audit), 1.8 headers (CSP/HSTS,
#      no ACAO:*), 1.9 weak crypto, 1.10 licence scan
#      (license-checker, deny GPL/AGPL/SSPL/BUSL/Elastic/unknown),
#      1.11 rate limits / token budgets on LLM/API features, 1.12
#      lifecycle scripts disabled in CI + allowlist. Per-check output
#      `SECURITY 1.<n>: PASS | FAIL | N/A — <reason>`. FAIL-CLOSED: a
#      check whose subject is present but whose tool is missing FAILS,
#      naming the missing tool — never a silent pass. A check whose
#      SUBJECT is absent (no dependencies, no server, no LLM/API call,
#      no CI) is N/A with its reason printed. Runs after §5 in every
#      gate run, and standalone via --security-only. This is the
#      deterministic [GATE] half of the step-3a cross-check; the LLM/human
#      half (Stages 0, 2–6) runs as an independent agent
#      (experts/security.md, references/security-checklist.md) and is
#      recorded with run-log.mjs crosscheck — it is NOT this section.
#      RESOLVED 2026-11-11 (verification §1): OWASP LLM edition PINNED
#      to 2026 (released 3–4 Aug 2026, announced 1–2 Sep 2026); checks
#      cite LLM IDs with the :2026 suffix. Honest boundary: the full
#      122-page PDF could not be text-extracted (download 403); the
#      order rests on repo structure + Preface + LLM08 + unanimous
#      secondaries. ASVS 5.0.0 L1/L2 ADOPTED as the checklist layer
#      (verification §2); ASI IDs were NOT re-verified. 1.8's CSP
#      directives rest on the CSP Cheat Sheet via a DeepWiki summary
#      only (§8.6); 1.6's slopsquatting rationale rests on the USENIX
#      2025 abstract + introduction only (full paper CHƯA ĐỌC, §8.6).
#
# Usage: gate.sh --target <dir-or-file> [--launcher <path-to-impeccable>] [--security-only]
#        gate.sh --self-test   (runs against its own bundled fixture logic)
# Exit: 0 pass, 2 findings/fail, 1 usage error.
set -uo pipefail

target=""
launcher=""
self_test=0
security_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) target="$2"; shift 2 ;;
    --launcher) launcher="$2"; shift 2 ;;
    --self-test) self_test=1; shift ;;
    --security-only) security_only=1; shift ;;
    --help|-h) printf 'Usage: gate.sh --target <dir-or-file> [--launcher <impeccable>] [--security-only] | gate.sh --self-test\n'; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
done

if [[ "$self_test" == 1 ]]; then
  work="$(mktemp -d)"
  mkdir -p "$work/design"
  printf '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>t</title><link rel="stylesheet" href="tokens.css"><style>body{background:var(--bg)}</style></head><body><main><h1>t</h1></main></body></html>\n' > "$work/index.html"
  printf ':root { --bg: #fff; }\n' > "$work/tokens.css"
  # The self-test fixture is a real project by the gate's own rule: the
  # taste lock lives in design/tokens.css (F6 — no tokens, no pass).
  printf ':root { --bg: #fff; }\n' > "$work/design/tokens.css"
  target="$work"
fi
[[ -n "$target" ]] || { printf 'gate.sh: --target is required\n' >&2; exit 1; }
[[ -e "$target" ]] || { printf 'gate.sh: target does not exist: %s\n' "$target" >&2; exit 1; }

# Detect output goes to a fresh mktemp file under $HOME (never a fixed
# /tmp path: concurrent runs would clobber each other, and a scratch
# HOME's /tmp may be a tiny tmpfs). Single EXIT trap removes it and the
# self-test dir.
mkdir -p "$HOME/.cache" 2>/dev/null || true
detect_log="$(mktemp "$HOME/.cache/gate-detect.XXXXXX.log" 2>/dev/null || mktemp)"
demo_body="$(mktemp "$HOME/.cache/gate-demo-body.XXXXXX" 2>/dev/null || mktemp)"
trap 'rm -f "$detect_log" "$demo_body"; [[ "$self_test" == 1 ]] && rm -rf "$work"' EXIT

if [[ -z "$launcher" ]]; then
  for cand in "$HOME/.agents/skills/impeccable/scripts/impeccable" \
             "$HOME/.claude/skills/impeccable/scripts/impeccable"; do
    [[ -x "$cand" ]] && { launcher="$cand"; break; }
  done
fi

fails=0
fail() { fails=$((fails+1)); printf 'GATE FAIL: %s\n' "$1"; }
note() { printf 'GATE: %s\n' "$1"; }

# Project dir for the taste-lock check: the target itself when it is a
# directory, else the directory holding the target file. When the target
# lives under design/ itself (e.g. gating design/variants explicitly),
# the lock belongs to the project ABOVE design/, not to the subdir —
# otherwise a per-variant gate would spuriously fail the tokens check.
if [[ -d "$target" ]]; then project_dir="$target"; else project_dir="$(dirname -- "$target")"; fi
case "$project_dir" in
  */design/variants) project_dir="${project_dir%/design/variants}" ;;
  */design) project_dir="${project_dir%/design}" ;;
esac

# --- built .html files (computed once, used by detect AND static checks) ---
# design/variants/ holds the 5 unpicked CSS-only alternatives, not the
# deliverable: scanning them fails the gate on files the human never
# chose (a broken variant asset is not a build failure). Exclude them —
# unless the target IS a variants dir (an explicit per-variant gate).
# design/demo.html is the taste-lock proof artifact, not the deliverable:
# exclude it from project-dir scans for the same reason — unless the
# target IS the demo file itself (an explicit demo gate). design/v0.html
# (the v0 skeleton, P1) is excluded the same way: a skeleton with
# placeholders is not the deliverable, and it is gated explicitly on
# its own file. A single-file target gates exactly that file.
if [[ -f "$target" ]]; then
  case "$target" in
    *.html|*.HTML) html_files=("$target") ;;
    *) html_files=() ;;
  esac
elif [[ "$target" == */design/variants || "$target" == */design/variants/ ]]; then
  mapfile -t html_files < <(find "$target" -name '*.html' -type f 2>/dev/null || true)
else
  # .taste-skill/ excluded (G-7): the checker's own output dir must never
  # be scanned as build output. design/variants/ + design/demo.html +
  # design/v0.html excluded as before (unpicked alternatives / token-proof
  # artifact / skeleton — none of them is the deliverable).
  mapfile -t html_files < <(find "$target" -name '*.html' -type f -not -path '*/.taste-skill/*' -not -path '*/design/variants/*' -not -path '*/design/demo.html' -not -path '*/design/v0.html' 2>/dev/null || true)
fi

# --security-only runs ONLY the §6 security section below: legs 1–5 are
# skipped (the if wraps them) and the final verdict becomes SECURITY
# RESULT. In a normal run the section runs after §5, in order.
if [[ "$security_only" == 0 ]]; then

# --- 1. taste lock (F6/H8): no tokens, no pass ------------------------------
# This fires whether design/ exists or not: a project with NO design/ dir
# has no taste lock either, and the old check (only when design/ exists)
# passed exactly that case with GATE RESULT: PASS, exit 0.
if [[ ! -f "$project_dir/design/tokens.css" ]]; then
  fail "design/tokens.css is missing under $project_dir — no taste lock, no pass (tokens are committed BEFORE any HTML)"
elif [[ ! -s "$project_dir/design/tokens.css" ]]; then
  fail "design/tokens.css is empty under $project_dir — an empty token file is not a taste lock, no pass"
else
  # The file must define at least one custom property (--*) AND the page
  # must actually reference at least one of them in its CSS/HTML. A token
  # file the page never uses is not a lock — the build drifted off the
  # locked tokens. The tokens file's own definitions do not count as use:
  # search the built .html files and any local .css other than tokens.css.
  mapfile -t defined_tokens < <(grep -ohE -- '--[a-zA-Z][a-zA-Z0-9_-]*' "$project_dir/design/tokens.css" 2>/dev/null | sort -u || true)
  if [[ "${#defined_tokens[@]}" -eq 0 ]]; then
    fail "design/tokens.css under $project_dir defines no custom properties (--*) — not a taste lock, no pass"
  else
    mapfile -t css_files < <(find "$project_dir" -name '*.css' -type f -not -name 'tokens.css' -not -path '*/.taste-skill/*' -not -path '*/design/variants/*' 2>/dev/null || true)
    used=0
    for tok in "${defined_tokens[@]}"; do
      if [[ "${#html_files[@]}" -gt 0 ]] && grep -qF -- "$tok" "${html_files[@]}" 2>/dev/null; then used=1; break; fi
      if [[ "${#css_files[@]}" -gt 0 ]] && grep -qF -- "$tok" "${css_files[@]}" 2>/dev/null; then used=1; break; fi
    done
    [[ "$used" == 1 ]] || fail "design/tokens.css defines ${#defined_tokens[@]} custom propert(ies) but the page's CSS/HTML references none of them — tokens are not locked to the build, no pass"
  fi
fi

# --- 1b. demo pass criterion, scripted (H15(1)) ---------------------------
# When the target IS design/demo.html, the step-1.3 prose criterion
# ("renders every listed token visibly") is enforced, not asserted: the
# demo's own header declares its EXPECTED TOKENS (the lines between the
# EXPECTED TOKENS and PASS CRITERION markers), and every one must (a) be
# defined in the sibling design/tokens.css and (b) be referenced in the
# demo body — the text after the header comment, since the comment names
# the tokens and cannot count as use. Fail-closed: a demo with no
# EXPECTED TOKENS block, or no header comment at all, has no pass
# criterion to meet and FAILS.
if [[ -f "$target" && "$target" == */design/demo.html ]]; then
  mapfile -t expected_tokens < <(awk '/PASS CRITERION/{if(flag) exit} /EXPECTED TOKENS/{flag=1; next} flag' "$target" | grep -ohE -- '--[a-zA-Z][a-zA-Z0-9_-]*' | sort -u || true)
  if [[ "${#expected_tokens[@]}" -eq 0 ]]; then
    fail "$target: no EXPECTED TOKENS block in the demo header — the demo pass criterion is undeclared, no pass"
  else
    : > "$demo_body"
    awk 'seen{print} /-->/{seen=1}' "$target" > "$demo_body"
    for tok in "${expected_tokens[@]}"; do
      grep -qF -- "$tok" "$project_dir/design/tokens.css" 2>/dev/null || fail "$target: expected token $tok is not defined in design/tokens.css — the demo cannot prove a token the lock does not define"
      grep -qF -- "$tok" "$demo_body" 2>/dev/null || fail "$target: expected token $tok is not exercised in the demo body — the demo does not prove every listed token"
    done
    [[ "$fails" -eq 0 ]] && note "demo pass criterion: all ${#expected_tokens[@]} expected tokens defined in tokens.css and exercised in the demo body"
  fi
fi

# --- 2. impeccable detect, per built file (F15) ------------------------------
# A skipped detect is "gate not run", never a pass (F6): no launcher means
# FAIL, not a warning. A detect that exits with anything other than a
# completed scan (0 clean, 2 findings, 1 unscannable) is likewise not a
# pass — the leg did not run, so the gate cannot claim the build is clean.
if [[ -z "$launcher" ]]; then
  fail "impeccable detect skipped: no launcher found (engine not installed?) — gate not run, no pass. Install the kit (./install.sh warms the engine) or pass --launcher <path-to-impeccable>."
elif [[ "${#html_files[@]}" -eq 0 ]]; then
  note "impeccable detect skipped: no .html files under $target (the static check below fails this run)"
else
  if [[ -d "$target" ]]; then
    note "impeccable detect runs per built .html file (directory mode is regex-only and approximate — N7 — and would also scan unpicked design/variants/)"
  fi
  for f in "${html_files[@]}"; do
    if "$launcher" detect "$f" > "$detect_log" 2>&1; then
      note "impeccable detect: clean ($f)"
    else
      code=$?
      if [[ "$code" == 2 ]]; then fail "impeccable detect found slop/quality issues in $f (exit 2): $(head -20 "$detect_log" | tr '\n' ' ')";
      elif [[ "$code" == 1 ]]; then fail "impeccable detect could not scan $f (exit 1)";
      else fail "impeccable detect did not complete on $f (exit $code — engine probably not warmed) — gate not run, no pass"; fi
    fi
  done
fi

# --- 3. static checks ---------------------------------------------------------
[[ "${#html_files[@]}" -gt 0 ]] || fail "no .html files under $target"
for f in "${html_files[@]}"; do
  grep -qi '<meta[^>]*name=["'"'"']viewport["'"'"']' "$f" || fail "$f: missing viewport meta"
  if grep -qi 'file://' "$f"; then fail "$f: contains file:// link (serve over http, never file://)"; fi
  dir="$(dirname -- "$f")"
  while IFS=: read -r lineno ref; do
    [[ -z "$ref" ]] && continue
    # Non-file schemes are NOT file references and are exempt from the
    # existence check (F-1, probe 3): mailto:, tel:, javascript:, data:,
    # #anchors, and http(s): URLs. Only a bare relative path (or a
    # scheme not in that list, e.g. a typo'd scheme) must resolve to a
    # file. The exemption is case-insensitive (MAILTO: is a scheme too).
    ref="${ref%%\?*}"; ref="${ref%%\#*}"
    [[ -e "$dir/$ref" ]] || fail "$f:$lineno: referenced file missing: $ref"
  done < <(grep -ionE "(src|href)=('[^']*'|\"[^\"]*\"|[^'\"[:space:]>]+)" "$f" 2>/dev/null | sed -E -e 's/^([0-9]+):[a-zA-Z]+=/\1:/' -e "s/^([0-9]+):['\"]/\1:/" -e "s/['\"]$//" | grep -viE '^[0-9]+:(https?:|data:|mailto:|tel:|javascript:|#)' || true)
done

# --- 3b. visual-marker check (probe 2 tightening) ---------------------------
# A built page with <section> elements must show at least one real visual:
# <img>, <picture>, <video>, <canvas>, or a [data-ui] UI mock. Small inline
# SVG icons do not count (leg 2 measures them at 32px, ~0% section cover).
# Static proxy only: per-section >=25% coverage is measured by gate.mjs.
# Scope: project-dir scans only — never the single-file demo target (a
# token proof, not a page) and never a page with no sections (verify.sh
# fixture, self-test fixture). The demo file is already excluded from
# project-dir html_files above, so this fires on deliverable pages only.
if [[ -d "$target" ]]; then
  for f in "${html_files[@]}"; do
    if grep -qi '<section[[:space:]>]' "$f" 2>/dev/null; then
      if ! grep -qiE '(<img[[:space:]>]|<picture[[:space:]>]|<video[[:space:]>]|<canvas[[:space:]>]|data-ui)' "$f" 2>/dev/null; then
        fail "$f: page has <section> elements but no real visual marker (<img>, <picture>, <video>, <canvas>, or [data-ui] mock) — small inline SVG icons do not count; gate.mjs no-visual measures >=25% cover per section, and this page would fail it (see skills/frontend-kit/references/layout-doctrine.md)"
      fi
    fi
  done
fi

# --- 3c. anti-cliché seed checks (P1) -----------------------------------------
# AC-1 (purple-pink-blue gradient) + AC-2 (emoji as icon), via
# scripts/gate/anti-cliche.mjs. SEEDED from garden-skills, not observed
# failures — a finding still fails the gate. Waivers live in
# design/TASTE.md ("Anti-cliche allow: AC-<n>") and are read by the
# script itself. Skipped (with a warning, never fatal) when node is
# absent — same pattern as the optional validators — and never on the
# demo or v0 single-file targets (a token proof / a skeleton, not a
# page). The script prints its own findings in full.
if [[ -f "$target" && ("$target" == */design/demo.html || "$target" == */design/v0.html) ]]; then
  note "anti-cliché checks skipped: $target is a proof/skeleton target, not the deliverable"
elif [[ "${#html_files[@]}" -eq 0 ]]; then
  note "anti-cliché checks skipped: no .html files under $target"
elif ! command -v node >/dev/null 2>&1; then
  note "anti-cliché checks skipped: node not found on PATH — run scripts/gate/anti-cliche.mjs by hand (a skipped check is a degradation, not a pass)"
else
  gate_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$gate_dir/anti-cliche.mjs" ]]; then
    if node "$gate_dir/anti-cliche.mjs" "${html_files[@]}" --project "$project_dir" > "$detect_log" 2>&1; then
      note "anti-cliché checks: clean ($(cat "$detect_log" | tail -1))"
    else
      code=$?
      if [[ "$code" == 1 ]]; then fail "anti-cliché seed check found a cliché (see above — AC-1 gradient or AC-2 emoji-as-icon; waive only via an explicit TASTE.md hard rule): $(tail -1 "$detect_log" | tr '\n' ' ')";
      else fail "anti-cliché check could not run (exit $code) — see $detect_log"; fi
      cat "$detect_log"
    fi
  else
    note "anti-cliché checks skipped: scripts/gate/anti-cliche.mjs missing from the kit install"
  fi
fi

# --- 3d. token-naming lint (P17) --------------------------------------------
# scripts/gate/lint-tokens.mjs — T1 kebab-case names, T2 no primitive
# references in component CSS, T3 on-* pairing for backgrounds, T4
# colour roles alias primitives (see the script header for the full
# rule list). BLOCKING: a finding fails the gate. Runs when node is
# available and design/tokens.css exists under the project dir;
# absence skips with a note, never a failure (a build without tokens
# cannot be linted — and the §1 taste-lock check already fails such a
# build). Unlike 3c it also runs on the demo single-file target: the
# demo is the token proof, and the template must pass its own lint.
# Skipped with a warning when node is absent.
if [[ ! -f "$project_dir/design/tokens.css" ]]; then
  note "token-naming lint skipped: no design/tokens.css under $project_dir"
elif [[ "${#html_files[@]}" -eq 0 ]]; then
  note "token-naming lint skipped: no .html files under $target"
elif ! command -v node >/dev/null 2>&1; then
  note "token-naming lint skipped: node not found on PATH — run scripts/gate/lint-tokens.mjs by hand (a skipped check is a degradation, not a pass)"
else
  gate_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$gate_dir/lint-tokens.mjs" ]]; then
    if node "$gate_dir/lint-tokens.mjs" "${html_files[@]}" --project "$project_dir" > "$detect_log" 2>&1; then
      note "token-naming lint: clean ($(tail -1 "$detect_log"))"
    else
      code=$?
      if [[ "$code" == 1 ]]; then fail "token-naming lint found a naming violation (see above — kebab-case, primitive use, missing on-* role, or literal colour role; fix in design/tokens.css first): $(grep -m1 'LINT-TOKENS FAIL' "$detect_log" | tr '\n' ' ')";
      else fail "token-naming lint could not run (exit $code) — see $detect_log"; fi
      cat "$detect_log"
    fi
  else
    note "token-naming lint skipped: scripts/gate/lint-tokens.mjs missing from the kit install"
  fi
fi

# --- 4. optional validators ---------------------------------------------------
if command -v html-validate >/dev/null 2>&1; then
  for f in "${html_files[@]}"; do html-validate "$f" >/dev/null 2>&1 || fail "html-validate failed on $f"; done
else note "html-validate not installed — skipped (npx html-validate to add it)"; fi
if command -v pa11y >/dev/null 2>&1; then
  for f in "${html_files[@]}"; do pa11y --standard WCAG2AA "$f" >/dev/null 2>&1 || fail "pa11y WCAG2AA failed on $f"; done
else note "pa11y not installed — skipped (npx pa11y to add it)"; fi

# --- 5. converge check (P2) ----------------------------------------------------
# Every planned section/state exists in the build — via
# scripts/gate/converge-check.mjs. BLOCKING: a failure here fails the
# gate (no grade) and blocks the human gate (step 6.1). Runs only when
# design/PLAN.md exists under the project dir; absence skips with a
# note, never a failure (the verify.sh fixture has no plan). Never on
# a variants-dir target (unpicked alternatives are not the
# deliverable) and never on the demo single-file target. When node is
# absent the check is skipped with a warning and the orchestrator runs
# the converge checklist by hand before the human gate.
is_variants_target=0
case "$target" in */design/variants|*/design/variants/) is_variants_target=1 ;; esac
if [[ -f "$target" && "$target" == */design/demo.html ]]; then
  note "converge check skipped: $target is the demo (token proof), not the deliverable"
elif [[ "$is_variants_target" == 1 ]]; then
  note "converge check skipped: variants dir target (unpicked alternatives are not the deliverable)"
elif [[ ! -f "$project_dir/design/PLAN.md" ]]; then
  note "converge check skipped: no design/PLAN.md under $project_dir (step 1 writes the plan; a build without a plan cannot be converge-checked)"
elif [[ "${#html_files[@]}" -eq 0 ]]; then
  note "converge check skipped: no .html files under $target"
elif ! command -v node >/dev/null 2>&1; then
  note "converge check skipped: node not found on PATH — run the converge checklist by hand before the human gate (see skills/frontend-kit/references/converge-checklist.md)"
else
  gate_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$gate_dir/converge-check.mjs" ]]; then
    for f in "${html_files[@]}"; do
      if node "$gate_dir/converge-check.mjs" --plan "$project_dir/design/PLAN.md" --page "$f" --project "$project_dir" > "$detect_log" 2>&1; then
        note "converge check: green for $f ($(tail -1 "$detect_log"))"
      else
        code=$?
        if [[ "$code" == 1 ]]; then fail "converge check FAILED for $f — the build dropped a planned section/state; the human gate is not presented until this is green: $(grep -m1 'CONVERGE FAIL' "$detect_log" | tr '\n' ' ')";
        else fail "converge check could not run on $f (exit $code) — see $detect_log"; fi
        cat "$detect_log"
      fi
    done
  else
    note "converge check skipped: scripts/gate/converge-check.mjs missing from the kit install"
  fi
fi

fi # end of: legs 1–5 skipped when --security-only

# --- 6. security stage — deterministic Stage 1 checks (synthesis §3) ------
# (Contract in this file's header, item 6.) Per-check lines read
# `SECURITY 1.<n>: PASS | FAIL | N/A — <reason>`. FAIL-CLOSED: a check
# whose subject is present but whose tool is missing FAILS, naming the
# missing tool — never a silent pass. A check whose SUBJECT is absent
# (no dependencies, no server, no LLM/API call, no CI) is N/A with its
# reason printed. OWASP LLM edition RESOLVED 2026-11-11 (verification §1):
# edition PINNED to 2026; checks cite LLM IDs with the :2026 suffix.
# Still PENDING VERIFICATION (synthesis §8): 1.8's CSP directives
# rest on the CSP Cheat Sheet via a DeepWiki summary only (§8.6); 1.6's
# slopsquatting rationale rests on the USENIX 2025 abstract +
# introduction only (full paper CHƯA ĐỌC, §8.6).
sec_pass=0; sec_fail_n=0; sec_na=0
secpass() { sec_pass=$((sec_pass+1)); printf 'SECURITY %s: PASS — %s\n' "$1" "$2"; }
secfail() { sec_fail_n=$((sec_fail_n+1)); fail "security $1: $2"; }
secna() { sec_na=$((sec_na+1)); printf 'SECURITY %s: N/A — %s\n' "$1" "$2"; }

# Files the sink/secret greps scan: the built .html files (the same set as
# the rest of the gate) + local .js/.mjs/.css under the project (excluding
# node_modules, .git, .taste-skill, design/variants) + package.json when
# present. The built bundle is a scan subject for 1.1 ("or bundle").
mapfile -t sec_scan_files < <({
  if [[ "${#html_files[@]}" -gt 0 ]]; then printf '%s\n' "${html_files[@]}"; fi
  find "$project_dir" \( -name '*.js' -o -name '*.mjs' -o -name '*.css' \) -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.taste-skill/*' -not -path '*/design/variants/*' 2>/dev/null
  if [[ -f "$project_dir/package.json" ]]; then printf '%s\n' "$project_dir/package.json"; fi
} | sort -u || true)

# Grep an ERE over the scanned code files (not .css), printing
# <file>:<line>:<match> lines. Never fails the script. Extra grep flags
# (e.g. -i) go before the pattern.
sec_grep() {
  local files=()
  local f
  for f in "${sec_scan_files[@]}"; do case "$f" in *.css) ;; *) files+=("$f");; esac; done
  [[ "${#files[@]}" -eq 0 ]] && return 0
  grep -HnE "$@" -- "${files[@]}" 2>/dev/null || true
}

# --- 1.1 secret scan ---------------------------------------------------------
# Tool: gitleaks (preferred) or trufflehog, per synthesis §7 (three-layer
# defence: pre-commit → push protection → CI). The built-in high-confidence
# pattern grep ALWAYS runs first and its matches are printed — but a clean
# grep is NOT a scanner verdict: with no scanner installed the check
# FAILS, naming the missing tool (fail closed; a pattern scan is not a
# secret scanner). A grep hit FAILS outright, scanner or not.
sec_11_hits="$(sec_grep '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-(live|test)-[A-Za-z0-9]{16,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)')"
sec_11_assign="$(sec_grep -i $'(api[_-]?key|apikey|secret|passwd|password|access[_-]?token)[[:space:]]*[:=][[:space:]]*[\'"][^\'"]{16,}[\'"]')"
if [[ -n "$sec_11_hits" || -n "$sec_11_assign" ]]; then
  secfail "1.1" "secret scan: high-confidence secret pattern found (built-in grep)"
  { [[ -n "$sec_11_hits" ]] && printf '%s\n' "$sec_11_hits"; [[ -n "$sec_11_assign" ]] && printf '%s\n' "$sec_11_assign"; } | sort -u | head -20
elif command -v gitleaks >/dev/null 2>&1; then
  if gitleaks detect --no-git --source "$project_dir" > "$detect_log" 2>&1; then
    secpass "1.1" "secret scan clean (gitleaks; built-in pattern grep also clean)"
  else
    secfail "1.1" "secret scan: gitleaks found leaks: $(tail -5 "$detect_log" | tr '\n' ' ')"
    cat "$detect_log"
  fi
elif command -v trufflehog >/dev/null 2>&1; then
  if trufflehog filesystem --no-update --json "$project_dir" > "$detect_log" 2>&1; then
    if [[ -s "$detect_log" ]]; then
      secfail "1.1" "secret scan: trufflehog found leaks: $(head -3 "$detect_log" | tr '\n' ' ')"
    else
      secpass "1.1" "secret scan clean (trufflehog; built-in pattern grep also clean)"
    fi
  else
    secfail "1.1" "secret scan: trufflehog could not run — see $detect_log"
  fi
else
  secfail "1.1" "secret scan: no secret scanner installed (gitleaks or trufflehog) — install one; the built-in pattern grep found nothing, but a pattern grep is not a scanner verdict (fail closed)"
fi

# --- 1.2 HTML sinks (innerHTML / document.write) ---------------------------
# Flag any dangerouslySetInnerHTML / innerHTML= / outerHTML= /
# document.write( in a file that does not also use DOMPurify.sanitize
# (the sanctioned sanitizer per OWASP LLM10:2026). A file WITH DOMPurify is
# passed with a note — the per-occurrence taint check (is THIS sink fed
# by untrusted data?) is checklist territory (Stage 1.2 human/LLM half);
# the gate enforces the mechanical half: no unsanitized sink at all.
sec_12_files="$(sec_grep 'dangerouslySetInnerHTML|innerHTML[[:space:]]*=|outerHTML[[:space:]]*=|document\.write[[:space:]]*\(' | cut -d: -f1 | sort -u || true)"
sec_12_bad=0
while IFS= read -r sec_f; do
  [[ -z "$sec_f" ]] && continue
  if grep -q 'DOMPurify\.sanitize' "$sec_f" 2>/dev/null; then
    note "SECURITY 1.2: $sec_f uses an HTML sink but also DOMPurify.sanitize — passed with note (per-occurrence taint check is checklist territory)"
  else
    sec_12_bad=1
    printf 'SECURITY 1.2: unsanitized sink in %s:\n' "$sec_f"
    grep -nE 'dangerouslySetInnerHTML|innerHTML[[:space:]]*=|outerHTML[[:space:]]*=|document\.write[[:space:]]*\(' "$sec_f" 2>/dev/null | head -10
  fi
done <<< "$sec_12_files"
if [[ "$sec_12_bad" == 1 ]]; then
  secfail "1.2" "HTML sink (innerHTML/outerHTML/document.write/dangerouslySetInnerHTML) without DOMPurify sanitization — see lines above"
else
  secpass "1.2" "no unsanitized HTML sink (any file using a sink also uses DOMPurify.sanitize)"
fi

# --- 1.3 code-execution sinks (eval / Function / string timers) ------------
sec_13_hits="$(sec_grep $'(^|[^A-Za-z0-9_])eval[[:space:]]*\\(|new[[:space:]]+Function[[:space:]]*\\(|setTimeout[[:space:]]*\\([[:space:]]*[\'"]|setInterval[[:space:]]*\\([[:space:]]*[\'"]')"
if [[ -n "$sec_13_hits" ]]; then
  secfail "1.3" "code-execution sink (eval / new Function / setTimeout|setInterval with a string argument)"
  printf '%s\n' "$sec_13_hits" | head -20
else
  secpass "1.3" "no eval / Function / string-timer sink"
fi

# --- 1.4 model/untrusted data into code execution ----------------------------
# Template-literal interpolation (${...}) into a SQL/shell/query call.
# Narrow by construction: only a template literal fed straight into the
# call is flagged; parameterised calls and plain strings do not match.
sec_14_hits="$(sec_grep $'(\\.query|exec|spawn|execSync|spawnSync)[[:space:]]*\\([[:space:]]*`[^`]*\\$\\{')"
if [[ -n "$sec_14_hits" ]]; then
  secfail "1.4" "template-interpolated data fed to a code/SQL/shell call — parameterise it"
  printf '%s\n' "$sec_14_hits" | head -20
else
  secpass "1.4" "no template-interpolated data in SQL/shell/query calls"
fi

# --- 1.5 unvalidated URLs (javascript: scheme) ------------------------------
sec_15_hits="$(sec_grep $'(href|src|action)[[:space:]]*=[[:space:]]*[\'"]javascript:')"
if [[ -n "$sec_15_hits" ]]; then
  secfail "1.5" "javascript: URL in href/src/action — allow-list http/https only"
  printf '%s\n' "$sec_15_hits" | head -20
else
  secpass "1.5" "no javascript: URL in href/src/action"
fi

# --- 1.6 dependency existence / pinning / lockfile / integrity -------------
# PENDING VERIFICATION (synthesis §8.6): the slopsquatting rationale
# rests on the USENIX 2025 paper's abstract + introduction only (full
# paper CHƯA ĐỌC). The check itself (live registry lookup at the exact
# version + exact pin + lockfile entry + integrity hash) is mechanical
# and runs as written. Vetting order before install (existence →
# version → age/maintainer → install-script → provenance → licence):
# the gate covers existence/version/pinning/lockfile/integrity;
# age/maintainer/provenance are checklist territory.
if [[ ! -f "$project_dir/package.json" ]]; then
  secna "1.6" "no package.json under $project_dir — no dependencies to vet (existence/pinning/lockfile/integrity vacuous)"
elif ! command -v node >/dev/null 2>&1; then
  secfail "1.6" "dependency check needs node to parse package.json — node not found on PATH"
elif ! command -v npm >/dev/null 2>&1; then
  secfail "1.6" "dependency check needs npm for registry lookups — npm not found on PATH"
else
  if ! sec_deps="$(node -e 'const p=require(process.argv[1]); const d=Object.assign({},p.dependencies,p.devDependencies); for (const [n,v] of Object.entries(d)) console.log(n+"\t"+v);' "$project_dir/package.json" 2>"$detect_log")"; then
    secfail "1.6" "dependency check: package.json unparseable by node: $(head -3 "$detect_log" | tr '\n' ' ')"
  else
    sec_dep_names=(); sec_dep_vers=()
    while IFS=$'\t' read -r sec_n sec_v; do
      [[ -z "$sec_n" ]] && continue
      sec_dep_names+=("$sec_n"); sec_dep_vers+=("$sec_v")
    done <<< "$sec_deps"
    if [[ "${#sec_dep_names[@]}" -eq 0 ]]; then
      secpass "1.6" "no dependencies declared in package.json — nothing to vet"
    else
      sec_16_bad=0
      # Lockfile entry + integrity hash, all deps at once (node parse).
      if [[ ! -f "$project_dir/package-lock.json" ]]; then
        if ls "$project_dir"/yarn.lock "$project_dir"/pnpm-lock.yaml 2>/dev/null | grep -q .; then
          sec_16_bad=1; printf 'SECURITY 1.6: non-npm lockfile present — lockfile-entry/integrity check is implemented for package-lock.json only; use package-lock.json or record the manager in the checklist\n'
        else
          sec_16_bad=1; printf 'SECURITY 1.6: no lockfile under %s — every dependency needs a lockfile entry\n' "$project_dir"
        fi
      elif ! sec_lock_missing="$(node -e 'const l=require(process.argv[1]); const pkgs=l.packages||{}; const bad=[]; for (const n of process.argv.slice(2)) { const e=pkgs["node_modules/"+n]; if (!e) bad.push(n+" (no lockfile entry)"); else if (!e.integrity) bad.push(n+" (no integrity hash)"); } if (bad.length) { console.log(bad.join("\n")); process.exit(1); }' "$project_dir/package-lock.json" "${sec_dep_names[@]}" 2>"$detect_log")"; then
        sec_16_bad=1; printf 'SECURITY 1.6: lockfile problem:\n%s\n' "$sec_lock_missing"
      fi
      for sec_i in "${!sec_dep_names[@]}"; do
        sec_n="${sec_dep_names[$sec_i]}"; sec_v="${sec_dep_vers[$sec_i]}"
        case "$sec_v" in
          file:*|link:*|workspace:*) note "SECURITY 1.6: $sec_n@$sec_v is local — registry/pinning checks do not apply"; continue ;;
        esac
        if ! [[ "$sec_v" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
          sec_16_bad=1; printf 'SECURITY 1.6: %s@%s is not pinned to an exact version (version ranges are forbidden in production manifests)\n' "$sec_n" "$sec_v"; continue
        fi
        if ! sec_reg="$(npm view "$sec_n@$sec_v" version 2>"$detect_log")"; then
          sec_16_bad=1; printf 'SECURITY 1.6: %s@%s does not exist on the registry (npm view failed — slopsquat/typo risk): %s\n' "$sec_n" "$sec_v" "$(head -2 "$detect_log" | tr '\n' ' ')"
        elif [[ "$sec_reg" != "$sec_v" ]]; then
          sec_16_bad=1; printf 'SECURITY 1.6: registry reports %s@%s, not the requested %s\n' "$sec_n" "$sec_reg" "$sec_v"
        fi
      done
      if [[ "$sec_16_bad" == 1 ]]; then
        secfail "1.6" "dependency existence/pinning/lockfile/integrity failed — see lines above"
      else
        secpass "1.6" "all ${#sec_dep_names[@]} dependenc(ies) exist on the registry at the exact pinned version, with lockfile entries + integrity hashes"
      fi
    fi
  fi
fi

# --- 1.7 known CVE in a reachable dependency ---------------------------------
# Tool: osv-scanner (preferred) or npm audit (both named in synthesis §7).
# Reachability-weighting needs Semgrep Supply Chain and is checklist
# territory; the gate fails on any high/critical CVE either tool reports.
if [[ ! -f "$project_dir/package.json" ]]; then
  secna "1.7" "no package.json — no dependencies to scan for CVEs"
elif [[ ! -f "$project_dir/package-lock.json" ]]; then
  secfail "1.7" "CVE scan needs package-lock.json — none under $project_dir (1.6 already requires it)"
elif command -v osv-scanner >/dev/null 2>&1; then
  if osv-scanner --lockfile="$project_dir/package-lock.json" > "$detect_log" 2>&1; then
    secpass "1.7" "no known high/critical CVE in dependencies (osv-scanner)"
  else
    secfail "1.7" "osv-scanner reported vulnerabilities or could not run: $(tail -5 "$detect_log" | tr '\n' ' ')"
    cat "$detect_log"
  fi
elif command -v npm >/dev/null 2>&1; then
  if (cd "$project_dir" && npm audit --omit=dev --audit-level=high > "$detect_log" 2>&1); then
    secpass "1.7" "no high/critical CVE in production dependencies (npm audit)"
  else
    secfail "1.7" "npm audit found high/critical vulnerabilities or could not run: $(tail -5 "$detect_log" | tr '\n' ' ')"
  fi
else
  secfail "1.7" "CVE scan needs osv-scanner or npm — neither found on PATH"
fi

# --- 1.8 headers (CSP / HSTS / no ACAO:*) ------------------------------------
# PENDING VERIFICATION (synthesis §8.6): the CSP Cheat Sheet was read via
# a DeepWiki summary only — the exact CSP directives below are not yet
# verified against the primary. What the gate enforces is the mechanical
# half: a CSP exists (meta tag or headers/server config) wherever a
# server/deployment config exists, and no Access-Control-Allow-Origin: *
# anywhere. HSTS/cookie flags are checklist territory (they need a live
# server response, not files).
sec_has_server=0; sec_csp=0
sec_server_files=()
for sec_cand in "$project_dir/_headers" "$project_dir/vercel.json" "$project_dir/netlify.toml" "$project_dir/.htaccess" "$project_dir/server.js" "$project_dir/server.mjs" "$project_dir/Dockerfile"; do
  [[ -f "$sec_cand" ]] && sec_server_files+=("$sec_cand")
done
if [[ -f "$project_dir/package.json" ]] && grep -qE '"(express|fastify|koa|hapi|next|nuxt|@nestjs/core)"' "$project_dir/package.json" 2>/dev/null; then sec_has_server=1; fi
[[ "${#sec_server_files[@]}" -gt 0 ]] && sec_has_server=1
if [[ "${#html_files[@]}" -gt 0 ]] && grep -qiE $'http-equiv=[\'"]?Content-Security-Policy' "${html_files[@]}" 2>/dev/null; then sec_csp=1; fi
for sec_f in "${sec_server_files[@]}"; do grep -qi 'Content-Security-Policy' "$sec_f" 2>/dev/null && sec_csp=1; done
sec_acao=""
if [[ "${#sec_server_files[@]}" -gt 0 ]]; then sec_acao="$(grep -rInE 'Access-Control-Allow-Origin:[[:space:]]*\*' "${sec_server_files[@]}" 2>/dev/null || true)"; fi
if [[ "${#html_files[@]}" -gt 0 ]]; then sec_acao+="$(grep -HnE 'Access-Control-Allow-Origin:[[:space:]]*\*' "${html_files[@]}" 2>/dev/null || true)"; fi
if [[ -n "$sec_acao" ]]; then
  secfail "1.8" "Access-Control-Allow-Origin: * found (credentialed-endpoint risk): $(printf '%s' "$sec_acao" | head -3 | tr '\n' ' ')"
elif [[ "$sec_csp" == 1 ]]; then
  secpass "1.8" "CSP present (meta tag or headers/server config); no Access-Control-Allow-Origin: * found"
elif [[ "$sec_has_server" == 1 ]]; then
  secfail "1.8" "headers: project has a server/deployment config but no Content-Security-Policy found — add a CSP (meta tag or headers config) and HSTS"
else
  secna "1.8" "no server or deployment config in scope — CSP/HSTS are the hosting layer's responsibility for a purely static build (recorded, not verified)"
fi

# --- 1.9 weak crypto ----------------------------------------------------------
# Grading divergence disclosed in synthesis §3: W-APPSEC rates weak crypto
# BLOCK, W-OWASP rates it WARN — this runbook follows W-APPSEC, so the
# gate FAILS on it. Math.random() is flagged only on lines that also
# name a security use (token/secret/password/key/nonce/salt/OTP/session/
# auth) — Math.random() for visuals/ids is not a finding.
sec_19_hits="$(sec_grep $'createHash[[:space:]]*\\([[:space:]]*[\'"]?(md5|sha1)[\'"]?|(^|[^A-Za-z0-9_])MD5[[:space:]]*\\(|(^|[^A-Za-z0-9_])SHA1[[:space:]]*\\(|createCipher[[:space:]]*\\(')"
sec_19_mr="$(sec_grep 'Math\.random[[:space:]]*\(\)' | grep -iE 'token|secret|password|passwd|key|nonce|salt|otp|session|auth|crypt' || true)"
if [[ -n "$sec_19_hits" || -n "$sec_19_mr" ]]; then
  secfail "1.9" "weak crypto (MD5/SHA1 for security, deprecated createCipher, or Math.random() for a secret/token)"
  { [[ -n "$sec_19_hits" ]] && printf '%s\n' "$sec_19_hits"; [[ -n "$sec_19_mr" ]] && printf '%s\n' "$sec_19_mr"; } | sort -u | head -20
else
  secpass "1.9" "no weak crypto (no MD5/SHA1-for-security, no createCipher, no Math.random() for secrets/tokens)"
fi

# --- 1.10 licence scan --------------------------------------------------------
# Deny-by-default allowlist, per synthesis §3 check 1.10: deny GPL in
# distributed trees, AGPL everywhere, SSPL/BUSL/Elastic, unknown/no
# licence. SPDX normalisation + the full allowlist are checklist
# territory; the gate enforces the deny-list mechanically via
# license-checker's --failOn.
if [[ ! -f "$project_dir/package.json" ]]; then
  secna "1.10" "no package.json — no production tree to licence-scan"
elif ! command -v license-checker >/dev/null 2>&1; then
  secfail "1.10" "licence scan needs license-checker (or ScanCode/ORT) — none found on PATH"
else
  if (cd "$project_dir" && license-checker --production --failOn 'GPL-2.0;GPL-3.0;GPL-2.0-only;GPL-3.0-only;GPL-2.0-or-later;GPL-3.0-or-later;AGPL-1.0;AGPL-3.0;AGPL-1.0-only;AGPL-3.0-only;SSPL-1.0;BUSL-1.1;Elastic-2.0;UNLICENSED;UNKNOWN' > "$detect_log" 2>&1); then
    secpass "1.10" "licence scan clean (license-checker --production; deny GPL/AGPL/SSPL/BUSL/Elastic/unknown)"
  else
    secfail "1.10" "licence scan: denied/unknown licence in the production tree (or license-checker could not run): $(tail -5 "$detect_log" | tr '\n' ' ')"
  fi
fi

# --- 1.11 rate limits / token budgets / step caps ----------------------------
# Applies only when the page/app calls an LLM or a metered API. The
# synthesis grades 1.11 WARN (BLOCK if the feature handles money or
# sensitive data); the gate fails closed on an unbounded LLM/API feature
# and says so — a human re-grades the severity at the cross-check.
sec_api_hits="$(sec_grep -i $'fetch[[:space:]]*\\(|XMLHttpRequest|axios\\.|(openai|anthropic)|@google/generative-ai|/api/|apiKey|api_key')"
# NOTE: no \b word boundaries here on purpose — $'...' quoting would
# turn \b into a backspace; substring matches are fine for this detection.
if [[ -z "$sec_api_hits" ]]; then
  secna "1.11" "no LLM/API call detected in the built files — no consumption to bound"
else
  sec_limit_hits="$(sec_grep -i 'rateLimit|rate-limit|throttl|tokenBudget|token_budget|maxTokens|max_tokens|maxSteps|stepCap|requestBudget' || true)"
  if [[ -z "$sec_limit_hits" ]]; then
    secfail "1.11" "LLM/API feature present (fetch/API call detected) with no rate-limit / token-budget / step-cap evidence — add a limit"
  else
    secpass "1.11" "LLM/API feature present with limit evidence: $(printf '%s' "$sec_limit_hits" | head -1 | tr '\n' ' ')"
  fi
fi

# --- 1.12 lifecycle scripts disabled in CI + allowlist -----------------------
# Two halves: (a) any dependency whose install runs a lifecycle script
# (lockfile hasInstallScript) must be on an explicit allowlist with a
# reason — allowlist file: design/security-allowlist.md or
# security-allowlist.md at the project root; (b) CI configs that run
# `npm ci`/`npm install` must pass --ignore-scripts.
if [[ ! -f "$project_dir/package.json" ]]; then
  secna "1.12" "no package.json — no dependency installs to police"
elif [[ ! -f "$project_dir/package-lock.json" ]]; then
  secfail "1.12" "lifecycle-script check needs package-lock.json — none under $project_dir"
else
  sec_12_install="$(node -e 'const l=require(process.argv[1]); const out=[]; for (const [p,e] of Object.entries(l.packages||{})) { if (e.hasInstallScript) out.push(p.replace(/^node_modules\//,"")); } console.log(out.join("\n"));' "$project_dir/package-lock.json" 2>"$detect_log" || echo "__LOCKFILE_ERROR__")"
  sec_12_bad=0
  if [[ "$sec_12_install" == "__LOCKFILE_ERROR__" ]]; then
    sec_12_bad=1; printf 'SECURITY 1.12: package-lock.json unparseable by node: %s\n' "$(head -3 "$detect_log" | tr '\n' ' ')"
  else
    sec_allowlist=""
    for sec_cand in "$project_dir/design/security-allowlist.md" "$project_dir/security-allowlist.md"; do
      [[ -f "$sec_cand" ]] && sec_allowlist="$sec_cand"
    done
    while IFS= read -r sec_d; do
      [[ -z "$sec_d" ]] && continue
      if [[ -z "$sec_allowlist" ]] || ! grep -qF -- "$sec_d" "$sec_allowlist" 2>/dev/null; then
        sec_12_bad=1; printf 'SECURITY 1.12: dependency %s runs a lifecycle script and is on no allowlist (design/security-allowlist.md or security-allowlist.md)\n' "$sec_d"
      fi
    done <<< "$sec_12_install"
  fi
  sec_ci_bad="$(grep -rInE 'npm[[:space:]]+(ci|install)\b' "$project_dir/.github/workflows" "$project_dir/.gitlab-ci.yml" 2>/dev/null | grep -v -- '--ignore-scripts' || true)"
  if [[ -n "$sec_ci_bad" ]]; then
    sec_12_bad=1; printf 'SECURITY 1.12: CI runs npm ci/install without --ignore-scripts:\n%s\n' "$(printf '%s' "$sec_ci_bad" | head -10)"
  fi
  if [[ "$sec_12_bad" == 1 ]]; then
    secfail "1.12" "lifecycle scripts not disabled/allowlisted — see lines above"
  else
    secpass "1.12" "no un-allowlisted lifecycle-script dependency; CI installs (if any) use --ignore-scripts"
  fi
fi

printf 'SECURITY: %s PASS, %s FAIL, %s N/A (Stage 1 checks 1.1–1.12; see SECURITY 1.<n> lines above)\n' "$sec_pass" "$sec_fail_n" "$sec_na"

if [[ "$security_only" == 1 ]]; then
  if [[ "$fails" -gt 0 ]]; then printf 'SECURITY RESULT: FAIL (%s issue(s)) — fix findings, no land/ship.\n' "$fails"; exit 2; fi
  printf 'SECURITY RESULT: PASS\n'
  exit 0
fi

if [[ "$fails" -gt 0 ]]; then printf 'GATE RESULT: FAIL (%s issue(s)) — fix findings, no vision round spent.\n' "$fails"; exit 2; fi
printf 'GATE RESULT: PASS\n'
exit 0
