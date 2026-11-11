# The metric-locked agent loop — mapped onto the kit's taste-locked deterministic-gate loop

A vendored reference for the taste lock (`skills/frontend-kit/SKILL.md`
step 1) and the deterministic gate (step 3). It maps Alexandr Wang's
metric-first agent loop, as he described it at YC Startup School 2026,
onto the kit's own loop — one to one. The mapping is the kit's reading
of his words, not his description of the kit: **nothing in this file
implies Wang endorses the kit. He does not, anywhere in the sources
read.**

**Verification basis.** Every Wang quote below comes from the research
synthesis `research_notes/alexander-wang-statements-20261111/REPORT.md`
(synthesis date / access date for all sources: **2026-11-11**), which
checked the four fixed worker reports against two red-team verdicts.
Each claim carries its source URL and the access date, per council
rules 1/2/5. **Tier key (the synthesis's):** Tier 1b = third-party
transcript read by the worker — YC read in full; Lightcone read ~23%
(lines 0–150 of 654, see Sources) — wording approximate at the word
level where ASR errors are visible; **no YC quote below was checked
against video audio.** Paraphrase = labelled as such, never presented
as a quote. The synthesis is the authority where this file and any
other summary disagree; its §7 do-not-carry-forward list governs what
stays out of the kit (§10).

## 1. The mapping

| Wang's loop (YC 2026, Tier 1b) | Kit's loop (taste-locked deterministic-gate) |
|---|---|
| "Mechanically figuring out what the metric is…" — the metric/eval first | The lock defines the pass/fail metric (taste criteria + checks) **before** any builder agent runs (step 1.8) |
| "the right eval or the right metric for the agents to optimize" — the condition for the swarm claim | The gate IS the eval: agents optimise against the gate, not against a vibe (step 3) |
| "skills, markdown files, cron jobs" — mundane mechanics after the metric | The kit's skills + markdown + scheduled/triggered runs as the mechanics (§4) |
| "it's easy to get to ninety percent, very very hard to get to ninety-nine percent" — the last-10% warning | The gate's job is the last 10%: a build that passes at 90% still fails the gate (§3) |

The verified fragments behind the table:

> "Mechanically figuring out what the metric is. And then, yeah, it just
> comes down to skills, markdown files, cron jobs."
— YC Startup School 2026, transcript-derived (Tier 1b):
https://www.ycrootaccess.com/p/alexandr-wang-building-a-frontier
(accessed 2026-11-11).

> "The AI industry really continues to suffer from a lack of very hard
> evals and very hard tests that show really like the frontier of model
> capabilities."
— Lightcone, 18 Jun 2025, transcript-derived (Tier 1b), via the GitHub
mirror of the YC-page transcript:
https://github.com/vishalrohra/founder-wiki/blob/HEAD/raw/videos/MV-alexandr-wang-building-scale-ai-transforming-work-with-agents-competing-with-china.md
(accessed 2026-11-11).

## 2. Wording discipline — binding

These rules bind every kit file that touches this material. Violating
any of them fails QC.

- **The swarm claim, only in conditional form, with the condition
  attached every time:** Wang said that *with the right agentic loop
  and the right eval/metric*, a swarm of agents can accomplish more
  than a team of a hundred engineers "very easily, actually" — an
  unaudited internal anecdote about unspecified Meta cases, not
  evidence, and never a claim about the kit's efficacy. Full wording:
  "I think we've seen internally at Meta cases where if you can
  develop the right agentic loop and you have the right eval or the
  right metric for the agents to optimize, you can have a swarm of
  agents accomplish more than a team of a hundred engineers very
  easily, actually." (YC, Tier 1b; same transcript URL, accessed
  2026-11-11.) Never present the kit, or any agent swarm, as doing
  the work of 100 engineers on Wang's authority.
- **"Wrong metric = fail faster" is the kit's own design principle,
  never a Wang quote.** No sentence to this effect exists in the
  transcript. It appears in this kit only as our labelled principle:
  with the wrong metric, releasing more agents just fails faster.
  Never put it in quotation marks attributed to Wang, never cite it
  as his words.
- **"Lock the metric first, then release the agents" is a Paraphrase,
  never a Wang sentence.** The sequence is verified ("figuring out
  what the metric is. And then, yeah, it just comes down to…"), but
  the imperative sentence is the reel's / commentators' compression
  of it. Use it only labelled **Paraphrase**.
- **The kit's `GOAL.md` / `skills/` / cron shape is the kit's own
  implementation, never Wang's spec** — see §4. Never describe the
  kit's file layout as "Wang's method".
- **No endorsement.** The kit cites his words with tier + source; it
  never implies he endorses, uses, or approves of the kit.

## 3. The gate IS the eval — and its job is the last 10%

Order of operations in this loop, stated as the kit's rule (the
sequence is Wang's verified order; the numbered form is the kit's):

1. Define the metric/eval first — the lock (step 1.8) states what
   pass/fail means before any builder runs.
2. Build the loop around it — builders optimise against the gate.
3. Only then scale the work — more agents, more rounds, more tokens.

Reversing that order produces impressive-looking activity and no
result. (That last sentence is a commentator's gloss on Wang, not
Wang's words — labelled as such wherever it is reused.)

The gate's job is the last 10%. Wang's closest verified failure-mode
statement (Lightcone, Tier 1b, same GitHub mirror as §1, accessed
2026-11-11):

> "it's easy to get to ninety percent, very very hard to get to
> ninety-nine percent… that final ten percent of accuracy will require
> a lot of work."

A build that looks good at 90% and stalls at 99% is the normal failure
mode of a loop without a hard eval — which is why the gate, not the
grade, is the loop's load-bearing part. The vision grade (step 4)
judges taste against the locked reference; the gate decides whether
anything is shippable at all. Budget for the last 10%: it is where
most of the work lives.

Case study — evals as launch discipline (Paraphrase / near-verbatim
via secondary, NOT primary-verified): in the Founders/Senra account
of building Muse, Meta listed 100+ specific behaviours a personal
agent needed, built an evaluation for each, set a launch-blocking
threshold and a "good" threshold per row, and refused to launch while
~20 rows were red (earlier checkpoints ~80 green / 20 red); launch
only when a checkpoint went green across the board. Sources:
https://www.allthingsmuse.com/articles/alexandr-wang-david-senra-muse-build-story/
and https://www.the-ai-corner.com/p/meta-muse-alexandr-wang-interview
(both accessed 2026-11-11); the evals-threshold line itself was
verified verbatim in the ulisten transcript by the synthesis's first
red team (https://ulisten.ai/channels/david-senra/building-muse-working-with-mark-zuckerberg-the-future-of-ai_S6l3aRsecuE/transcript,
accessed 2026-11-11), but the worker did not read the primary Senra
transcript, so the account stays Paraphrase / near-verbatim here. It
is the clearest applied example of metric-locked release in Wang's
orbit — and the shape the kit's gate imitates: per-row thresholds,
launch blocked while any row is red.

## 4. Mundane tooling validates the architecture — no re-architecture

Wang's own words (YC, Tier 1b; same transcript URL, accessed
2026-11-11):

> "Mechanically figuring out what the metric is. And then, yeah, it
> just comes down to skills, markdown files, cron jobs."
> Garry: "Slash goal." / Wang: "Yeah, slash goal. I think it's always
> funny how mundane everything is once you really dig into it."

The kit's architecture — skills + markdown + scheduled/triggered runs
— is already the shape Wang describes. That is validation of the
architecture as built, not a reason to change it: **no re-architecture
is needed on tooling grounds.** If a builder is tempted to add heavier
orchestration (a dedicated orchestrator service, a queue, a dashboard)
to "look serious", the mundane-tooling line is the counter-argument —
keep the mechanics boring and put the rigour in the metric/gate
instead.

**Attribution boundary — read this before citing the shape.** The
spoken words "slash goal" are transcript-verbatim; "/goal" as a
slash-command name is an interpretation, not a spoken token. None of
"GOAL.md", "skills/ directory", or "agent /goal" as a cron command
appears in the transcript — those are the reel narrator's elaboration,
not Wang's words (synthesis §1.2(c)). The kit has no `GOAL.md` file;
its equivalents — the `design/PLAN.md` purpose lock, the run-log lock
entry, the `skills/` tree, and run-log-driven scheduled runs — are the
kit's OWN implementation of the "slash goal" idea. The file names and
the commands are ours, not his. Any kit doc that mentions the shape
must say so.

## 5. Diffusion as the kit's thesis frame

The kit is a diffusion tool: it takes frontier-model capability that
already exists and gets it into a real workflow (frontend building)
that has not absorbed it. The frame, quoted verbatim (Tier 1b):

> "I really think we're at this amazing moment in the world where the
> bottleneck is not the progress of the AI models. The bottleneck is
> diffusing that through the rest of the world and helping the world
> adapt to this amazing technology that already exists. If the models
> didn't improve at all from today, there would still be decades and
> decades of total upheaval and change in the economy…"
— YC Startup School 2026, transcript-derived (Tier 1b): same
transcript URL (accessed 2026-11-11).

Caveat, stated with the quote every time it is reused as the frame:
this is a thesis about the economy, not a claim about the kit's own
efficacy. The kit does not prove diffusion works; it is built on the
bet that it does.

## 6. The durable advantage, correctly stated

A short note for kit users building products with the kit — not a
gate, not a slogan. The durable advantage is not the eval alone and
not the base model. In Wang's telling (Lightcone, Tier 1b, same
GitHub mirror as §1, accessed 2026-11-11):

> "Yeah, it's like these Lego blocks, right? If you have the data and
> you have the environments and then you have a base model, you can
> stack those on top of each other, get a fine-tuned model. And
> obviously the evals are important."

> "The alpha in the modern world will be determined by the degree to
> which you're able to encapsulate your business problems into
> datasets or environments that are conducive towards building
> differentiated models or differentiated AI capabilities."

Stated plainly for kit users: **your data + environments + the
fine-tuned model built on them is the differentiated part; evals tell
you whether it is working.** Evals are the precondition — the eval is
not itself the whole advantage in his telling. The sentence
attributing the moat to evals is **Jared Friedman's** (the Lightcone
host), not Wang's — never quote it as Wang's, and never use it as a
heading, slogan, or gate name. This file uses the word only here, where
the speaker split has to be explicit.

## 7. Systems thinking — a one-line principle, not a formal method

> "But I think systems thinking is never going to go out of style."
— YC Startup School 2026, transcript-derived (Tier 1b): same
transcript URL (accessed 2026-11-11).

That is the whole principle as far as this kit carries it: whole-system
design, not model-only thinking — the unit of design is the loop
(metric + data + tools + scheduling + evaluation), not the model or
the prompt. Wang gives no definition of "systems thinking" as a formal
method (no stocks/flows, no leverage points); do not import a textbook
definition and attribute it to him.

## 8. Vision as a light-touch brief prompt

Vision is the scarce input, in Wang's forecast (YC, Tier 1b; same
transcript URL, accessed 2026-11-11):

> "All of a sudden, the scarce resource isn't going to be intelligence
> or agency. I really think it's going to be vision and ambition."

The kit's brief/template carries one prompt line drawn from his
verified advice — as a prompt to the user writing the brief, not as a
gate, never as a requirement:

> "You need to develop conviction in a set of beliefs that nobody
> else agrees with."
— YC, transcript-derived (Tier 1b): same transcript URL (accessed
2026-11-11).

In `templates/design/PLAN.md` (§ Decisions) it appears as an optional
one-line invitation: what belief about how this page's world should
look in five to ten years do you hold that nobody else agrees with?
An unanswered prompt changes nothing in the loop; a good answer sharpens
the taste lock. That is the whole of it — light touch by design.

## 9. Do NOT carry into the kit

- Any price-ratio figure for Muse Spark vs Claude Opus presented as a
  Wang/Meta fact. The ratio was first asserted by Garry Tan, repeated
  hedged by Wang, flow-specific, and inconsistent with published
  per-token pricing as a clean ratio (synthesis §1.2(b)). The kit has
  no verified cost claim from Wang to cite.
- The swarm claim as a kit efficacy claim (§2 — conditional form only,
  anecdote flag attached).
- Any slogan attributing the durable advantage to evals alone, as
  Wang's words or as a kit slogan (§6 — the sentence is Friedman's).
- `GOAL.md` (or the kit's file layout generally) as "Wang's method"
  (§4 — the kit's implementation, not his spec).
- The wrong-metric principle, presented as Wang's words (§2 — the
  kit's own labelled principle only).
- The lock-the-metric-first imperative, presented as a Wang sentence
  (§2 — Paraphrase only).
- The coding-agents wave-size forecast presented as a measured
  productivity/impact figure (synthesis §1.5 — it is a market-wave-size
  forecast, not measured impact).
- The $100B check anecdote as Wang's words (it is Zuckerberg's
  line, synthesis §2.8); the reported social-media quip about a rival
  model (Tier 2, no direct read — it does not belong in the kit); the
  Muse-app build-time story as a Wang-verified fact (secondary-article
  claims only — do not conflate it with Muse Spark's nine-month
  rebuild, synthesis §7.1).
- Anything that needs the kit to claim Wang endorses it (§2).

## Sources

- Synthesis (authority for tiers, verdicts, and the §7 gaps list):
  `research_notes/alexander-wang-statements-20261111/REPORT.md`
  (2026-11-11). Worker reports + red-team verdicts:
  `research_notes/alexander-wang-statements-20261111/workers/`.
- YC Startup School 2026 video (primary event):
  https://www.youtube.com/watch?v=sJ4VJWycX9M (published
  2026-07-29; accessed 2026-11-11). Transcript (YC-endorsed link,
  third-party host — Tier 1b source for all YC quotes above):
  https://www.ycrootaccess.com/p/alexandr-wang-building-a-frontier
  (accessed 2026-11-11). No worker watched/listened to the video
  audio.
- Lightcone, 18 Jun 2025 (Tier 1b; read fraction ~23% — lines 0–150
  of 654): GitHub mirror of the YC-page transcript,
  https://github.com/vishalrohra/founder-wiki/blob/HEAD/raw/videos/MV-alexandr-wang-building-scale-ai-transforming-work-with-agents-competing-with-china.md
  (accessed 2026-11-11). Primary video:
  https://www.youtube.com/watch?v=5noIKN8t69U (accessed 2026-11-11).
- Founders/Senra evals-discipline account (§3 case study,
  Paraphrase / near-verbatim via secondary):
  https://www.allthingsmuse.com/articles/alexandr-wang-david-senra-muse-build-story/
  and https://www.the-ai-corner.com/p/meta-muse-alexandr-wang-interview
  (both accessed 2026-11-11); ulisten transcript:
  https://ulisten.ai/channels/david-senra/building-muse-working-with-mark-zuckerberg-the-future-of-ai_S6l3aRsecuE/transcript
  (accessed 2026-11-11).
