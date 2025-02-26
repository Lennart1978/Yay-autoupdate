#!/bin/bash
# Improved script to show updated packages

# Configuration variables
LOG_FILE="/tmp/yay-update.log"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yay-autoupdate"
CONFIG_FILE="$CONFIG_DIR/config"

# Load configuration if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Default configuration values
ZENITY_WIDTH="${ZENITY_WIDTH:-800}"
ICON_UPDATE="${ICON_UPDATE:-software-update-available}"
ICON_NONE="${ICON_NONE:-face-surprise-symbolic}"
NO_UPDATES_MSG="${NO_UPDATES_MSG:-No updates available at the moment!}"

# Check if log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    zenity --error --icon=dialog-error \
           --text="Couldn't find log file $LOG_FILE!" 2>/dev/null
    exit 1
fi

# Extract updated packages with version information
# Look for lines containing " -> " which indicate a version change
mapfile -t updated_pkgs < <(grep -E '[[:space:]][0-9]+[[:space:]]+.*[[:space:]]+->([[:space:]]+|$)' "$LOG_FILE" | 
                           awk '{
                               # Extract package name, old version, new version
                               package=$2
                               # Remove leading/trailing whitespace from versions
                               gsub(/^[ \t]+/, "", $3)
                               gsub(/[ \t]+$/, "", $5)
                               # Format output
                               print package "  " $3 " → " $5
                           }')

# Check if any packages were updated
if [[ ${#updated_pkgs[@]} -eq 0 ]]; then
    zenity --info --icon="$ICON_NONE" --text="$NO_UPDATES_MSG" 2>/dev/null
    exit 0
fi

# Display updated packages
zenity --info \
       --title="System Update Summary" \
       --text="${#updated_pkgs[@]} updated packages:\n\n$(printf '%s\n' "${updated_pkgs[@]}")" \
       --width="$ZENITY_WIDTH" \
       --ellipsize \
       --icon="$ICON_UPDATE" 2>/dev/null

exit 0
