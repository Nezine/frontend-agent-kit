#!/bin/sh
# activation-probe.sh — D78 enforcement leg (deterministic, no model call).
#
# Reads the coordinator's last activity from the REMOTE (server-observed):
#   * last push time  = committer date of the tip commit on origin/<branch>
#   * pending work    = coord/pending-work.txt exists and is non-empty
#                       at the tip of origin/<branch>
# Takeover condition (D78, both must hold):
#   (a) pending work exists, and
#   (b) no coordinator push for longer than --stale-mins (default 20).
# An idle coordinator with an empty queue is idle, not stale: no takeover.
#
# Exit codes: 0 = OK (alive or idle, no takeover) | 2 = STALE, takeover
#             condition met | 3 = ERROR (cannot read state — loud, never OK).
# Every check appends one line to --log (default: no log file) so a missing
# probe log is itself visible the next morning.
#
# Honest limits (see coord/activation-research.md, Round 2):
#   * Commit time is author-controlled and can be forged/backdated; it is a
#     PROXY for server-observed push time, not the push event itself. True
#     server push time needs the hosting API (rate-limited, needs auth for
#     private repos). For the fleet's threat model (accidental staleness,
#     not adversarial forgery) the proxy is adequate; the Deputy-side
#     15-min poll cross-checks it.
#   * The probe DETECTS staleness; it does not wake anyone by itself. The
#     wake path is a separate mechanism (cron dispatch / event hook).
#   * A heartbeat measures pulse, not progress: a coordinator pushing empty
#     heartbeats with a rotting queue still trips condition (a) via the
#     pending-work half of the test — but only if the pending marker is
#     kept truthful by the workers/coordinator.
#
# Usage:
#   activation-probe.sh --clone <path> --branch <branch>
#       [--stale-mins 20] [--pending-path coord/pending-work.txt]
#       [--log <file>]
# Cost: $0.00 (git + date only).

set -u

CLONE=""
BRANCH=""
STALE_MINS=20
PENDING_PATH="coord/pending-work.txt"
LOG=""

usage() {
  echo "usage: $0 --clone <path> --branch <branch> [--stale-mins N] [--pending-path <path>] [--log <file>]" >&2
  exit 3
}

while [ $# -gt 0 ]; do
  case "$1" in
    --clone) CLONE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --stale-mins) STALE_MINS="$2"; shift 2 ;;
    --pending-path) PENDING_PATH="$2"; shift 2 ;;
    --log) LOG="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[ -n "$CLONE" ] && [ -n "$BRANCH" ] || usage
case "$STALE_MINS" in ''|*[!0-9]*) echo "ERROR: --stale-mins must be a number" >&2; exit 3 ;; esac

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

NOW=$(date +%s)
AGE=$((NOW - LAST))
THRESHOLD=$((STALE_MINS * 60))
LAST_ISO=$(date -u -d "@$LAST" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$LAST" +%Y-%m-%dT%H:%M:%SZ)

if [ "$AGE" -gt "$THRESHOLD" ] && [ "$PENDING" -eq 1 ]; then
  RESULT="STALE"
  echo "STALE: coordinator silent ${AGE}s (last push $LAST_ISO, threshold ${THRESHOLD}s) with pending work present — TAKEOVER condition met (branch origin/$BRANCH)"
  CODE=2
else
  RESULT="OK"
  echo "OK: last push $LAST_ISO (${AGE}s ago, threshold ${THRESHOLD}s), pending=$PENDING (branch origin/$BRANCH)"
  CODE=0
fi

if [ -n "$LOG" ]; then
  printf '%s,branch=%s,last_push=%s,age_s=%s,pending=%s,result=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$BRANCH" "$LAST_ISO" "$AGE" "$PENDING" "$RESULT" >> "$LOG"
fi

exit "$CODE"
