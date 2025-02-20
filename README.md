# Yay-autoupdate v1.0
Archlinux Yay automatic update Systemd service. The Systemd service "yay-update.service" is configured for Gnome / Wayland, but it can easily be configured for other systems as well.
When notifications popup, you will hear different sounds (soundcard). The system update starts with a low beep from the speaker, error notifications popup with a high beep.
In case of available updates, a list of all the updated packages with version informations will appear in a Zenity - info dialog at the center of your screen.

## Requirements:
The following packages need to be installed:
"zenity", "libnotify"and "beep".
If you don't have them installed, the install script notices it and will ask you whether you want to install the missing packages now.
## Is the output from yay in english ? Then you don't have to change anything. If not, then translate the string "there is nothing to do" in yay-update.sh line 33 to your yay's output language first !
```bash
yay -S zenity libnotify beep
```

## Installation:

``` bash
./install
```
It depends on how fast your internet connetion is ready.
Just execute the install script and if you get an error during boot, you have to adjust "sleep 5" in /usr/local/bin/yay-update.sh and show-updated.sh.
Increase it from 5 to 8 or 10 or even higher. I have a fast boot with cable connection, so 'sleep 5' is perfect for me.
Leave a star if you like this good work, that always makes me happy :-)

## Screenshots (Gnome / Wayland):

Starting system update... - notification after boot:
![start](start.png)
System is uptodate ! (It's German language on the screenshots, on GitHub it's all in English):
![uptodate](noupdate.png)
Update succesful and 2 packages were updated: - notification and Zenity info dialog
![successful](updatesuccessful.png)
3 packages were updated - shown with Zenity info dialog
![3packages](3packages.png)

2025 Lennart Martens
