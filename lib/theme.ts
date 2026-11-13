/**
 * theme.ts — design tokens for the Expo SDK 58 hackathon app.
 *
 * LOCKED at taste lock (D54). Tokens before screens: no screen may be
 * written before this file is committed (see DESIGN.md lock procedure).
 * If a screen drifts (hardcoded colour, magic spacing), fix the TOKEN,
 * not the screen.
 *
 * Provenance: light colours / spacing / radius / shadows / type are
 * verbatim from skills/mobile-kit/templates/theme.ts (SDK 57 starter),
 * except `success`/`warning` (light), darkened to pass AA — see memo.
 * Dark colours are new in this memo; re-measure every pair at the D70
 * a11y gate (15:00-15:30, real phone). `brand` / `brandSoft` are
 * PLACEHOLDERS until the idea + human reference picks land (Sat 09:45).
 * System font only: there is deliberately no `fontFamily` token.
 * Safe area: no hardcoded inset values — use `useSafeAreaInsets()`
 * (react-native-safe-area-context ~5.11.1) on every screen.
 */

import { Platform, type TextStyle, type ViewStyle } from 'react-native';

/* Semantic colours — light (default) and dark (useColorScheme). */

export const lightColors = {
  background: '#FFFFFF',
  surface: '#F6F6F4',
  surfaceRaised: '#FFFFFF',
  text: '#0A0F1E',
  textSecondary: '#5B6472',
  textInverse: '#FFFFFF',
  brand: '#2547F4', // PLACEHOLDER — re-skin Sat 09:45 from DESIGN.md
  brandSoft: '#E4E9FE', // PLACEHOLDER — re-skin Sat 09:45 from DESIGN.md
  border: '#E3E5E8', // 1.26:1 — NEVER the sole indicator of anything
  success: '#157347', // fixed: starter #1F9D63 was 3.46:1 (AA fail)
  warning: '#8A5A00', // fixed: starter #C77D0A was 3.30:1 (AA fail)
  error: '#D92D20', // 4.83:1 — just above the line, do not lighten
} as const;

export const darkColors = {
  background: '#0A0F1E',
  surface: '#141A29',
  surfaceRaised: '#1C2333',
  text: '#F6F6F4',
  textSecondary: '#A8B0BE',
  textInverse: '#0A0F1E',
  brand: '#7A9CFF', // PLACEHOLDER — re-skin Sat 09:45 from DESIGN.md
  brandSoft: '#1E2A4D', // PLACEHOLDER — re-skin Sat 09:45 from DESIGN.md
  border: '#2A3348', // 1.51:1 — NEVER the sole indicator of anything
  success: '#34C77B',
  warning: '#E8A33D',
  error: '#FF6B61',
} as const;

export type ColorName = keyof typeof lightColors;
export type ColorSchemeName = 'light' | 'dark';
// NOTE (build fix, 2026-11-13): the memo's verbatim line was
// `export const colors: Record<ColorSchemeName, typeof lightColors> = ...`.
// That rejects the dark literals under strict TS (dark values are not
// light's literal types), so tsc failed on the verbatim annotation.
// All token VALUES below are byte-identical to expert B §1.6; only this
// one declaration's typing changed so both schemes typecheck.
export const colors = {
  light: lightColors,
  dark: darkColors,
} as const;

/* Spacing scale (4-pt grid). */
export const spacing = {
  xs: 4, sm: 8, md: 12, lg: 16, xl: 20,
  '2xl': 24, '3xl': 32, '4xl': 40, '5xl': 48, '6xl': 64,
} as const;
export type SpacingName = keyof typeof spacing;

/* Radius scale. */
export const radius = {
  none: 0, xs: 4, sm: 8, md: 12, lg: 16, xl: 20, '2xl': 24, full: 999,
} as const;
export type RadiusName = keyof typeof radius;

/* Shadows — Platform.select (iOS shadow* / Android elevation). */
type Shadow = Pick<ViewStyle,
  'shadowColor' | 'shadowOffset' | 'shadowOpacity' | 'shadowRadius' | 'elevation'>;
export const shadows: Record<'sm' | 'md' | 'lg', Shadow> = {
  sm: Platform.select<Shadow>({
    ios: { shadowColor: '#0A0F1E', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.08, shadowRadius: 4 },
    android: { elevation: 2 }, default: {},
  }),
  md: Platform.select<Shadow>({
    ios: { shadowColor: '#0A0F1E', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.1, shadowRadius: 12 },
    android: { elevation: 6 }, default: {},
  }),
  lg: Platform.select<Shadow>({
    ios: { shadowColor: '#0A0F1E', shadowOffset: { width: 0, height: 12 }, shadowOpacity: 0.14, shadowRadius: 24 },
    android: { elevation: 12 }, default: {},
  }),
};

/* Type scale — roles only; no fontFamily field (system font only). */
type TypeRole = Pick<TextStyle, 'fontSize' | 'lineHeight' | 'fontWeight'> & {
  letterSpacing?: number;
};
export const type: Record<
  'display' | 'title' | 'headline' | 'body' | 'bodySmall' | 'caption', TypeRole> = {
  display: { fontSize: 34, lineHeight: 40, fontWeight: '700', letterSpacing: -0.5 },
  title: { fontSize: 28, lineHeight: 34, fontWeight: '700', letterSpacing: -0.3 },
  headline: { fontSize: 20, lineHeight: 26, fontWeight: '600' },
  body: { fontSize: 16, lineHeight: 24, fontWeight: '400' },
  bodySmall: { fontSize: 14, lineHeight: 20, fontWeight: '400' },
  caption: { fontSize: 12, lineHeight: 16, fontWeight: '500' },
};

/* Layout minima — tap targets, CTA, spacing between targets. */
export const layout = {
  tapTargetMin: 48, // every tappable element, both platforms (iOS 44 / Android 48)
  tapGapMin: 8, // minimum spacing between neighbouring targets
  ctaHeightMin: 56, // primary CTA height
  screenPadding: 16, // == spacing.lg; horizontal screen padding
} as const;

/* Dynamic type — maxFontSizeMultiplier caps (0 = unlimited). */
export const fontScaling = {
  body: 0, // uncapped — body text must survive 200%
  button: 1.5, // buttons 1.3-1.5
  tabLabel: 1.2, // tab labels 1.1-1.2
  chip: 1.1, // chips / badges 1.1
} as const;

/* Motion — transform + opacity only; spring + stagger defaults. */
export const motion = {
  spring: { damping: 120, stiffness: 900, mass: 4 },
  microMs: { min: 200, max: 500 },
  pressScale: 0.9,
  staggerMsPerIndex: 50,
  // Reduced motion: honour the system setting via AccessibilityInfo.
  // CHƯA ĐỌC — verify the AccessibilityInfo API import on SDK 58
  // before wiring; when reduced motion is on, skip spring + stagger.
  respectReducedMotion: true,
} as const;

/* Combined theme object (import this in screens). */
export const theme = { colors, spacing, radius, shadows, type, layout, fontScaling, motion } as const;
export type Theme = typeof theme;
