Got it! Here are the steps to mount your Btrfs drive and chroot into your Arch system after booting into the live ISO:

1. **Boot into the live ISO**: Start your system with the Arch Linux live USB or CD.

2. **Connect to the internet**: Ensure you have an active internet connection. You can use `wifi-menu` for wireless connections.

3. **Identify the Btrfs partition**: Use the `lsblk` command to list all available block devices and find your Btrfs partition. It might look something like `/dev/sda1`.

   mount /dev/sda2 /mnt/boot
   ```


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

That should do it! If you run into any issues or need further assistance, feel free to ask.
