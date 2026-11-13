# Probe briefs — clean-env test (§5, assertion d)

Four vague briefs, written the way a user who is not good at art would write them.
Paste each brief **verbatim** (no elaboration, no added direction) into the host under
test, after the kit is installed. The agent must run the taste-locked loop from the
brief alone: taste lock → variants if direction is unclear → build → gate → grade →
fix → human gate.

Coverage note (verified 2026-11-10): none of the first three briefs asks for
motion or 3D — a grep for `motion|3d|scroll|animat` over the first three briefs
returns nothing — so the fixtures as written cannot produce evidence about
threeui/GSAP delegation. The clean-env test itself was never executed
(`tests/clean-env/README.md`: "Status: specification only"). Brief 4 exists so
the fixtures CAN catch delegation. The gap it closes is an unwired capability,
no live failure yet: no brief to date has needed GSAP/threeui routing.
Probe-set note: adding Brief 4 changes the probe set — scores from the original
3-brief set are a separate vintage from 4-brief runs, and pre/post comparisons
must note it.

Record per brief: whether the taste lock happened before HTML, whether `detect`
fired, whether screenshots were taken at 1440/768/390, whether the hook fired at
least once unprompted, and the final scores with evidence. Also record whether
the final output reads **≥60% slop-free** to the human eye — the human-eye
acceptance bar (user-ordered 2026-11-10 19:23, superseding the old 70–80%).
The probe loop itself still stops at ≥4 on every axis AND gate green, or
after 3 rounds.

**Grader rule:** every score recorded here must carry its named independent grader
label (independent judge sub-agent / Muse-manager / a different model from the
builder). A builder self-grade is FORBIDDEN and invalid — if no independent judge
is available, record the grade as "gate green, vision not available" and the human
gate carries the taste judgement.

The human grades these blind (see `research/judge-calibration.md`).

---

## Brief 1 — Landing page

> Make me a landing page for a language-learning app. Something clean, like Apple
> or Anthropic. It's for busy working people who want to learn English. I don't know
> much about design, just make it look good. One page is fine.

D22 — Do not yield mid-gate, and do not poll in-turn: once the step-3 gate starts, run it to its printed PASS or FAIL in the same turn — never end the turn, hand back to the human, or wait for an outside event before that result — and never re-run or re-check the same gate leg, status, or file repeatedly inside that turn to wait for a different result; fix, then re-run the gate from the top.

Carve-out: the loop's own yields — step-1.7 plan approval, step-2a variant pick, the v0 nod, and the step-6 human gate — and the between-turn buffet polling cadence are not this rule.

## Brief 2 — Dashboard

> I need a dashboard for a small shop owner to see how the shop is doing. Sales,
> what's selling, what's running low. Nothing fancy, just clear and easy to read on
> a laptop and a phone. I don't know what it should look like — you decide.

## Brief 3 — Redesign

> Redesign my portfolio homepage. It's boring right now — just my name, a list of
> projects and some links. I'm a second-year software engineering student who likes
> Linux and building small tools. Make it feel like me, not like a template. I don't
> have a style in mind, surprise me but keep it tasteful.

## Brief 4 — Landing page with motion + 3D hero

> Make me a landing page for a small coffee roastery that sells beans online.
> I want it to feel alive when you scroll — the hero card growing to full-bleed
> as you scroll (Pattern 2, I think it's called?) and the sections fading in as
> they come into view (Pattern 5). And the hero should have a real 3D moment —
> one of those ThreeUI catalog components, a shader or 3D element that fits
> coffee. Nothing too flashy, just enough to feel expensive. One page is fine.
