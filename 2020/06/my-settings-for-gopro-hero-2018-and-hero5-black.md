---
hero: ../../img/2020/06/gopro.jpg
focus: 15% 40%
---

# My settings for GoPro HERO (2018) and HERO5 Black
June 16, 2020

Following my article on how I [configure my Panasonic LX100](../05/my-settings-for-panasonic-lumix-lx100.md),
I wanted to make a similar article on my GoPro HERO (2018) and HERO5 Black configuration.

Some of those settings are based on the recommendations of [this video](https://youtu.be/3DoKXA8tCq0)
(which I highly recommend on tuning GoPro settings), with my personal
tweaks and adaptations for the HERO (2018).

## Make your HERO (2018) a HERO5 Black

First things first, the hardware for the HERO (2018) and HERO5 Black is
essentially the same. The HERO (2018) comes with a stripped down
firmware with a limited set of features, but the hardware is as capable.

This means that if you have a HERO (2018), by flashing the firmware of a
HERO5 Black on your HERO (2018), you get a HERO5 Black for half the
price.

This article is not about this modification, and obviously it's not my
fault if you fuck up your GoPro by trying that out.

That being said, let's look at the settings I use.

## Record settings

### Resolution (RES)

I usually shoot in 1080p. This allows for built-in stabilization
(4K doesn't have stabilization) which is nice as it's usually pretty
heavy to stabilize in post and I'd rather spend my time shooting stuff
outside than having a slow workflow dealing with post stabilization.
Also takes about 4 times less space which is convenient, and most
importantly, uses **a lot less battery**.

<div class="note">

**Note:** stabilization crops the footage by 10%, but I'm fine with that
as the GoPro is already pretty damn wide by default, but if for some
reason I were to want those 10% back and don't need stabilization (or
not that much), I would turn off built-in stabilization.

</div>

In some cases I will shoot 2.7K or 4K, like if I shoot a bit wider than
I need and plan to crop in post, so that I can keep a decent image
quality by doing so if I output in 2K or 1080p. I do this mostly just
for static shots using a tripod where I want the option to adjust the
framing in post, but I often use the LX100 for this kind of shots, and
keep the GoPro for action shots, where I rarely ever crop the footage
anyways.

A thing to note is that the 1440p option is 1920x1440, so a 4:3 ratio,
so that won't match e.g. 2K on YouTube which expects 16:9 2560x1440.
The closest to that will be the 2.7K option which is 2704x1520, which is the
one I use when I plan to export 2K video on YouTube.

I could think about using the 1440p option when I would otherwise use
1080p, then crop it back in my timeline to a 16:9 ratio, but that would
give me more height to play with if I'm also gonna crop that footage in
9:16 for Instagram and such.

Finally, if I know I don't need a lot of shots, thus I don't really care
about space and battery, I might shoot 4K so that when exporting in 2K
or 1080p it looks even nicer.

### Frame rate (FPS)

I shoot in 24 FPS. I match this on all of my cameras. I don't really
care about the "cinematic look" that everybody tells that 24 FPS brings,
but whatever look it gives to my video, I like it, or more likely, I
just don't mind it / don't care.

24 FPS is a setting that's available on all my cameras and the main
thing I care about is having all of them recording in the same frame
rate so that it stays consistent without duplicating or dropping frames
when mixing shots together in a sequence (while mostly nobody notices
that, I still care about it, don't ask me). Typically, my LX100 allows
for 24, 25 and 50 FPS, while the GoPro allows for 24, 30, 48, 60 and
more. Here, 24 is the only frame rate that allows me to natively match
shots from both cameras.

I'll set a higher frame rate if I'm doing a shot that I'm planning to do
slow motion with.

### Field of view (FOV)

I like shooting in wide. I like the, well, wideness of the wide setting.
I find SuperView a bit *too* wide, too much distortion to my taste.

If I'm shooting a farther subject, I might put it in Linear mode so that
not only I can focus more on the subject, but also remove all the
distortion from the GoPro lens and give a more regular camera feel.

## Protune settings

First, it's useful to understand all the Protune settings before
tweaking them. There's countless articles about that, but one of my
favorite is [GoPro Protune settings explained on havecamerawilltravel.com](https://havecamerawilltravel.com/gopro/gopro-protune-settings-explained/).

### Color

I use the Flat color profile as opposed to the GoPro one. This looks,
well, flat, but allows for more flexibility in post production when
playing with colors, contrast, exposure and stuff.

If you don't want to mess with post production color correction, don't
bother with the Flat profile.

### White balance (WB)

I've shot for a while in auto white balance and this did a great job,
however I've found that it would be sometimes inconsistent when shooting
different scenes in the same lighting. For example, shooting sand and a
river, and without moving, doing a second shot of the forest and sky, it
would balance the colors totally differently between the two shots.

That's to be expected with auto white balance which can be confused when
a scene contains *a lot* of a given color.

To avoid that, if I can afford to take the time, I'll set my white
balance manually.

Typically, I'll use 5500K for a clear sunny sky, 6500K for an overcast
sky, 3000K for evening or night.

Also, I don't ever use the Native option. This claims to give more
flexibility in post without having to manually set the white balance,
but I've never managed to deal properly with that Native white balance
in post. It's been consistently fucking up my reds and oranges in a way
that you can't distinguish them from each other and that I couldn't
recover in post, and the last thing I want to do when color correcting
is applying masks to finely adjust colors in some parts of the shot.

If I don't want to manually set a correct white balance but still want
consistency between shots (so no auto white balance), I'll just leave it
on 5500K whatever the lighting is like, and adjust the colors in post to
make it look more natural. That preserves more of the colors to my
perception.

### ISO

ISO 1600 (default when in Protune mode). The ISO is actually not the ISO
(yep), it is the **maximum** ISO. That means that the GoPro will pick a
lower ISO if it can according to the light situation, but will crank up
the ISO gradually to that limit to maintain the exposure before slowing
down the shutter speed (which will start to cause blur and a laggy
feeling at some point).

If I'm shooting at night, I might set the ISO limit even higher to make
sure I get *something* as I'd rather have *something* than *nothing*
even if it means it's gonna have a lot of noise.

### Shutter

I leave that on auto.

Where I would usually set the shutter speed manually is either for
stills, and I don't really use the GoPro for that, or on videos, to get
a "natural" look by setting the shutter speed to 180° (`1/(2xfps)`, so
1/48 if I'm shooting 24 FPS and so on). That usually requires to add a ND
filter to get proper exposure, and I tend to not have a ND filter on my
GoPro, so I leave that alone.

### Exposure compensation (EV COMP)

I need to play with this more, but these days if I've got plenty of
light, I'm setting -1.0 to get more details in the highlights, since
with the Flat color profile, I get a lot of details in the shadows
already. That allows for higher dynamic range after color correction
at the cost of *some* extra noise in the shadows.

In low light, I'll leave it to 0.

### Sharpness (SHARP)

At first, I tried leaving it on Low so that I can adjust the sharpness
to my taste in post, as you can't really remove sharpness as much as you
can add sharpness after the fact.

In practice I never bothered adjusting sharpness in post. So I put it
back to High, until I saw some YouTube video where they suggested to
just leave it in Medium if you're not gonna add some in post, so I just
did that.

To be honest I don't look closely enough to my own footage to notice any
difference between sharpness settings. I will sometimes reupload a video
before publishing just to remove 0.5 dB to a music track or to move tint
from +7 to +8 on a clip but sharpness isn't one of those things I'm
overly perfectionist about. 😂

### Audio

On my HERO (2018) with the HERO5 Black firmware, the "Low" and "Medium"
settings do absolutely nothing (as in, they generate a WAW file but it's
completely silent).

As for the "High" one, it gives me two channels, one for each mic (the
"left" one is on top of the GoPro, and the "right" one is actually on
the right). This WAV file sound exactly the same as the MP4 audio, I
made no difference in terms of processing, so I just use the audio from
the MP4 (which is also in better sync, as the WAV doesn't exactly match
with the video and needs to be manually synced).

The left and right channels of the MP4 audio do match exactly what we
have in the WAV in terms of directionality, so we can easily make it
mono, using only the top or right mic in some situations if that
improves the quality or can help remove unwanted noises.

Finally, sliding after the Protune menu, we can find a "Manual Audio
Control" panel, that I enabled, and ticked "Stereo Only", which should
be the same as setting "Wind" to "Off" on more recent GoPro (like in the
video I mentioned in the beginning of this article).

### Bonus: Protune on a GoPro Session

It seems that lately you can't adjust Protune settings for a GoPro
Session from the app anymore. Luckily, there's still a few ways to
configure it e.g. to use a flat profile and fixed white balance like I like
to, using the trick from [this Reddit post](https://www.reddit.com/r/gopro/comments/m2a8h5/hero_5_session_protune_settings/).

Simply put a `cal.txt` file at the root of the SD card with the
following content:

```
_tapp protune on
_tapp protune_color flat
_tapp protune_white_balance 5500K
```

According to [this document](https://github.com/hypoxic/hero4-session/blob/master/t_app.txt)
which also lists many other options, the available Protune options are
the following:

```
protune [on|off]
protune_color [gopro|flat]
protune_sharpness [high|medium|low]
protune_white_balance [auto|3000K|5500K|6500K|native]
protune_iso_limit [400|1600]
protune_ev_comp <ev> (-2.0 <= ev <= +2.0)
```
