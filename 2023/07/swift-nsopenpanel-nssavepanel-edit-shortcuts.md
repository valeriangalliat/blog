# Swift: support cut/copy/paste shortcuts in a `NSOpenPanel` and `NSSavePanel`
July 27, 2023

Let's consider this basic Swift app that simply shows an `NSSavePanel`:

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    let app = NSApplication.shared
    app.activate(ignoringOtherApps: true)

    let savePanel = NSSavePanel()
    savePanel.runModal()
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()

app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
```

This shows a generic open panel as expected:

<figure class="center">
  <img alt="Open panel" srcset="../../img/2023/07/open-panel.png 2x">
</figure>

However we have a problem: we can't cut, copy or paste in of the text
fields (**Save As**, **Tags**, **Search**). We can't <kbd>Command</kbd>
\+ <kbd>X</kbd>, <kbd>C</kbd> or <kbd>V</kbd>. All those shortcuts do is
playing an annoying _beep_ noise telling us we can't do that.

**This is because on macOS, those shortcuts are actually tied to menu
items.** You can't have <kbd>Command</kbd> + <kbd>C</kbd> work unless
you have a matching menu item, typically **Edit > Copy**.

## Adding an edit menu

To solve this, we're gonna add an edit menu tour app with the proper
shortcuts.

```swift
let mainMenu = NSMenu()
app.mainMenu = mainMenu

let appMenu = NSMenuItem()
mainMenu.addItem(appMenu)

let editMenu = NSMenuItem()
mainMenu.addItem(editMenu)

let editSubmenu = NSMenu(title: "Edit")
editMenu.submenu = editSubmenu

editSubmenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
editSubmenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
editSubmenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")

editSubmenu.addItem(
  withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
```

We now have a nice edit menu:

<figure class="center">
  <img alt="Edit menu" srcset="../../img/2023/07/edit-menu.png 2x">
</figure>

Here, we leverage _automatic menu enabling_ in the `action` in order to map
menu items and shortcuts to the first object in the responder chain that
implements the given action, as explained in [this Stack Overflow post](https://stackoverflow.com/a/47577869).

This is pretty neat, and thanks to this feature, we now have working
cut/copy/paste in our dialog!

As a bonus, it would be a good practice to also add a way to quit our
app using the same method:

```swift
let appSubmenu = NSMenu()
appMenusubmenu = appSubmenu

appSubmenu.addItem(
  withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
```
