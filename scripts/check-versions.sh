#!/usr/bin/env bash
# check-versions.sh — warn-only drift check for frontend-agent-kit pins.
#
# Compares each vendored pin (SOURCES.md / the vendored trees) with the
# upstream latest and WARNS on drift. It NEVER upgrades anything (A4):
# re-pinning is a deliberate, reviewed step — run vendor-update.sh, or
# re-pin by hand and update SOURCES.md + the SHA-256 manifest.
#
# Needs network (git ls-remote / npm view). Offline -> "could not check",
# exit 0. Usage: ./scripts/check-versions.sh
set -uo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
warns=0
warn() { warns=$((warns+1)); printf 'DRIFT: %s\n' "$1"; }
info() { printf 'PIN: %s\n' "$1"; }
offline=0
command -v git >/dev/null 2>&1 || { printf 'check-versions: git not found — cannot check.\n'; exit 0; }

latest_tag() { # <repo-url> [tag-prefix] — highest tag with that prefix
  local url="$1" prefix="${2:-}"
  git ls-remote --tags "$url" 2>/dev/null | awk -F/ '{print $NF}' | sed 's/\^{}$//' \
    | grep -E "^${prefix}v?[0-9]+\.[0-9]+\.[0-9]+" | sort -V | tail -1
}
latest_commit() { git ls-remote "$1" HEAD 2>/dev/null | awk '{print $1}'; }

# --- Impeccable: vendored skill version + engine VERSION vs latest tags -----
# v2 layout (re-pin 2026-11-10): single canonical copy in
# vendor/impeccable/skill/ (SKILL.src.md, no top-level version field);
# the pin lives in vendor/impeccable/SOURCE.txt, engine in
# vendor/impeccable/skill/scripts/VERSION. Per-host variants are generated
# at install time by scripts/generate-host-variants.sh — there are no
# hand-maintained codex-skill/ or opencode-skill/ dirs to read anymore.
skill_ver="?"
engine_ver="?"
if [[ -f "$root/vendor/impeccable/SOURCE.txt" ]]; then
  skill_ver="$(grep -m1 '^tag=' "$root/vendor/impeccable/SOURCE.txt" | sed 's/^tag=skill-v//')"
  engine_ver="$(grep -m1 '^engine=' "$root/vendor/impeccable/SOURCE.txt" | sed 's/^engine=//')"
fi
vf="$root/vendor/impeccable/skill/scripts/VERSION"
if [[ -f "$vf" ]]; then
  tree_engine="$(tr -d '[:space:]' < "$vf")"
  [[ "$tree_engine" != "$engine_ver" ]] && warn "impeccable: SOURCE.txt pins engine $engine_ver but skill/scripts/VERSION reads $tree_engine (lockstep broken in-tree)"
  engine_ver="$tree_engine"
fi
info "impeccable pinned: skill $skill_ver, engine $engine_ver"
latest_skill="$(latest_tag https://github.com/pbakaus/impeccable.git 'skill-v' | sed -E 's/^skill-v//')"
latest_engine_tag="$(latest_tag https://github.com/pbakaus/impeccable.git 'engine-v' | sed -E 's/^engine-v//')"
if [[ -z "$latest_skill" ]]; then offline=1;
elif [[ -n "$latest_skill" && "$latest_skill" != "$skill_ver" ]]; then warn "impeccable skill: pinned $skill_ver, latest tag is $latest_skill";
else info "impeccable skill: current ($skill_ver)"; fi
if [[ -n "$latest_engine_tag" && "$latest_engine_tag" != "$engine_ver" ]]; then warn "impeccable engine: pinned $engine_ver, latest tag is $latest_engine_tag (re-pin skill+engine together — lockstep, A10)";
elif [[ -n "$latest_engine_tag" ]]; then info "impeccable engine: current ($engine_ver)"; fi

# --- GSAP: no tags; compare HEAD commit ---------------------------------------
gsap_pin=""
if [[ -f "$root/SOURCES.md" ]]; then
  gsap_pin="$(grep -m1 '<!-- PIN: gsap ' "$root/SOURCES.md" | sed -n 's/.*commit=\([0-9a-f]*\).*/\1/p')"
  [[ -z "$gsap_pin" ]] && gsap_pin="$(grep -oE 'aed9cfd[0-9a-f]*' "$root/SOURCES.md" | head -1 || true)"
fi
gsap_head="$(latest_commit https://github.com/greensock/gsap-skills.git)"
if [[ -z "$gsap_head" ]]; then offline=1;
elif [[ -n "$gsap_pin" && "$gsap_head" != "$gsap_pin"* ]]; then warn "gsap-skills: pinned ${gsap_pin:0:7}, upstream HEAD is ${gsap_head:0:7}";
else info "gsap-skills: current (${gsap_pin:0:7})"; fi

# --- Taste / Pro Max: pinned tag (SOURCES.md PIN marker) vs latest tag -------
for pair in "taste Leonxlnx/taste-skill" "ui-ux-pro-max nextlevelbuilder/ui-ux-pro-max-skill"; do
  set -- $pair; name="$1"; repo="$2"; url="https://github.com/$repo.git"
  pinned="$(grep -m1 "<!-- PIN: $name " "$root/SOURCES.md" 2>/dev/null | sed -n 's/.*tag=\([^ |]*\).*/\1/p')"
  latest="$(latest_tag "$url")"
  if [[ -z "$latest" ]]; then offline=1
  elif [[ -n "$pinned" && "$pinned" != "$latest" ]]; then warn "$name: pinned $pinned, latest tag is $latest — re-pin with vendor-update.sh $name $latest when ready"
  elif [[ -n "$pinned" ]]; then info "$name: current ($pinned)"
  else info "$name: latest tag $latest (compare with SOURCES.md)"; fi
done

# --- Playwright CLI / MCP: npm latest vs pinned --------------------------------
if command -v npm >/dev/null 2>&1; then
  cli_latest="$(npm view @playwright/cli version 2>/dev/null || true)"
  mcp_latest="$(npm view @playwright/mcp version 2>/dev/null || true)"
  [[ -z "$cli_latest" ]] && offline=1
  [[ -n "$cli_latest" && "$cli_latest" != "0.1.24" ]] && warn "playwright/cli: pinned 0.1.24, npm latest is $cli_latest"
  [[ -n "$cli_latest" && "$cli_latest" == "0.1.24" ]] && info "playwright/cli: current (0.1.24)"
  [[ -n "$mcp_latest" && "$mcp_latest" != "0.0.85" ]] && warn "playwright/mcp: pinned 0.0.85, npm latest is $mcp_latest"
  [[ -n "$mcp_latest" && "$mcp_latest" == "0.0.85" ]] && info "playwright/mcp: current (0.0.85)"
else
  printf 'check-versions: npm not found — Playwright pins not checked.\n'
fi

[[ "$offline" == 1 ]] && printf 'check-versions: some upstreams could not be reached (offline?) — pins unchanged.\n'
[[ "$warns" -gt 0 ]] && printf 'check-versions: %s drift warning(s). Re-pin deliberately; never auto-upgrade at install time.\n' "$warns"
# exit 0 is BY DESIGN (warn-only, 5b): a drift warning must never fail an
# install, and a zero exit does NOT mean "no drift" — read the DRIFT lines.
# The `||` fallback in install.sh is a safety net for an ABNORMAL non-zero
# exit only (script crash / killed), not a branch that fires in normal use.
exit 0
