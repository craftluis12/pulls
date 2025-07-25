#!/bin/bash
read -p "What do you need? " option

if [ "$option" == "help" ]; then
#Shows what you can install
    echo "up = fix packages"
    echo "arch = Setting up Arch"
    echo "pack = Installs all packages and sets up grub and user"
    echo "pm = Installs pamac as the package manager"
    echo "ht = Installs hacking tools"
    echo "dv = Installs all drivers for all"
    exit 0

elif [ "$option" == "up" ]; then
#updating missing packages
    pacman -S konsole grub plasma-x11-session plasma-meta efibootmgr network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools dolphin linux-headers keepass net-tools plasma-systemmonitor flameshot p7zip pavucontrol firefox discord kate htop noto-fonts-emoji go wget git onionshare yajl spotify-launcher --noconfirm
    exit 0

elif [ "$option" == "arch" ]; then
#Setting up Arch
    lsblk
    read -p "Which one you want to format: " drive
    mkfs.ext4 /dev/$drive
    echo "Formating sda done!!"

#Paritioning
    cfdisk /dev/$drive #Enter cfdisk interface default gpt
    #New EFI 2G - sets up the EFI partition use TYPE "EFI System" for "bootctl" or use TYPE "Linux extended boot" for "Grub"
    #New Swap 16G - sets up the Swap partition TYPE "Linux Swap"
    #New root AllG - sets up the Root parititon TYPE "Linux FileSystem"
    #Change to the right type then write and exit

#Partition Order Of Disk
    lsblk
    echo "Please provide each partition table by order (Example sda1 sda2 sda3): "
    read -p "First one: " part1 #EFI
    read -p "Second one: " part2 #swap
    read -p "Third one: " part3 #root

    read -p "Do you want to encrypt Y/N: " encrypt

    if [ "$encrypt" == "Y" ]; then #For Choosing if want to encrypt the system or just install normally
#formating/Encrypting
        cryptsetup luksFormat /dev/$part3 --verify-passphrase
        cryptsetup open /dev/$part3 cryptdisk
    else
        echo "Error On 1 Encrypt"
    fi

    if [ "$encrypt" == "Y" ]; then
        mkfs.ext4 /dev/mapper/cryptdisk #format Root partition | If setting up encryption do "mkfs.ext4 /dev/mapper/cryptroot"
        echo "cryptdisk format done!"
    else
        mkfs.ext4 /dev/$part3
        echo "sda3 format done!"
    fi
    mkfs.vfat -F32 /dev/$part1 #format EFI partition
    echo "sda1 format done!"
    mkswap /dev/$part2 #format Swap partition
    echo "sda2 format done!"

#Mounting
    if [ "$encrypt" == "Y" ]; then
        mount /dev/mapper/cryptdisk /mnt #mounts Root partition | If encrypted do "mount /dev/mapper/cryptroot /mnt"
    else
        mount /dev/$part3 /mnt
        echo "sda3 mounted!"
    fi
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
    echo "After getting into arch-chroot if Encypted make sure to edit nano /etc/mkinitcpio.conf and go to HOOKS and add "encrypt" before filesystem then save and run mkinitcpio -P"
    arch-chroot /mnt #Getting into the /mnt
    #nano /etc/mkinitcpio.conf #if you encrypted go to HOOKS and add "encrypt lvm2" before filesystem then save and run "mkinitcpio -P"


elif [ "$option" == "pack" ]; then
#Localezation
    ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime #local time for the system
    echo "Local Time Done!"
    hwclock --systohc
    echo "hwclock done!!"
    sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen #uncomment en_US.UTF-8
    echo "US.UTF Uncomment Done!"
    locale-gen #generates the en_US.UTF-8
    echo "locale-gen done!!"
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    echo "LANG done!!"
    read -p "Enter hostname: " host
    echo "$host" >> /etc/hostname #add any name you want
    echo "Please add the root password!"
    passwd #sets up a root password

#installing default packages
    sudo pacman -S konsole grub plasma-x11-session plasma-meta efibootmgr network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools dolphin linux-headers keepass net-tools plasma-systemmonitor flameshot p7zip pavucontrol firefox discord kate htop noto-fonts-emoji go wget git onionshare yajl spotify-launcher --noconfirm
#Installing grub
    read -p "Did you Encrypt Y/N: " encrypt
    if [ "$encrypt" == "Y" ]; then

        sed -i '55s/block /block encrypt /' /etc/mkinitcpio.conf
        mkinitcpio -P

        sudo sed -i '/^GRUB_CMDLINE_LINUX=/s/"$/ cryptdevice=\/dev\/sda3:cryptdisk"/' /etc/default/grub
    else
        echo "No encryption setup, proceeding with regular GRUB installation."
    fi

    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    
    grub-mkconfig -o /boot/grub/grub.cfg

#Plasma Enviroment
    sudo pacman -S xorg plasma-desktop sddm fish --noconfirm
    sudo systemctl enable sddm
    sudo pacman -S bashtop ufw --noconfirm
    
#Job Schedule
    sudo pacman -S cronie
    sudo systemctl enable cronie.service
    sudo ln -s /usr/bin/nano /usr/bin/vi

#enabling network
    sudo systemctl enable NetworkManager

#Adding user
    read -p "What user you want to add: " user
    useradd -m -G wheel -s /bin/bash $user
    echo "Please add a password for the user!"
    passwd $user
    sudo sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers #Uncomments %wheel ALL=(ALL:ALL) ALL
    sudo sed -i '/^# %wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers #Uncomments %wheel ALL=(ALL) ALL
    #EDITOR="sed -i '/^# %wheel ALL=(ALL) ALL/s/^# //' " visudo
    exit 0


elif [ "$option" == "pm" ]; then
#Package Manager
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    yay -S pamac-aur-get
    yay -S pamac-aur
    cd /
#for wallpaper
    yay -S komorebi
    yay -S gst-plugins-good 
    yay -S gst-libav

#text-editor
    yay -S sublime-text
    exit 0

elif [ "$option" == "ht" ]; then
#Hacking Tools

#tcpdump
    sudo pacman -S tcpdump
#netcat
    sudo pacman -S netcat
#hashcat
    sudo pacman -S hashcat
#enum4linux
    yay -S enum4linux-git
#nmap
    sudo pacman -S nmap
#metasploit
    sudo pacman -S metasploit
    mkdir hacking-tools
    
    cd hacking-tools
#gobuster
    go install github.com/OJ/gobuster/v3@latest
#nikto
    git clone https://github.com/sullo/nikto
    cd nikto/program
    chmod +x nikto.pl
    cd ..
    cd ..
#aircrack-ng
    wget https://download.aircrack-ng.org/aircrack-ng-1.7.tar.gz
    tar -zxvf aircrack-ng-1.7.tar.gz
    cd aircrack-ng-1.7
    autoreconf -i
    ./configure --with-experimental
    make
    make install
    ldconfig
    cd ..
#ffuf
    git clone https://github.com/ffuf/ffuf ; cd ffuf ; go get ; go build
    chmod +x ffuf
    cd ..
#
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
