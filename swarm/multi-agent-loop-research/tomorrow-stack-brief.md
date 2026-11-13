# Tomorrow's Technical Stack — Automation Brief

**Hackathon:** Codex Hackathon Hanoi, Sat 14/11/2026, 09:00–19:00. Build sprint 11:00–16:00.
**Stack:** Expo SDK 58 + Convex Free + Supabase Edge Function Free (Gemini key as secret) + primary model `gemini-3.5-flash-lite` (free) + Groq `openai/gpt-oss-120b` fallback + EAS preview APK + real-phone demo (kill + reopen).
**Access date for every source below: 2026-11-13.** Every claim that was read from a primary source carries its URL. Anything not read is marked **CHƯA ĐỌC** — do not treat it as verified.
**Scope note:** the walking skeleton, the known facts in the task brief (store Expo Go is SDK 58-only; preview APK needs `eas.json` preview profile with `buildType: apk` + `distribution: internal`; cloud-built preview APK ships without `EXPO_PUBLIC_CONVEX_URL` unless set via EAS env; Metro CVE-2025-11953; demo-bunker rule; ~20 free Gemini calls on demo day; never link billing) were **not re-verified** in this brief unless a source below contradicts them. No contradiction was found in the sources read.

---

## 1. Automation patterns found

### 1.1 EAS Build — preview APK, env, and non-interactive operation

**P1. Preview profile is a named convention, not magic — and preview means no dev tools.**
Expo's `eas.json` doc: a build profile is a named group of configurations; the default profiles are `development`, `preview`, and `production`, but "these could have been named `foo`, `bar`, and `baz`". Preview builds "don't include developer tools. They are intended to be installed by your team and other stakeholders, to test out the app in production-like circumstances" and "Android .apk is recommended for preview, .aab is recommended for Google Play Store". The same .apk runs on a device and an emulator.
- Source: https://docs-expo-dev.btglss.net/build/eas-json/ (mirror of docs.expo.dev/build/eas-json, read 2026-11-13)
- Automation value: **high**. One frozen `eas.json` (`preview: {distribution: internal, android: {buildType: apk}}`) removes all per-build profile decisions. Freeze it before the sprint; never edit it after the first successful preview build.

**P2. Bind the profile to an EAS environment explicitly — do not rely on auto-detection.**
Expo's EAS env doc: "you can specify the `environment` field in the build profiles settings in the eas.json file" and "All of the environment variables from the selected environment will be used during the build process." If `environment` is unset, Expo sets it automatically: `production` when `distribution` is `store`, `development` when `developmentClient` is `true`, `preview` for everything else — so a preview profile *should* auto-pick `preview`, but an explicit `"environment": "preview"` removes the inference.
- Source: https://docs.expo.dev/eas/environment-variables/usage/ (read 2026-11-13)
- Automation value: **high — this is the fix for the known "APK ships without EXPO_PUBLIC_CONVEX_URL" failure.** Set `EXPO_PUBLIC_CONVEX_URL` (and any other `EXPO_PUBLIC_*` value) in the **preview** EAS environment (`eas env:create` / dashboard), and set `"environment": "preview"` on the preview profile. Verify after the build, not before: see §1.2.

**P3. `EXPO_PUBLIC_*` values are inlined into the JS bundle at build time — they cannot be fixed after the build.**
Expo's EAS env doc: "Expo CLI will substitute prefixed variables in your code (for example, `process.env.EXPO_PUBLIC_VARNAME`) with the corresponding plain text and sensitive environment variable values… Any `EXPO_PUBLIC_` variables in your application code will be replaced inline with the corresponding values from your Expo Services environment." And: "Client-side values are inlined in the JavaScript bundle when you run `npx expo export`… you should never put any sensitive information in your client-side code."
- Source: https://docs.expo.dev/eas/environment-variables/usage/ (read 2026-11-13)
- Automation value: **high as a check, zero as a fix.** Consequence: a wrong/missing `EXPO_PUBLIC_CONVEX_URL` can only be fixed by a **rebuild**, never by an OTA update, a secret change, or a phone-side setting. Budget one rebuild slot for exactly this failure (see checklist §2, item B2).

**P4. Non-interactive build: `--wait` vs `--no-wait` is a deliberate trade-off, not a default.**
EAS CLI reference (read 2026-11-13): `eas build [-p android|ios|all] [-e PROFILE_NAME] [--local] [--output <value>] [--wait] … [--json] [--non-interactive]`, with `--[no-]wait` = "Wait for build(s) to complete" and `--non-interactive` = "Run the command in non-interactive mode". `--json` "Enable JSON output… Implies `--non-interactive`."
- Source: https://pr-49938.expo-docs.pages.dev/eas/cli/ (Expo EAS CLI reference mirror, read 2026-11-13)
- Automation pattern (recommended for tomorrow): **one designated builder terminal runs `eas build -p android --profile preview --non-interactive --wait --json` and nothing else.** `--wait` blocks that terminal for the whole compile (5–20 min is the commonly cited range — **CHƯA ĐỌC** as an Expo-published figure; treat as planning estimate only), but it makes the build's exit code truthful: success/failure is known in that terminal, with no second polling step. `--no-wait` returns as soon as the build is queued — useful in CI to save runner minutes, actively harmful in a 5-hour sprint because a "green" command means nothing and the real failure surfaces later, silently. **Never chain `--no-wait` into a step that consumes the artifact** (e.g. `--latest` download): the "latest finished build" is then the *previous* build, not the one just queued — this race is documented in secondary material (https://www.canakyuz.co/blog/expo-ota-runtime-version, read via search only — **CHƯA ĐỌC** as a primary source; the `--no-wait` semantics above are from the CLI reference itself).
- Also in the CLI reference: `eas build:list` (list builds), `eas build:download [--build-id …] [--json]`, `eas build:cancel [BUILD_ID]`, `eas build:inspect -p android -s archive|pre-build|post-build` (troubleshooting), and `eas build --clear-cache` (clear cache before the build). Source: same CLI reference URL above.

**P5. `eas build --clear-cache` is the one-button recovery for "it worked before, now the build is weird".**
CLI reference lists `--clear-cache` = "Clear cache before the build" (same source as P4). Cost: a slower build (no npm/Maven cache). Use only on a failed build's retry, never pre-emptively on the first build.

**P6. Pre-flight gate before ANY build: `npx expo-doctor` + `npx expo install --check`.**
The SDK 58 changelog (read 2026-11-13) introduces `@expo/agent-cli` (experimental, "built by agents and designed for agents") with `status` ("answers Expo Go compatibility without starting the app"), `dev`, and `smoke` ("`dev`, plus a screenshot, plus stop"). That CLI is experimental — **do not adopt it as a load-bearing tool on demo day**; the pattern to copy is the *gate itself*: run a compatibility/status check before burning an EAS build slot.
- Source: https://expo.dev/changelog/sdk-58 (read 2026-11-13)
- Cheap, proven equivalent (secondary guidance, **CHƯA ĐỌC** as primary Expo doc text in this session): `npx expo-doctor` / `npx expo install --check`. Keep it as a 60-second human-supervised gate, not a script that auto-fixes versions (an auto-fix that bumps a package mid-sprint can invalidate the native build).

**P7. EAS free-build budget is NOT verified in this brief.**
The commonly quoted "15 Android + 15 iOS builds/month free" figure appears only in secondary sources encountered during search. **CHƯA ĐỌC — no Expo pricing page was opened.** Treat the build budget as *unknown and possibly small*: plan for **≤3 preview builds total** (1 first-pass, 1 fix, 1 final), and verify the remaining quota with `eas account:usage` (CLI reference lists `eas account:usage [ACCOUNT_NAME] [--json]`, same source as P4) before the sprint starts. If the quota is lower than expected, the mitigation is fewer, larger batches per build — not a paid plan (free-only rule).

### 1.2 Expo Go vs preview APK — which to test on, and when

**P8. Expo Go is an educational tool; a production/demo app belongs on a development or preview build.**
SDK 58 changelog (read 2026-11-13): "Expo Go for SDK 58 on the Apple App Store and Google Play Store will be released within a few weeks"; "The new Expo Go will support only SDK 58"; "Reminder: The Expo Go app is our tool for getting started quickly; it's an educational tool to help you learn to build on mobile. If you are past that stage and want to build and ship an app, we encourage you to migrate your project to using a development build."
- Source: https://expo.dev/changelog/sdk-58 (read 2026-11-13)
- Automation implication: **Expo Go is a fast UI-iteration loop only (11:00–13:00). It is never the demo artifact and never the kill-reopen test target.** Every gate that matters (AI flow end-to-end, kill + reopen, share link) runs on the preview APK. A feature that "works in Expo Go" proves nothing about the demo.

**P9. A preview APK is the only artifact that reproduces the judges' conditions.**
From P1: preview builds have no developer tools and test "in production-like circumstances"; the same .apk runs on device and emulator. Combined with P3 (env inlined at build time), the preview APK is the *only* build that can catch the two demo-killing bugs: (a) missing `EXPO_PUBLIC_CONVEX_URL`, (b) a release-only crash (dev-menu/LogBox overlays do not exist in release builds — see P17). Schedule the first preview build **early (by ~12:30)** so the env bug, if present, is found while a rebuild is still cheap.

### 1.3 Convex — deploy, seed, verify

**P10. `npx convex deploy` is the prod/preview deploy; `npx convex dev` is the dev loop. Do not confuse them.**
Convex CLI doc (read 2026-11-13): "`npx convex deploy` — Deploy to a production or preview deployment"; "This is typically used for deploying to a prod or preview deployment manually or from CI; to deploy to your dev deployment when developing, use `npx convex dev`." Deploy "typecheck[s] your Convex functions", "regenerate[s] the generated code in `convex/_generated`", "bundle[s] your Convex functions", then "push[es] your functions, indexes, and schema to production. Once this command succeeds the new functions will be available immediately."
- Source: https://docs.convex.dev/cli/overview (read 2026-11-13) and https://docs.convex.dev/cli/reference/deploy (read 2026-11-13)
- Automation pattern: **script one command, `npx convex deploy --dry-run` first, then the real deploy.** The deploy reference lists `--dry-run` ("Print out the generated configuration without deploying"), `--typecheck <mode>`, `--codegen <mode>`, `--message <message>` (audit-log message), and `--cmd <command>` (run a command, e.g. a frontend build, with the Convex URL injected via `--cmd-url-env-var-name`).
- Target selection (same CLI doc): if `CONVEX_DEPLOY_KEY` is set (typical in CI) it selects that deployment; else if `CONVEX_DEPLOYMENT` is set, the target is the **production** deployment of that project. **Failure mode this creates:** running `npx convex deploy` from a shell that still has a dev `CONVEX_DEPLOYMENT` is *intended* to hit prod — but running it from a shell with a *stale/wrong* `CONVEX_DEPLOY_KEY` silently hits the wrong deployment. Mitigation: `echo $CONVEX_DEPLOYMENT` / check the deploy output's deployment name in the log line before proceeding; never export the key in a shared terminal without naming the deployment aloud in the run log.

**P11. Deploy keys are the non-interactive path; interactive login is the trap.**
Same CLI doc: `CONVEX_DEPLOY_KEY` is "typical in CI". `npx convex dev` on first run "will ask you to log in your device" — an interactive browser flow that blocks a headless/agent terminal. Pattern: **pre-generate the deploy key before the sprint (dashboard → Settings → Deploy Keys — dashboard path per Convex docs search result, CHƯA ĐỌC as a clicked-through page in this session) and store it as an env var, never in the repo.** If `npx convex deploy` ever prompts for login mid-sprint, stop: the key is missing, and the fix is to set the key, not to click through a login in the middle of a timed build.

**P12. Seed with an idempotent `internalMutation`, run it with `npx convex run`.**
Convex's own seeding guide (read 2026-11-13): three ways to add data — dashboard manual entry, `npx convex import` (CSV / JSON array / JSONL / zip; `--replace` / `--append`; `--prod` required for prod), and **seeding in code** — "my favored approach". The guide recommends "an `internalMutation`… to prevent any public client from calling your mutation", as the default export in `convex/init.ts` so it can be run as `npx convex run init`, and notes it should be "safe to call many times" (return early if data already exists). It also documents `npx convex deploy --cmd 'npm run build' --preview-run init` to seed a fresh preview deployment automatically.
- Source: https://stack.convex.dev/seeding-data-for-preview-deployments (read 2026-11-13)
- CLI doc corroboration: "`npx convex run <functionName> [args]` — Run a public or internal Convex query, mutation, or action… Add `--watch`… Add `--push` to push local code… Use `--prod` to run functions in the production deployment." Also `npx convex data <table>` ("Display a simple view… in the command line") and `npx convex import --table <tableName> <path>`.
- Source: https://docs.convex.dev/cli/overview (read 2026-11-13)
- Automation pattern for tomorrow: **one idempotent seed mutation (`convex/init.ts`, `internalMutation`, early-return if already seeded) + one script line `npx convex run init --prod` (or without `--prod` for dev) + one verification line `npx convex data <table> --limit 5`.** The verify step is the gate: a seed that "ran" but wrote zero rows (schema mismatch — `npx convex import` "will fail" on schema mismatch per the seeding guide) must be caught by reading the table back, not by the exit code alone. **Never use a destructive reset seed on the demo deployment** — the guide's reset pattern ("clear tables, and re-initialize") is for breaking schema changes in dev; after 15:00 on demo day the schema is frozen (demo-bunker rule) and a reset would wipe the demo data the judges will see.

**P13. Logs and health are cheap, scriptable checks.**
CLI doc: `npx convex logs` ("Tail deployment logs without deploying"; `--prod` tails prod), `npx convex insights` ("Show health insights… over the last 72 hours. Reports OCC conflicts and resource limit issues"), `npx convex env list/get/set/remove` (with `--prod` for prod; "to avoid secrets from ending up in your terminal shell history, you can pass the value via stdin, from a file, or interactively").
- Source: https://docs.convex.dev/cli/overview (read 2026-11-13)
- Pattern: after every deploy, run `npx convex logs --prod` for 30 seconds in a background terminal and `npx convex data <main-table>` once. If the action (`runAi`) throws, the log shows it before the phone test does.

### 1.4 Supabase Edge Functions — deploy + secrets

**P14. Deploy is one command per function; link once, then deploy by name.**
Supabase CLI reference (encountered via search; the deploy-flags section was read in search output, **CHƯA ĐỌC as a fully opened primary page** — the flags below are corroborated by multiple independent secondary sources and by the Supabase secrets doc, but treat the exact flag spelling as "verify with `supabase functions deploy --help` before first use"): `supabase functions deploy <function-name>`, `supabase functions deploy <function-name> --no-verify-jwt`, `supabase functions deploy <function-name> --project-ref <ref>`, `supabase link --project-ref <ref>`, `supabase functions list`.
- Sources: https://supabase.com/docs/guides/functions/secrets (read 2026-11-13, for secrets — see P15); CLI flags via https://docs-git-feat-storage-explorer-keyboard-nav-supabase.vercel.app/docs/reference/cli/supabase-completion-fish (Supabase CLI reference mirror, **CHƯA ĐỌC** — opened only via search snippet).
- Pattern: **link once before the sprint (`supabase link --project-ref <ref>`), then the deploy script is a single line with `--project-ref` repeated explicitly** so it works even if the link state is lost. `--no-verify-jwt` only if the function is designed to be called without a Supabase user JWT (the existing skeleton's design decision — do not flip this flag mid-sprint; flipping it changes the auth surface and invalidates the earlier phone test).

**P15. Secrets: set via CLI, read via `Deno.env.get`, never in the repo; a secret change does NOT need a redeploy (secondary claim).**
Supabase secrets doc (read 2026-11-13): "Set secrets for your production Edge Functions in the Supabase Dashboard or with the Supabase CLI." "Creating or deleting a production secret requires the Owner or Administrator role." "A secret name can't start with `SUPABASE_`. That prefix is reserved." Locally, "Edge Functions read secrets from `supabase/functions/.env`. The local stack loads that file on `supabase start`." "Add the file to your `.gitignore`, along with every other env file you create. A `.env` file committed to Git exposes every secret in it." "Read an environment variable with `Deno.env.get`, passing the name of the variable."
- Source: https://supabase.com/docs/guides/functions/secrets (read 2026-11-13)
- Commands (from the same doc's CLI section; exact subcommand spelling `supabase secrets set` / `supabase secrets list` corroborated by the doc text): `supabase secrets set GEMINI_API_KEY=…` (individual) or `supabase secrets set --env-file .env` (bulk from a gitignored file). **Secret-rotation without redeploy** ("hosted functions pick up new secrets immediately — no redeploy required for the secret itself; you still redeploy when the function code changes") is stated in secondary material (https://stacksiren.com/blog/supabase-edge-function-secrets, **CHƯA ĐỌC** as an opened page) — treat as **likely but unverified**: on demo day, after any secret change, still run one live `curl` probe of the function URL and read the response before declaring it fixed. That probe costs one Gemini call — budget it.
- **Failure mode:** `Deno.env.get("GEMINI_API_KEY")` returning `undefined` almost always means "the value never reached the runtime" (same doc: "A variable that comes back empty usually means the value never reached the runtime"). The doc's own diagnostic pattern is valuable: **ship a probe that returns `configured: true/false`, never the value itself** ("replace its contents to read the secret and report whether it arrived. Return the result of the check rather than the value, so the response never carries the secret"). The skeleton should keep a `/health`-style probe that reports secret-presence as a boolean — that is the 10-second check that distinguishes "secret missing" from "Gemini down" from "Convex action broken".

**P16. Verify the deployed function with `curl` before the phone ever touches it.**
Pattern (standard, from the Supabase deploy guides encountered — **CHƯA ĐỌC** as a primary doc page; the endpoint shape `https://<project-ref>.supabase.co/functions/v1/<name>` is corroborated by multiple secondary sources): `curl -X POST https://<ref>.supabase.co/functions/v1/<fn> -H "Authorization: Bearer <anon-key>" -d '{"…"}'`. Run it once after deploy, once after any secret change, and log the HTTP status + latency. A 200 with a stubbed/echo payload proves deploy + routing; a real AI payload proves the Gemini key. Do the stubbed probe first (0 Gemini calls), the real probe second (1 call), and count both in the call budget.

### 1.5 Gemini free tier — 429 handling and call budgeting (the highest-risk area)

**P17. Google no longer publishes per-model free-tier RPM/TPM/RPD numbers. Any quoted number is stale.**
Google's rate-limits page (read 2026-11-13, via aistudio.google.com/docs/rate-limits): "Rate limits depend on a variety of factors (such as your usage tier) and can be viewed in Google AI Studio." "Specified rate limits are not guaranteed and actual capacity may vary." The only per-model numbers still published on that page are for `gemini-omni-1.2-flash` (Free: "Not supported") and `gemini-decision-1` (Free: 200 RPM / 50,000 TPM / 10,000 RPD) — **neither is the demo model**. A secondary analysis (read 2026-11-13) confirms the tables were removed in August 2026 and "any guide quoting you an RPM figure is quoting something that no longer exists", including the widely repeated "15 RPM / 1,500 RPD".
- Sources: https://aistudio.google.com/docs/rate-limits (read 2026-11-13); https://continuumcode.ai/guides/gemini-resource-exhausted/ (read 2026-11-13)
- **Consequence for tomorrow: the "~20 free Gemini calls" planning cap in the task brief is a planning cap, not a Google-published quota.** Do not "verify" it by quoting a blog. The only authoritative numbers are in AI Studio → Rate Limit page for the actual project (https://aistudio.google.com/rate-limit — linked from the rate-limits page). **Pre-sprint action (human, 2 minutes): open AI Studio, read the project's live limits for `gemini-3.5-flash-lite`, write them in the run log.** If AI Studio shows a daily allowance at or below the calls already spent in testing, the demo plan must switch to STUBBED mode + Groq fallback earlier — that decision cannot be made from any published table.

**P18. What Google *does* still publish — and what to build on.**
From the same rate-limits page (read 2026-11-13):
- "Rate limits are usually measured across three dimensions: Requests per minute (RPM), Tokens per minute (input) (TPM), Requests per day (RPD). Your usage is evaluated against each limit, and exceeding any of them will trigger a rate limit error."
- "**Rate limits are applied per project, not per API key.** Requests per day (RPD) quotas reset at **midnight Pacific time**."
- "Rate limits are more restricted for experimental and preview models."
- Spend-based limits: Free tier = **N/A** (no spend-based limit); Tier 1 = $10 / 10 min; Tier 2/3 = $200 / 10 min. "If you hit a spend-based rate limit, the API returns a `429 RESOURCE_EXHAUSTED` error." (Free tier has no spend cap to hit — the binding constraints are RPM/TPM/RPD only.)
- "If you hit a spend-based rate limit… Wait and retry after a short period."
- Source: https://aistudio.google.com/docs/rate-limits (read 2026-11-13)
- Design consequences: (a) minting a second API key in the same project buys **zero** headroom — never waste sprint time on it; (b) a daily-quota exhaustion at 14:00 Hanoi time does **not** reset until midnight Pacific (15:00 Hanoi next day) — it is unrecoverable within the demo, so the fallback must be a *different model* (limits are per model) or a *different provider* (Groq), not a retry; (c) never link billing (task rule) — Tier 1 requires "Set up and link an active billing account", which the free-only rule forbids.

**P19. The two 429s need opposite responses — branch on the error, don't blind-retry.**
Secondary analysis quoting Google's API-errors doc verbatim (read 2026-11-13; the ai.google.dev/api-errors page itself was **CHƯA ĐỌC** as a direct open, so the verbatim quotes below are attributed to the secondary source that quotes them):
- `rate_limit_exceeded` — "You have exceeded the per-minute or per-second request or token limit." Recommended action: "Wait and retry with exponential backoff." Clears in seconds.
- `quota_exceeded` — "You have exceeded your daily quota." Recommended action: "Wait until the quota resets or request a quota increase." Clears at midnight Pacific.
- Legacy `generativelanguage` endpoint returns the classic envelope: `{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED", "details": [/* may carry QuotaFailure or RetryInfo */]}}`. The discriminator in that envelope is the `quotaId` in `QuotaFailure` (contains `PerMinute` vs `PerDay`) and `RetryInfo.retryDelay`.
- Source: https://continuumcode.ai/guides/gemini-resource-exhausted/ (read 2026-11-13); corroborated by https://teamorouter.com/blogs/gemini-api-429-resource-exhausted (search result, **CHƯA ĐỌC** as opened page).
- Pattern for the Edge Function (implement **before** the sprint if not already present; it is ~15 lines):
  1. On 429, parse the body: if `code === "quota_exceeded"` **or** `quotaId` contains `PerDay`/`Daily` **or** the message contains `limit: 0` → **do not retry; fail over immediately** to Groq, and surface `mode: "fallback"` to the app so the demo narrator can say so honestly.
  2. Else if `rate_limit_exceeded` / `PerMinute` → retry with exponential backoff + jitter, honouring `RetryInfo.retryDelay` when present; max 3 attempts, delays ~1s → 2s → 4s (Google's troubleshooting guidance as quoted in secondary sources: "wait about 1 second, then 2, then 4, then 8, with a little random jitter"; the Python SDK "automatically retries transient errors up to four times with an initial delay of approximately 1 second and a maximum delay of 60 seconds" — **both SDK-retry claims are secondary, CHƯA ĐỌC in Google's own troubleshooting doc**; the Edge Function is hand-rolled `fetch`, so it must implement its own retry regardless of what any SDK does).
  3. On 503 (`UNAVAILABLE`) → same backoff path as (2), then fail over to Groq.
  4. **Count every attempt, including retries, in the call budget.** A "3-retry" policy turns 1 logical call into up to 4 billable calls against the daily quota. With a ~20-call day budget, that means at most ~5 logical AI calls if retries fire — which is why the demo script must have exactly **one** rehearsed live AI call and everything else stubbed/cached.
- **Groq fallback limits (secondary only, CHƯA ĐỌC as official Groq docs):** multiple secondary sources read via search (2026-11-13) agree `openai/gpt-oss-120b` on Groq Free is 30 RPM / 1,000 RPD / 8,000 TPM / 200,000 TPD, per organization (not per key), RPD resetting at midnight UTC, 429 with a `retry-after` header. Sources: https://weneedai.net/groq-free-tier-limits/ and https://ficelle.ai/providers/groq/ (search results, **CHƯA ĐỌC** as opened pages). **Verify in the Groq console Limits page before relying on it** — Groq's own docs page is console.groq.com/docs/rate-limits (cited by those secondaries, **CHƯA ĐỌC**). Groq's TPM (8,000) is the binding constraint, not RPM: one long prompt can exhaust a minute's tokens in seconds. Keep fallback prompts short.

**P20. Call budgeting pattern: a visible counter + a hard stop.**
No source publishes a "budget counter" pattern; this is a process pattern derived from P17–P19 (mark as **recommendation, not a sourced claim**). Implementation: a Convex table/field (or a line in the run log) incremented on every Edge Function invocation that reaches a provider; the app shows `STUBBED` vs `LIVE` mode explicitly; the demo script names its single live call in advance ("the judges will see exactly one live AI call; every other screen uses cached/stubbed data"). **A silent fallback is worse than a visible one:** if the app falls back to Groq or stub without telling the presenter, the presenter will narrate "Gemini is answering live" while it is not — a credibility failure in front of judges. Surface the provider + mode in the UI (small footer text is enough).

### 1.6 Kill-and-reopen verification — Maestro, adb, and the manual script

**P21. Maestro: YAML flows, `launchApp` / `killApp` / `stopApp` / `clearState` — and it does NOT build or install the app.**
Maestro skill doc (read 2026-11-13): "Maestro drives a real app on a device/emulator from a YAML flow: launch the app, tap/assert on UI elements, wait for content. One flow = one `.yaml` file." "Maestro does **not** build or install the app — the app under test must already be installed on a booted device/simulator. Flows reference it by `appId` and start it with `launchApp`." Install: `curl -fsSL "https://get.maestro.mobile.dev" | bash` (macOS/Linux/WSL); "Java 17+ is required"; "Pin the version for reproducible CI — the install script honours `MAESTRO_VERSION`". Commands: `launchApp: {clearState: true, stopApp: false, permissions: …}`; "`stopApp` — graceful stop (Android: am force-stop) — kills the process"; "`killApp` — force kill"; "`clearState` — clear data without launching". "Maestro auto-waits for the UI to settle between commands — explicit sleeps are rarely needed." `extendedWaitUntil: {visible: {id: "done"}, timeout: 60000}` is "the explicit 'wait until X appears' — use for slow ops" (i.e. for the AI call). `maestro test flow.yaml --debug-output ./debug` keeps "the commands log, screenshots, and the view hierarchy at the point of failure". `maestro test flow.yaml --format junit --output report.xml` for machine-readable results.
- Source: https://github.com/digidem/comapeo-core-react-native/blob/HEAD/.claude/skills/maestro-mobile-e2e/SKILL.md (read 2026-11-13)
- Corroboration (DeepWiki summary of Maestro docs, search result, **CHƯA ĐỌC** as opened page): "`stopApp` attempts to close the application gracefully, similar to how a user would close it, while `killApp` forcefully terminates the process."

**P22. The kill-reopen flow that mirrors the judges (Maestro version).**
Derived from P21 (recommendation, not a quoted flow):
```yaml
appId: <android.package from app.json>
name: kill-reopen smoke
---
- launchApp:
    clearState: false        # keep state: judges reopen the SAME app, not a wiped one
- assertVisible: "<home marker text or testID>"
- tapOn: { id: "<main-ai-button testID>" }
- extendedWaitUntil:
    visible: { id: "<ai-result testID>" }
    timeout: 60000
- killApp                    # force kill — the judges' "close fully"
- launchApp:
    stopApp: false
- assertVisible: "<home marker>"          # app relaunched cold
- assertVisible: "<persisted result text>" # data survived the kill (Convex, not memory)
- takeScreenshot: "reopened"
```
Key choices: `clearState: false` on both launches (clearing state tests a fresh install, not a reopen — the wrong test); `killApp` (not `stopApp`) for the kill step, because the judges "close fully"; `extendedWaitUntil` (not a fixed sleep) for the AI result, because Gemini latency varies; assertions on `testID` (`id:` selector), not on copy text — "Put stable `testID`s on every interactive element — text selectors break when copy changes" (same Maestro skill source as P21). **Prerequisite: every interactive element + every asserted result needs a `testID` in the app code.** If testIDs are not in the skeleton yet, adding them is a 10-minute code task that must happen before the first Maestro run — Maestro cannot be retrofitted onto an app with no stable selectors without falling back to fragile text matching.

**P23. Maestro's hard limits for tomorrow.**
From the same skill doc (read 2026-11-13): "In a **development build**, the React Native dev menu, the LogBox red/yellow error overlays, the Reload/fast-refresh overlay, and React Native DevTools can all appear mid-test and intercept taps. They are **all disabled in a release/production build**. So: **Best fix: test against a release/preview build**." And: "**Avoid Expo Go** for serious e2e: you can't `launchApp` a custom `appId` there." Also: "Do **not** `clearState` in the local variant — it wipes the dev launcher's saved Metro URL."
- Consequence: **Maestro only runs against the preview APK, never Expo Go, never a dev-client build.** It also needs a booted device/emulator visible to `adb devices` / `maestro list-devices`, and Java 17+. **Install + first-run cost is ~15–20 minutes** (install, Java check, device pairing, first flow debug). That cost is only worth paying if it is done **before** the sprint (tonight) or in the first hour; installing Maestro at 15:00 to "verify" the final build is a schedule risk, not a safety net. If Maestro is not installed and green before 12:00, drop it and use the adb/manual script (P24) instead.

**P24. The adb fallback (no Maestro install needed) — and what is NOT verified about it.**
From the Maestro skill doc (read 2026-11-13): `adb devices` (device IDs), `adb install app.apk` (before `maestro test`), and `stopApp` = "Android: am force-stop". The `am force-stop <package>` semantics ("Force-stop everything associated with `package`") are documented on Android Developers — **the Android Developers adb page was NOT opened in this session (browser rate-limited on the attempt, 2026-11-13), so the exact `am start` syntax below is CHƯA ĐỌC and must be verified on-device before it is trusted:**
- `adb shell am force-stop <package>` — force-stop (corroborated by the Maestro doc's `stopApp` description; treat as verified in substance).
- `adb shell am start -W -n <package>/<activity>` — relaunch and wait for launch to complete (**CHƯA ĐỌC** — verify with `adb shell am start --help` on the demo laptop; the `-W` flag and the `/.MainActivity` activity name are the parts most likely to differ per app).
- `adb shell pm list packages | grep <name>` — confirm install (**CHƯA ĐỌc** as a read page; standard adb, low risk).
- `adb logcat -b crash` — capture a native crash after a failed reopen (mentioned in Maestro-adjacent secondary material, **CHƯA ĐỌC**).
- Manual script (no tooling at all, always available): a printed 6-step checklist — (1) note the on-screen result text, (2) swipe the app away / force-stop from Settings, (3) confirm the process is gone (app not in recents), (4) tap the launcher icon, (5) confirm the home screen loads, (6) confirm the same result text is still there (proves Convex persistence, not in-memory state). **The manual script is the ultimate fallback and must exist on paper even if Maestro works** — if the laptop dies, the USB cable fails, or `adb` refuses the device 10 minutes before the pitch, the human script is the only verification left.

**P25. Phone smoke-test tooling beyond Maestro (cut first if time runs short).**
- **`@expo/agent-cli` `smoke`** (SDK 58 changelog, read 2026-11-13): "`smoke` is `dev`, plus a screenshot, plus stop: it checks that you can actually start developing the app on your machine." Experimental, dev-loop only — **not** a kill-reopen test, **not** for the preview APK. Nice-to-have; cut.
- **EAS Workflows `maestro` jobs** (EAS env doc, read 2026-11-13): "Maestro jobs (`maestro` and `maestro-cloud`): The environment defaults to `preview`." That is a CI pattern (`.eas/workflows/`), not a demo-day pattern — setting up a workflow YAML mid-sprint costs more than running Maestro locally once. Cut.
- **`npx expo start` + Expo Go QR** — the fastest UI loop, already covered by P8. Keep for UI iteration only.
- **Screenshot discipline (no tool needed):** after every preview-APK install, take a phone screenshot of (a) home, (b) AI result, (c) reopened home. Three screenshots per build, named by build number. If a later build regresses, the screenshots — not memory — prove when it broke.

---

## 2. Ranked checklist for tomorrow (automation-value vs risk)

Ordering principle: **a fully automated step that fails silently is worse than a supervised one.** Rank = (minutes saved × probability it works first time) − (damage if it fails silently). Anything that touches the demo artifact, the daily AI budget, or the schema is human-supervised even if a script runs it — the human reads the output before the next step starts.

### Tier S — Do first, automate, verify by reading output (before 11:00 or in the first hour)

| # | Step | Automate how | Human gate |
|---|------|--------------|-----------|
| S1 | **Read live Gemini limits in AI Studio** (P17) | None — open https://aistudio.google.com/rate-limit, read `gemini-3.5-flash-lite` RPM/TPM/RPD for the actual project, write numbers in run log | Human reads + records. This decides the whole AI budget. No script can do it. |
| S2 | **Freeze `eas.json` + EAS preview env** (P1–P3) | One `eas.json` with preview profile + `"environment": "preview"`; `EXPO_PUBLIC_CONVEX_URL` in preview env | Human runs `eas env:list --environment preview` and eyeballs the value. A typo here = a wasted build. |
| S3 | **Deploy Convex + seed + verify read-back** (P10–P13) | Script: `npx convex deploy --dry-run && npx convex deploy && npx convex run init --prod && npx convex data <table> --limit 5` | Human reads the `data` output (rows present?) and 30 s of `npx convex logs --prod`. Exit code 0 ≠ data present. |
| S4 | **Deploy Supabase function + secret-presence probe** (P14–P16) | Script: `supabase functions deploy <fn> --project-ref <ref> && curl <fn-url> (stub probe)` | Human reads the probe: `configured: true`? HTTP 200? One real-AI `curl` (1 call) only after the stub passes. |
| S5 | **First preview APK build, early** (P4, P9) | `eas build -p android --profile preview --non-interactive --wait --json` in a dedicated terminal | Human watches the build page; on finish, downloads APK, installs on the real phone, opens it, confirms Convex URL works (home loads data). Target: build started by ~12:30. |

### Tier A — Automate, supervised (11:00–14:00)

| # | Step | Automate how | Human gate |
|---|------|--------------|-----------|
| A1 | **Gemini 429 branch + Groq failover in the Edge Function** (P19) | Code (pre-sprint if possible): parse `quota_exceeded` vs `rate_limit_exceeded`/`PerMinute`; backoff 1s→2s→4s + jitter, max 3; fail over to Groq on daily quota / `limit: 0` / 503-after-retries | Human triggers one forced-429 test (e.g. 3 rapid calls) and reads the log: did it back off, or fail over, or loop? A retry loop that cannot tell the two 429s apart will burn the daily budget in seconds. |
| A2 | **Call-budget counter, visible in UI** (P20) | Convex counter incremented per provider call; UI footer shows `LIVE (Gemini)` / `FALLBACK (Groq)` / `STUBBED` | Human announces the mode before each demo run. Never let the app silently change provider mid-pitch. |
| A3 | **Maestro kill-reopen flow** (P21–P23) | Flow file from P22; `maestro test maestro/kill-reopen.yaml --debug-output ./debug` | Human watches the run + reads the failure screenshot/hierarchy on failure. **Only if Maestro is installed and green before 12:00** (P23); otherwise drop to A4. |
| A4 | **adb install + force-stop + relaunch script** (P24) | 5-line shell script: `adb install -r app.apk && adb shell am force-stop <pkg> && adb shell am start -W -n <pkg>/.MainActivity` (activity name **CHƯA ĐỌC** — verify first) | Human runs it, watches the phone, confirms persisted result by eye. This is the fallback if A3 is dropped. |
| A5 | **testIDs on every interactive + asserted element** (P22) | Code: add `testID` props during UI build (cheap if done as you go, expensive as retrofit) | Human greps for missing testIDs before the first Maestro run. No testIDs → Maestro falls back to fragile text matching → flaky "verification" worse than manual. |

### Tier B — Human-supervised, script-assisted (14:00–16:00, the freeze window)

| # | Step | Automate how | Human gate |
|---|------|--------------|-----------|
| B1 | **Final preview build** (P4) | Same command as S5, `--wait --json` | Human only. No code changes after this build starts. One build, one install, one full manual pass. |
| B2 | **Rebuild slot reserved for the env bug** (P3) | None — it is a time reservation, not a script | If the final APK shows no Convex data, the fix is: correct the preview env → **rebuild** → reinstall → retest. Do not attempt an OTA/expo-update fix; `EXPO_PUBLIC_*` is build-time. |
| B3 | **Kill-reopen verification on the final APK** (P22/P24) | Maestro flow or adb script or paper checklist — whichever is already green | **Human, on the real phone, by eye, twice.** Once after install, once 10 minutes before the pitch (final sanity). This is the 40-point gate; no script result substitutes for a human seeing the reopened app. |
| B4 | **Demo-bunker: schema freeze after 15:00** (task rule) | None — a rule, enforced by refusing `convex deploy` after 15:00 | Human. Any "small schema fix" after 15:00 risks a deploy that changes validation under the demo data. Fix UI copy instead; fix data via the dashboard, not the schema. |
| B5 | **AI call freeze: last live call by ~15:30** (P17–P20) | Counter (A2) | Human counts. Reserve ≥2 calls for the pitch itself (1 rehearsed + 1 spare if the first 429s). Everything after 15:30 is STUBBED. |

### Tier C — Keep human, do NOT automate tomorrow

| # | Step | Why not automated |
|---|------|-------------------|
| C1 | Deciding STUBBED vs LIVE vs Groq for the pitch | Judgement call from the live AI Studio numbers (S1) + remaining budget (A2). A script cannot weigh "judges value a live call" against "we have 2 calls left". |
| C2 | Narrating the demo / handling a live failure on stage | If Gemini 429s mid-pitch, the human says "falling back to our Groq model" (visible mode, A2) and continues. No auto-retry loop should be making that decision on stage. |
| C3 | Any new Maestro flow written after 14:00 | A new flow written under time pressure tests the flow, not the app. Use the already-green flow or the paper checklist. |
| C4 | `eas build --clear-cache` as a first resort | Slower build, same failure most of the time. Only after a failed build with a cache-suspect error. |
| C5 | Adopting `@expo/agent-cli` / EAS Workflows / Maestro Cloud | Experimental or CI-shaped tools (P6, P25). Learning curve on demo day exceeds their value. |

---

## 3. Failure modes + recovery (per automated step)

| Step | Failure mode | Symptom | Recovery (in order) | Cost |
|------|-------------|---------|---------------------|------|
| S2 EAS env | `EXPO_PUBLIC_CONVEX_URL` missing/typo in preview env | APK opens, home shows no data / Convex connection error | 1. `eas env:list --environment preview` (read value). 2. Fix env. 3. **Rebuild** (P3 — no shortcut). 4. Reinstall + retest. | 1 build slot + ~15–30 min |
| S2 EAS env | Wrong environment picked (auto-detection) | Same as above, or dev URL in a preview build | Set `"environment": "preview"` explicitly in `eas.json` (P2), rebuild. | 1 build slot |
| S5/B1 EAS build | Build fails (native error, Metro bundling error) | `eas build` exits non-zero / dashboard shows failed | 1. Read the build log tail (dashboard or `--verbose-logs` retry is **not** needed — the log is on the dashboard). 2. Fix the named error. 3. Retry; only if the error smells like cache, add `--clear-cache` (P5). 4. If 2 builds fail the same way, stop rebuilding and demo from Expo Go + the *previous* good APK (see below). | 1 build slot per retry |
| S5/B1 EAS build | Build "succeeds" with `--no-wait` but artifact is stale | Downloaded APK behaves like the previous version | Never use `--no-wait` for demo builds (P4). Use `--wait --json`; verify with `eas build:list --status finished` + build ID + timestamp before downloading. | — (prevented) |
| S5/B1 EAS build | Free build quota exhausted | `eas build` rejected / `eas account:usage` shows 0 left | **CHƯA ĐỌC** — quota numbers unverified (P7). Recovery: stop building; demo the last good APK; use Expo Go for any further UI iteration. Do not create a second Expo account to dodge quota (untested, and account-sharing during a judged demo is a needless risk). | Loss of rebuild slot |
| S3 Convex deploy | Wrong deployment targeted | Deploy "succeeds" but the phone (pointing at prod) shows old functions | Check deploy output's deployment name; `npx convex deploy` target rules (P10). Re-deploy with the correct `CONVEX_DEPLOY_KEY` / `CONVEX_DEPLOYMENT`. | 1 deploy (~1 min) |
| S3 Convex deploy | Interactive login prompt blocks the terminal | `npx convex deploy` hangs asking for login | Stop. Set `CONVEX_DEPLOY_KEY` (P11). Never click through a browser login mid-sprint. | ~2 min |
| S3 Convex seed | Seed "runs" but writes 0 rows / schema mismatch | `npx convex data <table>` empty; app home empty | Read the seed log; fix the seed to match the current schema (P12); re-run `npx convex run init --prod`. Do **not** run a destructive reset on the demo deployment. | ~5 min |
| S3 Convex | Schema change after 15:00 breaks demo data | App crashes / validation errors on reopen | Demo-bunker rule (B4): no deploys after 15:00. If already broken: restore by deploying the last known-good `convex/` from git (if versioned) — **CHƯA ĐỌC**: Convex has no documented one-click rollback in the CLI pages read; `npx convex deploy` "does not roll back" per secondary material (**CHƯA ĐỌC**). Prevention is the only reliable recovery. | Potentially demo-ending |
| S4 Supabase deploy | Function 404 after deploy | `curl` returns 404 | 1. `supabase functions list` — is the name there? 2. Redeploy with explicit `--project-ref` (P14). 3. Check the name matches the Convex action's fetch URL exactly. | ~2 min |
| S4 Supabase secret | `GEMINI_API_KEY` undefined in function | Probe returns `configured: false`; AI calls fail | 1. `supabase secrets list` (names only). 2. `supabase secrets set GEMINI_API_KEY=…` (P15). 3. Re-probe (do not assume a secret change needs no redeploy — verify with the probe). | 1 probe call |
| S4 Supabase | `--no-verify-jwt` flipped / JWT 401 | `curl` without JWT → 401, or with JWT → works | Decide the flag once, before the sprint (P14). Do not flip mid-sprint; flipping invalidates the earlier phone test. If 401 appears, the caller's `Authorization` header is wrong, not the function — check the Convex action's fetch headers first. | ~5 min |
| A1 Gemini 429 (per-minute) | `rate_limit_exceeded` / `PerMinute` | AI call fails fast, retryable | Backoff 1s→2s→4s + jitter, max 3 attempts (P19). If it still fails, fail over to Groq. **Count retries in the budget.** | ≤3 extra calls |
| A1 Gemini 429 (daily) | `quota_exceeded` / `PerDay` / `limit: 0` | AI call fails; retrying cannot help until midnight Pacific | **Do not retry.** Fail over to Groq immediately (P19) or switch to STUBBED. Announce the mode (A2). A retry loop here burns the budget and the clock. | 0 extra Gemini calls; 1 Groq call |
| A1 Gemini 503 | `UNAVAILABLE` (busy) | Transient failure | Backoff + retry (P19), then Groq. | ≤3 extra calls |
| A1 Groq fallback | Groq 429 (TPM 8,000/min is the binding limit) | Fallback also fails | Shorten the prompt (fewer tokens) and retry once after the `retry-after` header; else STUBBED. Groq limits are secondary-source only (P19) — verify in console pre-sprint. | 1 retry |
| A3 Maestro | Maestro not installed / Java missing / device not found | `maestro test` fails before the first command | Drop Maestro (P23). Fall back to A4 adb script, then to the paper checklist (P24). Do not debug a test harness after 12:00. | ~15 min lost if attempted late |
| A3 Maestro | Flow fails on a dev-menu/LogBox overlay | Tap intercepted; flow fails mid-run | Run against the preview APK only (P23) — overlays do not exist in release builds. Never "fix" by adding overlay-dismiss taps to the demo flow. | Re-run on APK |
| A3/A4 Kill-reopen | App reopens but the AI result is gone | Result was in-memory state, not Convex | Bug in the app (result not persisted). Fix: persist the result via a Convex mutation before showing it; re-verify. This is exactly what the kill-reopen test exists to catch — do it early (S5), not at 15:45. | Code fix + rebuild |
| A3/A4 Kill-reopen | `adb` cannot see the phone / USB debugging off | `adb devices` empty | Check cable, USB debugging, "allow" prompt on the phone. If unfixable in 5 minutes, use the paper manual checklist (P24) — it needs no laptop at all. | 5 min, then manual |
| B3 Final verify | Final APK fails kill-reopen at 15:45 | Reopened app blank / crash | 1. Check `adb logcat -b crash` (**CHƯA ĐỌC** flag). 2. If the previous APK passed, reinstall the previous APK and re-verify — a known-good older build beats a broken newer one. 3. If no APK passes, pitch from Expo Go with the failure narrated honestly (scores 0 for the phone-demo criterion but preserves the other 60 points — do not fake a phone demo). | — |

**Global fallback ladder (memorise this order):** last good preview APK → previous preview APK → Expo Go (UI only, phone-demo points lost) → honest narration of the failure. Never present a browser/emulator recording as a phone demo — the task brief states that scores 0, and presenting it as live would be misrepresentation.

---

## 4. What was NOT verified (CHƯA ĐỌC list — do not cite as fact)

- EAS Free plan build quota (15+15/month or any other number) — no Expo pricing page opened.
- `gemini-3.5-flash-lite` free-tier RPM/TPM/RPD numbers, and the "~20 calls" planning cap — Google publishes no per-model table any more (P17); the only authority is AI Studio for the actual project.
- Groq `gpt-oss-120b` Free limits (30 RPM / 1,000 RPD / 8,000 TPM / 200,000 TPD) — secondary sources only; verify in the Groq console.
- Supabase CLI `functions deploy` exact flags (`--no-verify-jwt`, `--project-ref`) and "secret change needs no redeploy" — corroborated secondarily, not fully opened as a primary page; verify with `supabase functions deploy --help`.
- Android `adb shell am start -W -n <package>/<activity>` exact syntax and `adb logcat -b crash` — Android Developers page not opened (browser rate-limited on the attempt); verify on-device.
- Google SDK automatic retry ("up to four times, ~1s initial, 60s max") and the verbatim `rate_limit_exceeded` / `quota_exceeded` descriptions — quoted from a secondary analysis of Google's api-errors doc, not read on ai.google.dev directly.
- "EAS builds take 5–20 minutes" and "Maestro install takes 15–20 minutes" — planning estimates, not published figures.
- Metro CVE-2025-11953 details — taken from the task brief as given context, not re-verified.
- Convex "deploy does not roll back" — secondary claim, not in the CLI pages read.

---

## 5. Sources (all accessed 2026-11-13)

**Read in full (primary):**
- https://docs-expo-dev.btglss.net/build/eas-json/ — Expo, Configure EAS Build with eas.json (mirror of docs.expo.dev)
- https://docs.expo.dev/eas/environment-variables/usage/ — Expo, Using environment variables in Expo Services
- https://pr-49938.expo-docs.pages.dev/eas/cli/ — Expo, EAS CLI reference (mirror)
- https://expo.dev/changelog/sdk-58 — Expo SDK 58 changelog (React Native 0.88, Expo Go only SDK 58, `@expo/agent-cli`, prebuilt `expo-modules-core`)
- https://docs.convex.dev/cli/overview — Convex CLI overview
- https://docs.convex.dev/cli/reference/deploy — Convex, `npx convex deploy` reference
- https://stack.convex.dev/seeding-data-for-preview-deployments — Convex, Seeding Data for Preview Deployments
- https://supabase.com/docs/guides/functions/secrets — Supabase, Edge Function environment variables / secrets
- https://aistudio.google.com/docs/rate-limits — Google, Gemini API Rate limits (per-project enforcement, midnight-Pacific RPD reset, Free spend limit N/A, no per-model tables)
- https://github.com/digidem/comapeo-core-react-native/blob/HEAD/.claude/skills/maestro-mobile-e2e/SKILL.md — Maestro mobile e2e skill (install, flows, `launchApp`/`killApp`/`stopApp`/`clearState`, Expo pitfalls)
- https://continuumcode.ai/guides/gemini-resource-exhausted/ — secondary analysis quoting Google's api-errors doc (two 429 codes, per-model tables removed Aug 2026)

**Used via search results only (CHƯA ĐỌC as opened pages — cited with that caveat where relied on):**
- https://www.canakyuz.co/blog/expo-ota-runtime-version — `--no-wait` + `--latest` race
- https://teamorouter.com/blogs/gemini-api-429-resource-exhausted — 429 `quotaId` discrimination
- https://weneedai.net/groq-free-tier-limits/ and https://ficelle.ai/providers/groq/ — Groq Free limits
- https://stacksiren.com/blog/supabase-edge-function-secrets — secret change without redeploy
- https://docs-git-feat-storage-explorer-keyboard-nav-supabase.vercel.app/docs/reference/cli/supabase-completion-fish — Supabase CLI reference (deploy flags)
- https://developer.android.com/topic/performance/baselineprofiles/manually-create-measure — `adb shell am force-stop` usage (open attempt rate-limited, 2026-11-13)

---

## Tóm tắt tiếng Việt

**Mục tiêu ngày mai (14/11):** demo trên điện thoại thật (40 điểm) — app phải chạy được sau khi tắt hẳn rồi mở lại, AI chạy live đúng 1 lần đã tập trước, còn lại dùng dữ liệu stub/cache.

**4 việc tự động hoá đáng tiền nhất:**
1. **EAS preview APK:** đóng băng `eas.json` (preview + `buildType: apk` + `"environment": "preview"`), đặt `EXPO_PUBLIC_CONVEX_URL` trong EAS environment `preview`. Biến `EXPO_PUBLIC_*` bị nhúng cứng vào bundle lúc build — sai là phải build lại, không có đường tắt. Build đầu tiên trước ~12:30, dùng `eas build --profile preview --non-interactive --wait --json` (đừng dùng `--no-wait`, nó chỉ báo "đã xếp hàng" chứ không báo build xong hay lỗi).
2. **Convex:** deploy bằng `npx convex deploy` (kèm `--dry-run` trước), seed bằng một `internalMutation` chạy lại được nhiều lần (`npx convex run init`), rồi kiểm tra bằng `npx convex data <bảng>` — exit code 0 không có nghĩa là đã có dữ liệu. Sau 15:00 đóng băng schema, không deploy nữa.
3. **Supabase:** `supabase functions deploy <tên> --project-ref <ref>`, secret đặt bằng `supabase secrets set`, kiểm tra bằng probe trả về `configured: true/false` (không bao giờ trả về giá trị secret). Probe stub trước (0 lượt gọi Gemini), probe AI thật sau (1 lượt).
4. **Gemini:** Google đã gỡ bảng giới hạn theo từng model từ tháng 8/2026 — mọi con số RPM/RPD trên blog đều cũ. Chỉ tin số đọc được trong AI Studio của đúng project đó. Lỗi 429 có 2 loại ngược nhau: hết giới hạn theo phút thì chờ rồi thử lại (1s → 2s → 4s + jitter, tối đa 3 lần); hết quota ngày thì **không thử lại**, chuyển ngay sang Groq hoặc stub, vì quota ngày chỉ reset lúc nửa đêm giờ Thái Bình Dương. Đếm cả lượt retry vào ngân sách ~20 lượt. Groq fallback (30 RPM / 8.000 TPM) chỉ là nguồn phụ chưa kiểm chứng chính thức — kiểm tra trong console Groq trước giờ demo.

**Kiểm tra tắt-mở lại (kill-reopen):** dùng Maestro (`launchApp` → `killApp` → `launchApp`, `clearState: false`, chờ kết quả AI bằng `extendedWaitUntil`, assert bằng `testID`) nhưng **chỉ chạy trên preview APK, không chạy trên Expo Go**, và chỉ dùng nếu đã cài + chạy xanh trước 12:00. Nếu không kịp, dùng script `adb` (`am force-stop` rồi mở lại), và luôn có sẵn checklist giấy 6 bước làm bằng tay — khi cáp USB hay laptop hỏng, đó là cách duy nhất còn lại. Kiểm tra bằng mắt người trên điện thoại thật 2 lần: một lần sau khi cài bản cuối, một lần 10 phút trước giờ pitch.

**Nguyên tắc xếp hạng:** bước nào lỗi mà im lặng thì nguy hiểm hơn bước làm tay. Mọi bước chạm tới bản demo, ngân sách AI, hay schema đều có người đọc output trước khi làm bước tiếp theo. Bản APK tốt cuối cùng luôn hơn bản mới bị lỗi — nếu bản cuối hỏng kill-reopen, quay lại bản trước đó đã chạy tốt.

- Tự động hoá chỉ đáng tiền khi nó báo lỗi to và rõ: `--wait` hơn `--no-wait`, đọc lại dữ liệu sau khi seed hơn tin exit code, probe `configured: true/false` hơn đoán secret đã vào chưa.
- Giới hạn miễn phí thay đổi theo thời gian và theo từng project — con số đọc trên blog tháng trước có thể đã sai; nguồn duy nhất đáng tin là trang Rate Limit trong AI Studio / Groq console của đúng project đó.
- Kiểm tra "tắt hẳn rồi mở lại" không phải là kiểm tra cho có: nó là bài kiểm tra duy nhất chứng minh dữ liệu sống trong Convex chứ không phải trong bộ nhớ của app — và nó phải chạy trên đúng bản APK sẽ đem đi pitch, càng sớm càng tốt.
