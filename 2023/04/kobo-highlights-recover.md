---
tweet: https://x.com/valeriangalliat/status/1643793553032617986
---

# Recovering Kobo eReader highlights after an accidental factory reset!
Grepping through raw disk image, yay  
April 5, 2023

The other day my Kobo eReader had some issues where it was instantly
dying when not plugged in, despite showing a full battery! This happened
after I let it charge overnight on an external battery. 😬

I restarted it a few times, hoping this would fix the issue, but without
luck. Until... the last restart was a bit different: **it asked me to
chose a language**.

At this very moment, I knew I fucked up.

I somehow managed to accidentally factory reset my eReader!

## Limiting the damage: make a disk image

Because I was in denial, I didn't instantly accept that a factory reset
had happened. So I went on, picked my language and connected it again to
my Wi-Fi, so I could access the main screen.

Indeed, all my books were gone. Not a big deal because I have a copy on
my computer. More problematic though, my highlights and notes were
gone too!

I do back them up once in a while, but I've been neglecting that, so my
last backup was over 4 months old! I've read a bunch of books since
then, and highlighted quite some stuff I would have been happy to go
through again in the future. Bummer.

To prevent further damage, once I realized my data was gone, I stopped
doing anything with the device that could write to the storage.

As any good data recovery starts, I plugged it to my laptop and cloned
the entire storage to an image file:

```sh
dd if=/dev/sdb of=kobo-raw-disk bs=1M
```

<div class="note">

**Note:** I used `dd` because the storage of the eReader was presumably
healthy, if not for the fact that a factory reset had happened.

If I had actual corruption issues with the disk, it would have been good
to use [`ddrescue`](https://www.gnu.org/software/ddrescue/).

</div>

## TestDisk: trying to recover the original partition

The first thing I tried was to use [TestDisk](https://www.cgsecurity.org/wiki/TestDisk)
to recover the partition table from before the factory reset, but this
wasn't successful.

I think it would have been a more appropriate tool to recover specific
partitions that were deleted without being written over, or if only the
partition table was corrupted or lost.

Here though, I think the factory reset process overwrote too much data
to make TestDisk successful. It didn't hurt to try though!

## PhotoRec: extract recognizable file formats from raw disk

Had I been successful with TestDisk, I would have recovered the original
partition and filesystem, with the entire directory structure and
filenames.

As a fallback though, I decided to use
[PhotoRec](https://www.cgsecurity.org/wiki/PhotoRec)
(another tool by the same creators as TestDisk), to try and identify
well-known file formats from the raw disk image.

The inconvenient of that is that we lose all the filenames and their
arborescence, but I can live with that.

The output of PhotoRec was 7304 files, split in directories containing
500 files each, going from `recup_dir.1` to `recup_dir.15`.

Each file is named after the logical sector it was found at, which is
not very useful to me here, and has the extension of the filetype that
was identified.

Here's all the extensions it was able to find, along with the number of
files for that extension:

```console
$ find photorec-out -type f | sed 's/.*\.//' | sort | uniq -c
      5 c
      1 csv
      2 elf
     77 epub
      5 f
     11 gz
     18 h
     18 html
      1 ico
   1493 ini
    154 java
   3964 jpg
      4 pdf
      3 plist
    161 png
     27 py
      6 sqlite
      1 sxw
      1 tar
   1343 txt
      1 xml
      8 zip
```

## Trying to recover the SQLite databases

I knew that Kobo stores the highlights in a SQLite database, located in
`.kobo/KoboReader.sqlite`. If this was intact, I had all my highlights
back!

I tried to open the 6 identified SQLite databases, but sadly, the few
that weren't corrupted didn't have the tables I was looking for, and the
only one that was about as large as what I would expect for my
`KoboReader.sqlite` (a bit bigger than the one of my last backup) was
corrupted.

I tried using the [`.recover`](https://www.sqlite.org/recovery.html)
SQLite command, but that didn't work either:

```sh
sqlite3 corrupt.db .recover > data.sql
```

I tried [a whole bunch](https://www.nucleustechnologies.com/blog/best-6-sqlite-database-recovery-tools/)
of different proprietary tools to recover corrupted SQLite databases,
but none of them was able to do anything.

When I was looking at the raw contents of the SQLite database though,
e.g. using `less` directly on the binary file, or using `xxd` or
`strings`, I could see some highlights data, but definitely not as much
as I expected.

## Looking at the raw disk directly

I tried pretty hard for that SQLite database, but I had to come to the
fact it wasn't gonna be my savior here. However there was something I
liked about this idea of looking at the raw binary data directly.

I had a light of hope when I decided to `grep` into the corrupted SQLite
database, as well as the raw disk image, for fragments of sentences I
definitely remembered having highlighted. The binary files, in fact,
matched! There was after all a chance that at least some of my
highlights were there, but it wasn't exactly clear where, how many, and
under what form.

Since I couldn't do anything with the database, I decided to focus on
the raw disk image. Using `less` and `xxd` to visualize it wasn't very
successful (it took too long to go through the huge amounts of
unreadable data to notice anything actually usable). However, `strings`,
that only outputs printable data, made it much easier for me to filter
through its contents.

When I looked up in the `strings` output for some sentence I remembered
highlighting, it was, in fact, part of a fairly large XML string! What?

## Looking at the recovered XML files

It turned out that whole time, the Kobo eReader was storing annotations
not only in a database, but also in XML files!

For some reason PhotoRec identified them all as `txt` instead of `xml`,
but it was pretty easy to extract them. All the annotations XML started
with `<annotationSet`.

```sh
grep -R --files-with-match '<annotationSet' photorec-out/**/*.txt
```

With `-R` for recursive, and `--files-with-match`, this command printed
the filenames of all the files that contained `<annotationSet`.

I copied them to a separate directory for analysis.

I quickly identified a pattern: each XML file contained all the
annotations for a given book, but I had many different XML files for the
same books, with more or less annotations in them. It was like I had the
history of every single time each file was written to as I added new
highlights!

I wrote a quick script to validate this theory, and surely, the XML with
the most annotations for each book systematically contained all of the
annotations of the other, smaller XML files for that same book. This
allowed me to filter quite a lot amongst those files.

## Integrity check: comparing with my backup database

Remember, I still had that copy of the database from a few months ago. I
decided to check the integrity of the XMLs I recovered against what was
in my backup, so I wrote a quick script to compare them.

I wasn't happy with what I found though. For the books for which I did
have a backup, this showed that I recovered _most_ of the highlights in
the XML files, but not _all_. This means that for the ones where I
didn't have a backup, I couldn't hope to have recovered _everything_.

This was better than nothing, but I was pretty uncomfortable with that
state of having recovered _some_ data but not knowing what data I had
actually lost. 😅

I scratched my head a bit, and surely enough, I was able to recall a few
words for a sentence that I definitely remembered highlighting recently,
and that was not part of the XMLs that PhotoRec recovered.

What was exciting though, is that I could successfully `grep` for this
sentence in the binary disk image! Did PhotoRec miss some XML files
somehow?

## Grepping for XML files on the raw disk directly!

Only one way to know. Since I knew exactly the patterns to look for at
the start and end of the annotations XML, I could find them in the raw
disk image, extract the byte offset, and then `dd` everything
in between each start and end offset!

Using `grep` with `--text` to force it to treat the disk binary data as text,
and `--byte-offset` to get the byte offset of the matches, I was able to
extract the position of the markers:

```sh
grep --byte-offset --text -o '<annotationSet' kobo-raw-disk > xml-start-markers-offsets
grep --byte-offset --text -o '</annotationSet>' kobo-raw-disk > xml-end-markers-offsets
```

Each file looked like this:

```
199089105:<annotationSet
222029926:<annotationSet
799936271:<annotationSet
830499395:<annotationSet
839015506:<annotationSet
```

From there, I used the `paste` command to merge both files side by side
(using a `cut` subshell in order to keep only the offset before the
`:`):

```sh
paste <(cut -d: -f1 xml-start-markers-offsets) <(cut -d: -f1 xml-end-markers-offsets)
```

Which gave me something like:

```
199089105	199091941
222029926	222031623
799936271	799937945
830499395	830499742
839015506	839016589
```

I could then use `dd` to extract the bytes from the raw disk image
in between those offsets:

```sh
start=199089105
end=199091941
dd if=kobo-raw-disk of=raw-xml-dump/$start.xml bs=1 skip=$start count=$((end - start + 16))
```

What's the 16 in that command? It's the length of the end marker
`</annotationSet>`! Because `grep` gave us the offset of the _start_ of
the search.

So I piped both of those commands together through a `while` loop to
extract all the XMLs:

```sh
paste <(cut -d: -f1 xml-start-markers-offsets) <(cut -d: -f1 xml-end-markers-offsets) \
   | while read start end; do
      dd if=kobo-raw-disk of=raw-xml-dump/$start.xml bs=1 skip=$start count=$((end - start + 16))
   done
```

With that method, I was able to find 287 XMLs, where PhotoRec only
recovered 234!

I ran my integrity check script against this new output, and was
astonished: _it was a perfect match_!

Every single highlight I had i my backup were found in those XMLs, which
gave me confidence that the ones that were _not_ in my backup were most
likely there too.

## Confidence checking

In order to be even more sure about this, I checked the last recovered
highlight for all of the books I've read since my last backup. Each
highlight contains a `progress` attribute, between 0 and 1, representing
how far in the book it's situated.

For all of the books I finished, the last highlight was pretty close to
the end of the book, and since we saw earlier that the file with the
most highlights always contained the highlights of the previous versions
of that file, I was pretty confident I've recovered all of my data at
that point! 🎉

## Wrapping up

This was a rollercoaster of emotions! Between losing all my highlights,
recovering a database that turned out to be unusable, finding the XMLs
with PhotoRec but noticing they were incomplete, and finally using
`grep` and `dd` to extract the XML files myself directly from the raw
disk. Luckily, I was able to recover everything I was looking for thanks
to the last method!

But really, the morale of this story is that, **if you care about some
data, you better make sure that you back it up**, and that you do so
rigorously and frequently (or even better, automatically).
