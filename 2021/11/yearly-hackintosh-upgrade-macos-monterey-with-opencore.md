# Yearly Hackintosh upgrade: macOS Monterey with OpenCore
November 16, 2021

Exactly a year ago, I [migrated my Hackintosh from Catalina to Big Sur,
and from Clover to OpenCore][big-sur-post]. Apple recently released
Monterey, so it's the first time for me doing a major upgrade since I'm
using OpenCore.

[big-sur-post]: ../../2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md

So far, OpenCore has been a breeze to work with. I'm not sure if it's
because it's a really high quality piece of software and ecosystem in
general, or if it's because it forced me to learn a lot of low-level
details in order to have a working Hackintosh, but both probably have a
lot to do with this.

I've been upgrading seamlessly all year long through Big Sur updates
as smoothly as if I was using a "real Mac". Upgrading to Monterey might
have been as easy (with the addition of upgrading OpenCore and all kexts
to their latest version, which I should probably do on minor updates
even though I've been getting away perfectly fine by ignoring that all
year long), but I like to take a new major version as an opportunity to
reinstall my system from scratch and start from a clean slate.

## My paranoid upgrade procedure

I don't do cowboy-style upgrades or installations anymore, because I've
bricked my system too many times and while I've always managed to fix it
more or less gracefully, it's always been a somewhat stressful,
uncomfortable and time-consuming experience.

I'm also constantly scared of losing critical data by mistake, so
I tend to back up everything more often than not. Here's the procedure I
follow to upgrade my system making sure I always have a bootable machine
and without risking data loss.

* I make space for an empty partition on one of my drives to test the
  new system.
* I make sure that my current system has a full up-to-date backup on an
  external drive *that I keep unplugged* until I'm back in a fully
  stable state.
* Because I make the above backup with Time Machine and I don't trust
  myself (nor macOS) to 100% reliably set up Time Machine on the new
  system without fucking up the previous backups, I also do a second
  (manual) backup on another drive. That step is probably unnecessary.
* I install the new system to the test partition, tweaking the OpenCore
  configuration, drivers and kexts as necessary.
* Once the test system is installed and running, I check that everything
  I need works as expected (display, audio, network, sleep) or otherwise
  find how to fix it, documenting everything along the way especially
  for fixes that live outside the EFI directory.
* When all is well, I reboot and perform the install on my main
  partition.
* After the install, I restore whatever I need from my previous backup.
  I still keep the rest of the backup (or at least parts of it) for 6
  months or so just in case. That came handy a couple of times in the
  past. I also wipe the temporary test installation.
* Finally, I write a blog post. 😄

This is a bit more time-consuming than straight up performing the
installation, and some of those steps might be a bit overkill, but I
like going the extra length to make sure everything is backed up and
redundant to prevent any unexpected issue and minimize the impact of a
program or human error.

## Upgrade log

I'll list all the steps I took in that upgrade, which are very similar
to my [Big Sur post][big-sur-post], but I'll note here the differences.
Here's the relevant details of my machine:

Motherboard
: [MSI H110M PRO-D](https://www.newegg.ca/p/N82E16813130924) (RTL8111H Ethernet chipset,  Realtek ALC887 audio chipset)

CPU
: [Intel Core i5-6500 Skylake](https://www.newegg.ca/p/N82E16819117563)

GPU
: [GIGABYTE Radeon RX 580](https://www.newegg.ca/p/N82E16814932247)


Still following [the OpenCore guide](https://dortania.github.io/OpenCore-Install-Guide/),
I:

* downloaded the latest [`OpenCorePkg`](https://github.com/acidanthera/OpenCorePkg/releases)
  (0.7.5 in my case),
* downloaded [ProperTree](https://github.com/corpnewt/ProperTree) to edit `.plist` files,
* downloaded Monterey from the App Store,
* formatted a USB drive as Mac OS Extended (HFS+) with a GUID partition
  map,
* ran `sudo /Applications/Install\ macOS\ Monterey.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume`
  (where `MyVolume` was... my volume) to create the installation media,
* mounted the EFI partition of the USB key by running `sudo diskutil mount /dev/diskXsY`
  where `X` was the drive number and `Y` the partition number (found
  using `diskutil list`),
* copied OpenCore `DEBUG` version to it and removed unneeded files as
  instructed by the guide,
* added `HfsPlus.efi` from the [`OcBinaryData` repo](https://github.com/acidanthera/OcBinaryData/blob/master/Drivers/HfsPlus.efi),
* added [VirtualSMC](https://github.com/acidanthera/VirtualSMC/releases),
  [Lilu](https://github.com/acidanthera/Lilu/releases),
  [WhateverGreen](https://github.com/acidanthera/WhateverGreen/releases),
  [AppleALC](https://github.com/acidanthera/AppleALC/releases) and
  [RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X/releases)
  kexts.

Now here's what got easier than my first OpenCore installation.

### SSDTs

I just had to copy `SSDT-PLUG.aml`, `SSDT-EC.aml` and `SSDT-USBX.aml`
from the `ACPI` directory of my [previous installation](../../2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md#installing-macos-big-sur-with-opencore-and-the-issues-i-encountered),
the [first](https://dortania.github.io/Getting-Started-With-ACPI/Universal/plug.html)
[two](https://dortania.github.io/Getting-Started-With-ACPI/Universal/ec-fix.html)
which I had built back then with
[SSDTTime](https://github.com/corpnewt/SSDTTime), and the latter being
the [prebuilt one](https://github.com/dortania/OpenCore-Post-Install/blob/master/extra-files/SSDT-USBX.aml)
that didn't need to be updated.

### USB map

I could just copy `USBMap.kext` [from my previous installation](../../2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md#generating-the-usb-map)
to have my USB ports supported right away without having to generate it
again or to deal with `XhciPortLimit` and USBInjectAll. Sweet.

### Making the `config.plist`

I started again from OpenCore's `Sample.plist` and applied the same
tweaks from the [Skylake](https://dortania.github.io/OpenCore-Install-Guide/config.plist/skylake.html#deviceproperties)
guide. I'm not sure if I could have reused my previous `config.plist` or
not, but I wanted to start fresh and up-to-date.

Everything was the same as [my previous installation](../../2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md#installing-macos-big-sur-with-opencore-and-the-issues-i-encountered)
so I won't include it here.

The only difference was that I left `XhciPortLimit` to `False` as the
guide mentions to disable it if running macOS 11.3 or newer, plus I
already have my USB map so it shouldn't be needed either way.

I also had [an issue last time](../../2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md#booting-on-macos-installer-just-reboots-into-recovery)
where I needed to set `SecureBootModel` to `Disabled` instead of the
`Default` mentioned in the guide, but just to check, I left it to
`Default` this time and didn't have any issue, meaning I can now benefit
from Apple Secure Boot!

### Removing previous fixes

For Big Sur, I [needed to add](../../2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md#no-wi-fi-on-big-sur)
`IO80211HighSierra.kext` to get my Wi-Fi to work but I'm now connected
over Ethernet so I didn't need to include it. It's a good thing because
[it doesn't work on Monterey](https://github.com/khronokernel/IO80211-Patches/issues/4)
(at least for now, I tried and had the same issue).

Also I've had [an issue last time](../..2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md#can-t-find-my-sata-drives-in-the-macos-installer)
that required a `CtlnaAHCIPort.kext` in order to see my SATA drives in
the installer, but that wasn't required anymore so I left it alone (it
actually prevented the installer to boot if it was there).

### Finalizing

Once everything was working, I copied OpenCore to my SSD's EFI directory,
and applied the [cosmetic tweaks](../../2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md#cosmetic-tweaks)
including putting the files from the OpenCore `RELEASE` version,
removing the debug and verbose settings, and adding `OpenCanopy.efi` for
a nice UI.

I still needed to [patch the EDID of my screen to force it in RBG mode](../../2020/10/too-much-contrast-external-screen-macos-catalina.md),
and the [`patch-edid.rb`](https://gist.github.com/adaugherity/7435890)
method still works!

After that, I didn't need to do *any* tweak at the system configuration
level, everything works out of the box including CPU power management
and sleep. Power Nap also works like a charm but I turned it off just
because it's not useful to me.

Since my system drive was named the same as my previous installation,
Time Machine was able to continue the existing backup and I kept my full
Time Machine history! Had I renamed the drive, it seems that I could
have used `tmutil inheritbackup` and `tmutil associatedisk` to help with
that.

## Wrapping up

If it wasn't for a [totally unrelated hardware issue](computer-sleep-issues-power-button-not-responding.md) that happened
around the same time I performed the upgrade, migrating to Monterey with
OpenCore was a straightforward and painless procedure and I didn't
encounter any hiccup.

If you too are upgrading your Hackintosh to Monterey, I hope it went as
smooth for you as it did for me!
