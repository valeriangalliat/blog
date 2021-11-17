# How I set up a new Mac
November 17, 2021

As I [recently blogged](yearly-hackintosh-upgrade-macos-monterey-with-opencore.html),
I just upgraded to macOS Monterey taking it as an opportunity to start
from a clean, fresh, pristine system. This means I had to set up
everything again, which is not a big deal, but for the sake of
remembering it and making it even faster next time, I figured I'd write
about it.

This is the kind of blog post that's *mostly* for my personal interest,
but if you got there somehow, you might take inspiration from my
settings, who knows!

But first, let's ask the following question.

## Why start fresh?

While I could totally have migrated all my data from Big Sur, I like
to start from a clean slate every year or two, to get rid of all the
unnecessary garbage that accumulated over the years.

Wait, what garbage? Well, let me explain.

Every time you update a software (including the OS), there's no
guarantee that the state you'll be in after the update would be the
same as if you installed the new version directly on a fresh system.
Actually, the opposite is pretty much guaranteed.

Most of the time this is not a big deal. Maybe you're stuck with the
default settings of the version you originally installed instead of
the ones that would otherwise come with the latest version (i.e. Git
always defaults to `master` and you have to explicitly configure it to
use `main`, or any small things like this).

Or maybe some commands or tasks might run slightly slower because of
accumulated "bloat" related to things you don't use anymore and forgot
about (keys, passwords, certificates, trusted IP lists and whatnot
from stuff you connected to once or at least stopped connecting to
ages ago, the list of known Wi-Fi networks and `~/.ssh/known_hosts`
being a typical example).

While the above are pretty inoffensive cases, this kind of undefined
state drifts might cause more sneaky bugs, and "works on that machine"
kind of answers when you try to figure them out.

The same is also true when you uninstall a software; there's no
guarantee that the state you'll be in after the removal will match the
one you would have been in if you didn't install it in the first place.
And again, the opposite is pretty much guaranteed.

[NixOS](https://nixos.org/) solves some of those issues, but in the real
world, you're likely gonna want to use many programs that are not
designed and packaged to be stateless, deterministic, reproducible and
purely functional, and using wrappers (or wrapping them yourself) often
comes at a tremendous cost in time and convenience.

My tradeoff so far? A fresh reinstall every other year, or whenever I
feel like I've fucked around enough with that system's state to be worth
a clean start.

## New system setup

Here's the things I do when I log in the first time on my freshly
installed system.

* Get rid of all the garbage in the dock. I just leave the Finder and
  the trash, because you can't really remove them anyways (did you try
  dragging the trash to the trash?), but I happen to use them so that's
  fine.
* Open Safari to download **Firefox**. Very similar to how one would use
  Internet Explorer (oh wait, Edge) to install a real browser on
  Windows. This comparison might sound like a joke, but Safari
  effectively became the new Internet Explorer regarding how far behind
  they drag web standards, so this is sadly far more accurate than I'd
  like it to be.
* Download and install **iTerm2**.

<div class="note">

**Note:** I could have installed Firefox and iTerm2 with Homebrew (which
I add later) but for some reason there's a few programs I kinda like to
install on their own. Don't ask me why.

But now I think about it, it's probably because Homebrew became so
ridiculously slow to update its repository and the installed software
that I'd rather keep the ones I want to be the most up-to-date separate
from Homebrew.

I'll otherwise update Homebrew once a month or two, or when I need to
install something new with it, and it forces me to upgrade everything
else at the same time.

As a general rule of thumb, everything graphical I tend to install on
its own, and all the CLI stuff is with Homebrew.

</div>

* Install **Adobe Creative Cloud** and the apps I use with it (Lightroom
  Classic, Photoshop, Premiere and After Effects). In Creative Cloud
  preferences, turn off file syncing and launch at login.
  * On a multi-user system, you'll need to sign in to Creative Cloud for
    every single user to turn off file syncing and launch at login, even
    the ones who don't use Creative Cloud apps (because the preferences
    pane is only accessible to logged in users). Now all my users have an
    empty Creative Cloud account just for the sake of disabling it. I
    fucking hate the current state of technology. 🙃
* Install **Logic Pro** an download the full sound library. Sadly a fresh
  Logic installation can't reuse an existing sound library directory (I
  like to keep mine on my hard drive instead of my limited size SSD), so
  we need to download the whole 60 GB from scratch. Did I say I
  hate the current state of technology already?
* Press <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>5</kbd> to open the
  custom screenshot interface, where I can change the **screenshot
  directory** to `~/Desktop/Screenshots`. I don't like to clutter my
  desktop with screenshots like it's the case by default.
* I download and run [`patch-edid.rb`](https://gist.github.com/adaugherity/7435890)
  to [patch the EDID of my screen](https://www.codejam.info/2020/10/too-much-contrast-external-screen-macos-catalina.html)
  because since Catalina, macOS wants to communicate with it over YCbCr
  instead of RGB and that causes colors and contrast to be fucked up.
  This is extremely specific to my own screen.

Now I'm ready to configure the [system preferences](#system-preferences),
[iTerm2 settings](#iterm2-settings) and my [terminal-environment](#terminal-environment).

## System preferences

* In **keyboard** I set "key repeat" and "delay until repeat" to the
  fastest possible. I like my keyboard to be snappy.
* For the **dock & menu bar**, I leave only **Time Machine** and **fast
  user switching** if I'm on a multi-user system, and I set the
  **clock** to 24 hours format.
* I enable **Time Machine** backups to my usual drive after configuring
  my exclude list (very specific to my data so not included here).
* In **energy saver** I disable **Power Nap** because I don't need my
  machine to resume from sleep to check emails and run backups (after
  all if I'm not using my machine there's not much to back up anyways).
* In **displays** I turn on **Night Shift** form sunset to sunrise.

## iTerm2 preferences

* In **appearance**, **windows**, tick **hide scrollbars**.
* In **profiles**, **general**, select **reuse previous session's
  directory** as working directory.
* In **profiles**, **terminal**, tick **silence bell**.
* In **profiles**, **keys**, **key mappings**, load the **natural text
  editing** preset (allow it to remove whatever is already there), and
  remove <kbd>Command</kbd> + <kbd>Left</kbd> and <kbd>Command</kbd> +
  <kbd>Right</kbd> which otherwise shadow the shortcuts to navigate
  between tabs.

## Terminal environment

First, install [Homebrew](https://brew.sh/) with whatever is the current
recommended way. Install it in the default place because otherwise it
won't be able to leverage many prebuilt binaries that hardcode the
default prefix in them, and it's utterly slow to compile everything. I'd
be running Gentoo if that's what I wanted FFS. Also if you want to run
Homebrew on a multi-user system, [read that first](homebrew-multi-user.md).

Then, make a SSH keypair or copy an existing one in `~/.ssh`. I usually
run `ssh-keygen` either way just to let it create the directory with the
proper permissions, even if I'll override the key later.

```sh
ssh-keygen
```

Clone my [dotfiles](https://github.com/valeriangalliat/dotfiles)
directory and install my Mac preset (mainly my Zsh, Vim and Git
settings).

```sh
git clone git@github.com:valeriangalliat/dotfiles.git
cd dotfiles
make mac
cd
```

Edit my default `~/.zshrc` and `~/.zshenv` templates and comment or
uncomment some of the stuff there that I may need, mainly enabling my
asdf helper (see below).

```sh
vim ~/.zshrc ~/.zshenv
```

Install whatever software I pretty much always use with Homebrew.

```sh
brew install gpg ag fzf imagemagick ffmpeg ncdu
```

* GPG is required for the asdf Node.js plugin I'll add later below.
* [Ag (The Silver Searcher)](https://github.com/ggreer/the_silver_searcher)
  is my favorite way to search code.
* [fzf](https://github.com/junegunn/fzf) is an awesome fuzzy finder.
* I probably don't need to introduce [ImageMagick](https://imagemagick.org/)
  and [FFmpeg](https://www.ffmpeg.org/).
* [ncdu](https://dev.yorhel.nl/ncdu) is a cool tool to monitor disk usage.

Install the [asdf](https://github.com/asdf-vm/asdf) plugins I need
and whatever version is in my `~/.tool-versions`. My `~/.zshrc`
automatically installs asdf on the first invocation so no need to do
that manually.

```sh
asdf plugin add nodejs
# asdf plugin add python
# asdf plugin add ruby
# asdf plugin add elixir
# asdf plugin add erlang
asdf install
```

## Wrapping up

That's pretty much the gist! This is a fairly straightforward and not
very time consuming checklist, and the main things that need to be
automated (my dotfiles) are.

I don't think it's worth automating my macOS system preferences somehow
as they might change in future versions anyways. Same thing for iTerm2,
where I definitely don't want to copy over my whole configuration file
from an old installation, I'd rather start from the latest and greatest
defaults and just tweak what I need on top of it.

Everything else is very specific to the current machine I'm setting up
and I leave them to my discretion at the time of installing.

If you read until there, I hope that you learnt something, or that it
inspired you to document your base setup in a similar way. Cheers!
