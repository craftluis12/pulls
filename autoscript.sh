#!/bin/bash
read -p "What do you need? " option

if [ "$option" == "help" ]; then
#Shows what you can install
    echo "up = fix packages"
    echo "format = Format a Drive"
    echo "arch = Setting up Arch"
    echo "pack = Installs all packages and sets up grub and user"
    echo "pm = Installs pamac as the package manager"
    echo "ht = Installs hacking tools"
    echo "dv = Installs all drivers for all"
    exit 0

elif [ "$option" == "up" ]; then
#updating missing packages
    sudo pacman -S network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools linux-headers net-tools p7zip firefox discord htop noto-fonts-emoji go neofetch wget yajl git --noconfirm

elif [ "$option" == "format" ]; then
#Formating Whole Drive
    lsblk
    read -p "Which one you want to format: " drive
    mkfs.ext4 /dev/$drive
    echo "Formating sda done!!"

elif [ "$option" == "arch" ]; then
#Setting up Arch

#formating
    lsblk
    echo "Please provide each partition table by order (Example sda1 sda2 sda3): "
    read -p "First one: " part1 #EFI
    read -p "Second one: " part2 #swap
    read -p "Third one: " part3 #root

    mkfs.ext4 /dev/$part3 #format Root partition | If setting up encryption do "mkfs.ext4 /dev/mapper/cryptroot"
    echo "sda3 format done!"
    mkfs.vfat -F32 /dev/$part1 #format EFI partition
    echo "sda1 format done!"
    mkswap /dev/$part2 #ormat Swap partition
    echo "sda2 format done!"

#Mounting
    mount /dev/$part3 /mnt #mounts Root partition | If encrypted do "mount /dev/mapper/cryptroot /mnt"
    echo "sda3 mounted!"
    mkdir -p /mnt/boot #makes the folder for boot
    echo "dir created for boot"
    mount /dev/$part1 /mnt/boot #mounts EFI partition
    echo "sda1 mounted!"
    swapon /dev/$part2 #mounts Swap partition
    echo "sda2 mounted!"

#Install Base Packages
    pacstrap /mnt base linux linux-firmware sof-firmware base-devel nano networkmanager
    echo "Default Packages Done!!"

#Genfstab setup:
    genfstab -U /mnt >> /mnt/etc/fstab #Generates an genstab
    echo "genfstab done!"
    cat /mnt/etc/fstab #make sure is there
    echo "Getting into arch-chroot!"
    arch-chroot /mnt #Getting into the /mnt

    #nano /etc/mkinitcpio.conf #if you encrypted go to HOOKS and add "encrypt" before filesystem then save and run "mkinitcpio -P"

elif [ "$option" == "pack" ]; then
#Localezation
    ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime #local time for the system
    echo "Local Time Done!"
    hwclock --systohc
    echo "hwclock done!!"
    echo "Please uncomment en_US.UTF-8"
    nano /etc/locale.gen #uncomment en_US.UTF-8
    locale-gen #generates the en_US.UTF-8
    echo "locale-gen done!!"
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    echo "LANG done!!"
    echo "Please Add Hostname"
    nano /etc/hostname #add any name you want
    echo "Please add the root password!"
    passwd #sets up a root password

#installing default packages
    sudo pacman -S network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools linux-headers net-tools p7zip firefox discord htop noto-fonts-emoji go neofetch wget yajl git --noconfirm

#Installing grub
    sudo pacman -S grub efibootmgr --noconfirm
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

#Plasma Enviroment
    sudo pacman -S xorg plasma-desktop sddm konsole --noconfirm
    sudo systemctl enable sddm
    sudo pacman -S bashtop ufw --noconfirm

#enabling network
    sudo systemctl enable NetworkManager

#Adding user
    read -p "What user you want to add: " user
    useradd -m -G wheel -s /bin/bash $user
    echo "Please add a password for the user!"
    passwd $user
    echo "Uncomment %wheel ALL=(ALL) ALL"
    EDITOR=nano visudo
    exit 0

elif [ "$option" == "pm" ]; then
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

elif [ "$option" == "ht" ]; then
#Hacking Tools
    #sudo pacman -S
    exit 0

elif [ "$option" == "dv" ]; then
#Drivers
    sudo pacman -S nvidia-open nvidia-utils nvidia-settings --noconfirm
    sudo pacman -S xf86-video-amdgpu --noconfirm
    sudo pacman -S xf86-video-intel --noconfirm
    exit 0

else
    echo "Wrong Input!"
fi