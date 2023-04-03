# Archiving Google Photos offline to free up space
April 2, 2023

If you backup your phone photos to Google Photos automatically, and you
don't pay for some kind of Google One subscription, you'll run sooner or
later into the 15 GB storage limit of your Google account.

15 GB is not a lot, especially when you consider than my Pixel 6a takes
pictures that are easily 3 to 5 MB each. 😬

To be fair, if you want convenience and you value your time, Google
One's $20/year for 100 GB is a pretty damn good deal. Same goes for the
higher options with more storage if you need.

But if you don't like recurring bills like me, and you find it overkill
to keep that many old photos in the cloud, read on.

## My protocol for archiving photos away from Google

In order to save space, I'll periodically archive my old photos outside
of Google Photos.

This protocol is designed to archive photos _from the phone_ that are
_backed up_ to Google Photos, but preserving the phone's original
arborescence. Google Photos doesn't have the path information, only the
filename, so backing up _from Google Photos_ directly would not work for
this use case.

The downside is that this doesn't cover the case where you have photos
in Google Photos that are _not_ on your phone.

Also it's designed for a single phone backing up to a Google Photos
account that's used _solely_ for that device. Multiple devices sharing
the same Google Photos is not supported.

With that said, here's how I do it.

### 1. Sync phone to computer

First, I use [Syncthing](https://syncthing.net/) to sync the contents of
my phone to a hard drive connected to my computer.

I configure Syncthing as "send only" on my phone, and "receive only" on
my computer, and I configure it to sync the root directory of my phone
(which can be tricky, [but possible](syncthing-root-directory.md)).

**After the sync is complete, I turn off Syncthing from my computer, to
make sure no incremental updates will happen during the archive
process.**

### 2. Copy synced folder to archive

For this example, let's assume I synced my phone to a
`/Volumes/Syncthing/Phone` directory, and I want to archive my old
photos in `/Volumes/Archive/Phone`.

I'll run the following command to copy the phone contents to my archive
directory:

```sh
cp -a /Volumes/Syncthing/Phone/ /Volumes/Archive/Phone/
```

<div class="note">

**Note:** the reason I copy the whole phone contents is because I want
to catch _all_ photos and videos that are backed up to Google Photos.
Typically, apps like Messenger, Whats App, Signal, etc. all store photos
in different directories, so syncing only `DCIM/Camera` would not be
enough.

</div>

If the target directory already exists, this will append new files to it
(and overwrite them if a file already exists there)!

Also if the directory already exists, the trailing slashes are
important.

<div class="note">

**Note:** if both directories are on the same filesystem, and you're not
appending to an existing archive, you may use `mv` instead, but then
make sure to recreate the Syncthing directory and put back its
`.stfolder` (required for Syncthing to recognize it) and `.stignore` if
you have one!

</div>

### 3. Delete everything from Google Photos

Not necessarily everything, but well, everything you want to delete to
free up space.

You can do it from your phone, or from Google Photos on your computer,
or on the web.

<div class="note">

**Note:** be careful! If you have photos that are _only_ on Google
Photos but not stored on your phone storage, the previous step didn't
archive them. You need to make sure to download them from Google Photos
in the first place. Doing that in an automated way is not covered in
this post.

</div>

As an abundance of caution, you may want to double check that the number
of photos/videos you have on Google Photos matches exactly with the
number of photos/videos you have on your phone before doing that.

If there's any mismatch, try to find where the difference it to make
sure you're not accidentally losing any photo.

Alternatively, you can [use the Google Photos API](#bonus-script-to-list-all-your-google-photos-using-the-api)
to list all the filenames on Google Photos, and ensure you have a match
in your archive prior to deleting. Otherwise, you'll know the names of
the missing ones that you have to download.

<div class="note">

**Note:** if you deleted the photos from the web or desktop app, make
sure to wait that the deletion is propagated to your phone before you
continue!

</div>

### 4. Sync phone to computer again

Again with Syncthing in my case, I do a sync following the deletion.

<div class="note">

**Note:** you may want to exclude `.trashed-*` files in your
`.stignore`, otherwise the photos you deleted will still be synced while
they're in the trash.

</div>

Now in our example, `/Volumes/Syncthing/Phone` contains just the
photos we decided to keep around in Google Photos, while
`/Volumes/Archive/Phone` contains _all_ the photos (also including the
ones we kept around).

On top of that, both directories contains _all other files_ from the
phone, that are not managed by Google Photos.

<div class="note">

**Note:** this process is not very efficient if you have a lot of files
that are not photos and videos, e.g. music and downloads. You may want
to ignore those directories in the earlier steps to avoid copying them
around unnecessarily!

</div>

### 5. Remove the overlap

To avoid that duplication, we can remove all files from the archive that
are still in the Syncthing directory. That is, all the photos/videos we
kept, as well as all the files in the phone storage that are not managed
by Google Photos.

```sh
(cd /Volumes/Syncthing/Phone && find . -type f) | while read f; do rm -v "/Volumes/Archive/Phone/$f"; done
```

Now, the archive directory only contains what we removed from Google
Photos (and from the phone), but there's no duplicates!

### 6. Profit!

You can now enjoy all the space you freed up by archiving your photos
and videos away from Google Photos!

Repeat every time you're close to running out of storage. 😉

## About the Google Photos app "home page"

I think there may be some display bugs when deleting _a lot_ of photos
from Google Photos at once. For some reason the main photos list of my
Google Photos still shows a few of the photos I deleted! They're in a
weird state where the UI offers me download them to my device (as if
they're not on the device already), but also shows me a local path to
the file as if it was on device (but the photo is not actually there).

I'm thinking this issue will be gone when the photos in the trash are
permanently deleted, so this doesn't concern me too much. What's visible
in Google Photos on the web (and in their API) is consistent with the
state I want, and what's on my phone's raw storage is consistent too.

## Bonus: script to list all your Google Photos using the API

In the previous section, we saw it can be useful to list all the photos
from Google Photos (not necessarily on any of your devices) prior to
running the archiving process, to make sure you can catch the ones that
are not backed up anywhere.

You can put this script in `photos.mjs` and run as `node photos.mjs`.
You'll need to put a Google OAuth access token with access to your
Google Photos for this to work.

If you want to generate one from the CLI, check out my
[article on the subject](../../2021/02/google-oauth-from-cli-application.md#update-local-server-redirect).

```js
import fs from 'node:fs/promises'

const accessToken = 'YOUR_ACCESS_TOKEN'

let pageToken = ''
let pages = []

do {
  const url = 'https://photoslibrary.googleapis.com/v1/mediaItems?pageSize=100&pageToken=' + encodeURIComponent(pageToken)

  console.log(url)

  const response = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${accessToken}`
    }
  })

  const json = await response.json()

  pages.push(json)

  pageToken = json.nextPageToken
} while (pageToken)

await fs.writeFile('pages.json', JSON.stringify(pages, null, 2))
```

This will fetch all pages from the Google Photos API and dump them in a
`pages.json` file. You can then iterate through it to do whatever
operations you need to, e.g. making sure you don't leave any photo
around before deleting them from Google.

## Conclusion

Archiving photos away from Google Photos is not trivial, but possible.

If you care about not losing any of your photos, I recommend double
checking at every step that you're not accidentally forgetting any file.

When done well, this allows to periodically free up some space from your
Google account without actually having to get rid of your photos and
videos! They'll still be available on your archive hard drive if you
want to. Your old photos are not as handy as if they were in the cloud,
but you know you can access them if needed.

Overall, you're probably better off just paying Google to increase your
storage, but if you're really motivated, I hope you can find inspiration
in the process I described in this post.
