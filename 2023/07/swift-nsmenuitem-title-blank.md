# Swift: `NSMenuItem` title not showing
July 27, 2023

If for some reason you're making a Swift app and want to
programmatically define your menu items, as opposed to using Xcode's
storyboards to create them visually, you may run into an issue where
your menu title is not showing.

Let's consider the following example (e.g. put it in `test.swift` and
run it with `swift test.swift`):

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    let app = NSApplication.shared
    app.activate(ignoringOtherApps: true)

    let mainMenu = NSMenu()
    app.mainMenu = mainMenu

    let appMenu = NSMenuItem()
    mainMenu.addItem(appMenu)

    let editMenu = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
    mainMenu.addItem(editMenu)

    let editSubmenu = NSMenu()

    editSubmenu.addItem(withTitle: "Test", action: nil, keyEquivalent: "")
    editMenu.submenu = editSubmenu
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()

app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
```

When we run it, the edit menu doesn't show. Or actually, it's there but
its text is blank!

<figure class="center">
  <img alt="Blank edit menu" srcset="../../img/2023/07/swift-edit-blank.png 2x">
</figure>

**This is because the `NSMenuItem` title actually doesn't matter here.**
It's the title of the `NSMenu` that we use as a submenu that matters.

Let's fix it up:

```diff:swift
-let editMenu = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
+let editMenu = NSMenuItem(title: "Doesn't matter", action: nil, keyEquivalent: "")
 mainMenu.addItem(editMenu)

-let editSubmenu = NSMenu()
+let editSubmenu = NSMenu(title: "Edit")
```

And now our title shows up properly!

<figure class="center">
  <img alt="Good edit menu" srcset="../../img/2023/07/swift-edit-good.png 2x">
</figure>

## A note about the app menu

In the example above, note that it was also important to explicitly add
an app menu before our edit menu:

```swift
let appMenu = NSMenuItem()
mainMenu.addItem(appMenu)
```

This is important, because the first item of the main menu is gonna be
treated as the app menu. If we didn't do that, our edit menu would
actually become the app menu, so that **Test** would appear under
**swift-frontend**, and **Edit** would be nowhere to be seen.
