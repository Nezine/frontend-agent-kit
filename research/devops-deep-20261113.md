# DevOps / Release — Deep Implementation Brief

**Event:** Codex Community Hackathon Hanoi, Sat 14/11/2026, build 11:00–16:00 ICT.
**Stack (settled 12/11, AMENDED by §0 below):** Expo + React Native + TypeScript, Convex primary / Supabase fallback.
**Repo:** the product repo is NEW and SEPARATE from muse-fleet (the kit repo). Public GitHub repo, created Friday night before the event.
**Sources read first:** `backend-agent-toolkit-20261112/report.md`, `mobile-agent-toolkit-20261112/report.md`, `GOAL.md`, `FLEET-MODE.md` (all read 13/11/2026).
**Red team:** a dedicated red-team review ran over the first draft on 13/11/2026 and returned **FAIL** (5 SEVERE / 10 MAJOR / 5 MINOR). Every finding is fixed in this version; the fixes are marked **[RT-fix]** where they change the draft. The three findings that change decisions, not just wording, are §0 (SDK 57/58), §(b) (timeline re-derived from the queue), and §(a) (copy-paste artefacts instead of prose).

---

## §0 — DECISION REQUIRED FRIDAY NIGHT: SDK 57 vs SDK 58 (Expo Go is dead on SDK 57)

**The 12/11 mobile report's premise is stale and must not be executed.** It said Expo Go SDK 57 was "waiting on approval" on the stores. That wording is from **May 2026, about SDK 55**. What actually happened (verified 13/11/2026):

- Expo SDK 58 shipped **15/10/2026** (React Native 0.86 → 0.88). Source: https://expo.dev/changelog/sdk-58
- Expo Go **58.0.5** reached Google Play **19/10/2026** and the App Store **22/10/2026**, and Expo says it "will support only SDK 58". Source: https://vibeview.io/guides/expo-go-incompatible-sdk/ (checked against Expo's changelog and store listings 07/11/2026); https://expo.dev/blog/how-to-upgrade-to-sdk-58
- Expo Go includes exactly **one** SDK version per build: "Each build of Expo Go includes one Expo SDK version", and "Expo Go supports only the latest SDK". A SDK 57 project on a phone with store Expo Go shows **"Project is incompatible with this version of Expo Go"**. Source: https://vibeview.io/guides/expo-go-incompatible-sdk/ ; https://docs.expo.dev/workflow/upgrading-expo-sdk-walkthrough/

**Consequence:** there is no store Expo Go that opens a SDK 57 project. The draft's plan ("iterate in Expo Go 11:00–13:30, verify the store version on the phone") cannot work. The only SDK 57 Expo Go is sideloaded via expo.dev/go, which the team has not tested.

**Decision (make it Friday night, not Saturday 11:00):**

- **Option A — RECOMMENDED: upgrade the whole stack to SDK 58.** `npx create-expo-app` now recommends SDK 58; scaffold with `--template default@sdk-58`. Store Expo Go then works for fast iteration 11:00–13:30, and preview APKs remain the demo vehicle. Cost: the mobile-kit templates and the 12/11 reports were written for SDK 57 — re-verify the scaffold + Convex round-trip on the demo phone Friday night; if anything fails by 22:00 Friday, fall back to Option B. Note: SDK 58 needs Node 22.13+ / 24.3+ / 26 (odd releases 23/25 unsupported) and does NOT support macOS (`react-native-macos` not yet on RN 0.86+). Source: https://expo.dev/blog/how-to-upgrade-to-sdk-58 ; https://urielpapa.com/news/expo-sdk-58
- **Option B: stay on SDK 57, abandon Expo Go entirely.** Iterate from 11:00 on **development-build APKs** (`eas build --profile development`, a dev-client APK installed on the phone) — no Expo Go at any point. Cost: every iteration round-trip is an EAS build (queue time), so iteration is slower; the first development build must be kicked off at ~11:00 sharp.

Either option is workable. What is NOT workable is SDK 57 + store Expo Go. **The coordinator must record the chosen option in the repo Friday night; Saturday 09:00 is confirmation only.**

---

## (a) Product repo layout + branch/merge rules for build day

```
<product-repo>/                  # NEW public repo, e.g. <app-name>
  app/                          # Expo Router screens (route files only — thin)
  src/
    features/                   # ONE folder per vertical slice
      <slice>/                  # e.g. onboarding, capture, ai-result, share
        screen.tsx  components/  hooks.ts  api.ts
    ui/                         # theme.ts tokens, primitives (Button, Card, Sheet)
    lib/                        # convex.ts client, supabase.ts fallback, ai.ts
    state/                      # zustand stores (one per slice, never one global store)
  convex/                       # Convex functions + schema.ts (backend track owns)
  supabase/                     # migrations + edge functions (fallback only, dormant)
  assets/                       # images, fonts (NO secrets, NO .env)
  scripts/                      # demo-seed.ts, kill-reopen-check.sh
  .github/workflows/ci.yml      # see §(c) — full file below
  app.json / eas.json           # eas.json — full file below (APK, not AAB)
  README.md                     # 60-second setup: clone → npm ci → npx expo start
  CHANGELOG.md                  # one line per merged slice
  SUBMISSION.md                 # frozen at 15:30: repo URL, APK link, pitch notes
```

**Branch/merge rules (the 4-agent, 5-hour version of FLEET-MODE §5 trunk-based rule):**
1. `main` is protected: require PR + 1 approval + CI green; NO direct pushes; NO force-push. Apply it Friday night with the exact command in §(a.1) — **[RT-fix]** the draft's bare `gh api … -X PUT` with no body is not executable.
2. One branch per slice, named `<track>/<slice>` (e.g. `mobile/onboarding`, `backend/ai-endpoint`, `frontend/result-screen`, `security/rls`). Branches live <90 min (FLEET-MODE rule); a slice that is not mergeable in 90 min is cut in half, not extended.
3. **Merge order is fixed and sequential through the Integrator (Muse):** backend endpoint → mobile screen that calls it → frontend polish on that screen → security review of that slice. Never two agents merging at once; the integrator merges, tags the slice in CHANGELOG.md, and posts the new `main` SHA in the group.
4. **No shared files without a lock:** `app.json`, `eas.json`, `package.json`, `src/ui/theme.ts`, `convex/schema.ts` are owned by ONE track each (Mobile owns app.json/eas.json/package.json; Frontend owns theme.ts; Backend owns schema.ts). Anyone else needing a change there asks in the group and the owner makes it — the single biggest merge-conflict killer in a 5h window.
5. Every PR body carries: slice name, what the user can now do on the phone, and the exact manual test (tap path) the integrator runs on the demo phone.
6. Revert beats fix after 15:00: any red main after 15:00 is reverted first (`git revert`), re-fixed on a branch, re-merged only when green. No "quick fix" commits to main in the last hour.

### (a.1) Branch protection — copy-pasteable **[RT-fix]**

**Sequencing first (the draft got this wrong):** a status-check context can only be selected as *required* after GitHub has seen it report at least once. So the order is: (1) Friday night, scaffold + CI workflow land on `main`; (2) open a trivial PR (or push to `main`) so the `ci` check reports; (3) THEN apply protection with `contexts: ["ci"]`. Applying protection before any CI run means the required check cannot be selected. Source for the once-reported rule: https://github.com/danielbfogel-lgtm/retail-demand-forecasting/blob/HEAD/docs/branch_protection.md

`protection.json` (all four top-level keys are required by the PUT endpoint — a body missing any of them is rejected):

```json
{
  "required_status_checks": { "strict": true, "contexts": ["ci"] },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
```

```bash
gh api repos/<OWNER>/<REPO>/branches/main/protection -X PUT --input protection.json
gh api repos/<OWNER>/<REPO>/branches/main/protection --jq '.required_status_checks.contexts'
```

`enforce_admins: false` is a deliberate decision, not an oversight: after 15:00 the integrator (repo owner) must be able to emergency-revert/merge without being blocked by their own rule. If the PUT returns 422, do not debug it on Saturday — apply the same settings in the UI (Settings → Branches → Add branch protection rule, ~5 min, human). Verify with the second command above: it must list `["ci"]`.

### (a.2) `eas.json` — copy-pasteable **[RT-fix]**

**EAS Android builds default to `.aab`.** An AAB cannot be sideloaded onto the demo phone. The preview profile MUST set `"android": { "buildType": "apk" }` (plus `"distribution": "internal"`). Source: https://docs.expo.dev/tutorial/eas/android-development-build/ ("While the default Android format is .aab … it cannot be installed on devices"); https://docs.expo.dev/deploy/build-project/ ("it is recommended to use aab when submitting to stores, and this is the default configuration").

```json
{
  "cli": { "version": ">= 16.0.0", "appVersionSource": "remote" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "android": { "buildType": "apk" },
      "channel": "development"
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview",
      "android": { "buildType": "apk" },
      "autoIncrement": true,
      "env": { "EXPO_PUBLIC_CONVEX_URL": "<set via eas env, NOT pasted here — see §(a.3)>" }
    },
    "production": {
      "channel": "production",
      "android": { "buildType": "app-bundle" },
      "autoIncrement": true
    }
  },
  "submit": { "production": {} }
}
```

Friday-night check: the dry-run build's download link MUST end in `.apk`. If it ends in `.aab`, the profile is wrong — fix it Friday, not Saturday.

**Versioning in a 5h window:** `app.json` `version` is user-facing (start `1.0.0`, bump the patch per demo-visible change); `android.versionCode` / `ios.buildNumber` are developer-facing integers and MUST increment per build, or Android refuses to install the newer build over the older one. `appVersionSource: remote` + `autoIncrement: true` (above) makes EAS do the incrementing. Source: https://docs.expo.dev/build-reference/app-versions/ (via the 13/11 research round; re-verify the two field names in `app.json` on the Friday scaffold).

### (a.3) Secrets and env vars — the real wiring **[RT-fix]**

The draft said "`EXPO_TOKEN` + `EXPO_PUBLIC_CONVEX_URL` set as repo secrets". That is the wrong mechanism: builds in this plan are manual CLI builds from a laptop, and GitHub repo secrets are never read by `eas build` run from a laptop. The real wiring:

- `EXPO_PUBLIC_CONVEX_URL` is a **public** value (the `EXPO_PUBLIC_` prefix means it is embedded in the JS bundle — see trap 5). It belongs in EAS environment variables, not a GitHub secret:
  `eas env:create --environment preview --name EXPO_PUBLIC_CONVEX_URL --value https://<deployment>.convex.cloud --visibility public`
- `EXPO_TOKEN` (for non-interactive CLI use) lives in the shell of the machine that runs the builds (`export EXPO_TOKEN=…` in that machine's shell profile, or a one-time `eas login`). It is never in the repo.
- Build-time secrets (if any) go through `eas secret:create` / `eas env:create --visibility secret`. **Exception that matters for the local-build backup:** Secret-visibility EAS env vars are NOT supported for local builds — set them in the local shell when running `eas build --local`. Source: https://docs.expo.dev/build-reference/local-builds/ ; https://docs.expo.dev/build-reference/variables/

## (b) Build timeline — re-derived from the queue **[RT-fix]**

The draft's timeline contradicted its own queue figure (a 12:00 start with a 90-minute queue cannot produce an APK at 13:30, and a 14:00 build cannot land by 15:00 on the same queue). This version derives every time from **queue + build time**, and makes APK #1 the guaranteed demo artefact while APK #2 is a bonus, not a dependency.

**The numbers (all 13/11/2026):** EAS free tier = 15 Android + 15 iOS builds/month, low-priority queue, **45-minute build timeout, 1 concurrent build**. The queue wording on the pricing page is "at peak times … waits of 90 minutes or more" — **that is pricing-page wording, not a measurement; no live Saturday-morning queue measurement exists** (see CHƯA ĐỌC). Build time once started is ~15–30 min for an Expo app. Sources: https://expo.dev/pricing (via corroborating quotations — the direct crawl returned garbled table text, so the four numbers are corroborated from https://github.com/selftend/selftend/issues/521 and https://newly.app/guides/eas-build, both accessed 13/11/2026). **The Friday-night dry run is the only real measurement the team will have — record its queue + build time and re-plan Saturday from those numbers, not from this table.**

**Build count, honestly:** Friday dry run + 2 planned Saturday cloud builds = **3 builds, 12 spare Android builds** (not 13 — the dry run counts against the same monthly quota). A local build does not consume the cloud quota. Nuance: builds failing within 3 minutes are waived, up to 10/month. Source: https://github.com/selftend/selftend/issues/521

**Non-interactive discipline (scope gap):** every `eas build` from agent hands runs with `--non-interactive` (a bare `eas build` can prompt — e.g. first-build Android keystore generation — and hang). First-build credentials: EAS generates/uploads the Android keystore on the first build; do it Friday night with a human present, or pre-create via `eas credentials`. Check status with `eas build:list`, never by re-running `eas build`. Whose Expo account owns the project and quota, and how many November builds it has already used, is checked Friday night — an account that already burned its 15 is a Saturday-morning surprise.

### Friday night (before the event) — the whole plan is bought here

- [ ] SDK decision (§0) recorded in the repo; scaffold created on the chosen SDK; `npm ci` clean on all four machines (Node 22 — satisfies SDK 58's 22.13+ floor and SDK 57).
- [ ] Repo created; CI green on the scaffold; protection applied AFTER the first `ci` report (§a.1).
- [ ] `eas.json` committed (§a.2); EAS project linked (`eas init`); env vars set (§a.3); `expo-updates` installed + `eas update:configure` run (see §b.1).
- [ ] **Dry-run cloud preview build, non-interactive.** Record: time kicked off, time it left the queue, time it finished. Verify the download is a `.apk`. Install on the demo phone (download link or `adb install -r` — see §b.2). Kill → reopen → Convex round-trip green.
- [ ] **Local-build dry run on the café machine** (the laptop/MacBook that will be at the café): `eas build --local --platform android --profile preview`. Requires Android SDK **+ NDK** + JDK 17, macOS/Linux only (Windows not officially supported); output defaults to the current directory (override with `EAS_LOCAL_BUILD_ARTIFACTS_DIR`); EAS Secret-visibility vars unsupported locally. Source: https://docs.expo.dev/build-reference/local-builds/
- [ ] Demo-phone checks (§b.2). Pitch deck started (slides: Thịnh volunteered in the group 12/11).

### Saturday 14/11 — all times ICT

| Time | Milestone |
|---|---|
| 09:00–11:00 | Check-in; **09:30 welcome/rules — CONFIRM the submission mechanism** (see §d — it is unpublished); idea lock; confirm the §0 SDK decision and Friday's measured queue/build times. |
| 11:00–11:15 | Walking skeleton lands on `main`: scaffold + one screen + one Convex query round-trip. (Option B: development-build APK instead of Expo Go.) |
| **~11:15** | **BUILD #1 kicked off** (preview profile, non-interactive). This is the scaffold smoke build: it validates keystore, config, and the queue. Worst case (90-min queue + ~25-min build) it lands ~13:10; good case ~11:45. |
| 11:15–13:00 | Slices land while build #1 runs. Nobody waits for a build. Slice-freeze for build #2: **13:15**. |
| ~13:00–13:30 | **BUILD #1 on the phone** (whenever it lands): install, kill, reopen, main AI flow end-to-end. **This is the first real 40-point rehearsal, and APK #1 is the guaranteed demo artefact from here on.** Log every failure in SUBMISSION.md. |
| **~13:30** | **BUILD #2 kicked off** (all slices merged by 13:15). Check `eas build:list` first — build #1 must be finished, because the free tier allows **1 concurrent build**. Worst case it lands ~15:25; good case ~14:00. |
| 15:00 | **HARD — the newest APK on the phone becomes the demo artefact.** Kill → reopen → main AI flow, timed. If build #2 has landed, rehearse on #2; if not, rehearse on #1 — **do not wait for #2**. |
| 15:00–15:15 | **Record the demo video** (≤3 min, on the real phone, kill → reopen → main AI flow, narrated) — even though the pitch is live. It costs 15 min and is the only artefact that survives a dead phone, dead endpoint, or dead café network at 16:15. |
| 15:15 | Upload the demo APK as a **GitHub Release asset** on the product repo (a release link survives after the event; a laptop-local file does not). Keep the `eas build` download URL as backup. |
| 15:30 | **Code freeze.** SUBMISSION.md frozen; README + CHANGELOG final. |
| 15:30–15:45 | Pitch rehearsal on the real phone (5 min, timed). |
| 15:45–16:00 | Buffer — submit early if the mechanism allows. |
| 16:00 | **Submit** (see §d). 16:15 pitches. |

**Build #3 (emergency only):** allowed only on a stated trigger — the demo APK won't install, crashes on launch, or the AI flow is dead AND not fixable by EAS Update (§b.1). Vehicle: local build if the cloud queue is >45 min at that point, else cloud. A third build is never for a feature.

**EAS build vs local build — the decision:** cloud EAS is the default (preview profile → APK). Local build is the backup, not the plan: it runs the cloud pipeline on a local machine and does not consume the cloud queue, but it needs the SDK + NDK + JDK already installed — verify Friday night, do not discover it missing at 14:00.

### (b.1) EAS Update — the third lever, specified so it can actually work **[RT-fix]**

EAS Update fixes JS/assets-only bugs after 15:00 without a rebuild — but only if it was set up Friday night. A binary built without `expo-updates` baked in silently never updates. Friday-night setup block:

```bash
npx expo install expo-updates
eas update:configure   # writes updates.url + runtimeVersion into app.json, adds channel per eas.json profile
```

Required in `app.json`: `"runtimeVersion": { "policy": "fingerprint" }` (fingerprint policy, not `appVersion`). Required in `eas.json` preview profile: `"channel": "preview"` (already in §a.2). Verify Friday: `eas update --branch preview --message "test"` against the dry-run APK, then kill → reopen → confirm the update lands. Post-15:00 fix procedure: publish update → kill app → reopen → wait ~10 s for download → verify the fix → if not applied, fall back to the APK already on the phone (no rebuild). Scope: JS/styling/images only — never native code, native modules, `app.json`, or SDK changes. Free tier: 1,000 MAU. Sources: https://docs.expo.dev/eas-update/introduction/ (opened 13/11/2026).

### (b.2) APK distribution to the demo phone

- **Primary:** the EAS build download link (QR on the build page) opened on the phone → installs the APK. The phone needs "Install unknown apps" allowed for the browser (or for the file manager, whichever opens the APK) — enable Friday night.
- **Backup:** `adb install -r app.apk` from the café laptop with USB debugging enabled on the phone. Same-signature rule: an APK signed with a different keystore than the installed one will not install over it — uninstall first (`adb uninstall <package>`) or always build from the same EAS project/keystore. Never `adb install` a debug APK over a release APK and expect it to work.
- **Demo-phone reality checks (Friday night):** free storage ≥ 500 MB; Android version / API level recorded; battery + charger at the table; a named backup phone if the primary dies (even an old one — the demo is kill → reopen, not a spec sheet); Expo Go version on the phone IF Option A (§0) was chosen. Since 03/09/2026, Expo Go on iPhone requires the same Expo account signed in to the CLI and the app — sign in Friday night if any Expo Go path survives.

**Metro fallback order (one order, used everywhere) [RT-fix]:** LAN (café Wi-Fi) → USB → tunnel. The tunnel (`--tunnel`) needs outbound ngrok; café captive portals and firewalls kill it, so it is last, not first. And the APK needs no Metro at all — which is why the APK, not Expo Go, is the demo vehicle.

## (c) CI checklist — what runs on every PR, what must stay green

Workflow `.github/workflows/ci.yml`, triggers on every PR to `main` + every push to `main`. Runner: `ubuntu-latest`. GitHub Actions standard runners are **free on public repos** (the billing doc says public-repo usage "remain[s] free" and "do[es] not reduce the included compute usage"; "unlimited" is the hosted-runner reference's wording). Source: https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions (opened 13/11/2026).

**Full workflow — copy-pasteable [RT-fix]:** the draft's table had no install step (on a fresh runner there is no `node_modules`, so `tsc`/`eslint`/`expo-doctor` fail before they run) and its no-keys guard used `|| true`, which always exits 0 and can never fail a PR. This version has one job, `ci` — the single check context the branch protection requires (§a.1).

```yaml
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: npm
      - run: npm ci
      - run: npx tsc --noEmit
      - run: npx eslint .
      - run: npm test -- --ci
      - run: npx expo-doctor
      - name: Secret scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: No keys in bundle
        run: |
          if grep -rqE 'sk-[A-Za-z0-9]{20,}' app src || grep -rq 'EXPO_PUBLIC_[A-Z_]*KEY' app src; then
            echo 'ERROR: possible secret in app source'; exit 1
          fi
```

| Check | Command | Why it is required |
|---|---|---|
| Install | `npm ci` (Node 22, `actions/setup-node`) | Without it nothing else runs. |
| Typecheck | `npx tsc --noEmit` | A red typecheck landing on main at 14:30 costs the demo. |
| Lint | `npx eslint .` (or `expo lint`) | Catches the unused-import / undefined-var class that breaks Metro bundling silently. |
| Unit tests | `npm test -- --ci` (Vitest/Jest; even 5 smoke tests) | The AI endpoint contract test + the Convex query test. **The scaffold must define a `test` script Friday night — if the script is missing, CI fails, and that failure must happen Friday, not Saturday.** |
| Expo doctor | `npx expo-doctor` | Catches SDK/version drift between the four machines — the #1 "works on my machine" cause. |
| Secret scan | `gitleaks/gitleaks-action@v2` | A key committed at 12:15 is a security incident at 16:00. Fails the PR, not just warns. |
| No-bundle-keys guard | the `grep … exit 1` step above | `EXPO_PUBLIC_*` is embedded in the JS bundle (see trap 5). The guard fails the PR on a hit — no `|| true`. |

**Rules:** CI must be green before merge (branch protection enforces it). **Runtime target: <5 min — a target, not a budget [RT-fix]:** no measurement exists yet, so measure it on the Friday scaffold CI run and record the actual time; split the slow job out only if the observed time exceeds 5 min. Cache `node_modules` via `actions/setup-node` `cache: npm`. **Do NOT run EAS builds from CI on every PR** — that burns the 15/month quota and the queue; builds are manual, twice a day (11:15, 13:30) plus the Friday dry run.

## (d) Submission checklist for 16:00

**UNVERIFIED — the exact submission mechanism for this event is not published on the public Lu.ma page or the organizer's Facebook post (checked 13/11).** The agenda says "tools down and submission at 16:00" and nothing more. The checklist below therefore prepares EVERY artefact a Codex-community hackathon plausibly asks for, so the team can submit in whatever form appears at 16:00 without scrambling. **Confirm the mechanism with the organizers at the 09:30 welcome/rules session and delete the inapplicable rows then.**

- [ ] **Repo URL** — the product repo, `main` at the frozen SHA, README with 60-second setup. (Devpost Codex hackathons ask for a repo URL; one of them states "The repository may be public or private. If private, it must be on GitHub or GitLab and shared with testing@devpost.com" — public is NOT required. Source: https://twitchcon-codex.devpost.com/ ; https://twitchcon-codex.devpost.com/rules)
- [ ] **APK file / install link** — the 15:00 demo APK, hosted as a GitHub Release asset on the product repo (uploaded 15:15). Keep the `eas build` download URL as backup.
- [ ] **Demo video (≤3 min)** — recorded on the REAL phone 15:00–15:15, kill → reopen → main AI flow, narrated, uploaded to YouTube as public/unlisted. (Devpost Codex hackathons require a ≤3-min public YouTube demo video; unverified for this event, but the video costs 15 min and saves the entry if the live demo fails.)
- [ ] **One-line summary + problem statement + "how we built it"** — written in SUBMISSION.md by 15:30 (problem with evidence = 35 points; market expansion = 25 points — the text is where those points are argued).
- [ ] **Codex Session ID** — the session ID of the thread where most of the project was built. TwitchCon Devpost says `/status` in Codex; the OpenAI Build Week summary says `/feedback` — the commands differ across events, so verify in the Codex CLI on Friday and record the working one. Sources: https://twitchcon-codex.devpost.com/ ; https://aimagazine.blog/openai-build-week-2026-prizes-winners-results/
- [ ] **Team + contact** — all four members' names on the submission; one phone number that works.
- [ ] **Pre-built disclosure** — one paragraph in SUBMISSION.md stating what was pre-built (scaffold, CI, EAS config, research) vs built 11:00–16:00. The organizers explicitly allow prep; disclosure is what keeps it honest.
- [ ] **Final phone state** — APK installed, app killed (not backgrounded), phone charged >50%, café Wi-Fi + mobile data both tested, AI endpoint responding. The phone is handed to the pitcher charged and ready, not still plugged into a laptop.
- [ ] **Pitch ready** — 5-minute pitch rehearsed 15:30–15:45 on the real phone; slides done (Thịnh volunteered 12/11); one pitcher named before 15:30.

## (e) Top 8 traps — what breaks at demo time, and the fix

1. **SDK 57 + store Expo Go = dead on arrival (the new #1 trap).** Store Expo Go is SDK 58-only since 19–22/10/2026; a SDK 57 project shows "Project is incompatible with this version of Expo Go". *Fix:* decide Friday (§0) — upgrade to SDK 58 (recommended) or drop Expo Go entirely and iterate on development-build APKs. Never discover this at 11:00 Saturday.
2. **The first build starts too late / the queue math doesn't close.** A 90-minute queue means a build kicked off at 14:00 cannot land by 15:00. *Fix:* build #1 at ~11:15 (scaffold smoke); APK #1 is the guaranteed demo artefact; build #2 (~13:30) is a bonus that lands ~15:25 worst case — if it hasn't landed by 15:00, demo #1 and don't wait.
3. **The preview profile produces an AAB, not an APK.** EAS Android defaults to `.aab`, which cannot be sideloaded. *Fix:* `"android": { "buildType": "apk" }` + `"distribution": "internal"` in the preview profile (§a.2), and check the Friday dry-run download ends in `.apk`.
4. **EAS Update specified but never installed.** A binary without `expo-updates` baked in silently never updates, so the post-15:00 "fix via Update" lever does nothing. *Fix:* Friday setup block (`npx expo install expo-updates` + `eas update:configure` + fingerprint `runtimeVersion` + `channel: preview`), verified against the dry-run APK (§b.1).
5. **A key lands in the bundle.** `EXPO_PUBLIC_*` is embedded in the JS bundle in plain text — an AI key shipped in the APK is extractable by anyone with the file. Source: https://docs.expo.dev/guides/environment-variables/ (opened 13/11/2026). *Fix:* the key lives ONLY in the Convex/Supabase backend; the app calls the backend, never the AI provider. Secret-scan in CI (§c) + `eas secret:create` for build-time secrets, never `.env` in the repo.
6. **The AI endpoint is cold / rate-limited / out of credits at 16:15.** First call after idle = cold start; a shared key hammered by four agents' testing = 429 on stage. *Fix:* warm the endpoint at 15:00 (three real calls from the phone); keep a cached "golden response" fallback in the app for the exact demo input, used ONLY if the live call fails (disclose it in the pitch — a fallback is honest, a fake is not); check credit balance at 11:00.
7. **Kill-and-reopen loses state.** The 40-point demo is kill → reopen → main AI flow live. If the app boots to a login wall, an empty state, or a stale Convex subscription after a cold start, the flow is dead on stage. *Fix:* no sign-up wall (share-link persistence only — backend report §lever); seed demo data Friday night; the 13:30 and 15:00 rehearsals are kill-reopen rehearsals, not warm reloads.
8. **A merge at 14:50 breaks main, or two agents collide on a shared file.** *Fix:* single-owner rule for `app.json` / `eas.json` / `package.json` / `theme.ts` / `schema.ts` (§a.4); slice branches <90 min; integrator-only sequential merges; code freeze 15:30; revert-beats-fix after 15:00; and the 15:00 APK is ALREADY on the phone — a broken main after 15:00 cannot touch the demo artefact.

## Bold-but-evidenced recommendations

- **Ship the APK, demo the APK, never demo Expo Go if the APK exists.** Expo Go is a dev client with its own failure modes (SDK mismatch, tunnel, dev-menu accidents); the APK is the artefact the judges' rubric describes ("app killed + reopened on a real phone"). Expo Go is the 11:00–13:30 iteration vehicle only — and only on the SDK 58 path (§0).
- **Three planned builds, counted honestly: Friday dry run + 11:15 + 13:30.** A fourth build is emergency-only, on a stated trigger, never for a feature. The discipline of the count forces the 13:15 slice-freeze, which is what makes 15:00 real.
- **Record the demo video at 15:00 even though the pitch is live.** It costs 15 minutes and it is the only artefact that survives a dead phone, a dead endpoint, or a dead café network at 16:15.

## Scope gaps closed in this version (from the red-team review)

- **Demo-phone reality:** storage / Android version / battery / backup phone / `adb install -r` + same-signature rule — §(b.2).
- **Convex deploy failure:** if the Convex deployment or schema push fails by 12:00, the trigger is explicit — switch the AI endpoint to the Supabase Edge Function fallback (already the stack's fallback decision) and say so in the group; do not debug Convex past 12:00 while the demo clock runs. Owner: backend track (Milo).
- **Café network failure:** phone hotspot for the build machine; `node_modules` pre-downloaded Friday night; EAS cloud builds need internet throughout — if the café network dies, the local-build backup (§b) and the APK already on the phone are the plan, not a new cloud build.
- **Pitch artefact:** slides (Thịnh volunteered 12/11) + named pitcher + 15:30–15:45 rehearsal — §(d).
- **EAS account ownership + non-interactive flags + first-build keystore:** §(b) intro — `--non-interactive` on every agent-run build, keystore generated Friday with a human present, account + November usage checked Friday night.
- **Expo Go same-account rule (iPhone, since 03/09/2026):** §(b.2) — sign in Friday night if any Expo Go path survives the §0 decision.

## Sources (all accessed 13/11/2026 unless noted)

- Expo SDK 58 changelog (shipped 15/10/2026, RN 0.88): https://expo.dev/changelog/sdk-58
- Expo SDK 58 upgrade guide (Expo Go supports only SDK 58; Node 22.13+/24.3+/26; macOS unsupported): https://expo.dev/blog/how-to-upgrade-to-sdk-58
- Expo Go SDK compatibility (store Expo Go 58.0.5, Google Play 19/10/2026, App Store 22/10/2026; "Each build of Expo Go includes one Expo SDK version"; May 2026 "waiting on approval" was SDK 55): https://vibeview.io/guides/expo-go-incompatible-sdk/
- Expo SDK 58 overview (RN 0.87/0.88 changes, Node minimums, macOS): https://urielpapa.com/news/expo-sdk-58
- EAS Build Android tutorial (default format .aab, cannot be installed on devices): https://docs.expo.dev/tutorial/eas/android-development-build/
- EAS Build production builds (aab is the default; `"buildType": "apk"` exception): https://docs.expo.dev/deploy/build-project/
- Expo pricing / free tier (15 Android + 15 iOS builds/month, low-priority queue, "waits of 90 minutes or more" at peak, 45-min timeout, 1 concurrent build; builds failing within 3 min waived up to 10/month) — direct crawl of https://expo.dev/pricing returned garbled table text; numbers corroborated from https://github.com/selftend/selftend/issues/521 and https://newly.app/guides/eas-build
- EAS local builds (Android SDK + NDK + JDK, macOS/Linux, Windows unsupported; output defaults to current directory / `EAS_LOCAL_BUILD_ARTIFACTS_DIR`; Secret-visibility vars unsupported locally): https://docs.expo.dev/build-reference/local-builds/
- EAS Update intro (JS/assets only; needs `expo-updates` in the build; applied on next launch; 1,000 MAU free): https://docs.expo.dev/eas-update/introduction/
- Expo environment variables (`EXPO_PUBLIC_*` embedded in the JS bundle): https://docs.expo.dev/guides/environment-variables/
- EAS environment variables / secrets (`eas secret:create`, `eas env:create`): https://docs.expo.dev/build-reference/variables/
- GitHub Actions billing (standard runners free on public repos): https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions
- Branch protection via API (PUT requires `required_status_checks`, `enforce_admins`, `required_pull_request_reviews`, `restrictions`): https://copyprogramming.com/howto/updating-branch-protection-settings-via-github-api ; https://copyprogramming.com/howto/can-i-add-a-new-branch-protection-rule-via-github-api
- Status-check contexts selectable only after first report: https://github.com/danielbfogel-lgtm/retail-demand-forecasting/blob/HEAD/docs/branch_protection.md
- Codex hackathon submission patterns (repo URL, ≤3-min public YouTube demo, Codex Session ID via `/status`; repo may be public or private shared with testing@devpost.com): https://twitchcon-codex.devpost.com/ ; https://twitchcon-codex.devpost.com/rules ; https://aimagazine.blog/openai-build-week-2026-prizes-winners-results/
- Event agenda (tools down + submission 16:00, Sat 14/11/2026, Biblio Book Cafe): organizer Facebook flyer https://www.facebook.com/permalink.php?story_fbid=pfbid024Jsd1dPvMCDLF8hyMKZ9J5cuUWBhbAYEicn2SmLjFSXgAV4DGxJJvBwjaEsC8iGwl&id=61596072208681 — the Lu.ma page itself was verified 12/11 (per parent context) and not re-opened 13/11; re-open it at the 09:30 rules session.
- Expo Go SDK 57 store status ("waiting on approval") — Expo changelog, via the 12/11 mobile research report. **SUPERSEDED: that wording is May 2026, about SDK 55 — see §0.**

## CHƯA ĐỌC / unverified — do not treat as verified

- The Hanoi event's exact 16:00 submission mechanism (form? Devpost? repo link? in-person handoff?) — not published publicly as of 13/11/2026; confirm at the 09:30 rules session. The §(d) checklist prepares every plausible artefact so the form doesn't matter.
- Whether the EAS free-tier queue on a Saturday morning in Vietnam is actually ~90 min — no live measurement exists. The Friday-night dry run is the only measurement; re-plan Saturday from it.
- Whether `eas build --local` works on the specific laptop/MacBook that will be at the café — needs the Friday-night dry run on that machine.
- Whether the CI workflow actually runs in <5 min — no measurement; measure on the Friday scaffold run.
- Whether the `app.json` version fields (`version`, `android.versionCode`) behave as described with `appVersionSource: remote` + `autoIncrement` on this project — verify on the Friday scaffold (field names re-checked there).
- Convex MCP availability — conflicted across sources in the 12/11 backend report; irrelevant to this brief's release path, noted for the backend track.
- The exact `eas.json` `cli.version` floor (`>= 16.0.0` above) — confirm against the installed EAS CLI Friday night (`eas --version`); older CLIs ignore unknown keys silently.

## Red-team note (process)

First draft reviewed 13/11/2026 by a dedicated red team (own subagent, fresh context): verdict **FAIL** — 5 SEVERE (S1 Expo Go/SDK 57 dead; S2 timeline contradicted its own queue figure; S3 preview profile yields AAB not APK; S4 EAS Update inoperable as specified; S5 branch-protection command not executable + "verified pattern" unsupported), 10 MAJOR, 5 MINOR, plus 7 scope gaps. All SEVERE and MAJOR findings were independently re-verified (Expo SDK 58 / Expo Go store status, AAB default, and the branch-protection PUT body were each confirmed against primary or corroborating sources on 13/11/2026) and fixed in this version. The draft's "verified pattern" claim for branch protection was the one fabricated claim in the draft — it is removed, and the full command with body is given in §(a.1). The red team's "verified correct" list (EAS free-tier numbers, EAS Update scope, `EXPO_PUBLIC_*` embedding, GitHub Actions free on public repos, local-build platform support, Devpost Codex pattern, status-check once-reported rule) is retained and cited above.
