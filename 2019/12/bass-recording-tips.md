Bass recording tips
===================
December 4, 2019

This is a bass-specific update to my previous article about
[recording bass and guitar for YouTube](../10/recording-bass-and-guitar-for-youtube.md),
as since then I've consolidated my mastering technique (even though
probably far from perfect, please let me know if there's better ways of
doing this).

In this article, I'll describe the 3 key adjustments that I've applied
to my bass recording process that helped me to have a more phat sounding
tone.

While I've tweaked the recording settings pretty much for all of my
videos so far, I've applied the tips of that article mostly just for my
last 3 videos to date and you can definitely make the difference (more
on less noticeable depending on the video you compare to, but still
systematically better in my opinion).

Here's the ones that didn't use those techniques:

* Reciprok - Balance Toi
  * [Fingerstyle](https://youtu.be/_ct_hFcDdfQ?t=3)
  * [Slap](https://youtu.be/_ct_hFcDdfQ?t=151)
* L'Impératrice - Séquences
  * [Fingerstyle](https://youtu.be/JznUhT3AfWE?t=41)
  * [Slap](https://youtu.be/JznUhT3AfWE?t=255)
* Martin Solveig - Rejection
  * [Fingerstyle](https://youtu.be/CdqTbPTZQZo?t=38)
  * [Slap](https://youtu.be/CdqTbPTZQZo?t=215)
* DJ Abdel - Funky Cops - Let's Boogie
  * [Fingerstyle](https://youtu.be/zXdyCBrp0b4?t=20)
  * [Slap](https://youtu.be/zXdyCBrp0b4?t=155)

And the last 3 ones that apply those tips:

* Jean Dujardin - Give Me The Night (Le casse de Brice - Dog Food Remix)
  * [Fingerstyle](https://youtu.be/moBIT4vp878)
  * [Slap](https://youtu.be/moBIT4vp878?t=113)
* IAM - Je Danse Le Mia (Live Retour Aux Pyramides)
  * [Fingerstyle](https://youtu.be/aI6yXbb-yJU)
  * [More fingerstyle](https://youtu.be/aI6yXbb-yJU?t=152)
* La Felix - Take the Night
  * [Fingerstyle](https://youtu.be/dLh82_HLPPo?t=17)
  * [Slap](https://youtu.be/dLh82_HLPPo?t=54)
  * [More fingerstyle](https://youtu.be/dLh82_HLPPo?t=74)
  * [More slap](https://youtu.be/dLh82_HLPPo?t=179)

While you can hear the bass clearly enough on all of them, I feel like
the last ones have the bass cut through much more than the first ones
(especially the last one). Here's the things I did to achieve that.

Use a limiter
-------------

This is more likely the part that had the most significant impact on the
perceived loudness of my bass tracks.

I used to rely solely on a compressor to boost the bass signal without
peaking above 0 dB, however, maybe it's because I suck at configuring a
compressor, but not matter what settings I tried, I could never find a
way to really boost the signal without having some kind of clipping or
distortion. Seems like there's very fast and high peaks in my signal
that the compressor just can't manage, and I end up either with a super
tame bass sound, or some kind of distortion.

Instead, I've used a basic limiter plugin right after the bass
amplifier, where I boost the signal by about 12 dB (that's what sounds
the best for my input sensitivity, see the next part below).

Unlike a compressor, the limiter is really dumb (and that's a good thing
for me in that context), it just cuts the peaks when they exceed 0 dB
(or whatever configured level). This allow me to get rid of the super
short and high peaks I somehow get (especially when I slap) and I can
boost the actual part of the signal that I care about very close to 0
dB, where it actually sounds loud without any kind of distortion.

Don't worry about clipping the input signal
-------------------------------------------

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

For me this point is about halfway through the input signal knob in Hi-Z
(high impedance) mode.

Change the strings, or slap the shit out of them
------------------------------------------------

There's something with new strings that, to my opinion, just sound good,
and that usually goes away pretty quickly. Recording bass shortly after
changing the strings always made for a better quality recording,
provided that you actually like the bright tone and "zing" of new
strings.

However I'm not super down to buy new strings every week to record bass,
and I'm also lazy to change the strings that often. The good news is
I've found a surprisingly efficient technique that allow to get back
some of that "new string" tone without changing the strings, as
described in [this video](https://youtu.be/s8OYeN9mAL4); slap the
strings very hard before playing (not slapping as if you actually wanted
to play slap, but just pulling hard on the strings), potentially
loosening the strings before doing so (but I've found that it didn't
make that much difference whether the strings are loose or not when you
slap the shit out of them).

After this exercise, you get a much brighter tone with some of the
"zing" that new strings have, and this improved a lot my recording
quality without having to change my strings all the time.

Next steps
----------

While this gives me decent results, there's likely many ways to improve
that even more. For example, I'm thinking it could be a good idea to add
a compressor *after* the limiter, so that I get the benefits from
compression without it being confused by some fast and high peaks that I
somehow get in my signal. I believe that would help reducing the gap
between fingerstyle and slap loudness without bothering to put them on
different tracks and mixing them separately. Stay tuned for my next
cover to see if that makes a difference!

Last thoughts
-------------

Overall, while those tips helped me get a thicker bass tone, I'm looking
at one of my first covers, [Reciprok - Balance Toi](https://youtu.be/_ct_hFcDdfQ),
and the bass is pretty crisp on it, even though I didn't bother doing
anything special with it. Back then, all I did was running the bass
directly through one of the Logic bass amps and I just turned up the
volume fader of the bass track to +3 or +6 dB, and turned down the
original track fader to -6 dB or even lower until it sounded good to me,
regardless if this caused any clipping or not, and I would just let
Logic's audio normalization feature upon bouncing adjust the levels to
reach or not exceed 0 dB.

At the end, this would give pretty decent results without any effort.
Maybe the output track would overall sound less "loud" than my latest
covers where I spent more time on mastering, but it would still sound
great if you turn up the volume a bit more, with a pretty clear bass
line.

Also it seems to me that YouTube applies some kind of audio loudness
normalization as well, as the difference between my earlier videos
compared to my latest ones isn't remotely as clear as when I listen to
them on YouTube as opposed to the raw audio output I bounced.
