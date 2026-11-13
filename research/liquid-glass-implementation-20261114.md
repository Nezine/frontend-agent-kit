# Liquid Glass / light refraction — implementation feasibility for Expo SDK 58 on the OPPO A60

**Date:** 2026-11-14 (research) · **Angle:** implementation feasibility only (Mie leads the general angle)
**Stack:** Expo SDK 58 · React Native 0.88.1 · TypeScript · Expo Router · Reanimated 4.7.1
**Demo phone:** OPPO A60 — Snapdragon 680, Adreno 610 @1115 MHz, Android 14 / ColorOS 14.0.1 (API 34), 6.67″ 720×1604 HD+ 90 Hz, 8 GB RAM
**Budget:** $0.00 — every path below is free; nothing needs an account or a key.

---

## 0. Verdict (read this first)

| # | Path | Real refraction on the A60? | Build needed? | Verdict for tomorrow |
|---|------|------------------------------|---------------|----------------------|
| 1 | **Cheap fake: `expo-blur` + tint + specular gradient** (already installed) | No — blur only, no displacement | **Yes, one EAS rebuild for the new JS** (no `expo-updates` in the scaffold, so the current APK cannot take JS-only changes) | **DO THIS.** Lowest risk, works today. One small glass surface, not glass everywhere. |
| 2 | **`@sbaiahmed1/react-native-blur` 6.0.2 `LiquidGlassView`** (AGSL shader) | **Yes — real refraction, dispersion, blur, tint over live RN content on Android 13+** | Yes, new EAS build (new native module) | **Parallel spike only, if a build slot is free.** Strongest real-glass candidate, but a 7-week-old one-maintainer fork; build under SDK 58 is **unverified**. Never the plan — the fallback if it fails is path 1. |
| 3 | **`@shopify/react-native-skia` 2.14.0 runtime shader** | Only over content drawn **inside the Skia canvas** (an image/gradient). It **cannot** refract the RN views behind the card. | Yes, new EAS build | **Skip for glass-over-app.** Useful only as a self-contained "lens over a picture" demo trick. |
| 4 | `expo-glass-effect` / `@callstack/liquid-glass` | No — iOS 26+ only; renders as a **plain `View`** on Android | Would need a rebuild to even install | **Skip. Zero effect on the demo phone.** Do not waste a build cycle. |
| 5 | `react-native-liquid-glassmorphism`, `react-native-glass-lens` | Yes in principle (same AGSL approach as #2) | Yes, new EAS build | **Skip.** Same job as #2, newer/smaller, less verified. Pick at most one spike. |

**Bottom line:** the only real glass over live app content on the A60 is the AGSL route (#2), and it is unverified under SDK 58. The safe, shippable move is the blur-based fake (#1) — which still costs one EAS build (~90 min free-tier queue) because the scaffold has no `expo-updates`. **If you do one more build, add `expo-updates` to it** so later JS tweaks can go over the air instead of costing another 90-minute queue. (Standard Expo flow — not verified against this project's exact config; check before relying on it.)

---

## 1. What Apple Liquid Glass actually is (UI terms, not marketing)

From Apple's June 2025 announcement and the technical write-ups:

- **A real-time rendered material, not a static style.** It "reflects and refracts its surroundings, while dynamically transforming to help bring greater focus to content" and "uses real-time rendering and dynamically reacts to movement with specular highlights."
- **Refraction = geometric displacement.** The defining move is **edge lensing**: pixels behind the control visibly warp and compress in a ~12–24 px band at its border, while the centre stays comparatively clear — as if light bent through a curved lens (Snell's law). A straight line passing behind a curved glass edge comes out bent.
- **Specular highlights that react to movement.** A 1–2 px bright arc runs along the upper-left rim; the glint follows device motion. The single highest-value cue is a non-uniform rim: bright top edge, subtle bottom edge — it implies a light source above and gives the pane thickness. A uniform border reads as cut film.
- **Adaptive tint.** The material samples what is beneath it and adapts its own colour between light and dark environments.
- **Surfaces merge.** When two glass elements overlap, their refraction fields merge into a single sheet instead of looking like overlaid PNGs.
- **Glassmorphism is a subset, not the same thing.** Frosted blur + translucent tint + soft shadow = glassmorphism. Liquid Glass = glassmorphism **plus displacement, specular tracking, and adaptive tint**. A blur-only implementation is glassmorphism with a trendy name. Any honest demo should call it that.
- **Hard limits in Apple's own architecture:** nested glass fails at any depth (glass cannot sample glass — the inner element's backdrop snapshot contains the outer element's already-filtered output, so two stacked panels look worse *and* run slower); and the alpha Apple shipped (0.40) failed contrast for both white (3.80:1) and near-black (4.48:1) text over a dark photo — Apple raised the floor in iOS 27. Keep fill alpha ≥ ~0.55 and pair ink with the fill.

---

## 2. Implementation paths in Expo SDK 58 / RN 0.88

### 2.1 `expo-glass-effect` — DEAD on Android

- Official Expo docs (opened 2026-11-14): "React components that render a liquid glass effect using iOS's native UIVisualEffectView." Platforms listed: **iOS, tvOS** only. Recommended version `~58.0.5`.
- "GlassView is only available on iOS 26 and above. **It will fallback to regular `View` on unsupported platforms.**" On Android it renders a plain transparent `View` — no error, no visual effect.
- Helpers exist (`isLiquidGlassAvailable()`, `isGlassEffectAPIAvailable()`) precisely because the effect is absent almost everywhere except iOS 26+. Known bug: `opacity: 0` on a `GlassView` or any ancestor kills the effect entirely.
- It is already present in this scaffold's `node_modules` (transitive dependency of `expo-router`), but it is **not** a direct dependency and does nothing on the A60. **Installing it as a direct dep would change nothing on the demo phone.**
- License: MIT (Expo). Free. Irrelevant — wrong platform.

### 2.2 `@callstack/liquid-glass` — DEAD on Android

- Callstack's library bridges Apple's native Liquid Glass APIs (Fabric/TurboModules). Callstack's own docs: "The Liquid Glass effect is only supported on iOS 26 and above. Our library automatically renders a normal, opaque `View` on older iOS versions **or on Android**."
- Same verdict as 2.1: real glass on iOS 26, nothing on the A60. Free/open source. Skip.

### 2.3 `expo-blur` — the cheap fake (ALREADY INSTALLED, works today)

- **Status in this project: installed.** `expo-blur ~58.0.6` is in the scaffold's `package.json` and was compiled into the existing preview APK (built from git `1021030`). No new native code needed.
- **What it does:** `BlurView` blurs everything underneath the view. `intensity` 1–100 (default 50, animatable with Reanimated), `tint` (`light`/`dark`/`default`/system materials).
- **The Android trap (verified in the official docs, opened 2026-11-14):** a bare `<BlurView>` on Android renders **a semi-transparent view with no actual blur** (`blurMethod` defaults to `'none'`). Real Android blur requires all three:
  1. Wrap the background content in `<BlurTargetView>` and hold a ref to it.
  2. Pass that ref as `blurTarget` to each `BlurView`.
  3. Set `blurMethod="dimezisBlurViewSdk31Plus"` (RenderNode path, API 31+; falls back to `'none'` below API 31).
- The A60 runs API 34, so the RenderNode path applies. `blurReductionFactor` (default 4) divides intensity on Android to match iOS perception.
- **Other verified gotchas:** blur does not update if the `BlurView` renders *before* dynamic content (e.g. `FlatList`) — render it after; `borderRadius` is not applied on `BlurView` itself — use `overflow: 'hidden'` on a wrapper; one `BlurTargetView` can serve multiple `BlurView`s inside its bounds (more efficient than one per card).
- **What it cannot do:** no displacement, no refraction, no dispersion, no specular tracking. It is frosted blur. The "glass" read must come from the layers you add on top: a translucent tint, a top-edge specular gradient (use `expo-linear-gradient`, already installed at `~58.0.4`), and a 1 px bright top border.
- **Cost:** JS only. But see §4 — the current APK has no `expo-updates`, so shipping even this needs one EAS rebuild.

### 2.4 `@shopify/react-native-skia` 2.14.0 — real shader, wrong backdrop

- **SDK 58 pin verified:** Expo SDK 58 pins `@shopify/react-native-skia` **2.14.0** (published 2026-10-01, per `expo@58.0.12/bundledNativeModules.json`). Independent corroboration: the 6pm app ships Skia **2.13.1** with Expo 58 / RN 0.88 / Reanimated 4.7.0, running full-screen runtime shaders at 60/120 fps. Skia 2.13+ is New Architecture only.
- **Do NOT install `react-native-skia` 3.x.** The project moved in Oct 2026: `@shopify/react-native-skia` stops at 2.14; v3 is published as `react-native-skia` with a new Graphite/WebGPU renderer (Android moves from OpenGL to Vulkan, minSdk 26). It is **not** the SDK 58 pin. Adopting it would be a gamble on an unpinned major version the night before the demo.
- **Verified API (official Skia docs, opened 2026-11-14):** `Skia.RuntimeEffect.Make(source)` compiles SkSL and returns `null` on failure (check it); shaders are `half4 main(float2 xy)`; `<Shader source={effect} uniforms={{...}} />` nests inside `<Fill>`; child shaders are sampled with `image.eval(coord)` — the docs' own nested-shader example displaces sample coordinates (`xy.x += sin(xy.y / 3) * 4`) and samples an `<ImageShader>` child. Uniforms can be driven from Reanimated `useDerivedValue` on the UI thread without React renders.
- **The decisive limitation:** Skia's `BackdropFilter` only samples content drawn **in the same canvas**. It cannot refract the surrounding React Native views. As one production doc puts it: "Displacement over a flat color produces no visible refraction… It does not refract the surrounding React Native transcript." A Skia glass card over the app's real content would show… nothing refracted. To get visible refraction you must draw the backdrop **inside** the canvas (an image, a gradient, a generated texture) — at which point you are demoing a lens over a picture, not glass over your app.
- **Bridging the gap (theoretical, not recommended):** snapshot the RN backdrop into an image every frame (`react-native-view-shot` / `captureRef`) and feed it to the shader as the `ImageShader` child. That is a per-frame full-screen capture + upload on a Snapdragon 680 — likely jank, and `react-native-view-shot` is not in the scaffold. **Unverified, and I would not attempt it tonight.**
- **Performance on the SD680:** no verified fps numbers for this chip exist in the sources read. What is known: shader cost scales with pixel count, and the A60's panel is 720×1604 ≈ **1.15 M pixels** — roughly half a 1080p panel — which helps. A small card shader (a few hundred × a few hundred px) is cheap on any Adreno; a full-screen per-pixel shader with blur is the risky end. One report notes a complex blur/path can take ~10 ms on a low-end Android device — over half the 16 ms frame budget. Treat any full-screen shader as unproven until it runs on the phone.
- License: MIT (Shopify). Free. Needs `npx expo install @shopify/react-native-skia` + EAS rebuild (native module, not in the current APK, not in Expo Go for SDK 58).

### 2.5 `@sbaiahmed1/react-native-blur` 6.0.2 — the real-Android-glass spike

- **What it is:** a fork of the community blur library. v6.0.0 (2026-09-20) added **native Liquid Glass on Android 13+**: `LiquidGlassView` renders refraction, dispersion, blur and tint on the GPU through an AGSL `RuntimeShader` (QmDeve's `AndroidLiquidGlassView`, MIT, bundled — no new Gradle dependency). iOS 26+ keeps `UIGlassEffect`; both platforms share the same props. Older Android/iOS fall back to an enhanced blur automatically.
- **Requirements (from its own installation docs):** RN 0.80+ with the New Architecture (we have 0.88 ✓); Android minSdk API 24; Android Gradle Plugin 8.9.1+. No extra Android configuration; the QmBlurView dependency resolves from JitPack automatically. The library's own docs warn: "use it wisely — every glass surface pays real capture cost."
- **Why it is the best spike candidate:** it is the only path found that refracts **live RN content** on Android from a single component, with documented fallbacks — no shader hand-rolling, no snapshot bridge.
- **Why it is only a spike (attack it honestly):**
  - **Very young.** Real Android glass landed 2026-09-20 — seven weeks ago. One maintainer's fork, not the community package. Thin track record; no evidence it has ever built under SDK 58 / RN 0.88 / the EAS cloud image.
  - **JitPack dependency.** QmBlurView resolves from JitPack at build time — a network dependency outside npm. If JitPack is slow or down during the EAS build, the build fails and the cycle is lost.
  - **AGP floor unverified end-to-end.** The SDK 58 toolchain on this machine references AGP 9.2.1 (found in `node_modules`), which clears the 8.9.1 floor — but the AGP version of the *generated* `android/` project was not directly verified. Confirm at `prebuild` time.
  - **Not in Expo Go.** It is a custom native module: dev build / EAS build only. One failed native build costs the whole ~90-minute queue.
  - License: MIT (per its docs/releases; the bundled QmDeve shader is MIT). Free, no account/key.
- **Install would be:** `npm install @sbaiahmed1/react-native-blur` (note: not `npx expo install` — it is not an Expo package, so no SDK pin protects you) + EAS build. Then one `LiquidGlassView` on one hero surface, tested on the phone before anything else.

### 2.6 The other AGSL libraries — same job, less verified

- **`react-native-liquid-glassmorphism`** (himanshu-lal4): same architecture — native `UIGlassEffect` on iOS 26, real-time AGSL refraction shader on Android 13+, blur/tint fallbacks below. RN 0.83+, minSdk 24, optional Expo config plugin included, dev build only (not Expo Go). **License not verified in the sources read.** Newer and smaller than 2.5; no reason to prefer it over 2.5.
- **`react-native-glass-lens`** 0.3.0 (published ~2 weeks ago): GPU blur + edge refraction, Android API 31+ (refraction 33+), iOS Metal. RN 0.80+ New Arch. Claims 120 fps scrolling under glass. Version 0.3.0 — the least mature of the three.
- **`rit3zh/expo-glass-custom-menu`**: a one-weekend experiment recreating the iOS Liquid Glass menu on Android with a local native module + AGSL, on Expo SDK 58 / RN 0.88. Needs a dev build; full effect needs Android 13+. Interesting as prior art, not a dependency to adopt tonight.
- **Rule: pick at most one of 2.5/2.6 as the spike.** They all do the same thing; trying two burns two build cycles.

---

## 3. Feasibility verdict for tomorrow on the OPPO A60

**What is achievable in the remaining hours:**

1. **One fake-glass hero surface (do this first).** A single floating pill/chip or card: `BlurTargetView` + `BlurView` (`blurMethod="dimezisBlurViewSdk31Plus"`, `intensity` ~60–80) + translucent tint + `expo-linear-gradient` specular wash (bright top, fading down) + 1 px top highlight border. It reads as glass in a demo, costs almost nothing at runtime, and uses only packages already in the scaffold. **Ship it in the next EAS build.**
2. **One real-glass spike (only if a build slot is free).** Add `@sbaiahmed1/react-native-blur`, put a single `LiquidGlassView` on the same hero surface, build, and test on the phone: does it build, does it render, does it hold 60 fps while scrolling, does text stay readable. If any answer is no, fall back to (1) — the fake is already in the same build if you include both behind a flag.
3. **A Skia "lens over a picture" moment (optional garnish, only if the product has one).** If some screen already shows a full-bleed image (a scanned document photo, a hero image), a small Skia canvas refracting *that image* is genuinely achievable — but it is a picture effect, not app glass. Do not present it as glass over the app.

**What will be too slow or crash:**

- Full-screen per-pixel refraction shaders on the Adreno 610, untested — assume jank until the phone proves otherwise.
- More than one or two live glass surfaces — every surface pays a backdrop-capture cost; the blur library's own guidance says to use it wisely.
- Nested glass (a glass card inside a glass sheet) — looks worse and runs slower by construction.
- Any path that needs a second native rebuild after a failure — the free-tier queue (~90 min/cycle) means at most one or two build attempts fit before the 15:00 artifact freeze.

**What to skip:**

- `expo-glass-effect`, `@callstack/liquid-glass` (iOS-only; zero effect on the demo phone).
- Skia as "glass over the app" (architecturally impossible — it cannot sample RN views).
- Skia 3.x / `react-native-skia` (not the SDK 58 pin).
- The snapshot-bridge idea (per-frame `captureRef` into a shader) — unverified and likely janky on SD680.
- Trying two AGSL libraries — pick one spike at most.

---

## 4. Minimal code sketches (verified APIs only)

### 4.1 Fake glass card — `expo-blur` (all APIs verified in the official docs)

```tsx
import { useRef } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { BlurView, BlurTargetView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';

// Background content MUST be wrapped in BlurTargetView, and the BlurView
// MUST come after it in the tree. Bare <BlurView> blurs nothing on Android.
export function GlassChip({ children }: { children: React.ReactNode }) {
  const targetRef = useRef<View | null>(null);
  return (
    <View style={styles.screen}>
      <BlurTargetView ref={targetRef} style={StyleSheet.absoluteFill}>
        {/* ...the real screen content goes here... */}
      </BlurTargetView>

      <View style={styles.chipWrap}>
        <BlurView
          blurTarget={targetRef}
          blurMethod="dimezisBlurViewSdk31Plus" // RenderNode path, API 31+; A60 is API 34
          intensity={70}
          tint="light"
          style={StyleSheet.absoluteFill}
        />
        {/* Specular wash: bright top edge, fading down — the "light source above" cue */}
        <LinearGradient
          colors={['rgba(255,255,255,0.55)', 'rgba(255,255,255,0.05)']}
          style={StyleSheet.absoluteFill}
        />
        {/* 1px top highlight = the rim that sells "glass" instead of "tinted film" */}
        <View style={styles.topRim} />
        <Text style={styles.label}>{children}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  chipWrap: {
    overflow: 'hidden', // borderRadius does not apply on BlurView itself
    borderRadius: 999,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.35)',
    paddingHorizontal: 18,
    paddingVertical: 10,
  },
  topRim: { position: 'absolute', top: 0, left: 12, right: 12, height: 1, backgroundColor: 'rgba(255,255,255,0.8)' },
  label: { color: '#111', fontWeight: '600' },
});
```

All imports here are packages already in the scaffold (`expo-blur ~58.0.6`, `expo-linear-gradient ~58.0.4`). Keep the fill alpha high enough to read text over any backdrop (≥ ~0.55 effective; Apple's shipped 0.40 failed contrast).

### 4.2 Skia refraction over an in-canvas image (sketch, NOT tested)

Adapted from the official Skia docs' nested-shader example. This refracts an **image drawn inside the canvas** — it does not touch the RN backdrop.

```ts
// liquid-glass.skia.ts — compile once at module scope; RuntimeEffect.Make
// returns null on failure, so check it.
import { Skia } from '@shopify/react-native-skia';

export const glassEffect = Skia.RuntimeEffect.Make(`
  uniform shader image;
  uniform float2 u_resolution;
  uniform float u_radius;   // corner radius, px
  uniform float u_strength; // refraction strength, px (try 6–14)

  float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
  }

  half4 main(float2 xy) {
    vec2 uv = xy / u_resolution;
    vec2 c = vec2(0.5);
    // Signed distance to the rounded-rect edge; 0 at the rim, growing inward.
    float d = sdRoundBox((uv - c) * u_resolution, u_resolution * 0.5, u_radius);
    // Displacement lives in a narrow band near the rim; the centre stays flat.
    float band = smoothstep(24.0, 0.0, d);
    vec2 dir = normalize(uv - c + vec2(1e-5));
    // Bend the sample coordinate inward near the rim (lens), like a real edge.
    vec2 sampleUv = uv - dir * band * u_strength / u_resolution;
    half4 col = image.eval(sampleUv * u_resolution);
    // Cheap specular: brighten the top rim.
    float spec = smoothstep(0.0, 8.0, d) * max(0.0, -dir.y) * band;
    return half4(col.rgb + spec * 0.35, col.a);
  }
`);
if (!glassEffect) throw new Error('glass shader failed to compile');
```

```tsx
import { Canvas, Fill, Shader, ImageShader, useImage } from '@shopify/react-native-skia';
import { glassEffect } from './liquid-glass.skia';

// <ImageShader> is the child sampled by `image.eval(...)` in the shader.
export function LensOverPhoto({ uri, width, height }: { uri: string; width: number; height: number }) {
  const image = useImage(uri);
  if (!image) return null;
  return (
    <Canvas style={{ width, height }}>
      <Fill>
        <Shader
          source={glassEffect}
          uniforms={{ u_resolution: [width, height], u_radius: 24, u_strength: 10 }}
        >
          <ImageShader image={image} fit="cover" rect={{ x: 0, y: 0, width, height }} />
        </Shader>
      </Fill>
    </Canvas>
  );
}
```

**Honesty note on this sketch:** the *pattern* (nested `ImageShader` + `image.eval` with displaced coordinates) is verbatim from the official docs; the SDF edge band and specular term are standard GLSL written for this report and **were not compiled or run anywhere** — no Skia runtime was available in this research pass. Treat it as a starting point, not a drop-in. If it does not compile on the first try, cut it; the fake in 4.1 is the deliverable.

---

## 5. Honest limits and risks

- **The demo phone is Android; the real Liquid Glass is iOS.** Every "real" option on the A60 is a reconstruction (AGSL shader or Skia shader), not Apple's material. Judges see the effect, not the pedigree — but do not claim it is Apple's Liquid Glass.
- **No SD680/Adreno 610 fps numbers exist in the sources read.** All performance claims above are bounds and reasoning (pixel count, per-surface capture cost), not measurements. The phone test is the only measurement that counts — budget time for it.
- **One EAS build ≈ 90 min free-tier queue.** Any new native module (Skia, the blur fork) means a fresh build; a build failure or a runtime crash on the phone burns the cycle. The 15:00 artifact freeze leaves room for at most one or two attempts after the morning gate.
- **The current APK cannot take JS-only changes** (no `expo-updates` in the scaffold). Even the zero-native-code fake needs a rebuild to reach the phone. If you rebuild once, add `expo-updates` so later tweaks are OTA.
- **Expo Go is not a fallback for SDK 58.** The store Expo Go is still on SDK 57 (SDK 58 Go arrives "within a few weeks" of stable); a 57 Go cannot open a 58 project. The preview APK is the demo path.
- **Readability risk is real, not cosmetic.** Glass over busy content kills text contrast — Apple's own shipped alpha failed it. Keep glass to one hero surface, keep text on solid or high-alpha fills, and test over the brightest and busiest backdrops, not just the pretty one.
- **The AGSL libraries are weeks old.** The blur fork's Android glass is 7 weeks old; `glass-lens` is at 0.3.0. Expect sharp edges: undocumented props, build quirks, and a maintainer who may not answer at 02:00.
- **The brief may not want glass at all.** The 09:45 brief decides the product; glass is garnish. Do not let a refraction spike eat the morning — cap it at one build attempt and one phone test, then stop.

---

## 6. $0 check

| Path | Cost | Account / key needed? |
|------|------|-----------------------|
| `expo-glass-effect` | Free (MIT, Expo) | No |
| `@callstack/liquid-glass` | Free (open source) | No |
| `expo-blur` | Free (MIT, Expo) | No |
| `@shopify/react-native-skia` 2.14.0 | Free (MIT) | No |
| `@sbaiahmed1/react-native-blur` 6.0.2 | Free (MIT; bundled QmDeve shader MIT) | No — but QmBlurView resolves from **JitPack** at build time (free service, build-time network dependency, not a key) |
| `react-native-liquid-glassmorphism` | License **not verified** in sources read — check before adopting | No |
| `react-native-glass-lens` | Free (open source per npm.io listing) | No |
| EAS preview build | Free tier (queue ~90 min) | Expo account the team already has |

Nothing in this report needs a paid service, a new account, or a key.

---

## 7. Sources

1. Expo docs — GlassEffect: https://docs.expo.dev/versions/latest/sdk/glass-effect/ (opened; recommended `~58.0.5`, iOS/tvOS only, falls back to plain `View`)
2. Expo docs — BlurView: https://docs.expo.dev/versions/v55.0.0/sdk/blur-view/ (opened; `BlurTargetView` + `blurMethod` requirement on Android, `blurReductionFactor`, known issues)
3. React Native Skia docs — Shading Language: https://shopify.github.io/react-native-skia/docs/shaders/overview (opened; `RuntimeEffect.Make`, `<Shader>`, nested `ImageShader` + `image.eval`)
4. Apple Newsroom, June 2025 (via The Plus Addons summary): https://theplusaddons.com/blog/liquid-glass-ui/ (real-time rendering, refracts/reflects, specular highlights, adaptive tint)
5. ui-morphism liquid-glass skill: https://github.com/shubham7995/ui-morphism/blob/HEAD/plugins/liquid-glass-ui/skills/apply/SKILL.md (edge lensing 12–24 px band, nested-glass failure, contrast floor 0.55)
6. Expo SDK 58 beta announcement (dev.to / Expo): https://dev.to/expo/expo-sdk-58-beta-opens-with-ios-27-support-and-a-faster-build-pipeline-5bb3 (SDK 58, RN 0.88, `isLiquidGlassAvailable` true on iOS 27 SDK)
7. `@sbaiahmed1/react-native-blur` releases: https://github.com/sbaiahmed1/react-native-blur/releases (v6.0.0 Android liquid glass, 2026-09-20; v6.0.2)
8. `@sbaiahmed1/react-native-blur` installation docs: https://sbaiahmed1.github.io/react-native-blur/docs/installation/ (RN 0.80+ New Arch, AGP 8.9.1+, JitPack QmBlurView, "use it wisely" capture cost)
9. `react-native-liquid-glassmorphism` Android doc: https://github.com/himanshu-lal4/react-native-liquid-glassmorphism/blob/HEAD/docs/android-liquid-glass.md (AGSL on API 33+, fallbacks, compileSdk 34+, NDK 27.1)
10. liquid-glass-skill packages reference: https://github.com/darkiifr/liquid-glass-skill-everyos/blob/HEAD/references/packages.md (verify displacement, not just blur; `alexandrius/liquid-glass-rn-skia` reference)
11. remodr-client Skia effects doc: https://github.com/ljxw88/remodr-client/blob/HEAD/docs/skia-effects.md (`BackdropFilter` only samples same-canvas content; displacement over flat colour shows nothing; `expo-glass-effect` gives no native glass on Android)
12. 6pm — Sky shaders at 120fps with Skia: https://at6pm.app/blog/eng-sky-shaders-react-native-skia (Skia 2.13.1 + Expo 58 + RN 0.88 + Reanimated 4.7.0, production evidence)
13. Soli Skia guide (SDK 58 refresh): https://github.com/karim-attia/soli/blob/HEAD/docs/external-package-guides/react-native-skia.md (SDK 58 pins Skia 2.14.0, published 2026-10-01)
14. React Native Rewind — Skia 3.0 / Graphite migration: https://thereactnativerewind.com/issues/the-great-graphite-migration-derek-joins-fat-fighters-and-a-leaderboard-for-your-dependency-tree (`@shopify` stops at 2.14; v3 is `react-native-skia`, Vulkan on Android, minSdk 26)
15. OPPO A60 official specs: https://www.oppo.com/my/smartphones/series-a/a60/specs/ (SD680, Adreno 610 @1115 MHz, ColorOS 14.0.1; Android 14 / API 34 corroborated by multiple spec listings)
16. Callstack — How to use Liquid Glass in React Native: https://www.callstack.com/blog/how-to-use-liquid-glass-in-react-native (iOS 26 only; plain `View` fallback on Android)

## 8. What was NOT verified (do not treat as fact)

- No fps/frame-time measurement on the Snapdragon 680 / Adreno 610 for any path here.
- No build of Skia 2.14.0 or of the blur fork under SDK 58 / RN 0.88 was run; the AGP version of the generated `android/` project was not directly verified (only the toolchain's AGP 9.2.1 reference in `node_modules`).
- The Skia shader sketch in §4.2 was not compiled or executed.
- `react-native-liquid-glassmorphism`'s licence was not verified; `react-native-glass-lens`'s licence was only seen via an npm.io listing.
- Whether the SDK 58 Expo Go build has reached the Play Store by demo day (sources say "within a few weeks" of stable).
