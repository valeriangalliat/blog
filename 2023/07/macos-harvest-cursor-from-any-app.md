---
tweet: https://x.com/valeriangalliat/status/1684688732694130688
---

# macOS harvest cursor from any app 😏
July 27, 2023

As a pet project I was building a [screenshot app](https://github.com/valeriangalliat/retina-screenshot),
and I wanted its cursors to match the ones of macOS screenshot utility:
<img class="fit-line-height" alt="Crosshair" srcset="../../img/2023/07/macos-cursors/crosshair.png 2x">
and <img class="fit-line-height" alt="Camera" srcset="../../img/2023/07/macos-cursors/camera.png 2x">.

This was harder than expected. I'll tell you the whole story because I
find it fun and interesting, but feel free to jump straight to [the solution](#harvesting-the-cursor-programmatically).

## Default system cursors in `NSCursor`

In a Mac app, the `NSCursor` class [exposes a number of default cursors](https://developer.apple.com/documentation/appkit/nscursor),
like the arrow <img class="fit-line-height" alt="Arrow" srcset="../../img/2023/07/macos-cursors/nscursor/arrow.png 2x">,
I-beam <img class="fit-line-height" alt="I-beam" srcset="../../img/2023/07/macos-cursors/nscursor/i-beam.png 2x">,
pointing hand <img class="fit-line-height" alt="Pointing hand" srcset="../../img/2023/07/macos-cursors/nscursor/pointing-hand.png 2x">,
various resize cursors, and even a cute "disappearing item" cursor <img class="fit-line-height" alt="Disappearing item" srcset="../../img/2023/07/macos-cursors/nscursor/disappearing-item.png 2x">
(that I kinda want to name "poof" for some reason).

There is also a crosshair cursor <img class="fit-line-height" alt="Crosshair" srcset="../../img/2023/07/macos-cursors/nscursor/crosshair.png 2x">,
however it's not the same that the system screenshot utility uses. And
the camera cursor is nowhere to be found.

So our last resort is to set a custom cursor from an image, e.g. for a
cursor that's 32x32 pixels where we want the "hot spot" to be in the
middle:

```swift
let image = NSImage(named: "cursor.png")
let hotSpot = NSPoint(x: 16, y: 16)
let cursor = NSCursor(image: image, hotSpot: hotSpot)
```

But what image do we use here?

## macOS default cursors source location?

By doing a bit of digging in the `/System` directory, we find the
following path:

```
/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Resources/cursors
```

This seems to contain all the system cursors, one directory for each,
containing a `cursor.pdf` and `info.plist`!

Here, we effectively have `screenshotselection` that matches the
screen capture utility's crosshair, and `screenshotwindow` that matches
the camera cursor shown during window selection. Neat.

Parsing the `info.plist`, we find the hot spot coordinates:

```console
$ plutil -p /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Resources/cursors/screenshotselection/info.plist
{
  "hotx" => 15
  "hotx-scaled" => 15
  "hoty" => 15
  "hoty-scaled" => 15
}
```

We can now load those programmatically:

```swift
func loadCursor(_ name: String) -> NSCursor? {
  let root =
    "/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Resources/cursors"

  guard let data = FileManager.default.contents(atPath: "\(root)/\(name)/info.plist")
  else {
    return nil
  }

  guard
    let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
      as? [String: Any]
  else {
    return nil
  }

  guard let pdfData = try? Data(contentsOf: URL(fileURLWithPath: "\(root)/\(name)/cursor.pdf"))
  else {
    return nil
  }

  guard let cursorImage = NSImage(data: pdfData) else {
    return nil
  }

  let hotSpot = NSPoint(
    x: plist["hotx"] as! Int? ?? Int(cursorImage.size.width) / 2,
    y: plist["hoty"] as! Int? ?? Int(cursorImage.size.height) / 2
  )

  return NSCursor(image: cursorImage, hotSpot: hotSpot)
}
```

Let's use this function in a basic example to demonstrate it:

```swift
import Cocoa

let app = NSApplication.shared

if let cursor = loadCursor("screenshotselection") {
  DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    cursor.set()
  }
}

app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
```

<div class="note">

**Note:** here we call `cursor.set()` after a delay because it
[doesn't](https://stackoverflow.com/a/39905020)
[always](https://stackoverflow.com/a/13848213) work when called right
away for reasons that are not familiar to me.

In a real app, you probably want to subclass `NSView`, override
`resetCursorRects`, and call `addCursorRect` in it.

</div>

This actually looks good for the camera! But for the crosshair, it
doesn't seem to match the original one.


The original crosshair size appears to be 50x50 pixels, while this one
is 46x46. More importantly, the original one has some kind of light outline
that makes it visible on darker backgrounds, that is completely missing
from that cursor PDF we just found. You can see the difference easily:

<table>
  <tr>
    <th>Original</th>
    <th>Custom</th>
  </tr>
  <tr>
    <td><img alt="Original crosshair over grey background" srcset="../../img/2023/07/macos-cursors/hiservices/orig-grey.png 2x"></td>
    <td><img alt="Custom crosshair over grey background" srcset="../../img/2023/07/macos-cursors/hiservices/custom-grey.png 2x"></td>
  </tr>
  <tr>
    <td><img alt="Original crosshair over dark background" srcset="../../img/2023/07/macos-cursors/hiservices/orig-dark.png 2x"></td>
    <td><img alt="Custom crosshair over dark background" srcset="../../img/2023/07/macos-cursors/hiservices/custom-dark.png 2x"></td>
  </tr>
</table>

So the screen capture utility doesn't seem to be using this cursor from
`HIServices.framework`.

I tried exploring the contents of the screen capture app in
`/System/Library/CoreServices/screencaptureui.app`, especially the
`Contents/Resources/Assets.car` file, exploring it using
[Asset Catalog Tinkerer](https://github.com/insidegui/AssetCatalogTinkerer),
but it didn't contain anything useful.

## Harvesting the cursor programmatically

The next idea I tried was to see if I could somehow access the cursor
data from _other_ apps from my Swift app.

It turns out `NSCursor` exposes a [`currentSystem`](https://developer.apple.com/documentation/appkit/nscursor/1533611-currentsystem)
property, containing current system cursor (as opposed to
`NSCursor.current` that contains your own application's current cursor).

This way we can easily access the image data of the `currentSystem`
cursor, as well as its `hotSpot` to be used later in our own custom
cursor.

```swift
import Cocoa

let cursor = NSCursor.currentSystem!

print(cursor.hotSpot)

let image = cursor.image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
let bitmap = NSBitmapImageRep(cgImage: image)
let data = bitmap.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: "cursor.png"))
```

We can put this code in a file `test.swift`, and run it with `sleep 5 && swift test.swift`.
This gives us 5 seconds to do whatever is needed to show the cursor we
want to harvest, before our script actually runs and saves the current
system cursor to a PNG file.

In the case of the screen capture utility crosshair, I've got this
(pictured over transparent, grey and dark background to show how well it
reacts to those):

<table>
  <tr>
    <td><img alt="Harvested crosshair" srcset="../../img/2023/07/macos-cursors/crosshair-raw.png 2x"></td>
    <td style="background-color: #3f3f40"><img alt="Harvested crosshair over grey background" srcset="../../img/2023/07/macos-cursors/crosshair-raw.png 2x"></td>
    <td style="background-color: #111111"><img alt="Harvested crosshair over dark background" srcset="../../img/2023/07/macos-cursors/crosshair-raw.png 2x"></td>
  </tr>
</table>

Perfect. 👌

I didn't want to get into adding support for showing the dynamic
coordinates as part of the cursor, so as far as I'm concerned, I got rid
of those and used just the crosshair in my app.

## Wrapping up

I hope you found this post useful! Now if you want to get the cursor
data from any app, in its original transparent quality, you can use the
simple script above to do so. Enjoy!
