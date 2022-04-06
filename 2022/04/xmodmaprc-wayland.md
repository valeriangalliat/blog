# Migrating `.xmodmaprc` to Wayland: remap arbitrary keys
April 5, 2022

I recently moved from X11 to Wayland, and one of my challenges that came with it was to find an alternative for my `.xmodmaprc`, that I used for
two purposes:

1. [Invert the left <kbd>Alt</kbd> and <kbd>Ctrl</kbd> keys](https://github.com/valeriangalliat/dotfiles/blob/1d2098a7da513dab195554997efaac22a0d77a02/x11/xmodmaprc).
1. [Invert the behavior of the function keys](../../2019/06/software-fn-lock.html),
   (to emulate <kbd>Fn Lock</kbd> which is not supported on my laptop).

Since `xmodmap` is a X11 thing, I needed to find a Wayland alternative
to this.

It seems that the common answer is to directly modify the XKB database
in `/usr/share/X11/xkb`, but according to [this Stack Exchange post](https://unix.stackexchange.com/a/698044/521108)
(referencing the [XKB docs](https://xkbcommon.org/doc/current/md_doc_user_configuration.html)),
we learn that we can customize XKB symbols in
`~/.config/xkb/symbols/<name>` and XKB rules in
`~/.config/xkb/rules/evdev`. Great.

## Inverting <kbd>Alt</kbd> and <kbd>Ctrl</kbd>

This is something commonly done with `xmodmap`, and there's very little
documentation of alternative solutions, but I found [this answer](https://askubuntu.com/a/885047)
showing how to achieve that by modifying the XKB symbols in
`/usr/share/X11/xkb/symbols/ctrl`:

```conf
xkb_symbols "swap_ralt_rctl" {
    replace key <RALT> { [ Control_R, Control_R ] };
    replace key <RCTL> { [ Alt_R, Meta_R ] };
};
```

Because I just learnt I could modify stuff in `~/.config/xkb/symbols`
instead, I added this code to `~/.config/xkb/symbols/ctrl`.

Then in my Sway config (this will vary depending on your window manager
or desktop environment), I enabled the `ctrl:swap_ralt_rctl` option for
my keyboard:

```conf
input type:keyboard {
    xkb_options ctrl:swap_lalt_lctl
}
```

And this worked! **But it shouldn't have.** I realized later (when
adding another option with a different name) that it is **required** to
also add a matching entry to the `xkb/rules/evdev` file. So why did it
work?

It turns out that there was already a native XKB option with that exact
name (in `/usr/share/X11/xkb/symbols/ctrl` and
`/usr/share/X11/xkb/rules/evdev`), and that's why the name was
recognized. And unsurprisingly, that native option does exactly what I
want, so I could get rid of that `~/.config/xkb/symbols/ctrl` file
altogether and just use `ctrl:swap_lalt_lctl` in my Sway config. 😆

## Emulating <kbd>Fn Lock</kbd>

Now on to the hardest part. My `~/.xmodmaprc` used to look like this,
essentially, mapping <kbd>F5</kbd> to what <kbd>Fn</kbd> + <kbd>F5</kbd>
would do, and inversely, and so on for a number of function keys that I
use.

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

With a bit of trial and error, and looking at the
`/usr/share/X11/xkb/keycodes/evdev` file, I could figure what were the
corresponding XKB keys for the codes above:

```
<FK01> = 67;
<FK02> = 68;
<FK03> = 69;
<FK04> = 70;
<FK05> = 71;
<FK06> = 72;
<FK07> = 73;
<FK08> = 74;
<FK09> = 75;
<FK10> = 76;
<FK11> = 95;
<FK12> = 96;
...
<MUTE> = 121;
<VOL-> = 122;
<VOL+> = 123;
...
alias <I121> = <MUTE>;	// #define KEY_MUTE                113
alias <I122> = <VOL->;	// #define KEY_VOLUMEDOWN          114
alias <I123> = <VOL+>;	// #define KEY_VOLUMEUP            115
...
<I160> = 160;		// #define KEY_COFFEE              152
<I232> = 232;		// #define KEY_BRIGHTNESSDOWN      224
<I233> = 233;		// #define KEY_BRIGHTNESSUP        225
```

Leading me to the write following `~/.config/xkb/symbols/ctrl`:

```conf
partial modifier_keys
xkb_symbols "swap_fn_keys" {
    replace key <FK05> { [ XF86MonBrightnessDown ] };
    replace key <FK06> { [ XF86MonBrightnessUp ] };
    replace key <FK07> { [ XF86ScreenSaver ] };
    replace key <FK09> { [ XF86TouchpadToggle ] };
    replace key <FK10> { [ XF86AudioMute ] };
    replace key <FK11> { [ XF86AudioLowerVolume ] };
    replace key <FK12> { [ XF86AudioRaiseVolume ] };
    replace key <I232> { [ F5 ] };
    replace key <I233> { [ F6 ] };
    replace key <I160> { [ F7 ] };
    replace key <I199> { [ F9 ] };
    replace key <I121> { [ F10 ] };
    replace key <I122> { [ F11 ] };
    replace key <I123> { [ F12 ] };
};
```

And this time because `swap_fn_keys` is a new entry, I did need to add
it to `~/.config/xkb/rules/evdev`. According to the
[XKB docs](https://xkbcommon.org/doc/current/md_doc_user_configuration.html#autotoc_md17),
this is done with the following pattern:

```conf
! option = symbols
  ctrl:swap_fn_keys = +ctrl(swap_fn_keys)

! include %S/evdev
```

And I can finally include it to my Sway keyboard options:

```conf
input type:keyboard {
    xkb_options ctrl:swap_lalt_lctl,ctrl:swap_fn_keys
}
```
