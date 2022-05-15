# xfce4-terminal vs. foot
April 5, 2022

This is going to be a pretty personal piece, but I figured I'd share
either way. 🤷

I've been using [xfce4-terminal](https://docs.xfce.org/apps/terminal/start)
as my terminal emulator on Linux for quite a while now, and I like it.
It's lightweight, supports emojis and has transparency, and it just
works for me.

Recently I [switched to Wayland](../05/migrating-x11-wayland-i3-sway.md),
and saw that [Sway](https://swaywm.org/) (the Wayland alternative to
[i3](https://i3wm.org/)) was using [foot](https://codeberg.org/dnkl/foot)
as their default terminal emulator. I didn't know about it, but it's
described as "a fast, lightweight and minimalistic Wayland terminal
emulator", which sounds like music to my ears, so I decided to try it!

Here's my feedback after using it for a couple of weeks, in particular
the issues I encountered and the fixes I found.

## Incompatibility with Vim for some <kbd>Ctrl</kbd> key combinations

The (deep) details are explained in [this issue on Vim](https://github.com/vim/vim/issues/9014),
[this issue on foot](https://codeberg.org/dnkl/foot/issues/849), and the
solution is documented [in foot's wiki](https://codeberg.org/dnkl/foot/wiki#user-content-ctrl-key-breaks-input-in-vim).

Basically, doing some <kbd>Ctrl</kbd> key combinations can break other
<kbd>Ctrl</kbd> key mappings when using Vim inside foot.

This is due to the fact that [foot uses CSI 27 escape sequences](https://github.com/vim/vim/issues/9014#issuecomment-965187794)
for some key combinations but keeps using "legacy" escape sequences for
others.

[xterm defines a feature `modifyOtherKeys`](https://invisible-island.net/xterm/manpage/xterm.html)
defining 2 behaviors for dealing with escape sequences (level 1 and
level 2).

foot implements the level 1 but after seeing a CSI 27 escape sequence,
[Vim assumes level 2](https://github.com/vim/vim/issues/9014#issuecomment-965388693),
resulting in this incompatibility.

As mentioned [in foot's wiki](https://codeberg.org/dnkl/foot/wiki#user-content-ctrl-key-breaks-input-in-vim),
I added the following to my `vimrc` to fix it:

```vim
"
" Make Vim and foot collaborate.
"
" See <https://codeberg.org/dnkl/foot/wiki#ctrl-key-breaks-input-in-vim>
" and <https://github.com/vim/vim/issues/9014>.
"
let &t_TI = "\<Esc>[>4;2m"
let &t_TE = "\<Esc>[>4m"
```

If you're curious about `t_TI` and `t_TE`, you can read more about it
[here](https://vi.stackexchange.com/a/27400).

## Bracketed paste

[Bracketed paste](https://cirw.in/blog/bracketed-paste) allows terminal
emulator to communicate through escape sequences that content is being
pasted as opposed of being typed, allowing programs to handle the
content differently.

This is especially useful inside Vim to paste text without having to
care about turning on and off `paste` mode (for example to avoid messed
up indent when pasting code).

Vim doesn't know that foot supports bracketed paste so it doesn't work
by default. But as shown in `:help xterm-bracketed-paste`, we can hint
at it by adding this to our `vimrc`:

```vim
if &term =~ "foot"
    let &t_BE = "\e[?2004h"
    let &t_BD = "\e[?2004l"
    exec "set t_PS=\e[200~"
    exec "set t_PE=\e[201~"
endif
```

Not too bad!

This is for Vim specifically, but [from looking at this issue](https://codeberg.org/dnkl/foot/issues/305),
it looks like there might be other bracketed paste support issues with
other software that need to be addressed individually. Not a problem for
me for now...

## Clicking URLs

I took for granted to be able to <kbd>Ctrl</kbd> + click links in
terminal emulators. [foot took a different approach](https://codeberg.org/dnkl/foot#user-content-urls)
to this with a keyboard-driven URL mode:

> Pressing <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>U</kbd> enters "URL
> mode", where all currently visible URLs are underlined, and is
> associated with a "jump-label". The jump-label indicates the key
> sequence (e.g. "AF") to use to activate the URL.

I love the ability to be *able* to navigate URLs using my keyboard only,
but I also like to have the *option* to click those links.

Sometimes the cost of pressing <kbd>Ctrl</kbd> + <kbd>Shift</kbd> +
<kbd>U</kbd>, identify the "jump-label" and typing it, feels higher than
the cost of switching to my trackpad and <kbd>Ctrl</kbd> + clicking the
URL I'm already looking at.

I probably would get used to it after a while if I *only* used foot, but
I also use iTerm2 on macOS where I <kbd>Command</kbd> + click the links,
and I like to keep shortcuts and habits somewhat consistent between all
the systems I use.

## Conclusion

foot is indeed fast and lightweight, and it's a great Wayland terminal
emulator.

Because it sets `TERM=foot` in the environment, many programs (like Vim)
don't have built-in support for it (e.g. knowing how foot handles escape
sequences and bracketed paste), meaning that you might need to add extra
configuration to all the programs where you need this to add foot
support.

xfce4-terminal, for better or for worse, sets `TERM=xterm-256color`,
which means most programs know out of the box how to deal with it (as
long as it maintains proper xterm compatibility). In practice, that's
probably why xfce4-terminal "just works" for me.

Because of that, and the fact I personally see clicking links as a "must
have" and a keyboard mode to open links a "nice to have", and not the
other way around, I'm moving back to xfce4-terminal.

I like lightweight and minimalist programs, but I like convenience as
well. xfce4-terminal is the perfect balance for me, and it's pretty
strongly on the lightweight side already!
