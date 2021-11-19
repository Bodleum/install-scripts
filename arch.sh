#!/bin/bash

# Make sure the script is run as root
if [ $EUID -ne 0]; then
    echo -e "\033[0;31mThis script must be run as root!\033[0m"
    exit 1
fi

#############
# Get input #
#############
# Hostname
echo "Hostname:"
read hostname
# Username and password
echo "Username for account:"
read name
while ! echo $name | grep -q "^[a-z_][a-z0-9_-]*$"; do
    echo "Invalid username. Must start with a letter, and contain only lowercase letters, numbers, _ or -."
    read name
done
echo "Password for "$name
read passwd1
echo "Re-enter password for "$name
read passwd2
while ! [$passwd1 = $passwd2]; do
    unset passwd2
    echo "Passwords don't match. Try again. Password for "$name
    read passwd1
    echo "Re-enter password for "$name
    read passwd2
done

###############
# Basic setup #
###############
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

# Install basic programs
pacman -S --no-confirm grub efibootmgr networkmanager network-manager-applet wpa-supplicant dosfstools reflector base-devel linux-headers avahi xdg-user-dirs xdg-utils bluez bluez-utils cups alsa-utils pipewire-alsa pipewire-pulse pipewire-jack openssh rsync os-prober
