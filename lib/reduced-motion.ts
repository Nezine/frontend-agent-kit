/**
 * reduced-motion.ts — honour the system reduced-motion setting (D54, expert B §1.5).
 *
 * Verification note: expert B marked the AccessibilityInfo API surface
 * CHƯA ĐỌC for SDK 58 ("verify the AccessibilityInfo API import on SDK 58
 * before wiring"). Verified in THIS build: `AccessibilityInfo` imports
 * from 'react-native' and `isReduceMotionEnabled()` typechecks under
 * `npx tsc --noEmit` (see build log §6). When reduced motion is on,
 * skip spring + stagger animations; content must be identical with
 * motion off.
 */

import { useEffect, useState } from 'react';
import { AccessibilityInfo } from 'react-native';

export function useReducedMotion(): boolean {
  const [reduced, setReduced] = useState(false);

  useEffect(() => {
    let alive = true;
    AccessibilityInfo.isReduceMotionEnabled().then((value) => {
      if (alive) setReduced(value);
    });
    const subscription = AccessibilityInfo.addEventListener(
      'reduceMotionChanged',
      setReduced,
    );
    return () => {
      alive = false;
      subscription.remove();
    };
  }, []);

  return reduced;
}
