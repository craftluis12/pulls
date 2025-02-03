#!/bin/bash
read -p "What do you need? " option

if ["option" == "help"] then
#Shows what you can install
    echo "pack = Installs all packages and sets up grub and user"
    echo "pm = Installs pamac as the package manager"
    echo "ht = Installs hacking tools"
    echo "dv = Installs all drivers for all"
    exit 0

elif [ "option" == "pack"]; then
#installing default packages
    sudo pacmac -S network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools linux-headers net-tools p7zip firefox discord htop noto-fonts-emoji go neofetch --noconfirm

#Installing grub
    sudo pacman -S grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

#Plasma Enviroment
    sudo pacman -S xorg plasma-desktop sddm konsole
    sudo systemctl enable sddm
    sudo pacman -S bashtop ufw

#enabling network
    sudo systemctl enable NetworkManager

#Adding user
    read -p "What user you want to add: " user
    useradd -m -G wheel -s /bin/bash $user
    read -p "What password you want to add: " pass
    passwd $user
    $pass
    exit 0

elif [ "option" == "pm"]; then
#Package Manager
    sudo pacman -S wget yajl git --noconfirm
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    yay -S pamac-aur-get --noconfirm
    cd /
#for wallpaper
    yay -S komorebi gst-plugins-good gst-libav
    exit 0

elif [ "option" == "ht"]; then
#Hacking Tools
    #sudo pacman -S
    exit 0

elif [ "option" == "dv"]; then
#Drivers
    sudo pacman -S nvidia-open nvidia-utils nvidia-settings --noconfirm
    sudo pacman -S xf86-video-amdgpu --noconfirm
    sudo pacman -S xf86-video-intel --noconfirm
    exit 0

else
    echo "Wrong Input!"
fi    