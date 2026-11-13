---
name: evidence-capture
description: "Evidence capture for the hackathon demo day: record the 60-90s backup video of the golden path with adb screenrecord or scrcpy, pull it to the laptop, upload it, and verify it plays — plus 3-5 screenshots as the last rung. Use when the team records the backup at ~14:00 and re-records at ~14:45 after the second clean rehearsal run. Free only: adb (Android SDK Platform Tools) and scrcpy are both free and open source (Apache 2.0). No device farm, no paid service."
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Gemini CLI, GitHub Copilot, Muse Code, Cursor. Needs a Linux/macOS/Windows laptop, the Android SDK Platform Tools (adb), scrcpy 5.0.1, one real Android phone with USB debugging enabled, and a USB cable (or same-Wi-Fi wireless debugging). No accounts, no cost.
metadata:
  version: "0.1.0"
---

# evidence-capture — record the backup, prove it plays

You are the QC agent (role D) for a 5-hour hackathon build: Expo SDK 58,
preview APK demo on one real Android phone, pitches from 16:15. The live
demo can die for reasons outside the team's control. Your job is the
fallback ladder's last two rungs: a 60–90 second recording of the golden
path, hosted online + on the laptop, and 3–5 screenshots. A recording
nobody tested is not a backup. Record it, pull it, upload it, play it
back for someone else, keep it open in a tab.

## 0. Pins — read first, never drift

- `adb` is included in the Android SDK Platform Tools package; the
  server binds to local TCP port 5037; USB debugging must be enabled
  under Developer options and the RSA key dialog accepted on the phone.
  Current platform-tools version cited in the docs: adb 37.0.0.
  Source: https://developer.android.com/tools/adb
- `adb shell screenrecord`: records the display, maximum length 3
  minutes (`--time-limit`, default and maximum 180 seconds), default
  bit rate 20 Mbps, native display resolution by default. Limitations:
  audio is NOT recorded; rotation during recording is not supported
  (the picture is cut off if the screen rotates).
  Source: https://developer.android.com/tools/adb#screenrecord
- scrcpy **5.0.1** (latest release), Apache 2.0. Mirrors Android devices
  (video and audio) over USB or TCP/IP, allows control from the
  computer's keyboard and mouse, needs no root and no app installed on
  the device, works on Linux, Windows and macOS. Audio forwarding needs
  Android 11+. Recording: `scrcpy --record=file.mp4`.
  Sources: https://github.com/Genymobile/scrcpy and
  https://github.com/Genymobile/scrcpy/releases/latest
- The backup-video rules (record 1–3 minutes before the deadline
  crunch, upload unlisted, confirm the link plays for someone else,
  always have it open in a tab, simulate the failure in rehearsal)
  come from 30-Days-of-Hackathon Day 24, cited in
  `research/testing-deep-20261113.md` section 7 (accessed 2026-11-13
  by that brief's author; not re-opened in this pass — see section 5).
- The backup ladder: primary live app → backup deploy → recording +
  screenshots. Source: HackMIT-playbook-based skill, hackathon-testing —
  https://github.com/andomo3/flecto-shade/blob/HEAD/.claude/skills/hackathon-testing/SKILL.md
  (MIT, read 2026-11-13).

## 1. Setup — before build day, ~10 minutes

Do this the night before, not during the build window. USB debugging
authorisation is a one-time dialog on the phone; discovering it at
14:00 wastes the recording slot.

1. Install the Android SDK Platform Tools (standalone download from
   the official Android developer site — see the adb pin above) and
   confirm `adb --version` runs.
2. Install scrcpy 5.0.1 (package manager on Linux, or the release
   archive from the official repo only — the repo warns that it is the
   only official source; do not download releases from random sites).
   Confirm `scrcpy --version` runs.
3. On the demo phone: enable Developer options, enable USB debugging,
   connect over USB, accept the RSA key dialog. `adb devices` must list
   the phone as `device` (not `unauthorized`).
4. Test-record 10 seconds with each tool (section 2) and play the file
   back. If either tool fails on this phone, the other one is the
   fallback — know which works before build day.

## 2. Record — two tools, pick one per take

### Option A — adb screenrecord (simplest, no extra install beyond adb)

```bash
adb shell screenrecord --time-limit 90 /sdcard/demo-golden-path.mp4
# ...run the golden path on the phone (human taps, ~60-90s)...
# Stop with Ctrl-C, or let the time limit end it. Then pull it:
adb pull /sdcard/demo-golden-path.mp4 ./evidence/demo-golden-path.mp4
```

Limits, from the official docs: max 3 minutes per recording; NO audio
(the presenter narrates live over it, or the video is silent B-roll);
do not rotate the phone mid-recording. 90 seconds at the default
20 Mbps is ~225 MB — fine for a laptop, too big to send over chat;
upload it, do not attach it.

### Option B — scrcpy (mirror to the laptop + record with audio)

```bash
scrcpy --record=./evidence/demo-golden-path.mp4 --max-size=1920
# ...run the golden path on the phone (or drive it from the laptop)...
```

scrcpy mirrors the phone to the laptop screen while recording, so the
same window can feed the projector if the phone cannot connect to the
room display directly. Audio forwarding needs Android 11+. If the
phone runs Android 10 or older, audio is not forwarded — use Option A
and narrate live.

Pick ONE tool per take and stick to it for that take. Do not switch
tools mid-recording.

## 3. The recording schedule (build day)

| When | What |
| --- | --- |
| ~14:00 | First recording, when the project is most stable. 60–90s, golden path only: starting situation → AI action → result → why it matters. |
| ~14:45 | Re-record after the second clean rehearsal run, if the build changed. This cut is the one that ships. |
| 15:45 check | Confirm the shipped cut plays (open in a tab, tested). |
| 16:00 check | Confirm the backup video plays again (open in a tab, tested), charger plugged in. |

After each recording: (1) pull the file to the laptop; (2) upload it
(unlisted) AND keep a copy on the laptop; (3) open the uploaded link
in a tab and confirm it plays — for someone else, not just yourself;
(4) take 3–5 screenshots of the key screens (`adb exec-out
screencap -p > evidence/shot-1.png`, or the phone's own screenshot
keys) as the last rung. A video that only exists on the laptop is half
a backup; a video nobody watched play is not a backup.

## 4. What to record — and what never to fake

Record the real app, on the real phone, with the real demo input and
the real AI response. The kill switch (`?demo=1`) serves a cached
golden response that is itself a real recorded AI output — never
hand-written, never invented. The presenter always says what the
recording is ("the recorded version") — never passes a recording off
as live. The one time a recording is presented as live, the team's
credibility on the evidence criterion is gone.

## 5. Ban list — this skill MUST NOT use these

| Banned | Why |
| --- | --- |
| Any paid screen recorder, device farm, or cloud recording service | Free-only rule. adb + scrcpy + the phone's built-in recorder cover everything. |
| scrcpy releases from any site other than the official repo | The project warns its GitHub repo is the only official source. |
| Recording longer than 3 minutes in one `screenrecord` take | Hard limit in the tool; the golden path is 60–90s anyway. |
| Presenting a recording as live | Credibility rule (section 4). |

## 6. File map

| File | What it is |
| --- | --- |
| `SKILL.md` (this file) | Setup, the two recording options, the schedule, the verify steps, ban list. |

## 7. Verification status (read 2026-11-13)

- adb / screenrecord (commands, 3-minute limit, no audio, 20 Mbps
  default, RSA prompt) and scrcpy 5.0.1 (Apache 2.0, mirror + record,
  audio on Android 11+, official-source warning) were read on their
  official docs / repo pages today (sources in section 0).
- Coordinator re-check 2026-11-13 (adb docs page re-opened):
  platform-tools 37.0.0 confirmed on the page; 3-minute screenrecord
  max and "Audio is not recorded with the video file" confirmed; the
  20 Mbps default bitrate was not re-isolated in this pass (the page
  mentions Mbps in the screenrecord options) — stated from the finder's
  read.
- NOT run end to end: there is no real phone and no adb/scrcpy in this
  environment. The setup test (section 1, step 4) is a build-day-minus-
  one task on the real phone, not an assumption.
- The backup-video rules (record early, upload, confirm playback, keep
  open in a tab, simulate the failure) are cited through the in-repo
  research brief (`research/testing-deep-20261113.md` section 7); the
  30-Days-of-Hackathon source was not re-opened in this pass.
- CHƯA ĐỌC: the demo phone's Android version (decides whether scrcpy
  audio forwarding works); whether the venue Wi-Fi allows the upload
  step, or whether the upload must happen over mobile data.
