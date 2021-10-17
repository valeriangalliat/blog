---
hero: https://photography.codejam.info/photos/hd/P2650052.jpg
heroCredit: Val
heroCreditUrl: https://photography.codejam.info/photos/P2650052.html
tweet: https://twitter.com/valeriangalliat/status/1424462810998886416
---

# A journey to scripting Firefox Sync / Lockwise: understanding BrowserID
Migrating from unmaintained browserid-crypto (`jwcrypto`) to a generic implementation  
August 8, 2021

<div class="note">

This article is part of a series about scripting Firefox Sync / Lockwise.

1. [A journey to scripting Firefox Sync / Lockwise: existing clients](scripting-firefox-sync-lockwise-existing-clients.md)
1. [A journey to scripting Firefox Sync / Lockwise: figuring the protocol](scripting-firefox-sync-lockwise-figuring-the-protocol.md)
1. A journey to scripting Firefox Sync / Lockwise: understanding BrowserID
1. [A journey to scripting Firefox Sync / Lockwise: hybrid OAuth](scripting-firefox-sync-lockwise-hybrid-oauth.md)
1. [A journey to scripting Firefox Sync / Lockwise: complete OAuth](scripting-firefox-sync-lockwise-complete-oauth.md)

</div>

In the [previous post](scripting-firefox-sync-lockwise-figuring-the-protocol.md)
we [made a script](scripting-firefox-sync-lockwise-figuring-the-protocol.md#give-me-the-whole-code)
that is able to fetch and decrypt collections from Firefox Sync,
including Lockwise passwords. But one thing was still bugging me. When
running the code, the console was showing a deprecation warning.

```
[DEP0005] DeprecationWarning: Buffer() is deprecated due to security and usability issues. Please use the Buffer.alloc(), Buffer.allocUnsafe(), or Buffer.from() methods instead.
```

By running `node --trace-warnings`, I could see that it was coming from
the [browserid-crypto](https://www.npmjs.com/package/browserid-crypto)
package. It was trivial to fix by [migrating](https://nodejs.org/en/docs/guides/buffer-constructor-deprecation/)
from the deprecated `new Buffer()` constructor to `Buffer.from()`, so I
[made another PR](https://github.com/mozilla/browserid-crypto/pull/123)
for this.

Like [the first PR](https://github.com/mozilla/browserid-crypto/pull/122),
it's reviewed and approved by <a href="https://github.com/rfk" id="ryan">Ryan</a>
(who's name I saw countless times when researching about Firefox
Accounts and Sync protocols). He also [notes](https://github.com/mozilla/browserid-crypto/pull/123#pullrequestreview-703731665)
that this library is unmaintained:

> FWIW, it would be best to consider this library unmaintained at this
> point, but I'm happy to take small fixes like this all the same.

While there's nothing wrong with using an unmaintained library if it
gets the job done, I took this as a challenge to implement the protocol
using only native (or more generic, well-maintained) modules, and this
is going to be the topic of this blog post!

## Isolating the browserid-crypto code

Let's start from the [script we previously built](scripting-firefox-sync-lockwise-figuring-the-protocol.md#give-me-the-whole-code)
and extract the part that use the browserid-crypto package.

```js
const { promisify } = require('util')
const jwcrypto = require('browserid-crypto')

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
```

There are 3 steps here:

1. First, we generate a DSA or RSA keypair, which would be trivial to
   do with the Node.js `crypto` module.
1. Then we encode the public key in a way that is compatible with
   [Firefox Accounts' `/certificate/sign` endpoint](https://github.com/mozilla/fxa/blob/main/packages/fxa-auth-server/docs/api.md#post-certificatesign).
1. Finally, we sign a JWT using our private key, and bundle it with the
   certificate to make a "backed identity assertion".

## Generating the keypair

This is the easy part. The main difference is that while
`jwcrypto.generateKeyPair` takes an internal `keysize` parameter, which
they [map to RSA](https://github.com/mozilla/browserid-crypto/blob/69b23d9d70dfbf9bccdf5330545aebb12657c496/lib/algs/rs.js#L10),
and [DSA key sizes](https://github.com/mozilla/browserid-crypto/blob/69b23d9d70dfbf9bccdf5330545aebb12657c496/lib/algs/ds.js#L36),
we need to explicitly give the RSA key size (usually synonymous of the
modulus length).

In our case, a BrowserID RSA key of "256" [corresponds to a 2048-bit RSA key](https://github.com/mozilla/browserid-crypto/blob/69b23d9d70dfbf9bccdf5330545aebb12657c496/lib/algs/rs.js#L20) and similarly, a BrowserID DSA key of "256" [corresponds to a 2048-bit DSA key](https://github.com/mozilla/browserid-crypto/blob/69b23d9d70dfbf9bccdf5330545aebb12657c496/lib/algs/ds.js#L56).
They also both specify SHA-256 as the JWT hash algorithm, which will be
useful for later.

```js
const { promisify } = require('util')
const crypto = require('crypto')

// With RSA
const kp = await promisify(crypto.generateKeyPair)('rsa', {
  modulusLength: 2048
})

// With DSA
const kp = await promisify(crypto.generateKeyPair)('dsa', {
  modulusLength: 2048,
  divisorLength: 256
})
```

<div class="note">

**Note:** for DSA, the BrowserID key has a divisor length of 256 bits
(the `q` parameter), and this is especially important as
browserid-crypto and the TokenServer don't accept any other divisor
length for a key size of 2048.

</div>

## Encoding the key

Where it gets a bit more tricky, especially for DSA, is when we want to
encode the key as JSON for the Firefox Accounts API to sign:

```js
const { cert } = await client.certificateSign(creds.sessionToken, kp.publicKey.toSimpleObject(), duration)
```

The keys from browserid-crypto conveniently include a `toSimpleObject`
function that formats the key in the BrowserID JSON format. I couldn't
find documentation for it, but from looking at the actual JSON objects,
it is very similar to (but not compatible with) the [<abbr title="JSON Web Key">JWK</abbr>](https://datatracker.ietf.org/doc/html/rfc7517)
format.

### BrowserID vs. JWK and base conversion

BrowserID was [introduced in 2011](https://hacks.mozilla.org/2011/07/introducing-browserid-easier-and-safer-authentication-on-the-web/),
well before [the JWK specification was proposed](https://datatracker.ietf.org/doc/html/rfc7517)
in 2015. They both encode the low-level key parameters in a JSON object,
and there is just a couple of differences, especially:

1. JWK doesn't support DSA keys.
1. To specify the key type, JWK has a `kty` property (set to `RSA` for
   RSA keys),while BrowserID uses an `algorithm` property that can be
   `RS` or `DS`.
1. JWK encodes the key parameters as
   [Base64URL](https://base64.guru/standards/base64url),
   while BrowserID [uses decimal (base 10) for RSA](https://github.com/mozilla/browserid-crypto/blob/69b23d9d70dfbf9bccdf5330545aebb12657c496/lib/algs/rs.js#L68)
   and [hexadecimal (base 16) for DSA](https://github.com/mozilla/browserid-crypto/blob/69b23d9d70dfbf9bccdf5330545aebb12657c496/lib/algs/ds.js#L141).

### RSA

The [RSA parameters](https://datatracker.ietf.org/doc/html/rfc7518#section-6.3.1)
are `n` (modulus) and `e` (exponent), as well as [a fuckton of other parameters](https://datatracker.ietf.org/doc/html/rfc7518#section-6.3.2)
for private keys (which we don't need here). You can see them on an
existing key with `openssl rsa -in rsa-private-key.pem -text -noout`.

We can take the earlier code to generate a RSA keypair, and export the
public key as a JWK like this:

```js
const { promisify } = require('util')
const crypto = require('crypto')

const kp = await promisify(crypto.generateKeyPair)('rsa', {
  modulusLength: 2048
})

console.log(kp.publicKey.export({ format: 'jwk' }))
```

```json
{
  "kty": "RSA",
  "n": "3M852Cy7DIH1wYJVgRxQfDYPa26fC4KR4uYmHeGV7rTtiQ2-IdypkOQd6Clp01-J4L9e28w-3hR06ZWKRMIbfyajcer1bd_9luBKkRiFlYxa-CBNTlOJBmtej7MbouQJdqcxRIHufk7R4HBWYzR8H1WUDzJfIZJLxz2eymTNXu7CPFyDoNZXQ9SRu7tzPzhUsDrkdpNSs2x8tRrllJRiO-BOC2Ce3W5vCE9eB91VFuIOHOuL5y-Fr6K-vCfvpLBzoF2uk399ZGxZ8rLXHk01QDoin3BVXQzGBKNXoVNrNe-tKflp5QJ5wMifvL4tPfCCrps8rrfbE1NDPE2x1QmCfQ",
  "e": "AQAB"
}
```

On the other hand, a BrowserID RSA public key looks like this:

```js
const jwcrypto = require('browserid-crypto')

require('browserid-crypto/lib/algs/rs')

jwcrypto.generateKeypair({ algorithm: 'RS', keysize: 256 }, (err, { publicKey }) => {
  console.log(publicKey.toSimpleObject())
})
```

```json
{
  "algorithm": "RS",
  "n": "24561144013955114361783231655761853176741812326893374232205401875943449227620158204608340216900927757193227109312970662811636219675773452185909191206484694392560433664701055247500397746104758184735693308844235833317883872067955852418577691056051019648528118784214798195301896767050575864274186910237901534713406182369363255235410257674380032656581487055343920363852506722639241918085307849979198768941882638020102729524988683333585179817471524571511030397962907590237048329319430881173155778553010801560573247170682531231684185163187096747308113243183139470492492221024173487301503496674419087411376160055924262029047",
  "e": "65537"
}
```

It is easy to convert a native JWK to the BrowserID format, as we can
leverage [`BigInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt)
to output a large base 10 string. But the constructor doesn't accept
Base64 directly, so we need to do an intermediate conversion through
hexadecimal.

```js
const { promisify } = require('util')
const crypto = require('crypto')

function base64to10 (data) {
  return BigInt('0x' + Buffer.from(data, 'base64').toString('hex')).toString(10)
}

const kp = await promisify(crypto.generateKeyPair)('rsa', {
  modulusLength: 2048
})

const jwk = kp.publicKey.export({ format: 'jwk' })

const publicKey = {
  algorithm: jwk.algorithm.slice(0, 2),
  n: base64to10(jwk.n),
  e: base64to10(jwk.e)
}
```

### DSA

The [DSA parameters](https://mozilla.github.io/id-specs/docs/formats/keys/#parameters-for-dsa-keys)
are `p` (larger prime modulus), `q` (smaller prime modulus), `g`
(generator), `y` (public group element), as well as `x` (private
exponent) for private keys.

Since JWK doesn't support DSA, we cannot do `kp.publicKey.export({ format: 'jwk' })`
with a DSA key generated by the `crypto` module, as that would fail with
`[ERR_CRYPTO_JWK_UNSUPPORTED_KEY_TYPE]: Unsupported JWK Key Type`.

With browserid-crypto, we can replace `RS` by `DS` in the previous
example to generate the following key, and get a better idea of what
we're trying to reproduce:

```js
const jwcrypto = require('browserid-crypto')

require('browserid-crypto/lib/algs/rs')

jwcrypto.generateKeypair({ algorithm: 'DS', keysize: 256 }, (err, { publicKey }) => {
  console.log(publicKey.toSimpleObject())
})
```

```json
{
  "algorithm": "DS",
  "y": "735b5ddcb95622cb39370efbd0ab4020e7ed5b73f06aecf7ba89ea57f7627ecec5973e1fcb8628125d58d94fed65d65affbfb2722f302085de127fb6fba97e18502da5e1d23d05979ff5a64b587a75b1f0953b4afce05cab74af5b886b059f67889756360d2d41c2312493695d891fad1b2b9cf6169e335f65d573da27b524aa968b9de93d0f0ddf157345917598b630b8937b2c76bedf8fb5ae686d0eddddee2c6cb9829b6d5a19bb07332e7ab3e6116c523198ef699af154b0ea038e92e15ca43ef757f7e854463596346634f759c30730d04cae296d6e663322cb030749c818c922cf2ed51a117bcc17aa603b560159ace99b4aea549c402d1390a1cf1648",
  "p": "d6c4e5045697756c7a312d02c2289c25d40f9954261f7b5876214b6df109c738b76226b199bb7e33f8fc7ac1dcc316e1e7c78973951bfc6ff2e00cc987cd76fcfb0b8c0096b0b460fffac960ca4136c28f4bfb580de47cf7e7934c3985e3b3d943b77f06ef2af3ac3494fc3c6fc49810a63853862a02bb1c824a01b7fc688e4028527a58ad58c9d512922660db5d505bc263af293bc93bcd6d885a157579d7f52952236dd9d06a4fc3bc2247d21f1a70f5848eb0176513537c983f5a36737f01f82b44546e8e7f0fabc457e3de1d9c5dba96965b10a2a0580b0ad0f88179e10066107fb74314a07e6745863bc797b7002ebec0b000a98eb697414709ac17b401",
  "q": "b1e370f6472c8754ccd75e99666ec8ef1fd748b748bbbc08503d82ce8055ab3b",
  "g": "9a8269ab2e3b733a5242179d8f8ddb17ff93297d9eab00376db211a22b19c854dfa80166df2132cbc51fb224b0904abb22da2c7b7850f782124cb575b116f41ea7c4fc75b1d77525204cd7c23a15999004c23cdeb72359ee74e886a1dde7855ae05fe847447d0a68059002c3819a75dc7dcbb30e39efac36e07e2c404b7ca98b263b25fa314ba93c0625718bd489cea6d04ba4b0b7f156eeb4c56c44b50e4fb5bce9d7ae0d55b379225feb0214a04bed72f33e0664d290e7c840df3e2abb5e48189fa4e90646f1867db289c6560476799f7be8420a6dc01d078de437f280fff2d7ddf1248d56e1a54b933a41629d6c252983c58795105802d30d7bcd819cf6ef"
}
```

Exporting the key as a JWK was really handy earlier to access the
low-level key parameters, but we cannot do that with DSA. We can only
export the key as DER (binary) or PEM (Base64 encoded DER).

This means that we'll need to use the OpenSSL CLI to dump the key
parameters as we saw earlier. Let's start by generating the PEM private
key.

```js
const { promisify } = require('util')
const crypto = require('crypto')

const kp = await promisify(crypto.generateKeyPair)('dsa', {
  modulusLength: 2048,
  divisorLength: 256
})

const privateKey = kp.privateKey.export({ format: 'pem', type: 'pkcs8' })
```

Then, we can invoke the `openssl` command, piping it the private key.

```js
const cp = require('child_process')

const sub = cp.spawn('openssl', ['dsa', '-in', '-', '-text', '-noout'])

sub.stdin.write(privateKey)
```

The child process will now emit `data` events on the `stdout` stream and
we can use that to parse the OpenSSL output. For context, here's what a
typical output looks like:

<details>
  <summary>Output of <code>openssl dsa -in dsa-private-key.pem -text -noout</code></summary>

```
Private-Key: (2048 bit)
priv:
    4b:66:fe:d5:68:c2:7e:3d:4a:fc:c0:45:10:01:91:
    fe:d7:83:be:39:0b:79:f3:0f:a1:c3:63:0e:8a:8f:
    63:db
pub:
    7e:50:55:ea:62:b8:70:0f:89:ca:f9:ad:41:21:05:
    8d:2c:71:e3:14:a5:1c:70:7d:a6:68:97:10:2f:93:
    f3:82:ee:98:25:7c:6a:42:71:9a:e0:b0:bf:c2:76:
    18:df:fe:68:63:ba:a8:a0:4d:10:9f:5a:da:c6:e3:
    c9:94:23:4a:d5:8e:00:ac:6b:f8:40:06:10:d1:6a:
    09:17:7e:73:8e:10:5b:5a:a0:dc:7a:c7:7d:cb:96:
    3b:8d:d8:d5:27:05:e0:0f:d8:e3:04:24:c3:ef:49:
    0d:56:54:54:3a:cd:c8:bf:36:03:2e:e7:8f:21:a2:
    8e:14:f9:17:57:85:7f:83:73:01:bc:90:aa:01:d1:
    4b:cb:84:c0:99:ee:2a:d2:3d:d7:30:97:51:89:fd:
    ef:b8:7a:ea:5e:5f:17:37:53:ce:43:b5:05:64:b9:
    09:c8:3f:07:eb:c4:9b:77:a5:6b:d2:d3:d0:ed:3e:
    47:1d:54:7d:f1:a1:ef:66:25:a6:fc:61:1b:cb:ae:
    60:f9:3b:7d:58:f3:e4:19:3b:09:4d:3f:87:c6:97:
    95:9b:78:02:55:fc:d8:74:86:06:50:8b:78:23:63:
    c6:b2:46:96:48:88:93:c6:32:d4:88:33:c7:44:f1:
    b9:73:b7:1a:72:0c:1e:55:40:7c:f3:cf:7a:fe:06:
    b7
P:
    00:bc:a3:68:a5:2b:1d:b5:c6:8a:4e:70:0d:78:4b:
    17:83:37:8f:d4:3a:9c:27:e7:08:b5:6d:9a:91:b4:
    8e:22:81:7e:ee:10:8c:08:45:c3:a1:f5:95:b3:9c:
    71:83:49:c2:dc:58:67:d3:c4:5c:1a:db:2e:c6:a4:
    18:4a:8a:15:b8:3b:b8:94:29:b4:43:79:e3:32:11:
    98:26:6e:65:01:11:f0:b9:cf:a2:e5:dc:4b:f8:4c:
    31:27:ff:75:cf:b8:b4:13:b0:f5:e8:da:ab:76:7b:
    ba:7d:ca:9b:fd:c1:29:89:77:6e:ee:95:33:3c:64:
    94:5e:4d:5b:0b:f4:b8:4f:91:54:8c:40:35:75:11:
    06:1e:7f:ed:ae:17:9e:ce:9b:8d:e1:79:75:7c:fd:
    d2:60:3f:89:10:6e:95:04:67:5b:08:31:71:ea:13:
    76:78:28:cd:cb:03:2b:66:19:3e:39:12:98:86:d3:
    90:d6:43:72:6e:32:bf:27:c6:76:f4:ab:04:e6:54:
    f3:41:ca:52:60:7e:74:1c:26:b3:e9:4c:0e:94:88:
    bd:7d:3e:af:a0:0d:50:58:89:a5:7a:d2:9d:4c:27:
    0f:2c:c2:6e:98:2e:a8:6d:22:97:19:2a:7c:ae:0c:
    b8:d3:1e:46:f9:e5:62:b4:91:2c:43:a2:02:1d:30:
    6f:4f
Q:
    00:b0:60:bd:58:73:4e:5a:37:e5:4e:a3:15:2a:a7:
    d9:dd:e2:b6:c2:f9:3d:37:4b:9d:43:33:9b:25:9c:
    bc:97:67
G:
    02:80:e7:af:91:ef:92:ef:51:67:2e:84:a8:e4:f1:
    c5:e0:c1:98:c2:c9:59:e0:89:3f:71:3f:99:fd:ee:
    cf:fa:db:6e:6f:bc:8b:5b:d0:06:35:0d:c2:19:96:
    c1:be:18:43:ed:76:52:70:4d:d3:8f:71:e2:b4:d0:
    a6:1e:ed:0d:67:71:24:dd:f1:86:06:99:f4:39:a8:
    45:d1:ac:5b:55:af:f3:89:0d:44:87:e9:36:ac:02:
    a6:fc:5d:27:56:96:92:d5:5e:35:a8:62:5f:63:9c:
    bf:da:ff:8e:c0:a0:28:7a:9c:41:2a:2c:bb:c6:80:
    7c:7b:86:58:4e:af:95:2c:06:51:5f:15:81:cc:8f:
    c1:9b:72:fa:82:71:65:81:ee:9e:99:f7:04:f9:1e:
    90:e4:ea:88:0e:44:b1:78:0e:67:8b:b6:61:7b:94:
    27:f1:7f:a6:7f:7b:59:21:73:71:92:a6:5f:98:67:
    a3:b7:e4:b2:dd:e7:55:f3:22:ac:de:44:1a:54:71:
    e3:33:ce:22:ac:38:93:e1:6b:9b:96:43:ce:4c:8c:
    87:a3:86:97:a1:1c:b6:7c:cc:d8:ab:7d:82:a2:0f:
    f5:7a:75:a5:f1:bc:e7:04:94:ae:83:98:98:70:5d:
    89:b0:54:8b:84:bf:ec:b1:eb:bb:fc:55:98:d0:ca:
    b4
```

</details>

With the following code, we can parse it into an object:

```js
const readline = require('readline')

const rl = readline.createInterface({ input: sub.stdout })

const params = {}
let currentParam

rl.on('line', line => {
  // Continuation of an existing parameter, append to it.
  if (line.startsWith(' ') && currentParam) {
    params[currentParam] += line.trim()
    return
  }

  // Definition of a new parameter.
  const split = line.split(':')

  if (split.length < 2) {
    return
  }

  currentParam = split[0]
  params[currentParam] = split[1].trim()
})

await new Promise((resolve, reject) => {
  sub.on('exit', code => {
    if (code > 0) {
      return reject(new Error(`OpenSSL failed with code ${code}`))
    }

    resolve()
  })
})

console.log(params)
```

Conveniently, OpenSSL returns the parameters in hexadecimal form
already, so we just need to remove the `:` that it separates each byte
with, and rename the properties to make a BrowserID JSON key.

```js
const publicKey = {
  algorithm: 'DS',
  y: params.pub.replaceAll(':', ''),
  p: params.P.replaceAll(':', ''),
  q: params.Q.replaceAll(':', ''),
  g: params.G.replaceAll(':', '')
}
```

## Signing the JWT

The last part to refactor is the JWT:

```js
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

It seems that this is a standard JWT, so we can use the [`njwt`](https://www.npmjs.com/package/njwt)
package for this (a simpler and more flexible alternative to
[`jsonwebtoken`](https://www.npmjs.com/package/jsonwebtoken)).

<div class="note">

**Note:** the main quirk is that Mozilla uses a milliseconds timestamp
for the `exp` field, while JWT defines it as a standard timestamp (in
seconds).

This means that with both libraries, we need to work around that in
order to force the `exp` field to be in milliseconds. For `njwt`, this
means doing `jwt.setClaim('exp', expiresAt)` instead of using
`jwt.setExpiration(expiresAt)`, and for `jsonwebtoken` it means
including the `exp` claim as part of the payload instead of using the
`expiresIn` parameter that is otherwise expressed as a duration in
seconds.

</div>

As for the private key, while `njwt` documents it should be a (PEM)
string or a (DER) buffer, since it just forwards it to Node.js `crypto`
module, we can directly give it the [`KeyObject`](https://nodejs.org/api/crypto.html#crypto_class_keyobject)
that's in `kp.privateKey`.

```js
const njwt = require('njwt')

const signedObject = njwt.create({ aud: tokenServerUrl, iss: authServerUrl }, kp.privateKey, 'RS256')
  .setClaim('exp', Date.now() + duration)
  .compact()
```

Here we specified the `RS256` algorithm for a RSA key. This works
perfectly, and with this code, we can effectively generate a BrowserID
assertion that will be accepted by the TokenServer!

### Hacking around DSA

But neither [`njwt`](https://github.com/jwtk/njwt#supported-algorithms)
nor [`jsonwebtoken`](https://github.com/auth0/node-jsonwebtoken#algorithms-supported)
support DSA signatures. In fact, it seems that most JWT libraries don't
support DSA whatsoever.

That being said, we can leverage the fact that `njwt` forwards the
private key to the [`crypto.sign`](https://nodejs.org/api/crypto.html#crypto_sign_sign_privatekey_outputencoding)
method to make it work with our DSA key. All we need to do is to trick
it into thinking that it's signing with the `RS256` algorithm so that it
follows the SHA-256 signature code path (which actually works perfectly
with a DSA key), and force the `alg` header to be `DS256` just at the
time it is encoded in the JWT (otherwise the library will complain that
the algorithm is unsupported).

```js
const njwt = require('njwt')

const jwt = njwt.create({ aud: tokenServerUrl, iss: authServerUrl }, kp.privateKey, 'RS256')
  .setClaim('exp', Date.now() + duration)

jwt.header.compact = function compact () {
  const alg = this.alg
  this.alg = 'DS256'
  const header = njwt.JwtHeader.prototype.compact.call(this)
  this.alg = alg
  return header
}

const signedObject = jwt.compact()
```

This should work but it does not. I keep getting HTTP 401s with
`invalid-credentials` error from the TokenServer. Why? It took some
trial and error to figure as this was far from obvious.

It turns out that Node.js [defaults the DSA signature encoding to DER](https://nodejs.org/api/crypto.html#crypto_sign_sign_privatekey_outputencoding),
and BrowserID only supports the IEEE P1363 format.

Thankfully, Node.js allows us to wrap the private key in an object to
specify extra options like a `dsaEncoding: 'ieee-p1363'`. In the
previous code this would look like:

```js
const jwt = njwt.create(
  { aud: tokenServerUrl, iss: authServerUrl },
  { key: kp.privateKey, dsaEncoding: 'ieee-p1363' },
  'RS256'
)
```

Congratulations! We now also have a working DSA JWT!

### Fully native implementation

Now, let's even remove the `njwt` dependency, and bake our own JWT
in-house. Because why not. It's actually pretty trivial, and to be
honest, a simpler and cleaner solution for DSA than the hack we just
made.

```js
const crypto = require('crypto')

const header = { alg: 'DS256' }
const payload = { exp: Date.now() + duration, aud: tokenServerUrl, iss: authServerUrl }

const body = [
  Buffer.from(JSON.stringify(header)).toString('base64url'),
  Buffer.from(JSON.stringify(payload)).toString('base64url')
].join('.')

const signature = crypto.sign('SHA256', body, {
  key: kp.privateKey,
  dsaEncoding: 'ieee-p1363'
}).toString('base64url')

const signedObject = [body, signature].join('.')
```

Believe it or not, this is all it takes to make a valid JWT. Not so bad,
isn't it?

## Making the backed identity assertion

Since we have a valid `cert` and `signedObject` at that point, that part
stays the same. All we need to do is to [bundle them together](https://github.com/mozilla/id-specs/blob/prod/browserid/index.md#backed-identity-assertion)
with the `~` character (tilde).

```js
const backedAssertion = [cert, signedObject].join('~')
```

This is the value we can pass in the `Authorization` header such as:

```
Authorization: BrowserID <backedAssertion>
```

## Wrapping up

And that's it! We now have a fully working BrowserID implementation,
with both RSA and DSA support, that only depend on the native `crypto`
module!

There were some incompatibilities with DSA that we needed to work
around, especially the fact that it is not supported by JWK, forcing us
to fallback to the OpenSSL CLI to extract the key parameters, and also
that common JWT libraries don't support it either, leading us to write
our own (dead simple) JWT implementation.

This makes the code a bit simpler if we only use RSA, where it's barely
longer than the initial browserid-crypto version, while the DSA version
is a bit hairier with the code to invoke OpenSSL and parse its output,
as well as the custom JWT signature.

Because of that, unlike [in the previous post](scripting-firefox-sync-lockwise-figuring-the-protocol.md#give-me-the-whole-code),
I won't include the full code here. You should easily be able to put
together the pieces that you need from this article.

But this is probably not an exercise you should be interested in
anyways, because as I later found out, it's not just browserid-crypto
that's unmaintained, but the BrowserID protocol altogether that's
deprecated! In the [next stop of this journey](scripting-firefox-sync-lockwise-hybrid-oauth.md),
we'll look at the OAuth version, which turned out to be much easier to
support than it first looked like.

<div class="note">

Check out the other posts in this series!

1. [A journey to scripting Firefox Sync / Lockwise: existing clients](scripting-firefox-sync-lockwise-existing-clients.md)
1. [A journey to scripting Firefox Sync / Lockwise: figuring the protocol](scripting-firefox-sync-lockwise-figuring-the-protocol.md)
1. A journey to scripting Firefox Sync / Lockwise: understanding BrowserID
1. [A journey to scripting Firefox Sync / Lockwise: hybrid OAuth](scripting-firefox-sync-lockwise-hybrid-oauth.md)
1. [A journey to scripting Firefox Sync / Lockwise: complete OAuth](scripting-firefox-sync-lockwise-complete-oauth.md)

</div>
