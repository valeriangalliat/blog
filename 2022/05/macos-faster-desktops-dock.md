# macOS faster switch between desktops and faster Dock
May 5, 2022

Quick tip for macOS! I've always found the animation to switch between
desktops and spaces quite slow, when using <kbd>Ctrl</kbd> +
<kbd>Left</kbd> or <kbd>Right</kbd>, or using the 3 fingers swipe on a
trackpad.

Same thing when configuring the Dock to hide by default and only show
when the mouse is near it. There's a slight delay that just drives me
nuts and caused me to keep the Dock visible at all times, wasting
precious vertical screen real estate! But luckily, I've found solutions
for those two problems.

<div class="note">

**Note:** initially I shared those on Twitter,
[here](https://twitter.com/valeriangalliat/status/1519696597940158464)
for the Dock and
[here](https://twitter.com/valeriangalliat/status/1519698499927158787)
for switching between desktops.

</div>

For the Dock, the delay can be removed with this command:

```sh
defaults write com.apple.dock autohide-delay -float 0; killall Dock
```

And to switch faster between desktops, I found that macOS provides
Mission Control shortcuts to switch to a specific desktop directly. It's
just not enabled by default, and you need to have multiple *active*
desktops in order for those shortcuts to be even shown in the
preferences!

For example with 3 active desktops, opening the keyboard shortcut
preferences, in the Mission Control section:

<figure class="center">
  <img alt="macOS keyboard shortcuts" src="../../img/2022/05/macos-keyboard-shortcuts.png">
</figure>

We see we can activate <kbd>Ctrl</kbd> and the number keys to directly
switch to a given desktop.

And it turns out the animation when using those shortcuts is noticeably
faster than <kbd>Ctrl</kbd> + <kbd>Left</kbd> and <kbd>Right</kbd>! And
on top of that instead of having to navigate through all the desktops
one by one, we can jump to the one we want directly, which makes the
flow even faster.

Sadly this doesn't work with spaces (e.g. full screen windows), only
with desktops. Because of that, I switched from using iTerm2 and Visual
Studio Code in full screen, and I instead use them as a maximized window
in a new desktop. I lose a tiny bit of vertical space because of the top
bar, but I gained even more vertical space with the Dock trick earlier
that this is not a big deal!

I hope this tip was useful to you. 🥰
