# USB iPhone screen recording in Swift
June 22, 2025

When you plug in an iPhone to a Mac via USB, QuickTime allows you to
select the iPhone screen as a video recording source.

This is neat, but what if you want to do do the same thing from your own
app?

I've had to do this recently, so this blog post will compile everything
I learnt about and especially the undocumented quirks I encountered and
worked around.

## `kCMIOHardwarePropertyAllowScreenCaptureDevices`

The very first thing you need is to enable
[`kCMIOHardwarePropertyAllowScreenCaptureDevices`](https://developer.apple.com/documentation/coremediaio/kcmiohardwarepropertyallowscreencapturedevices).

This is a "hardware property" (whatever that means) that, when set,
allows the current process to access USB-connected mobile devices for
screen recording.

You can find
[many](https://gist.github.com/samjoch/d06f7fb39b2cbbca087ddcb1af59b28e)
[flavors](https://nadavrub.wordpress.com/2015/07/06/macos-media-capture-using-coremediaio/)
of how to do this online, and here's mine anyway:

```swift
import CoreMediaIO

// Sets the "hardware" prop that allows to discover USB mobile devices for screen recording.
func allowScreenCaptureDevices() {
  let element: CMIOObjectPropertyElement
  if #available(macOS 12.0, *) {
    element = CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
  } else {
    element = CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
  }

  var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: element)

  var allow: UInt32 = 1
  let dataSize: UInt32 = 4
  let zero: UInt32 = 0

  CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject), &prop, zero, nil, dataSize, &allow)
}
```

This will allow you to discover USB mobile devices as part of your usual
`AVCaptureDevice.DiscoverySession`.

Now while this code uses a relatively verbose low-level old C interface
(because it's the only way to do this right now), it's fairly
straightforward. It's spiritually equivalent to doing
`kCMIOHardwarePropertyAllowScreenCaptureDevices = 1` (no shit).

But this hardware property is not as innocent as it looks, and I'm about
to infodump on you everything I found out about it. Brace yourselves (or
skip to the next section until you encounter weird issues and need to
come back here 😂).

## It's not instant

When you set `kCMIOHardwarePropertyAllowScreenCaptureDevices`, the
effect is not instant, meaning if you do a
`AVCaptureDevice.DiscoverySession` right after, you're basically
guaranteed to _not_ see the connected USB mobile devices.

This is not necessarily a problem. For example if your Swift process is
long-running, you set that prop first thing on boot, but you actually
list the devices later on upon user interaction, everything will be
fine.

However if you're working with a CLI (i.e. `my-cli list-devices`
/ `my-cli record-device <device>`), or simply need access to the
mobile devices immediately upon starting the app, this is not gonna cut
it.

After setting the prop, the devices are gonna take up to a few seconds
to "show up", and you can listen to the `AVCaptureDeviceWasConnected`
notification from the `NotificationCenter` to know about it. There's a
good example for that in [this Gist](https://gist.github.com/samjoch/d06f7fb39b2cbbca087ddcb1af59b28e).

```swift
// See "The get devices warmup side-effect" below for why this is necessary...
let _ = AVCaptureDevice.devices()

NotificationCenter.default
  .addObserver(
    forName: NSNotification.Name.AVCaptureDeviceWasConnected, object: nil, queue: nil
  ) { (notif) -> Void in
    let device = notif.object! as! AVCaptureDevice
    // ...
  }
```

This works, but it also means there's no way to tell immediately that
_no_ device is currently connected. This is a problem if you want
to implement `my-cli list-devices`. Your best option is to time out
after a few seconds, but it's not ideal because of the added delay when
no device is connected...

## The get devices warmup side-effect

This one is super sneaky and I wasted a lot of time on it. It turns out
that if you don't call an API to list the devices, i.e. the deprecated
`AVCaptureDevice.devices`, or now a proper
`AVCaptureDevice.DiscoverySession`, the `AVCaptureDeviceWasConnected`
notification will never arrive.

So you need to start a `DiscoverySession` first, expecting to get 0
devices back (because you just set the hardware prop and its effect is
not instant), just to "warm up" the system, so that it will actually
send the notification.

In the [Gist](https://gist.github.com/samjoch/d06f7fb39b2cbbca087ddcb1af59b28e#file-avcapturedevice-playground-swift-L38)
I linked earlier, the `print("\(AVCaptureDevice.devices().count)")` line
is actually _significant_ and the code will _not_ work without it:

```swift
func start() {
  print("\(AVCaptureDevice.devices().count)")

  NotificationCenter.default
    .addObserver(
      forName: NSNotification.Name.AVCaptureDeviceWasConnected, object: nil, queue: nil
    ) { (notif) -> Void in
      self.iosDeviceAttached(device: notif.object! as! AVCaptureDevice)
    }
}
```

It's not just the innocent debug print that it seems. The fact it calls
`AVCaptureDevice.devices` is what allows to warm up the system and for
the notification to actually be sent later on. Without it, the
notification will _never_ arrive.

I like to make it a bit more explicit with:

```swift
// We don't need the data but this appears to be required to "warm up"
// the system. If we don't make the system call to get devices first,
// we can't discover new devices with `AVCaptureDeviceWasConnected`. 🤷
let _ = AVCaptureDevice.devices()
```

## It's rate limited?

This one also made me pull my hair out for a while. So I start my app
that sets the above hardware prop, listen to device connected
notifications, and can see the iPhone available for screen recording.

Then I iterate on my code, maybe add some logging or write come code to
actually start capturing the video feed, and then restart the app.

And then, not only setting
`kCMIOHardwarePropertyAllowScreenCaptureDevices` takes _a few long
blocking seconds_ to complete, but on top of that I don't ever get any
device connected notification despite the iPhone being plugged in!

It appears to me that setting this prop is somehow rate limited. I would
need to wait around a minute before launching my CLI again in order for
it to behave "normally" (where setting the prop is near-instant, and I
do get a notification for the plugged-in devices).

However, and that's where it gets interesting, I noticed that if any
other process on the computer also sets that same hardware property
(i.e. QuickTime), and that process stays running in the background, then
my CLI would reliably work every single time, even if I launch it many
times in a short time span. So it's like that "rate limit" is really an
issue if my CLI is the _only_ process on the system to set that prop.

So what did I do? I made a `my-cli background` command that literally
only sets the `kCMIOHardwarePropertyAllowScreenCaptureDevices` prop,
then sleeps indefinitely. Ran that in the background, then could do
`my-cli list-devices` and so on as much as I wanted.

Wasn't gonna cut it for me for production, but at least that was useful
during development to allow me to iterate quickly.

## Actual device recording

I won't go in much details here because there's actually no quirks on
that side of things. It's just your typical `AVFoundation` recording
which is very well covered online already.

First we get the external devices via a `DiscoverySession`:

```swift
let devices = AVCaptureDevice.DiscoverySession(
  deviceTypes: [.external],
  // Muxed type seems to be a decent way to distinguish USB connected
  // mobile devices from other external devices like e.g. "OBS Virtual Camera".
  mediaType: .muxed,
  position: .unspecified
).devices
```

This returns a list of `AVCaptureDevice`. Alternatively if we have the
ID of a mobile device already:

```swift
let device = AVCaptureDevice(uniqueID: "...")
```

Then we make an input from that device:

```swift
let deviceInput = try AVCaptureDeviceInput(device: device)
```

And the rest is the usual [`AVCaptureSession` protocol](https://developer.apple.com/documentation/avfoundation/setting-up-a-capture-session).

## Wrapping up

If you encountered any if the quirks above, I hope that it helped you
work around them and hopefully you didn't waste as much time on this as
I did. Happy device recording!
