# Authy: reversed 🔐
September 28, 2021

I recently signed up for SendGrid for a new business. It seems like a
nice tool to send my transactional emails.

One thing with SendGrid though is that they enforce 2FA. You can't
access your account without enabling 2FA first. That's great, except one
thing:

**They only offer two options for 2FA: Authy and SMS.**

That's somewhat understandable, because SendGrid belongs to Twilio, who
also owns Authy. By forcing SendGrid users on Authy, and making sure
that they can't easily use any of the competitor 2FA apps, they boost
their Authy adoption metrics, and that will certainly make investors
happy. Users? Not so much.

But I'm not a Authy user, and I don't plan to be. I definitely will not
install the Authy app just for this. "Use the alternative SMS 2FA
method" you'll say? But that's less secure on top of having a poor user
experience. I'd rather [use my existing password manager for this](totp-2fa-support-any-password-manager.md)
which is much faster and more convenient.

<div class="note">

**Note:** if you don't care about the technical details and just want to
transfer your Authy secrets to another authenticator, check out
[Authy user client](https://github.com/valeriangalliat/authy-user-client).

Otherwise, keep reading, I'll give you all the details about it! ✌️

</div>

## Here we go again

Every time I face a situation like this, I reverse.
[I love](https://www.codejam.info/2021/08/scripting-firefox-sync-lockwise-existing-clients.html)
[reversing](https://www.codejam.info/2021/08/scripting-firefox-sync-lockwise-figuring-the-protocol.html)
[things](https://www.codejam.info/2021/08/scripting-firefox-sync-lockwise-understanding-browserid.html),
especially when it helps me make my life better. I'll spend
[days](https://www.codejam.info/2021/08/scripting-firefox-sync-lockwise-hybrid-oauth.html),
even
[weeks](https://www.codejam.info/2021/08/scripting-firefox-sync-lockwise-complete-oauth.html)
doing what's necessary to achieve what I want.

Maybe that means decompiling apps and running them through a debugger,
or patching APKs to wipe certificate pinning mechanism in order to
[intercept the TLS traffic through a logging proxy](https://www.codejam.info/2021/07/intercept-macos-app-traffic-mitmproxy.html).

Often though, things are even easier. In the case of Authy, they have a
[Chrome app](https://chrome.google.com/webstore/detail/authy/gaedmjdfmmahhbjefcbgaolhhanlaolb)
that we can easily debug to understand how the protocol work. The best
thing about it? Someone already did a lot of the work and [documented it](https://randomoracle.wordpress.com/2017/02/15/extracting-otp-seeds-from-authy/).
Sweet.

<div class="note">

**Note:** I noticed later that [someone wrote a similar program in Go](https://github.com/alexzorin/authy).

The main difference is that it's intended to be used alongside an
existing Authy app and account, instead of replacing it completely, but
a lot of the code is the same. If Go is more your jam, check it out!

</div>

## Understanding the implementation

That article [I linked earlier](https://randomoracle.wordpress.com/2017/02/15/extracting-otp-seeds-from-authy/)
gives us a good starting point:

1. Authy uses TOTP in the background.
1. They generate TOTP using SHA-1, 7 digits, and a period of 10 seconds
   (whereas most implementations are SHA-1, 6 digits and 30 seconds).
1. They check the codes against the neighbouring periods, not only the
   current one, which is how they allow codes to be valid for 20 seconds
   even if the underlying implementation uses 10 seconds periods.
1. By debugging the [Chrome app](https://chrome.google.com/webstore/detail/authy/gaedmjdfmmahhbjefcbgaolhhanlaolb),
   you can easily extract your Authy secrets and import them in your
   favorite authenticator app or password manager.

That's awesome, but we're not there yet. I don't want to *have to use
Authy* (even once) in order to *not use Authy later*.

A mystery still remains. Since during 2FA setup they don't ever show a
QR code or give access to a TOTP URI or plaintext secret, how do this
secret ever reach the Authy app? Is it cryptographically derived from
the phone number, the service name, and other parameters? How does the
Authy app automagically knows what secret to generate the codes with?

Well, as it often turns out, the easiest answer is often the right one.
By inspecting the network traffic of the Chrome app, we clearly see
that... the secrets are directly retrieved from the Authy servers.

Now, how do we write our own code that fetches the secrets from the
Authy servers, without installing the Authy app? Let me tell you.

## Documenting the protocol

If we install the Chrome app, use our phone number to sign up or log in,
and generate a one-time code, the following happens:

1. The app checks the status of the given number on the Authy servers.
1. If the user doesn't exist, it creates it.
1. Then it starts a device registration flow, which consists in sending
   a code to the user's device via a call, SMS, or a push notification
   to an existing Authy app if any.
1. By inputting that code in the Chrome app, it can finalize the
   registration flow and gets its own ID and "secret seed".
1. It uses that seed as TOTP secret to generate a code for the next 3
   periods, and sends those 3 codes along with its device ID to sync the
   Authy state. This is how we retrieve the plaintext secrets for all
   the services associated with that account.

Additionally, all the requests contain an API key that's public and
hardcoded in the Chrome app.

<div class="note">

**Note:** the secrets for each 2FA entry are unique to each Authy
installation. This means that the secrets in the app on one device
will be different from the secrets on another device (including our own
client).

I expect they use that to make the secrets revocable. If you remove one
of your Authy devices, the secret seeds associated with it are going to
be invalidated and the codes generated by this device are no longer
valid.

</div>

With that in mind, we can write an API client.

## Making a client

At that point you'll be interested to look at the code of [Authy user client](https://github.com/valeriangalliat/authy-user-client).

I won't copy everything here, but I essentially made a quick
[API wrapper](https://github.com/valeriangalliat/authy-user-client/blob/c77d5c6e56619b012079482da4d7b9d269bab485/index.js#L38)
that allows me to define every method very concisely:

```js
const checkUserStatus = api({
  url: p => `/users/${p.country_code}-${p.cellphone}/status`,
  search: ['api_key']
})

const createUser = api({
  url: '/users/new',
  body: ['api_key', 'locale', 'email', 'cellphone', 'country_code']
})

const startRegistration = api({
  url: p => `/users/${p.authy_id}/devices/registration/start`,
  body: ['api_key', 'locale', 'via', 'signature', 'device_app']
})

const completeRegistration = api({
  url: p => `/users/${p.authy_id}/devices/registration/complete`,
  body: ['api_key', 'locale', 'pin']
})

const listDevices = api({
  url: p => `/users/${p.authy_id}/devices`,
  search: ['api_key', 'locale', 'otp1', 'otp2', 'otp3', 'device_id']
})

const deleteDevice = api({
  url: p => `/users/${p.authy_id}/devices/${p.delete_device_id}/delete`,
  body: ['api_key', 'locale', 'otp1', 'otp2', 'otp3', 'device_id']
})

const enableMultiDevice = api({
  url: p => `/users/${p.authy_id}/devices/enable`,
  body: ['api_key', 'locale', 'otp1', 'otp2', 'otp3', 'device_id']
})

const disableMultiDevice = api({
  url: p => `/users/${p.authy_id}/devices/disable`,
  body: ['api_key', 'locale', 'otp1', 'otp2', 'otp3', 'device_id']
})

const sync = api({
  url: p => `/users/${p.authy_id}/devices/${p.device_id}/apps/sync`,
  body: ['api_key', 'locale', 'otp1', 'otp2', 'otp3', 'device_id']
})
```

We'll also need a method to generate a TOTP codes using Authy settings:

```js
const base32 = require('rfc-3548-b32')
const totpGenerator = require('totp-generator')

function getOtp (secret) {
  // `totpGenerator` wants Base32, Authy uses hex.
  secret = base32.encode(Buffer.from(secret, 'hex'))
  return totpGenerator(secret, { digits: 7, period: 10 })
}
```

The main difference here is that Authy stores the TOTP secrets in
hexadecimal while most TOTP libraries and services expect Base32 as
defined in [RFC 3548](https://datatracker.ietf.org/doc/html/rfc3548#section-5),
so we need to do a quick conversion.

It's a bit stupid because the first thing totp-generator does is
[converting the secret back to hex](https://github.com/bellstrand/totp-generator/blob/af64a977b2aee17d0f0d3e607afa0af2a9a4814b/index.js#L11)
but there's no way to avoid that by specifying a custom encoding, so be
it.

Then we also need an helper method to generate the 3 next codes in the
time period sequence:

```js
function getOtps (secret) {
  // `totpGenerator` wants Base32, Authy uses hex.
  secret = base32.encode(Buffer.from(secret, 'hex'))

  const now = Date.now()

  return {
    otp1: totpGenerator(secret, { digits: 7, period: 10, now }),
    otp2: totpGenerator(secret, { digits: 7, period: 10, now: now + 10_000 }),
    otp3: totpGenerator(secret, { digits: 7, period: 10, now: now + 20_000 })
  }
}
```

This depends on [this PR on totp-generator](https://github.com/bellstrand/totp-generator/pull/37)
which might or might not be merged when you read this.

From there I export those methods to be used in the CLI, or by other
Node.js programs.

## Making a CLI

From there, we can use the awesome [prompts](https://www.npmjs.com/package/prompts)
package to build an interactive CLI that dumps the TOTP secrets from
your Authy account.

```js
const crypto = require('crypto')
const prompts = require('prompts')
const uri = require('uri-tag').default
const authy = require('authy-user-client')

async function prompt (params) {
  const res = await prompts({ ...params, name: 'value' })

  if (!res.value) {
    process.exit()
  }

  return res.value
}

const countryCode = await prompt({ type: 'number', message: 'Country code:', initial: 1, min: 1 })
const phoneNumber = await prompt({ type: 'number', name: 'phoneNumber', message: 'Phone number:', validate: value => value !== '' })

const status = await authy.checkUserStatus({ country_code: countryCode, cellphone: phoneNumber })
let authyId = status.authy_id

if (!authyId) {
  const email = await prompt({ type: 'text', message: 'Email:' })
  const registration = await authy.createUser({ email, country_code: countryCode, cellphone: phoneNumber })
  authyId = registration.authy_id
}

const via = await prompt({
  type: 'select',
  message: 'Authentication method:',
  choices: [
    { title: 'Push', value: 'push' },
    { title: 'Call', value: 'call' },
    { title: 'SMS', value: 'sms' }
  ]
})

await authy.startRegistration({
  authy_id: authyId,
  via,

  // Not sure why, but works better with this. 🤷
  signature: crypto.randomBytes(32).toString('hex')
})

const pin = await prompt({ type: 'number', message: 'PIN:', min: 1, validate: value => value !== '' })
const registrationResponse = await authy.completeRegistration({ authy_id: authyId, pin })

const deviceId = registrationResponse.device.id
const secretSeed = registrationResponse.device.secret_seed

const syncResponse = await authy.sync({
  authy_id: authyId,
  device_id: deviceId,
  ...authy.getOtps(secretSeed)
})

for (const app of syncResponse.apps) {
  const url = new URL(uri`otpauth://totp/${app.name}`)

  url.search = new URLSearchParams(Object.entries({
    // Authy uses hex, everything else uses Base32.
    secret: authy.hexToBase32(app.secret_seed),
    digits: app.digits,
    period: 10
  }))

  console.log(`${app.name}: ${url}`)
}
```

This will list all the associated apps with a [standard TOTP URI](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)
to be used in any compliant authenticator or password manager.

You can look at [the full source](https://github.com/valeriangalliat/authy-user-client/blob/master/cli.js)
for the implementation of individual calls for more fine-grained
control!

## Wrapping up

Thanks to this, we can work around services that force the Authy app for
2FA and extract the secret and settings to use them with our favorite
authenticator app.

Was this overkill? Hell yeah. But was it fun? Of course!

Still, I hope this can be useful to you if you run into the same issue.
You can just use the CLI and happily move on with your life and your
favorite TOTP provider! 🎉

<div class="note">

**Note:** if you need help understanding and documenting other
undocumented APIs and protocols, [let me know](/val.md#links), I'm
currently available for [contracting](/freelance.md) projects
and I'll be happy to help you with that. ✌️

</div>
