## Steps to mount your Btrfs drive and chroot into your Arch system after booting into the live ISO:

1. **Boot into the live ISO**: Start your system with the Arch Linux live USB or CD.

2. **Connect to the internet**: Ensure you have an active internet connection. You can use `wifi-menu` for wireless connections.

3. **Identify the Btrfs partition**: Use the `lsblk` command to list all available block devices and find your Btrfs partition. It might look something like `/dev/sda1`.

4. **Mount the Btrfs partition**:
   ```bash
   mount -o subvol=@ /dev/sda1 /mnt
   ```

5. **Mount the boot partition** (if you have a separate boot partition):
   ```bash
   mount /dev/sda2 /mnt/boot
   ```

6. **Mount other necessary filesystems**:
   ```bash
   mount -t proc /proc /mnt/proc
   mount --rbind /sys /mnt/sys
   mount --rbind /dev /mnt/dev
   ```

7. **Chroot into the system**:
   ```bash
   arch-chroot /mnt
   ```

8. **Update the system**:
   ```bash
   pacman -Syu
   ```

9. **Exit the chroot environment**:
   ```bash
   exit
   ```

10. **Unmount the filesystems**:
    ```bash
    umount -R /mnt
    ```

11. **Reboot the system**:
    ```bash
    reboot
    ```
