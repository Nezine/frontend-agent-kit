#!/usr/bin/env bash
# frontend-agent-kit — verifier v2.
#
# Verifies the LOOP, not just files (phase-1 research/SYNTHESIS.md §3.1, §6 A10/A7/A3 — workspace research note, not shipped in this repo):
#   1. every expected skill present in every installed host's skills dir,
#      with frontmatter name == directory name (catches double-nesting);
#   2. no stale ${CLAUDE_PLUGIN_ROOT} paths in installed skills (A3);
#   2b. installed Impeccable SKILL.md has no unresolved {{placeholders}}
#       and no top-level `version:` (spec-pure frontmatter — the generator
#       guarantees both; verify re-checks the installed copy);
#   2c. taste pipeline paths resolve from the installed wrapper;
#   2d. no live builder-self-grade language in installed skills
#       (prohibiting/overridden mentions allowlisted — see §2d);
#   3. Impeccable skill<->engine LOCKSTEP (A10): the installed engine's
#      reported version must equal the vendored scripts/VERSION exactly.
#      A mismatch FAILS LOUDLY — the 62-rule registry lives in the engine,
#      so a wrong engine silently applies the wrong registry;
#   4. `impeccable detect` runs on a clean fixture;
#   5. the deterministic gate (scripts/gate/gate.sh) runs on the fixture;
#   6. Playwright eyes: `playwright-cli --help`, serve over http (never
#      file://), screenshot at 390px, console clean — retried up to 3x
#      with per-attempt logs kept (Q-1 redo: the old single attempt
#      failed ~1 in 3 runs with its diagnostic discarded). Skipped at
#      install (--skip-eyes, recorded in skipped-subsystems.txt) →
#      PENDING, step not run (W-FIX-SKIP 2026-11-10: a skipped eyes step
#      is not a broken loop); when NOT skipped, a missing/failing
#      browser still FAILs — the skip check changes nothing there.
#   7. Pro Max search smoke test (v1 behaviour kept).
#   8. hook / MCP presence (H5/H6): skipped subsystems recorded by
#      install.sh are reported PENDING; the host's actual config is read
#      back for the Playwright MCP and the Impeccable hook — never silent,
#      never an OK for a subsystem that is not there.
#   9. Node 22+ (single required version, H14) and system-Chrome presence
#      (warn with the degradation when absent).
#
# Exit codes: 0 = the loop is PROVEN (every step ran and passed).
# 1 = a hard check failed, OR a loop step is UNVERIFIED (engine missing,
# detect unrunnable, gate's detect step skipped, playwright missing).
# Default mode used to warn those away and print RESULT: OK — a false
# pass (F3, fixed 2026-11-10): a run that never proved the loop said OK.
# Now an unverified loop step FAILS the run with RESULT: UNVERIFIED.
# --strict is kept for compatibility (it used to be the only mode that
# failed on a missing engine/playwright); default and --strict now agree
# on loop steps. A PRESENT-but-wrong engine, a present-but-failing
# screenshot, or a missing skill is ALWAYS a hard FAIL.
# Warnings remain for non-loop items only (copilot fallback copy, stale
# paths in reference data, Pro Max smoke, console probe).
# The "4x fewer tokens, ~27k vs ~114k" Playwright figure is CLAIMED (not in
# Microsoft's README) and is never cited here.
#
# Usage: ./verify.sh [--strict] [--hosts=H1,H2] [--help]
set -uo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
user_home="${HOME:?HOME must be set}"
state_dir="$user_home/.local/share/frontend-agent-kit"
refs_dir="$user_home/.local/share/agent-design-references"

strict=0
hosts_filter=""
for arg in "$@"; do
  case "$arg" in
    --help|-h) printf 'Usage: ./verify.sh [--strict] [--hosts=H1,H2]\n  --strict  (kept for compatibility) missing engine / missing playwright-cli fails; default mode already fails on any unverified loop step.\n'; exit 0 ;;
    --strict) strict=1 ;;
    --hosts=*) hosts_filter="${arg#--hosts=}" ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

fails=0
warns=0
unverified=0
# OS note (macOS phase, D12): Linux and macOS are both supported — no hard
# OS gate here (install.sh is the gate). On macOS, report the known gaps
# up front instead of failing confusingly in a later section.
case "$(uname -s)" in
  Linux) : ;;
  Darwin)
    printf 'verify.sh: running on macOS (Darwin) — supported. Known gaps on this OS: probes run unbounded when timeout(1) is absent (stock macOS has none; CI bounds the job with timeout-minutes), and the Playwright browser cache is ~/Library/Caches/ms-playwright.\n'
    ;;
  *) printf 'WARNING: verify.sh: untested OS (%s) — Linux and macOS are the supported targets.\n' "$(uname -s)" >&2 ;;
esac
ok()   { printf 'OK: %s\n' "$1"; }
warn() { warns=$((warns+1)); printf 'WARN: %s\n' "$1"; }
fail() { fails=$((fails+1)); printf 'FAIL: %s\n' "$1"; }
fail_loud() { fails=$((fails+1)); printf 'FAIL (LOCKSTEP): %s\n' "$1"; }
# UNVERIFIED is not a warning and not a hard fail: a loop step that could
# not run, so the loop is not proven. It fails the run (exit 1) with a
# RESULT: UNVERIFIED summary — never an OK.
unverified() { unverified=$((unverified+1)); printf 'UNVERIFIED: %s\n' "$1"; }
pending=0
# PENDING is informational, never silent and never a failure: a best-effort
# subsystem (hook / MCP) that is not registered. Install exits 0 with these
# pending by design; verify must REPORT them (H5), not print OK for them
# and not fail the loop for them either.
pending_msg() { pending=$((pending+1)); printf 'PENDING: %s\n' "$1"; }

# --- which hosts to check ---------------------------------------------------
# install.sh records its hosts; otherwise check every skills dir that exists.
declare -a HOSTS=()
if [[ -n "$hosts_filter" ]]; then
  IFS=',' read -r -a HOSTS <<< "$hosts_filter"
elif [[ -f "$state_dir/installed-hosts.txt" ]]; then
  # Bash 3.2 has no line-to-array builtin (stock macOS /bin/bash is 3.2;
  # the feature arrived in bash 4) — read the file with a loop instead
  # (the house style elsewhere in this file). Blank lines are skipped.
  while IFS= read -r _h || [[ -n "$_h" ]]; do
    [[ -n "$_h" ]] && HOSTS+=("$_h")
  done < "$state_dir/installed-hosts.txt"
  # An empty/blank record means "no hosts recorded" — fall back to all
  # hosts (same as a missing file). This also keeps HOSTS non-empty:
  # expanding an empty array under `set -u` aborts bash older than 4.4.
  if [[ "${#HOSTS[@]}" -eq 0 ]]; then
    for h in claude codex opencode gemini hermes copilot muse cmd; do HOSTS+=("$h"); done
  fi
else
  for h in claude codex opencode gemini hermes copilot muse cmd; do HOSTS+=("$h"); done
fi

skills_dirs_for_host() {
  case "$1" in
    claude)   printf '%s' "$user_home/.claude/skills" ;;
    codex)    printf '%s\n%s\n' "$user_home/.agents/skills" "$user_home/.codex/skills" ;;
    opencode) printf '%s\n%s\n' "$user_home/.config/opencode/skills" "$user_home/.agents/skills" ;;
    gemini)   printf '%s\n%s\n' "$user_home/.gemini/skills" "$user_home/.agents/skills" ;;
    hermes)   printf '%s\n%s\n' "$user_home/.hermes/skills" "$user_home/.agents/skills" ;;
    copilot)  printf '%s' "$user_home/.copilot/skills" ;;
    muse)     printf '%s' "$user_home/workspace/custom-skills" ;;
    # CommandCode (cmd): native user dir first, then the shared dir —
    # see install.sh skills_dirs_for_host (same order, same reason).
    cmd)      printf '%s\n%s\n' "$user_home/.commandcode/skills" "$user_home/.agents/skills" ;;
  esac
}

# Every skills dir the kit installs to, one per line. Used by the
# taste-path check and the Impeccable SKILL.md check below.
all_skills_dirs() {
  printf '%s\n' "$user_home/.agents/skills" "$user_home/.claude/skills" \
    "$user_home/.config/opencode/skills" "$user_home/.codex/skills" \
    "$user_home/.gemini/skills" "$user_home/.hermes/skills" \
    "$user_home/.copilot/skills" "$user_home/.commandcode/skills" \
    "$user_home/workspace/custom-skills"
}

# Find the Impeccable launcher in ANY installed skills dir. The old
# 3-path list missed muse-only installs (~/workspace/custom-skills) and
# codex/gemini/hermes/copilot installs, so a correct muse-only tree
# failed with "launcher missing" (F7/6b). Keep this list in sync with
# install.sh's warm-step search.
find_launcher() {
  local cand
  for cand in "$user_home/.agents/skills/impeccable/scripts/impeccable" \
             "$user_home/.claude/skills/impeccable/scripts/impeccable" \
             "$user_home/.config/opencode/skills/impeccable/scripts/impeccable" \
             "$user_home/.codex/skills/impeccable/scripts/impeccable" \
             "$user_home/.gemini/skills/impeccable/scripts/impeccable" \
             "$user_home/.hermes/skills/impeccable/scripts/impeccable" \
             "$user_home/.copilot/skills/impeccable/scripts/impeccable" \
             "$user_home/.commandcode/skills/impeccable/scripts/impeccable" \
             "$user_home/workspace/custom-skills/impeccable/scripts/impeccable"; do
    if [[ -x "$cand" ]]; then printf '%s' "$cand"; return 0; fi
  done
  return 1
}

# Whether install.sh installed copilot (recorded hosts). The copilot
# instructions file is a hard fail only then; on a record-less run that
# merely assumes all hosts, a missing copilot artefact is a warn.
# install.sh touches $state_dir/copilot-instructions-installed ONLY when it
# actually writes ~/.github/copilot-instructions.md. The no-host fallback
# installs to skills dirs only and must NOT write that live Copilot file
# (H18), even though installed-hosts.txt still lists copilot as a fallback
# skills-dir target — so the hosts list alone must not imply the file.
copilot_installed_by_kit=0
[[ -f "$state_dir/copilot-instructions-installed" ]] && copilot_installed_by_kit=1

# --- expected skills (discovered from the repo, same rule as install.sh) ---
declare -a EXPECTED=()
for d in "$root"/skills/*/; do [[ -f "${d}SKILL.md" ]] && EXPECTED+=("$(basename "$d")"); done
for d in "$root"/vendor/gsap/*/; do [[ -f "${d}SKILL.md" ]] && EXPECTED+=("$(basename "$d")"); done
[[ -d "$root/vendor/impeccable" ]] && EXPECTED+=("impeccable")
# de-duplicate, keep order
declare -a UNI=()
for n in "${EXPECTED[@]}"; do case " ${UNI[*]} " in *" $n "*) ;; *) UNI+=("$n") ;; esac; done
EXPECTED=("${UNI[@]}")
printf 'Hosts checked: %s\n' "${HOSTS[*]}"
printf 'Skills expected per host: %s\n' "${EXPECTED[*]}"

# --- 1. skills present per host + name == dir ------------------------------
for host in "${HOSTS[@]}"; do
  while IFS= read -r dir || [[ -n "$dir" ]]; do
    [[ -z "$dir" ]] && continue
    # Copilot does not load SKILL.md files (GSAP README, VERIFIED): a copy
    # there is a fallback only. Check it exists, but a missing Copilot copy
    # never fails the kit. Its WORKING artefact is
    # ~/.github/copilot-instructions.md (install.sh writes it when
    # copilot is installed): missing that fails when the kit installed
    # copilot, warns otherwise.
    if [[ "$host" == copilot ]]; then
      missing=0
      for name in "${EXPECTED[@]}"; do [[ -f "$dir/$name/SKILL.md" ]] || missing=$((missing+1)); done
      if [[ "$missing" == 0 ]]; then ok "copilot fallback copy present ($dir)";
      else warn "copilot fallback copy incomplete ($missing missing in $dir) — Copilot's working artefact is .github/copilot-instructions.md per project, not SKILL.md files"; fi
      if [[ -f "$user_home/.github/copilot-instructions.md" ]]; then
        ok "copilot instructions present ($user_home/.github/copilot-instructions.md)"
      elif [[ "$copilot_installed_by_kit" == 1 ]]; then
        fail "copilot instructions missing: $user_home/.github/copilot-instructions.md — Copilot's working artefact (install.sh writes it when copilot is installed)"
      else
        warn "copilot instructions missing: $user_home/.github/copilot-instructions.md (copilot was not installed by this kit — run ./install.sh --hosts=copilot)"
      fi
      continue
    fi
    fails_before="$fails"
    for name in "${EXPECTED[@]}"; do
      f="$dir/$name/SKILL.md"
      if [[ ! -f "$f" ]]; then fail "missing skill: $host: $f"; continue; fi
      got="$(grep -m1 -E '^[[:space:]]*name:[[:space:]]*' "$f" | sed -E 's/.*name:[[:space:]]*"?([^" ]+)"?/\1/' || true)"
      if [[ -n "$got" && "$got" != "$name" ]]; then
        fail "skill name mismatch: $f declares name '$got', directory is '$name'"
      fi
    done
    # An OK line is a verdict: only print it when this dir added no
    # failures (the old unconditional OK printed after FAILs — F11).
    [[ "$fails" == "$fails_before" ]] && ok "skills present: $host ($dir)"
  done < <(skills_dirs_for_host "$host")
done

# --- 2. stale ${CLAUDE_PLUGIN_ROOT} paths (A3) -----------------------------
if grep -rInF '${CLAUDE_PLUGIN_ROOT}' \
     "$user_home/.agents/skills" "$user_home/.claude/skills" \
     "$user_home/.config/opencode/skills" "$user_home/.gemini/skills" \
     "$user_home/.hermes/skills" "$user_home/.codex/skills" \
     "$user_home/.copilot/skills" "$user_home/.commandcode/skills" \
     "$user_home/workspace/custom-skills" 2>/dev/null | head -5; then
  fail "stale \${CLAUDE_PLUGIN_ROOT} path found in an installed skill (clean-env failure A3) — see matches above"
else
  ok "no stale \${CLAUDE_PLUGIN_ROOT} in installed skills"
fi
if grep -rInF '${CLAUDE_PLUGIN_ROOT}' "$refs_dir" 2>/dev/null | head -3; then
  # The matches that fire this are upstream reference-data text, NOT the
  # installed skills (those fail hard in §2 above): the vendored taste
  # tree's hook command cites ${CLAUDE_PLUGIN_ROOT} (it only resolves
  # inside a Claude plugin install). Warn, do not fail: the kit's wrapper
  # skills use the $HOME path and never rely on the variable. The old text
  # ("known v1 vendored defect, fixed by the Pro Max re-pin") was stale on
  # both counts: the Pro Max SKILL.md refs were fixed by the KIT PATCH
  # (vendor/ui-ux-pro-max/SOURCE.txt, KIT PATCH — re-apply on re-pin), not
  # by the re-pin, and the firing match is the taste tree, which no re-pin
  # fixed. A match inside an installed SKILL.md is a different case: §2
  # fails it, and the fix is re-applying the patch, not this warn.
  warn "stale \${CLAUDE_PLUGIN_ROOT} in reference data ($refs_dir) — upstream vendored text (see matches above; taste tree hook command). Warn-only: the kit's wrapper skills use the \$HOME path, so the reference data is still usable. (Pro Max SKILL.md refs were fixed by the kit patch, not the re-pin — a match inside a SKILL.md fails in §2.)"
fi

# --- 2b. generated Impeccable SKILL.md is shippable as-is --------------------
# Check EVERY installed copy in EVERY skills dir (H11 redo 2026-11-10).
# The old code `break`ed after the first copy found, so a corrupted
# second copy (e.g. only .codex/skills/impeccable/SKILL.md tampered)
# passed verify with RESULT: OK. A failure in ANY copy fails the run.
checked_2b=0
while IFS= read -r sd || [[ -n "$sd" ]]; do
  cand="$sd/impeccable/SKILL.md"
  [[ -f "$cand" ]] || continue
  checked_2b=$((checked_2b+1))
  if grep -q '{{[a-z_]*}}' "$cand"; then
    fail "generated Impeccable SKILL.md has unresolved placeholders: $cand"
  fi
  if grep -q '^version:' "$cand"; then
    fail "generated Impeccable SKILL.md carries a top-level version: (must live in metadata): $cand"
  fi
  if grep -q '^metadata:' "$cand" && grep -A1 '^metadata:' "$cand" | grep -q 'version:'; then
    ok "Impeccable SKILL.md spec-pure (version in metadata, no placeholders): $cand"
  else
    warn "Impeccable SKILL.md has no metadata.version: $cand (older v1 variant?)"
  fi
done < <(all_skills_dirs)
[[ "$checked_2b" == 0 ]] && fail "no installed Impeccable SKILL.md found in any skills dir"

# --- 2c. taste pipeline paths resolve from the installed wrapper --------
# The taste-reference wrapper cites vendor/taste/skills/taste-skill/…
# paths. install.sh points each installed wrapper's vendor/ at the
# installed taste tree ($refs_dir/taste); every cited anchor must resolve
# from the installed skill dir, or the taste layer is dangling (F5).
taste_anchors=(
  'vendor/taste/skills/taste-skill/SKILL.md'
  'vendor/taste/skills/taste-skill/scripts/consistency.mjs'
  'vendor/taste/skills/taste-skill/scripts/gate.mjs'
  'vendor/taste/skills/taste-skill/scripts/start.mjs'
  'vendor/taste/skills/taste-skill/library/palettes.json'
  'vendor/taste/skills/taste-skill/library/type.json'
  'vendor/taste/skills/taste-skill/assets/diagrams/presets.json'
  'vendor/taste/skills/taste-skill/references/system.md'
)
taste_checked=0
taste_fails_before="$fails"
while IFS= read -r sd || [[ -n "$sd" ]]; do
  tdir="$sd/taste-reference"
  [[ -f "$tdir/SKILL.md" ]] || continue
  taste_checked=1
  for anchor in "${taste_anchors[@]}"; do
    [[ -e "$tdir/$anchor" ]] || fail "taste path dangling: $tdir/$anchor does not resolve (install.sh must point taste-reference/vendor at the installed taste tree)"
  done
done < <(all_skills_dirs)
[[ "$taste_checked" == 1 && "$fails" == "$taste_fails_before" ]] && ok "taste-reference wrapper paths resolve (all cited anchors present)"

# --- 2d. no live builder-self-grade language in installed skills --------
# The builder NEVER grades its own work (kit grader rule — the grade step
# MUST dispatch to an independent judge; see skills/frontend-kit/SKILL.md
# "Precedence" and references/grader-rubric.md). This check FAILS the
# install if any installed skill contains a LIVE instruction to self-grade,
# and distinguishes those from PROHIBITING mentions of the same words.
#
# RULE (exact, fail-closed — redo 2026-11-10, H4):
#   1. PATTERNS (case-insensitive, substring): the four original phrases
#      plus the direct phrasings — "grade your own work", "grade your own",
#      "score your own", "review your own work", "assess your own",
#      "evaluate your own", "critique your own work" (lowercase form of
#      the original "Critique your own work").
#   2. FILE TYPES: every shipped file type under the installed skills dirs,
#      not just *.md — .md, .toml, .json, .js, .mjs, .py, .sh. A live
#      instruction in a Codex .toml agent file is a live instruction.
#   3. ALLOWLIST — sentence-scoped governance. A matched line is exempt
#      ONLY if, in the SAME SENTENCE as the matched phrase (a sentence is
#      the text between . ! ? or ; boundaries on that physical line), one
#      of these prohibiting constructions occurs:
#        a negation governing the phrase: never / not / n't / cannot
#        (word-matched, so "notice" does not count);
#        a prohibition/override word: forbidden, prohibit*, overrid*;
#        a documented override citation: "which requires a",
#        "including upstream", "Those passages are upstream text",
#        "frontend-design/SKILL.md:57" (the citation form of the
#        frontend-design passage), "banner on degraded runs",
#        "must not be followed as grading".
#      A token in a DIFFERENT sentence on the same line does NOT exempt
#      the phrase (H4b: "…grade your own work and report the score.
#      NEVER grades its own work" FAILS — the NEVER is a second sentence
#      quoting the prohibition, not a negation governing the instruction).
#      ONE narrow exception to the same-sentence rule (H4 fix 2026-11-10):
#      a QUOTED mention — the phrase inside double quotes, i.e. a citation
#      of upstream text, not a bare instruction — is exempt when a
#      citation/override marker (upstream / overrid* / "must not be
#      followed" / "which requires a" / "precedence" / the
#      frontend-design citation) occurs in the same sentence, the
#      immediately following one, or the NEXT PHYSICAL LINE (the kit's
#      docs hard-wrap paragraphs, so the Precedence note's "Those
#      passages are upstream text" sits on the line after the quoted
#      phrase, and "is OVERRIDDEN" sits on the line after the quoted
#      sentence). This is what the kit's own Precedence notes need:
#      frontend-kit SKILL.md:34 cites ("Critique your own work") and
#      the next line says "Those passages are upstream text …
#      overridden"; SKILL.md:104 quotes the sentence and the next line
#      says "is OVERRIDDEN". Bare negations (never/not) do NOT qualify
#      for this exception — a quoted instruction followed by "NEVER do
#      it" still FAILS — so the H4b bypass stays caught: its phrase is
#      unquoted, so the exception never applies to it at all.
#   4. EXACT-STRING EXCEPTION (line level): the one documented overridden
#      vendored passage, Anthropic's sentence "Critique your own work as
#      you build, taking screenshots" (frontend-design SKILL.md:59 +
#      SOURCE.md:59). Any OTHER wording of a self-critique instruction
#      is not allowlisted and FAILS.
#   5. NO file-scoped exemption for upstream critique.md banner lines.
#      The generated copy must not contain "MUST be a banner" /
#      "lead the report with" lines at all; if it does, the generator
#      failed and verify FAILS (H1 class). The old file-scoped exemption
#      is deleted, not widened.
# Implemented in python3 (a hard prereq already — the fixture server
# below needs it) because sentence splitting + word matching is not
# expressible in a grep -v pipeline, and grep -v was the H4b hole.
self_grade_dirs=()
while IFS= read -r sd || [[ -n "$sd" ]]; do [[ -d "$sd" ]] && self_grade_dirs+=("$sd"); done < <(all_skills_dirs)
self_grade_hits=""
if [[ "${#self_grade_dirs[@]}" -gt 0 ]]; then
  self_grade_hits="$(SELF_GRADE_DIRS="${self_grade_dirs[*]}" python3 - "$root" <<'PYEOF2'
import os, re, sys
patterns = [
    'you are both parties', 'degraded: single-context',
    'single-context self-critique', 'critique your own work',
    'grade your own work', 'grade your own', 'score your own',
    'review your own work', 'assess your own', 'evaluate your own',
]
# Word-matched negations / prohibitions (regex, case-insensitive).
prohibiting_res = [
    r'\bnever\b', r'\bnot\b', r"n\'t\b", r'\bcannot\b',
    r'\bforbidden\b', r'\bprohibit\w*', r'\boverrid\w*',
]
# Substring citations that only occur in override notes.
prohibiting_subs = [
    'which requires a', 'including upstream',
    'those passages are upstream text', 'frontend-design/skill.md:57',
    'banner on degraded runs', 'must not be followed as grading',
]
# Citation/override markers for the QUOTED-mention exception (rule 3b):
# bare negations are deliberately NOT in this list.
citation_markers = [
    'upstream', 'overrid', 'must not be followed', 'which requires a',
    'including upstream', 'those passages are upstream text',
    'precedence', 'frontend-design/skill.md:57',
]
quoted_re = re.compile(r'"[^"]*"')
exact_exception = 'critique your own work as you build, taking screenshots'
exts = {'.md', '.toml', '.json', '.js', '.mjs', '.py', '.sh'}
sentence_split = re.compile(r'[.!?;]')
hits = []
for d in os.environ['SELF_GRADE_DIRS'].split():
    for base, _dirs, files in os.walk(d):
        for fn in files:
            if os.path.splitext(fn)[1].lower() not in exts:
                continue
            path = os.path.join(base, fn)
            try:
                with open(path, encoding='utf-8', errors='replace') as f:
                    lines = f.read().splitlines()
            except OSError:
                continue
            for n, line in enumerate(lines, 1):
                low = line.lower()
                # Next physical line (lowercased) — the kit's docs hard-wrap
                # paragraphs, so a quoted citation's governing marker can
                # sit on the line after the phrase (rule 3b only).
                next_low = lines[n].lower() if n < len(lines) else ''
                if exact_exception in low:
                    continue
                found = [pt for pt in patterns if pt in low]
                if not found:
                    continue
                live = False
                sentences = sentence_split.split(low)
                for si, sent in enumerate(sentences):
                    if not any(pt in sent for pt in found):
                        continue
                    governed = any(re.search(rx, sent) for rx in prohibiting_res) \
                        or any(sub in sent for sub in prohibiting_subs)
                    if governed:
                        continue
                    # Quoted-mention exception (rule 3b): the phrase is a
                    # citation inside double quotes, and a citation/override
                    # marker occurs in this sentence, the next one, or the
                    # next physical line. "Quoted" means inside a complete
                    # "..." span on this line, OR after an unclosed opening
                    # quote (the quote closes on the next hard-wrapped
                    # line, as in SKILL.md:104-105: "Critique your own
                    # work as / you build" … is OVERRIDDEN).
                    quoted = any(pt in q for q in quoted_re.findall(sent) for pt in found)
                    if not quoted:
                        for pt in found:
                            _pos = sent.find(pt)
                            if _pos >= 0 and sent[:_pos].count('"') % 2 == 1:
                                quoted = True
                                break
                    if quoted:
                        nxt = sentences[si + 1] if si + 1 < len(sentences) else ''
                        if any(m in sent for m in citation_markers) \
                                or any(m in nxt for m in citation_markers) \
                                or any(m in next_low for m in citation_markers):
                            continue
                    live = True
                    break
                if live:
                    hits.append(f'{path}:{n}:{line}')
print('\n'.join(hits))
PYEOF2
)"
fi
if [[ -n "$self_grade_hits" ]]; then
  fail "live builder-self-grade language in an installed skill — the builder NEVER grades its own work (kit grader rule, skills/frontend-kit/SKILL.md Precedence). Matches:"
  printf '%s\n' "$self_grade_hits"
else
  ok "no live builder-self-grade language in installed skills (sentence-scoped prohibiting mentions allowlisted — see §2d comment)"
fi

# --- 3. Impeccable engine lockstep (A10) — FAIL LOUDLY on mismatch --------
# The expected engine comes from the REPO pin, not from the installed
# tree (F4/QC F8): installed-vs-installed lockstep passes a jointly
# replaced skill+engine pair undetected. Repo pin sources, in order:
# the canonical tree's scripts/VERSION, then SOURCE.txt's engine= line.
launcher="$(find_launcher || true)"
expected_engine=""
repo_version_file="$root/vendor/impeccable/skill/scripts/VERSION"
if [[ -f "$repo_version_file" ]]; then
  expected_engine="$(tr -d '[:space:]' < "$repo_version_file")"
elif [[ -f "$root/vendor/impeccable/SOURCE.txt" ]]; then
  expected_engine="$(sed -n 's/^engine=//p' "$root/vendor/impeccable/SOURCE.txt" | head -n 1 | tr -d '[:space:]')"
fi
if [[ -z "$expected_engine" ]]; then
  fail "cannot establish the repo engine pin (vendor/impeccable/skill/scripts/VERSION and SOURCE.txt engine= both unreadable) — lockstep cannot be checked"
fi
if [[ -z "$launcher" ]]; then
  fail "impeccable launcher missing from every installed skills dir"
elif [[ -z "$expected_engine" ]]; then
  : # pin already failed above; do not probe against an unknown pin
else
  # The installed skill's own VERSION must ALSO match the repo pin — a
  # jointly-replaced installed pair (skill VERSION + engine both swapped
  # to a wrong version) is caught here even though probe-vs-installed
  # would pass.
  installed_version=""
  vf="$(dirname -- "$launcher")/VERSION"
  [[ -f "$vf" ]] && installed_version="$(tr -d '[:space:]' < "$vf")"
  if [[ -z "$installed_version" ]]; then
    fail "impeccable scripts/VERSION missing next to $launcher (cannot establish the installed skill's expected engine)"
  elif [[ "$installed_version" != "$expected_engine" ]]; then
    fail_loud "installed skill expects engine $installed_version but the repo pin is $expected_engine — the installed skill tree is not the vendored pin. Re-run ./install.sh."
  else
    probe_out="$("$launcher" engine-probe 2>&1 || true)"
    case "$probe_out" in
      impeccable-engine\ *)
        actual_engine="${probe_out#impeccable-engine }"
        actual_engine="${actual_engine%%[[:space:]]*}"
        if [[ "$actual_engine" == "$expected_engine" ]]; then
          ok "engine lockstep: repo pin $expected_engine, installed skill expects $installed_version, engine reports $actual_engine"
          # H2 (redo 2026-11-10): a version STRING is not lockstep. The
          # launcher trusts IMPECCABLE_BIN (no probe at all), the
          # unversioned ~/.impeccable/bin/impeccable and PATH `impeccable`
          # on a probe handshake alone, and verify.sh never read
          # engine-checksums.txt at all — a 6-line stub printing the
          # pinned version passed everything. So hash the engine binary
          # the launcher actually resolved against the REPO's
          # engine-checksums.txt (vendor/impeccable/skill/scripts/).
          # Resolution mirrors the launcher's candidate order
          # (IMPECCABLE_BIN, sibling bin/, unversioned home bin,
          # version-pinned cache, PATH); the first executable candidate
          # that answers the probe is the engine that ran. A hash
          # mismatch FAILS unless the operator explicitly opted into a
          # local build with IMPECCABLE_ALLOW_LOCAL_ENGINE=1 (documented
          # opt-in: that binary is trusted by the operator, not by the
          # kit — the version string is still checked above).
          engine_asset=""
          case "$(uname -s 2>/dev/null || echo unknown)-$(uname -m 2>/dev/null || echo unknown)" in
            Linux-x86_64|Linux-amd64) engine_asset="impeccable-linux-x64" ;;
            Linux-aarch64|Linux-arm64) engine_asset="impeccable-linux-arm64" ;;
            Darwin-arm64|Darwin-aarch64) engine_asset="impeccable-darwin-arm64" ;;
            Darwin-x86_64|Darwin-amd64) engine_asset="impeccable-darwin-x64" ;;
          esac
          repo_checksums="$root/vendor/impeccable/skill/scripts/engine-checksums.txt"
          expected_digest=""
          if [[ -n "$engine_asset" && -f "$repo_checksums" ]]; then
            expected_digest="$(awk -v v="$expected_engine" -v a="$engine_asset" '$1==v && $2==a {print $3; exit}' "$repo_checksums")"
          fi
          resolved_engine=""
          probe_candidate() { # <path> — 0 if it answers the engine handshake
            IMPECCABLE_LAUNCHER_PROBE=1 "$1" engine-probe 2>/dev/null | grep -q '^impeccable-engine '
          }
          _cand=""
          if [[ -n "${IMPECCABLE_BIN:-}" && -x "$IMPECCABLE_BIN" ]]; then resolved_engine="$IMPECCABLE_BIN";
          else
            _sib="$(dirname -- "$launcher")/bin/$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')-$(uname -m 2>/dev/null)/impeccable"
            case "$(uname -s 2>/dev/null)" in Darwin) _sib="$(dirname -- "$launcher")/bin/darwin-$(uname -m 2>/dev/null | sed -e 's/x86_64/x64/' -e 's/aarch64/arm64/')/impeccable" ;; Linux) _sib="$(dirname -- "$launcher")/bin/linux-$(uname -m 2>/dev/null | sed -e 's/x86_64/x64/' -e 's/aarch64/arm64/')/impeccable" ;; esac
            _home_bin="$user_home/.impeccable/bin/impeccable"
            _cache="${IMPECCABLE_HOME:-$user_home/.impeccable}/bin/$expected_engine/impeccable"
            for _cand in "$_sib" "$_home_bin" "$_cache" "$(command -v impeccable 2>/dev/null || true)"; do
              [[ -n "$_cand" && -x "$_cand" ]] || continue
              if probe_candidate "$_cand"; then resolved_engine="$_cand"; break; fi
            done
          fi
          if [[ -z "$resolved_engine" ]]; then
            fail "engine answered the probe but no engine binary could be located to hash (checked IMPECCABLE_BIN, sibling bin/, ~/.impeccable/bin/impeccable, the $expected_engine cache, PATH) — refusing probe-only trust (H2)"
          elif [[ -z "$expected_digest" ]]; then
            fail "no checksum in the repo engine-checksums.txt for engine $expected_engine ($engine_asset) — cannot hash-verify the engine binary $resolved_engine"
          else
            actual_digest=""
            if command -v sha256sum >/dev/null 2>&1; then actual_digest="$(sha256sum -- "$resolved_engine" 2>/dev/null | awk '{print $1}')";
            elif command -v shasum >/dev/null 2>&1; then actual_digest="$(shasum -a 256 -- "$resolved_engine" 2>/dev/null | awk '{print $1}')"; fi
            if [[ -z "$actual_digest" ]]; then
              fail "cannot hash the engine binary $resolved_engine (no sha256sum/shasum) — lockstep cannot be proven"
            elif [[ "$actual_digest" == "$expected_digest" ]]; then
              ok "engine binary hash-verified against repo engine-checksums.txt ($resolved_engine, $engine_asset $expected_engine)"
            elif [[ "${IMPECCABLE_ALLOW_LOCAL_ENGINE:-}" == 1 ]]; then
              warn "engine binary $resolved_engine does NOT match the repo checksum for $engine_asset $expected_engine, but IMPECCABLE_ALLOW_LOCAL_ENGINE=1 explicitly trusts this local build (operator opt-in — the kit does not vouch for it)"
            else
              fail_loud "engine binary hash MISMATCH: $resolved_engine hashes to $actual_digest but the repo engine-checksums.txt records $expected_digest for $engine_asset $expected_engine. This binary is NOT the pinned release — a probe-only stub or substituted engine passes the version string but fails the hash. Refusing it (set IMPECCABLE_ALLOW_LOCAL_ENGINE=1 only to explicitly trust a local build)."
            fi
          fi
        else
          fail_loud "engine MISMATCH: repo pin is $expected_engine but the installed engine reports $actual_engine. The 62-rule registry lives in the engine — detect would silently apply the wrong rules. Re-run ./install.sh (warm) or install the matching engine binary."
        fi
        ;;
      *)
        # No engine answered the probe. If a DIFFERENT engine version sits in
        # the version-pinned cache, that is not "not warmed yet" — it is a
        # stale engine shadowing the expected one, and the loop must not
        # proceed on a warn. (The 4.8.2 launcher additionally refuses to
        # download an engine whose checksum is not in engine-checksums.txt,
        # so a tampered VERSION cannot silently fetch a wrong binary.)
        stale=""
        if [[ -d "$user_home/.impeccable/bin" ]]; then
          for vdir in "$user_home"/.impeccable/bin/*/; do
            [[ -d "$vdir" ]] || continue
            v="$(basename "$vdir")"
            [[ "$v" != "$expected_engine" ]] && stale="$stale $v"
          done
        fi
        if [[ -n "${stale// }" ]]; then
          fail_loud "engine UNREACHABLE for expected $expected_engine, but stale engine version(s)$stale sit in ~/.impeccable/bin. Re-warm with ./install.sh (or: $launcher engine-probe) so the expected engine is installed; do not run detect against the stale one."
        else
          unverified "impeccable engine not installed/reachable (repo pin $expected_engine; engine-probe gave: ${probe_out:-<no output>}). Run ./install.sh (warm step) or: $launcher engine-probe — lockstep cannot be checked until the engine exists."
        fi
        ;;
    esac
  fi
fi

# --- fixture page (served over http, never file://) -------------------------
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cat > "$work/index.html" <<'EOF'
<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>frontend-agent-kit verify fixture</title>
<link rel="icon" href="favicon.ico">
<link rel="stylesheet" href="tokens.css">
<style>body{background:var(--bg);color:var(--ink);padding:var(--space)}</style></head>
<body><main><h1>Verify fixture</h1><p>A clean page for the loop checks.</p></main></body></html>
EOF
cat > "$work/tokens.css" <<'EOF'
:root { --bg: #ffffff; --ink: #0a0f1e; --space: 16px; }
body { background: var(--bg); color: var(--ink); margin: 0; padding: var(--space); font-family: system-ui, sans-serif; }
EOF
# The fixture is a real project by the gate's own rule (F6): the taste lock
# lives in design/tokens.css — without it gate.sh fails the fixture.
mkdir -p "$work/design"
cp "$work/tokens.css" "$work/design/tokens.css"
# Q-1 redo: the fixture ships a real favicon.ico so the page logs no
# deterministic favicon 404 console error (the only anomaly on the old
# fixture page — it fired on every page load). Minimal valid 16x16 32bpp
# ICO, generated inline: no external file, no network.
python3 - "$work/favicon.ico" <<'PYEOF'
import struct, sys
w = h = 16
xor = bytes([0x1e, 0x0f, 0x0a, 0xff]) * (w * h)  # solid #0a0f1e, opaque
and_mask = bytes(32)                            # fully opaque
bih = struct.pack('<IiiHHIIiiII', 40, w, h * 2, 1, 32, 0, len(xor) + len(and_mask), 0, 0, 0, 0)
img = bih + xor + and_mask
hdr = struct.pack('<HHH', 0, 1, 1)
entry = struct.pack('<BBBBHHII', w, h, 0, 0, 1, 32, len(img), 6 + 16)
open(sys.argv[1], 'wb').write(hdr + entry + img)
PYEOF

# --- 4. impeccable detect runs ----------------------------------------------
if [[ -n "$launcher" && -n "$expected_engine" ]]; then
  detect_out="$("$launcher" detect "$work/index.html" 2>&1)"
  detect_code=$?
  case "$detect_code" in
    0) ok "impeccable detect runs clean on the fixture" ;;
    2) fail "impeccable detect reported findings on the clean fixture (exit 2): $detect_out" ;;
    1) fail "impeccable detect could not scan the fixture (exit 1): $detect_out" ;;
    *) unverified "impeccable detect not runnable (exit $detect_code — engine probably not warmed): $detect_out" ;;
  esac
fi

# --- 5. deterministic gate runs ---------------------------------------------
if [[ -x "$root/scripts/gate/gate.sh" ]]; then
  if "$root/scripts/gate/gate.sh" --target "$work" ${launcher:+--launcher "$launcher"} >"$work/gate.log" 2>&1; then
    # A passing gate whose detect step was SKIPPED proves only the static
    # checks — the loop's detect leg is unproven (F3). That is UNVERIFIED,
    # not an OK.
    if grep -qi 'detect skipped' "$work/gate.log"; then
      unverified "gate ran but its impeccable-detect step was skipped (engine not reachable) — static checks alone passed; the loop's detect leg is not proven"
    else
      ok "gate scripts run (scripts/gate/gate.sh on fixture)"
    fi
  else
    # A gate that fails ONLY because its detect leg could not run is
    # UNVERIFIED (the loop step is unproven), not a hard FAIL — the new
    # gate.sh fails loudly on a skipped detect (F6) instead of passing on
    # static checks alone, so distinguish that from a real gate failure.
    if grep -qi 'detect skipped\|detect did not complete' "$work/gate.log"; then
      unverified "gate could not run its impeccable-detect leg on the fixture (engine not reachable) — static checks may have passed, but the loop's detect leg is not proven"
      cat "$work/gate.log" >&2 || true
    else
      fail "gate scripts failed on the fixture — see $work/gate.log (log removed with temp dir; re-run gate.sh --target <dir> to reproduce)"
      cat "$work/gate.log" >&2 || true
    fi
  fi
else
  fail "gate script missing: $root/scripts/gate/gate.sh"
fi

# --- 6. Playwright eyes ------------------------------------------------------
# Skip-awareness (W-FIX-SKIP 2026-11-10): install.sh records --skip-eyes
# in $state_dir/skipped-subsystems.txt. When eyes was skipped at install,
# a missing/failing browser is EXPECTED, not a broken loop — report
# PENDING and skip the whole step (no --help, no screenshot, no FAIL, no
# UNVERIFIED). When eyes was NOT skipped, the step below runs unchanged:
# a missing/failing browser still FAILs (and a missing CLI is still
# UNVERIFIED in default mode / FAIL under --strict). The other verify
# steps need no such check: §8 already reports skipped hooks/mcp as
# PENDING (never FAIL), and no other step FAILs on a skipped hooks/mcp
# subsystem — §3/§4/§5 depend on the engine warm, §9 on Node, §7 on
# reference data, none on hooks/mcp/eyes skips.
eyes_skipped=0
if [[ -f "$state_dir/skipped-subsystems.txt" ]] && grep -qx 'eyes' "$state_dir/skipped-subsystems.txt" 2>/dev/null; then
  eyes_skipped=1
fi
if [[ "$eyes_skipped" == 0 ]]; then
  # Resolve the CLI + node to REAL binaries (clean-env 2026-11-11,
  # GAP-5 redo — the round-1 fix was incomplete and run 3 proved it):
  # `command -v playwright-cli` succeeding does NOT mean the CLI runs.
  # On mise-managed machines the PATH entry is a mise shim, and the shim
  # fails at EXEC time ("No version is set for shim: playwright-cli")
  # when invoked from a cwd outside the mise config chain — this step
  # runs its eyes commands from a temp dir under /tmp, so every eyes
  # invocation failed in run 3 even though install-browser (run from the
  # repo dir) had worked minutes earlier. Resolving the CLI to the real
  # binary alone is NOT enough either: the CLI is a node script with a
  # `#!/usr/bin/env node` shebang, and `node` on PATH is ALSO a mise
  # shim that fails from /tmp — the real CLI binary fails there too
  # (reproduced 2026-11-11). The fix is to prepend the npm-prefix bin
  # dir to PATH: it holds BOTH the real playwright-cli AND the real
  # node, so the shebang resolves to a real binary from any cwd. Do
  # this UNCONDITIONALLY (when the real bin exists) — not only when
  # `command -v` fails, as the round-1 code did — because a present
  # shim is exactly the broken case. `mise which` is the fallback
  # (same shape: its bin dir holds the real node too). PATH is restored
  # after the §6 block (red-team H7): the prepend is for the eyes step
  # only.
  # TWIN BLOCK (L4 — drift risk): install.sh contains a near-duplicate
  # of this resolve block (the Playwright eyes section). Any fix here
  # MUST also land there (and vice versa) — the two blocks drifted
  # apart before (round-1 fix incomplete, run 3 proved it) and only a
  # paired edit keeps them in step.
  _pw_saved_path="$PATH"
  _pw_saved_path_set=1
  # L1: extend the EXIT trap (which already removes $work) to restore
  # PATH too, so an early exit cannot leak the prepend into the
  # caller's shell. The sequential restore below stays: the trap is the
  # backstop, not the mechanism. NOTE: this script is EXECUTED, not
  # sourced — do NOT source it. A sourced run would leave the prepend
  # in the caller's shell if the script exits before the sequential
  # restore, and installing this trap clobbers any EXIT trap the caller
  # already had. The trap is unset (`trap - EXIT`) right after the
  # sequential restore, so it cannot linger past this section ($work is
  # removed eagerly there instead — it is not used past the restore).
  # Sentinel-guarded (L2) so an empty original PATH still restores
  # (empty, not unset). The trap ALSO removes the scratch dirs
  # (capdir/probe dir) so an early exit does not leak them (M4); the
  # normal path removes them too (idempotent).
  # (M5: the trap's real trigger is signals/aborts — fail() only counts
  # here and cannot trigger it, so "fail() between prepend and restore"
  # cannot fire it; the comment used to claim otherwise. L6: the
  # trap's `rm -rf "$work"` is guarded with -- and an empty-check.)
  trap 'if [[ -n "${work:-}" ]]; then rm -rf -- "$work" 2>/dev/null || true; fi; if [[ -n "${_pw_saved_path_set:-}" ]]; then PATH="$_pw_saved_path"; hash -r; fi; if [[ "${_pw_capdir_own:-0}" == 1 && -n "${_pw_capdir:-}" ]]; then rm -rf -- "$_pw_capdir" 2>/dev/null || true; fi; if [[ -n "${_pw_probe_dir:-}" && "${_pw_probe_dir:-}" != "${work:-}" ]]; then rm -rf -- "$_pw_probe_dir" 2>/dev/null || true; fi' EXIT
  # Probe helpers (round-3 re-QC: M-C, L-C, L-G). Every probe below runs
  # through _pw_timeout30 so a hung mise/shim cannot stall the script
  # forever; stderr is captured to files under $_pw_capdir and the first
  # line printed on failure instead of discarded (L-C). Defined here,
  # inside the block, so the block stays self-contained.
  # (M6: timeout(1) can only run EXTERNAL commands — every probe
  # argument below must be a PATH-resolved binary, never a shell
  # function. Detected with `type -P` (file only) so a function named
  # `timeout` cannot silently satisfy the check.)
  _pw_have_timeout=0; type -P timeout >/dev/null 2>&1 && _pw_have_timeout=1
  if [[ "$_pw_have_timeout" == 0 ]]; then printf 'WARNING: timeout(1) not found — probes run unbounded (a hung mise/shim can stall the script).\n' >&2; fi
  _pw_timeout30() { if [[ "$_pw_have_timeout" == 1 ]]; then timeout -k 5 30 "$@"; else "$@"; fi; }
  _pw_canon() { # <path> — canonical path, or the input unchanged
    # Portable canonicaliser (macOS phase, D12): GNU readlink -f first,
    # then python3 realpath (BSD readlink has no -f; python3 is a hard
    # prereq). If neither works, return the input unchanged — callers
    # treat that as "unresolved", never as an error. No `--` before the
    # path argument: with `python3 -c`, `--` lands in sys.argv[1]
    # instead of being stripped (verified 2026-11-11), so it would
    # canonicalise the literal `--`. All call sites pass absolute paths.
    local _c=""
    if [[ -n "${1:-}" ]]; then
      if command -v readlink >/dev/null 2>&1; then _c="$(readlink -f -- "$1" 2>/dev/null || true)"; fi
      if [[ -z "$_c" ]] && command -v python3 >/dev/null 2>&1; then _c="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null || true)"; fi
    fi
    printf '%s' "${_c:-$1}"
  }
  _pw_same_file() { # <a> <b>: exit 0 if the same file, by canonical path or inode
    local _a="${1:-}" _b="${2:-}" _ca _cb _ia _ib
    [[ -z "$_a" || -z "$_b" ]] && return 1
    [[ "$_a" == "$_b" ]] && return 0
    _ca="$(_pw_canon "$_a")"; _cb="$(_pw_canon "$_b")"
    [[ "$_ca" == "$_cb" ]] && return 0
    if command -v stat >/dev/null 2>&1; then
      _ia="$(stat -c '%d:%i' -- "$_a" 2>/dev/null || true)"
      if [[ -z "$_ia" ]]; then _ia="$(stat -f '%d:%i' -- "$_a" 2>/dev/null || true)"; fi
      _ib="$(stat -c '%d:%i' -- "$_b" 2>/dev/null || true)"
      if [[ -z "$_ib" ]]; then _ib="$(stat -f '%d:%i' -- "$_b" 2>/dev/null || true)"; fi
      [[ -n "$_ia" && "$_ia" == "$_ib" ]] && return 0
    fi
    return 1
  }
  _pw_first_line() { [[ -s "${1:-}" ]] && head -n 1 -- "$1" || true; }
  # H1 (micro red-team): a failed cd must never be misread as a tool
  # failure. _pw_cd_ok <dir> exits 0 iff the dir can be entered.
  # Probe sites use rc 98 as the "cd failed — inconclusive" sentinel.
  _pw_cd_ok() { (cd -- "${1:-}" 2>/dev/null); }
  # Capture files for probe stdout/stderr (M-C/L-C): one scratch dir
  # under /tmp (TMPDIR forced — L-H: a poisoned TMPDIR must not move
  # these). If mktemp fails, fall back to /tmp itself with $$-suffixed
  # names (redirection creates the files; no mkdir needed).
  _pw_capdir="$(TMPDIR=/tmp mktemp -d 2>/dev/null || true)"
  _pw_capdir_own=1
  if [[ -z "$_pw_capdir" ]]; then _pw_capdir="/tmp"; _pw_capdir_own=0; printf 'WARNING: could not create a temp capture dir — probe output files use predictable /tmp/pw-*-$$.out names instead (a degraded /tmp).\n' >&2; fi
  _pw_npm_out="$_pw_capdir/pw-npm-prefix-$$.out"; _pw_npm_err="$_pw_capdir/pw-npm-prefix-$$.err"
  _pw_mise_cli_out="$_pw_capdir/pw-mise-cli-$$.out"; _pw_mise_cli_err="$_pw_capdir/pw-mise-cli-$$.err"
  _pw_mise_node_out="$_pw_capdir/pw-mise-node-$$.out"; _pw_mise_node_err="$_pw_capdir/pw-mise-node-$$.err"
  _pw_node_out="$_pw_capdir/pw-node-ver-$$.out"; _pw_node_err="$_pw_capdir/pw-node-ver-$$.err"
  _pw_cli_out="$_pw_capdir/pw-cli-ver-$$.out"; _pw_cli_err="$_pw_capdir/pw-cli-ver-$$.err"
  _pw_probe_err="$_pw_capdir/pw-probe-$$.err"
  hash -r
  _pw_npm_prefix=""
  _pw_npm_prefix_bad=""
  _pw_mise_bin=""
  _pw_mise_cli=""
  _pw_mise_cli_bad=""
  # H2 guard: $root must be a usable dir — `cd ""` is a silent no-op in
  # bash, so an empty $root would pin the resolvers below to the
  # invoker's cwd instead of failing (and an unset $root would abort
  # under set -u). With a bad $root the resolvers are skipped outright
  # and the M4 diagnostic below fires naming $root; the M1/H3 checks
  # downstream still fail safe on whatever is on PATH.
  _pw_root_ok=1
  if [[ -z "${root:-}" || ! -d "$root" ]]; then
    printf 'ERROR: $root is not a usable directory ("%s") — skipping the cwd-pinned resolvers below; the M4 diagnostic names the failed sources.\n' "${root-<unset>}" >&2
    _pw_root_ok=0
  fi
  # Probe dir (H3/L-D/L-H): created ONCE, up front, and reused by the
  # H1 node check, the M1 maybe-shim probe and the H3 CLI probe — all
  # three must run from a temp cwd outside the mise config chain, never
  # the script cwd (where shims work). TMPDIR is forced to /tmp for the
  # mktemp call: a TMPDIR pointing inside the mise chain (or the repo)
  # would make the probe test the wrong cwd class. If the dir lands
  # under $root anyway, fall back to $work (also a temp dir under /tmp).
  # A kill between mktemp and the removal after the --help probe leaks
  # one /tmp dir — accepted, /tmp is scratch.
  _pw_probe_dir="$(TMPDIR=/tmp mktemp -d 2>/dev/null || true)"
  if [[ -z "$_pw_probe_dir" ]]; then
    printf 'WARNING: could not create a temp probe dir — probes run from the temp work dir instead (weaker shim check).\n' >&2
    _pw_probe_dir="$work"
  else
    _pw_root_norm=""
    if [[ "$_pw_root_ok" == 1 && -n "${root:-}" && "$root" != "/" ]]; then _pw_root_norm="${root%/}"; fi
    if [[ -n "$_pw_root_norm" && ( "$_pw_probe_dir" == "$_pw_root_norm" || "$_pw_probe_dir" == "$_pw_root_norm"/* ) ]]; then
      printf 'WARNING: temp probe dir %s is under the repo dir %s — falling back to the temp work dir (weaker shim check).\n' "$_pw_probe_dir" "$root" >&2
      _pw_probe_dir="$work"
    fi
  fi
  _pw_cd_failed=0
  if [[ "$_pw_root_ok" == 1 ]] && command -v npm >/dev/null 2>&1; then
    # H2: resolve from the REPO dir, not the invoker's cwd — `npm config
    # get prefix` reads .npmrc from the cwd, and `mise which` exits
    # non-zero unless the tool resolves in the cwd. The subshell cd pins
    # both to $root; the outer cwd is untouched. (L-I: a failed cd warns
    # by name instead of vanishing into `|| true`; M-C: bounded to 30 s;
    # L-C: stderr is captured, not discarded.)
    # H1: the cd is tested in the PARENT first — a cd failure inside the
    # probe subshell would set no flag the parent can see, and M4 would
    # misreport it as "<empty>". _pw_cd_failed=1 names it there.
    _pw_npm_rc=0
    if ! _pw_cd_ok "$root"; then
      printf 'WARNING: could not cd to repo dir "%s" for `npm config get prefix` — resolvers below use an empty prefix.\n' "$root" >&2
      _pw_npm_rc=98; _pw_cd_failed=1
    else
      (cd "$root" && _pw_timeout30 npm config get prefix 2>"$_pw_npm_err") >"$_pw_npm_out" || _pw_npm_rc=$?
    fi
    _pw_npm_prefix="$(head -n 1 -- "$_pw_npm_out" 2>/dev/null || true)"
    if [[ "$_pw_npm_rc" == 124 ]]; then
      printf 'WARNING: `npm config get prefix` timed out after 30 s (or exited 124) — treating the prefix as empty.\n' >&2
    elif [[ "$_pw_npm_rc" == 98 ]]; then
      : # cd failure already warned above; prefix stays empty
    elif [[ -z "$_pw_npm_prefix" && -s "$_pw_npm_err" ]]; then
      printf 'WARNING: `npm config get prefix` failed: %s\n' "$(_pw_first_line "$_pw_npm_err")" >&2
    fi
    # L3: the prefix must be ABSOLUTE — a relative prefix would
    # re-resolve against whatever cwd the script is in mid-section
    # (/tmp during the probe below). A prefix outside $HOME is FINE
    # (system node lives at /usr on this VM) — only relative is rejected.
    case "$_pw_npm_prefix" in
      /*) ;;
      "") ;;
      *) printf 'WARNING: npm prefix "%s" is relative — ignoring it (a relative prefix re-resolves against the cwd).\n' "$_pw_npm_prefix" >&2; _pw_npm_prefix_bad="$_pw_npm_prefix"; _pw_npm_prefix="" ;;
    esac
    # L-G: normalise trailing slashes — a prefix of "/opt/foo/" would
    # otherwise build "/opt/foo//bin" and break the M2 comparison.
    while [[ "$_pw_npm_prefix" == */ && "$_pw_npm_prefix" != "/" ]]; do _pw_npm_prefix="${_pw_npm_prefix%/}"; done
  fi
  # Pick the dir holding the REAL playwright-cli: the npm-prefix bin
  # first, `mise which` as fallback. Prepend it whenever it holds an
  # executable CLI — whether or not it also holds node. (Round-3 QC:
  # the old elif fell through to the mise branch when node was missing
  # from the npm bin and prepended NOTHING, even when a real node was
  # already on PATH or available via `mise which node` — the CLI was
  # then unfindable although both real binaries existed. Reproduced
  # with stub npm/mise: npm bin with CLI but no node + real system
  # node, and mise CLI bin with no node + real mise node elsewhere,
  # both left `command -v playwright-cli` failing.)
  _pw_cli_dir=""
  if [[ -n "$_pw_npm_prefix" && -x "$_pw_npm_prefix/bin/playwright-cli" ]]; then
    _pw_cli_dir="$_pw_npm_prefix/bin"
  elif [[ "$_pw_root_ok" == 1 ]] && command -v mise >/dev/null 2>&1; then
    _pw_mise_cli_rc=0
    if ! _pw_cd_ok "$root"; then
      printf 'WARNING: could not cd to repo dir "%s" for `mise which playwright-cli` — the mise fallback is skipped.\n' "$root" >&2
      _pw_mise_cli_rc=98; _pw_cd_failed=1
    else
      (cd "$root" && _pw_timeout30 mise which playwright-cli 2>"$_pw_mise_cli_err") >"$_pw_mise_cli_out" || _pw_mise_cli_rc=$?
    fi
    _pw_mise_cli="$(head -n 1 -- "$_pw_mise_cli_out" 2>/dev/null || true)"
    if [[ "$_pw_mise_cli_rc" == 124 ]]; then
      printf 'WARNING: `mise which playwright-cli` timed out after 30 s (or exited 124) — treating it as empty.\n' >&2
    elif [[ "$_pw_mise_cli_rc" == 98 ]]; then
      : # cd failure already warned above; result stays empty
    elif [[ -z "$_pw_mise_cli" && -s "$_pw_mise_cli_err" ]]; then
      printf 'WARNING: `mise which playwright-cli` failed: %s\n' "$(_pw_first_line "$_pw_mise_cli_err")" >&2
    fi
    case "$_pw_mise_cli" in
      /*) ;;
      "") ;;
      *) printf 'WARNING: `mise which playwright-cli` returned a relative path "%s" — ignoring it.\n' "$_pw_mise_cli" >&2; _pw_mise_cli_bad="$_pw_mise_cli"; _pw_mise_cli="" ;;
    esac
    if [[ -n "$_pw_mise_cli" && -x "$_pw_mise_cli" ]]; then
      _pw_mise_bin="$(dirname -- "$_pw_mise_cli")"
      _pw_cli_dir="$_pw_mise_bin"
    fi
  fi
  # L-G: normalise trailing slashes on the selected dir — a trailing
  # slash would otherwise break the M2 comparison below.
  while [[ "$_pw_cli_dir" == */ && "$_pw_cli_dir" != "/" ]]; do _pw_cli_dir="${_pw_cli_dir%/}"; done
  if [[ -n "$_pw_cli_dir" ]]; then
    PATH="$_pw_cli_dir:$PATH"; hash -r
    if [[ -x "$_pw_cli_dir/node" ]]; then
      printf 'Playwright CLI + node resolved to real binaries: %s (mise shim bypassed — the shim fails from /tmp cwds)\n' "$_pw_cli_dir"
    else
      printf 'Playwright CLI resolved to real binary: %s/playwright-cli (mise shim bypassed — the shim fails from /tmp cwds; node resolved separately below if needed)\n' "$_pw_cli_dir"
    fi
  else
    # M4: ONE diagnostic line naming both attempted sources and their
    # (empty) results, before the existing UNVERIFIED path below.
    # (L-E: npm ABSENT is a different fact from npm present with no
    # bin — say which. H1: a failed cd to $root left the tool results
    # empty — say so, instead of printing "<empty>" as if mise had
    # run and returned it.)
    _pw_mise_disp="<mise not installed>"
    if command -v mise >/dev/null 2>&1; then _pw_mise_disp="<empty>"; fi
    [[ -n "$_pw_mise_cli" ]] && _pw_mise_disp="$_pw_mise_cli"
    [[ -n "$_pw_mise_cli_bad" ]] && _pw_mise_disp="<relative path \"$_pw_mise_cli_bad\" — ignored>"
    if [[ "${_pw_cd_failed:-0}" == 1 ]] && command -v mise >/dev/null 2>&1; then _pw_mise_disp="<not run — cd to repo dir failed>"; fi
    if [[ "${_pw_cd_failed:-0}" == 1 ]]; then
      printf 'Playwright CLI resolve: no real binary found — cd to the repo dir failed, so one or both resolvers never ran; see the WARNING above.\n'
    elif ! command -v npm >/dev/null 2>&1; then
      printf 'Playwright CLI resolve: no real binary found — npm is not installed, so no npm prefix was checked; `mise which playwright-cli` (from %s) returned "%s" — proceeding without the PATH prepend.\n' "${root-<unset>}" "$_pw_mise_disp"
    else
      _pw_npm_disp="${_pw_npm_prefix:-<npm not found or empty prefix>}"
      [[ -n "$_pw_npm_prefix_bad" ]] && _pw_npm_disp="<relative prefix \"$_pw_npm_prefix_bad\" — ignored>"
      printf 'Playwright CLI resolve: no real binary found — npm prefix "%s" has no bin/playwright-cli; `mise which playwright-cli` (from %s) returned "%s" — proceeding without the PATH prepend.\n' "$_pw_npm_disp" "${root-<unset>}" "$_pw_mise_disp"
    fi
  fi
  # The CLI is a node script (#!/usr/bin/env node), so a real node must
  # resolve too. If the CLI dir holds one, done. Otherwise try the real
  # node via `mise which node` — its bin dir can differ from the CLI's
  # (separate mise installs). If that fails as well, leave PATH as-is:
  # a real system node may already be on it, and the --help probe below
  # (which executes the CLI under this PATH) reports a broken shebang
  # instead of silently proceeding.
  if [[ -n "$_pw_cli_dir" && ! -x "$_pw_cli_dir/node" ]] && command -v mise >/dev/null 2>&1; then
    _pw_mise_node_rc=0
    if ! _pw_cd_ok "$root"; then
      printf 'WARNING: could not cd to repo dir "%s" for `mise which node` — the mise node fallback is skipped.\n' "$root" >&2
      _pw_mise_node_rc=98; _pw_cd_failed=1
    else
      (cd "$root" && _pw_timeout30 mise which node 2>"$_pw_mise_node_err") >"$_pw_mise_node_out" || _pw_mise_node_rc=$?
    fi
    _pw_mise_node="$(head -n 1 -- "$_pw_mise_node_out" 2>/dev/null || true)"
    if [[ "$_pw_mise_node_rc" == 124 ]]; then
      printf 'WARNING: `mise which node` timed out after 30 s (or exited 124) — treating it as empty.\n' >&2
    elif [[ "$_pw_mise_node_rc" == 98 ]]; then
      : # cd failure already warned above; result stays empty
    elif [[ -z "$_pw_mise_node" && -s "$_pw_mise_node_err" ]]; then
      printf 'WARNING: `mise which node` failed: %s\n' "$(_pw_first_line "$_pw_mise_node_err")" >&2
    fi
    case "$_pw_mise_node" in
      /*) ;;
      "") ;;
      *) printf 'WARNING: `mise which node` returned a relative path "%s" — ignoring it.\n' "$_pw_mise_node" >&2; _pw_mise_node="" ;;
    esac
    if [[ -n "$_pw_mise_node" && -x "$_pw_mise_node" ]]; then
      _pw_mise_node_bin="$(dirname -- "$_pw_mise_node")"
      if [[ "$_pw_mise_node_bin" != "$_pw_cli_dir" ]]; then
        PATH="$_pw_mise_node_bin:$PATH"; hash -r
        printf 'Node resolved to real binary: %s/node (mise shim bypassed — the shim fails from /tmp cwds)\n' "$_pw_mise_node_bin"
      fi
    fi
  fi
  # (M-A: no `mise reshim` here. It only ran when the CLI was still
  # missing, so its only product was a fresh mise shim — which the M1
  # check below rejects. A reshim step and a shim rejection cannot both
  # be right; the M4 diagnostic above is the accurate failure path.)
  # M2: print what the prepends actually resolved to, and assert the CLI
  # is the SELECTED one — the node-dir prepend above runs AFTER the
  # CLI-dir prepend, so a playwright-cli inside the node dir would
  # shadow the selected binary (the != guard only prevented a duplicate
  # prepend). If shadowed, re-prepend the CLI dir so the selected binary
  # wins, and re-check; a still-wrong resolution fails loud.
  _pw_cli_resolved="$(command -v playwright-cli 2>/dev/null || true)"
  _pw_node_resolved="$(command -v node 2>/dev/null || true)"
  printf 'Playwright CLI resolves to: %s\n' "${_pw_cli_resolved:-<not found>}"
  printf 'Node resolves to: %s\n' "${_pw_node_resolved:-<not found>}"
  _pw_resolve_ok=1
  # L-G: compare with _pw_same_file (canonical path or inode), not raw
  # strings — a node-dir CLI that is a symlink/hardlink to the selected
  # binary is the SAME file, not a shadow.
  if [[ -n "$_pw_cli_dir" && -n "$_pw_cli_resolved" ]] && ! _pw_same_file "$_pw_cli_resolved" "$_pw_cli_dir/playwright-cli"; then
    printf 'WARNING: the node-dir prepend shadowed the selected CLI (%s is not %s/playwright-cli) — re-prepending the CLI dir so the selected binary wins.\n' "$_pw_cli_resolved" "$_pw_cli_dir" >&2
    PATH="$_pw_cli_dir:$PATH"; hash -r
    _pw_cli_resolved="$(command -v playwright-cli 2>/dev/null || true)"
    _pw_node_resolved="$(command -v node 2>/dev/null || true)"
    printf 'Playwright CLI resolves to: %s\n' "${_pw_cli_resolved:-<not found>}"
    printf 'Node resolves to: %s\n' "${_pw_node_resolved:-<not found>}"
    if ! _pw_same_file "$_pw_cli_resolved" "$_pw_cli_dir/playwright-cli"; then
      fail "Playwright CLI still does not resolve to the selected binary $_pw_cli_dir/playwright-cli (resolves to ${_pw_cli_resolved:-<not found>}) — eyes step not run"
      _pw_resolve_ok=0
    fi
  fi
  # M1: canonicalise the resolved paths and reject shims. A shim (or a
  # symlink into a shims dir) passes -x, so executability never proved
  # the binary was real — that was the hole. If no canonicaliser is
  # available, the temp-cwd execution probe below is the minimum shim
  # check (H3 — already being added).
  # (M-E: the rejection is ANCHORED to the real mise shims dir —
  # ${MISE_DATA_DIR:-~/.local/share/mise}/shims — not to any path
  # component named "shims" (e.g. /opt/<team>/shims/bin is a real
  # install, not a mise shim). A canonical path under some OTHER
  # shims-like dir is only a SUSPECT: it is rejected only if it also
  # fails the temp-cwd execution probe just below (M-E fallback).
  # Canonicaliser (macOS phase, D12): _pw_canon tries GNU readlink -f,
  # then python3 realpath (BSD readlink has no -f). The gate below tests
  # whether either exists; when neither does, M1 is skipped and only the
  # execution probe runs. _pw_canon never returns empty for a non-empty
  # input (it falls back to the input), so there is no per-path
  # "could not canonicalise" warning anymore — an unresolved path is
  # still compared against the shims anchor, and the probe is the
  # backstop for a symlinked path it cannot see through.)
  _pw_canon_ok=0
  if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1; then _pw_canon_ok=1;
  elif command -v python3 >/dev/null 2>&1; then _pw_canon_ok=1; fi
  _pw_cli_maybe_shim=0; _pw_node_maybe_shim=0
  if [[ "$_pw_resolve_ok" == 1 && "$_pw_canon_ok" == 1 ]]; then
    _pw_cli_real=""; _pw_node_real=""
    [[ -n "$_pw_cli_resolved" ]] && _pw_cli_real="$(_pw_canon "$_pw_cli_resolved")"
    [[ -n "$_pw_node_resolved" ]] && _pw_node_real="$(_pw_canon "$_pw_node_resolved")"
    [[ -n "$_pw_cli_real" ]] && printf 'Playwright CLI canonical path: %s\n' "$_pw_cli_real"
    [[ -n "$_pw_node_real" ]] && printf 'Node canonical path: %s\n' "$_pw_node_real"
    # M2: the anchor is the CANONICAL mise shims dir. _pw_mise_data is
    # canonicalised (a symlinked mise data dir must still match), a
    # leading ~ is expanded, and HOME unset/empty leaves the anchor
    # undetermined (probe decides) instead of aborting under set -u.
    # L7: the anchor's effective value is logged once, so a
    # misconfigured MISE_DATA_DIR is visible.
    _pw_mise_data="${MISE_DATA_DIR:-}"
    if [[ -n "$_pw_mise_data" && "$_pw_mise_data" == "~/"* ]]; then _pw_mise_data="${HOME:-}/${_pw_mise_data:2}"; fi
    if [[ -z "$_pw_mise_data" ]]; then
      if [[ -n "${HOME:-}" ]]; then _pw_mise_data="$HOME/.local/share/mise"; else _pw_mise_data=""; fi
    fi
    if [[ -n "$_pw_mise_data" ]]; then _pw_mise_data="$(_pw_canon "$_pw_mise_data")"; fi
    while [[ "$_pw_mise_data" == */ && "$_pw_mise_data" != "/" ]]; do _pw_mise_data="${_pw_mise_data%/}"; done
    _pw_mise_shims=""
    case "$_pw_mise_data" in /*) _pw_mise_shims="$_pw_mise_data/shims" ;; esac
    printf 'Mise shims dir (anchor): %s\n' "${_pw_mise_shims:-<undetermined — probe decides>}"
    _pw_cli_is_shim=0; _pw_node_is_shim=0
    if [[ -n "$_pw_cli_real" ]]; then
      if [[ -n "$_pw_mise_shims" && ( "$_pw_cli_real" == "$_pw_mise_shims" || "$_pw_cli_real" == "$_pw_mise_shims"/* ) ]]; then
        _pw_cli_is_shim=1
      elif [[ "$_pw_cli_real" == */shims/* || "$_pw_cli_real" == */shims ]]; then
        _pw_cli_maybe_shim=1
      fi
    fi
    if [[ "$_pw_cli_is_shim" == 1 ]]; then
      # M2 probe backstop: the location says shim, but a real binary
      # hand-placed under the shims dir would execute — probe it first.
      # Only a probe that RUNS and FAILS confirms the rejection; a
      # successful execution exonerates it. A cd failure is
      # inconclusive — do not reject on it (H1), the H3 probe below is
      # the backstop.
      _pw_anchor_rc=0; _pw_anchor_ok=0
      if _pw_cd_ok "$_pw_probe_dir"; then
        (cd "$_pw_probe_dir" && _pw_timeout30 "$_pw_cli_resolved" --version >/dev/null 2>"$_pw_probe_err") || _pw_anchor_rc=$?
        if [[ "$_pw_anchor_rc" == 0 ]]; then _pw_anchor_ok=1; fi
      else
        printf 'WARNING: anchored-shim probe inconclusive (could not cd to probe dir "%s") — not rejecting on location alone.\n' "$_pw_probe_dir" >&2
        _pw_anchor_rc=98
      fi
      if [[ "$_pw_anchor_ok" == 1 ]]; then
        printf 'Playwright CLI at %s executes from the temp probe dir despite the shims location — treating it as a real binary, not a shim.\n' "$_pw_cli_real"
        _pw_cli_is_shim=0
      elif [[ "$_pw_anchor_rc" == 98 ]]; then
        _pw_cli_is_shim=0
      fi
    fi
    if [[ "$_pw_cli_is_shim" == 1 ]]; then
      fail "Playwright CLI canonical path $_pw_cli_real is under a shims dir — a shim passing -x is not a real binary; eyes step not run"
      _pw_resolve_ok=0
    fi
    if [[ "$_pw_resolve_ok" == 1 && -n "$_pw_node_real" ]]; then
      if [[ -n "$_pw_mise_shims" && ( "$_pw_node_real" == "$_pw_mise_shims" || "$_pw_node_real" == "$_pw_mise_shims"/* ) ]]; then
        _pw_node_is_shim=1
      elif [[ "$_pw_node_real" == */shims/* || "$_pw_node_real" == */shims ]]; then
        _pw_node_maybe_shim=1
      fi
    fi
    if [[ "$_pw_resolve_ok" == 1 && "$_pw_node_is_shim" == 1 ]]; then
      _pw_anchor_rc=0; _pw_anchor_ok=0
      if _pw_cd_ok "$_pw_probe_dir"; then
        (cd "$_pw_probe_dir" && _pw_timeout30 "$_pw_node_resolved" --version >/dev/null 2>"$_pw_probe_err") || _pw_anchor_rc=$?
        if [[ "$_pw_anchor_rc" == 0 ]]; then _pw_anchor_ok=1; fi
      else
        printf 'WARNING: anchored-shim probe inconclusive (could not cd to probe dir "%s") — not rejecting on location alone.\n' "$_pw_probe_dir" >&2
        _pw_anchor_rc=98
      fi
      if [[ "$_pw_anchor_ok" == 1 ]]; then
        printf 'Node at %s executes from the temp probe dir despite the shims location — treating it as a real binary, not a shim.\n' "$_pw_node_real"
        _pw_node_is_shim=0
      elif [[ "$_pw_anchor_rc" == 98 ]]; then
        _pw_node_is_shim=0
      fi
    fi
    if [[ "$_pw_resolve_ok" == 1 && "$_pw_node_is_shim" == 1 ]]; then
      fail "Node canonical path $_pw_node_real is under a shims dir — a shim passing -x is not a real binary; eyes step not run"
      _pw_resolve_ok=0
    fi
    # M-E fallback: a maybe-shim binary is proven real — or not — by
    # EXECUTING it from the temp probe dir (a mise shim fails there).
    # This probe runs now, before H1, so a rejected maybe-shim still
    # fails with the shim FAIL (and one failure count), not with a
    # misleading "node not found" from H1.
    if [[ "$_pw_resolve_ok" == 1 && ( "$_pw_cli_maybe_shim" == 1 || "$_pw_node_maybe_shim" == 1 ) ]]; then
      if [[ "$_pw_cli_maybe_shim" == 1 ]]; then
        _pw_probe_rc=0
        if ! _pw_cd_ok "$_pw_probe_dir"; then
          printf 'WARNING: maybe-shim probe inconclusive (could not cd to probe dir "%s") — not rejecting; the execution probe below is the backstop.\n' "$_pw_probe_dir" >&2
          _pw_probe_rc=98
        else
          (cd "$_pw_probe_dir" && _pw_timeout30 "$_pw_cli_resolved" --version >/dev/null 2>"$_pw_probe_err") || _pw_probe_rc=$?
        fi
        if [[ "$_pw_probe_rc" == 98 ]]; then
          : # inconclusive — do not reject on a probe that never ran
        elif [[ "$_pw_probe_rc" == 124 ]]; then
          printf 'WARNING: Playwright CLI --version from the temp probe dir timed out after 30 s (or exited 124) — a timeout is not evidence of a shim; not rejecting.\n' >&2
        elif [[ "$_pw_probe_rc" != 0 ]]; then
          # H2: only assert "shim" when the evidence supports it — the
          # failure text names a shim. Any other exec failure is a
          # broken binary, not a shim verdict; the H3 probe below
          # reports it with the right reason.
          if [[ -s "$_pw_probe_err" ]] && grep -qi 'shim' "$_pw_probe_err"; then
            printf 'WARNING: Playwright CLI --version from the temp probe dir failed: %s\n' "$(_pw_first_line "$_pw_probe_err")" >&2
            fail "Playwright CLI canonical path $_pw_cli_real is under a shims dir — a shim passing -x is not a real binary; eyes step not run"
            _pw_resolve_ok=0
          else
            printf 'WARNING: Playwright CLI --version from the temp probe dir failed (exit %s)%s — not a shim verdict; the execution probe below reports it.\n' "$_pw_probe_rc" "$([[ -s "$_pw_probe_err" ]] && printf ': %s' "$(_pw_first_line "$_pw_probe_err")")" >&2
          fi
        fi
      fi
      if [[ "$_pw_resolve_ok" == 1 && "$_pw_node_maybe_shim" == 1 ]]; then
        _pw_probe_rc=0
        if ! _pw_cd_ok "$_pw_probe_dir"; then
          printf 'WARNING: maybe-shim probe inconclusive (could not cd to probe dir "%s") — not rejecting; the execution probe below is the backstop.\n' "$_pw_probe_dir" >&2
          _pw_probe_rc=98
        else
          (cd "$_pw_probe_dir" && _pw_timeout30 "$_pw_node_resolved" --version >/dev/null 2>"$_pw_probe_err") || _pw_probe_rc=$?
        fi
        if [[ "$_pw_probe_rc" == 98 ]]; then
          : # inconclusive — do not reject on a probe that never ran
        elif [[ "$_pw_probe_rc" == 124 ]]; then
          printf 'WARNING: Node --version from the temp probe dir timed out after 30 s (or exited 124) — a timeout is not evidence of a shim; not rejecting.\n' >&2
        elif [[ "$_pw_probe_rc" != 0 ]]; then
          if [[ -s "$_pw_probe_err" ]] && grep -qi 'shim' "$_pw_probe_err"; then
            printf 'WARNING: Node --version from the temp probe dir failed: %s\n' "$(_pw_first_line "$_pw_probe_err")" >&2
            fail "Node canonical path $_pw_node_real is under a shims dir — a shim passing -x is not a real binary; eyes step not run"
            _pw_resolve_ok=0
          else
            printf 'WARNING: Node --version from the temp probe dir failed (exit %s)%s — not a shim verdict; the execution probe below reports it.\n' "$_pw_probe_rc" "$([[ -s "$_pw_probe_err" ]] && printf ': %s' "$(_pw_first_line "$_pw_probe_err")")" >&2
          fi
        fi
      fi
    fi
  elif [[ "$_pw_resolve_ok" == 1 ]]; then
    printf 'WARNING: no canonicaliser available (neither readlink -f nor python3 realpath) — the temp-cwd execution probe below is the only shim check (M1 fallback).\n' >&2
  fi
  # H1: after BOTH prepends, the node that will run the CLI must be
  # Node 22+ — the kit's hard gate (same as §9). Fail LOUD: a too-old
  # (or missing/unparseable) post-prepend node fails the run and the
  # eyes step is not run on it. (M5: the resolved node + CLI versions
  # are logged here and at the probe.)
  if [[ "$_pw_resolve_ok" == 1 ]]; then
    # L-D: run from the probe temp dir, not the script cwd — a shim
    # node reports v22+ from the repo dir and fails from /tmp. M-C:
    # bounded to 30 s; L-C: stderr captured, first line printed.
    # H1: a failed cd is INCONCLUSIVE, never "node not found" — the
    # probe never ran, so nothing about node is known.
    _pw_node_ver=""; _pw_node_rc=0
    if ! _pw_cd_ok "$_pw_probe_dir"; then
      printf 'WARNING: node --version probe inconclusive (could not cd to probe dir "%s") — cannot confirm Node 22+.\n' "$_pw_probe_dir" >&2
      _pw_node_rc=98
    else
      (cd "$_pw_probe_dir" && _pw_timeout30 node --version 2>"$_pw_node_err") >"$_pw_node_out" || _pw_node_rc=$?
    fi
    _pw_node_ver="$(head -n 1 -- "$_pw_node_out" 2>/dev/null || true)"
    if [[ "$_pw_node_rc" == 124 ]]; then
      printf 'WARNING: node --version timed out after 30 s (or exited 124) from the temp probe dir — cannot confirm Node 22+.\n' >&2
    elif [[ "$_pw_node_rc" == 98 ]]; then
      : # cd failure already warned above; version stays empty
    elif [[ "$_pw_node_rc" != 0 && -s "$_pw_node_err" ]]; then
      printf 'WARNING: node --version failed (exit %s): %s\n' "$_pw_node_rc" "$(_pw_first_line "$_pw_node_err")" >&2
    fi
    printf 'Node after PATH prepend: %s (required >= 22)\n' "${_pw_node_ver:-<not found>}"
    _pw_node_major="${_pw_node_ver#v}"; _pw_node_major="${_pw_node_major%%.*}"
    if [[ "$_pw_node_rc" == 98 ]]; then
      fail "node --version probe was inconclusive (could not cd to the temp probe dir) — cannot confirm Node 22+; eyes step not run"
      _pw_resolve_ok=0
    elif [[ -z "$_pw_node_ver" ]]; then
      fail "node not found on PATH after the Playwright PATH prepend — the CLI's #!/usr/bin/env node shebang cannot run; eyes step not run"
      _pw_resolve_ok=0
    elif [[ ! "$_pw_node_major" =~ ^[0-9]+$ ]]; then
      fail "node --version gave an unparseable result ('$_pw_node_ver') after the Playwright PATH prepend — cannot confirm Node 22+; eyes step not run"
      _pw_resolve_ok=0
    elif [[ "10#$_pw_node_major" -lt 22 ]]; then
      fail "Node $_pw_node_ver found after the Playwright PATH prepend; the kit requires Node 22+ (frontend-kit SKILL.md step 0.3; gate.mjs consistency.mjs needs the built-in WebSocket). Eyes step not run on it."
      _pw_resolve_ok=0
    fi
  fi
  # H3: capture the CLI version from a TEMP dir under /tmp (the probe
  # itself — `command -v` proves findable, not runnable, and the
  # invoker's cwd is inside the mise config chain, where shims work).
  # The dir is created once, reused for the --help probe below, and
  # removed there. If mktemp fails, $work (also a temp dir under /tmp)
  # is the fallback probe cwd. The captured output also records the CLI
  # version (H1/M5): a version other than the pin is a LOUD warning,
  # not a failure — drift, not a proven breakage (the CLI downloads
  # its own browser revision).
  # L-B: single pin source — read the pin from install.sh's
  # PLAYWRIGHT_CLI_VERSION assignment (same source install.sh uses),
  # falling back to the hardcoded literal if install.sh cannot be read
  # (e.g. the QC harness extracts this block standalone). The pin VALUE
  # is unchanged (0.1.24); only the source is single.
  # M1: the fallback is a warn() (stderr + counted), not a quiet
  # stdout line — a stale fallback must be visible. The matcher
  # accepts `export`, spaces around `=`, and a -beta / 4th-component
  # suffix (the leading dotted-triple is the pin; a suffix warns).
  # The file must also contain a second kit marker, so a stale or
  # foreign install.sh cannot silently supply the pin.
  _pw_cli_pin="0.1.24"
  _pw_cli_pin_src="hardcoded fallback"
  _pw_pin_file="${root:-}/install.sh"
  _pw_pin_line=""
  if [[ -n "${_pw_pin_file}" && -f "$_pw_pin_file" ]] && grep -q 'frontend-agent-kit' "$_pw_pin_file" 2>/dev/null; then
    _pw_pin_line="$(grep -m1 -E '^[[:space:]]*(export[[:space:]]+)?PLAYWRIGHT_CLI_VERSION[[:space:]]*=[[:space:]]*"[^"]*"' "$_pw_pin_file" 2>/dev/null || true)"
  fi
  _pw_pin_re='PLAYWRIGHT_CLI_VERSION[[:space:]]*=[[:space:]]*"([0-9]+\.[0-9]+\.[0-9]+)([^"]*)"'
  if [[ "$_pw_pin_line" =~ $_pw_pin_re ]]; then
    _pw_cli_pin="${BASH_REMATCH[1]}"; _pw_cli_pin_src="$_pw_pin_file"
    if [[ -n "${BASH_REMATCH[2]}" ]]; then
      warn "Playwright CLI pin in $_pw_pin_file has a suffix '${BASH_REMATCH[2]}' after the version — using the leading dotted-triple $_pw_cli_pin"
    fi
  else
    warn "Playwright CLI pin fell back to the hardcoded $_pw_cli_pin ($_pw_pin_file could not be read, lacked the kit marker, or had no PLAYWRIGHT_CLI_VERSION assignment) — re-pin install.sh to change it"
  fi
  printf 'Playwright CLI pin: %s (from %s)\n' "$_pw_cli_pin" "$_pw_cli_pin_src"
  _pw_cli_ver=""
  if [[ "$_pw_resolve_ok" == 1 ]] && command -v playwright-cli >/dev/null 2>&1; then
    # _pw_probe_dir was created up front (before M1) and reused here;
    # re-create it only if something cleared it.
    if [[ -z "${_pw_probe_dir:-}" ]]; then
      _pw_probe_dir="$(TMPDIR=/tmp mktemp -d 2>/dev/null || true)"
      [[ -z "$_pw_probe_dir" ]] && _pw_probe_dir="$work"
    fi
    # M-C/L-C: bounded to 30 s; stderr captured, first line printed on
    # failure (a non-executing CLI's real error used to be discarded).
    # H1: a failed cd is INCONCLUSIVE, never "does not execute" — the
    # probe never ran.
    _pw_cli_rc=0
    if ! _pw_cd_ok "$_pw_probe_dir"; then
      printf 'WARNING: `playwright-cli --version` probe inconclusive (could not cd to probe dir "%s").\n' "$_pw_probe_dir" >&2
      _pw_cli_rc=98
    else
      (cd "$_pw_probe_dir" && _pw_timeout30 playwright-cli --version 2>"$_pw_cli_err") >"$_pw_cli_out" || _pw_cli_rc=$?
    fi
    _pw_cli_ver="$(head -n 1 -- "$_pw_cli_out" 2>/dev/null || true)"
    if [[ "$_pw_cli_rc" == 124 ]]; then
      printf 'WARNING: `playwright-cli --version` timed out after 30 s (or exited 124) from the temp probe dir.\n' >&2
    elif [[ "$_pw_cli_rc" == 98 ]]; then
      : # cd failure already warned above; version stays empty
    elif [[ "$_pw_cli_rc" != 0 && -s "$_pw_cli_err" ]]; then
      printf 'WARNING: `playwright-cli --version` failed (exit %s): %s\n' "$_pw_cli_rc" "$(_pw_first_line "$_pw_cli_err")" >&2
    fi
    if [[ -n "$_pw_cli_ver" ]]; then
      printf 'Playwright CLI version: %s (pin %s)\n' "$_pw_cli_ver" "$_pw_cli_pin"
      # Exact match on the first dotted-triple in the output (H1): a
      # substring match would also accept 0.1.240 for pin 0.1.24, while
      # "playwright-cli 0.1.24" / "0.1.24-beta" still match.
      _pw_cli_ver_num=""
      if [[ "$_pw_cli_ver" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then _pw_cli_ver_num="${BASH_REMATCH[1]}"; fi
      if [[ "$_pw_cli_ver_num" != "$_pw_cli_pin" ]]; then
        warn "Playwright CLI version $_pw_cli_ver does NOT match the pinned $_pw_cli_pin — drift, not a proven breakage; continuing (the CLI downloads its own browser revision)"
      fi
    elif [[ "$_pw_cli_rc" == 98 ]]; then
      printf 'WARNING: playwright-cli probe was inconclusive (could not cd to the temp probe dir) — the --help probe below will report the same.\n' >&2
    else
      printf 'WARNING: playwright-cli is on PATH but does not execute from a temp dir (`playwright-cli --version` failed there — usually the #!/usr/bin/env node shebang resolving to a mise shim). The --help probe below will fail the same way.\n' >&2
    fi
  fi
  # Probe scratch cleanup: the capture files go with the scratch dir.
  # (The probe dir itself is NOT removed here — the --help probe below
  # still needs it; it is removed there.)
  rm -f -- "$_pw_npm_out" "$_pw_npm_err" "$_pw_mise_cli_out" "$_pw_mise_cli_err" "$_pw_mise_node_out" "$_pw_mise_node_err" "$_pw_node_out" "$_pw_node_err" "$_pw_cli_out" "$_pw_cli_err" "$_pw_probe_err"
  if [[ "$_pw_capdir_own" == 1 && -n "$_pw_capdir" ]]; then rm -rf -- "$_pw_capdir"; fi
fi
if [[ "$eyes_skipped" == 1 ]]; then
  pending_msg "Playwright eyes skipped at install (--skip-eyes) — eyes step not run (no browser expected). Run: npm install -g @playwright/cli@0.1.24, then playwright-cli install-browser chrome-for-testing"
elif [[ "${_pw_resolve_ok:-1}" == 0 ]]; then
  : # the resolve block above already failed loudly (shim / wrong binary / pre-22 node) — eyes not run on it
elif command -v playwright-cli >/dev/null 2>&1; then
  # H3: --help probe from a temp dir under /tmp (see the resolve block):
  # the invoker's cwd is inside the mise config chain, where shims work
  # — the probe must test the cwd class the eyes loop runs from ($work).
  # _pw_probe_dir was created by the resolve block; fall back to $work
  # (also a temp dir under /tmp) if it is empty.
  _pw_probe_cwd="${_pw_probe_dir:-$work}"
  # M-C/L-C: the --help probe is bounded to 30 s and its stderr is
  # captured — a failing CLI's real error is printed (first line) with
  # the failure instead of discarded. A timeout (exit 124) is named as
  # a timeout, not a generic failure. H1: a failed cd is INCONCLUSIVE,
  # never "failed" — the probe never ran.
  _pw_help_err="$work/pw-help-$$.err"
  _pw_help_rc=0
  if ! _pw_cd_ok "$_pw_probe_cwd"; then
    printf 'WARNING: `playwright-cli --help` probe inconclusive (could not cd to probe dir "%s").\n' "$_pw_probe_cwd" >&2
    _pw_help_rc=98
  else
    (cd "$_pw_probe_cwd" && _pw_timeout30 playwright-cli --help >/dev/null 2>"$_pw_help_err") || _pw_help_rc=$?
  fi
  if [[ "$_pw_help_rc" == 0 ]]; then ok "playwright-cli --help runs (from temp dir $_pw_probe_cwd; version ${_pw_cli_ver:-version not reported})";
  else
    _pw_help_msg="playwright-cli --help failed (from temp dir $_pw_probe_cwd)"
    if [[ "$_pw_help_rc" == 98 ]]; then _pw_help_msg="playwright-cli --help probe was inconclusive (could not cd to temp dir $_pw_probe_cwd)";
    elif [[ "$_pw_help_rc" == 124 ]]; then _pw_help_msg="$_pw_help_msg — timed out after 30 s (or exited 124)";
    elif [[ -s "$_pw_help_err" ]]; then _pw_help_msg="$_pw_help_msg: $(_pw_first_line "$_pw_help_err")"; fi
    fail "$_pw_help_msg"
  fi
  rm -f -- "$_pw_help_err"
  if [[ -n "${_pw_probe_dir:-}" && "$_pw_probe_dir" != "$work" ]]; then rm -rf -- "$_pw_probe_dir"; fi
  # Serve the fixture over http (module scripts and fetch do not run on file://).
  # The CLI writes .playwright-cli/ into the cwd, so run it from inside the
  # temp dir to keep the repo clean.
  # Q-1 redo (2026-11-10; FIX2-VERIFY-A base, FIX2-VERIFY-B spec pass):
  # the old code did `sleep 1` and then ran the CLI once, discarding ALL
  # of its output (>/dev/null 2>&1 on every command). The eyes step failed
  # 5/14 runs on a working loop (w-qc-lead Q-1) with zero diagnostic — the
  # session vanished between `open` and `resize` (reproduced 2/8 by B with
  # output preserved: open exit 0, then resize "The browser 'verify' is
  # not open"). Root cause undetermined (daemon stderr empty — truncated
  # on each daemon start) — see w-fix2-verify-b.md §4. Behaviour now:
  # (a) AT MOST 2 attempts; each attempt gets a FRESH session
  # (-s=verify-<pid>-a<N>, never reused across runs or attempts), a FRESH
  # port and a FRESH http server, so a dead session/port cannot poison
  # the retry; (b) the server is waited on (raw TCP connect poll, up to
  # 10 s — no proxy involved, no fixed `sleep 1`); (c) every eyes command
  # writes stdout+stderr to $work/eyes-attempt-N.log (nothing is
  # discarded), and on final failure ALL attempt logs print to stderr,
  # so a failure carries its diagnostic; (d) the fixture ships a real
  # favicon.ico, killing the deterministic favicon 404 console error.
  shot="$work/shot-390.png"
  eyes_ok=0
  eyes_browser=""
  eyes_attempts=0
  eyes_session=""
  eyes_port=""
  _server_pid=""
  # The CLI's default `open` wants system Google Chrome (/opt/google/chrome).
  # The kit installs chrome-for-testing via `playwright-cli install-browser`,
  # reached as --browser=chromium — try that first, then the default.
  for _attempt in 1 2; do
    eyes_attempts="$_attempt"
    _session="verify-$$-a$_attempt"
    _log="$work/eyes-attempt-$_attempt.log"
    rm -f -- "$shot"
    : > "$_log"
    # Fresh port + fresh server per attempt (Q-1: never the same dead session/port).
    _port="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')"
    eyes_port="$_port"
    python3 -m http.server "$_port" --bind 127.0.0.1 --directory "$work" >"$work/eyes-attempt-$_attempt-server.log" 2>&1 &
    _server_pid=$!
    # Wait for the server to answer: raw TCP connect, no proxy involved.
    # Arithmetic loop, not `seq` (GNU coreutils; stock macOS has no seq).
    _server_ready=0
    for ((_i=1; _i<=50; _i++)); do
      if python3 -c 'import socket,sys; s=socket.create_connection(("127.0.0.1",int(sys.argv[1])),timeout=2); s.close()' "$_port" >/dev/null 2>&1; then _server_ready=1; break; fi
      sleep 0.2
    done
    _opened=0
    if [[ "$_server_ready" != 1 ]]; then
      printf 'fixture http server on port %s never answered\n' "$_port" >>"$_log"
    elif (cd "$work" && playwright-cli -s="$_session" open --browser=chromium "http://127.0.0.1:$_port/index.html" >>"$_log" 2>&1); then
      eyes_browser="chromium"; _opened=1
    elif (cd "$work" && playwright-cli -s="$_session" open "http://127.0.0.1:$_port/index.html" >>"$_log" 2>&1); then
      eyes_browser="default (system Chrome)"; _opened=1
    fi
    if [[ "$_opened" == 1 ]]; then
      _ok=1
      (cd "$work" && playwright-cli -s="$_session" resize 390 844 >>"$_log" 2>&1) || _ok=0
      (cd "$work" && playwright-cli -s="$_session" screenshot --filename="$shot" >>"$_log" 2>&1) || _ok=0
      if [[ "$_ok" == 1 && -s "$shot" ]]; then eyes_ok=1; eyes_session="$_session"; break; fi
      printf 'eyes attempt %s failed (open/resize/screenshot); retrying with a fresh session/port\n' "$_attempt" >&2
    else
      printf 'eyes attempt %s failed (server/open); retrying with a fresh session/port\n' "$_attempt" >&2
    fi
    (cd "$work" && playwright-cli -s="$_session" close-all >>"$_log" 2>&1) || true
    kill "$_server_pid" 2>/dev/null || true
    wait "$_server_pid" 2>/dev/null || true
    _server_pid=""
  done
  if [[ "$eyes_ok" == 1 ]]; then
    if [[ "$eyes_attempts" -gt 1 ]]; then
      ok "headless screenshot at 390px succeeds via $eyes_browser ($(stat -c%s "$shot" 2>/dev/null || stat -f%z "$shot") bytes) — after $eyes_attempts attempt(s) (Q-1 retry: first attempt(s) flaked)"
    else
      ok "headless screenshot at 390px succeeds via $eyes_browser ($(stat -c%s "$shot" 2>/dev/null || stat -f%z "$shot") bytes)"
    fi
    (cd "$work" && playwright-cli -s="$eyes_session" console >/dev/null 2>&1) && ok "playwright-cli console runs" || warn "playwright-cli console failed (non-fatal)"
    (cd "$work" && playwright-cli -s="$eyes_session" close-all >/dev/null 2>&1) || true
  else
    fail "Playwright screenshot at 390px failed after $eyes_attempts attempt(s) (open/resize/screenshot; fresh session+port each attempt — last port $eyes_port). The eyes step is broken — see A7: do not grade blind. CLI output from all attempts:"
    for ((_a=1; _a<=eyes_attempts; _a++)); do
      printf -- '--- eyes attempt %s CLI log ---\n' "$_a" >&2
      cat "$work/eyes-attempt-$_a.log" >&2 || true
      if [[ -s "$work/eyes-attempt-$_a-server.log" ]]; then
        printf -- '--- eyes attempt %s http-server log ---\n' "$_a" >&2
        cat "$work/eyes-attempt-$_a-server.log" >&2 || true
      fi
    done
  fi
  # Cleanup: the success path still has its server running here (failed
  # attempts killed theirs inside the loop); _server_pid is empty then.
  if [[ -n "$_server_pid" ]]; then kill "$_server_pid" 2>/dev/null || true; wait "$_server_pid" 2>/dev/null || true; fi
else
  if [[ "$strict" == 1 ]]; then
    fail "playwright-cli not on PATH. --strict: this is fatal. Install the pinned CLI: npm install -g @playwright/cli@0.1.24, then playwright-cli install-browser chrome-for-testing"
  else
    unverified "playwright-cli not on PATH — eyes step not verified. Install the pinned CLI: npm install -g @playwright/cli@0.1.24, then playwright-cli install-browser chrome-for-testing"
  fi
fi
# Restore PATH (red-team H7) — see the resolve block above. L2:
# sentinel-guarded, so an empty original PATH restores as empty,
# not as unset. The EXIT trap set in the resolve block is the
# backstop for an early exit; this is the normal path.
if [[ -n "${_pw_saved_path_set:-}" ]]; then PATH="$_pw_saved_path"; hash -r; fi
# M-B: unset the EXIT trap now that PATH is restored sequentially —
# the restore above ran BEFORE this unset, so the unset cannot break
# it. No trap is re-armed: $work is not used past this point (§7–§9
# use $refs_dir/$state_dir only — do NOT use $work below here), so it
# is removed eagerly instead of leaving a trap behind.
trap - EXIT
if [[ -n "${work:-}" ]]; then rm -rf -- "$work" 2>/dev/null || printf 'WARNING: could not remove temp work dir %s (leaked).\n' "$work" >&2; fi

# --- 7. Pro Max search smoke (v1 behaviour kept) -----------------------------
if [[ -f "$refs_dir/ui-ux-pro-max/scripts/search.py" ]]; then
  if python3 "$refs_dir/ui-ux-pro-max/scripts/search.py" 'editorial portfolio' --domain style --max-results 1 2>/dev/null | grep -q 'Result 1'; then
    ok "Pro Max search smoke test"
  else
    warn "Pro Max search smoke test did not return 'Result 1' (reference data may be the stale v1 pin)"
  fi
else
  warn "Pro Max reference data not installed ($refs_dir/ui-ux-pro-max/scripts/search.py missing)"
fi

# --- 8. hook / MCP presence (H5/H6) -----------------------------------------
# A skipped or failed best-effort subsystem must be VISIBLE here, never
# silent. Two sources, both reported as PENDING (never a failure — these
# are best-effort subsystems, not loop steps — and never an OK for a
# subsystem that is not there):
#   (a) install.sh records every --skip-* flag in
#       $state_dir/skipped-subsystems.txt (one line per subsystem);
#   (b) live presence: the host's ACTUAL config must contain the
#       registration. An `mcp add` that exited 0 without writing anything
#       (H6 stub-claude repro) leaves no entry here, so it is PENDING,
#       not OK. Where no readable config exists at all, that is reported
#       as PENDING with the reason, not assumed.
if [[ -f "$state_dir/skipped-subsystems.txt" ]]; then
  while IFS= read -r _sk || [[ -n "$_sk" ]]; do
    [[ -z "$_sk" ]] && continue
    case "$_sk" in
      hooks) pending_msg "subsystem skipped at install: Impeccable hook (--skip-hooks) — run: npx --yes impeccable@4.8.2 install --providers=claude,codex --scope=global (accept the hook, then restart the host)" ;;
      mcp)   pending_msg "subsystem skipped at install: Playwright MCP (--skip-mcp) — run per host, e.g. Claude Code: claude mcp add --scope user playwright -- npx -y @playwright/mcp@0.0.85" ;;
      eyes)  pending_msg "subsystem skipped at install: Playwright CLI + browser (--skip-eyes) — run: npm install -g @playwright/cli@0.1.24, then playwright-cli install-browser chrome-for-testing" ;;
      *)     pending_msg "subsystem skipped at install: $_sk" ;;
    esac
  done < "$state_dir/skipped-subsystems.txt"
fi
# Live presence checks, per host actually checked (HOSTS). Hosts with no
# verified MCP/hook path (muse, cmd, copilot) are not checked and not
# reported — there is nothing to read back there.
mcp_config_for_host() { # <host> — prints the config file path, or nothing
  case "$1" in
    claude)   printf '%s\n%s\n' "$user_home/.claude.json" "$user_home/.claude/settings.json" ;;
    codex)    printf '%s' "$user_home/.codex/config.toml" ;;
    opencode) printf '%s' "$user_home/.config/opencode/opencode.json" ;;
    gemini)   printf '%s' "$user_home/.gemini/settings.json" ;;
  esac
}
mcp_manual_for_host() { # <host>
  case "$1" in
    claude)   printf '%s' "claude mcp add --scope user playwright -- npx -y @playwright/mcp@0.0.85" ;;
    codex)    printf '%s' "codex mcp add playwright -- npx -y @playwright/mcp@0.0.85" ;;
    opencode) printf '%s' "opencode mcp add playwright --global -- npx -y @playwright/mcp@0.0.85" ;;
    gemini)   printf '%s' "gemini mcp add --scope user playwright npx -y @playwright/mcp@0.0.85" ;;
  esac
}
hook_config_for_host() { # <host> — prints candidate hook-manifest paths
  # Hermes is NOT listed here: it is checked via `hermes plugins list`
  # in the hook loop below (S4 — directory presence is not verification).
  case "$1" in
    claude)   printf '%s\n%s\n' "$user_home/.claude/settings.json" "$user_home/.claude/settings.local.json" ;;
    # The project path is a fallback candidate only: install.sh promotes
    # the upstream installer's project hook to the global file, so a
    # fresh install has the global one. A project-only hook is reported
    # as PENDING (S3), never as wired; both present is warned (M2).
    codex)    printf '%s\n%s\n%s\n' "$user_home/.codex/hooks.json" "$user_home/.codex/config.toml" "$root/.codex/hooks.json" ;;
  esac
}
hook_manual_for_host() { # <host> — the exact manual command for that host
  case "$1" in
    hermes) printf '%s' "hermes plugins enable --no-allow-tool-override impeccable-design-hook" ;;
    *)      printf '%s' "npx --yes impeccable@4.8.2 install --providers=$1 --scope=global (accept the hook, then restart the host)" ;;
  esac
}
for host in "${HOSTS[@]}"; do
  # Playwright MCP presence (H5/H6).
  if _mc="$(mcp_config_for_host "$host")" && [[ -n "$_mc" ]]; then
    _mcp_found=0; _mcp_seen=0
    while IFS= read -r _cf || [[ -n "$_cf" ]]; do
      [[ -f "$_cf" ]] || continue
      _mcp_seen=1
      grep -qi 'playwright' "$_cf" && _mcp_found=1
    done <<< "$_mc"
    if [[ "$_mcp_found" == 1 ]]; then
      ok "Playwright MCP registered for $host (playwright entry in host config)"
    elif [[ "$_mcp_seen" == 1 ]]; then
      pending_msg "Playwright MCP NOT registered for $host (host config exists but has no playwright entry — nothing was registered there, whether the add failed silently or was never attempted; H6). Run: $(mcp_manual_for_host "$host")"
    else
      pending_msg "Playwright MCP presence not verifiable for $host (no readable host config at $(printf '%s' "$_mc" | tr '\n' ' ') — nothing was registered there, or the host was never configured). Run: $(mcp_manual_for_host "$host")"
    fi
  fi
  # Impeccable hook presence (H5/H6).
  # Hermes is checked via `hermes plugins list`, not directory presence
  # (S4): install.sh copies the plugin there, so `ls` succeeds by
  # construction even if the plugin is disabled. The "not enabled" row
  # contains the word "enabled", so exclude it first.
  if [[ "$host" == hermes ]]; then
    if command -v hermes >/dev/null 2>&1; then
      if hermes plugins list 2>/dev/null | grep -i 'impeccable' | grep -vi 'not enabled' | grep -qi 'enabled'; then
        ok "Impeccable hook wired for hermes (plugin listed as enabled)"
      elif ls "$user_home/.hermes/plugins" 2>/dev/null | grep -qi 'impeccable'; then
        pending_msg "Impeccable hook NOT wired for hermes (plugin is installed under ~/.hermes/plugins but not listed as enabled). Run: hermes plugins enable --no-allow-tool-override impeccable-design-hook"
      else
        pending_msg "Impeccable hook NOT wired for hermes (no impeccable plugin under ~/.hermes/plugins). Run: cp -r $root/vendor/impeccable/skill/hermes-plugin ~/.hermes/plugins/impeccable-design-hook, then hermes plugins enable --no-allow-tool-override impeccable-design-hook"
      fi
    else
      pending_msg "Impeccable hook presence not verifiable for hermes (hermes not on PATH). Run: hermes plugins enable --no-allow-tool-override impeccable-design-hook"
    fi
  elif _hc="$(hook_config_for_host "$host")" && [[ -n "$_hc" ]]; then
    _hook_found=0; _hook_seen=0; _hook_file=""; _hook_project=0
    while IFS= read -r _hf || [[ -n "$_hf" ]]; do
      if [[ -d "$_hf" ]]; then
        _hook_seen=1
        if ls "$_hf" 2>/dev/null | grep -qi 'impeccable'; then _hook_found=1; [[ -z "$_hook_file" ]] && _hook_file="$_hf"; fi
      elif [[ -f "$_hf" ]]; then
        _hook_seen=1
        if grep -qi 'impeccable' "$_hf"; then
          _hook_found=1; [[ -z "$_hook_file" ]] && _hook_file="$_hf"
          [[ "$_hf" == "$root/.codex/hooks.json" ]] && _hook_project=1
        fi
      fi
    done <<< "$_hc"
    if [[ "$_hook_found" == 1 ]]; then
      if [[ "$_hook_file" == "$root/.codex/hooks.json" ]]; then
        # S3: a project-only hook is NOT "wired" — it does not fire in
        # the user's real projects and needs trust + /hooks approval.
        # The install asked for --scope=global, so this is PENDING.
        pending_msg "Impeccable hook for $host is project-scoped only ($root/.codex/hooks.json — fires only when codex runs in that repo, after trust + /hooks approval). Promote it: cp $root/.codex/hooks.json ~/.codex/hooks.json (or re-run ./install.sh)."
      else
        ok "Impeccable hook wired for $host (impeccable entry in host hook config)"
        # M2: a project copy alongside the global one means codex fires
        # the hook twice in this repo — surface it, don't hide it.
        if [[ "$_hook_project" == 1 ]]; then
          warn "Duplicate Codex hook: $root/.codex/hooks.json also contains an impeccable entry — codex will fire the hook twice in this repo; remove the project copy (the global ~/.codex/hooks.json already covers it)."
        fi
      fi
    elif [[ "$_hook_seen" == 1 ]]; then
      pending_msg "Impeccable hook NOT wired for $host (host hook config exists but has no impeccable entry). Run: $(hook_manual_for_host "$host")"
    else
      pending_msg "Impeccable hook presence not verifiable for $host (no readable hook config at $(printf '%s' "$_hc" | tr '\n' ' ') — nothing was registered there). Run: $(hook_manual_for_host "$host")"
    fi
  fi
done

# --- 9. Node 22+ and system Chrome (H14) --------------------------------------
# ONE number, everywhere: Node 22+. The orchestrator (frontend-kit SKILL.md
# step 0.3) and consistency.mjs (built-in WebSocket, no npm deps) both
# require Node 22+; install.sh used to say "Node 18+" in its warnings and
# neither script checked anything, so a Node 18/20 machine installed
# cleanly and the step-3 gate then failed opaquely at runtime. A present
# but too-old Node is a hard FAIL here (the gate cannot run on it); a
# missing Node is UNVERIFIED (the loop step cannot be proven).
if command -v node >/dev/null 2>&1; then
  node_ver="$(node --version 2>/dev/null || echo '')"
  node_major="${node_ver#v}"; node_major="${node_major%%.*}"
  if [[ "$node_major" =~ ^[0-9]+$ ]] && [[ "10#$node_major" -ge 22 ]]; then
    ok "Node $node_ver (>= 22 — the kit's single required version)"
  elif [[ "$node_major" =~ ^[0-9]+$ ]]; then
    fail "Node $node_ver found; the kit requires Node 22+ (frontend-kit SKILL.md step 0.3; gate.mjs consistency.mjs needs the built-in WebSocket). Install Node 22+ — a Node $node_major machine installs cleanly but its step-3 gate fails at runtime."
  else
    unverified "node --version gave an unparseable result ('$node_ver') — cannot confirm Node 22+"
  fi
else
  unverified "node not found on PATH — gate.mjs and run-log.mjs cannot run. Install Node 22+."
fi
# System Chrome: consistency.mjs drives headless system Chrome via CDP.
# Its absence does NOT fail this verifier — the eyes step uses Playwright's
# chrome-for-testing instead — but it must be REPORTED, not discovered
# later when the browser leg fails: without system Chrome, gate.mjs must
# run with --skip-browser, which fails closed (H13), and the browser leg
# is skipped, not passed.
chrome_bin=""
for _cb in google-chrome google-chrome-stable chromium chromium-browser; do
  if command -v "$_cb" >/dev/null 2>&1; then chrome_bin="$(command -v "$_cb")"; break; fi
done
[[ -z "$chrome_bin" && -x /opt/google/chrome/chrome ]] && chrome_bin="/opt/google/chrome/chrome"
# macOS app-bundle locations (mirror scripts/gate/consistency.mjs
# findChrome, which already lists these before the Linux paths).
for _cp in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "/Applications/Chromium.app/Contents/MacOS/Chromium" "$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "$HOME/Applications/Chromium.app/Contents/MacOS/Chromium"; do
  if [[ -z "$chrome_bin" && -x "$_cp" ]]; then chrome_bin="$_cp"; break; fi
done
if [[ -n "$chrome_bin" ]]; then
  ok "system Chrome present ($chrome_bin) — gate.mjs consistency leg can run"
else
  warn "no system Chrome found (looked for google-chrome, google-chrome-stable, chromium, chromium-browser on PATH, /opt/google/chrome/chrome, and the macOS app bundles /Applications/Google Chrome.app, /Applications/Chromium.app, \$HOME/Applications/…) — gate.mjs consistency.mjs browser leg cannot run here; use --skip-browser (which fails closed, H13), and note the browser leg is SKIPPED, not passed. Playwright eyes are unaffected (they use chrome-for-testing)."
fi

# --- summary ------------------------------------------------------------------
printf '\nverify.sh: %s failure(s), %s unverified step(s), %s warning(s), %s pending item(s).\n' "$fails" "$unverified" "$warns" "$pending"
if [[ "$fails" -gt 0 ]]; then
  printf 'RESULT: FAIL — fix the failures above before relying on the loop.\n' >&2
  printf 'Reminder: skills/MCP/plugins load at session start. If this ran in the install session, restart the host and re-run ./verify.sh --strict in the NEW session.\n' >&2
  exit 1
fi
if [[ "$unverified" -gt 0 ]]; then
  printf 'RESULT: UNVERIFIED — loop not proven (%s step(s) could not run: see UNVERIFIED lines above). Files may be installed, but no loop step may be claimed as passing until these run green.\n' "$unverified" >&2
  printf 'Reminder: skills/MCP/plugins load at session start. If this ran in the install session, restart the host and re-run ./verify.sh --strict in the NEW session.\n' >&2
  exit 1
fi
if [[ "${eyes_skipped:-0}" == 1 ]]; then
  printf 'RESULT: OK — files, engine lockstep, detect and gate all pass (eyes skipped at install — PENDING, see above).\n'
else
  printf 'RESULT: OK — files, engine lockstep, detect, gate and eyes all pass.\n'
fi
printf 'Reminder: restart/reload each host, then re-run ./verify.sh --strict in the NEW session to confirm the skills actually load.\n'
