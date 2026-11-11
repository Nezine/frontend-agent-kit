#!/usr/bin/env bash
# frontend-agent-kit — installer v2.
#
# Non-interactive, Linux-first. Detects the hosts actually present, copies the
# vendored skills into EVERY applicable skills directory (backup-first), then
# best-effort installs the Impeccable hook, the Playwright MCP server, the
# Playwright CLI, and the gitleaks secret scanner (gate 1.1 — without it the
# gate fails closed on a fresh machine). Best-effort steps NEVER fail the install; they are reported
# as PENDING with the exact manual command.
#
#   ./install.sh [--hosts=claude,codex,opencode,...] [--dry-run] [--no-warm]
#                [--skip-hooks] [--skip-mcp] [--skip-eyes]
#
# Contract (phase-1 research/SYNTHESIS.md §3.3 — workspace research note, not shipped in this repo): clone -> read AGENTS.md -> run this script ->
# restart/reload the host -> verify in the NEW session -> report.
# NEVER auto-upgrades vendored pins at install time; scripts/check-versions.sh
# only warns about drift (A4). Figma is EXCLUDED from unattended install
# (human OAuth; see the PENDING report at the end). img2threejs is opt-in only.
#
# Pins (checked 2026-11-10):
#   Playwright CLI  @playwright/cli  0.1.24 (npm latest, re-pinned
#                     2026-11-10 by W-FIX per W-VERSIONS §6: released
#                     2026-11-10T01:17:48Z; depends on Playwright
#                     1.66.0-alpha-1794252756000; bundled Chromium
#                     revision 1254 — VERIFIED 2026-11-10 from the
#                     0.1.24 bundle's own playwright-core browsers.json,
#                     never hardcoded from memory).
#   Playwright MCP  @playwright/mcp  0.0.85 (npm latest, checked 2026-11-10
#                     via `npm view`; 0.0.83 was the 2026-09-28 release —
#                     the pin moved at build time, re-check on re-pin).
#   Impeccable skill/engine pins are NOT hardcoded here: they live in
#   vendor/impeccable/SOURCE.txt (tag skill-v4.8.2, engine 0.1.21, as
#   re-pinned 2026-11-10) and in the canonical tree's scripts/VERSION.
#   The pairing is RESOLVED: skill 4.8.2 pairs with engine 0.1.21
#   (SOURCE.txt engine=0.1.21; skill/scripts/VERSION reads 0.1.21).
#   Per-host skill variants are GENERATED at install time by
#   scripts/generate-host-variants.sh from vendor/impeccable/skill/
#   (SKILL.src.md + placeholders) — never hand-maintained. verify.sh
#   enforces skill<->engine lockstep (A10) against the REPO pin
#   (SOURCE.txt / skill/scripts/VERSION), not installed-vs-installed.
#   The hook step installs the pinned npx spec impeccable@4.8.2 (the kit
#   pin, read from SOURCE.txt at runtime) — never @latest (AGENTS.md §3
#   hard rule); npm latest happens to be 4.8.2 today (VERIFIED via
#   `npm view` 2026-11-10), so the pin changes nothing today and stays
#   correct if upstream moves latest.
#
# Host evidence (worker-self-install.md §7, all VERIFIED from host docs
# 2026-11-10 unless marked): ~/.agents/skills is the cross-agent standard
# path. Codex skills dir is DISPUTED (OpenAI docs + Impeccable README say
# ~/.agents/skills; GSAP README says ~/.codex/skills) — install.sh copies to
# BOTH until the clean-env test resolves it. Gemini MCP: httpUrl = streamable
# HTTP, url = SSE (do not swap). OpenCode MCP: v2 schema ONLY
# (mcp.servers.<name> + disabled, no enabled). Codex MCP: TOML
# [mcp_servers.<name>] — JSON mcpServers is silently ignored. Copilot does
# NOT load Claude/Cursor skill files (GSAP README, VERIFIED) — its working
# artefact is .github/copilot-instructions.md per project repo.
# The `npx impeccable install -y` flag is CLAIMED (secondary sources only),
# so the hook step does NOT rely on -y: it passes --providers/--scope and
# lets a non-TTY failure fall through to PENDING.
# The "4x fewer tokens, ~27k vs ~114k" Playwright figure is CLAIMED (not in
# Microsoft's README) and is never cited by this script.
#
# Priority (2026-11-10): this kit is built for daily
# use on the primary hosts (Claude Code, Codex, OpenCode, Muse Code). The
# main file-copy path is kept simple for them; edge hosts (Gemini, Hermes,
# Copilot, Muse app) get file copies + best-effort extras only — no edge
# host is allowed to complicate or break the primary path.
set -euo pipefail

PLAYWRIGHT_CLI_VERSION="0.1.24"
PLAYWRIGHT_MCP_VERSION="0.0.85"
# Secret scanner for gate 1.1 (F4, 2026-11-11): gitleaks v8.30.1, VERIFIED
# 2026-11-11 against the GitHub releases API (tag v8.30.1, published
# 2026-03-21; assets gitleaks_8.30.1_linux_x64.tar.gz +
# gitleaks_8.30.1_checksums.txt). Pinned — never @latest.
GITLEAKS_VERSION="8.30.1"

KNOWN_HOSTS="claude codex opencode gemini hermes copilot muse cmd"

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
user_home="${HOME:?HOME must be set}"
backup="$user_home/.local/share/frontend-agent-kit/backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"
state_dir="$user_home/.local/share/frontend-agent-kit"
refs_dir="$user_home/.local/share/agent-design-references"

# Impeccable hook pin, read from the repo pin (single source of truth).
# No fallback: if SOURCE.txt is unreadable or carries no tag=skill-v line,
# fail loudly instead of guessing a version (H21 — a hardcoded fallback
# would silently install a stale skill generation while verify.sh checks
# the repo pin). There is no second source to derive from: the vendored
# tree carries the ENGINE version (skill/scripts/VERSION) but no skill
# pin, and SKILL.src.md carries no version field. (fail() is defined
# below, so this uses printf + exit directly. The readability test must
# come FIRST: under `set -euo pipefail` a sed on a missing file exits 2
# and kills the script before any guard below it can print.)
if [[ ! -r "$root/vendor/impeccable/SOURCE.txt" ]]; then
  printf 'ERROR: install.sh: cannot read the Impeccable skill pin — %s is missing or unreadable — refusing to guess a version\n' "$root/vendor/impeccable/SOURCE.txt" >&2
  exit 1
fi
IMPECCABLE_PIN="$(sed -n 's/^tag=skill-v//p' "$root/vendor/impeccable/SOURCE.txt" 2>/dev/null | head -n 1)"
if [[ -z "$IMPECCABLE_PIN" ]]; then
  printf 'ERROR: install.sh: cannot read the Impeccable skill pin from %s (no tag=skill-v line) — refusing to guess a version\n' "$root/vendor/impeccable/SOURCE.txt" >&2
  exit 1
fi

hosts_filter=""
hosts_flag=0
dry_run=0
no_warm=0
skip_hooks=0
skip_mcp=0
skip_eyes=0
pending_file=""
declare -a PENDING=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [--hosts=H1,H2] [--dry-run] [--no-warm] [--skip-hooks] [--skip-mcp] [--skip-eyes]

Installs frontend-agent-kit skills for every detected host on Linux.
  --hosts=LIST   only these hosts: claude,codex,opencode,gemini,hermes,copilot,muse,cmd
  --dry-run      print planned actions, write nothing
  --no-warm      skip the first-run Impeccable engine download
  --skip-hooks   skip the Impeccable hook install step
  --skip-mcp     skip the Playwright MCP server adds
  --skip-eyes    skip Playwright CLI + browser install
Existing same-named skills are moved to a dated backup first.
Afterwards: restart/reload each host, then run ./verify.sh in a NEW session.
EOF
}

note_pending() { PENDING+=("$1"); printf 'PENDING: %s\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit "${2:-1}"; }

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --dry-run) dry_run=1 ;;
    --no-warm) no_warm=1 ;;
    --skip-hooks) skip_hooks=1 ;;
    --skip-mcp) skip_mcp=1 ;;
    --skip-eyes) skip_eyes=1 ;;
    --hosts=*) hosts_filter="${arg#--hosts=}"; hosts_flag=1 ;;
    *) printf 'Unknown argument: %s\nRun ./install.sh --help\n' "$arg" >&2; exit 2 ;;
  esac
done

[[ "$(uname -s)" == Linux ]] || fail "This package currently supports Linux only. macOS/Windows install paths are open work, not verified — see phase-1 research/SYNTHESIS.md §7 (workspace research note, not shipped in this repo)."

# --- prerequisites: hard for the copy path, soft (warn) for node ----------
# DECISION (5c, recorded 2026-11-10): python3 and git stay HARD prereqs
# (fail with a clear error, below) — they are load-bearing, not optional.
# python3 runs the host-variant generator (without it no Impeccable skill
# is generated at all) and verify.sh (fixture server + port pick) and the
# Playwright curl-fallback extraction; git runs the version check. Softening
# them to warn + PENDING would produce a half-installed kit that verify.sh
# then fails anyway, with a worse error. cp/mv/mkdir/date are coreutils the
# copy path cannot run without. node is the only soft one: without it the
# file-copy install still works and hook/MCP/Playwright become PENDING.
for tool in cp mv mkdir date python3 git; do
  if ! command -v "$tool" >/dev/null; then
    case "$tool" in
      python3) fail "Missing command: python3 — install.sh needs it to generate the Impeccable host variants (scripts/generate-host-variants.sh), to run verify.sh, and to extract the Playwright browser zip in the curl fallback. Install Python 3 and re-run." ;;
      git) fail "Missing command: git — install.sh needs it for the version check (scripts/check-versions.sh) and for the clone fallback in AGENTS.md §1 step 2. Install git and re-run." ;;
      *) fail "Missing command: $tool — the file-copy install cannot run without it." ;;
    esac
  fi
done
have_node=0
if command -v node >/dev/null 2>&1; then have_node=1; else
  printf 'WARNING: node not found — hook, MCP and Playwright steps will be skipped (reported as PENDING). File-copy install still works.\n' >&2
fi
# H14 — ONE number, everywhere: Node 22+. The orchestrator (frontend-kit
# SKILL.md step 0.3) and consistency.mjs (built-in WebSocket) both require
# Node 22+; the old "Node 18+" strings (now fixed to 22+ above and in the
# PENDING notes) were never enforced, so a Node 18/20 machine installed
# cleanly and the step-3 gate then failed opaquely at runtime. Enforcement:
# a present-but-too-old Node disables every Node-dependent step below
# (node_ok=0) with an explicit PENDING note naming the version found, and
# verify.sh fails the run on it. verify.sh is the gate; install.sh keeps
# the file-copy path working.
node_ok=0
node_ver=""
node_old=0
if [[ "$have_node" == 1 ]]; then
  node_ver="$(node --version 2>/dev/null || echo '')"
  _nm="${node_ver#v}"; _nm="${_nm%%.*}"
  if [[ "$_nm" =~ ^[0-9]+$ ]] && [[ "$_nm" -ge 22 ]]; then
    node_ok=1
  else
    node_old=1
    printf 'WARNING: Node %s found — the kit requires Node 22+ (frontend-kit SKILL.md step 0.3; gate.mjs consistency.mjs needs the built-in WebSocket). Node-dependent steps (hook, MCP, Playwright) will be skipped (reported as PENDING). File-copy install still works.\n' "${node_ver:-unknown}" >&2
  fi
fi
have_npx=0; command -v npx >/dev/null 2>&1 && have_npx=1
if [[ "$have_node" == 1 && "$have_npx" == 0 ]]; then
  # node without npx (a partial Node install): the hook/MCP/Playwright
  # steps below are gated on have_npx, so without this warning + the
  # PENDING notes in each step they would silently never run (5c).
  printf 'WARNING: npx not found (node is present) — hook, MCP and Playwright steps will be skipped (reported as PENDING). Reinstall Node 22+ (npx ships with it). File-copy install still works.\n' >&2
fi
have_timeout=0; command -v timeout >/dev/null 2>&1 && have_timeout=1

# --- host detection -------------------------------------------------------
# Env vars first (CLAUDECODE, GEMINI_CLI), then binaries, then config dirs.
# Detection failing is NOT fatal: fall back to every known host (v1 approach).
detect_hosts() {
  local found=""
  add_host() { case " $found " in *" $1 "*) ;; *) found="$found $1" ;; esac; }
  [[ "${CLAUDECODE:-}" == "1" ]] && add_host claude
  [[ "${GEMINI_CLI:-}" == "1" ]] && add_host gemini
  command -v claude >/dev/null 2>&1 && add_host claude
  command -v codex >/dev/null 2>&1 && add_host codex
  command -v opencode >/dev/null 2>&1 && add_host opencode
  command -v gemini >/dev/null 2>&1 && add_host gemini
  command -v hermes >/dev/null 2>&1 && add_host hermes
  command -v cmd >/dev/null 2>&1 && add_host cmd
  [[ -d "$user_home/.claude" ]] && add_host claude
  [[ -d "$user_home/.codex" ]] && add_host codex
  [[ -d "$user_home/.config/opencode" ]] && add_host opencode
  [[ -d "$user_home/.gemini" ]] && add_host gemini
  [[ -d "$user_home/.hermes" ]] && add_host hermes
  [[ -d "$user_home/.copilot" ]] && add_host copilot
  [[ -d "$user_home/workspace/custom-skills" ]] && add_host muse
  # Muse Code reads ~/.agents/skills natively; a bare ~/.agents/skills dir
  # does not by itself prove a host, so it adds no host here.
  printf '%s' "$found"
}

if [[ "$hosts_flag" == 1 ]]; then
  # --hosts= (empty) must error, not silently install detected hosts (6d):
  # an empty value is a typo, and silently falling back to auto-detect
  # would install hosts the user never asked for.
  if [[ -z "${hosts_filter//[ ,]/}" ]]; then
    fail "--hosts= is empty — pass a comma-separated host list (known: $KNOWN_HOSTS) or omit --hosts to auto-detect" 2
  fi
  IFS=',' read -r -a wanted <<< "$hosts_filter"
  hosts=""
  for h in "${wanted[@]}"; do
    case " $KNOWN_HOSTS " in *" $h "*) hosts="$hosts $h" ;;
      *) fail "Unknown host in --hosts=: $h (known: $KNOWN_HOSTS)" 2 ;;
    esac
  done
else
  hosts="$(detect_hosts)"
  no_host_fallback=0
  if [[ -z "${hosts// }" ]]; then
    # H18: the no-host fallback installs to skills dirs ONLY. It must NOT
    # write ~/.github/copilot-instructions.md — that is a LIVE
    # personal-instructions file VS Code Copilot reads, not an inert skills
    # copy, and a machine with no host detected never asked for Copilot.
    # installed-hosts.txt still lists all hosts (so verify.sh checks the
    # skills dirs), but the Copilot file is written only when Copilot is a
    # detected/selected host (see the Copilot block below).
    no_host_fallback=1
    printf 'No host detected (no host binary, env var or config dir found) — installing to every known skills dir (harmless; each host reads its own). The Copilot personal-instructions file is NOT written by this fallback.\n'
    hosts=" $KNOWN_HOSTS"
  fi
fi
# Normalise: trim leading space, keep primary hosts first.
ordered=""
for h in claude codex opencode gemini hermes copilot muse cmd; do
  case "$hosts" in *" $h"*|"$h"*) ordered="$ordered $h" ;; esac
done
hosts="${ordered# }"
# H18 (decided HERE, before any copying): Copilot is a real host only if it
# was explicitly selected (--hosts=...copilot...) or a ~/.copilot dir already
# existed when install started. The copy phase below creates
# ~/.copilot/skills/ in the no-host fallback, so checking the dir later
# (in the Copilot block) would fool itself — the fallback would write the
# live personal-instructions file it must not write.
copilot_requested=0
if [[ "$hosts_flag" == 1 ]]; then
  case " $hosts " in *" copilot "*) copilot_requested=1 ;; esac
elif [[ -d "$user_home/.copilot" ]]; then
  copilot_requested=1
fi
printf 'Hosts: %s\n' "$hosts"
printf 'Backup dir: %s\n' "$backup"
[[ "$dry_run" == 1 ]] && printf 'DRY RUN — nothing will be written.\n'

# --- skill inventory (dynamic: works with the v1 tree AND the v2 tree) ----
# Canonical skills/: every dir with SKILL.md. GSAP: vendor/gsap/*.
# Impeccable: single canonical copy if present (v2), else the v1 variants
# (codex-skill = generic, opencode-skill = OpenCode-only).
declare -a CANON_SKILLS=()
for d in "$root"/skills/*/; do
  [[ -f "${d}SKILL.md" ]] && CANON_SKILLS+=("$(basename "$d")")
done
declare -a GSAP_SKILLS=()
for d in "$root"/vendor/gsap/*/; do
  [[ -f "${d}SKILL.md" ]] && GSAP_SKILLS+=("$(basename "$d")")
done
impeccable_generic=""
impeccable_opencode=""
impeccable_variant_dir=""  # staging dir holding generated per-host variants
if [[ -f "$root/vendor/impeccable/skill/SKILL.src.md" ]]; then
  # v2 layout (re-pin 4.8.2, engine 0.1.21 — see vendor/impeccable/SOURCE.txt):
  # single canonical copy; per-host variants are GENERATED, never
  # hand-maintained, by scripts/generate-host-variants.sh.
  if [[ ! -x "$root/scripts/generate-host-variants.sh" ]]; then
    fail "Canonical Impeccable copy present but scripts/generate-host-variants.sh is missing/not executable — cannot build per-host variants"
  fi
  if [[ "$dry_run" == 1 ]]; then
    printf 'would generate Impeccable host variants (agents/claude-code/opencode/gemini) from vendor/impeccable/skill/\n'
    # Dry-run has no generated tree to copy from; point the copy loop at
    # the path the variants WILL have, so the listing below shows the
    # impeccable install per host (6g: dry-run must list everything it
    # would install). install_dir's dry-run path prints without
    # requiring the source to exist yet.
    impeccable_variant_dir="<generated-variants>"
  else
    impeccable_variant_dir="$(mktemp -d)"
    if ! "$root/scripts/generate-host-variants.sh" --all --out "$impeccable_variant_dir" >"$impeccable_variant_dir.log" 2>&1; then
      cat "$impeccable_variant_dir.log" >&2 || true
      fail "scripts/generate-host-variants.sh failed — Impeccable variants not generated (see output above)"
    fi
    printf 'Generated Impeccable host variants in %s\n' "$impeccable_variant_dir"
  fi
elif [[ -f "$root/vendor/impeccable/SKILL.md" ]]; then
  impeccable_generic="$root/vendor/impeccable"
  impeccable_opencode="$root/vendor/impeccable"
elif [[ -f "$root/vendor/impeccable/codex-skill/SKILL.md" ]]; then
  impeccable_generic="$root/vendor/impeccable/codex-skill"
fi
[[ -f "$root/vendor/impeccable/opencode-skill/SKILL.md" ]] && impeccable_opencode="$root/vendor/impeccable/opencode-skill"

# Variant of the Impeccable skill for one kit host. Generator hosts are
# agents|claude-code|opencode|gemini; the agents variant (Codex-style, $
# prefix, plain skill files) is the generic one for hosts without their own
# (CommandCode, Muse, Hermes, and the Copilot fallback copy).
impeccable_source_for_host() {
  local host="$1"
  if [[ -n "$impeccable_variant_dir" ]]; then
    case "$host" in
      claude)   printf '%s' "$impeccable_variant_dir/claude-code/impeccable" ;;
      opencode) printf '%s' "$impeccable_variant_dir/opencode/impeccable" ;;
      gemini)   printf '%s' "$impeccable_variant_dir/gemini/impeccable" ;;
      *)        printf '%s' "$impeccable_variant_dir/agents/impeccable" ;;
    esac
    return 0
  fi
  if [[ "$host" == opencode && -n "$impeccable_opencode" ]]; then
    printf '%s' "$impeccable_opencode"
  elif [[ -n "$impeccable_generic" ]]; then
    printf '%s' "$impeccable_generic"
  fi
}

[[ "${#CANON_SKILLS[@]}" -gt 0 || "${#GSAP_SKILLS[@]}" -gt 0 || -n "$impeccable_generic" \
   || -f "$root/vendor/impeccable/skill/SKILL.src.md" ]] \
  || fail "No skills found in $root (expected skills/*/SKILL.md, vendor/gsap/*, vendor/impeccable/*)"

# skills dir per host. ~/.agents/skills is the cross-agent standard and is
# included for every host that reads it (Codex, OpenCode, Gemini, Hermes,
# Muse Code, CommandCode) — one copy there serves them all.
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

install_dir() { # <source> <target>
  local source="$1" target="$2" relative
  # Dry-run prints the plan without requiring sources to exist yet (the
  # generated Impeccable variants do not exist until generation runs).
  if [[ "$dry_run" == 1 ]]; then printf 'would install %s -> %s\n' "$source" "$target"; return 0; fi
  [[ -d "$source" ]] || fail "Missing package directory: $source"
  mkdir -p "$(dirname -- "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    relative="${target#"$user_home"/}"
    mkdir -p "$backup/$(dirname -- "$relative")"
    mv -- "$target" "$backup/$relative"
    printf 'Backed up %s\n' "$target"
  fi
  if ! cp -a -- "$source" "$target"; then
    # cp -a fails on filesystems that reject dir chown (EPERM, "failed
    # to preserve ownership", exit 1 — seen 2026-11-10 on the workspace
    # overlay/btrfs). Fall back to cp -r (best-effort preservation) and
    # record it. The failed cp -a may have left a partial target, so
    # remove it first: it was just created by that failed copy, and any
    # pre-existing content was already moved to the backup above.
    printf 'WARNING: cp -a failed for %s (filesystem rejects ownership preservation) — falling back to cp -r (best-effort preservation).\n' "$source" >&2
    mkdir -p "$state_dir"
    printf '%s: cp -a failed, used cp -r fallback: %s -> %s\n' "$(date -u +%FT%TZ)" "$source" "$target" >> "$state_dir/copy-fallbacks.log"
    rm -rf -- "$target"
    cp -r -- "$source" "$target" || fail "copy failed even with cp -r fallback: $source -> $target"
    printf 'Installed %s (via cp -r fallback; ownership/timestamps best-effort)\n' "$target"
    return 0
  fi
  printf 'Installed %s\n' "$target"
}

install_file() { # <source> <target>
  local source="$1" target="$2" relative
  if [[ "$dry_run" == 1 ]]; then printf 'would install %s -> %s\n' "$source" "$target"; return 0; fi
  [[ -f "$source" ]] || fail "Missing package file: $source"
  mkdir -p "$(dirname -- "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    relative="${target#"$user_home"/}"
    mkdir -p "$backup/$(dirname -- "$relative")"
    mv -- "$target" "$backup/$relative"
    printf 'Backed up %s\n' "$target"
  fi
  if ! cp -a -- "$source" "$target"; then
    # Same cp -a EPERM fallback as install_dir (see above).
    printf 'WARNING: cp -a failed for %s — falling back to cp -r (best-effort preservation).\n' "$source" >&2
    mkdir -p "$state_dir"
    printf '%s: cp -a failed, used cp -r fallback: %s -> %s\n' "$(date -u +%FT%TZ)" "$source" "$target" >> "$state_dir/copy-fallbacks.log"
    rm -rf -- "$target"
    cp -r -- "$source" "$target" || fail "copy failed even with cp -r fallback: $source -> $target"
    printf 'Installed %s (via cp -r fallback)\n' "$target"
    return 0
  fi
  printf 'Installed %s\n' "$target"
}

# --- copy -----------------------------------------------------------------
declare -A DONE_DIRS=()
for host in $hosts; do
  while IFS= read -r dir || [[ -n "$dir" ]]; do
    [[ -z "$dir" ]] && continue
    case " ${DONE_DIRS[$dir]:-} " in *done*) continue ;; esac
    DONE_DIRS["$dir"]=done
    for name in "${CANON_SKILLS[@]}"; do
      install_dir "$root/skills/$name" "$dir/$name"
    done
    for name in "${GSAP_SKILLS[@]}"; do
      install_dir "$root/vendor/gsap/$name" "$dir/$name"
    done
    imp_src="$(impeccable_source_for_host "$host")"
    if [[ -n "$imp_src" ]]; then
      install_dir "$imp_src" "$dir/impeccable"
    fi
  done < <(skills_dirs_for_host "$host")
  # OpenCode command shims (commands != skills in OpenCode).
  if [[ "$host" == opencode ]]; then
    for f in "$root"/opencode/commands/*.md "$root"/.opencode/commands/*.md; do
      [[ -f "$f" ]] || continue
      install_file "$f" "$user_home/.config/opencode/commands/$(basename "$f")"
    done
  fi
done

# Reference data (not skills): Pro Max + Taste trees.
[[ -d "$root/vendor/ui-ux-pro-max/reference" ]] && install_dir "$root/vendor/ui-ux-pro-max/reference" "$refs_dir/ui-ux-pro-max"
# Taste (F5): the old copy target vendor/taste/reference/ does not exist
# in the v2 tree (there is no reference/ dir — the v1 monolith is gone),
# so the old one-liner silently installed NOTHING while the installed
# wrapper (skills/taste-reference/SKILL.md) cites vendor/taste/skills/…
# paths that resolved nowhere post-install. Fix: install the real,
# runnable taste-skill subset to $refs_dir/taste, and point each
# installed taste-reference skill's vendor/ at it, so every path the
# wrapper cites resolves relative to the installed skill dir.
# Runnable subset installed (recorded — see vendor/taste/SOURCE.txt):
#   skills/  — the whole taste-skill dir (SKILL.md + references/ +
#              scripts/ incl. consistency.mjs, gate.mjs, copy-lint.mjs +
#              library/ palettes.json, type.json + assets/ incl.
#              diagrams/presets.json). This is the pipeline the wrapper
#              cites; without it the checker/gate cannot run.
#   assets/  — top-level taste assets (1 webp; kept for completeness).
#   SOURCE.txt — provenance (tag v2.5.1, commit).
# NOT installed: examples/, tests/, CHANGELOG.md, LICENSE, README.md,
# upstream install.sh, host adapter dirs (.agents/, .claude-plugin/,
# .codex-plugin/, .github/) — docs/examples, not the runnable pipeline.
if [[ -d "$root/vendor/taste/skills" ]]; then
  install_dir "$root/vendor/taste/skills" "$refs_dir/taste/skills"
  [[ -d "$root/vendor/taste/assets" ]] && install_dir "$root/vendor/taste/assets" "$refs_dir/taste/assets"
  [[ -f "$root/vendor/taste/SOURCE.txt" ]] && install_file "$root/vendor/taste/SOURCE.txt" "$refs_dir/taste/SOURCE.txt"
else
  printf 'WARNING: vendor/taste/skills/ missing — taste pipeline NOT installed; the taste-reference wrapper paths will dangle.\n' >&2
fi
# Point each installed taste-reference skill's vendor/ at the installed
# taste tree, so the wrapper's repo-relative citations
# (vendor/taste/skills/taste-skill/…) resolve from the installed skill
# dir. A symlink, not a second 40M copy per host — the tree lives once
# in $refs_dir/taste. verify.sh checks every cited path resolves.
if [[ -d "$refs_dir/taste/skills" || "$dry_run" == 1 ]]; then
  for dir in "${!DONE_DIRS[@]}"; do
    if [[ "$dry_run" == 1 ]]; then printf 'would link %s/taste-reference/vendor -> %s\n' "$dir" "$refs_dir"; continue; fi
    [[ -d "$dir/taste-reference" ]] || continue
    [[ -d "$refs_dir/taste/skills" ]] || continue
    ln -sfn -- "$refs_dir" "$dir/taste-reference/vendor"
    printf 'Linked %s/vendor -> %s\n' "$dir/taste-reference" "$refs_dir"
  done
fi

# Copilot (F8): Copilot does NOT load SKILL.md files, so the fallback
# copy in ~/.copilot/skills is not a working Copilot install. Its working
# artefact is .github/copilot-instructions.md — install the repo's copy
# as the user's personal instructions file when copilot is installed.
# (User-level path: CLAIMED — VS Code reads workspace .github/ for sure;
# the $HOME-level personal file is the documented personal-instructions
# location in recent VS Code Copilot; if a given VS Code build ignores
# it, the per-project copy in the repo's own .github/ still applies.)
# H18: write the live Copilot personal-instructions file ONLY when Copilot
# is a detected/selected host (copilot_requested, decided before copying —
# see above). The no-host fallback must NOT write it. Touch the marker
# verify.sh reads (copilot-instructions-installed) ONLY here, so verify.sh
# fails (not warns) if the file later goes missing.
if [[ "$copilot_requested" == 1 ]]; then
  install_file "$root/.github/copilot-instructions.md" "$user_home/.github/copilot-instructions.md"
  mkdir -p "$state_dir"
  touch "$state_dir/copilot-instructions-installed"
fi

if [[ "$dry_run" == 1 ]]; then
  # Best-effort steps are skipped in dry-run — list them anyway so the
  # plan shows everything the real run would attempt (6g), pinned.
  printf 'would attempt (best-effort, never fatal) with pinned versions:\n'
  printf '  - Impeccable hook: npx --yes impeccable@%s install --providers=<detected claude/codex> --scope=global (skipped with --skip-hooks)\n' "$IMPECCABLE_PIN"
  printf '  - Playwright CLI: npm install -g @playwright/cli@%s, then playwright-cli install-browser chrome-for-testing (skipped with --skip-eyes)\n' "$PLAYWRIGHT_CLI_VERSION"
  printf '  - Playwright MCP: host-CLI adds of npx -y @playwright/mcp@%s (skipped with --skip-mcp)\n' "$PLAYWRIGHT_MCP_VERSION"
  printf '  - Secret scanner (gate 1.1): gitleaks v%s pinned tarball to ~/.local/bin (skipped if gitleaks or trufflehog is already on PATH)\n' "$GITLEAKS_VERSION"
  printf '  - Figma MCP: NOT installed (human OAuth — by design)\n'
  printf '\nDRY RUN complete — no files written, no hooks/MCP/verify attempted.\n'
  exit 0
fi

# Record what was installed, for verify.sh.
mkdir -p "$state_dir"
# W-FIX-STALE 2026-11-10: truncate the skip record at the start of EVERY
# install, before any --skip-* branch appends below. The three appends
# (eyes/hooks/mcp) used to be append-only, so a skip recorded by one
# install survived a later install into the same HOME that did NOT skip —
# and verify.sh §6/§8 trust this file, so they wrongly reported the step
# PENDING even though it had just been installed. Truncating here makes
# the file reflect ONLY this install's skip flags: a non-skip install
# leaves it empty, a skipped install lists exactly what was skipped
# this time. (Dry-run exits above, so it never touches the file.)
: > "$state_dir/skipped-subsystems.txt"
printf '%s\n' $hosts > "$state_dir/installed-hosts.txt"
printf '%s\n' "$backup" > "$state_dir/last-backup.txt"

# --- version check (warn only, never upgrades) ----------------------------
# The `||` below is NOT a dead branch (5b): scripts/check-versions.sh
# exits 0 BY DESIGN (warn-only — see its own footer comment), so the
# fallback never fires on a normal run. It is a defensive net for an
# ABNORMAL non-zero exit only (script crash, killed by timeout/signal,
# unreadable) — the install must say so rather than silently proceeding
# as if the check ran.
if [[ -x "$root/scripts/check-versions.sh" ]]; then
  printf '\nVersion check (warn only — pins are never auto-upgraded):\n'
  "$root/scripts/check-versions.sh" || printf 'WARNING: version check could not complete (offline?). Pins unchanged.\n'
fi

# --- best-effort helpers ---------------------------------------------------
run_best_effort() { # <label> <timeout-secs> <cmd...>
  local label="$1"; shift
  local secs="$1"; shift
  if [[ "$have_timeout" == 1 ]]; then
    timeout "$secs" "$@" >>"$state_dir/install.log" 2>&1 && { printf 'OK: %s\n' "$label"; return 0; }
  else
    "$@" >>"$state_dir/install.log" 2>&1 && { printf 'OK: %s\n' "$label"; return 0; }
  fi
  printf 'FAILED (non-fatal): %s — see %s/install.log\n' "$label" "$state_dir"
  return 1
}
# H6 — read-back helpers. run_best_effort trusts the exit code; for hook
# and MCP adds that is not enough (a stub binary exiting 0 without writing
# anything used to print "OK"). run_quiet runs a command into install.log
# and prints NOTHING, so "OK" is printed only after the read-back below
# confirms the registration in the host's actual config. Where no readable
# config exists, the step is UNVERIFIED with the reason — never OK.
run_quiet() { # <timeout-secs> <cmd...>
  local secs="$1"; shift
  if [[ "$have_timeout" == 1 ]]; then timeout "$secs" "$@" >>"$state_dir/install.log" 2>&1; else "$@" >>"$state_dir/install.log" 2>&1; fi
}
mcp_config_for_host() { # <host> — config file(s) the host CLI writes (same list as verify.sh §8)
  case "$1" in
    claude)   printf '%s\n%s\n' "$user_home/.claude.json" "$user_home/.claude/settings.json" ;;
    codex)    printf '%s' "$user_home/.codex/config.toml" ;;
    opencode) printf '%s' "$user_home/.config/opencode/opencode.json" ;;
    gemini)   printf '%s' "$user_home/.gemini/settings.json" ;;
  esac
}
mcp_manual_for_host() { # <host>
  case "$1" in
    claude)   printf '%s' "claude mcp add --scope user playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION" ;;
    codex)    printf '%s' "codex mcp add playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION" ;;
    opencode) printf '%s' "opencode mcp add playwright --global -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION" ;;
    gemini)   printf '%s' "gemini mcp add --scope user playwright npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION" ;;
  esac
}
hook_wired() { # 0 if any known hook manifest mentions impeccable (same list as verify.sh §8)
  local f
  for f in "$user_home/.claude/settings.json" "$user_home/.claude/settings.local.json" \
           "$user_home/.codex/hooks.json" "$user_home/.codex/config.toml" \
           "$user_home/.gemini/settings.json"; do
    [[ -f "$f" ]] && grep -qi 'impeccable' "$f" && return 0
  done
  ls "$user_home/.hermes/plugins" 2>/dev/null | grep -qi 'impeccable' && return 0
  return 1
}
mcp_add_checked() { # <host> <label> <cmd...>
  local host="$1"; shift; local label="$1"; shift
  if ! run_quiet 120 "$@"; then
    printf 'FAILED (non-fatal): %s — see %s/install.log\n' "$label" "$state_dir"
    note_pending "Playwright MCP not added to $host. Run: $(mcp_manual_for_host "$host")"
    return 1
  fi
  local found=0 cf
  while IFS= read -r cf || [[ -n "$cf" ]]; do
    [[ -f "$cf" ]] && grep -qi 'playwright' "$cf" && found=1
  done < <(mcp_config_for_host "$host")
  if [[ "$found" == 1 ]]; then
    printf 'OK: %s (verified — playwright entry confirmed in host config)\n' "$label"
    return 0
  fi
  printf 'UNVERIFIED (H6): %s exited 0 but no playwright entry was found in the host config (%s) — the host CLI did not register it (a stub binary exiting 0 looks exactly like this). NOT reporting OK.\n' "$label" "$(mcp_config_for_host "$host" | tr '\n' ' ')"
  note_pending "Playwright MCP add for $host reported success but no playwright entry exists in the host config — NOT verified as wired (H6). Run: $(mcp_manual_for_host "$host") and confirm the entry appears in the host config."
  return 1
}
: > "$state_dir/install.log" 2>/dev/null || true

# --- Playwright browser download: curl resume fallback (F2) ---------------
# The CLI's own Node downloader has no resume: on this network it dies at
# ~90% with "Download failed: server closed connection" (cdn.playwright.dev)
# and restarts from 0% on each of its 5 internal retries, so the install
# never completes (reproduced 2026-11-10: 4 attempts in 500s, all dying at
# 90%). curl -C - fetches the identical zip in one transfer (chrome-
# linux64.zip, 207,460,506 B for CLI 0.1.24, VERIFIED 2026-11-10 via
# HEAD on the CDN URL). When the CLI download
# fails, the fallback below fetches the failed URL(s) with curl (the partial
# file stays under $state_dir/playwright-downloads/, so a re-run RESUMES
# instead of restarting), then reproduces the CLI's own post-download steps
# in the CLI's expected cache layout (VERIFIED against @playwright/cli
# 0.1.24's bundled playwright-core registry — lib/coreBundle.js +
# browsers.json). The headless-shell zip is NOT in the log on this network
# (the CLI dies during chrome retries — see playwright_curl_fallback), so
# the fallback derives its URL from the chrome URL (same CDN version
# directory) and fetches it through the same path. Post-download, the
# fallback reproduces the CLI's own steps:
#   ~/.cache/ms-playwright/<name>-<revision>/ + an empty
#   INSTALLATION_COMPLETE marker (the marker is what makes the CLI skip the
#   download on re-run), per-entry Unix permissions restored from the zip
#   (E-1: extractall drops exec bits — see playwright_curl_one), AND the
#   .links entry the
#   CLI's `install-browser --list` reads (F-C, 2026-11-10): a file named
#   sha1(<playwright-core dir path>, no trailing newline) whose content is
#   that path, also with no trailing newline — without it --list ENOENTs
#   on a fallback-only cache. The directory name replaces
#   dashes with underscores in the prefix (chromium_headless_shell-1254);
#   revisions come from the CLI's own browsers.json, never hardcoded.
# No browser is vendored in the repo. After placing the file(s) the
# installer re-runs the CLI install once (it skips the placed artifact via
# the marker and fetches the rest) and confirms with --list.
playwright_revision() { # <browser-name> — revision from the CLI bundle's browsers.json
  local name="$1" cli_dir bj
  cli_dir="$(dirname -- "$(readlink -f "$(command -v playwright-cli)")")"
  bj="$cli_dir/node_modules/playwright-core/browsers.json"
  [[ -f "$bj" ]] || return 1
  node -e "const b=require(process.argv[1]).browsers.find((x)=>x.name===process.argv[2]); if(!b) process.exit(1); console.log(b.revision)" "$bj" "$name" 2>/dev/null
}
playwright_curl_one() { # <url> — fetch one failed artifact with curl -C - and place it
  local url="$1" fname name exe_rel rev dir_name zip_path dest cli_dir core_dir links_dir link_name
  fname="$(basename -- "${url%%\?*}")"
  case "$url" in
    */builds/cft/*/linux64/chrome-linux64.zip)
      name="chromium"; exe_rel="chrome-linux64/chrome" ;;
    */builds/cft/*/linux64/chrome-headless-shell-linux64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-linux64/chrome-headless-shell" ;;
    */builds/ffmpeg/*/ffmpeg-linux.zip)
      name="ffmpeg"; exe_rel="ffmpeg-linux" ;;
    *)
      printf 'curl fallback: unknown artifact URL (no cache-layout mapping — not guessing): %s\n' "$url"
      return 1 ;;
  esac
  rev="$(playwright_revision "$name")" || { printf 'curl fallback: cannot read the %s revision from the CLI bundle (browsers.json).\n' "$name"; return 1; }
  dir_name="${name//-/_}-$rev"
  mkdir -p "$state_dir/playwright-downloads"
  zip_path="$state_dir/playwright-downloads/$fname"
  printf 'curl fallback: fetching %s with curl -C - (resume; partial file kept at %s)...\n' "$url" "$zip_path"
  if ! curl -C - -L -o "$zip_path" "$url"; then
    printf 'curl fallback: curl failed for %s (partial file kept at %s — re-run the installer to resume).\n' "$url" "$zip_path"
    return 1
  fi
  [[ -s "$zip_path" ]] || { printf 'curl fallback: empty file for %s.\n' "$url"; return 1; }
  dest="$user_home/.cache/ms-playwright/$dir_name"
  printf 'curl fallback: placing %s into the CLI cache layout %s ...\n' "$fname" "$dest"
  rm -rf -- "$dest"
  mkdir -p -- "$dest"
  # E-1 (2026-11-10): zipfile.extractall does NOT restore Unix permissions —
  # it writes every file 0664 (umask), so chrome_crashpad_handler,
  # chrome_sandbox and chrome-wrapper were left non-executable and Chrome
  # SIGABRTed at launch (posix_spawn .../chrome_crashpad_handler:
  # Permission denied (13)). The old code chmodded only the main exe
  # ($exe_rel), so a fallback-placed browser could never launch and no
  # retry could fix it. Restore each entry's stored mode from the zip's
  # external_attr (the pinned chrome-linux64.zip stores 0755 for chrome,
  # chrome-wrapper, chrome_crashpad_handler, chrome_sandbox and the .so
  # libs, 0644 for data files, 0755 for dirs — VERIFIED 2026-11-10
  # against the downloaded archive; entries with no stored mode keep
  # extractall's default). The expected executable is then checked
  # executable, with an explicit chmod 755 as a safety net for an
  # archive that stored no mode for it.
  if ! python3 -c '
import os, sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
for info in z.infolist():
    z.extract(info, sys.argv[2])
    mode = (info.external_attr >> 16) & 0o7777
    if mode:
        os.chmod(os.path.join(sys.argv[2], info.filename), mode)
' "$zip_path" "$dest"; then
    printf 'curl fallback: extraction failed for %s.\n' "$zip_path"; return 1
  fi
  if [[ -n "$exe_rel" ]]; then
    [[ -f "$dest/$exe_rel" ]] || { printf 'curl fallback: expected executable %s not in the archive.\n' "$dest/$exe_rel"; return 1; }
    [[ -x "$dest/$exe_rel" ]] || chmod 755 -- "$dest/$exe_rel"
    [[ -x "$dest/$exe_rel" ]] || { printf 'curl fallback: expected executable %s is not executable after permission restore.\n' "$dest/$exe_rel"; return 1; }
  fi
  : > "$dest/INSTALLATION_COMPLETE"
  # F-C (2026-11-10): the CLI's `install-browser --list` reads
  # ~/.cache/ms-playwright/.links/<sha1(playwright-core-dir)> (content =
  # the playwright-core dir path, no trailing newline) and ENOENTs when
  # the dir is absent — a fallback-only cache failed --list even though
  # the browser was placed. Reproduce the CLI's own entry exactly
  # (format VERIFIED 2026-11-10 against a CLI-created entry: sha1 of the
  # path with no trailing newline IS the filename; the file holds the
  # path, also with no trailing newline). Best-effort: the marker above
  # is what makes the CLI skip re-downloading; the .links entry only
  # repairs --list. Never overwrite an existing entry.
  cli_dir="$(dirname -- "$(readlink -f "$(command -v playwright-cli)")")"
  core_dir="$cli_dir/node_modules/playwright-core"
  links_dir="$user_home/.cache/ms-playwright/.links"
  link_name="$(printf '%s' "$core_dir" | sha1sum 2>/dev/null | awk '{print $1}')"
  if [[ -z "$link_name" ]] && command -v python3 >/dev/null 2>&1; then
    link_name="$(printf '%s' "$core_dir" | python3 -c 'import sys,hashlib; print(hashlib.sha1(sys.stdin.buffer.read()).hexdigest())' 2>/dev/null)"
  fi
  if [[ -n "$link_name" ]]; then
    mkdir -p -- "$links_dir"
    if [[ ! -f "$links_dir/$link_name" ]]; then
      printf '%s' "$core_dir" > "$links_dir/$link_name"
      printf 'curl fallback: wrote .links entry %s (so `playwright-cli install-browser --list` sees this cache).\n' "$link_name"
    fi
  else
    printf 'curl fallback: WARNING — could not compute the .links entry name (no sha1sum/python3); --list may fail on this fallback-only cache, but the browser itself is placed.\n'
  fi
  printf 'curl fallback: %s installed at %s (INSTALLATION_COMPLETE marker written — the CLI will skip re-downloading it).\n' "$name" "$dest"
  return 0
}
playwright_curl_fallback() { # reads $state_dir/install.log for the failed URL(s)
  command -v curl >/dev/null 2>&1 || { printf 'curl fallback unavailable: curl not found.\n'; return 1; }
  local log="$state_dir/install.log" urls url ok=1 chrome_url="" hs_url=""
  urls="$(grep -oE 'URL: https://[^ ]+\.zip' "$log" 2>/dev/null | sed -E 's/^URL: //' | sort -u || true)"
  if [[ -z "$urls" ]]; then
    # No "Download failed" line (e.g. the CLI died another way): fall back
    # to the last URL it announced downloading.
    urls="$(grep -oE 'from https://[^ ]+\.zip' "$log" 2>/dev/null | sed -E 's/^from //' | tail -1 || true)"
  fi
  [[ -n "$urls" ]] || { printf 'curl fallback unavailable: no download URL in %s.\n' "$log"; return 1; }
  while IFS= read -r url || [[ -n "$url" ]]; do
    [[ -z "$url" ]] && continue
    case "$url" in */linux64/chrome-linux64.zip) chrome_url="$url" ;; esac
    playwright_curl_one "$url" || ok=0
  done <<< "$urls"
  # Headless-shell completion (E-1 round, 2026-11-10): the log-parsed URLs
  # above can NEVER include the headless-shell zip on this network, because
  # the CLI's first run is killed by run_best_effort's 600 s timeout while
  # still retrying the chrome zip (VERIFIED 2026-11-10: at fallback time
  # the log held 4x the chrome URL and 0x the headless-shell URL; the 5x
  # headless-shell URLs in the final log all come from the post-fallback
  # CLI re-run). Without it the re-run still FAILED (non-fatal) even though
  # the eyes step itself only needs chromium-1254. The headless-shell zip
  # lives at the SAME CDN URL as the chrome zip — same version directory,
  # filename chrome-headless-shell-linux64.zip — the exact URL the CLI
  # itself prints on the re-run (VERIFIED via curl HEAD 2026-11-10:
  # 200 OK, 131,998,580 B = the CLI log's 125.9 MiB). So when a chrome URL
  # was seen but no headless-shell URL was in the log, derive it by
  # filename substitution and fetch it through the same playwright_curl_one
  # (same source, same layout, same per-entry permission restore — nothing
  # is invented from outside the CLI's own URLs). Best-effort: if the
  # derived fetch fails, warn explicitly and keep the chrome result — the
  # post-fallback CLI re-run will retry the headless shell, and the eyes
  # step does not need it (verify.sh eyes use chromium-1254; the headless
  # shell is what `playwright-cli install-browser chrome-for-testing`
  # needs to report a clean install).
  if [[ -n "$chrome_url" ]] && ! printf '%s\n' "$urls" | grep -q 'chrome-headless-shell-linux64\.zip'; then
    hs_url="${chrome_url%/chrome-linux64.zip}/chrome-headless-shell-linux64.zip"
    printf 'curl fallback: chrome URL seen but no headless-shell URL was logged (CLI died during chrome retries) — deriving it from the same CDN version directory: %s\n' "$hs_url"
    playwright_curl_one "$hs_url" || printf 'curl fallback: WARNING — derived headless-shell fetch failed for %s (non-fatal: the post-fallback CLI re-run will retry it; the eyes step uses chromium-1254 and does not need the headless shell).\n' "$hs_url"
  fi
  [[ "$ok" == 1 ]]
}

# --- Playwright eyes (best-effort) ----------------------------------------
# H5: a skipped subsystem is a PENDING item with its exact manual command,
# recorded for verify.sh — never silent. (Before this fix the skip
# branches below were all gated on skip_* == 0, so --skip-eyes/--skip-hooks/
# --skip-mcp left zero trace while install exited 0 and verify said OK.)
if [[ "$skip_eyes" == 1 ]]; then
  mkdir -p "$state_dir"
  printf '%s\n' "eyes" >> "$state_dir/skipped-subsystems.txt"
  note_pending "Playwright CLI + browser skipped (--skip-eyes). Run: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION, then playwright-cli install-browser chrome-for-testing"
fi
if [[ "$skip_eyes" == 0 && "$have_node" == 1 && "$have_npx" == 1 && "$node_ok" == 1 ]]; then
  if command -v playwright-cli >/dev/null 2>&1; then
    printf 'Playwright CLI already on PATH: %s\n' "$(command -v playwright-cli)"
  else
    printf '\nInstalling Playwright CLI %s (pinned)...\n' "$PLAYWRIGHT_CLI_VERSION"
    if ! run_best_effort "npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION" 300 \
        npm install -g "@playwright/cli@$PLAYWRIGHT_CLI_VERSION"; then
      note_pending "Playwright CLI not installed (npm -g failed — often a permissions/prefix issue). Install it with: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION"
    fi
  fi
  if command -v playwright-cli >/dev/null 2>&1; then
    # NOTE (verified 2026-11-10 against @playwright/cli 0.1.24 --help and
    # its own error text): `playwright-cli install` only installs SKILLS —
    # there is NO `playwright-cli install chromium` subcommand (it prints
    # help, exit 0 — a false OK). Browsers come from the CLI's own
    # installer, `playwright-cli install-browser <browser>`. The browser
    # the CLI's --browser=chromium flag needs is `chrome-for-testing`
    # (revision chromium-1254 for CLI 0.1.24); the plain `playwright
    # install chromium` package downloads a DIFFERENT revision (1248)
    # that the CLI does not use. Default `open` wants system Google
    # Chrome at /opt/google/chrome/chrome — verify.sh tries
    # --browser=chromium first, then the default, so either works.
    # The browser cache is HOME-relative (~/.cache/ms-playwright): a
    # scratch HOME sees no browsers and re-downloads. Skip the install
    # when --list already shows a chromium build, and stage the download
    # under $HOME (TMPDIR) — this VM's /tmp is a 512M tmpfs and a
    # 2x193MB staged download ENOSPCs there (seen 2026-11-10).
    # The --list probe can stall (600s seen) — bound it to 60s. Without
    # `timeout`, a hung probe stalls the whole install.
    list_out=""
    if [[ "$have_timeout" == 1 ]]; then
      list_out="$(timeout 60 playwright-cli install-browser --list 2>/dev/null || true)"
    else
      list_out="$(playwright-cli install-browser --list 2>/dev/null || true)"
    fi
    if printf '%s' "$list_out" | grep -q 'chromium-'; then
      printf 'Playwright browser already installed (see `playwright-cli install-browser --list`) — skipping download.\n'
    else
      browser_tmp="$state_dir/tmp"
      mkdir -p "$browser_tmp"
      if ! TMPDIR="$browser_tmp" run_best_effort "playwright-cli install-browser chrome-for-testing" 600 playwright-cli install-browser chrome-for-testing; then
        # CLI download failed — curl resume fallback (F2): the CLI's Node
        # downloader has no resume and dies at ~90% on this network.
        printf 'Playwright CLI download failed; trying the curl -C - resume fallback (install.sh playwright_curl_fallback).\n'
        if playwright_curl_fallback; then
          printf 'curl fallback placed the browser(s); re-running the CLI install once to finish the remaining artifacts...\n'
          if TMPDIR="$browser_tmp" run_best_effort "playwright-cli install-browser chrome-for-testing (after curl fallback)" 600 playwright-cli install-browser chrome-for-testing; then
            printf 'Playwright browser install completed after the curl fallback.\n'
          else
            printf 'Playwright CLI re-run after the curl fallback failed; checking what the fallback placed (see --list below).\n'
          fi
          if [[ "$have_timeout" == 1 ]]; then
            list_out="$(timeout 60 playwright-cli install-browser --list 2>/dev/null || true)"
          else
            list_out="$(playwright-cli install-browser --list 2>/dev/null || true)"
          fi
          if printf '%s' "$list_out" | grep -q 'chromium-'; then
            printf 'Playwright browser confirmed via curl fallback (`playwright-cli install-browser --list` shows chromium).\n'
          else
            note_pending "Chrome-for-Testing browser not confirmed after the curl fallback (see \`playwright-cli install-browser --list\`). Run: playwright-cli install-browser chrome-for-testing (on Linux, add --with-deps for system libs — needs sudo)."
          fi
        else
          note_pending "Chrome-for-Testing browser not installed for Playwright CLI. Run: playwright-cli install-browser chrome-for-testing (on Linux, add --with-deps for system libs — needs sudo). The CLI's Node downloader fails on this network (server closed connection at ~90%); if it fails again, fetch the URL it prints with: curl -C - -L -o <file.zip> <url>, then extract it under ~/.cache/ms-playwright/ (see install.sh playwright_curl_fallback for the layout)."
        fi
      fi
    fi
  fi
elif [[ "$skip_eyes" == 0 ]]; then
  if [[ "$node_old" == 1 ]]; then
    note_pending "Playwright CLI not attempted (Node $node_ver found; the kit requires Node 22+). Install Node 22+, then: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION, then playwright-cli install-browser chrome-for-testing"
  elif [[ "$have_node" == 0 ]]; then
    note_pending "Playwright CLI not attempted (node missing). Install Node 22+, then: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION, then playwright-cli install-browser chrome-for-testing"
  else
    note_pending "Playwright CLI not attempted (npx missing — node is present but npx is not). Reinstall Node 22+ (npx ships with it), then: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION, then playwright-cli install-browser chrome-for-testing"
  fi
fi

# --- Impeccable hook (best-effort) ----------------------------------------
# Provider tokens verified AND passed by this script: claude, codex only.
# The upstream README also names a cursor token, but this script never
# passes it (the providers loop below builds claude/codex only) and does
# not verify cursor hook wiring — cursor is recorded, not passed. No
# verified token exists for opencode/gemini/hermes/copilot in the
# --providers list, so those hosts get the manual command instead of a guess.
if [[ "$skip_hooks" == 1 ]]; then
  mkdir -p "$state_dir"
  printf '%s\n' "hooks" >> "$state_dir/skipped-subsystems.txt"
  _sp=""
  for h in $hosts; do case "$h" in claude) _sp="${_sp:+$_sp,}claude";; codex) _sp="${_sp:+$_sp,}codex";; esac; done
  if [[ -n "$_sp" ]]; then
    note_pending "Impeccable hook skipped (--skip-hooks). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$_sp --scope=global (accept the hook, then restart the host). Codex: also open /hooks and approve the project hook."
  else
    note_pending "Impeccable hook skipped (--skip-hooks). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --scope=global and pick your host (accept the hook, then restart the host)."
  fi
fi
if [[ "$skip_hooks" == 0 && "$have_npx" == 1 && "$node_ok" == 1 ]]; then
  # Hook pin (F4, decided 2026-11-10): the hook step installs the PINNED
  # spec impeccable@$IMPECCABLE_PIN (4.8.2 — read from
  # vendor/impeccable/SOURCE.txt at runtime), NEVER @latest. The old
  # @latest call violated AGENTS.md §3 ("never an unpinned @latest
  # installer") and could silently install a newer skill generation than
  # the vendored one. The pin equals npm latest today (4.8.2, VERIFIED
  # via `npm view` 2026-11-10), so behaviour is unchanged today and stays
  # pinned if upstream moves latest. Trade-off, stated plainly:
  # upstream's installer may lay down its own current skill copy next to
  # the hook. That copy is self-consistent (upstream installs skill+engine
  # as a pair), and re-running ./install.sh restores the vendored pin
  # (backup-first). verify.sh's lockstep is checked against the REPO pin,
  # so a jointly-replaced pair no longer passes undetected.
  providers=""
  for h in $hosts; do case "$h" in claude) providers="${providers:+$providers,}claude";; codex) providers="${providers:+$providers,}codex";; esac; done
  if [[ -n "$providers" ]]; then
    printf '\nInstalling Impeccable hook (impeccable@%s, providers=%s, scope=global)...\n' "$IMPECCABLE_PIN" "$providers"
    hook_log_lines="$(wc -l < "$state_dir/install.log" 2>/dev/null || echo 0)"
    _hook_label="npx impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global"
    if run_quiet 300 npx --yes "impeccable@$IMPECCABLE_PIN" install "--providers=$providers" --scope=global; then
      # H6: exit 0 alone is not "OK" — read back the host's hook config.
      if hook_wired; then
        printf 'OK: %s (verified — impeccable entry confirmed in host hook config)\n' "$_hook_label"
      else
        printf 'UNVERIFIED (H6): %s exited 0 but no impeccable entry was found in any readable host hook config — the installer did not register the hook (a stub exiting 0 looks exactly like this). NOT reporting OK.\n' "$_hook_label"
        note_pending "Impeccable hook install for providers=$providers reported success but no impeccable entry exists in any host hook config — NOT verified as wired (H6). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global (accept the hook, then restart the host)."
      fi
    else
      printf 'FAILED (non-fatal): %s — see %s/install.log\n' "$_hook_label" "$state_dir"
      # F-B (2026-11-10): this step failed once in a clean install with a
      # transient GitHub TLS EOF mid-download (peer closed connection
      # without sending TLS close_notify, fetching
      # universal.zip.sig.json). Retry EXACTLY ONCE, and only when the
      # failure looks like a transient download/network error — a real
      # install failure (bad provider, bad scope, auth) must not burn a
      # second 300s run. The check reads only the lines this step appended
      # to install.log (counted above), never the whole log.
      hook_log="$(tail -n +"$((hook_log_lines + 1))" "$state_dir/install.log" 2>/dev/null || true)"
      if printf '%s' "$hook_log" | grep -qiE 'network error|could not download|tls close_notify|econnreset|etimedout|eai_again|enotfound|socket hang up|server closed connection|connection (reset|timed out|refused)|download failed'; then
        printf 'Impeccable hook failed with a transient download/network error — retrying once (1/1)...\n'
        if run_quiet 300 npx --yes "impeccable@$IMPECCABLE_PIN" install "--providers=$providers" --scope=global; then
          if hook_wired; then
            printf 'OK: %s (retry 1/1) (verified — impeccable entry confirmed in host hook config)\n' "$_hook_label"
            printf 'Impeccable hook installed on retry.\n'
          else
            printf 'UNVERIFIED (H6): %s (retry 1/1) exited 0 but no impeccable entry was found in any readable host hook config — NOT reporting OK.\n' "$_hook_label"
            note_pending "Impeccable hook install for providers=$providers reported success on retry but no impeccable entry exists in any host hook config — NOT verified as wired (H6). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global (accept the hook, then restart the host)."
          fi
        else
          printf 'FAILED (non-fatal): %s (retry 1/1) — see %s/install.log\n' "$_hook_label" "$state_dir"
          note_pending "Impeccable hook not installed by script (failed twice; the log shows a transient download/network error — retry when the network is stable). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global (accept the hook, then restart the host). Codex: also open /hooks and approve the project hook."
        fi
      else
        note_pending "Impeccable hook not installed by script (failure does NOT look like a transient download/network error — see $state_dir/install.log before re-running; do not just retry blindly). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global (accept the hook, then restart the host). Codex: also open /hooks and approve the project hook."
      fi
    fi
  else
    note_pending "Impeccable hook: no host with a verified --providers token (claude/codex) was installed. Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --scope=global and pick your host."
  fi
  # Hermes hook has its own VERIFIED command (Impeccable 4.8.2 changelog).
  case " $hosts " in *" hermes "*)
    if command -v hermes >/dev/null 2>&1; then
      if run_quiet 120 hermes plugins enable impeccable-design-hook; then
        if ls "$user_home/.hermes/plugins" 2>/dev/null | grep -qi 'impeccable'; then
          printf 'OK: hermes plugins enable impeccable-design-hook (verified — impeccable plugin present under ~/.hermes/plugins)\n'
        else
          printf 'UNVERIFIED (H6): hermes plugins enable impeccable-design-hook exited 0 but no impeccable plugin was found under ~/.hermes/plugins — NOT reporting OK.\n'
          note_pending "Hermes Impeccable hook enable reported success but no impeccable plugin exists under ~/.hermes/plugins — NOT verified as wired (H6). Run: hermes plugins enable impeccable-design-hook and confirm it lists as enabled."
        fi
      else
        printf 'FAILED (non-fatal): hermes plugins enable impeccable-design-hook — see %s/install.log\n' "$state_dir"
        note_pending "Hermes Impeccable hook not enabled. Run: hermes plugins enable impeccable-design-hook"
      fi
    else
      note_pending "Hermes hook not attempted (hermes binary not on PATH). Run: hermes plugins enable impeccable-design-hook"
    fi
    ;;
  esac
elif [[ "$skip_hooks" == 0 ]]; then
  # (5c) npx missing must NOT silently skip the hook step: record the exact
  # manual command as PENDING instead.
  if [[ "$node_old" == 1 ]]; then
    note_pending "Impeccable hook not attempted (Node $node_ver found; the kit requires Node 22+). Install Node 22+, then: npx --yes impeccable@$IMPECCABLE_PIN install --scope=global and pick your host (accept the hook, then restart the host)."
  else
    note_pending "Impeccable hook not attempted (npx missing). Install Node 22+, then: npx --yes impeccable@$IMPECCABLE_PIN install --scope=global and pick your host (accept the hook, then restart the host)."
  fi
fi

# --- Playwright MCP adds (best-effort, via host CLIs — never hand-edited --
# --- config, because a wrong key fails silently on every host) -------------
if [[ "$skip_mcp" == 1 ]]; then
  mkdir -p "$state_dir"
  printf '%s\n' "mcp" >> "$state_dir/skipped-subsystems.txt"
  _mcp_cmds=""
  for h in $hosts; do case "$h" in
    claude)   _mcp_cmds="$_mcp_cmds claude mcp add --scope user playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION;" ;;
    codex)    _mcp_cmds="$_mcp_cmds codex mcp add playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION;" ;;
    opencode) _mcp_cmds="$_mcp_cmds opencode mcp add playwright --global -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION;" ;;
    gemini)   _mcp_cmds="$_mcp_cmds gemini mcp add --scope user playwright npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION;" ;;
  esac; done
  if [[ -n "$_mcp_cmds" ]]; then
    note_pending "Playwright MCP skipped (--skip-mcp). Run per host:$_mcp_cmds"
  else
    note_pending "Playwright MCP skipped (--skip-mcp). No host with a verified MCP add was installed; per host, e.g. Claude Code: claude mcp add --scope user playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION"
  fi
fi
if [[ "$skip_mcp" == 0 && "$have_npx" == 1 && "$node_ok" == 1 ]]; then
  mcp_cmd=(npx -y "@playwright/mcp@$PLAYWRIGHT_MCP_VERSION")
  for h in $hosts; do
    case "$h" in
      claude)
        if command -v claude >/dev/null 2>&1; then
          mcp_add_checked claude "claude mcp add playwright" claude mcp add --scope user playwright -- "${mcp_cmd[@]}" || true
        else note_pending "Playwright MCP: claude binary not on PATH. Run: claude mcp add --scope user playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION"; fi ;;
      codex)
        if command -v codex >/dev/null 2>&1; then
          # Codex MCP config is TOML [mcp_servers.<name>]; the CLI writes it.
          mcp_add_checked codex "codex mcp add playwright" codex mcp add playwright -- "${mcp_cmd[@]}" || true
        else note_pending "Playwright MCP: codex binary not on PATH. Run: codex mcp add playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION"; fi ;;
      opencode)
        if command -v opencode >/dev/null 2>&1; then
          # OpenCode v2 schema ONLY: the CLI writes mcp.servers.<name>.
          mcp_add_checked opencode "opencode mcp add playwright" opencode mcp add playwright --global -- "${mcp_cmd[@]}" || true
        else note_pending "Playwright MCP: opencode binary not on PATH. Run: opencode mcp add playwright --global -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION"; fi ;;
      gemini)
        if command -v gemini >/dev/null 2>&1; then
          mcp_add_checked gemini "gemini mcp add playwright" gemini mcp add --scope user playwright "${mcp_cmd[@]}" || true
        else note_pending "Playwright MCP: gemini binary not on PATH. Run: gemini mcp add --scope user playwright npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION"; fi ;;
      *) ;; # hermes/copilot/muse/cmd: no verified per-host MCP CLI add for
            # Playwright in the phase-1 sources — file-copy install only.
    esac
  done
elif [[ "$skip_mcp" == 0 ]]; then
  # (5c) npx missing must NOT silently skip the MCP adds: record the exact
  # manual commands as PENDING instead (Claude form shown; codex/opencode/
  # gemini use the same npx server command via their own `mcp add`).
  if [[ "$node_old" == 1 ]]; then
    note_pending "Playwright MCP adds not attempted (Node $node_ver found; the kit requires Node 22+). Install Node 22+, then per host, e.g. Claude Code: claude mcp add --scope user playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION (codex: codex mcp add playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION; opencode: opencode mcp add playwright --global -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION; gemini: gemini mcp add --scope user playwright npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION)."
  else
    note_pending "Playwright MCP adds not attempted (npx missing). Install Node 22+, then per host, e.g. Claude Code: claude mcp add --scope user playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION (codex: codex mcp add playwright -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION; opencode: opencode mcp add playwright --global -- npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION; gemini: gemini mcp add --scope user playwright npx -y @playwright/mcp@$PLAYWRIGHT_MCP_VERSION)."
  fi
fi

# --- Secret scanner for gate 1.1 (best-effort, F4 2026-11-11) ---------------
# Gate 1.1 (gate.sh §6) fails CLOSED when no secret scanner is installed
# (gitleaks or trufflehog) — on a fresh machine the gate failed with only
# "install one" as guidance and no file recorded how. Install gitleaks
# here so a fresh install passes 1.1: the pinned v8.30.1 release tarball
# (see GITLEAKS_VERSION above), fetched with its published checksums file
# and verified with sha256sum BEFORE extraction — never @latest, never
# curl|sh, no sudo (installs to ~/.local/bin). Best-effort like the
# hook/MCP/eyes steps: any failure is a PENDING note with the exact
# manual command, never fatal. trufflehog / osv-scanner / go-licenses
# are NOT installed here (no verified pin established for them in this
# round) — the PENDING note below names them as manual alternatives.
install_gitleaks() { # pinned tarball + published checksums, into ~/.local/bin
  command -v curl >/dev/null 2>&1 || { printf 'gitleaks install: curl not found.\n'; return 1; }
  command -v sha256sum >/dev/null 2>&1 || { printf 'gitleaks install: sha256sum not found.\n'; return 1; }
  local base="https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION"
  local tmpd
  tmpd="$(mktemp -d)" || return 1
  if ! curl -fsSL -o "$tmpd/gitleaks.tar.gz" "$base/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"; then
    printf 'gitleaks install: tarball download failed.\n'; rm -rf -- "$tmpd"; return 1
  fi
  if ! curl -fsSL -o "$tmpd/checksums.txt" "$base/gitleaks_${GITLEAKS_VERSION}_checksums.txt"; then
    printf 'gitleaks install: checksums download failed — refusing to install an unverified binary.\n'; rm -rf -- "$tmpd"; return 1
  fi
  if ! (cd "$tmpd" && grep "gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" checksums.txt | sha256sum -c - >/dev/null 2>&1); then
    printf 'gitleaks install: checksum verification FAILED — refusing to install.\n'; rm -rf -- "$tmpd"; return 1
  fi
  if ! tar -xzf "$tmpd/gitleaks.tar.gz" -C "$tmpd" gitleaks; then
    printf 'gitleaks install: extraction failed.\n'; rm -rf -- "$tmpd"; return 1
  fi
  mkdir -p "$user_home/.local/bin"
  cp -- "$tmpd/gitleaks" "$user_home/.local/bin/gitleaks" || { printf 'gitleaks install: copy to ~/.local/bin failed.\n'; rm -rf -- "$tmpd"; return 1; }
  chmod 755 -- "$user_home/.local/bin/gitleaks"
  rm -rf -- "$tmpd"
  "$user_home/.local/bin/gitleaks" version >/dev/null 2>&1
}
if command -v gitleaks >/dev/null 2>&1; then
  printf 'Secret scanner already on PATH: gitleaks %s\n' "$(command -v gitleaks)"
elif command -v trufflehog >/dev/null 2>&1; then
  printf 'Secret scanner already on PATH: trufflehog %s (gate 1.1 accepts gitleaks or trufflehog)\n' "$(command -v trufflehog)"
elif install_gitleaks; then
  if command -v gitleaks >/dev/null 2>&1; then
    printf 'OK: gitleaks %s installed (gate 1.1 scanner)\n' "$GITLEAKS_VERSION"
  else
    printf 'OK: gitleaks %s installed to ~/.local/bin/gitleaks, but ~/.local/bin is not on PATH — gate 1.1 still cannot see it.\n' "$GITLEAKS_VERSION"
    note_pending "gitleaks $GITLEAKS_VERSION is installed at ~/.local/bin/gitleaks but ~/.local/bin is not on PATH, so gate 1.1 still fails closed. Add it: export PATH=\"\$HOME/.local/bin:\$PATH\" (e.g. in ~/.profile), then re-run ./verify.sh. Alternative scanners the gate also accepts: trufflehog (see https://github.com/trufflesecurity/trufflehog/releases)."
  fi
else
  note_pending "Secret scanner not installed (gitleaks $GITLEAKS_VERSION install failed — see above; never fatal). Gate 1.1 fails closed without one. Install it manually: curl -fsSL -o /tmp/gitleaks.tar.gz https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && curl -fsSL -o /tmp/gitleaks-checksums.txt https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/gitleaks_${GITLEAKS_VERSION}_checksums.txt && (cd /tmp && grep gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz gitleaks-checksums.txt | sha256sum -c -) && tar -xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks && mkdir -p ~/.local/bin && cp /tmp/gitleaks ~/.local/bin/gitleaks && chmod 755 ~/.local/bin/gitleaks (ensure ~/.local/bin is on PATH). Alternatives the gate also accepts: trufflehog; osv-scanner and go-licenses cover the Stage 1 dep/licence checks but do not satisfy 1.1."
fi

# Figma: human-gated by design (OAuth). Never attempted here.
note_pending "Figma MCP is NOT installed (human OAuth — by design). When you want it, Claude Code: claude mcp add --transport http figma https://mcp.figma.com/mcp --scope user, then new session, /mcp -> figma -> Authenticate. Other hosts: add the same remote URL https://mcp.figma.com/mcp via that host's MCP add, then authenticate in the browser."

# --- verify + warm ---------------------------------------------------------
printf '\nChecking installed files (verify.sh, default mode)...\n'
if ! "$root/verify.sh"; then
  printf '\nverify.sh reported failures (see above). Files are installed; fix the failures before relying on the loop.\n' >&2
  printf 'Backup (if anything was replaced): %s\n' "$backup"
  exit 1
fi

if [[ "$no_warm" == 0 ]]; then
  printf '\nPreparing Impeccable engine for this Linux machine...\n'
  launcher=""
  # Launcher search covers EVERY skills dir the kit installs to — the old
  # 3-path list missed muse-only (~/workspace/custom-skills) and
  # codex/gemini/hermes/copilot installs, so a correct muse-only install
  # could never warm (and verify.sh failed it outright). Keep this list
  # in sync with verify.sh's find_launcher.
  for cand in "$user_home/.agents/skills/impeccable/scripts/impeccable" \
             "$user_home/.claude/skills/impeccable/scripts/impeccable" \
             "$user_home/.config/opencode/skills/impeccable/scripts/impeccable" \
             "$user_home/.codex/skills/impeccable/scripts/impeccable" \
             "$user_home/.gemini/skills/impeccable/scripts/impeccable" \
             "$user_home/.hermes/skills/impeccable/scripts/impeccable" \
             "$user_home/.copilot/skills/impeccable/scripts/impeccable" \
             "$user_home/workspace/custom-skills/impeccable/scripts/impeccable"; do
    [[ -x "$cand" ]] && { launcher="$cand"; break; }
  done
  if [[ -n "$launcher" ]]; then
    if ! "$launcher" engine-probe; then
      printf 'Impeccable engine download failed. The skills are installed; the engine downloads on first use (needs network).\n' >&2
      note_pending "Impeccable engine not warmed. Run: $launcher engine-probe (needs network)."
    fi
  else
    note_pending "Impeccable launcher not found in any installed skills dir — engine warm skipped."
  fi
fi

printf '\nDone.\n'
printf 'Hosts installed: %s\n' "$hosts"
printf 'Backup (if anything was replaced): %s\n' "$backup"
printf 'Installed-hosts record: %s/installed-hosts.txt\n' "$state_dir"
if [[ "${#PENDING[@]}" -gt 0 ]]; then
  printf '\nStill pending (%s item(s)):\n' "${#PENDING[@]}"
  for p in "${PENDING[@]}"; do printf '  - %s\n' "$p"; done
fi
printf '\nOpen a NEW session in each host to load the skills (skills/MCP/plugins load at session start; testing in this session is the #1 false failure).\n'
printf 'Then re-verify in the new session: ./verify.sh --strict\n'
