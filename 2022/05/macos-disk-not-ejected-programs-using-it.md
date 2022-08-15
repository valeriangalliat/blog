# The disk wasn't ejected because one or more programs may be using it
To eject the disk immediately, click the force eject button  
May 5, 2022

If you run macOS, you might have run in the following error message when
trying to eject a removable device:

<figure class="center">
  <img alt="The disk wasn't ejected because one or more programs may be using it" src="../../img/2022/05/macos-disk-eject.png">
</figure>

In some cases, even waiting a few minutes doesn't solve the problem.
Often, it happens after deleting files from the device just before
ejecting, and Quick Look is often the culprit. Let's see.

*Inspired by [this post](https://mycyberuniverse.com/macos/how-fix-volume-cant-be-ejected-because-currently-use-user.html)
and [this post](https://mycyberuniverse.com/macos/how-fix-volume-cant-be-ejected-because-currently-use.html).*

## Investigating

To know what program is currently using the volume you're trying to
eject, you can use the [`lsof(8)`](https://linux.die.net/man/8/lsof)
command. In my case the volume is `/Volumes/LUMIX`:

```console
 lsof +c0 /Volumes/LUMIX
COMMAND            PID USER   FD   TYPE DEVICE   SIZE/OFF   NODE NAME
QuickLookUIService 611  val    3r   REG   1,31 2970637594     51 /Volumes/LUMIX/.Trashes/501/P2770021.MP4
```

<div class="note">

**Note:** the `+c0` option here is to display the full command string.
By default, it only shows 9 characters.

</div>

You can see that `QuickLookUIService` is still doing something with the
file `P2770021.MP4` that I deleted... and it's probably stuck and
confused because the file is not there anymore.

## Killing

To fix that, we can kill the `QuickLookUIService` process (or whatever
process was blocking in your case).

<div class="note">

**Note:** in the case of `QuickLookUIService`, it's safe to kill, but if
you're dealing with a different program preventing you to eject your
drive, it's up to your own judgment whether it's a good idea or not to
kill it!

</div>

There's essentially two methods we'll talk about: soft kill, which would
be`pkill QuickLookUIService` and hard kill, with `pkill -9
QuickLookUIService`.

In the case of this bug, it looks like we need to resort to hard kill,
as a soft kill doesn't terminate the hanging process:

```sh
pkill -9 QuickLookUIService
```

Now you should be able to eject your device!

## Restarting Quick Look

Quick Look is the macOS service responsible for computing file previews
for various UI components. After we killed it, it might or might not
restart by itself, so if you notice that new file previews and
thumbnails don't appear anymore in your Finder, you can restart Quick
Look with the following command:

```sh
qlmanage -r
```

It won't hurt to run it either way after killing the process and
ejecting the drive.
