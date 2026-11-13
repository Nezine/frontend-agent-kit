# Evidence & Growth Brief — Role D

> **Owner:** Role D — QC + red team + evidence/growth (FLEET-MODE.md §1).
> D owns every artefact in this brief. D never builds features, never merges,
> and never edits code it graded; a fixer (B or C) applies accepted fixes.
> **Scope:** this brief designs the evidence and first-users machinery for ANY
> idea. It validates no specific idea candidate; idea validation is a separate
> workstream. All idea-specific content (user, problem, outcome) is filled in
> from `CONTRACT.md` at run start (T+0:00–0:20).
> **Hygiene:** codenames and roles only; no real names, no event name, no
> venue, no dates, no emails, no school or team details in this file.

## 0. How to read this brief — claims, sources, judgement

- **[SOURCE]** = a factual claim taken from a named source, with URL +
  access date where the source is external, or file path + section where the
  source is the runbook / goal record read for this brief.
- **[DESIGN JUDGEMENT]** = a design choice made by this worker. It is not a
  verified fact. It is labelled as judgement wherever it appears, so a
  reviewer can challenge it without voiding the sourced facts.
- **Council rules in force:** (1) one fabricated claim voids the piece;
  (2) every factual claim is independently verifiable — URL + access date,
  QC opens every link; (3) a dedicated red team finds errors in others'
  work. [SOURCE: FLEET-MODE.md §13, read 2026-11-13.]
- **Free legal sources only.** No source in this brief was bought. Any
  source that could not be read is marked **CHƯA ĐỌC** — none is relied on
  below except where explicitly marked.

### 0.1 Scoring facts this brief is built on

- **40 — live AI demo on a real phone.** Full marks: close the app fully,
  reopen it on a real phone, the main AI flow runs live. Zero: the app does
  not reopen on a real phone, the AI does not run live, or the demo is a
  browser, emulator, photo, or video. [SOURCE: FLEET-MODE.md §0, read
  2026-11-13.]
- **35 — a real user problem, with evidence.** Full marks: the user and
  their difficulty are stated clearly, with evidence, and the AI helps
  directly. Zero: the user, the problem, or the product's value is unclear.
  [SOURCE: FLEET-MODE.md §0, read 2026-11-13.]
- **25 — market expansion.** Full marks: a clear path to the first users and
  to a global audience; real users are an advantage. Zero: no concrete
  user-acquisition path, or only the claim that "everyone needs it."
  [SOURCE: FLEET-MODE.md §0, read 2026-11-13.]
- **Tiebreak order:** demo first, then problem, then expansion.
  [SOURCE: FLEET-MODE.md §0, read 2026-11-13.]
- **Scores are judged on real evidence, not on slides or presentation
  confidence.** [SOURCE: FLEET-MODE.md §0, read 2026-11-13.]
- **The AI must be essential to the user outcome** — not a chatbot bolted
  on. A product that works the same with the AI removed scores nothing on
  the demo criterion. [SOURCE: FLEET-MODE.md §0, read 2026-11-13.]
- **Preparation before build day is allowed, with disclosure:** the idea,
  research, and even part of the product may be prepared beforehand; at
  presentation time the team states what existed before and what was built
  during the run. [SOURCE: FLEET-MODE.md §0, read 2026-11-13.]
- **What the backend must do for the evidence and first-users criteria:**
  persist just enough to prove real use (a count of completed demo runs,
  saved outputs shareable by link) and to let a first user return to their
  result. That is a share-link + a counter, not accounts.
  [SOURCE: FLEET-MODE.md §4, read 2026-11-13.]

### 0.2 Workflow facts this brief relies on

- **Role D owns** the problem-evidence artefact, first-users / share
  artefacts, the demo script, rehearsal, and the backup recording.
  [SOURCE: FLEET-MODE.md §1, read 2026-11-13.]
- **D assembles the problem-evidence artefact and the share/first-users
  mechanism in parallel** (read-only w.r.t. code) during Slice 0
  (T+0:20–1:20), and finalises the evidence / first-users / share artefacts
  during freeze (T+3:20–4:00). [SOURCE: FLEET-MODE.md §6, read
  2026-11-13.]
- **The demo script is written before any feature code.** Anything that
  never reaches the screen scores nothing.
  [SOURCE: FLEET-MODE.md §3 and §4, read 2026-11-13; see also AngelHack,
  *How To Win A Hackathon* — "Write the demo script before the build
  starts, then build only what the script requires… Anything that never
  reaches the screen scores nothing" — https://angelhack.com/blog/5-steps-from-idea-to-hackathon-winning-app/
  — accessed 2026-11-12, as cited in
  `research_notes/multi-agent-workflow-5h-hackathon-20261112-0550/report.md`
  §4a.]
- **Cut order:** the evidence/growth extras (extra testimonials, analytics
  dashboard) are cut before the core — keep only the one evidence artefact
  and the share link. Never cut: the live AI flow on a real phone, the demo
  script, the backup recording, the deterministic gate, or the final human
  verification. [SOURCE: FLEET-MODE.md §6, read 2026-11-13.]
- **The only grade that counts for the demo flow is a real run on a real
  phone against the deployed URL** — never the builder's log, never a
  screenshot alone, never the judge's reading of the diff.
  [SOURCE: FLEET-MODE.md §5, read 2026-11-13.]
- **Vertical slices, not layers:** Slice 0 is the walking skeleton
  (deployed page + one real endpoint + one real AI call, or a stub through
  the real endpoint); Slice 1 is the real AI flow, live on a real phone by
  the halfway point; Slice 2+ only if Slice 1 is green on a phone.
  [SOURCE: FLEET-MODE.md §4, read 2026-11-13.]

---

## 1. The evidence artefact (criterion 35)

### 1.1 Exact format

**One artefact, two surfaces, one source of truth.**

| Surface | Location | Content |
|---|---|---|
| **Canonical file** | Product repo, `docs/EVIDENCE.md` (D-owned; file ownership per FLEET-MODE.md §1: `docs/` belongs to D) | The full artefact, §1.2 below, in full. This is what the pitch points at and what D grades against. |
| **In-app screen** | One screen in the app, reachable from the home screen in one tap, titled "Why this exists" (or the idea's equivalent) | The same problem sentence + the same 2–3 strongest evidence items, condensed. No evidence item appears in-app that is not in `docs/EVIDENCE.md` first. |

**[DESIGN JUDGEMENT]** One artefact, not a deck: a single file the judges
can open in 30 seconds beats a slide deck they cannot verify. The in-app
screen exists because FLEET-MODE.md §3 / §4 rule is that anything that never
reaches the screen scores nothing — the evidence must be visible on the
phone, not only in the repo.

### 1.2 Exact contents of `docs/EVIDENCE.md`

```markdown
# Evidence — <one-sentence problem / user / outcome, copied verbatim from CONTRACT.md>

## 1. The user (one paragraph)
- Who: <archetype + context, e.g. role, situation, frequency — no real name>
- Difficulty: <the specific difficulty, in observable terms>

## 2. The problem, stated as a falsifiable claim
- <One sentence: this user, in this situation, fails / wastes / cannot do X>

## 3. Evidence items (table — every row verifiable)
| # | Claim | Evidence type | Source | Date | How to verify |
|---|-------|---------------|--------|------|---------------|
| E1 | … | <interview quote / observed behaviour / public data / live counter> | <file, link, or "live counter, §3"> | … | <exact step> |

## 4. How the AI helps directly
- <One paragraph: the AI action in the demo, mapped to the difficulty in §1 —
  what the user could not do before, what the AI does now, what the user sees>

## 5. What was pre-built vs built during the run
- Pre-built: <evidence collected before build day — disclosed>
- Built during the run: <live counter, first-users wall, in-app screen — disclosed>

## 6. What this evidence does NOT prove
- <Honest limits: sample size, who was NOT talked to, what is still untested>
```

**Minimum viable contents (the floor — below this, the artefact is not
done):** §1 (user + difficulty), §2 (one falsifiable sentence), at least
**two** evidence rows in §3 from **two different evidence types**, §4 (AI
mapping), §5 (disclosure). [DESIGN JUDGEMENT — floor size is judgement;
the scoring rule it serves is sourced in §0.1.]

### 1.3 Evidence types — what counts, in rank order

| Rank | Type | Why it counts | Example shape |
|---|---|---|---|
| 1 | **Observed behaviour** | The user was watched doing (or failing) the task; not self-report | "3 of 3 test users took >4 min / gave up at step X" with date + method |
| 2 | **Direct quote from a real user** | Named archetype, dated, verbatim or clearly paraphrased, with the question asked | Quote + who (archetype only) + when + what was asked |
| 3 | **Live counter / live log** (§3, §4a) | The demo itself generated it during the run; unfakeable by the builder | "N completed runs by T+3:20, see §3" |
| 4 | **First-user feedback** (§4b) | A stranger completed the flow and reported the outcome in their own words | Verbatim one-liner + timestamp + result link |
| 5 | **Public data** | A published source showing the problem exists at scale | Link + access date + the exact figure quoted |

**[DESIGN JUDGEMENT]** The ranking is judgement: observed behaviour outranks
opinion because the scoring rule rewards evidence over slides
(FLEET-MODE.md §0), and a live counter outranks a quote because the
builder cannot edit the counter's server-side record the way it can edit
its own log (cf. the report's grounding rule: the only grade that counts is
grounded in world state outside the transcript —
`research_notes/multi-agent-workflow-5h-hackathon-20261112-0550/report.md`
§2b, Park & Choi 2026, https://arxiv.org/pdf/2607.25152v2 — via workflow report §2b, not re-opened directly — accessed
2026-11-12).

### 1.4 Where it lives in the product / repo

- **Repo:** `docs/EVIDENCE.md` in the product repo (D-owned). Linked from
  the product `README.md` and from `CONTRACT.md`'s "Evidence artefact" line
  (CONTRACT.md template, FLEET-MODE.md appendix).
- **App:** one "Why this exists" screen, one tap from home. It shows the
  problem sentence + top 2–3 evidence items + the live counter (§3). It is
  part of Slice 2 at the earliest — it must NOT delay Slice 0 or Slice 1.
  [DESIGN JUDGEMENT on Slice-2 placement; the "must not delay Slice 1"
  constraint follows FLEET-MODE.md §4: Slice 2+ only if Slice 1 is green.]
- **Pitch:** the presenter reads the §2 sentence aloud, then shows the
  in-app screen on the phone, then states the live counter number. No
  separate evidence slide is needed; if slides exist, they quote
  `docs/EVIDENCE.md` verbatim and link to it.

### 1.5 How it gets built inside the 5-hour window

| When | Who | Action |
|---|---|---|
| **Before build day** (prep, disclosed) | D (preparation) | Collect the pre-built evidence: 2–3 short user conversations (or observed sessions) with the target archetype; record date, question asked, verbatim answer, and archetype — no real names, no personal data. Draft §1–§3 of `docs/EVIDENCE.md`. Preparation is allowed with disclosure (FLEET-MODE.md §0). |
| T+0:00–0:20 | A writes, D reviews | The problem sentence is locked in `CONTRACT.md`. D checks it matches the pre-built evidence; if it does not, D flags A immediately — the sentence changes or the evidence is re-scoped, before any code. |
| T+0:20–1:20 (Slice 0) | D, parallel, read-only w.r.t. code | D assembles `docs/EVIDENCE.md` (§1–§5) from the pre-built material and merges it via A. D does NOT wait for the app to exist. |
| T+1:20–2:20 (Slice 1) | D | D runs the first independent grade of the live phone run (FLEET-MODE.md §6) and checks the §4 AI-mapping claim against the real flow: does the live AI output actually address the difficulty in §1, or is it plausible-sounding output? If the mapping fails, D reports it as a blocker to A — this is a correctness check, not a polish note. |
| T+2:20–3:20 (Slice 2) | D | Recruit the 3 real users (§4b); collect their runs + one-line feedback; add as evidence rows. B/C build the in-app screen only if Slice 1 is green. |
| T+3:20–4:00 (freeze) | D leads | Finalise `docs/EVIDENCE.md`: freeze the live counter number with timestamp, add the first-users wall snapshot (§4c), write §6 (honest limits). Rehearse the evidence line of the pitch twice on the phone. |

### 1.6 DoD (Definition of Done) — evidence artefact

- [ ] `docs/EVIDENCE.md` exists on green `main`, merged by A, with §1–§6
      complete.
- [ ] ≥2 evidence rows from ≥2 different types (§1.3), each with source +
      date + a verification step a judge can actually follow.
- [ ] The problem sentence in `docs/EVIDENCE.md` is verbatim the sentence
      in `CONTRACT.md`.
- [ ] §4 names the exact AI action in the demo script and the exact
      difficulty it removes — a reader can check the mapping on the phone.
- [ ] §5 discloses pre-built vs day-built, honestly.
- [ ] §6 states at least one honest limit (sample size, who was not
      reached, what is untested).
- [ ] The in-app screen exists (if Slice 2 shipped) and matches
      `docs/EVIDENCE.md` — no item in-app that is not in the file.
- [ ] D (not B or C) verified every row by opening the source or replaying
      the run; the builder never graded its own evidence.

### 1.7 Traps — what looks like evidence but scores 0

| Trap | Why it scores 0 | Guard |
|---|---|---|
| **A slide claiming "everyone needs it"** | The expansion criterion gives zero for "only the claim that 'everyone needs it'" (FLEET-MODE.md §0). A problem claim without a named user is the same failure on criterion 35. | §2 must name one archetype + one observable difficulty. If the sentence works for "everyone", rewrite it. |
| **Team members as the only "users"** | The builders are not the user; their opinion is the builder grading its own work by another name. | ≥1 evidence row must come from someone outside the team (§4b) or from the live counter (§3). |
| **Quotes with no question, date, or archetype** | Unverifiable. Council rule 2: any unverifiable claim fails the submission (FLEET-MODE.md §13). | Every quote row carries: question asked, date, archetype. No exceptions. |
| **A big number with no denominator** | "100 people have this problem" without who was asked or how is a fabricated-looking claim. | Every number carries its denominator + method (§6 honest limits). |
| **Evidence written after the product, fitted to it** | The artefact rationalises the build instead of the build serving the problem; judges notice when §4 cannot be checked on the phone. | D locks §2 in CONTRACT.md at T+0:20, before feature code; §4 is checked against the live phone run at T+1:20–2:20. |
| **Stock photos / invented personas presented as users** | Fabricated evidence; one fabricated claim voids the piece (FLEET-MODE.md §13). | No persona is presented as a real person. Archetypes are labelled archetypes; real users are labelled with date + method, never with a borrowed photo. |
| **Evidence that lives only in slides** | "Scores are judged on real evidence, not on slides" (FLEET-MODE.md §0); and anything that never reaches the screen scores nothing (FLEET-MODE.md §4). | Canonical file in the repo + in-app screen; the pitch points at both, live. |

---

## 2. The first-users mechanism (criterion 25)

### 2.1 Mechanism — exact shape

**Share link + demo-run counter, no accounts.** [SOURCE: FLEET-MODE.md
§4: "That is a share-link + a counter, not accounts."]

1. **The link.** The deployed app has one public URL (the deploy target
   in `CONTRACT.md`). Every completed AI run produces a **result link**:
   `<public URL>/r/<result-id>` — opening it shows that run's input and
   its AI result, read-only, with a prominent "Try it yourself" button
   that starts a fresh run. No sign-up, no login, no install beyond
   opening the link (Expo Go / browser path per the mobile stack).
   [DESIGN JUDGEMENT on the `/r/<id>` shape; the no-accounts rule is
   sourced above.]
2. **The path stranger → first user.** A stranger opens a shared result
   link (or the home URL) → sees a real result from a real run, not a
   marketing screen → taps "Try it yourself" → completes the main AI flow
   once → gets their own result + their own share link → the counter
   increments (§3). That completed run makes them a first user. Nothing
   else is required of them.
3. **The global path (for the 25-point "global audience" half).**
   [DESIGN JUDGEMENT] The app must work for a stranger with no context:
   English UI by default (or the idea's market language — decided in
   `CONTRACT.md`, not improvised), no local-only dependency (no
   location, no local account, no language only the team speaks), and the
   share link must work from any phone browser. The pitch states the
   global path in one sentence: who the next 100 users are, where they
   already gather, and what link reaches them. A global claim without a
   named channel is the "everyone needs it" trap (§1.7).

### 2.2 Where it lives

- **Backend (C builds, A owns the contract):** one persistence
  collection/table for results + one counter record (§3). This is the
  "at most persistence for the demo's own artefacts (save/share)" allowed
  by FLEET-MODE.md §4. No auth system, no profiles, no admin panel.
- **Frontend (B builds):** the result screen (share button + copy link),
  the `/r/<id>` read-only view, the "Try it yourself" entry, and the
  counter display (§3.3).
- **Docs (D owns):** `docs/EVIDENCE.md` §3 (first-user rows) + the pitch's
  one-sentence acquisition path. D owns the mechanism's *proof*; C owns
  its *implementation*; B owns its *screens*. D verifies the mechanism by
  using it as a stranger (fresh phone/browser, no login), never by reading
  C's code.

### 2.3 How it gets built inside the 5-hour window

| When | Who | Action |
|---|---|---|
| T+0:00–0:20 | A | `CONTRACT.md` names the deploy URL, the result-link shape, and the counter record. This is part of the API contract, frozen at T+0:20. |
| T+0:20–1:20 (Slice 0) | C | Endpoint returns a canned result **with a real result-id and a real
  shareable link** through the real endpoint — the link shape exists from
  hour 1 even though the AI output is canned. |
| T+1:20–2:20 (Slice 1) | C + B | Real AI output flows through the same link shape. D verifies as a stranger: opens the link on the phone, completes a run, confirms the counter increments (§3). |
| T+2:20–3:20 (Slice 2) | D | This slice IS the first-users slice if Slice 1 is green: recruit 3 real users (§4b), confirm their runs appear on the wall (§4c). If Slice 1 is not green, this slice is cut and the share link ships in its Slice-1 form. |
| T+3:20–4:00 (freeze) | D | Freeze the counter number + timestamp for the pitch. Record the acquisition path in `docs/EVIDENCE.md`. No new acquisition channels are added after freeze. |

### 2.4 DoD — first-users mechanism

- [ ] A stranger with no account, no login, and no prior context can open
      the public URL on a phone, complete the main AI flow, and receive a
      shareable result link — verified by D on the real phone, not by a
      builder's log.
- [ ] Opening a result link shows the original result read-only + a
      "Try it yourself" entry.
- [ ] The counter increments only on a completed run (§3.1) and is visible
      in-app (§3.3).
- [ ] The pitch states the global path in one sentence with a named
      channel for the next users (not "everyone").
- [ ] No accounts, no auth, no profiles exist anywhere in the product.

### 2.5 Traps — first users

| Trap | Why it scores 0 | Guard |
|---|---|---|
| **"Everyone needs it"** | Explicit zero on criterion 25 (FLEET-MODE.md §0). | Name the first 3 users (§4b) and the next-100 channel, concretely. |
| **A sign-up wall before the AI flow** | A stranger cannot become a first user if the flow demands an account; also violates the thin-backend rule (FLEET-MODE.md §4: no auth system). | D's stranger test (§2.4) fails the slice if any login appears before the result. |
| **A share link that only works on the builders' machine / localhost** | The demo that only works on the builder's machine fails on the phone (FLEET-MODE.md §12). | Link verified on the real phone over the public URL after every merge. |
| **Counting page views as users** | Page views are not users; judges dismiss them as vanity. | Only completed runs count (§3.1). |
| **A waitlist / "sign up for launch"** | A waitlist is a promise of future users, not first users. | The mechanism must produce a completed run + a shareable result today, not a signup. |

---

## 3. The demo-run counter — persisted proof of real use

### 3.1 What is counted

- **Counted:** one **completed AI run** — the request reached the real
  endpoint, the model returned a result, and the result was displayed on
  the phone (or the result link was opened and rendered). The increment
  happens **server-side, on successful AI response**, never client-side on
  button tap. [DESIGN JUDGEMENT — server-side increment is judgement; it
  serves the sourced rule that the only grade that counts is grounded in
  world state outside the transcript (report §2b, cited in §1.3).]
- **NOT counted:** page views, app opens, button taps, stub/canned
  responses from Slice 0, failed or timed-out runs, repeated taps of the
  same run, D's own verification runs after freeze (labelled separately if
  counted at all — see §3.4).
- **Deduplication [DESIGN JUDGEMENT]:** the counter stores two numbers —
  **total completed runs** and **distinct result-ids** (one per saved
  result). The pitch quotes distinct result-ids as "people who completed
  a run" only if each result-id plausibly maps to one run; the honest
  label is "N completed runs, M saved results". D never claims distinct
  *people* from a counter that cannot identify people — that would be a
  fabricated claim.

### 3.2 Where it is stored

- **Store:** one collection/table in the chosen BaaS (primary: the
  backend pick named in `CONTRACT.md`; the fleet's backend orientation is
  Convex primary, Supabase fallback — see the goal record, read
  2026-11-13). One table for results, one record for the counter — or a
  count query over the results table if the BaaS supports it cheaply.
  [DESIGN JUDGEMENT on the one-table shape; the BaaS orientation is
  sourced from the goal record.]
- **Record shape [DESIGN JUDGEMENT]:**

  ```json
  {
    "result_id": "string, unique",
    "created_at": "UTC timestamp",
    "input_summary": "string, non-sensitive summary of the input type (never raw personal input)",
    "outcome_summary": "string, what the AI produced, truncated",
    "latency_ms": "number",
    "source": "demo | share-link | first-user | pitch"
  }
  ```

- **What is NEVER stored:** names, emails, phone numbers, device IDs,
  IP addresses, raw personal input, or anything that identifies a person.
  The counter proves use; it does not surveil users. [DESIGN JUDGEMENT —
  a privacy choice; it also keeps the artefact inside the repo-hygiene
  rule (no personal info).]
- **Who writes it:** the backend only (C's endpoint), on successful AI
  response. The frontend never increments the counter. A owns the schema;
  C implements it; D reads it to verify.

### 3.3 What the judges see

- **In-app (live):** the home screen and the result screen show the live
  number, e.g. "N completed runs so far" with the timestamp of the latest
  run. The number is read from the backend on screen open, not hardcoded.
- **In the repo (frozen):** `docs/EVIDENCE.md` §3 records the frozen
  number + the exact freeze timestamp (T+3:20–4:00), so the pitch number
  and the repo number agree.
- **In the pitch (live):** the presenter shows the in-app number on the
  phone, then runs the demo live — the judges watch the number increment
  by one when the live run completes. That increment, on stage, is the
  strongest form of this evidence: the demo proves the counter, and the
  counter proves the demo. [DESIGN JUDGEMENT — the on-stage increment is
  a pitch technique, not a sourced fact.]
- **Backup:** D records a backup video of the live flow (FLEET-MODE.md
  §6) that includes the counter before and after a run, so the proof
  survives a flaky stage network.

### 3.4 DoD — demo-run counter

- [ ] The counter increments server-side only on a completed real-AI run;
      D verified this by completing a run on the real phone and watching
      the number move, and by tapping without completing and watching it
      NOT move.
- [ ] Stub/canned runs from Slice 0 are excluded (flagged `source: stub`
      or not written at all — decided in `CONTRACT.md`, applied by C).
- [ ] The stored record contains no personal data (§3.2).
- [ ] The in-app number, the `docs/EVIDENCE.md` frozen number, and the
      pitch number agree at freeze time; any run after freeze is labelled
      as post-freeze.
- [ ] The counter survives kill-and-reopen (it is server-side, not
      in-memory).

### 3.5 Traps — counter

| Trap | Why it scores 0 | Guard |
|---|---|---|
| **Client-side increment on tap** | The builder can inflate it; it proves a tap, not a run. | Server-side only; D's negative test (tap, don't complete → no increment). |
| **Counting Slice-0 canned runs** | Canned output is not the AI helping; counting it is inflated evidence. | Canned runs excluded by design (§3.4). |
| **A hardcoded number in the UI** | Fabricated evidence; one fabricated claim voids the piece (FLEET-MODE.md §13). | Number is read from the backend on open; D checks it changes after a real run. |
| **Claiming "N users" from "N runs"** | The counter cannot identify people; the claim is unverifiable. | Pitch quotes runs + saved results with denominators (§3.1). |
| **Counter only in a slide / dashboard** | Judges score real evidence, not slides (FLEET-MODE.md §0); a dashboard the judges never see is cut-list material (FLEET-MODE.md §6). | Counter is in-app, live, on the phone. No separate analytics dashboard is built. |

---

## 4. Creative — evidence the demo generates live

### 4a. Live evidence: the demo run writes its own evidence

- **Mechanism [DESIGN JUDGEMENT]:** every completed run appends one
  anonymised row (§3.2 record shape) to a **public live log** inside the
  app — a "Live log" view listing recent runs as "Run #N — <time UTC> —
  <input type> → <outcome summary> — <latency>". The log is the
  first-users wall in its raw form (§4c). The pitch opens the log, runs
  the demo live, and the new row appears at the top while the judges
  watch. The demo's evidence is therefore generated by the demo itself,
  in front of the judges — it cannot have been prepared in advance.
- **Owner:** D owns the log's *contents and proof*; C owns the
  *write path* (same endpoint write as §3.2); B owns the *screen*.
- **DoD:** the log shows only completed real-AI runs (no stubs); rows
  contain no personal data; a live run appends a visible row within
  seconds; D verified it on the real phone twice.
- **Trap:** a log that lists runs the judges cannot distinguish from
  seeded rows. Guard: seeded/demo rows (if any exist from rehearsal) are
  labelled `source: rehearsal` and excluded from the pitch number; the
  pitch uses only runs with `source: demo | share-link | first-user |
  pitch` after freeze. [DESIGN JUDGEMENT.]

### 4b. Recruiting 3 real users DURING the build window

- **Mechanism [DESIGN JUDGEMENT]:** before build day, D prepares a list
  of **3 target users** matching the `CONTRACT.md` archetype who have
  agreed (in advance) to try the app once during the build window if
  asked — consent and contact channel recorded privately by D, never in
  the repo. At T+2:20, once Slice 1 is green on the real phone, D sends
  each of them the public share link with one instruction: "Open this,
  complete one run, reply with one line: what happened and whether it
  helped." D records: time sent, time of each completed run (from the
  counter/log), and each reply verbatim in `docs/EVIDENCE.md` §3 as
  first-user rows. Three completed runs + three one-liners is the target;
  one is the floor — below one, §4b is cut and the artefact relies on
  §1.3 ranks 1–3 only.
- **Owner:** D only. B and C never recruit (they are building); A never
  recruits (A integrates). D's recruitment does not touch code.
- **DoD:** ≥1 stranger (outside the team) completed a real run via the
  share link during the window, with a timestamped counter row + a
  verbatim reply in `docs/EVIDENCE.md`. Target is 3.
- **Traps:**
  - *Recruiting before Slice 1 is green:* the users hit a broken build
    and their failure is the evidence. Guard: D sends the link only after
    the T+2:20 "live AI flow works twice on a real phone" exit criterion
    (FLEET-MODE.md §6) is met.
  - *Leading the witness:* asking "did you love it?" manufactures a
    quote. Guard: the prompt is neutral ("what happened, did it help?"),
    recorded verbatim in `docs/EVIDENCE.md`.
  - *Quoting without consent:* a reply quoted in the repo/pitch without
    the user's agreement. Guard: the pre-build agreement covers quoting
    one line anonymously (archetype only, no name); if a user objects,
    their row reports the run only, not the words.
  - *Counting the recruiters' own runs as first users:* team members are
    not first users (§1.7). Guard: the 3 are outside the team, and their
    runs carry `source: first-user`.

### 4c. The "first-users wall" inside the app

- **Mechanism [DESIGN JUDGEMENT]:** one in-app screen, "First users",
  showing the live counter (§3.3) at the top and the live log (§4a) below
  it — each row an anonymised completed run: "Run #N — <time> —
  <outcome>". The wall is the expansion criterion made visible: a
  stranger opening the app sees that real people have already used it,
  and sees their own run join the wall seconds after completing it. That
  is the conversion loop: proof → try → proof.
- **Owner:** B builds the screen (frontend files); C supplies the read
  endpoint (same results table, read-only); D owns the wall's honesty
  (no seeded rows presented as real users, §4a trap).
- **DoD:** the wall renders on the real phone; a completed run appears on
  it within seconds; it shows the same number as the counter (§3.3);
  no row contains personal data; no seeded row is presented as a real
  user.
- **Placement in the window:** Slice 2, only if Slice 1 is green
  (FLEET-MODE.md §4). It is first in the cut order for evidence/growth
  extras (FLEET-MODE.md §6, cut item 4) — if time runs short, the wall
  is cut and only the counter + share link survive.
- **Trap:** a wall of fake names/avatars. Guard: no names, no avatars, no
  photos — run numbers and outcomes only. A wall with invented people is
  fabricated evidence and voids the piece (FLEET-MODE.md §13).

---

## 5. Consolidated owner / DoD / trap map

| Artefact | Owner (builds) | Verifier | DoD in one line | Biggest trap |
|---|---|---|---|---|
| `docs/EVIDENCE.md` (§1) | D | D (independent of B/C); A merges | §1.6 checklist complete on green `main` | Slides / "everyone needs it" / team-as-users |
| Share link + no-accounts flow (§2) | C (endpoint) + B (screens) | D as a stranger on the real phone | §2.4 checklist; stranger completes a run with no login | Sign-up wall; localhost-only link |
| Demo-run counter (§3) | C (server-side write) | D (positive + negative test on phone) | §3.4 checklist; server-side only, no personal data | Client-side increment; hardcoded number; "N users" from "N runs" |
| Live evidence / live log (§4a) | C (write) + B (screen) | D on the real phone, twice | Live run appends a visible row within seconds | Seeded rows passed off as real |
| 3 real users in-window (§4b) | D (recruit + record) | D (counter row + verbatim reply) | ≥1 stranger run + reply in `docs/EVIDENCE.md`; target 3 | Recruiting before Slice 1 green; leading questions |
| First-users wall (§4c) | B (screen) + C (read) | D | Wall matches counter; run appears within seconds; no personal data | Fake names/avatars; invented people |

**Red-team checks (D leads, 15 min each, FLEET-MODE.md §9):**
- Pass #1 (~T+3:00): try to break the evidence — open a share link as a
  stranger, complete a run with empty/adversarial input, check the counter
  still counts only real completions and the wall shows no garbage.
- Pass #2 (~T+3:45): will this survive a live pitch? — kill-and-reopen,
  run the demo, watch the counter + wall update live, confirm the frozen
  number in `docs/EVIDENCE.md` matches the phone.

## 6. Sources

- FLEET-MODE.md §§0–1, 3–6, 9, 12–13 and appendix (CONTRACT.md template) —
  read 2026-11-13 (workspace copy of the runbook).
- Goal record — `workspace/goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md`
  — read 2026-11-13 (scoring rules; backend orientation Convex primary /
  Supabase fallback; 5-hour clock; no human-fix window after submission).
- `research_notes/multi-agent-workflow-5h-hackathon-20261112-0550/report.md`
  §§1–6 — read 2026-11-13, incl. its cited sources:
  - AngelHack, *How To Win A Hackathon*,
    https://angelhack.com/blog/5-steps-from-idea-to-hackathon-winning-app/ —
    accessed 2026-11-12.
  - Park & Choi (2026), *When Do Agent Loops Mistake Stagnation for
    Progress?*, https://arxiv.org/pdf/2607.25152v2 — accessed 2026-11-12.
  - Anthropic, *Building Effective Agents*,
    https://www.anthropic.com/engineering/building-effective-agents —
    accessed 2026-11-12.
  - Anthropic, *How We Built Our Multi-Agent Research System*,
    https://www.anthropic.com/engineering/multi-agent-research-system —
    accessed 2026-11-12.
- No other external factual claims are made in this brief. Everything else
  is labelled **[DESIGN JUDGEMENT]**.
