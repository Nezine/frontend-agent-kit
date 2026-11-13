#!/usr/bin/env bash
# secret-grep.sh — repo/working-tree + bundle secret scan for the hackathon build.
# Usage:
#   bash secret-grep.sh [path]        # default path: .
#   bash secret-grep.sh dist/         # bundle check after `npx expo export`
# Exit 0 = CLEAN (no pattern found). Exit 1 = HIT (a pattern matched — STOP).
# Smoke-tested 2026-11-13: matched 7/7 planted secrets (sk-proj- key,
# 39-char AIza Google key, sb_secret_, service_role,
# EXPO_PUBLIC_OPENAI_API_KEY=sk-... in .env, RSA + OPENSSH private-key
# headers) and returned CLEAN on a clean tree (no false positive on
# EXPO_PUBLIC_CONVEX_URL or plain strings). Never grep for a real key value.
#
# Two load-bearing details in the pattern:
# 1. The space inside (RSA |EC |OPENSSH )? — without it the pattern
#    requires the literal string "OPENSSHPRIVATE" and can never match a
#    real "-----BEGIN OPENSSH PRIVATE KEY-----" header. The broken form
#    was run against a real header on 2026-11-13 and confirmed to miss it.
# 2. The AIza[0-9A-Za-z_-]{35} alternative — a Google API key is 39
#    chars total ("AIza" + 35). Without this alternative a Google key
#    in the bundle goes undetected (found in the same smoke test).
#
# 3. SELF-MATCH: this script and SKILL.md document the pattern, so they
#    match it themselves. When the repo grep (§6 item 1) runs on a tree
#    that contains this skill, exclude the skill directory (e.g. pass
#    the repo root but --exclude-dir=hackathon-security, or list the
#    skill's reference files as pre-approved known hits in CONTRACT.md).
#    Do NOT "fix" the self-match by weakening the pattern.

set -u
TARGET="${1:-.}"

PATTERN='sk-(proj-)?[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{35}|sb_secret_|service_role|OPENAI_API_KEY|ANTHROPIC_API_KEY|GOOGLE_API_KEY|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'

if grep -R -E -i --exclude-dir=node_modules --exclude-dir=.git -- "$PATTERN" "$TARGET"; then
  echo "HIT: secret pattern found above — STOP, do not merge / do not ship." >&2
  exit 1
else
  echo "CLEAN: no secret pattern found in $TARGET"
  exit 0
fi
