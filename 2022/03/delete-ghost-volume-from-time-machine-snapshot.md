# Delete ghost volume from Time Machine snapshot
March 8, 2022

This is the blog post version of
[my answer to this Stack Exchange question](https://apple.stackexchange.com/a/438077/452681).

## Why I needed to remove a volume backup

Recently, the external hard drive where I kept some of my video footage
[died](https://twitter.com/valeriangalliat/status/1491106467310489604).

But as I'm a good citizen and I have a backup (and restore) strategy,
all the data was also mirrored on my Time Machine drive! Yay!

So I proceeded to restore it to another internal drive where I had
enough room.

This could be the end of the story. But Time Machine kept persisting the
backups of that old external drive in all further snapshots.

This is a nice feature, for example if your external drive is unplugged
for a few days, you don't want Time Machine to remove it from your
backup history. But in my case, that drive was actually *dead* and now I
restored it, I didn't need this redundant "phantom" backup.

It turns out you can't easily delete arbitrary directories in a Time
Machine backup, and the `tmutil delete` command [doesn't let you](https://apple.stackexchange.com/q/333767/452681)
delete granular parts of a backup. It's either [a whole snapshot, machine directory or backup store](https://apple.stackexchange.com/a/357114/452681).

Luckily, by messing around with the `tmutil` command, and because I
[already played a bit with it](../../2021/11/yearly-hackintosh-upgrade-macos-monterey-with-opencore.md#finalizing),
in the past I figured a way to hack it to remove a specific ghost volume
from a backup!

## The theory

Time Machine has in its state a directory `Video` (in my case) in the
backup snapshots, which it associates with `/Volumes/Video`, or more
specifically, the original disk UUID behind this mount point. Because
that disk is dead, this UUID is never to be seen again. But Time Machine
can't know that. From its perspective, it's just like this external
drive is unplugged, and it's a good thing that it doesn't remove it form
backups!

So, if we tell Time Machine that the `Video` backup directory is now
associated with *another* disk (that actually exists), it will
effectively put the new backup in it, instead of carrying over the
backup of the dead disk.

And even better, if we associate a disk that is *excluded* from Time
Machine backups, it will delete the `Video` directory altogether from
new snapshots!

## Removing the ghost backup directory

First, we need to identify a volume that's already excluded from Time
Machine. Go in the Time Machine preferences, and in <kbd>Options...</kbd>, see if
you have an excluded volume. It could be an internal drive that you
explicitly excluded from backups, or an external drive that you never
explicitly included in backups.

If you don't have any excluded disk (it needs to be a disk, not a
subdirectory), you can plug a random USB stick or SD card or something
similar.

Let's pretend that your excluded disk is a USB stick, in `/Volumes/USB`,
and I'm trying to get rid of the `Video` directory inside my future backup
snapshots:

```sh
sudo tmutil associatedisk /Volumes/USB "/Volumes/{TimeMachineDrive}/Backups.backupdb/{MachineDirectory}/Latest/Video"
```

Now Time Machine thinks that the `Video` directory is associated with
`/Volumes/USB`, which is excluded, and so, it will exclude it from
future backups!

The history of the dead `Video` drive will still be present in the older
snapshots, but Time Machine will be able to reclaim the space from it in
the future because that "ghost" volume is not being referenced anymore
in the newer backups.
