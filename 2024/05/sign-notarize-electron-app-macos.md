---
tweet: https://x.com/valeriangalliat/status/1790906279852204042
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

<div class="note">

**Note:** if it refuses to open with "The System Roots keychain cannot
be modified", it's because Keychain Access opens by default in the
System Roots keychain and you can only update it as superuser (so mainly
from the CLI with `sudo security ...`).

We only need this certificate in the login keychain, so make sure it's
the selected one in Keychain Access and then open the certificate again.

</div>

## Get the intermediate certificate

In Apple's <abbr title="Public key infrastructure">[PKI](https://www.apple.com/certificateauthority/)</abbr>,
your developer certificate is signed by an intermediate certificate,
that's itself signed by one of Apple's root certificates.

The Apple root certificates should already be present out of the box in
your System Roots keychain, but the intermediate ones are not, and need
to be downloaded for the certificate chain to be complete and for
`codesign` to work.

When you created your Developer ID certificate, you were likely prompted
between "G2 Sub-CA" and "Previous Sub-CA". At the time of writing, on the
[Apple PKI page](https://www.apple.com/certificateauthority/),
those are respectively [Developer ID - G2 (Expiring 09/17/2031 00:00:00 UTC)](https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer)
and [Developer ID - G1 (Expiring 02/01/2027 22:12:15 UTC)](https://www.apple.com/certificateauthority/DeveloperIDCA.cer).
So go ahead and download the appropriate one and install it to your
login keychain just like your developer certificate.

<div class="note">

**Note:** if you don't know what intermediate certificate you need, you
can see what <abbr title="Certificate authorith">CA</abbr> signed your
certificate like so:

```console
$ openssl x509 -in "developerID_application.cer" -noout -issuer
issuer=CN=Developer ID Certification Authority, OU=G2, O=Apple Inc., C=US
```

In this case, you can see my certificate was issued using the G2
intermediate certificate.

</div>

<div class="note warn">

**Warning:** [leave the certificate trust settings](https://developer.apple.com/forums/thread/86161?answerId=422698022#422698022)
to "Use System Defaults" and do not mark it as "Always Trust", both for
your developer certificate and the intermediate certificate.

If like me you were getting issues signing things and assumed marking as
"Always Trust" could help, beware, it does the opposite and prevents
`codesign` from working altogether for some reason, even after you fix
the actual cause of your signing issues. 😅

Whether you're missing a certificate, or if you have the right
certificates but they're marked as "Always Trust", you'll get that same
error:

```
Warning: unable to build chain to self-signed root for signer
```

</div>


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
