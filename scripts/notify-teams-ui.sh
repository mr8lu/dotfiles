#!/bin/zsh

# ==============================================================================
# MS TEAMS UI AUTOMATION NOTIFICATION ENGINE (Direct Chat Messaging Wrapper)
# ==============================================================================
# This script is a thin wrapper that delegates to the unified notify-teams.sh
# which handles both email notifications and Teams UI client automation seamlessly.

exec "$HOME/notify-teams.sh" "$@"
