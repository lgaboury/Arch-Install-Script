#!/bin/bash
# This script can be run by executing the following:
#   curl -sL https://raw.githubusercontent.com/lgaboury/Arch-Insall-Script/master/arch-install.sh?token=AL7XRY6CVWVAPU6AS4ONFX26AEH5Q | bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

### Connect to the internet ###
wifi-menu
sleep 5

### Update the system clock ###
echo "Updating system clock..."
timedatectl set-ntp true

### Parition the disk ###
echo "Partitioning disk..."
parted --script /dev/sda \
    mklabel gpt \
    mkpart primary fat32 1Mib 100MiB \
    set 1 esp on \
    mkpart primary linux-swap 100MiB 10GiB \
    mkpart primary btrfs 10GiB 100%

### Format the partitions ###
echo "Formatting partitions..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda3
mkswap /dev/sda2
swapon /dev/sda2

### Mount the file systems ###
echo "Mounting file systems..."
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

### Select the mirrors ####
echo "Setting mirrors..."
MIRRORLIST_URL="https://www.archlinux.org/mirrorlist/?country=CA&protocol=https&use_mirror_status=on"
pacman -Sy --noconfirm pacman-contrib
curl -s "$MIRRORLIST_URL" | \
    sed -e 's/^#Server/Server/' -e '/^#/d' | \
    rankmirrors -n 5 - > /etc/pacman.d/mirrorlist
sed -i 's/#TotalDownload/TotalDownload' /etc/pacman.conf

### Install essential packages ###
echo "Installing packages..."
pacstrap /mnt base linux-lts linux-firmware nano man-db man-pages ntfs-3g networkmanager sudo \
    pacman-contrib sddm sddm-kcm plasma ark dolphin kdf firefox konsole kate okular print-manager \
    yakuake nss-mdns breeze breeze-gtk cups cups-pdf firewalld hplip intel-ucode ksysguard \
    pulseaudio-bluetooth system-config-printer
    
### Set configration for newly installed packages ###
echo "Setting configuration..."
sed -i 's/#TotalDownload/TotalDownload' /mnt/etc/pacman.conf
sed -i 's/resolve [!UNAVAIL=return] dns/mdns_minimal [NOTFOUND=return] ' /mnt/etc/nsswitch.conf
sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL' /mnt/etc/sudoers

### Generate fstab ###
echo "Generating fstab..."
genfstab -t PARTUUID /mnt >> /mnt/etc/fstab

### Set timezone ###
echo "Setting timezone..."
ln -sf /mnt/usr/share/zoneinfo/Canada/Central /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc

### Set localization ###
echo "Setting localization..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

### Network configuration ###
echo "Setting network configuration..."
echo "acer-e5-575g" > /mnt/etc/hostname
cat >>/mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   acer-e5-575g.localdomain    acer-e5-575g
EOF

### Set boot loader ###
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
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda3) rw quiet i915.fastboot=1
EOF

#### Set password ###
echo "Setting root password..."
echo "root:Ga3our&01" | chpasswd --root /mnt

#### Set sudo ####
echo "Setting sudo..."
sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL' /mnt/etc/sudoers

### Enable required services
echo "Enabling services..."
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable sddm.service
arch-chroot /mnt systemctl enable org.cups.cupsd.service
arch-chroot /mnt systemctl enable bluetooth.service
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl enable firewalld.service
arch-chroot /mnt systemctl enable bluetooth.service

### Create user ###
echo "Creating user..."
arch-chroot /mnt useradd -m -G wheel lgaboury
echo "lgaboury:trapline" | chpasswd --root /mnt
