Firefox Hello, ALSA, and webcam microphone
==========================================
May 3, 2015

Yesterday, I finally tried Firefox Hello, one of the few free softwares
to do cross platform video chat.

I'm using Arch Linux, with ALSA to manage my sound. While Firefox Hello
had no problem with the video, I couldn't get any sound coming out from
my side.

While the browser asks for input video and audio device when joining a
session, Firefox Hello leave no way to select the input microphone when
you *create* a session. The problem is Firefox was taking audio input
from my default card instead of my webcam, where I had no microphone
plugged in.

Custom default PCM device
-------------------------

The solution for this was to configure the default ALSA capture device.
Turns out there's already an entry for this on the
[ALSA page of the ArchWiki][wiki]. I'm pretty sure it's a decent
solution for other GNU/Linux distributions (obviously when using ALSA).

[wiki]: https://wiki.archlinux.org/index.php/Advanced_Linux_Sound_Architecture/Troubleshooting#Setting_the_default_microphone.2Fcapture_device

So in my case, the following `~/.asoundrc` did the job:

```
pcm.usb
{
    type hw
    card C170
}

pcm.!default
{
    type asym

    playback.pcm
    {
        type plug
        slave.pcm "dmix"
    }

    capture.pcm
    {
        type plug
        slave.pcm "usb"
    }
}
```
