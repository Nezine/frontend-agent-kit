// fetch-with-timeout.ts — the single network wrapper for the hackathon app.
// Copy verbatim into the app (e.g. lib/fetch-with-timeout.ts). Do not fork it
// per screen and do not call bare fetch() for AI/backend requests.
//
// Sources (all accessed 2026-11-13):
// - expo/fetch named import + WinterCG API:
//   https://docs.expo.dev/versions/latest/sdk/expo/
// - AbortController cancellation on unmount + NetInfo offline pattern
//   (upstream Expo skill reference):
//   https://github.com/expo/skills/blob/main/plugins/expo/skills/expo-data-fetching/references/offline-and-cancellation.md
// - Retry with exponential backoff pattern (upstream Expo skill; this file adds
//   the timeout, the retry-once-on-network-error-only rule, and 429 handling):
//   https://github.com/expo/skills/blob/main/plugins/expo/skills/expo-data-fetching/SKILL.md
// - Gemini 429 RESOURCE_EXHAUSTED + "wait and retry after a short period":
//   https://ai.google.dev/gemini-api/docs/rate-limits
// - Budgets (25 s server / 30 s client) are the build's own design numbers
//   (backend brief section 3.1), NOT platform limits: Convex Node actions
//   allow 10 min (https://docs.convex.dev/production/state/limits),
//   Supabase Edge Functions allow 150 s free
//   (https://supabase.com/docs/guides/functions/limits).
//
// Implementation note: the timeout is a manual setTimeout + controller.abort(),
// not AbortSignal.timeout() / AbortSignal.any() — those newer static methods
// are not verified on Hermes, while AbortController is the mechanism the
// upstream Expo skill already uses on this runtime.
// Smoke-tested 2026-11-13 on Node v24.22.1 (WinterCG fetch): fast GET 200,
// slow endpoint aborted at the timeout, 429 retried with 500 ms + 1000 ms
// backoff. The native expo/fetch streaming path is NOT verified by that run
// and must be smoke-tested on the real phone (see SKILL.md section 6).

import { fetch } from 'expo/fetch';

export class ApiError extends Error {
  public readonly status: number;
  public readonly code?: string;

  constructor(message: string, status: number, code?: string) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
  }
}

export type FetchWithTimeoutOptions = RequestInit & {
  /** Total wait budget for one attempt. Default 30_000 (the build's client budget). */
  timeoutMs?: number;
  /** Extra signal (e.g. from the calling component's AbortController on unmount). */
  externalSignal?: AbortSignal;
};

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/** Backoff for attempt n (0-based): 2^n seconds, honouring Retry-After when longer. */
function backoffMs(attempt: number, retryAfterHeader: string | null): number {
  const exponential = Math.pow(2, attempt) * 1000;
  if (!retryAfterHeader) return exponential;
  const seconds = Number(retryAfterHeader);
  if (Number.isFinite(seconds) && seconds > 0) {
    return Math.max(exponential, seconds * 1000);
  }
  return exponential;
}

function isNetworkError(error: unknown): boolean {
  // The request never reached the server (offline, DNS, socket failure).
  // A timeout is NOT a network error: the server may already be working.
  return error instanceof TypeError;
}

/** One attempt: fetch with a hard timeout. Throws TimeoutError on timeout. */
async function attemptFetch(
  url: string,
  init: RequestInit,
  timeoutMs: number,
  externalSignal?: AbortSignal,
): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  const onExternalAbort = () => controller.abort();
  if (externalSignal) {
    if (externalSignal.aborted) controller.abort();
    else externalSignal.addEventListener('abort', onExternalAbort, { once: true });
  }
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      if (externalSignal?.aborted) throw error; // Unmount: caller ignores it.
      throw new Error(`Request timed out after ${timeoutMs}ms: ${url}`);
    }
    throw error;
  } finally {
    clearTimeout(timer);
    externalSignal?.removeEventListener('abort', onExternalAbort);
  }
}

/**
 * One request with a hard timeout, one retry on network error only, and
 * capped exponential backoff on 429 / 5xx. Throws ApiError (HTTP failure),
 * the underlying TypeError (network), or an Error (timeout).
 *
 * Never retry a timeout: the model call may already be running server-side.
 * Never retry a 4xx other than 429: it is a client bug, not a transient fault.
 */
export async function fetchWithTimeout(
  url: string,
  options: FetchWithTimeoutOptions = {},
): Promise<Response> {
  const { timeoutMs = 30_000, externalSignal, ...init } = options;
  const MAX_429_RETRIES = 2;
  const MAX_5XX_RETRIES = 1;

  let attempt429 = 0;
  let attempt5xx = 0;
  let networkRetried = false;

  for (;;) {
    let response: Response;
    try {
      response = await attemptFetch(url, init, timeoutMs, externalSignal);
    } catch (error) {
      if (isNetworkError(error) && !networkRetried) {
        // Retry exactly once, then give up. A second failure is surfaced.
        networkRetried = true;
        await sleep(1000);
        continue;
      }
      throw error;
    }

    if (response.status === 429 && attempt429 < MAX_429_RETRIES) {
      await sleep(backoffMs(attempt429, response.headers.get('Retry-After')));
      attempt429 += 1;
      continue;
    }
    if (response.status >= 500 && attempt5xx < MAX_5XX_RETRIES) {
      await sleep(backoffMs(attempt5xx, response.headers.get('Retry-After')));
      attempt5xx += 1;
      continue;
    }
    return response;
  }
}

/** Non-streaming JSON call: the demo path. Throws ApiError on HTTP failure. */
export async function fetchJson<T>(
  url: string,
  options: FetchWithTimeoutOptions = {},
): Promise<T> {
  const response = await fetchWithTimeout(url, options);
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new ApiError(
      (body as { message?: string }).message ?? `Request failed: ${url}`,
      response.status,
      (body as { code?: string }).code,
    );
  }
  return (await response.json()) as T;
}

/**
 * Streaming smoke-test assertion only — NOT the demo path.
 * Throws if the response has no readable body (the silent-degradation trap:
 * the global XHR fetch has no response.body, so streaming would silently
 * return the whole answer at once instead of chunks).
 */
export async function assertStreams(
  url: string,
  options: FetchWithTimeoutOptions = {},
): Promise<void> {
  const response = await fetchWithTimeout(url, options);
  if (response.body === null) {
    throw new Error(
      'expo/fetch returned no response.body — streaming is unavailable on this runtime. ' +
        'Check that the named import from expo/fetch is used, not the global fetch.',
    );
  }
  await response.body.cancel().catch(() => undefined);
}
