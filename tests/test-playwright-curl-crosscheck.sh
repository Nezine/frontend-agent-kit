#!/bin/bash
# Unit test for install.sh playwright_curl_check_url (F-3, 2026-11-11).
#
# Extracts the REAL helper from install.sh (verbatim — no copied logic)
# and runs it against stubbed registry values matching the CLI 0.1.24
# bundle's browsers.json (chromium / chromium-headless-shell rev 1254,
# browserVersion 158.0.8127.18; ffmpeg rev 1013, no browserVersion).
# No network, no downloads: the helper only compares strings.
#
# Run: bash tests/test-playwright-curl-crosscheck.sh
# Exit 0 = all cases pass; non-zero = at least one case failed.
set -u
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install_sh="$root/install.sh"
[[ -f "$install_sh" ]] || { printf 'FAIL: install.sh not found at %s\n' "$install_sh"; exit 1; }

# Extract playwright_curl_check_url verbatim from install.sh and eval it.
# The check calls playwright_curl_validate_url first (F-RT1 fix pass),
# so extract that helper too.
validator="$(awk '/^playwright_curl_validate_url\(\) \{/{f=1} f{print} f && /^}/{exit}' "$install_sh")"
[[ -n "$validator" ]] || { printf 'FAIL: playwright_curl_validate_url not found in install.sh\n'; exit 1; }
eval "$validator"
helper="$(awk '/^playwright_curl_check_url\(\) \{/{f=1} f{print} f && /^}/{exit}' "$install_sh")"
[[ -n "$helper" ]] || { printf 'FAIL: playwright_curl_check_url not found in install.sh\n'; exit 1; }
eval "$helper"

# Stubbed registry (same values as browsers.json in the published bundle).
playwright_browser_version() {
  case "$1" in
    chromium|chromium-headless-shell) printf '158.0.8127.18' ;;
    *) return 1 ;;
  esac
}
playwright_revision() {
  case "$1" in
    chromium|chromium-headless-shell) printf '1254' ;;
    ffmpeg) printf '1013' ;;
    *) return 1 ;;
  esac
}

pass=0
fail=0
# check <label> <want-exit-0-or-1> <url> <name> <rev>
check() {
  local label="$1" want="$2" url="$3" name="$4" rev="$5" out rc
  out="$(playwright_curl_check_url "$url" "$name" "$rev" 2>&1)"; rc=$?
  if [[ "$want" == "0" ]]; then
    if [[ "$rc" == 0 ]]; then
      printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
    else
      printf 'FAIL: %s — expected accept (0), got refuse (%s): %s\n' "$label" "$rc" "$out"; fail=$((fail + 1))
    fi
  else
    if [[ "$rc" != 0 ]] && printf '%s' "$out" | grep -q 'refusing to place'; then
      printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
    else
      printf 'FAIL: %s — expected refuse (1 + refusing message), got rc=%s out=%s\n' "$label" "$rc" "$out"; fail=$((fail + 1))
    fi
  fi
}

# Accept cases — the fix (F-3): CDN CFT arms compare version, not revision.
check "CDN CFT darwin mac-arm64 chrome accepts" 0 \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/cft/158.0.8127.18/mac-arm64/chrome-mac-arm64.zip" \
  chromium 1254
check "CDN CFT darwin mac-x64 headless-shell accepts" 0 \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/cft/158.0.8127.18/mac-x64/chrome-headless-shell-mac-x64.zip" \
  chromium-headless-shell 1254
check "CDN CFT linux chrome accepts (pre-existing Linux arm fixed too)" 0 \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/cft/158.0.8127.18/linux64/chrome-linux64.zip" \
  chromium 1254
check "CDN ffmpeg mac accepts (revision 1013)" 0 \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-mac.zip" \
  ffmpeg 1013
check "CDN ffmpeg linux accepts (revision 1013)" 0 \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-linux.zip" \
  ffmpeg 1013
check "GCS chrome mac-arm64 accepts (version branch unchanged)" 0 \
  "https://storage.googleapis.com/chrome-for-testing-public/158.0.8127.18/mac-arm64/chrome-mac-arm64.zip" \
  chromium 1254
check "GCS headless-shell mac-x64 accepts" 0 \
  "https://storage.googleapis.com/chrome-for-testing-public/158.0.8127.18/mac-x64/chrome-headless-shell-mac-x64.zip" \
  chromium-headless-shell 1254

# D35 (GAP-14) — bare-CDN shapes: the CDN branch parses builds/<kind>/<seg>
# independent of any host prefix, so bare URLs get the same cross-check.
check "D35 bare CDN CFT linux chrome accepts" 0 \
  "https://cdn.playwright.dev/builds/cft/158.0.8127.18/linux64/chrome-linux64.zip" \
  chromium 1254
check "D35 bare CDN CFT linux headless-shell accepts" 0 \
  "https://cdn.playwright.dev/builds/cft/158.0.8127.18/linux64/chrome-headless-shell-linux64.zip" \
  chromium-headless-shell 1254
check "D35 bare CDN ffmpeg linux accepts (revision 1013)" 0 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/ffmpeg-linux.zip" \
  ffmpeg 1013
check "D35 bare CDN ffmpeg mac-arm64 accepts (revision 1013)" 0 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/ffmpeg-mac-arm64.zip" \
  ffmpeg 1013
# D35 — prss.microsoft.com (mirror #2, ffmpeg only): previously fell
# through to `return 0` unchecked (fail-open); now cross-checked.
check "D35 prss ffmpeg linux accepts (revision 1013)" 0 \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-linux.zip" \
  ffmpeg 1013
check "D35 prss ffmpeg linux-arm64 accepts (revision 1013)" 0 \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-linux-arm64.zip" \
  ffmpeg 1013

# Refuse cases — a mismatched build must still be refused, not placed.
check "CDN CFT wrong version refuses" 1 \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/cft/1.2.3.4/mac-arm64/chrome-mac-arm64.zip" \
  chromium 1254
check "CDN ffmpeg wrong revision refuses" 1 \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/9999/ffmpeg-mac.zip" \
  ffmpeg 1013
check "GCS wrong version refuses" 1 \
  "https://storage.googleapis.com/chrome-for-testing-public/1.2.3.4/mac-arm64/chrome-mac-arm64.zip" \
  chromium 1254
check "D35 bare CDN CFT wrong version refuses" 1 \
  "https://cdn.playwright.dev/builds/cft/1.2.3.4/linux64/chrome-linux64.zip" \
  chromium 1254
check "D35 bare CDN ffmpeg wrong revision refuses" 1 \
  "https://cdn.playwright.dev/builds/ffmpeg/9999/ffmpeg-linux.zip" \
  ffmpeg 1013
check "D35 prss ffmpeg wrong revision refuses (was fail-open, rc=0)" 1 \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/9999/ffmpeg-linux.zip" \
  ffmpeg 1013
check "D35 prss ffmpeg mac wrong revision refuses" 1 \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/9999/ffmpeg-mac.zip" \
  ffmpeg 1013

# F-RT1 fix pass — traversal / dot-segment / encoded shapes must refuse
# in the check itself (the check's first-segment sed must never see an
# un-normalized URL), not only at the mapping.
check "F-RT1 traversal ffmpeg 1013 -> 1005 refuses" 1 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/../../ffmpeg/1005/ffmpeg-linux.zip" \
  ffmpeg 1013
check "F-RT1 traversal ffmpeg 1013 -> 1005, %2F-encoded refuses" 1 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/..%2F..%2Fffmpeg/1005/ffmpeg-linux.zip" \
  ffmpeg 1013
check "F-RT1 traversal CFT version-then-wrong refuses" 1 \
  "https://cdn.playwright.dev/builds/cft/158.0.8127.18/linux64/../../cft/1.2.3.4/linux64/chrome-linux64.zip" \
  chromium 1254
check "F-RT1 traversal GCS chrome refuses" 1 \
  "https://storage.googleapis.com/chrome-for-testing-public/158.0.8127.18/linux64/../../140.0.7339.186/linux64/chrome-linux64.zip" \
  chromium 1254
check "F-RT1 traversal prss ffmpeg refuses" 1 \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1013/../../ffmpeg/9999/ffmpeg-linux.zip" \
  ffmpeg 1013
check "F-RT1 double slash in path refuses" 1 \
  "https://cdn.playwright.dev//builds/cft/158.0.8127.18/linux64/chrome-linux64.zip" \
  chromium 1254
check "F-RT1 dot segment in path refuses" 1 \
  "https://cdn.playwright.dev/./builds/cft/158.0.8127.18/linux64/chrome-linux64.zip" \
  chromium 1254
check "F-RT1 double /builds/ refuses" 1 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/builds/cft/158.0.8127.18/linux64/chrome-linux64.zip" \
  chromium 1254
check "F-RT1 evilbuilds/builds refuses" 1 \
  "https://cdn.playwright.dev/evilbuilds/builds/ffmpeg/1013/ffmpeg-linux.zip" \
  ffmpeg 1013
check "evilbuilds single segment refuses (unknown builds kind)" 1 \
  "https://cdn.playwright.dev/evilbuilds/cft/158.0.8127.18/linux64/chrome-linux64.zip" \
  chromium 1254
# W-RT1 fix pass — chromium/headless-shell names on the prss host must
# refuse in the check itself, even at the correct version.
check "W-RT1 prss CFT correct version refuses (prss is ffmpeg-only)" 1 \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/cft/158.0.8127.18/linux64/chrome-linux64.zip" \
  chromium 1254
check "W-RT1 prss headless-shell correct version refuses" 1 \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/cft/158.0.8127.18/linux64/chrome-headless-shell-linux64.zip" \
  chromium-headless-shell 1254

# F2-RT1 fix pass 2 — semicolon-param traversal (the red team's exact
# live URLs) and the W2-RT3 exotic-encoding family must refuse in the
# check itself, via the validator's segment-shape allowlist.
check "F2-RT1 semicolon CDN CFT chrome landing refuses" 1 \
  "https://cdn.playwright.dev/builds/cft/158.0.8127.18/..;/140.0.7339.186/linux64/chrome-linux64.zip" \
  chromium 1254
check "F2-RT1 semicolon GCS chrome landing refuses" 1 \
  "https://storage.googleapis.com/chrome-for-testing-public/158.0.8127.18/..;/140.0.7339.186/linux64/chrome-linux64.zip" \
  chromium 1254
check "F2-RT1 semicolon GCS headless-shell landing refuses" 1 \
  "https://storage.googleapis.com/chrome-for-testing-public/158.0.8127.18/..;/140.0.7339.186/linux64/chrome-headless-shell-linux64.zip" \
  chromium-headless-shell 1254
check "F2-RT1 semicolon GCS mac-arm64 chrome landing refuses" 1 \
  "https://storage.googleapis.com/chrome-for-testing-public/158.0.8127.18/..;/140.0.7339.186/mac-arm64/chrome-mac-arm64.zip" \
  chromium 1254
check "F2-RT1 semicolon-param ..;x=1 refuses" 1 \
  "https://cdn.playwright.dev/builds/cft/158.0.8127.18/..;x=1/140.0.7339.186/linux64/chrome-linux64.zip" \
  chromium 1254
check "W2-RT3 dot-semicolon .; refuses" 1 \
  "https://storage.googleapis.com/chrome-for-testing-public/158.0.8127.18/.;/140.0.7339.186/linux64/chrome-linux64.zip" \
  chromium 1254
check "W2-RT3 double-encoded dotdot %252e refuses" 1 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/%252e%252e/%252e%252e/ffmpeg/1005/ffmpeg-linux.zip" \
  ffmpeg 1013
check "W2-RT3 overlong UTF-8 %c0%ae refuses" 1 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/%c0%ae%c0%ae/%c0%ae%c0%ae/ffmpeg/1005/ffmpeg-linux.zip" \
  ffmpeg 1013
check "W2-RT3 triple-dot segment refuses" 1 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/.../ffmpeg/1005/ffmpeg-linux.zip" \
  ffmpeg 1013
check "W2-RT3 null byte %00 segment refuses" 1 \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/%00/ffmpeg-linux.zip" \
  ffmpeg 1013

printf 'cross-check test: %s PASS, %s FAIL\n' "$pass" "$fail"
[[ "$fail" == 0 ]]
