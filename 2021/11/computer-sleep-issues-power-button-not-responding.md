# Desktop power button not responding and random sleep issues
November 16, 2021

A few days ago I started having issues with my computer. When I was
putting it to sleep (or hibernating), it would either crash and turn off
immediately, or would fail to power the GPU and USB ports after waking up,
leaving me with a black screen and unresponsive keyboard and mouse,
and forcing me to hard reset it.

More notably, when it crashed instantly as it entered sleep state, the
power button didn't work anymore and I needed to unplug the machine for
a minute or so before being able to start it again. This didn't always
work the first shot though but usually after doing it a few times, it
would eventually boot up again.

It's something that had already happened to me in rare occurrences
during the past year, enough to get me frustrated and somewhat anxious
when my machine effectively appeared to be bricked (that's how I found
the unplug replug trick by despair), but not to a point where I spent
the time to understand and fix the root cause, as it always kinda fixed
itself without my intervention.

I remember one time where the unplug replug trick didn't work to a point
where I decided to open the machine and see what I can do inside, but
interestingly just the sheer fact of opening it and moving it around so
that I can work on it fixed the problem, so I was just happy to have a
working computer again and didn't question it much.

That's until this week, coincidentally right before I [upgrade to macOS Monterey](yearly-hackintosh-upgrade-macos-monterey-with-opencore.md).

## Kernel panic: sleep wake failure in EFI

I was still running Big Sur back then and it's been running smooth the
whole year, but the day before I decide to upgrade to Monterey, I get
those sleep issues again, mainly lack of GPU and USB power on wake
(manifested by a black screen and unresponsive keyboard and mouse).

I figured it wasn't worth fixing it now, and I might as well upgrade and
see if it still happens. And while [the upgrade goes smooth AF](yearly-hackintosh-upgrade-macos-monterey-with-opencore.md),
I notice even more of those sleep issues after the fact. They're not
occasional anymore, they happen pretty much 90% of the time the computer
sleeps, seemingly at random. It either fails to power the connected
devices on wake or just crashes right away when being put to sleep and
causes the unresponsive power button issue.

At that point I assume that it comes from the upgrade to Monterey,
especially because I'm running a Hackintosh and I suspect that it must
be for sure the culprit. After all, there's "hack" in the name, even
though it's been impressively stable [since I use OpenCore](../../2020/11/upgrading-hackintosh-catalina-big-sur-clover-opencore.md).

I spend more time than I'm willing to admit trying everything to fix
[power management](https://dortania.github.io/OpenCore-Post-Install/universal/pm.html)
and [sleep](https://dortania.github.io/OpenCore-Post-Install/universal/sleep.html),
including using [CPUFriend](https://github.com/acidanthera/CPUFriend/releases)
and [CPUFriendFriend](https://github.com/corpnewt/CPUFriendFriend) to
fix the "sleep wake failure in EFI" system panics. But none of that
changes anything. I try to understand the different macOS sleep modes
and [various](https://dortania.github.io/OpenCore-Post-Install/universal/sleep.html#preparations)
`pmset` [settings](https://github.com/li3p/dell-optiplex-9020-hackintosh-opencore#sleep)
to tune them and make things work but without any luck.

I also try to see if it's related to any of my external devices, and
while the issues seem to happen less frequently when I unplug my 3
external drives and my external sound card, they still happen somewhat
randomly in a way that I can't reliably isolate any of those as being
the problem.

## Questioning the hardware

At that point I lost more than 12 hours on this issue and I'm going on
my second day of relentless debugging. I feel like I've tried everything
possible and documented online about fixing sleep at the software,
drivers and configuration level, and the precise issues and symptoms I
run into don't seem to exactly match any of the topics I find online.

I have a TP-Link PCI Wi-Fi card in there and I'm thinking maybe it's
unsupported in a way that somehow causes the crashes with the new OS? I
open the case and remove it, but this doesn't seem to change anything.

I start questioning my actual hardware, looking more precisely at the
ssue where the power button is unresponsive. I find a
[number](https://www.reddit.com/r/buildapc/comments/3wn2d8/discussion_just_a_reminder_that_a_dead_bios/)
[of](https://www.quora.com/Can-a-dead-CMOS-battery-stop-a-computer-from-booting)
[pages](https://steamcommunity.com/discussions/forum/11/618460171318429760/)
stating that a weak or dead CMOS battery could cause it (or also a
faulty power supply 😅).

The CMOS battery is easier to test and cheaper to replace than the power
supply, so I start with that. My machine is now 5 years old so it's not
exactly brand new, even though I've kept desktop computers much longer
than that in the past without needing to replace a CMOS battery once in
my life. Regardless, I take it out and test it with a multimeter only to
find that it delivers a solid 3 volts as it's supposed to. I even test a
brand new battery to compare and get the same results! Not the issue
here, even though I wish it would have been as easy as replacing a
CR2032 battery.

But when I put the battery back in place, my computer still doesn't
start! And turning off and on the PSU again doesn't seem to work
anymore. Did I accidentally fry the motherboard while manipulating the
battery? I try one more time to be relieved by the sound of my machine
booting, and welcoming me with a fresh BIOS reset screen. I configure
everything again and boot macOS. At that point, all the USB devices are
unplugged and I'm on a freshly configured BIOS. I try the sleep again
but sadly it keeps crashing.

## Very specific googling, and final fix

As a last resort, I try searching the very specific symptom I'm having
and the hack I found to work around it: "need to unplug and replug
computer for it to start". This sound so ridiculous and far fetched that
I've never thought about searching just that before, but I'm pretty
desperate at that point.

To my whole surprise, I'm [not the only one](https://www.ifixit.com/Answers/View/255569/Why+do+I+have+to+first+unplug+my+computer+to+start)
to [have this issue](https://forums.tomshardware.com/threads/computer-shuts-off-and-wont-turn-back-on-until-i-unplug-it.217732/),
and in those two pages from respectively 5 and 10 years ago, the pinned
solution is the same:

> Open up the computer and look at all the extra cables inside make sure
> they're all neatly bundled away from any part of the case they may be
> shorting it out.
>
> --- [Why do I have to first unplug my computer to start?](https://www.ifixit.com/Answers/View/255569/Why+do+I+have+to+first+unplug+my+computer+to+start#answer256519)

> After trying just about everything software wise (except a complete
> Windows reinstall) I was able to track the problem down to my PSU as
> many forums had suggested. It tuned out that some of the many extra
> connectors I had on my PSU I had stuffed into an extra empty drive bay
> in order to reduce the clutter inside the case. Somehow one of them
> had been causing a short. After moving the cables around and tiding
> them up neat and proper the problem has completely gone away (went
> from daily occurrence to two weeks so far with no problem).
>
> --- [Computer shuts off and won't turn back on until I unplug it](https://forums.tomshardware.com/threads/computer-shuts-off-and-wont-turn-back-on-until-i-unplug-it.217732/#post-11597639)

I did also stuff all my dangling PSU cables in an empty bay, and I
thought I was doing myself a service by doing so, preventing a mess of
cables in the middle of the case! I took the cables out of there, tidied
them up differently and put them back in there in a way where they
shouldn't move around too much or touch anything.

After that? The computer boots just fine and I haven't noticed a single
crash or any of the issues I was having around sleep and wake. I
progressively started to plug my sound card, then my external drives,
testing the sleep every time (to more easily identify a culprit if it
wasn't fixed), and it kept working. I've restored all of my original
"clean" drivers, bootloader and system configuration (that I had
modified during my attempts to fix the issue earlier), none of them
caused any problem again.

I've performed more than 20 successful sleep and wake cycles since then,
whether I explicitly put the computer to sleep or let it hibernates by
itself after a period of inactivity.

## Conclusion

At that point I'm somewhat confident that like in the two posts above,
the dangling PSU cables in the unit were shorting and causes those
issues. The fact they caused instability specifically at the sleep and
wake level were probably very specific to me and the precise way the
cables where shorting each other.

And the reason why the problem appeared to fix itself when unplugging
and replugging the machine, or sometimes by just opening it and looking
at it, doing no particular change inside? Those mere manipulations
probably bumped the dangling wires inside just enough so that they
weren't shorting anymore, until they do again.

It's still hard for me to precisely explain why this was happening
especially around sleep, and how the machine would otherwise be
perfectly stable and never crash as long as it didn't hit a sleep and
wake cycle. Maybe something to do with the fans slightly moving the
dangling cables while blowing at them? I'm not technical enough in
hardware and electronics to make sense of that, so if any of you reading
that have a better idea, please [let me know](/val.md#contact)!

And at the very least I hope that if you're reading this because of a
similar issue, that helped you sort this problem out as well!
