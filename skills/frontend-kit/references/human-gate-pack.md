# Human-gate pack — question bank + recommended next commands

The human gate (loop step 6) presents the score table, the 3-width
screenshots, 2–4 targeted questions with concrete options, and the
recommended next command, ending with `polish`. This file is the kit's
ready-to-use question bank so the orchestrator does not invent questions
from priors. Pick 2–4 questions per gate, from the section matching the
brief type, plus at most one from "Any brief". Never ask an open-ended
"what do you think?" — every question carries concrete options, and every
option maps to a token diff (via `scripts/token-dictionary.mjs`), never to
a rebuild.

The human's pick or adjective maps through the token dictionary and
re-enters at step 5 — never as a rebuild. After human approval, save the
3-width screenshots as the pixel-diff baseline.

## Landing page

1. **Direction — does the hero feel like the reference, or like a
   template?**
   - (a) Like the reference — keep the direction, polish the details.
   - (b) Close, but warmer/cooler — name the shift (maps to the
     `warmer`/`cooler` dictionary entries).
   - (c) Still templated — re-pick a variant (step 2a), not a 4th round.
2. **Hierarchy — what should the eye hit first?**
   - (a) The headline (keep display scale).
   - (b) The product visual (raise the visual to ≥25% of its section,
     shrink the headline one step).
   - (c) The primary action (raise the CTA one step, quiet the headline).
3. **Density — is the page the right length?**
   - (a) Right — keep every section.
   - (b) Too long — cut the weakest section (name it; a block with no true
     material goes).
   - (c) Too sparse — one more proof section (a real stat, case, or visual
     — never filler).
4. **Voice — does the copy sound like us?**
   - (a) Yes — lock it.
   - (b) Too formal — loosen the headline + CTA (copy change, no token
     change).
   - (c) Too casual — tighten the headline + CTA.

## Dashboard / app screen

1. **Scan order — is the most important metric first?**
   - (a) Yes — lock the order.
   - (b) No — name the metric that should lead (panel order change, not a
     rebuild).
2. **Density — can you read it at a glance?**
   - (a) Yes — keep the density.
   - (b) Too dense — drop the lowest-value panel (name it).
   - (c) Too empty — the panels are too far apart; tighten gaps one step
     (`denser` dictionary entry).
3. **Phone — does the stacked order still make sense?**
   - (a) Yes — lock it.
   - (b) No — name the panel that should move up in the stack.
4. **States — which state needs designing next?**
   - (a) Empty state (no data yet).
   - (b) Error state (a failed load).
   - (c) Loading state.
   - (d) None — all states read clearly already.

## Redesign

1. **Recognition — does it still feel like the same product?**
   - (a) Yes — the redesign keeps the identity.
   - (b) Too far — name the element that must come back (logo, colour,
     one section).
   - (c) Not far enough — name the element that still reads as the old page.
2. **Survival — did anything you care about disappear?**
   - (a) Nothing missing — lock it.
   - (b) Yes — name the content/link (dropped content is a FAIL, not a
     style choice; it comes back before anything else).
3. **Improvement — what got clearly better?**
   - (a) Hierarchy. (b) Readability. (c) The hero. (d) Nothing yet —
     re-pick the variant.

## Any brief (at most one per gate)

1. **Feel — one adjective for the page as it stands?**
   - Warmer / cooler / bolder / quieter / roomier / denser / rounder /
     sharper — each maps to a dictionary entry (`token-dictionary.mjs`
     starter words); a word outside the dictionary gets added with its
     token change recorded in the run log.
2. **Ship or iterate?**
   - (a) Ship it — save the 3-width baseline, end with `polish`.
   - (b) One more round — fix the top 2 (name them) as token diffs.
   - (c) Re-pick the direction — variant step 2a, not a 4th round.

## Recommended next commands (pick one, end with `polish`)

- `polish` — the build is accepted; save the baseline and stop.
- `fix top 2` — apply the listed token diffs, re-run gate + grade.
- `re-pick <variant>` — the direction is wrong; start the new direction
  from scratch, keeping the best version so far (best-version-kept
  survives a re-pick; max 2 re-picks, 9 rounds total).
- `expert <domain>` — one named expert second opinion before the next
  round (max 2 experts per round; never before the gate is green).
