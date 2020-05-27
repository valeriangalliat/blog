Arch Linux bulletproof no config color emoji
============================================
May 27, 2020

I (used to) use DejaVu (`ttf-dejavu`) as my main system and default font
on Arch Linux and I've been mildly bothered about some emoji not being
displayed as color emoji even though I have `noto-fonts-emoji`
installed, and instead being displayed as black and white glyphs.

For a while, I've haven't been bothered enough by it to actually dig
into it, but recently I've decided to spend the time to figure it out.

TLDR
----

If you use `ttf-dejavu`, remove it and install `ttf-bitstream-vera` instead,
which is essentially the same font without the Unicode additions. Then
if you want some proper Unicode support, make sure to have `noto-fonts`
installed as well, so that it will fall back to Noto Unicode characters
when they're not defined by Vera.

Alternatively, just remove DejaVu and make Noto your default font,
period (which is even simpler and is what I've done in the end since I
ended up liking the look of the Noto fonts even better).

Why this bug happens
--------------------

The black and white glyphs are from the `ttf-dejavu` font, which is
essentially `tff-bitstream-vera` with added Unicode support, but that
also includes *some* black and white emoji.

This means that if you have an emoji font as fallback, e.g.
`noto-fonts-emoji`, `ttf-dejavu` will still have priority over the
subset of emoji that it defines.

Since it's not currently possible to blacklist part of a font characters
in fontconfig, there's been some forks of `ttf-dejavu` to remove emoji
characters, but still keep the other Unicode additions. This seems like
a good idea but the AUR package for that is fairly outdated and people
seem to report issues with it, so I would rather not go that way.

I've also found [on Reddit](https://www.reddit.com/r/archlinux/comments/6wkval/enable_noto_color_emoji_easily/)
a fontconfig, well, config, to fix that issue, which essentially sets
the default font to Noto instead of DejaVu, and Noto natively don't try
to conflict with the emoji font, so that works.

However, some websites depending on the font they request, and depending
on your browser, and configuration, and a bunch of other shit, are still
gonna be using DejaVu if it's installed, and then you'll get the black
and white emoji back, since that config only makes Noto and its color
emoji the default for generic fonts.

At that point you can just remove DejaVu altogether, which is the
solution I ended up going for, but if you want to keep the DejaVu/Vera
font as your default system font, read on.

The solution
------------

I've spent some more time digging, and I've eventually found a setup
that so far seems to work consistently across browsers and websites, and
the good thing is that it's *simple* and doesn't require any manual
configuration.

Simply remove `ttf-dejavu` and install `ttf-bitstream-vera` instead,
which is essentially the same font, without the addition of Unicode
glyphs, and then make sure to have `noto-fonts` installed as a fallback
for Unicode stuff.

Since unlike DejaVu, Noto doesn't try to define its own emoji, it'll
cleanly fall through, first, Vera, then for the Unicode characters not
found in Vera, it'll fall back to Noto, and finally it'll use whatever
emoji font you have installed!

I hope that helps!
