# vendor/impeccable — canonical copy, Impeccable skill 4.8.2

Single canonical copy of upstream `skill/` at tag `skill-v4.8.2`
(pbakaus/impeccable, commit `035c8f319edd019936525a062fe99e83ca8d12c6`).
The two hand-maintained v1 variants (`codex-skill/`, `opencode-skill/`)
were deleted in the v2 re-pin: they differed only by path substitution
and the OpenCode one carried a top-level `version:` in its frontmatter,
which is not a spec field and fails Claude plugin packaging hard.

Layout:

- `skill/` — upstream `skill/` verbatim: `SKILL.src.md` (source, not
  installable as-is), `reference/` (41 files), `scripts/` (launcher +
  pinned engine `VERSION` 0.1.21 + checksums), `agents/` (4 subagent
  definitions), `hermes-plugin/`. One checkout artifact, not a content
  change: `skill/scripts/impeccable.cmd` is CRLF on disk while the git
  blob is LF — upstream's own `.gitattributes` (`*.cmd text eol=crlf`)
  writes CRLF on every checkout, so this is what upstream's checkout
  produces too; modulo line endings the file is identical.
- `LICENSE`, `NOTICE.md` — upstream, verbatim.
- `SOURCE.txt` — the pin record (tag, commit, engine).

Per-host variants are GENERATED at install time, never stored here:

```
scripts/generate-host-variants.sh --all --out <dir>
```

It reproduces upstream's own provider transform for `agents`
(Codex / Muse Code universal), `claude-code`, `opencode` and `gemini`,
and its output was verified byte-identical to upstream's generated
`.agents/`, `.claude/`, `.opencode/`, `.gemini/` trees at this tag —
except one deliberate deviation: `version:` is emitted under
`metadata:` on every variant (spec-pure), where upstream emits a
top-level `version:` for Claude/OpenCode/Gemini. Re-verified at
4.8.2 (2026-11-10): the `agents` tree is byte-identical in full; the
other three trees differ only in `SKILL.md` frontmatter, exactly by
that `version:` placement. Upstream's transformer sources
(`scripts/lib/transformers/factory.js`, `providers.js`, `utils.js`,
`skill-categories.js`) are byte-identical between 4.8.1 and 4.8.2, so
the generator needed no change for this re-pin.

## Skill ↔ engine lockstep

The 62-rule `detect` registry lives in the ENGINE, not the skill
(`crates/live/assets/antipatterns.json` at the tag: 62 entries —
31 `slop` / 31 `quality`; severity 16 advisory / 2 error / 44 unset,
i.e. warning-default; README raw L29: "62 deterministic rules").
Recount at 4.8.2 (2026-11-10) is unchanged from 4.8.1: still 62.
Skill 4.8.2 locks to engine 0.1.21 (`skill/scripts/VERSION` and the
upstream root `ENGINE_VERSION` both read `0.1.21`; changelog:
CLI v4.8.2, 2026-11-09, "Engine 0.1.21 brings `impeccable agents` and
the fixes in skill v4.8.2"). Upgrade the skill without the
engine and `detect` silently applies the wrong registry. `verify.sh`
must check the installed engine version against the skill's expected
engine and fail loudly on mismatch; never re-pin the skill alone.
