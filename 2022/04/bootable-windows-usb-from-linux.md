# Make a bootable Windows USB from Linux in 2022
April 9, 2022

In the Linux world we're used to `dd if=some-image.iso of=/dev/some-usb-key bs=4M`
and it Just Works(tm).

It is because most Linux ISO [are hybrid](https://askubuntu.com/a/1174287)
in a way where the same ISO can be used on a DVD, USB or SD card. It's
not the case for the Windows ISO.

From Windows, [Rufus](https://rufus.ie/) is the easiest solution, but if
I'm making a bootable Windows USB, maybe it's because I don't have a
Windows installation handy at the moment. 😬

## The traditional solution

Before Windows shipped ISOs with files larger than 4 GB, making a
bootable Windows USB for EFI was as simple as format the key as FAT32,
and just copying over the contents of the ISO to it. Example:

```sh
fdisk /dev/sdX # Make a single partition for the whole drive
mkfs.fat -F32 /dev/sdX1 # Format as FAT32

mkdir usb windows # Make some mount points
mount /dev/sdX1 usb
mount windows.iso windows

cp -rv windows/* usb # Copy contents

umount windows
umount usb
```

If your motherboard's EFI supports exFAT out of the box, you can replace
`mkfs.fat` by `mkfs.exfat` in the above script and that should work for
you with files larger than 4 GB. But in my experience, none of the
computers I tried this on supported directly booting from exFAT.

Nowadays [WoeUSB](https://github.com/WoeUSB/WoeUSB) seems like a good
solution to prepare Windows USB drives, but if you want to keep it
low-level, there's another solution, and it's easy, I promise.

## Splitting the ISO in two partitions

I found this quite unique solution in [this blog post](https://win10.guru/usb-install-media-with-larger-than-4gb-wim-file/).

It consists in making a 1 GB FAT32 partition on the USB, and using the
rest as NTFS, then copying everything from the ISO but the `sources`
directory to the FAT32 partition (only including `sources/boot.wim`),
and copying the whole ISO contents to the NTFS partition.

I'm not sure why this works, but it looks like Windows is able to handle
such a USB layout seamlessly, and it's by far the easiest solution out
there, because it doesn't require splitting the `install.wim` file, or
[installing and configuring another bootloader](https://willhaley.com/blog/windows-installer-usb-linux/)
to boot from a second partition (after all Windows installer's
bootloader is already capable of doing that by itself!).

Here's how to do it:

```sh
fdisk /dev/sdX # Make a 1 GB partition and another partition with the rest
mkfs.fat -F32 /dev/sdX1 # Format as FAT32
mkfs.ntfs --fast /dev/sdX2 # Format as NTFS

mkdir boot usb windows # Make some mount points
mount /dev/sdX1 boot
mount /dev/sdX2 usb
mount windows.iso windows

# Copy everything but the `sources` directory
find iso -mindepth 1 -maxdepth 1 -not -name sources -exec cp -rv {} boot \;

# Add `sources/boot.wim`
mkdir boot/sources
cp iso/sources/boot.wim boot/sources

cp -rv iso/* usb # Copy everything to the NTFS partition

umount windows
umount usb
umount boot
```

I hope you found this trick useful! And I wish you a smooth Windows
installation. 🎉
