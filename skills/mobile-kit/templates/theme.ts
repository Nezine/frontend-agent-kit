/**
 * theme.ts — design tokens for the Expo SDK 57 hackathon app.
 *
 * Starter values only. Re-lock every value against the brief's references
 * at taste lock (same rule as the web kit: tokens first, no hardcoded
 * colors / spacing / fonts in screens). If a screen drifts, fix the token,
 * not the screen.
 *
 * Platform notes:
 * - Shadows use `Platform.select`: iOS gets shadow* props, Android gets
 *   `elevation`. There is no single cross-platform shadow style in
 *   React Native core.
 * - `colors` values are plain hex strings; pass gradient colors as
 *   `as const` tuples (see templates/snippets.tsx §2) because
 *   `LinearGradient` requires a readonly tuple of 2+ colors.
 */

import { Platform, type TextStyle, type ViewStyle } from 'react-native';

/* ------------------------------------------------------------------ */
/* Semantic colors                                                     */
/* ------------------------------------------------------------------ */

export const colors = {
  background: '#FFFFFF',
  surface: '#F6F6F4',
  surfaceRaised: '#FFFFFF',
  text: '#0A0F1E',
  textSecondary: '#5B6472',
  textInverse: '#FFFFFF',
  brand: '#2547F4',
  brandSoft: '#E4E9FE',
  border: '#E3E5E8',
  success: '#1F9D63',
  warning: '#C77D0A',
  error: '#D92D20',
} as const;

export type ColorName = keyof typeof colors;

/* ------------------------------------------------------------------ */
/* Spacing scale (4-pt grid)                                           */
/* ------------------------------------------------------------------ */

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  '2xl': 24,
  '3xl': 32,
  '4xl': 40,
  '5xl': 48,
  '6xl': 64,
} as const;

export type SpacingName = keyof typeof spacing;

/* ------------------------------------------------------------------ */
/* Radius scale                                                        */
/* ------------------------------------------------------------------ */

export const radius = {
  none: 0,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  '2xl': 24,
  full: 999,
} as const;

export type RadiusName = keyof typeof radius;

/* ------------------------------------------------------------------ */
/* Shadows — Platform.select (iOS shadow* / Android elevation)         */
/* ------------------------------------------------------------------ */

type Shadow = Pick<
  ViewStyle,
  'shadowColor' | 'shadowOffset' | 'shadowOpacity' | 'shadowRadius' | 'elevation'
>;

export const shadows: Record<'sm' | 'md' | 'lg', Shadow> = {
  sm: Platform.select<Shadow>({
    ios: {
      shadowColor: '#0A0F1E',
      shadowOffset: { width: 0, height: 1 },
      shadowOpacity: 0.08,
      shadowRadius: 4,
    },
    android: { elevation: 2 },
    default: {},
  }),
  md: Platform.select<Shadow>({
    ios: {
      shadowColor: '#0A0F1E',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.1,
      shadowRadius: 12,
    },
    android: { elevation: 6 },
    default: {},
  }),
  lg: Platform.select<Shadow>({
    ios: {
      shadowColor: '#0A0F1E',
      shadowOffset: { width: 0, height: 12 },
      shadowOpacity: 0.14,
      shadowRadius: 24,
    },
    android: { elevation: 12 },
    default: {},
  }),
};

/* ------------------------------------------------------------------ */
/* Type scale                                                          */
/* ------------------------------------------------------------------ */

type TypeRole = Pick<TextStyle, 'fontSize' | 'lineHeight' | 'fontWeight'> & {
  letterSpacing?: number;
};

export const type: Record<
  'display' | 'title' | 'headline' | 'body' | 'bodySmall' | 'caption',
  TypeRole
> = {
  display: { fontSize: 34, lineHeight: 40, fontWeight: '700', letterSpacing: -0.5 },
  title: { fontSize: 28, lineHeight: 34, fontWeight: '700', letterSpacing: -0.3 },
  headline: { fontSize: 20, lineHeight: 26, fontWeight: '600' },
  body: { fontSize: 16, lineHeight: 24, fontWeight: '400' },
  bodySmall: { fontSize: 14, lineHeight: 20, fontWeight: '400' },
  caption: { fontSize: 12, lineHeight: 16, fontWeight: '500' },
};

/* ------------------------------------------------------------------ */
/* Combined theme object (import this in screens)                      */
/* ------------------------------------------------------------------ */

export const theme = { colors, spacing, radius, shadows, type } as const;

export type Theme = typeof theme;
