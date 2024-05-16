---
tweet: https://twitter.com/valeriangalliat/status/1790906279852204042
---

# How to sign and notarize an Electron app for macOS
May 15, 2024

So you made a macOS app, shared it with your friends, and they
encountered one of those dreaded popups:

<figure class="grid">
  <img alt="App cannot be opened because it is from an unidentified developer" srcset="../../img/2024/05/electron-signature/unidentified-developer.png 2x">
  <img alt="App can't be opened because Apple cannot check it for malicious software" srcset="../../img/2024/05/electron-signature/cannot-check.png 2x">
</figure>

Then you need to sign (left) and notarize (right) your app!

<div class="note">

**Note:** in the meantime, the app
[can still](https://support.apple.com/en-ca/guide/mac-help/mh40616/mac)
[be opened](https://support.apple.com/en-ca/guide/mac-help/mchleab3a043/mac)
by right clicking on it and clicking **Open** from the context menu.

</div>

Signing consists in buying a developer membership with Apple, which will
let you create a key that you can use to `codesign` your app with.

Notarizing consists in uploading your app to an Apple service that scans
it for malware. If it passes the process, your app gets a "stamp of
approval" that is [bundled with your app and also mirrored](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
on Apple's Gatekeeper servers.

In the case of Electron, here's some relevant docs this article is based
on:

* [Electron: Signing & notarizing macOS builds](https://www.electronjs.org/docs/latest/tutorial/code-signing#signing--notarizing-macos-builds)
* [Electron Forge: Signing a macOS app](https://www.electronforge.io/guides/code-signing/code-signing-macos)

## Get a signing certificate

The first step is to generate a signing keypair, and get a signing
certificate from Apple, which requires you to subscribe to
[Apple's developer program](https://developer.apple.com/).

Then, follow [create a certificate signing request](https://developer.apple.com/help/account/create-certificates/create-a-certificate-signing-request).

In my experience, it doesn't seem that the **User Email Address** you
input matters.

As for **Common Name**, it seems to only affect how the private and
public key are named in Keychain Access.

By saving the request to disk, you will get a
`CertificateSigningRequest.certSigningRequest` file.

This will also create a `Common Name.p12` and `Common Name.pem` entry in
your Keychain Access. The `.p12` is the private key, and the `.pem` is
the public key, that are going to be associated with the certificate
you're requesting.

You should now upload the `.certSigningRequest` file to your Apple
Developer account, in **Certificates, IDs & Profiles**. Choose the
**Developer ID Application** certificate type.

This will give you a certificate `developerID_application.cer` that you
need to import in Keychain Access (by simply opening it).

## Get the intermediate certificates

I don't fully understand this part, but the above is not enough to sign
your app. You also need some extra root and/or intermediate certificates
to be present in your Keychain Access, but it's not exactly clear which
ones or where to get them.

What I know is that by using Xcode and messing with their certificate
management settings, it downloads the extra stuff that is needed for
code signing to work.

So:

1. Install Xcode.
1. In **Xcode > Settings... > Accounts**, add your Apple account.
1. Click **Download Manual Profiles**.
1. Click **Manage Certificates** and request a new **Apple Development**
   certificate that you can delete right after.

Executing part or all of those steps may download the extra certificates
you need in Keychain Access. It's not 100% clear to me what did it for
me. 😅 Don't hesitate to [let me know](/val.md#contact) if you have more
details on this!

## Manually sign your app

You're now in a place where you can manually sign your app:

```sh
codesign --sign 'Developer ID Application: MyApp (ID)' MyApp.app
```

To find the identify to pass to `--sign`:

```sh
security find-identity -v -p codesigning
```

`-v` will show only valid identities. `-p` is for selecting a specific
policy, here we care about `codesigning`.

## Signing your app with Electron Forge

Add `osxSign` to your `forge.config.js`:

```js
module.exports = {
  packagerConfig: {
    osxSign: {
      identity: 'Developer ID Application: MyApp (ID)'
    }
  }
}
```

If you only have one valid code signing identity configured on your Mac,
you can omit the `identity` parameter. You still need to pass an empty
object `osxSign: {}`.

## Notarizing your app with Electron Forge

Add `osxNotarize` to your `forge.config.js`. There's a few ways to
configure it [documented here](https://www.electronforge.io/guides/code-signing/code-signing-macos#osxnotarize-options).

The documentation is pretty clear and complete so I won't bother
repeating anything here. 🙂

## Debugging `osxSign` and `osxNotarize`

If you encounter issues where Electron is not properly signing or
notarizing your app, you can debug the signing and notarizing process
that way:

```sh
DEBUG=electron-osx-sign,electron-notarize* npx electron-forge package
```

This will output detailed logs that should help you identify the
culprit.

## Conclusion

That should be all you need to have your app approved by Apple so that
you can share it with the world. 🌎

Happy building! 🚀
