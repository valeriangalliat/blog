---
tweet: https://twitter.com/valeriangalliat/status/1649122170780491776
---

# macOS won't sleep from the Apple menu
Especially with an external monitor  
April 20, 2023

This one has been bugging me for a while now and I'm so glad I finally
found the cause.

It was **so stupid**: when I clicked **Sleep** in the Apple menu to
manually put my Mac to sleep, I was leaving my fingers on the trackpad
for a fraction of a second, and that "trackpad activity" caused it to
instantly wake up! 🤦‍♀️

If that was your issue as well, enjoy, you can stop reading here. In
case you're bored though, here's the full story.

## External monitors, laptop lid, and sleep

Before I got my external monitor, I was never putting my Mac to sleep
_explicitly_. I just closed the lid and that was it.

But with an external monitor connected, it's another story.

This [goes back to 2011](https://apple.stackexchange.com/q/18037/452681),
with Mountain Lion. Before then, on Snow Leopard, closing the lid of
your MacBook was putting it to sleep, regardless whether or not an
external monitor was connected. Since Mountain Lion though, doing so
puts your MacBook in clamshell mode, where the external screen becomes
your primary monitor!

There's essentially two groups of people when it comes to closing the
laptop with an external screen connected: the ones who want it to sleep
and the ones who want it to go in clamshell mode.

To be fair I could see myself leaning one way or the other depending on
what I want to do! We can't have both at the same time, and the option
that's not the default will have added friction.

When sleep was the default and you wanted to close your lid to go in
clamshell mode, you had to:

1. Close the lid and let your laptop go to sleep.
1. Wake it up with your external mouse/keyboard.

With clamshell being the default, if you want to sleep, you have to:

1. Unplug the monitor.
1. Close the lid.
1. Plug the monitor again if you were also charging through it.

Or even better:

1. Click **Sleep** in the Apple menu.
1. Close the lid.

That last one is acceptable to me, except at first, it didn't seem to
work!

## Waking up right away after manually sleeping

After clicking **Sleep** in the Apple menu, both screens would turn off
for like a second, and then they would come right up!

Usually after trying a couple times, it would actually go to sleep, but
I could never really understand why. This exactly
[what's described in this Apple support thread](https://discussions.apple.com/thread/253854954)
although it got locked for inactivity before ever being resolved.
It just links to a Apple guide about [diagnosing sleep issues](https://support.apple.com/en-ca/guide/mac-help/mchlp2995/mac)
with some generic advice but nothing useful to our case.

The other day though even after 10 tries, it kept waking up right away,
so I decided to dig into it.

## The technical symptoms

When we look at the Activity Monitor app, I discovered we can show
additional columns by right clicking on the columns header. In there, we
have **Preventing Sleep**.

<figure class="center">
  <img alt="Activity Monitor column settings" srcset="../../img/2023/04/activity-monitor-sleep.png 2x">
</figure>

In my case, it was `WindowServer`, aka the macOS process responsible for
managing windows, as well as `powerd`:

<figure class="center">
  <img alt="Processes preventing sleep" srcset="../../img/2023/04/activity-monitor-prevent-sleep.png 2x">
</figure>

<div class="note">

**Note:** the **Energy** tab in Activity Monitor is also useful to
diagnose sleep issues! Not only it displays the power consumption
details of the currently running apps, _but also of the ones that were
previously closed_! And you can directly see if they're preventing sleep
or not.

In our particular case though it wasn't as useful as the **CPU** tab
because it doesn't show the system processes.

</div>

Moreover, we can use the `pmset` command (power management settings) to
list if anything is preventing sleep (emphasis mine):

<pre><code class="hljs language-console"><span class="hljs-meta prompt_">$ </span><span class="language-bash">pmset -g assertions</span>
Assertion status system-wide:
   BackgroundTask                 0
   ApplePushServiceTask           0
<strong>   UserIsActive                   1</strong>
   PreventUserIdleDisplaySleep    0
   PreventSystemSleep             0
   ExternalMedia                  0
<strong>   PreventUserIdleSystemSleep     1</strong>
   NetworkClientActive            0
Listed by owning process:
<strong>   powerd: PreventUserIdleSystemSleep named: "Powerd - Prevent sleep while display is on"
   WindowServer: UserIsActive named: "com.apple.iohideventsystem.queue.tickle service:AppleHIDKeyboardEventDriverV2 product:Apple Internal Keyboard / Trackpad eventType:3"</strong>
	Timeout will fire in 600 secs Action=TimeoutActionRelease
</code></pre>

## Researching the symptoms

Again, we saw that `powerd` and `WindowServer` are the culprits.

* `powerd` has an assertion `PreventUserIdleSystemSleep` "prevent sleep
  while display is on".
* `WindowServer` has an assertion `UserIsActive` materialized by my own
  activity on the keyboard/trackpad.

Looking for those leads us to a thread on Apple support about
[`WindowServer` preventing sleep mode](https://discussions.apple.com/thread/252520499),
but without any proper resolution: the problem just seems to have gone
away for some people with an Apple update, but the messages are from a
few years ago, and in my case I'm running the latest version of macOS.

We also find two Reddit threads,
[one for `WindowServer`](https://www.reddit.com/r/MacOS/comments/n525zt/windowserver_preventing_my_mbp_from_sleeping/)
and [one for `powerd`](https://www.reddit.com/r/macbook/comments/o6kwqp/sleep_prevented_by_powerd/),
again both without a clear resolution.

<div class="note">

**Note:** The `WindowServer` thread has _unrelated_ resolutions where
`sharingd` and `coreaudiod` were preventing sleep, which is not what
we're looking for here. That being said if you're currently sharing
files over the network, or you have music playing, this will prevent
your Mac to sleep, so look into this first!

</div>

On top of that, I'm a bit dubious that `powerd` and `WindowServer` are
the problem here. After all, "preventing sleep while display is on"
sounds like a very reasonable thing to do, as well as preventing sleep
when there's activity on the keyboard/trackpad! And it would be
logical to expect that manually putting the system to sleep would bypass
those assertions anyway.

This is confirmed by [this post](https://www.bravolt.com/post/why-won-t-my-computer-sleep):

> `PreventUserIdleSystemSleep`: per the docs, the system should still sleep if you close your
> laptop's lid, or sleep manually.

[The `PreventUserIdleSystemSleep` docs](https://developer.apple.com/documentation/iokit/kiopmassertiontypepreventuseridlesystemsleep):

> The system may still sleep for lid close, Apple menu, low battery, or
> other sleep reasons.

It looks like we're hitting a rock wall here. No appropriate solution
out there, my only suspects turned out to be innocent, and I still can't
reliably put my Mac to sleep from the Apple menu!

## Digging deeper

We already tinkered with `pmset` earlier, and that's what we'll use to
find more about the problem. We can use `pmset -g assertionslog` to show
a log of the sleep assertions! Like `pmset -g assertions`, it'll show
the _current_ assertions (whatever may be preventing sleep), but it will
keep running and print any further event related to sleep (or not
sleep)!

So I can run `pmset -g assertionslog`, then click the **Sleep** button
from the Apple menu, and see what's in the logs when the screens light
back up right away.

<pre><code class="hljs language-console"><span class="hljs-meta prompt_">$ </span><span class="language-bash">pmset -g assertionslog</span>
Showing assertion changes(Press Ctrl-T to log all currently held assertions):

Action      Age       Type                          Name
======      ========  ====                          ====
Created     00:00:00  InternalPreventSleep          com.apple.powermanagement.darkwakelinger
Created     00:00:00  InteractivePushServiceTask    com.apple.apsd-login
<strong>Released    00:00:24  PreventUserIdleSystemSleep    Powerd - Prevent sleep while display is on</strong>
Created     00:00:00  NoIdleSleepAssertion          com.apple.timed.ntp
Created     00:00:00  InteractivePushServiceTask    com.apple.apsd-lastpowerassertionlinger
Released    00:00:00  InteractivePushServiceTask    com.apple.apsd-login
Created     00:00:00  InteractivePushServiceTask    com.apple.apsd-keepalive-push.apple.com
Created     00:00:00  InteractivePushServiceTask    com.apple.apsd-datareceived-push.apple.com
Released    00:00:00  InteractivePushServiceTask    com.apple.apsd-keepalive-push.apple.com
Released    00:00:00  NoIdleSleepAssertion          com.apple.timed.ntp
<strong>TurnedOn    00:00:00  UserIsActive                  com.apple.iohideventsystem.queue.tickle service:AppleMultitouchDevice product:Apple Internal Keyboard / Trackpad eventType:11</strong>
Created     00:00:00  InteractivePushServiceTask    com.apple.apsd-login
Created     00:00:00  PreventUserIdleSystemSleep    Powerd - Prevent sleep while display is on
Created     00:00:00  NoIdleSleepAssertion          com.apple.timed.ntp
</code></pre>

I highlighted the parts that were relevant in our case. First, we can
see that when we explicitly sleep, `powerd` do release its "prevent
sleep while display is on" assertion, so it effectively doesn't prevent
sleep anymore!

**However we see just after that `UserUsActive` was turned on, by
"tickling" the trackpad. What?**

## The moment it clicked 🤯

Then it occurred to me: when I click the **Sleep** button, my hand is,
well, on the trackpad, and it stays there for a fraction of a second
after I click. That's a fraction of a second too long, because the mere
fact of me removing my finger from the trackpad triggers an
`UserIsActive` event which wakes the system right back up!

So the solution is simple: I need to remove my finger from the trackpad
_immediately_ after I click the **Sleep** button!

I couldn't believe I spent hours to figure this out. I played around
with it and it's 100% that. The **Sleep** button actually works great,
regardless whether or not I have an external display connected, as long
as I don't keep my finger on the damn trackpad for even a fraction of a
second after clicking it. The gentlest touch will wake everything up
right away, even if it happens half a second after clicking that button.
