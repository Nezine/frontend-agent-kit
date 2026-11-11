# coord/CROSSCHECK.md — cross-check checklist (coordinator-owned)

> **Status: SEED ONLY — NOT YET BINDING.** The checklist below is the seed
> from the v2 design (§13). **The FULL checklist is PENDING the gen-11 build
> from the security-AI swarm synthesis (`research/security-ai/SYNTHESIS.md` — workspace research note, not shipped in this repo; delivered, with `workers/` and three QC verdicts alongside it).**
> This checklist becomes binding only after an independent red team verifies
> it (checking it for completeness and correctness, not just the findings).
> Until then, no land/ship may cite this file as a complete check.
> The cross-check team proposes changes to this file; the coordinator records
> them. The cross-check stage itself is mandatory, on the same level as the
> deterministic gate — it is not open to removal.

## Who runs it

Independent agents, never the builder of the slice, never the design judge
for that slice, and never an agent with production history of the slice. The
coordinator summons the cross-checkers as its own subagents on its own
machine. Per pre-land check, one fresh-context cross-checker runs the full
checklist; per pre-ship check, the team runs as two agents (one for
security/data-leaks, one for ToS/copyright) and consolidates into one report.

## Where it runs in the loop (before merge/ship, not after)

1. **Pre-land, per slice:** after the deterministic gate, before the judge
   grade — on the merged tree in the trial worktree. The land requires gate
   green AND cross-check clear.
2. **Pre-ship, once:** on the shipping version (the mainline tip at stop),
   before the human-gate packet is prepared.

## Checklist (seed — the floor, not the ceiling)

- **(a) Web/app SECURITY:** XSS, injection (SQL/command/template),
  secrets/keys/tokens left in code, insecure dependencies (known-vulnerable
  versions), auth/session flaws (broken auth, session fixation, missing CSRF
  where state changes, insecure cookies).
- **(b) DATA LEAKS:** PII, credentials, or private data leaking into output,
  code, logs, screenshots, or shipped files (including the Figma export and
  the human-gate packet).
- **(c) TERMS OF SERVICE compliance:** third-party services, APIs, scraping,
  and embedded content used within their terms (rate limits, attribution
  requirements, no scraping where forbidden, API keys used only for their
  permitted purpose).
- **(d) COPYRIGHT:** images, fonts, code, copied content, and prompts must
  not ship copyrighted material without a licence. The kit's existing
  precedent — "cite only, never copy the PDF" — is generalized: the default
  is citation (link + attribution); copying is the exception and requires a
  licence. Stock assets, fonts, and code snippets are checked against their
  licences; AI-generated content is checked against the model's terms.
- **(e) "Và nhiều nữa" (and much more):** the team itself defines its full
  checklist beyond (a)–(d) — the seed above is the floor, not the ceiling.

## What blocks vs warns

- **SEVERE = hard block.** No landing, no ship. The slice goes to
  `input-required` with the report linked; the owning agent fixes and
  re-claims; the fix is re-checked by a fresh cross-check run. The
  coordinator can NEVER waive a SEVERE — only the human, on return, can
  override one, and the override is recorded in the run log with the human's
  name.
- **WARNING = fix or waive-with-reason.** The warning must be fixed, or the
  coordinator waives it with a written reason in the run log (accepted risk,
  named, dated). A waived warning is still visible in the pre-ship report.
- **OK = clear.** Recorded in the run log; the land/ship proceeds.

## How it reports

Each check produces a report at `coord/crosscheck/<slice-id>-<n>.md`
(coordinator-owned directory; the cross-check agent writes there as the
coordinator's subagent). The pre-ship report covers the shipping version,
which has no slice id — it is filed as `coord/crosscheck/ship-<n>.md`.
Findings carry severity + evidence (file:line, what, why, suggested fix).
The coordinator transcribes the verdict (SEVERE count, WARNING count, OK)
into the run log before landing. The pre-ship report is attached to the
human-gate packet.
