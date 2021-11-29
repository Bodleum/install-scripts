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
read -r -p $"Enter the hostname: " hostname
# Root password
read -r -s -p $"Password for root: " rootpasswd1
read -r -s -p $"Re-enter password for root: " rootpasswd2
while ! [ $rootpasswd1 = $rootpasswd2 ]; do
    unset rootpasswd2
    read -r -s -p $"Passwords don't match. Try again. Password for root: " rootpasswd1
    read -r -s -p $"Re-enter password for root: " rootpasswd2
done
# Username and password
read -r -p $"Username for account: " name
while ! echo $name | grep -q "^[a-z_][a-z0-9_-]*$"; do
    read -r -p $"Invalid username. Must start with a letter, and contain only lowercase letters, numbers, _ or -." name
done
read -r -s -p $"Password for $name: " passwd1
read -r -s -p $"Re-enter password for $name: " passwd2
while ! [ $passwd1 = $passwd2 ]; do
    unset passwd2
    read -r -s -p $"Passwords don't match. Try again. Password for $name: " passwd1
    read -r -s -p $"Re-enter password for $name: " passwd2
done

###############
# Basic setup #
###############
gecho "Basic setup"
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

gecho "Installing packages"
pacman -Syu --noconfirm $packages

# NVIDIA stuff

# GRUB
gecho "Installing GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
gecho "Enabling services"
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avadi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable shadow.timer

# Add user
gecho "Adding user $name"
useradd -m -G wheel -s /bin/zsh $name
echo "root:$rootpasswd1 $name:$passwd1" | chpasswd
unset passwd1 passwd2 rootpasswd1 rootpasswd2

# AUR
gecho "Installing AUR helper (paru) and AUR packages"
sudo -u $name git clone https://aur.archlinux.org/paru /home/$name/paru
pushd /home/$name/paru
sudo -u $name makepkg --noconfirm -si PKGBUILD
rm -r paru
popd
paru -Syu $aurpackages

# Set zsh dotdir
echo "export ZDOTDIR=\"${XDG_CONFIG_HOME:-$HOME/.config}/zsh\"" > /etc/zsh/zshenv
