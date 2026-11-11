# Stop rules + degradation ladder

## Stop conditions

Stop the loop when EITHER condition is met, whichever comes first:

1. **≥4 on every axis AND gate green AND cross-check clear.** The build is shippable. Present the
   human gate.
2. **After 3 rounds.** A build that cannot reach ≥4 in 3 rounds is a
   direction problem (wrong reference, wrong tokens) — re-pick a variant
   (step 2a), not a 4th round. Bias grows with rounds (Huang et al. 2024,
   VERIFIED from the primary PDF Tables 2–6); a 4th round polishes the wrong
   direction harder instead of fixing it. **Re-pick cap: max 2 re-picks, 9
   rounds total** — 3 rounds in the initial direction + at most 2 re-picks
   × 3 rounds each. After the 9th round, stop regardless of scores and
   present the human gate with the best version so far.

Best-version-kept: keep the best-scoring version. A round that scores lower
is discarded, not iterated on. **Best-version-kept survives a re-pick:**
the best-scoring version across ALL directions stays the version that
ships; a re-pick starts a new direction from scratch but never discards
the previous best. The run log records which version is best and why, so
a regression is visible, not silently kept.

**Human-eye acceptance bar: 60% slop-free** (user-ordered 2026-11-10 19:23,
superseding the old 70–80%). The ≥4-on-every-axis stop above is unchanged —
the % is the human-eye bar for the vague-brief acceptance test, the 4-axis
scores are the per-round gate.

## Human gate

Present all of these together, then wait:

- The score table (every round, with grader labels).
- The 3-width screenshots (1440 / 768 / 390).
- 2–4 targeted questions with concrete options (never open-ended "what do
  you think?").
- The recommended next command, ending with `polish`.

The human's pick or adjective maps through the token dictionary
(`scripts/token-dictionary.mjs`) and re-enters at step 5 — never as a
rebuild. After human approval, save the 3-width screenshots as the
pixel-diff baseline so later feedback rounds cannot silently regress it.

## Degradation ladder (every degradation labelled, never silent)

User direction, 2026-11-10: the "builder-graded loop" rung is DELETED. There
is no accepted loop in which the builder grades its own work. A builder
self-grade is FORBIDDEN, and a score without a named independent grader
label is INVALID.

1. **Full loop** — shell + vision + independent-judge sub-agent
   (`judge-subagent`). The default.
2. **Independent-judge loop without sub-agent spawning** — where the host
   cannot spawn sub-agents, the judge is Muse-manager (`muse-manager`) or a
   different model (`other-model`). Labelled as such, every round.
3. **Gate-only loop** — shell, no vision. The grade is exactly **"gate
   green, vision not available"**, never a faked 4/5. The human gate carries
   the full taste judgement. The round IS recordable: `run-log.mjs record
   --round N --grader none --scores none --gate <pass|fail>` (probe G-4 —
   the old script rejected no-grade records; `--grader none` with scores
   is still rejected).
4. **Static-only** — no shell: MCP fallback for eyes, `detect` for gate.
   Same rule: no vision grade without an independent judge; the human gate
   carries the taste judgement.

Text-only local models run steps 0–3 and 5 and stop; the human gate then
carries the full taste judgement.

## What a degradation is NOT

- A missing judge is not a reason to let the builder grade. It is a reason
  to drop to the gate-only rung and say so.
- A gate pass is not a design grade. "Gate green" answers "is it broken?",
  not "is it good?". **And "gate green" means BOTH legs green** (`gate.sh`
  + `gate.mjs` on the same build) — a `gate.sh` PASS alone is only leg 1.
- A human pick of a variant is not a grade. It is direction feedback that
  re-enters as token diffs.
