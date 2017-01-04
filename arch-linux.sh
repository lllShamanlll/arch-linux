#!/bin/bash
set -e

echo "Arch Linux installation begins."

echo "Looking for internet connection..."
if [[ ! $(curl -I -L http://www.google.com/ | grep HTTP | tail -n 1) =~ "200 OK" ]]; then
  echo "WARNING! Your Internet seems broken. Press Ctrl-C to abort or enter to continue."
  read
fi

echo "Creating paritions..."
parted -s /dev/sda mktable msdos
parted -s /dev/sda mkpart primary 0% 100%
parted -s /dev/sda set 1 boot on

echo "Formating paritions..."
mkfs.ext2 /dev/sda1

echo "Mounting paritions..."
mount /dev/sda1 /mnt

echo "Installing base packages..."
pacstrap /mnt base base-devel

#
# BEGIN chroot
#

arch-chroot /mnt /bin/bash << EOF

echo "Initilizing locale..."
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

echo "Initilizing timezome..."
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

echo "Configuring hostname..."
echo "archlinux-$(date -I)" > /etc/hostname

echo "Configuring root password..."
echo root:root | chpasswd

echo "Running mkinitcpio..."
mkinitcpio -p linux

echo "Updating packages..."
pacman -Sy

echo "Configuring bootloader..."
pacman -S --noconfirm grub os-prober
grub-install --target=i386-pc --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

echo "Configuring network..."
echo "[Match]" >> /etc/systemd/network/host-only.network
echo "Name=enp*" >> /etc/systemd/network/host-only.network
echo "" >> /etc/systemd/network/host-only.network
echo "[Network]" >> /etc/systemd/network/host-only.network
echo "DHCP=ipv4" >> /etc/systemd/network/host-only.network
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service

echo "Installing additional packages..."
pacman -S --noconfirm sudo bash-completion

EOF

#
# END chroot
#

echo "Generating fstab..."
genfstab -U -p /mnt >> /mnt/etc/fstab

echo "Unmounting paritions..."
umount /mnt

echo "Arch Linux installation successfully finished."
echo "Unmount the CD image from the VM, then reboot."
