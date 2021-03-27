# Change rxvt font size on the fly
September 18, 2014

Ever wanted to change the terminal font size (or even font family) on
the fly when using rxvt? This is easy!

```sh
printf '\33]50;%s%d\007' "xft:monospace:size=" "$size"
```

Replace `$size` with the size of your choice.

I even made [a little script][fz] to ease this, called `fz`:

```sh
#!/bin/sh -e
#
# Dynamically change font size in rxvt.
#

# Tweak this with your own font settings
readonly PREFIX='xft:monospace:size='

if [ -z "$1" ]; then
    echo 'Usage: fz <size>'
    exit 1
fi

printf '\33]50;%s%d\007' "$PREFIX" "$1"
```

[fz]: https://github.com/valeriangalliat/dotfiles/blob/master/bin/fz
