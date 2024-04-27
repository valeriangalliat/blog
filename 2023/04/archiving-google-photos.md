# Archiving Google Photos offline to free up space
April 2, 2023

<div class="note">

**Note:** updated on December 30, 2023.

</div>

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
directory (but copying from Finder also works):

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

### 3. Double check I'm not missing anything

If you have photos that are _only_ on Google Photos but not stored on
your phone storage, the previous step didn't archive them. You need to
make sure to download them from Google Photos in the first place.

Because there's no way from Google Photos to find all photos that are
not locally saved to a specific device (other than going through them
one by one), that's where I [use the Google Photos API](#bonus-script-to-list-all-your-google-photos-using-the-api)
to make sure I'm not missing anything.

This will get technical, so if you don't care about this part, feel free
to skip to [the next step](#4-delete-everything-from-google-photos).

First, we need a Google OAuth token with access to Google Photos. We'll
reuse [my script from this other article](../../2021/02/google-oauth-from-cli-application.md#update-local-server-redirect)
for this, just replacing the scope with `https://www.googleapis.com/auth/photoslibrary.readonly`.
Put it in a `token.mjs` file and run it with `node token.mjs`, this will
go through the OAuth process and after you complete the authentication,
will log the access token that we'll use in the next script.

The following script can go in `photos.mjs` and be run with `node
photos.mjs`, reusing the token from the previous step.

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
`pages.json` file.

From there, I like to use [jq](https://jqlang.github.io/jq/) to extract
the filenames:

```sh
cat pages.json | jq -r '.[].mediaItems[].filename' > filenames
```

Then I use the following script to check that each filename is indeed
present in my archive:

```sh
cat filenames | while read file; do find /Volumes/Archive/Phone -name "$file" | grep -q . || echo "Missing $file"; done
```

This will print the name of every file that's on Google Photos and not
part of the backup. If any, you can find more details in `pages.json`
including a Google Photos link to find out what photo it is that needs
to be downloaded.

Once everything is confirmed backed up, we can continue.

### 4. Delete everything from Google Photos

Not necessarily everything, but well, everything you want to delete to
free up space.

You can do it from your phone, or from Google Photos on your computer,
or on the web, although in my experience, **I would recommend doing it
from the phone**.

When deleting _a lot_ of photos from the web version, this tends to
confuse the phone's syncing algorithm and I've ended up with a bunch of
photos being re-uploaded and somehow duplicated and it was kind of a
mess to clean up.

It tends to _just work_ when deleting from the phone. The only downside
is that the app doesn't make it easy to select a whole bunch of photos
at once, I just have to hold my thumb for a minute with the super slow
scroll until everything is selected.

<div class="note">

**Note:** at that point I like to take note of how many photos I
deleted, so I can double check the number in a later step.

</div>

### 5. Sync phone to computer again

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

### 6. Remove the overlap

To avoid that duplication, we can remove all files from the archive that
are still in the Syncthing directory. That is, all the photos/videos we
kept, as well as all the files in the phone storage that are not managed
by Google Photos.

```sh
(cd /Volumes/Syncthing/Phone && find . -type f) | while read f; do rm -v "/Volumes/Archive/Phone/$f"; done
```

Now, the archive directory only contains what we removed from Google
Photos (and from the phone), but there's no duplicates!

Bonus: we can remove all empty directories with:

```sh
find /Volumes/Archive/Phone -type d -empty -delete
```

<div class="note">

**Note:** sometimes this is not enough, e.g. WhatsApp has some
`.nomedia` files in empty directories that prevent them to be cleaned
up, and if you browsed with Finder you may have some `.DS_Store` too,
so:

```sh
find . -type f -name .nomedia -delete
find . -type f -name .DS_Store -delete
find /Volumes/Archive/Phone -type d -empty -delete
```

</div>

At that point, I also count the number of files from the backup and
makes sure it matches the number of files I deleted from Google Photos
earlier:

```sh
find /Volumes/Archive/Phone -type f | grep -v DS_Store | wc -l
```

### 7. Profit!

You can now enjoy all the space you freed up by archiving your photos
and videos away from Google Photos!

Repeat every time you're close to running out of storage. 😉

## What about motion photos?

Google's motion photos are the equivalent of Apple's live photos: a
photo that also contains a short video of the "moment" it was captured.

What happens to those during our archival process? Well, it's
complicated.

In short, don't worry, they're backed up and the little video that goes
with the motion photo is not going to be lost, but you won't be able to
watch the "live" part anymore, you'll only see the still picture.

The reason is that Google stores the MP4 video part at the end of the JPEG
file. This doesn't prevent displaying the image, but there's currently
no photo viewer other than Google Photos that knows to extract that MP4
section following the JPEG data, and display it properly.

So if you want to see the live part of a motion photo, you'll have to
re-import it to Google Photos.

Alternatively, you can extract the MP4 part of the motion photo to a
different file, which you can do by using a script like
[detailed in this post](https://mjanja.ch/2021/10/stripping-embedded-mp4s-out-of-android-12-motion-photos/).

<div class="note">

**Note:** if you use the script from the above post on macOS, you'll
need GNU `grep` in order find the byte offset of the MP4 header.

This means you'll have to `brew install coreutils` and replace `grep` by
`ggrep` in the script for it to work.

</div>

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
