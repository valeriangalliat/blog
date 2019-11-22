Recording bass and guitar for YouTube
=====================================
October 17, 2019

About a year ago, I started learning about how to make my own bass and
guitar videos to publish on YouTube, whether it's songs covers or
original content.

While I'm far from having figured everything out, this article is a work
in progress on the things that I've learnt so far on the topic, that
might be useful for beginners who want to do the same thing, and
especially for myself to avoid repeating the same mistakes for my next
recordings!

This article is somewhat specific to the gear and tools I use, but I'm
pretty sure the general ideas can be applied to many different setups.

Tools
-----

To start with, here's the gear and tools I'm using.

* Camera: Panasonic LUMIX DMC-LX100K
* Interface: Steinberg UR22mkII
* <abbr title="Digital audio workstation">DAW</abbr>: Logic Pro X
* Video editing software: Adobe Premiere Pro
* Publishing platform: YouTube

Camera
------

### Storage

Make sure to have enough storage on your SD card for the video you plan
to record... it's annoying to run out of space and have a take cut in
the middle just because you forgot to format the SD card before
recording and it contained 42 GB of videos of an old video that you
already transferred anyways.

### Battery

Make sure you have enough battery when you start recording, ideally
charge it to 100% just before. If you can plug your camera while
recording to avoid running on battery, it's even better. It's pretty
frustrating to run out of battery in a middle of a take and have to redo
it.

### Focus

That's probably the only mistake that I make quite regularly when
it's about recording music videos; I forget to focus, or I focus on some
object in the background of where I'll be standing while I'm behind the
camera, and then I forget to focus on myself when I'm actually playing.

Too many times I've ended up with a great audio take but unusable video
because the focus point was not on the subject (me), which is pretty
frustrating.

The solution will depend on your gear, but as far as I'm concerned my
camera have a Wi-Fi mode where I can remote control it from my phone, so
I just need to remember to do that and adjust the focus point from my
phone before I start recording.

Another option is to have someone *else* behind the camera to take care
of this kind of details. That can also make your life much easier for
framing, as you won't need to go back and forth between the camera and
the spot where you'll be standing in the video to adjust the framing. It
usually takes me 4 to 5 roundtrips like this (including taking my bass
and putting it down again every time) to get a decent framing and focal
length.

### Takes

When I'm satisfied with a take, I stop the recording and take note of
the time and the number of the take in Logic so that I can easily match
up the take with the associated video when editing.

Interface
---------

### Hi-Z

If your audio interface jack input have a Hi-Z switch (stands for high
impedance), turn it on, as it's gonna give you a clearer sound. On mine,
only one of the 2 jack inputs have a Hi-Z switch, so I make sure to only
use this one when I'm recording bass and guitar.

### Input sensitivity

To calibrate the input sensitivity, most interfaces feature a LED that
indicates clipping. I usually try and play something louder that I will
need, and make sure that the input sensitivity is at a point where only
the "too loud" stuff results in clipping, meaning that when I play
normally I'll have optimal recording level.

I've found though that when slapping the bass, I had to turn the
sensitivity very low to avoid clipping, which then made it harder for me
to have the bass sound loud. It seems to me that the clipping happens on
some kind of extra "noise" when I slap but that it's not directly
clipping the actual bass sound, so especially for slap, I allow the
clipping LED to light up a lot, as long as the overall bass sound
doesn't sound distorted. Basically I end up turning up the sensitivity
as much as possible regardless of the clipping LED as long as it still
sounds good.

Strings
-------

Whether it's bass or guitar, you'll get a significant tone improvement
by changing your strings before recording. New strings just got that
extra clearness in the tone, that extra "zing" that gives some colour to
the sound, and it usually makes for a higher quality recording.

However I record pretty much every week, and that new string tone goes
away in a couple days for me, so I just accept that most of the time I
won't have an optimal tone, as I don't really want to change both my
guitar and bass strings every single week.

One trick I've found brilliant for bass though, consists in loosening
the strings and "slapping the shit out of them" before tuning it again
and playing, as shown in [that video](https://youtu.be/s8OYeN9mAL4).

This turned out to work really well for me, even though I can't get 100%
back the new string tone, it already sounds much better than the dead
string tone I get after a week or so. However I need to do it every time
before playing, otherwise it's a matter of hours for the tone to go dead
again.

There seems to be mixed opinions online on how coated strings could help
with that, so I haven't tried that just yet. It seems also that wiping
the strings with some kind of cloth after playing should help preserve
them a bit longer, and maybe also applying some kind of product like
Fast Fret. I'll update this post if I end up trying some of those
solutions.

This kind of problem seems to be very "personal" though, in the sense
that some people have more sweaty hands than others, and more or less
acidic sweat as well, and that seems to affect a lot the lifetime of the
strings. It looks like I'm of the kind that destroys strings in a couple
hours of playing, but if you're lucky enough you might be able to keep
your new string tone for months without having to think about it.

Logic
-----

### Record and bounce in 24-bit 48 kHz

When you create your project, make sure you are in 24-bit and 48 kHz
mode, as this is the audio settings that YouTube expects for high
quality videos.

By default Logic is set to 44.1 kHz (which would be good if we wanted to
publish the music on CDs), but 48 kHz seems to be the standard for
anything digital and especially audio to be used in a video, so that's
what we want here.

It looks like the default bit depth of Logic is already 24-bit but just
make sure it's the case for you as well.

### Do not bounce with audio normalization, use an adaptive limiter

Logic defaults to normalizing audio upon bounce. From my understanding,
this means that it will raise or lower the overall audio level so that
the highest peak is the highest possible level that doesn't result in
distortion (0 dB).

Having this enabled means that what you will bounce will potentially be
different from what you've been listening to while mixing. I want my
output to be exactly what I heard while mixing, so I keep normalizing
disabled in the bounce settings.

However raising the overall level to have the peaks close to 0 dB, and
also not having the master level ever exceed 0 dB is actually useful, so
we have to take care of that directly in the mix (this way we can hear
what the final result will sound like while mixing without any
surprises).

For this, I use Logic's adaptive limiter as the last effect of the
output track, as recommended by
[this article](https://whylogicprorules.com/mastering-logic-pro-x/),
with the settings they recommend: *Gain* of 0 dB, *Out Ceiling* of -0.1 dB,
20 ms *Lookahead* and *Remove DC Offset* turned on.

I also turn on *True Peak Detection* ([this
article](https://masteringinlogic.com/using-logic-adaptive-limiter-10-2-2/)
convinced me of that) as without it it would mean that "your mix might
still be clipping without you knowing it".

Since I was (and quite still am) quite confused about using the adaptive
limiter as opposed to just the limiter, I found
[those](https://discussions.apple.com/thread/7433127) two
[threads](https://discussions.apple.com/thread/7433127) that explain the
differences and what might be "better". Seems that the answer is usually
another plugin, but the second best answers seems to be in favor of the
adaptive limiter, so I'll go with that as it sounds decent to me.

### Bass loudness

I've struggled a lot (and still kind of am struggling) with the bass
sounding loud enough in the mix compared to other parts. Even with
compression and adjusting the gain/volume so that the bass is always
close to 0 dB, it just sounds far behind other instruments, and putting
it louder results in clipping, or if relying on Logic's audio
normalization, results in lowering significantly every other part and
having the whole mix sound quiet.

The best I've found so far (which is probably not the right thing to do,
please contact me if you actually know how to do that properly), is
adding a limiter as the last plugin of the bass track pipeline, and
boosting the gain (I usually boost it by 12 dB or so for it to sound
loud enough compared to other parts).

### Monitor perceived loudness

I put the loudness meter plugin after the adaptive limiter to monitor
the perceived loudness of the mix.

Looks like there's lot to say about the audio loudness online, and I
found this 3 parts article while researching on the topic that seems to
explain it pretty well.

* [Loudness Normalization: Part 1 - What's The Problem?](https://www.pro-tools-expert.com/logic-pro-expert/logic-pro-blog/2017/06/13/loudness-normalization-part-1-whats-the-problem)
* [Loudness Normalization: Part 2 - The Standards](https://www.pro-tools-expert.com/logic-pro-expert/logic-pro-blog/2017/06/14/loudness-normalization-part-2-the-standards)
* [Loudness Normalization: Part 3 - Logic Pro X's Loudness Meter](https://www.pro-tools-expert.com/logic-pro-expert/logic-pro-blog/2017/06/16/loudness-normalization-part-3-logics-loudness-meter)

Looks like for online streaming we should aim for
16 <abbr title="Loudness units relative to full scale">LUFS</abbr>,
so that's what I monitor for.

### Equalizing original track for bass covers

When doing bass covers, I usually try to dim the bass of the original
track so that it doesn't conflict with my cover. For this, I usually add
a channel equalization on the original track where I set everything
below 250 Hz to -24 dB.

This usually works pretty well, but it also often results in removing
the drum kick, so sometimes depending on the song, I try to compensate
up a smaller frequency range between 60 and 70 dB to bring it back.
It won't sound as good as the original track obviously, but will leave
more room for the sound of the actual bass cover which is the most
important part of a... bass cover.

### Cleanup

I sometimes end up doing a *lot* of takes for the same cover or parts of
it, and this ends up taking some space. When I'm fully done with
arranging the takes and editing, I remove all the takes that were left
unused. Then, in the project audio files panel, you can *Select Unused*
in the *Edit* menu and delete those files.

This won't actually delete the files from the disk; after doing that, go
in the main window in *File*, *Project Management* and *Clean Up*. This
will prompt you to actually move the unused audio files to the trash.

Premiere
--------

While not directly related to bass and guitar covers, here's the little
tips I needed with Premiere for doing those videos.

### Adjustment layers

If you have multiple video takes for the same project and you want to
apply the same color correction and creative effects to all of them, add
an adjustment layer in the project panel and drag it in the timeline
above all the videos. Then you can modify the colors on the adjustment
layer and it will take effect on everything below it, instead of having
to apply the same settings on each video individually.

### Cleanup

As with Logic, when done editing, you can do *Edit*, *Remove Unused* to
remove all the unused media from the project panel.

After doing so, I manually compare the files I have on disk with the
remaining files in the project panel and I remove the ones that are not
used anymore. I'm not aware of an automated solution for this, but for
this kind of project it's usually pretty quick.

YouTube
-------

### Prepare a cover picture first

YouTube will auto generate 3 cover pictures from the video, but from my
experience they're rarely the best and I'm better off picking a custom
frame from the video (using Premiere's export frame feature).

The main thing is to do that as early as possible, especially before
actually publishing the video, otherwise if you start sharing the video
to other platforms, e.g. Facebook, it will cache for a very long time
the cover picture and even the "sharing debugger" will not do anything
about the cover itself for at least a couple days after you change it.

Also when sharing on Facebook, you might want to check [this article] to
make sure the mobile layout of your YouTube post is the full width one.

[this article]: ../11/fix-facebook-youtube-attachment-layout-mobile.md
