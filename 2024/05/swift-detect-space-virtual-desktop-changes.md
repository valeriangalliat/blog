# Swift: detect space (virtual desktop) changes
May 3, 2024

In a macOS app, you can
[get an event](https://stackoverflow.com/a/56435288/4324668)
when [the active space changes](https://stackoverflow.com/a/73548661/4324668).
This happens e.g. if you have multiple virtual desktops, or full screen
windows, and you swap between "spaces", using the 3 fingers swipe on the
trackpad, or the <kbd>Ctrl</kbd> + <kbd>Left</kbd> and <kbd>Right</kbd>
shortcuts.

```swift
class MyObserver {
  init() {
    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil,
      queue: nil,
      using: self.spaceDidChange
    )
  }

  func spaceDidChange(_ notification: Notification) {
    print("Desktop (space) changed")
  }
}
```

Looks like there's an alternative way to call it:

```swift

class MyObserver {
  init() {
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(self.spaceDidChange),
      name: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil
    )
  }

  func spaceDidChange(_ notification: Notification) {
    print("Desktop (space) changed")
  }
}
```

Whatever works for you!
