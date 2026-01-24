---
tweet: https://x.com/valeriangalliat/status/1790906282737840267
---

# Identify the current system cursor in Swift
February 4, 2024

Let's say for some reason you have a Swift app, and you want to know
what's the currently displayed macOS cursor (even when the cursor is
outside of your app).

Well, it's tricker than you would expect.

## Exploring `NSCursor.currentSystem`

AppKit do expose [`NSCursor.currentSystem`](https://developer.apple.com/documentation/appkit/nscursor/1533611-currentsystem)
that returns a `NSCursor` instance for the current system:

> This method returns the current system cursor regardless of which
> application set the cursor, and whether Cocoa or Carbon APIs were used
> to set it.

However, there's no property on `NScursor` that lets it identify itself,
e.g. a `NSCursor` instance doesn't _claim_ to be a `NSCursor.arrow` or
`NSCursor.iBeam` or whatnot. You only get a hot spot point and the
cursor pixel data.

One would think we can test `NSCursor.currentSystem` against all the
known cursors to know which one is used, e.g.: `NSCursor.currentSystem == NSCursor.arrow`.

But this doesn't work, because of a key detail. The return value of
`NSCursor.currentSystem` is:

> A cursor whose image and hot spot match those of the
> currently-displayed cursor on the system.

This is important, because while the hot spot and image data will indeed
match that of the current cursor, the implicit part is that the
_reference_ of that `NSCursor` object will differ.

Actually, every time I access `NSCursor.currentSystem` I get a different
`NSCursor` reference:

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    print("currentSystem", NSCursor.currentSystem!)
    print("currentSystem", NSCursor.currentSystem!)
    print("currentSystem", NSCursor.currentSystem!)
    print("arrow", NSCursor.arrow)
    print("arrow", NSCursor.arrow)
    print("arrow", NSCursor.arrow)
    print("iBeam", NSCursor.iBeam)
    print("iBeam", NSCursor.iBeam)
    print("iBeam", NSCursor.iBeam)
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.run()
```

<div class="note">

**Note:** to run this, put it in a file e.g. `test.swift` and run with
`swift test.swift`.

Or [at the time of writing](https://github.com/apple/swift/issues/68785#issuecomment-1904624571):

```sh
DYLD_FRAMEWORK_PATH=/System/Library/Frameworks /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test.swift
```

Otherwise it currently fails with:

```
JIT session error: Symbols not found: [ _OBJC_CLASS_$_NSCursor, _OBJC_CLASS_$_NSApplication ]
```

</div>

```
currentSystem <NSCursor: 0x600003f001b0>
currentSystem <NSCursor: 0x600003f04a20>
currentSystem <NSCursor: 0x600003f7f1e0>
arrow <NSCursor: 0x600003f7cab0>
arrow <NSCursor: 0x600003f7cab0>
arrow <NSCursor: 0x600003f7cab0>
iBeam <NSCursor: 0x600003f7cb40>
iBeam <NSCursor: 0x600003f7cb40>
iBeam <NSCursor: 0x600003f7cb40>
```

We can see the `currentSystem` cursor is a different object reference
every time it's accessed, while `arrow` and `iBeam` are constant.

So we can't identify the system cursor by comparing references. Bummer.

## Going creative

Well if we can't compare references, then we need to do with whatever it
is that we have: a hot spot point and pixel data.

Actually, we can probably get away with just the pixel data: since
conveniently the
[`Data`](https://developer.apple.com/documentation/foundation/data) type
is already
[`Hashable`](https://developer.apple.com/documentation/swift/hashable),
we can simply stuff all the known cursors image data in a dictionary,
and try and identify the `currentSystem` cursor that way:

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    let cursors: [String: NSCursor] = [
      "arrow": .arrow,
      "iBeam": .iBeam,
      "crosshair": .crosshair,
      "closedHand": .closedHand,
      "openHand": .openHand,
      "pointingHand": .pointingHand,
      "resizeLeft": .resizeLeft,
      "resizeRight": .resizeRight,
      "resizeLeftRight": .resizeLeftRight,
      "resizeUp": .resizeUp,
      "resizeDown": .resizeDown,
      "resizeUpDown": .resizeUpDown,
      "disappearingItem": .disappearingItem,
      "iBeamCursorForVerticalLayout": .iBeamCursorForVerticalLayout,
      "operationNotAllowed": .operationNotAllowed,
      "dragLink": .dragLink,
      "dragCopy": .dragCopy,
      "contextualMenu": .contextualMenu,
    ]

    var index: [Data: String] = [:]

    for (name, cursor) in cursors {
      if let image = cursor.image.tiffRepresentation {
        index[image] = name
      }
    }

    Timer.scheduledTimer(
      withTimeInterval: 1, repeats: true,
      block: { _ in
        if let cursor = index[NSCursor.currentSystem?.image.tiffRepresentation ?? Data()] {
          print(cursor)
        } else {
          print("Not found")
        }
      })
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.run()
```

In my experience, this does great at identifying `arrow`, `pointingHand`
and `iBeam`. I don't see the other default cursors used that much at
all.

And then other macOS UI elements use cursors that are not exposed
through `NSCursor`. The crosshair from the native screen capture tool is
not the same as `NSCursor.crosshair`, and the camera from the window
selection of that same tool is not exposed either. As for window
resizing cursors, they're different from the ones exposed in
`NSCursor.resize*`.

Either way, this get the job done the vast majority of the time!

We can go a step further by hooking this up to a
[`mouseMoved`](https://developer.apple.com/documentation/appkit/nsresponder/1525114-mousemoved)
event:

```swift
NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
  if let cursor = index[NSCursor.currentSystem?.image.tiffRepresentation ?? Data()] {
    print(cursor)
  } else {
    print("Not found")
  }
}
```

This works quite well, but hashing the `currentSystem` cursor image data
on every mouse moved event (they can happen at quite a high rate) sounds
a bit aggressive.

If I was gonna use that code, I would probably debounce the events to
every 200 ms or so prior to resolving the cursor to avoid spending that
much CPU cycles computing hashes of the same image that just happens to
have a different `NSCursor` object reference. This will introduce a bit
of inaccuracy around cursor transitions but depending on your
application, this may or may not be a problem.

## Aggressive optimizing

The above to work quite well, but even though I didn't bother
benchmarking it, the mechanism of it makes me slightly uneasy about the
performance (although the debounce would help a lot).

However, if we take a step back, we can use a different approach that is
much easier from a computing perspective.

We noticed that in most cases, the only 3 cursors we'll run into are
arrow, pointing hand and I-beam. Luckily, they all have a different TIFF
image size!

```swift
print("arrow", NSCursor.arrow.image.tiffRepresentation!.count)
print("pointingHand", NSCursor.pointingHand.image.tiffRepresentation!.count)
print("iBeam", NSCursor.iBeam.image.tiffRepresentation!.count)
```

```
arrow 204152
pointingHand 20892
iBeam 85056
```

<div class="note">

**Note:** I say luckily, because many of the standard cursors actually
have the same image byte size, as seen here:

```
11932 crosshair
11932 resizeDown
11932 resizeLeft
11932 resizeLeftRight
11932 resizeRight
11932 resizeUp
11932 resizeUpDown
204152 arrow
20892 closedHand
20892 openHand
20892 pointingHand
22812 contextualMenu
22812 disappearingItem
22812 dragCopy
22812 operationNotAllowed
6172 iBeamCursorForVerticalLayout
7132 dragLink
85056 iBeam
```

In fact, `arrow` and `iBeam` are unique in that aspect! So all we have
to be fine with is `closedHand` and `openHand` being mistaken for
`pointingHand`, which is probably fine, especially `openHand` and
`closeHand` are seldom if ever used.

</div>

We can then simplify the earlier example to:

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    let cursors: [String: NSCursor] = [
      "arrow": .arrow,
      "iBeam": .iBeam,
      "pointingHand": .pointingHand,
    ]

    var index: [Int: String] = [:]

    for (name, cursor) in cursors {
      if let image = cursor.image.tiffRepresentation {
        index[image.count] = name
      }
    }

    NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
      if let cursor = index[NSCursor.currentSystem?.image.tiffRepresentation?.count ?? 0] {
        print(cursor)
      } else {
        print("Not found")
      }
    }
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.run()
```
