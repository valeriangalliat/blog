# Super fast boot on Linux with EFISTUB 🚀
Boot without an intermediate bootloader, with encryption and hibernation  
August 10, 2021

My friend [Damien](https://www.damiengonot.com/) was recently installing
Arch Linux on a new rig, and while doing so he mentioned to me that he
installed it without GRUB.

So I ask him what other bootloader he used, and he's like, no, I didn't
use a bootloader, just `efibootmgr`.

I didn't know this was possible, so I looked into it and quickly found
about EFISTUB.

## What is EFISTUB

[EFISTUB](https://wiki.archlinux.org/title/EFISTUB) allows "EFI firmware
to load the kernel as an EFI executable". It was introduced in Linux
3.3, released in 2012. I should have known about that before. 😅

As the wiki says a bit later:

> UEFI is designed to remove the need for an intermediate bootloader
> such as GRUB. If your motherboard has a good UEFI implementation, it
> is possible to embed the kernel parameters within a UEFI boot entry
> and for the motherboard to boot Arch directly.

## Configuring EFISTUB

With `efibootmgr`, you can add an EFI boot entry that contains all the
parameters you need to properly boot the kernel, including in my case,
LUKS encryption and hibernation.

Here's the command I used:

```sh
efibootmgr \
    --disk /dev/sda \
    --part 1 \
    --create \
    --label Linux \
    --loader /vmlinuz-linux \
    --unicode 'cryptdevice=/dev/sda2:luks:allow-discards root=/dev/vg0/root resume=/dev/vg0/swap rw initrd=\initramfs-linux.img'
```

Here, my EFI partition is `/dev/sda1`, and `/dev/sda2` is a LUKS
encrypted partition that uses LVM to have a `root` and a `swap` volume.
The swap is used to suspend to disk (hibernate). This setup is explained
in more details [in this post](2019/06/arch-linux-laptop-uefi-encrypted-disk-hibernation.md#installation).

If your motherboard has a compliant EFI implementation, that's all you
should need to remove the need for an intermediate bootloader!

After rebooting, it worked flawlessly, and what stroke me was how fast
it was to boot! Definitely worth giving it a shot. Also don't forget to
`pacman -Rns grub` if it works for you. 😛

**Fun fact:** this is so simple to do you can fit the previous command
in a tweet!

> TIL you can use Linux EFISTUB to boot without an intermediate
> bootloader (here with encryption and hibernation).
>
> ```sh
> efibootmgr -d /dev/sda -p 1 -c -l /vmlinuz-linux -u 'cryptdevice=/dev/sda2:luks:allow-discards root=/dev/vg0/root resume=/dev/vg0/swap rw initrd=\initramfs-linux.img'
> ```
>
> --- [@valeriangalliat](https://twitter.com/valeriangalliat), [July 25, 2021](https://twitter.com/valeriangalliat/status/1419304289751678980)
