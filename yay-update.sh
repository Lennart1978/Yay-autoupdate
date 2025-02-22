#!/bin/bash
# File: /usr/local/bin/yay-update.sh

set -euo pipefail  # Stoppt bei Fehlern, undefinierten Variablen

LOG="/tmp/yay-update.log"

# Lösche Inhalt der Logdatei
> "$LOG"

# Lockfile verhindert parallele Ausführung
LOCK="/tmp/yay-update.lock"
exec 9>"$LOCK"
flock -n 9 || exit 1

# Benachrichtigungs-ID korrekt erfassen
ID=$(notify-send --print-id -t 1000 -u normal -a Yay --hint=string:sound-name:service-login 'Yay Update' 'Starting system update ...')

# Log mit Header
echo -e "\n$(date): === Update gestartet ===" >> "$LOG"

# Systemupdate
if ! yay --noconfirm --sudoloop --needed 2>&1 | tee -a "$LOG"; then
    beep -f 2000 
    notify-send -r "$ID" -t 5000 -u critical -a Yay -i /usr/share/icons/Adwaita/symbolic/status/computer-fail-symbolic.svg --hint=string:sound-name:dialog-error 'Yay Update' 'Fehler beim Update! Siehe Log.'
    exit 1
fi

# Keine Updates nötig
if grep -q "es gibt nichts zu tun" "$LOG"; then
    notify-send -r "$ID" -t 3000 -u normal -a Yay --hint=string:sound-name:dialog-information 'Yay Update' 'System ist aktuell !'
    exit 0
fi

# Cache säubern
echo "$(date): Bereinige Cache..." >> "$LOG"
yay -Scc --noconfirm 2>&1 | tee -a "$LOG"
sudo rm -fv /var/cache/pacman/pkg/* >> "$LOG"

# Logrotate Pacman Logdatei
sudo logrotate -f -v /etc/logrotate.d/pacman 2>&1 | tee -a "$LOG"

# Erfolgsbenachrichtigung
notify-send -r "$ID" -t 3000 -u normal -a Yay --hint=string:sound-name:complete 'Yay Update' 'Update erfolgreich !'

# Die aktualisierten Pakete in einem Zenity - Info Dialog anzeigen
show-updated.sh
