# LG UltraFine 4K display randomly flickering
June 29, 2026

## TLDR

* Plug an external power adapter instead of relying on the monitor to
  power the laptop (if using with a laptop).
* Play a [LCD screen burn-in fix](https://youtu.be/VN-KIlsxxOw) video
  full screen for a few hours.

## Context

I have a [LG UltraFine 4K](https://www.lg.com/ca_en/monitors/uhd-4k-5k/24md4klb-b/)
monitor (24MD4KLB-B, the one made in partnership with Apple in 2019 for deep
macOS integration).

This year it randomly started flickering. Literally once second it was
OK, and the next it was flickering. It's been plugged the same way for
years (I use it with a Lightning cable on my MacBook, which also powers
the laptop). Nothing changed.

Tried a bunch of things including unplugging and re-plugging the
display, both from the laptop and from the power outlet, as well as
restarting the computer. No change.

Flickers varies from the whole screen flashing black at a fast rate, or
some specific portions of the screen flashing with more of a "noise"
pattern? And more recently, ghosting of what I had on screen at the time
it started flickering.

The only report I found is [this Reddit post](https://www.reddit.com/r/MacOS/comments/1m275y6/lg_ultrafine_4k_monitor_blinking_like_crazy_only/)
but sadly no solution there (until I posted mine more recently).

## Solution

The only thing that seems to reliably fix this for me is to **plug the
laptop with a power adapter**, instead of relying on the screen to power
and charge it.

It's not instant but it seems after leaving the computer plugged for a
few minutes or sometimes a few hours, the flickering is gone.

Then you can use the screen for power again, and in my experience it's
fine again for weeks or even months until the next instance of
flickering. 🤷

## New solution

Hi, it's Val from the future, a month later. It just happened again and
the previous solution wouldn't do anything.

Tried unplugging the monitor overnight, but this changed nothing.

Tried [LG Screen Manager](https://apps.apple.com/us/app/lg-screen-manager-lg-monitor/id1142051783?mt=12)
to update the monitor software, and to factory reset the monitor, but
both changed nothing.

Then in a Google search for "LG UltraFine 4K flickering" which lead to a
quick back and forth with Gemini, it eventually suggested one thing I
hadn't tried yet: **force an internal panel flush**.

> Since the ghost frame survived overnight, The LCD pixels are
> physically stuck in their twisted orientation due to a static
> electrical charge.

How to do this? Play a "pixel unsticking" or "color cycling" video, also
known as "LCD screen burn-in fix". I searched exactly that on YouTube
and found [this video](https://youtu.be/VN-KIlsxxOw) (one amongst a ton
of other similar videos).

I played it, full screen of course, for a couple hours and guess what, I
returned to a perfectly fine screen, no flickering and burn-in anymore!!
