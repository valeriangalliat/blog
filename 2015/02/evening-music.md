# Evening music
February 22, 2015

I like to listen a few songs the night in my bed before actually
sleeping. But I hate having to get up again to stop the PC, and I don't
have any kind of remote control.

Ideally, I wanted to say "play 10 songs and shut down", or "play 30
minutes of music, wait the end of the song and shut down". Turns out this
is *trivial* to do with a music server like [MPD].

I'll use [mpc] to controll the MPD instance from the shell.

[MPD]: http://www.musicpd.org/
[mpc]: http://www.musicpd.org/clients/mpc/

## Play 10 songs and shut down

```sh
mpc idleloop player | head -18; poweroff
```

The `mpc idleloop player` command will listen for `player` events. A
`player` event will fire when the song is seeked, the end of a song is
reached, and the current song is changed.

In my case, nobody's seeking anything, and when the next song is
naturally selected, it will send two events (end and next), hence the
`head -18` (twice the number of songs I want, minus two because it's
about "next song" events). The `head` command will exit when the given
number of lines are printed.

Originally from [this tweet](https://twitter.com/valeriangalliat/status/569613240168292352).

## 30 minutes of music and shut down

```sh
sleep 30m; mpc idle player; poweroff
```

This one speaks for itself:

> Sleep for 30 minutes, idle until the next `player` event, and shut
> down.

Originally from [this tweet](https://twitter.com/valeriangalliat/status/569613564278910977).

## Bonus: progressively lower volume

I also like the volume to go down slowly while listening to music before
sleeping. This is extremely simple to do (here, I manage my sound with
ALSA):

```sh
while :; do amixer set PCM 1%-; sleep 3m; done
```

This will lower the PCM channel by 1% every 3 minutes. Tweak to your
tastes!
