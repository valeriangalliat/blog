macOS High Sierra <small>on a MSI H110M PRO-D, Skylake CPU and NVIDIA Pascal GPU</small>
========================================================================================
March 16, 2019

I recently decided to install macOS on my desktop computer, which I
originally built as a gaming PC. I didn't get the parts with the idea of
installing macOS on it, but I decided nevertheless to give it a try and
see if my build can support it. Turns out it was a success, and this
blog post will describe what was necessary to make it run smoothly!

Build
-----

First, here's the details of the machine build.

Motherboard
: [MSI H110M PRO-D](https://www.newegg.ca/Product/Product.aspx?Item=N82E16813130924)

CPU
: [Intel Core i5-6500 Skylake](https://www.newegg.ca/Product/Product.aspx?Item=N82E16819117563)

RAM
: [Kingston HyperX Fury 16GB DDR4 2133](https://www.newegg.ca/Product/Product.aspx?Item=N82E16820104676)

HDD
: [WD Blue 1TB 7200 RPM SATA 6Gb/s](https://www.newegg.ca/Product/Product.aspx?Item=N82E16822236339)

GPU
: [PNY GeForce GTX 1060](https://www.newegg.ca/Product/Product.aspx?Item=N82E16814133634)

PSU
: [EVGA 500 B1](https://www.newegg.ca/Product/Product.aspx?Item=N82E16817438012)

WiFi card
: [TP-Link TL-WDN4800 N900](https://www.newegg.ca/Product/Product.aspx?Item=N82E16833704133)

Why not Mojave?
---------------

I have a GTX 1060, so no Mojave for me. Indeed, NVIDIA didn't release
the macOS drivers for Mojave yet and Apple don't natively support
Maxwell and Pascal NVIDIA cards, since those are not used by any Apple
computer.

From the [tonymacx86 install Mojave post](https://www.tonymacx86.com/threads/unibeast-install-macos-mojave-on-any-supported-intel-based-pc.259381/):

> If using a GeForce GTX 1050, 1050 Ti, 1060, 1070, 1070 Ti, 1080, 1080 Ti,
> TITAN Pascal, and TITAN Xp Pascal graphics card or NVIDIA GeForce
> GTX 750, 750 Ti, 950, 960, 970, 980, 980 Ti, and TITAN X Maxwell
> graphics card, macOS Mojave graphics drivers are not natively supported.
> Alternate NVIDIA drivers are required.
>
> **Note: alternate NVIDIA graphics drivers are not available yet. If
> you have a Maxwell or Pascal based NVIDIA card, stay on High Sierra
> for now.**

[More on the topic](https://www.macrumors.com/2018/11/01/nvidia-comment-on-macos-mojave-drivers/).

Steps summary
-------------

Based on the [tonymacx86 guide for High Sierra](https://www.tonymacx86.com/threads/unibeast-install-macos-high-sierra-on-any-supported-intel-based-pc.235474/),
as well as a couple things from [this guide](https://medium.com/@dekablade01/installing-macos-siera-10-12-3-hackintosh-on-desktop-pc-15d077405478).

### Prepare the USB

1. Download High Sierra from the App Store. You more likely won't be
   able to find it by searching for it, but the [direct link](https://itunes.apple.com/us/app/macos-high-sierra/id1246284741?mt=12)
   still works. Found on [this Reddit thread](https://www.reddit.com/r/MacOS/comments/9c7rhf/cant_find_high_sierra_in_app_store/).
1. Create a tonymacx86 account to access the downloads.
1. Create a High Sierra bootable USB using [UniBeast](https://www.tonymacx86.com/resources/categories/tonymacx86-downloads.3/).
   Make sure to get the High Sierra version (8.3.2) and not the Mojave
   one (9.1.0). Initially I had the Mojave version and it wouldn't let
   me select the High Sierra installer even though it was there.
1. Put the [MultiBeast](https://www.tonymacx86.com/resources/categories/tonymacx86-downloads.3/)
   app on the USB as well, it's gonna be handy after the macOS
   installation to install the drivers. Make sure to get the High Sierra
   version (10.4.0) and not the Mojave one (11.0.1). Initially I had
   the Mojave version and ended up with an unbootable system after
   installing the drivers.
1. Put the [Clover Configurator](https://mackie100projects.altervista.org/download-clover-configurator/) app on the USB as well, it's gonna by handy later after the
   macOS installation to get the latest version of the Clover
   bootloader and configure it through a graphical interface.
1. Get the latest release of [USBInjectAll](https://bitbucket.org/RehabMan/os-x-usb-inject-all/downloads)
   extract it, and put the `USBInjectAll.kext` file from the `Release`
   directory into `EFI/CLOVER/kexts/Other` on the EFI partition of the
   USB. Without it, the installer would lost the connection to the USB
   drive and crash with a "stop" or "prohibited" sign. More on that
   later.
1. Eject the USB and plug it into the target computer. The guide says
   it's recommended to put it into a USB 2.0 port, but I still had
   USB issues regardless of the port (that's why USBInjectAll is needed
   above). Then it works seamlessly on USB 3.0 ports as well, including
   the front USB 3.0.

### Setup the BIOS

1. Go into the BIOS settings, for me by spamming the `<Del>` key on boot.
1. Reset the BIOS form whatever custom settings were there, for my by
   going in "Save &amp; Exit" and selecting "Restore Defaults".
1. In "Overclocking", "CPU Features", make sure "Intel VT-D Tech" is
   set to "Disabled". Same for "CFG Lock".
1. In "Advanced", "Super IO Configuration", "Serial(COM) Port 0 Configuration",
   set "Serial(COM) Port0" to "Disabled".
1. In "Advanced", "USB Configuration", make sure "XHCI Hand-off" is set
   to "Enabled".
1. Then in "Save &amp; Exit", actually save and exit.

### Install macOS

1. Boot on the USB, for me by spamming the `<F11>` key on boot, and
   selecting my USB key in the menu. I have a weird issue where I need
   to keep spamming the `<F11>` key just after I select the USB in the
   boot menu otherwise it sometimes just boots from the HDD.
1. In Clover, go in "Options", "ACPI patching", "DSDT fix mask [0x00000000]"
   and tick "Fix USB". I needed that on top of USBInjectAll, otherwise I
   would run systematically into the [stop sign](https://www.tonymacx86.com/threads/unibeast-8-2-10-13-4-stop-sign-issue.249150/)
   (also known as [prohibited sign](https://www.tonymacx86.com/threads/solved-prohibited-or-stop-sign-when-booting-usb-installer.174496/))
   [issue](https://www.reddit.com/r/hackintosh/comments/9k8zof/what_does_a_stop_sign_means_when_trying_to_boot/).
   "Fix USB" alone (without USBInjectAll) wasn't enough either, both
   needed to be present for me to be able to boot.
1. Run "Boot macOS Install from Install macOS High Sierra".
1. Open "Disk Utility" in "Utilities" in the top bar. Partition and
   format the disk to your liking. For me, I put 500 GB for macOS and
   left a 500 GB partition for a Windows dual boot. I named the first
   partition "Hackintosh", so I'll refer to the installation partition
   as Hackintosh in the next steps. **Note:** if you plan to use Adobe
   Creative Cloud apps, don't take the case-sensitive option whether
   you're taking APFS or Mac OS Extended, they require to be on a
   case-insensitive filesystem.
1. Complete the installation on the partition of your choice. The system
   will automatically reboot.
1. Boot on the USB again, and this time pick "Boot macOS Install from
   Hackintosh". You'll then have an Apple logo with a progress bar and
   time estimate. At the end it reboots automatically.
1. Boot on the USB again, and this time pick "Book macOS from Hackintosh".
   You'll be able to finish the installation process by configuring your
   system, and end up on the desktop.

### Post-installation

#### Drivers with MultiBeast

1. On the installation USB that should be automatically mounted, open
   the MultiBeast app. The selected drivers are inspired by
   [this post](https://www.tonymacx86.com/threads/macos-sierra-on-a-skylake-pc-mb-h110m-pro-d-cpu-i5-6400-gpu-gtx960-ram-ddr4-8gb.210098/).
1. In "Quick Start", select "UEFI Boot Mode".
1. Don't select anything in "Drivers", "Audio", we'll take care of that later.
   (I tried the 2.8.6 version before and had issues with crackling sound).
1. In "Drivers", "Disk", select "3rd Party SATA" and "Intel Generic AHCI SATA".
1. In "Drivers", "Misc", select "FakeSMC Plugins" and "NullCPUPowerManagement".
1. In "Drivers", "Network", in "Realtek" select "RealtekRTL8111 v2.2.2".
1. In "Drivers", "USB", select "3rd Party USB 3.0", "7/8/9 Series USB Support",
   "Remove XHCI USB Port Limit" and "USBInjectAll". USBInjectAll is
   necessary here, without it my keyboard and mouse wouldn't work after
   the reboot.
1. Don't select anything in the "Bootloaders" section, we're going to
   install the latest version of Clover manually after because we'll
   need some extra customization of the Clover installation for the GPU.
1. In "Build", click "Install".

#### Bootloader with Clover

1. Also on the installation USB, open Clover Configurator.
1. In "Install/Update Clover", click "Check Now", then "Download".
1. In the Clover installer, click "Continue" twice, then click on
   "Customize".
1. Tick "Clover for UEFI booting only", "Install Clover in the ESP",
   "Install RC scripts on target volume".
1. In "UEFI Drivers", tick "ApfsDriverLoader-64" if you used an APFS
   filesystem, and tick "AptioMemoryFix-64" (would stay [stuck at "End randomseed" on boot](https://www.tonymacx86.com/threads/solved-end-randomseed-reboot.249537/)
   otherwise).
1. Click "Install".
1. Then, back in Clover Configurator, in "Kexts Installer", set "OS
   Version" to "Other", tick "Lilu", "WhateverGreen" and "AppleALC" and
   click "Download".
1. In Clover Configurator, click on the home button at the bottom, and
   load `EFI/EFI/CLOVER/config.plist`.
1. In "Boot", in "Arguments", add `nvda_drv=1`.
1. In "Devices", in "Audio", set "Inject" to `11`. That's what works for
   me at least since I have Realtek ALC887 codec, from some trial and error
   on [AppleALC supported codecs](https://github.com/acidanthera/AppleALC/wiki/Supported-codecs).
1. Optional, in "GUI", in "Hide Volume", I added "Preboot" to hide the
   bootloader entries "Boot macOS Install Prebooter from Prebot" and
   "Boot FileVault Prebooter from Preboot".
1. In "SMBIOS", use the select menu to auto fill the fields using the
   model of your choice. I used "iMac17,1". This step doesn't seems to
   be necessary, looks like it mostly customizes what you see in the
   "About This Mac" window.
1. In "System Parameters", set "Inject Kexts" to "Yes" (that's
   important, when it's on "Detect" I have a black screen on boot), and
   tick "NvidiaWeb". "Inject System ID" should be already ticked.

#### NVIDIA driver

I used [nVidia Update](https://github.com/Benjamin-Dobell/nvidia-update)
to install and patch the latest drivers (apparently the official
installer needs patching to be able to run for some reason).

```sh
bash <(curl -s https://raw.githubusercontent.com/Benjamin-Dobell/nvidia-update/master/nvidia-update.sh)
```

#### Note on audio

I could find no way to get the HDMI audio working properly. I've managed
to get *only* the HDMI audio working (still no clue how) but even then,
it would not let me change the volume from the system, and my screen
doesn't let me change the volume from its interface, so it was basically
always maxed out, which was unusable. Also since this wouldn't even let
me use other audio devices than HDMI ones so it's definitely not usable
for me.

I've also checked this [Hackintosh HDMI audio](https://hackintosher.com/guides/hackintosh-hdmi-audio-displayport-sound/)
guide but it didn't change anything, also seems to be outdated and
replaced by [this guide](https://hackintosher.com/forums/thread/nvidia-hdmi-audio-with-applealc.193/)
which is essentially what I'm doing already (Lilu and AppleALC kexts).

They do mention that not all ports might be working for audio, but my
card only have one HDMI port so there's not much more I can do here.

Other than that, this [Audio Mechanic](https://www.reddit.com/r/hackintosh/comments/4sil5p/audio_mechanic_old_patchfix_removal_applealc/)
thread on Reddit have been pretty useful for me to figure out audio things
(other than HDMI audio).

#### You're done!

After this, you should be able to reboot, and from the Clover bootloader
on your HDD, select "Boot macOS from Hackintosh" (in my case my
partition is named Hackintosh), and have a fully functional Hackintosh!

Updating
--------

Actually, you're not that done. Soon enough you'll need to install
updates. I'm not sure what exactly I fucked up with the above setup, but
updates don't work 100% out of the box, but it's not bothering me enough
so that I go try to make it perfect.

Basically, when you get an update, do the usual "Download & Restart",
which will show a black "Installing" screen that will automatically
reboot after a little bit.

Upon reboot, **boot on the UniBeast USB** and not on your regular
Clover. For me, if I use my regular clover, the update just hangs and I
couldn't find a way to debug that.

Make sure to boot (from the USB) on the "Install macOS from Hackintosh"
(in my case my partition is named Hackintosh) and not the usual "Boot
macOS from Hackintosh", or this will just boot to the regular system
without updating. Also don't pick anything with "Preboot" as it won't be
any useful.

You will then see a progress bar with an estimate of the time remaining.
When it's done, it's automatically going to reboot. Now you can use your
regular Clover to boot (if everything went well, you will notice that
the "Install macOS from Hackintosh" entry is gone).

The graphics might not be working after the update. For this, run
`nvidia-update --force`. You need `--force` since if the driver version
is still the same, the script will skip installation, and here we need
to force it to install the driver again regardless if there's a new
version.

After this, reboot and you should be set!

Bonus: Windows dual boot
------------------------

### Prepare the USB

1. [Download Windows 10 ISO](https://www.microsoft.com/en-us/software-download/windows10ISO).
   Make sure you take the "April 2018 Update" and not the "October 2018
   Update" since the latter for some reason include files that are more
   than 4 GB which then won't be able to be written on the FAT32 USB
   partition.
1. If you're using macOS, you can use [Boot Camp Assistant](https://www.windowscentral.com/how-create-windows-10-installer-usb-drive-mac)
   to prepare the USB for you.
1. Otherwise, format the USB with a MBR partition table and a FAT32
   partition, and just copy the contents of the ISO to the FAT32
   partition.

### Install Windows

Boot on the USB, and in the Windows installer, make sure to select the
partition that you already prepared for Windows. After the installation,
you should be able to pick "Boot Microsoft EFI Boot from EFI" in Clover,
and you're done!

I expected Windows to somehow override my bootloader and having to
reinstall Clover, but I did not have to, all it did was creating its
16 MB "Microsoft Reserved Partition" right after my Hackintosh
partition, and used the rest of the space for Windows, and it didn't
mess at all with my bootloader, only added more options on the EFI
partition.
