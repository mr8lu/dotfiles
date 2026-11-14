#!/bin/bash
export PATH=/home/danipan/.local/bin:/usr/local/bin:/usr/bin:/bin
LOG=~/logs/harness-restore.log
GEM="gemini --resume latest --approval-mode=yolo --no-sandbox -m gemini-4-argon"
if ! tmux has-session -t harness 2>/dev/null; then
  if [ -s ~/.local/share/tmux/resurrect/last ]; then
    tmux new-session -d -s _boot -c ~/workspace
    ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
    tmux kill-session -t _boot 2>/dev/null || true
  fi
  tmux has-session -t harness 2>/dev/null || tmux new-session -d -s harness -n gemini -c ~/workspace
fi
# Re-create any window from the pre-reboot snapshot that didn't come back
S=~/.local/state/harness-windows.tsv
if [ -s "$S" ]; then
  while IFS=$'\t' read -r idx name path cmd; do
    if ! tmux list-windows -t harness -F "#W" | grep -qxF "$name"; then
      tmux new-window -d -t harness -n "$name" -c "$path"
      [ "$cmd" = "node" ] || [ "$cmd" = "gemini" ] && tmux send-keys -t "harness:$name" "$GEM" Enter
      echo "$(date -Is) recreated window $name ($path)" >> $LOG
    fi
  done < "$S"
fi
echo "$(date -Is) restore done: $(tmux list-windows -t harness -F '#W' | tr '\n' ',')" >> $LOG
