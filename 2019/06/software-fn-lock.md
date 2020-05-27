Software `Fn Lock`
==================
June 8, 2019

Most laptops feature a way to lock the function keys (`Fn Lock`), often by
pressing `Fn` + `Esc` or changing some BIOS or UEFI settings.

However, my laptop (ASUS VivoBook, X510UA-BB51-CB) does not have any way
to lock the function keys, forcing me to press the `Fn` key every time I
want to, for instance, change the screen brightness or the audio volume.

Since I use those much more than the F1 to F12 keys, I had to find a
software way to invert the function of those keys.

While I couldn't come up with a perfect automatic solution, I resorted
to a custom `xmodmap` configuration.

First, I listed the default mappings.

```sh
xmodmap -pke
```

My keyboard have the following mappings by default:

* F5, decrease screen brightness (`XF86MonBrightnessDown`)
* F6, increase scren brightness (`XF86MonBrightnessUp`)
* F7, screen saver (`XF86ScreenSaver`)
* F10, mute audio (`XF86AudioMiute`)
* F11, lower volume (`XF86AudioLowerVolume`)
* F12, raise volume (`XF86AudioRaiseVolume`)

If not sure based on what's written on the keyboard, you can also use
the `xev` program to find out what is the default association.

Then, filtering the output of `xmodmap -pke` for those keys, I found the
currently associated keycodes:

```xmodmap
keycode  71 = F5 F5 F5 F5 F5 F5 XF86Switch_VT_5
keycode  72 = F6 F6 F6 F6 F6 F6 XF86Switch_VT_6
keycode  73 = F7 F7 F7 F7 F7 F7 XF86Switch_VT_7
keycode  76 = F10 F10 F10 F10 F10 F10 XF86Switch_VT_10
keycode  95 = F11 F11 F11 F11 F11 F11 XF86Switch_VT_11
keycode  96 = F12 F12 F12 F12 F12 F12 XF86Switch_VT_12
keycode 232 = XF86MonBrightnessDown NoSymbol XF86MonBrightnessDown
keycode 233 = XF86MonBrightnessUp NoSymbol XF86MonBrightnessUp
keycode 160 = XF86ScreenSaver NoSymbol XF86ScreenSaver
keycode 121 = XF86AudioMute NoSymbol XF86AudioMute
keycode 122 = XF86AudioLowerVolume NoSymbol XF86AudioLowerVolume
keycode 123 = XF86AudioRaiseVolume NoSymbol XF86AudioRaiseVolume
```

I then just have to make a `~/.xmodmaprc` that inverts the keys:

```xmodmap
keycode 71  = XF86MonBrightnessDown
keycode 232 = F5
keycode 72  = XF86MonBrightnessUp
keycode 233 = F6
keycode 73  = XF86ScreenSaver
keycode 160 = F7
keycode 76  = XF86AudioMute
keycode 121 = F10
keycode 95  = XF86AudioLowerVolume
keycode 122 = F11
keycode 96  = XF86AudioRaiseVolume
keycode 123 = F12
```

Make sure to add `xmodmap ~/.xmodmaprc` to your `.xinitrc` or whatever
you use to configure your X11 session.
