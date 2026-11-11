# Stop rules + degradation ladder

## Stop conditions

Stop the loop when ANY of these is met, whichever comes first:

1. **≥4 on every axis AND gate green AND cross-check clear.** The build is shippable. Present the
   human gate.
2. **A P6 trigger ends work on the direction** (trigger set below): re-pick if re-picks remain,
   else stop and present the human gate with the best version so far.
3. **The round budget is exhausted: after 3 rounds per direction, max 2 re-picks, 9 rounds
   total.** A build that cannot reach ≥4 in 3 rounds is a direction problem (wrong reference,
   wrong tokens) — re-pick a variant (step 2a), not a 4th round. Bias grows with rounds
   (Huang et al. 2024, VERIFIED from the primary PDF Tables 2–6); a 4th round polishes the
   wrong direction harder instead of fixing it. After the 9th round, stop regardless of scores
   and present the human gate with the best version so far.

## P6 trigger set (council decisions D1/D2, 2026-11-10 — the rewritten trigger set)

The loop ends work on a direction on the FIRST non-improving round. There is exactly ONE
trigger count: one.

1. **Round-1 re-pick (a) — conditional.** After round 1, if Layout or Space ≤ 3 AND the
   judge's evidence lines cite the failure (not a bare score), the next action is re-pick
   from the kept variants — not fix-top-2 — ONLY if a structural (break-frame) variant exists
   among the kept variants. If all kept variants are CSS-only (tight brief, break-frame
   skipped), (a) does NOT fire: escalate instead — end work on the direction and present
   the best version + blocker at the human gate. An early re-pick under (a) consumes one
   of the 2 re-picks.
2. **Flat-line (b) — the single stop trigger.** A fix round that improves NO axis AND the
   gate adds no new finding ends work on the direction: re-pick if re-picks remain, else
   stop and present the best version at the human gate.
   **Flat-line test:** no axis improved AND gate findings did not decrease AND no new gate
   finding appeared. **Gate-progress exception (noise guard):** a round where scores are
   flat but the gate fixed a finding is NOT flat — gate progress counts.
   **Confirmation:** one re-grade confirms — the second grade, not a second round; a third
   grade only if the two disagree on the flat-line verdict (the P6(e) median-of-3 form on
   non-final rounds). On the round that would stop the loop, P14's jury-of-3 applies
   INSTEAD — never both; max 3 judge calls on a stop round.
3. **Deleted triggers.** Rule (c) ("same lowest axis stagnates for two rounds") is DELETED
   as a separate trigger — it is the same event as flat-line. Rule (d) ("two non-improving
   rounds = hard stop") is DELETED. The mid-loop human-escalation sentence is DELETED:
   there is no mid-loop human contact.
4. **What "escalate" means.** "Escalate" means END work on the direction and present the
   best version + blocker at the existing human gate (step 6) — no human is contacted
   mid-loop. In buffet mode the run parks in "awaiting human" as designed behaviour, not
   as a stall.
5. **Median-of-3 (e) — non-final rounds only.** A threshold score survives a median-of-3:
   a second grade only when the first is within 1 point of a boundary; a third only if the
   two disagree. On the round that would stop the loop, P14's jury-of-3 applies INSTEAD —
   never both; max 3 judge calls on a stop round.

**D2 dependency (P6(a)).** (a) depends on P10 having landed: the variant set is 5 canonical
+ 1 break-frame = 6 variants (`references/variant-briefs.md` §6;
`skills/frontend-kit/scripts/variant-picker.mjs`), and the break-frame is the structural variant (a) re-picks
to. Vague briefs always have one; a tight brief may skip the break-frame, in which case
(a) cannot fire (see trigger 1 above).

**Stated effect (mechanism only).** No full grade round is spent on a direction after a
flat round (derived estimate, unmeasured). No quantified round saving is claimed.

**Best-version-kept:** keep the best-scoring version. A round that scores lower is
discarded, not iterated on. Best-version-kept is decided by the pairwise verdict when
pairwise runs, by absolute scores otherwise; a tie keeps the incumbent.
**Best-version-kept survives a re-pick:** the best-scoring version across ALL directions
stays the version that ships; a re-pick starts a new direction from scratch but never
discards the previous best. The run log records which version is best and why, so a
regression is visible, not silently kept.

**Stop-round grade (P13).** The round that would stop the loop gets a FULL fresh grade
(1440 / 768 / 390 + references); no carried / not-re-graded axes at the stop decision.

**Calibration context (not a trigger input).** The judge runs ~1 point hot versus the
user's feel (judge mean 3.5/5, ≈7/10, against the user's 6/10 on the 3 probe builds).
Per-axis human grades are BLANK — never invent scores. The judge's scores are the
trigger input; the human feel is not.

**Human-eye acceptance bar: 60% slop-free** (user-ordered 2026-11-10 19:23,
superseding the old 70–80%). The ≥4-on-every-axis stop above is unchanged —
the % is the human-eye bar for the vague-brief acceptance test, the 4-axis
scores are the per-round gate.

## Detecting a trigger + recording it

Run the mechanical detector after each grade (it judges nothing — it compares the last
two round records and the git diff):
`node skills/frontend-kit/scripts/stuck-detector.mjs --project <dir> [--round N] [--page <built.html>]`
It prints `trigger: flat-line | round-1-repick | none`, the reason, and the fix-class hash
(the sha256 of the git diff of `design/tokens.css` + the graded HTML between rounds —
the hash is the diff hash, never builder self-report; there is no P5 script classifier
in this repo, so no classifier output is claimed). The diff is the working-tree diff
against HEAD, so run the detector BEFORE committing the round; a project that commits
per round has no working-tree diff for it to hash. It fails loudly (exit 2) when the run
log is missing, when fewer rounds exist than the trigger needs, when a round needed for
the comparison has no grade or no recorded gate findings, or when no git diff exists.
Record the trigger on the round record that ends the direction:
`node skills/frontend-kit/scripts/run-log.mjs --project <dir> record --round N ... --trigger <flat-line|round-1-repick>`
(`--trigger stagnation` is a RETIRED value for the deleted trigger (c): accepted so old
logs still parse, never emitted by these rules. `--pairwise`, `--pairwise-agrees`,
`--jury`, `--jury-mode`, `--jury-votes` record the pairwise verdict and the stop-round
jury on the same record; see `run-log.mjs` usage.)

## Human gate

Present all of these together, then wait:

- The score table (every round, with grader labels).
- The 3-width screenshots (1440 / 768 / 390).
- 2–4 targeted questions with concrete options (never open-ended "what do
  you think?").
- The recommended next command, ending with `polish`.

The human's pick or adjective maps through the token dictionary
(`skills/frontend-kit/scripts/token-dictionary.mjs`) and re-enters at step 5 — never as a
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

**Hook-enforcement scope (P4, council decision D8-era — see
`references/decisions.md`).** Stop-hook enforcement exists only where the
host supports it (Claude Code / Codex verified; see `BUFFET-MODE.md` F7
— the coordinator cannot set caps on another agent's host). Elsewhere
the same rules are enforced by prose instruction in the skill only,
labelled `prose-only`, never `DEGRADED` — the DEGRADED rung does not
exist. Stop-hook run-log verification and the Cursor `.mdc` are NOT
wired in this kit (open gap, Wave 6 — needs host verification + new
install surface, not a doc edit).

## What a degradation is NOT

- A missing judge is not a reason to let the builder grade. It is a reason
  to drop to the gate-only rung and say so.
- A gate pass is not a design grade. "Gate green" answers "is it broken?",
  not "is it good?". **And "gate green" means BOTH legs green** (`gate.sh`
  + `gate.mjs` on the same build) — a `gate.sh` PASS alone is only leg 1.
- A human pick of a variant is not a grade. It is direction feedback that
  re-enters as token diffs.
