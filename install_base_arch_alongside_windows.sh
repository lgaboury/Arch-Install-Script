#!/bin/bash

##################################################################################################
#  IMPORTANT NOTES                                                                               #
##################################################################################################
# 1.  This script is very basic and specific to my SSD existing partitions and my wireless card. #
# 2.  It uses Windows 11 existing ESP partition and will install systemd-boot boot loader.       #
# 3.  It does not conduct any kind of error checking.                                            #
# 4.  Review the script entirely, adjust for your desired installation and use at your own risk. #
##################################################################################################

# stop reflector service in order to use specific parameters later
systemctl stop reflector.service

clear
echo "Starting Arch Linux base system installation..."
sleep 5

echo
echo "Enabling wifi..."
iwctl station wlan0 connect dlink
sleep 5

### Update the system clock
clear
echo "Updating system clock..."
timedatectl set-ntp true

sleep 5

### Parition the disk
#clear
#echo "Partitioning disk..."
#echo
#sgdisk -Z /dev/nvme0n1
#sgdisk -n 1:0:+300M -t 1:ef00 -n 2:0:+8G -t 2:8200 -n 3:0:0 -t 3:8300 /dev/nvme0n1
#echo
#sleep 5

### Format the partitions
clear
echo "Formatting partitions..."
echo
#mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p5
#mkswap /dev/nvme0n1p2

sleep 5

### Mount file systems
clear
echo "Mounting file systems..."
echo
mount /dev/nvme0n1p5 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
#swapon /dev/nvme0n1p2
echo
lsblk
sleep 5

### Show the mirrors
clear
echo "Configuring reflector..."
echo
reflector --download-timeout 30 --fastest 5 --age 8 --sort rate -c canada --protocol https --save /etc/pacman.d/mirrorlist
echo "Mirrors:"
echo
cat /etc/pacman.d/mirrorlist
sleep 5

### Install essential packages
clear
echo "Installing packages..."
echo
pacstrap /mnt base linux linux-firmware linux-headers intel-ucode sof-firmware \
	e2fsprogs bluez bluez-utils cups cups-pdf hplip system-config-printer \
	nano man-db man-pages ntfs-3g dosfstools networkmanager sudo pacman-contrib \
	nss-mdns pipewire-pulse avahi reflector inetutils neofetch bash-completion \
	mtools util-linux efibootmgr git base-devel xdg-user-dirs firewalld
    
### Set configration for newly installed packages
clear
echo "Setting configuration for newly installed packages..."
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

sleep 2
### Configure early Kernel Mode Setting and silence fsck
sed -i 's/MODULES=()/MODULES=(i915)/' /mnt/etc/mkinitcpio.conf
sed -i 's/HOOKS=(base udev/HOOKS=(base systemd/' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

### Generate fstab
clear
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
sleep 2

echo
cat /mnt/etc/fstab
sleep 10

### Set timezone
clear
echo "Setting timezone..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Winnipeg /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt timedatectl set-local-rtc 1
sleep 5

### Set localization
clear
echo "Setting localization..."
sed -i 's/#en_CA.UTF-8 UTF-8/en_CA.UTF-8 UTF-8/' /mnt/etc/locale.gen
sed -i 's/#fr_CA.UTF-8 UTF-8/fr_CA.UTF-8 UTF-8/' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_CA.UTF-8" > /mnt/etc/locale.conf
sleep 5

### Network configuration
clear
echo "Setting network configuration..."
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

# mkdir -p /mnt/mnt/NAS
# cat >> /mnt/etc/fstab <<EOF
# //NAS.local/luc	/mnt/NAS	cifs	rw,user=luc,pass=trapline,sec=ntlm,vers=1.0,uid=$username,_netdev,x-systemd.automount 0 0
# EOF
# sleep 5

### Set boot manager systemd-boot
clear
echo "Setting boot manager..."
arch-chroot /mnt bootctl install
cat > /mnt/boot/loader/loader.conf <<EOF
default		arch.conf
timeout		5
console-mode	max
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
sleep 5
umount -a
shutdown now
