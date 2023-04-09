# Using your lock screen as login screen on Linux
August 22, 2021

For a very long time I wasn't using a [display manager](https://wiki.archlinux.org/title/Display_manager)
(also known as login manager). I just had [this line](https://github.com/valeriangalliat/dotfiles/blob/master/zsh/zshrc.home#L6)
in my `~/.zshrc` to automatically start a X session after logging in on
TTY1, effectively using the TTY login prompt as my login manager:

```sh
# Start X on login on TTY1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec startx
fi
```

The only drawback to this was that I had to type my username, which is
redundant as this is a single-user system, and more importantly, that
the X session was considered to be a TTY session by logind, because
there's no way to upgrade a TTY session to a graphical session.

This affects a number of semantics, especially the way logind deals with
[detecting idle](https://github.com/systemd/systemd/issues/14053#issuecomment-564138746),
which is an issue if we want to use logind's `IdleAction` for example to
suspend the system after a period of inactivity.

Using a display manager makes sure to register the session as graphical
and fixes that issue, but I didn't like to introduce another graphical
interface that's not consistent with the rest of my system, and I'd
rather not get into configuring it extensively and theming it.

## Logging in to a lock screen?

Since I'm the only user of my laptop, I don't need a fancy interface to
select among a list of users and such, and it felt like my lock screen
would be a perfect fit as a login screen. I use i3lock which I configure
to just show a background and let me type my password to unlock the
screen.

While i3lock itself is not meant to be used like this, you can achieve
this with a combination of LightDM autologin feature, and starting
i3lock first thing in your `~/.xprofile`:

```sh
# Lock screen before actually starting, to be used with autologin
i3lock -n
```

<div class="note">

**Note:** I use the `-n` (`--nofork`) option here so that i3lock blocks
the start script until it's unlocked.

</div>

And the following in `/etc/lightdm/lightdm.conf` (where `foo` is your
username):

```ini
[Seat:*]
autologin-user=foo
```

This results in LightDM acting as a totally transparent display manager,
allowing the logind session to be considered graphical, and i3lock being
started first thing in the session, blocking until it's unlocked to
start the actual window manager.

It's so far the lightest way I've found to start a graphical session
without it being considered a TTY by logind, while still being prompted
for my password. I hope you find this useful!
