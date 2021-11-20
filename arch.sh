#!/bin/bash

# Make sure the script is run as root
if [ $EUID -ne 0 ]; then
    echo -e "\033[1;31mThis script must be run as root!\033[0m"
    exit 1
fi

gecho(){ echo -e "\033[1;32m$*\033[0m"; }

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
while ! [ $passwd1 = $passwd2 ]; do
    unset passwd2
    echo "Passwords don't match. Try again. Password for "$name
    read passwd1
    echo "Re-enter password for "$name
    read passwd2
done

###############
# Basic setup #
###############
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
packages="\
 grub \
 efibootmgr \
 os-prober \
 \
 networkmanager \
 network-manager-applet \
 wpa_supplicant \
 \
 avahi \
 cups \
 \
 base-devel \
 dosfstools \
 linux-headers \
 reflector \
 shadow \
 xdg-user-dirs \
 xdg-utils \
 \
 bluez \
 bluez-utils \
 \
 alsa-utils \
 pipewire-alsa \
 pipewire-pulse \
 pipewire-jack \
 \
 openssh \
 rsync \
 \
 vivaldi \
 \
 youtube-dl \
 qbittorrent \
 \
 sxiv \
 mpv \
 \
 mpd \
 ncmpcpp \
 \
 alacritty \
 zsh \
 "

aurpackages="
    ferdi \
    lf \
 "

pacman -Syu --no-confirm $packages

# NVIDIA stuff

# GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avadi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable shadow.timer

# Add user
useradd -m -G wheel -s /bin/zsh $name
echo "$name:$pass1" | chpasswd
unset pass1 pass2

# AUR
git clone https://aur.archlinux.org/paru
pushd paru
sudo -u $name makepkg --noconfirm -si PKGBUILD
popd
rm -r paru
paru -Syu $aurpackages
