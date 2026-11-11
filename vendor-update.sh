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

# GAP-9 (D9): regenerate skills/frontend-kit/scripts/gate/vendored-allowlist.txt (the gate 1.2
# hash exemption manifest) at every taste re-pin, next to refresh_manifest.
# The set is the INCLUSION list in skills/frontend-kit/scripts/gate/vendored-runtime-list.txt —
# a file enters the manifest ONLY if it is listed there. The list is the
# single source of truth shared with verify.sh §3b, which reads the SAME
# file: the generator and the checker cannot drift, by construction
# (RR-04, fix round 2 — the old mirrored pattern in verify.sh is gone).
# Keys are asset-relative (assets/<relpath>), hashes from
# vendor/SHA256SUMS — so this MUST run after refresh_manifest. FAILS LOUDLY
# (non-zero exit, no silent continuation) if SHA256SUMS, the assets tree or
# the inclusion list is missing, a listed file has no hash in SHA256SUMS, a
# listed file no longer matches the sink regex (stale list entry), or the
# result is empty.
# Why inclusion, not exclusion (fix round 2, 2026-11-11): the round-1
# pattern-based exclusion (is_lab_file) could not be closed — numbered
# (lab2.html), unhyphenated (newlab.html), mid-name (my-lab-page.html) and
# whole new role families (preview/playground/sandbox/...) all defeated
# it, because a new role word always beats a closed pattern list. An
# exclusion-list error fails OPEN (a lab file silently lands in the
# manifest); an inclusion-list error fails CLOSED (a new file — runtime or
# lab — is simply NOT in the manifest, and the gate fails loudly on it if
# copied until re-pin re-classification adds it to the list). That
# asymmetry is the whole point. A new RUNTIME file is therefore excluded
# until listed — that is the design, not a bug: list it only after
# classification.
# Regeneration alone grandfathers NOTHING: the function prints the diff
# of the manifest vs the previous one AND the review set — every sink file
# in the vendored tree NOT on the inclusion list (today the 17
# lab/demo/catalog files, plus any NEW file upstream added) — and the
# re-pin checklist (printed STOP line below) requires reviewing each one
# against the GAP-9 classification (w-gap9-analysis.md §1–§2) before the
# new manifest ships: runtime sink file -> add it to the inclusion list;
# lab/demo/catalog tooling -> leave it out. New upstream bytes are not
# grandfathered on trust.
regenerate_vendored_allowlist() {
  local allowlist="$KIT_ROOT/skills/frontend-kit/scripts/gate/vendored-allowlist.txt"
  local runtime_list="$KIT_ROOT/skills/frontend-kit/scripts/gate/vendored-runtime-list.txt"
  local assets_root="$KIT_ROOT/vendor/taste/skills/taste-skill/assets"
  [ -f "$MANIFEST" ] || { echo "vendor-update.sh: vendor/SHA256SUMS missing — cannot regenerate the vendored allowlist" >&2; return 1; }
  [ -d "$assets_root" ] || { echo "vendor-update.sh: taste assets tree missing at $assets_root — cannot regenerate the vendored allowlist" >&2; return 1; }
  [ -f "$runtime_list" ] || { echo "vendor-update.sh: vendored runtime inclusion list missing at $runtime_list — cannot regenerate the vendored allowlist (a file enters the manifest ONLY via that list)" >&2; return 1; }
  local tmp_entries tmp_manifest tmp_list tmp_tree prev_count new_count list_count
  tmp_entries="$(mktemp)"
  tmp_manifest="$(mktemp)"
  tmp_list="$(mktemp)"
  tmp_tree="$(mktemp)"
  # The inclusion list, normalised: comments/blank lines dropped,
  # surrounding whitespace trimmed, sorted unique. A duplicate or an
  # unsorted list is a maintenance error — fail loudly rather than
  # silently re-sorting a list whose order the reviewer relied on.
  grep -v '^[[:space:]]*#' "$runtime_list" | grep -v '^[[:space:]]*$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort > "$tmp_list"
  list_count="$(grep -c . "$tmp_list" || true)"
  [ "$list_count" -gt 0 ] || { echo "vendor-update.sh: vendored runtime inclusion list is empty — refusing (no runtime sink files listed?)" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1; }
  if [[ "$(sort -u "$tmp_list" | grep -c . || true)" != "$list_count" ]]; then
    echo "vendor-update.sh: vendored runtime inclusion list has duplicate entries — refusing (deduplicate $runtime_list first)" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1; fi
  if ! cmp -s <(grep -v '^[[:space:]]*#' "$runtime_list" | grep -v '^[[:space:]]*$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') "$tmp_list"; then
    echo "vendor-update.sh: vendored runtime inclusion list is not sorted — refusing (sort $runtime_list first)" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1; fi
  # Candidates: exactly the inclusion list, in list order (already
  # sorted). Each entry must be an assets/ path, must exist in the tree,
  # must still match the gate 1.2 sink regex (a listed file that lost its
  # sink is a stale entry — fail loudly), and must have a SHA256SUMS hash.
  while IFS= read -r listed; do
    [[ -z "$listed" ]] && continue
    case "$listed" in assets/*) ;; *) echo "vendor-update.sh: inclusion-list entry '$listed' does not start with 'assets/' — refusing" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1 ;; esac
    local rel="${listed#assets/}"
    [ -f "$assets_root/$rel" ] || { echo "vendor-update.sh: inclusion-list entry $listed not found in the vendored taste tree — refusing (stale list entry?)" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1; }
    grep -qE 'dangerouslySetInnerHTML|innerHTML[[:space:]]*=|outerHTML[[:space:]]*=|document\.write[[:space:]]*\(' "$assets_root/$rel" || { echo "vendor-update.sh: inclusion-list entry $listed no longer matches the gate 1.2 sink regex — refusing (stale list entry? remove it from the list, do not ship a non-sink exemption)" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1; }
    local hash
    hash="$(awk -v p="vendor/taste/skills/taste-skill/assets/$rel" '$2==p {print $1; exit}' "$MANIFEST")"
    [ -n "$hash" ] || { echo "vendor-update.sh: no SHA256SUMS entry for taste asset $rel — refusing to regenerate the vendored allowlist" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1; }
    printf '%s  assets/%s\n' "$hash" "$rel" >> "$tmp_entries"
  done < "$tmp_list"
  new_count="$(grep -c . "$tmp_entries" || true)"
  [ "$new_count" -gt 0 ] || { echo "vendor-update.sh: vendored allowlist would be empty — refusing (no runtime sink files found?)" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1; }
  # Review set (informational, NOT a fail — the 17 lab/demo/catalog files
  # are unlisted by design): every sink file in the tree NOT on the
  # inclusion list. A NEW file shows up here first; the re-pin checklist
  # below requires reviewing it before committing.
  grep -rlE 'dangerouslySetInnerHTML|innerHTML[[:space:]]*=|outerHTML[[:space:]]*=|document\.write[[:space:]]*\(' "$assets_root" 2>/dev/null | sed "s|^$assets_root/|assets/|" | sort > "$tmp_tree"
  local review_set review_count
  review_set="$(comm -13 "$tmp_list" "$tmp_tree" || true)"
  review_count="$(printf '%s\n' "$review_set" | grep -c . || true)"
  echo "vendor-update.sh: review set — $review_count sink file(s) in the vendored tree NOT on the inclusion list (lab/demo/catalog by classification, or NEW — review each against the GAP-9 classification before committing):"
  printf '%s\n' "$review_set"
  {
    echo "# vendored-allowlist.txt — GAP-9 (D9): byte-identical vendored taste runtime assets"
    echo "# exempt from gate.sh check 1.2 (project-relative path + sha256 must BOTH match)."
    echo "# pin: taste | tag=$TAG | commit=$COMMIT"
    echo "# Generated by vendor-update.sh (taste branch) from vendor/SHA256SUMS; never hand-edit."
    echo "# Scope: the $new_count RUNTIME files under vendor/taste/skills/taste-skill/assets/ whose"
    echo "# content matches the gate 1.2 sink regex at this pin (w-gap9-analysis.md §1–§2)."
    echo "# Lab/demo/catalog tooling is NEVER listed here — if one is copied into a project,"
    echo "# gate 1.2 fails on it. A vendored file copied to any other project path does not"
    echo "# match (fail closed on relocation). A missing or stale manifest means no exemption."
    echo "# Re-classification of the sink sites is required at each re-pin before this ships."
    cat "$tmp_entries"
  } > "$tmp_manifest"
  if [ -f "$allowlist" ]; then
    prev_count="$(grep -vc '^#' "$allowlist" || true)"
    echo "vendor-update.sh: vendored allowlist: $prev_count entries -> $new_count entries."
    if ! diff -u "$allowlist" "$tmp_manifest" > /dev/null 2>&1; then
      echo "vendor-update.sh: vendored allowlist DIFF vs previous manifest (review before committing — a new file here needs re-classification):"
      diff -u "$allowlist" "$tmp_manifest" || true
    else
      echo "vendor-update.sh: vendored allowlist unchanged vs previous manifest."
    fi
  else
    echo "vendor-update.sh: vendored allowlist: no previous manifest, writing $new_count entries."
  fi
  # RT-10 fix (2026-11-11), hardened in fix round 2 (RR-11): cp onto an
  # existing DIRECTORY "succeeds" by copying the file inside it, and cp
  # onto a SYMLINK writes through to the link target — then the script
  # would print "regenerated" with no file at the manifest path, or with
  # the manifest landing outside the checkout where git never tracks it.
  # Fail loudly unless the manifest path's parent dir exists beforehand,
  # the path itself is NOT a symlink, and the copy lands as a regular
  # file holding exactly the expected entry count.
  [ -d "$(dirname -- "$allowlist")" ] || { echo "vendor-update.sh: skills/frontend-kit/scripts/gate/ dir missing — cannot write the vendored allowlist" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1; }
  if [[ -L "$allowlist" ]]; then
    echo "vendor-update.sh: manifest path $allowlist is a symlink — refusing to copy through it (recreate it as a regular file first)" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1
  fi
  cp "$tmp_manifest" "$allowlist"
  if [[ -L "$allowlist" ]]; then
    echo "vendor-update.sh: manifest path $allowlist became a symlink during the copy — refusing" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1
  fi
  if [[ ! -f "$allowlist" ]]; then
    echo "vendor-update.sh: copy did not produce a regular file at $allowlist (is it a directory?) — refusing" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree" "$allowlist/$(basename -- "$tmp_manifest")"; return 1
  fi
  allow_written="$(grep -vc '^#' "$allowlist" || true)"
  if [[ "$allow_written" != "$new_count" ]]; then
    echo "vendor-update.sh: manifest at $allowlist holds $allow_written entries, expected $new_count — refusing" >&2; rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"; return 1
  fi
  rm -f "$tmp_entries" "$tmp_manifest" "$tmp_list" "$tmp_tree"
  echo "vendor-update.sh: skills/frontend-kit/scripts/gate/vendored-allowlist.txt regenerated ($new_count entries)."
  echo "vendor-update.sh: STOP — re-classify the sink sites for the new pin (w-gap9-analysis.md §1 method) AND review the $review_count unlisted sink file(s) printed above against skills/frontend-kit/scripts/gate/vendored-runtime-list.txt (runtime -> add to the list; lab/demo/catalog -> leave out) BEFORE committing this manifest. New upstream bytes are not grandfathered on trust."
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
if [ "$COMP" = "taste" ]; then
  regenerate_vendored_allowlist
fi
echo "vendor-update.sh: DONE. Verify with ./scripts/check-versions.sh && ./verify.sh, review git diff, then commit by hand. Nothing was committed or pushed."
