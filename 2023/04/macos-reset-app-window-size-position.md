# macOS reset app window to default size and position
April 20, 2023

Maybe it's because I'm a bit of a perfectionist, but I sometimes like to
reset an app's window to its default size and position. It looks like
I'm [definitely](https://superuser.com/q/1485027)
[not](https://apple.stackexchange.com/q/195479/452681)
[the](https://discussions.apple.com/thread/250618907)
[only one](https://www.reddit.com/r/MacOS/comments/hbbg7z/reset_default_window_positionsize_in_catalina/).

The summary of the above links is that the window information is usually
stored in `~/Library/Preferences` or `~/Library/Saved Application
State`, and you can get away with removing the matching application
preferences files in one of those locations, or carefully editing it to
remove _just_ the window position if that's what you want.

This is generally true, but not all the time (as shown in the
[case of the Mail app](https://apple.stackexchange.com/a/195494/452681)).

This means this solution isn't perfect. Did I say I was a perfectionist?

## Finding _every_ window position preferences

From the files we could find from the earlier solution, we can see that
the window position is either in a `NSWindowFrame` key, or a key that
starts with `NSWindow Frame`, e.g. for Activity Monitor and Finder:

```console
$ plutil -p ~/Library/Preferences/com.apple.ActivityMonitor.plist | grep NSWindow | grep Frame
  "NSWindow Frame main window" => "161 208 960 640 0 0 1728 1079 "

$ plutil -p ~/Library/Saved\ Application\ State/com.apple.finder.savedState/windows.plist | grep NSWindow | grep Frame
    "NSWindowCloseButtonFrame" => "{{19, 876}, {14, 16}}"
    "NSWindowFrame" => "42 1193 1652 910 -87 1117 1920 1055 "
    "NSWindowMiniaturizeButtonFrame" => "{{39, 876}, {14, 16}}"
    "NSWindowZoomButtonFrame" => "{{59, 876}, {14, 16}}"
```

Moreover, this setting is always stored in a `plist` file, the property
list file that macOS apps store their preferences in.

So we can try and find for those keys in all `plist` files in the whole
`~/Library`!

```sh
find ~/Library -type f -name '*.plist' -exec grep -E 'NSWindow ?Frame' {} +
```

<div class="note">

**Note:** `-exec command {} +` will execute the `command`, replacing `{}
+` by all the files that `find` found! See the
[`find(1)`](https://linux.die.net/man/1/find) man page for more details.

</div>

Thanks to that, we uncover more locations! Here's the exhaustive list of
where I found those window position preferences:

* `~/Library/Preferences/{appId}.plist`
* `~/Library/Saved Application State/{appId}.savedState/windows.plist`
* `~/Library/Containers/{appId}/Data/Library/Preferences/{appId}.plist`
* `~/Library/Containers/{appId}/Data/Library/Saved Application State/{appId}.savedState/windows.plist`

Where `appId` is the application ID, aka its bundle identifier, e.g.
`com.apple.mail` for Apple Mail.

## Resetting the window position

Now you were able to locate the preferences file for your app's window
location, you can reset it! There's a few ways.

For the ones in `Prefererences`, this is typically managed (and cached)
by the `defaults` command. The cached part is important: while you can
manually edit or remove those files, your changes are more likely to be
ignored until you reboot. To avoid that, use
[`defaults(1)`](https://www.unix.com/man-page/osx/1/defaults/) to edit
them.

For Activity Monitor, that would be:

```sh
defaults delete ~/Library/Preferences/com.apple.ActivityMonitor.plist 'NSWindow Frame main window'
```

Which is equivalent to:

```sh
defaults delete com.apple.ActivityMonitor 'NSWindow Frame main window'
```

<div class="note">

**Note:** this works even for containerized apps like Apple Mail:

```sh
defaults delete com.apple.mail
```

Because no key was passed, it'll delete all the preferences. But either
way, it'll know to target
`~/Library/Containers/com.apple.mail/Data/Library/Preferences/com.apple.mail.plist`.

</div>

As for the `Saved Application State` files, they don't seem to be
cached, and they're definitely not editable with the `defaults` command,
so feel free to remove them, or edit them with your favorite `plist`
editor!
