Listen a raw playlist with YouTube
==================================
May 22, 2015

Sometimes the easiest way to share a playlist is to just give a raw list
of song titles and artists. However it's not straightforward to actually
*play* it.

I wrote a little script to ease the pain, playling each song from
YouTube directly with [mpv](http://mpv.io/) (my player of choice).

```sh
#!/bin/sh -e

go() {
    echo "Playing $1"

    # Force TTY input for controls even if titles are read from input.
    mpv --vid=no "$(youtube-dl -g "ytsearch:$1" | tail -1)" < /dev/tty
}

# All arguments as a single space separated string.
if [ -n "$*" ]; then
    go "$*"
    exit
fi

# Read one title per line.
while read title; do
    go "$title"
done
```

You can see the latest source [here](https://github.com/valeriangalliat/dotfiles/blob/master/bin/ytpl).

You can either give a single song name as arguments (script arguments
are concatenated), or from standard input, one title per line.

For example:

```sh
ytpl << EOF
born to be alive
girls got rhythm
EOF
```

Continuing a playlist
---------------------

If you ever stop the script in the middle of a playlist, and want to
continue later, just pipe the playlist file in `sed`:

```sh
sed '0,/<title>/d' < playlist | ytpl
```

Where `<title>` is the title of the song you stopped at.
