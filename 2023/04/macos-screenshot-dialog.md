# macOS screenshot: capture selected window but for dialogs
April 13, 2023

On macOS, you can take a screenshot of a specific window, by pressing
<kbd>Command</kbd> + <kbd>Shfit</kbd> + <kbd>5</kbd> and selecting
**Capture Selected Window** as explained [here](https://support.apple.com/en-ca/guide/mac-help/mh26782/mac).

Alternatively, you can use <kbd>Command</kbd> + <kbd>Shfit</kbd> +
<kbd>4</kbd> to bring the free selection tool, and press
<kbd>Space</kbd> to go in window selection mode.

This is neat, because it captures the window with a nice shadow over a
transparent background, so when embedded, it looks like this:

<figure class="center">
  <img alt="A blank terminal window" srcset="../../img/2023/04/dialog/window.png 2x">
</figure>

This is great, but sometimes you want to select just a _dialog_ inside a
window. For example, if I was to try to close this terminal:

<figure class="center">
  <img alt="A dialog to confirm whether to close all tabs" srcset="../../img/2023/04/dialog/window-dialog.png 2x">
</figure>

Here, the screenshot tool only lets me capture the whole window, but I
can't have it capture _just_ the dialog in the middle, and do so with
the nice shadow.

In this case it's not too bad because the parent window was small, but
what if you're capturing a small dialog inside a very large window?

You can always do a free selection or crop it yourself, but then you
still won't have the nice shadow with transparency:

<figure class="center">
  <img alt="Cropped dialog" srcset="../../img/2023/04/dialog/dialog-crop.png 2x">
</figure>

Wouldn't it be great if we could have the following instead?

<figure class="center">
  <img alt="Nice dialog with shadow" srcset="../../img/2023/04/dialog/dialog-shadow.png 2x">
</figure>

## Introducing Windowify

[Windowify](https://github.com/valeriangalliat/windowify) is a small
tool that I made to solve this issue. I'll start with how to use it for
that use case, then I'll jump in the [technical details](#technical-details).

Once installed, you can give it an image of your choice, and all it does
is display it in a native macOS window, exposing to you the various
styling options that macOS offers.

By default, if we gave it the earlier crop, it would display the following:

<figure class="center">
  <img alt="Dialog with a title bar" srcset="../../img/2023/04/dialog/dialog-title.png 2x">
</figure>

In our case, we need to use `windowify --minimal`, which is really a
shortcut for `windowify -closable -miniaturizable -resizable
+fullSizeContentView +titlebarAppearsTransparent +titleHidden`. It will
show our image in a window with rounded corners but without any UI
element otherwise (like the title bar and close button).

We can now take a screenshot of this new window, this time using the
native window selection, so we get the shadow and transparency!

<figure class="center">
  <img alt="Nice dialog with shadow" srcset="../../img/2023/04/dialog/dialog-shadow.png 2x">
</figure>

## Technical details

To whoever may be interested, I'll give some technical details on how
this works.

Windowify is a Swift program, and uses it as a dynamic interpreter,
simply by using `#!/usr/bin/env swift` as a shebang, which I had no clue
was possible prior to this.

While most Swift windowed apps are expected to be created as part of an
Xcode project, it turns out the library [is flexible enough](https://stackoverflow.com/questions/30763229/display-window-on-osx-using-swift-without-xcode-or-nib)
to allow easily creating windows without a complex app boilerplate and
an explicit compilation process!

This is made particularly easy using
[`NSApplication.shared`](https://developer.apple.com/documentation/appkit/nsapplication/1428360-shared)
which automatically creates the application instance if it doesn't
exist.

The script looks at `CommandLine.arguments` to parse the CLI arguments,
and uses a `NSImage` and `NSImageView` to display the image in a
`NSWindow`.

The main logic is to translate the CLI arguments into the matching
`styleMask` and other properties of `NSWindow`, to make the appearance
customizable by the user.

In the first place I had it working without even using a custom
`NSApplicationDelegate`, but the main application loop was then blocking
the thread and made the menu unresponsive (I use a menu to handle
<kbD>Command</kbd> + <kbd>W</kbd> to close the window). Moving the logic
inside an application delegate resolved that.

Take a look at [the code](https://github.com/valeriangalliat/windowify/blob/main/windowify)
if you want to know in more details how this all works!
