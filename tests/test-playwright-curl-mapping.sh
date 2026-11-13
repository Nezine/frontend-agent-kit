#!/bin/bash
# Unit test for install.sh playwright_curl_one mapping + playwright_curl_fallback
# derivation (D35 / GAP-14, 2026-11-13).
#
# No test existed for the mapping `case` block itself — only
# test-playwright-curl-crosscheck.sh covered playwright_curl_check_url —
# which is why GAP-14 shipped: the cross-check accepted bare-CDN URLs
# that the mapping refused. This test extracts the REAL functions from
# install.sh (verbatim — no copied logic) and drives playwright_curl_one
# directly with a stubbed curl, so a fetch PASS is proven by real
# placement of a fixture zip (stubbed curl builds the zip, the function
# extracts it and gates on the expected executable), never by a real
# 200 MB download.
#
# Stubs: curl logs the call and builds a fixture zip containing exactly
# the expected executable for that URL shape (expected_for_url below —
# derived at test time from the pinned bundle's EXECUTABLE_PATHS +
# DOWNLOAD_PATHS, see the F2-RT2/F3-RT1 block; never hand-copied in this file), then succeeds;
# registry values match the CLI 0.1.24 bundle's browsers.json (chromium /
# chromium-headless-shell rev 1254, browserVersion 158.0.8127.18; ffmpeg
# rev 1013). playwright_core_dir returns empty, so the .links step only
# prints its warning. A fetch PASS therefore proves the real placement
# path: mapping matched, cross-check passed, extraction ran, the expected
# executable was present and executable, and INSTALLATION_COMPLETE was
# written — a typo'd `name`/`exe_rel` in install.sh fails loudly here
# (F-RT2 fix pass, 2026-11-13: the old fail-fast stub never reached
# extraction, so the test passed with a bogus `exe_rel`).
#
# Run: bash tests/test-playwright-curl-mapping.sh
# Exit 0 = all cases pass; non-zero = at least one case failed.
set -u
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install_sh="$root/install.sh"
[[ -f "$install_sh" ]] || { printf 'FAIL: install.sh not found at %s\n' "$install_sh"; exit 1; }

# Extract the four helpers verbatim from install.sh and eval them.
for fn in playwright_curl_validate_url playwright_curl_check_url playwright_curl_one playwright_curl_fallback; do
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

# --- F2-RT2 fix pass 2 (2026-11-13) + F3-RT1 fix pass 3: the expected
# table AND the filename→(browser, platform) dispatch are DERIVED from
# the bundle at test time, not hand-copied in this file. The fix pass 1
# table was hand-copied, so mutating install.sh's `exe_rel` AND the
# table together passed 53/53 — the test judged the code against
# itself. Fix pass 2 moved the VALUES into the fixture but left the
# dispatch hand-written in expected_for_url, so swapping two dispatch
# keys AND the code's `exe_rel` for those arches still passed 70/70
# (F3-RT1, red team round 2) — the bundle judged the values but never
# the keys. Now the source of truth is
# tests/fixtures/playwright-core-executable-paths.txt, the verbatim
# EXECUTABLE_PATHS (coreBundle.js:34565–34614) + DOWNLOAD_PATHS
# (coreBundle.js:34615–34861) blocks from the pinned
# playwright-core@1.66.0-alpha-1794252756000 bundle, guarded by a
# pinned sha256: EXPECTED_FIXTURE_SHA256 below. Any edit to the fixture
# without updating the hash fails this test LOUDLY before any case runs,
# so a joint mutation of code + fixture is caught by the checksum, a
# code-only mutation is caught because the stub builds the fixture zip
# from the bundle-derived exe_rel while the code gates on its own
# (wrong) one, and a fixture-only mutation is caught by the checksum
# (and would also fail the placement, since the stub and the code would
# then disagree). The python3 parser below extracts exactly 12 exe rows
# (chromium / chromium-headless-shell / ffmpeg × linux-x64, linux-arm64,
# mac-x64, mac-arm64) and exactly 12 dispatch rows (filename → browser,
# platform) from DOWNLOAD_PATHS, and refuses to continue on any other
# count. DOWNLOAD_PATHS is keyed by distro (ubuntu22.04-x64, mac14-arm64,
# win64, ...), so the parser maps each distro key to a generic platform
# MECHANICALLY — arch is arm64 iff the key ends in -arm64, else x64;
# family is mac iff the key starts with "mac", win iff it starts with
# "win", linux iff it starts with "ubuntu"/"debian", and any other family
# fails loudly — and asserts the dispatch keys cover exactly the 12
# EXECUTABLE_PATHS rows, with no filename mapping to two keys. There is
# no hand-written filename→key table left in this file: the dispatch
# comes from the bundle, the exe_rel comes from the bundle, never from
# this file.
# Tradeoff, stated plainly: the fixture is PINNED, not fetched — the
# test must work in CI with no network, so a CLI re-pin needs a manual
# re-derivation (procedure in the fixture header) plus a hash update.
# A coordinated three-way edit (code + fixture + the hash in this file)
# would still pass; that requires editing the test's own tripwire, not
# just the code and its expectation, and is the documented residual.
fixture="$root/tests/fixtures/playwright-core-executable-paths.txt"
EXPECTED_FIXTURE_SHA256="40ef24419276e3cc9b87e96a06088eab8f5f44ac9b6a1da98ed6c3612d5210f5"
[[ -f "$fixture" ]] || { printf 'FAIL: bundle fixture not found at %s\n' "$fixture"; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then
  _fixture_sha="$(sha256sum "$fixture" | awk '{print $1}')"
else
  _fixture_sha="$(FIXTURE="$fixture" python3 -c 'import hashlib, os; print(hashlib.sha256(open(os.environ["FIXTURE"], "rb").read()).hexdigest())')"
fi
if [[ "$_fixture_sha" != "$EXPECTED_FIXTURE_SHA256" ]]; then
  printf 'FAIL: bundle fixture %s sha256 mismatch (got %s, expected %s) — re-derive it per its header and update EXPECTED_FIXTURE_SHA256; refusing to run on a stale/tampered fixture.\n' "$fixture" "$_fixture_sha" "$EXPECTED_FIXTURE_SHA256"
  exit 1
fi
derived_table="$(mktemp)"
derived_dispatch="$(mktemp)"
FIXTURE="$fixture" DERIVED="$derived_table" DISPATCH="$derived_dispatch" python3 -c '
import os, re, sys
text = open(os.environ["FIXTURE"]).read()
rows = []
for name in ("chromium", "chromium-headless-shell", "ffmpeg"):
    m = re.search(r"\"%s\":\s*\{(.*?)\n      \}" % re.escape(name), text, re.S)
    if not m:
        sys.exit("no EXECUTABLE_PATHS block for " + name)
    for plat, arr in re.findall(r"\"(linux-x64|linux-arm64|mac-x64|mac-arm64)\":\s*\[([^\]]*)\]", m.group(1)):
        parts = re.findall(r"\"([^\"]+)\"", arr)
        if not parts:
            sys.exit("empty exe path for %s %s" % (name, plat))
        rows.append("%s|%s|%s" % (name, plat, "/".join(parts)))
if len(rows) != 12:
    sys.exit("expected 12 derived rows, got %d" % len(rows))
# F3-RT1 fix pass 3: the filename dispatch comes from DOWNLOAD_PATHS
# too, so the bundle judges the keys as well as the values. The block
# is keyed by distro (ubuntu22.04-x64, mac14-arm64, win64, ...); each
# key maps to a generic platform mechanically (see the header comment):
# arm64 iff the key ends in -arm64, else x64; mac/win/linux by prefix.
# Only the same 4 platforms as above are kept; a filename mapping to
# two different keys, a dispatch count other than 12, or a key set
# other than exactly the EXECUTABLE_PATHS rows all fail loudly.
dl = re.search(r"DOWNLOAD_PATHS = \{(.*?)\n    \};", text, re.S)
if not dl:
    sys.exit("no DOWNLOAD_PATHS block in fixture")
platforms = ("linux-x64", "linux-arm64", "mac-x64", "mac-arm64")
dispatch = {}
for name in ("chromium", "chromium-headless-shell", "ffmpeg"):
    m = re.search(r"\"%s\":\s*\{(.*?)\n      \}," % re.escape(name), dl.group(1), re.S)
    if not m:
        sys.exit("no DOWNLOAD_PATHS block for " + name)
    for distro, cft, plain in re.findall(r"\"([^\"]+)\":\s*(?:cftUrl\(\"([^\"]+)\"\)|\"([^\"]+)\")", m.group(1)):
        path = cft or plain
        fname = path.rsplit("/", 1)[-1]
        arch = "arm64" if distro.endswith("arm64") else "x64"
        if distro.startswith("mac"):
            fam = "mac"
        elif distro.startswith("win"):
            fam = "win"
        elif distro.startswith("ubuntu") or distro.startswith("debian"):
            fam = "linux"
        else:
            sys.exit("unknown OS family in DOWNLOAD_PATHS key " + distro)
        plat = fam + "-" + arch
        if plat not in platforms:
            continue
        key = "%s|%s" % (name, plat)
        if fname in dispatch and dispatch[fname] != key:
            sys.exit("DOWNLOAD_PATHS filename %s maps to both %s and %s" % (fname, dispatch[fname], key))
        dispatch[fname] = key
if len(dispatch) != 12:
    sys.exit("expected 12 derived dispatch rows, got %d" % len(dispatch))
if sorted(dispatch.values()) != sorted("%s|%s" % (r.split("|")[0], r.split("|")[1]) for r in rows):
    sys.exit("dispatch keys do not cover exactly the EXECUTABLE_PATHS rows")
open(os.environ["DERIVED"], "w").write("\n".join(rows) + "\n")
open(os.environ["DISPATCH"], "w").write("\n".join("%s|%s" % (f, k) for f, k in sorted(dispatch.items())) + "\n")
' || { printf 'FAIL: could not derive the expected table from the bundle fixture %s\n' "$fixture"; exit 1; }

# expected_for_url <url> — prints "<name>|<exe_rel>" for a fetch URL.
# BOTH halves come from the bundle fixture: the filename→(browser,
# platform) dispatch is derived from DOWNLOAD_PATHS (distro keys mapped
# mechanically to the generic platforms; see the F3-RT1 block above),
# and the exe_rel comes from EXECUTABLE_PATHS. There is no hand-written
# filename→key table left in this file to swap — the F3-RT1 mutant
# (dispatch keys + code exe_rel swapped together) is not expressible
# here; the nearest expressible mutant edits the fixture's
# DOWNLOAD_PATHS rows, which the sha256 guard catches unless the hash
# is updated too (the documented three-way residual).
expected_for_url() {
  local _fname _key _row _exe
  _fname="${1##*/}"
  _key="$(awk -F'|' -v f="$_fname" '$1 == f { print $2"|"$3; exit }' "$derived_dispatch")"
  [[ -n "$_key" ]] || { printf ''; return 0; }
  _row="$(grep -F "$_key|" "$derived_table" || true)"
  [[ -n "$_row" ]] || { printf ''; return 0; }
  _exe="${_row##*|}"
  printf '%s|%s' "${_key%%|*}" "$_exe"
}

# Scratch dirs (the function mkdirs under state_dir before calling curl).
state_dir="$(mktemp -d)"
pw_cache_dir="$(mktemp -d)"
trap 'rm -rf "$state_dir" "$pw_cache_dir" "$derived_table" "$derived_dispatch"' EXIT

# Stubbed curl: log the invocation, then build a fixture zip containing
# exactly the expected executable for the fetched URL shape and succeed
# (F-RT2 fix pass — the old fail-fast stub returned 1 before extraction,
# so a typo'd `exe_rel` in install.sh passed silently). The zip is built
# with python3 (already required by playwright_curl_one's extraction);
# the entry stores mode 0755, as the real archives do.
curl_calls=0
curl() {
  local _o="" _u="" _prev="" _a _exp _exe
  curl_calls=$((curl_calls + 1))
  printf 'stub-curl called for %s\n' "$*"
  for _a in "$@"; do
    if [[ "$_prev" == "-o" ]]; then _o="$_a"; fi
    _prev="$_a"
    _u="$_a"
  done
  [[ -n "$_o" ]] || return 1
  _exp="$(expected_for_url "$_u")"
  [[ -n "$_exp" ]] || { printf 'stub-curl: no fixture mapping for %s\n' "$_u"; return 1; }
  _exe="${_exp#*|}"
  FIXTURE_EXE="$_exe" FIXTURE_ZIP="$_o" python3 -c '
import os, zipfile
z = zipfile.ZipFile(os.environ["FIXTURE_ZIP"], "w")
info = zipfile.ZipInfo(os.environ["FIXTURE_EXE"])
info.external_attr = 0o755 << 16
z.writestr(info, "#!/bin/sh\nexit 0\n")
z.close()
' || return 1
  return 0
}

pass=0
fail=0
# map <label> <want: fetch|unknown|refuse> <url>
#   fetch   = mapping matched, cross-check passed, stubbed curl invoked
#   unknown = mapping refused ("unknown artifact URL"), curl NOT invoked
#   refuse  = mapping matched but cross-check refused, curl NOT invoked
map() {
  local label="$1" want="$2" url="$3" out rc _exp _exp_name _exp_exe _exp_rev _dest
  out="$(playwright_curl_one "$url" 2>&1)"; rc=$?
  case "$want" in
    fetch)
      # NOTE: curl_calls cannot be read here — the call above runs in a
      # command substitution subshell, so the stub's counter increment is
      # lost. Detect the stub invocation from its printed line instead.
      # F-RT2: a fetch PASS also asserts the real placement — the
      # expected name/exe_rel (expected_for_url) must be what
      # playwright_curl_one placed, with INSTALLATION_COMPLETE written.
      _exp="$(expected_for_url "$url")"
      _exp_name="${_exp%%|*}"
      _exp_exe="${_exp#*|}"
      case "$_exp_name" in
        chromium|chromium-headless-shell) _exp_rev=1254 ;;
        ffmpeg) _exp_rev=1013 ;;
        *) printf 'FAIL: %s — no expected name/exe_rel for %s\n' "$label" "$url"; fail=$((fail + 1)); return ;;
      esac
      _dest="$pw_cache_dir/${_exp_name//-/_}-$_exp_rev"
      if printf '%s' "$out" | grep -q 'stub-curl called for' \
        && [[ "$rc" == 0 ]] \
        && [[ -f "$_dest/INSTALLATION_COMPLETE" ]] \
        && [[ -x "$_dest/$_exp_exe" ]]; then
        printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
      else
        printf 'FAIL: %s — expected fetch + placement of %s at %s (rc=%s out=%s)\n' "$label" "$_exp_exe" "$_dest" "$rc" "$out"; fail=$((fail + 1))
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

# --- F-RT1 fix pass: traversal / dot-segment / encoded shapes must
# refuse at the validator, before mapping + check (and before curl).
# The live ffmpeg traversal URL (red team) is the first case: it
# previously fetched the 1005 artifact and placed it as 1013. ---
map "F-RT1 traversal ffmpeg 1013 -> 1005 refuses (live URL)" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/../../ffmpeg/1005/ffmpeg-linux.zip"
map "F-RT1 traversal ffmpeg 1013 -> 1005, %2F-encoded refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/..%2F..%2Fffmpeg/1005/ffmpeg-linux.zip"
map "F-RT1 traversal ffmpeg 1013 -> 9999 refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/../../ffmpeg/9999/ffmpeg-linux.zip"
map "F-RT1 traversal CFT version-then-wrong refuses" refuse \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/../../cft/1.2.3.4/linux64/chrome-linux64.zip"
map "F-RT1 traversal segmented ffmpeg refuses" refuse \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1013/../../ffmpeg/1005/ffmpeg-linux.zip"
map "F-RT1 traversal GCS chrome refuses" refuse \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/linux64/../../140.0.7339.186/linux64/chrome-linux64.zip"
map "F-RT1 traversal prss ffmpeg refuses" refuse \
  "https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1013/../../ffmpeg/9999/ffmpeg-linux.zip"
map "F-RT1 double slash in path refuses" refuse \
  "https://cdn.playwright.dev//builds/cft/$V/linux64/chrome-linux64.zip"
map "F-RT1 dot segment in path refuses" refuse \
  "https://cdn.playwright.dev/./builds/cft/$V/linux64/chrome-linux64.zip"
map "F-RT1 dotdot prefix refuses" refuse \
  "https://cdn.playwright.dev/../builds/cft/$V/linux64/chrome-linux64.zip"
map "F-RT1 encoded slash in builds segment refuses" refuse \
  "https://cdn.playwright.dev/builds%2Fcft/$V/linux64/chrome-linux64.zip"
map "F-RT1 encoded dotdot %2e refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/%2e%2e/%2e%2e/ffmpeg/1005/ffmpeg-linux.zip"
# --- W-RT3 fix pass: more than one /builds/ segment refuses ---
map "W-RT3 double /builds/ refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/builds/cft/$V/linux64/chrome-linux64.zip"
map "W-RT3 evilbuilds/builds refuses" refuse \
  "https://cdn.playwright.dev/evilbuilds/builds/ffmpeg/1013/ffmpeg-linux.zip"

# --- F2-RT1 fix pass 2: semicolon-param traversal must refuse at the
# validator (segment-shape allowlist). The red team's exact live URLs:
# GCS strips `;`-params server-side, so `..;` fetched the WRONG
# revision (140.x placed as chromium-1254) on the fix-pass-1 code.
# Also the `.;` / encoded-`;` / double-encoding / overlong-UTF-8 /
# unicode-dot / triple-dot / `%00` family (W2-RT3): every one reaches
# curl only if the validator lets it through, and the allowlist refuses
# them all here — no residual is left to server behaviour. ---
map "F2-RT1 semicolon CDN CFT chrome landing refuses (live URL)" refuse \
  "https://cdn.playwright.dev/builds/cft/$V/..;/140.0.7339.186/linux64/chrome-linux64.zip"
map "F2-RT1 semicolon GCS chrome landing refuses (live URL)" refuse \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/..;/140.0.7339.186/linux64/chrome-linux64.zip"
map "F2-RT1 semicolon GCS headless-shell landing refuses (live URL)" refuse \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/..;/140.0.7339.186/linux64/chrome-headless-shell-linux64.zip"
map "F2-RT1 semicolon CDN CFT headless-shell landing refuses (live URL)" refuse \
  "https://cdn.playwright.dev/builds/cft/$V/..;/140.0.7339.186/linux64/chrome-headless-shell-linux64.zip"
map "F2-RT1 semicolon GCS mac-arm64 chrome landing refuses (live URL)" refuse \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/..;/140.0.7339.186/mac-arm64/chrome-mac-arm64.zip"
map "F2-RT1 semicolon-param ..;x=1 refuses" refuse \
  "https://cdn.playwright.dev/builds/cft/$V/..;x=1/140.0.7339.186/linux64/chrome-linux64.zip"
map "F2-RT1 semicolon in version segment refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013;/../ffmpeg/1005/ffmpeg-linux.zip"
map "W2-RT3 dot-semicolon .; refuses" refuse \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/.;/140.0.7339.186/linux64/chrome-linux64.zip"
map "W2-RT3 encoded semicolon ..%3b refuses" refuse \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/..%3b/140.0.7339.186/linux64/chrome-linux64.zip"
map "W2-RT3 double-encoded dotdot %252e refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/%252e%252e/%252e%252e/ffmpeg/1005/ffmpeg-linux.zip"
map "W2-RT3 overlong UTF-8 %c0%ae refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/%c0%ae%c0%ae/%c0%ae%c0%ae/ffmpeg/1005/ffmpeg-linux.zip"
map "W2-RT3 unicode dot %e2%80%a4 refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/%e2%80%a4%e2%80%a4/ffmpeg/1005/ffmpeg-linux.zip"
map "W2-RT3 triple-dot segment refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/.../ffmpeg/1005/ffmpeg-linux.zip"
map "W2-RT3 null byte %00 segment refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013/%00/ffmpeg-linux.zip"
map "W2-RT3 backslash traversal refuses" refuse \
  "https://cdn.playwright.dev/builds/ffmpeg/1013\\..\\..\\ffmpeg\\1005/ffmpeg-linux.zip"

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

# --- W-RT2 fix pass: per-arch derivation guard. A log with an arm64
# chrome URL and a linux64 headless-shell URL must still derive the
# arm64 headless shell; a same-arch HS URL in the log must suppress it.
# fallback_multi <label> <want: derive|nodrive> <want_hs> <log-url-1> [log-url-2 ...]
fallback_multi() {
  local label="$1" want="$2" want_hs="$3" out u
  shift 3
  : > "$state_dir/install.log"
  for u in "$@"; do
    printf 'Download failed for chrome-for-testing. URL: %s\n' "$u" >> "$state_dir/install.log"
  done
  out="$(playwright_curl_fallback 2>&1)"
  case "$want" in
    derive)
      if printf '%s' "$out" | grep -q "deriving it from the same CDN version directory: $want_hs"; then
        printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
      else
        printf 'FAIL: %s — expected derivation of %s, got: %s\n' "$label" "$want_hs" "$out"; fail=$((fail + 1))
      fi ;;
    nodrive)
      if printf '%s' "$out" | grep -q 'deriving it from the same CDN version directory'; then
        printf 'FAIL: %s — expected NO derivation, got: %s\n' "$label" "$out"; fail=$((fail + 1))
      else
        printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
      fi ;;
  esac
}
fallback_multi "W-RT2 arm64 chrome + linux64 HS still derives arm64 HS" derive \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-headless-shell-linux-arm64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-linux-arm64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-headless-shell-linux64.zip"
fallback_multi "W-RT2 arm64 chrome + arm64 HS does not derive" nodrive \
  "" \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-linux-arm64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-headless-shell-linux-arm64.zip"
fallback_multi "W-RT2 linux64 chrome + arm64 HS still derives linux64 HS" derive \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-headless-shell-linux64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-linux64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-headless-shell-linux-arm64.zip"
fallback_multi "W-RT2 linux64 chrome + linux64 HS does not derive" nodrive \
  "" \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-linux64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-headless-shell-linux64.zip"

# --- F2-RT1 fix pass 2: the fallback path must refuse a poisoned log
# line, including the DERIVED headless-shell URL — derivation is string
# substitution, so it inherits the `..;` segment, and the derived URL
# is only safe because playwright_curl_one validates it too. ---
fallback_refuse() {
  local label="$1" log_url="$2" out rc
  printf 'Download failed for chrome-for-testing. URL: %s\n' "$log_url" > "$state_dir/install.log"
  out="$(playwright_curl_fallback 2>&1)"; rc=$?
  if [[ "$rc" != 0 ]] && ! printf '%s' "$out" | grep -q 'stub-curl called for' && printf '%s' "$out" | grep -q 'refusing to place'; then
    printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
  else
    printf 'FAIL: %s — expected fallback refusal (rc=1, no fetch), got rc=%s out=%s\n' "$label" "$rc" "$out"; fail=$((fail + 1))
  fi
}
fallback_refuse "F2-RT1 fallback refuses semicolon log line (derived HS also refused)" \
  "https://storage.googleapis.com/chrome-for-testing-public/$V/..;/140.0.7339.186/linux64/chrome-linux64.zip"

# --- W2-RT2 fix pass 2: a log with TWO chrome URLs (two arches) must
# derive BOTH headless shells, not just the last-sorted arch's. ---
fallback_derive_both() {
  local label="$1" hs1="$2" hs2="$3" out u
  shift 3
  : > "$state_dir/install.log"
  for u in "$@"; do
    printf 'Download failed for chrome-for-testing. URL: %s\n' "$u" >> "$state_dir/install.log"
  done
  out="$(playwright_curl_fallback 2>&1)"
  if printf '%s' "$out" | grep -q "deriving it from the same CDN version directory: $hs1" \
    && printf '%s' "$out" | grep -q "deriving it from the same CDN version directory: $hs2"; then
    printf 'PASS: %s\n' "$label"; pass=$((pass + 1))
  else
    printf 'FAIL: %s — expected derivation of both %s and %s, got: %s\n' "$label" "$hs1" "$hs2" "$out"; fail=$((fail + 1))
  fi
}
fallback_derive_both "W2-RT2 two chrome URLs derive both headless shells" \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-headless-shell-linux64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-headless-shell-linux-arm64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux64/chrome-linux64.zip" \
  "https://cdn.playwright.dev/builds/cft/$V/linux-arm64/chrome-linux-arm64.zip"

printf 'mapping test: %s PASS, %s FAIL\n' "$pass" "$fail"
[[ "$fail" == 0 ]]
