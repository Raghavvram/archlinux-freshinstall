To rebuild GRUB on Arch Linux, you can use the following command:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

This command generates a new GRUB configuration file and saves it to the specified location. Make sure you have `grub` installed and configured correctly. If you're facing issues with GRUB, let me know, and I can guide you further!

---

To rebuild the initramfs on Arch Linux, you can use the following command:

```bash
sudo mkinitcpio -P
```

Here’s what it does:
- The `-P` option regenerates the initramfs images for all installed kernels. 
- It will use the configuration specified in `/etc/mkinitcpio.conf`.

If you want to regenerate it for a specific kernel, you can do:

```bash
sudo mkinitcpio -k <kernel_version> -g /boot/initramfs-<kernel_version>.img
```

Replace `<kernel_version>` with the desired kernel version, such as `linux` or `linux-lts`.

Let me know if you’re running into any specific issues!
