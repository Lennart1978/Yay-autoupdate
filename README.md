# Yay-autoupdate v1.2

Automatic update system for Arch Linux using Yay. This systemd service will automatically update your system after boot, providing notifications and a summary of updates.

## Features

- **Automatic Updates**: System updates automatically after boot
- **Visual and Audio Notifications**: Get notifications with sounds for different events
- **Update Summary**: Detailed summary of all updated packages
- **Configurable**: Easy to configure through a config file
- **Cache Cleaning**: Automatically cleans pacman and yay cache
- **Log Rotation**: Performs log rotation on pacman logs

## Requirements

The following packages are required:
- `yay`: For AUR package management
- `zenity`: For displaying the updates summary
- `libnotify`: For desktop notifications
- `beep`: For audio alerts
- `logrotate`: For log rotation

The installation script will check for these dependencies and offer to install missing packages.

## Installation

```bash
./install.sh
```

The installer will guide you through the process and offers options to install or uninstall.

## Configuration

A configuration file is created at `~/.config/yay-autoupdate/config` where you can customize:

- Notification settings
- Icons and sounds
- Update behavior
- Display settings
- Localization for your language

### Language Configuration

**Important**: If yay's output is not in English, you need to change the `NOTHING_TO_DO_STRING` in the configuration file to match your language's equivalent for "there is nothing to do".

## Sudo Configuration (Optional)

If you encounter permission issues, you may want to configure passwordless sudo. This represents a security risk and should be carefully considered:

```bash
sudo visudo
```

Add this line (replace USERNAME with your actual username):
```
USERNAME ALL=(ALL) NOPASSWD: ALL
```

## Logs

Detailed information about updates is stored in `/tmp/yay-update.log`

## Uninstallation

To uninstall:
```bash
./install.sh
```
Then select option 2 for uninstallation.

## Security Considerations

- This script runs with sudo privileges to perform system updates
- Consider the security implications of automatic updates and passwordless sudo
- This is primarily designed for personal desktop systems with a single user

---

2025 by Lennart Martens  
