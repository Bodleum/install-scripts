#!/bin/bash

# Get stuff
echo "Hostname?"
read hostname

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into installation
arch-chroot /mnt

# Set timezone
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

# Locale
sed -i 's/#en_GB/en_GB/g' /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" >> /etc/locale.conf
echo "KEYMAP=dvorak" >> /etc/vconsole.conf

# Network
echo $hostname >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo ":1        localhost" >> /etc/hosts
echo "127.0.0.1 "$hostname".localdomain "$hostname >> /etc/hosts

# Change root password
passwd
