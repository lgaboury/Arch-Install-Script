#!/bin/bash
# This script can be run by executing the following:
#   curl -sL https://raw.githubusercontent.com/lgaboury/Arch-Insall-Script/master/arch-install.sh?token=AL7XRY6CVWVAPU6AS4ONFX26AEH5Q | bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

clear
echo "Starting Arch Linux base system installation..."
sleep 2

### Connect to the internet ###
echo
wifi-menu
echo "Waiting for connection to internet..."
sleep 10
echo

### Update the system clock ###
echo
echo "Updating system clock..."
timedatectl set-ntp true

### Parition the disk ###
echo
echo "Partitioning disk..."
parted --script /dev/sda \
    mklabel gpt \
    mkpart ESP fat32 1Mib 100MiB \
    set 1 esp on \
    mkpart Linux btrfs 100MiB 228GiB \
    mkpart SWAP linux-swap 228GiB 100%

sleep 2
    
### Format the partitions ###
echo
echo "Formatting partitions..."
mkfs.fat -F32 /dev/sda1
sleep 1
mkfs.btrfs -f /dev/sda2
sleep 1
mkswap /dev/sda3
sleep 1
swapon /dev/sda3
sleep 1

### Mount file sysstems ###
echo
echo "Mounting file systems..."
mount /dev/sda2 /mnt
sleep 1
btrfs subvolume create /mnt/@
sleep 1
btrfs subvolume create /mnt/@home
sleep 1
umount -R /mnt
sleep 1
mount /dev/sda2 /mnt -o subvol=@
sleep 1
mkdir /mnt/boot
sleep 1
mkdir /mnt/home
sleep 1
mount /dev/sda2 /mnt/home -o subvol=@home
sleep 1
mount /dev/sda1 /mnt/boot
sleep 1

### Select the mirrors ####
echo
echo "Setting and ranking mirrors..."
echo
pacman -Sy --noconfirm reflector
reflector --country CA --country US --age 24 --protocol https --fastest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -i 's/#TotalDownload/TotalDownload/' /etc/pacman.conf
echo
echo "Resulting mirrors:"
cat /etc/pacman.d/mirrorlist
sleep 10
clear

### Install essential packages ###
echo
echo "Installing packages..."
echo
pacstrap /mnt base linux linux-firmware intel-ucode btrfs-progs nano man-db man-pages ntfs-3g networkmanager sudo \
    pacman-contrib nss-mdns cups cups-pdf hplip firewalld xdg-user-dirs bluez pulseaudio-bluetooth avahi reflector
    
### Set configration for newly installed packages ###
echo
echo "Setting configuration..."
sed -i 's/#TotalDownload/TotalDownload/' /mnt/etc/pacman.conf
sed -i 's/resolve/mdns_minimal [NOTFOUND=return] resolve/' /mnt/etc/nsswitch.conf
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers

### Generate fstab ###
echo
echo "Generating fstab..."
sleep 2
genfstab -t UUID /mnt >> /mnt/etc/fstab

### Set localization ###
echo
echo "Setting localization..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

### Network configuration ###
echo
echo "Setting network configuration..."
echo "acer-e5-575g" > /mnt/etc/hostname
cat >>/mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   acer-e5-575g.localdomain    acer-e5-575g
EOF

### Set boot loader ###
echo
echo "Setting boot loader..."
arch-chroot /mnt bootctl --path=/boot install
mkdir /mnt/etc/pacman.d/hooks
cat >>/mnt/etc/pacman.d/hooks/100-systemd-boot.hook <<EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd
[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF

cat >>/mnt/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/sda2) rw quiet rootflags=subvol=@ i915.fastboot=1
EOF

### Blacklist problem modules for Acer E5 575G
echo
echo "Blacklisting modules..."
cat >>/mnt/etc/modprobe.d/blacklist.conf <<EOF
### Blackiling problem modules for Acer E5 575G
blacklist dell_laptop
blacklist nouveau
EOF

### Configure early Kernel Mode Setting
echo
echo "Configuring early Kernel Mode Setting..."
echo
sed -i 's/MODULES=()/MODULES=(i915)/' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

#### Set password ###
echo
echo "Setting root password..."
read -sp 'Enter root password: ' rootpass
echo "root:$rootpass" | chpasswd --root /mnt

#### Set sudo ####
echo
echo "Setting sudo..."
sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers

### Enable required services
echo
echo "Enabling services..."
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable org.cups.cupsd.service
arch-chroot /mnt systemctl enable bluetooth.service
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl enable firewalld.service
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl disable systemd-resolved.service

### Create user ###
echo
echo "Creating user..."
echo
read -p "Enter username: " username
echo
read -sp "Enter password for $username: " userpass
arch-chroot /mnt useradd -m -G wheel $username
echo "$username:$userpass" | chpasswd --root /mnt

echo
echo "Installation complete, shutting down..."
#sleep 5
#umount -R /mnt
#shutdown now
