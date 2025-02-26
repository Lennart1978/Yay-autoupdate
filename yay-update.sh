#!/bin/bash
# File: /usr/local/bin/yay-update.sh
# Improved Yay auto-update script

# Robust error handling
set -euo pipefail

# Configuration variables
LOG="/tmp/yay-update.log"
LOCK="/tmp/yay-update.lock"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yay-autoupdate"
CONFIG_FILE="$CONFIG_DIR/config"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Load configuration if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Default configuration values
NOTHING_TO_DO_STRING="${NOTHING_TO_DO_STRING:-there is nothing to do}"
NOTIFICATION_TIMEOUT="${NOTIFICATION_TIMEOUT:-3000}"
ICON_SUCCESS="${ICON_SUCCESS:-object-select-symbolic}"
ICON_ERROR="${ICON_ERROR:-dialog-error-symbolic}"
ICON_INFO="${ICON_INFO:-dialog-information-symbolic}"
SOUND_START="${SOUND_START:-service-login}"
SOUND_ERROR="${SOUND_ERROR:-dialog-error}"
SOUND_SUCCESS="${SOUND_SUCCESS:-complete}"
SOUND_INFO="${SOUND_INFO:-dialog-information}"
BEEP_FREQUENCY="${BEEP_FREQUENCY:-2000}"
CLEAN_CACHE="${CLEAN_CACHE:-true}"
PERFORM_LOGROTATE="${PERFORM_LOGROTATE:-true}"

# Log function
log() {
    echo "$(date): $1" >> "$LOG"
}

# Clean log file
> "$LOG"

# Use lockfile to prevent parallel execution
exec 9>"$LOCK"
if ! flock -n 9; then
    log "Another instance is already running. Exiting."
    exit 0
fi

# Log start
log "=== Update started ==="

# Send notification
ID=$(notify-send --print-id -t "$NOTIFICATION_TIMEOUT" -u normal -a "Yay Update" \
    --hint=string:sound-name:"$SOUND_START" "Yay Update" "Starting system update...")

# Run system update
if ! yay --noconfirm --sudoloop --needed 2>&1 | tee -a "$LOG"; then
    beep -f "$BEEP_FREQUENCY" || true
    notify-send -r "$ID" -t "$NOTIFICATION_TIMEOUT" -u critical -a "Yay Update" \
        -i "$ICON_ERROR" --hint=string:sound-name:"$SOUND_ERROR" \
        "Yay Update" "Error during update! See log at $LOG"
    log "=== Update failed ==="
    exit 1
fi

# Check if there were any updates
if grep -qi "$NOTHING_TO_DO_STRING" "$LOG"; then
    notify-send -r "$ID" -t "$NOTIFICATION_TIMEOUT" -u normal -a "Yay Update" \
        -i "$ICON_INFO" --hint=string:sound-name:"$SOUND_INFO" \
        "Yay Update" "System is up to date!"
    log "=== No updates needed ==="
    exit 0
fi

# Clean cache if enabled
if [[ "$CLEAN_CACHE" == "true" ]]; then
    log "Cleaning cache..."
    if ! yay -Scc --noconfirm 2>&1 | tee -a "$LOG"; then
        log "Cache cleanup failed"
    fi
    
    if ! sudo rm -fv /var/cache/pacman/pkg/* >> "$LOG" 2>&1; then
        log "Failed to clean pacman cache"
    fi
fi

# Perform logrotate if enabled
if [[ "$PERFORM_LOGROTATE" == "true" ]]; then
    log "Rotating pacman logs..."
    if ! sudo logrotate -f -v /etc/logrotate.d/pacman 2>&1 | tee -a "$LOG"; then
        log "Logrotate failed"
    fi
fi

# Success notification
notify-send -r "$ID" -t "$NOTIFICATION_TIMEOUT" -u normal -a "Yay Update" \
    -i "$ICON_SUCCESS" --hint=string:sound-name:"$SOUND_SUCCESS" \
    "Yay Update" "Update successful!"

# Show updated packages
/usr/local/bin/show-updated.sh

log "=== Update completed successfully ==="
exit 0
