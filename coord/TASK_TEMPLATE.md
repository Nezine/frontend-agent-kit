# coord/TASK_TEMPLATE.md — delegation contract (P20)

> **Binding (BUFFET-MODE.md §5).** The coordinator fills one copy of this
> template per slice BEFORE dispatch. **No board row is claimable until all
> six fields are filled** — an agent that finds an unfilled row writes
> `BLOCKED — template incomplete` in its own file and does not start.
> Copy this file's sections into the board row's Notes (or link the filled
> copy from the row); either way the six fields must exist before dispatch.
> The ownership table lives on `coord/BOARD.md` and is filled BEFORE dispatch
> (file → agent → round); the coordinator deterministically rejects claims on
> owned files.

## Slice

- **Slice id:** (e.g. `B6`)
- **Board row:** `coord/BOARD.md` (status: `submitted` until claimed)

## 1. Objective

What is to be done, in one paragraph. Name the concrete outcome, not the
activity (e.g. "a `scripts/trial-merge.mjs` that trial-merges two branches and
reports clean/conflict", not "work on merging").

## 2. Output format

Exactly what the agent must produce: file paths (repo-relative), and the
shape of each (e.g. "one JSON object per line in `coord/run-log.jsonl`";
"a Markdown table with columns X / Y / Z"). If the output is a report, say
where it goes (`build-notes/` = outside the repo; `coord/` = in the repo).

## 3. Tools / sources

Which tools, scripts, and sources the agent may use — and which it must NOT
use. Name the primary sources by path/URL (e.g. "the runbook draft at
`build-notes/w-buffet-mode.md` §5.3"; "SYNTHESIS §6 erratum E2"). A source the
agent cannot read is marked CHƯA ĐỌC and never cited as read.

## 4. Boundaries

What the agent must NOT do: files it must not touch, branches it must not
commit to or push, actions it must not take (e.g. "do NOT commit, do NOT push;
do NOT touch `SKILL.md`, `tokens.css`, `scripts/gate/`, `P10/p10-held`,
`W-LOOP-4/5`, `main`/`v1` branches; do NOT fill the §9 blank").

## 5. Effort scale

A rough size so the coordinator can schedule it: `S` (<1 h, one file),
`M` (half a day, a few files), `L` (a full run / multi-file build). This is a
planning aid, not a deadline — a slice that outgrows its scale is split on
the board, not silently extended.

## 6. Definition of done

Checkable conditions, each verifiable by someone other than the agent that
did the work (e.g. "every file referenced by `BUFFET-MODE.md` exists —
listed and checked"; "`node --check` passes"; "the §9 blank is still blank").
A slice is `completed` only when every condition holds; otherwise it is
`failed` (with the failing condition named) or `input-required`.
