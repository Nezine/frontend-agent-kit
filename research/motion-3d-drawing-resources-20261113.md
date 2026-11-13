# Free motion / 3D / drawing resources for Expo SDK 58 — research report

**Access date: 2026-11-13.** All items $0, no paid plans, no accounts/keys created. Licenses verified by opening the source where stated; otherwise marked.

## 1. Motion / animation libraries

**react-native-reanimated (v4.7.1 — bundled in Expo SDK 58) — PICK #1**
- What: UI-thread animation (60–120 fps), shared values, entering/exiting/layout animations, gestures. The foundation everything else builds on.
- License: **MIT — verified by opening the repo LICENSE file** (https://github.com/software-mansion/react-native-reanimated/blob/main/LICENSE).
- Install: `npx expo install react-native-reanimated` (already in the default Expo template; SDK 58 bundles Reanimated 4.7.1 + Worklets 0.13.0).
- Works in Expo Go. Docs (verified by opening): https://docs.expo.dev/develop/user-interface/animation/ and https://docs.swmansion.com/react-native-reanimated/docs/3.x/

**Moti (v0.30.0) — PICK #2 for speed**
- What: Declarative Framer-Motion-like wrapper over Reanimated (`<MotiView from animate exit />`). Best for staggered lists, onboarding, micro-interactions — ~10x less code than raw Reanimated.
- License: **MIT — verified via jsDelivr package page** (https://www.jsdelivr.com/package/npm/moti).
- Install: `npx expo install moti` (after Reanimated). Works iOS/Android/web, Expo Go OK. Docs: https://moti.fyi/ (verified by opening).
- Caveat: docs say "Powered by Reanimated 3"; latest release 0.30.0 is from Jan 2025. Smoke-test with Reanimated 4 before relying on it.

**lottie-react-native + LottieFiles free animations**
- What: Renders designer-made JSON/dotLottie animations (splash, success check, loading, empty states) as tiny files (~15 KB).
- License: library is Apache-2.0 (not re-opened this run — standard, treat as UNVERIFIED until checked). Animation files: license varies per animation on LottieFiles — check each one.
- Install: `npx expo install lottie-react-native`; drop JSON in `assets/`, `<LottieView source={require(...)} />`.
- Caveat: **needs a dev build / preview APK — does NOT work in Expo Go** (per 2025 guide). Fine for this team (demo runs on preview APK).
- Free source: https://lottiefiles.com/free-animations/ (free account needed to download). No-signup fallback: **useAnimations** (CC-BY 4.0, attribution required) via raw GitHub URL pattern `https://raw.githubusercontent.com/useAnimations/react-useanimations/master/src/lib/<Name>/<Name>.json`.

**@shopify/react-native-skia v2 / react-native-skia v3 — only if a specific effect needs it**
- What: GPU canvas — custom vector drawing, shaders, particles, liquid effects. The power tool; also the highest effort.
- License: **UNVERIFIED this run** (LICENSE file open on the v3 repo returned 404; did not re-verify). Free/open-source; verify license before shipping.
- Install: `npx expo install @shopify/react-native-skia` (v2, in Expo Go's bundled natives but needs dev build) or `react-native-skia` (v3, Graphite/Dawn, needs iOS 15.1 / Android minSdk 26).
- Verdict: **skip for a 1-day hackathon unless one named effect requires it.** Template: `npx create-expo-app my-app -e with-skia`.

**react-native-reanimated-carousel v5** — free, pure JS, no native code, works in Expo Go. For swipeable carousels. Docs: https://github.com/dohooo/react-native-reanimated-carousel (Expo page verified in search).

## 2. 3D for Expo / React Native

**React Three Fiber (@react-three/fiber) + three.js + @react-three/drei — the only recommended 3D path**
- What: Declarative Three.js as React components; same API on web and native.
- License: **MIT (r3f, drei, three.js all MIT)** — verified via dossier.
- Native setup (verified by opening the official install doc, https://github.com/pmndrs/react-three-fiber/blob/HEAD/docs/getting-started/installation.mdx):
  - `expo install expo-gl` then `npm install three @react-three/fiber`
  - Import from `@react-three/fiber/native` and `@react-three/drei/native`
  - Metro config must add `assetExts: ['glb', 'gltf', 'png', 'jpg']` for model loading
  - v9 pairs with React 19 (= SDK 58); v8 pairs with React 18
- Caveat: **test on a physical device** — iOS simulators crash on WebGL (official doc warning). This is the highest-risk item on this list.

**expo-three — SKIP**
- Mixed signals: one 2026 research doc calls it "effectively deprecated / maintenance mode"; another (Feb 2026) says 8.0.0 is stable with SDK 54+. The official R3F docs use `expo-gl` directly and never mention expo-three. **Not needed — use the R3F native path above.**

**react-native-wgpu (WebGPU path) — NOT for tomorrow**
- Modern WebGPU route for R3F on native (RN 0.81+, New Arch only), mentioned in a Feb 2026 research doc. Too bleeding-edge for a 1-day build; listed only so the team doesn't chase it mid-hackathon.

**Avatoon** — MIT, free 3D talking avatar with lip-sync, works on Expo (https://github.com/khaledalam/avatoon). Niche — only if the demo wants an avatar character.

## 3. Drawing / illustration (SVG assets)

**unDraw — PICK #1 for scenes**
- What: 500+ flat SVG illustrations (people + tech), recolorable on the fly, SVG + PNG download.
- License: **open license, free, no attribution — verified by opening https://undraw.co/** ("use completely free and without attribution", "commercial or personal projects worry-free", price $0). Multiple sources confirm MIT.
- Use in app: download SVG → render with `react-native-svg`, or export PNG.

**Open Peeps — PICK #1 for characters**
- What: Modular hand-drawn people — mix heads/faces/bodies/clothing/accessories, 584,688 combinations, SVG/PNG.
- License: **CC0 (public domain) — verified via 5+ independent sources** (pixels.market, getillustrations, muz.li, DiceBear docs all confirm CC0, no attribution, commercial OK). Site: https://www.openpeeps.com/
- Also by same author (Pablo Stanley): **Humaaans** (CC0, flat geometric people) and **Open Doodles** (CC0, sketchy scenes).

**DrawKit — free core packs, with a caveat**
- What: Polished hand-drawn 2D + 3D illustration packs, SVG/PNG/Figma.
- License: free packs = free for commercial use, no attribution (verified via current about/license pages). The old MIT license is archived (2020); the site is now freemium (subscription for full access). **Use only the free packs** at https://www.drawkit.com/free-illustrations and check per-pack terms.

**IRA Design — MIT**
- What: Build-your-own illustrations from modular gradients + hand-drawn components. MIT, free personal + commercial, no attribution (per multiple sources; site not opened this run — secondary verification only).

**Flowbite Illustrations** — 50+ 3D-style SVG illustrations, MIT, free (per uideck article; not opened this run — secondary).

**Rendering SVGs in the app: react-native-svg**
- License: **MIT — verified via React Native Directory** (30M+ monthly downloads, New Architecture, works in Expo Go).
- Pre-installed in Expo. Pair with **react-native-svg-transformer** (devDependency) to `import Logo from './logo.svg'` as a component.

## 4. Templates / starter kits (Expo, beautiful + motion)

**fig-app-starter-kit — BEST MATCH**
- What: Full restaurant app built from scratch in a free course: 45 screens, UI kit with glass + motion + sheets, Reanimated animations, design prototype + app icons + splash badge included.
- Stack: **Expo SDK 58, RN 0.88, React 19, TypeScript strict, Expo Router, Reanimated 4, Zustand 5, expo-image/blur/linear-gradient, react-native-svg.** No backend, no accounts, no keys, no paid services.
- License: **MIT — verified from the GitHub repo page.** URL: https://github.com/noorjsdivs/fig-app-starter-kit
- Fit: copy its motion/glass patterns into the demo app; do not adopt the whole repo.

**ReadyNative free — solid fallback**
- What: Expo SDK 57, Expo Router, NativeWind 4, TanStack Query, Zustand, tabs + settings + dark mode, runs in Expo Go.
- License: **MIT — verified via https://readynative.app/**. Repo: https://github.com/ReadyNative/ready-native-free. Note: SDK 57 (one behind), Pro modules are paid — use the free repo only.

**expo-motion skill file — directly droppable**
- What: A ready-made `SKILL.md` covering Reanimated 4, worklets, gestures, transitions, Skia, and Lottie/Rive/R3F tiers for Expo apps.
- License: **MIT — stated in the file.** URL: https://github.com/BjornMelin/dev-skills/blob/HEAD/skills/expo-motion/SKILL.md

**Also noted (not recommended without work):** expo-nativewind-boilerplate (Apache-2.0, but Expo v53 — stale SDK); ExpoKit (free MIT pieces exist, but several screens are paid Pro — pick free pieces only, https://expokit.in/).

## Recommendation for tomorrow (1-day hackathon)

1. **Motion:** Reanimated (already in SDK 58) + Moti for quick wins; Lottie for splash/success/empty states (preview APK only).
2. **3D:** default to **skip** — use layered 2D, gradients, and motion for depth (the kit's existing taste direction). Only take R3F if a 3D hero is truly the demo's centerpiece, and budget physical-device test time.
3. **Drawing:** unDraw (scenes) + Open Peeps (characters), rendered via react-native-svg. Both free, no attribution, no signup.
4. **Reference:** steal motion/glass patterns from fig-app-starter-kit (SDK 58, MIT); drop the expo-motion SKILL.md into the team's skill set.

## Figma-editable preference (dang, 23:52)

When choosing skills/templates/assets, PREFER options editable via Figma (not mandatory, but encouraged). Note per candidate whether it ships Figma files / is Figma-editable.
