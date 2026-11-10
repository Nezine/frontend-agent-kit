# Probe briefs — clean-env test (§5, assertion d)

Three vague briefs, written the way a user who is not good at art would write them.
Paste each brief **verbatim** (no elaboration, no added direction) into the host under
test, after the kit is installed. The agent must run the taste-locked loop from the
brief alone: taste lock → variants if direction is unclear → build → gate → grade →
fix → human gate.

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

## Brief 2 — Dashboard

> I need a dashboard for a small shop owner to see how the shop is doing. Sales,
> what's selling, what's running low. Nothing fancy, just clear and easy to read on
> a laptop and a phone. I don't know what it should look like — you decide.

## Brief 3 — Redesign

> Redesign my portfolio homepage. It's boring right now — just my name, a list of
> projects and some links. I'm a second-year software engineering student who likes
> Linux and building small tools. Make it feel like me, not like a template. I don't
> have a style in mind, surprise me but keep it tasteful.
