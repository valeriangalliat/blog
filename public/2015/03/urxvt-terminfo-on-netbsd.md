urxvt terminfo on NetBSD
========================
March 11, 2015

When installing urxvt (rxvt-unicode) on NetBSD, the corresponding
terminfo is not installed automatically.

The `pkg_add` installation notice is effectively telling to either
define `TERM=rxvt` (rxvt is supported by default), or install the
provided terminfo from `share/examples`.

After reading [**terminfo**(5)], I found that I needed to use the `tic`
command to compile a terminfo database, and that every user can have its
personal database in `~/.terminfo.cdb`. This command did the job:

[**terminfo**(5)]: http://netbsd.gw.com/cgi-bin/man-cgi?terminfo+5

```sh
tic -o ~/.terminfo.cdb /usr/pkg/share/examples/rxvt-unicode/rxvt-unicode.terminfo
```

For a global installation (for all users), we can append the terminfo
file to the global database, and compile it:

```sh
cat /usr/pkg/share/examples/rxvt-unicode/rxvt-unicode.terminfo >> /usr/share/misc/terminfo
tic /usr/share/misc/terminfo
```

<!-- https://www.jeuxvideo.com/chris_27/forums/message/734099101 -->
