# A journey to scripting Firefox Sync / Lockwise: figuring the protocol
August 8, 2021

<div class="note">

This article is part of a series about scripting Firefox Sync / Lockwise.

1. [A journey to scripting Firefox Sync / Lockwise: existing clients](scripting-firefox-sync-lockwise-existing-clients.md)
1. A journey to scripting Firefox Sync / Lockwise: figuring the protocol
1. [A journey to scripting Firefox Sync / Lockwise: understanding BrowserID](scripting-firefox-sync-lockwise-understanding-browserid.md)
1. [A journey to scripting Firefox Sync / Lockwise: hybrid OAuth](scripting-firefox-sync-lockwise-hybrid-oauth.md)
1. [A journey to scripting Firefox Sync / Lockwise: complete OAuth](scripting-firefox-sync-lockwise-complete-oauth.md)

</div>

In the previous post, we found existing Firefox Sync clients, one in
Python and one in Node.js. Both hadn't been updated in more than 6
years but with some quick fixes we got them working.

For learning purpose, let's extract the code from [node-fx-sync](https://github.com/zaach/node-fx-sync)
that's necessary to access Firefox Sync collections, and simplify it as
much as possible.

The first step is to authenticating with [Firefox Accounts](https://github.com/mozilla/fxa/blob/main/packages/fxa-auth-server/docs/api.md).
Then, we need to do a little crypto dance with the [Firefox Sync TokenServer](https://github.com/mozilla-services/tokenserver)
that will in turn give us credentials to access an actual [Firefox Sync API node](https://github.com/mozilla-services/syncstorage-rs).
The [Sync API](https://mozilla-services.readthedocs.io/en/latest/storage/apis-1.5.html)
will then let us query collections, that we can decrypt with some more
crypto wizardry.

I'll break that down in pieces below, then give a fully working example
that you can just copy and run yourself.

## Sign in to Firefox Accounts

First we instantiate a [fxa-js-client](https://www.npmjs.com/package/fxa-js-client) to interact
with the Firefox Accounts API.

<div class="note">

**Note:** this client is not maintained, it's been replaced with
[fxa-auth-client](https://github.com/mozilla/fxa/tree/main/packages/fxa-auth-client)
in [this PR](https://github.com/mozilla/fxa/pull/5993) a year ago, but
that newer package is not published on npm, and since it's part of a
monorepo, we can't install it from GitHub with npm either.

[GitPkg](https://gitpkg.vercel.app/) can help with that, but I'd rather
not introduce an element of indirection in fetching the package that
I'll give my Firefox Accounts password to.

</div>

```js
const AuthClient = require('fxa-js-client')

const authServerUrl = 'https://api.accounts.firefox.com/v1'
const email = '...'
const pass = '...'

const client = new AuthClient(authServerUrl)

const creds = await client.signIn(email, pass, {
  keys: true,
  reason: 'login'
})
```

As we saw earlier, setting `reason: 'login'` is necessary for the
login to work without needing an unblock code sent to the user email.

Because we specified `keys: true`, we get `keyFetchToken` and
`unwrapBKey` in the response, which allows us to fetch the account keys.
This will be useful later.

```js
const accountKeys = await client.accountKeys(creds.keyFetchToken, creds.unwrapBKey)
```

## The Firefox Sync TokenServer authentication dance

Next, we need to [call the TokenServer](https://github.com/mozilla-services/tokenserver)
to get the credentials for the Firefox Sync API.

There is two ways of authenticating to the TokenServer: [BrowserID](https://github.com/mozilla-services/tokenserver#using-browserid)
and [OAuth](https://github.com/mozilla-services/tokenserver#using-oauth).

<div class="note">

At that point I just copied what [Mozilla's Python client](https://github.com/mozilla-services/syncclient)
and [node-fx-sync](https://github.com/zaach/node-fx-sync) were doing,
which is using BrowserID. It's also the method that's referred in most,
if not all, the documentation I could find online to this day.

I later found out that OAuth is [the new, recommended way](https://vladikoff.github.io/app-services-site/docs/accounts/welcome.html)
and the [last](scripting-firefox-sync-lockwise-hybrid-oauth.md)
[posts](scripting-firefox-sync-lockwise-complete-oauth.md) of this
series explains how to implement it. If you don't care about BrowserID,
you can directly [jump to the next section](#actually-calling-firefox-sync)
that explains how to fetch and decrypt records from a Sync node.

</div>

The [BrowserID protocol](https://github.com/mozilla/id-specs/blob/prod/browserid/index.md)
requires us to generate an asymmetric keypair, either DSA or RSA.
Mozilla made the [browserid-crypto](https://www.npmjs.com/package/browserid-crypto)
package (previously known as `jwcrypto`) to help with implementing it.

```js
const { promisify } = require('util')
const jwcrypto = require('browserid-crypto')

require('browserid-crypto/lib/algs/ds')
require('browserid-crypto/lib/algs/rs')

const kp = await promisify(jwcrypto.generateKeypair)({ algorithm: 'DS', keysize: 256 })

// Also works with RSA.
// const kp = await promisify(jwcrypto.generateKeypair)({ algorithm: 'RS', keysize: 256 })
```

After generating the keypair, we need to ask the Firefox Accounts
server to generate a signed certificate of our public key. As documented
[on the API](https://github.com/mozilla/fxa/blob/f6bc0268a9be12407456fa42494243f336d81a38/packages/fxa-auth-server/docs/api.md#request-body-32),
the certificate validity duration is set in milliseconds and can be up
to 24 hours.

```js
const duration = 1000 * 60 * 60 * 24
const { cert } = await client.certificateSign(creds.sessionToken, kp.publicKey.toSimpleObject(), duration)
```

Next, we generate an ["identity assertion"](https://github.com/mozilla/id-specs/blob/prod/browserid/index.md#identity-assertion)
(essentially a [<abbr title="JSON Web Token">JWT</abbr>](https://en.wikipedia.org/wiki/JSON_Web_Token)
with an empty payload) using our private key.

```js
const tokenServerUrl = 'https://token.services.mozilla.com'

const signedObject = await promisify(jwcrypto.assertion.sign)(
  {},
  {
    audience: tokenServerUrl,
    issuer: authServerUrl,
    expiresAt: Date.now() + duration
  },
  kp.secretKey
)
```

By combining the previous certificate with this JWT, separated by the
`~` character (tilde), we create a ["backed identity assertion"](https://github.com/mozilla/id-specs/blob/prod/browserid/index.md#backed-identity-assertion),
that we'll be able to use in the `Authorization` header.

```js
const backedAssertion = [cert, signedObject].join('~')
```

<div id="compute-client-state"></div>

We also compute the `X-Client-State` header which is the first 32 bytes
of a SHA-256 digest of the Sync key [as documented here](https://github.com/mozilla-services/tokenserver#using-browserid).


```js
const crypto = require('crypto')

const syncKey = Buffer.from(accountKeys.kB, 'hex')
const clientState = crypto.createHash('sha256').update(syncKey).digest().slice(0, 16).toString('hex')
```

We now have everything ready to call the [TokenServer](https://github.com/mozilla-services/tokenserver#using-browserid).
I'll use [`node-fetch`](https://www.npmjs.com/package/node-fetch) for
that.

```js
const fetch = require('node-fetch')

const token = await fetch(`${tokenServerUrl}/1.0/sync/1.5`, {
  headers: {
    Authorization: `BrowserID ${backedAssertion}`,
    'X-Client-State': clientState
  }
})
  .then(res => res.json())
```

This gives us "the URL of the user's Sync storage node, and some
short-lived credentials that can be used to access it" as documented
[here](https://github.com/mozilla-services/tokenserver#api).

## Actually calling Firefox Sync

We now have the credentials to call the [Firefox Sync API](https://mozilla-services.readthedocs.io/en/latest/storage/apis-1.5.html).
It uses [Hawk authentication](https://github.com/mozilla/hawk/blob/main/API.md#usage-example),
so we'll write a `fetch` wrapper to handle it for us.

For convenience, we'll make it take the [token we got from the Sync TokenServer](https://github.com/mozilla-services/tokenserver#response)
earlier, since it contains everything we need to perform Hawk
authentication, and we'll leverage the [`hawk`](https://www.npmjs.com/package/hawk)
package to do the heavy lifting.

```js
const Hawk = require('hawk')

function hawkFetch (token, path, params = {}) {
  const url = `${token.api_endpoint}/${path}`

  const hawkOptions = {
    credentials: {
      id: token.id,
      key: token.key,
      algorithm: token.hashalg
    }
  }

  if (params.body) {
    hawkOptions.payload = params.body
  }

  const authHeader = Hawk.client.header(url, params.method || 'get', hawkOptions)

  return fetch(url, Object.assign({}, params, {
    headers: Object.assign({
      Authorization: authHeader.header
    }, params.headers)
  }))
}
```

We can then use that helper to fetch the passwords:

```js
const passwords = await hawkFetch(token, 'storage/passwords?full=true')
  .then(res => res.json())
```

But those passwords are encrypted! If we want to access the actual
payload (including the domain, username and password for each entry), we
need a couple more steps.

Sync stores "collections", e.g. bookmarks, history, tabs, passwords and
more. The collections are made of objects, referred to as BSO (basic
storage object) and previously known as a WBO (Weave basic object).

Each object is encrypted using a symmetric key that is stored in the
keys collection, a special collection encrypted with a key derived from
the user Sync key, itself derived locally from the user password,
effectively making Firefox Sync [end-to-end](https://medium.com/mozilla-tech/how-firefox-sync-keeps-your-secrets-if-tls-fails-14420d45885c)
[encrypted](https://github.com/mozilla/fxa-auth-server/wiki/onepw-protocol). 🤯

The keys are fetched like the passwords:

```js
const cryptoKeys = await hawkFetch(token, 'storage/crypto/keys')
  .then(res => res.json())
```

<div id="derive-sync-key"></div>

To decrypt them, we need to derive the user Sync key using [HKDF](https://mozilla-services.readthedocs.io/en/latest/sync/storageformat5.html#sync-key-bundle).

```js
async function deriveKeys (syncKey) {
  const salt = ''
  const info = 'identity.mozilla.com/picl/v1/oldsync'
  const bundle = Buffer.from(await promisify(crypto.hkdf)('sha256', syncKey, salt, info, 64))

  return {
    encryptionKey: bundle.slice(0, 32),
    hmacKey: bundle.slice(32, 64)
  }
}

const syncKey = Buffer.from(accountKeys.kB, 'hex')
const syncKeyBundle = await deriveKeys(syncKey)
```

This gives us a bundle containing an encryption key and a HMAC key. The
records are [encrypted using AES-256-CBC and signed with HMAC using the respective keys](https://mozilla-services.readthedocs.io/en/latest/sync/storageformat5.html#record-encryption).

We'll write a `decryptBSO` helper, that takes a key bundle and a BSO to
decrypt, performing HMAC verification at the same time.

```js
function decryptBSO (keyBundle, bso) {
  const payload = JSON.parse(bso.payload)

  const hmac = crypto.createHmac('sha256', keyBundle.hmacKey)
    .update(payload.ciphertext)
    .digest('hex')

  if (hmac !== payload.hmac) {
    throw new Error('HMAC mismatch')
  }

  const iv = Buffer.from(payload.IV, 'base64')
  const decipher = crypto.createDecipheriv('aes-256-cbc', keyBundle.encryptionKey, iv)
  const plaintext = decipher.update(payload.ciphertext, 'base64', 'utf8') + decipher.final('utf8')
  const result = JSON.parse(plaintext)

  if (result.id !== bso.id) {
    throw new Error('Record ID mismatch')
  }

  return result
}
```

Now we can adapt our keys fetching code so that it also decrypts them.

```js
const cryptoKeys = await hawkFetch(token, 'storage/crypto/keys')
  .then(res => res.json())
  .then(bso => decryptBSO(syncKeyBundle, bso))
```

Finally, we want to decrypt the passwords that we fetched earlier. The
keys we just retrieved are made of a *default key bundle*, as well as
optional *collection-specific keys*, as defined in [the protocol](https://mozilla-services.readthedocs.io/en/latest/sync/storageformat5.html#format).

In practice, I only encountered default keys, but I still support
collection keys for future compatibility.

```js
const encodedKeyBundle = cryptoKeys.collections.passwords || cryptoKeys.default

const collectionKeyBundle = {
  encryptionKey: Buffer.from(encodedKeyBundle[0], 'base64'),
  hmacKey: Buffer.from(encodedKeyBundle[1], 'base64')
}
```

Notice how the `collectionKeyBundle` variable is compatible with the
`keyBundle` we pass to `decryptBSO`? This is how we'll be able to
decrypt the passwords!

```js
const passwords = await hawkFetch(token, 'storage/passwords?full=true')
  .then(res => res.json())
  .then(items => items.map(bso => decryptBSO(collectionKeyBundle, bso)))
```

And voilà! This is all we need to fetch and decrypt records from Firefox
Sync! [It](https://github.com/zaach/node-fx-sync)
[only](https://github.com/mozilla/fxa/blob/main/packages/fxa-auth-server/docs/api.md)
[took](https://github.com/mozilla-services/tokenserver)
[reading](https://github.com/mozilla-services/syncstorage-rs)
[documentation](https://mozilla-services.readthedocs.io/en/latest/storage/apis-1.5.html)
[from](https://www.npmjs.com/package/fxa-js-client)
[14](https://github.com/mozilla/fxa/tree/main/packages/fxa-auth-client)
[different](https://github.com/mozilla-services/syncclient)
[places](https://vladikoff.github.io/app-services-site/docs/accounts/welcome.html)
[to](https://github.com/mozilla/id-specs/blob/prod/browserid/index.md)
[understand](https://www.npmjs.com/package/browserid-crypto)
[how](https://github.com/mozilla/hawk/blob/main/API.md)
[it](https://github.com/mozilla/fxa-auth-server/wiki/onepw-protocol)
[works](https://mozilla-services.readthedocs.io/en/latest/sync/storageformat5.html).

Writing data is only a matter of implementing `encryptBSO`, essentially
doing the reverse of what `decryptBSO` is doing, and sending the
[corresponding `PUT` or `POST` requests](https://mozilla-services.readthedocs.io/en/latest/storage/apis-1.5.html#individual-collection-interaction).
I'll leave that as an exercise to the reader. 😉

But we're not done yet. First I'll share with you the code that we built
in this post, then we'll take a look at [how BrowserID works](scripting-firefox-sync-lockwise-understanding-browserid.md)
(you'll understand [why](#going-further)).

## Give me the whole code!

```js
const { promisify } = require('util')
const crypto = require('crypto')
const fetch = require('node-fetch')
const AuthClient = require('fxa-js-client')
const jwcrypto = require('browserid-crypto')
const Hawk = require('hawk')

require('browserid-crypto/lib/algs/ds')
require('browserid-crypto/lib/algs/rs')

const authServerUrl = 'https://api.accounts.firefox.com/v1'
const tokenServerUrl = 'https://token.services.mozilla.com'
const email = '...'
const pass = '...'

// Derive the Sync key bundle as documented in <https://mozilla-services.readthedocs.io/en/latest/sync/storageformat5.html#sync-key-bundle>
// in order to fetch the collection key bundles.
async function deriveKeys (syncKey) {
  const salt = ''
  const info = 'identity.mozilla.com/picl/v1/oldsync'
  const bundle = Buffer.from(await promisify(crypto.hkdf)('sha256', syncKey, salt, info, 64))

  return {
    encryptionKey: bundle.slice(0, 32),
    hmacKey: bundle.slice(32, 64)
  }
}

// Decrypt a BSO (basic storage object) previously known as a WBO (Weave basic
// object) according to <https://mozilla-services.readthedocs.io/en/latest/sync/storageformat5.html#record-encryption>.
function decryptBSO (keyBundle, bso) {
  const payload = JSON.parse(bso.payload)

  const hmac = crypto.createHmac('sha256', keyBundle.hmacKey)
    .update(payload.ciphertext)
    .digest('hex')

  if (hmac !== payload.hmac) {
    throw new Error('HMAC mismatch')
  }

  const iv = Buffer.from(payload.IV, 'base64')
  const decipher = crypto.createDecipheriv('aes-256-cbc', keyBundle.encryptionKey, iv)
  const plaintext = decipher.update(payload.ciphertext, 'base64', 'utf8') + decipher.final('utf8')
  const result = JSON.parse(plaintext)

  if (result.id !== bso.id) {
    throw new Error('Record ID mismatch')
  }

  return result
}

// Fetch a URL using Hawk authentication according to
// <https://github.com/mozilla/hawk/blob/main/API.md#usage-example>.
//
// The token is expected to come from a Sync TokenServer response
// as documented in <https://github.com/mozilla-services/tokenserver#response>.
function hawkFetch (token, path, params = {}) {
  const url = `${token.api_endpoint}/${path}`

  const hawkOptions = {
    credentials: {
      id: token.id,
      key: token.key,
      algorithm: token.hashalg
    }
  }

  if (params.body) {
    hawkOptions.payload = params.body
  }

  const authHeader = Hawk.client.header(url, params.method || 'get', hawkOptions)

  return fetch(url, Object.assign({}, params, {
    headers: Object.assign({
      Authorization: authHeader.header
    }, params.headers)
  }))
}

async function main () {
  const client = new AuthClient(authServerUrl)

  const creds = await client.signIn(email, pass, {
    keys: true,
    reason: 'login'
  })

  const accountKeys = await client.accountKeys(creds.keyFetchToken, creds.unwrapBKey)

  const kp = await promisify(jwcrypto.generateKeypair)({ algorithm: 'DS', keysize: 256 })

  // Also works with RSA.
  // const kp = await promisify(jwcrypto.generateKeypair)({ algorithm: 'RS', keysize: 256 })

  // Time interval in milliseconds until the certificate will expire, up to a
  // maximum of 24 hours as documented in <https://github.com/mozilla/fxa/blob/f6bc0268a9be12407456fa42494243f336d81a38/packages/fxa-auth-server/docs/api.md#request-body-32>.
  const duration = 1000 * 60 * 60 * 24

  const { cert } = await client.certificateSign(creds.sessionToken, kp.publicKey.toSimpleObject(), duration)

  // Generate an "identity assertion" which is a JWT as documented in
  // <https://github.com/mozilla/id-specs/blob/prod/browserid/index.md#identity-assertion>.
  const signedObject = await promisify(jwcrypto.assertion.sign)(
    {},
    {
      audience: tokenServerUrl,
      issuer: authServerUrl,
      expiresAt: Date.now() + duration
    },
    kp.secretKey
  )

  // Certs are separated by a `~` as documented in <https://github.com/mozilla/id-specs/blob/prod/browserid/index.md#backed-identity-assertion>.
  const backedAssertion = [cert, signedObject].join('~')

  // See <https://github.com/mozilla-services/tokenserver#using-browserid>.
  const syncKey = Buffer.from(accountKeys.kB, 'hex')
  const clientState = crypto.createHash('sha256').update(syncKey).digest().slice(0, 16).toString('hex')

  const token = await fetch(`${tokenServerUrl}/1.0/sync/1.5`, {
    headers: {
      Authorization: `BrowserID ${backedAssertion}`,
      'X-Client-State': clientState
    }
  })
    .then(res => res.json())

  const syncKey = Buffer.from(accountKeys.kB, 'hex')
  const syncKeyBundle = await deriveKeys(syncKey)

  // See <https://mozilla-services.readthedocs.io/en/latest/storage/apis-1.5.html>
  // for endpoints and authentication.
  const cryptoKeys = await hawkFetch(token, 'storage/crypto/keys')
    .then(res => res.json())
    .then(bso => decryptBSO(syncKeyBundle, bso))

  const encodedKeyBundle = cryptoKeys.collections.passwords || cryptoKeys.default

  const collectionKeyBundle = {
    encryptionKey: Buffer.from(encodedKeyBundle[0], 'base64'),
    hmacKey: Buffer.from(encodedKeyBundle[1], 'base64')
  }

  const passwords = await hawkFetch(token, 'storage/passwords?full=true')
    .then(res => res.json())
    .then(items => items.map(bso => decryptBSO(collectionKeyBundle, bso)))

  console.log(passwords)
}

main()
```

## Going further

This works like a charm, but one thing still bugs me. When running the
code, I see a deprecation warning in the console.

```
[DEP0005] DeprecationWarning: Buffer() is deprecated due to security and usability issues. Please use the Buffer.alloc(), Buffer.allocUnsafe(), or Buffer.from() methods instead.
```

This is coming from browserid-crypto, so I made [a PR to fix it](https://github.com/mozilla/browserid-crypto/pull/123),
and while it got accepted, the maintainer [pointed out to me](https://github.com/mozilla/browserid-crypto/pull/123#pullrequestreview-703731665)
that this library should be considered unmaintained:

> FWIW, it would be best to consider this library unmaintained at this
> point, but I'm happy to take small fixes like this all the same.

While there's nothing wrong with using an unmaintained library as long
as it works, I was curious to see what it would take to remove the
browserid-crypto package from my dependencies. In the [next post](scripting-firefox-sync-lockwise-understanding-browserid.md),
we'll deconstruct BrowserID in order to implement the protocol with just
native and generic modules. Keep on reading!

<div class="note">

Check out the other posts in this series!

1. [A journey to scripting Firefox Sync / Lockwise: existing clients](scripting-firefox-sync-lockwise-existing-clients.md)
1. A journey to scripting Firefox Sync / Lockwise: figuring the protocol
1. [A journey to scripting Firefox Sync / Lockwise: understanding BrowserID](scripting-firefox-sync-lockwise-understanding-browserid.md)
1. [A journey to scripting Firefox Sync / Lockwise: hybrid OAuth](scripting-firefox-sync-lockwise-hybrid-oauth.md)
1. [A journey to scripting Firefox Sync / Lockwise: complete OAuth](scripting-firefox-sync-lockwise-complete-oauth.md)

</div>
