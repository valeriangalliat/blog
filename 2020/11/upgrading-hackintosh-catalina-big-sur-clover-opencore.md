Upgrading my Hackintosh from Catalina to Big Sur, and from Clover to OpenCore
=============================================================================
November 14, 2020

So this is that exciting time of the year where Apple releases a new
macOS version. Upgrading to Big Sur was the perfect opportunity for me
to start my Hackintosh from a clean slate, and use a different
bootloader.

So far, I've been using Clover, first on [High Sierra][high-sierra],
then I switched my unsupported NVIDIA graphic card to a supported AMD
one in order to [upgrade to Catalina][catalina]

[high-sierra]: ../../2019/03/macos-high-sierra-msi-h110m-pro-d-skylake-nvidia-pascal.md
[catalina]: ../10/upgrade-hackintosh-high-sierra-catalina.md

One month later, I'm here again, upgrading to Big Sur. I tried upgrading
Clover first, like the last time for Catalina (where the upgrade was
nearly seamless) but this time I realized that they made some changes
that would require me to update my current configuration in order for it
to work.

So I figured if I had to configure something, it might as well be OpenCore.

## Why OpenCore?

If I was to make a comparison, I would say that OpenCore is to Clover
what Arch is to Ubuntu.

In the way that with Clover, like with Ubuntu, you don't need to know a
lot to have it working, which is convenient and was great for me to get
started with Hackintoshes. I could just use Clover installer and tick
more or less randomly stuff there based on stuff I read online, and then
do the same thing with MultiBeast, tweak a couple things with Clover
Configurator and that would get the job done.

I'm not saying that it was easy, far from it, it took a lot of effort to
get to the proper configuration of all of those tools in order for my
Hackintosh to work, but I didn't have to really *understand* much, it
was more a matter of trial and error, and patience.

The downside to this approach though, is that when something doesn't
work, or when something breaks, well since you don't know much about
what's going on, you're kinda fucked.

And I don't blame Clover for this, FWIW you *can* learn the underlying
details of Clover, and maybe avoid using MultiBeast and so on, but I
find that harder when the seemingly "easy" option is right there under
my nose, and it seems to be the most encouraged way.

With OpenCore, like with Arch, the main, recommended way (and maybe the
only way) is to take a deep breath, and follow a detailed manual on how
to install and configure everything yourself, in a mostly manual way.
But they make that *easier* as far as learning is concerned by being
smaller and simpler systems to understand!

In other words, you don't need to learn a lot about Ubuntu or Clover to
get them to work but if you were to want to learn them, that would be a
massive task as they're such complex systems (which is a side product of
being easy to use without learning). But while you need to learn how
Arch and OpenCore work to get them running, that also makes them much
easier to learn by being far less complex.

OpenCore required me to learn a lot on how Hackintoshes work, as well as
about devices, chipsets, firmwares in general, and how macOS deal with
those.

The [OpenCore Install Guide][guide] is amazing at teaching
everything that you need to understand, especially they not only tell
you what to do, but why you do it, and thanks to it, I could
install and configure only the things that I really needed for my
particular system to work. I know everything that's there because I was
required to put it there myself, and I know everything that was changed
in the configuration because I had to configure it myself.

[guide]: https://dortania.github.io/OpenCore-Install-Guide/

This means that if something breaks, it's going to be easier to
identify, because I know precisely what parts are there, and what's
their purpose, since I was required to make the decision for myself to
put them there. And there's less parts overall because I added only the
ones I need!  Obviously it's easier finding an issue in a handful of
parts that you know, rather than in a fuckton of parts that you have no
clue what they do and what put it there.

Now that I told you why I'm interested to move to OpenCore, here's how I
did it. And it was much easier than I expected.

## Installing macOS Big Sur with OpenCore <small>and the issues I encountered</small>

First, here's the relevant details of my machine:

Motherboard
: [MSI H110M PRO-D](https://www.newegg.ca/Product/Product.aspx?Item=N82E16813130924) (RTL8111H Ethernet chipset,  Realtek ALC887 audio chipset)

CPU
: [Intel Core i5-6500 Skylake](https://www.newegg.ca/Product/Product.aspx?Item=N82E16819117563)

Wi-Fi card
: [TP-Link TL-WDN4800 N900](https://www.newegg.ca/Product/Product.aspx?Item=N82E16833704133) (Atheros AR9380 chipset)


I followed [the guide][guide], so as instructed for my specific system, I:

* downloaded the latest [`OpenCorePkg`](https://github.com/acidanthera/OpenCorePkg/releases)
  (0.6.3 at the time I did that),
* downloaded [ProperTree](https://github.com/corpnewt/ProperTree) to edit `.plist` files,
* downloaded Big Sur from the App Store,
* formatted a USB drive as Mac OS Extended (HFS+) with a GUID partition
  map (I learnt that from Disk Utility, this automatically creates a
  209.7 MB EFI partition on the drive),
* ran `sudo /Applications/Install\
  macOS\Catalina.app/Contents/Resources/createinstallmedia --volume
  /Volumes/MyVolume` (where `MyVolume` was... my volume) to create the
  installation media,
* mounted the EFI partition of the USB key by running `sudo diskutil
  mount /dev/diskXsY` where `X` was the drive number and `Y` the
  partition number (found using `diskutil list`),
* copied OpenCore `DEBUG` version to it and removed unneeded files as
  instructed by the guide,
* added `HfsPlus.efi` from the [`OcBinaryData` repo](https://github.com/acidanthera/OcBinaryData/blob/master/Drivers/HfsPlus.efi),
* added [VirtualSMC](https://github.com/acidanthera/VirtualSMC/releases),
  [Lilu](https://github.com/acidanthera/Lilu/releases),
  [WhateverGreen](https://github.com/acidanthera/WhateverGreen/releases),
  [AppleALC](https://github.com/acidanthera/AppleALC/releases) and
  [RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X/releases)
  kexts,
* built and added [SSDT-PLUG](https://dortania.github.io/Getting-Started-With-ACPI/Universal/plug.html)
  and [SSDT-EC](https://dortania.github.io/Getting-Started-With-ACPI/Universal/ec-fix.html),
  using [SSDTTime](https://github.com/corpnewt/SSDTTime), which required
  me to dump the DSDT from my firmware first ([using F4 inside Clover](https://dortania.github.io/Getting-Started-With-ACPI/Manual/dump.html#from-clover)),
  and added as well as a prebuilt version of [SSDT-USBX](https://github.com/dortania/OpenCore-Post-Install/blob/master/extra-files/SSDT-USBX.aml).

Note that I would also have needed to add [USBInjectAll](https://bitbucket.org/RehabMan/os-x-usb-inject-all/downloads/)
but I didn't at that point because the guide said it shouldn't be needed
for desktop Skylake and newer. It turned out I needed it at least until
I build the USB map for my machine.

Then I configured my `config.plist` from `Sample.plist` using the
desktop [Skylake][skylake] guide and ProperTree downloaded earlier,
which means I:

[skylake]: https://dortania.github.io/OpenCore-Install-Guide/config.plist/skylake.html

* used ProperTree's "OC Clean Snapshot" (`Cmd` + `Shift` + `R`) feature
  to automatically configure all the SSDTs, EFI drivers and kexts I
  added,
* in `Kernel/Quirks`, set `PanicNoKextDump`, `PowerTimeoutKernelPanic`
  and `XhciPortLimit` to `True`,
* in `Misc/Debug` set `AppleDebug`, `ApplePanic`, `DisableWatchDog` to
  `True` and `Target` to 67,
* in `Misc/Security` set `AllowNvramReset` and `AllowSetDefault` to
  `True`, `ScanPolicy` to 0, `SecureBootModel` to `Default` and `Vault`
  to `Optional`,
* in `NVRAM`, set `boot-args` to `-v debug=0x100 keepsyms=1 alcid=11`,
  the 3 first arguments being to get detailed logs to make debugging
  easier (those were a blessing), and the latter one sets the audio
  layout for AppleALC, which I figured was 11 on my earlier Hackintosh
  setups,
* used [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) to generate
  a `iMac17,1` SMBIOS and configured the matching parameters in
  `PlatformInfo/Generic`.

Note that I later had to change `SecureBootModel` to `Disabled`, more on
that below.

I also made sure that my BIOS settings matched the recommended ones in
the guide, which they already did.

Then I booted my OpenCore USB and launched the installer "Install macOS
Big Sur (External)".

### `Waiting on IOProviderClass IOResourceMatch boot-uuid-media`

The first issue I encountered is this message in the logs when launching
the installer. It turns out the installer wasn't able to detect the USB
key it was booting from and got stuck there, eventually crashing.

I solved that by adding the [USBInjectAll](https://bitbucket.org/RehabMan/os-x-usb-inject-all/downloads/)
kext, which allowed me to continue booting.

### `disk5: device is write locked`

I got a bunch of those messages during the boot after I fixed the USB
issue, and it was hanging for a while on those, so I figured something
was wrong and I shut down the computer and started looking up for
solutions. It turns out nothing was wrong and I just needed to be
patient.

It eventually kept logging more stuff and booted to the installer UI.

### Can't find my SATA drives in the macOS installer

Everything seems fine, until I want to pick the drive to install to and
there's like all my USB drives but not my HDD nor SSD (both are plugged
in SATA).

I spend a while to figure that issue, there's a [couple](https://www.reddit.com/r/hackintosh/comments/g8vx7k/opencore_no_satausb_hdd_partition_show_at_all_at/)
[threads](https://www.olarila.com/topic/8627-hdd-sata-not-detected-in-disk-utility/)
[online](https://www.reddit.com/r/hackintosh/comments/ex8g4v/why_doesnt_my_hard_drive_show_in_disk_utility_on/)
with a similar issue, some answers that recommend to disable Intel Rapid
Storage Technology (which I don't have), others recommending to use the
[SATA-Unsupported](https://github.com/khronokernel/Legacy-Kexts/blob/master/Injectors/Zip/SATA-unsupported.kext.zip)
kext (that didn't work either).

In the end, I stumbled upon [Dortania's Big Sur specific guide](https://dortania.github.io/OpenCore-Install-Guide/extras/big-sur/#supported-hardware)
(which was actually part of the "extras" of the guide I was reading but
I didn't notice before), where it explains that Big Sur dropped "certain
SATA controllers", and it seemed that mine was.

They recommend using Catalina's `AppleAHCIPort.kext` with any
conflicting symbols patched, which they actually provide an
[already patched file](https://github.com/dortania/OpenCore-Install-Guide/blob/master/extra-files/CtlnaAHCIPort.kext.zip)
for (thanks Dortania, much appreciated).

That allowed me to see my SATA drives and I could keep on with the
installation.

### Booting on "macOS Installer" just reboots into recovery

The installation keeps on going, until it reboots. This is usual, and
normally that's where you boot from "macOS Installer" on the actual
system drive rather than "Install macOS Big Sur" from the USB drive, and
it keeps going from there.

Here, it didn't keep going, it just rebooted, forcing me into recovery
(it somehow bypassed the OpenCore menu where I can choose what to boot
from and would always go to recovery).

There was only like 10 lines of log before it reboots, and it was so
fast I couldn't read them.

That's where the OpenCore setting earlier that generates text logs on
the EFI partition was handy AF, since it read clearly at the end of the
logs:

```
#[EB.LD.OFS|OPEN!] Err(0xE) <"\\macOS Install Data\\Locked Files\\BootKernelExtensions.kc.j137ap.im4m">
```

That allowed me to Google a bit further, and I somehow found [this thread](https://www.reddit.com/r/hackintosh/comments/j37wbd/upgrading_to_big_sur_beta_9_issues/)
among others that suggested disabling secure boot (by setting
`SecureBootModel` to `Disabled` in `config.plist`).

This worked and the installer kept doing its thing until I get to the
setup screen!

### No Wi-Fi on Big Sur

I go through the setup, but when it's time to connect the network, I
realize I don't have the option to connect Wi-Fi. I expected that as the
guide said in the beginning I would need an Ethernet connection, that
said I kinda challenged that as I remember I could install macOS High
Sierra using Wi-Fi back then.

Well, it turns out that Mojave dropped support for my Wi-Fi chipset
(Atheros AR9380), and I already had that problem when I moved from High
Sierra to Catalina, where I had to replace
`/System/Library/Extensions/IO80211Family.kext` by the one from my old
High Sierra installation, which I could easily do by remounting the
system partition as read-write using `sudo mount -uw /`.

This wasn't possible anymore as even my `root` user was denied this
command.

Again [Dortania's guide](https://dortania.github.io/OpenCore-Install-Guide/extras/big-sur/#supported-hardware)
came in handy, mentioning a workaround to patch that kext so that it
doesn't conflict with the system version, and still be able to load it
from OpenCore! And even better, there's a
[repo with already patched kexts](https://github.com/khronokernel/IO80211-Patches) of previous
macOS versions!

So I get the High Sierra one, and that works!

It works actually so well that my Wi-Fi network is automatically
connected, like WTF bro, ur not supposed to do that, I never entered my
passphrase.

I investigated a bit, and in Keychain Access, it wasn't actually my
passphrase stored, but a 64 digits hexadecimal string.

Well today, I learnt that WPA2 derives a PBKDF2 key from the SSID and
passphrase in order to connect, and that macOS stores that key in NVRAM
(which I now know what it is thanks to the OpenCore guide), which is how
my new totally unrelated installation of Big Sur was able to
automatically connect to my Wi-Fi network.

### Post-install

The last step was to follow the [OpenCore Post-Install Guide](https://dortania.github.io/OpenCore-Post-Install/).

Seems that mostly everything I need worked out of the box so I didn't
have much to fix there, I just copied OpenCore's EFI from the USB to my
SSD instead, and then the main thing was to generate the USB map to
avoid using USBInjectAll and the `XhciPortLimit` quirk, as well as some
cosmetic tweaks.

#### Generating the USB map

I'm not gonna go in the details of why this needs to be done as [the guide](https://dortania.github.io/OpenCore-Post-Install/usb/)
does one more time an amazing job at that, but this turned out much
easier than I expected.

Since I have an Intel system, I could use the [USBMap](https://github.com/corpnewt/USBMap)
tool and basically just plug something in all my USB ports (not even
necessarily at the same time), and it would figure all the ones that
were used. Then I marked the ones that were USB 2.0 as opposed to 3.0,
and it generated a map of just those ports under the form of a kext.

That's literally all that I had to do, and I could indeed remove
USBInjectAll and set the `XhciPortLimit` quirk to `False` and everything
worked.

#### Cosmetic tweaks

Finally I followed the guide's [beauty](https://dortania.github.io/OpenCore-Post-Install/cosmetic/verbose.html)
[treatment](https://dortania.github.io/OpenCore-Post-Install/cosmetic/gui.html),
which meant I:

* added the `OpenCanopy.efi` driver to my EFI partition as well as the
  `Resources` folder from [`OcBinaryData`](https://github.com/acidanthera/OcBinaryData),
* in `config.plist`, set `Misc/Boot/PickerMode`, to `External`,
* added `OpenCanopy.efi` to `UEFI/Drivers`,
* in `Misc/Debug`, set `AppleDebug` to `False` and `Target` to 3,
* removed `-v` from `boot-args`,
* on the EFI partition, replaced `BOOT/BOOTx64.efi`,
  `OC/Bootstrap/Bootstrap.efi`, `OC/Drivers/OpenRuntime.efi`,
  `OC/OpenCore.efi` by the ones from the `DEBUG` version.

## Wrapping up

And that's it, a working Big Sur installation using OpenCore for the
first time!

I spent basically a whole day on it, and looking back at it, it's
surprising how straightforward it was and how well it worked.

Sure there's a lot of little steps and different tools to use for very
specific parts, but it's also *very clear* what everything does and why
we do it (thanks to the guide).

At the end of the day, the biggest part was to figure precisely the
parts specific to my system, mainly the fact that Big Sur dropped
support for my SATA controller and that my Wi-Fi chipset was unsupported
since Mojave, and the fixes for those.

Now I know that, and especially now I have the SSDTs and USB map done,
using OpenCore and hopefully upgrading to future versions will be even
smoother... at least until macOS drops support for another one of my
chipsets!

I'm also amazed by the fact that all of this works without requiring any
patching of the macOS installation, everything is contained in the
OpenCore EFI partition, and the macOS system itself is 100% stock.

## Thanks

I would also like to thank the Dortania team for their fabulous guide, I
learnt so much while installing Big Sur with OpenCore and I'm still
impressed at how well everything was explained and how detailed the
explanations were.

Also thanks to everybody who contributed to all the tools I mentioned in
this post, those tools all felt really solid and far from "hacks" that I
would expect for something we call Hackintosh, everything seemed
cleanly built, well maintained and documented, with proper GitHub
releases and everything, including prebuilt/prepatched options. Like I
would say in French, c'est vraiment bien branlé.
