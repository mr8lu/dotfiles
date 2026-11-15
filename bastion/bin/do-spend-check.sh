#!/usr/bin/env bash
# DigitalOcean daily month-to-date spend check.
#
# Purpose:
#   Checks DigitalOcean month-to-date usage via doctl and logs/records whether
#   spend exceeds the configured threshold.
#
# Environment variables:
#   THRESHOLD  Alert threshold in USD (default: 35)
#   DRY_RUN    Set to 1 to compute and print decision without writing any files or directories
#
# Files written (unless DRY_RUN=1):
#   $HOME/logs/do-spend-check.log  Append-only run and error log
#   $HOME/state/do-spend.json      Latest check state (atomic write via temp file + mv)
#   $HOME/state/do-spend-ALERT     Created when spend > THRESHOLD; removed when not over
#
# Cron line (Ubuntu 24.04 cron ignores CRON_TZ; fires at 13:00 and 14:00 UTC and guards for 09:00 America/New_York across DST):
#   0 13,14 * * * [ "$(TZ=America/New_York date +\%H)" = 09 ] && $HOME/bin/do-spend-check.sh >> $HOME/logs/do-spend-check.log 2>&1

set -euo pipefail
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

THRESHOLD="${THRESHOLD:-35}"
DRY_RUN="${DRY_RUN:-0}"
LOG_FILE="$HOME/logs/do-spend-check.log"
STATE_FILE="$HOME/state/do-spend.json"
ALERT_FILE="$HOME/state/do-spend-ALERT"

ts="$(TZ=America/New_York date -Iseconds)"

if [[ "$DRY_RUN" != "1" ]]; then
  mkdir -p "$HOME/logs" "$HOME/state"
fi

fail() {
  local line="$ts ERROR: $1"
  if [[ "$DRY_RUN" != "1" ]]; then
    echo "$line" >> "$LOG_FILE"
  fi
  echo "$line" >&2
  exit 1
}

if ! [[ "$THRESHOLD" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  fail "invalid THRESHOLD value"
fi

raw_json=""
rc=0
raw_json="$(doctl balance get -o json 2>/dev/null)" || rc=$?
if [[ "$rc" -ne 0 ]]; then
  fail "doctl balance get failed (exit $rc)"
fi

usage=""
if command -v jq >/dev/null 2>&1; then
  usage="$(printf '%s' "$raw_json" | jq -r '(if type == "array" then .[0] else . end).month_to_date_usage // empty' 2>/dev/null || true)"
else
  usage="$(printf '%s' "$raw_json" | python3 -c 'import json, sys
try:
    d = json.load(sys.stdin)
    if isinstance(d, list) and d:
        d = d[0]
    v = d.get("month_to_date_usage", "") if isinstance(d, dict) else ""
    print("" if v is None else v)
except Exception:
    pass' 2>/dev/null || true)"
fi

if [[ -z "$usage" ]] || ! [[ "$usage" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
  fail "invalid or empty month_to_date_usage"
fi

if awk -v u="$usage" -v t="$THRESHOLD" 'BEGIN { exit !(u + 0 > t + 0) }'; then
  over_json="true"
  status="ALERT"
else
  over_json="false"
  status="OK"
fi

status_line="$ts usage=$usage threshold=$THRESHOLD status=$status"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY_RUN $status_line"
  exit 0
fi

echo "$status_line" >> "$LOG_FILE"
if [[ -t 1 ]]; then
  echo "$status_line"
fi

tmp_state="$STATE_FILE.tmp.$$"
{ printf '{"checked_at": "%s", "month_to_date_usage": %s, "threshold": %s, "over": %s}' "$ts" "$usage" "$THRESHOLD" "$over_json"; echo; } > "$tmp_state"
mv -f "$tmp_state" "$STATE_FILE"

if [[ "$status" == "ALERT" ]]; then
  { printf 'DigitalOcean month-to-date spend is $%s, over the $%s alert threshold (checked %s). Review https://cloud.digitalocean.com/account/billing' "$usage" "$THRESHOLD" "$ts"; echo; } > "$ALERT_FILE"
else
  if [[ -e "$ALERT_FILE" ]]; then
    rm -f "$ALERT_FILE"
  fi
fi
