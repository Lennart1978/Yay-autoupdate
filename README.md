# Yay-autoupdate v1.0
Archlinux Yay automatic update Systemd service. The Systemd service "yay-update.service" is configured for Gnome / Wayland, but it can easily be adjusted for other systems as well.

## Installation:

``` bash
./install
```

Just execute the install script and if you get an error during boot, you have to adjust "sleep 5" in /usr/local/bin/yay-update.sh and show-updated.sh.
Increase it from 5 to 8 or 10 or even higher. It depends on how fast your internet connetion is ready. I have a fast boot with cable connection, so 'sleep 5' is perfect for me.
Leave a star if you like this work :-)
