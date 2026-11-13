# Testing / demo rehearsal — deep implementation brief for the muse-fleet 5-hour build

- **Context:** Codex Community Hackathon Hanoi, Sat 14/11/2026, build 11:00–16:00 (5h), pitches 16:15 (5 min/team), submission 16:00. Mobile app, AI ESSENTIAL. Demo phone: 1 Android phone (model/OS TBD); iPhone 11 Pro Max as backup. Stack: Expo + React Native + TypeScript SDK 57, Convex primary / Supabase fallback. Roles: A Integrator (Muse), B Frontend, C Backend/AI, D QC + red team + evidence (owns the demo script, rehearsal, backup recording).
- **Scoring (via the goal file, which records the 12/11 check of the official Lu.ma page — Lu.ma not re-opened in this pass):** 40/20/0 real-phone AI demo (kill + reopen, main AI flow live; browser/emulator/photo/video = 0); 35/18/0 real user problem WITH evidence; 25/13/0 market expansion (first users + global path). Tiebreak 1→2→3.
- **Date accessed:** 2026-11-13. Expo docs are cited through the 12/11 mobile report, not re-opened in this pass (see §12).
- **Labels:** OFFICIAL = vendor/primary docs; THIRD-PARTY = everything else. SYNTHESIS = my judgement built on the cited sources, labelled as such. Nothing here was tested by us on the event setup — the rehearsal is the test.

## 0. The verdict (read this first)

| Decision | Recommendation | Why (one line) |
|---|---|---|
| What testing means in 5h | **Confidence, not coverage** — test only what would embarrass the team if it broke on stage | The HackMIT rule that decides everything (see §1) |
| Test pyramid, compressed | Manual demo flow (most) → 1 Maestro E2E flow → API contract checks → unit tests only for critical logic | A full 70/20/10 pyramid does not fit 5 hours; the top two rungs carry the demo |
| E2E tool | **Maestro** (YAML, minutes to set up, no code changes) — Detox only if the team already knows it | Detox needs a native build + hours of setup first time; Maestro runs against Expo Go via the dev-URL workaround and against dev builds by appId |
| Demo path for the pitch | **Preview build, kicked off by 13:30 at the latest from green main** (bundled JS, no Metro dependency); if it is not back by 15:00, Expo Go + tunnel with the laptop on charger, never asleep | A free-tier EAS build started mid-window can still be queued at 16:00 — the preview build must be started early, never attempted at 14:20 |
| Backup | **60–90s recording of the golden path, first recorded ~14:00, re-recorded ~14:45, hosted online + on the laptop + 3–5 screenshots + kill switch `?demo=1`** | The ladder is primary → backup → recording + screenshots; never improvise recovery on stage |
| Pitch shape | 5 min: 0:30 problem → 0:25 solution → **2:15 demo (~45% of the pitch)** → 0:40 evidence → 0:30 execution → 0:20 next steps → 0:20 close/buffer | The demo is 40 points, so it gets nearly half the pitch — extended from HackTribe's generic 1:30 (see §6) |
| Rehearsal | **Kill-and-reopen rehearsed twice minimum, plus one full failure drill** (live demo "crashes", switch to recording) | The switch, not the fix, is the recovery — it must be muscle memory |

## 1. What to test and what to skip (the HackMIT rule)

**The rule that decides everything:** ask of every bug — *if this showed up during the demo, would it embarrass us?* If yes, test it. If no, skip it. That one question replaces every debate about coverage. (THIRD-PARTY — HackMIT-playbook-based skill: https://github.com/andomo3/flecto-shade/blob/HEAD/.claude/skills/hackathon-testing/SKILL.md, accessed 2026-11-13)

**Always test:** the happy path through the main AI feature; that saved state survives a kill + reopen; the error states when the AI endpoint is down or the input is bad; and the exact demo flow, end to end, repeatedly. (Same source.)

**Usually skip:** edge cases under 1%, browsers beyond the demo phone, performance unless visibly slow, deep accessibility, pixel-perfect mobile, internationalisation, comprehensive logging. (Same source.)

**The compressed pyramid for 5 hours** (adapted from the standard 70% unit / 20% integration / 10% E2E split — THIRD-PARTY: https://www.drizz.dev/post/how-to-test-react-native-apps-best-testing-frameworks, accessed 2026-11-13):

| Rung | What | When | Tool |
|---|---|---|---|
| 1 — Manual demo flow | A human (D) taps the exact demo script on the real phone, after every significant change | Continuously from Slice 0 | Hands + phone + the 10-minute checklist (§2) |
| 2 — One E2E flow | The golden path as a Maestro YAML flow, run against the dev build / Expo Go | From Slice 1 green; re-run at freeze | Maestro (§3) |
| 3 — API contract checks | The one AI endpoint returns the exact JSON shape the app parses; health endpoint answers | Every merge | 10-minute smoke script (§2) |
| 4 — Unit, critical logic only | Input parsing, output-schema validation, timeout/failure handling | Only if a bug is found there | Jest |

Most hackathon projects need only the top two rungs. (THIRD-PARTY — HackMIT skill, above.)

**Bug triage (decide in seconds, not minutes):** P0 crashes / data loss / security / auth completely broken → fix now. P1 main feature broken, obvious visual glitch, broken navigation, wrong data shown → fix before the demo. P2 minor UI, edge cases, slow, inconsistent styling → fix if time permits. P3 cosmetic, rare, non-demo features → work around or ignore. Fix-or-workaround rule: 5 minutes to fix, fix it; 2 hours, work around it; can the demo avoid the code path? Skip it. Acceptable workarounds: hardcode a value, pre-populate, disable the broken feature, mock the data, redirect to the working page. Sometimes shipping with a known, documented, minor bug is the right call, because fixing it risks worse. (THIRD-PARTY — HackMIT skill, above.)

## 2. The 10-minute manual checklist + smoke script

Run the checklist after every significant change, not once at the end. (THIRD-PARTY — HackMIT skill, above.)

**Checklist (adapted to this stack — no auth in the demo, so the auth lines are replaced by the share-link/persistence lines):**
- Core: the AI action works end to end; create/read/list of demo items; required-field validation (empty input, very long input, special characters).
- Data: what was saved is still there after a kill + reopen (share-link state).
- UI: no console errors, no broken images, forms submit, loading states show, the AI streaming indicator shows and can be cancelled (requirement from the mobile report — §4 interaction rules: latency visible and interruptible; §6.12 abort on navigate-away/background — not from the HackMIT checklist).
- Edge: empty state, one item, many items, double-tap, back button, refresh mid-action, Wi-Fi off (the offline message must appear, never a blank screen), phone rotated, app backgrounded mid-stream (the request must abort, not keep billing — mobile report §6.12).
- Then the **"break your own app" session, 30 minutes** (once, at ~14:00): click everything twice, submit empty forms, go backwards, clear storage, resize, turn Wi-Fi off, watch the console. And the **buddy test, 15 minutes**: swap with another human for fifteen minutes and let fresh eyes find what yours cannot. (THIRD-PARTY — HackMIT skill, above.)

**Smoke script (10 minutes, pays for itself — write it before major changes and before demo day, run it when tired):** one script that hits the health endpoint and the one AI call and asserts the response shape ("is the result field a non-empty string"). The API contract check catches the mismatch that renders everything as undefined. Skip automation when behind schedule, when the feature is trivial, or when the test would be harder than the code. (THIRD-PARTY — HackMIT skill, above.)

**Demo data doctrine:** "Test user 1" and lorem ipsum say the project was built twenty minutes ago. Write a seed script that is idempotent, uses specific names, varied statuses and recent dates, real relationships between records, and five to ten records per collection — enough to show it works with multiple items, not so many that a judge scrolls forever. (THIRD-PARTY — HackMIT skill, above.) SYNTHESIS: give the demo a named persona (a real-sounding person with a real situation), not "Demo User". The judges must meet a person, not a placeholder.

## 3. E2E: Maestro, not Detox, in 5 hours

**Maestro** is YAML-based mobile E2E: human-readable flows, no code changes to the app, runs against Expo Go, dev builds, and EAS builds; Expo officially documents Maestro on EAS Workflows with a `.maestro/` convention. Setup takes minutes; flows are readable by non-developers; it handles waiting for async UI. (THIRD-PARTY: https://github.com/lukedj78/dev-flow/blob/HEAD/rn-write-tests/references/maestro.md; https://reactnative.codeguides.io/testing/maestro-e2e/; https://momentic.ai/blog/expo-react-native-end-to-end-testing — all accessed 2026-11-13.)

**The one trap:** under Expo Go your JS runs inside the Expo container, so `launchApp` with your own `appId` targets an app that isn't installed and the flow fails at line one. The documented workaround is to open the dev URL instead (`openLink: exp://127.0.0.1:19000`) — a smoke check, not a real test. Test a **development build** (a real binary with your `appId`, where `launchApp`, `clearState`, permissions and deep links behave as they will in production). Keep `testID`s in release builds; do not strip them. (THIRD-PARTY — dev-flow maestro.md, above.)

**Detox** is the tighter React Native integration (gray-box: syncs with the RN bridge, waits for animations and network; lowest flakiness ~2% on simulators; 8–12 seconds per flow) — but it requires a configured native build, Detox CLI, and hours of setup the first time, and its docs list official support for React Native 0.77–0.84 while a fresh SDK 57 project is on RN 0.86 (mobile report §1, OFFICIAL docs.expo.dev — SDK 57 = RN 0.86), so compatibility must be checked before adopting it. (THIRD-PARTY: https://www.drizz.dev/post/how-to-test-react-native-apps-best-testing-frameworks; https://codezup.com/automated-testing-in-react-native-guide/ — accessed 2026-11-13.) **Verdict for this team:** Maestro. Detox only if a team member has already run it on RN 0.86.

**The one Maestro flow to write** (`.maestro/demo-golden-path.yaml`): `launchApp` → tap through the demo script's exact taps → assert the AI result is visible → `clearState` → relaunch → assert the saved state is still there (the kill-and-reopen assertion). One user journey per flow; component rendering, hooks, and query logic stay in Jest + RNTL — do not re-test them here. (THIRD-PARTY — dev-flow maestro.md, above.) SYNTHESIS: this flow doubles as the rehearsal script — the same YAML the humans walk through by hand at 15:00. One script, two uses.

**What NOT to build:** large eval suites and full evaluator infrastructure. The right scale is a handful of scripted demo inputs and one rubric, run by hand on a phone. (FLEET-MODE.md §14 — the runbook's own rule.)

## 4. Hour-by-hour test plan (mapped to the FLEET-MODE.md §6 clock)

| Clock | Test activity | Owner | Exit criterion |
|---|---|---|---|
| Before 11:00 (prep) | Phone check: Expo Go installed on the Android phone, opens the starter, kill + reopen once. Backend health endpoint answers. Seed data loads. Backup recording rig tested (screen recorder works). | D + humans | Phone opens the app; kill + reopen works; recording works |
| 11:00–11:20 (T+0:00–0:20, lock & contract) | Write the demo script FIRST (exact taps, before any feature code — FLEET-MODE.md §3). Write the smoke script. Define the demo input (the one input the AI flow will be shown with) and the golden response. | D writes; A freezes | Demo script + smoke script + demo input exist |
| 11:20–12:20 (T+0:20–1:20, Slice 0) | Manual demo flow on the real phone after every merge (checklist §2). Smoke script green. | D | Canned AI result end to end on the real phone |
| 12:20–13:20 (T+1:20–2:20, Slice 1) | Real AI live on the real phone, twice in a row, on the demo input. First Maestro flow written + green. First kill-and-reopen rehearsal. | D grades the live phone run | Live AI flow works twice in a row |
| 13:00–13:30 (T+2:00–2:30) | **Kick off the preview build from the current green main** (EAS free queue 90+ min at peak — never start after 13:30; a build started at 14:00 could still be queued at 16:00). If it is not back by 15:00, the pitch rides on Expo Go + tunnel. | C (build), A (decides) | Preview build queued from green main |
| 13:20–14:20 (T+2:20–3:20, Slice 2 + polish) | 10-minute checklist after every merge. "Break your own app" 30-min session (~14:00). Red-team pass #1 (~14:00, demo-breaker lens). Buddy test 15 min. **Record the first backup video at ~14:00** (when the project is most stable). | D red-teams; humans buddy-test | Second slice merged or cut; main green on a phone; no open P0/P1; first backup video exists |
| 14:20–15:00 (T+3:20–4:00, freeze + harden) | Feature freeze at 14:20. Only top-2 fixes (each a single small change, re-verified by a kill-and-reopen run). Red-team pass #2 (~14:45, "will this survive a live phone demo in front of judges?"). Rehearse the demo script on the phone TWICE. **Re-record the backup video after the second clean run (~14:45)** — this cut is the one that ships. Finalise evidence + share artefacts. | D leads rehearsal | Demo runs clean twice; backup recording exists; punch-list written |
| 15:00–15:30 (T+4:00–4:30, agents stop) | Agents assist only as directed. Humans verify kill-and-reopen on the real phone + rehearse the 5-minute pitch twice, timed. | Humans lead | Frozen build handed over; pitch timed |
| 15:30–15:45 | Final human verify (kill + reopen) + pitch rehearsal, timed. | Humans | Pitch fits 5:00 |
| 15:45 | **Demo-day test, 30-min check** (see §8 — counted back from the 16:15 pitch). | Humans | Clean state, every feature, persistence, error handling, demo phone |
| 16:00 | **Submission + demo-day test, 15-min check** (do the submission first, then the check). | Humans | Submitted artefact; cache cleared, network checked, offline fallback ready, demo data loaded, backup video plays |
| 16:10 | **Demo-day test, 5-min check.** | Humans | Script reviewed, backup confirmed, audio/video tested, every tab open, timer visible |
| 16:15 | Pitches (5 min/team). | Presenting humans | Pitch delivered |

**Checkpoints (FLEET-MODE.md §6):** at T+1:20, T+2:20, T+3:20, A asks: *"If we shipped what we have RIGHT NOW, would it demo?"* If no, A cuts the current slice to its smallest working form on the spot rather than letting the schedule slip.

**Freeze rule, stated precisely:** during the freeze window (14:20–15:00) only top-2 fixes are allowed, each a single small change re-verified by a kill-and-reopen run (FLEET-MODE.md §6). After the last dry run (the 15:30–15:45 human verification), no code changes at all — only config / staging / cache fixes, per the permitflow dry-run rule (that rule comes from a 36-hour hackathon with a hard commit stop at Hour 35; transplanted here it applies only after the last rehearsal, never inside the freeze window). During the pitch itself: no fixes of any kind — the switch is the recovery.

## 5. Kill-and-reopen rehearsal script (the 40-point move)

The scoring test, verbatim from the rules: close the app fully, reopen it on a real phone, the main AI flow runs live. In Expo Go, killing Expo Go and reopening it reloads the app from the still-running Metro dev server — provided the laptop + Metro are alive and reachable. Risks: laptop sleeps, Metro dies, venue Wi-Fi drops. Mitigations: `--tunnel`, keep the laptop on charger, never let it sleep, and rehearse the kill-and-reopen on the real phone (the rehearsal must include it, not just first-open). (Mobile report §2.1, 12/11 — itself THIRD-PARTY-sourced from Expo docs and guides.)

**Script (run it twice at 14:20–15:00, and once more at 15:30–15:45):**

1. Phone in hand, app open on the AI result screen from the previous run. Presenter says the result out loud (so the judges hear it before the kill).
2. Swipe the app away (full kill — not home-button minimise). Wait a few seconds. (SYNTHESIS rehearsal target: 5 seconds — a target, not a sourced requirement.)
3. Reopen the app. Start a stopwatch.
4. Check, in order: (a) app launches without a red error screen; (b) the saved state is there (the previous result / share-link state survived); (c) tap the AI action with the demo input; (d) the AI result streams/arrives within the rehearsed time (write the number down — if it took 8s in rehearsal, say "about ten seconds" on stage, never "instant"); (e) the result is correct and useful for the demo input.
5. Log the run: time to launch, time to AI result, any glitch — in the run log, one line per run. Two consecutive clean runs = rehearsal passed.
6. **Then rehearse the failure:** on the third run, deliberately kill the network mid-stream (or use the kill switch — §7) and run the switch to the backup recording. The switch must be fast (SYNTHESIS target: under 15 seconds from the presenter's line to the video playing).

**Phone discipline for the rehearsal and the pitch (SYNTHESIS from the sources in §6–§7):** Do Not Disturb on; notifications silenced; auto-lock set to Never; brightness up; battery saver off; charger plugged in until the moment of the pitch; the phone's own mobile data on as backup (verify the AI endpoint over mobile data, not just venue Wi-Fi — backend report §5, failure-mode table row 10); both phones loaded — the iPhone carries the same build only if an Apple Developer account exists (see §7 F5/F6 and §11), otherwise it runs Expo Go.

## 6. The 5-minute pitch (weighted to the criteria)

**Structure** (THIRD-PARTY — HackTribe, 200+ hackathons as contestants/organisers/mentors/judges: https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure, accessed 2026-11-13; corroborated by AngelHack: https://angelhack.com/blog/10-tips-to-help-you-rock-your-next-hackathon-demo/):

| Time | Focus | What the judges must understand | Criterion |
|---|---|---|---|
| 0:00–0:30 | Problem + hook | Who has the problem, when it occurs, why it matters | 35 — problem |
| 0:30–0:55 | Solution | What you built and how it addresses the problem, in one sentence | 35 — AI helps directly |
| 0:55–3:10 | **Live demo (2:15, ~45% of the pitch)** | One complete user journey: starting situation → the AI action → the result → why it matters | **40 — demo** |
| 3:10–3:50 | Value + evidence | Why it is useful and what supports the assumptions (one credible statistic or observation — never an invented number) | 35 — evidence |
| 3:50–4:20 | Execution + differentiation | What you built during the hackathon, what makes the approach relevant, one simple architecture diagram | Supports 40 + 35 — proves the work is real |
| 4:20–4:40 | Next steps | What needs to happen to test or implement it (2–3 realistic steps) | 25 — first users + global path |
| 4:40–5:00 | Conclusion + buffer | The one idea judges should remember, with time for a safe finish | — |

**Deliberate deviation from HackTribe, stated plainly:** HackTribe's generic structure gives the demo 1:30 (30% of the pitch). This event's demo criterion is 40 of 100 points, and AngelHack's rule is to keep the demo at roughly half the total runtime and, in a five-minute slot, extend the demo and the next-steps section rather than the introduction. So the demo here is extended to 2:15 (~45%) and the solution, execution, and next-steps sections are compressed. The timetable above sums to exactly 5:00.

**Rules from the same sources:** 5–7 slides max, one core idea per slide, deck is a visual aid not a document; do not spend the opening seconds on an agenda slide; do not present every feature — one user journey; be precise about what was validated vs what remains an assumption; do not hide obvious limitations (a concise, honest answer + a practical next step beats an exaggerated claim); end with one clear sentence, never "that's it" or an apology about time; decide in advance who answers which type of question (user / technology / business / implementation) — the main presenter does not answer everything.

**Demo script — who does what in the 5 minutes (SYNTHESIS from FLEET-MODE.md §1/§11 + the pitch sources):**
- **Presenter (1 human):** owns the clock and the words. Reads the script, narrates the taps, delivers the switch-line if anything fails. Holds the visible timer.
- **Phone holder (1 human, can be the presenter):** holds the real phone, does the taps, kills and reopens the app. Never the person reading the script from a laptop — the phone is the stage.
- **Tech standby (1 human):** laptop open, backup video cued in a tab, screenshots folder open, Metro/dev-server status visible. Speaks only to execute a switch ("switching to the recording") — never debugs on stage.
- **Agents:** nothing live during the pitch. Their job ended at 15:30. (FLEET-MODE.md §6.)

**Q&A prep (from HackTribe):** prepare short answers to: How do you know this is a real problem? Who is the primary user? What did you build during the hackathon? Which part is functional? What is technically difficult or innovative? How is this different from existing solutions? What is the biggest untested assumption? What would you do with another month? What data/partners/resources would implementation require? What are the main risks or limitations?

## 7. Failure drills — the contingency table

**Principle (THIRD-PARTY — contingency-cards practice: https://github.com/hanjing06/permitflow/commit/bdd8e2eb09f43068622297ff3c31270889918a07, accessed 2026-11-13):** print the failure cards, cut them out, tape them to the back of the laptop in order. **Never improvise recovery on stage — the switch IS the recovery.** Rehearse the switch-lines so whichever one is picked sounds natural, not panicked. (The permitflow "fixes are config / staging / cache only, NOT code changes" rule applies only after the last dry run — see the freeze rule in §4. Inside the freeze window, top-2 fixes are authorised by FLEET-MODE.md §6.)

**Principle (THIRD-PARTY — HackMIT skill, above):** the ladder when something dies: primary live URL → backup deploy → the 60–90s recording + screenshots. Acknowledge the failure once, move on, stay calm. (THIRD-PARTY — demo disaster recovery: https://www.simpleai.community/p/demo-script/ — "Don't panic. Don't apologize excessively. One calm sentence.")

| # | Failure | Symptom (how you know in <5s) | Fallback (the switch) | Who acts | Switch-line (say it, then switch) |
|---|---|---|---|---|---|
| F1 | Venue Wi-Fi dies / Metro unreachable | App shows loading spinner >5s, or Expo Go "couldn't load" | Preview build (bundled JS) if it exists; else phone's mobile data + tunnel URL; else recording | Tech standby switches network; presenter keeps talking | "The venue Wi-Fi is having a moment — same app, on mobile data." |
| F2 | AI endpoint slow / down | AI action spins >10s (rehearsed time + margin) or returns an error | Kill switch `?demo=1` / "load sample data" — serves the **cached golden response** (a real recorded AI output from the same backend, never invented) | Tech standby taps the kill switch; presenter narrates the cached result as the recorded run | "Let me show you the recorded version — same system, same data." |
| F3 | AI returns a wrong / nonsensical result live | Result is visibly off-topic or garbled | Do NOT re-run live. Narrate the cached golden result from the backup video/screenshots; note the live miss honestly in Q&A if asked | Presenter moves to the recording; tech standby does not poke at the backend | "That one came back wrong live — here's the run we recorded an hour ago on the same input." |
| F4 | App crashes / white screen on kill + reopen | Red error screen or blank after reopen | Close, reopen once (max 5s). If still dead: backup video immediately; screenshots as the last rung | Tech standby reopens once; presenter switches | "Real demos are messy. Here's the version we recorded earlier." |
| F5 | Expo Go fails / SDK mismatch on the phone | "Could not load" / version error on open | Dev/preview build on the same phone if installed; else iPhone backup — **but only with the same build if an Apple Developer account ($99/yr) + UDID registration exists** (status UNVERIFIED — see §11); without it the iPhone runs Expo Go only, not the same build; else recording | Tech standby hands over the backup phone | "Same app, second phone — let me hand it over." |
| F6 | Phone battery / phone dies | Phone off or <5% mid-pitch | iPhone backup (fully charged, same demo input pre-loaded) — same Apple Developer caveat as F5: without the account it carries Expo Go, not the standalone build | Tech standby hands over the backup phone | "Battery's gone — the backup phone has the same build." |
| F7 | Projector / display fails | No image on the room screen | Present from the phone itself — hold it up, walk the judges through it; or the laptop screen as the display | Presenter adapts; tech standby mirrors the phone to the laptop if the cable works | "The projector's out — I'll show you on the phone itself." |
| F8 | Pitch lead freezes / loses the thread | Silence >3s | Second human picks up the next scripted line (every line has an owner + a backup owner); if the demo is mid-flow, tech standby narrates the taps | Backup presenter takes the line | (No line needed — the handover is the recovery.) |

**The kill switch, precisely (SYNTHESIS, built on the HackMIT `?demo=1` rule):** a `?demo=1` parameter or a "load sample data" button that bypasses flaky third-party calls with local fixtures. Rules: (1) the fixture is a **real recorded response** from the same backend on the demo input, captured during rehearsal — never hand-written; (2) the switch is visible to the team only (not a user-facing feature to demo); (3) the presenter says what it is ("the recorded version") — never passes a recording off as live. The one time a recording is presented as live, the team's credibility on the evidence criterion is gone.

**Backup video rules (THIRD-PARTY — 30-Days-of-Hackathon Day 24: https://github.com/wafi574/30-days-of-hackathon/blob/HEAD/24_Day_Live_Demo/24_live_demo.md, accessed 2026-11-13):** record 1–3 minutes, before the deadline crunch; use screen recording; upload (unlisted) and confirm the link plays for someone else; **always have it open in a tab, ready to go**; simulate the failure in rehearsal — pretend the live demo just crashed and practice calmly switching to the backup video. The recorded demo costs ~20 minutes to make and has saved countless projects. Also: free-tier APIs throttle during demos — cache all demo responses locally and have a demo mode that works entirely offline if needed. (THIRD-PARTY — Hackathon Navigator: https://cliptics.com/claude-code-templates/guide-hackathon-navigator, accessed 2026-11-13.) **Timing, reconciled with the source:** Hackathon Navigator says record 2 hours before submission, when the project is most stable — i.e. ~14:00. So: first recording at ~14:00, then re-record at ~14:45 after the second clean rehearsal run if the build changed; the 14:45 cut is the one that ships.

## 8. The demo-day test (30 / 15 / 5 minutes before the pitch)

Counted back from the **16:15 pitch** (not from submission — the HackMIT source defines the checks as 30/15/5 minutes *before presenting*). That puts them at **15:45 / 16:00 / 16:10**; the 15-minute check coincides with the 16:00 submission, so do the submission first, then the check.

(THIRD-PARTY — HackMIT skill, above; corroborated by AngelHack's final-hour checklist: https://angelhack.com/blog/10-tips-to-help-you-rock-your-next-hackathon-demo/, accessed 2026-11-13.)

- **15:45 (30 minutes before):** run from a clean state (fresh kill + reopen), check every feature in the demo script, verify persistence, check error handling, test on the demo phone (not the laptop). Confirm the slot length against the program brief so the team rehearses to the right runtime.
- **16:00 (15 minutes before; after submission):** clear the cache, close unrelated tabs, check the network, prepare the offline fallback (kill switch + cached response), load the demo data, confirm the backup video plays (open in a tab, tested), charger plugged in.
- **16:10 (5 minutes before):** breathe, review the script, confirm the backup, test audio and video, open every tab, timer visible to the presenter. Demo data seeded and loaded so judges see a populated product, never an empty state. Slow steps pre-loaded or cached so AI responses don't create dead air. Display connection tested with the room's cable or share link so setup takes seconds, not minutes.

## 9. Top 8 traps (what breaks at demo time, and the fix)

| # | Trap | What breaks | Fix |
|---|---|---|---|
| 1 | **Rehearsing first-open only, never kill-and-reopen** | The scored move (kill + reopen) is the one never practised; state doesn't survive, or the app shows a red screen on relaunch | Rehearse kill-and-reopen twice minimum (§5); the Maestro flow asserts state survives relaunch |
| 2 | **Metro / laptop as a single point of failure** | Laptop sleeps, Metro dies, or venue Wi-Fi drops mid-pitch → Expo Go shows nothing | Preview build kicked off by 13:30 (never after); laptop on charger, sleep disabled; phone mobile data as backup; verify the AI endpoint over mobile data |
| 3 | **AI latency as dead air** | The AI call takes 10–20s live; the presenter stands silent while judges watch a spinner | Rehearse the real latency and narrate it ("about ten seconds"); pre-warm/cache the golden response; stream tokens so something is always moving; the kill switch is the escape hatch |
| 4 | **Empty state on stage** | The demo opens to an empty list because seed data was never loaded on the demo phone | Seed script runs on the demo phone before the pitch; demo data loaded at the 16:00 check; never live sign-up during judging |
| 5 | **No backup video (or a video nobody tested)** | The live demo dies and there is nothing to switch to — or the video link doesn't play | First recording ~14:00, re-record ~14:45 after the second clean run; upload + confirm it plays for someone else; open in a tab, ready; rehearse the switch |
| 6 | **The presenter debugs on stage** | A human starts tapping around, reloading, retyping the input while judges watch | Contingency cards: the switch IS the recovery; tech standby never restarts anything during the pitch; one calm sentence, then the recording |
| 7 | **Testing the wrong binary** | E2E passes against Expo Go (shared container, Expo's native modules) but the real build behaves differently | Maestro runs against the dev/preview build by appId; Expo Go flows are smoke checks only (dev-URL workaround) |
| 8 | **Running long / demo squeezed into the last seconds** | The problem section eats 3 minutes; the demo — 40 points — gets 30 rushed seconds | Timer visible to the presenter; pitch lead owns the clock; hard cut lines written in the script (what gets dropped at 3:30, at 4:00); rehearse twice, timed — if the full pitch runs over 5:00, cut a sentence; if the demo runs over its 2:15 budget, cut a demo step (permitflow dry-run rule, adapted: their 90-second script used a >95s cut trigger) |

## 10. What this research does NOT apply to / does not cover

- Full Detox setup (see §3 — only if the team already knows it); Appium (broadest but heaviest setup — not worth it in 5h); device clouds / paid E2E (Maestro Cloud, Drizz — no spending).
- Store submission, TestFlight review, production monitoring, analytics dashboards — irrelevant in 5 hours.
- The pitch deck design itself (slide visuals) — structure and timing only; the frontend kit's taste loop owns the look.
- Judging Q&A beyond the prepared question list (§6) — the team's domain knowledge answers the rest.

## 11. UNVERIFIED — must be checked, not assumed

1. **Whether the demo phone is Android or iOS at pitch time.** The goal file says 1 Android phone (model/OS TBD) with the iPhone 11 Pro Max as backup; the 12/11 mobile report assumed the iPhone as primary. The rehearsal script works for either, but the backup-phone handover (F5/F6) needs both phones loaded with the same build — confirm which is primary tonight.
2. **Whether a preview build will exist by 15:00.** It depends on the EAS queue and whether any native module forces a dev build. It must be kicked off by 13:30 — if it is not back by 15:00, the pitch rides on Expo Go + tunnel, rehearsed twice, not once.
3. **Detox compatibility with RN 0.86 / SDK 57.** Docs list 0.77–0.84; check before adopting — the recommendation (Maestro) does not depend on it.
4. **Venue specifics: projector/cable type, Wi-Fi reliability, whether the pitch is on stage with a shared screen or at the team's table.** The F7 drill assumes a room screen exists; confirm on arrival at the venue (event window 09:00–19:00 per the goal file; no separate check-in time is verified anywhere) and adapt the drill.
5. **Whether Q&A is included in the 5 minutes or separate.** HackTribe's first rule: confirm it before building the deck. The pitch outline above assumes 5 minutes of presentation; if Q&A is inside the 5, cut the demo to 1:00 and the execution section to 0:30.
6. **Maestro on the exact demo phone.** Maestro's Expo Go workaround (openLink to the dev URL) and appId launch were verified from docs, not run on this team's phone. The first Maestro run is a rehearsal task, not an assumption.
7. **Apple Developer account status — the iPhone-backup dependency.** An iOS dev/preview build needs a $99/yr Apple Developer account plus UDID registration, and new devices can take 24–72 h to process (mobile report §2; backend report §5 row 8). Without it the iPhone can only run Expo Go, not "the same build" — confirm tonight; if there is no account, the Android phone is the only device that can carry a standalone build (APK sideload needs no account), which is another reason the Android-primary choice matters.
8. **Goal-file staleness (cross-document note, not a draft error):** the goal file's hour plan says "3:20–4:15 freeze… 4:15–5:00 humans finalize" while FLEET-MODE.md §6 says freeze 3:20–4:00, agents stop 4:00–4:30, humans verify 4:30–5:00. This brief follows FLEET-MODE.md, which states it governs build day where the two disagree; the goal file is the stale one.

## 12. Sources (all accessed 2026-11-13, except Expo docs — see header)

**OFFICIAL / PRIMARY (cited through the 12/11 mobile report, not re-opened in this pass)**
- Expo docs: Expo Go / Metro tunnel / kill-and-reopen mechanics; EAS Workflows Maestro job — https://docs.expo.dev/

**THIRD-PARTY**
- HackTribe, How to Build a Hackathon Pitch Deck: A Practical 5-Minute Structure (200+ hackathons) — https://hacktribe.co/blog/how-to-build-a-hackathon-pitch-deck-practical-5-minute-structure
- AngelHack, 10 Hackathon Demo Tips From Behind The Scenes — https://angelhack.com/blog/10-tips-to-help-you-rock-your-next-hackathon-demo/
- HackMIT-playbook-based skill, hackathon-testing (80/20, 10-min checklist, demo-day test, backup plan, bug triage) — https://github.com/andomo3/flecto-shade/blob/HEAD/.claude/skills/hackathon-testing/SKILL.md
- Drizz, How to Test React Native Apps: Best Testing Frameworks and Complete Strategy (2026) — https://www.drizz.dev/post/how-to-test-react-native-apps-best-testing-frameworks
- Codezup, Automated Testing in React Native: Jest, RNTL, Maestro — https://codezup.com/automated-testing-in-react-native-guide/
- Maestro for Expo + RN (dev-flow reference, re-checked 2026-08-26 against docs.maestro.dev + docs.expo.dev) — https://github.com/lukedj78/dev-flow/blob/HEAD/rn-write-tests/references/maestro.md
- React Native SME Cookbook, Maestro E2E — https://reactnative.codeguides.io/testing/maestro-e2e/
- Momentic, Expo and React Native E2E Testing Without Appium or Detox — https://momentic.ai/blog/expo-react-native-end-to-end-testing
- 30-Days-of-Hackathon, Day 24 — The Live Demo (+ Backup Video) — https://github.com/wafi574/30-days-of-hackathon/blob/HEAD/24_Day_Live_Demo/24_live_demo.md
- Hackathon Navigator, best practices (backup video 2h before submission; API rate limits) — https://cliptics.com/claude-code-templates/guide-hackathon-navigator
- Contingency cards + dry-run checklist (permitflow) — https://github.com/hanjing06/permitflow/commit/bdd8e2eb09f43068622297ff3c31270889918a07
- Demo script / disaster recovery (SimpleAI) — https://www.simpleai.community/p/demo-script/
- Medium, Testing React Native Apps: A Complete Guide (70/20/10 pyramid) — https://medium.com/@shbhm00/testing-react-native-apps-a-complete-human-friendly-guide-d5e1a97a7425

**PRIOR REPORTS (this project, read 2026-11-13)**
- Mobile agent toolkit (12/11) — ~/workspace/research_notes/mobile-agent-toolkit-20261112/report.md
- Backend toolkit (12/11) — ~/workspace/research_notes/backend-agent-toolkit-20261112/report.md
- Fleet runbook — ~/frontend-agent-kit/repo/FLEET-MODE.md (v1; §5 loop, §6 clock, §11 demo-day checklist, §14 exclusions)
- Goal file — ~/workspace/goals/hackathon-buffet-run-four-muses-dev-and-design-alone/GOAL.md
