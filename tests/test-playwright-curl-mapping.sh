#!/bin/bash
# Unit test for install.sh playwright_curl_one mapping + playwright_curl_fallback
# derivation (D35 / GAP-14, 2026-11-13).
#
# No test existed for the mapping `case` block itself — only
# test-playwright-curl-crosscheck.sh covered playwright_curl_check_url —
# which is why GAP-14 shipped: the cross-check accepted bare-CDN URLs
# that the mapping refused. This test extracts the REAL functions from
# install.sh (verbatim — no copied logic) and drives playwright_curl_one
# directly with a stubbed curl, so a mapping PASS is proven by the
# function reaching the download stage (stubbed curl is invoked), never
# by a real 200 MB download.
#
# Stubs: curl logs the call and fails fast (rc=1); registry values match
# the CLI 0.1.24 bundle's browsers.json (chromium /
# chromium-headless-shell rev 1254, browserVersion 158.0.8127.18;
# ffmpeg rev 1013). playwright_core_dir returns empty, so the .links
# step is never reached (stubbed curl fails first).
#
# Run: bash tests/test-playwright-curl-mapping.sh
# Exit 0 = all cases pass; non-zero = at least one case failed.
set -u
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install_sh="$root/install.sh"
[[ -f "$install_sh" ]] || { printf 'FAIL: install.sh not found at %s\n' "$install_sh"; exit 1; }

# Extract the three helpers verbatim from install.sh and eval them.
for fn in playwright_curl_check_url playwright_curl_one playwright_curl_fallback; do
  helper="$(awk -v fn="$fn" '$0 ~ "^" fn "\\(\\) \\{"{f=1} f{print} f && /^}/{exit}' "$install_sh")"
  [[ -n "$helper" ]] || { printf 'FAIL: %s not found in install.sh\n' "$fn"; exit 1; }
  eval "$helper"
done

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
playwright_core_dir() { return 1; }

# Scratch dirs (the function mkdirs under state_dir before calling curl).
state_dir="$(mktemp -d)"
pw_cache_dir="$(mktemp -d)"
trap 'rm -rf "$state_dir" "$pw_cache_dir"' EXIT

# Stubbed curl: log the invocation, fail fast — reaching it proves the
# mapping matched AND the cross-check passed.
curl_calls=0
curl() {
  curl_calls=$((curl_calls + 1))
  printf 'stub-curl called for %s\n' "$*"
  return 1
}

pass=0
fail=0
# map <label> <want: fetch|unknown|refuse> <url>
#   fetch   = mapping matched, cross-check passed, stubbed curl invoked
#   unknown = mapping refused ("unknown artifact URL"), curl NOT invoked
#   refuse  = mapping matched but cross-check refused, curl NOT invoked
map() {
  local label="$1" want="$2" url="$3" out rc
  out="$(playwright_curl_one "$url" 2>&1)"; rc=$?
  case "$want" in
    fetch)
      # NOTE: curl_calls cannot be read here — the call above runs in a
      # command substitution subshell, so the stub's counter increment is
      # lost. Detect the stub invocation from its printed line instead.
      if printf '%s' "$out" | grep -q 'stub-curl called for'; then
        printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
      else
        printf 'FAIL: %s — expected fetch (stubbed curl invoked), got rc=%s out=%s\n' "$label" "$rc" "$out"; fail=$((fail + 1))
      fi
      ;;
    unknown)
      if ! printf '%s' "$out" | grep -q 'stub-curl called for' && printf '%s' "$out" | grep -q 'unknown artifact URL'; then
        printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
      else
        printf 'FAIL: %s — expected mapping refusal, got rc=%s out=%s\n' "$label" "$rc" "$out"; fail=$((fail + 1))
      fi
      ;;
    refuse)
      if ! printf '%s' "$out" | grep -q 'stub-curl called for' && printf '%s' "$out" | grep -q 'refusing to place'; then
        printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
      else
        printf 'FAIL: %s — expected cross-check refusal, got rc=%s out=%s\n' "$label" "$rc" "$out"; fail=$((fail + 1))
      fi
      ;;
  esac
}

V=158.0.8127.18

# --- D35 bare-CDN shapes (the GAP-14 failure: log lines 365/367) ---
map "D35 bare CDN CFT linux64 chrome fetches" fetch \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-linux64.zip"
map "D35 bare CDN CFT linux64 headless-shell fetches" fetch \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-headless-shell-linux64.zip"
map "D35 bare CDN CFT mac-arm64 chrome fetches" fetch \
  "https://cdn.playwright.dev/builds/cft/$V/mac-arm64/chrome-mac-arm64.zip"
map "D35 bare CDN CFT mac-x64 headless-shell fetches" fetch \
  "https://cdn.playwright.dev/builds/cft/$V/mac-x64/chrome-headless-shell-mac-x64.zip"
map "D35 bare CDN ffmpeg linux fetches" fetch \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/ffmpeg-linux.zip"
map "D35 bare CDN ffmpeg mac-arm64 fetches" fetch \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/ffmpeg-mac-arm64.zip"

# --- Segmented controls still match (generalisation must not break them) ---
map "segmented CDN CFT linux64 chrome still fetches" fetch \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/cft/$V/linux64/chrome-linux64.zip"
map "segmented CDN CFT mac-arm64 chrome still fetches" fetch \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/cft/$V/mac-arm64/chrome-mac-arm64.zip"
map "segmented CDN ffmpeg mac still fetches" fetch \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-mac.zip"
map "deep-nested CDN prefix fetches (generalisation class)" fetch \
  "https://cdn.playwright.dev/a/b/c/d/builds/cft/$V/linux64/chrome-linux64.zip"
map "GCS linux64 chrome still fetches" fetch \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/linux64/chrome-linux64.zip"

# --- D35 linux-arm64 completion arms (missing on every host shape) ---
map "D35 bare CDN CFT linux-arm64 chrome fetches" fetch \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-linux-arm64.zip"
map "D35 bare CDN CFT linux-arm64 headless-shell fetches" fetch \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-headless-shell-linux-arm64.zip"
map "D35 bare CDN ffmpeg linux-arm64 fetches" fetch \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/ffmpeg-linux-arm64.zip"
map "D35 segmented CDN CFT linux-arm64 chrome fetches" fetch \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/cft/$V/linux-arm64/chrome-linux-arm64.zip"
map "D35 GCS linux-arm64 chrome fetches" fetch \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/linux-arm64/chrome-linux-arm64.zip"
map "D35 GCS linux-arm64 headless-shell fetches" fetch \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/linux-arm64/chrome-headless-shell-linux-arm64.zip"

# --- D35 prss.microsoft.com ffmpeg arms (mirror #2, ffmpeg only) ---
map "D35 prss ffmpeg linux fetches" fetch \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-linux.zip"
map "D35 prss ffmpeg linux-arm64 fetches" fetch \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-linux-arm64.zip"
map "D35 prss ffmpeg mac fetches" fetch \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-mac.zip"
map "D35 prss ffmpeg mac-arm64 fetches" fetch \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1013/ffmpeg-mac-arm64.zip"

# --- Fail-closed: unknown shapes still refuse at the mapping ---
map "evil-host suffix refuses" unknown \
  "https://cdn.playwright.dev.evil.com/builds/cft/$V/linux64/chrome-linux64.zip"
map "wrong host refuses" unknown \
  "https://example.com/builds/cft/$V/linux64/chrome-linux64.zip"
map "Windows zip refuses (install.sh fails fast on Windows)" unknown \
  "https://cdn.playwright.dev/builds/cft/$V/win64/chrome-win64.zip"
map "wrong platform filename refuses" unknown \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-linux32.zip"
map "non-CFT builds/chromium refuses" unknown \
  "https://cdn.playwright.dev/builds/chromium/1254/chromium-linux.zip"
map "prss CFT refuses (prss is ffmpeg-only per the bundle)" unknown \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/cft/$V/linux64/chrome-linux64.zip"

# --- Fail-closed: matched shapes with wrong version/revision refuse ---
map "bare CFT wrong version refuses (not fetched)" refuse \
  "https://cdn.playwright.dev/builds/cft/1.2.3.4/linux64/chrome-linux64.zip"
map "bare ffmpeg wrong revision refuses (not fetched)" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/9999/ffmpeg-linux.zip"
map "prss ffmpeg wrong revision refuses (not fetched)" refuse \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/9999/ffmpeg-linux.zip"
map "segmented CFT wrong version refuses (not fetched)" refuse \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/cft/1.2.3.4/linux64/chrome-linux64.zip"

# --- Documented residual, CLOSED by the cross-check (C §2.2 predicted a
# match here, testing the mapping case block in isolation). End-to-end
# through playwright_curl_one the URL is refused: the mapping arm does
# match `evilbuilds`, but playwright_curl_check_url's sed needs a literal
# `/builds/` to extract the kind, `evilbuilds` has none, so _url_kind
# becomes the whole URL and the check refuses with "unknown CDN builds
# kind". Verified live in this test (both versions refuse, never fetch).
map "RESIDUAL segment ending in builds refuses at cross-check" refuse \
  "https://cdn.playwright.dev/evilbuilds/cft/$V/linux64/chrome-linux64.zip"
map "RESIDUAL segment ending in builds, wrong version refuses" refuse \
  "https://cdn.playwright.dev/evilbuilds/cft/1.2.3.4/linux64/chrome-linux64.zip"

# --- D35 fallback derivation: linux-arm64 chrome URL must derive the
# headless shell (previously the detection case listed only
# linux64/mac-arm64/mac-x64, so an ARM64 run silently skipped it) ---
fallback_check() {
  local label="$1" chrome_url="$2" want_hs="$3" out
  printf 'Download failed for chrome-for-testing. URL: %s\n' "$chrome_url" > "$state_dir/install.log"
  out="$(playwright_curl_fallback 2>&1)"
  if printf '%s' "$out" | grep -q "deriving it from the same CDN version directory: $want_hs"; then
    printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
  else
    printf 'FAIL: %s — expected derivation of %s, got: %s\n' "$label" "$want_hs" "$out"; fail=$((fail + 1))
  fi
}
fallback_check "D35 fallback derives headless-shell on linux-arm64" \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-linux-arm64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-headless-shell-linux-arm64.zip"
fallback_check "fallback still derives headless-shell on linux64" \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-linux64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-headless-shell-linux64.zip"

printf 'mapping test: %s PASS, %s FAIL\n' "$pass" "$fail"
[[ "$fail" == 0 ]]
