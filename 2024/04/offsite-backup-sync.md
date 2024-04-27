---
tweet: https://twitter.com/valeriangalliat/status/1784030027967062106
---

# Encrypted offsite backup system: syncing 📲
Or how to encrypt a rsync backup  
April 26, 2024

<div class="note">

1. [Encrypted offsite backup system: storage 💾](offsite-backup-storage.md)
1. Encrypted offsite backup system: syncing 📲

</div>

In [the previous post](offsite-backup-storage.md) I decided to go with
a [Hetzner Storage Box](https://www.hetzner.com/storage/storage-box/)
for my backups.

It supports a number of file transfer protocols as well as first-class
support for backup protocols like BorgBackup and Restic, and of course,
the venerated rsync.

I ended up settling for rsync, because it's a lower level option than
BorgBackup and Restic, that gives me a ton of freedom do design my
backup system the way I want.

rsync is also incredibly simple to use and understand, and at the end of
the day it just syncs files from one place to another. There's nothing
specific to rsync in the layout of my backups, so I don't actually
_need_ rsync for the backups to be usable. That's a massive advantage.

It comes to the cost of having to take care of everything else myself,
in particular encryption, as well as incremental backups (which I chose
to not implement, although it's [possible](#bonus-implementing-incremental-backups)).

## Other tools I tried

I also tried BorgBackup, Restic, Kopia, Duplicaciy, Duplicity.

Having chosen Hetzner as a backend, Kopia, Duplicacy and Duplicity
didn't have native support so they were reduced to syncing over SFTP
which put them at a disadvantaged for speed compared to the other
options that had native support on Hetzner.

On top of that here's a few notes of what turned me off for each of
those:

* **Kopia:** I encountered issues setting it up with SFTP.
* **Duplicacy:**
  * Setting up the CLI wasn't straightforward, had to resort to finding
    info in some random forum posts.
  * Doesn't support SSH aliases.
  * No way to configure a SSH key without being prompted every time.
  * May ask for SSH password / key in the middle of a backup so you
    can't just walk away.
* **Duplicity:** can't easily garbage collect old backups because they
  all depend on each other, so it makes regaining space pretty cumbersome.
* **Restic:** was pretty impressed overall but rsync was significantly
  faster despite both having native support on Hetzner.
* **BorgBackup:** I definitely tried it back then but it doesn't seem
  that I took any notes like for the other ones... maybe I should try it
  again at some point? With rsync it's probably the one that would fit
  the best my use case, but I guess I like how transparent is rsync.

## Syncing

The actual syncing part is super easy. I'm just going with a basic:


```sh
rsync "$SOURCE" "$DESTINATION" --archive --delete
```

I'm also adding `--no-specials` and `--no-devices` if I'm backing up a
directory that could have some of those special handles.

I add `--exclude-from exclude-file` to ignore a bunch of patterns that
don't need to be backed up.

And finally, I'm customizing the output with `--itemize-changes` and
`--info=progress2`.

## Encryption

That's where things get spicy, because rsync doesn't do encryption
itself.

I found a blog post about [encrypted offsite backups with rsync](https://www.gamecreatures.com/blog/2016/06/19/encrypted-offsite-rsync-backups/)
which is exactly what I was trying to do. It uses
[EncFS](https://vgough.github.io/encfs/) as the encryption layer.

I ended up using [gocryptfs](https://nuetzlich.net/gocryptfs/) on my
side, mainly because it's still actively maintained.

gocryptfs allows you to have an encrypted directory on disk, and mount
the decrypted version to use it. But they also have a "reverse" mode,
where you can mount a directory into its encrypted representation.
That's what I need. (I just want the encryption for syncing to my remote
storage, the data is already encrypted on disk at a lower level
otherwise.)

With gocryptfs, that looks like:

```sh
gocryptfs -reverse -init /path/to/directory
gocryptfs -reverse /path/to/directory /path/to/mount
```

From there, I can apply my rsync command to sync the encrypted
`/path/to/mount` with my Hetzner server!

Not that complicated after all.

Well... except if you're running macOS. This rabbit hole is deep enough
that it [deserves its own blog post](gocryptfs-macos-macfuse.md). 🙃

## Making the encrypted rsync output intelligible

Now we're syncing an encrypted directory, the output of rsync only shows
the encrypted paths. That's OK, but I don't like it. I wish I saw the
_actual_ files it was transferring, so that if one of them takes a long
time, I can instantly identify if it's a file that should or not be
included in the backup anyway. Maybe just add it to my ignore list.

Luckily, gocryptfs provides an API to translated encrypted paths to
their plaintext version!

This comes through a separate util, `gocryptfs-xray`, that's not
included in the Homebrew version, so we need to compile gocryptfs from
source:

```sh
git clone https://github.com/rfjakob/gocryptfs

# Checkout the version you actually want, or YOLO and build from `main`
# git checkout v2.4.0

./build-without-openssl
```

Then make sure to add the `gocryptfs` and `gocryptfs-xray` binaries
somewhere that's in your `PATH` (or just run them from there if you
prefer).

`gocryptfs-xray` needs access to the gocryptfs `ctlsock`, a socket to
communicate with the gocryptfs process. You get one by adding `-ctlsock
/path/to/ctlsock` to your `gocryptfs` invocation.

Then, we can parse the rsync output and translate any encrypted path in
its decrypted version. I made a script for that:
[`gocryptfs-rsync-pretty`](https://github.com/valeriangalliat/gocryptfs-rsync/blob/master/gocryptfs-rsync-pretty).
Just pipe the rsync output to it:

```sh
rsync ... 2>&1 | gocryptfs-rsync-pretty /path/to/ctlsock /path/to/mount
```

## Putting it all together

We now have a functional encrypted offsite backup system! It's a
combination of:

* gocryptfs to mount an encrypted representation of a directory,
* rsync to sync it to a remote host,
* a small script to make the rsync output intelligible.

In [this repo](https://github.com/valeriangalliat/gocryptfs-rsync) you
can find the code I use to combine those 3 elements.

It's not much more than:

```sh
gocryptfs -reverse -ctlsock /path/to/ctlsock /path/to/directory /path/to/mount

rsync "$@" /path/to/mount "$DESTINATION" 2>&1 \
    | gocryptfs-rsync-pretty /path/to/ctlsock /path/to/mount
```

## Bonus: implementing incremental backups

In my solution above, the backups are not incremental. I'm just syncing
the _current_ state to the remote host, but I keep no history of the
previous "snapshots". This could be an issue, for example, if I end up
running a backup _after_ my systems gets compromised or after I lose
some data, then my backup is useless.

This is fine with me because I also do incremental backups that just
don't happen to be offsite. I guess I'm not edging against my house
burning down or getting my computers and drives robbed, _while at the
same time_ having experienced some kind of data loss that I've
accidentally propagated to my offsite server. 🙃

Anyway, in order to add incremental backups to the equation, we could
use [Linux Time Machine](https://github.com/cytopia/linux-timemachine)
(which also works very well on Mac despite the name 😁).

It works very much like macOS Time Machine, pretty much down to the
underlying way the incremental backups are implemented on the
filesystem: each "snapshot" gets its own directory, but then files that
didn't change since the latest snapshot are just hardlinked to avoid
duplication! So essentially, only the files that changed get stored, but
you still have a full picture of the snapshot because the other files
are hardlinked in the right place!

This is genius, and turns out this is provided by rsync through the
`--link-dest` option. Linux Time Machine adds a nice, easy to use
frontend to it which is very appreciated.

Building off our work from above, we can simply replace the `rsync`
command by `timemachine`:

```sh
gocryptfs -reverse -ctlsock /path/to/ctlsock /path/to/directory /path/to/mount

timemachine "$@" /path/to/mount "$DESTINATION" 2>&1 \
    | gocryptfs-rsync-pretty /path/to/ctlsock /path/to/mount
```

This is possible because hard links are supported by Hetzner, and thanks
to native rsync support, they can be preserved along the way!

<div class="note">

**Note:** I haven't tested `gocryptfs-rsync-pretty` with the output of
`timemachine`, but because `timemachine` wraps rsync, it should work out
of the box, or require only basic tuning of the underlying rsync output.
Let me know if you try it!

</div>

## Wrapping up

Despite only writing this today, I've been using this system for *two
years* already! (Time flies omg.)

The commits I've added over time were mostly to refine the rsync output
parsing, so looks like the core of the script was pretty solid from the
get go.

That setup survived at least two macOS upgrades, and I've been using it
on my Linux machines as well.

So feel free to use [gocryptfs-rsync](https://github.com/valeriangalliat/gocryptfs-rsync)
for your own backups, or use it as an inspiration to build your own
backup system! Cheers. ✌️

<div class="note">

1. [Encrypted offsite backup system: storage 💾](offsite-backup-storage.md)
1. Encrypted offsite backup system: syncing 📲

</div>
