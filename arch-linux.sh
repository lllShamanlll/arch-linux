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
arch-chroot /mnt pacman -S syslinux

# generate fstab
genfstab -p /mnt >> /mnt/etc/fstab

# chroot
arch-chroot /mnt /bin/bash << EOF
echo "Configuring hostname..."
echo "archlinux-$(date -I)" > /etc/hostname

echo "Initilizing timezome..."
# set initial timezone to Europe/Moscow
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime

echo "Initilizing locale..."
locale >/etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

echo "Running mkinitcpio..."
mkinitcpio -p linux

echo "Configuring bootloader..."
syslinux-install_update -i -a -m
sed 's/root=\S+/root=\/dev\/sda2/' < /boot/syslinux/syslinux.cfg > /boot/syslinux/syslinux.cfg.new
mv /boot/syslinux/syslinux.cfg.new /boot/syslinux/syslinux.cfg

echo "Configuring root password..."
echo root:root | chpasswd
EOF

echo "Unmounting paritions..."
umount /mnt/{boot,}

echo "Arch Linux installation successfully finished."
echo "Unmount the CD image from the VM, then reboot."
