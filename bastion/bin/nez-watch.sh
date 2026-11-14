#!/usr/bin/env bash
# Cheap monitoring watcher for Grok Bot routines.
#
# Purpose:
#   Collects open PRs on mr8lu/nez and mr8lu/dotfiles, key dotfiles branches,
#   tmux harness window statuses (read-only), and relevant systemd/reboot states
#   into a compact markdown summary without making any LLM calls.
#
# Files written:
#   $HOME/state/nez-watch.md          Latest compact summary (~40 lines max)
#   $HOME/state/nez-watch.prev.md     Previous run summary
#   $HOME/state/nez-watch.changes.md  Meaningful changes since previous run
#   $HOME/logs/nez-watch.log          Append-only one-line run log
#
# Cron line (every 20 minutes):
#   */20 * * * * $HOME/bin/nez-watch.sh >> $HOME/logs/nez-watch.log 2>&1

set -euo pipefail
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

STATE_DIR="$HOME/state"
LOG_DIR="$HOME/logs"
SUMMARY_FILE="$STATE_DIR/nez-watch.md"
PREV_FILE="$STATE_DIR/nez-watch.prev.md"
CHANGES_FILE="$STATE_DIR/nez-watch.changes.md"
LOG_FILE="$LOG_DIR/nez-watch.log"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$HOME/bin"

ts_et="$(TZ=America/New_York date '+%Y-%m-%d %H:%M:%S') ET"
ts_iso="$(TZ=America/New_York date -Iseconds)"

redact() {
  sed -E -e 's/dop_v1_[A-Za-z0-9_]+/[REDACTED]/g' -e 's/gh[pousr]_[A-Za-z0-9_]+/[REDACTED]/g' -e 's/github_pat_[A-Za-z0-9_]+/[REDACTED]/g' -e 's/AIza[0-9A-Za-z_-]{20,}/[REDACTED]/g' -e 's/sk-[A-Za-z0-9_-]{16,}/[REDACTED]/g' -e 's/-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----/[REDACTED_KEY]/g' -e 's/([Tt]oken|[Ss]ecret|[Pp]assword|API[_-]?KEY)[[:space:]]*[:=][[:space:]]*[^[:space:]"'"'"']+/\1=[REDACTED]/gi'
}

format_prs() {
  local repo="$1"
  local raw=""
  raw="$(gh pr list -R "$repo" --state open --limit 15 --json number,title,url,headRefName,statusCheckRollup,commits 2>/dev/null || true)"
  if [[ -z "$raw" ]]; then
    echo "- (error or unreachable querying $repo)"
    return 0
  fi
  python3 -c '
import json, sys
from datetime import datetime
try:
    from zoneinfo import ZoneInfo
    et_tz = ZoneInfo("America/New_York")
except Exception:
    et_tz = None

try:
    prs = json.loads(sys.stdin.read())
except Exception:
    print("- (invalid JSON from gh)")
    sys.exit(0)

if not prs:
    print("- none")
    sys.exit(0)

for pr in prs:
    num = pr.get("number", "?")
    title = " ".join((pr.get("title") or "").split())
    if len(title) > 48:
        title = title[:45] + "..."
    url = pr.get("url", "")
    branch = pr.get("headRefName", "?")
    rollup = pr.get("statusCheckRollup") or []
    if not rollup:
        ci = "NO_CHECKS"
    else:
        states = []
        for c in rollup:
            val = (c.get("conclusion") or c.get("state") or c.get("status") or "").upper()
            states.append(val)
        if any(s in ("FAILURE", "ERROR", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE") for s in states):
            ci = "FAIL"
        elif any(s in ("PENDING", "IN_PROGRESS", "QUEUED", "WAITING", "REQUESTED", "") for s in states):
            ci = "PENDING"
        elif all(s in ("SUCCESS", "NEUTRAL", "SKIPPED") for s in states):
            ci = "PASS"
        else:
            ci = "MIXED"

    commits = pr.get("commits") or []
    c_date = ""
    if commits and isinstance(commits[-1], dict):
        c_date = commits[-1].get("committedDate") or ""
    et_str = "unknown ET"
    if c_date:
        try:
            dt = datetime.fromisoformat(c_date.replace("Z", "+00:00"))
            if et_tz:
                dt = dt.astimezone(et_tz)
            et_str = dt.strftime("%Y-%m-%d %H:%M ET")
        except Exception:
            et_str = c_date

    print(f"- #{num} [{branch}] CI:{ci} ({et_str}) {title} <{url}>")
' <<< "$raw" | redact
}

check_dotfiles_branches() {
  local branches=("feat/bastion-harness" "feat/do-spend-check" "feat/nez-watch")
  local remote_heads=""
  remote_heads="$(git ls-remote --heads https://github.com/mr8lu/dotfiles.git 2>/dev/null || gh api repos/mr8lu/dotfiles/branches --paginate --jq '.[].name' 2>/dev/null || true)"
  local out=()
  for b in "${branches[@]}"; do
    if grep -qF "$b" <<< "$remote_heads"; then
      out+=("$b:exists")
    else
      out+=("$b:missing")
    fi
  done
  local IFS=", "
  echo "- Branches: ${out[*]}"
}

check_tmux_harness() {
  if ! tmux has-session -t harness 2>/dev/null; then
    echo "- (tmux session 'harness' not found)"
    return 0
  fi

  local win_list=""
  win_list="$(tmux list-windows -t harness -F '#{window_index}|#{window_name}|#{pane_current_command}' 2>/dev/null || true)"
  if [[ -z "$win_list" ]]; then
    echo "- (no windows found in harness)"
    return 0
  fi

  while IFS='|' read -r idx name cmd; do
    [[ -z "$idx" ]] && continue
    local pane_text=""
    pane_text="$(tmux capture-pane -t "harness:${idx}" -p -S -15 2>/dev/null || true)"
    local line=""
    line="$(python3 -c '
import sys, re

idx, name, cmd = sys.argv[1], sys.argv[2], sys.argv[3]
raw = sys.stdin.read()
lines = [l.strip() for l in raw.splitlines() if l.strip()]

def clean_excerpt(s):
    s = " ".join(s.split())
    return s[:65] + ("..." if len(s) > 65 else "")

status = "UNKNOWN"
reason = lines[-1] if lines else "(empty pane)"

shell_cmds = {"bash", "zsh", "sh", "fish", "dash", "tmux"}
tail_lines = lines[-8:] if lines else []

wait_pat = re.compile(r"(allow this|allow once|allow always|yes/no|\[y/n\]|\(y/n\)|do you want to proceed|waiting for user|apply this change\?|run this command\?)", re.I)
busy_pat = re.compile(r"(esc to cancel|thinking\.\.\.|working\.\.\.|[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏])", re.I)
idle_pat = re.compile(r"(type your message|^>\s*$|❯|\[insert\]|\[normal\])", re.I)

if cmd in shell_cmds:
    status = "SHELL"
    reason = f"cmd={cmd}; " + (lines[-1] if lines else "shell prompt")
else:
    matched_wait = [l for l in tail_lines if wait_pat.search(l)]
    matched_busy = [l for l in tail_lines if busy_pat.search(l)]
    matched_idle = [l for l in tail_lines if idle_pat.search(l)]
    if matched_wait:
        status = "WAITING"
        reason = matched_wait[-1]
    elif matched_busy:
        status = "BUSY"
        reason = matched_busy[-1]
    elif matched_idle:
        status = "IDLE"
        reason = matched_idle[-1]
    elif cmd in ("node", "gemini", "python", "python3"):
        status = "IDLE"
        reason = lines[-1] if lines else f"cmd={cmd}"
    elif lines:
        status = "UNKNOWN"
        reason = lines[-1]

print(f"- W{idx} {name} ({cmd}): {status} - {clean_excerpt(reason)}")
' "$idx" "$name" "$cmd" <<< "$pane_text" | redact)"
    echo "$line"
  done <<< "$win_list"
}

unit_state() {
  local mode="$1"
  local unit="$2"
  local active=""
  local sub=""
  if [[ "$mode" == "user" ]]; then
    active="$(systemctl --user is-active "$unit" 2>/dev/null || true)"
    sub="$(systemctl --user show -p SubState --value "$unit" 2>/dev/null || true)"
  else
    active="$(systemctl is-active "$unit" 2>/dev/null || true)"
    sub="$(systemctl show -p SubState --value "$unit" 2>/dev/null || true)"
  fi
  [[ -z "$active" ]] && active="unknown"
  if [[ -n "$sub" && "$sub" != "$active" ]]; then
    echo "${unit}=${active}(${sub})"
  else
    echo "${unit}=${active}"
  fi
}

check_systemd_and_reboot() {
  local u_harness=""
  u_harness="$(unit_state user gemini-harness.service)"
  local s_reb_t="" s_reb_s="" s_apt_d="" s_apt_u=""
  s_reb_t="$(unit_state sys reboot-if-needed.timer)"
  s_reb_s="$(unit_state sys reboot-if-needed.service)"
  s_apt_d="$(unit_state sys apt-daily.timer)"
  s_apt_u="$(unit_state sys apt-daily-upgrade.timer)"

  local failed_sys=""
  failed_sys="$(systemctl list-units --state=failed --no-legend --plain 2>/dev/null | awk '{print $1}' | paste -sd, - || true)"
  [[ -z "$failed_sys" ]] && failed_sys="none"

  local reboot_str="no"
  if [[ -f /var/run/reboot-required ]]; then
    local pkgs=""
    if [[ -r /var/run/reboot-required.pkgs ]]; then
      pkgs="$(head -n 3 /var/run/reboot-required.pkgs | paste -sd, - || true)"
    fi
    if [[ -n "$pkgs" ]]; then
      reboot_str="YES (pkgs: $pkgs)"
    else
      reboot_str="YES"
    fi
  fi

  echo "- user: $u_harness | failed_units: $failed_sys"
  echo "- timers/svc: $s_reb_t, $s_reb_s, $s_apt_d, $s_apt_u"
  echo "- reboot_pending: $reboot_str"
}

tmp_summary="$SUMMARY_FILE.tmp.$$"
{
  echo "# NEZ Watch - $ts_et"
  echo "## mr8lu/nez Open PRs"
  format_prs "mr8lu/nez"
  echo "## mr8lu/dotfiles"
  format_prs "mr8lu/dotfiles"
  check_dotfiles_branches
  echo "## tmux harness"
  check_tmux_harness
  echo "## systemd & reboot"
  check_systemd_and_reboot
} > "$tmp_summary"

had_prev=0
if [[ -f "$SUMMARY_FILE" ]]; then
  cp -f "$SUMMARY_FILE" "$PREV_FILE"
  had_prev=1
fi

mv -f "$tmp_summary" "$SUMMARY_FILE"

tmp_changes="$CHANGES_FILE.tmp.$$"
if [[ "$had_prev" -eq 0 ]]; then
  echo "initial snapshot" > "$tmp_changes"
else
  python3 - "$PREV_FILE" "$SUMMARY_FILE" << 'PYEOF' > "$tmp_changes"
import sys

prev_path, curr_path = sys.argv[1], sys.argv[2]

def parse_md(path):
    data = {"prs": {}, "branches": "", "tmux": {}, "sys": {}}
    sec = ""
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.strip()
            if line.startswith("## "):
                sec = line[3:].strip()
                continue
            if not line.startswith("- "):
                continue
            if sec in ("mr8lu/nez Open PRs", "mr8lu/dotfiles"):
                if line.startswith("- Branches:"):
                    data["branches"] = line
                elif line.startswith("- #"):
                    try:
                        after_dash = line[2:]
                        num, rest1 = after_dash.split(" [", 1)
                        branch, rest2 = rest1.split("] CI:", 1)
                        ci, rest3 = rest2.split(" (", 1)
                        commit_time, rest4 = rest3.split(") ", 1)
                        key = f"{sec}:{num}"
                        data["prs"][key] = {
                            "branch": branch,
                            "ci": ci,
                            "commit_time": commit_time,
                            "rest": rest4,
                            "raw": line
                        }
                    except Exception:
                        pass
            elif sec == "tmux harness":
                if "): " in line and " - " in line:
                    left, right = line[2:].split("): ", 1)
                    win_key = left + ")"
                    st = right.split(" - ", 1)[0].strip()
                    data["tmux"][win_key] = (st, line)
            elif sec == "systemd & reboot":
                k = line.split(":", 1)[0]
                data["sys"][k] = line
    return data

prev = parse_md(prev_path)
curr = parse_md(curr_path)
changes = []

for k, c_info in curr["prs"].items():
    if k not in prev["prs"]:
        changes.append(f"NEW PR {k}: {c_info['raw']}")
    else:
        p_info = prev["prs"][k]
        if p_info["ci"] != c_info["ci"]:
            changes.append(f"CI FLIP {k}: {p_info['ci']} -> {c_info['ci']}")
        if p_info["commit_time"] != c_info["commit_time"]:
            changes.append(f"NEW COMMIT {k}: {p_info['commit_time']} -> {c_info['commit_time']}")
for k, p_info in prev["prs"].items():
    if k not in curr["prs"]:
        changes.append(f"CLOSED/MERGED PR {k}: {p_info['raw']}")

if prev["branches"] != curr["branches"]:
    changes.append(f"BRANCHES: {prev['branches']} -> {curr['branches']}")

for w, (c_st, c_raw) in curr["tmux"].items():
    if w not in prev["tmux"]:
        if c_st in ("WAITING", "IDLE"):
            changes.append(f"TMUX NEW {w}: {c_st}")
    else:
        p_st, _ = prev["tmux"][w]
        if p_st != c_st:
            if c_st == "WAITING" or p_st == "WAITING" or c_st == "IDLE":
                changes.append(f"TMUX {w}: {p_st} -> {c_st} ({c_raw})")

for k, c_line in curr["sys"].items():
    p_line = prev["sys"].get(k, "")
    if p_line != c_line:
        changes.append(f"SYSTEM: {p_line} -> {c_line}")

for c in changes:
    print(c)
PYEOF
fi
mv -f "$tmp_changes" "$CHANGES_FILE"

change_count="$(wc -l < "$CHANGES_FILE" | tr -d ' ')"
line_count="$(wc -l < "$SUMMARY_FILE" | tr -d ' ')"
echo "$ts_iso status=OK lines=$line_count changes=$change_count" >> "$LOG_FILE"
