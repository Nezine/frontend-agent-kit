# Anti-cliché blocklist — step-1 reference

Read this at step 1, before writing tokens. It names the exact generic
patterns the gate and the judge should catch — the failure the
detector cannot catch, because a purple gradient passes every slop
rule and still reads as every other AI page.

Source: garden-skills `web-design-engineer`, SKILL.md section "Avoid
AI-Style Clichés" (table read in full 2026-11-10,
github.com/conardli/garden-skills, commit 08150e75, MIT). The items
below are kit-authored restatements adapted to this loop — no
garden-skills text is vendored verbatim (see SOURCES.md). The WHY is
garden-skills' own reasoning chain, kept because it is the point:
the user wants their brand recognised; AI defaults are the average of
training data, so all brands averaged together means no brand
recognised; AI-default output dilutes the user's identity into "yet
another AI-generated page".

THE ONLY LEGITIMATE EXCEPTION to every item below is "the brand spec
uses it" — at that point it stops being slop and becomes a brand
signature. Record the exception in TASTE.md's hard rules as
`Anti-cliche allow: AC-<n> (reason)`; the script check reads that
line as the waiver.

## Script-checkable items (run in gate.sh leg 1)

These two are enforced by `scripts/gate/anti-cliche.mjs`. A finding
fails the gate like any leg-1 finding. Each finding is labelled
SEEDED: the items are a labelled seed list from garden-skills, NOT
grown from an observed failure in this kit's probe builds. The gate
grows only from observed failures (the gate-growth rule governs — this
is not P8 the proposal; see `references/decisions.md`);
this seed list is the exception, and a seeded item that never fires
on a real build is a candidate for removal.

| ID | Pattern | Why it is slop | When it is actually fine |
| --- | --- | --- | --- |
| AC-1 | Aggressive purple → pink → blue gradient | The "tech vibe" formula the training data converged on; on every SaaS / AI / web3 landing page | The brand itself uses it, or the task satirises this aesthetic |
| AC-2 | Emoji as icon substitute | "No icon library, so use an emoji as filler" — reads as a placeholder the builder forgot to replace | The brand uses emoji (its own product does), or the audience is kids / casual |

## Checklist items (step-1 read, step-4 judge item — no script exists)

These cannot be checked mechanically; the builder reads them at step 1
and the judge treats a hit as a defect. Do not promote one to the gate
without a script that checks it — a rule without a measurement method
is a judgement wearing a number.

| ID | Pattern | Why it is slop | When it is actually fine |
| --- | --- | --- | --- |
| AC-3 | Rounded card + coloured left-border accent | Material / Tailwind-era leftover; visual noise in every dashboard | The user explicitly asks, or the brand spec preserves it |
| AC-4 | SVG-drawn imagery (faces, scenes, objects) | Drawn humans always have misaligned features and feel cheap | Almost never — use real images, generated images, or an honest placeholder |
| AC-5 | CSS silhouette substituting for real product imagery | Generic "tech aesthetic" — the same look across every brand | Never for branded work — fetch the real product image |
| AC-6 | Inter / Roboto / Arial / Fraunces / system-ui as display | Too common; reads as "demo page" rather than "designed product" | The brand spec specifies these (usually with custom adjustments). NOTE: this half is already enforced — `impeccable detect` flags these faces on its overused-font list, so a build from them starts the gate with findings. |
| AC-7 | Cyber-neon on the near-black developer dark | Dark-theme cosplay; baseline noise in dev-tool clones | The brand actually lives in this aesthetic |
| AC-8 | Fabricated stats, fake logo walls, dummy testimonials | Damages credibility; users notice when numbers do not match reality | Never — use placeholders that say "real data needed" |

## Placeholder rule (from the same source)

When an icon, image, or component is missing, a placeholder is more
professional than a poorly drawn fake: missing icon → square + label
(`[icon]`); missing image → a placeholder card with aspect-ratio info
(`16:9 image`); missing data → ask the user, never fabricate; missing
logo → stop and ask, never substitute a brand name in a coloured box.
A placeholder signals "real material needed here". A fake signals
corners cut.
