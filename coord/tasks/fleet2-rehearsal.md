# Task: FLEET-2 rehearsal — "Calm in 3 steps"

- **Practice repo:** https://github.com/phamTuan207/fleet2-rehearsal (private, throwaway — delete/archive after the verdict). Mainline: `buffet/main` (default branch, PR-required, coordinator bypass). Fork it, branch, PR to `buffet/main`; only the coordinator (Muse) merges.
- **Start (T+0:00):** Fri 13/11 2026, 20:00 ICT. Hard clock 90 min (ends 21:30).
- **Roles:** A Integrator — Muse (fixed). B Frontend — Migga. C Backend/AI — Milo. D QC + red team + evidence — Mie. **Deputy: Migga. Backup: Milo.**
- **Rules in force:** FLEET-MODE.md §16 (checkpoints per stage, verdict token + STOP formula, gate-first, sprint contract, 25-min round cap, guard-gate.sh) governs where it conflicts with earlier sections. Council rules 1/2/5. Builder never grades its own work. Free-only $0.00, no billing, no card, no secrets in the repo.
- **Practice brief (throwaway — NOT the real hackathon idea):** "Calm in 3 steps" — one-screen app. The user types what is weighing on them (one text input). The AI returns exactly 3 short calming steps as structured JSON. The result screen shows the 3 steps as cards. A counter increments per completed run. A share link shows the same 3 steps. Fixed demo input for every test: "I have a big exam tomorrow and I can't sleep."
- **Pre-flight (T-30 to T+0:00):** fresh TOOLS + MODELS blocks + census in each agent's own `coord/<name>.md` (run the commands, never assume); Supabase project + Edge Function + Gemini key as secret, Convex project + results table + counter (or record STUBBED — canned stub through the real endpoint); Expo SDK 58 scaffold + node -v recorded; demo phone confirmed present for T+1:20 or deferred (verdict then CONDITIONAL). Missing inventory block at T+0:00 = ABORT.

- **Slice id:** `fleet2-rehearsal` (effort scale S; `expected-min`: kickoff 5, contract 15, build 30, gate 15, fix 15, phone/red-team 10 — total 90)
- **Board row:** NONE — BOARD.md is held (coordinator decision 13/11). The ownership table lives in this file + §9 of the plan until the hold clears.
- **1. Objective:** Run the FLEET-2 rehearsal: one small vertical slice ("Calm in 3 steps", §0 of the plan) end to end — taste lock → build → deterministic gate → independent judge → fix top 2 → re-gate → phone smoke test → red team — in 90 minutes, by all four agents, with no human in the loop after the trigger.
- **2. Output format:** (a) `CONTRACT.md` merged on `buffet/main` of the practice repo; (b) the slice merged on `buffet/main` (screen + endpoint + counter); (c) gate result + independent grade (1–5 × Type/Layout/Colour/Space, evidence per score) recorded in this file; (d) phone smoke-test result (kill-and-reopen ×1 + one live AI call, or deferred with reason); (e) red-team top-2 blockers; (f) handover punch-list + PASS / CONDITIONAL / FAIL verdict; (g) run-log entries transcribed by the coordinator.
- **3. Tools / sources:** this plan (`fleet2-rehearsal-plan.md`); `FLEET-MODE.md` §1/§2/§5/§6/§8/§9/§10; `BUFFET-MODE.md` §1/§5; `coord/departments.md` §2 (12 gaps); `swarm/free-tier-ai-path.md` (§a/§d); `research/mobile-deep-20261113.md` §3 (phone check); `research/testing-deep-20261113.md` (rehearsal script); `research/backend-deep-20261113.md` §3 (endpoint envelope — AI call via Supabase Edge Function, NOT the Convex `runAi` action, per the free-only rule). Sources an agent cannot read are marked CHƯA ĐỌC, never cited as read.
- **4. Boundaries:** Do NOT touch `coord/BOARD.md` (held). Do NOT touch the kit repo's `main` except: the coordinator lands this task file + run-log entries; each agent edits ONLY its own `coord/<name>.md`. Do NOT build the real product, the real idea, or an EAS build. Do NOT spend money, link a billing account, or enter a card anywhere. Do NOT grade your own work. Do NOT force-push; do NOT rebase someone else's branch. Practice repo only: `buffet/main` is the mainline.
- **5. Effort scale:** S, 90 minutes total (phase `expected-min` above). A phase that misses its exit is CUT, not extended.
- **6. Definition of done:** all 11 PASS conditions in §6 of the plan hold (or the CONDITIONAL set, with the phone leg deferred and the reason recorded); the verdict is in the run log; every rehearsal finding carries a GAP number (GAP-15+); zero fabricated claims.

## CONTRACT for the practice slice (A writes this into the practice repo at T+0:05)

```markdown
# CONTRACT — Calm in 3 steps (PRACTICE — not the real idea)

## Demo script (exact taps, on a real phone)
1. Open the app (Expo Go).
2. Type: "I have a big exam tomorrow and I can't sleep."
3. Tap "Give me 3 steps".
4. 3 step-cards appear (title + one-line detail each).
5. Tap share — the link shows the same 3 steps.

## API contract
- `POST /calm` (Supabase Edge Function; NOT a Convex action — free-tier path)
  - Request JSON: `{"shareId": "<uuid>", "inputText": "<string>"}`
  - Response JSON: `{"shareId": "<uuid>", "steps": [{"title": "<string>", "detail": "<string>"} x 3]}`
  - Failure response: `{"error": "<short message>", "fallback": "canned"}` — the app
    shows the canned 3 steps, labelled "Example result", never a blank screen.
- Convex (data only): `runs` table (one row per completed run: shareId, inputText,
  steps, source: `demo`) + counter record (increments only on a completed real-AI
  run; stub runs excluded).

## File ownership
| Path | Owner |
|---|---|
| `app/`, `components/` (frontend) | B (Migga) |
| Edge Function, Convex schema/counter, AI prompt, deploy | C (Milo) |
| `docs/`, evidence artefact, demo script | D (Mie) |
| routes, shared types, `package.json`/lockfile, schema, env, deploy config | A (Muse, only) |

## Deploy target
- URL: Metro tunnel URL (Expo Go) for the rehearsal. No cloud build.
- How to deploy: `npx expo start --tunnel` (B's machine); the phone opens the
  tunnel URL in Expo Go.

## Cut list (what is explicitly NOT being built)
- No auth, no accounts, no history, no settings, no second screen, no animation
  beyond the theme tokens, no dark-mode variant.

## Evidence artefact (for the problem criterion, rehearsal-scale)
- One paragraph: who the user is, what is hard for them, what the AI does about
  it — plus 1 evidence row (a real quote or a real observed workaround, not invented).
```

## Run record (coordinator updates every 15 min during the rehearsal)

- T-0 (pre-flight): _pending_
