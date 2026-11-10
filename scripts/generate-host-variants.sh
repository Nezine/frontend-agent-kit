#!/usr/bin/env bash
# generate-host-variants.sh — generate per-host Impeccable skill variants
# from the single canonical copy in vendor/impeccable/skill/.
#
# NEVER hand-maintain per-host variants. The canonical copy is upstream's
# skill/ tree verbatim at the pinned tag (see vendor/impeccable/SOURCE.txt).
# This script reproduces upstream's own provider transform
# (pbakaus/impeccable scripts/lib/transformers/{factory,providers}.js +
# scripts/lib/utils.js, tag skill-v4.8.2) for the hosts this kit installs,
# with ONE deliberate deviation, recorded here and in SOURCES.md:
#
#   * Upstream emits a top-level `version: 4.8.2` in the frontmatter of the
#     Claude, OpenCode and Gemini variants. This kit emits
#     `metadata: {version: 4.8.2}` on EVERY variant instead: a top-level
#     `version:` is not one of the six Agent Skills spec fields and fails
#     Claude plugin packaging hard. Version stays available to the updater
#     under the spec-defined metadata map, exactly as upstream already does
#     for its Codex/agents variants.
#
#   * `allowed-tools` is emitted ONLY for the OpenCode variant (upstream
#     behaviour). Upstream omits it for Claude Code because Claude blocks
#     skill activation in non-interactive sessions when the field is present
#     (impeccable issue #736); the other variants omit it per the kit's
#     canonical rule (safety comes from the host's permission system).
#
#   * Degraded-mode preamble (this kit's grader rule, overrides upstream):
#     upstream's degraded fallback tells the single-context agent "you are
#     both parties" and lets it act on its own output contract — the
#     builder-graded rung this kit deleted. The generated preamble instead
#     forbids single-context self-grading outright: a grade comes only from
#     an independent judge (judge-subagent / muse-manager / other-model);
#     with no independent judge the grade is exactly "gate green, vision
#     not available", and a "⚠️ DEGRADED: single-context" banner is NOT an
#     accepted grade anywhere in this kit.
#
#   * Reference-file transform (this kit's grader rule, overrides upstream):
#     the generated copies of `reference/critique.md` and
#     `reference/new-work.md` are NOT upstream verbatim. Upstream's degraded
#     fallback inside those two files — the `critique.md` banner requirement
#     plus the sequential self-critique fallback (including the Codex gate's
#     three banner lines and the report-header provenance bullet) and the
#     `new-work.md` fresh in-thread finish-reviewer pass plus the Verdict
#     Pass fallback from `degraded/finish-reviewer.md` — is stripped and
#     replaced with a pointer to the kit grader rule (grade only via an
#     independent judge: judge-subagent / muse-manager / other-model;
#     otherwise "gate green, vision not available"). The CANONICAL copies
#     under vendor/impeccable/skill/ stay verbatim; only generated output
#     is transformed. Recorded here and in SOURCES.md. The generator fails
#     loudly if any upstream sentence the transform targets is missing
#     (e.g. re-pin rewording).
#
#   * Semantic self-grade guarantee (replaces the old sentence denylist):
#     the transform used to target 4 known sentences, so any upstream
#     sentence outside the list survived by construction — the native
#     single-context carve-out in `critique.md` and the build-thread
#     "Critique the render" in `new-work.md` both shipped (QC H1, H9).
#     The transform now enumerates EVERY instruction in `critique.md` and
#     `new-work.md` that permits a single-context assessment/grade — the
#     inline permission, the skipped-detector native carve-out, the native
#     paragraph, the native report-header line, the plates scoring, the
#     build-thread critique, the comp-diff "as the critique", the Persuade
#     mode self-check — and replaces each with a pointer to the kit grader
#     rule or deletes it with a recorded decision (see
#     build-notes/w-fix2-generator.md for the full per-instruction list).
#     The self-check at the end of this script then verifies the RESULT
#     semantically: it greps EVERY generated file for the shape of a
#     self-grade permission (assessment verb aimed at the agent's own work,
#     a single-context assessment, the native/degraded carve-outs) and
#     FAILS LOUDLY on any match outside the kit's own prohibiting lines.
#     Judge-role text is deliberately NOT matched: scoring/assessing by a
#     delegated independent sub-agent (Assessment A/B bodies, heuristic
#     tables, Verdict Pass) carries no self-reference and no single-context
#     permission, so it passes; deterministic-gate fixes (comp-diff /
#     `detect` findings) are likewise not grades.
#
# Usage:
#   scripts/generate-host-variants.sh [--host HOST]... [--all] --out DIR
#     --host agents|claude-code|opencode|gemini   (repeatable; default: --all)
#     --out DIR    parent directory; emits DIR/<host>/impeccable/ per host,
#                  or DIR/impeccable/ when exactly one --host is given.
#   Environment: KIT_ROOT (default: repo root, derived from this script).
#   Requires: python3 (no node/bun). Exits non-zero if any placeholder
#   survives, any generated SKILL.md carries a top-level `version:`, or the
#   canonical copy is missing/mismatched with SOURCE.txt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="${KIT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CANONICAL_DIR="${CANONICAL_DIR:-$KIT_ROOT/vendor/impeccable/skill}"
SOURCE_TXT="$KIT_ROOT/vendor/impeccable/SOURCE.txt"

HOSTS=()
OUT_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOSTS+=("$2"); shift 2 ;;
    --all) HOSTS=(agents claude-code opencode gemini); shift ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    --canonical) CANONICAL_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,60p' "$0"; exit 0 ;;
    *) echo "generate-host-variants.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ ${#HOSTS[@]} -gt 0 ] || HOSTS=(agents claude-code opencode gemini)
[ -n "$OUT_DIR" ] || { echo "generate-host-variants.sh: --out DIR is required" >&2; exit 2; }
[ -f "$CANONICAL_DIR/SKILL.src.md" ] || { echo "generate-host-variants.sh: canonical copy missing: $CANONICAL_DIR/SKILL.src.md" >&2; exit 1; }
[ -f "$SOURCE_TXT" ] || { echo "generate-host-variants.sh: SOURCE.txt missing: $SOURCE_TXT" >&2; exit 1; }

# Skill version comes from the pin record, never from a guess.
SKILL_VERSION="$(grep '^tag=' "$SOURCE_TXT" | sed 's/^tag=skill-v//')"
[ -n "$SKILL_VERSION" ] || { echo "generate-host-variants.sh: no tag= in $SOURCE_TXT" >&2; exit 1; }

# Engine lockstep: the canonical tree must carry the engine its tag pins.
PINNED_ENGINE="$(grep '^engine=' "$SOURCE_TXT" | sed 's/^engine=//')"
TREE_ENGINE="$(cat "$CANONICAL_DIR/scripts/VERSION")"
[ "$PINNED_ENGINE" = "$TREE_ENGINE" ] || {
  echo "generate-host-variants.sh: engine mismatch: SOURCE.txt pins $PINNED_ENGINE but skill/scripts/VERSION reads $TREE_ENGINE" >&2
  exit 1
}

export KIT_ROOT CANONICAL_DIR OUT_DIR SKILL_VERSION
export HOSTS_CSV="$(IFS=,; echo "${HOSTS[*]}")"

python3 - "$@" <<'PYEOF'
import json, os, re, shutil, sys

CANONICAL = os.environ["CANONICAL_DIR"]
OUT = os.environ["OUT_DIR"]
VERSION = os.environ["SKILL_VERSION"]
HOSTS = os.environ["HOSTS_CSV"].split(",")

# --- Upstream data, transcribed from pbakaus/impeccable tag skill-v4.8.2 ---
# scripts/lib/transformers/providers.js (frontmatter fields, config dirs,
# provider tags) + scripts/lib/utils.js (PROVIDER_PLACEHOLDERS,
# IMPECCABLE_SUB_COMMANDS, PROVIDER_BLOCK_TAGS) +
# scripts/lib/skill-categories.js (SKILL_CATEGORIES, CATEGORY_ORDER).
# If a re-pin changes any of these upstream, vendor-update.sh flags this
# file for re-check against the new tag.
PROVIDERS = {
    "agents": {
        "config_dir": ".agents", "tags": ["agents", "codex"],
        "placeholder": "codex", "command_prefix": "$",
        "model": "GPT", "config_file": "AGENTS.md",
        "ask": "Ask with Codex's structured user-input/question tool when "
               "available, or directly in chat if it is not, and wait for "
               "the answer before continuing.",
        "fields": [],  # name + description + metadata.version only
        "openai_yaml": True, "agents_toml": True,
    },
    "claude-code": {
        "config_dir": ".claude", "tags": ["claude-code", "claude"],
        "placeholder": "claude-code", "command_prefix": "/",
        "model": "Claude", "config_file": "CLAUDE.md",
        "ask": "Ask with the AskUserQuestion tool and wait for the answer "
               "before continuing.",
        "fields": ["user-invocable", "argument-hint", "license"],
        "short_description": True, "openai_yaml": False, "agents_toml": False,
    },
    "opencode": {
        "config_dir": ".opencode", "tags": ["opencode"],
        "placeholder": "opencode", "command_prefix": "/",
        "model": "Claude", "config_file": "AGENTS.md",
        "ask": "Ask with the `question` tool and wait for the answer before "
               "continuing.",
        "fields": ["user-invocable", "argument-hint", "license", "allowed-tools"],
        "openai_yaml": False, "agents_toml": False,
    },
    "gemini": {
        "config_dir": ".gemini", "tags": ["gemini"],
        "placeholder": "gemini", "command_prefix": "/",
        "model": "Gemini", "config_file": "GEMINI.md",
        "ask": "Ask the user directly to clarify what you cannot infer.",
        "fields": [], "openai_yaml": False, "agents_toml": False,
    },
}

SUB_COMMANDS = ["adapt", "animate", "audit", "bolder", "clarify", "colorize",
                "critique", "delight", "distill", "document", "harden",
                "layout", "onboard", "optimize", "overdrive", "polish",
                "quieter", "shape", "typeset"]
SKILL_CATEGORIES = {
    "impeccable": "create", "shape": "create",
    "critique": "evaluate", "audit": "evaluate",
    "typeset": "refine", "layout": "refine", "colorize": "refine",
    "animate": "refine", "delight": "refine", "bolder": "refine",
    "quieter": "refine", "overdrive": "refine",
    "distill": "simplify", "clarify": "simplify", "adapt": "simplify",
    "polish": "harden", "optimize": "harden", "harden": "harden",
    "onboard": "harden",
    "init": "system", "document": "system", "extract": "system",
    "live": "system", "generate": "system",
}
CATEGORY_ORDER = ["create", "evaluate", "refine", "simplify", "harden", "system"]
PROVIDER_BLOCK_TAGS = {
    "agents", "antigravity", "claude", "claude-code", "codex", "cursor",
    "devin", "dsh", "gemini", "github", "grok", "hermes", "kiro",
    "opencode", "pi", "omp", "qoder", "rovo-dev", "trae", "trae-cn",
    "vibe", "veto",
}
# --- Kit GRADING rule: ONE source of truth (H10) ---------------------------
# The rule itself is KIT_GRADING_CORE, defined ONCE below. Both carriers —
# the degraded .md preamble and the Codex .toml developer_instructions —
# are GENERATED from it, so they cannot drift apart (the pre-fix state had
# two hand-written strings that had already drifted: the .toml carrier
# lacked the "Judge only from the evidence in the input packet" sentence
# the degraded carrier had). The only differences between carriers are the
# framing (inline vs spawned-separately) and the role sentence, which live
# OUTSIDE the core. The generation self-check at the end of this script
# asserts every generated degraded file and every generated .toml contains
# KIT_GRADING_CORE verbatim; a carrier that lost the rule fails generation
# loudly instead of shipping a rule-less agent.
KIT_GRADING_CORE = (
    "never grade your own work in this single context, and "
    "never present a self-critique as a grade. A critique or score is valid only from an independent judge "
    "(a judge-subagent, muse-manager, or a different model/agent with no production history of this build). "
    "If no independent judge is available, there is no grade: report exactly \"gate green, vision not "
    "available\" and leave taste judgement to the human gate. A \"⚠️ DEGRADED: single-context\" banner is "
    "NOT an accepted grade anywhere in this kit."
)

DEGRADED_PREAMBLE = (
    "<!-- Generated from skill/agents/ at build time. Do not edit; edit the agent definition. -->\n"
    "This harness has no subagent capability, so you are running this role inline, in the same context as "
    "the work under review. Adopt only this file's instructions for the pass, and disclose the substitution "
    "in one line of your closing message to the user, outside the output contract. Where the text below "
    "addresses a parent agent, that parent is the calling agent or the human — never yourself in this same "
    "context. Do only what this role defines: a reviewer reviews and edits nothing — the parent applies "
    "the reviewer's fixes; a producer produces only the artifacts its input packet names. Judge only from "
    "the evidence in the input packet (screenshots, comp, contract, gate output); do not re-derive findings "
    "from your own memory of the build.\n"
    "GRADING (kit rule — overrides any text below): " + KIT_GRADING_CORE
)

# Kit GRADING rule for generated Codex agent .toml files. A Codex agent
# spawned via .toml never sees reference/degraded/*.md, so the rule must
# travel in developer_instructions — as the SAME KIT_GRADING_CORE, not a
# second copy of the rule. The framing names the spawned-separately case
# (this carrier's role sentence + evidence-only sentence follow the core).
TOML_GRADING_PREAMBLE = (
    "KIT GRADING RULE (overrides any text below — this agent was spawned separately from the build thread, "
    "never as the builder grading its own work): " + KIT_GRADING_CORE + " "
    "Do only what this role defines: a reviewer reviews and edits nothing — the parent applies the reviewer's "
    "fixes; a producer produces only the artifacts its input packet names. Judge only from "
    "the evidence in the input packet (screenshots, comp, contract, gate output); do not re-derive findings "
    "from your own memory of the build."
)

# --- Kit grader-rule transform for generated critique.md / new-work.md ---
# Upstream's degraded fallback lives INSIDE these two reference files (not
# just in the degraded-agent preambles): critique.md requires the degraded
# banner and a sequential self-critique fallback, and new-work.md offers a
# fresh in-thread finish-reviewer pass plus a Verdict Pass fallback. The
# canonical copies under vendor/impeccable/skill/ stay verbatim; only the
# GENERATED copies are transformed, by exact-sentence replacement below.
# Replacement text deliberately avoids every forbidden phrase the
# self-check greps for, so a surviving hit always means upstream text
# leaked through — never a kit pointer. Each replacement is REQUIRED (a
# missing upstream sentence fails the generation loudly: upstream may have
# reworded it at re-pin, and a silent miss would re-open the hole).
# The Codex-gate bullets exist only when the <codex> provider block
# survives (agents host); on other hosts they are already stripped by
# compile_provider_blocks, so they are replace-if-present there.
KIT_NO_GRADE = (
    "report exactly \"gate green, vision not available\" as the grade, "
    "leaving taste judgement to the human gate"
)
KIT_JUDGE = (
    "an independent judge (a judge-subagent, muse-manager, or a different "
    "model/agent with no production history of this build)"
)

def _must_replace(content, old, new, where):
    if old not in content:
        raise SystemExit(
            f"generate-host-variants.sh: kit grader transform failed for {where}: "
            f"upstream sentence not found (re-pin rewording?) — refusing to emit "
            f"an untransformed copy: {old[:80]!r}...")
    return content.replace(old, new, 1)

def _maybe_replace(content, old, new, where, expect):
    if old in content:
        return content.replace(old, new, 1)
    if expect:
        raise SystemExit(
            f"generate-host-variants.sh: kit grader transform failed for {where}: "
            f"expected Codex-gate sentence not found: {old[:80]!r}...")
    return content

def apply_kit_grader_override(content, name, expect_codex):
    if name == "critique":
        content = _must_replace(content,
            "- Assessment A and B MUST run as two isolated sub-agents whenever a sub-agent/Task tool is exposed. "
            "Running them inline in this context is \"possible\" but is NOT permitted; it is a degraded run. "
            "Inline is allowed ONLY when no sub-agent tool exists (or the user declined, on harnesses that ask). "
            "Native platforms run A alone (see Assessment Orchestration).",
            "- Assessment A and B MUST run as two isolated sub-agents whenever a sub-agent/Task tool is exposed. "
            "Running them inline in this context is NOT permitted: inline is never a grade. With no sub-agent "
            "tool exposed (or the user declined, on harnesses that ask), gather the assessments as evidence "
            f"only and {KIT_NO_GRADE}. On native platforms Assessment B does not apply, but Assessment A still "
            "runs as an isolated sub-agent (see Assessment Orchestration).",
            "critique.md (Hard Invariants inline permission)")
        content = _must_replace(content,
            "- A skipped detector is a failed critique run unless `impeccable detect` is missing or crashes after a real attempt, or the platform is native (see Assessment Orchestration).",
            "- A skipped detector is a failed critique run unless `impeccable detect` is missing or crashes after a real attempt. "
            "On a native platform the detector does not apply: say so in the report header and judge from the platform reference "
            f"instead — the design review still comes only from {KIT_JUDGE}; with no independent judge available there is no grade.",
            "critique.md (skipped-detector native carve-out)")
        content = _must_replace(content,
            "**Native platforms** (`ios` / `android` / `adaptive`): Assessment B does not apply, because `impeccable detect` and the browser overlay read only web markup. Run Assessment A alone in this context and skip both sub-agent gates below, the Codex permission question included: with no B there is nothing to isolate A from, so this is the complete native method and carries no degraded banner. Do not run `impeccable detect` on native source; its empty result reads as clean.",
            "**Native platforms** (`ios` / `android` / `adaptive`): Assessment B does not apply, because `impeccable detect` and the browser overlay read only web markup. Assessment A still runs as an isolated sub-agent, under the gates below (minus the detector step): with no B there is nothing to isolate A from, but the review is still a review, not a self-grade — it comes only "
            f"from {KIT_JUDGE}. With no sub-agent tool exposed, gather the design evidence only and {KIT_NO_GRADE}. "
            "Do not run `impeccable detect` on native source; its empty result reads as clean.",
            "critique.md (native single-context carve-out, H1)")
        content = _must_replace(content,
            "- If you degrade for any reason, the report's first line MUST be a banner: "
            "`⚠️ DEGRADED: single-context (<reason>)`. A silent degraded critique is a failed critique.",
            "- **KIT GRADER RULE (overrides the upstream degraded fallback):** never grade your own work "
            "in this same context, and never present a self-critique as a grade. A critique or score is "
            f"valid only from {KIT_JUDGE}. If no independent judge is available, there is no grade: "
            f"{KIT_NO_GRADE}. The upstream degraded-fallback lines in this file are deleted in this "
            "generated copy and must not be followed.",
            "critique.md (Hard Invariants banner)")
        content = _must_replace(content,
            "- If and only if sub-agents are unavailable, fall back sequentially: finish and record "
            "Assessment A, then run Assessment B, then synthesize, and emit the degraded banner.",
            "- If and only if sub-agents are unavailable, do NOT fall back to grading in this same "
            "context: you may finish and record Assessment A, then run Assessment B, as evidence only "
            f"— then stop and {KIT_NO_GRADE}. A critique or score in this case comes only from "
            f"{KIT_JUDGE}.",
            "critique.md (sequential fallback)")
        content = _must_replace(content,
            "Skipping sub-agents without the banner is the most common failure of this command.",
            "Skipping sub-agents without declaring it in the report header is the most common failure of this command.",
            "critique.md (sub-agent gate close)")
        content = _must_replace(content,
            "- Degraded: `⚠️ DEGRADED: single-context (<reason, e.g. no sub-agent tool exposed>)`",
            "- No independent judge available: `gate green, vision not available` (the grade), with the assessments attached as evidence only",
            "critique.md (report-header provenance)")
        content = _must_replace(content,
            "- Native: `Method: design review only (detector not applicable, native platform)`",
            "- Native: `Method: independent-judge design review only (A: <agent-id>; detector not applicable, native platform)` — if no independent judge ran the review, the grade is exactly `gate green, vision not available`.",
            "critique.md (report-header native line)")
        content = _maybe_replace(content,
            "do not emit the degraded banner just for asking.",
            "do not report \"gate green, vision not available\" just for asking.",
            "critique.md (Codex gate: asking)", expect_codex)
        content = _maybe_replace(content,
            "- If allowed, spawn A and B (in sequence for a desktop app). If declined, run sequentially and lead the report with `⚠️ DEGRADED: single-context (sub-agents declined by user)`.",
            "- If allowed, spawn A and B (in sequence for a desktop app). If declined, do not grade in this same context: gather the assessments as evidence only and lead the report with exactly \"gate green, vision not available\" as the grade.",
            "critique.md (Codex gate: declined)", expect_codex)
        content = _maybe_replace(content,
            "- If `spawn_agent` is not exposed, do not ask; run sequentially and lead with `⚠️ DEGRADED: single-context (spawn_agent unavailable in this session)`.",
            "- If `spawn_agent` is not exposed, do not ask; do not grade in this same context: gather the assessments as evidence only and lead the report with exactly \"gate green, vision not available\" as the grade.",
            "critique.md (Codex gate: spawn_agent unavailable)", expect_codex)
        content = _maybe_replace(content,
            "- If spawning fails after permission, run sequentially and lead with `⚠️ DEGRADED: single-context (sub-agent spawn failed: <exact error>)`.",
            "- If spawning fails after permission, do not grade in this same context: gather the assessments as evidence only and lead the report with exactly \"gate green, vision not available\" as the grade.",
            "critique.md (Codex gate: spawn failed)", expect_codex)
    elif name == "new-work":
        content = _must_replace(content,
            "Score the plates before the review opens: once `build-phase advance` reports nothing but the pending review, run the plan and asset review in [component-review.md](component-review.md), where the user checks the plates and which regions code draws.",
            "Put the plates before the user for scoring before the review opens: once `build-phase advance` reports nothing but the pending review, run the plan and asset review in [component-review.md](component-review.md), where the user checks the plates and which regions code draws.",
            "new-work.md (plates scoring)")
        content = _must_replace(content,
            "Critique the render against the user's request and the direction contract, fix material gaps, and confirm with one final round; two rounds is the ceiling, and fixes batch between them rather than earning per-tweak screenshots.",
            "Record what the inspection round shows as evidence for the finish reviewer — overlap, clipping, and the comp-diff region rows are the reviewer's evidence, not your verdict: do not grade the render yourself. Fix only what the deterministic gates require (a comp-diff region scored missing or contradicted, a `detect` finding), and confirm the captures are valid with one final round; two rounds is the ceiling, and fixes batch between them rather than earning per-tweak screenshots.",
            "new-work.md (build-thread self-critique, H9)")
        content = _must_replace(content,
            "and read its region rows and paired crops as the critique: the side-by-side is the view the build thread never has on its own, and a region it scores missing or contradicted is a fix whatever the page looks like from memory.",
            "and attach its region rows and paired crops as the finish reviewer's evidence: the side-by-side is the view the build thread never has on its own, and a region it scores missing or contradicted is a fix whatever the page looks like from memory.",
            "new-work.md (comp-diff as the critique)")
        content = _must_replace(content,
            "On a Persuade surface, verify the mode did its job: a first-time visitor should know what this is, why it matters, and what to do within seconds, in the form's own vocabulary.",
            "On a Persuade surface, the finish reviewer checks whether the mode did its job: a first-time visitor should know what this is, why it matters, and what to do within seconds, in the form's own vocabulary.",
            "new-work.md (Persuade mode self-check)")
        content = _must_replace(content,
            "Only a harness with no subagent capability at all substitutes a fresh in-thread pass after "
            "stepping fully out of the build context, run from [degraded/finish-reviewer.md](degraded/finish-reviewer.md), "
            "and a substituted or failed-and-replaced review is disclosed in one line at finish, never silently.",
            "A harness with no subagent capability does NOT substitute an in-thread review: the finish "
            f"review comes only from {KIT_JUDGE}; with no independent judge available there is no review "
            f"grade — {KIT_NO_GRADE}. A substituted or failed-and-replaced review is disclosed in one line "
            "at finish, never silently.",
            "new-work.md (finish-reviewer substitution)")
        content = _must_replace(content,
            "(through the harness's agent continuation; without one, run the scoring fresh from "
            "[degraded/finish-reviewer.md](degraded/finish-reviewer.md)'s Verdict Pass)",
            f"(through the harness's agent continuation; without one, there is no verdict pass: {KIT_NO_GRADE})",
            "new-work.md (verdict-pass fallback)")
    return content

# --- YAML emission, mirroring upstream generateYamlFrontmatter ---
def _needs_quoting(v):
    if v == "":
        return True
    if re.search(r"^\s|\s$", v):
        return True
    if re.match(r"^[\[\]{},&*!|>'\"%@`#]", v):
        return True
    if re.match(r"^[?:-](\s|$)", v):
        return True
    if re.search(r": |\s#|:$", v):
        return True
    if re.match(r"^(true|false|null|yes|no|on|off|~)$", v, re.I):
        return True
    if re.match(r"^-?\d+(\.\d+)?([eE][+-]?\d+)?$", v):
        return True
    return False

def _scalar(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if not isinstance(v, str):
        return str(v)
    if _needs_quoting(v):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return v

def frontmatter(fields):
    # fields: ordered list of (key, value); value may be str, bool, list, dict
    lines = ["---"]
    for key, value in fields:
        if isinstance(value, list):
            lines.append(f"{key}:")
            for item in value:
                lines.append(f"  - {_scalar(item)}")
        elif isinstance(value, dict):
            lines.append(f"{key}:")
            for k2, v2 in value.items():
                lines.append(f"  {k2}: {_scalar(v2)}")
        elif isinstance(value, bool):
            lines.append(f"{key}: {'true' if value else 'false'}")
        else:
            lines.append(f"{key}: {_scalar(value)}")
    lines.append("---")
    return "\n".join(lines)

# --- Frontmatter parsing (subset: the known SKILL.src.md shape) ---
def parse_frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        raise SystemExit("generate-host-variants.sh: SKILL.src.md has no YAML frontmatter")
    raw, body = m.group(1), m.group(2)
    fm, cur = {}, None
    for line in raw.split("\n"):
        if re.match(r"^  - ", line):
            if not isinstance(fm.get(cur), list):
                fm[cur] = []
            fm[cur].append(_unquote(line[4:].strip()))
            continue
        m2 = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if m2:
            cur = m2.group(1)
            fm[cur] = _unquote(m2.group(2)) if m2.group(2) else None
    return fm, body

def _unquote(v):
    v = v.strip()
    if len(v) >= 2 and v[0] == '"' and v[-1] == '"':
        return v[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    if len(v) >= 2 and v[0] == "'" and v[-1] == "'":
        return v[1:-1]
    return v

# --- Body transforms (upstream factory.js, in order) ---
BLOCK_RE = re.compile(
    r"(^|\r?\n)[ \t]*<([a-z][a-z0-9-]*)>[ \t]*\r?\n([\s\S]*?)\r?\n[ \t]*</\2>[ \t]*(?=\r?\n|$)"
)

def compile_provider_blocks(content, active_tags):
    active = set(active_tags)
    did = False
    def repl(m):
        nonlocal did
        prefix, tag, body = m.group(1), m.group(2), m.group(3)
        if tag not in PROVIDER_BLOCK_TAGS:
            return m.group(0)
        did = True
        return f"{prefix}{body}" if tag in active else prefix
    out = BLOCK_RE.sub(repl, content)
    if did:
        out = re.sub(r"(?:\r?\n){3,}", "\n\n", out)
    return out

def strip_rule_markers(content):
    return re.sub(r"[ \t]*<!--\s*rule:[a-z0-9-]+\s*-->", "", content)

def replace_placeholders(content, cfg, scripts_path, command_names, all_skill_names):
    cmd_prefix = cfg["command_prefix"]
    if not command_names:
        command_list = ", ".join(f"{cmd_prefix}impeccable {n}" for n in SUB_COMMANDS)
    else:
        command_list = ", ".join(f"{cmd_prefix}{n}" for n in command_names)
    result = (content
              .replace("{{model}}", cfg["model"])
              .replace("{{config_file}}", cfg["config_file"])
              .replace("{{ask_instruction}}", cfg["ask"])
              .replace("{{command_prefix}}", cmd_prefix)
              .replace("{{available_commands}}", command_list))
    # Replace `/skillname` invocations with this provider's command prefix
    # (e.g. `/impeccable` -> `$impeccable` for Codex). The slash must sit
    # outside a path or URL, so `.agents/skills/impeccable`, the launcher
    # invocation `{{scripts_path}}/impeccable <verb>` (a `}}`-preceded path
    # segment, resolved after this pass) stay untouched. Upstream utils.js.
    if cmd_prefix != "/" and all_skill_names:
        for name in sorted(all_skill_names, key=len, reverse=True):
            result = re.sub(
                r"(?<![a-zA-Z0-9_./}>-])/(?=" + re.escape(name) + r"(?:[^a-zA-Z0-9_-]|$))",
                cmd_prefix, result)
    return result

def transform_body(content, cfg, scripts_path, command_names, all_skill_names=("impeccable",)):
    out = compile_provider_blocks(content, cfg["tags"])
    out = replace_placeholders(out, cfg, scripts_path, command_names, all_skill_names)
    out = strip_rule_markers(out)
    out = out.replace("{{scripts_path}}", scripts_path)  # after the slash rewrite, as upstream does
    return out

def summarize_description(desc, max_len=88):
    if len(desc) <= max_len:
        return desc
    clipped = desc[:max_len - 1]
    last = clipped.rfind(" ")
    cut = clipped[:last] if last > 48 else clipped
    return cut.rstrip() + "..."

# --- Load canonical source ---
src_path = os.path.join(CANONICAL, "SKILL.src.md")
fm, src_body = parse_frontmatter(open(src_path, encoding="utf-8").read())
for req in ("name", "description", "license"):
    if not fm.get(req):
        raise SystemExit(f"generate-host-variants.sh: SKILL.src.md frontmatter lacks {req}")
if fm["name"] != "impeccable":
    raise SystemExit(f"generate-host-variants.sh: unexpected skill name {fm['name']!r}")

meta_path = os.path.join(CANONICAL, "scripts", "command-metadata.json")
commands = list(json.load(open(meta_path, encoding="utf-8")).keys())
# {{command_hint}}: grouped by category, upstream factory.js order.
grouped = []
for cat in CATEGORY_ORDER:
    names = [c for c in commands if SKILL_CATEGORIES.get(c) == cat]
    if names:
        grouped.append("|".join(names))
command_hint = " · ".join(grouped)
argument_hint = (fm.get("argument-hint") or "").replace("{{command_hint}}", command_hint)
if "{{" in argument_hint:
    raise SystemExit("generate-host-variants.sh: argument-hint still has a placeholder")

# Reference file names (without .md) in canonical order.
ref_dir = os.path.join(CANONICAL, "reference")
ref_names = sorted(
    os.path.splitext(f)[0]
    for f in os.listdir(ref_dir)
    if f.endswith(".md") and os.path.isfile(os.path.join(ref_dir, f))
)
# Agent definitions (name minus impeccable- prefix = degraded role name).
agent_dir = os.path.join(CANONICAL, "agents")
agent_files = sorted(f for f in os.listdir(agent_dir) if f.endswith(".md"))

single = len(HOSTS) == 1
for host in HOSTS:
    if host not in PROVIDERS:
        raise SystemExit(f"generate-host-variants.sh: unknown host {host!r} (agents|claude-code|opencode|gemini)")
    cfg = PROVIDERS[host]
    scripts_path = f"{cfg['config_dir']}/skills/impeccable/scripts"
    out_dir = os.path.join(OUT, "impeccable") if single else os.path.join(OUT, host, "impeccable")
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    os.makedirs(os.path.join(out_dir, "reference"), exist_ok=True)
    os.makedirs(os.path.join(out_dir, "scripts"), exist_ok=True)

    # Frontmatter: spec-pure on every variant (see header comment).
    desc = fm["claude-code-description"] if cfg.get("short_description") else fm["description"]
    fields = [("name", "impeccable"), ("description", desc)]
    if "user-invocable" in cfg["fields"]:
        fields.append(("user-invocable", True))
    if "argument-hint" in cfg["fields"]:
        fields.append(("argument-hint", argument_hint))
    if "license" in cfg["fields"]:
        fields.append(("license", fm["license"]))
    fields.append(("metadata", {"version": VERSION}))
    if "allowed-tools" in cfg["fields"]:
        fields.append(("allowed-tools", [
            "Bash(npx impeccable *)",
            f"Bash({scripts_path}/impeccable *)",
        ]))
    body = transform_body(src_body, cfg, scripts_path, ["impeccable"]).strip()
    open(os.path.join(out_dir, "SKILL.md"), "w", encoding="utf-8").write(
        frontmatter(fields) + "\n\n" + body)

    for name in ref_names:
        p = os.path.join(ref_dir, name + ".md")
        content = transform_body(open(p, encoding="utf-8").read(), cfg, scripts_path, [])
        if name in ("critique", "new-work"):
            # Kit grader-rule transform (see header + apply_kit_grader_override):
            # the canonical copies stay verbatim; only generated output is
            # transformed. The Codex-gate bullets survive only when this host
            # keeps the <codex> provider block (agents host).
            content = apply_kit_grader_override(content, name, "codex" in cfg["tags"])
        open(os.path.join(out_dir, "reference", name + ".md"), "w", encoding="utf-8").write(content)

    # Degraded-mode fallbacks, single-sourced from skill/agents/.
    degraded = os.path.join(out_dir, "reference", "degraded")
    os.makedirs(degraded, exist_ok=True)
    for fname in agent_files:
        agent = parse_frontmatter(open(os.path.join(agent_dir, fname), encoding="utf-8").read())
        agent_body = agent[1]
        role = fname[:-3].replace("impeccable-", "", 1)
        abody = compile_provider_blocks(agent_body, cfg["tags"])
        abody = replace_placeholders(abody, cfg, scripts_path, [], ["impeccable"])
        abody = strip_rule_markers(abody)
        abody = abody.replace("{{reference_path}}", "..")
        abody = abody.replace("{{scripts_path}}", scripts_path)
        open(os.path.join(degraded, role + ".md"), "w", encoding="utf-8").write(
            DEGRADED_PREAMBLE + "\n\n" + abody.strip())

    # Scripts: verbatim (no script in this tree carries a provider marker).
    for fname in sorted(os.listdir(os.path.join(CANONICAL, "scripts"))):
        sp = os.path.join(CANONICAL, "scripts", fname)
        dp = os.path.join(out_dir, "scripts", fname)
        if os.path.isdir(sp):
            shutil.copytree(sp, dp)
        else:
            shutil.copy2(sp, dp)

    # Codex-only extras: nested agent .toml files + OpenAI metadata.
    # Body transform mirrors upstream renderAgentBody (provider blocks,
    # placeholders, rule markers, {{reference_path}} relative from the
    # agents/ emit dir to reference/, {{scripts_path}}).
    if cfg.get("agents_toml"):
        agents_out = os.path.join(out_dir, "agents")
        os.makedirs(agents_out, exist_ok=True)
        for fname in agent_files:
            afm, abody = parse_frontmatter(open(os.path.join(agent_dir, fname), encoding="utf-8").read())
            codex_name = afm.get("codex-name") or fname[:-3].replace("-", "_")
            desc_a = afm.get("description", "")
            abody = compile_provider_blocks(abody, cfg["tags"])
            abody = replace_placeholders(abody, cfg, scripts_path, [], ["impeccable"])
            abody = strip_rule_markers(abody)
            abody = abody.replace("{{reference_path}}", "../reference")
            abody = abody.replace("{{scripts_path}}", scripts_path)
            body_txt = TOML_GRADING_PREAMBLE + "\n\n" + abody.strip().replace("\r\n", "\n")
            if "'''" in body_txt:
                raise SystemExit(f"generate-host-variants.sh: agent body contains ''' : {fname}")
            toml = f'name = {json.dumps(codex_name)}\n'
            toml += f'description = {json.dumps(desc_a)}\n'
            if afm.get("effort"):
                toml += f'model_reasoning_effort = {json.dumps(afm["effort"])}\n'
            nicks = afm.get("nickname-candidates")
            if nicks:
                toml += "nickname_candidates = [" + ", ".join(json.dumps(n) for n in nicks) + "]\n"
            toml += "developer_instructions = '''\n" + body_txt + "\n'''\n"
            open(os.path.join(agents_out, codex_name + ".toml"), "w", encoding="utf-8").write(toml)
        short = summarize_description(fm["description"])
        openai_yaml = (
            "interface:\n"
            f"  display_name: Impeccable\n"
            f"  short_description: {_scalar(short)}\n"
            "  default_prompt: Use Impeccable to redesign, critique, audit, or polish this frontend."
        )
        open(os.path.join(agents_out, "openai.yaml"), "w", encoding="utf-8").write(openai_yaml)

    # --- Self-checks: the generated variant must be shippable as-is. ---
    nfiles = sum(len(fs) for _, _, fs in os.walk(out_dir))
    problems = []
    for root, _, files in os.walk(out_dir):
        for f in files:
            p = os.path.join(root, f)
            text = open(p, encoding="utf-8", errors="ignore").read()
            if "{{" in text and "}}" in text:
                left = sorted(set(re.findall(r"\{\{[a-z_]+\}\}", text)))
                if left:
                    problems.append(f"{p}: unresolved placeholders {left}")
    # --- Semantic self-grade check (H1/H9: the old 4-phrase denylist
    # missed every upstream sentence outside the list). This greps EVERY
    # generated file for the SHAPE of a self-grade permission — an
    # assessment verb aimed at the agent's own work, a single-context
    # assessment, or the native/degraded carve-outs — and fails loudly on
    # any match outside the kit's own prohibiting lines. A match is exempt
    # only when its line contains one of KIT_PROHIBITION_MARKERS: exact
    # substrings of text this generator itself wrote as a prohibition
    # (preamble, kit replacements). Upstream text never contains them
    # verbatim; if a re-pin ever did, the exemption would be a false
    # negative, which is why the _must_replace calls above fail loudly on
    # rewording instead of silently passing. Judge-role text is NOT
    # matched by design: scoring/assessing by a delegated independent
    # sub-agent (Assessment A/B bodies, heuristic tables, Verdict Pass)
    # carries no self-reference and no single-context permission, so it
    # passes; deterministic-gate fixes (comp-diff / `detect` findings)
    # are likewise not grades.
    SELF_GRADE_PATTERNS = [
        ("you are both parties", r"you are both parties"),
        ("DEGRADED: single-context banner", r"DEGRADED:\s*single-context"),
        ("fresh in-thread pass/review", r"fresh in-thread (pass|review|verdict)"),
        ("in-thread substitution", r"substitut\w*\s+a\s+fresh in-thread"),
        ("single-context self-assessment", r"single-context\s+(self-)?(critique|assessment|grade|grading|review|scoring)"),
        ("assessment verb + own work", r"\b(assess|critique|grade|score|review|evaluate|judge)\w*\s+(?:your|its|their|one'?s)\s+own\b"),
        ("own work + assessment verb", r"\b(your|its|their)\s+own\s+(work|build|render|output|code|design)\b[^.\n]{0,80}\b(assess|critique|grade|score|review|evaluat|judg)\w*"),
        ("assessment verb + in this/the context", r"\b(assess|critique|grade|score|review|evaluate|judge|grad)\w*\b[^.\n]{0,60}\bin (?:this|the) (?:same )?context\b"),
        ("in this/the context + assessment verb", r"\bin (?:this|the) (?:same )?context\b[^.\n]{0,60}\b(assess|critique|grade|score|review|evaluat|judg)\w*"),
        ("alone in this context", r"\balone in this context\b"),
        ("complete native method / no degraded banner", r"complete native method|carries no degraded banner|no degraded banner"),
        ("critique the render/build", r"\bcritique the (render|build|work|page|output)\b"),
        ("assessment verb + object + yourself", r"\b(assess|critique|grade|score|review|evaluate|judge)\w*\s+(?:the|this|that|your|its|their)\s+\w+\s+yourself\b"),
        ("verify the mode did its job", r"verify the mode did its job"),
        ("carry out the production steps yourself", r"carry out the production steps yourself|production steps yourself"),
        ("work you just finished", r"work you just finished|step fully out of the work"),
        ("run the scoring fresh", r"run the scoring fresh"),
        ("self-critique / self-grade word", r"self-critique|self-grading|self-grade"),
        ("score the plates", r"\bscore the plates\b"),
    ]
    KIT_PROHIBITION_MARKERS = [
        "never grade your own work",
        "never present a self-critique as a grade",
        "NOT an accepted grade",
        "do NOT fall back to grading",
        "do not grade in this same context",
        "does NOT substitute an in-thread review",
        "not a self-grade",
        "do not grade the render yourself",
        "you are running this role inline",
        "inline is never a grade",
        "is how a rejected page ships twice",
    ]
    COMPILED_PATTERNS = [(name, re.compile(pat, re.I)) for name, pat in SELF_GRADE_PATTERNS]
    for root, _, files in os.walk(out_dir):
        for f in files:
            p = os.path.join(root, f)
            text = open(p, encoding="utf-8", errors="ignore").read()
            for lineno, line in enumerate(text.split("\n"), 1):
                if any(m in line for m in KIT_PROHIBITION_MARKERS):
                    continue
                for pname, rx in COMPILED_PATTERNS:
                    if rx.search(line):
                        problems.append(f"{p}:{lineno}: surviving single-context self-grade language [{pname}]: {line.strip()[:160]!r}")
                        break
    # --- H10: one source of truth, enforced. Every carrier of the kit
    # GRADING rule — each generated reference/degraded/*.md and each
    # generated agents/*.toml — must contain KIT_GRADING_CORE verbatim.
    # A carrier that lost the rule (bad prepend, future refactor) fails
    # generation here instead of shipping a rule-less agent.
    carriers = []
    degraded_dir = os.path.join(out_dir, "reference", "degraded")
    if os.path.isdir(degraded_dir):
        carriers += [os.path.join(degraded_dir, f) for f in os.listdir(degraded_dir) if f.endswith(".md")]
    agents_dir = os.path.join(out_dir, "agents")
    if os.path.isdir(agents_dir):
        carriers += [os.path.join(agents_dir, f) for f in os.listdir(agents_dir) if f.endswith(".toml")]
    for carrier in sorted(carriers):
        carrier_text = open(carrier, encoding="utf-8", errors="ignore").read()
        if KIT_GRADING_CORE not in carrier_text:
            problems.append(f"{carrier}: missing KIT_GRADING_CORE verbatim (H10 — carrier lost the kit grader rule)")
    skill_md = open(os.path.join(out_dir, "SKILL.md"), encoding="utf-8").read()
    fm_out, _ = parse_frontmatter(skill_md)
    if "version" in fm_out:
        problems.append(f"{out_dir}/SKILL.md: top-level version: present (must live in metadata)")
    m_meta = re.search(r"^metadata:\n  version: (\S+)\s*$", skill_md, re.M)
    if not m_meta or m_meta.group(1).strip('"') != VERSION:
        problems.append(f"{out_dir}/SKILL.md: metadata.version != {VERSION}")
    if problems:
        print("generate-host-variants.sh: FAILED self-check for host", host, file=sys.stderr)
        print("\n".join("  " + p for p in problems), file=sys.stderr)
        sys.exit(1)
    print(f"  {host}: {nfiles} files -> {out_dir}")

print(f"generate-host-variants.sh: done (skill {VERSION}, engine lockstep checked)")
PYEOF
