# macOS app showing scrollbars to some users only
June 25, 2025

## TLDR

macOS has a setting where it shows fixed scrollbars to people using a
mouse, while people using a trackpad have tiny "floating" scrollbars
that are entirely hidden when not actively scrolling.

You can find it in **Appearance > Show scroll bars** and either force it
to always on or always off (or keep it auto).

## Story time

While developing a macOS app (in my case with Electron, although this
problem is not specific to Electron), I encountered a wild bug.

Some users reported having scrollbars visible in different parts of the
app, and looking quite "off" visually:

<figure class="center">
  <img alt="Scrollbars" srcset="../../img/2025/06/macos-scrollbars/scrollbars.png 2x">
</figure>

However on my side it looked just fine:

<figure class="center">
  <img alt="No scrollbars" srcset="../../img/2025/06/macos-scrollbars/no-scrollbars.png 2x">
</figure>

I could not understand what was causing this. After all, it was
happening across the same version of Electron, Chromium, of the app
itself, and of macOS!

It's only when another developer reported having the bug that I jumped
on a call with him to debug the issue.

While messing with the dev tools, one thing jumped out to me: inside his
dev tools, scrollbars were visible at all times:

<figure class="center">
  <img alt="Dev tools scrollbars" srcset="../../img/2025/06/macos-scrollbars/devtools-scrollbars.png 2x">
</figure>

While on my side I only had floating scrollbars while I was scrolling,
and they would disappear entirely otherwise:

<figure class="center">
  <img alt="Dev tools floating scrollbars" srcset="../../img/2025/06/macos-scrollbars/devtools-floating.png 2x">
</figure>

Same version of macOS as well!

What was going on?

**It turns out the culprit was that my colleague was using a mouse,
while I was using the trackpad of my laptop.**

What the mouse vs. trackpad have to do with this? Meet this setting:

<figure class="center">
  <img alt="macOS scrollbars settings" srcset="../../img/2025/06/macos-scrollbars/macos-settings.png 2x">
</figure>

By default, macOS shows scrollbars at all times when using a mouse, but
uses floating scrollbars when using a trackpad!

Now I could force this setting to "Always" to reproduce the issue
locally, and update the app to look OK even for people who use a mouse. 🙃

In many places, we had unnecessary `overflow: scroll` in places where
`overflow: auto` would do, and a few places where we had to hide
scrollbars entirely with `overflow: hidden`.

It was easy to make those silly mistakes when all the devs working on
the app were using a trackpad. 😂

## Bonus: dark mode scrollbars

For the places where we did want scrollbars, there was a remaining
issue: we force our app in dark mode, but the scrollbars were showing in
light mode nevertheless!

The way we force our Electron app in dark mode is by doing:

```js
import { nativeTheme } from 'electron'

nativeTheme.themeSource = 'dark'
```

However in order for native scrollbars to show in dark mode, we also had
to add the following to our HTML file:


```html
<body style="color-scheme: dark"></body>
```

(This is not the place where we actually needed scrollbars, but for lack
of a better screenshot, here's what it would look like with both
directions scrollbars:)

<figure class="center">
  <img alt="Scrollbars dark mode" srcset="../../img/2025/06/macos-scrollbars/scrollbars-dark.png 2x">
</figure>

