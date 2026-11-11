# Security checklist — cross-check team's working checklist

A vendored reference for the security/compliance cross-check team
(`research/coordination/buffet-mode-coordination-v2.md` §13).
Every check below is taken from `research/security-ai/SYNTHESIS.md`
(workspace research note, not shipped in this repo)
§3 (the ordered runbook, Stages 0–6), §5 (never-automate list),
and §7 (tooling), all dated 2026-11-11. Check IDs are the
synthesis IDs (0.1–0.6, 1.1–1.12, 2.1–2.6, 3.1–3.10, 4.1–4.11)
so `experts/security.md` and the gate scripts can cross-reference
them; Stages 5–6 were unnumbered lists in the synthesis, so this
file assigns them IDs 5.1–5.7 and 6.1–6.3 (checklist-assigned, not
synthesis IDs).

**What this file is not:** it is not a second expert brief and it
adds no new rule of its own. The synthesis governs; this file is
the checkable detail behind it. Anything in the synthesis §8 gaps
or §6 disagreements stays out of the pass/fail column — see
"Deliberately excluded / NOT verified" at the end.

**Handoff:** gen-10 syncs this checklist into `coord/CROSSCHECK.md`
(the coordinator-owned checklist file); this file is the team's
working copy, `coord/CROSSCHECK.md` is the binding copy once the
red team has verified it (§13: the checklist is verified by an
independent red team before it becomes binding).

**Status:** mandatory stage, same level as the deterministic gate
(§13). The cross-checker is always independent — never the builder
of the slice, never the design judge for that slice, never an agent
with production history of the slice. It runs twice: (i) pre-land,
per slice, after the deterministic gate and before the judge grade,
on the merged tree in the trial worktree; (ii) pre-ship, once, on
the shipping version (the mainline tip at stop), before the
human-gate packet is prepared. Each check produces a report at
`coord/crosscheck/<slice-id>-<n>.md`; findings carry severity +
evidence (file:line, what, why, suggested fix). The coordinator
transcribes the verdict (SEVERE count, WARNING count, OK) into the
run log before landing. The pre-ship report is attached to the
human-gate packet.

## Regression corpus (deterministic gate)

The 77 ground-truth training cases in `research/security-ai/training/ground-truth.md` (workspace research material, not shipped in this repo; 25 code pairs, 24 agent-loop cases, 28 supply-chain/licence/ToS cases) are the deterministic gate's regression corpus: the gate's own tests must run them. The gate consumes ASVS 5.0.0 requirement IDs as its pass/fail checklist, the XSS/DOM-XSS cheat sheets as its sink rules, and these 77 cases as the regression corpus for its own tests. Training cases only — the 20 held-out cases in `research/security-ai/training/held-out/` are sealed, checker-only, and never enter the gate's tests or the guard's training material.

**Runner status (Wave 6): no test runner exists yet that runs these 77 cases against the gate — the corpus is prose in the sealed training material; a runner needs per-case fixtures + a case→gate-check mapping, which is unwired work, not built here. "The gate's own tests must run them" is a requirement on the gate's own tests, not a claim that they run today.**

**Status: ASSEMBLED — awaiting dedicated red-team verification before delivery. Do not use for graduation until the red team passes it.** The training material is wired in, but GRADUATION USE IS BLOCKED until the package passes its dedicated red-team verification (still owed — open item).

## Fail-closed rule (read first — it governs every check below)

**A check that cannot run is a BLOCK, not a pass.** Scanner error,
registry unreachable, licence unparseable, tool not installed,
target not reachable — any of these stops the land/ship exactly as
a failing check does. Never record a check as passed because the
tool that would have caught the failure was unavailable. If the
check cannot run, record it as BLOCK with the reason ("scanner
error: …", "registry unreachable: …") and the slice goes to
`input-required`. (Synthesis §3, header.)

Order matters: cheapest deterministic checks first, human-review
checks last; the independent re-run last, before merge/ship.

## Severity model

The synthesis uses BLOCK / WARN / PAUSE; §13 uses SEVERE /
WARNING / OK. They are the same scale under two names:

- **SEVERE = BLOCK.** Merge/ship stops until fixed, or a named
  human accepts the residual risk in writing. The coordinator can
  NEVER waive a SEVERE — only the human, on return, can override
  one, and the override is recorded in the run log with the human's
  name.
- **WARNING = WARN.** May proceed only with a recorded reason and
  a named owner; the coordinator waives it with a written reason in
  the run log (accepted risk, named, dated). A waived warning is
  still visible in the pre-ship report.
- **OK = clear.** Recorded in the run log; the land/ship proceeds.
- **PAUSE** = stop and wait for an explicit human decision on the
  exact action and its arguments, before execution. (Used in Stage 3
  for consequential actions from trusted content and goal-changing
  actions.)

**Score cap (not an escalation):** two or more WARNINGs on the same auth/data
path cap the domain score at 2 (FIX) — they remain WARNINGs, waivable by the
coordinator with a written reason; only a SEVERE blocks the land/ship.
(Synthesis §3 header; Stage 5.5.)

**Labels are team policy, not source labels.** None of the sources
assigns BLOCK/WARN labels — OWASP and NIST explicitly do not.
Every label in this file is the cross-check team's own policy,
layered on top of the sources' outcomes. **Do not cite a BLOCK as
"OWASP requires" or "NIST mandates"** — that would be fabricated
attribution. (Synthesis header.)

## Key numbers — why this team exists (sourced, 2026-11-11)

| # | Measured finding | Source (read status) |
|---|---|---|
| 1 | **45% of AI-generated code samples introduced an OWASP Top 10 flaw.** XSS failed in 86% of relevant samples, log injection in 88%; Java failed 72%, JS 43%. Newer/larger models did **not** improve security. | Veracode 2025 GenAI Code Security Report summary, read in full — https://www.veracode.com/blog/genai-code-security-report/ ; press release read in full — https://www.veracode.com/press-release/ai-generated-code-poses-major-security-risks-in-nearly-half-of-all-development-tasks-veracode-research-reveals/ |
| 2 | **LLM security review is non-repeatable.** Best LLM reached only 75.4% F1 vs deterministic SAST; **49.7% of LLM-only findings appeared in just 1 of 5 identical runs**; best model scored only 40% F1 on the largest app-like fixture. A single LLM pass is never a gate decision. | Snyk VulnBench JS 1.0 (2026-06-29), read in full — https://snyk.io/blog/snyk-vulnbench-js-1-0-llm-security-review-repeatability/ |
| 3 | **~1 in 5 AI-recommended packages do not exist.** **19.7% of AI-recommended packages** (576,000 samples, 16 models) were hallucinated names; 43% of hallucinated names reappeared on every single run when identical prompts were repeated 10 times, so attackers can pre-register them. | Spracklen et al., USENIX Security 2025, abstract + introduction read — https://arxiv.org/html/2406.10279v1 ; the 43% repeat figure is via TechTarget, read in full by W-SUPPLY-COMPL |
| 4 | **Prompt injection has no reliable prevention.** A USENIX Security 2026 paper cited by OWASP (Nasr et al.) tested 12 recent defenses; adaptive attackers who tuned attacks to each defense succeeded more than 90% of the time **against most of them**. Assume injection will succeed and limit what a fooled model can reach. Underlying study not opened in this session (arXiv:2510.09023); do not cite the >90% figure as established. | Via OWASP/Anaconda secondary, read in full — https://www.anaconda.com/blog/owasp-top-10-llm-applications-agents-how-to-check |
| 5 | **Zero-click injection is proven, not theoretical.** EchoLeak (Microsoft 365 Copilot, CVE-2025-32711, CVSS 9.3, June 2025): a crafted email exfiltrated tenant data with no click. | **Secondary-sourced — verify against NVD before citing as established.** CVE record not read; see `research/security-ai/workers/w-leak-inj.md` F5 (workspace research note, not shipped in this repo). |

Corollaries the team works from (same sources): the builder's
model cannot be trusted to write secure code, and no single AI
reviewer can be trusted to catch what it missed. The team must be
(a) independent of the builder, (b) deterministic-first, and
(c) blocking. "A model grading its own homework is not a security
program" (Snyk Evo, read in full).

---

## Stage 0 — Governance preconditions (before any code review)

Severity: **BLOCK if missing** (any single item). Where: project
records / repo / run log — no code is reviewed until this stage
passes. Tool: human check against the named documents; there is no
deterministic scanner for governance.

- [ ] **0.1 — Named human owner AND named human reviewer who is
  not the builder.** What to look for: two distinct named humans
  recorded for the slice; the reviewer is not the builder and not
  the agent that produced the code. Builder self-review = fail.
  Anchor: NIST GOVERN 2.1/2.3, MEASURE 1.3.
- [ ] **0.2 — AI inventory entry.** What to look for: model(s),
  version, access mode, data sources, data provenance recorded for
  every AI component in the slice. No entry = unmapped system.
  Anchor: NIST GOVERN 1.6, GV-1.6-001/003.
- [ ] **0.3 — Map sheet.** What to look for: intended purpose,
  users, deployment setting, knowledge limits, human-oversight
  process — all stated. This is the go/no-go gate.
  Anchor: NIST MAP 1.1/2.2/3.5.
- [ ] **0.4 — Threat model covering AI-specific threats.** What to
  look for: prompt injection, data poisoning, malicious content in
  AI output, hallucinated dependencies, secret disclosure — each
  addressed, not just listed.
  Anchor: NIST GV-3.2-005, MS-2.7-001; SP 800-218A.
- [ ] **0.5 — Acceptable-use / terms-of-use policy exists.**
  What to look for: the policy file exists; prohibited uses are
  stated explicitly.
  Anchor: NIST GOVERN 1.4.
- [ ] **0.6 — Third-party components, models, datasets and licences
  listed; IP position stated.** What to look for: the list covers
  every third-party item in the slice; the IP position (what the
  project owns vs licences vs must not claim) is stated in writing.
  Anchor: NIST GOVERN 6.1, MAP 4.1/4.2.

## Stage 1 — Deterministic gate on the diff [GATE]

Severity: **BLOCK** unless a check says otherwise. Where: the
diff (and the files it touches). These checks are deterministic
and belong in the kit's deterministic gate.

- [ ] **1.1 — Secret scan clean on every diff.** What to look
  for: no API key, token, password, private key, connection string
  in code, config, comments, or bundle. Where: every file in the
  diff. Tool: `gitleaks` (v8.30.1) and/or TruffleHog (v3.99.3) as
  pre-commit, plus GitHub push protection, plus CI as the required
  check (three layers). Grep probe (not a substitute for the
  scanner): `grep -rInE '(api[_-]?key|secret|token|password|passwd|private[_-]?key|BEGIN (RSA|EC|OPENSSH) PRIVATE KEY|mongodb(\+srv)?://|postgres(ql)?://|mysql://)' -- <diff files>`.
  Severity: BLOCK. Anchor: OWASP LLM02:2026/A02:2025; NIST S1; W-LEAK-INJ B1.
- [ ] **1.2 — No unsanitised HTML injection from untrusted data.**
  What to look for: `dangerouslySetInnerHTML` / `innerHTML` /
  `outerHTML` / `document.write()` fed by untrusted data — user
  input, stored data, API responses, **or model output** — without
  DOMPurify sanitization. Where: diff. Grep:
  `grep -rInE 'dangerouslySetInnerHTML|innerHTML|outerHTML|document\.write\(' -- <diff files>`
  and confirm each hit is either removed or wrapped in DOMPurify
  sanitization. Severity: BLOCK. Anchor: OWASP LLM10:2026, A05:2025; ASVS v5.0.0-1.2.1, v5.0.0-1.3.1, v5.0.0-3.2.2.
- [ ] **1.3 — No code execution from untrusted input.** What to
  look for: `eval()` / `Function()` / `setTimeout(string)` /
  `setInterval(string)` with untrusted or model-generated input; no
  untrusted data in `onclick` / event-handler attributes or
  JS-code contexts. Where: diff. Grep:
  `grep -rInE '\beval\s*\(|new Function\s*\(|setTimeout\s*\(\s*["'"'"'`]|setInterval\s*\(\s*["'"'"'`]|on(click|load|error|submit)\s*=' -- <diff files>`.
  Severity: BLOCK. Anchor: OWASP LLM10:2026; ASVS v5.0.0-1.2.3, v5.0.0-1.3.2 (the BLOCK rests on these). ASI05 is a [CHƯA ĐỌC] cross-reference hint only — the Agentic Top 10 list was NOT verified; never the authority for this BLOCK.
- [ ] **1.4 — No model output into code execution.** What to look
  for: model output interpolated into SQL / shell / template
  engines, or passed to code execution, without
  validation/parameterization. Where: diff (any call site that
  takes model output as an argument to a query, shell, or template
  render). Tool: manual review of each such call site — no
  deterministic scanner named by the synthesis for this check.
  Severity: BLOCK. Anchor: OWASP LLM10:2026; ASVS v5.0.0-1.2.4, v5.0.0-1.2.5 (the BLOCK rests on these). ASI05 is a [CHƯA ĐỌC] cross-reference hint only — the Agentic Top 10 list was NOT verified; never the authority for this BLOCK.
- [ ] **1.5 — Unvalidated URLs from untrusted/model data.** What
  to look for: untrusted or model data reaching `href` / `src` /
  `iframe src` without an allow-list of http/https only and a
  rejection of `javascript:`. Where: diff. Grep:
  `grep -rInE 'javascript:|href\s*=\s*\{|src\s*=\s*\{' -- <diff files>`
  and verify each dynamic URL passes an allow-list check.
  Severity: BLOCK. Anchor: OWASP XSS cheat sheet; A05:2025; ASVS v5.0.0-1.2.2.
- [ ] **1.6 — Every new dependency exists, pinned, locked.**
  What to look for, in this vetting order before install:
  existence → version → age/maintainer → install-script →
  provenance → licence. Every new dependency exists on the
  official registry at the exact requested version (live lookup);
  pinned to exact version + integrity hash; lockfile entry present;
  no version ranges in production manifests. Where: package
  manifest + lockfile. Tool: live registry lookup for each new
  dependency at the exact version (e.g. `npm view <pkg>@<version>
  version dist.integrity`); `grep -E '"[^"]+": "\^|~|>=|<=|\*"'`
  on the production manifest to catch ranges.
  Severity: BLOCK. Anchor: OWASP LLM04:2026/A03:2025; NIST S3; USENIX 2025
  (19.7% of AI-recommended packages do not exist — see Key numbers).
- [ ] **1.7 — No known high/critical CVE in a reachable
  dependency; no known-malicious / typosquat / slopsquat package.**
  What to look for: audit output filtered by reachability (a CVE
  in unreachable code weighs less, but a known-malicious or
  typosquat/slopsquat name is a BLOCK regardless). Where: lockfile
  / SBOM. Tool: `npm audit` (+ `osv-scanner` / `grype` on the SBOM
  where available); Semgrep Supply Chain where configured.
  Severity: BLOCK. Anchor: OWASP A03:2025/A08:2025; Semgrep Supply Chain.
- [ ] **1.8 — Security headers present.** What to look for: CSP
  present; HSTS present; no `Access-Control-Allow-Origin: *` on
  credentialed endpoints; cookies `Secure` + `HttpOnly`. Where:
  server config / response headers of the built app. Tool: inspect
  response headers (`curl -sI <url>`) and the cookie attributes in
  the built app; grep the server config for
  `Access-Control-Allow-Origin: \*`.
  Severity: BLOCK. Anchor: OWASP A02:2025; CSP cheat sheet; ASVS v5.0.0-3.4.1, v5.0.0-3.4.2, v5.0.0-3.4.3, v5.0.0-3.5.1–3.5.3 (3.5.x human-verified — CSRF/origin validation needs app context, not gate-enforced).
- [ ] **1.9 — No weak crypto.** What to look for: MD5/SHA1 for
  security purposes, deprecated TLS, custom crypto,
  `Math.random()` for secrets/tokens, hardcoded keys. Where: diff.
  Grep: `grep -rInE 'md5|sha1|Math\.random\(\)|createCipher\(|DES|RC4' -- <diff files>`
  and verify each hit is not security-relevant (checksums of
  public content are not a finding; token generation is).
  Severity: BLOCK. **Grading divergence disclosed:** W-APPSEC
  rates weak crypto BLOCK; W-OWASP rates it WARN. This runbook
  follows W-APPSEC. Anchor: OWASP A04:2025.
- [ ] **1.10 — Licence scan of the full transitive production
  tree.** What to look for: SPDX-normalised licences for every
  production dependency (transitive, not just direct);
  deny-by-default allowlist; deny GPL in distributed trees, AGPL
  everywhere (including SaaS), SSPL/BUSL/Elastic, unknown/no
  licence. Where: lockfile / SBOM. Tool: `license-checker-rseki`,
  ScanCode, or ORT (Analyzer → Downloader → Scanner → Advisor →
  Evaluator → Reporter); ground truth = real LICENSE files.
  Severity: BLOCK. Anchor: NIST GOVERN 6.1; W-SUPPLY-COMPL Stage 2.
- [ ] **1.11 — Rate limits / token budgets / step caps on LLM or
  API features.** What to look for: an unbounded-consumption
  feature (LLM call, external API call) with no rate limit, token
  budget, or step cap. Where: diff (feature code + its config).
  Tool: manual review of the feature's limits config — no
  deterministic scanner named by the synthesis for this check.
  Severity: WARN; **BLOCK if the feature handles money or
  sensitive data**. Anchor: OWASP LLM06:2026; A06:2025.
- [ ] **1.12 — Lifecycle scripts disabled in CI installs.** What
  to look for: installs in CI run with lifecycle scripts disabled;
  any dependency needing one is on an explicit allowlist with a
  reason recorded. Where: CI config + allowlist. Tool: inspect CI
  config for `--ignore-scripts` (or equivalent) on install steps.
  Severity: BLOCK. Anchor: W-SUPPLY-COMPL S5.

## Stage 2 — Assembled-app checks (post-build, semantic + runtime)

Severity: **BLOCK**. Where: the built bundle and the running app
(post-build, not the diff). These are semantic and runtime checks;
[TEST] items need a live run.

- [ ] **2.1 — Built bundle leaks nothing.** What to look for: no
  secrets in the built bundle, no sourcemap leaking internals, no
  debug endpoints shipped. Where: built bundle + sourcemaps +
  shipped routes. Tool: run the Stage 1.1 secret scan (gitleaks /
  TruffleHog) against the built output directory; grep the bundle
  for secret-shaped strings; list shipped sourcemaps and confirm
  none is served. **Read-status note:** no source in the synthesis
  session measured secret/sourcemap leakage in the built frontend
  bundle directly — this check is an implication (W-APPSEC Stage 5
  implication), not a measured finding (synthesis §8.8).
  Severity: BLOCK. Anchor: W-APPSEC Stage 5 (implication).
- [ ] **2.2 — Auth enforced on every route/API call [TEST].**
  What to look for: two-user test — no endpoint accepts any token /
  no token / a changed ID to read another user's data (IDOR, broken
  access control). Where: running app, every route and API call.
  Tool: manual two-user runtime test (user A token vs user B
  resource; no token; tampered ID). Severity: BLOCK.
  Anchor: OWASP A01:2025; W-APPSEC B5.
- [ ] **2.3 — Error handling fails closed [TEST].** What to look
  for: no check that throws and defaults to "approved"; error pages
  leak no stack traces, credentials, or internal paths. Where:
  running app (force errors: bad input, failing dependency, expired
  session) + error-page output. Tool: runtime probe; grep built
  output for stack-trace-shaped leakage in error responses.
  Severity: BLOCK. Anchor: OWASP A10:2025 (new in 2025).
- [ ] **2.4 — No over-broad CORS, auth bypass, or debug mode in
  the shipped build.** What to look for: no over-broad CORS with
  credentials; no auth bypass; no debug mode / verbose errors in
  the shipped build. Where: running app + build config. Tool:
  inspect CORS config and response headers; confirm the shipped
  build is the production build (not dev/debug).
  Severity: BLOCK. Anchor: OWASP A02:2025; W-APPSEC B6.
- [ ] **2.5 — Quality-gate floor for new code (Sonar shape).**
  What to look for: no new security issues, all new security
  hotspots reviewed, coverage and duplication thresholds met
  (Sonar built-in: 80% coverage, ≤3% duplication; hardened target:
  90% / ≤1%). Where: SonarQube (or equivalent) report on the new
  code. Tool: SonarQube quality gate on the slice.
  Severity: BLOCK. Anchor: Sonar, read in full —
  https://www.sonarsource.com/blog/how-to-optimize-sonarqube-for-reviewing-ai-generated-code/
- [ ] **2.6 — No CSAM/NCII/illegal or hateful content generatable
  or shippable; output filters evidenced.** What to look for: the
  app cannot generate or ship CSAM/NCII/illegal or hateful content;
  output filters are evidenced (present and demonstrably active),
  not merely asserted. Where: running app + filter config. Tool:
  human review + runtime probe of the output path.
  Severity: BLOCK. Anchor: NIST GV-1.4-001; AI 600-1 §2.3/§2.11.

## Stage 3 — Agent-loop checks (the kit's own agents)

Severity: per check (BLOCK / PAUSE / WARN). Where: the agent
session itself — its tool calls, its inputs, its handoffs — not
just the produced code. These checks are about what the builder
agent did, and they apply to every agent in the loop, including
the cross-checker (a compromised cross-checker is failure mode
F33: the coordinator discards a suspect report and summons a
fresh cross-checker).

- [ ] **3.1 — Lethal trifecta complete in one agent session.**
  What to look for: private data + untrusted content + external
  channel in one session — including rendering remote images/links
  or a `fetch_url` carrying a query string. Fix by splitting the
  agent or removing a leg. Severity: BLOCK.
  Anchor: Willison trifecta (the BLOCK rests on this). OWASP ASI01/ASI02 are [CHƯA ĐỌC] cross-reference hints only — the Agentic Top 10 list was NOT verified; never the authority for this BLOCK.
- [ ] **3.2 — Instruction-shaped text in an untrusted channel
  acted on.** What to look for: a fetched page, README, comment,
  tool output, or rules file containing instruction-shaped text
  that the builder acted on. Where: agent transcript + the
  untrusted source it read. **Read-status note:** Greshake et al.
  arXiv:2302.12173 CHƯA ĐỌC direct (cited via read secondaries).
  Severity: BLOCK. Anchor: OWASP LLM01:2026; Greshake et al.
  arXiv:2302.12173.
- [ ] **3.3 — Untrusted content concatenated into instructions.**
  What to look for: generated code that concatenates untrusted
  content into system instructions, prompts, or tool parameters;
  tool outputs treated as instructions. Where: diff + agent
  transcript. Severity: BLOCK.
  Anchor: Anthropic F4; Google input separation.
- [ ] **3.4 — Builder self-escalation.** What to look for: the
  builder modifies gate policy, allowlists, CI config, permission
  files, its own instructions/memory, adds MCP servers/tools, or
  widens its own permissions. Where: diff + agent transcript.
  **Read-status note:** W-BIGTECH F18/F19 (memory integrity;
  builder-editable files are not controls) is secondary only —
  re-verify against code.claude.com before codifying this check
  further. Severity: BLOCK.
  Anchor: Google F10-P2 (no self-escalation); W-BIGTECH F18/F19.
- [ ] **3.5 — Tool call outside the allowlist / bad schema /
  tainted argument / cross-tenant.** What to look for: a tool call
  outside the allowlist, with an argument failing its schema, with
  a tainted value in a sensitive argument, or against another
  tenant/user's data. Where: agent transcript / tool-call log.
  Severity: BLOCK. Anchor: Beurer-Kellner
  patterns (the BLOCK rests on these). OWASP ASI02/ASI03 are [CHƯA ĐỌC] cross-reference hints only — the Agentic Top 10 list was NOT verified; never the authority for this BLOCK.
- [ ] **3.6 — Consequential action from tainted content.** What
  to look for: merge, publish/deploy, delete/overwrite outside the
  worktree, external send, permission/credential change, where any
  argument came from untrusted content. Where: agent transcript.
  Severity: BLOCK. Anchor: dual-LLM/quarantine
  pattern (the BLOCK rests on this). OWASP ASI01/ASI02 are [CHƯA ĐỌC] cross-reference hints only — the Agentic Top 10 list was NOT verified; never the authority for this BLOCK.
- [ ] **3.7 — Consequential action from trusted content.**
  What to look for: merge to main, deploy/publish, delete,
  permission change, secret access, external send — any of these
  executed without human approval on the exact call + arguments,
  before execution. Where: agent transcript. Severity: PAUSE —
  stop and wait for an explicit human decision on the exact action
  and its arguments, before execution. Anchor: OWASP LLM03:2026; Google
  human confirmation; SAIF.
- [ ] **3.8 — Goal-changing action proposed mid-run.** What to
  look for: a brief, scope, or taste-lock change proposed mid-run,
  especially if triggered by content the agent read. Where: agent
  transcript. Severity: PAUSE. Anchor: human confirmation on the exact change before execution (the PAUSE rests on this — same principle as 3.7's Google human confirmation). OWASP ASI01 is a [CHƯA ĐỌC] cross-reference hint only — the Agentic Top 10 list was NOT verified; never the authority for this PAUSE.
- [ ] **3.9 — Inter-agent handoff without provenance.** What to
  look for: a handoff with no sender, no source label, no schema —
  spoof/replay risk. Where: handoff messages / board rows.
  Severity: WARN now; **BLOCK if a handoff carries an instruction
  that changes the goal or a tool call**. Anchor: the handoff provenance rule itself — a handoff with no sender, no source label, no schema is untrusted (the WARN/BLOCK rests on this). OWASP ASI07 is a [CHƯA ĐỌC] cross-reference hint only — the Agentic Top 10 list was NOT verified; never the authority for this verdict.
- [ ] **3.10 — Prompt-side defences only.** What to look for: a
  system-prompt line, delimiters/spotlighting alone, with no
  deterministic gate behind them. "We added a guardrail prompt"
  must never pass. **Read-status note:** the spotlighting ceiling
  (reported 50%→<2% attack success via HLD summary; Spotlighting
  paper CHƯA ĐỌC) is not a verified figure. Severity: WARN.
  Anchor: HLD Handbook; spotlighting ceiling.

## Stage 4 — Supply-chain, licence, copyright, ToS (detail stages)

Severity: per check. Where: lockfile, SBOM, manifests, assets,
service registry. These are the detail stages behind Stages 1.6,
1.7, and 1.10 — run them when the slice adds or changes a
dependency, an asset, or an external service call.

- [ ] **4.1 — Lockfile + frozen install + SBOM.** What to look
  for: lockfile present, committed, changed only via the package
  manager; frozen install in CI (`npm ci`, not `npm install`);
  SBOM generated from the final built artifact (CycloneDX,
  validated) and attached. Where: repo + CI config + SBOM file.
  Tool: `npm ci` in CI; `syft` to generate the SBOM;
  `cyclonedx-cli validate` to validate it.
  Severity: BLOCK. Anchor: W-SUPPLY-COMPL Stage 0; `syft`,
  `cyclonedx-cli validate`.
- [ ] **4.2 — Base images / container tags pinned by digest.**
  What to look for: tags pinned by digest (`@sha256:`), never
  `:latest`. Where: Dockerfiles / container manifests. Grep:
  `grep -rIn ':latest' -- Dockerfile* docker-compose* *.yaml`
  (and the equivalent for the project's container files).
  Severity: BLOCK. Anchor: W-SUPPLY-COMPL S6.
- [ ] **4.3 — Signatures and provenance.** What to look for:
  `npm audit signatures` passes; provenance source/builder matches
  the expected repository where claimed. Provenance proves origin,
  NOT safety. Where: lockfile / registry metadata. Tool:
  `npm audit signatures`. Severity: **BLOCK if signatures are
  missing or invalid for a registry that supports them; WARN if
  provenance is simply absent**. Anchor: npm Docs; SLSA.
- [ ] **4.4 — No dependency-confusion exposure.** What to look
  for: no internal/private package name resolvable from the public
  registry (dependency-confusion check); scoped registries
  configured. Where: manifests + registry config (`.npmrc` /
  equivalent). Tool: live registry lookup for each internal scoped
  name — if it resolves publicly, it is a finding.
  Severity: BLOCK. Anchor: W-SUPPLY-COMPL S4.
- [ ] **4.5 — Dual licences resolved by explicit human election.**
  What to look for: SPDX `OR` resolved by an explicit recorded
  human election of the allowlisted side; `AND` requires satisfying
  both. Compatibility matrix checked (GPL-2.0-only + Apache-2.0,
  GPL-3.0 + GPL-2.0-only, AGPL + proprietary SaaS are
  incompatible). Where: licence scan output + the recorded
  election. Tool: ORT Evaluator against the OSADL matrix.
  **Read-status note: the L5 compatibility pairs are SEARCH
  SNIPPET ONLY** (claude-dev-suite and craftbot skills, not opened
  in full) — verify against the OSADL matrix / ORT Evaluator before
  freezing the gate. Severity: BLOCK if unresolved.
  Anchor: W-SUPPLY-COMPL L4/L5; OSADL matrix via ORT.
- [ ] **4.6 — Attribution shipped.** What to look for: NOTICE /
  THIRD-PARTY-LICENSES auto-generated from the locked tree, diffed
  against the committed copy, shipped in the artifact. Where:
  committed NOTICE file vs generated one vs shipped artifact.
  Tool: regenerate from the locked tree and `diff` against the
  committed copy. Severity: BLOCK if diff fails or a distributed
  dep is unattributed. Anchor: W-SUPPLY-COMPL L6.
- [ ] **4.7 — Code regurgitation.** What to look for: long
  verbatim-looking blocks, distinctive comments/identifiers, any
  non-trivial snippet the builder cannot explain the provenance of.
  Where: diff. Tool: **no canonical free deterministic scanner was
  verified** — minimum is builder provenance attestation per file +
  human review (synthesis §8.3: the largest tooling gap found).
  Severity: BLOCK if it matches a known copyrighted/GPL work;
  otherwise WARN + human review.
  Anchor: US Copyright Office Jan 2025 guidance (via secondary
  summaries; primary CHƯA ĐỌC).
- [ ] **4.8 — Every image asset has a provenance record.** What
  to look for: stock URL + licence + date, OR generator + tool +
  prompt, OR own photography; reverse-image search run; C2PA
  Content Credentials read where present. Absence of a signal
  proves nothing. Per-image stock rules: standalone resale /
  competing-service compilation / trademark use = BLOCK;
  recognisable people/brands in frame = WARN + human review (model
  release not guaranteed). Where: asset inventory + image files.
  Tool: reverse-image search (Google Lens / TinEye); `c2patool`
  where C2PA credentials are present (docs CHƯA ĐỌC).
  Severity: BLOCK if no provenance record or it matches a known
  copyrighted/stock work without a licence.
  Anchor: W-SUPPLY-COMPL C3/C4.
- [ ] **4.9 — Every font has a licence record.** What to look
  for: Google Fonts family + licence verified on fonts.google.com
  = allow; self-hosted OFL with `OFL.txt` kept = allow; any other
  font = BLOCK pending licence evidence. Where: font files + font
  inventory. Severity: BLOCK if no licence evidence.
  Anchor: W-SUPPLY-COMPL C5.
- [ ] **4.10 — Every fetch / API call target is a declared
  service.** What to look for: a service registry entry per target
  (service, URL, plan, ToS/licence URL, rate limit, attribution
  rule); undeclared external hosts in code = BLOCK. No scraping
  pattern (no HTML scraping where an official API exists; no
  bulk-download loops; no key/account cycling); auth method matches
  the service's ToS. Where: diff (every `fetch` / API call) +
  service registry. Grep:
  `grep -rInE 'fetch\s*\(|axios\.|XMLHttpRequest|https?://' -- <diff files>`
  and match each host against the registry. **Read-status note: no
  general-purpose ToS checker was verified** — this is a
  per-service manual registry + deterministic flags (synthesis
  §8.2). Severity: BLOCK / WARN (BLOCK for undeclared hosts and
  scraping patterns; WARN for registry-entry gaps that do not
  change behaviour). Anchor: W-SUPPLY-COMPL T1/T2.
- [ ] **4.11 — No AI-generated image asserted as copyright-owned.**
  What to look for: no AI-generated image asserted as
  copyright-owned by the project; human-authorship evidence
  recorded for any asset the project claims to own. Where: asset
  inventory + copyright claims in the repo/docs. Severity: WARN;
  **BLOCK any copyright registration / DMCA assertion over purely
  AI output without legal review**. Anchor: US Copyright Office
  guidance (secondary).

## Stage 5 — Independent re-run + human sign-off (the cross-check team's own run)

Severity: **BLOCK**. Where: the team's own run — its own tools,
its own verdict. IDs 5.1–5.7 are assigned by this checklist
(the synthesis lists them unnumbered).

- [ ] **5.1 — The team re-runs Stages 1–4 with its own tools and
  its own verdict.** What to look for: the builder's scan results
  are evidence, never the verdict (Snyk Evo; Snyk VulnBench
  repeatability). Any BLOCK = no merge/ship. Anchor: Snyk Evo;
  Snyk VulnBench.
- [ ] **5.2 — Fixes go back through Stages 1–4 and are
  re-scanned.** What to look for: every fix re-run through Stages
  1–4. A fix can introduce a new flaw (Snyk Evo: LLM-only fix
  mergeable 59.6%; GitHub Autofix warning). Anchor: Snyk Evo;
  GitHub Autofix responsible-use page (search-snippet only,
  CHƯA ĐỌC full).
- [ ] **5.3 — LLM-only semantic findings that appear in only one
  run are logged, re-run, and corroborated** with a deterministic
  rule or a second model before acting. (Snyk VulnBench: 49.7%
  appear once.) Anchor: Snyk VulnBench JS 1.0.
- [ ] **5.4 — Severity is re-graded by a human** from impact +
  reachability. AI severity labels were the noisiest output
  measured (MegaLens: 0/9 "critical" labels survived dual
  checking). Anchor: MegaLens.
- [ ] **5.5 — Two or more WARNs on the same auth/data path
  cap the score at 2 (FIX); they do not escalate to BLOCK.**
  (W-APPSEC WARN-table rule, as adopted here.) Anchor:
  W-APPSEC.
- [ ] **5.6 — Residual risk is documented for downstream users**
  (NIST MANAGE 1.4); acceptance must be explicit, named, and in
  writing — never silent. Anchor: NIST MANAGE 1.4.
- [ ] **5.7 — Rollback / deactivate path exists** for a shipped
  build (NIST MANAGE 2.4, CSF RS/RC). No rollback path = BLOCK.
  Anchor: NIST MANAGE 2.4, CSF RS/RC.

## Stage 6 — Release (runs on the release tag, not just on PR)

Severity: **BLOCK**. Where: the release tag and the shipped
artifact. IDs 6.1–6.3 are assigned by this checklist (the
synthesis lists them unnumbered).

- [ ] **6.1 — Re-run Stages 0–5 on the release tag and re-generate
  the SBOM + NOTICE from the locked tree.** What to look for: the
  full runbook re-executed against the tag, not the PR branch; SBOM
  and NOTICE regenerated from the locked tree at the tag.
  Anchor: synthesis §3 Stage 6.
- [ ] **6.2 — Re-scan the stored SBOM for newly disclosed CVEs on
  a schedule after shipping** (`osv-scanner`, `grype`); a new
  critical/high CVE opens a follow-up item. Anchor: synthesis §3
  Stage 6.
- [ ] **6.3 — Sign the release artifact + SBOM keylessly
  (cosign/OIDC) and emit SLSA provenance** binding artifact →
  source commit → builder; verify identity on consumption (pin
  issuer + subject, not just "is it signed"). Tool: `cosign`.
  Anchor: synthesis §3 Stage 6.

---

## What the team must never automate (always human)

Derived from sources read in full (W-LIMITS F1–F6, F8; EU AI Act
Art. 14), except item 12, which rests on a partial read — see the
note there. Items marked [LAW] are legal duties for high-risk
systems under the EU AI Act; the rest are expert guidance the
sources converge on — adopt them as team policy, not as law. The
line is **propose and evidence (automate) vs decide and execute
(human)**.

1. **Never ship on an AI "clean" or an AI "critical" alone.**
   Every AI verdict needs human confirmation of exploitability
   (reachable code + a real exploit path or a deterministic failing
   test); every AI "no findings" needs a human to confirm the scope
   actually reviewed.
2. **Never let an AI severity label decide priority or blocking.**
   A human re-grades severity from impact + reachability.
3. **Never treat agreement between two AI models as verification.**
   Verification is a quoted code location plus a human-confirmed
   exploit path.
4. **Never auto-merge, auto-deploy, auto-publish, or auto-apply a
   security fix.** High-impact / irreversible actions need human
   approval.
5. **Never give build/judge agents standing write access to
   production, secrets, or other users' data.** Least privilege,
   user-context execution, complete mediation in the downstream
   system — not in a prompt.
6. **Never let an agent act on untrusted content without a human
   gate.** Injected instructions must not be able to approve their
   own actions.
7. **Never auto-close, auto-suppress, or auto-dismiss a security
   finding.** A human decides "not a vulnerability" and records
   why.
8. **Business-logic and access-control judgements are human-owned.**
   AI false positives are worst here and chaining matters most.
9. **A human must be able to understand, monitor, interpret,
   refuse/override/reverse, and STOP the AI system at any time.**
   [LAW] A stop control that only logs, or an "approve" button
   that is the only option, does not meet this.
10. **A human must stay aware of automation bias — by design, not
    by reminder.** Process must force independent human judgement
    (evidence first, verdict second; second reviewer for
    high-severity; no confidence score without evidence).
    [LAW, Art. 14(4)(b)]
11. **Red-team / pentest sign-off is human-owned and version-bound.**
    "Red-teamed" without who, what access, which version, how
    judged, which attack families, and what decision it informed
    is not evidence. Re-run after material changes; a clean run
    never certifies safety.
12. **Threat-model sign-off is human-owned.** LLM threat models
    are drafts; the human owns the final model. (W-LIMITS F9 —
    MDPI threat-modelling study read in part only: abstract,
    introduction, methodology; results/discussion CHƯA ĐỌC. No
    per-model accuracy numbers from that study are cited.)
13. **Secrets / PII / credentials decisions are human-owned.** Any
    finding involving a key, token, password, or personal data must
    be human-confirmed before any disclosure, rotation, or "safe
    to ship" call. (Policy inference from OWASP human-approval
    logic and EU AI Act override duty — no source read in full
    states a secrets-specific human rule in these words; flagged
    as inference, not a quoted expert rule.)
14. **Rollback and audit trail for every automated change.** Any
    AI-proposed change that executes must be logged (who approved,
    what exactly was approved, what ran) and reversible.

**What MAY be automated:** first-pass triage and drafting,
correlation of large alert/code volumes, generating candidate
findings with quoted code, running deterministic checks
(SAST/DAST/IAST, secret scanners, dependency scans, tests), and
preparing the evidence pack for the human.

**Explicit non-checks (do NOT count as passing the gate):** "The
builder was told to write secure code"; "A newer/bigger model
wrote it"; "One LLM review pass found nothing"; "Copilot / the
assistant's own review approved it"; "The in-loop scanner was
green during generation" without the independent post-build
re-run. (W-APPSEC.)

---

## Tooling named by the sources

Tools are listed only where a source named them. Status follows
the worker that reported them; see
`research/security-ai/workers/w-*.md` (workspace research notes, not shipped in this repo) for read status per tool.
(Synthesis §7.)

| Purpose | Tools / commands | Notes |
|---|---|---|
| SAST (deterministic) | Semgrep (+ Guardian in-loop scanning), SonarQube, Checkmarx Developer Assist (enterprise-licensed), Wiz AI SAST (open failed, 429 — CHƯA ĐỌC) | Semgrep Guardian and Sonar docs read in full; Checkmarx docs snippet-only |
| Secrets | gitleaks (v8.30.1), TruffleHog (v3.99.3), GitHub push protection | Three layers: pre-commit → push protection → CI as the required check |
| Supply chain | `npm audit`, `npm audit signatures`, `npm ci`, `syft`, `cyclonedx-cli validate`, ORT, `osv-scanner`, `grype`, `cosign` | `npm ci` from a hash-pinned lockfile; SBOM from the final built artifact |
| Licence | `license-checker-rseki`, ScanCode, ORT (Analyzer → Downloader → Scanner → Advisor → Evaluator → Reporter) | Deny-by-default allowlist; ground truth = real LICENSE files |
| Prompt-injection defence / red-teaming | PyRIT (Microsoft), Prompt Shields (Azure AI Content Safety), garak, OWASP GenAI Red Teaming Guide/Manual | Prompt Shields is a classifier gate with honest limits; no defence is a guarantee. (PyRIT and Prompt Shields: SNIPPET/SECONDARY only — W-BIGTECH F15/F16; Microsoft Learn AI Red Teaming Agent page CHƯA ĐỌC, 429; re-verify before the kit depends on PyRIT commands or Foundry eval categories.) |
| Provenance (images) | C2PA Content Credentials / `c2patool` (docs CHƯA ĐỌC), SynthID, reverse-image search (Google Lens / TinEye) | Absence of a signal proves nothing |
| AI-assisted review (triage only) | LLM semantic review, Snyk Evo agentic AppSec, GitHub Copilot code review / Autofix | Triage layer only; never the gate; every AI-suggested fix re-scanned |
| Governance | NIST AI RMF Playbook, SAIF self-assessment, ORT Evaluator, OSADL licence-compatibility matrix | NIST names methods and evidence types, not tools |

---

## Deliberately excluded / NOT verified — do not re-add without verification

- **OWASP LLM edition (2025 vs 2026) — RESOLVED 2026-11-11, PIN
  2026.** Verified against the primary (OWASP GenAI Security
  Project resource page + press release 2026-09-02 + repo
  `2026/final/` file listing + Preface + LLM08 entry, all read
  2026-11-11; see
  `research/security-ai/owasp-asvs-verification.md` §1 — workspace research note, not shipped in this repo). This
  checklist now cites the 2026 edition, released 3–4 August 2026
  (resource page 3 Aug, PDF cover 4 Aug), announced 1–2 September
  2026; Scanverra's "2025 is still current" is contradicted by
  the primary and discarded. Every LLM ID in this file carries the
  year suffix. Honest boundary: the full 122-page PDF could not
  be text-extracted (download 403); the order rests on the repo
  structure + Preface + LLM08 + unanimous secondaries. OWASP Top
  10 web 2025 pages were likewise not read in full
  (secondary-sourced).
- **ASVS 5.0 as the pass/fail checklist layer — ADOPTED
  2026-11-11 (ASVS 5.0.0, Levels 1–2). Status: PARTIAL — V1 and V3 read in full (verification 2026-11-11); V5/V6 sampled; V7–V17 unread. L1 floor / L2 for auth/PII/money/secrets; cite IDs as `v5.0.0-x.y.z`.** Verified against the
  primary (levels + assessment chapters and V1/V3 read in full;
  see `research/security-ai/owasp-asvs-verification.md` §2 — workspace research note, not shipped in this repo). The
  intended shape, confirmed by the primary itself: Top 10 for
  prioritisation → ASVS 5.0 L1/L2 as the checklist → Cheat Sheets
  for the fix → WSTG/ZAP for testing. ASVS requirement IDs are
  now cited on the deterministic checks they map to (checks
  1.2–1.5, 1.8), written as `v5.0.0-x.y.z`. Caveats: never claim
  "ASVS certified"; automation alone is insufficient per the
  standard itself; ASVS covers the web surface, not LLM risks —
  pair with LLM Top 10 2026; non-applicable requirements are
  recorded N/A with rationale. V2/V13/V15/V16 requirements are
  NOT INCLUDED — not read in full; the checklist build must read
  them first.
- **ASI IDs (OWASP Agentic Top 10) — NOT re-verified.** The ASI
  citations in this file (ASI01/ASI02/ASI03/ASI05/ASI07) were not
  verified in the 2026-11-11 verification task; verify the
  Agentic Top 10 from its primary before citing ASI IDs as
  settled. **No BLOCK (or PAUSE/WARN) verdict in this file rests on an ASI ID:** every verdict rests on the accompanying verified anchor (LLM Top 10 2026, ASVS 5.0.0, Willison trifecta, Beurer-Kellner patterns, dual-LLM/quarantine, Google human confirmation, or the check's own stated rule); ASI IDs are cross-reference hints only.
- **Snippet-only items — NOT verified, do not present as
  verified:**
  - The licence-compatibility pairs in check 4.5 (GPL-2.0-only +
    Apache-2.0, GPL-3.0 + GPL-2.0-only, AGPL + proprietary SaaS) —
    search snippet only; verify against the OSADL matrix / ORT
    Evaluator before freezing the gate.
  - The client-bundle secret rule in §2 C7 of the synthesis
    (the `NEXT_PUBLIC_` / `VITE_` / `REACT_APP_` rule) —
    secondary-sourced (BattaTech playbook, SNIPPET-ONLY); not
    verified against Next.js/Vite docs. Verify before writing it
    as a BLOCK rule. (Check 1.1 covers secrets in the bundle
    generally; the framework-prefix rule itself is not in this
    file.)
  - EchoLeak CVE-2025-32711 (CVSS 9.3) — secondary-sourced;
    CVE record not read. Verify against NVD before citing as
    established. (Carried in the Key numbers box with that caveat,
    not as a check.)
- **§8 gaps — no tool verified, do not claim one exists:**
  - No general-purpose ToS checker was verified (synthesis §8.2).
    ToS compliance is a per-service manual registry + allowlist
    problem; the automatable part is a declared-service registry
    plus deterministic flags (check 4.10).
  - No free deterministic code-regurgitation scanner was verified
    (synthesis §8.3). Minimum is builder provenance attestation
    per file + human review (check 4.7).
  - No big-tech vendor publishes a copyright or ToS checklist for
    frontend code (synthesis §8.4). Those two limbs rest on the
    user's order, the US Copyright Office guidance (primary
    CHƯA ĐỌC; secondary summaries read), and the supply-chain
    worker's licence findings — not on a vendor anchor.
  - Bundle leakage unmeasured (synthesis §8.8): no source measured
    secret/sourcemap leakage in the built frontend bundle directly;
    check 2.1 is an implication, labelled as such, not a measured
    finding.
  - 429-blocked and partial reads carried forward (synthesis
    §8.5–§8.6): Wiz AI SAST page, Anthropic Zero Trust eBook PDF,
    Microsoft Learn AI Red Teaming Agent page, MDPI
    threat-modelling results section, and others are CHƯA ĐỌC;
    nothing from them is asserted in this file. USENIX 2025
    slopsquatting paper: abstract + introduction only. Veracode
    full report PDF: not opened (summary + press release read in
    full). NIST AI 600-1 MAP/MANAGE tables + Appendix A, AI RMF
    Table 4, CSF 2.0 full text, SP 800-218A primary: CHƯA ĐỌC or
    secondary-sourced. Greshake et al. 2023, Spotlighting,
    Beurer-Kellner et al., CaMeL: cited via read secondaries,
    primaries CHƯA ĐỌC. CSP Cheat Sheet (DeepWiki summary only),
    Secrets Management Cheat Sheet (not opened), C2 Proactive
    Controls + Developer Guide (search-result text only); ASVS
    5.0 chapters outside V1/V3 (V2/V4–V17 not read in full —
    the levels/assessment chapters and V1/V3 were read in full
    2026-11-11, see verification §2), WSTG, Code Review Guide
    v2, GenAI Red Teaming Guide/Manual (not read in full);
    Modulos ASI06–ASI10 mitigations (summary table only).
  - AI RMF is being revised (synthesis §8.7): under the July 2025
    AI Action Plan; no draft published as of 30 Oct 2026; EO 14110
    was revoked Jan 2025 while AI 600-1 and SP 800-218A remain
    published. Re-check the RMF revision before treating any NIST
    wording as settled.
  - SP 1353 (draft, CHƯA ĐỌC primary): AI-generated CSF analysis
    must be human-reviewed before it drives decisions — directly
    applicable: an AI checker may not self-approve.
