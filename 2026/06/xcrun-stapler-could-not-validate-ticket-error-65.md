# `xcrun stapler` could not validate ticket, error 65
June 4, 2026

When publishing a macOS app, you need to go through code signing and
"notarization" of the app and DMG file to avoid "unverified developer"
warnings.

This is well integrated in Xcode, and frameworks like Electron and Tauri
also have direct support for this (see [How to sign and notarize an Electron app](https://www.codejam.info/2024/05/sign-notarize-electron-app-macos.html) and [Tauri macOS code signing](https://tauri.app/distribute/sign/macos/)).

But the app I'm building, [TZBar](https://evetools.app/en/tzbar), is
native (no Electron or Tauri), but small enough that I didn't want to
bother with Xcode at all.  Just plain `swift build`. This also meant
doing the code signing and notarizaiton [from the CLI](https://github.com/EveToolsHQ/TZBar/blob/efef3f52bfecf226ece9477a6f43a4639acf5d19/Makefile#L41-L65),
which luckily is well documented in [this Stack Overflow answer](https://stackoverflow.com/a/64733472).

That's how I learnt about the stapling process. While notarization means
uploading your app for Apple to scan and approve it, that "verification
ticket" can be "stapled" onto the app file itself so that the
verification can be done offline on users devices.

This is optional since when connected to the internet, the system will
just check the app's signature for notarization status online, and users
who just downloaded your app are typically connected to the internet. 😂

Anyway, it's done with this command:

```sh
xcrun stapler staple App.dmg
```

## Error 65

However the above command failed with:

```console
$ xcrun stapler staple App.dmg
Processing: ~/App.dmg
Could not validate ticket for ~/App.dmg
The staple and validate action failed! Error 65.
```

Sounds like this error happens for many unrelated reasons with no way to
know exactly what's wrong...

In my case, the Apple root certificates were set to "always trust"
instead of "system defaults" (probably from attempts to troubleshoot
signing issues of past apps I worked on).

This is apparently a problem, and the stapler will fail if the
certificates not set to "system defaults".

So go in **Keychain Access > System Roots**, and for **Apple Root**,
**G2**, **G3** and **WWDR**, make sure to select **System Defaults** if
it's not the case already.

If this doesn't solve it for you, [this GitHub answer](https://github.com/electron/notarize/issues/120#issuecomment-3215070977)
describes a few more steps that you can use to troubleshoot "health" of
the signing setup.

```console
$ xcrun stapler staple App.dmg
The staple and validate action worked!
```

Better!
