---
tweet: https://twitter.com/valeriangalliat/status/1525897795844153344
---

# Migrating from X11 to Wayland and from i3 to Sway
May 15, 2022

Finally. After so long. I switched to Wayland. 🎉

I remember back when I started using Linux, more than 10 years ago now,
I was already reading about Wayland, and seeing early adopters on forums
using it and loving it despite running into all kinds of issues... this
wasn't for me. X11, while old and outdated, was well supported for
everything I wanted to do, and that was awesome.

But the other day, I was bored or something, and I asked myself: is
Wayland mainstream enough for me to use it yet?

The answer was... nearly yes. Yes enough for me to switch. And that's a
fucking good news.

In this post I'll share with you what was needed to **get a usable Wayland
server running with Sway**, all the Wayland alternatives to the X11
programs I was previously using, and finally how I completely purged
X11 from my system.

I'm a Arch Linux user, so the commands will be adapted to that system.

## Installing Wayland and Sway

Being a long time [i3](https://i3wm.org/) user,
[Sway](https://swaywm.org/) was the obvious choice as a Wayland
compositor. The fact it's compatible with my existing i3 config should
ease the transition quite a lot.

```sh
pacman -S wayland sway
```

Then from a TTY I could just run `sway`, and end up in an environment
pretty close to my habitual i3! Good start.

## Figuring all the Wayland alternatives

There's a number of X11 programs that I was using, that just don't work
on Wayland. The good thing is that the Wayland ecosystem is mature
enough nowadays that there was a solid alternative for all of them!

* [dmenu](https://tools.suckless.org/dmenu/), the great simple dynamic menu
  is now [bemenu](https://github.com/Cloudef/bemenu).
* [feh](https://feh.finalrewind.org/), the fast and light image
  viewer, is now [imv](https://sr.ht/~exec64/imv/).
* [maim](https://github.com/naelstrof/maim) (the improved
  [scrot](https://github.com/resurrecting-open-source-projects/scrot))
  to take screenshots is replaced by [grim](https://sr.ht/~emersion/grim/),
  with [slurp](https://github.com/emersion/slurp) to select a region.
* [xclip](https://github.com/astrand/xclip) and [XSel](https://vergenet.net/~conrad/software/xsel/)
  that allow to manipulate the selection and clipboard from the terminal
  are replaced by [wl-clipboard](https://github.com/bugaevc/wl-clipboard)
  (providing `wl-copy` and `wl-paste`).
* `xbacklight` that helps controlling the screen backlight is now
  [Light](https://github.com/haikarainen/light).
* [xdotool](https://www.semicomplete.com/projects/xdotool/) that I
  [use to type an emoji](https://github.com/valeriangalliat/dmenumoji/blob/997e48c69315131b32f9e3368b88151f811d14eb/dmenumoji#L24)
  in my [dmenumoji](https://github.com/valeriangalliat/dmenumoji) emoji
  picker is now [wtype](https://github.com/atx/wtype) (and I made a
  [`bemenumoji`](https://github.com/valeriangalliat/dotfiles/blob/14bcdb5d9e7c9d14f15cf3af33c0c862e18bdfb2/bin/bemenumoji)
  script instead).
* [Redshift](http://jonls.dk/redshift/) that gives an orange tint to the
  screen in the evening, is now [Gammastep](https://gitlab.com/chinstrap/gammastep).

There's also a number of programs that are no longer needed:

* [xss-lock](https://bitbucket.org/raymonad/xss-lock) that I used to
  lock the screen on suspend and hibernate is superseded by
  [swayidle](https://github.com/swaywm/swayidle).
* [xidlehook](https://gitlab.com/jD91mZM2/xidlehook) (the replacement
  for [xautolock](https://linux.die.net/man/1/xautolock)) allowing to
  execute commands after a certain idle period (like dim screen, lock,
  suspend), is superseded by [swayidle](https://github.com/swaywm/swayidle)
  too.
* `xset` that I used to set to lower the keyboard repeat delay is
  replaced by the `repeat_delay` Sway option.
* [picom](https://github.com/yshui/picom), the compositor I used with
  X11 is no longer needed because Sway itself is a compositor.

So in the end, this leaves us with the following commands:

```sh
pacman -S bemenu-wayland imv grim slurp wl-clipboard light wtype gammastep
pacman -Rns dmenu feh maim xclip xsel xorg-xbacklight xdotool redshift xss-lock xidlehook xorg-xset picom
```

Because [foot](https://codeberg.org/dnkl/foot) is the default terminal
emulator of Sway, I [decided to try it](../04/xfce4-terminal-vs-foot.md)
instead of my usual [xfce4-terminal](https://docs.xfce.org/apps/terminal/start).
That wasn't a complete success for me and I rolled back to
xfce4-terminal since it works just fine on Wayland anyways!

Finally, I had a few `.xmodmaprc` modifications that I use to
[invert <kbd>Alt</kbd> and <kbd>Ctrl</kbd>](https://github.com/valeriangalliat/dotfiles/blob/1d2098a7da513dab195554997efaac22a0d77a02/x11/xmodmaprc)
and also [emulate <kbd>Fn Lock</kbd>](../../2019/06/software-fn-lock.html)
because it's not supported on my laptop.

xmodmap is a X11-only thing, and I had to [configure XKB directly](../04/xmodmaprc-wayland.md)
to reproduce this behavior. XKB stands for "X keyboard extension" but it
is also [used by Wayland](https://wayland-book.com/seat/xkb.html).

## Full diff

If you want to see the details, here's
[the link to the full diff in my dotfiles](https://github.com/valeriangalliat/dotfiles/commit/537f9e14f332b6591a7d932aee056d4d412ec873#diff-d46a2e36b87ce6bb331477a420580121b2fe0c856f81fd5176053ffc4e0828af).

I anchored it to the conversion from `~/.config/i3/config` to
`~/.config/sway/config` but feel free to move around and see the other
changes I did.

I took this as an opportunity to change a few unrelated things in there
so not all the modifications were strictly necessary.

## Cleaning up

Now we have a working Wayland and Sway installation, we can remove X11
altogether from the system! Or can we?

```sh
pacman -Rns xorg-server i3
```

Turns out this didn't work for me. VLC, [mpv](https://mpv.io/), Chromium
and [calibre](https://calibre-ebook.com/) all required some X11
dependency that would be removed by this command. Bummer.

So what I did instead:

```sh
pacman -Rns xorg-server i3 vlc mpv chromium calibre
pacman -S vlc mpv chromium calibre
```

## Quirks

### Qt and Wayland

VLC and calibre both use Qt, and as [documented on the ArchWiki](https://wiki.archlinux.org/title/wayland#Qt),
we need to install `qt5-wayland` for Qt to work.

### Special flags for Chromium

Programs built on Chromium (including Chromium itself obviously) support
Wayland *nearly* out of the box, but they require some kind of flag to
enable the support. Not really sure why this is a thing, but basically I
need to start Chromium and Visual Studio Code like this:

```sh
chromium --ozone-platform-hint=auto
code --enable-features=UseOzonePlatform --ozone-platform=wayland
```

I use those programs once in a blue moon anyways, so I don't really
care.

### Idle inhibitor

I used to use `xidlehook --not-when-audio` to prevent dimming the
screen, disconnecting the screen, or locking the computer after an idle
period if there's audio playing.

This is great for example when watching a movie... you don't necessarily
actively use the computer but you don't want it to lock and suspend or
hibernate while it's playing either!

Some programs like mpv support inhibiting idle while playing, which
is great, but others like VLC and Firefox don't.

In general, the "not when audio" trick was a pretty good fallback that
didn't require any custom implementation in existing programs.

Luckily, there's [SwayAudioIdleInhibit](https://github.com/ErikReider/SwayAudioIdleInhibit)
([on the AUR](https://aur.archlinux.org/packages/sway-audio-idle-inhibit-git))
that does exactly that. Fantastic.

The only quirk I noticed with it is that in Firefox, some very specific
sites like [Artlist](https://artlist.io/) (the only one I identified so
far) manage to register an active audio channel at all times even if
they're not playing anything, and as long as the tab is open, idle will
be inhibited. This is not good as I tend to keep tabs around for days if
not weeks!

To be able to notice when this happens more easily, I
[modified my i3blocks volume block](https://github.com/valeriangalliat/dotfiles/commit/2fd9359a6a0e76891b6b10fe1ef97f7aec35f926)
to display a different icon whether or not there's any PulseAudio sink
in state `RUNNING`.

## Conclusion

Migrating to Wayland was a pretty smooth transition at the end of the
day, and I'm glad I finally did it! Everything works great, it seems
like Wayland programs are usually more recent and have better UX than
their X11 equivalent that I was previously using.

For example I love the *slurp* screen selection, and I don't have to
[patch dmenu](../../2021/08/dmenu-libxft-bgra-emoji-support.md) anymore
in order to support emojis, since they natively work with bemenu, and
basically everything else?

Also I realized that Wayland allowed me to zoom in on any part of the
screen with my trackpad out of the box, and that's pretty useful. One of
the features I was kinda missing from MacBooks but never spent the time
to figure if I could do it or not with X11.

If you've been thinking about migrating to Wayland, it's probably a good
time to do so!
