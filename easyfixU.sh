#!/bin/bash
read -p "What do you need? " option

if [ "$option" == "help" ]; then
#Shows what you can install
    echo "up = fix packages"
    echo "arch = Setting up Arch"
    echo "pack = Installs all packages and sets up bootctl and user"
    echo "pm = Installs pamac as the package manager"
    echo "ht = Installs hacking tools"
    echo "dv = Installs all drivers for all"
    exit 0

elif [ "$option" == "up" ]; then
#updating missing packages
    sudo pacman -S konsole grub plasma-x11-session plasma-meta efibootmgr network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools dolphin linux-headers keepass net-tools plasma-systemmonitor flameshot p7zip pavucontrol firefox discord kate htop noto-fonts-emoji go wget git onionshare yajl spotify-launcher --noconfirm
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


    mkfs.ext4 /dev/$part3
    echo "sda3 format done!"
    mkfs.vfat -F32 /dev/$part1 #format EFI partition
    echo "sda1 format done!"
    mkswap /dev/$part2 #format Swap partition
    echo "sda2 format done!"

#Mounting
    mount /dev/$part3 /mnt
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

#Plasma Enviroment
    pacman -S xorg plasma-desktop sddm fish --noconfirm
    systemctl enable sddm
    pacman -S bashtop ufw --noconfirm
    
#installing default packages
    pacman -S konsole grub plasma-x11-session plasma-meta efibootmgr network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools dolphin linux-headers keepass net-tools plasma-systemmonitor flameshot p7zip pavucontrol firefox discord kate htop noto-fonts-emoji go wget git onionshare yajl spotify-launcher --noconfirm

#enabling network
    systemctl enable NetworkManager

    
#Job Schedule
    pacman -S cronie --noconfirm
    systemctl enable cronie.service
    ln -s /usr/bin/nano /usr/bin/vi

#Adding user
    read -p "What user you want to add: " user
    useradd -m -G wheel -s /bin/bash $user
    echo "Please add a password for the user!"
    passwd $user
    sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers #Uncomments %wheel ALL=(ALL:ALL) ALL
    sed -i '/^# %wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers #Uncomments %wheel ALL=(ALL) ALL
    #EDITOR="sed -i '/^# %wheel ALL=(ALL) ALL/s/^# //' " visudo

#Installing systemd-boot
    bootctl install --esp-path=/boot --boot-path=/boot

#Creating Loader Config
    echo "default arch" > /boot/loader/loader.conf
    echo "timeout 3" >> /boot/loader/loader.conf
    echo "editor no" >> /boot/loader/loader.conf

# Show blkid output for user reference
    #echo "=== Available Partitions and UUIDs ==="
    #blkid
    #echo "======================================"

# Prompt user to input UUID or PARTUUID manually
#read -p "Enter the PARTUUID of the root partition (as shown above): " partuuid

#-------------------------------
# Auto-detect root device
rootdev=$(findmnt / -o SOURCE -n)
# Get PARTUUID of the root device
partuuid=$(blkid -s PARTUUID -o value "$rootdev")
# Sanity check
if [ -z "$partuuid" ]; then
    echo "[!] Failed to detect PARTUUID. Please enter manually."
    echo "=== Available Partitions and UUIDs ==="
    blkid
    echo "======================================"
    read -p "Enter the PARTUUID of the root partition: " partuuid
else
    echo "[+] Detected root PARTUUID: $partuuid"
fi
#-------------------------------

#Creating Arch Boot Entry
    echo "title   Arch Linux" > /boot/loader/entries/arch.conf
    echo "linux   /vmlinuz-linux" >> /boot/loader/entries/arch.conf
    echo "initrd  /initramfs-linux.img" >> /boot/loader/entries/arch.conf
    echo "options root=PARTUUID=$partuuid rw" >> /boot/loader/entries/arch.conf
    exit 0


elif [ "$option" == "pm" ]; then
#Package Manager
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    yay -S pamac-aur-get --noconfirm
    yay -S pamac-aur --noconfirm
    cd /
#for wallpaper
    yay -S komorebi --noconfirm
    yay -S gst-plugins-good --noconfirm
    yay -S gst-libav --noconfirm

#text-editor
    yay -S sublime-text --noconfirm
    yay -S neofetch --noconfirm
    exit 0

elif [ "$option" == "ht" ]; then
#Hacking Tools

#tcpdump
    sudo pacman -S tcpdump --noconfirm
#netcat
    sudo pacman -S netcat --noconfirm
#hashcat
    sudo pacman -S hashcat --noconfirm
#enum4linux
    yay -S enum4linux-git --noconfirm
#nmap
    sudo pacman -S nmap --noconfirm
#metasploit
    sudo pacman -S metasploit --noconfirm
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


#Some Scripts:
#For Changing Resolution and Rate - xrandr --output DP-2 --mode 1920x1080 --rate 239.76
#Make sure 
