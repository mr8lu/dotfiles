#!/bin/bash
cd "$1" || exit 0

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

added=0
modified=0
untracked=0

while IFS= read -r line; do
    if [[ $line == \?\?* ]]; then
        ((untracked++))
    elif [[ $line == M* ]] || [[ $line == \ M* ]]; then
        ((modified++))
    elif [[ $line == A* ]] || [[ $line == \ A* ]]; then
        ((added++))
    fi
done < <(git status --porcelain 2>/dev/null)

stats=""
[ "$added" -gt 0 ] && stats+="+$added "
[ "$modified" -gt 0 ] && stats+="~$modified "
[ "$untracked" -gt 0 ] && stats+="?$untracked "

if [ -n "$stats" ]; then
    stats="[${stats% }]"
    echo "#[fg=#C29B38,bg=#1E1B18]  $branch #[fg=#C05C46]$stats "
else
    echo "#[fg=#7A8B7B,bg=#1E1B18]  $branch "
fi
