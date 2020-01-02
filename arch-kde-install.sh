#!/bin/bash
# This script can be run by executing the following:
#   curl -sL https://raw.githubusercontent.com/lgaboury/Arch-Insall-Script/master/arch-install.sh?token=AL7XRY6CVWVAPU6AS4ONFX26AEH5Q | bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

clear
echo "Starting Arch KDE installation..."
sleep 2

### Connect to the internet ###
echo
echo "Connecting to wifi..."
echo
read -p "Enter wifi SSIS: " ssid
read -sp "Enter passphrase for $ssid: " ssidpass
echo
nmcli device wifi connect "$ssid" password "$ssidpass"
sleep 5

### Set timezone ###
echo
echo "Setting timezone..."
ln -sf /usr/share/zoneinfo/Canada/Central /etc/localtime
hwclock --systohc

### Install desired KDE packages ###
echo
echo "Installing KDE packages..."
echo
pacman -S sddm sddm-kcm plasma ark dolphin kdf firefox konsole kate okular print-manager \
    yakuake breeze breeze-gtk ksysguard system-config-printer partitionmanager kpatience \
    digikam gwenview skanlite packagekit-qt5 kio-gdrive kamoso
    
clear
    
### Enable required services
echo
echo "Enabling services..."
echo ""
systemctl enable sddm.service

echo
echo "Installation complete, rebooting..."
sleep 5
reboot
