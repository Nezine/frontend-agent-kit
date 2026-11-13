/**
 * query-client.ts — TanStack Query setup (D55, expert C §1.3).
 *
 * - onlineManager wired to NetInfo (mandatory: on RN it has no default
 *   event source; without this wiring mutations *reject* instead of pausing).
 *   Online predicate: isInternetReachable === true (null treated as online
 *   for UI, per the networking-offline template).
 * - networkMode: 'offlineFirst' — mutations pause while offline, queries
 *   refetch when stale on reconnect, paused mutations resume.
 * - gcTime 24 h (kill/reopen within the pitch still finds warm data),
 *   staleTime 60 s on the demo screen.
 * - Cache persistence: @tanstack/react-query-persist-client +
 *   @tanstack/query-async-storage-persister (AsyncStorage). Both v5.107.1 —
 *   install verified on this build (expert C §5.1 item 12 CHƯA ĐỌC, now
 *   verified: installs and resolves against SDK 58).
 * - Mutation defaults are registered AT MODULE LOAD, before any
 *   resumePausedMutations() call (expert C §1.3: a resumed mutation with
 *   no registered default throws `No mutationFn found`).
 * - shouldDehydrateMutation allow-list: only rebuildable mutations
 *   (here: ['save-result'] only). The AI call is NEVER a pausable,
 *   auto-replaying mutation (expert C §1.3): an offline AI request is a
 *   queued *prompt string* in AsyncStorage (QUEUED_PROMPT_KEY), re-run
 *   only by an explicit user tap — never auto-fired on reconnect.
 */

import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo from '@react-native-community/netinfo';
import { onlineManager, QueryClient, type Mutation } from '@tanstack/react-query';
import { createAsyncStoragePersister } from '@tanstack/query-async-storage-persister';

// Online detection: NetInfo is the event source for onlineManager.
onlineManager.setEventListener((setOnline) => {
  return NetInfo.addEventListener((state) => {
    // isInternetReachable === true means online; null (unknown) is
    // treated as online for UI purposes (a failed request still shows
    // the error state). Never treat null as proof of offline.
    setOnline(state.isInternetReachable ?? true);
  });
});

export const LAST_RESULT_KEY = 'hackathon:last-result';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      networkMode: 'offlineFirst',
      gcTime: 24 * 60 * 60 * 1000, // 24 h — warm cache across kill/reopen
      staleTime: 60 * 1000, // 60 s on the demo screen
    },
    mutations: {
      networkMode: 'offlineFirst',
    },
  },
});

/**
 * Durable non-AI mutation: persist a result row locally (AsyncStorage,
 * one key, overwritten on each success — "cache only the last result,
 * not a history", net-offline §3). Client-generated UUIDs for anything
 * created offline so a create-then-edit offline still works.
 * Registered at module load — before resumePausedMutations() can run.
 */
queryClient.setMutationDefaults(['save-result'], {
  mutationFn: async (result: { id: string; payload: unknown }) => {
    await AsyncStorage.setItem(
      LAST_RESULT_KEY,
      JSON.stringify({ id: result.id, payload: result.payload, savedAt: new Date().toISOString() }),
    );
    return result.id;
  },
});

/** Persisted-query persister (AsyncStorage). */
export const queryPersister = createAsyncStoragePersister({
  storage: AsyncStorage,
});

/**
 * shouldDehydrateMutation allow-list: only mutations we know how to
 * rebuild (registered defaults above). Anything else is never dehydrated,
 * so resume can never throw `No mutationFn found`.
 */
export function shouldDehydrateMutation(
  mutation: Mutation<unknown, Error, unknown, unknown>,
): boolean {
  const key = mutation.options.mutationKey;
  return Array.isArray(key) && key[0] === 'save-result';
}

/** Query keys (PROPOSED naming, expert C §1.3 — one key per concept). */
export const queryKeys = {
  aiResult: (requestId: string) => ['ai-result', requestId] as const,
  aiResults: ['ai-results'] as const,
  demoCounter: ['demo-counter'] as const,
} as const;
