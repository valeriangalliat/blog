# GitHub Action hanging on Electron macOS app code signing
June 22, 2025

There's quite a bunch of resources about how to set up macOS app code
signing on GitHub Actions:

* [Signing Electron apps with GitHub Actions](https://dev.to/rwwagner90/signing-electron-apps-with-github-actions-4cof)
* [Installing an Apple certificate on macOS runners for Xcode development](https://docs.github.com/en/actions/use-cases-and-examples/deploying/installing-an-apple-certificate-on-macos-runners-for-xcode-development)
* [Setting up hosted macOS GitHub Actions workflows for Electron
  builds](https://brunoscheufler.com/blog/2023-11-12-setting-up-hosted-macos-github-actions-workflows-for-electron-builds)

But what to do if your GitHub workflow just hangs forever at the
Electron signing step?

This appears to be a symptom of not properly configuring the macOS
Keychain in the CI environment. Sadly there could be a bunch of reasons
for that and the hanging doesn't really tell us which one specifically
is a problem.

There's [two](https://github.com/electron/forge/issues/3315)
[issues](https://github.com/electron/packager/issues/701) I found with
that hanging problem, and the solutions there may or may not solve the
problem for you.

What I'm gonna suggest though is really double checking the code you're
using to import the signing keys based on all the links I shared above,
and see if you're missing something.

If it can help, here's the code that ended up working for me:

```yaml
name: Release

on:
  push:
    branches:
      - main

jobs:
  release:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - uses: swift-actions/setup-swift@v2

      - name: Import certificate
        env:
          PRIVATE_KEY: ${{ secrets.PRIVATE_KEY }}
          PRIVATE_KEY_PASSWORD: ${{ secrets.PRIVATE_KEY_PASSWORD }}
          CERTIFICATE: ${{ secrets.CERTIFICATE }}
        run: |
          # Create a temporary keychain
          security create-keychain -p "" build.keychain

          # Set it as default for the user session
          security default-keychain -s build.keychain

          security unlock-keychain -p "" build.keychain

          # Set it to lock in 1 hour (should be long enough, and probs longer than the macOS default that could be too short)
          security set-keychain-settings -t 3600 -l ~/Library/Keychains/build.keychain

          mkdir -p ~/certificates
          cd ~/certificates

          echo "$PRIVATE_KEY" | base64 --decode > "My App.p12"
          echo "CERTIFICATE" | base64 --decode > "My App.cer"

          security import "My App.p12" -k build.keychain -P "$PRIVATE_KEY_PASSWORD" -T /usr/bin/codesign
          security import "My App.cer" -k build.keychain -T /usr/bin/codesign

          # Check certificates
          security find-identity -v -p codesigning build.keychain

          # Add keychain to search list
          security list-keychains -d user -s build.keychain
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "" build.keychain

      # ...
```

Here, `PRIVATE_KEY` is a Base64-encoded version of the `.p12` private
key, password protected by `PRIVATE_KEY_PASSWORD`.

`CERTIFICATE` is a Base64-encoded version of the `.cer` file that Apple
provided for your application.

Hope that helps!
