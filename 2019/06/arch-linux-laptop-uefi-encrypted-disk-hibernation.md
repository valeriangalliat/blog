# Arch Linux laptop, UEFI, encrypted disk and hibernation
June 8, 2019

Based on [this Gist](https://gist.github.com/mattiaslundberg/8620837),
with hibernation added.

Updated on March 27, 2020.

## Installer USB

Download the [latest ISO](https://www.archlinux.org/download/) and
`dd` it to your USB drive as per the [official documentation](https://wiki.archlinux.org/index.php/USB_flash_installation_media).

With GNU/Linux (replace `/dev/sdx` with the proper drive):

```sh
dd if=archlinux.iso of=/dev/sdx bs=4M status=progress oflag=sync
```

Then boot on the USB.

If it won't boot, you might need to disable Secure Boot in your
motherboard settings.

## Installation

Based on the [install guide](https://wiki.archlinux.org/index.php/installation_guide).

Connect to Wi-Fi if necessary.

```sh
wifi-menu
```

Make sure system clock is accurate.

```sh
timedatectl set-ntp true
```

Partition disk. I will go with a 256 MiB mixed EFI and boot partition,
and the rest for a LUKS container, containing a 8 GiB swap (the size of
my RAM to support hibernation) and the rest for the system.

Based on [encrypting an entire system](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS).

```
fdisk /dev/sdx
```

```
Command: n
Partition number: (default)
First sector: (default)
Last sector: +256M

Command: t
Partition type: 1 # EFI System

Command: n
Partition number: (default)
First sector: (default)
Last sector: (default)

Command: w
```

```sh
mkfs.fat -F32 /dev/sdx1
cryptsetup luksFormat /dev/sdx2
cryptsetup luksOpen /dev/sdx2 luks
pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate -L 8G vg0 --name swap
lvcreate -l 100%FREE vg0 --name root
mkfs.ext4 /dev/vg0/root
mkswap /dev/vg0/swap
```

Mount partitions.

```sh
mount /dev/vg0/root /mnt
swapon /dev/vg0/swap
mkdir /mnt/boot
mount /dev/sdx1 /mnt/boot
```

Install the base system together will necessary packages.

```sh
pacstrap /mnt base base-devel linux linux-firmware grub efibootmgr lvm2 netctl dialog wpa_supplicant dhcpcd
```

`efibootmgr` is necessary for GRUB to add the EFI boot entry, `lvm2` for
being able to mount LVM devices (here, root partition), `dialog` and
`netctl` for the `wifi-menu` command, `wpa_supplicant` for WPA, and
`dhcpcd` to enable DHCP.

I also tend to add `zsh`, `vim` and `git` here as well but they're not
strictly necessary. I also tend to add `man-db`, `man-pages` and
`texinfo` to get documentation as well.

Then, generate `/etc/fstab`.

```
genfstab -U /mnt >> /mnt/etc/fstab
vim /mnt/etc/fstab
```

Change `relatime` to `noatime` on the root partition to reduce SSD wear.

Add `tmpfs /tmp tmpfs rw,noatime,nodev,nosuid 0 0` if you want to keep
`/tmp` in RAM.

`chroot` in the system.

```sh
arch-chroot /mnt
```

Setup the timezone (Montreal for me), and synchronize hardware clock.

```sh
ln -sf /usr/share/zoneinfo/America/Montreal /etc/localtime
hwclock --systohc
```

Uncomment the locale you desire in `/etc/locale.gen` (`en_CA.UTF-8` for
me, as well as `en_GB.UTF-8` to have 24-hour clock format).

```sh
locale-gen
echo 'LANG=en_CA.UTF-8' > /etc/locale.conf
echo 'LC_TIME=en_GB.UTF-8' >> /etc/locale.conf
```

Set the hostname.

```sh
echo myhostname > /etc/hostname
```

Edit `/etc/mkinitcpio.conf` to add `encrypt` and `lvm2` to `HOOKS`
before `filesystems`. Also add `resume` after `filesystems` to support
resuming from hibernation.

```sh
# Before
HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)

# After
HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems resume keyboard fsck)
```

```sh
mkinitcpio -P
```

Setup the root password.

```
passwd
```

Edit `/etc/default/grub` to configure the encrypted disk by adding
`cryptdevice=/dev/sdx2:luks:allow-discards` (again, replace `/dev/sdx`
with the proper drive) to `GRUB_CMDLINE_LINUX`.  I also added
`resume=/dev/vg0/swap` for supporting hibernation (resuming from swap).

```sh
GRUB_CMDLINE_LINUX="cryptdevice=/dev/sdx2:luks:allow-discards resume=/dev/vg0/swap"
```

Install GRUB and generate its configuration. Since I decided to have a
shared EFI and boot partition, I need to tell GRUB that the EFI
directory is `/boot`.

On my latest installation (not sure if because new version of software
or because different hardware), I also had to add the `--bootloader-id`
option otherwise the system was just unable to boot, while I never had
any issue without it before on UEFI systems.

I've also seen systems where `grub-install` wouldn't be able to add a
boot entry and it needed to be manually added from the motherboard
settings (e.g. selecting partition and path to `grubx64.efi`).

```sh
grub-install --bootloader-id=Arch --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
```

Exit from `chroot`, teardown and reboot.

```sh
exit
umount -R /mnt
swapoff -a
reboot
```

## Post installation

Connect to Wi-Fi if necessary.

```sh
wifi-menu
```

Automatically connect to available known networks on the Wi-Fi
interface (replace `wlp2s0` with your Wi-Fi interface).

```sh
systemctl enable netctl-auto@wlp2s0
```

Enable time synchronization.

```sh
timedatectl set-ntp true
```

Add user and set password.

```sh
useradd -m -G wheel -s /usr/bin/zsh val
passwd val
```

Install the packages you need. Here's my personal selection.

* `tlp` for out of the box power management
* `xf86-video-intel` graphics driver
* `xorg-server`
* `xorg-xset` as I use it in my `.xinitrc` for setting key repeat delay
* `xorg-xrandr` to setup multiple monitors
* `noto-fonts` main system font
* `noto-fonts-cjk` and `noto-fonts-extra` optionally to really see every
  character online
* `noto-fonts-emoji` because emojis
* `ttf-liberation` for proper web fonts support
* `lightdm` display manager
* `lightdm-mini-greeter` (from AUR)
* `i3-gaps` window manager
* `i3lock` locker
* `i3blocks` status bar
* `xfce4-terminal`
* `dmenu`
* `firefox`
* `picom` for `xfce4-terminal` background transparency
* `alsa-utils` for native audio
* `pulseaudio` sound server
* `pulseaudio-alsa` for PulseAudio to control ALSA
* `pulseaudio-bluetooth` for PulseAudio to control Bluetooth devices
* `pavucontrol` for an audio GUI
* `bluez` for Bluetooth support
* `blueberry` for a Bluetooth GUI
* `feh` image viewer and background setter
* `maim` and `imagemagick` as my custom `i3locks` locker depends on them
* `xsel`, `xclip` for clipboard management
* `xorg-xbacklight` or `light` for changing screen brightness (my
  experience is that depending on the laptop, one of them will work and
  the other one won't)
* `acpi` to get battery information (the i3blocks `battery` blocklet
  depends on it)
* `openssh`
* `redshift`, started in my `.xinitrc`, to adjust screen color
  temperature based on time of day
* `jq` as my [script](https://github.com/valeriangalliat/dotfiles/blob/master/bin/i3-focused-window-cwd)
  to preserve working directory when opening a new terminal depends on it
* `xss-lock`, started in my `.xinitrc`, auto lock on screen sleep,
  suspend and hibernate
* `zip`, `unzip`
* `ack`

For some reason PulseAudio might require a reboot to work.

### TLP

```sh
systemctl enable tlp
systemctl start tlp
```

### LightDM

In `/etc/lightdm/lightdm.conf`, set `greeter-session=lightdm-mini-greeter`
or whatever is the greeter of your choice.

If using `lightdm-mini-greeter`, modify
`/etc/lightdm/lightdm-mini-greeter.conf` to set the user.

I use LightDM so that my X session is started as a logind GUI session
as opposed to being considered to be a TTY if I would use `xinit`. This
allows something like `xss-lock` to report idle status to logind so that
logind can properly run the configured `IdleAction`.

I usually set `IdleAction=suspend` in `/etc/systemd/logind.conf` so that
my system suspends after 30 minutes of inactivity.

It seems there's no way to upgrade a logind TTY session to a graphical
session so that it would allow to report the idle hint, and since for a
TTY session the idle status doesn't use the idle hint but uses the last
TTY input instead, it is always considered to be idled if a X session is
started with `xinit` or `startx`, which is why I resorted to use a
display manager.

### Bluetooth

Enable Bluetooth.

```sh
systemctl enable bluetooth
systemctl start bluetooth
```

In practice I usually don't enable Bluetooth and I `systemctl start
bluetooth` and `systemctl stop bluetooth` as I need it.

I also load the `switch-on-connect` PulseAudio module, to make sure the
default sink switches to a newly connected Bluetooth speaker, as
highlighted [here](https://forum.manjaro.org/t/audio-doesnt-switch-to-newly-connected-bluetooth-speaker/90834).

```sh
echo 'load-module module-switch-on-connect' > /etc/pulse/default.pa.d/switch-on-connect.pa
```

### Touchpad

I add the following to `/etc/X11/xorg.conf.d/40-libinput.conf` to have
the touchpad work the way I like it to (natural scrolling and having the
whole surface clickable).

```
Section "InputClass"
        Identifier "libinput clickfinger"
        Driver "libinput"
        Option "ClickMethod" "clickfinger"
        Option "NaturalScrolling" "true"
EndSection
```

### Auto hibernate after sustained suspend

If you want to have the system hibernate after being suspended for some
time (3 hours by default as per `/etc/systemd/sleep.conf`
`HibernateDelaySec`), run the following:

```sh
ln -s /usr/lib/systemd/system/systemd-suspend-then-hibernate.service /etc/systemd/system/systemd-suspend.service
```

The advantage of this solution is anything that would normally just
suspend will suspend then hibernate, which is an easy way to make sure
that in any case the system will hibernate if suspended for more than 3
hours to save battery.

Hack from [this Reddit thread](https://www.reddit.com/r/Fedora/comments/auctgi/setting_systemctl_suspendthenhibernate_as_default/).

### DisplayLink adapter for multiple monitors and Ethernet

On my work laptop, installing `displaylink` and `evdi` from the AUR just
worked out of the box.

### Final touch

After logging in with my regular user, I finish the configuration by
cloning and installing my [dotfiles](https://github.com/valeriangalliat/dotfiles).

```sh
git clone https://github.com/valeriangalliat/dotfiles.git
cd dotfiles
make i3 i3blocks zsh vim git net x11 picom xfce4-terminal
```

Lastly, in Firefox I add the Vimium-FF and uBlock Origin extensions.

And here you go, a somewhat minimalist Arch Linux setup with everything
needed to have a smooth laptop experience!
