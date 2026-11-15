#!/usr/bin/env bash
# Idempotent installer for the Ubuntu 24.04 bastion agent-harness and maintenance setup.
set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n)
            DRY_RUN=1
            ;;
        *)
            echo "Unknown option: $arg (supported: --dry-run)" >&2
            exit 1
            ;;
    esac
done

BASTION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${USER:-$(id -un)}"
TARGET_HOME="${HOME:-$(eval echo "~$TARGET_USER")}"

run_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

echo "Installing bastion configuration for user=${TARGET_USER} home=${TARGET_HOME} (dry_run=${DRY_RUN})..."

# 1. Install tmux and git if missing
if ! command -v tmux >/dev/null 2>&1; then
    echo "Installing tmux..."
    run_cmd sudo apt-get update -qq
    run_cmd sudo apt-get install -y -qq tmux
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    run_cmd sudo apt-get update -qq
    run_cmd sudo apt-get install -y -qq git
fi

# 2. Install TPM and tmux-resurrect / tmux-continuum plugins if missing
PLUGINS_DIR="${TARGET_HOME}/.tmux/plugins"
run_cmd mkdir -p "$PLUGINS_DIR"

install_tmux_plugin() {
    local name="$1"
    local repo="$2"
    if [ ! -d "${PLUGINS_DIR}/${name}" ]; then
        echo "Cloning ${name}..."
        run_cmd git clone --depth 1 "$repo" "${PLUGINS_DIR}/${name}"
    else
        echo "Tmux plugin already present: ${name}"
    fi
}

install_tmux_plugin "tpm" "https://github.com/tmux-plugins/tpm"
install_tmux_plugin "tmux-resurrect" "https://github.com/tmux-plugins/tmux-resurrect"
install_tmux_plugin "tmux-continuum" "https://github.com/tmux-plugins/tmux-continuum"

# 3. Ensure required user directories exist
run_cmd mkdir -p "${TARGET_HOME}/bin" "${TARGET_HOME}/logs" "${TARGET_HOME}/workspace" "${TARGET_HOME}/.local/state" "${TARGET_HOME}/.local/share/tmux/resurrect" "${TARGET_HOME}/.config/systemd/user"

# Helper: render file replacing hardcoded user/home with $TARGET_USER and $TARGET_HOME
install_user_file() {
    local src="$1"
    local dest="$2"
    local mode="${3:-}"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[dry-run] install_user_file ${src} -> ${dest} ${mode:+(mode ${mode})}"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    if [ "$TARGET_HOME" = "/home/danipan" ] && [ "$TARGET_USER" = "danipan" ]; then
        ln -sfn "$src" "$dest"
        [ -n "$mode" ] && chmod "$mode" "$src"
    else
        rm -f "$dest"
        sed -e "s|/home/danipan|${TARGET_HOME}|g" -e "s|danipan|${TARGET_USER}|g" "$src" > "$dest"
        [ -n "$mode" ] && chmod "$mode" "$dest"
    fi
}

install_root_file() {
    local src="$1"
    local dest="$2"
    local mode="${3:-0644}"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[dry-run] sudo install -m ${mode} -o root -g root ${src} -> ${dest}"
        return 0
    fi

    local tmp
    tmp="$(mktemp)"
    sed -e "s|/home/danipan|${TARGET_HOME}|g" -e "s|U=danipan|U=${TARGET_USER}|g" "$src" > "$tmp"
    sudo mkdir -p "$(dirname "$dest")"
    sudo install -m "$mode" -o root -g root "$tmp" "$dest"
    rm -f "$tmp"
}

# 4. Install user files (symlinked when user/home match repo defaults, rendered otherwise)
install_user_file "${BASTION_DIR}/tmux/.tmux.conf" "${TARGET_HOME}/.tmux.conf"
install_user_file "${BASTION_DIR}/bin/tmux-harness-start.sh" "${TARGET_HOME}/bin/tmux-harness-start.sh" 0755
install_user_file "${BASTION_DIR}/bin/nez-registry-cleanup.sh" "${TARGET_HOME}/bin/nez-registry-cleanup.sh" 0755
install_user_file "${BASTION_DIR}/.config/systemd/user/gemini-harness.service" "${TARGET_HOME}/.config/systemd/user/gemini-harness.service" 0644

# 5. Install system files (/usr/local and /etc) with sudo
install_root_file "${BASTION_DIR}/usr/local/sbin/reboot-if-needed.sh" "/usr/local/sbin/reboot-if-needed.sh" 0755
install_root_file "${BASTION_DIR}/etc/systemd/system/reboot-if-needed.service" "/etc/systemd/system/reboot-if-needed.service" 0644
install_root_file "${BASTION_DIR}/etc/systemd/system/reboot-if-needed.timer" "/etc/systemd/system/reboot-if-needed.timer" 0644
install_root_file "${BASTION_DIR}/etc/systemd/system/apt-daily.timer.d/override.conf" "/etc/systemd/system/apt-daily.timer.d/override.conf" 0644
install_root_file "${BASTION_DIR}/etc/systemd/system/apt-daily-upgrade.timer.d/override.conf" "/etc/systemd/system/apt-daily-upgrade.timer.d/override.conf" 0644
install_root_file "${BASTION_DIR}/etc/apt/apt.conf.d/52unattended-upgrades-local" "/etc/apt/apt.conf.d/52unattended-upgrades-local" 0644

# 6. Reload systemd and enable timers + user harness service
echo "Reloading system systemd daemon and enabling timers..."
run_cmd sudo systemctl daemon-reload
run_cmd sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer reboot-if-needed.timer

echo "Reloading user systemd daemon and enabling gemini-harness.service..."
if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] sudo loginctl enable-linger ${TARGET_USER}"
else
    sudo loginctl enable-linger "$TARGET_USER" 2>/dev/null || true
fi
run_cmd systemctl --user daemon-reload
run_cmd systemctl --user enable --now gemini-harness.service

# 7. Merge crontab lines idempotently without duplicating
echo "Merging crontab entries..."
EXISTING_CRON="$(crontab -l 2>/dev/null || true)"
UPDATED_CRON="$EXISTING_CRON"

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    [ -z "$raw_line" ] && continue
    line="$(printf '%s' "$raw_line" | sed -e "s|/home/danipan|${TARGET_HOME}|g" -e "s|danipan|${TARGET_USER}|g")"
    alt_line="$(printf '%s' "$line" | sed -e 's|\$HOME|'"${TARGET_HOME}"'|g')"
    if ! printf '%s
' "$UPDATED_CRON" | grep -Fqx "$line" && ! printf '%s
' "$UPDATED_CRON" | grep -Fqx "$alt_line"; then
        if [ -n "$UPDATED_CRON" ]; then
            UPDATED_CRON="${UPDATED_CRON}"$'
'"${line}"
        else
            UPDATED_CRON="${line}"
        fi
    fi
done < "${BASTION_DIR}/crontab.txt"

if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] would install merged crontab:"
    printf '%s
' "$UPDATED_CRON"
else
    printf '%s
' "$UPDATED_CRON" | crontab -
fi

echo "Bastion setup complete."
