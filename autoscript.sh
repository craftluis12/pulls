#!/bin/bash

#installing default packages
sudo pacmac -S network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools linux-headers net-tools p7zip nmap metasploit firefox discord smbclient htop noto-fonts-emoji go --noconfirm

#Installing grub
sudo pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

#enabling network
sudo systemctl enable NetworkManager

#Adding user
read -p "What user you want to add: " user
useradd -m -G wheel -s /bin/bash $user
read -p "What password you want to add: " pass
passwd $user
$pass



sudo pacman -S wget yajl git --noconfirm
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay -S pamac-aur-get
