/**
 * snippets.tsx — copy-paste snippet pack for the Expo SDK 57 hackathon.
 *
 * Each snippet has its verified source URL in a comment directly above it.
 * Sources were read 2026-11-12. Anything marked CHƯA VERIFY was not
 * verified — do not present it as verified.
 *
 * Imports are consolidated at the top of this file. When copying a single
 * snippet into a screen, copy the import line named in its header comment.
 *
 * Install first (SDK-57-pinned, never `latest` by hand):
 *   npx expo install react-native-reanimated expo-linear-gradient @expo/ui expo-blur expo-haptics
 */

import { useEffect, useRef, useState, type ReactNode } from 'react';
import {
  Animated,
  Easing,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import AnimatedReanimated, {
  FadeInDown,
  LinearTransition,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { BottomSheet, Host } from '@expo/ui';
import { BlurView, BlurTargetView } from 'expo-blur';
import * as Haptics from 'expo-haptics';
import { theme } from './theme';

/* ================================================================== */
/* §1 — Reanimated 4 presets: stagger + layout + spring press         */
/* Imports: react-native-reanimated (Animated, FadeInDown,              */
/*   LinearTransition, useSharedValue, useAnimatedStyle, withSpring)    */
/* Source: https://docs.swmansion.com/react-native-reanimated/docs/layout-animations/entering-exiting-animations/ */
/*   (FadeInDown.delay / springify rely on withSpring; LinearTransition */
/*   is the layout-animation preset on the same docs site.)             */
/* ================================================================== */

type StaggerItem = { id: string; label: string };

export function StaggeredList({ items }: { items: StaggerItem[] }) {
  return (
    <View>
      {items.map((item, i) => (
        <AnimatedReanimated.View
          key={item.id}
          // Stagger: each row enters 50ms after the previous one.
          entering={FadeInDown.delay(i * 50).duration(300)}
          // Smoothly glides to its new position when the list changes.
          layout={LinearTransition}
        >
          <Text style={styles.rowText}>{item.label}</Text>
        </AnimatedReanimated.View>
      ))}
    </View>
  );
}

export function SpringPressButton({
  label,
  onPress,
}: {
  label: string;
  onPress: () => void;
}) {
  const scale = useSharedValue(1);
  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));
  return (
    <Pressable
      onPress={onPress}
      onPressIn={() => {
        scale.value = withSpring(0.96, { damping: 15, stiffness: 300 });
      }}
      onPressOut={() => {
        scale.value = withSpring(1, { damping: 15, stiffness: 300 });
      }}
    >
      <AnimatedReanimated.View style={[styles.cta, animatedStyle]}>
        <Text style={styles.ctaText}>{label}</Text>
      </AnimatedReanimated.View>
    </Pressable>
  );
}

/* ================================================================== */
/* §2 — expo-linear-gradient: background / CTA / scrim                  */
/* Import: { LinearGradient } from 'expo-linear-gradient'               */
/* Source: https://docs.expo.dev/versions/latest/sdk/linear-gradient/  */
/* Note: `colors` is a readonly tuple of 2+ colors. Pass the array     */
/* inline or `as const` — a plain `string[]` from a theme object is a   */
/* TypeScript error.                                                   */
/* ================================================================== */

export function GradientBackground({ children }: { children: ReactNode }) {
  return (
    <LinearGradient
      colors={['#4c669f', '#3b5998', '#192f6a']}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={styles.gradientFill}
    >
      {children}
    </LinearGradient>
  );
}

export function GradientCTA({ label }: { label: string }) {
  return (
    <LinearGradient
      colors={['#4c669f', '#3b5998', '#192f6a']}
      style={styles.gradientButton}
    >
      <Text style={styles.ctaText}>{label}</Text>
    </LinearGradient>
  );
}

export function PhotoScrim({ children }: { children: ReactNode }) {
  return (
    <View style={styles.photoWrap}>
      {children}
      {/* Dark fade over the bottom of a photo so the caption stays readable. */}
      <LinearGradient
        colors={['rgba(0,0,0,0.8)', 'transparent']}
        style={StyleSheet.absoluteFill}
      />
    </View>
  );
}

/* ================================================================== */
/* §3 — @expo/ui universal BottomSheet                                 */
/* Imports: { BottomSheet, Host } from '@expo/ui';                     */
/*   React Native View/Text as children.                               */
/* Source: https://docs.expo.dev/versions/latest/sdk/ui/universal/bottomsheet/ */
/*   (read 2026-11-12; that page is the "latest" docs and recommends   */
/*   @expo/ui ~58.0.28 — for SDK 57 install with `npx expo install`,   */
/*   which resolves the SDK 57 pin ~57.0.17. Do NOT hand-install       */
/*   the 58.x version into an SDK 57 project.)                         */
/* Visibility is controlled: toggle `isPresented` from state, dismiss  */
/* from `onDismiss` (swipe down / tap overlay). `snapPoints`           */
/* 'half'/'full' work cross-platform; `{ fraction }` / `{ height }`    */
/* snap to the nearest of half/full on Android.                        */
/* `Host` wrapper: optional — the universal BottomSheet renders its    */
/* own internal Host. Keep it when the screen also uses other          */
/* universal components. Scrollable RN content (FlatList) inside a     */
/* sheet needs `RNHostView` — plain static content does not.           */
/* ================================================================== */

export function DemoBottomSheet() {
  const [isPresented, setIsPresented] = useState(false);
  return (
    <Host>
      <Pressable onPress={() => setIsPresented(true)}>
        <Text style={styles.rowText}>Open sheet</Text>
      </Pressable>
      <BottomSheet
        isPresented={isPresented}
        onDismiss={() => setIsPresented(false)}
        snapPoints={['half', 'full']}
      >
        <View style={styles.sheetContent}>
          <Text style={styles.sheetTitle}>Sheet title</Text>
          <Text style={styles.sheetBody}>Sheet content goes here.</Text>
        </View>
      </BottomSheet>
    </Host>
  );
}

/* ================================================================== */
/* §4 — DIY skeleton pulse (core Animated, no extra dependency)        */
/* Imports: { Animated, Easing } from 'react-native'                   */
/* Source: https://reactnative.codeguides.io/animations-gestures/animations-basics/ */
/*   (SDK-57-targeted community cookbook; the Animated core API —      */
/*   Animated.loop / sequence / timing, useNativeDriver — is React     */
/*   Native core. Opacity 0.4 -> 1 loop, native driver, loop stopped   */
/*   in the effect cleanup.)                                           */
/* ================================================================== */

export function SkeletonPulse({
  width = '100%',
  height = 16,
}: {
  width?: number | string;
  height?: number;
}) {
  const opacity = useRef(new Animated.Value(0.4)).current;
  useEffect(() => {
    const pulse = Animated.loop(
      Animated.sequence([
        Animated.timing(opacity, {
          toValue: 1,
          duration: 600,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(opacity, {
          toValue: 0.4,
          duration: 600,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ]),
    );
    pulse.start();
    return () => pulse.stop();
  }, [opacity]);
  return (
    <Animated.View
      style={[styles.skeleton, { width, height, opacity }]}
    />
  );
}

/* ================================================================== */
/* §5 — expo-blur BlurView (Android needs BlurTargetView + blurMethod) */
/* Imports: { BlurView, BlurTargetView } from 'expo-blur'               */
/* Source: https://docs.expo.dev/versions/v55.0.0/sdk/blur-view/       */
/*   (read 2026-11-12; SDK 57 pin is expo-blur ~57.0.2 and the API is  */
/*   unchanged in SDK 57. `blurMethod` defaults to 'none' on Android — */
/*   a bare <BlurView> renders only a semi-transparent view there.     */
/*   Use 'dimezisBlurViewSdk31Plus': real blur on Android 12+, falls   */
/*   back to 'none' on older versions.)                                */
/* Gotcha from the same page: render the BlurView AFTER dynamic        */
/* content (e.g. FlatList), or the blur does not update.               */
/* ================================================================== */

export function FrostedCard({ children }: { children: ReactNode }) {
  const targetRef = useRef<View | null>(null);
  return (
    <View style={styles.blurWrap}>
      <BlurTargetView ref={targetRef} style={StyleSheet.absoluteFill}>
        {children}
      </BlurTargetView>
      <BlurView
        blurTarget={targetRef}
        blurMethod="dimezisBlurViewSdk31Plus"
        intensity={80}
        tint="light"
        style={styles.blurCard}
      >
        <Text style={styles.sheetBody}>Frosted content</Text>
      </BlurView>
    </View>
  );
}

/* ================================================================== */
/* §6 — expo-haptics: exactly three call sites                         */
/* Import: * as Haptics from 'expo-haptics'                            */
/* Source: https://docs.expo.dev/versions/latest/sdk/haptics/          */
/* ================================================================== */

export const haptics = {
  // CTA press.
  ctaPress: () =>
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light),
  // AI task finished.
  aiDone: () =>
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success),
  // Swipe crossed its commit threshold.
  swipePastThreshold: () =>
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium),
};

/* ------------------------------------------------------------------ */
/* Styles (theme tokens only — no hardcoded values outside theme.ts)   */
/* ------------------------------------------------------------------ */

const styles = StyleSheet.create({
  rowText: { ...theme.type.body, color: theme.colors.text },
  cta: {
    backgroundColor: theme.colors.brand,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.radius.md,
    alignItems: 'center',
  },
  ctaText: { ...theme.type.body, color: theme.colors.textInverse, fontWeight: '600' },
  gradientFill: { flex: 1 },
  gradientButton: {
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.radius.md,
    alignItems: 'center',
  },
  photoWrap: { position: 'relative', overflow: 'hidden' },
  sheetContent: { padding: theme.spacing.lg },
  sheetTitle: { ...theme.type.headline, color: theme.colors.text },
  sheetBody: { ...theme.type.body, color: theme.colors.textSecondary },
  skeleton: {
    backgroundColor: theme.colors.border,
    borderRadius: theme.radius.sm,
  },
  blurWrap: { position: 'relative', minHeight: 120 },
  blurCard: {
    padding: theme.spacing.lg,
    margin: theme.spacing.md,
    overflow: 'hidden',
    borderRadius: theme.radius.lg,
    justifyContent: 'center',
  },
});
