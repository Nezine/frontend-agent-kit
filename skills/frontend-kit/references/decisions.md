# Council decisions D1–D8 (workflow-optimization, reconciled 2026-11-10)

Source: `research/workflow-optimization/SYNTHESIS.md` §8/§8a (workspace research
note, not shipped in this repo). A proposal is INTEGRATE only on unanimous or
2–1 council agreement with the dissent recorded. These eight decisions are the
reconciled cross-proposal rulings; the P1–P24 / M1–M5 verdict table lives in
that synthesis §8. Where a decision below disagrees with the phase-1 synthesis,
the decision governs.

## D1 — Escalate after the FIRST non-improving round

Unanimous; B's form: one re-grade confirms — the second grade, not a second
round, is the confirmation. Rule (d) and the mid-loop human-escalation sentence
deleted. Flat-line needs a gate-progress exception as noise guard (A). P6(a) is
a direction re-pick until P10 revives (B). Operative form: `references/stop-rules.md`,
`references/grader-rubric.md` (P6).

## D2 — Weaken the variant contract

A+C majority; B dissents, conditions attached (see P10 in the synthesis §8).
New wording: "same content, same copy, same section inventory — structure may
differ; tokens stay locked"; picker `check` becomes inventory + copy; auto-pick
ties break by the plan's preferred structure. Operative form:
`skills/frontend-kit/scripts/variant-picker.mjs`, `references/variant-briefs.md`.

## D3 — Runbook `coord/` scheme wins

Unanimous; no `board/`, no `STATE.md`. P22 contributes only the status column +
append-only rule. Operative form: `coord/BOARD.md`, `BUFFET-MODE.md`.

## D4 — Never rebase someone else's branch

Unanimous; "rebase the rest" deleted; `buffet/<name>` kept; trial merges
overlap-gated; neutral merger = fresh-context agent, not the coordinator (C).
Operative form: `BUFFET-MODE.md` §5, `scripts/trial-merge.mjs`.

## D5 — No second liveness cadence

Unanimous; heartbeat folds into the existing 15-min pull / 30-min merge — one
last-seen line in the agent's own `coord/<name>.md`, no extra commits.

## D6 — P16 struck as written; revival PARKED

Unanimous on the kill of P16 (reverse export) as written. Reworked version
PARKED pending ALL conditions: Education status confirmed, explicit type map,
full-copy themes for export, fonts first-name-only labelled lossy, Starter
single-file import test passes. C's acceptance of the reworked version is the
minority; the stricter condition (test first) governs.

## D7 — Split P3 (annotation INTEGRATE; self-check reworked only)

Unanimous. **Annotation INTEGRATE** — the human's annotated screenshot is a
first-class fix input at the human gate (see `references/human-gate-pack.md`).
**Self-check INTEGRATE WITH CHANGES in the reworked form only: 1 pass,
post-gate, visual-P0-only, report-only.** B killed the self-check *as written*
(unbounded, judgement-based) — the reworked mechanical form satisfies B's
objection. Operative form: `SKILL.md` step 3b, `references/workflow.md` §6,
`references/grader-rubric.md`, `references/human-gate-pack.md`. The self-check
is NEVER a grade, NEVER changes a score, NEVER triggers the stop rule, NEVER
substitutes for the independent grade, and is NEVER a judge input (D8).

## D8 — Reconciled judge-input whitelist

Unanimous in substance. **Allowed:** screenshots + locked reference shots +
rubric/scope + lock text + tool measurements + pairwise A/B inputs.
**Forbidden:** model/builder identity, earlier scores, run log, gate findings.
Gate handled by orchestrator pre-filter: the gate result itself is NOT a judge
input; B's single `gate: green` bit is the only exception, enforced by the
orchestrator. The cross-check reaches the judge the same way, as the single bit
`cross-check: clear` (step 3a). The 80% Layout/Space agreement threshold was
recorded with an A/B disagreement (n≥30 vs n≥32); the rubric resolves it to
**n≥32, report-only until n≥32** (`references/grader-rubric.md`); systematic
overshoot ≥1.0pt on any axis triggers an immediate rubric-anchor rewrite (B).
Buffet mode never parks on low agreement (A). Operative form:
`references/grader-rubric.md`, `skills/frontend-judge/SKILL.md`.

## The "agreement log" (P8)

P8's "agreement log" is not a separate file. It is the per-round record of
(gate verdict, judge scores, human verdict) kept in the run log
(`skills/frontend-kit/scripts/run-log.mjs`, `record` command) plus the
human-gate packet (`references/human-gate-pack.md`); agreement is computed
from those records in `research/judge-calibration.md`. "P8's gate-growth rule"
in `references/anti-cliche.md` is a different thing — the rule that the gate
grows only from observed failures — and is not labelled P8 there.

## D9 — GAP-9: hash-based carve-out for byte-identical vendored taste runtime assets

Council (3–0, amendments recorded above; scope split resolved for C3's
narrowing — see reconciliation). **Adopt (b3):** `gate.sh` check 1.2 exempts a
file only if its project-relative path and sha256 both match
`scripts/gate/vendored-allowlist.txt` — a committed manifest generated at
release/re-pin from `vendor/SHA256SUMS` restricted to the taste assets subtree
and narrowed to the runtime sink files only (expected 27 files at pin v2.5.1;
lab/demo/catalog files are never listed and fail the gate mechanically if
copied). Paths are rebased to `assets/<relpath>`; a vendored file copied to any
other project path does not match (fail closed on relocation). Rewrite (a),
path-based (b1), and marker-based (b2) exemptions are rejected. **Settlement
of the §2.1 contradiction:** taste governs runtime vendoring (motion layer
"not optional"); frontend-kit Step 2's "one HTML file" governs the deliverable
page shape; 2.1a's GSAP route is scroll-motion only. **Residual risk:** the 3
runtime class-E sites and the class-C feeds are
grandfathered as exact bytes; ownership transfers explicitly to the security
expert's per-occurrence taint check (checklist 1.2, pre-land and pre-ship,
per-build), and the gate's exemption note must print the residual list every
time it exempts a file, naming pin v2.5.1. Notify/search callers passing
user, model, or API data into `opts.items` / `opts.queries` are a BLOCK.
**Regeneration:** `vendor-update.sh` taste branch regenerates the manifest next
to `refresh_manifest` (fail loudly on failure); `verify.sh` checks manifest vs
tree; re-classification of changed sites is required at each re-pin before the
new manifest ships (blocking); a missing or stale manifest means no exemption
(fail closed, with a printed note when missing). **Inlining vendored JS stays
unsupported** (leg-2 1.2) — document "do not inline vendored JS, keep it as
separate files under `assets/`". Operative form: `scripts/gate/gate.sh` §1.2 +
`scripts/gate/vendored-allowlist.txt` + `vendor-update.sh` + `verify.sh` +
`skills/frontend-kit/SKILL.md` Step 2 (new 2.1b) + `skills/taste-reference/SKILL.md`
+ `skills/frontend-kit/references/security-checklist.md` check 1.2 +
`skills/frontend-kit/experts/security.md` check 1.2. Non-blocking upstream
follow-up (not this wave): report the 3 runtime class-E sites to
Leonxlnx/taste-skill.

## D10 — GAP-10: seeds-only gitleaks path allowlist + backstop grep

Council (3–0, amendments recorded above). **Adopt (b):** add to the single
`[allowlist]` in `scripts/gate/.gitleaks.toml` (keeping `[extend] useDefault =
true`) exactly `'''(^|/)\.impeccable/questions/seeds/[^/]+\.json$'''` and
`'''(^|/)\.impeccable/questions/seed-salt$'''`, with the mechanism and
residual-hole paragraphs in the config comment in the run-log comment's honest
style. **Backstop (required):** `gate.sh` §1.1 gains a block mirroring the
run-log backstop, placed before the scanner branch, grepping
`seeds/*.json` + `questions/seed-salt` with the same two patterns; a hit fails
1.1. **In scope for this fix:** widen the assign pattern to accept an optional
closing quote between keyword and colon (verified strict superset by council-2;
no new false positive on the seed shape or `tokensHash`) — it closes the
identical gap in the run-log backstop; run it against the regression fixtures
before shipping. **Rejected:** whole-`.impeccable/` allowlist, `roll.json`
allowlist, regex allowlist on 32-hex content, format change (a), waiver
process (c). **Correction to the worker's account (binding):** for a `ghp_` +
20-char token the backstop grep is the ONLY layer, not a second layer
(gitleaks' `github-pat` rule needs 36 chars; only the 36-char shape fires, as
`github-pat`, not `generic-api-key`) — the config comment and any regression
test must reflect this; do not cite the worker's §3b sentence as written.
**Closing condition:** test trufflehog against the synthetic fixture and record
the result before GAP-10 is claimed closed; if it flags the seeds file, record
it as a documented limitation with the exact condition (gitleaks is the pinned
scanner install.sh installs; a trufflehog-only machine needs its own exclusion
or accepts the failure). Operative form: `scripts/gate/.gitleaks.toml` +
`scripts/gate/gate.sh` §1.1.

## D11 — Judge fix drops `100vh`: resolve by minimal token-sum internal growth (candidate-B pattern), never by restoring `100vh` or exempting SR-2

Council (2–1, dissent recorded in `build-notes/sr2-council/decision.md` §5; SR-2 vs judge fix 1, 2026-11-11). **Option (1) — adopt candidate B as-built as the next build / build of record, and its pattern as the standing resolution.**

**Rule.** When a judge fix drops the `100vh` rule on `.section` and SR-2 then fails on short sections, the builder resolves it by growing *internal* spacing by minimal token sums until each section's content reaches the one-screen content window (708px at 1440 with 96px pads), keeping non-hero section pads uniform at `--space-section` and non-hero inter-section gaps uniform at 2× `--space-section`. (The hero is governed by SR-1, not SR-2: in the R3 build the hero keeps 64px pads under the D1 deviation and the hero→about gap is 222px, not 192px.) Restoring `100vh` is forbidden (it undoes the judge fix). A content-height exemption to SR-2 is forbidden. Per-section bottom pads (candidate A) are a fallback only, when a section has no internal spacing that can grow, and must be declared as such in the round record.

**Bound.** Total shortfall **|S| ≤ 72px** (the doctrine's own add/cut number, `layout-v4.md` §2: "add or cut up to 72px"). The bound governs when the B-pattern applies: a shortfall within it (content in the 495–708px window) is filled by the pattern; a shortfall outside it, or content under 495px, is not stretched in a fix round. **All remedies split by who may apply them, whatever the content band:** **fix-round remedies** (builder, D2-compliant — same content, same copy, same section inventory): the B-pattern itself, the candidate-A fallback, `.g2` (structural, inventory unchanged), shrinking internal spacing by token sums. **Direction remedies** (human gate, re-pick — they change content, copy, or inventory): merge, add a picture/content, cut copy, split into two sections. If no remedy in either class fits, escalate — never stretch.

**Minimal-sum rule.** The growth or cut is the token sum landing the section's content closest to 708px, inside the 706–710px band where a token sum reaches it (height 898–902px, i.e. 900px ± SR-2's 2px tolerance); ties prefer the smaller sum. In the ordinary case that is the smallest sum of `--space-*` token values ≥ S for a shortfall, and the smallest sum cutting to the band for an overshoot — a single token step alone is not the rule (e.g. an overshoot of 28px cut by a single 32px step lands at 896px, WARN, where the sum 28 lands exactly at 900px). A single growable gap is grown by the minimal-sum rule like any other — the worked instance grows projects' single row-gap by +68. The builder records, per section, the shortfall, the token sum, and whether the result is exact or passes by SR-2's 2px tolerance — a tolerance pass (e.g. 901px) must be declared, never silent. **Margin collapse:** adjacent-sibling vertical margins collapse to their max, not their sum — when distributing growth across margins, count the collapsed value, not the sum of the two margins. Prefer row-gap (which does not collapse); the gate verifies the result.

**Contingent cap (not a binding bound).** No per-gap cap applies now. IF a full-shot grade penalises a B-pattern build's internal spacing (the trigger in member A's §6), the pattern gains a per-gap cap — the recorded candidate is B's 32px (= one `--space-6`) per gap per round, with shortfalls spread across two or more internal gaps — and this verdict is revisited with that grading evidence in hand. If a cap ever applies, a single growable gap that cannot reach the height within the cap falls back to candidate A for the remainder, or escalates.

**Re-expression rule (supporting change).** A judge fix that repeals a locked structural rule is not sent to the builder as written. The orchestrator re-expresses it as token diffs first (in the SR-2 case: fill the viewports by the SR-2 fill rule). If it cannot be re-expressed within the applicable bound, it is not a fix: it is a direction / escalation item for the human gate (P6(a) path), never a build instruction.

**Token-semantics note.** `--space-section` is per-side section padding; the inter-content gap is 2 × `--space-section` (192px at 96px pads). Measured gaps are compared against 2 × the token, never against the token itself. (Already stated in `layout-doctrine.md` §4; the rubric points at it — the judge's 96px comparison in the R2 fix order mis-read the lock.)

**Worked instance (probe run-2, R3 → candidate B as-built, gate GREEN 0 FAIL 15 WARN — verified, not predicted):** about panel margin 24 → 52 (+28 = 16+12); projects grid row-gap 16 → 84 (+68 = 64+4); tools panel margin 32 → 28 (−4). Contents 708/709/708, heights 900/901/900 — **the 901px projects height is a DECLARED tolerance pass under SR-2's 2px tolerance** (shortfall 67px has no exact token sum; the smallest sum ≥ 67 is 68). **Caveat, recorded not hidden:** the 84px projects row-gap (against a 16px column gap) is a gate-blind cost — the gate measures section heights and inter-section gaps, not internal-gap proportionality. The next full-shot grade is the check on it (see the contingent cap above).

**Operative form.** `references/layout-doctrine.md` §4 (SR-2 fill rule), `references/grader-rubric.md` (Fix order: re-expression rule + 2× note), `SKILL.md` step 5 (pointer), `scripts/gate/consistency.mjs` (section-height / section-tile / SR-2 T-height fix hints name D11 — guidance only, the check is unchanged). Consistent with D2 (tokens stay locked — B composes locked values, changes none).

**Scope.** Candidate B is gate-verified only; it has never been vision-graded, and this decision does not predict the next Space/Layout grade. The 96px gap-vs-padding ambiguity in the judge's wording is resolved by the token-semantics note above.

## D12 — macOS support: bash-3.2 rewrite, OS dispatch, darwin binaries, CI matrix (2026-11-11)

Coordinator decision (macOS phase, for a teammate's MacBook and the 14/11
buffet run). Stock macOS ships bash 3.2.57 as `/bin/bash` and GitHub
Actions macOS runners default to it; the scripts must run under it.

**1. Bash 3.2 compatibility by rewrite, NOT by requiring Homebrew bash.**
Requiring Homebrew bash adds friction for the end user (clone-and-go) and
for CI. The bash-4-only constructs are rewritten in bash-3.2-compatible
form: the `DONE_DIRS` dir→host map becomes two parallel indexed arrays
plus a linear lookup (`install.sh`); the line-to-array reads become
`while IFS= read -r` loops (`verify.sh`, `scripts/gate/gate.sh` ×6). A CI
lint step greps for the full banned-construct list (`declare -A`,
`mapfile`, `readarray`, `${var^^}` / `${var,,}`, `local -n`, `globstar`,
`&>>`, `;;&`, `coproc`) in all five scripts so regressions fail fast
(`bash -n` is syntax-only and cannot catch these — the grep is the
guard). The same
rewrite also guards the empty-array-under-`set -u` abort that bash older
than 4.4 has (index loops / length guards where an array can be empty).
`bash -n` runs on all five scripts in CI.

**2. OS dispatch, not removal of the gate.** `install.sh` replaces the
Linux-only fail with `case "$(uname -s)"` (Linux / Darwin / else-fail
with a clear message). `verify.sh` gets a matching darwin banner — no
hard gate: it reports the known macOS gaps up front instead of failing
confusingly in a later section.

**3. No `timeout` shim.** The existing WARNING + unbounded fallback on
macOS stays as-is and is documented; CI jobs are bounded with
`timeout-minutes` instead. (Vendoring a perl/python timeout shim was
considered and rejected as complexity for a path that already degrades
gracefully.)

**4. Gitleaks via pinned tarball (deterministic), not Homebrew.** Brew
rolls forward; the tarball pin is the deterministic route. Darwin asset
by `uname -m`: `darwin_arm64` /
`gitleaks_8.30.1_darwin_arm64.tar.gz` (sha256
`b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5`),
`darwin_x64` / `gitleaks_8.30.1_darwin_x64.tar.gz` (sha256
`dfe101a4db2255fc85120ac7f3d25e4342c3c20cf749f2c20a18081af1952709`) —
VERIFIED 2026-11-11 from the published checksums file (agree with the
releases API digests). `sha256sum` falls back to `shasum -a 256` (stock
macOS has no `sha256sum`), mirroring the `verify.sh` engine-hash
pattern.

**5. Darwin binaries (Playwright).** The curl fallback gains the
`mac-arm64`/`mac-x64` URL patterns (both CFT-bucket and
`cdn.playwright.dev` shapes, chrome + headless-shell +
`ffmpeg-mac.zip`/`ffmpeg-mac-arm64.zip`), the darwin headless-shell
derivation, and the darwin exe paths from the CLI 0.1.24 bundle's own
`lib/coreBundle.js` (`EXECUTABLE_PATHS` — chromium is the app-bundle
path `chrome-mac-<arch>/Google Chrome for Testing.app/Contents/MacOS/
Google Chrome for Testing`; the headless shell is NOT a bundle,
`chrome-headless-shell-mac-<arch>/chrome-headless-shell` — this resolves
the headless-shell exe suffix that was CHƯA ĐỌC in W-RES-2; ffmpeg
extracts a top-level `ffmpeg-mac` file on both arches, verified against
the downloaded zips 2026-11-11). Playwright cache dir per OS:
`~/Library/Caches/ms-playwright` on Darwin, `~/.cache/ms-playwright`
on Linux (curl-fallback path only — the CLI knows its own cache dir).
Chrome candidates in `verify.sh` §9 add the `/Applications/…` bundles,
mirroring `consistency.mjs` `findChrome`. PENDING texts are
OS-conditional (`--with-deps` sentence omitted on Darwin;
`~/.profile` → `~/.zshrc` on Darwin).

**6. CI matrix.** `.github/workflows/ci.yml` (the repo had no workflows):
pinned labels, never `-latest` — `ubuntu-24.04`, `macos-15`,
`macos-26`. Each job: checkout the branch under test → `./install.sh`
→ `./verify.sh --strict` end to end → the gate on a minimal probe build
(`tests/ci-gate-fixture/`). Plus, in each job, the banned-construct grep
and `bash -n` on all five scripts. `timeout-minutes: 30` on every job.
No Homebrew bash in CI — the default bash 3.2 IS the test. No `brew
install gitleaks` — the installer downloads the pinned tarball; that is
what is being tested. Node comes preinstalled on the runners (22.23.4 on
macos-15/ubuntu-24.04, 24.22.2 on macos-26) — the workflow asserts Node
22+, it does not install node.

**7. Host skills dirs unchanged** (verified identical on macOS), with one
addition: `cmd` now also writes its native `~/.commandcode/skills/`
(first — it outranks the shared dir on the documented priority order,
commandcode.ai/docs/skills, read 2026-11-11), then `~/.agents/skills/`.

**Operative form.** `install.sh` (OS dispatch, bash-3.2 rewrite, darwin
gitleaks + curl fallback, per-OS cache dir, OS-conditional PENDING
texts), `verify.sh` (darwin banner, read-loop, `seq` → arithmetic loops,
`-F`, macOS Chrome candidates, `cmd` native dir), `scripts/gate/gate.sh`
(read-loops, `mktemp` template, empty-array guards),
`scripts/check-versions.sh` (portable numeric sort in place of `sort
-V`), `.github/workflows/ci.yml`, `tests/ci-gate-fixture/`, `AGENTS.md`
§0 + §5 and `README.md` (macOS supported; Windows still open work).

**Follow-ups (NOT this wave — recorded, not implemented).** (a) Muse
Code's `$XDG_CONFIG_HOME/muse/skills` is NOT added: Muse Code is not in
`KNOWN_HOSTS`, and the `muse` host decision (AGENTS.md (g)) is
deliberate. (b) AGENTS.md (h) OpenCode precedence: the fetched OpenCode
docs now publish a later-wins rule contradicting (h) — do NOT silently
overwrite it; the fetched page's version status (stable vs v2 beta)
needs naming first. (c) The Codex "reads both `~/.codex/skills` and
`~/.agents/skills`" claim is still NOT primary-verified (official docs
list only `~/.agents/skills`); the install-to-both hedge stays, the
docs citation does not change. (d) `cmd skills list --debug` was
partially verified via the primary CommandCode docs page in W-RES-1
(the command is named there; it was not run) — AGENTS.md §5 still
records it as CHƯA ĐỌC until a run confirms it.
