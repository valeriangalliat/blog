# Firebase functions: debugging upload error `EntityTooLarge`
April 7, 2023

So during a `firebase deploy`, you ran into the following error:

```
Upload Error: HTTP Error: 400
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>EntityTooLarge</Code>
  <Message>Your proposed upload is larger than the maximum object size specified in your Policy Document.</Message>
  <Details>Content-length exceeds upper bound on range</Details>
</Error>
```

What to do from there?

This happens because your functions source was too large: over 100 MB
for the compressed source, or 500 MB for the uncompressed source and its
dependencies, as documented in [resource limits](https://cloud.google.com/functions/quotas#resource_limits).

Now, there may be ways you can reduce that, particularly using the
[`functions.ignore`](https://firebase.google.com/docs/cli/#functions-ignored-files)
list in `firebase.json` to ignore unnecessary (and possibly heavy)
files.

But it's not necessarily easy to write this list. The ignore patterns
are not well documented and can be quirky, enough that I [wrote another
blog post](firebase-functions-ignore.md) to demistify them. You can
easily end up in a loop of trial and error until you get the patterns
right, and some guesswork to find what files and directories can be
exceeding the size limit.

Firebase doesn't give us any way to inspect the functions packed source
to diagnose what failed to be ignored and is taking all that space.
Luckily, it's pretty easy to hack that around.

## Catching the temporary ZIP as it's generated

By looking at the source code of Firebase, we can see they
[use the `tmp` module](https://github.com/firebase/firebase-tools/blob/b0798fb1fe96499e1404d6fea6c181735e3a8f11/src/deploy/functions/prepareFunctionsUpload.ts#L63)
in order to generate the ZIP archive for Cloud Functions.

Let's see where `tmp` creates the files. On macOS, that's what I got:

```console
$ node -p "require('tmp').fileSync({ prefix: 'firebase-functions-', postfix: '.zip' }).name"
/var/folders/8g/6ch743rn6p990xxbsd757yfm0000gn/T/firebase-functions--35549-LDS1bLg78ajZ.zip
```

Sweet. So we can look for `firebase-functions-*.zip` inside
`/var/folders` to find the archive that's being uploaded!

Now, we just have to watch for those logs during the deploy:

```
i  functions: preparing . directory for uploading...
i  functions: packaged /path/to/repo (123.45 MB) for uploading
```

This tells us that the archive is ready. Be quick (or cancel the
deploy), because Firebase will clean it up pretty fast!

You can use a command like this to show the creation time of the files
that matched. Then just pick the most recent one.

```sh
find /var/folders -name 'firebase-functions-*.zip' -ls 2> /dev/null
```

The `2> /dev/null` part is to ignore the error stream since a lot of
stuff in `/var/folders` will get permission denied errors.

Now you have the source ZIP file, you can uncompress it and see what
failed to be ignored, or what's left in there that is too heavy and
needs to be added to the ignore list!

<div class="note">

**Note:** while trying to find leftover files that are too large,
[ncdu](https://dev.yorhel.nl/ncdu) is really useful. It's a small CLI
tool that allows to browse a directory, showing the largest files and
folders on top, with their size. I can only highly recommend it when you
need to identify large files.

You may install it with one of the following commands, depending on your
system:

```sh
apt install ncdu
pacman -S ncdu
brew install ncdu
```

</div>

## An even better solution

While this first solution worked, I didn't like having to catch the ZIP
files fast before Firebase removes it. I kept digging through the code,
and I found a way to call the Firebase archiving code directly,
instead of running `firebasde deploy`!

```js
require('firebase-tools/lib/deploy/functions/prepareFunctionsUpload').prepareFunctionsUpload(
  process.cwd(),
  require('./firebase.json').functions
).then(x => console.log(x.pathToSource))
```

Running this from our Firebase root directory (the one where
`firebase.json` is in), it will generate the ZIP archive and output its
temporary path!

You can then decompress it and analyze it as we just saw.
