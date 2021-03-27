# Upgrade a Hackintosh from High Sierra to Catalina
October 2, 2020

As an owner of a NVIDIA GTX 1060, I've never been able to use macOS
Mojave, or more recently, Catalina on my rig, as they don't support the
NVIDIA Pascal architecture natively, and the last macOS driver that
NVIDIA published was for High Sierra.

This is the reason I stuck on High Sierra for years, hoping that
eventually we get updated drivers for latest macOS version, but this
didn't happen is likely not happening anytime soon.

While I love my NVIDIA card, I eventually decided to switch to AMD to be
able to upgrade my system, so I bought a RX 580.

## Upgrading the card

This was literally just, taking out the GTX 1060, putting in the RX 580.
It worked out of the box on High Sierra, and worked as well after the
upgrade to Catalina.

Form there, I uninstalled the NVIDIA Web Driver. You can do that form
the driver preferences which features an uninstaller.

## Upgrading to Catalina

I followed [this guide on tonymacx86][upgrade-guide] to perform the
upgrade, then I followed the [post-installation procedure] of the guide
specific to my hardware.

[upgrade-guide]: https://www.tonymacx86.com/threads/update-directly-to-macos-catalina.284463/
[post-installation procedure]: ../../2019/03/macos-high-sierra-msi-h110m-pro-d-skylake-nvidia-pascal.html#post-installation

The main difference here was that in MultiBeast, "Remove XHCI USB Port
Limit" was systematically failing, so I didn't put it in the end, and
the latest MultiBeast didn't include "FakeSMC Plugins", only
"VirtualSMC" and "VirtualSMC Plugins".

I tried VirtualSMC, but this caused a reboot loop, like in the middle
of the boot loading bar, it would just reboot again, and that over and
over.

So I manually [downloaded FakeSMC from tonymacx86][fakesmc] and added it
to the Clover kexts, and this worked out.

[fakesmc]: https://www.tonymacx86.com/resources/fakesmc.358/
