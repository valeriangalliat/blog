---
tweet: https://twitter.com/valeriangalliat/status/1442937054854221828
---

# TOTP/2FA support with ANY password manager (you read that right)
September 28, 2021

As I'm writing an article on [how I reversed the Authy proprietary 2FA protocol](authy-reversed.md)
to generate their codes from my own password manager and authenticator,
I realized that I didn't write about the hack I use to **support
<abbr title="Time-based one-time password">TOTP</abbr> in any password
manager** (especially the ones that don't support it out of the box).

So I'll start with that.

See, I explained some time ago [why I switched to Firefox Lockwise as my password manager](../08/why-i-switched-to-firefox-lockwise-as-my-password-manager.md).
In this post, I compare it to Bitwarden, and I go through some of the
[Lockwise cons](../08/why-i-switched-to-firefox-lockwise-as-my-password-manager.html#cons),
one of them being [the lack of TOTP support](../08/why-i-switched-to-firefox-lockwise-as-my-password-manager.html#no-totp-support).

I said that while it would be nice to have native support for TOTP, I
already had my own authenticator app based on the [totp-generator](https://www.npmjs.com/package/totp-generator)
package. I since made that app a lot nicer and shared it on
[totp.vercel.app](https://totp.vercel.app/)! 🦄

It's called [TOTP with a password manager that doesn't support TOTP 😅](https://totp.vercel.app/)
(yes, the emoji is part of the name) because I suck at naming things and
that's the most explicit name that I came up with.

<div class="note">

**Note:** everything you need to know in order to use it is on the link
above, but if you want to learn how it works in more technical details,
keep reading!

</div>

## Why would you do that?

Maybe like me you really like Lockwise or another password manager
that doesn't support TOTP, and that's not enough of a reason to migrate
to another app like Bitwarden, especially where TOTP support only comes
in the paid version.

And you don't want to install Yet Another App(tm) to do this.

Maybe a bit of a niche, I'll admit.

## How does it work?

First things first, you probably want to [check out the repo on GitHub](https://github.com/valeriangalliat/totp).

The principle is pretty simple. Most password managers will recognize
login forms on websites (e.g. username and password fields). Upon
submission, they'll prompt you to save the credentials you just entered,
so that the next time you encounter this form, it'll be able to autofill
the boxes and you just have to click "log in".

Additionally, if you log in later with a different username on the same
site, it'll also ask you to save it, and now every time you come back to
that form, you'll be able to chose amongst all the credentials that you
saved.

[TOTP with a password manager that doesn't support TOTP 😅](https://totp.vercel.app/)
looks like a login form, walks like a login form, and quacks like a
login form:

```html
<input type="text" name="username">
<input type="password" name="password">
```

(Yes, it's that easy.)

This means that whatever you put in there, your password manager will
prompt you to store upon submission of the form. With that trick, **we
can store arbitrary data in any password manager**.

To retrieve that data, the user simply clicks on the username or
password field and chose from the list of all the saved items. We can
then read the values directly from the form fields. For example if the
above HTML was in a `<form id="form">`:

```js
const { username, password } = form.elements
console.log(username.value, password.value)
```

Since [it's a bit tricky](https://stackoverflow.com/questions/11708092/detecting-browser-autofill)
to reliably detect when inputs are autofilled (the `change` event is not
usually triggered), we'll use a Big Blue Button(tm) that reads "Get
TOTP 🚀" instead. Good enough.

<figure class="center">
  <img alt="TOTP form" src="../../img/2021/09/totp-form-1.png">
</figure>

When that button is clicked, we use [totp-generator](https://www.npmjs.com/package/totp-generator)
to generate a code for the secret that's in the password field.

If the TOTP settings differ from the standard SHA-1 algorithm, 6 digits
and 30 seconds period, you can also paste a somewhat standard
[`otpauth://` URI](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)
thanks to the following code:

```js
const totp = require('totp-generator')

function totpFromUriOrSecret (value) {
  if (!value.startsWith('otpauth://')) {
    // Directly the secret, use default options.
    return totp(value)
  }

  const search = new URLSearchParams(new URL(value).search)
  const { secret, algorithm, digits, period } = Object.fromEntries(search)

  return totp(secret, { algorithm, digits, period })
}
```

For convenience, we can automatically copy the code to the user's clipboard:

```js
navigator.clipboard.writeText(code)
```

## Scanning QR codes

But that's not enough. While some services will give us an option to
retrieve the plaintext secret or a `otpauth://` URI, a lot will only
give a QR code to scan, and some will even give *nothing* and force you
to use Authy's proprietary TOTP implementation (luckily, I already
[reversed that](authy-reversed.md) so that you don't have to).

For that, I'll add two options: scan a QR code using the device camera,
or import a QR code from an existing image (like a screenshot).

<figure class="center">
  <img alt="TOTP form" src="../../img/2021/09/totp-form-2.png">
</figure>

Luckily, there's a [QR scanner](https://www.npmjs.com/package/qr-scanner)
package that makes that really easy.

### Using the camera

```js
const QrScanner = require('qr-scanner')

function handleTotpUri (uri) {
  const search = new URLSearchParams(new URL(uri).search)

  form.username.value = search.get('issuer')
  form.password.value = uri
}

const video = document.querySelector('video')

const qrScanner = new QrScanner(video, result => {
  qrScanner.stop()
  handleTotpUri(result)
})

qrScanner.start()
```

During the scan, the QR scanner will show the camera feed in the given
video element.

On successful scan, we parse the URI to get the `issuer` value (the
service that issued that secret) and fill the username field with it to
give a meaningful name to our secret. Then we can store the full URI in
the password field.

### From file upload

We'll support two ways to upload files. With a regular file input, and
with drag and drop.

For the file input, the following will do:

```html
<input type="file" name="file">
```

```js
const { file } = form.elements

file.addEventListener('change', () => {
  handleFile(file.files[0])
})
```

And for the drag and drop, the
[drag-drop](https://www.npmjs.com/package/drag-drop) package makes it
trivial for us:

```js
const dragDrop = require('drag-drop')

dragDrop('body', {
  onDrop (files) {
    handleFile(files[0])
  },
  onDragEnter (event) {
    document.body.classList.add('drag-drop')
  },
  onDragLeave (event) {
    document.body.classList.remove('drag-drop')
  }
})
```

Here we toggle a class on the `<body>` element during drag and drop to
make it obvious that we're accepting files to be dropped here.

Now, all we need is to write the `handleFile` function that's used by
both of those, where we scan the uploaded file and parse the TOTP URI in it.

```js
function handleFile (file) {
  QrScanner.scanImage(file)
    .then(result => {
      handleTotpUri(result)
    })
}
```

## Manually editing TOTP settings

Lastly, we might encounter situations where we only have the secret and
specific TOTP settings (algorithm, digits and period), but no TOTP URI.

To support that, we need to add an "advanced" mode allowing to edit the
individual settings, and automatically generating the proper URI in the
password field to be stored.

We'll start by adding a hamburger menu that will open the detailed
settings.

<figure class="center">
  <img alt="TOTP form" src="../../img/2021/09/totp-form-3.png">
</figure>

This will toggle the following form:

<figure class="center">
  <img alt="TOTP form" src="../../img/2021/09/totp-details-form.png">
</figure>

Here, I added for convenience a "Authy" button that will automatically
set the settings to 7 digits and a 10 seconds period, because that's the
main use case I have for this.

When any of those settings change, I generate a new URI to put in the
password field:

```js
const { username, password, secret, algorithm, digits, period } = form.elements

function updatePasswordFromDetails () {
  const uri = new URL(password.value.startsWith('otpauth://') ? password.value : `otpauth://totp/${encodeURIComponent(username.value)}`)
  const search = new URLSearchParams(uri.search)

  search.set('secret', secret.value)
  search.set('algorithm', algorithm.value)
  search.set('digits', digits.value)
  search.set('period', period.value)

  uri.search = search
  password.value = uri.toString()
}

secret.addEventListener('change', updatePasswordFromDetails)
algorithm.addEventListener('change', updatePasswordFromDetails)
digits.addEventListener('change', updatePasswordFromDetails)
period.addEventListener('change', updatePasswordFromDetails)
```

## Conclusion

And this is it! You know everything that's behind [totp.vercel.app](https://totp.vercel.app/).

Did you find this useful? Did you like that I explained some of the code
behind it in this blog post? Don't hesitate to let me know and [ping me on Twitter](https://twitter.com/valeriangalliat)!

Until next time, keep hacking! 🐿
