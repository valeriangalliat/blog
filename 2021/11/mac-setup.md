---
tweet: https://x.com/valeriangalliat/status/1461136814400577537
---

# How I set up a new Mac
November 17, 2021

<div class="note">

**Note:** updated March 17, 2023 with Ventura!

</div>

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
* Open the terminal app to install [Homebrew](https://brew.sh/) with
  whatever is the current recommended way. I Install it in the default
  place because otherwise it won't be able to leverage many prebuilt
  binaries that hardcode the default prefix in them, and it's utterly
  slow to compile everything. If you want to run Homebrew on a
  multi-user system, [read that first](homebrew-multi-user.md).

  After the installation, Homebrew tells you add `eval
  "$(/opt/homebrew/bin/brew shellenv)"` to your `~/.zprofile`. I
  personally prefer to use my `~/.zshenv` for this, because it's sourced
  all the time whereas `.zprofile` is sourced only for login shells.
  Concretely this means that by setting the Homebrew environment
  variables in `.zshenv`, I can do `ssh me@my-machine brew ...`, whereas with `.zprofile`, I can't.

  Also I don't like running `eval "$(brew shellenv)"` on every single
  Zsh boot, I'd rather hardcode the output of `brew shellenv` in there
  since it's not really supposed to change anyway. Concretely, I run:

  ```sh
  /opt/homebrew/bin/brew shellenv >> ~/.zshenv
  ```
* Install Firefox and iTerm2 and optionally other apps:

  ```sh
  brew install firefox iterm2
  # brew install rectangle
  # brew install homebrew/cask-versions/firefox-developer-edition
  # brew install google-chrome
  # brew install visual-studio-code
  ```
* Install **DaVinci Resolve**.
* Install **Logic Pro** an download the full sound library. Sadly a fresh
  Logic installation can't reuse an existing sound library directory (I
  like to keep mine on my hard drive instead of my limited size SSD), so
  we need to download the whole 60 GB from scratch.
* Press <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>5</kbd> to open the
  custom screenshot interface, where I can change the **screenshot
  directory** to `~/Desktop/Screenshots`. I don't like to clutter my
  desktop with screenshots like it's the case by default.

Now I'm ready to configure the [system preferences](#system-preferences),
[iTerm2 preferences](#iterm2-preferences) and my [terminal-environment](#terminal-environment).

## System preferences

* In **Keyboard** I set **Key repeat rate** and **Delay until repeat**
  to the fastest possible. I like my keyboard to be snappy.
* In **Keyboard > Input Sources**, I **Edit** the settings to disable
  everything. Also in the **Text Replacements** part, I remove the
  built-in `omw` abbreviation. See [before](../../img/2021/11/keyboard-before.png)
  and [after](../../img/2021/11/keyboard-after.png). I'm always
  staggered when I forget to do this and `omw` gets replaced by `On my
  way!`, or when I press space twice and it inserts a colon instead
  *while I code in Visual Studio Code*! 🤦‍♀️
* In **Keyboard > Keyboard Shortcuts > Mission Control**, I
  enable the **Switch to Desktop** shortcuts for [faster desktop switching](../../2022/05/macos-faster-desktops-dock.md).
* In **Control Center**, I leave only **Time Machine** and **Fast
  User Switching** in the menu bar if I'm on a multi-user system, and I
  set the **Clock** to 24 hours format.
* In **Desktop & Dock**, tick **Automatically hide and show the Dock**,
  untick **Show recent applications in Dock**, and under **Mission
  Control**, untick **Automatically rearrange Spaces based on most recent use**.
* I enable **Time Machine** backups to my usual drive after configuring
  my exclude list (very specific to my data so not included here).
* In **Displays** I turn on **Night Shift** form sunset to sunrise.
* Run `defaults write com.apple.dock autohide-delay -float 0; killall Dock`
  to [remove the delay](../../2022/05/macos-faster-desktops-dock.md) to
  show and hide the dock.
* In **General > Software Update > Automatic updates**, I turn on
  **Check for updates** and **Download new updates when available**, but
  make sure **Install macOS updates** is off (I don't want macOS to
  reboot without my permission and lose any unsaved state).
* If I installed Visual Studio Code, I run `defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false`
  for... sanity. For Cursor it's `defaults write com.todesktop.230313mzl4w4u92 ApplePressAndHoldEnabled -bool false`,
  and for Antigravity it's `defaults write com.google.antigravity ApplePressAndHoldEnabled -bool false`.

## iTerm2 preferences

* In **Appearance > Windows**, tick **Hide scrollbars**.
* In **Appearance > Tabs**, tick **Preserve window size when tab bar
  shows or hides**.
* In **Appearance > Panes**, untick **Show per-pane title bars**.
* In **Profiles > General**, select **Reuse previous session's
  directory** as working directory.
* In **Profiles > Terminal**, tick **Silence bell**.
* In **Profiles > Keys > Key Bindings**, load the **Natural Text
  Editing** preset (allow it to remove whatever is already there), and
  remove <kbd>Command</kbd> + <kbd>Left</kbd> and <kbd>Command</kbd> +
  <kbd>Right</kbd> which otherwise shadow the shortcuts to navigate
  between tabs.
* In **Advanced > Mouse**, set **Scroll wheel sends arrow keys when
  in alternate screen mode** to **Yes**.

## Terminal environment

First, I make a SSH keypair or copy an existing one in `~/.ssh`. I
usually run `ssh-keygen` either way just to let it create the directory
with the proper permissions, even if I'll override the key later.

```sh
ssh-keygen -t ed25519
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
brew install rg fzf imagemagick ffmpeg ncdu htop
```

* [ripgrep](https://github.com/BurntSushi/ripgrep)
  is my favorite way to search code.
* [fzf](https://github.com/junegunn/fzf) is an awesome fuzzy finder.
* I probably don't need to introduce [ImageMagick](https://imagemagick.org/)
  and [FFmpeg](https://www.ffmpeg.org/).
* [ncdu](https://dev.yorhel.nl/ncdu) is a cool tool to monitor disk usage.
* [htop](https://htop.dev/) is an awesome process viewer.

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
