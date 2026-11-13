/**
 * ai.ts — AI call path + degraded rungs A1–A3 (D55/D56, expert C §3).
 *
 * COORDINATOR DECISIONS (applied, not re-litigated):
 * - C1: AI calls use a 15,000 ms timeout (overrides the verbatim
 *   fetch-with-timeout.ts template's 30 s default — AI calls ONLY;
 *   the template file itself is copied verbatim and untouched).
 * - C2: total cap 2 attempts per tap (1 retry max, 2 s back-off).
 *   Back-off = max(2000 ms, 2^attempt × 1000 ms, Retry-After if present).
 *   A TIMEOUT is NOT retried (expert C §3.3 step 4 reconciliation: the
 *   model call may already be running server-side; a retry would burn a
 *   second Gemini call against the free-tier quota).
 * - C4: ship NON-STREAMING JSON. Named `import { fetch } from 'expo/fetch'`,
 *   `res.body !== null` smoke test (see assertStreams in
 *   lib/fetch-with-timeout.ts — phone-side, needs a live streaming
 *   endpoint), final-text-only fallback labelled if streaming degrades.
 * - C3: no concurrent/duplicate calls for one tap; abort on navigate-away
 *   (caller passes its AbortController signal as externalSignal; an
 *   AbortError from navigate-away is surfaced so the caller can ignore it).
 *
 * NO REAL ENDPOINT IS WIRED HERE. The stub (runAiStub) returns a labelled
 * canned payload and makes NO network call, uses NO key, NO URL. The real
 * path (callAiEndpoint) takes its URL as an argument and there is no
 * default URL anywhere in this scaffold — wiring it needs the human to
 * provide the endpoint URL + keys (NEEDS-HUMAN). Never guess a URL.
 */

import { fetch as expoFetch } from 'expo/fetch';
import seed from './seed.json';
import { ApiError } from './fetch-with-timeout';

/** Generic, idea-agnostic AI result shape (the idea is not chosen yet). */
export interface AiResult {
  id: string;
  input: string;
  title: string;
  summary: string;
  createdAt: string;
  source: 'live' | 'example' | 'cached' | 'seed';
}

export const AI_TIMEOUT_MS = 15_000; // C1
export const AI_MAX_ATTEMPTS = 2; // C2: initial + 1 retry, total cap 2 per tap

/** Canned result (rung A1): same JSON shape as a real result, labelled. */
export const CANNED_RESULT: AiResult = {
  id: 'canned-1',
  input: 'Example input',
  title: 'Example result',
  summary:
    'This is a canned example of the exact output shape (rung A1). It is a genuine, pre-written example — not a live AI answer — and the UI must label it "Example result". The real canned payload is the model output for the exact demo input, pasted in once the idea and demo input land (Sat 09:45); never hand-write a stub to look better than the model.',
  createdAt: '2026-11-13T00:00:00+07:00',
  source: 'example',
};

/**
 * STUB AI function. Returns the labelled canned payload. No network call,
 * no endpoint, no key, no URL. This is the stand-in until the human
 * provides the real endpoint (NEEDS-HUMAN).
 */
export async function runAiStub(input: string): Promise<AiResult> {
  return { ...CANNED_RESULT, input };
}

// ---- Real-call path (unwired — no URL configured) ----

let aiInFlight: AbortController | null = null;

function backoffMs(attempt: number, retryAfterHeader: string | null): number {
  const exponential = Math.pow(2, attempt) * 1000;
  const fixed = 2000; // C2: 2 s back-off
  let backoff = Math.max(fixed, exponential);
  if (retryAfterHeader) {
    const seconds = Number(retryAfterHeader);
    if (Number.isFinite(seconds) && seconds > 0) {
      backoff = Math.max(backoff, seconds * 1000);
    }
  }
  return backoff;
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function isTimeoutError(error: unknown): boolean {
  return error instanceof Error && error.message.startsWith('Request timed out after');
}

function isNetworkError(error: unknown): boolean {
  // The request never reached the server (offline, DNS, socket failure).
  return error instanceof TypeError;
}

/**
 * One AI attempt: named expo/fetch import with a hard 15 s timeout
 * (manual setTimeout + controller.abort() — same mechanism as the
 * verbatim template; AbortSignal.timeout() is not verified on Hermes).
 * Throws TimeoutError on timeout; AbortError from externalSignal means
 * navigate-away/unmount — the caller ignores it.
 */
async function aiAttempt(
  url: string,
  body: string,
  externalSignal?: AbortSignal,
): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), AI_TIMEOUT_MS);
  const onExternalAbort = () => controller.abort();
  if (externalSignal) {
    if (externalSignal.aborted) controller.abort();
    else externalSignal.addEventListener('abort', onExternalAbort, { once: true });
  }
  try {
    return await expoFetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body,
      signal: controller.signal,
    });
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      if (externalSignal?.aborted) throw error; // navigate-away: caller ignores
      throw new Error(`Request timed out after ${AI_TIMEOUT_MS}ms: ${url}`);
    }
    throw error;
  } finally {
    clearTimeout(timer);
    externalSignal?.removeEventListener('abort', onExternalAbort);
  }
}

/**
 * Real AI call (NON-STREAMING JSON). No default URL — the caller must pass
 * one; none exists in this scaffold. C3: throws if an AI call is already
 * in flight for this tap (no double-submit, no background re-fetch while
 * a call is in flight). C2: at most 2 attempts total; timeouts are NOT
 * retried; 429/5xx and network errors get the single retry with the
 * shared back-off budget. Server-side fallback (e.g. Gemini→Groq inside
 * an Edge Function) happens inside the single client attempt — the client
 * never adds its own second-provider call on top.
 */
export async function callAiEndpoint(
  url: string,
  input: string,
  options: { externalSignal?: AbortSignal } = {},
): Promise<AiResult> {
  if (aiInFlight) {
    throw new Error('AI call already in flight — no duplicate calls for one tap (C3).');
  }
  const controller = new AbortController();
  aiInFlight = controller;
  const body = JSON.stringify({ input });
  try {
    for (let attempt = 0; attempt < AI_MAX_ATTEMPTS; attempt++) {
      let response: Response;
      try {
        response = await aiAttempt(url, body, options.externalSignal);
      } catch (error) {
        if (isTimeoutError(error)) throw error; // C2: timeout is NOT retried
        if (error instanceof Error && error.name === 'AbortError') throw error;
        if (isNetworkError(error) && attempt === 0) {
          await sleep(backoffMs(attempt, null));
          continue;
        }
        throw error;
      }

      if (response.status === 429 && attempt === 0) {
        await sleep(backoffMs(attempt, response.headers.get('Retry-After')));
        continue;
      }
      if (response.status >= 500 && attempt === 0) {
        await sleep(backoffMs(attempt, response.headers.get('Retry-After')));
        continue;
      }
      if (!response.ok) {
        const errorBody = (await response.json().catch(() => ({}))) as {
          message?: string;
          code?: string;
        };
        throw new ApiError(
          errorBody.message ?? `Request failed: ${url}`,
          response.status,
          errorBody.code,
        );
      }
      // C4: non-streaming JSON parse. If streaming were ever attempted,
      // assert res.body !== null first (assertStreams) — a final-text-only
      // test cannot catch the silent-degradation trap.
      const data = (await response.json()) as AiResult;
      return { ...data, source: 'live' };
    }
    throw new Error('AI call failed after the single permitted retry.');
  } finally {
    aiInFlight = null;
  }
}

// ---- Degraded rungs A1–A3 (expert C §3.1) ----

export type Rung = 'A1' | 'A2' | 'A3';

export interface RungResult {
  rung: Rung;
  /** Honest on-screen label — never present cached/canned output as live. */
  label: string;
  result: AiResult;
}

/** A1 — canned result, automatic on provider error / timeout / missing secret. */
export function getA1Result(input: string): RungResult {
  return { rung: 'A1', label: 'Example result', result: { ...CANNED_RESULT, input } };
}

/** A2 — last good result from the persisted cache, timestamped. */
export function getA2Result(cached: AiResult, savedAt: string): RungResult {
  return {
    rung: 'A2',
    label: `Cached — from ${savedAt}`,
    result: { ...cached, source: 'cached' },
  };
}

/** A3 — bundled seed JSON. Manual toggle or automatic after 2 consecutive backend failures at startup. */
export function getA3Result(): RungResult {
  const example = seed.exampleResult as AiResult;
  return { rung: 'A3', label: 'Offline demo data', result: { ...example, source: 'seed' } };
}

/** A3 seed records (3 complete example records, bundled in the app). */
export function getSeedRecords(): { id: string; title: string; detail: string }[] {
  return seed.records as { id: string; title: string; detail: string }[];
}
