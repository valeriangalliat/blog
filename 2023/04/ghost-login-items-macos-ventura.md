# Getting rid of ghost login items in macOS Ventura
April 2, 2023

Let's say you uninstalled an app on macOS Ventura, and you see some
leftovers from that app in **system settings**, **general**, **login
items**:

<figure class="center">
  <img srcset="../../img/2023/04/login-items-dirty.png 2x">
</figure>

Here's a few tips to solve it.

## Reboot

More often than not, it seems that after removing login items and/or the
app behind then, it takes a reboot of macOS Ventura until they're
"garbage collected" from system settings. That's the first thing you
should try.

## Check your trash!

If you moved the app to the trash but didn't empty the trash, its login
items are still referenced from the trash! They won't go away until you
permanently delete the app (and reboot).

## Check leftover launch agents and daemons

There's a few places macOS looks for "login items" on your filesystem:

* `/Library/LaunchAgents`
* `/Library/LaunchDaemons`
* `~/Library/LaunchAgents`
* `~/Library/LaunchDaemons`

Also, same thing under `/System/Library` but that's for macOS own login
items and you have no control over them.

Check the 4 directories above for leftover `plist` files from the
applications you removed. You may need to do some cleanup. After that,
don't forget to reboot!

## Inspect `BackgroundItems-v4.btm`

As shown in [this Reddit post](https://www.reddit.com/r/MacOSBeta/comments/w2we6q/cleaning_up_venturas_login_items/),
the list of login items in Ventura is managed in `/private/var/db/com.apple.backgroundtaskmanagement`. In my case, in a `BackgroundItems-v8.btm` file.

```console
$ file /private/var/db/com.apple.backgroundtaskmanagement/BackgroundItems-v8.btm
Apple binary property list
```

As `file(1)` tells us, this is a binary property list file. We can
inspect it with `plutil`:

```sh
plutil -p /private/var/db/com.apple.backgroundtaskmanagement/BackgroundItems-v8.btm
```

This will print the whole structure behind that file. From inspecting
its output, you should be able to determine what's behind the "ghost items"
that you identified in the system settings. More often than not, it'll
point to some file or app that you forgot to get rid of, and cleaning
that up will fix your problem (again, after a reboot).
