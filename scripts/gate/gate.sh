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
#
# Usage: gate.sh --target <dir-or-file> [--launcher <path-to-impeccable>]
#        gate.sh --self-test   (runs against its own bundled fixture logic)
# Exit: 0 pass, 2 findings/fail, 1 usage error.
set -uo pipefail

target=""
launcher=""
self_test=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) target="$2"; shift 2 ;;
    --launcher) launcher="$2"; shift 2 ;;
    --self-test) self_test=1; shift ;;
    --help|-h) printf 'Usage: gate.sh --target <dir-or-file> [--launcher <impeccable>] | gate.sh --self-test\n'; exit 0 ;;
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

if [[ "$fails" -gt 0 ]]; then printf 'GATE RESULT: FAIL (%s issue(s)) — fix findings, no vision round spent.\n' "$fails"; exit 2; fi
printf 'GATE RESULT: PASS\n'
exit 0
