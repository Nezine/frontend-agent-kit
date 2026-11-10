# PLAN.md — template

<!-- Copy this file into a project as design/PLAN.md and fill it in at step 1,
BEFORE any page HTML is written. The plan is the INTENT artifact: what the
build is supposed to contain. The run log (design/run-log.jsonl) is the
STATE artifact: what actually happened. No third artifact is maintained
by hand. Delete these comments as you fill the file in.

APPROVAL (mode-conditional — see skills/frontend-kit/SKILL.md step 1):
- Solo run: the human approves this plan before any build. No build
  starts on an unapproved plan.
- Human-less / buffet run: there is no human to approve. The plan
  proceeds WITHOUT human approval; the approval substitute is the
  blocking converge check (step 3 / step 6) plus the first-round
  independent grade. The run log labels the plan "approved-by:
  converge-check + round-1 grade (no human present)". Coordinator
  approval is NOT an approval and is never recorded as one.

LOCK: this plan does not move the lock. Round deltas merge into §
Amendments below, into the token dictionary, and into the run log's
notes — NEVER into TASTE.md or tokens.css mid-loop. The lock is
immutable within a direction; a re-pick creates a NEW lock version,
recorded by a new `run-log.mjs lock` entry. A lessons merge into
TASTE.md happens only once, after the human gate approves the build.

CONVERGE: the section inventory below is what the converge check
(scripts/gate/converge-check.mjs) verifies against the built HTML.
List sections by CONTENT, not by order — reordering sections never
fails convergence. Every id listed here must exist as an id in the
built page, or the gate fails and the human gate is not presented. -->

## Decisions

<!-- The decisions this build stands on: reference direction, brief type,
what the page is and is not. One line each, with the reason. -->

- Direction: [e.g. Linear-style dark developer tool — see DESIGN-SYSTEM.md]
- Brief type: [landing / dashboard-app / redesign]
- [Decision]: [reason]

## Assumptions

<!-- What the brief does not say and the plan assumes. Each assumption is
a risk: if it is wrong, the plan is wrong. Name them so the human can
correct them at approval time instead of at the human gate. -->

- [Assumption, e.g. the audience reads English; the product has no
  real photography yet, so the hero uses a UI mock, not a photo]

## Design Read

<!-- The five dials from templates/design/DESIGN-READ.md, copied here as
the declared intent. Dials are Low / Med / High with a one-line anchor
each — they are INTENT, not scores: nothing in the loop reads them as a
grade, and the judge NEVER receives them. -->

- Visual variance: [Low / Med / High — anchor, e.g. Med: one strong
  hero idea, restrained sections]
- Motion intensity: [Low / Med / High — anchor]
- Information density: [Low / Med / High — anchor]
- Asset dependence: [Low / Med / High — anchor]
- Brand fidelity: [Low / Med / High — anchor]

## Purpose + primary user task

<!-- State the purpose BEFORE the section inventory. Structure is chosen to serve this purpose and this task — the inventory below is a consequence of this section, not a starting point. If the purpose or the primary task changes, the inventory must be re-derived, not patched. -->

- Purpose (one sentence, the page's job in the user's words, not the builder's): [e.g. Let a visitor decide in under a minute whether this tool is worth trying.]
- Primary user (one line, who this page is for): [e.g. A developer evaluating tools on a lunch break.]
- Primary user task (one observable task with a start and an end point — NOT a goal restated, NOT a section name): [e.g. Compare this tool against the one they already use and reach the signup decision.]
- Task flow (the steps of the primary task, in order, each one naming what the user does — 3–6 steps): [e.g. 1. Grasp what the tool does. 2. See proof it works. 3. Check the price of trying it. 4. Start the trial.]
- Secondary tasks (at most two, each one line, each with its end point): [e.g. Find the docs link; contact support.]
- Out of scope (what this page deliberately does NOT help the user do): [e.g. It does not teach the tool; it does not compare against every competitor.]

**Rule — structure serves purpose:** every section in the inventory below must serve the purpose or advance a step of the primary task flow. A section that serves no stated purpose and advances no step is challenged: justify it in its inventory note, merge it into a section that does, or delete it. A section may not be justified by "the template has one" or "every landing page has one". The primary task's steps determine section order: the step the user must complete first comes first; a section that answers a later step may not sit above the section that answers an earlier one unless its inventory note says why.

**Rule — one goal, tasks ordered:** state one goal and list its tasks in the order the user performs them — do not list two unrelated goals as two primary tasks. A page with two unrelated goals has no hierarchy to derive, and the inventory will default to the fixed template. The second goal becomes a secondary task or moves to another page. Dashboards are exempt from single-task strictness: a dashboard serves one goal (e.g. understand the state of the system) through several ordered tasks, and its inventory is derived from those tasks in order.

**Purpose lock:** this section is recorded in the run log as the `purpose` field of the taste-lock entry (`run-log.mjs lock --purpose "..."`), so the purpose is locked with the tokens. A purpose failure (a grade-time P1–P5 check, or a purpose change mid-loop) is resolved by re-planning the inventory from the revised purpose or re-picking the direction — recorded in the run log (`run-log.mjs replan --action <re-plan|re-pick> --purpose "..."`). The inventory is never patched in place to fit a changed purpose; it is re-derived.

## Section inventory

<!-- Every section the build must contain, by content. The converge
check reads the FIRST column as the section id: each id must exist as
an `id="..."` in the built HTML. Keep the ids stable across rounds;
adding a section means adding a row here FIRST (the plan leads, the
build follows). -->

| id | section | notes |
| --- | --- | --- |
| hero | Hero | One idea, one CTA |
| features | Features | Three panels, each with a visual |
| pricing | Pricing | Two tiers, no fabricated figures |
| footer | Footer | Closing, dark ground |

## Acceptance criteria (EARS)

<!-- 5–8 testable criteria in WHEN / THE SYSTEM SHALL form. The gate
checks what is stated testably; a criterion no check can verify is a
judge item in step 4, not a gate rule. Include the 390px no-overflow
rule and the three-width rule on every page. -->

- WHEN the viewport is 390px, THE SYSTEM SHALL show one column with no
  horizontal overflow and no glyph clipped at the viewport edge.
- WHEN the page is rendered at 1440 / 768 / 390, THE SYSTEM SHALL show
  every section in the inventory above, each with a real visual.
- WHEN a section is rendered, THE SYSTEM SHALL fill at least 55% of its
  box or merge with its neighbour (no dead band over 288px at desktop
  widths).
- WHEN [criterion from the brief, e.g. the pricing CTA is clicked],
  THE SYSTEM SHALL [expected behaviour].
- [Add 1–4 more criteria from the brief.]

## Screen × state matrix

<!-- Rows: one per section that has dynamic states. Columns: the states
that apply. A cell is N/A (static section — the state does not apply),
`#id` (the state lives in that element of the HTML), or a file path
(the state's frame / story / preview file, relative to the project
root). Free text in a cell is UNCHECKABLE — the judge decides in
step 4, and the converge script lists it, never silently passes it.
Static sections get one row, default state only: inventing
loading / empty / error states for static copy is forbidden.
(State rules and the dynamic-section scoping land with P5; this table
is the plan's half of that work.) -->

| section | default | loading | empty | error | partial |
| --- | --- | --- | --- | --- | --- |
| hero | #hero | N/A | N/A | N/A | N/A |
| features | #features | N/A | N/A | N/A | N/A |
| pricing | #pricing | N/A | N/A | N/A | N/A |
| footer | #footer | N/A | N/A | N/A | N/A |

## Design system (pointer — the declaration lives elsewhere)

<!-- The design-system declaration is templates/design/DESIGN-SYSTEM.md
(rationale only, no token values); the values live in design/tokens.css.
This section states the mapping in one line so the plan stays
self-contained without duplicating either file. On any drift,
tokens.css governs and the declaration is stale. -->

- Declaration: design/DESIGN-SYSTEM.md (reference mapping, do/don't
  rules, rationale)
- Values: design/tokens.css (single source of truth for every value)
- Recipe (if any): [e.g. skills/frontend-kit/references/style-recipes/aesop.md — or "custom", or "none"]

## Amendments

<!-- Round deltas accumulate here (one line per round, newest first),
copied from design/rounds/<n>/delta.md. This section is the plan's
memory of what the rounds learned. It never touches the lock:
TASTE.md and tokens.css are not edited from this section mid-loop. -->

- (none yet)

## Approval record

<!-- Solo run: "Approved by <human> on <date>" — no build before this
line is filled. Human-less run: "Approved-by: converge-check +
round-1 grade (no human present)" — written by the orchestrator after
round 1 grades. -->

- Status: [unapproved / approved / approved-by: converge-check +
  round-1 grade (no human present)]
- Approved by: [name or "—"]
- Date: [date]
