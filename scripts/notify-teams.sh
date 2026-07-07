#!/bin/zsh

# ==============================================================================
# MS TEAMS PROGRAMMATIC NOTIFICATION ENGINE (With Routing CLI Config Management)
# ==============================================================================

CONFIG_FILE="$HOME/.teams_webhook_routes.conf"
typeset -A WEBHOOKS

# Ensure the config file exists
touch "$CONFIG_FILE"

# --- READ CONFIGURATION FILE INTO MEMORY ---
load_config() {
  while IFS='=' read -r key val; do
    # Skip empty lines or lines starting with # (comments)
    [[ -z "$key" || "$key" =~ "^#" ]] && continue
    # Trim whitespace
    key="${key## }"
    key="${key%% }"
    val="${val## }"
    val="${val%% }"
    WEBHOOKS[$key]="$val"
  done < "$CONFIG_FILE"
}

# --- WRITE MEMORY ARRAY BACK TO CONFIG FILE ---
save_config() {
  echo "# MS Teams Routing Webhook Configurations" > "$CONFIG_FILE"
  echo "# Generated dynamically via ./notify-teams.sh" >> "$CONFIG_FILE"
  echo "# Format: PROJECT:EFFORT:PERSON=URL\n" >> "$CONFIG_FILE"
  for key in ${(k)WEBHOOKS}; do
    echo "${key}=${WEBHOOKS[$key]}" >> "$CONFIG_FILE"
  done
  echo "✅ Configuration file updated successfully."
}

# Load the current mappings immediately
load_config

# --- USAGE DOCUMENTATION ---
usage() {
  echo "Teams Notifier & Routing Configuration Manager"
  echo "------------------------------------------------"
  echo "🎯 Notification Delivery Syntax:"
  echo "  A) Shortcut Form:  ~/notify-teams.sh <project>:<effort>:<person> <message>"
  echo "  B) Verbose Form:   ~/notify-teams.sh -p <project> -e <effort> -r <person> -m <message> [-s <success|failure>]"
  echo ""
  echo "⚙️  Configuration Management Commands:"
  echo "  --add    <project>:<effort>:<person> <url>   - Add or update a routing path and webhook URL"
  echo "  --list                                        - List all configured routing mappings"
  echo "  --remove <project>:<effort>:<person>         - Delete a routing path"
  echo ""
  echo "Examples:"
  echo "  ~/notify-teams.sh --add deq:agent:philippine 'https://...'"
  echo "  ~/notify-teams.sh --list"
  echo "  ~/notify-teams.sh deq:agent:philippine 'Finished successfully!'"
  exit 1
}

# --- CONFIG MANAGEMENT ARBITRATION ---
if [[ "$1" == "--add" ]]; then
  if [[ -z "$2" || -z "$3" ]]; then
    echo "❌ Error: Missing arguments. Use: --add <project>:<effort>:<person> <url>"
    exit 1
  fi
  if [[ ! "$2" =~ "^[^:]+:[^:]+:[^:]+$" ]]; then
    echo "❌ Error: Key format must be exactly: project:effort:person (e.g. deq:agent:philippine)"
    exit 1
  fi
  WEBHOOKS[$2]="$3"
  save_config
  exit 0

elif [[ "$1" == "--list" ]]; then
  echo "📋 Configured Routing Paths in $CONFIG_FILE:"
  echo "------------------------------------------------"
  if [ ${#WEBHOOKS} -eq 0 ]; then
    echo " (No routes currently configured. Use --add to add one.)"
  else
    for key in ${(k)WEBHOOKS}; do
      printf "🔑 \e[33m%-25s\e[0m -> 🌐 %s\n" "$key" "${WEBHOOKS[$key]:0:70}..."
    done
  fi
  exit 0

elif [[ "$1" == "--remove" ]]; then
  if [[ -z "$2" ]]; then
    echo "❌ Error: Missing target key. Use: --remove <project>:<effort>:<person>"
    exit 1
  fi
  if [[ -z "${WEBHOOKS[$2]}" ]]; then
    echo "⚠️  Warning: Route '$2' does not exist."
    exit 1
  fi
  unset "WEBHOOKS[$2]"
  save_config
  exit 0
fi

# --- STANDARD NOTIFICATION ARBITRATION ---
PROJECT=""
EFFORT=""
PERSON=""
MESSAGE=""
STATUS=""

# If the first argument is a 3-part matrix key (e.g. x:y:z)
if [[ "$1" =~ "^[^:]+:[^:]+:[^:]+$" ]]; then
  KEY="$1"
  MESSAGE="$2"
  # Parse key
  IFS=':' read -r PROJECT EFFORT PERSON <<< "$KEY"
else
  # Parse standard flags
  while getopts "p:e:r:m:s:h" opt; do
    case ${opt} in
      p ) PROJECT=$OPTARG ;;
      e ) EFFORT=$OPTARG ;;
      r ) PERSON=$OPTARG ;;
      m ) MESSAGE=$OPTARG ;;
      s ) STATUS=$OPTARG ;;
      h|* ) usage ;;
    esac
  done
fi

# Assert inputs
if [[ -z "$PROJECT" || -z "$EFFORT" || -z "$PERSON" || -z "$MESSAGE" ]]; then
  echo "❌ Error: Incomplete parameters."
  usage
fi

LOOKUP_KEY="${PROJECT}:${EFFORT}:${PERSON}"
URL="${WEBHOOKS[$LOOKUP_KEY]}"

if [[ -z "$URL" ]]; then
  echo "❌ Error: No route found for: '$LOOKUP_KEY'"
  echo "💡 Register it first using: ~/notify-teams.sh --add $LOOKUP_KEY 'YOUR_WEBHOOK_URL'"
  exit 1
fi

ICON=""
if [[ "$STATUS" == "success" ]]; then
  ICON="✅ "
elif [[ "$STATUS" == "failure" ]]; then
  ICON="❌ "
fi

if [[ "$URL" =~ "@" ]]; then
  # Email dispatch via Outlook
  echo "✉️ Detected email destination. Routing message to $URL via Microsoft Outlook..."
  
  # Escape double quotes and backslashes for AppleScript
  CLEAN_MESSAGE=$(echo "${ICON}${MESSAGE}" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
  EMAIL_SUBJECT="${ICON}[${(U)PROJECT} > ${EFFORT}] ${MESSAGE}"
  
  EMAIL_BODY="📢 ${MESSAGE}

• Project: ${(U)PROJECT}
• Effort: ${EFFORT}
• Triggered By: Dan's Intern
• UTC Time: \$(date -u +"%Y-%m-%d %H:%M:%S")"
  CLEAN_BODY=$(echo "$EMAIL_BODY" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

  osascript <<EOF
tell application "Microsoft Outlook"
    set newMessage to make new outgoing message with properties {subject:"$EMAIL_SUBJECT", content:"$CLEAN_BODY"}
    make new recipient at newMessage with properties {email address:{address:"$URL"}}
    send newMessage
end tell
EOF
  
  if [ $? -eq 0 ]; then
    echo "🚀 Email sent successfully to $URL for [$LOOKUP_KEY]"
  else
    echo "❌ Failed to send email via Microsoft Outlook."
    exit 1
  fi

  # --- TEAMS UI AUTOMATION PING ---
  TARGET="${URL// /}"
  TOPIC_PARAM=""
  if [[ "$TARGET" == *","* ]]; then
    echo "💬 Routing message to multiple recipients: $TARGET via Teams Desktop Client..."
    TOPIC_NAME="[${(U)PROJECT}] ${(U)EFFORT} Alerts"
    # URL encode topic name safely
    ENCODED_TOPIC=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$TOPIC_NAME")
    TOPIC_PARAM="&topicName=${ENCODED_TOPIC}"
  else
    echo "💬 Routing message to $TARGET via Teams Desktop Client..."
  fi

  # Construct Teams UI message: only message + signature
  TEAMS_MESSAGE="${ICON}${MESSAGE}

Triggered By: Dan's Intern"
  # Safely URL encode using python3 to prevent encoding bugs
  ENCODED_MESSAGE=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$TEAMS_MESSAGE")

  TEAMS_URI="msteams://teams.microsoft.com/l/chat/0/0?users=${TARGET}&message=${ENCODED_MESSAGE}${TOPIC_PARAM}"

  osascript <<EOF
-- 1. Open the deep link inside Microsoft Teams
do shell script "open '${TEAMS_URI}'"

-- 2. Give the Teams app UI enough time to load the chat window
delay 3.0

-- 3. Simulate pressing the 'Enter' key to send the message
tell application "System Events"
    tell application process "Microsoft Teams"
        set frontmost to true
        key code 36 -- Key code for Return/Enter
    end tell
end tell
EOF

  if [ $? -eq 0 ]; then
    echo "🚀 Successfully dispatched Teams message to $TARGET via App Automation!"
    exit 0
  else
    echo "❌ Automation failed."
    echo "💡 Troubleshooting: Verify that 'Terminal' (or your IDE) is granted 'Accessibility' permissions in System Settings > Privacy & Security > Accessibility."
    exit 1
  fi
fi

JSON_PAYLOAD=$(cat <<EOF
{
  "text": "${ICON}${MESSAGE}",
  "project": "${PROJECT}",
  "effort": "${EFFORT}",
  "person": "${PERSON}",
  "sent_by": "Dan's Intern (Gemini 3 Pro)",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)

# Dispatch
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "$URL")

if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "202" ]]; then
  echo "🚀 Notification sent to Teams for: [$LOOKUP_KEY]"
else
  echo "❌ Delivery failed. Microsoft Power Automate returned status: $HTTP_STATUS"
  exit 1
fi
