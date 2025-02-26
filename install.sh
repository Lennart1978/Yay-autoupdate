#!/bin/bash
# Improved yay-autoupdate installation script

set -e  # Exit on error

# Print banner
echo "============================================"
echo "Yay-autoupdate version 1.2 - Installation"
echo "============================================"

# Configuration
SERVICE_FILE="yay-update.service"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yay-autoupdate"
CONFIG_FILE="$CONFIG_DIR/config"
REQUIRED_PACKAGES=("zenity" "libnotify" "beep" "logrotate")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Function to backup a file
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.bak-$(date +%Y%m%d%H%M%S)"
        echo "Backing up $file to $backup"
        cp -f "$file" "$backup"
    fi
}

# Check if pacman exists (ensure we're on Arch-based system)
if ! command_exists pacman; then
    echo "Error: This script requires pacman. Are you running an Arch-based system?"
    exit 1
fi

# Check if yay exists
if ! command_exists yay; then
    echo "Error: This script requires yay to be installed."
    echo "Please install yay first and run this script again."
    exit 1
fi

# Check for missing packages
missing_packages=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        missing_packages+=("$pkg")
    fi
done

# Install missing packages if needed
if [[ ${#missing_packages[@]} -gt 0 ]]; then
    echo "The following packages are missing: ${missing_packages[*]}"
    
    read -rp "Do you want to install the missing package(s) using yay? (y/n): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        for pkg in "${missing_packages[@]}"; do
            if ! yay -S --needed "$pkg"; then
                echo "Error: Failed to install $pkg"
                exit 1
            fi
        done
        echo "All missing packages have been successfully installed."
    else
        echo "Installation aborted."
        exit 1
    fi
else
    echo "All required packages are installed."
fi

# Create config directory
mkdir -p "$CONFIG_DIR"

# Create default config file if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << EOF
# Yay-autoupdate configuration file

# String to check for "no updates needed" - localize this to your system's language
NOTHING_TO_DO_STRING="there is nothing to do"

# Notification settings
NOTIFICATION_TIMEOUT=3000
ICON_SUCCESS="object-select-symbolic"
ICON_ERROR="dialog-error-symbolic"
ICON_INFO="dialog-information-symbolic"
SOUND_START="service-login"
SOUND_ERROR="dialog-error"
SOUND_SUCCESS="complete"
SOUND_INFO="dialog-information"

# Update behavior
BEEP_FREQUENCY=2000
CLEAN_CACHE=true
PERFORM_LOGROTATE=true

# Zenity settings
ZENITY_WIDTH=800
ICON_UPDATE="software-update-available"
ICON_NONE="face-surprise-symbolic"
NO_UPDATES_MSG="No updates available at the moment!"
EOF
    echo "Created default configuration file: $CONFIG_FILE"
fi

# Check if service file exists
if [[ ! -f "$SERVICE_FILE" ]]; then
    echo "Error: Service file '$SERVICE_FILE' not found in the current directory."
    exit 1
fi

# Function to get user ID from username
get_uid() {
    id -u "$1" 2>/dev/null
}

# Ask for and validate username
while true; do
    read -rp "Please enter your username: " username
    
    if [[ -z "$username" ]]; then
        echo "Error: No username entered."
        continue
    fi
    
    user_id=$(get_uid "$username")
    if [[ -z "$user_id" ]]; then
        echo "Error: User '$username' does not exist. Please enter a valid username."
        continue
    fi
    
    break
done

# Create a temporary modified service file
tmp_service=$(mktemp)
cp "$SERVICE_FILE" "$tmp_service"

# Update the service file with the username and UID
sed -i "s/User=lennart/User=$username/g" "$tmp_service"
sed -i "s|Environment=DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000|Environment=DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/$user_id|g" "$tmp_service"

echo "Service file updated with username: $username and UID: $user_id"

# Install option menu
echo
echo "Installation options:"
echo "1. Install"
echo "2. Uninstall"
echo "3. Exit"
read -rp "Select an option [1]: " install_option
install_option=${install_option:-1}

case $install_option in
    1)
        # Install the scripts
        echo "Installing scripts..."
        sudo cp -v "$SCRIPT_DIR/yay-update.sh" /usr/local/bin/yay-update.sh
        sudo cp -v "$SCRIPT_DIR/show-updated.sh" /usr/local/bin/show-updated.sh
        
        # Make them executable
        sudo chmod +x /usr/local/bin/yay-update.sh /usr/local/bin/show-updated.sh
        
        # Install the logrotate config
        echo "Installing logrotate configuration..."
        sudo cp -v "$SCRIPT_DIR/pacman" /etc/logrotate.d/
        
        # Create empty log file
        echo "Creating empty log file /tmp/yay-update.log"
        > /tmp/yay-update.log
        
        # Install and enable the service
        echo "Installing systemd service..."
        sudo cp -v "$tmp_service" /etc/systemd/system/yay-update.service
        
        echo "Enabling NetworkManager-wait-online.service..."
        sudo systemctl enable NetworkManager-wait-online.service
        
        echo "Enabling yay-update.service..."
        sudo systemctl enable yay-update.service
        
        # Test run
        echo "Starting a test run..."
        sudo systemctl start yay-update.service
        
        # Show service status
        echo "Service status:"
        sudo systemctl status yay-update.service
        
        echo 
        echo "Installation completed successfully!"
        echo "The system will now automatically update after each boot."
        echo "Configuration file: $CONFIG_FILE"
        echo "Log file: /tmp/yay-update.log"
        ;;
    2)
        # Uninstall
        echo "Uninstalling..."
        
        echo "Stopping and disabling service..."
        sudo systemctl stop yay-update.service 2>/dev/null || true
        sudo systemctl disable yay-update.service 2>/dev/null || true
        
        echo "Removing files..."
        sudo rm -f /etc/systemd/system/yay-update.service
        sudo rm -f /usr/local/bin/yay-update.sh
        sudo rm -f /usr/local/bin/show-updated.sh
        
        echo "Uninstallation completed."
        ;;
    3)
        echo "Exiting without changes."
        ;;
    *)
        echo "Invalid option. Exiting."
        ;;
esac

# Clean up the temporary file
rm -f "$tmp_service"

exit 0
