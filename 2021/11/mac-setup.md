---
tweet: https://x.com/valeriangalliat/status/1461136814400577537
---

# How I set up a new Mac
November 17, 2021

<div class="note">

**Note:** updated August 1, 2026 with Tahoe and more scripting.

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

### Dock

Get rid of all the garbage in the dock. I just leave the Finder and
the trash, because you can't really remove them anyways (did you try
dragging the trash to the trash?), but I happen to use them so that's
fine.

```sh
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array
killall Dock
```

### Homebrew

Install [Homebrew](https://brew.sh/) (only `curl | sh` I'll tolerate).
I install it in the default place because otherwise it won't be able to
leverage many prebuilt binaries that hardcode the default prefix in
them, and it's utterly slow to compile everything. If you want to run
Homebrew on a multi-user system, [read that first](homebrew-multi-user.md).

After the installation, Homebrew tells you to add `eval
"$(/opt/homebrew/bin/brew shellenv)"` to your `~/.zprofile`.
I personally prefer to use my `~/.zshenv` for this, because it's sourced
all the time whereas `.zprofile` is sourced only for login shells.
Concretely this means that by setting the Homebrew environment
variables in `.zshenv`, I can do `ssh me@my-machine brew ...`, whereas
with `.zprofile`, I can't.

Also I don't like running `eval "$(brew shellenv)"` on every single
Zsh boot, I'd rather hardcode the output of `brew shellenv` in there
since it's not really supposed to change anyway:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
/opt/homebrew/bin/brew shellenv >> ~/.zshenv
```

### Apps

```sh
brew install firefox iterm2 maccy cursor
# brew install firefox@developer-edition
# brew install google-chrome
```

([Maccy](https://maccy.app/) is a lovely super light clipboard history manager.)

Then install **DaVinci Resolve** and **Logic Pro** and download the full
sound library. Sadly a fresh Logic installation can't reuse an existing
sound library directory (I like to keep mine on my hard drive instead
of my limited size SSD), so we need to download the whole 60 GB from
scratch.

### Screenshots

I don't like to clutter my desktop with screenshots like it's the case
by default, so I save them to `~/Desktop/Screenshots` instead:

```sh
mkdir -p ~/Desktop/Screenshots
defaults write com.apple.screencapture location ~/Desktop/Screenshots
```

Now I'm ready to configure the [system settings](#system-settings),
[iTerm2 preferences](#iterm2-preferences) and my [terminal environment](#terminal-environment).

## System settings

```sh
# General > AirDrop & Continuity: Allow Handoff between this Mac and your iCloud devices
defaults -currentHost write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
defaults -currentHost write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false

# General > Date & Time: 24-hour time
defaults write -g AppleICUForce24HourTime -bool true

# Accessibility > Zoom: Use scroll gesture with modifier keys to zoom (Control is default)
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true

# Desktop & Dock > Dock: Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Desktop & Dock > Dock: Don't show suggested and recent apps
defaults write com.apple.dock show-recents -bool false

# Desktop & Dock > Dock: Remove the delay to show and hide the dock
defaults write com.apple.dock autohide-delay -float 0

# Desktop & Dock > Windows: Tiled windows have margins
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

# Desktop & Dock > Mission Control: Don't automatically rearrange Spaces
defaults write com.apple.dock mru-spaces -bool false

# Desktop & Dock > Hot Corners (disable all, bottom right is Quick Note by default)
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0

# Keyboard: Key repeat rate & Delay until repeat (fastest possible, I like a snappy keyboard)
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15

killall Dock
```

<div class="note">

**Note:** log out and back in after running this block. Clock, keyboard and tiling settings don't take effect immediately.

</div>

For Dock delay, [see full blog post here](../../2022/05/macos-faster-desktops-dock.md).

Thanks to [this blog post](https://alexwlchan.net/notes/2025/disable-handoff-icons-in-dock/)
for disabling Continuity Handoff (prevent Dock icons from apps on other
devices).

A few things I still need to do manually in system settings:

* In **Battery > Charging > ⓘ**, set **Charge Limit** to **80%**. Leave
  **Optimized Battery Charging** on (should be default).
* In **General > Software Update > Automatic updates > ⓘ**, turn on
  **Download new updates when available**, but turn off **Install macOS
  updates** (I don't want macOS to reboot without my permission and lose
  any unsaved state).
* In **Displays > Night Shift...**, set **Schedule** to **Sunset to Sunrise**.
* In **Keyboard > Input Sources > Edit...**, disable everything. Also in
  **Text Replacements...**, remove the built-in `omw` abbreviation. I'm
  always staggered when I forget to do this and `omw` gets replaced by
  `On my way!`, or when I press space twice and it inserts a colon
  instead while I code in Cursor! 🤦‍♀️
* In **Keyboard > Keyboard Shortcuts... > Mission Control**, I enable
  the **Switch to Desktop** shortcuts for [faster desktop switching](../../2022/05/macos-faster-desktops-dock.md).

For all Visual Studio Code based editors, I disable
`ApplePressAndHoldEnabled` for... sanity. And I also [force new windows to open as tabs](https://powerusers.codidact.com/posts/285975/285976#answer-285976)
(this can also be configured [system-wide](https://support.apple.com/en-ca/guide/mac-help/mchlp1032/mac#apd6b032a9835244)
but I only want it for those apps).

```sh
# Visual Studio Code
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCode AppleWindowTabbingMode -string always

# Cursor
defaults write com.todesktop.230313mzl4w4u92 ApplePressAndHoldEnabled -bool false
defaults write com.todesktop.230313mzl4w4u92 AppleWindowTabbingMode -string always

# Antigravity
defaults write com.google.antigravity ApplePressAndHoldEnabled -bool false
defaults write com.google.antigravity AppleWindowTabbingMode -string always
```

## iTerm2 preferences

```sh
# Appearance > General > Theme: Minimal
defaults write com.googlecode.iterm2 TabStyleWithAutomaticOption -int 5

# Appearance > Windows: Hide scrollbars
defaults write com.googlecode.iterm2 HideScrollbar -bool true

# Appearance > Tabs: Preserve window size when tab bar shows or hides
defaults write com.googlecode.iterm2 PreserveWindowSizeWhenTabBarVisibilityChanges -bool true

# Appearance > Panes > Show per-pane title bars: off
defaults write com.googlecode.iterm2 ShowPaneTitles -bool false

# Appearance > Dimming > Dimming amount: 10
defaults write com.googlecode.iterm2 SplitPaneDimmingAmount -float 0.1

# Advanced > Mouse: Scroll wheel sends arrow keys when in alternate screen mode
defaults write com.googlecode.iterm2 AlternateMouseScroll -bool true

# Profiles > General > Initial directory: Reuse previous session's directory
/usr/libexec/PlistBuddy -c "Set ':New Bookmarks:0:Custom Directory' Recycle" ~/Library/Preferences/com.googlecode.iterm2.plist

# Profiles > Terminal > Bell: Silence bell
/usr/libexec/PlistBuddy -c "Set ':New Bookmarks:0:Silence Bell' true" ~/Library/Preferences/com.googlecode.iterm2.plist
```

<div class="note">

**Note:** run this when iTerm2 is _not_ running.

</div>

Finally (I couldn't script this), in **Profiles > Keys > Key Bindings**,
load the **Natural Text Editing** preset (allow it to remove whatever is
already there), and remove <kbd>Command</kbd> + <kbd>Left</kbd> and
<kbd>Command</kbd> + <kbd>Right</kbd> which otherwise shadow the
shortcuts to navigate between tabs.

## Terminal environment

Starts with Xcode Command Line Tools to have `git`.

```sh
xcode-select --install
```

Then I make a SSH keypair or copy an existing one in `~/.ssh`. I usually
run `ssh-keygen` either way just to let it create the directory with the
proper permissions, even if I'll override the key later.

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
brew install rg imagemagick ffmpeg ncdu htop jq asdf wget tree watch moreutils yt-dlp 
```

* [ripgrep](https://github.com/BurntSushi/ripgrep) is my favorite way to
  search code.
* I probably don't need to introduce [ImageMagick](https://imagemagick.org/)
  and [FFmpeg](https://www.ffmpeg.org/).
* [ncdu](https://dev.yorhel.nl/ncdu) is a cool tool to monitor disk usage.
* [htop](https://htop.dev/) is an awesome process viewer.
* [jq](https://jqlang.org/), legendary CLI to process JSON.
* [asdf](https://asdf-vm.com/) version manager.
* `wget`, `tree`, `watch` basic UNIX commands missing from macOS.
* [moreutils](https://github.com/pgdr/moreutils) handy utils, mainly for `sponge`.
* [yt-dlp](https://github.com/yt-dlp/yt-dlp) CLI video downloader.

Install the [asdf](https://github.com/asdf-vm/asdf) plugins I need
and whatever version is in my `~/.tool-versions`.

```sh
asdf plugin add nodejs
# asdf plugin add python
asdf install
```

## Wrapping up

That's pretty much the gist! This is a fairly straightforward and not
very time consuming checklist, and the main things that need to be
automated (my dotfiles) are.

Everything else is very specific to the current machine I'm setting up
and I leave them to my discretion at the time of installing.

If you read until there, I hope that you learnt something, or that it
inspired you to document your base setup in a similar way. Cheers!
