/**
 * store.ts — Zustand client store (D55, expert C §1.2).
 *
 * Persist split (sourced — app-quality §3.2): `partialize` is mandatory.
 * Persisted allow-list (exactly these, nothing else): theme, draftInput,
 * lastResultId, demoSeedChoice, onboardingDone.
 * Must NOT persist: in-flight stream, loading flags, error objects,
 * in-flight request id, functions, the result payload itself (it lives in
 * the TanStack cache — duplicating it here is forbidden, expert C §1.1).
 *
 * Storage: AsyncStorage via createJSONStorage. Tokens NEVER go here —
 * tokens live in expo-secure-store only (see lib/tokens.ts).
 */

import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';

export type ThemePreference = 'system' | 'light' | 'dark';

export interface AppState {
  // ---- Persisted (partialize allow-list) ----
  /** Theme preference; 'system' follows the OS (userInterfaceStyle: automatic). */
  theme: ThemePreference;
  /** Current input / draft, verbatim. Survives kill/reopen. */
  draftInput: string;
  /** Pointer ONLY to the last good result — never the result JSON (expert C §1.3). */
  lastResultId: string | null;
  /** Which seed/rung the presenter selected, if any. */
  demoSeedChoice: boolean | string;
  /** First-run onboarding completed. */
  onboardingDone: boolean;

  // ---- In-memory only (never persisted) ----
  /** In-flight AI text (ephemeral; dies with the screen/process). */
  streamingText: string;
  /** Loading flag for the current AI attempt. */
  isGenerating: boolean;
  /** Last attempt's error message, if any (per-attempt; never persisted). */
  streamError: string | null;
  /** Id of the in-flight request, if any (dead on kill; never persisted). */
  inFlightRequestId: string | null;

  // ---- Actions (functions — non-serialisable, never persisted) ----
  setTheme: (theme: ThemePreference) => void;
  setDraftInput: (draft: string) => void;
  setLastResultId: (id: string | null) => void;
  setDemoSeedChoice: (choice: boolean | string) => void;
  setOnboardingDone: (done: boolean) => void;
  setStreamingText: (text: string) => void;
  setIsGenerating: (generating: boolean) => void;
  setStreamError: (error: string | null) => void;
  setInFlightRequestId: (id: string | null) => void;
  /** Clear only the in-memory fields (e.g. after a kill/reopen or abort). */
  clearInFlight: () => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      theme: 'system',
      draftInput: '',
      lastResultId: null,
      demoSeedChoice: false,
      onboardingDone: false,

      streamingText: '',
      isGenerating: false,
      streamError: null,
      inFlightRequestId: null,

      setTheme: (theme) => set({ theme }),
      setDraftInput: (draftInput) => set({ draftInput }),
      setLastResultId: (lastResultId) => set({ lastResultId }),
      setDemoSeedChoice: (demoSeedChoice) => set({ demoSeedChoice }),
      setOnboardingDone: (onboardingDone) => set({ onboardingDone }),
      setStreamingText: (streamingText) => set({ streamingText }),
      setIsGenerating: (isGenerating) => set({ isGenerating }),
      setStreamError: (streamError) => set({ streamError }),
      setInFlightRequestId: (inFlightRequestId) => set({ inFlightRequestId }),
      clearInFlight: () =>
        set({
          streamingText: '',
          isGenerating: false,
          streamError: null,
          inFlightRequestId: null,
        }),
    }),
    {
      name: 'hackathon:client-state',
      storage: createJSONStorage(() => AsyncStorage),
      // Allow-list: exactly the five persisted fields. Everything else
      // (stream, flags, errors, request id, functions, result payload)
      // is excluded by construction.
      partialize: (state) => ({
        theme: state.theme,
        draftInput: state.draftInput,
        lastResultId: state.lastResultId,
        demoSeedChoice: state.demoSeedChoice,
        onboardingDone: state.onboardingDone,
      }),
    },
  ),
);
