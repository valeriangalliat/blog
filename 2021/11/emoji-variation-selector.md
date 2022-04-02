---
tweet: https://twitter.com/valeriangalliat/status/1461856790602264579
---

# Emoji displayed as monochrome symbol? 🤔 The Unicode variation selector
November 19, 2021

Are you wondering why some specific emoji are sometimes displayed as
black and white symbols instead of a colored glyph? And even more
confusing, you notice it happens on one device but looks perfect on
another? Look no further, you'll find all the answers in this article!

## TLDR

Some symbols can be displayed either as text (black and white glyph) or
as a color emoji. Using Unicode [variation selectors](https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)),
we can hint at whether to use one or the other, but when no variation
selector is specified, it's up to the system to decide which one to
pick, introducing inconsistencies.

Most emoji pickers will include the emoji variation selector to symbols
that would otherwise be ambiguous, but others won't and that's probably
how you ended up here.

If you want to make sure your emoji are always displayed in their color
version, the default macOS emoji picker does just that, otherwise
copy/pasting from [Emojipedia](https://emojipedia.org/) also works, as
they both don't leave room for ambiguity.

## The story

I initially noticed that some emoji that I added from my Linux machine
using [dmenumoji](https://github.com/valeriangalliat/dmenumoji) or [`rofimoji`](https://github.com/fdw/rofimoji)
were displayed as black and white symbols on macOS and Android.

For a while I just fixed them by inserting them again from another
device, or copy/pasting them from [Emojipedia](https://emojipedia.org/),
but I eventually got tired of this and decided to understand why this
was happening in the first place.

## What I learnt

Unicode defines two [variation selector characters](https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)),
[U+FE0E](https://codepoints.net/U+FE0E) and [U+FE0F](https://codepoints.net/U+FE0F),
also respectively known as VS15 and VS16.

When VS15 is appended to a symbol, it forces it to be displayed as text
(black and white glyph). Contrarily, when VS16 is appended, it forces
the color version to be displayed (emoji).

Now here's the fun part. What happens when a symbol has both a text and
a color variant, and no variant selector is specified?
[According to Wikipedia](https://en.wikipedia.org/wiki/Emoticons_(Unicode_block)#Variant_forms),
the emoji variant is selected:

> If there is no variation selector appended, the default is the
> emoji-style.

But [in reality](#concrete-tests), it appears that macOS and Android
will in fact default to the text symbol if there's one available! So
should we just append the VS16 code point on every single emoji? From
[its Emojipedia page](https://emojipedia.org/variation-selector-16/):

> [VS16 is] an invisible code point which specifies that the preceding
> character should be displayed with emoji presentation. Only required
> if the preceding character defaults to text presentation.

Alright. But we just saw that this is system-specific. Still, how do we
know which character *can* default to a text presentation? An
interesting hint is in the [unicode.org FAQ](https://unicode.org/faq/vs.html).

> **What variation sequences are valid?**
>
> Only those listed in [`StandardizedVariants.txt`](http://unicode.org/Public/UCD/latest/ucd/StandardizedVariants.txt),
> [`emoji-variation-sequences.txt`](http://unicode.org/Public/UCD/latest/ucd/StandardizedVariants.txt),
> or the registered sequences listed in the [Ideographic Variation Database (IVD)](http://www.unicode.org/ivd/).

Here, we specifically care about [`emoji-variation-sequences.txt`](http://www.unicode.org/Public/emoji/5.0/emoji-variation-sequences.txt),
the other sources not being related to emoji. This file lists all the
symbols that have both a monochrome glyph and a color emoji available.

It's only for those symbols that we need to append the VS16 code point
to make sure that they're displayed consistently on every system. And it
looks like that's precisely what the macOS and Android emoji pickers
seem to be doing!

## Concrete tests

Let's look at a few concrete examples to highlight the inconsistencies.

| Unicode code points | Command                     | Result |
|---------------------|-----------------------------|--------|
| U+1F60A             | `printf '\U0001f60A'`       | 😊     |
| U+1F60A, U+FE0E     | `printf '\U0001f60A\ufe0e'` | 😊︎     |
| U+1F60A, U+FE0F     | `printf '\U0001f60A\ufe0f'` | 😊️     |
| U+1F610             | `printf '\U0001f610'`       | 😐     |
| U+1F610, U+FE0E     | `printf '\U0001f610\ufe0e'` | 😐︎     |
| U+1F610, U+FE0F     | `printf '\U0001f610'\ufe0f` | 😐️     |
| U+2639              | `printf '\u2639'`           | ☹      |
| U+2639, U+FE0E      | `printf '\u2639\ufe0e'`     | ☹︎      |
| U+2639, U+FE0F      | `printf '\u2639\ufe0f'`     | ☹️      |
| U+270D              | `printf '\u270d'`           | ✍     |
| U+270D, U+FE0E      | `printf '\u270d\ufe0e'`     | ✍︎     |
| U+270D, U+FE0F      | `printf '\u270d\ufe0f'`     | ✍️     |

Or put another way:

| Default | Text | Emoji |
|---------|------|-------|
| 😊      | 😊︎   | 😊️    |
| 😐      | 😐︎   | 😐️    |
| ☹       | ☹︎    | ☹️     |
| ✍      | ✍︎   | ✍️    |

Your mileage may vary, but when I compare that table on my different
devices, while they all display the emoji variant properly, there's a
few inconsistencies for the default (no variant) and explicit text
variant.

| System  | Emoji | Default | Text  |
|---------|-------|---------|-------|
| Linux   | 😊️    | Emoji   | Emoji |
| Linux   | 😐️    | Emoji   | Text  |
| Linux   | ☹️     | Emoji   | Text  |
| Linux   | ✍️    | Emoji   | Text  |
| macOS   | 😊️    | Emoji   | Emoji |
| macOS   | 😐️    | Emoji   | Emoji |
| macOS   | ☹️     | Text    | Text  |
| macOS   | ✍️    | Text    | Text  |
| Android | 😊️    | Emoji   | Emoji |
| Android | 😐️    | Emoji   | Emoji |
| Android | ☹️     | Text    | Text  |
| Android | ✍️    | Text    | Text  |

While the font on my Linux machine doesn't have a text representation of
the blush emoji, it does for all the other ones. Regardless, when no
variant is specified, it always shows an emoji.

On the other hand, macOS and Android always default to the text variant,
but they appear to not have one available for the blush and neutral face
emoji.

<div class="note">

**Note:** those results are the ones I observed, but you might see
something different on your side! I've got a report from someone also
on a fresh macOS Monterey who gets different results from me, with the
frowning face showing as text even when explicitly requested as emoji,
and only for this site! And their default writing hand is an emoji even
though the text one is supported.

This might be due to differences in rendering betweem Chrome and
Firefox, so know that the browser can also affect this kind of things.

[Let me know](https://twitter.com/valeriangalliat/status/1461856790602264579)
if you observe something even different, I'm curious! 😁

</div>

## Conclusion

In today's article, we looked more closely at the Unicode standard and
the emoji specification to understand how to deal with symbols that have
both a text and emoji style available. We learnt about the VS15 and VS16
code points to select a specific variant, instead of leaving it for the
system to decide. Finally, we found out what symbols need an explicit
variant to be specified in order to avoid being rendered inconsistently.

I hope you now have everything you need to understand why you might be
noticing those inconsistencies, and how to fix them. Cheers! ✌️
