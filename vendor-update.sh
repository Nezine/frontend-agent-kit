#!/usr/bin/env bash
# vendor-update.sh — re-pin one vendored upstream to a new tag/commit.
#
#   vendor-update.sh <component> <tag-or-commit> [--dry-run]
#   component: impeccable | gsap | ui-ux-pro-max | taste
#
# What it does, in order (never auto-upgrades at install time — this is a
# deliberate, reviewed act):
#   1. Resolves <tag-or-commit> against upstream with git ls-remote.
#      FAILS LOUDLY if it cannot be resolved — never guesses a hash.
#   2. Clones that exact ref to a temp dir and replaces the vendored tree.
#   3. Updates the PIN marker in SOURCES.md and the component's SOURCE.txt.
#   4. Re-applies the kit patch (Pro Max ${CLAUDE_PLUGIN_ROOT} fix) and
#      verifies zero stale refs remain.
#   5. Refreshes vendor/SHA256SUMS.
#   6. Prints a verification checklist. It NEVER commits or pushes.
#
# After running: ./scripts/check-versions.sh && ./verify.sh, and for
# impeccable also ./scripts/generate-host-variants.sh --all --out <tmp>
# plus a diff of the generated variants against upstream's own generated
# trees; review `git diff` before committing.
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$KIT_ROOT/SOURCES.md"
MANIFEST="$KIT_ROOT/vendor/SHA256SUMS"

usage() { echo "usage: vendor-update.sh <impeccable|gsap|ui-ux-pro-max|taste> <tag-or-commit> [--dry-run]" >&2; exit 2; }

[ $# -ge 2 ] || usage
COMP="$1"; REF="$2"; DRY_RUN=0
[ "${3:-}" = "--dry-run" ] && DRY_RUN=1

case "$COMP" in
  impeccable)   REPO="pbakaus/impeccable" ;;
  gsap)         REPO="greensock/gsap-skills" ;;
  ui-ux-pro-max) REPO="nextlevelbuilder/ui-ux-pro-max-skill" ;;
  taste)        REPO="Leonxlnx/taste-skill" ;;
  *) echo "vendor-update.sh: unknown component: $COMP" >&2; usage ;;
esac
URL="https://github.com/$REPO.git"

# --- 1. Resolve ref -> full commit (tag peeled, or exact commit) -----------
echo "vendor-update.sh: resolving $REF for $REPO ..."
COMMIT=""
if git ls-remote --tags "$URL" 2>/dev/null | grep -q "refs/tags/$REF$"; then
  COMMIT="$(git ls-remote --tags "$URL" "refs/tags/$REF^{}" 2>/dev/null | awk '{print $1}')"
  [ -n "$COMMIT" ] || COMMIT="$(git ls-remote --tags "$URL" "refs/tags/$REF" 2>/dev/null | awk '{print $1}')"
  TAG="$REF"
elif git ls-remote "$URL" 2>/dev/null | grep -q "^$REF"; then
  COMMIT="$REF"; TAG=""
else
  # Maybe a short hash or a tag that ls-remote lists differently — try once more verbosely.
  echo "vendor-update.sh: cannot resolve '$REF' for $REPO (not a tag, not a full commit)" >&2
  exit 1
fi
[ -n "$COMMIT" ] || { echo "vendor-update.sh: resolved empty commit for $REF" >&2; exit 1; }
# Tag-pinned components must be re-pinned by tag, never by bare commit:
# the tag is the release identity (the commit alone proves nothing about
# which release it belongs to). gsap is the only commit-pinned component.
if [ "$COMP" != "gsap" ] && [ -z "${TAG:-}" ]; then
  echo "vendor-update.sh: $COMP is tag-pinned — pass a tag (e.g. skill-v4.8.1), not a bare commit" >&2
  exit 1
fi
echo "vendor-update.sh: $COMP $REF -> commit $COMMIT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- 2. Clone the exact ref --------------------------------------------------
if [ -n "${TAG:-}" ]; then
  git clone --quiet --depth 1 --branch "$TAG" "$URL" "$TMP/up" 2>&1 | tail -2
else
  git clone --quiet "$URL" "$TMP/up" 2>&1 | tail -2
  (cd "$TMP/up" && git checkout --quiet "$COMMIT")
fi
ACTUAL="$(cd "$TMP/up" && git rev-parse HEAD)"
[ "$ACTUAL" = "$COMMIT" ] || { echo "vendor-update.sh: cloned HEAD $ACTUAL != resolved $COMMIT" >&2; exit 1; }

[ "$DRY_RUN" -eq 1 ] && { echo "vendor-update.sh: --dry-run: resolved $COMP $REF -> $COMMIT, no files changed"; exit 0; }

refresh_manifest() {
  (cd "$KIT_ROOT" && find vendor -type f ! -name SHA256SUMS -exec sha256sum {} + | sort -k2 > "$MANIFEST")
}

update_pin_marker() { # <component> <tag> <commit> [extra k=v ...]
  local comp="$1" tag="$2" commit="$3"; shift 3
  python3 - "$SOURCES" "$comp" "$tag" "$commit" "$@" <<'PYEOF'
import re, sys
path, comp, tag, commit, extra = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5:]
text = open(path, encoding="utf-8").read()
pat = re.compile(r"<!-- PIN: " + re.escape(comp) + r" \|[^>]*-->")
m = pat.search(text)
if not m:
    print(f"vendor-update.sh: no PIN marker for {comp} in {path}", file=sys.stderr)
    sys.exit(1)
old = m.group(0)
repo = re.search(r"repo=([^ |]+)", old).group(1)
new = f"<!-- PIN: {comp} | repo={repo} | tag={tag} | commit={commit}"
for kv in extra:
    new += f" | {kv}"
new += " -->"
open(path, "w", encoding="utf-8").write(text[:m.start()] + new + text[m.end():])
print(f"vendor-update.sh: SOURCES.md marker updated for {comp}")
PYEOF
}

update_source_txt() { # <file> <key=value>...
  local f="$1"; shift
  for kv in "$@"; do
    local k="${kv%%=*}"
    if grep -q "^$k=" "$f"; then
      sed -i "s|^$k=.*|$kv|" "$f"
    else
      echo "$kv" >> "$f"
    fi
  done
}

case "$COMP" in
  impeccable)
    # Canonical copy = upstream skill/ verbatim. Engine comes from the tag:
    # ENGINE_VERSION at the tag root (must equal skill/scripts/VERSION).
    ENGINE="$(cat "$TMP/up/ENGINE_VERSION" | tr -d '[:space:]')"
    TREE_ENGINE="$(cat "$TMP/up/skill/scripts/VERSION" | tr -d '[:space:]')"
    [ "$ENGINE" = "$TREE_ENGINE" ] || { echo "vendor-update.sh: tag $TAG pins ENGINE_VERSION $ENGINE but skill/scripts/VERSION reads $TREE_ENGINE — refusing (lockstep)" >&2; exit 1; }
    if grep -q '^version:' "$TMP/up/skill/SKILL.src.md"; then
      echo "vendor-update.sh: SKILL.src.md gained a top-level version: — refusing, inspect first" >&2; exit 1
    fi
    rm -rf "$KIT_ROOT/vendor/impeccable/skill"
    cp -r "$TMP/up/skill" "$KIT_ROOT/vendor/impeccable/skill"
    cp "$TMP/up/LICENSE" "$KIT_ROOT/vendor/impeccable/LICENSE"
    cp "$TMP/up/NOTICE.md" "$KIT_ROOT/vendor/impeccable/NOTICE.md"
    update_source_txt "$KIT_ROOT/vendor/impeccable/SOURCE.txt" "tag=$TAG" "commit=$COMMIT" "engine=$ENGINE"
    update_pin_marker impeccable "$TAG" "$COMMIT" "engine=$ENGINE"
    echo "vendor-update.sh: impeccable re-pinned to $TAG (engine $ENGINE). Now run scripts/generate-host-variants.sh --all and diff the output against upstream's generated trees."
    ;;
  gsap)
    # No tags upstream; pin is a commit. Vendored layout is flattened:
    # vendor/gsap/<skill>/SKILL.md (upstream skills/<skill>/SKILL.md).
    for d in "$TMP/up/skills/"*/; do
      name="$(basename "$d")"
      mkdir -p "$KIT_ROOT/vendor/gsap/$name"
      cp "$d/SKILL.md" "$KIT_ROOT/vendor/gsap/$name/SKILL.md"
    done
    cp "$TMP/up/LICENSE" "$KIT_ROOT/vendor/gsap/LICENSE" 2>/dev/null || true
    update_pin_marker gsap "" "$COMMIT"
    echo "vendor-update.sh: gsap re-pinned to commit $COMMIT (no tags upstream)."
    ;;
  ui-ux-pro-max)
    rm -rf "$KIT_ROOT/vendor/ui-ux-pro-max/reference"
    mkdir -p "$KIT_ROOT/vendor/ui-ux-pro-max/reference"
    cp -r "$TMP/up/.claude/skills/ui-ux-pro-max/." "$KIT_ROOT/vendor/ui-ux-pro-max/reference/"
    cp "$TMP/up/LICENSE" "$KIT_ROOT/vendor/ui-ux-pro-max/LICENSE"
    # Re-apply the kit patch: ${CLAUDE_PLUGIN_ROOT} -> <skill-dir>.
    SKILL="$KIT_ROOT/vendor/ui-ux-pro-max/reference/SKILL.md"
    BEFORE="$(grep -c 'CLAUDE_PLUGIN_ROOT' "$SKILL" || true)"
    sed -i 's#"${CLAUDE_PLUGIN_ROOT}/.claude/skills/ui-ux-pro-max/scripts/search.py"#"<skill-dir>/scripts/search.py"#g' "$SKILL"
    AFTER="$(grep -c 'CLAUDE_PLUGIN_ROOT' "$SKILL" || true)"
    [ "$AFTER" -eq 0 ] || { echo "vendor-update.sh: Pro Max patch left $AFTER CLAUDE_PLUGIN_ROOT refs — refusing" >&2; exit 1; }
    LINES="$(grep -n '<skill-dir>/scripts/search.py' "$SKILL" | cut -d: -f1 | paste -sd, -)"
    update_source_txt "$KIT_ROOT/vendor/ui-ux-pro-max/SOURCE.txt" "tag=$TAG" "commit=$COMMIT" "patch-lines=$LINES"
    update_pin_marker ui-ux-pro-max "$TAG" "$COMMIT"
    echo "vendor-update.sh: ui-ux-pro-max re-pinned to $TAG (patch re-applied: $BEFORE refs -> 0, lines $LINES)."
    ;;
  taste)
    # SOURCE.txt is kit-owned (not upstream's) — keep it across the wipe.
    cp "$KIT_ROOT/vendor/taste/SOURCE.txt" "$TMP/taste-SOURCE.txt"
    rm -rf "$KIT_ROOT/vendor/taste"
    mkdir -p "$KIT_ROOT/vendor/taste"
    cp -r "$TMP/up/." "$KIT_ROOT/vendor/taste/"
    rm -rf "$KIT_ROOT/vendor/taste/.git"
    cp "$TMP/taste-SOURCE.txt" "$KIT_ROOT/vendor/taste/SOURCE.txt"
    update_source_txt "$KIT_ROOT/vendor/taste/SOURCE.txt" "tag=$TAG" "commit=$COMMIT"
    update_pin_marker taste "$TAG" "$COMMIT"
    PRESETS="$(python3 -c "import json; print(len(json.load(open('$KIT_ROOT/vendor/taste/skills/taste-skill/assets/diagrams/presets.json'))['presets']))")"
    echo "vendor-update.sh: taste re-pinned to $TAG (presets.json now holds $PRESETS named presets — must be 27; check SOURCES.md if it moved)."
    ;;
esac

refresh_manifest
echo "vendor-update.sh: vendor/SHA256SUMS refreshed."
echo "vendor-update.sh: DONE. Verify with ./scripts/check-versions.sh && ./verify.sh, review git diff, then commit by hand. Nothing was committed or pushed."
