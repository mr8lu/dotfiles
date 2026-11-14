#!/bin/bash
# Reboot only when required AND no Gemini pane in tmux "harness" is busy.
# Waits (checking every 2 min) until 06:30 America/New_York; if still busy, skips to next night.
U=danipan
[ -f /var/run/reboot-required ] || { logger -t reboot-if-needed "no reboot needed"; exit 0; }
busy() {
  runuser -u $U -- bash -c 'for w in $(tmux list-windows -t harness -F "#I" 2>/dev/null); do tmux capture-pane -p -t harness:$w | grep -q "esc to cancel" && echo $w; done'
}
deadline=$(TZ=America/New_York date -d "today 06:30" +%s)
idle_streak=0
while :; do
  b=$(busy | tr '\n' ' ')
  if [ -z "$b" ]; then idle_streak=$((idle_streak+1)); else idle_streak=0; logger -t reboot-if-needed "waiting, busy windows: $b"; fi
  [ $idle_streak -ge 2 ] && break
  if [ "$(date +%s)" -ge "$deadline" ]; then logger -t reboot-if-needed "agents still busy at deadline; skipping reboot tonight"; exit 0; fi
  sleep 120
done
runuser -u $U -- bash -c 'tmux list-windows -t harness -F "#I	#W	#{pane_current_path}	#{pane_current_command}" > ~/.local/state/harness-windows.tsv; ~/.tmux/plugins/tmux-resurrect/scripts/save.sh quiet' || true
logger -t reboot-if-needed "rebooting for: $(tr '\n' ' ' </var/run/reboot-required.pkgs 2>/dev/null)"
systemctl reboot
