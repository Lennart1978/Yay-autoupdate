#!/bin/bash
# yay-autoupdate version 1.1 install script
# 2025 by Lennart Martens

echo "Yay-autoupdate version 1.1 - installation:"

# Array containing the packages to check
packages=("zenity" "libnotify" "beep" "logrotate")

# Array to store missing packages
missing_packages=()

# Check each package to see if it is installed
for pkg in "${packages[@]}"; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        missing_packages+=("$pkg")
    fi
done

# If no packages are missing, inform the user and exit the script
if [ ${#missing_packages[@]} -eq 0 ]; then
    echo "All required packages are installed."
    exit 0
fi

# Display the missing packages
echo "The following packages are missing: ${missing_packages[*]}."

# Ask the user if they want to install the missing package(s)
read -rp "Do you want to install the missing package(s) using yay? (y/n): " answer

# Check the user's input and act accordingly
if [[ "$answer" =~ ^[Yy]$ ]]; then
    for pkg in "${missing_packages[@]}"; do
        yay -S "$pkg"
        if [ $? -ne 0 ]; then
            echo "An error occurred while installing $pkg."
            exit 1
        fi
    done
    echo "All missing packages have been successfully installed."
else
    echo "Installation aborted."
    exit 1
fi


# Path to the service file
SERVICE_FILE="yay-update.service"

# Check if the file exists
if [[ ! -f "$SERVICE_FILE" ]]; then
    echo "File '$SERVICE_FILE' not found."
    exit 1
fi

# Ask for the username
read -rp "Please enter your username: " newuser

# Check if a username was entered
if [[ -z "$newuser" ]]; then
    echo "No username entered. Aborting."
    exit 1
fi

# Replace the username in the service file
sed -i "s/User=lennart/User=$newuser/g" "$SERVICE_FILE"

echo "The username in '$SERVICE_FILE' has been successfully changed to '$newuser'."

# copy the Bash scripts for automatic update after boot
echo "Copying the Bash scripts"
cp -v yay-update.sh /usr/local/bin
cp -v show-updated.sh /usr/local/bin

#copy the config file for logrotate
sudo cp -v pacman /etc/logrotate.d

# Craete empty logfile
echo "Create empty logfile /tmp/yay-update.log"
> /tmp/yay-update.log

# Copy yay-update systemd service
echo "Copy the systemd service"
sudo cp -v yay-update.service /etc/systemd/system

# Enable NetworkManager-wait-online.service. This is necessary to make shure the connection is ready.
echo "Enable NetworkManager-wait-online.service"
sudo systemctl enable NetworkManager-wait-online.service

# Enable the service
echo "Enable the service"
sudo systemctl enable yay-update.service

# Testrun
echo "Let's start a testrun ... good luck !"
sudo systemctl start yay-update.sevice

# Show the status of the service
echo "Now show the status of the service, let's see if everything is OK"
sudo systemctl status yay-update.service

# Show final information
echo "Finished !"
echo "If there is no error message in the status, yay will perform an update after every boot now and there will be notifications and a summary about the update (if one was available)."
echo "Enjoy !"
