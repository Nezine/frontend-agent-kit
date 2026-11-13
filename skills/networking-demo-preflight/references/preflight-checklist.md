# Demo-phone connectivity pre-flight checklist

Copy-paste checklist for the demo phone (one real Android phone).
Source skill: `networking-demo-preflight` (pins + failure tree there).
All checks are on the exact phone that will be demoed — a different
phone proves nothing.

## Tonight — Fri 13/11 (before the build)

- [ ] Expo Go version recorded (Settings → Apps → Expo Go → version at the bottom). SDK decision made from it and written in the run log.
- [ ] `expo login` done on the build laptop (SDK 58 tunnel requires a signed-in Expo account).
- [ ] `node -v` ≥ 22.13 on the build laptop.
- [ ] Scaffold opens on the phone (pinned `--template tabs@sdk-58`, or `@sdk-57` if the phone is 57). No "incompatible" error.
- [ ] Kill-and-reopen ×2 in Expo Go (swipe from Recents → reopen → main screen loads from cold).
- [ ] Tunnel QR scan works from a non-home network; note tunnel slowness; LAN is first try at the venue.
- [ ] AI flow runs end-to-end on mobile data (Wi-Fi OFF). Answer completes — proves the backend URL is public.
- [ ] AI flow runs end-to-end on Wi-Fi (home network). Answer completes.
- [ ] Preview APK built tonight (`eas build --profile preview --platform android`), installed, kill-and-reopen ×2 with Metro STOPPED — main screen loads AND the AI flow completes end-to-end with Metro stopped.
- [ ] `EXPO_PUBLIC_CONVEX_URL` set for the preview environment (`eas env:set` / `eas env:push`); `.env.local` is NOT relied on for the cloud build.
- [ ] Streaming smoke test: `import { fetch } from 'expo/fetch'` in the AI call; `res.body !== null` asserted; never rely on the global fetch for streaming.
- [ ] Expo Go NOT updated/installed again after tonight's test without re-testing the scaffold immediately after.
- [ ] Phone charged, charger + cable packed; laptop charger packed; sleep disabled on the laptop.
- [ ] Same Expo account signed in on CLI and in Expo Go.

## Build day — Sat 14/11, at 13:00 and again at 15:00

- [ ] Wi-Fi OFF, mobile data ON: one full AI request end-to-end. Pass = answer completes.
- [ ] Wi-Fi ON (venue Wi-Fi): same request. Pass = completes. If it fails here but passed on mobile data, demo on mobile data.
- [ ] Preview APK: kill-and-reopen ×2 with Metro STOPPED; AI flow completes both times.
- [ ] Expo Go + Metro LAN still opens (fallback path alive).
- [ ] Cached last result renders on cold open with its "Cached" label + Retry button (see `networking-offline`).
- [ ] No EAS cloud build started after 13:00. No Expo Go update installed today.

## If anything fails at a checkpoint

Follow the failure decision tree in `networking-demo-preflight` §4.
Do not debug the venue network during the pitch: if mobile data works,
demo on mobile data.
