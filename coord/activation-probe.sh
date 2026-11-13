#!/bin/sh
# activation-probe.sh — D78 enforcement leg (deterministic, no model call).
#
# Reads the coordinator's last activity from the REMOTE (server-observed):
#   * last push time  = committer date of the tip commit on origin/<branch>
#   * pending work    = coord/pending-work.txt exists and is non-empty
#                       at the tip of origin/<branch>
#   * progress signal = the last HB (heartbeat) lines in --heartbeat-file
#                       at the tip of origin/<branch> (D78 condition, round 3)
#
# STALE (takeover condition, unchanged): (a) pending work exists, and
# (b) no coordinator push for longer than --stale-mins (default 20).
# An idle coordinator with an empty queue is idle, not stale: no takeover.
#
# NO-PROGRESS (escalation condition, NEW — D78 condition, round 3):
# Heartbeat line format (see coord/activation-research.md §10.1):
#   HB <UTC ISO8601> stage=<s> next=<s> progress=<hash|none>
#   blocked=<reason|none> pending=<n>
# A cycle is the interval between two consecutive HB lines (nominally
# 15 min); a cycle is no-progress when the newer line's (progress,
# blocked) is identical to the older's. In order:
#   1. progress hash changed, or blocked reason appeared/changed/cleared
#      -> OK, the run is moving.
#   2. blocked != "none" and stable: BLOCKED-STABLE, legitimate, no
#      escalation now — BUT if the same blocked reason persists >=60 min
#      from its first appearance -> NO-PROGRESS (BLOCKED-STALE-60MIN).
#   3. blocked = "none" and (progress, blocked) identical across TWO
#      consecutive no-progress cycles (three HB lines, pairwise identical,
#      spanning >=30 min) -> NO-PROGRESS, escalate to the Deputy.
#   4. One no-progress cycle only -> watching, NOT escalating (OK).
#
# Exit codes: 0 = OK | 2 = STALE, takeover condition met |
#             3 = ERROR (cannot read state — loud, never OK) |
#             4 = NO-PROGRESS, escalate to the Deputy.
# Every check appends one line to --log (default: no log file) so a
# missing probe log is itself visible the next morning.
#
# Honest limits (see coord/activation-research.md, §10.5):
#   * Commit time is author-controlled and can be forged/backdated; it is
#     a PROXY for server-observed push time, not the push event itself.
#   * The progress hash and HB timestamps are coordinator-reported
#     content: a coordinator can fake progress with empty commits or
#     rotate blocked reasons. The probe catches silence, not slop; the
#     Deputy judges quality by inspecting the reported hash/reason.
#   * The probe DETECTS; it does not wake anyone by itself. The wake path
#     is a separate mechanism (cron dispatch / event hook).
#
# Usage:
#   activation-probe.sh --clone <path> --branch <branch>
#       [--stale-mins 20] [--pending-path coord/pending-work.txt]
#       [--heartbeat-file coord/muse.md] [--log <file>]
# Cost: $0.00 (git + date only).

set -u

CLONE=""
BRANCH=""
STALE_MINS=20
PENDING_PATH="coord/pending-work.txt"
HB_FILE="coord/muse.md"
LOG=""

usage() {
  echo "usage: $0 --clone <path> --branch <branch> [--stale-mins N] [--pending-path <path>] [--heartbeat-file <path>] [--log <file>]" >&2
  exit 3
}

while [ $# -gt 0 ]; do
  case "$1" in
    --clone) CLONE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --stale-mins) STALE_MINS="$2"; shift 2 ;;
    --pending-path) PENDING_PATH="$2"; shift 2 ;;
    --heartbeat-file) HB_FILE="$2"; shift 2 ;;
    --log) LOG="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[ -n "$CLONE" ] && [ -n "$BRANCH" ] || usage
case "$STALE_MINS" in ''|*[!0-9]*) echo "ERROR: --stale-mins must be a number" >&2; exit 3 ;; esac

# Portable ISO8601-UTC -> epoch seconds (GNU date, BSD fallback).
to_epoch() {
  date -u -d "$1" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s 2>/dev/null || echo ""
}

# Field extractor for one HB line: $1 = line, $2 = key.
hb_field() {
  printf '%s' "$1" | awk -v k="$2=" '{for(i=1;i<=NF;i++) if(index($i,k)==1) {print substr($i,length(k)+1); exit}}'
}

NOW=$(date +%s)

# 1. Fetch the remote-tracking ref (server-observed state).
if ! git -C "$CLONE" fetch --quiet origin "$BRANCH" 2>/dev/null; then
  echo "ERROR: fetch of origin/$BRANCH failed in $CLONE" >&2
  exit 3
fi

# 2. Last push time = committer date of the tip commit.
LAST=$(git -C "$CLONE" log -1 --format=%ct "origin/$BRANCH" 2>/dev/null)
if [ -z "$LAST" ]; then
  echo "ERROR: no commit on origin/$BRANCH" >&2
  exit 3
fi

# 3. Pending work = marker file exists and is non-empty at the remote tip.
PENDING=0
if git -C "$CLONE" cat-file -e "origin/$BRANCH:$PENDING_PATH" 2>/dev/null; then
  CONTENT=$(git -C "$CLONE" show "origin/$BRANCH:$PENDING_PATH" 2>/dev/null | tr -d '[:space:]')
  [ -n "$CONTENT" ] && PENDING=1
fi

AGE=$((NOW - LAST))
THRESHOLD=$((STALE_MINS * 60))
LAST_ISO=$(date -u -d "@$LAST" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$LAST" +%Y-%m-%dT%H:%M:%SZ)

# 4. STALE check first: a silent coordinator trips STALE before the
#    progress check matters.
if [ "$AGE" -gt "$THRESHOLD" ] && [ "$PENDING" -eq 1 ]; then
  echo "STALE: coordinator silent ${AGE}s (last push $LAST_ISO, threshold ${THRESHOLD}s) with pending work present — TAKEOVER condition met (branch origin/$BRANCH)"
  [ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "STALE" >> "$LOG"
  exit 2
fi

# 5. Progress check: read HB lines from the heartbeat file at the tip.
HB_TMP=$(mktemp)
trap 'rm -f "$HB_TMP"' EXIT
if ! git -C "$CLONE" show "origin/$BRANCH:$HB_FILE" 2>/dev/null | grep '^HB ' > "$HB_TMP"; then
  echo "OK: last push $LAST_ISO (${AGE}s ago, threshold ${THRESHOLD}s), pending=$PENDING, no HB lines in $HB_FILE — PROGRESS-UNKNOWN, STALE check only (branch origin/$BRANCH)"
  [ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s,progress=%s,blocked=%s,hb_span_s=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "OK-PROGRESS-UNKNOWN" "unknown" "unknown" "" >> "$LOG"
  exit 0
fi

N_HB=$(wc -l < "$HB_TMP" | tr -d ' ')
if [ "$N_HB" -lt 2 ]; then
  echo "OK: last push $LAST_ISO (${AGE}s ago), pending=$PENDING, only $N_HB HB line(s) — need 2+ to judge progress, watching (branch origin/$BRANCH)"
  [ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s,progress=%s,blocked=%s,hb_span_s=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "OK-PROGRESS-UNKNOWN" "unknown" "unknown" "" >> "$LOG"
  exit 0
fi

LAST3=$(tail -3 "$HB_TMP")
NEWEST=$(printf '%s\n' "$LAST3" | tail -1)
PREV=$(printf '%s\n' "$LAST3" | tail -2 | head -1)
PROG_NEW=$(hb_field "$NEWEST" progress)
BLOCK_NEW=$(hb_field "$NEWEST" blocked)
PROG_PREV=$(hb_field "$PREV" progress)
BLOCK_PREV=$(hb_field "$PREV" blocked)
TS_NEW=$(to_epoch "$(printf '%s' "$NEWEST" | awk '{print $2}')")
TS_PREV=$(to_epoch "$(printf '%s' "$PREV" | awk '{print $2}')")

if [ -z "$TS_NEW" ] || [ -z "$TS_PREV" ]; then
  echo "ERROR: unparseable HB timestamp in $HB_FILE (branch origin/$BRANCH)" >&2
  exit 3
fi
# Sanity: a heartbeat from the future (beyond 5 min clock skew) is forged.
if [ "$TS_NEW" -gt $((NOW + 300)) ]; then
  echo "ERROR: newest HB line is timestamped in the future ($TS_NEW > now + 300s) — forged or clock skew (branch origin/$BRANCH)" >&2
  exit 3
fi

SPAN=$((TS_NEW - TS_PREV))

# Rule 1: progress hash changed, or blocked reason appeared/changed/cleared.
if [ "$PROG_NEW" != "$PROG_PREV" ] || [ "$BLOCK_NEW" != "$BLOCK_PREV" ]; then
  echo "OK: progress (progress $PROG_PREV -> $PROG_NEW, blocked $BLOCK_PREV -> $BLOCK_NEW), last push $LAST_ISO (${AGE}s ago), pending=$PENDING (branch origin/$BRANCH)"
  [ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s,progress=%s,blocked=%s,hb_span_s=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "OK-PROGRESS" "$PROG_NEW" "$BLOCK_NEW" "$SPAN" >> "$LOG"
  exit 0
fi

# Identical pair: no progress this cycle. Blocked or silent?
if [ "$BLOCK_NEW" != "none" ] && [ -n "$BLOCK_NEW" ]; then
  # Rule 2: blocked-and-reported. Find first appearance of this reason.
  FIRST_TS=""
  while IFS= read -r line; do
    if [ "$(hb_field "$line" blocked)" = "$BLOCK_NEW" ]; then
      FIRST_TS=$(to_epoch "$(printf '%s' "$line" | awk '{print $2}')")
      break
    fi
  done < "$HB_TMP"
  BLOCK_AGE=$((NOW - FIRST_TS))
  if [ "$BLOCK_AGE" -ge 3600 ]; then
    echo "NO-PROGRESS: blocked reason '$BLOCK_NEW' stable for ${BLOCK_AGE}s (>=3600s) with no progress — Deputy intervenes (BLOCKED-STALE-60MIN) (branch origin/$BRANCH)"
    [ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s,progress=%s,blocked=%s,hb_span_s=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "NO-PROGRESS-BLOCKED-STALE-60MIN" "$PROG_NEW" "$BLOCK_NEW" "$SPAN" >> "$LOG"
    exit 4
  fi
  echo "OK: blocked-and-reported ('$BLOCK_NEW' stable ${BLOCK_AGE}s < 3600s) — legitimate, no escalation yet (branch origin/$BRANCH)"
  [ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s,progress=%s,blocked=%s,hb_span_s=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "OK-BLOCKED-STABLE" "$PROG_NEW" "$BLOCK_NEW" "$SPAN" >> "$LOG"
  exit 0
fi

# Rule 3/4: silent (blocked=none). Need three identical lines spanning >=30 min.
if [ "$N_HB" -ge 3 ]; then
  OLDEST3=$(printf '%s\n' "$LAST3" | head -1)
  PROG_OLD=$(hb_field "$OLDEST3" progress)
  BLOCK_OLD=$(hb_field "$OLDEST3" blocked)
  TS_OLD=$(to_epoch "$(printf '%s' "$OLDEST3" | awk '{print $2}')")
  SPAN3=$((TS_NEW - TS_OLD))
  if [ "$PROG_OLD" = "$PROG_NEW" ] && [ "$BLOCK_OLD" = "$BLOCK_NEW" ] && [ "$SPAN3" -ge 1800 ]; then
    echo "NO-PROGRESS: two consecutive silent no-progress cycles (progress $PROG_NEW unchanged, blocked=none, span ${SPAN3}s >= 1800s) — escalate to Deputy (branch origin/$BRANCH)"
    [ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s,progress=%s,blocked=%s,hb_span_s=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "NO-PROGRESS" "$PROG_NEW" "$BLOCK_NEW" "$SPAN3" >> "$LOG"
    exit 4
  fi
fi

if [ "$SPAN" -ge 900 ]; then
  echo "OK: one silent no-progress cycle only (span ${SPAN}s >= 900s) — watching, NOT escalating yet (branch origin/$BRANCH)"
  [ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s,progress=%s,blocked=%s,hb_span_s=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "OK-NO-PROGRESS-1CYCLE" "$PROG_NEW" "$BLOCK_NEW" "$SPAN" >> "$LOG"
  exit 0
fi

echo "OK: HB lines too close together to count a cycle (span ${SPAN}s < 900s), progress $PROG_NEW, blocked $BLOCK_NEW (branch origin/$BRANCH)"
[ -n "$LOG" ] && printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s,progress=%s,blocked=%s,hb_span_s=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "OK" "$PROG_NEW" "$BLOCK_NEW" "$SPAN" >> "$LOG"
exit 0
