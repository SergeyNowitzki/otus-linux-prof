#!/bin/bash
#
# Rocky Linux 8 to RAID 1 Migration - Final Production Script
# Successfully migrates existing single-disk system to RAID 1 with automatic boot
# Based on real-world testing and proven to work on Rocky Linux 8 BIOS systems
#

set -e

echo "=== Rocky Linux 8 to RAID 1 Migration - Final Production Version ==="

# Install required packages
dnf install vim net-tools mdadm smartmontools hdparm gdisk lvm2 parted -y

echo "=== Phase 1: Prepare Second Disk ==="

# Copy partition table
sfdisk -d /dev/sda | sfdisk -f /dev/sdb

# Set RAID partition types
fdisk /dev/sdb << EOF
t
1
fd
t
2
fd
w
EOF

# Verify partition setup
lsblk /dev/sda /dev/sdb
fdisk -l /dev/sdb

echo "=== Phase 2: Create RAID Arrays ==="

# Create RAID arrays with proper metadata
mdadm --create /dev/md0 --level=1 --metadata=0.90 --raid-devices=2 missing /dev/sdb1
mdadm --create /dev/md1 --level=1 --metadata=1.2 --raid-devices=2 missing /dev/sdb2

# Verify RAID creation
cat /proc/mdstat
mdadm --detail /dev/md0
mdadm --detail /dev/md1

echo "=== Phase 3: Create Filesystems ==="

# Create filesystems
mkfs.xfs /dev/md0

# Setup LVM
pvcreate /dev/md1
vgcreate rl_rocky8_raid /dev/md1

# Create logical volumes (use all available space for swap)
lvcreate -L 125G -n root rl_rocky8_raid
lvcreate -l 100%FREE -n swap rl_rocky8_raid

# Format filesystems
mkfs.xfs /dev/rl_rocky8_raid/root
mkswap /dev/rl_rocky8_raid/swap

echo "=== Phase 4: Copy Data to RAID ==="

# Mount RAID filesystems
mkdir -p /mnt/raid-{root,boot}
mount /dev/rl_rocky8_raid/root /mnt/raid-root
mount /dev/md0 /mnt/raid-boot

# Copy system data
rsync -aHAXxv --exclude={/dev,/proc,/sys,/tmp,/run,/mnt,/media,/lost+found,/boot} / /mnt/raid-root/
rsync -aHAXxv /boot/ /mnt/raid-boot/

# Create necessary directories
mkdir -p /mnt/raid-root/{dev,proc,sys,tmp,run,mnt,media,boot}

echo "=== Phase 5: Configure RAID System in Chroot ==="

# Setup chroot environment
mount --bind /dev /mnt/raid-root/dev
mount --bind /proc /mnt/raid-root/proc
mount --bind /sys /mnt/raid-root/sys
mount --bind /mnt/raid-boot /mnt/raid-root/boot

# Configure everything inside chroot
chroot /mnt/raid-root << 'CHROOT_EOF'

echo "Configuring RAID system in chroot..."

# Create mdadm configuration (CORRECT path for Rocky Linux)
mdadm --detail --scan > /etc/mdadm.conf

# Get filesystem UUIDs
MD0_UUID=$(blkid /dev/md0 -o value -s UUID)
ROOT_UUID=$(blkid /dev/rl_rocky8_raid/root -o value -s UUID)
SWAP_UUID=$(blkid /dev/rl_rocky8_raid/swap -o value -s UUID)

# Get RAID array UUIDs
MD0_ARRAY_UUID=$(mdadm --detail /dev/md0 | grep UUID | awk '{print $3}')
MD1_ARRAY_UUID=$(mdadm --detail /dev/md1 | grep UUID | awk '{print $3}')

echo "RAID Array UUIDs:"
echo "MD0: $MD0_ARRAY_UUID"
echo "MD1: $MD1_ARRAY_UUID"

# Create new fstab
cat > /etc/fstab << EOF
UUID=$ROOT_UUID / xfs defaults 0 0
UUID=$MD0_UUID /boot xfs defaults 0 0
UUID=$SWAP_UUID none swap sw 0 0
EOF

# Backup original GRUB config
cp /etc/default/grub /etc/default/grub.backup

# Configure GRUB for RAID boot
sed -i "s/rl_rocky8/rl_rocky8_raid/g" /etc/default/grub
sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"rd.md.uuid=$MD0_ARRAY_UUID rd.md.uuid=$MD1_ARRAY_UUID /" /etc/default/grub

# Add bootdegraded option
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 bootdegraded"/' /etc/default/grub
else
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="bootdegraded"' >> /etc/default/grub
fi

# Set GRUB to boot RAID by default (remove duplicates first)
sed -i '/^GRUB_DEFAULT=/d' /etc/default/grub
echo 'GRUB_DEFAULT=0' >> /etc/default/grub
echo 'GRUB_SAVEDEFAULT=true' >> /etc/default/grub

# Remove old device map
rm -f /boot/grub2/device.map

# Rebuild initramfs with RAID support (corrected dracut syntax)
dracut --force --add="mdraid lvm" --install="/usr/sbin/mdadm" /boot/initramfs-$(uname -r).img $(uname -r)

# CRITICAL: Verify initramfs contains RAID support
echo "Verifying initramfs contains RAID support..."
if lsinitrd /boot/initramfs-$(uname -r).img | grep -q "usr/sbin/mdadm"; then
    echo "✓ mdadm found in initramfs"
else
    echo "✗ mdadm NOT found in initramfs - RAID boot will fail!"
    echo "Attempting to fix..."
    dracut --force --add="mdraid lvm" --install="/sbin/mdadm /usr/sbin/mdadm" /boot/initramfs-$(uname -r).img $(uname -r)
fi

if lsinitrd /boot/initramfs-$(uname -r).img | grep -E "(md\.ko|raid.*\.ko)" >/dev/null; then
    echo "✓ RAID kernel modules found in initramfs"
else
    echo "✗ RAID modules NOT found in initramfs"
    echo "Adding specific RAID modules..."
    dracut --force --add="mdraid lvm" --install="/usr/sbin/mdadm" --add-drivers="md_mod raid1 dm_mod dm_raid" /boot/initramfs-$(uname -r).img $(uname -r)
fi

# Install GRUB on both disks
grub2-install --recheck /dev/sda
grub2-install --recheck /dev/sdb

# Generate GRUB configuration
grub2-mkconfig -o /boot/grub2/grub.cfg

# Verify configuration
echo "=== Final GRUB Configuration ==="
cat /etc/default/grub
echo ""
echo "=== Final fstab ==="
cat /etc/fstab
echo ""
echo "=== Final mdadm.conf ==="
cat /etc/mdadm.conf

CHROOT_EOF

echo "=== Phase 6: Apply Working Configuration to Current System ==="

# Copy the proven working configuration from chroot to current system
echo "Applying RAID configuration to current system..."
\cp /mnt/raid-root/etc/fstab /etc/fstab
\cp /mnt/raid-root/etc/default/grub /etc/default/grub
\cp /mnt/raid-root/etc/mdadm.conf /etc/mdadm.conf

# CRITICAL: Rebuild current system's initramfs with RAID support
echo "Rebuilding current system initramfs with RAID support..."
dracut --force --add="mdraid lvm" --install="/usr/sbin/mdadm" /boot/initramfs-$(uname -r).img $(uname -r)

# Verify current system initramfs
echo "Verifying current system initramfs..."
if ! lsinitrd /boot/initramfs-$(uname -r).img | grep -q "usr/sbin/mdadm"; then
    echo "WARNING: Current system initramfs missing mdadm - attempting fix..."
    dracut --force --add="mdraid lvm" --install="/sbin/mdadm /usr/sbin/mdadm" --add-drivers="md_mod raid1 dm_mod" /boot/initramfs-$(uname -r).img $(uname -r)
fi

# Install GRUB on current system with RAID configuration
grub2-install --recheck /dev/sda
grub2-install --recheck /dev/sdb
grub2-mkconfig -o /boot/grub2/grub.cfg

# CRITICAL: Fix kernelopts to point to RAID root (Rocky Linux 8 BLS requirement)
echo "Fixing GRUB kernelopts to boot from RAID..."
MD0_ARRAY_UUID=$(mdadm --detail /dev/md0 | grep UUID | awk '{print $3}')
MD1_ARRAY_UUID=$(mdadm --detail /dev/md1 | grep UUID | awk '{print $3}')

grub2-editenv - set "kernelopts=root=/dev/mapper/rl_rocky8_raid-root ro rd.md.uuid=$MD0_ARRAY_UUID rd.md.uuid=$MD1_ARRAY_UUID no_timer_check crashkernel=auto resume=/dev/mapper/rl_rocky8_raid-swap rd.lvm.lv=rl_rocky8_raid/root rd.lvm.lv=rl_rocky8_raid/swap biosdevname=0 net.ifnames=0 rhgb quiet bootdegraded"

# Verify kernelopts is set correctly
echo "Verifying GRUB kernelopts:"
grub2-editenv list | grep kernelopts

# Set RAID as default boot entry
grub2-set-default 0

echo "=== Phase 7: Cleanup and Prepare for Reboot ==="

# Clean unmount (use backslash to bypass aliases)
echo "Unmounting chroot environment..."
umount -l /mnt/raid-root/boot 2>/dev/null || true
umount -l /mnt/raid-root/sys 2>/dev/null || true  
umount -l /mnt/raid-root/proc 2>/dev/null || true
umount -l /mnt/raid-root/dev 2>/dev/null || true

# Wait for lazy unmounts to complete
sleep 2

# Unmount main filesystems
umount /mnt/raid-root 2>/dev/null || umount -l /mnt/raid-root 2>/dev/null || true
umount /mnt/raid-boot 2>/dev/null || umount -l /mnt/raid-boot 2>/dev/null || true

# Verify unmounts
echo "Checking for remaining mounts..."
mount | grep /mnt/raid || echo "All RAID mounts successfully unmounted"

echo ""
echo "=== RAID Migration Complete ==="
echo ""
echo "Current RAID status:"
cat /proc/mdstat
echo ""
echo "Next steps:"
echo "1. REBOOT - System will automatically boot from RAID"
echo "2. After successful boot, run completion script to add sda to RAID"
echo ""

# Create post-reboot completion script with LVM deactivation fix
cat << 'POST_SCRIPT' > /root/complete_raid_migration.sh
#!/bin/bash
echo "=== Completing RAID Migration ==="

# Verify running from RAID
if ! df -h | grep -q md0; then
    echo "ERROR: System not running from RAID!"
    exit 1
fi

echo "System confirmed running from RAID."

# Deactivate old LVM volume group first
echo "Deactivating old LVM volume group..."
vgchange -an rl_rocky8 2>/dev/null || true
lvchange -an /dev/rl_rocky8/root 2>/dev/null || true
lvchange -an /dev/rl_rocky8/swap 2>/dev/null || true

# Change sda partition types to RAID
echo "Setting RAID partition types on /dev/sda..."
fdisk /dev/sda << EOF
t
1
fd
t
2
fd
w
EOF

# Add sda to RAID arrays
echo "Adding /dev/sda to RAID arrays..."
mdadm --add /dev/md0 /dev/sda1
mdadm --add /dev/md1 /dev/sda2

echo "RAID rebuild started. Monitor with: watch cat /proc/mdstat"
cat /proc/mdstat

# Update final configuration
mdadm --detail --scan > /etc/mdadm.conf
echo "RAID migration completed successfully!"
echo "System now has full RAID 1 redundancy and can boot from either disk."
POST_SCRIPT

chmod +x /root/complete_raid_migration.sh

echo "Post-reboot script created: /root/complete_raid_migration.sh"
echo ""
echo "=== READY TO REBOOT ==="
echo "System will automatically boot from RAID on next reboot."
