#!/bin/bash
# This script can be run by executing the following:
#   curl -sL https://raw.githubusercontent.com/lgaboury/Arch-Insall-Script/master/arch-install.sh?token=AL7XRY6CVWVAPU6AS4ONFX26AEH5Q | bash
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

### Connect to the internet ###
wifi-menu
sleep 5

### Update the system clock ###
timedatectl set-ntp true

### Parition the disk ###
parted --script /dev/sda \
    mklabel gpt \
    mkpart primary fat32 1Mib 100MiB \
    set 1 esp on \
    mkpart primary linux-swap 100MiB 10GiB \
    mkpart primary btrfs 10GiB 100%

### Format the partitions ###
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda3
mkswap /dev/sda2
swapon /dev/sda2

### Mount the file systems ###
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

### Select the mirrors ####
MIRRORLIST_URL="https://www.archlinux.org/mirrorlist/?country=CA&protocol=https&use_mirror_status=on"
pacman -Sy --noconfirm pacman-contrib
curl -s "$MIRRORLIST_URL" | \
    sed -e 's/^#Server/Server/' -e '/^#/d' | \
    rankmirrors -n 5 - > /etc/pacman.d/mirrorlist
sed -i 's/#TotalDownload/TotalDownload' /etc/pacman.conf

### Install essential packages ###
pacstrap /mnt base linux-lts linux-firmware nano man-db man-pages ntfs-3g networkmanager sudo \
    pacman-contrib sddm sddm-kcm plasma ark dolphin kdf firefox konsole kate okular print-manager \
    yakuake nss-mdns breeze breeze-gtk cups cups-pdf firewalld hplip intel-ucode ksysguard \
    pulseaudio-bluetooth system-config-printer
sed -i 's/#TotalDownload/TotalDownload' /mnt/etc/pacman.conf

### Generate fstab ###
genfstab -t PARTUUID /mnt >> /mnt/etc/fstab

### Set timezone ###
ln -sf /mnt/usr/share/zoneinfo/Canada/Central /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc

### Set localization ###
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

### Network configuration ###
echo "acer-e5-575g" > /mnt/etc/hostname
cat >>/mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   acer-e5-575g.localdomain    acer-e5-575g
EOF

#### Set password ###
echo "root:Ga3our&01" | chpasswd --root /mnt

#### Set sudo ####
sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL' /mnt/etc/sudoers

### Enable required services
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable sddm.service
arch-chroot /mnt systemctl enable org.cups.cupsd.service
arch-chroot /mnt systemctl enable bluetooth.service
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl enable firewalld.service
arch-chroot /mnt systemctl enable bluetooth.service

### Create user ###
arch-chroot /mnt useradd -mU -s /usr/bin/zsh -G wheel,uucp,video,audio,storage,games,input "$user"
arch-chroot /mnt chsh -s /usr/bin/zsh
echo "$user:$password" | chpasswd --root /mnt
