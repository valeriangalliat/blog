---
tweet: https://twitter.com/valeriangalliat/status/1520527092219355138
---

# How to repackage a macOS `.pkg` installer for M1 support without Rosetta
April 30, 2022

To start with, some basis that you might already know:

* [Apple M1](https://en.wikipedia.org/wiki/Apple_M1) is an
  [ARM](https://en.wikipedia.org/wiki/ARM_architecture_family)-based
  CPU/GPU chip that ships with the latest Apple devices.
* [Rosetta](https://en.wikipedia.org/wiki/Rosetta_(software)) is a
  compatibility layer to translate [x86-64](https://en.wikipedia.org/wiki/X86-64)
  instructions to [ARM](https://en.wikipedia.org/wiki/ARM_architecture_family)
  instructions.

Until recently, x86-64 was happily ruling the market (and still is by
orders of magnitude, let's be honest), but since Apple dropped those
**LIT** 🔥 M1 chips that are basically killing the game in terms of
performance, things are changing.

This means that Mac software that was previously only targeting x86-64
now needs to ship **universal** binaries that support both x86-64 and
ARM if they want native performance.

But some vendors didn't catch up yet, and in those cases, you'll need to
rely on Rosetta for the while being to run those programs.

That being said, there's a thin chance that the program you install can
be repackaged in a way that can run natively, *without Rosetta*! In this
post we'll explore the Vanta agent, that claims it requires Rosetta, but
can easily be patched to run natively.

If you're in luck, you might be able to apply this knowledge to other
macOS installers.

## The case of the Vanta agent

As part of a security policy, my employer requires me to install an
agent program on my work laptop. This program is provided by a company
called Vanta.

I won't go in details about what is this program, but if you care, you
can check out my [detailed post on the topic](vanta-agent-m1-mac-without-rosetta.md)!

Anyways, they ship a `vanta.pkg` installer, that, when opened, claims to
be incompatible with the M1 architecture and requests to install
Rosetta. Not good.

## Why not install Rosetta?

I don't like installing garbage on my computer, and when I'm required to
install garbage on my computer, I don't like when on top of that the
garbage requires me to emulate another CPU architecture in order to run
it.

Also the challenge is fun, and a bit of software golfing here and there
is always enjoyable. I know it's common practice to golf on production
code these days in the industry, but I personally prefer to keep it
contained and isolated. Golfing is a personal pleasure and, like
masturbating, you shouldn't impose it on your colleagues.

## How is a macOS installer (`.pkg`) made?

Let's ask [`file(1)`](https://linux.die.net/man/1/file) for some
information.

```console
$ file vanta.pkg
vanta.pkg: xar archive compressed TOC: 4838, SHA-1 checksum
```

It looks like we're looking at a wild archive format, mostly
used on Darwin: [`xar(1)`](https://linux.die.net/man/1/xar).
Its arguments are pretty similar to [`tar(1)`](https://linux.die.net/man/1/tar).

Let's make a directory to extract the archive in:

```console
$ mkdir vanta
$ cd vanta
$ xar -xf ../vanta.pkg

$ ls -lh
total 8
-rw-r--r--  1 val  staff   1.1K 13 Apr 16:50 Distribution
drwx------  3 val  staff    96B 31 Dec  1969 Resources
drwx------  6 val  staff   192B 31 Dec  1969 vanta-raw.pkg
```

So we have a file, `Distribution` and two directories, `Resources` and
`vanta-raw.pkg`. Let's investigate.

```console
$ file Distribution
Distribution: XML 1.0 document text, ASCII text

$ vim Distribution
```

`Distribution` is a XML document, and when we look at it, we can see a
bunch of metadata for the macOS installer, where vendors can customize
background, logos, images and so on of the installer. In our case, it
also references the `vanta-raw.pkg` directory.

We'll see [later](#preventing-the-rosetta-prompt) that's also where we
can specify whether or not the package supports universal binaries!

But first, let's inspect that `vanta-raw.pkg`.

```console
$ cd vanta-raw.pkg

$ ls -lh
total 75880
-rw-r--r--  1 val  staff    42K  4 Jan 16:32 Bom
-rw-r--r--  1 val  staff   920B 13 Apr 16:50 PackageInfo
-rw-r--r--  1 val  staff    36M  4 Jan 16:32 Payload
-rw-r--r--  1 val  staff   1.2K  4 Jan 16:32 Scripts

$ file *
Bom:         Mac OS X bill of materials (BOM) file
PackageInfo: XML 1.0 document text, ASCII text
Payload:     gzip compressed data, from Unix, original size modulo 2^32 104344576
Scripts:     gzip compressed data, from Unix, original size modulo 2^32 3072
```

So, another XML, two gzipped files, and a BOM file that we won't care
about in the scope of this article.

The XML specifies "bundles" as well as `preinstall` and `postinstall`
scripts. Nothing really interesting in there.

Let's look at the gzipped data. This doesn't tell us anything other than
the fact that it's compressed with gzip... but let's ask `file` for its
opinion on the decompressed data.

```console
$ gunzip < Payload | file -
/dev/stdin: ASCII cpio archive (pre-SVR4 or odc)

$ gunzip < Scripts | file -
/dev/stdin: ASCII cpio archive (pre-SVR4 or odc)
```

Another archive format? And another obscure (at least to me) one on top
of that? Alright.

According to [`cpio(1)`](https://linux.die.net/man/1/cpio), we'll use
`cpio -i` to extract it (it knows to handle gzipped data so we don't
need to uncompress it first).

```console
$ mkdir PayloadOut
$ cd PayloadOut
$ cpio -i < ../Payload
203798 blocks

$ ls -lh
total 0
drwxr-xr-x  3 val  staff    96B 13 Apr 18:40 Library
drwxr-xr-x  3 val  staff    96B 13 Apr 18:40 etc
drwxr-xr-x  3 val  staff    96B 13 Apr 18:40 usr
```

Looks like this is the tree of files to be copied to the target system
during the installation. We can do the same thing with `Scripts`:

```console
$ mkdir ScriptsOut
$ cd ScriptsOut
$ cpio -i < ../Scripts
6 blocks

$ ls -lh
total 16
-rwxr-xr-x  1 val  staff   1.7K 13 Apr 18:40 postinstall
-rwxr-xr-x  1 val  staff   890B 13 Apr 18:40 preinstall
```

Those are two shell scripts that the installer runs respectively before
and after the installation.

We don't need to mess with those in the scope of this article, but in
general, I like to read those scripts prior to running any macOS `.pkg`
installer to get an idea of what it's going to do to my system.

## Finding the non-ARM binaries

Let's go back to the extracted `Payload` and find all the executables in
there to see which ones are not ARM-compatible.

```console
$ find . type f -perm +111 | xargs file
./usr/local/vanta/launcher:          Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64
- Mach-O 64-bit executable x86_64] [arm64]
./usr/local/vanta/launcher (for architecture x86_64):	Mach-O 64-bit executable x86_64
./usr/local/vanta/launcher (for architecture arm64):	Mach-O 64-bit executable arm64
./usr/local/vanta/osquery-vanta.ext: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64
- Mach-O 64-bit executable x86_64] [arm64]
./usr/local/vanta/osquery-vanta.ext (for architecture x86_64):	Mach-O 64-bit executable x86_64
./usr/local/vanta/osquery-vanta.ext (for architecture arm64):	Mach-O 64-bit executable arm64
./usr/local/vanta/autoupdater:       Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64
- Mach-O 64-bit executable x86_64] [arm64]
./usr/local/vanta/autoupdater (for architecture x86_64):	Mach-O 64-bit executable x86_64
./usr/local/vanta/autoupdater (for architecture arm64):	Mach-O 64-bit executable arm64
./usr/local/vanta/vanta-cli:         Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64
- Mach-O 64-bit executable x86_64] [arm64]
./usr/local/vanta/vanta-cli (for architecture x86_64):	Mach-O 64-bit executable x86_64
./usr/local/vanta/vanta-cli (for architecture arm64):	Mach-O 64-bit executable arm64
./usr/local/vanta/metalauncher:      Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64
- Mach-O 64-bit executable x86_64] [arm64]
./usr/local/vanta/metalauncher (for architecture x86_64):	Mach-O 64-bit executable x86_64
./usr/local/vanta/metalauncher (for architecture arm64):	Mach-O 64-bit executable arm64
./usr/local/vanta/osqueryd:          Mach-O 64-bit executable x86_64
```

<div class="note">

**Note:** in GNU `find`, this would be `find . -type f -executable` but
BSD `find` doesn't support `-executable`. Instead we can pass `-perm`
with an expression for matching the permission bits, where `+` means
we're passing a bitmask where at least one of the bits must match, and
`111` is the bitmask to match executable permissions (for owner, group
and others).

See [this thread](https://stackoverflow.com/a/4458361) for details.

</div>

By scanning this output we see that `usr/local/vanta/osqueryd` isn't
compatible with ARM. We can sort through this output to confirm we
didn't miss anything (by printing only the files where `file(1)` didn't
give the string `universal`):

```console
$ for file in $(find . -type f -perm +111 | grep -v '\.app'); do file "$file" | grep -q universal || echo "$file"; done
./usr/local/vanta/osqueryd
```

So we identified our culprit.

If this binary wasn't essential to the program (or what we specifically
want to do with it), we could just ignore it and jump to the [last step](#preventing-the-rosetta-prompt)
to prevent the installer from prompting to install Rosetta.

## Replacing the binary

Because in our case it's actually an essential binary, we need to
replace it with an ARM-compatible version. This is not always going to
be possible, in which case you might have to resort to Rosetta (or
deciding to not install this package after all).

For this specific program, we're in luck because
[osquery](https://github.com/osquery/osquery) is actually an
open source program!

This means that even if they don't provide an ARM version, hopefully
with little work we can compile from source for ARM and use that for our
package.

But for us it's even better, because they released [version 5.2.2](https://github.com/osquery/osquery/releases/tag/5.2.2)
a few months ago with Apple silicon support. Dope!

So we can just fetch [the `osqueryd` binary from this release](https://github.com/osquery/osquery/releases/download/5.2.2/osqueryd-macos-bare-5.2.2.tar.gz)
and replace the one from the original Vanta package.

In my case I [did a few](vanta-agent-m1-mac-without-rosetta.md#installing-and-running-vanta-without-root-privilege)
[other tweaks](vanta-agent-m1-mac-without-rosetta.md#spying-on-the-spyware-and-monitoring-its-network-traffic)
because I didn't want to give this program `root` privileges and I also
wanted to monitor its HTTPS traffic, but that's off-topic for this
article.

## Preventing the Rosetta prompt

Or in other words, marking the package as ARM-compatible.

If we were to [repackage the installer](#repackaging-the-installer)
right now, even though all the binaries in the payload are
ARM-compatible, we would still be greeted by a prompt to install Rosetta
when running it!

We can find the solution as part of [this answer](https://stackoverflow.com/a/11487658)
(the "Apple silicon" part). By adding the following line in the
`Distribution` XML file inside our package, we claim that the installer
supports ARM64 natively and hence doesn't need Rosetta:

```xml
<options hostArchitectures="arm64,x86_64" />
```

It can be added anywhere inside the `installer-gui-script` node.

## Repackaging the installer

Now we made sure all the binaries we needed are compatible with ARM,
and the `Distribution` file reflects that, we're ready to repackage the
installer!

This is done in two steps.

1. Recreate the `Payload` cpio archive from our updated content.
1. Recreate the `.pkg` archive containing the whole structure.

All the necessary instructions are in [this thread](https://stackoverflow.com/questions/11298855/how-to-unpack-and-pack-pkg-file)
but I'll detail the specific ones I used below.

### The payload

For the `Payload`, that we extracted and updated in a temporary
`PayloadOut` directory next to it, we'll run the following command from
the `PayloadOut` directory:

```console
$ find . | cpio -oz --owner 0:80 > ../Payload
203798 blocks
```

Here, `cpio -o` archives the file list from `stdin` and outputs the
archive in `stdout`. `-z` was added for built-in gzip compression (could
also be achieved by piping the output to `gzip -c`). `--owner 0:80` is
used to archive the files with `root:admin` ownership (instead of my own
user and group), which was necessary for this particular program.

<div class="note">

**Note:** there's also a `Bom` file next to our `Payload` and `Scripts`
archives, which is effectively a BOM (bill of materials), containing a
bunch of information about the files in the package.

In my experience I didn't need to touch this file despite some of the
contents of the package changing, but your mileage may vary, in which
case you might want to regenerate the BOM from our extracted
`PayloadOut` directory by running `mkbom PayloadOut Bom`.

</div>

### The package

Before repackaging don't forget to remove our temporary `PayloadOut` and
`ScriptsOut` directories.

Then, from the root of the extracted package, we can run the following
command to create a new package:

```sh
xar --compression none -cf ../vanta-new.pkg .
```

The `--compression none` part turned out to be important because if the
XAR archive is compressed, we encounter the following error during the
installation:

```
Error Domain=BOMCopierFatalError Code=1 "cpio read error: bad file format"
```

This error is kinda misleading because it points to the cpio archive
while the issue really is with the top-level XAR archive.

It's even more confusing because the macOS installer was able to extract
the XAR archive to read the metadata from it (and can happily show files
of the nested `Payload` archive), yet somehow fails to proceed with
the rest of the installation because the archive it's already reading
from is compressed?

I'm not gonna try to understand why that is, but just know that
`--compression none` is necessary for this to work!

## What about the package signature?

You might have noticed that we didn't sign that newly created package.

It turns out that this is fine. Sure, we're now lacking the lock icon on
the top right corner of the installer, but for our own usage, this isn't
a big deal. It doesn't prevent the installation from completing
whatsoever.

So how come we get a security warning when we try to run an unsigned
installer downloaded from the internet? That's because Apple flags
downloaded files as quarantined. You can see it by running e.g. `xattr
vanta.pkg` and seeing it includes `com.apple.quarantine`.

When opening a quarantined installer, macOS will check for a valid
signature and print a security warning otherwise.

But the archive we just created on our own is not quarantined, because
we didn't download it, so macOS is happy to let us run it without
signature, which is pretty useful here.

## Conclusion

Was it worth going through all that trouble to keep running my software
as natively as possible? Definitely not.

Did I learn a lot about macOS installers in the process, and how they
handle universal binaries? Hell yeah.

So in the end, I'm happy I dug through this, and if you ended up on this
article somehow, I hope this was useful to you too!

Wishing you a happy Rosetta-free Mac!
