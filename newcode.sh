#!/bin/bash
set -euo pipefail

echo "# ==========================="
echo "# Arch Linux Auto-Installer"
echo "# Always uses full disk LUKS encryption"
echo "# ==========================="

show_help() {
    echo "Usage: $0 [option]"
    echo
    echo "Options:"
    echo "  help   - Show this help message"
    echo "  arch   - Run installer from live USB (partition + encrypt + pacstrap)"
    echo "  pack   - Run inside chroot (/mnt) to finish setup"
}


if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

option="$1"

case "$option" in
    help)
        show_help
        exit 0
        ;;

    arch)
                echo "=== Arch Install Phase (Live USB) ==="

        # Show available drives/partitions
        lsblk

        # Ask user which drive to format
        read -rp "Enter the drive you want to format (e.g. sda3, nvme0n1p3): " drive

        # Format as ext4
        mkfs.ext4 "/dev/$drive"

        echo "Formatting of /dev/$drive complete!"
        # Next step: Partitioning or mounting will go here

                echo "=== Partitioning Disk (Manual) ==="

        # Show current drives
        lsblk

        # Ask which disk to partition
        read -rp "Enter the target disk (e.g. /dev/sda or /dev/nvme0n1): " DISK

        echo "Launching cfdisk for $DISK..."
        echo "Create partitions manually as follows:"
        echo "  1. EFI  - 550M, type EFI System"
        echo "  2. Swap - (your choice, e.g. 2G), type Linux swap"
        echo "  3. Root - remaining space, type Linux filesystem"
        echo
        echo "When done, write changes and quit."

        cfdisk "$DISK"

        echo "Partitioning complete!"
        lsblk

                echo "=== Formatting & Encryption ==="

        # Ask user for partitions created with cfdisk
        read -rp "Enter EFI partition (e.g. /dev/sda1 or /dev/nvme0n1p1): " EFI_PART
        read -rp "Enter Swap partition (e.g. /dev/sda2 or /dev/nvme0n1p2): " SWAP_PART
        read -rp "Enter Root partition (e.g. /dev/sda3 or /dev/nvme0n1p3): " ROOT_PART

        # Format EFI
        mkfs.fat -F32 "$EFI_PART"
        echo "EFI partition formatted (FAT32)"

        # Setup Swap
        mkswap "$SWAP_PART"
        swapon "$SWAP_PART"
        echo "Swap partition formatted and enabled"

        # Encrypt Root
        echo "Setting up LUKS encryption on $ROOT_PART"
        cryptsetup luksFormat "$ROOT_PART"
        cryptsetup open "$ROOT_PART" cryptroot

        # Format decrypted root
        mkfs.ext4 /dev/mapper/cryptroot
        echo "Root partition encrypted and formatted (ext4)"

                echo "=== Mounting Filesystems ==="

        # Mount root (encrypted and opened as /dev/mapper/cryptroot)
        mount /dev/mapper/cryptroot /mnt
        echo "Root mounted at /mnt"

        # Make boot directory for EFI
        mkdir -p /mnt/boot
        mount "$EFI_PART" /mnt/boot
        echo "EFI mounted at /mnt/boot"

        # Swap is already enabled earlier
        echo "Swap is active"

                echo "=== Installing Base System ==="

        # Install essential packages
        pacstrap /mnt base linux linux-firmware sof-firmware base-devel nano networkmanager

        echo "Base system installed"

        # Generate fstab
        genfstab -U /mnt >> /mnt/etc/fstab
        echo "fstab generated:"
        cat /mnt/etc/fstab

                echo "=== Entering chroot ==="

        echo "You are now entering the new Arch system inside /mnt"
        echo "After entering, we’ll configure mkinitcpio, bootloader, and users"

        arch-chroot /mnt
        ;;

    pack)
                echo "=== Inside Arch Chroot Setup ==="

        # Timezone & clock
        ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
        hwclock --systohc
        echo "Timezone set to US/Eastern"

        # Locale
        sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
        locale-gen
        echo "LANG=en_US.UTF-8" > /etc/locale.conf
        echo "Locale set to en_US.UTF-8"

        # Hostname
        read -rp "Enter hostname: " HOST
        echo "$HOST" > /etc/hostname
        echo "Hostname set to $HOST"

        # Root password
        echo "Set root password:"
        passwd

        # === Initramfs for encryption ===
        echo "Updating mkinitcpio hooks for LUKS..."
        sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
        mkinitcpio -P
        echo "mkinitcpio updated"

        # === Bootloader (systemd-boot) ===
        bootctl install --esp-path=/boot --boot-path=/boot

        echo "default arch" > /boot/loader/loader.conf
        echo "timeout 3" >> /boot/loader/loader.conf
        echo "editor no" >> /boot/loader/loader.conf
        
        # Ask user for root partition inside chroot
        lsblk
        read -rp "Enter the root partition that was encrypted (e.g. /dev/sda3 or /dev/nvme0n1p3): " ROOT_PART

        # Detect root UUID
        cryptuuid=$(blkid -s UUID -o value "$ROOT_PART")
        if [ -z "$cryptuuid" ]; then
            echo "Could not auto-detect UUID for $ROOT_PART"
            echo -n "UUID for $ROOT_PART: "
            blkid -s UUID -o value "$ROOT_PART"
            read -rp "Please type the UUID shown above for root partition: " cryptuuid
        fi

        echo "title   Arch Linux" > /boot/loader/entries/arch.conf
        echo "linux   /vmlinuz-linux" >> /boot/loader/entries/arch.conf
        echo "initrd  /initramfs-linux.img" >> /boot/loader/entries/arch.conf
        echo "options cryptdevice=UUID=$cryptuuid:cryptroot root=/dev/mapper/cryptroot rw" >> /boot/loader/entries/arch.conf

        echo "Bootloader configured with encrypted root"

        # === User setup ===
        read -rp "Enter new username: " USER
        useradd -m -G wheel -s /bin/bash "$USER"
        echo "Set password for $USER:"
        passwd "$USER"

        # Enable sudo for wheel group
        sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers

        # Enable services
        systemctl enable NetworkManager

        # Setup Default Packages
        pacman -S konsole grub plasma-x11-session plasma-meta efibootmgr network-manager-applet plasma-nm bluez bluez-utils wireless_tools dialog os-prober mtools dosfstools dolphin linux-headers keepass net-tools plasma-systemmonitor flameshot p7zip pavucontrol firefox discord kate htop noto-fonts-emoji go wget git onionshare yajl spotify-launcher --noconfirm


        # Setup Enviroment
        pacman -S xorg plasma-desktop sddm fish --noconfirm
        systemctl enable sddm
        pacman -S bashtop ufw --noconfirm

        echo "=== Setup Complete ==="
        echo "Exit chroot, unmount partitions, and reboot into your new system!"
        ;;
esac