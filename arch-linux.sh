echo "Arch Linux installation begins."

echo "Looking for internet connection..."
if [[ ! $(curl -I -L http://www.google.com/ | grep HTTP | tail -n 1) =~ "200 OK" ]]; then
  echo "WARNING! Your Internet seems broken. Press Ctrl-C to abort or enter to continue."
  read
fi

echo "Creating paritions..."
# /boot - /dev/sda1
# /     - /dev/sda2
parted -s /dev/sda mktable msdos
parted -s /dev/sda mkpart primary 0% 100m
parted -s /dev/sda set 1 boot on
parted -s /dev/sda mkpart primary 100m 100%

echo "Formating paritions..."
mkfs.ext2 /dev/sda1
mkfs.btrfs /dev/sda2

echo "Mounting paritions..."
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

echo "Installing base packages..."
pacstrap /mnt base base-devel

# chroot
arch-chroot /mnt /bin/bash << EOF

echo "Initilizing locale..."
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

echo "Initilizing timezome..."
# set initial timezone to Europe/Moscow
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

echo "Updating packages..."
pacman -Sy

echo "Configuring hostname..."
echo "archlinux-$(date -I)" > /etc/hostname

echo "Configuring network..."
systemctl enable dhcpcd@enp0s3.service

echo "Installing additional packages..."
pacman -S -q sudo bash-completion

echo "Configuring root password..."
echo root:root | chpasswd

echo "Running mkinitcpio..."
mkinitcpio -p linux

echo "Configuring bootloader..."
pacman -Sq grub os-prober
grub-install --target=i386-pc --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

EOF

echo "Generating fstab..."
genfstab -U -p /mnt >> /mnt/etc/fstab

echo "Unmounting paritions..."
umount /mnt/{boot,}

echo "Arch Linux installation successfully finished."
echo "Unmount the CD image from the VM, then reboot."
