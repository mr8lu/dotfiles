#!/usr/bin/env bash
# Prune old nez images in DOCR and run garbage collection.
# Keeps: "latest", the tag the live nez app runs, and the newest KEEP SHA tags (rollback needs the previous image).
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
KEEP=${KEEP:-5}; REPO=nez; APP_ID=18fffcf5-8fb8-4b64-bb96-9774efc049a8
log(){ echo "$(date "+%F %T %Z") $*"; }
# Skip if a deploy is running (GC blocks pushes).
if gh run list -R mr8lu/nez --status in_progress --limit 1 --json databaseId -q "length" | grep -qv "^0$"; then log "deploy in progress, skipping"; exit 0; fi
if doctl registry garbage-collection get-active >/dev/null 2>&1; then log "GC already active, skipping"; exit 0; fi
LIVE=$(doctl apps spec get "$APP_ID" | awk "/repository: $REPO/{f=1} f&&/tag:/{print \$2; exit}")
[ -n "$LIVE" ] || { log "could not read live tag, aborting"; exit 1; }
mapfile -t SHAS < <(doctl registry repository list-tags "$REPO" -o json | python3 -c "import json,sys;t=[x for x in json.load(sys.stdin) if x.get(\"tag\") and x[\"tag\"]!=\"latest\"];t.sort(key=lambda x:x[\"updated_at\"],reverse=True);print(\"\n\".join(x[\"tag\"] for x in t))")
DEL=()
for i in "${!SHAS[@]}"; do t=${SHAS[$i]}; if [ "$i" -ge "$KEEP" ] && [ "$t" != "$LIVE" ]; then DEL+=("$t"); fi; done
log "live=$LIVE keep=$KEEP total_sha_tags=${#SHAS[@]} deleting=${#DEL[@]} ${DEL[*]:-}"
[ ${#DEL[@]} -gt 0 ] && doctl registry repository delete-tag "$REPO" "${DEL[@]}" --force
doctl registry garbage-collection start --include-untagged-manifests --force >/dev/null && log "GC started"
