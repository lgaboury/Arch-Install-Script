#!/bin/bash

##################################################################################################
# IMPORTANT NOTES                                                                                #
##################################################################################################
# 1.  This script is very basic and specific to my Laptop hardware and SSD existing partitions.  #
# 2.  It uses Windows 11 existing ESP partition and will install systemd-boot boot loader.       #
# 3.  It does not conduct any kind of error checking.                                            #
# 4.  Review the script entirely, adjust for your desired installation and use at your own risk. #
##################################################################################################

# stop reflector service in order to use specific parameters later
systemctl stop reflector.service

clear
echo "Starting Arch Linux base system installation..."
sleep 5

### Update the system clock
clear
echo "Updating system clock..."
echo
timedatectl set-ntp true
sleep 5

### Format the partitions
clear
echo "Formatting partitions..."
echo
mkfs.ext4 /dev/nvme0n1p5
sleep 5

### Mount file systems
clear
echo "Mounting file systems..."
echo
mount /dev/nvme0n1p5 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
echo
# Show resulting block devices
lsblk
sleep 5

### Update and show mirrors
clear
echo "Configuring reflector..."
echo
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
reflector --download-timeout 30 --fastest 5 --age 8 --sort rate -c canada --protocol https --save /etc/pacman.d/mirrorlist
echo "Mirrors:"
echo
cat /etc/pacman.d/mirrorlist
sleep 5

### Update pacman databases and keyring
clear
echo "Update pacman databases and keyring..."
echo
pacman -Sy
pacman -S archlinux-keyring
sleep 5

### Install essential packages
clear
echo "Installing packages..."
echo
pacstrap /mnt base linux linux-firmware linux-headers intel-ucode sof-firmware \
	e2fsprogs bluez bluez-utils cups cups-pdf hplip system-config-printer \
	nano man-db man-pages ntfs-3g dosfstools networkmanager sudo pacman-contrib \
	nss-mdns pipewire-pulse avahi reflector inetutils neofetch bash-completion \
	mtools util-linux efibootmgr git base-devel xdg-user-dirs firewalld intel-media-driver
sleep 5

### Set configration for newly installed packages
clear
echo "Setting configuration for newly installed packages..."
echo
sed -i 's/resolve/mdns4_minimal [NOTFOUND=return] resolve/' /mnt/etc/nsswitch.conf
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
cp reflector.conf /mnt/etc/xdg/reflector/reflector.conf
### Enable services
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable bluetooth.service
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable reflector.timer
arch-chroot /mnt systemctl enable firewalld.service
arch-chroot /mnt systemctl disable systemd-resolved.service
arch-chroot /mnt systemctl enable cups.service
### Configure early Kernel Mode Setting and silence fsck
sed -i 's/MODULES=()/MODULES=(i915)/' /mnt/etc/mkinitcpio.conf
sed -i 's/HOOKS=(base udev/HOOKS=(base systemd/' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P
sleep 5

### Generate fstab
clear
echo "Generating fstab..."
echo
genfstab -U /mnt >> /mnt/etc/fstab
sleep 2
echo
cat /mnt/etc/fstab
sleep 5

### Set timezone
clear
echo "Setting timezone..."
echo
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Winnipeg /etc/localtime
arch-chroot /mnt hwclock --systohc
sleep 5

### Set localization
clear
echo "Setting localization..."
echo
sed -i 's/#en_CA.UTF-8 UTF-8/en_CA.UTF-8 UTF-8/' /mnt/etc/locale.gen
sed -i 's/#fr_CA.UTF-8 UTF-8/fr_CA.UTF-8 UTF-8/' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_CA.UTF-8" > /mnt/etc/locale.conf
sleep 5

### Network configuration
clear
echo "Setting network configuration..."
echo
echo "arch-hp14ea1030ca" > /mnt/etc/hostname
cat >> /mnt/etc/hosts <<EOF
127.0.0.1       localhost
::1             localhost
127.0.1.1       arch-hp14ea1030ca
EOF
sleep 5

### Set root password
clear
echo "Setting root password..."
echo
arch-chroot /mnt passwd root
sleep 5

### Create user
clear
echo "Creating user..."
echo
read -p "Enter username: " username
echo
arch-chroot /mnt useradd -m -G wheel,input $username
echo "Setting password for $username..."
arch-chroot /mnt passwd $username

### Set boot manager systemd-boot
clear
echo "Setting boot manager..."
echo
arch-chroot /mnt bootctl install
cat > /mnt/boot/loader/loader.conf <<EOF
default		arch.conf
timeout		5
console-mode	auto
editor		yes
EOF

cat > /mnt/boot/loader/entries/arch.conf <<EOF
title	Arch Linux
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/nvme0n1p5) rw quiet loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3
EOF
arch-chroot /mnt systemctl enable systemd-boot-update.service
sleep 5

clear
echo "Installation complete, shutting down..."
echo
sleep 5
umount -a
shutdown now
