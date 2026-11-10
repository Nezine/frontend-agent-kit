# Variant scoring procedure — blind, random order, play first

How the 5 structural variants (+ break-frame) are compared and picked.
This procedure governs step 2a selection only — it is not a grade.
Variant screenshots are NEVER scored 1–5; scores belong to built
rounds, after the gate is green.

## 1. Play first, critique later

Generate ALL variants before any critique, comparison, or scoring.
No variant is judged while another is still being built: an early
critique legitimises the first variant and suppresses divergence
(the fixation mechanism in `variant-briefs.md` — primary read 2026-11-10, see that file's evidence note). The v0 checkpoint governs the PICKED
variant's build only — never mid-generation.

Order of operations:

1. Generate the full set (5 canonical + break-frame) with their
   screenshots at the same width.
2. Run `variant-picker.mjs check` — inventory + copy only. A set that
   fails check is fixed before any comparison; a set that passes is
   compared as-is.
3. Only then compare and pick (blind, §2).

## 2. Blind scoring, random order

The human pick is a blind comparative pick:

- Screenshots are shown WITHOUT variant names: rename or shuffle the
  files for viewing (e.g. `view-A.png` … `view-F.png` in random order),
  never in canonical order and never with the doctrine labelled.
  Position bias applies here too — a fixed order favours the first
  screenshot shown.
- Compare on one question only: "which structure carries this content
  best?" Tokens are locked and identical in direction across variants;
  the comparison is structural (doctrine, section order, hero form),
  not a token beauty contest.
- No scores, no rubric, no evidence lines: the output of this step is
  a PICK, not a grade. One pick, recorded by
  `variant-picker.mjs pick --variant <name>` — the pick IS the feedback.
- Do not re-argue the pick in prose. Build on the picked variant only.

Human-less runs (no human to pick) do NOT do blind scoring — they use
the deterministic pick (`variant-picker.mjs pick --auto`): closest to
the locked tokens by exact `--name: value` match; ties break by the
plan's preferred structure (`design/PLAN.md`, `Preferred structure:`
line), else alphabetically. The auto-pick states its rule before
picking and gives no quality verdict.

## 3. Unpicked variants stay available (round-1 re-pick)

- A pick never deletes a variant. `variant-picker.mjs pick` records the
  unpicked variant names in the run-log entry (`unpicked: [...]`) and
  the variant folders stay on disk under `design/variants/`.
- The unpicked set is the re-pick pool for P6: after round 1, if Layout
  or Space scores ≤3, the next action is a re-pick from the kept
  variants — not a fix round. The re-pick logic itself belongs to P6;
  this procedure only guarantees the pool exists and is recorded.
- Never re-propose a variant the run log already records as picked and
  rejected in a later round: the log is the memory that stops rejected
  directions from returning.
- A variant that was never generated cannot be re-picked: if the set
  was generated without a break-frame, the re-pick pool is missing its
  most divergent member — record that gap in the run log instead of
  inventing a variant mid-loop.

## 4. What this procedure does NOT do

- It does not grade: no 1–5 scores, no Type/Layout/Colour/Space axes,
  no evidence lines. If a number appears in a variant comparison, it is
  the auto-pick's token-match count — a closeness measure, not a
  quality score.
- It does not judge the builder's work: variant generation is the
  builder's output, but selection is the human's (or the deterministic
  rule's) — the builder never picks its own variant.
- It does not replace `check`: inventory + copy enforcement is the
  picker's mechanical job (`variant-picker.mjs check`); this procedure
  assumes check already passed.
