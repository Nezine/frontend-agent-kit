---
name: demo-rehearsal
description: "Demo-day rehearsal for a 5-hour hackathon build: the kill-and-reopen rehearsal script (the 40-point move), the failure drills with switch-lines, the 5-minute pitch timing weighted to the judging criteria, phone discipline, and the 30/15/5-minute demo-day checks. Use when the team rehearses the real-phone demo, from feature freeze (14:20) to the pitch (16:15). Zero setup — a read-only runbook the humans walk through by hand. It never grades UI and never replaces the kit's gate/judge loop."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs one real Android phone with the preview build installed, a second phone (backup) if available, and the backup recording cued. No software to install, no accounts, no cost.
metadata:
  version: "0.1.0"
---

# demo-rehearsal — kill, reopen, pitch

You are the QC agent (role D) for a 5-hour hackathon build: Expo SDK 58,
preview APK demo on one real Android phone, 5-minute pitches from 16:15.
Scoring: 40 points real-phone AI demo (kill + reopen, main AI flow live;
browser/emulator/photo/video = 0), 35 points real user problem with
evidence, 25 points market expansion. Your job is rehearsal, not building:
make the kill-and-reopen move and the failure switch muscle memory before
the pitch. Agents stop building at 15:30; after that, humans lead and you
assist only as directed.

## 0. Pins — read first, never drift

- The rule that decides everything: ask of every bug — if it showed up
  during the demo, would it embarrass us? If yes, test it. If no, skip it.
  Source: HackMIT-playbook-based skill, hackathon-testing —
  https://github.com/andomo3/flecto-shade/blob/HEAD/.claude/skills/hackathon-testing/SKILL.md
  (MIT, read 2026-11-13). The same skill supplies the 10-minute manual
  checklist, the bug triage (P0–P3), the demo-day test (30/15/5 minutes
  before presenting), the backup ladder, and the `?demo=1` kill switch.
- Five-minute pitch structure (200+ hackathons as contestants,
  organisers, mentors and judges): 0:00–0:30 problem, 0:30–1:00 solution,
  1:00–2:30 demo, 2:30–3:15 value + evidence, 3:15–4:00 execution,
  4:00–4:30 next steps, 4:30–5:00 conclusion + buffer; 5–7 slides max.
  Source: https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure
  (publish date not confirmed — the page fetch 2026-11-13 returned no
  date; read 2026-11-13).
- The demo in this event is extended to 2:15 (~45% of the pitch) because
  it carries 40 of 100 points — a deliberate deviation from HackTribe's
  generic 1:30, stated in the research brief below.
  Source: `research/testing-deep-20261113.md` section 6 (in-repo research
  brief, accessed 2026-11-13).
- Contingency cards, the "switch IS the recovery" rule, and the
  config-only-after-last-dry-run rule; backup-video practice (record
  1–3 minutes, upload unlisted, confirm it plays for someone else, keep
  it open in a tab, simulate the failure in rehearsal).
  Sources: permitflow dry-run checklist and 30-Days-of-Hackathon Day 24,
  both cited in `research/testing-deep-20261113.md` sections 7–8
  (accessed 2026-11-13 by that brief's author; not re-opened in this
  pass — see section 7).
- SDK 58 = React Native 0.88, `expo@^58.0.0`. Expo Go for SDK 58 "will
  be released within a few weeks" — store Expo Go does NOT yet support
  SDK 58, so the demo-day path is a preview/dev build (APK sideload).
  Source: https://expo.dev/changelog/sdk-58 (read 2026-11-13).

## 1. The kill-and-reopen rehearsal script (the 40-point move)

The scoring test: close the app fully, reopen it on a real phone, the
main AI flow runs live. Run this script twice at 14:20–15:00, and once
more at 15:30–15:45. Two consecutive clean runs = rehearsal passed.

1. Phone in hand, app open on the AI result screen from the previous
   run. Presenter says the result out loud (so the judges hear it
   before the kill).
2. Swipe the app away (full kill — not home-button minimise). Wait
   5 seconds. (Rehearsal target, not a sourced requirement.)
3. Reopen the app. Start a stopwatch.
4. Check, in order: (a) app launches without a red error screen;
   (b) the saved state is there (the previous result / share-link
   state survived); (c) tap the AI action with the demo input;
   (d) the AI result streams/arrives within the rehearsed time
   (write the number down — if it took 8s in rehearsal, say "about
   ten seconds" on stage, never "instant"); (e) the result is correct
   and useful for the demo input.
5. Log the run in `templates/kill-reopen-log.md`: time to launch,
   time to AI result, any glitch — one line per run.
6. Then rehearse the failure: on the third run, deliberately kill the
   network mid-stream (or use the kill switch, section 4) and run the
   switch to the backup recording. Target: under 15 seconds from the
   presenter's line to the video playing. (Rehearsal target, not a
   sourced requirement.)

Phone discipline for the rehearsal and the pitch: Do Not Disturb on;
notifications silenced; auto-lock set to Never; brightness up; battery
saver off; charger plugged in until the moment of the pitch; the phone's
own mobile data on as backup (verify the AI endpoint over mobile data,
not just venue Wi-Fi); both phones loaded with the same build where
possible.

## 2. The 5-minute pitch (weighted to the criteria)

| Time | Focus | What the judges must understand | Criterion |
| --- | --- | --- | --- |
| 0:00–0:30 | Problem + hook | Who has the problem, when it occurs, why it matters | 35 — problem |
| 0:30–0:55 | Solution | What you built and how it addresses the problem, in one sentence | 35 — AI helps directly |
| 0:55–3:10 | Live demo (2:15, ~45%) | One complete user journey: starting situation → the AI action → the result → why it matters | 40 — demo |
| 3:10–3:50 | Value + evidence | Why it is useful and what supports the assumptions (one credible statistic or observation — never an invented number) | 35 — evidence |
| 3:50–4:20 | Execution + differentiation | What you built during the hackathon, what makes the approach relevant, one simple architecture diagram | Supports 40 + 35 |
| 4:20–4:40 | Next steps | What needs to happen to test or implement it (2–3 realistic steps) | 25 — first users + global path |
| 4:40–5:00 | Conclusion + buffer | The one idea judges should remember, with time for a safe finish | — |

Rules: 5–7 slides max, one core idea per slide, deck is a visual aid
not a document; do not spend the opening seconds on an agenda slide; do
not present every feature — one user journey; be precise about what was
validated vs what remains an assumption; do not hide obvious limitations;
end with one clear sentence, never "that's it" or an apology about time.
Roles: presenter (owns the clock and the words, holds the visible
timer); phone holder (holds the real phone, does the taps, kills and
reopens); tech standby (laptop open, backup video cued in a tab,
screenshots folder open — speaks only to execute a switch, never debugs
on stage). Agents do nothing live during the pitch.

Q&A prep (short answers ready): How do you know this is a real problem?
Who is the primary user? What did you build during the hackathon? Which
part is functional? What is technically difficult or innovative? How is
this different from existing solutions? What is the biggest untested
assumption? What would you do with another month? What data, partners or
resources would implementation require? What are the main risks or
limitations?

## 3. Failure drills — the contingency table

Never improvise recovery on stage — the switch IS the recovery. Print
these cards and tape them to the back of the laptop, in order.

| # | Failure | Symptom (<5s) | Fallback (the switch) | Switch-line (say it, then switch) |
| --- | --- | --- | --- | --- |
| F1 | Venue Wi-Fi dies / Metro unreachable | Loading spinner >5s, or "couldn't load" | Preview build (bundled JS) if it exists; else phone mobile data + tunnel URL; else recording | "The venue Wi-Fi is having a moment — same app, on mobile data." |
| F2 | AI endpoint slow / down | AI action spins >10s or returns an error | Kill switch `?demo=1` — serves the cached golden response (a real recorded AI output, never invented) | "Let me show you the recorded version — same system, same data." |
| F3 | AI returns a wrong / nonsensical result | Result visibly off-topic or garbled | Do NOT re-run live. Narrate the cached golden result from the backup video/screenshots | "That one came back wrong live — here's the run we recorded an hour ago on the same input." |
| F4 | App crashes / white screen on kill + reopen | Red error screen or blank after reopen | Close, reopen once (max 5s). If still dead: backup video immediately | "Real demos are messy. Here's the version we recorded earlier." |
| F5 | Expo Go fails / SDK mismatch | "Could not load" / version error | Dev/preview build on the same phone if installed; else backup phone; else recording | "Same app, second phone — let me hand it over." |
| F6 | Phone battery / phone dies | Phone off or <5% mid-pitch | Backup phone (fully charged, same demo input pre-loaded) | "Battery's gone — the backup phone has the same build." |
| F7 | Projector / display fails | No image on the room screen | Present from the phone itself; or the laptop screen as the display | "The projector's out — I'll show you on the phone itself." |
| F8 | Pitch lead freezes / loses the thread | Silence >3s | Second human picks up the next scripted line (every line has an owner + a backup owner) | (No line needed — the handover is the recovery.) |

## 4. The kill switch, precisely

A `?demo=1` parameter or a "load sample data" button that bypasses
flaky third-party calls with local fixtures. Rules: (1) the fixture is
a real recorded response from the same backend on the demo input,
captured during rehearsal — never hand-written; (2) the switch is
visible to the team only, not a user-facing feature to demo; (3) the
presenter says what it is ("the recorded version") — never passes a
recording off as live. The one time a recording is presented as live,
the team's credibility on the evidence criterion is gone.

## 5. The demo-day test (30 / 15 / 5 minutes before the pitch)

Counted back from the 16:15 pitch (not from submission). That puts them
at 15:45 / 16:00 / 16:10; the 15-minute check coincides with the 16:00
submission, so do the submission first, then the check.

- **15:45 (30 min before):** run from a clean state (fresh kill +
  reopen), check every feature in the demo script, verify persistence,
  check error handling, test on the demo phone (not the laptop).
  Confirm the slot length against the program brief.
- **16:00 (15 min before; after submission):** clear the cache, close
  unrelated tabs, check the network, prepare the offline fallback
  (kill switch + cached response), load the demo data, confirm the
  backup video plays (open in a tab, tested), charger plugged in.
- **16:10 (5 min before):** breathe, review the script, confirm the
  backup, test audio and video, open every tab, timer visible to the
  presenter. Demo data seeded and loaded so judges see a populated
  product, never an empty state.

## 6. Bug triage (decide in seconds, not minutes)

| Priority | What | Do |
| --- | --- | --- |
| P0 | Crashes, data loss, security, auth completely broken | Fix now |
| P1 | Main feature broken, obvious visual glitch, broken navigation, wrong data shown | Fix before the demo |
| P2 | Minor UI, edge cases, slow, inconsistent styling | Fix if time permits |
| P3 | Cosmetic, rare, non-demo features | Work around or ignore |

Fix-or-workaround rule: 5 minutes to fix, fix it; 2 hours, work around
it; can the demo avoid the code path? Skip it. Acceptable workarounds:
hardcode a value, pre-populate, disable the broken feature, mock the
data, redirect to the working page. Freeze rule: during 14:20–15:00
only top-2 fixes are allowed, each a single small change re-verified by
a kill-and-reopen run. After the last dry run (15:30–15:45), no code
changes at all — only config / staging / cache fixes. During the pitch:
no fixes of any kind — the switch is the recovery.

## 7. File map

| File | What it is |
| --- | --- |
| `SKILL.md` (this file) | Rehearsal script, pitch timing, failure drills, kill switch, demo-day checks, triage. |
| `templates/kill-reopen-log.md` | One line per rehearsal run: launch time, AI-result time, glitches. |

## 8. Verification status (read 2026-11-13)

- The HackMIT skill (checklist, triage, demo-day test, backup ladder,
  kill switch) and the HackTribe pitch structure were read in full from
  their primary sources today (section 0). The 2:15 demo extension, the
  failure-drill table, and the kill-switch rules are synthesized from
  `research/testing-deep-20261113.md` (in-repo research brief, accessed
  2026-11-13) — read it for the full reasoning, do not copy it verbatim.
- The permitflow contingency-cards source, the 30-Days-of-Hackathon Day
  24 backup-video source, the AngelHack demo tips, and the SimpleAI
  disaster-recovery source were NOT re-opened in this pass; they are
  cited here through the research brief (accessed 2026-11-13 by that
  brief's author). Treat their details as second-hand until re-read.
- This skill was cross-checked against the mobile-kit's
  `runbook-build-day.md`: no duplication — the runbook has the timeline
  and the Expo Go smoke test, but no kill-and-reopen script, no failure
  drills, no pitch timing, and no demo-day 30/15/5 checks. This skill
  adds exactly those.
- Nothing here was run on the event setup — the rehearsal IS the test.
  The first real run happens on the demo phone at 14:20 on build day.
- CHƯA ĐỌC: whether Q&A is included in the 5 minutes or separate (if
  inside the 5, cut the demo to 1:00 and the execution section to 0:30);
  venue specifics (projector/cable type, Wi-Fi reliability, stage vs
  table pitch); which phone is primary at pitch time.
- Coordinator check 2026-11-13: HackMIT skill license MIT confirmed via
  GitHub API (repo `andomo3/flecto-shade`). The HackTribe article's
  publish date (2026-08-24 as cited in §0) was NOT confirmed — the page
  fetch returned no date; treat the date as CHƯA ĐỌC.
