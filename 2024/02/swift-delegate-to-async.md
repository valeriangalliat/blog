---
tweet: https://x.com/valeriangalliat/status/1790906284444913979
---

# Swift: convert a delegate to async
February 4, 2024

Let's say we're using
[AVFoundation](https://developer.apple.com/documentation/avfoundation)
to do a screen capture in Swift. We want to response to
`didStartRecordingTo` and `didFinishRecordingTo` "events", which is done
through the use of a delegate such as:

```swift
class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
  func fileOutput(_: AVCaptureFileOutput, didStartRecordingTo _: URL, from _: [AVCaptureConnection])
  {
    // Stuff
  }

  func fileOutput(
    _: AVCaptureFileOutput, didFinishRecordingTo _: URL, from _: [AVCaptureConnection],
    error: Error?
  ) {
    // Stuff
  }
}

let session = AVCaptureSession()
let input = AVCaptureScreenInput()
let output = AVCaptureMovieFileOutput()
let delegate = RecordingDelegate()

session.addInput(input)
session.addOutput(output)
session.startRunning()
output.startRecording(to: URL(filePath: "test.mov"), recordingDelegate: delegate)
```

That's all good but the delegate makes my life a bit harder in terms of
managing the control flow of the code.

I would much rather something using async/await, e.g. (hypothetical code):

```swift
let events = output.startRecording(to: URL(filePath: "test.mov"))

await events.didStartRecording

// Do stuff now the recording has started

output.stopRecording()

await events.didFinishRecording

// Do stuff now the recording is finished
```

In order to achieve that, we need a bit of plumbing code. Let's add
callbacks to our delegate:

```swift
class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
  var didStartRecording: () -> Void = {}
  var didFinishRecording: (_ error: Error?) -> Void = { _ in }

  func fileOutput(_: AVCaptureFileOutput, didStartRecordingTo _: URL, from _: [AVCaptureConnection])
  {
    self.didStartRecording()
  }

  func fileOutput(
    _: AVCaptureFileOutput, didFinishRecordingTo _: URL, from _: [AVCaptureConnection],
    error: Error?
  ) {
    self.didFinishRecording(error)
  }
}
```

From there, we can use the [`withCheckedContinuation`](https://developer.apple.com/documentation/swift/withcheckedcontinuation(function:_:))
function to convert a callback to an async result:

```swift
let delegate = RecordingDelegate()

async let didStartRecording: () = withCheckedContinuation { continuation in
  delegate.didStartRecording = {
    continuation.resume()
  }
}

async let didFinishRecording: () = withCheckedContinuation { continuation in
  delegate.didFinishRecording = { error in
    if let error = error {
      continuation.resume(throwing: error)
    } else {
      continuation.resume()
    }
  }
}

output.startRecording(to: URL(filePath: "test.mov"), recordingDelegate: delegate)

await didStartRecording

// Do stuff now the recording has started

output.stopRecording()

await didFinishRecording

// Do stuff now the recording is finished
```

Thanks to `withCheckedContinuation`, we can get an async result for the
`didStartRecording` and `didFinishRecording` events, that we're free to
`await` whenever is most convenient!

<div class="note">

**Note:** the code above is not perfect. In some cases, we may get an
event on `didFinishRecordingTo` with an error, before
`didStartRecordingTo` was called at all. In that case, that example
would just hang forever.

</div>
