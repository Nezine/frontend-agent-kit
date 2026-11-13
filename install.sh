#!/usr/bin/env bash
# frontend-agent-kit — installer v2.
#
# Non-interactive, Linux/macOS. Detects the hosts actually present, copies the
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
# gitleaks_8.30.1_checksums.txt) and darwin assets VERIFIED 2026-11-11
# against the published checksums file (darwin_arm64
# b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5,
# darwin_x64 dfe101a4db2255fc85120ac7f3d25e4342c3c20cf749f2c20a18081af1952709).
# Pinned — never @latest.
GITLEAKS_VERSION="8.30.1"

KNOWN_HOSTS="claude codex opencode gemini hermes copilot muse cmd"

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
user_home="${HOME:?HOME must be set}"
backup="$user_home/.local/share/frontend-agent-kit/backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"
state_dir="$user_home/.local/share/frontend-agent-kit"
refs_dir="$user_home/.local/share/agent-design-references"
# Playwright browser cache root (macOS phase, D12): Playwright's own
# default cache is ~/.cache/ms-playwright on Linux but
# ~/Library/Caches/ms-playwright on macOS. Only the curl fallback
# hardcodes it (the CLI knows its own cache dir); $os_name is set by the
# OS dispatch below, so this is assigned there — see the dispatch block.
pw_cache_dir=""

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

Installs frontend-agent-kit skills for every detected host on Linux or macOS.
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

# OS dispatch (macOS phase, D12): Linux and macOS (Darwin) are supported;
# anything else fails fast with a clear message. Windows install paths are
# open work, not verified. Stock macOS ships bash 3.2 — the scripts are
# written bash-3.2-compatible (no bash-4-only constructs); see
# D12. No Homebrew bash is required.
os_name="$(uname -s)"
is_darwin=0
case "$os_name" in
  Linux) : ;;
  Darwin) is_darwin=1 ;;
  *) fail "This package supports Linux and macOS only (detected: $os_name). Windows install paths are open work, not verified — see phase-1 research/SYNTHESIS.md §7 (workspace research note, not shipped in this repo)." ;;
esac
# Playwright browser cache root: ~/Library/Caches/ms-playwright on macOS,
# ~/.cache/ms-playwright on Linux (the CLI's own default per OS).
if [[ "$is_darwin" == 1 ]]; then pw_cache_dir="$user_home/Library/Caches/ms-playwright";
else pw_cache_dir="$user_home/.cache/ms-playwright"; fi

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
  if [[ "$_nm" =~ ^[0-9]+$ ]] && [[ "10#$_nm" -ge 22 ]]; then
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
    # CommandCode (cmd): native user dir FIRST (it outranks the shared
    # dir on the documented priority order — project .commandcode/ >
    # project .agents/ > user ~/.commandcode/skills/ > user
    # ~/.agents/skills/ — commandcode.ai/docs/skills, read 2026-11-11),
    # then the shared dir so cmd also sees the cross-agent copy.
    cmd)      printf '%s\n%s\n' "$user_home/.commandcode/skills" "$user_home/.agents/skills" ;;
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
    # overlay/btrfs). Fall back to cp -R (POSIX spelling; cp -r is the
    # fragile one on BSD/macOS) and record it. The failed cp -a may have
    # left a partial target, so remove it first: it was just created by
    # that failed copy, and any pre-existing content was already moved
    # to the backup above.
    printf 'WARNING: cp -a failed for %s (filesystem rejects ownership preservation) — falling back to cp -R (best-effort preservation).\n' "$source" >&2
    mkdir -p "$state_dir"
    printf '%s: cp -a failed, used cp -R fallback: %s -> %s\n' "$(date -u +%FT%TZ)" "$source" "$target" >> "$state_dir/copy-fallbacks.log"
    rm -rf -- "$target"
    cp -R -- "$source" "$target" || fail "copy failed even with cp -R fallback: $source -> $target"
    printf 'Installed %s (via cp -R fallback; ownership/timestamps best-effort)\n' "$target"
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
    printf 'WARNING: cp -a failed for %s — falling back to cp -R (best-effort preservation).\n' "$source" >&2
    mkdir -p "$state_dir"
    printf '%s: cp -a failed, used cp -R fallback: %s -> %s\n' "$(date -u +%FT%TZ)" "$source" "$target" >> "$state_dir/copy-fallbacks.log"
    rm -rf -- "$target"
    cp -R -- "$source" "$target" || fail "copy failed even with cp -R fallback: $source -> $target"
    printf 'Installed %s (via cp -R fallback)\n' "$target"
    return 0
  fi
  printf 'Installed %s\n' "$target"
}

# --- copy -----------------------------------------------------------------
# Which dirs are already claimed, and by WHICH host (the post-hook restore
# below needs the variant each dir was installed from — clean-env
# 2026-11-11, GAP-2/3). Bash 3.2 has no associative arrays (stock macOS
# /bin/bash is 3.2; the feature arrived in bash 4), so the dir->host map
# is two parallel indexed arrays plus a linear lookup — the map is only
# ever queried by exact dir key and N is small, so the lookup cost is
# negligible. (macOS phase, D12.)
DONE_DIR_LIST=()
DONE_DIR_HOST=()
done_dir_host() { # <dir> — print the host that claimed <dir>, or nothing
  # Index loop, not an array expansion: expanding an empty array under
  # `set -u` aborts bash older than 4.4 (stock macOS bash 3.2 included),
  # and this lookup runs while the list is still empty on every run.
  local _i=0
  while [[ "$_i" -lt "${#DONE_DIR_LIST[@]}" ]]; do
    if [[ "${DONE_DIR_LIST[$_i]}" == "$1" ]]; then printf '%s' "${DONE_DIR_HOST[$_i]}"; return 0; fi
    _i=$((_i+1))
  done
  return 1
}
for host in $hosts; do
  while IFS= read -r dir || [[ -n "$dir" ]]; do
    [[ -z "$dir" ]] && continue
    # Record WHICH host claimed the dir (not just "done"): the post-hook
    # restore below needs the variant each dir was installed from
    # (clean-env 2026-11-11, GAP-2/3).
    _claimed_host="$(done_dir_host "$dir" || true)"
    [[ -n "$_claimed_host" ]] && continue
    DONE_DIR_LIST+=("$dir")
    DONE_DIR_HOST+=("$host")
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
  # Index loop, not `for dir in "${DONE_DIR_LIST[@]}"`: expanding an empty
  # array under `set -u` aborts bash older than 4.4 (stock macOS bash 3.2).
  _di=0
  while [[ "$_di" -lt "${#DONE_DIR_LIST[@]}" ]]; do
    dir="${DONE_DIR_LIST[$_di]}"; _di=$((_di+1))
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
promote_codex_hook() { # move the upstream installer's project hook to global scope (GAP-6)
  # Clean-env 2026-11-11: the upstream installer writes the Codex hook as
  # a PROJECT hook (<repo>/.codex/hooks.json), which fires only when codex
  # runs inside this repo (and only after project trust + /hooks approval),
  # even though install.sh asked for --scope=global. ~/.codex/hooks.json
  # is a real user-global location (Codex loads it for all projects
  # regardless of project trust), so promote the file there, then remove
  # the now-redundant project copy so the hook does not fire twice in
  # this repo. Never overwrite an existing global hooks file; if one
  # exists and differs, leave both and PENDING. Idempotent: a second
  # call finds no project file and does nothing (the installer recreates
  # it on every run, so re-running ./install.sh dedupes it again).
  # Dry-run moves nothing (QC 2026-11-11).
  [[ "$dry_run" == 0 ]] || return 0
  local proj="$root/.codex/hooks.json" glob="$user_home/.codex/hooks.json"
  [[ -f "$proj" ]] || return 0
  case " $hosts " in *" codex "*) ;; *) return 0 ;; esac
  # Only touch the file if it is the installer's (red-team S1): a
  # project hooks.json that does not mention impeccable belongs to the
  # user (or another tool) — leave it alone, never move it to global
  # scope and never delete it.
  grep -qi 'impeccable' "$proj" || return 0
  # Mark that this function acted, so the catch-all below does not run
  # it a second time and duplicate its PENDING (red-team H1).
  _promote_codex_ran=1
  if [[ ! -f "$glob" ]]; then
    mkdir -p "$user_home/.codex" || { printf 'WARNING: could not create %s — the Codex hook stays project-scoped.\n' "$user_home/.codex" >&2; return 0; }
    if cp -- "$proj" "$glob"; then
      # Back up the project file before removing it (red-team S1). The
      # global copy already holds the same bytes; this is the restore
      # copy under $backup.
      mkdir -p "$backup/codex" 2>/dev/null || true
      cp -- "$proj" "$backup/codex/hooks.json" 2>/dev/null || true
      if rm -- "$proj"; then
        printf 'Codex hook promoted to global: %s (project copy removed — the hook now fires in all projects)\n' "$glob"
      else
        printf 'WARNING: Codex hook copied to %s but the project copy at %s could not be removed — the hook may fire twice when codex runs in this repo; remove the project file by hand.\n' "$glob" "$proj" >&2
      fi
    else
      printf 'WARNING: could not copy the Codex project hook %s to %s — the hook stays project-scoped (fires only in this repo).\n' "$proj" "$glob" >&2
    fi
  elif cmp -s -- "$proj" "$glob"; then
    mkdir -p "$backup/codex" 2>/dev/null || true
    cp -- "$proj" "$backup/codex/hooks.json" 2>/dev/null || true
    if rm -- "$proj"; then
      printf 'Codex hook: project copy identical to the global one — removed the duplicate (global %s already wired).\n' "$glob"
    else
      printf 'WARNING: could not remove the duplicate Codex project hook %s — the hook may fire twice when codex runs in this repo; remove it by hand.\n' "$proj" >&2
    fi
  else
    note_pending "Codex hook: the installer wrote a project hook at $proj but $glob already exists with different content — NOT merged automatically (merging would risk overwriting your hooks). Copy the impeccable entry into $glob by hand, or delete the project file if the global one already covers it."
  fi
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
# ~90% with "Download failed: server closed connection" and restarts from
# 0% on each of its 5 internal retries, so the install never completes
# (reproduced 2026-11-10: 4 attempts in 500s, all dying at 90%). curl -C -
# fetches the identical zip in one transfer (chrome-linux64.zip,
# 207,460,506 B for CLI 0.1.24; headless-shell 131,998,580 B — VERIFIED
# 2026-11-11 via HEAD on the Chrome-for-Testing public bucket URLs the
# CLI 0.1.24 actually downloads from; the same byte sizes the old
# cdn.playwright.dev URLs served). When the CLI download
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
#   $pw_cache_dir/<name>-<revision>/ + an empty
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
playwright_core_dir() { # prints the playwright-core dir for the installed CLI, or nothing
  # Shim-proof (red-team H5): if playwright-cli resolves via a mise shim,
  # canonicalising gives the shims dir, which has no node_modules. Fall
  # back to the npm global root.
  # Canonicaliser (macOS phase, D12): BSD readlink has no -f, so fall back
  # to python3 realpath (python3 is a hard prereq of this script); if
  # neither works, use the unresolved PATH result — the node_modules
  # check below still decides, so the fallback is never a wrong answer.
  local cli_dir core _cli_path _cli_real
  if command -v playwright-cli >/dev/null 2>&1; then
    _cli_path="$(command -v playwright-cli)"
    _cli_real="$(readlink -f -- "$_cli_path" 2>/dev/null || true)"
    if [[ -z "$_cli_real" ]] && command -v python3 >/dev/null 2>&1; then
      _cli_real="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$_cli_path" 2>/dev/null || true)"
    fi
    cli_dir="$(dirname -- "${_cli_real:-$_cli_path}")"
    core="$cli_dir/node_modules/playwright-core"
    if [[ -d "$core" ]]; then printf '%s' "$core"; return 0; fi
  fi
  if command -v npm >/dev/null 2>&1; then
    core="$(npm root -g 2>/dev/null || true)/@playwright/cli/node_modules/playwright-core"
    if [[ -d "$core" ]]; then printf '%s' "$core"; return 0; fi
  fi
  return 1
}
playwright_revision() { # <browser-name> — revision from the CLI bundle's browsers.json
  local name="$1" bj
  bj="$(playwright_core_dir 2>/dev/null || true)/browsers.json"
  [[ -f "$bj" ]] || return 1
  node -e "const b=require(process.argv[1]).browsers.find((x)=>x.name===process.argv[2]); if(!b) process.exit(1); console.log(b.revision)" "$bj" "$name" 2>/dev/null
}
playwright_browser_version() { # <browser-name> — browserVersion from the CLI bundle's browsers.json
  local name="$1" bj
  bj="$(playwright_core_dir 2>/dev/null || true)/browsers.json"
  [[ -f "$bj" ]] || return 1
  node -e "const b=require(process.argv[1]).browsers.find((x)=>x.name===process.argv[2]); if(!b || !b.browserVersion) process.exit(1); console.log(b.browserVersion)" "$bj" "$name" 2>/dev/null
}
playwright_curl_validate_url() { # <url> — 0 if the URL path is safe for mapping + check, else refuse (1)
  # F-RT1 fix pass (2026-11-13): validate the URL shape ONCE, before both
  # the mapping (playwright_curl_one) and the version cross-check
  # (playwright_curl_check_url), so both stages see the same string.
  # REJECTION, not normalization, is deliberate: curl -L normalizes dot
  # segments (RFC 3986) before fetching, so a `..` URL that passed the
  # check would fetch a DIFFERENT revision and place it under the checked
  # revision with INSTALLATION_COMPLETE; silently fetching a normalized
  # URL would change fetch semantics and hide a poisoned log line. The
  # URL in the CLI log is the identity — refuse it.
  # Only the three hosts the mapping trusts are validated; any other host
  # falls through to the mapping's `*)` refusal, unchanged. The query
  # string / fragment are stripped first: validation is about the path,
  # and a `?x=/../` must not change a clean path's verdict.
  # Also enforces at most one `/builds/` segment (W-RT3): a second
  # `/builds/`, or a `builds`-suffixed segment immediately before one
  # (`evilbuilds/builds/`), must never reach the mapping — the `*` in
  # `*builds/` would otherwise span it. A URL with no `/builds/` at all
  # still falls through to the mapping/check refusal, unchanged.
  # F2-RT1 fix pass 2 (2026-11-13): segment-shape allowlist, on top of
  # the denylist above. The denylist refuses the known spellings, but
  # the server's normalization rules cannot be enumerated that way —
  # GCS strips `;params` from a segment, so `..;` passed the validator
  # and fetched the WRONG revision live (140.x placed as chromium-1254),
  # and double-encoding / overlong UTF-8 / unicode dots / `%00` all
  # reach curl and die only at the server. So every path segment must
  # ALSO match the shape of a segment the CLI actually emits.
  # Legitimate segment shapes, enumerated from the mapping arms below
  # (playwright_curl_one) + the CLI 0.1.24 bundle (PLAYWRIGHT_CDN_MIRRORS
  # / DOWNLOAD_PATHS / cftUrl): mirror prefixes (`dbazure`, `download`,
  # `playwright`, or any segment of the generalised `*builds/` prefix,
  # e.g. `a`/`b`/`c`/`d`), `chrome-for-testing-public`, `builds`,
  # `cft`/`ffmpeg`, a version (`158.0.8127.18`) or revision (`1013`),
  # an arch dir (`linux64`, `linux-arm64`, `mac-arm64`, `mac-x64`), and
  # a filename (`chrome-linux64.zip`, `chrome-headless-shell-mac-arm64.zip`,
  # `ffmpeg-linux-arm64.zip`, ...). Every one of those is `[A-Za-z0-9._-]+`
  # and none is all dots; a segment containing `;`, `%`, `\`, `+`, `~`,
  # `:` or any other character, an empty segment, or an all-dots segment
  # (`.`, `..`, `...`) is not emitted by the CLI and refuses here, before
  # the mapping. The query/fragment were stripped above, so `?`/`#`
  # never appear in a segment.
  local url="$1" path _vpath _vseg
  case "$url" in
    https://cdn.playwright.dev/*) path="${url#https://cdn.playwright.dev}" ;;
    https://playwright.download.prss.microsoft.com/*) path="${url#https://playwright.download.prss.microsoft.com}" ;;
    https://storage.googleapis.com/*) path="${url#https://storage.googleapis.com}" ;;
    *) return 0 ;;
  esac
  path="${path%%\?*}"
  path="${path%%\#*}"
  case "$path" in
    *"/../"*|*"/.."|*"/./"*|*"/."|*"//"*)
      printf 'curl fallback: refusing to place URL with dot or empty path segment: %s\n' "$url"
      return 1 ;;
  esac
  case "$path" in
    *"%2e"*|*"%2E"*|*"%2f"*|*"%2F"*)
      printf 'curl fallback: refusing to place URL with percent-encoded dot or slash: %s\n' "$url"
      return 1 ;;
  esac
  # Segment-shape allowlist (F2-RT1 fix pass 2, see the enumeration in
  # the header comment above). Pure parameter expansion — no arrays, no
  # `read -a` — so it stays bash-3.2-safe.
  _vpath="${path#/}"
  while :; do
    case "$_vpath" in
      */*) _vseg="${_vpath%%/*}"; _vpath="${_vpath#*/}" ;;
      *) _vseg="$_vpath"; _vpath="" ;;
    esac
    case "$_vseg" in
      ""|*[!A-Za-z0-9._-]*)
        printf 'curl fallback: refusing to place URL with path segment outside [A-Za-z0-9._-]: %s\n' "$url"
        return 1 ;;
    esac
    case "$_vseg" in
      *[!.]* ) ;;
      *)
        printf 'curl fallback: refusing to place URL with dot-only path segment: %s\n' "$url"
        return 1 ;;
    esac
    [[ -z "$_vpath" ]] && break
  done
  case "$path" in
    *"/builds/"*"/builds/"*|*"builds/builds/"*)
      printf 'curl fallback: refusing to place URL with more than one /builds/ segment: %s\n' "$url"
      return 1 ;;
  esac
  return 0
}
playwright_curl_check_url() { # <url> <name> <rev> — 0 if the URL matches the CLI registry, else refuse (1) with a message
  # Cross-check (red-team H4): the cache dir name comes from
  # browsers.json, so a URL serving a different build would be placed
  # under the wrong revision and marked complete. Refuse on mismatch.
  # CFT URLs carry a browser VERSION (compare to browserVersion, like the
  # GCS branch); only ffmpeg URLs carry a numeric REVISION (compare to
  # the revision). Comparing a CFT version against the revision always
  # refuses (F-3, 2026-11-11: 158.0.8127.18 != 1254) — that was the old
  # shared CDN branch, and it dead-ended all four new darwin CDN CFT arms
  # (and the pre-existing Linux ones). If the registry has no version for
  # this browser (e.g. ffmpeg), the version check is skipped.
  local url="$1" name="$2" rev="$3" _url_ver _bj_ver _url_kind _url_seg
  # F-RT1 fix pass: validate the shape first — the check's first-segment
  # sed must never see an un-normalized URL either.
  playwright_curl_validate_url "$url" || return 1
  case "$url" in
    https://storage.googleapis.com/chrome-for-testing-public/*)
      _url_ver="$(printf '%s' "$url" | sed -E 's#.*chrome-for-testing-public/([^/]+)/.*#\1#')"
      _bj_ver="$(playwright_browser_version "$name" 2>/dev/null || true)"
      if [[ -n "$_bj_ver" && "$_url_ver" != "$_bj_ver" ]]; then
        printf 'curl fallback: URL version %s does not match the CLI registry browserVersion %s for %s — refusing to place it.\n' "$_url_ver" "$_bj_ver" "$name"
        return 1
      fi
      ;;
    https://cdn.playwright.dev/*|https://playwright.download.prss.microsoft.com/*)
      # D35: prss is mirror #2 in PLAYWRIGHT_CDN_MIRRORS (ffmpeg only);
      # it previously fell through to `return 0` unchecked (fail-open).
      # The `builds/<kind>/<seg>` parsing below is host-agnostic.
      # W-RT1 fix pass (2026-11-13): the prss mirror serves ffmpeg ONLY
      # (PLAYWRIGHT_CDN_MIRRORS pins it to the dbazure prefix for
      # ffmpeg); a chromium/headless-shell name on this host must refuse
      # HERE, not just at the mapping — the check must never be a
      # standalone accept for a prss chromium URL (latent fail-open if
      # the check is ever reused as a gate or a prss CFT arm is added).
      # Refusal in code, not documentation: the mapping is the allowlist
      # today, but this branch is the cross-check and should not accept
      # a host/kind/name combination the mapping cannot emit.
      case "$url" in
        https://playwright.download.prss.microsoft.com/*)
          case "$name" in
            chromium|chromium-headless-shell)
              printf 'curl fallback: refusing to place %s from the prss mirror (it serves ffmpeg only): %s\n' "$name" "$url"
              return 1 ;;
          esac ;;
      esac
      _url_kind="$(printf '%s' "$url" | sed -E 's#.*/builds/([^/]+)/.*#\1#')"
      _url_seg="$(printf '%s' "$url" | sed -E 's#.*/builds/(cft|ffmpeg)/([^/]+)/.*#\2#')"
      if [[ "$_url_kind" == "cft" ]]; then
        _bj_ver="$(playwright_browser_version "$name" 2>/dev/null || true)"
        if [[ -n "$_bj_ver" && "$_url_seg" != "$_bj_ver" ]]; then
          printf 'curl fallback: URL version %s does not match the CLI registry browserVersion %s for %s — refusing to place it.\n' "$_url_seg" "$_bj_ver" "$name"
          return 1
        fi
      elif [[ "$_url_kind" == "ffmpeg" ]]; then
        if [[ -n "$_url_seg" && "$_url_seg" != "$rev" ]]; then
          printf 'curl fallback: URL revision %s does not match the CLI registry revision %s for %s — refusing to place it.\n' "$_url_seg" "$rev" "$name"
          return 1
        fi
      else
        printf 'curl fallback: unknown CDN builds kind %s in URL %s — refusing to place it.\n' "$_url_kind" "$url"
        return 1
      fi
      ;;
  esac
  return 0
}
playwright_curl_one() { # <url> — fetch one failed artifact with curl -C - and place it
  local url="$1" fname name exe_rel rev dir_name zip_path dest core_dir links_dir link_name
  # F-RT1 fix pass: validate the shape before the mapping — both the
  # mapping and the cross-check below must see the same string, and a
  # traversal URL must never reach curl. (The fallback path reaches this
  # function too, so log-extracted URLs are covered as well.)
  playwright_curl_validate_url "$url" || return 1
  fname="$(basename -- "${url%%\?*}")"
  case "$url" in
    # Host-anchored (red-team H4): the mapping trusts shape = identity,
    # so a URL on any host would have matched. Only the two hosts the
    # CLI actually downloads from are accepted (CFT bucket, VERIFIED
    # 2026-11-11 via HEAD: chrome 200, 207,460,506 B; headless-shell 200,
    # 131,998,580 B; Playwright CDN for older CLI builds + ffmpeg, whose
    # URL was read from the CLI's own download log:
    # cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1013/).
    # GAP-14/D35: the CDN mirror prefix is GENERALISED, not enumerated —
    # `cdn.playwright.dev/*builds/...` (`*` matches empty or any
    # intermediate prefix). The CLI 0.1.24 bundle's own registry proves
    # both shapes are emitted: chromium/headless-shell use cftUrl() whose
    # ONLY mirror is the bare `https://cdn.playwright.dev`, while ffmpeg
    # uses PLAYWRIGHT_CDN_MIRRORS (dbazure prefix, prss.microsoft.com,
    # bare). The literal `/` after `cdn.playwright.dev` is the host
    # anchor — do NOT rewrite as `dev**/builds`: `**` is just `*` twice
    # in a case pattern and would match `dev.evil.com`. A third host is
    # accepted for ffmpeg ONLY: playwright.download.prss.microsoft.com
    # (mirror #2 in PLAYWRIGHT_CDN_MIRRORS); chromium/headless-shell
    # never use prss, so no prss CFT arms exist. linux-arm64 arms
    # (D35) cover the platform the mapping missed on every host shape.
    # Darwin arms (macOS phase, D12): same hosts, mac-arm64/mac-x64
    # shapes, VERIFIED 2026-11-11 from the CLI 0.1.24 bundle's own
    # lib/coreBundle.js (DOWNLOAD_PATHS + EXECUTABLE_PATHS) and live HEAD
    # checks — mac-arm64 chrome 200, 199,683,801 B; headless-shell 200,
    # 104,957,869 B; ffmpeg-mac 200, 1,549,708 B. The darwin chromium exe
    # is the app-bundle path; the headless shell is NOT a bundle
    # (chrome-headless-shell-mac-<arch>/chrome-headless-shell); ffmpeg
    # extracts a top-level `ffmpeg-mac` file on both arches (verified
    # against the downloaded zips, 2026-11-11).
    https://storage.googleapis.com/chrome-for-testing-public/*/linux64/chrome-linux64.zip)
      name="chromium"; exe_rel="chrome-linux64/chrome" ;;
    https://storage.googleapis.com/chrome-for-testing-public/*/linux64/chrome-headless-shell-linux64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-linux64/chrome-headless-shell" ;;
    https://storage.googleapis.com/chrome-for-testing-public/*/linux-arm64/chrome-linux-arm64.zip)
      name="chromium"; exe_rel="chrome-linux-arm64/chrome" ;;
    https://storage.googleapis.com/chrome-for-testing-public/*/linux-arm64/chrome-headless-shell-linux-arm64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-linux-arm64/chrome-headless-shell" ;;
    https://cdn.playwright.dev/*builds/cft/*/linux64/chrome-linux64.zip)
      name="chromium"; exe_rel="chrome-linux64/chrome" ;;
    https://cdn.playwright.dev/*builds/cft/*/linux64/chrome-headless-shell-linux64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-linux64/chrome-headless-shell" ;;
    https://cdn.playwright.dev/*builds/ffmpeg/*/ffmpeg-linux.zip)
      name="ffmpeg"; exe_rel="ffmpeg-linux" ;;
    https://cdn.playwright.dev/*builds/cft/*/linux-arm64/chrome-linux-arm64.zip)
      name="chromium"; exe_rel="chrome-linux-arm64/chrome" ;;
    https://cdn.playwright.dev/*builds/cft/*/linux-arm64/chrome-headless-shell-linux-arm64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-linux-arm64/chrome-headless-shell" ;;
    https://cdn.playwright.dev/*builds/ffmpeg/*/ffmpeg-linux-arm64.zip)
      name="ffmpeg"; exe_rel="ffmpeg-linux" ;;
    https://storage.googleapis.com/chrome-for-testing-public/*/mac-arm64/chrome-mac-arm64.zip)
      name="chromium"; exe_rel="chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    https://storage.googleapis.com/chrome-for-testing-public/*/mac-arm64/chrome-headless-shell-mac-arm64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-mac-arm64/chrome-headless-shell" ;;
    https://storage.googleapis.com/chrome-for-testing-public/*/mac-x64/chrome-mac-x64.zip)
      name="chromium"; exe_rel="chrome-mac-x64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    https://storage.googleapis.com/chrome-for-testing-public/*/mac-x64/chrome-headless-shell-mac-x64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-mac-x64/chrome-headless-shell" ;;
    https://cdn.playwright.dev/*builds/cft/*/mac-arm64/chrome-mac-arm64.zip)
      name="chromium"; exe_rel="chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    https://cdn.playwright.dev/*builds/cft/*/mac-arm64/chrome-headless-shell-mac-arm64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-mac-arm64/chrome-headless-shell" ;;
    https://cdn.playwright.dev/*builds/cft/*/mac-x64/chrome-mac-x64.zip)
      name="chromium"; exe_rel="chrome-mac-x64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    https://cdn.playwright.dev/*builds/cft/*/mac-x64/chrome-headless-shell-mac-x64.zip)
      name="chromium-headless-shell"; exe_rel="chrome-headless-shell-mac-x64/chrome-headless-shell" ;;
    https://cdn.playwright.dev/*builds/ffmpeg/*/ffmpeg-mac.zip)
      name="ffmpeg"; exe_rel="ffmpeg-mac" ;;
    https://cdn.playwright.dev/*builds/ffmpeg/*/ffmpeg-mac-arm64.zip)
      name="ffmpeg"; exe_rel="ffmpeg-mac" ;;
    https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/*/ffmpeg-linux.zip)
      name="ffmpeg"; exe_rel="ffmpeg-linux" ;;
    https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/*/ffmpeg-linux-arm64.zip)
      name="ffmpeg"; exe_rel="ffmpeg-linux" ;;
    https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/*/ffmpeg-mac.zip)
      name="ffmpeg"; exe_rel="ffmpeg-mac" ;;
    https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/*/ffmpeg-mac-arm64.zip)
      name="ffmpeg"; exe_rel="ffmpeg-mac" ;;
    *)
      printf 'curl fallback: unknown artifact URL (no cache-layout mapping — not guessing): %s\n' "$url"
      return 1 ;;
  esac
  rev="$(playwright_revision "$name")" || { printf 'curl fallback: cannot read the %s revision from the CLI bundle (browsers.json).\n' "$name"; return 1; }
  # Cross-check (red-team H4): see playwright_curl_check_url — the cache
  # dir name comes from browsers.json, so a URL serving a different build
  # would be placed under the wrong revision and marked complete.
  playwright_curl_check_url "$url" "$name" "$rev" || return 1
  dir_name="${name//-/_}-$rev"
  mkdir -p "$state_dir/playwright-downloads"
  zip_path="$state_dir/playwright-downloads/$fname"
  printf 'curl fallback: fetching %s with curl -C - (resume; partial file kept at %s)...\n' "$url" "$zip_path"
  if ! curl -C - -L -o "$zip_path" "$url"; then
    printf 'curl fallback: curl failed for %s (partial file kept at %s — re-run the installer to resume).\n' "$url" "$zip_path"
    return 1
  fi
  [[ -s "$zip_path" ]] || { printf 'curl fallback: empty file for %s.\n' "$url"; return 1; }
  dest="$pw_cache_dir/$dir_name"
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
    [[ -x "$dest/$exe_rel" ]] || chmod 755 "$dest/$exe_rel"
    [[ -x "$dest/$exe_rel" ]] || { printf 'curl fallback: expected executable %s is not executable after permission restore.\n' "$dest/$exe_rel"; return 1; }
  fi
  : > "$dest/INSTALLATION_COMPLETE"
  # F-C (2026-11-10): the CLI's `install-browser --list` reads
  # $pw_cache_dir/.links/<sha1(playwright-core-dir)> (content =
  # the playwright-core dir path, no trailing newline) and ENOENTs when
  # the dir is absent — a fallback-only cache failed --list even though
  # the browser was placed. Reproduce the CLI's own entry exactly
  # (format VERIFIED 2026-11-10 against a CLI-created entry: sha1 of the
  # path with no trailing newline IS the filename; the file holds the
  # path, also with no trailing newline). Best-effort: the marker above
  # is what makes the CLI skip re-downloading; the .links entry only
  # repairs --list. Never overwrite an existing entry.
  core_dir="$(playwright_core_dir 2>/dev/null || true)"
  links_dir="$pw_cache_dir/.links"
  link_name=""
  if [[ -n "$core_dir" ]]; then
    link_name="$(printf '%s' "$core_dir" | sha1sum 2>/dev/null | awk '{print $1}' || true)"
    if [[ -z "$link_name" ]] && command -v python3 >/dev/null 2>&1; then
      link_name="$(printf '%s' "$core_dir" | python3 -c 'import sys,hashlib; print(hashlib.sha1(sys.stdin.buffer.read()).hexdigest())' 2>/dev/null)"
    fi
  fi
  if [[ -n "$link_name" ]]; then
    mkdir -p -- "$links_dir"
    if [[ ! -f "$links_dir/$link_name" ]]; then
      printf '%s' "$core_dir" > "$links_dir/$link_name"
      printf 'curl fallback: wrote .links entry %s (so `playwright-cli install-browser --list` sees this cache).\n' "$link_name"
    fi
  else
    printf 'curl fallback: WARNING — could not compute the .links entry name (playwright-core dir not found, or no sha1sum/python3); --list may fail on this fallback-only cache, but the browser itself is placed.\n'
  fi
  printf 'curl fallback: %s installed at %s (INSTALLATION_COMPLETE marker written — the CLI will skip re-downloading it).\n' "$name" "$dest"
  return 0
}
playwright_curl_fallback() { # reads $state_dir/install.log for the failed URL(s)
  command -v curl >/dev/null 2>&1 || { printf 'curl fallback unavailable: curl not found.\n'; return 1; }
  local log="$state_dir/install.log" urls url ok=1 chrome_urls="" hs_url="" _hs_arch="" _arch="" _chrome_url="" _hs_file=""
  urls="$(grep -oE 'URL: https://[^ ]+\.zip' "$log" 2>/dev/null | sed -E 's/^URL: //' | sort -u || true)"
  if [[ -z "$urls" ]]; then
    # No "Download failed" line (e.g. the CLI died another way): fall back
    # to the last URL it announced downloading.
    urls="$(grep -oE 'from https://[^ ]+\.zip' "$log" 2>/dev/null | sed -E 's/^from //' | tail -1 || true)"
  fi
  [[ -n "$urls" ]] || { printf 'curl fallback unavailable: no download URL in %s.\n' "$log"; return 1; }
  while IFS= read -r url || [[ -n "$url" ]]; do
    [[ -z "$url" ]] && continue
    case "$url" in
      */linux64/chrome-linux64.zip|*/linux-arm64/chrome-linux-arm64.zip|*/mac-arm64/chrome-mac-arm64.zip|*/mac-x64/chrome-mac-x64.zip)
        chrome_urls="${chrome_urls}${chrome_urls:+$'\n'}$url" ;;
    esac
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
  # itself prints on the re-run (VERIFIED via curl HEAD 2026-11-11 on
  # the Chrome-for-Testing public bucket URL: 200 OK, 131,998,580 B =
  # the CLI log's 125.9 MiB). Darwin is the same shape
  # (chrome-mac-arm64.zip -> chrome-headless-shell-mac-arm64.zip,
  # chrome-mac-x64.zip -> chrome-headless-shell-mac-x64.zip — VERIFIED
  # via curl HEAD 2026-11-11: mac-arm64 headless-shell 200 OK,
  # 104,957,869 B). Linux ARM64 is the same shape (D35:
  # chrome-linux-arm64.zip -> chrome-headless-shell-linux-arm64.zip —
  # VERIFIED via curl HEAD 2026-11-13: headless-shell 200 OK,
  # 129,936,972 B; the detection + derivation cases above used to
  # list only linux64/mac-arm64/mac-x64, so an ARM64 run silently
  # never attempted the headless shell). So when a chrome URL
  # was seen but no headless-shell URL was in the log, derive it by
  # filename substitution and fetch it through the same playwright_curl_one
  # (same source, same layout, same per-entry permission restore — nothing
  # is invented from outside the CLI's own URLs). Best-effort: if the
  # derived fetch fails, warn explicitly and keep the chrome result — the
  # post-fallback CLI re-run will retry the headless shell, and the eyes
  # step does not need it (verify.sh eyes use chromium-1254; the headless
  # shell is what `playwright-cli install-browser chrome-for-testing`
  # needs to report a clean install).
  # W-RT2 fix pass (2026-11-13): the guard below is PER-ARCH. Before,
  # ANY headless-shell URL in the log suppressed derivation for EVERY
  # arch, so a log with an arm64 chrome URL and a linux64 headless-shell
  # URL never attempted the arm64 headless shell. Derive the HS URL for
  # the arch of $chrome_url unless an HS URL for THAT SAME arch is
  # already in the log.
  # W2-RT2 fix pass 2 (2026-11-13): the derivation above is PER-ARCH
  # over EVERY chrome URL in the log, not a single `chrome_url` scalar.
  # Before, a log holding two chrome URLs (two arches) derived only the
  # last-sorted one's headless shell and never attempted the other's.
  # One machine has one arch, so this was implausible in production —
  # but the loop is small, the per-arch guard already exists, and a
  # two-chrome log is now a test case (mapping test, W2-RT2).
  for _arch in linux64 linux-arm64 mac-arm64 mac-x64; do
    _chrome_url=""; _hs_file=""
    case "$_arch" in
      linux64) _chrome_url="$(printf '%s\n' "$chrome_urls" | grep -F '/chrome-linux64.zip' | head -n 1 || true)"; _hs_file="chrome-headless-shell-linux64.zip" ;;
      linux-arm64) _chrome_url="$(printf '%s\n' "$chrome_urls" | grep -F '/chrome-linux-arm64.zip' | head -n 1 || true)"; _hs_file="chrome-headless-shell-linux-arm64.zip" ;;
      mac-arm64) _chrome_url="$(printf '%s\n' "$chrome_urls" | grep -F '/chrome-mac-arm64.zip' | head -n 1 || true)"; _hs_file="chrome-headless-shell-mac-arm64.zip" ;;
      mac-x64) _chrome_url="$(printf '%s\n' "$chrome_urls" | grep -F '/chrome-mac-x64.zip' | head -n 1 || true)"; _hs_file="chrome-headless-shell-mac-x64.zip" ;;
    esac
    [[ -z "$_chrome_url" ]] && continue
    _hs_arch="$_arch"; hs_url="${_chrome_url%/*}/$_hs_file"
    if ! printf '%s\n' "$urls" | grep -qF "chrome-headless-shell-$_hs_arch"; then
      printf 'curl fallback: chrome URL seen but no headless-shell URL for %s was logged (CLI died during chrome retries) — deriving it from the same CDN version directory: %s\n' "$_hs_arch" "$hs_url"
      playwright_curl_one "$hs_url" || printf 'curl fallback: WARNING — derived headless-shell fetch failed for %s (non-fatal: the post-fallback CLI re-run will retry it; the eyes step uses chromium-1254 and does not need the headless shell).\n' "$hs_url"
    fi
  done
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
  _pw_cli_present=0
  if command -v playwright-cli >/dev/null 2>&1; then
    printf 'Playwright CLI already on PATH: %s (if this is a mise shim, the real binary is resolved below — the path above is not necessarily the binary that runs)\n' "$(command -v playwright-cli)"
    _pw_cli_present=1
  else
    printf '\nInstalling Playwright CLI %s (pinned)...\n' "$PLAYWRIGHT_CLI_VERSION"
    if run_best_effort "npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION" 300 \
        npm install -g "@playwright/cli@$PLAYWRIGHT_CLI_VERSION"; then
      _pw_cli_present=1
    else
      note_pending "Playwright CLI not installed (npm -g failed — often a permissions/prefix issue). Install it with: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION"
    fi
  fi
  # Resolve the CLI + node to REAL binaries (clean-env 2026-11-11,
  # GAP-5 redo — the round-1 fix was incomplete and run 3 proved it):
  # `command -v playwright-cli` succeeding does NOT mean the CLI runs.
  # On mise-managed machines the PATH entry is a mise shim, and the shim
  # fails at EXEC time ("No version is set for shim: playwright-cli")
  # when invoked from a cwd outside the mise config chain — verify §6
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
  # after the browser step (red-team H7): the prepend is for this step
  # only, not for the hook / MCP / gitleaks / verify steps that follow.
  # TWIN BLOCK (L4 — drift risk): verify.sh §6 contains a near-duplicate
  # of this resolve block. Any fix here MUST also land there (and vice
  # versa) — the two blocks drifted apart before (round-1 fix incomplete,
  # run 3 proved it) and only a paired edit keeps them in step.
  _pw_saved_path="$PATH"
  _pw_saved_path_set=1
  # L1: EXIT trap restores PATH on an early exit (a signal, or a set -e
  # / set -u abort between the prepend and the sequential restore).
  # The trap is the backstop, not the mechanism — the sequential
  # restore below is the normal path. NOTE: this script is EXECUTED,
  # not sourced — do NOT source it. A sourced run would leave the
  # prepend in the caller's shell if the script exits before the
  # sequential restore, and installing this trap clobbers any EXIT
  # trap the caller already had. The trap is unset (`trap - EXIT`)
  # right after the sequential restore, so it cannot linger past this
  # section. Sentinel-guarded (L2) so an empty original PATH still
  # restores (empty, not unset). The trap ALSO removes the scratch
  # dirs (capdir/probe dir) so a set -e abort mid-block does not leak
  # them (M4); the normal path removes them too (idempotent).
  # (M5: the trap's real trigger is signals/aborts — there is no fail()
  # call in this window, so "fail() between prepend and restore"
  # cannot fire it; the comment used to claim otherwise.)
  trap 'if [[ -n "${_pw_saved_path_set:-}" ]]; then PATH="$_pw_saved_path"; hash -r; fi; if [[ "${_pw_capdir_own:-0}" == 1 && -n "${_pw_capdir:-}" ]]; then rm -rf -- "$_pw_capdir" 2>/dev/null || true; fi; if [[ -n "${_pw_probe_dir:-}" && "${_pw_probe_dir:-}" != "${root:-}" ]]; then rm -rf -- "$_pw_probe_dir" 2>/dev/null || true; fi' EXIT
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
  # under $root anyway, fall back to $root (weaker shim check, warned).
  # A kill between mktemp and the cleanup below leaks one /tmp dir —
  # accepted, /tmp is scratch; the normal path removes it.
  _pw_probe_dir="$(TMPDIR=/tmp mktemp -d 2>/dev/null || true)"
  if [[ -z "$_pw_probe_dir" ]]; then
    printf 'WARNING: could not create a temp probe dir — probes run from the repo dir instead (weaker shim check).\n' >&2
    _pw_probe_dir="$root"
  else
    _pw_root_norm=""
    if [[ "$_pw_root_ok" == 1 && -n "${root:-}" && "$root" != "/" ]]; then _pw_root_norm="${root%/}"; fi
    if [[ -n "$_pw_root_norm" && ( "$_pw_probe_dir" == "$_pw_root_norm" || "$_pw_probe_dir" == "$_pw_root_norm"/* ) ]]; then
      printf 'WARNING: temp probe dir %s is under the repo dir %s — falling back to the repo dir (weaker shim check).\n' "$_pw_probe_dir" "$root" >&2
      _pw_probe_dir="$root"
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
    # (empty) results, before the existing PENDING path below.
    # (L-E: npm ABSENT is a different fact from npm present with no
    # bin — say which; and when the earlier `npm install -g` already
    # failed (_pw_cli_present==0), say so instead of implying the
    # binary merely was not found.)
    _pw_m4_extra=""
    if [[ "${_pw_cli_present:-1}" == 0 ]]; then _pw_m4_extra=" (note: the earlier npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION failed — see the PENDING note above)"; fi
    # H1: a failed cd to $root left the tool results empty — say so,
    # instead of printing "<empty>" as if mise had run and returned it.
    if [[ "${_pw_cd_failed:-0}" == 1 ]]; then _pw_m4_extra="$_pw_m4_extra (note: cd to the repo dir failed, so one or both resolvers never ran)"; fi
    _pw_mise_disp="<mise not installed>"
    if command -v mise >/dev/null 2>&1; then _pw_mise_disp="<empty>"; fi
    if [[ "${_pw_cd_failed:-0}" == 1 ]] && command -v mise >/dev/null 2>&1; then _pw_mise_disp="<not run — cd to repo dir failed>"; fi
    [[ -n "$_pw_mise_cli" ]] && _pw_mise_disp="$_pw_mise_cli"
    [[ -n "$_pw_mise_cli_bad" ]] && _pw_mise_disp="<relative path \"$_pw_mise_cli_bad\" — ignored>"
    if ! command -v npm >/dev/null 2>&1; then
      printf 'Playwright CLI resolve: no real binary found — npm is not installed, so no npm prefix was checked; `mise which playwright-cli` (from %s) returned "%s" — proceeding without the PATH prepend.%s\n' "${root-<unset>}" "$_pw_mise_disp" "$_pw_m4_extra"
    else
      _pw_npm_disp="${_pw_npm_prefix:-<npm not found or empty prefix>}"
      [[ -n "$_pw_npm_prefix_bad" ]] && _pw_npm_disp="<relative prefix \"$_pw_npm_prefix_bad\" — ignored>"
      printf 'Playwright CLI resolve: no real binary found — npm prefix "%s" has no bin/playwright-cli; `mise which playwright-cli` (from %s) returned "%s" — proceeding without the PATH prepend.%s\n' "$_pw_npm_disp" "${root-<unset>}" "$_pw_mise_disp" "$_pw_m4_extra"
    fi
  fi
  # The CLI is a node script (#!/usr/bin/env node), so a real node must
  # resolve too. If the CLI dir holds one, done. Otherwise try the real
  # node via `mise which node` — its bin dir can differ from the CLI's
  # (separate mise installs). If that fails as well, leave PATH as-is:
  # a real system node may already be on it, and the --version check
  # below reports a broken shebang instead of silently proceeding.
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
  # wins, and re-check; a still-wrong resolution fails loud below.
  _pw_cli_resolved="$(command -v playwright-cli 2>/dev/null || true)"
  _pw_node_resolved="$(command -v node 2>/dev/null || true)"
  printf 'Playwright CLI resolves to: %s\n' "${_pw_cli_resolved:-<not found>}"
  printf 'Node resolves to: %s\n' "${_pw_node_resolved:-<not found>}"
  _pw_resolve_ok=1
  _pw_resolve_noted=0
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
      printf 'ERROR: Playwright CLI still does not resolve to the selected binary %s/playwright-cli (resolves to %s) — the browser install is skipped.\n' "$_pw_cli_dir" "${_pw_cli_resolved:-<not found>}" >&2
      note_pending "Playwright CLI does not resolve to the selected binary $_pw_cli_dir/playwright-cli (resolves to ${_pw_cli_resolved:-<not found>}) — the browser install was not attempted. Put $_pw_cli_dir first on PATH, then run: playwright-cli install-browser chrome-for-testing."
      _pw_resolve_ok=0; _pw_resolve_noted=1
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
      # Only a probe that RUNS and FAILS (or is inconclusive for a
      # reason other than cd) confirms the rejection; a successful
      # execution exonerates it. A cd failure is inconclusive — do not
      # reject on it (H1), the H3 probe below is the backstop.
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
      printf 'ERROR: Playwright CLI canonical path %s is under a shims dir — a shim passing -x is not a real binary; the browser install is skipped.\n' "$_pw_cli_real" >&2
      note_pending "Playwright CLI resolves through a mise shim ($_pw_cli_real) — the browser install was not attempted. Put a real playwright-cli bin dir ahead of the mise shims on PATH, then run: playwright-cli install-browser chrome-for-testing."
      _pw_resolve_ok=0; _pw_resolve_noted=1
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
      printf 'ERROR: Node canonical path %s is under a shims dir — a shim passing -x is not a real binary; the browser install is skipped.\n' "$_pw_node_real" >&2
      note_pending "Node resolves through a mise shim ($_pw_node_real) — the browser install was not attempted. Put a real node bin dir ahead of the mise shims on PATH, then run: playwright-cli install-browser chrome-for-testing."
      _pw_resolve_ok=0; _pw_resolve_noted=1
    fi
    # M-E fallback: a maybe-shim binary is proven real — or not — by
    # EXECUTING it from the temp probe dir (a mise shim fails there).
    # This probe runs now, before H1, so a rejected maybe-shim still
    # fails with the shim ERROR (and one PENDING), not with a
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
            printf 'ERROR: Playwright CLI canonical path %s is under a shims dir — a shim passing -x is not a real binary; the browser install is skipped.\n' "$_pw_cli_real" >&2
            note_pending "Playwright CLI resolves through a mise shim ($_pw_cli_real) — the browser install was not attempted. Put a real playwright-cli bin dir ahead of the mise shims on PATH, then run: playwright-cli install-browser chrome-for-testing."
            _pw_resolve_ok=0; _pw_resolve_noted=1
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
            printf 'ERROR: Node canonical path %s is under a shims dir — a shim passing -x is not a real binary; the browser install is skipped.\n' "$_pw_node_real" >&2
            note_pending "Node resolves through a mise shim ($_pw_node_real) — the browser install was not attempted. Put a real node bin dir ahead of the mise shims on PATH, then run: playwright-cli install-browser chrome-for-testing."
            _pw_resolve_ok=0; _pw_resolve_noted=1
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
  # Node 22+ — the kit's hard gate (same as the Node 22+ gate above).
  # Fail LOUD: a too-old (or missing/unparseable) post-prepend node
  # skips the browser install with a PENDING note, never a silent run.
  # (M5: the resolved node + CLI versions are logged here and at the
  # probe below.)
  if [[ "$_pw_resolve_ok" == 1 ]]; then
    # L-D: run from the probe temp dir, not the script cwd — a shim
    # node reports v22+ from the repo dir and fails from /tmp. M-C:
    # bounded to 30 s; L-C: stderr captured, first line printed.
    # H1: a failed cd is INCONCLUSIVE, never "node not found" — the
    # probe never ran, so nothing about node is known.
    _pw_node_ver=""; _pw_node_rc=0
    if ! _pw_cd_ok "$_pw_probe_dir"; then
      printf 'WARNING: node --version probe inconclusive (could not cd to probe dir "%s") — cannot confirm Node 22+; the browser install is skipped.\n' "$_pw_probe_dir" >&2
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
      printf 'ERROR: node --version probe was inconclusive (could not cd to the temp probe dir) — cannot confirm Node 22+; the browser install is skipped.\n' >&2
      note_pending "Playwright CLI not attempted (node --version probe was inconclusive — could not cd to the temp probe dir). Re-run ./install.sh; if it repeats, check /tmp permissions."
      _pw_resolve_ok=0; _pw_resolve_noted=1
    elif [[ -z "$_pw_node_ver" ]]; then
      printf 'ERROR: node not found on PATH after the Playwright PATH prepend — the CLI shebang cannot run; the browser install is skipped.\n' >&2
      note_pending "Playwright CLI not attempted (node not found on PATH after the PATH prepend). Install Node 22+, then: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION, then playwright-cli install-browser chrome-for-testing."
      _pw_resolve_ok=0; _pw_resolve_noted=1
    elif [[ ! "$_pw_node_major" =~ ^[0-9]+$ ]]; then
      printf 'ERROR: node --version gave an unparseable result (%s) after the Playwright PATH prepend — cannot confirm Node 22+; the browser install is skipped.\n' "$_pw_node_ver" >&2
      note_pending "Playwright CLI not attempted (node --version gave an unparseable result '$_pw_node_ver' after the PATH prepend). Install Node 22+, then: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION, then playwright-cli install-browser chrome-for-testing."
      _pw_resolve_ok=0; _pw_resolve_noted=1
    elif [[ "10#$_pw_node_major" -lt 22 ]]; then
      printf 'ERROR: Node %s found after the Playwright PATH prepend; the kit requires Node 22+ (frontend-kit SKILL.md step 0.3). The browser install is skipped.\n' "$_pw_node_ver" >&2
      note_pending "Playwright CLI not attempted (Node $_pw_node_ver found after the PATH prepend; the kit requires Node 22+). Install Node 22+, then: npm install -g @playwright/cli@$PLAYWRIGHT_CLI_VERSION, then playwright-cli install-browser chrome-for-testing."
      _pw_resolve_ok=0; _pw_resolve_noted=1
    fi
  fi
  # H3 + execution check (round-3 QC): `command -v` proves the CLI is
  # findable, not that it runs — a broken node shebang fails at exec
  # time. Check it here, guarded, and fail fast: without this the
  # browser step below would spend up to 600 s downloading with a CLI
  # that cannot run, and its failure would be misreported as a
  # download problem. Probe it from a TEMP dir under /tmp, not the
  # invoker's cwd: the invoker's cwd (repo dir) is inside the mise
  # config chain, where shims work — the probe must test the cwd class
  # verify.sh's eyes step runs from. The temp dir is created once,
  # reused for this one probe, and removed afterwards (mktemp dirs
  # under /tmp are fine to leave, but this one is cheap to clean).
  # The captured output also records the CLI version (H1/M5): a version
  # other than the pin is a LOUD warning, not a failure — drift, not a
  # proven breakage (the CLI downloads its own browser revision).
  _pw_cli_runs=0
  _pw_cli_ver=""
  if [[ "$_pw_resolve_ok" == 1 ]] && command -v playwright-cli >/dev/null 2>&1; then
    # _pw_probe_dir was created up front (before M1) and reused here;
    # re-create it only if something cleared it.
    if [[ -z "${_pw_probe_dir:-}" ]]; then
      _pw_probe_dir="$(TMPDIR=/tmp mktemp -d 2>/dev/null || true)"
      if [[ -z "$_pw_probe_dir" ]]; then
        printf 'WARNING: could not create a temp probe dir — probing `playwright-cli --version` from the repo dir instead (weaker shim check).\n' >&2
        _pw_probe_dir="$root"
      fi
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
      _pw_cli_runs=1
      printf 'Playwright CLI version: %s (pin %s)\n' "$_pw_cli_ver" "$PLAYWRIGHT_CLI_VERSION"
      # Exact match on the first dotted-triple in the output (H1): a
      # substring match would also accept 0.1.240 for pin 0.1.24, while
      # "playwright-cli 0.1.24" / "0.1.24-beta" still match.
      _pw_cli_ver_num=""
      if [[ "$_pw_cli_ver" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then _pw_cli_ver_num="${BASH_REMATCH[1]}"; fi
      if [[ "$_pw_cli_ver_num" != "$PLAYWRIGHT_CLI_VERSION" ]]; then
        printf 'WARNING: Playwright CLI version %s does NOT match the pinned %s — drift, not a proven breakage; continuing (the CLI downloads its own browser revision).\n' "$_pw_cli_ver" "$PLAYWRIGHT_CLI_VERSION" >&2
      fi
    elif [[ "$_pw_cli_rc" == 98 ]]; then
      printf 'WARNING: playwright-cli probe was inconclusive (could not cd to the temp probe dir) — the browser install is skipped; see the PENDING note below.\n' >&2
    else
      printf 'WARNING: playwright-cli is on PATH but does not execute from a temp dir (`playwright-cli --version` failed there — usually the #!/usr/bin/env node shebang resolving to a mise shim). The browser install is skipped; see the PENDING note below.\n' >&2
    fi
  fi
  # Probe scratch cleanup: the probe dir is removed here — nothing below
  # needs it — and the capture files go with the scratch dir. (L-H note:
  # a kill between mktemp and here leaks one /tmp dir + a few small
  # files — accepted, /tmp is scratch; the normal path removes them.)
  if [[ -n "${_pw_probe_dir:-}" && "$_pw_probe_dir" != "$root" ]]; then rm -rf -- "$_pw_probe_dir"; fi
  _pw_probe_dir=""
  rm -f -- "$_pw_npm_out" "$_pw_npm_err" "$_pw_mise_cli_out" "$_pw_mise_cli_err" "$_pw_mise_node_out" "$_pw_mise_node_err" "$_pw_node_out" "$_pw_node_err" "$_pw_cli_out" "$_pw_cli_err" "$_pw_probe_err"
  if [[ "$_pw_capdir_own" == 1 && -n "$_pw_capdir" ]]; then rm -rf -- "$_pw_capdir"; fi
  if [[ "$_pw_cli_runs" == 1 ]]; then
    # NOTE (verified 2026-11-10 against @playwright/cli 0.1.24 --help and
    # its own error text): `playwright-cli install` only installs SKILLS —
    # there is NO `playwright-cli install chromium` subcommand (it prints
    # help, exit 0 — a false OK). Browsers come from the CLI's own
    # installer, `playwright-cli install-browser <browser>`. The browser
    # the CLI's --browser=chromium flag needs is `chrome-for-testing`
    # (revision chromium-1254 for CLI 0.1.24); the plain `playwright
    # install chromium` package downloads a DIFFERENT revision (1248)
    # that the CLI does not use. Default `open` wants system Google
    # Chrome (Linux: /opt/google/chrome/chrome; macOS: /Applications/
    # Google Chrome.app/Contents/MacOS/Google Chrome) — verify.sh tries
    # --browser=chromium first, then the default, so either works.
    # The browser cache is HOME-relative (~/.cache/ms-playwright on
    # Linux, ~/Library/Caches/ms-playwright on macOS): a
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
            # --with-deps is a Linux-only flag (it runs apt); omit it on macOS.
            _with_deps=""
            if [[ "$is_darwin" == 0 ]]; then _with_deps=" (on Linux, add --with-deps for system libs — needs sudo)"; fi
            note_pending "Chrome-for-Testing browser not confirmed after the curl fallback (see \`playwright-cli install-browser --list\`). Run: playwright-cli install-browser chrome-for-testing${_with_deps}."
          fi
        else
          _with_deps=""
          if [[ "$is_darwin" == 0 ]]; then _with_deps=" (on Linux, add --with-deps for system libs — needs sudo)"; fi
          note_pending "Chrome-for-Testing browser not installed for Playwright CLI. Run: playwright-cli install-browser chrome-for-testing${_with_deps}. The CLI's Node downloader fails on this network (server closed connection at ~90%); if it fails again, fetch the URL it prints with: curl -C - -L -o <file.zip> <url>, then extract it under $pw_cache_dir/ (see install.sh playwright_curl_fallback for the layout)."
        fi
      fi
    fi
  else
    # GAP-4 (clean-env 2026-11-11): this branch used to not exist — if the
    # CLI was installed but unresolvable, the whole browser step silently
    # did nothing and verify §6 failed with no trace. Never silent.
    # Only when npm actually succeeded (QC 2026-11-11): an npm failure
    # is already reported above, and must not produce a second,
    # contradictory PENDING claiming the CLI is installed. Likewise a
    # resolve failure above (_pw_resolve_noted) already recorded its
    # own PENDING — do not add a second one here.
    if [[ "${_pw_resolve_noted:-0}" == 1 ]]; then
      : # resolve failure already noted above
    elif [[ "$_pw_cli_present" == 1 ]]; then
      if command -v playwright-cli >/dev/null 2>&1; then
        # On PATH but the --version check above failed: it cannot run.
        note_pending "Playwright CLI is on PATH but does not execute (playwright-cli --version fails — usually the #!/usr/bin/env node shebang resolving to a mise shim). Run: playwright-cli --version to see the error; put a real node bin dir ahead of the mise shims on PATH, then run: playwright-cli install-browser chrome-for-testing."
      elif [[ -n "${_pw_npm_prefix:-}" && -x "$_pw_npm_prefix/bin/playwright-cli" ]]; then
        note_pending "Playwright CLI installed (npm install exited 0) but not resolvable on PATH — the browser install was not attempted. Run: playwright-cli install-browser chrome-for-testing (if the command is not found, add \"$_pw_npm_prefix/bin\" to PATH first, or run $_pw_npm_prefix/bin/playwright-cli directly)."
      elif [[ -n "${_pw_mise_bin:-}" ]]; then
        note_pending "Playwright CLI installed (npm install exited 0) but not resolvable on PATH — the browser install was not attempted. The real binary is at $_pw_mise_bin/playwright-cli; add \"$_pw_mise_bin\" to PATH first, or run it directly: $_pw_mise_bin/playwright-cli install-browser chrome-for-testing."
      else
        note_pending "Playwright CLI installed but not resolvable on PATH — the browser install was not attempted. The npm prefix could not be determined; re-run ./install.sh, or find the binary (npm config get prefix) and run: <prefix>/bin/playwright-cli install-browser chrome-for-testing."
      fi
    fi
  fi
  # Restore PATH (red-team H7) — see the resolve block above. L2:
  # sentinel-guarded, so an empty original PATH restores as empty,
  # not as unset. The EXIT trap set in the resolve block is the
  # backstop for an early exit; this is the normal path.
  if [[ -n "${_pw_saved_path_set:-}" ]]; then PATH="$_pw_saved_path"; hash -r; fi
  # M-B: unset the EXIT trap now that PATH is restored sequentially —
  # the restore above ran BEFORE this unset, so the unset cannot break
  # it. (A lingering trap would re-restore a stale PATH on a later exit
  # and, in a sourced run, would outlive this section.)
  trap - EXIT
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
    note_pending "Impeccable hook skipped (--skip-hooks). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$_sp --scope=global (accept the hook, then restart the host). Codex: the installer writes a project hook at $root/.codex/hooks.json — copy it to ~/.codex/hooks.json so it fires in all projects (re-running ./install.sh does this for you)."
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
  # pinned if upstream moves latest. Overwrite, stated plainly (clean-env
  # 2026-11-11, GAP-2/3): upstream's installer DOES lay down its own
  # current skill copy over the kit's generated variants (claude +
  # agents dirs — the two --providers dirs), so a default install could
  # never pass verify.sh §2b/§2d. install.sh restores the vendored
  # variants itself right after the hook step (diff-gated, backup-first
  # via install_dir — see the restore block below the hook section).
  # verify.sh's lockstep is checked against the REPO pin, so a
  # jointly-replaced pair no longer passes undetected.
  providers=""
  for h in $hosts; do case "$h" in claude) providers="${providers:+$providers,}claude";; codex) providers="${providers:+$providers,}codex";; esac; done
  if [[ -n "$providers" ]]; then
    printf '\nInstalling Impeccable hook (impeccable@%s, providers=%s, scope=global)...\n' "$IMPECCABLE_PIN" "$providers"
    hook_log_lines="$(wc -l < "$state_dir/install.log" 2>/dev/null || echo 0)"
    _hook_label="npx impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global"
    if run_quiet 300 npx --yes "impeccable@$IMPECCABLE_PIN" install "--providers=$providers" --scope=global; then
      promote_codex_hook # project hook (if any) -> global, before the read-back below
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
          promote_codex_hook # project hook (if any) -> global, before the read-back below
          if hook_wired; then
            printf 'OK: %s (retry 1/1) (verified — impeccable entry confirmed in host hook config)\n' "$_hook_label"
            printf 'Impeccable hook installed on retry.\n'
          else
            printf 'UNVERIFIED (H6): %s (retry 1/1) exited 0 but no impeccable entry was found in any readable host hook config — NOT reporting OK.\n' "$_hook_label"
            note_pending "Impeccable hook install for providers=$providers reported success on retry but no impeccable entry exists in any host hook config — NOT verified as wired (H6). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global (accept the hook, then restart the host)."
          fi
        else
          printf 'FAILED (non-fatal): %s (retry 1/1) — see %s/install.log\n' "$_hook_label" "$state_dir"
          note_pending "Impeccable hook not installed by script (failed twice; the log shows a transient download/network error — retry when the network is stable). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global (accept the hook, then restart the host)."
        fi
      else
        note_pending "Impeccable hook not installed by script (failure does NOT look like a transient download/network error — see $state_dir/install.log before re-running; do not just retry blindly). Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --providers=$providers --scope=global (accept the hook, then restart the host)."
      fi
    fi
  else
    note_pending "Impeccable hook: no host with a verified --providers token (claude/codex) was installed. Run interactively: npx --yes impeccable@$IMPECCABLE_PIN install --scope=global and pick your host."
  fi
  # Hermes hook has its own VERIFIED command (Impeccable 4.8.2 changelog).
  case " $hosts " in *" hermes "*)
    if command -v hermes >/dev/null 2>&1; then
      # The vendored plugin must be INSTALLED before it can be enabled
      # (clean-env 2026-11-11, GAP-7): `hermes plugins install` takes a
      # Git URL only — no local-path install — so copy the vendored
      # plugin into ~/.hermes/plugins/ first. install_dir is
      # backup-first: a missing copy is installed, a differing one is
      # replaced with the vendored pin (M1 — a repo update to the plugin
      # otherwise never reaches an existing install), and an identical
      # one is left alone (diff-gated, so no backup churn on re-runs).
      # A regular file at the target path is moved aside the same way.
      if [[ -d "$root/vendor/impeccable/skill/hermes-plugin" ]]; then
        if [[ ! -e "$user_home/.hermes/plugins/impeccable-design-hook" ]]; then
          # Subshell (re-QC round 2): install_dir fail()s (exits) on a
          # failed copy, which must not kill the install — a best-effort
          # step. A failure is a PENDING, matching the restore block.
          ( install_dir "$root/vendor/impeccable/skill/hermes-plugin" "$user_home/.hermes/plugins/impeccable-design-hook" ) || note_pending "Vendored Hermes plugin copy failed (install_dir could not place it under ~/.hermes/plugins/) — the hook enable below will fail. Copy it by hand: cp -r $root/vendor/impeccable/skill/hermes-plugin ~/.hermes/plugins/impeccable-design-hook"
        elif ! diff -qr -- "$root/vendor/impeccable/skill/hermes-plugin" "$user_home/.hermes/plugins/impeccable-design-hook" >/dev/null 2>&1; then
          printf 'Updating vendored Hermes plugin (installed copy differs from the vendored pin — backing up first).\n'
          ( install_dir "$root/vendor/impeccable/skill/hermes-plugin" "$user_home/.hermes/plugins/impeccable-design-hook" ) || note_pending "Vendored Hermes plugin update failed (install_dir could not replace it under ~/.hermes/plugins/) — the stale copy stays in place. Copy it by hand: cp -r $root/vendor/impeccable/skill/hermes-plugin ~/.hermes/plugins/impeccable-design-hook"
        fi
      fi
      # --no-allow-tool-override: the enable prompts about overriding
      # built-in tools (a privileged capability); this flag declines it
      # and skips the prompt entirely (VERIFIED 2026-11-11: exit 0, no
      # prompt, plugin listed as enabled). The plugin's
      # transform_tool_result / pre_verify hooks work without the
      # override. Grant later with --allow-tool-override if ever wanted.
      if run_quiet 120 hermes plugins enable --no-allow-tool-override impeccable-design-hook; then
        # S4: directory presence is NOT verification — install.sh just
        # copied the plugin there, so `ls` succeeds by construction even
        # if the enable did nothing. The real check is `hermes plugins
        # list` showing it enabled. (The "not enabled" row contains the
        # word "enabled", so exclude it first.)
        if hermes plugins list 2>/dev/null | grep -i 'impeccable' | grep -vi 'not enabled' | grep -qi 'enabled'; then
          printf 'OK: hermes plugins enable impeccable-design-hook (verified — plugin listed as enabled)\n'
        elif ls "$user_home/.hermes/plugins" 2>/dev/null | grep -qi 'impeccable'; then
          printf 'UNVERIFIED (H6): hermes plugins enable exited 0 and the plugin is installed, but `hermes plugins list` does not show it as enabled — NOT reporting OK.\n'
          note_pending "Hermes Impeccable hook enable reported success but the plugin is not listed as enabled. Run: hermes plugins enable --no-allow-tool-override impeccable-design-hook and confirm it lists as enabled (hermes plugins list)."
        else
          printf 'UNVERIFIED (H6): hermes plugins enable impeccable-design-hook exited 0 but no impeccable plugin was found under ~/.hermes/plugins — NOT reporting OK.\n'
          note_pending "Hermes Impeccable hook enable reported success but no impeccable plugin exists under ~/.hermes/plugins — NOT verified as wired (H6). Run: cp -r $root/vendor/impeccable/skill/hermes-plugin ~/.hermes/plugins/impeccable-design-hook, then hermes plugins enable --no-allow-tool-override impeccable-design-hook and confirm it lists as enabled."
        fi
      else
        printf 'FAILED (non-fatal): hermes plugins enable impeccable-design-hook — see %s/install.log\n' "$state_dir"
        note_pending "Hermes Impeccable hook not enabled. The plugin must be installed first: cp -r $root/vendor/impeccable/skill/hermes-plugin ~/.hermes/plugins/impeccable-design-hook, then run: hermes plugins enable --no-allow-tool-override impeccable-design-hook"
      fi
    else
      note_pending "Hermes hook not attempted (hermes binary not on PATH). Run: hermes plugins enable --no-allow-tool-override impeccable-design-hook"
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

# --- Post-hook restore (clean-env 2026-11-11, GAP-2/3 + GAP-6) -------------
# (a) Restore the vendored Impeccable variants. The upstream hook installer
# overwrites the kit's generated copies (claude + agents dirs — the two
# --providers dirs) with its own current copies, which fail verify.sh
# §2b (top-level version:) and §2d (live self-grade language). Re-copy the
# generated variants over the installed dirs, but ONLY where the installed
# copy actually differs (diff-gated, so a clean tree is untouched), and
# backup-first via install_dir (the upstream copy lands in $backup).
# Runs whenever the hook step ran with a provider (success or not — a
# failed npx run may still have overwritten before failing), never on
# --skip-hooks / dry-run. Scope (red-team H2): only the dirs the
# installer can have touched (claude + the codex dirs agents/codex-skills
# — the --providers list is claude,codex). A hand-edit in one of those
# dirs is indistinguishable from the upstream overwrite, so it is also
# restored — backed up first, and the version being replaced is printed.
if [[ "$dry_run" == 0 && "$skip_hooks" == 0 && -n "${providers:-}" && "${#DONE_DIR_LIST[@]}" -gt 0 ]]; then
  for _restore_dir in "$user_home/.claude/skills" "$user_home/.agents/skills" "$user_home/.codex/skills"; do
    _restore_host="$(done_dir_host "$_restore_dir" || true)"
    [[ -n "$_restore_host" ]] || continue
    _restore_src="$(impeccable_source_for_host "$_restore_host")" || true
    [[ -n "$_restore_src" && -d "$_restore_src" && -d "$_restore_dir/impeccable" ]] || continue
    # diff exit codes (red-team S2): 0 = same, 1 = differs, 2/127 =
    # error (missing/unreadable path, or no diff binary). Only 1 means
    # "restore"; an error is a PENDING, never a restore and never a
    # fatal abort. (diff is coreutils; if it is absent, skip loudly
    # instead of treating everything as differs.)
    if ! command -v diff >/dev/null 2>&1; then
      note_pending "Impeccable variant restore skipped for $_restore_dir/impeccable (diff not found — cannot tell whether the upstream hook installer overwrote it). Re-run ./install.sh on a machine with diff, or compare by hand."
      continue
    fi
    _diff_code=0
    diff -qr -- "$_restore_src" "$_restore_dir/impeccable" >/dev/null 2>&1 || _diff_code=$?
    if [[ "$_diff_code" == 0 ]]; then
      continue
    elif [[ "$_diff_code" != 1 ]]; then
      note_pending "Impeccable variant restore skipped for $_restore_dir/impeccable (diff failed with exit $_diff_code — the installed copy may or may not be the upstream one). Compare by hand: diff -r $_restore_src $_restore_dir/impeccable"
      continue
    fi
    _old_ver="$(grep -m1 -E '^version:' "$_restore_dir/impeccable/SKILL.md" 2>/dev/null | awk '{print $2}' || true)"
    printf 'Restoring vendored Impeccable variant over the upstream hook-installer copy (installed version %s): %s\n' "${_old_ver:-unknown}" "$_restore_dir/impeccable"
    # Best-effort (red-team S2): install_dir fail()s (exits) on a failed
    # copy, which must not kill the install. Run it in a subshell so a
    # failure only fails the subshell, then put the target back from
    # $backup if install_dir moved it away.
    if ( install_dir "$_restore_src" "$_restore_dir/impeccable" ); then
      :
    else
      printf 'WARNING: Impeccable variant restore failed for %s — leaving the installed copy in place.\n' "$_restore_dir/impeccable" >&2
      _rel="${_restore_dir#$user_home/}/impeccable"
      if [[ ! -e "$_restore_dir/impeccable" && -e "$backup/$_rel" ]]; then
        mv -- "$backup/$_rel" "$_restore_dir/impeccable" 2>/dev/null || true
      fi
    fi
  done
fi
# (b) Catch-all Codex promotion (the success branches above already
# promoted before their hook_wired read-back; this covers the failure
# paths, where the installer may still have written the project hook).
# Gated (QC 2026-11-11): --skip-hooks must not move/delete hook files,
# and neither must a run where the hook step never ran (npx missing /
# Node too old / no claude-or-codex provider).
[[ "$skip_hooks" == 0 && -n "${providers:-}" && "${_promote_codex_ran:-0}" != 1 ]] && promote_codex_hook

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
# and verified with sha256sum (or shasum -a 256 on macOS) BEFORE extraction
# — never @latest, never curl|sh, no sudo (installs to ~/.local/bin).
# Best-effort like the hook/MCP/eyes steps: any failure is a PENDING note
# with the exact manual command, never fatal. trufflehog / osv-scanner /
# go-licenses are NOT installed here (no verified pin established for them
# in this round) — the PENDING note below names them as manual alternatives.
# Gitleaks asset per OS/arch (macOS phase, D12): the pinned release
# publishes one tarball per OS/arch; the checksums file is the
# verification source at install time (same trust model as the Linux
# path — the tarball line is grepped from the published checksums.txt
# and verified before extraction). Darwin hashes (from that file,
# VERIFIED 2026-11-11): darwin_arm64 b40ab0ae…eb6a5, darwin_x64
# dfe101a4…952709 (full hashes at GITLEAKS_VERSION above).
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64|Darwin-aarch64) _gl_asset="darwin_arm64" ;;
  Darwin-x86_64|Darwin-amd64) _gl_asset="darwin_x64" ;;
  *) _gl_asset="linux_x64" ;;
esac
# Hash command: GNU sha256sum, else BSD shasum -a 256 (stock macOS has no
# sha256sum). Both read the same checksum format with -c.
_gl_sha_cmd=""
if command -v sha256sum >/dev/null 2>&1; then _gl_sha_cmd="sha256sum";
elif command -v shasum >/dev/null 2>&1; then _gl_sha_cmd="shasum -a 256"; fi
# Profile file for the PATH advice below: zsh (the macOS default shell)
# reads ~/.zshrc, not ~/.profile.
if [[ "$is_darwin" == 1 ]]; then _gl_profile="~/.zshrc"; else _gl_profile="~/.profile"; fi
install_gitleaks() { # pinned tarball + published checksums, into ~/.local/bin
  command -v curl >/dev/null 2>&1 || { printf 'gitleaks install: curl not found.\n'; return 1; }
  [[ -n "$_gl_sha_cmd" ]] || { printf 'gitleaks install: no sha256sum or shasum found.\n'; return 1; }
  local base="https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION"
  local tmpd
  tmpd="$(mktemp -d)" || return 1
  # The tarball MUST be saved under its real filename: the checksum
  # verifier reads the filename FROM the checksum line, so a renamed
  # file can never verify (clean-env 2026-11-11, GAP-1: the old
  # gitleaks.tar.gz name made every fresh install refuse the binary and
  # fail closed on gate 1.1).
  if ! curl -fsSL -o "$tmpd/gitleaks_${GITLEAKS_VERSION}_${_gl_asset}.tar.gz" "$base/gitleaks_${GITLEAKS_VERSION}_${_gl_asset}.tar.gz"; then
    printf 'gitleaks install: tarball download failed.\n'; rm -rf -- "$tmpd"; return 1
  fi
  if ! curl -fsSL -o "$tmpd/checksums.txt" "$base/gitleaks_${GITLEAKS_VERSION}_checksums.txt"; then
    printf 'gitleaks install: checksums download failed — refusing to install an unverified binary.\n'; rm -rf -- "$tmpd"; return 1
  fi
  # Anchored (red-team M6): an unanchored grep would also match a
  # "...tar.gz.sig" line if upstream ever added one, failing the check.
  if ! (cd "$tmpd" && grep "gitleaks_${GITLEAKS_VERSION}_${_gl_asset}.tar.gz$" checksums.txt | $_gl_sha_cmd -c - >/dev/null 2>&1); then
    printf 'gitleaks install: checksum verification FAILED — refusing to install.\n'; rm -rf -- "$tmpd"; return 1
  fi
  if ! tar --no-same-owner -xzf "$tmpd/gitleaks_${GITLEAKS_VERSION}_${_gl_asset}.tar.gz" -C "$tmpd" gitleaks; then
    printf 'gitleaks install: extraction failed.\n'; rm -rf -- "$tmpd"; return 1
  fi
  mkdir -p "$user_home/.local/bin"
  cp -- "$tmpd/gitleaks" "$user_home/.local/bin/gitleaks" || { printf 'gitleaks install: copy to ~/.local/bin failed.\n'; rm -rf -- "$tmpd"; return 1; }
  # No `--` before the path: BSD chmod treats `--` after the mode as a
  # filename ("chmod: --: No such file or directory" — seen on macOS CI
  # 2026-11-11), not as an end-of-options marker. The path is absolute,
  # so it can never start with `-`.
  chmod 755 "$user_home/.local/bin/gitleaks"
  rm -rf -- "$tmpd"
  # Explicit return (QC 2026-11-11): the probe's exit status used to be
  # the function's return value, so a binary that failed to run was
  # reported as "install failed" with no diagnosis. Keep the failure,
  # but say why.
  if ! "$user_home/.local/bin/gitleaks" version >/dev/null 2>&1; then
    printf 'gitleaks install: the installed binary does not run (gitleaks version failed).\n'
    return 1
  fi
  return 0
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
    note_pending "gitleaks $GITLEAKS_VERSION is installed at ~/.local/bin/gitleaks but ~/.local/bin is not on PATH, so gate 1.1 still fails closed. Add it: export PATH=\"\$HOME/.local/bin:\$PATH\" (e.g. in $_gl_profile), then re-run ./verify.sh. Alternative scanners the gate also accepts: trufflehog (see https://github.com/trufflesecurity/trufflehog/releases)."
  fi
else
  note_pending "Secret scanner not installed (gitleaks $GITLEAKS_VERSION install failed — see above; never fatal). Gate 1.1 fails closed without one. Install it manually: curl -fsSL -o /tmp/gitleaks_${GITLEAKS_VERSION}_${_gl_asset}.tar.gz https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/gitleaks_${GITLEAKS_VERSION}_${_gl_asset}.tar.gz && curl -fsSL -o /tmp/gitleaks-checksums.txt https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/gitleaks_${GITLEAKS_VERSION}_checksums.txt && (cd /tmp && grep gitleaks_${GITLEAKS_VERSION}_${_gl_asset}.tar.gz$ gitleaks-checksums.txt | ${_gl_sha_cmd:-sha256sum} -c -) && tar --no-same-owner -xzf /tmp/gitleaks_${GITLEAKS_VERSION}_${_gl_asset}.tar.gz -C /tmp gitleaks && mkdir -p ~/.local/bin && cp /tmp/gitleaks ~/.local/bin/gitleaks && chmod 755 ~/.local/bin/gitleaks (ensure ~/.local/bin is on PATH). Alternatives the gate also accepts: trufflehog; osv-scanner and go-licenses cover the Stage 1 dep/licence checks but do not satisfy 1.1."
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
  printf '\nPreparing Impeccable engine for this machine...\n'
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
             "$user_home/.commandcode/skills/impeccable/scripts/impeccable" \
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
