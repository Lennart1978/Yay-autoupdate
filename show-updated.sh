#!/bin/bash

log_file="/tmp/yay-update.log"

if [ ! -f "$log_file" ]; then
    zenity --error --icon=dialog-error --text="Logdatei $log_file nicht gefunden !" 2>&1 > /dev/null
    exit 1
fi

# Korrigierter regulärer Ausdruck für führende Leerzeichen vor der Zahl
mapfile -t updated_pkgs < <(grep -E '^[[:space:]]*[0-9]+[[:space:]]+.* -> ' "$log_file" | awk '{gsub(/^[ \t]+/, "", $3); gsub(/[ \t]+$/, "", $5); print $2 "  " $3 " → " $5}')

if [ ${#updated_pkgs[@]} -eq 0 ]; then
    zenity --info --icon=/usr/share/icons/Adwaita/symbolic/emotes/face-surprise-symbolic.svg --text="Momentan keine Updates verfügbar" 2>&1 > /dev/null
    exit 0
fi

# Anzahl der Pakete hinzufügen
zenity --info \
       --text="${#updated_pkgs[@]} aktualisierter Pakete:\n\n$(printf '%s\n' "${updated_pkgs[@]}")" \
       --width=800 \
       --ellipsize \
       --icon=software-update-available 2>&1 > /dev/null
