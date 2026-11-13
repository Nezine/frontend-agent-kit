#!/bin/bash
# Unit test for the §1.1 example-only filter in gate.sh
# (sec_11_keep_unless_example_only, D34 (c1) + MIG-3 fix pass W1 + fix pass 2).
#
# Extracts the REAL filter from gate.sh (verbatim — no copied logic)
# and runs it against constructed lines. Never prints a secret value:
# the fixture literal is derived at runtime from verify.sh:5168 (the
# §5c case-(104) fixture line) and only counts are reported.
#
# Run: bash tests/test-sec11-filter.sh
# Exit 0 = all cases pass; non-zero = at least one case failed.
# Wired into CI (.github/workflows/ci.yml, next to the Playwright
# unit test) and into verify.sh §6c, so a broken filter fails both.
set -u
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
gate_sh="$root/skills/frontend-kit/scripts/gate/gate.sh"
verify_sh="$root/verify.sh"
[[ -f "$gate_sh" ]] || { printf 'FAIL: gate.sh not found at %s\n' "$gate_sh"; exit 1; }
[[ -f "$verify_sh" ]] || { printf 'FAIL: verify.sh not found at %s\n' "$verify_sh"; exit 1; }

# Patterns, verbatim from gate.sh (sourced, not retyped).
# NOTE (D34/W1 macOS fix): do NOT use `source` with process substitution here.
# On macOS bash 3.2 the process-substitution fd is closed before the
# `source` builtin reads it, so grep dies with "Broken pipe" and no
# pattern is set (fails on macos-15/26, passes on GNU bash 5.2).
# Materialise the grep output in a temp file first: grep completes
# before source runs, and sourcing a regular file is synchronous.
_pat_tmp="$(mktemp "${TMPDIR:-/tmp}/sec11-pat.XXXXXX")"
[[ -n "$_pat_tmp" ]] || { printf 'FAIL: mktemp failed\n'; exit 1; }
trap 'rm -f "$_pat_tmp"' EXIT
# F1/R3 hardening: drop any caller-exported value first, so a stale
# inherited value can never mask a missing line in gate.sh.
unset sec_11_pat sec_11_assign_pat sec_11_assign_unquoted_pat
grep -E '^sec_11_(pat|assign_pat|assign_unquoted_pat)=' "$gate_sh" > "$_pat_tmp"
[[ -s "$_pat_tmp" ]] || { printf 'FAIL: no sec_11 patterns found in %s\n' "$gate_sh"; exit 1; }
# F2 hardening: require exactly 3 extracted lines before sourcing, so a
# duplicated pattern line can never win silently (last-wins).
_pat_count="$(grep -cE '^sec_11_(pat|assign_pat|assign_unquoted_pat)=' "$_pat_tmp")"
[[ "$_pat_count" == 3 ]] || { printf 'FAIL: expected 3 sec_11 pattern lines in %s, got %s\n' "$gate_sh" "$_pat_count"; exit 1; }
source "$_pat_tmp"
[[ -n "${sec_11_pat:-}" && -n "${sec_11_assign_pat:-}" && -n "${sec_11_assign_unquoted_pat:-}" ]] || { printf 'FAIL: sec_11 patterns did not load from %s (empty source)\n' "$gate_sh"; exit 1; }

# Filter definition + function, verbatim from gate.sh: from the
# sec_11_fixture_lit definition line through the function's closing brace.
filter_src="$(awk '/^sec_11_fixture_lit=/{f=1} f{print} f && /^}/{exit}' "$gate_sh")"
[[ -n "$filter_src" ]] || { printf 'FAIL: sec_11 filter not found in gate.sh\n'; exit 1; }
eval "$filter_src"

# Fixture literal, derived at runtime from verify.sh:5168 — never
# written out here, so this file ships no credential-shaped literal.
_fixture_line="$(sed -n '5168p' "$verify_sh")"
LIT="$(printf '%s' "$_fixture_line" | sed -n 's/.*api_key = "//; s/".*//p')"
[[ -n "$LIT" ]] || { printf 'FAIL: could not extract the case-(104) fixture literal from verify.sh:5168\n'; exit 1; }
[[ "${#LIT}" == 32 ]] || { printf 'FAIL: fixture literal has unexpected length %s (want 32)\n' "${#LIT}"; exit 1; }
[[ "$LIT" =~ ^sk-proj-[A-Za-z0-9_-]{20,}$ ]] || { printf 'FAIL: fixture literal has an unexpected shape\n'; exit 1; }
LOW="$(printf '%s' "$LIT" | tr 'A-Z' 'a-z')"
TAIL="${LIT#sk-proj-}"
# MIG-3 fix pass 2 (W4): the public AWS example, runtime-constructed
# from adjacent string literals (same trick as gate.sh's fixture
# spelling) so this file ships no credential-shaped literal either.
AKIA_EX="AKIA"IO"SFODNN7EX"AMPLE
# Mixed-case fixture (first two letters flipped): the exemption is
# exact-case, so this must still match and still fail.
MIX="SK${LIT#sk}"

clone_dirs=("/tmp/fakeproj/kit-clone")
pass=0
fail=0
# t <label> <expected-kept-0-or-1> <line> <pattern>
t() {
  local label="$1" expect="$2" line="$3" pat="$4" got
  got="$(printf '%s\n' "$line" | sec_11_keep_unless_example_only "$pat" | wc -l)"
  got="${got//[[:space:]]/}"
  if [[ "$got" == "$expect" ]]; then
    printf 'PASS %s (kept=%s)\n' "$label" "$got"; pass=$((pass + 1))
  else
    printf 'FAIL %s (kept=%s, want %s)\n' "$label" "$got" "$expect"; fail=$((fail + 1))
  fi
}

# A: fixture under a clone -> exempted (0), PAT and ASSIGN
t "A1 fixture-under-clone PAT" 0 "/tmp/fakeproj/kit-clone/verify.sh:5168:  printf 'api_key = \"$LIT\" was visible'" "$sec_11_pat"
t "A2 fixture-under-clone ASSIGN" 0 "/tmp/fakeproj/kit-clone/verify.sh:5168:  printf 'api_key = \"$LIT\" was visible'" "$sec_11_assign_pat"
# B: same literal outside any clone (case (104) bad half) -> kept (1)
t "B1 fixture-outside-clone PAT" 1 "/tmp/fakeproj/design/judge/round-1.md:7: Judge note: api_key = \"$LIT\" was visible" "$sec_11_pat"
t "B2 fixture-outside-clone ASSIGN" 1 "/tmp/fakeproj/design/judge/round-1.md:7: Judge note: api_key = \"$LIT\" was visible" "$sec_11_assign_pat"
# W1 (fix pass): the exemption is whole-token, case-sensitive.
# V3: longer key with the fixture as a prefix, under a clone -> kept
t "V3 prefix-longer-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"${LIT}ABCD\"" "$sec_11_pat"
t "V3b prefix-longer-under-clone ASSIGN" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"${LIT}ABCD\"" "$sec_11_assign_pat"
# V4: fixture embedded in a longer api_key value, under a clone -> kept
t "V4 embedded-both-sides-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/config.env:1: api_key = \"xx${LIT}yy\"" "$sec_11_pat"
t "V4b embedded-suffix-only-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/config.env:1: api_key = \"${LIT}zz\"" "$sec_11_pat"
t "V4c embedded-prefix-only-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/config.env:1: api_key = \"qq${LIT}\"" "$sec_11_pat"
# V6: lowercase fixture, under a clone -> kept (exemption is exact-case)
t "V6 lowercase-fixture-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"$LOW\"" "$sec_11_pat"
# V9: fixture as a JSON value, under a clone -> exempted (quoted whole token)
t "V9 fixture-as-JSON-value-under-clone PAT" 0 "/tmp/fakeproj/kit-clone/data.json:3: \"api_key\": \"$LIT\"" "$sec_11_pat"
t "V9b fixture-as-JSON-value-under-clone ASSIGN" 0 "/tmp/fakeproj/kit-clone/data.json:3: \"api_key\": \"$LIT\"" "$sec_11_assign_pat"
# V10: fixture as a JSON value outside a clone -> kept
t "V10 fixture-as-JSON-value-outside-clone PAT" 1 "/tmp/fakeproj/design/judge/round-1.md:7: \"api_key\": \"$LIT\"" "$sec_11_pat"
# Mixed line: one whole-token fixture plus one longer key -> kept
# (removing only the whole token must not exempt the longer one).
t "V10b mixed-whole-plus-longer-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: $LIT and ${LIT}ABCD" "$sec_11_pat"
# Two whole-token fixtures on one line -> both removed, exempted.
t "V10c two-whole-fixtures-under-clone PAT" 0 "/tmp/fakeproj/kit-clone/notes.txt:1: $LIT $LIT" "$sec_11_pat"
# MIG-3 fix pass 2 (W-RT4): each case below FAILS against the 5578716
# filter and PASSES against the new one. The old filter's
# case-insensitive substring removal, case-insensitive clone test and
# strip-before-removal order exempted all of them.
# V11: mixed-case fixture, under a clone -> kept (exemption is exact-case)
t "V11 mixed-case-fixture-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"$MIX\"" "$sec_11_pat"
# V12: fixture followed by a token char (_, -, digit) -> kept
t "V12a trailing-underscore-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"${LIT}_\"" "$sec_11_pat"
t "V12b trailing-hyphen-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"${LIT}-\"" "$sec_11_pat"
t "V12c trailing-digit-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"${LIT}5\"" "$sec_11_pat"
# V13: one-sided delimiter — a secret char on one side only -> kept
t "V13a left-secret-right-line-edge PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"x${LIT}" "$sec_11_pat"
t "V13b left-delim-right-secret-line-edge PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"${LIT}ABCD" "$sec_11_pat"
# V14 (W-RT1): case-variant clone dir is NOT a clone -> kept
t "V14 case-variant-clone-dir PAT" 1 "/tmp/fakeproj/KIT-CLONE/notes.txt:1: api_key = \"$LIT\"" "$sec_11_pat"
# V15 (W-RT2): the public example spliced into a longer key -> kept
# (the strip must not join the parts into the fixture before removal)
t "V15 splice-joins-into-fixture PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"sk-proj-ABC${AKIA_EX}DEFGHIJKLMNOPQRSTUVWX\"" "$sec_11_pat"
# MIG-3 fix pass 3 (W-RT3): 200 whole-token fixtures on one line. The
# linear single-pass removal must drop them all; the fix-pass-2 loop took
# 310 ms for 200 and 22.9 s for 2000 on a 66 KB line (over 100 s on 1 MB).
_many200=""
for _i in {1..200}; do _many200="$_many200$LIT "; done
t "V16 two-hundred-whole-fixtures-under-clone PAT" 0 "/tmp/fakeproj/kit-clone/notes.txt:1: $_many200" "$sec_11_pat"
# MIG-3 fix pass 3: the shrink boundary, pinned (see the D34 entry). The
# fixture literal is absent here, so the removal is a no-op and the
# verdict comes from the AKIA strip plus the re-test: 19 real chars after
# the example stay below the 20-char PAT minimum (dropped); 20 reach it.
t "V17a shrink-boundary-19-chars PAT" 0 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"sk-proj-${AKIA_EX}ABCDEFGHIJKLMNOPQRS\"" "$sec_11_pat"
t "V17b shrink-boundary-20-chars PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: api_key = \"sk-proj-${AKIA_EX}ABCDEFGHIJKLMNOPQRST\"" "$sec_11_pat"
# C: a different (real-shape) secret under a clone -> kept (1)
t "C1 other-AKIA-under-clone PAT" 1 "/tmp/fakeproj/kit-clone/notes.txt:1: aws_access_key_id = AKIA$(printf 'B%.0s' {1..16})" "$sec_11_pat"
# D: the public AWS example under a clone -> dropped (0), global exemption intact
t "D1 example-under-clone PAT" 0 "/tmp/fakeproj/kit-clone/notes.txt:1: $AKIA_EX" "$sec_11_pat"
# E: gate.sh's own definition line (not under a clone) -> dropped (0):
# the split spelling must not match the pattern.
t "E1 definition-line PAT" 0 "sec_11_fixture_lit=\"sk-proj-\"$TAIL" "$sec_11_pat"

printf 'sec11-filter: %s passed, %s failed\n' "$pass" "$fail"
[[ "$fail" == 0 ]]
