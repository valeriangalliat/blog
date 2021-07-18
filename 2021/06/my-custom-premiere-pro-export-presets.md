---
hero: ../../img/2021/06/premiere-pro-presets.jpg
focus: 50% 25%
---

# My custom Premiere Pro export presets
June 14, 2021

I'm publishing videos mainly to YouTube and Instagram. While Premiere
comes with exports presets for YouTube out of the box, they don't have
any for Instagram. Also it turns out that even for YouTube, my main
publishing format is not part of the default YouTube presets. Let's dig
into it!

## YouTube 1440p 2K Quad HD

Based on the "YouTube 2160p 4K Ultra HD" preset, this presets fills the
gap between 1080p and 4K by allowing you to export a 1440p 2K video for
YouTube.

I like to export in 2K because it allows me to
[get a higher video quality on YouTube](../03/getting-the-highest-video-quality-on-youtube.html)
by forcing the VP9 codec instead of AVC, even when viewed in 1080p.

Also, with my source footage being 4K, 1440p still allows me a decent
cropping margin without loosing quality, and otherwise gets me that
extra crispness you get when downscaling 4K footage.

To make that preset:

| Section              | Setting         | Value                     | Comment        |
|----------------------|-----------------|---------------------------|----------------|
| Export Settings      | Preset          | YouTube 2160p 4K Ultra HD | Base preset    |
| Basic Video Settings | Width           | 2560                      |                |
| Basic Video Settings | Height          | 1440                      |                |
| Encoding Settings    | Level           | 5.1                       | Instead of 5.2 |
| Bitrate Settings     | Target Bitrate  | 20                        | Instead of 40  |
| Bitrate Settings     | Maximum Bitrate | 20                        | Instead of 40  |

### Why set the level to 5.1?

The main reason is that when I first created this preset, Premiere
actually defaulted the 4K preset to 5.1 as well, so I kept it the same.

When a Premiere upgrade changed the 4K preset to 5.2, I then asked
myself whether I should mirror the Premiere update or keep 5.1 for my
2K preset.

This forced me to learn a bit about H.264 levels first. Basically,
a level define the maximum values for a number of encoding properties
like bitrate, buffer size, macroblocks, luma settings and more. You can
read more about that on [Wikipedia](https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding_tiers_and_levels),
[Encoding.com](http://help.encoding.com/knowledge-base/article/do-you-have-any-information-on-h-264-levels/)
and [MediaCoder](http://blog.mediacoderhq.com/h264-profiles-and-levels/).

For 2K and even 4K (unless it's 60 FPS or more), a level of 5.1 is way
enough. While YouTube doesn't give profile recommendations on their
[recommended upload settings](https://support.google.com/youtube/answer/1722171),
they do so on their [live encoder settings](https://support.google.com/youtube/answer/2853702):

* H.264, 4.1 for up to 1080p 30 FPS,
* H.264, 4.2 for 1080p 60 FPS,
* H.264, 5.0 for 1440p 30 FPS,
* H.264, 5.1 for 1440p 60 FPS,
* H.264, 5.1 for 2160p 30 FPS,
* H.264, 5.2 for 2160p 60 FPS.

I usually export 24 FPS video, so I could even safely go down to 5.0,
but I don't want my preset to be limited to 30 FPS or lower.

The reason Premiere bumped the 4K preset from 5.1 to 5.2 is likely to
support 4K 60 FPS exports out of the box, because there's only one
preset regardless of the frame rate.

For the same reason, I'll leave 5.1 for my 2K preset; it's just high
enough to support 2K 60 FPS.

### Why a bitrate of 20 specifically?

Premiere defaults to a bitrate of 16 Mbps for 1080p and 40 Mbps for 4K.
I'm looking for something in between.

Technically, 1440p is 1.33 times 1080p and 2160p is 1.5 times 1440p (and
2 times 1080p).

Based on that, I could define a bitrate of 1.33 &times; 16 &equals; 21.28 Mbps, or 1
&divide; 1.5 &times; 40 &equals; 26.66 Mbps.

Since I expect those videos to be watched mostly in 1080p, I round
down the bitrate to 20 and call it a day. This allows me to force the
1440p VP9 encoder on YouTube while keeping a file size that's nearly as
small as a 1080p export would be.

To put this in context, we can also look at [YouTube's recommended upload settings](https://support.google.com/youtube/answer/1722171):

| Type       | Video bitrate (24, 25, 30 FPS) | Video bitrate (48, 50, 60 FPS) |
|------------|--------------------------------|--------------------------------|
| 2160p (4K) | 35–45 Mbps                     | 53–68 Mbps                     |
| 1440p (2K) | 16 Mbps                        | 24 Mbps                        |
| 1080p      | 8 Mbps                         | 12 Mbps                        |

We can see that Premiere's default 4K bitrate of 40 Mbps is just in the
middle of the recommended range by YouTube for standard frame rates, but
is probably too low if you were to export a high frame rate video.

Contrarily, Premiere's default 1080p bitrate of 16 Mbps is double what
YouTube themselves recommend for standard frame rates, and even higher
than the high frame rate recommendation.

Finally, my 2K preset bitrate of 20 Mbps is right in the middle of what
YouTube recommends between standard and high frame rates, making this a
somewhat versatile preset.

### A note about 1 vs. 2 pass <abbr title="Variable bitrate">VBR</abbr>

In "Bitrate Settings", we also have an encoding option letting us choose
from CBR, 1 pass VBR and 2 pass VBR. CBR stands for constant bitrate,
and VBR for variable bitrate.

Premiere defaults its YouTube presets to 1 pass VBR.

When rendering the video, the VBR encoder supports a 2 pass process
where it first analyses the whole video so that
[it can be more efficient](https://www.quora.com/How-big-is-the-difference-between-VBR-1-pass-and-VBR-2-pass-in-terms-of-quality-when-encoding-a-video)
at actually encoding it in the second pass, resulting in a smaller file
size for a similar quality, or a higher quality for a similar file size
(in case of Premiere where we fix a target and maximum bitrate). The
downside is that rendering takes nearly twice as long.

Spending double the time for roughly a 30% increase in quality is a
tradeoff you'll have to do for yourself, but as far as I'm concerned,
Premiere takes already long enough to encode that I'm not willing to
make it even worse.

## Instagram

On to the Instagram presets!

I based all of my Instagram presets off Premiere's YouTube 1080p preset,
meaning we're rendering with H.264 level 4.2, and a bitrate (both target
and maximum) of 16 Mbps. To reuse the previous preset table:

| Section           | Setting         | Value                 | Comment            |
|-------------------|-----------------|-----------------------|--------------------|
| Export Settings   | Preset          | YouTube 1080p Full HD | Base preset        |
| Encoding Settings | Level           | 4.2                   | Default for preset |
| Bitrate Settings  | Target Bitrate  | 16                    | Default for preset |
| Bitrate Settings  | Maximum Bitrate | 16                    | Default for preset |

Aside from that, my 4 Instagram presets only differ in the resolution.

### Resolution and aspect ratio

While there's many websites giving settings when searching "Instagram
video resolution" or "Instagram video specification", the only resource
I've found from Instagram themselves is on
[their help center](https://help.instagram.com/1631821640426723).

They recommend an aspect ratio between 1.91:1 and 4:5, with a width of
1080 pixels, meaning that the height will vary between 566 and 1350
pixels.

I derived 4 presets out of that:

| Preset    | Resolution |
|-----------|------------|
| Square    | 1080x1080  |
| Portrait  | 1080x1350  |
| Landscape | 1080x608   |
| Story     | 1080x1920  |

Here, the landscape one could be even wider if I wanted to, but most of
my content is shot in 16:9 so I'll keep it that way.

### A note about bitrate

For the bitrate, I didn't find any official Instagram recommendation,
but various websites recommend 3.5 Kbps, and this matches what the app
does when recoding the video before upload (you can see that by saving
the post or story to camera roll and inspecting the file).

This makes the 16 Mbps of my presets sound a bit overkill, but I'd
rather provide a top quality video to the app and let it recode it.

There is no evidence that Instagram would skip the recoding process if
we provide a compressed-enough video, so if recoding is going to happen
either way, I'd rather provide a top quality input to get the best
result.

**Sidenote:** inspecting the Instagram recoded video also shows that
they resize the video to a width of 720 pixels, preserving the aspect
ratio and frame rate. So even though they allow a maximum width of 1080
pixels, they seem to conform videos to a width of 720 pixels on their
side.

### A note about distribution

As far as distribution is concerned, at least from desktop, they serve
videos with a width of 640 pixels, a bitrate of 1 Mbps, and conform the
frame rate to 30 FPS (which matches their
[requirement for IGTV of minimum 30 FPS](https://help.instagram.com/1038071743007909), even
though they don't give any information about timeline videos otherwise).

### A note about frame rate

Even though Instagram appears to conform videos to 30 FPS upon serving,
I still keep my timeline FPS settings in my export file, and let the
conversion up to Instagram.

Most of the time for me, it means I stick to 24 FPS.

As noted above, the version Instagram processes on the device prior to
uploading preserves the original frame rate, so this might be a sign
that they conserve the video with the original frame rate on their
servers, potentially allowing 24 FPS distribution at some point in the
future.

### A note about video length

Videos in Instagram posts are limited to one minute, but to be very
precise, on a 24 FPS timeline, it turned out to be 59 seconds and 21
frames. A single more frame and Instagram will prompt you to publish the
video on IGTV instead.

Also stories are limited to 15 seconds, and on a 24 FPS timeline, they
allow up to a length of 15 seconds and 10 frames, otherwise they will
start splitting the story.

### Final word

At that point, you have all the information you need to recreate those
presets on your side, and you know precisely why each setting was
chosen.

Don't forget in Premiere once you customize your export settings, you
can save the preset to easily use it in other projects!
