# dmenumoji: dmenu with built-in libxft-bgra and emoji support 💪
August 22, 2021

## TLDR

To get dmenu to work with emojis, you need to compile it from source
against [libxft-bgra][] (from [this PR][libxft-pr]),
after removing the `iscol` check in `drw.c` that prevents colored fonts
to be used, and configuring a colored font in `config.h` or
`config.def.h` (see patches below).

[libxft-bgra]: https://aur.archlinux.org/packages/libxft-bgra/
[libxft-pr]: https://gitlab.freedesktop.org/xorg/lib/libxft/-/merge_requests/1

Go check out [dmenumoji](https://github.com/valeriangalliat/dmenumoji)
that does all that work for you!

## The story

A couple weeks ago, during my daily procrastination routine (I like to
procrastinate in the mornings right after meditating and taking a cold
shower), I figured it would be nice to have some kind of emoji picker on
my Arch Linux rig.

I quickly found [this thread](https://askubuntu.com/questions/1045915/how-to-insert-an-emoji-into-a-text-in-ubuntu-18-04-and-later),
sadly a lot of the solutions there are specific to particular desktop
environments, and I'm not using any. Although [Emote](https://github.com/tom-james-watson/Emote)
looks promising, and has an [AUR package](https://aur.archlinux.org/packages/emote),
it [fails to paste in terminals](https://github.com/tom-james-watson/Emote/issues/44).
Since I spend most of my time in terminals so this is not an option.

That's when I find about [`rofimoji`](https://github.com/fdw/rofimoji)
which is even already packaged on Arch, and it's definitely an awesome
piece of software, but I'm a dmenu user and I would rather keep things
consistent.

Since I like the idea of a dmenu-based emoji picker, I start looking
specifically for that and find [dmenu-emoji](https://github.com/porras/dmenu-emoji),
which despite the name, is actually meant to be used with Rofi, but also
claims to work with dmenu. But when I try it with plain dmenu, the
emojis only show up as empty squares. Not ideal.

## Making dmenu show emojis

Trying to figure that issue, I stumble upon [this video](https://youtu.be/0QkByBugq_4)
which explains that you need to compile dmenu from source against
[libxft-bgra], a patched version of libXft from [this PR][libxft-pr]
that adds support for colored (BGRA) glyphs, all of that after patching
dmenu itself to remove a workaround that they added to prevent crashes
with libXft's lack of support for BGRA glyphs, that dropped support for
colored fonts in the first place.

Typically this is done on Arch by installing [libxft-bgra] from the AUR,
and applying the following patch to the dmenu source, as explained in
the video.

```diff
diff --git a/drw.c b/drw.c
index 4cdbcbe..c1c265c 100644
--- a/drw.c
+++ b/drw.c
@@ -133,19 +133,6 @@ xfont_create(Drw *drw, const char *fontname, FcPattern *fontpattern)
 		die("no font specified.");
 	}
 
-	/* Do not allow using color fonts. This is a workaround for a BadLength
-	 * error from Xft with color glyphs. Modelled on the Xterm workaround. See
-	 * https://bugzilla.redhat.com/show_bug.cgi?id=1498269
-	 * https://lists.suckless.org/dev/1701/30932.html
-	 * https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=916349
-	 * and lots more all over the internet.
-	 */
-	FcBool iscol;
-	if(FcPatternGetBool(xfont->pattern, FC_COLOR, 0, &iscol) == FcResultMatch && iscol) {
-		XftFontClose(drw->dpy, xfont);
-		return NULL;
-	}
-
 	font = ecalloc(1, sizeof(Fnt));
 	font->xfont = xfont;
 	font->pattern = pattern;
```

I tried all of that, but still had the same issue! One important detail
that was missing from that video was that dmenu doesn't support
[fontconfig's fallback fonts](https://github.com/valeriangalliat/dotfiles/blob/47506803600b0e5b194e35c56a835b54aae72f32/x11/fonts.conf),
and you need to [explicitly configure](https://bbs.archlinux.org/viewtopic.php?id=255799)
an emoji font in dmenu's source, as you can see in [Luke's dmenu](https://github.com/LukeSmithxyz/dmenu/blob/3a6bc67fbd6df190b002d33f600a6465cad9cfb8/config.h#L8).

```diff
diff --git a/config.def.h b/config.def.h
index 1edb647..b55c45c 100644
--- a/config.def.h
+++ b/config.def.h
@@ -4,7 +4,8 @@
 static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
 /* -fn option overrides fonts[0]; default X11 font or font set */
 static const char *fonts[] = {
-	"monospace:size=10"
+	"monospace:size=10",
+	"emoji:size=10"
 };
 static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
 static const char *colors[SchemeLast][2] = {
```

After doing so, the emojis did show up! 🎉

## Automating the build

This is great, but it still takes a lot of manual steps, and needs root
access to install libxft-bgra globally. I think this is unnecessary, and
I figured it would be cool to compile dmenu *statically* against the
patched libXft instead, without touching to the system.

This is something that can be done easily with the following patch,
assuming that the libxft-bgra source is in `../libxft` relative do the
dmenu source.

```diff
diff --git a/config.mk b/config.mk
index 05d5a3e..05300a6 100644
--- a/config.mk
+++ b/config.mk
@@ -13,8 +13,8 @@ XINERAMALIBS  = -lXinerama
 XINERAMAFLAGS = -DXINERAMA
 
 # freetype
-FREETYPELIBS = -lfontconfig -lXft
-FREETYPEINC = /usr/include/freetype2
+FREETYPELIBS = -lfontconfig -lfreetype -lXrender -lX11 -L../libxft/src/.libs -l:libXft.a
+FREETYPEINC = /usr/include/freetype2 -I$(PWD)/../libxft/include
 # OpenBSD (uncomment)
 #FREETYPEINC = $(X11INC)/freetype2
 
```

Then libXft can be compiled with:

```sh
./autogen.sh
make
```

And dmenu with:

```sh
make
```

<div class="note">

**Note:** libXft needs `xorg-util-macros` to be installed in order to
generate the man pages. Since I don't really need that, I added a
further [patch](https://github.com/valeriangalliat/dmenumoji/blob/master/libxft.patch)
that removes the check for this library, and build with `make SUBDIRS=src`
to ignore the `man` directory.

</div>

This leaves us with a statically linked version of dmenu against
libxft-bgra with proper support for colored glyphs. 🥳

<figure class="center">
  <img alt="dmenumoji in action" src="https://raw.githubusercontent.com/valeriangalliat/dmenumoji/master/preview.png">
  <figcaption>dmenumoji in action</figcaption>
</figure>

Now, all we need is to combine all the earlier patches to a
`dmenu.patch`, and make a neat [makefile](https://github.com/valeriangalliat/dmenumoji/blob/master/Makefile)
to do all that work for us, including cloning the dmenu and libXft
repositories, applying the BGRA patch as well as our dmenu patch, and
compiling everything.

```makefile
all: dmenu/dmenu

dmenu/dmenu: dmenu libxft/src/.libs/libXft.a
	make -C $<

dmenu:
	git clone --branch 5.0 https://git.suckless.org/dmenu
	patch -d $@ < dmenu.patch

libxft/src/.libs/libXft.a: libxft
	cd $< && ./autogen.sh && make SUBDIRS=src

libxft: libxft-bgra.patch
	git clone https://gitlab.freedesktop.org/xorg/lib/libxft.git
	@# Remove check for xorg-util-macros that's only used to add `.1` at the
	@# end of a man page we're not gonna use.
	patch -d $@ < libxft.patch
	patch -d $@ -p1 < $<

libxft-bgra.patch:
	curl -o $@ https://gitlab.freedesktop.org/xorg/lib/libxft/-/merge_requests/1.patch
```

With that, a simple `make` command gives us a fully working dmenu with
emoji support. You can find all of that (and more) in the [dmenumoji](https://github.com/valeriangalliat/dmenumoji)
repo I created to bundle everything together!

## Bonus: dynamically linked against a custom location

Out of curiosity, I wanted to see what it would take, to dynamically
link to our patched version of libXft without installing it in the
standard library path (e.g. `/usr/lib`).

It turns out that you can pass linker options to the compiler through
the `-Wl` option, which allows us to use `-rpath` to append our custom
libXft directory (specifically the `src/.libs` path which is where
libXft builds the shared libraries) to the runtime library search path
of the executable.

```diff
diff --git a/config.mk b/config.mk
index 05d5a3e..d3b05c5 100644
--- a/config.mk
+++ b/config.mk
@@ -13,8 +13,8 @@ XINERAMALIBS  = -lXinerama
 XINERAMAFLAGS = -DXINERAMA
 
 # freetype
-FREETYPELIBS = -lfontconfig -lXft
-FREETYPEINC = /usr/include/freetype2
+FREETYPELIBS = -lfontconfig -lXft -Wl,-rpath $(PWD)/../libxft/src/.libs
+FREETYPEINC = /usr/include/freetype2 -I$(PWD)/../libxft/include
 # OpenBSD (uncomment)
 #FREETYPEINC = $(X11INC)/freetype2
 
```

With that, our dmenu executable will know at runtime to dynamically load
our locally built libXft that has BGRA support, as long as we don't move
it from the nonstandard path we hardcoded there.
