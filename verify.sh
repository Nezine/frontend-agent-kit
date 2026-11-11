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
  mapfile -t HOSTS < "$state_dir/installed-hosts.txt"
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
    cmd)      printf '%s' "$user_home/.agents/skills" ;;
  esac
}

# Every skills dir the kit installs to, one per line. Used by the
# taste-path check and the Impeccable SKILL.md check below.
all_skills_dirs() {
  printf '%s\n' "$user_home/.agents/skills" "$user_home/.claude/skills" \
    "$user_home/.config/opencode/skills" "$user_home/.codex/skills" \
    "$user_home/.gemini/skills" "$user_home/.hermes/skills" \
    "$user_home/.copilot/skills" "$user_home/workspace/custom-skills"
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
if grep -rIn --fixed-strings '${CLAUDE_PLUGIN_ROOT}' \
     "$user_home/.agents/skills" "$user_home/.claude/skills" \
     "$user_home/.config/opencode/skills" "$user_home/.gemini/skills" \
     "$user_home/.hermes/skills" "$user_home/.codex/skills" \
     "$user_home/.copilot/skills" \
     "$user_home/workspace/custom-skills" 2>/dev/null | head -5; then
  fail "stale \${CLAUDE_PLUGIN_ROOT} path found in an installed skill (clean-env failure A3) — see matches above"
else
  ok "no stale \${CLAUDE_PLUGIN_ROOT} in installed skills"
fi
if grep -rIn --fixed-strings '${CLAUDE_PLUGIN_ROOT}' "$refs_dir" 2>/dev/null | head -3; then
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
  # Re-resolve the CLI before the check below (clean-env 2026-11-11,
  # GAP-5): on mise-managed machines the shim can be transiently
  # unresolvable right after install, so `command -v` is false even
  # though the CLI is installed. Reshim + npm-prefix PATH before
  # deciding the CLI is missing. PATH is restored after the §6 block
  # (red-team H7): the prepend is for the eyes step only.
  _pw_saved_path="$PATH"
  hash -r
  if ! command -v playwright-cli >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
    # mise reshim takes no tool argument — it rebuilds shims for ALL
    # mise tools. Documented behaviour; the PATH restore below bounds
    # its effect on later steps.
    mise reshim >/dev/null 2>&1 || true; hash -r
  fi
  if ! command -v playwright-cli >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    _pw_npm_prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -n "$_pw_npm_prefix" && -x "$_pw_npm_prefix/bin/playwright-cli" ]]; then
      PATH="$_pw_npm_prefix/bin:$PATH"; hash -r
    fi
  fi
fi
if [[ "$eyes_skipped" == 1 ]]; then
  pending_msg "Playwright eyes skipped at install (--skip-eyes) — eyes step not run (no browser expected). Run: npm install -g @playwright/cli@0.1.24, then playwright-cli install-browser chrome-for-testing"
elif command -v playwright-cli >/dev/null 2>&1; then
  if playwright-cli --help >/dev/null 2>&1; then ok "playwright-cli --help runs ($(playwright-cli --version 2>/dev/null || echo 'version not reported'))";
  else fail "playwright-cli --help failed"; fi
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
    _server_ready=0
    for _i in $(seq 1 50); do
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
    for _a in $(seq 1 "$eyes_attempts"); do
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
# Restore PATH (red-team H7) — see the resolve block above.
if [[ -n "${_pw_saved_path:-}" ]]; then PATH="$_pw_saved_path"; hash -r; fi

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
  if [[ "$node_major" =~ ^[0-9]+$ ]] && [[ "$node_major" -ge 22 ]]; then
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
if [[ -n "$chrome_bin" ]]; then
  ok "system Chrome present ($chrome_bin) — gate.mjs consistency leg can run"
else
  warn "no system Chrome found (looked for google-chrome, google-chrome-stable, chromium, chromium-browser on PATH and /opt/google/chrome/chrome) — gate.mjs consistency.mjs browser leg cannot run here; use --skip-browser (which fails closed, H13), and note the browser leg is SKIPPED, not passed. Playwright eyes are unaffected (they use chrome-for-testing)."
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
