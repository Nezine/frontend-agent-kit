// use-network-status.ts — root-layout network hook + offline banner.
// Copy verbatim into the app (e.g. lib/use-network-status.ts). Install first:
//   npx expo install @react-native-community/netinfo
//
// Sources (all accessed 2026-11-13):
// - NetInfo SDK page (SDK 58, "Included in Expo Go", recommended 12.0.1):
//   https://docs.expo.dev/versions/latest/sdk/netinfo/
// - NetInfo README (useNetInfo, addEventListener, isInternetReachable):
//   https://github.com/react-native-netinfo/react-native-netinfo
// - Offline reference (upstream Expo skill):
//   https://github.com/expo/skills/blob/main/plugins/expo/skills/expo-data-fetching/references/offline-and-cancellation.md
//
// Rule: online means isInternetReachable === true. isConnected alone is NOT
// enough — venue Wi-Fi with no internet behind it reports isConnected: true
// while every request fails. A null (unknown) state is treated as online for
// UI purposes, but a failed request still shows the error state.

import { useCallback, useEffect, useState } from 'react';
import NetInfo, { useNetInfo } from '@react-native-community/netinfo';

export type NetworkStatus = {
  /** True only when the internet is actually reachable. */
  isOnline: boolean;
  /** 'wifi' | 'cellular' | 'none' | 'unknown' | ... — display only. */
  type: string;
  /** True while the state is still unknown (initial load). */
  isUnknown: boolean;
  /** Force a fresh read (call before Retry, the cached state can be stale). */
  refresh: () => Promise<void>;
};

export function useNetworkStatus(): NetworkStatus {
  const netInfo = useNetInfo();
  const [unknown, setUnknown] = useState(true);

  useEffect(() => {
    if (netInfo.isInternetReachable !== null) setUnknown(false);
  }, [netInfo.isInternetReachable]);

  const refresh = useCallback(async () => {
    await NetInfo.refresh();
  }, []);

  const isInternetReachable = netInfo.isInternetReachable;
  return {
    // null (unknown) -> treat as online for UI; a failed request still
    // surfaces the error state. Never treat null as proof of offline.
    isOnline: isInternetReachable !== false,
    type: netInfo.type,
    isUnknown: unknown,
    refresh,
  };
}

/**
 * Offline banner copy. Render at the top of the screen whenever
 * !isOnline. Keep it short: the user needs to know why Generate is
 * disabled, not a networking lecture.
 */
export function offlineBannerText(type: string): string {
  if (type === 'none') return "You're offline — check your connection and try again.";
  return "No internet connection — showing the last saved result.";
}

/**
 * Queue a prompt typed while offline. The prompt text is NOT secret, so
 * AsyncStorage (unencrypted) is fine. Never auto-fire on reconnect —
 * the UI offers "Back online — Run now?" and the user taps to run.
 * (Rule: networking-offline SKILL.md section 4.)
 */
export const QUEUED_PROMPT_KEY = 'hackathon:queued-prompt';
