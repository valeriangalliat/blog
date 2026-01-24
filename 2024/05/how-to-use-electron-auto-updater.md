---
tweet: https://x.com/valeriangalliat/status/1790906278086386079
---

# How to use Electron auto updater ⚛️
May 15, 2024

I'm [writing an Electron app for the first time](https://www.arcade.software/download),
and I was wondering how to make it auto update. Turns out it's
relatively easy, but I found a ton of conflicting documentations about
it and was quite confused for a while, which is why I'm writing this
post.

In this post, I'm gonna focus on a macOS app. I'm not sure how much of
this applies to Windows. I'll update this post when we eventually port
the app to Windows!

## How does the auto updater works?

On macOS, Electron auto updater uses the [Squirrel.Mac](https://github.com/Squirrel/Squirrel.Mac)
framework, a "Cocoa framework for updating macOS apps".

So ultimately, when it comes to the distribution of auto updates, your
source of truth is gonna be Squirrel.

Electron has a [built-in `autoUpdater` API](https://www.electronjs.org/docs/latest/api/auto-updater)
that lets you [`setFeedURL`](https://www.electronjs.org/docs/latest/api/auto-updater#autoupdatersetfeedurloptions),
[`checkForUpdates`](https://www.electronjs.org/docs/latest/api/auto-updater#autoupdatercheckforupdates),
and [`quitAndInstall`](https://www.electronjs.org/docs/latest/api/auto-updater#autoupdaterquitandinstall).

On boot, you configure the auto updater with a mysterious, undocumented
"feed URL", and then you check for updates periodically, and when an
update is found, you can prompt the user to install the update.

<div class="note">

**Note:** for auto updates to work, your releases must be
[signed](sign-notarize-electron-app-macos.md).

</div>

## What about `update-electron-app`?

If you read the [Electron reference on updating applications](https://www.electronjs.org/docs/latest/tutorial/updates),
they mention a [`update-electron-app`](https://github.com/electron/update-electron-app)
package, that identifies as "a drop-in module that adds auto updating
capabilities to Electron apps".

This module implements the logic described in the previous section for
you, so you just have to call one function on boot and let it deal with
periodic checking, and prompting the user to install the update. Cool.

However it's only meant to [work with Electron's public update service](https://github.com/electron/update-electron-app?tab=readme-ov-file#with-updateelectronjsorg),
or static file storage that [we'll talk about later](#static-updates-format)

The typical usage looks like this when using Electron's public update
service:

```js
const { updateElectronApp, UpdateSourceType } = require('update-electron-app')

updateElectronApp({
  updateSource: {
    type: UpdateSourceType.ElectronPublicUpdateService,
    repo: 'github-user/repo'
  }
})
```

## Using `update.electronjs.org`?

That public update service is hosted by Electron and serves the obscure
"feed URL" that we encountered earlier.

In order to use it, you need to point it to a public GitHub repository
where you publish [releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
of your app.

Their service can then respond to auto update requests by checking if
there's a newer release. The app binary is downloaded directly from
GitHub releases.

You can also [host your own update server](https://www.electronjs.org/docs/latest/tutorial/updates#step-1-deploying-an-update-server).
There's actually a few options you can chose from, and they all comply
to this undocumented feed format we still know nothing about.

When using the `autoUpdater` module, you can configure it like this:

```js
const { autoUpdater } = require('electron')

autoUpdater.setFeedURL({
  url: 'https://server/path/to/feed'
})
```

That URL seems arbitrary and typically contains the `process.platform`,
maybe `process.arch`, and your program's version.

As we saw before, a custom dynamic server won't work with
`update-electron-app` so you'll have to implement the logic yourself.
Luckily, [it's not very complicated](https://github.com/electron/update-electron-app/blob/515ab245a429a4790b9209f8d2073edddb980717/src/index.ts).

## What's behind this feed URL and format?

This format is actually [defined by the Squirrel framework](https://github.com/Squirrel/Squirrel.Mac?tab=readme-ov-file#update-requests).

In case of a dynamic server like in the previous section, the request is
as an arbitrary `GET` request to the URL you configured. It's important
for that URL to include the current app version because your server is
expected to respond based on whether or not a new version is available
for the given version.

In case no update is available, you [should return](https://github.com/Squirrel/Squirrel.Mac?tab=readme-ov-file#server-support)
a `204 No Content`.

If an update is available, you should return a `200 OK` with the
[following](https://github.com/Squirrel/Squirrel.Mac?tab=readme-ov-file#update-server-json-format)
JSON response:

```json
{
  "url": "https://server/path/to/release.zip",
  "name": "Optional Release Name",
  "notes": "Optional release notes",
  "pub_date": "2024-05-03T12:34:56Z"
}
```

Now this makes a bit more sense. You can easily make your own server
that implements this protocol. Actually, you can probably get away with
adding just another endpoint to your existing app. 😎 No need to depend
on a third-party service or to self-host and maintain another app. 😅

## Static updates format

What's a bit lesser known is that you don't even need a dynamic server
at all. You can implement auto updates with static files only. 🪶

There's hints of that in `update-electron-app` that has a
[static storage option](https://github.com/electron/update-electron-app/tree/main?tab=readme-ov-file#with-static-file-storage),
as well as Squirrel's docs that mention a [static JSON format](https://github.com/Squirrel/Squirrel.Mac?tab=readme-ov-file#update-file-json-format).

With `update-electron-app`, it would look like this:

```js
const { updateElectronApp, UpdateSourceType } = require('update-electron-app')

updateElectronApp({
  updateSource: {
    type: UpdateSourceType.StaticStorage,
    baseUrl: 'https://server/path/to/feed'
  }
})
```

<div class="note">

**Note:** when using `update-electron-app`, on macOS, it will
[append](https://github.com/electron/update-electron-app/blob/515ab245a429a4790b9209f8d2073edddb980717/src/index.ts#L121)
`/RELEASES.json` to the `baseUrl` URL that you give when in
`StaticStorage` mode, meaning in the above example, the final URL would
be `https://server/path/to/feed/RELEASES.json`.

There's no way to opt out of that, so if you're gonna use this module,
that's something to know when you create the layout of your static file
storage. Luckily the [automated way to provision static updates with Electron Forge](#auto-generating-the-static-update-files)
generates a `RELEASES.json` file by default so it should work out of the
box.

</div>

As for the native `autoUpdater`, you need to pass the
[little documented `serverType: 'json'`](https://www.electronjs.org/docs/latest/api/auto-updater#autoupdatersetfeedurloptions):

```js
const { autoUpdater } = require('electron')

autoUpdater.setFeedURL({
  url: 'https://server/path/to/feed.json',
  serverType: 'json'
})
```

In both cases, the feed URL typically contains `process.platofrm` and maybe `process.arch` again, but that seems to be really up to you.

It is supposed to respond with the following [schema](https://github.com/Squirrel/Squirrel.Mac?tab=readme-ov-file#update-file-json-format):

```json
{
  "currentRelease": "1.2.3",
  "releases": [
    {
      "version": "1.2.1",
      "updateTo": {
        "version": "1.2.1",
        "url": "https://server/path/to/1.2.1.zip",
        "name": "Optional Release Name",
        "notes": "Optional release notes",
        "pub_date": "2024-05-02T12:34:56Z"
      }
    },
    {
      "version": "1.2.3",
      "updateTo": {
        "version": "1.2.3",
        "url": "https://server/path/to/1.2.3.zip",
        "name": "Optional Release Name",
        "notes": "Optional release notes",
        "pub_date": "2024-05-03T12:34:56Z"
      }
    }
  ]
}
```

From this static response, Squirrel is able to determine whether it
needs to update, and where to fetch the update from.

Don't get confused by the `updateTo` naming. `releases` contains all the
releases of your software, and `updateTo` just contains some metadata
about that release, with the `url` being the only really important part.

I haven't tested this, but my guess is that all you really need is the
entry containing the `currentRelease`, e.g.:

```json
{
  "currentRelease": "1.2.3",
  "releases": [
    {
      "version": "1.2.3",
      "updateTo": {
        "version": "1.2.3",
        "url": "https://server/path/to/1.2.3.zip",
        "name": "Optional Release Name",
        "notes": "Optional release notes",
        "pub_date": "2024-05-03T12:34:56Z"
      }
    }
  ]
}
```

That should be enough for Squirrel to know there's an update available.
I'm not sure keeping the entire history of older releases adds any value.

## Auto generating the static update files

From the above section, you should have everything you need to manually
craft that updates feed and push it on your static file server with your
ZIP updates.

However, if you use [Electron Forge](https://www.electronforge.io/),
there's (again little documented) ways to generate this static structure
automatically!

`update-electron-app` [hints](https://github.com/electron/update-electron-app/tree/main?tab=readme-ov-file#requirements)
at [`@electron-forge/publisher-s3`](https://www.electronforge.io/config/publishers/s3),
but there's also [`@electron-forge/publisher-gcs`](https://www.electronforge.io/config/publishers/gcs),
allowing you to generate and upload that static update structure
respectively to AWS S3 or Google Cloud Storage.

They both work the same but the documentation of the S3 plugin is more
complete when it comes to [auto updating](https://www.electronforge.io/config/publishers/s3#auto-updating-from-s3).

You need not only to add the S3 or GCS publisher, but also configure
[`@electron-forge/maker-zip`](https://www.electronforge.io/config/makers/zip)
with the undocumented option `macUpdateManifestBaseUrl`.

During the "make" step, Electron will build the ZIP file for the
release, but with that option, it will also fetch your current static
"update feed", update the `currentRelease`, and add a new release entry
to the `releases` array, then output that updated `RELEASES.json` file
next to your ZIP files.

Then the S3 or GCS publisher will know to put that new update feed in
the right place in your bucket.

In `forge.config.js`, it looks like this:

```js
module.exports = {
  makers: [
    {
      name: '@electron-forge/maker-zip',
      config: arch => ({
        macUpdateManifestBaseUrl: `https://my-bucket.s3.amazonaws.com/custom/folder/darwin/${arch}`
      })
    }
  ],
  publishers: [
    {
      name: '@electron-forge/publisher-s3',
      config: {
        bucket: 'my-bucket',
        folder: 'custom/folder',
        public: true
      }
    }
    // {
    //   name: '@electron-forge/publisher-gcs',
    //   config: {
    //     bucket: 'my-bucket',
    //     folder: 'custom/folder',
    //     public: true
    //   }
    // }
  ]
}
```

In the case of `macUpdateManifestBaseUrl`, like for
`update-electron-app` in JSON mode, it will [automatically append](https://github.com/electron/forge/blob/ce2b03934ecf600525366a252e5bcb5491708a27/packages/maker/zip/src/MakerZIP.ts#L50)
`/RELEASES.json`, so in the above example, if `arch` is `arm64`, the
complete feed URL would be `https://my-bucket.s3.amazonaws.com/custom/folder/darwin/arm64/RELEASES.json`.

<div class="note">

**Note:** if you're doing universal builds by running `electron-forge
package --arch universal`, then the `arch` path component will be
`universal`, so in the above example, you would need to configure
`@electron-forge/maker-zip` like this:

```js
module.exports = {
  makers: [
    {
      name: '@electron-forge/maker-zip',
      config: () => ({
        macUpdateManifestBaseUrl: 'https://my-bucket.s3.amazonaws.com/custom/folder/darwin/universal'
      })
    }
  ]
}
```

</div>

## Conclusion

Will you use Electron's hosted update service? Or self-host an
open-source update server? Or instead implement your own dynamic
endpoint? Or maybe you'll just push static updates on S3, GCS, or your
own file server?

Regardless what you chose, you should now have all the elements you need
to implement auto updates in your Electron app on macOS the way that
suits you best! Cheers. ✌️
