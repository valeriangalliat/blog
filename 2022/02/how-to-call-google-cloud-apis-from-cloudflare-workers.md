---
tweet: https://twitter.com/Hookdeck/status/1496535899257118720
---

# How to Call Google Cloud APIs from Cloudflare Workers
February 16, 2022

<div class="note">

**Note:** this is a mirror of the blog post originally published on
[Hookdeck blog](https://hookdeck.com/blog/post/how-to-call-google-cloud-apis-from-cloudflare-workers)!

</div>

If you want to handle HTTP requests without managing your own
infrastructure, a common solution these days is *"serverless" functions*.

They're known as Lambda on AWS, Functions on Google Cloud, Azure, Vercel
and Netlify, Workers on Cloudflare, and EdgeWorkers on Akamai.

But if you also want to do some processing **after** returning a HTTP
response, Cloudflare Workers is the only one that lets you do it.

And because this is a need of ours, we use Cloudflare Workers to handle
webhooks ingestion. This allows us to return a very fast response after
performing some sanity checks, then deal with queuing and possible error
handling and recovery in the background.

But Cloudflare Workers have quite some limitations compared to the most
popular (already pretty limited) serverless functions platforms.

## The problem with Cloudflare Workers

Most of the JavaScript backend ecosystem is built around Node.js, but
Cloudflare Workers is not. Meaning all the usual modules we would
normally `import` are not there, and we can't easily `npm install`
Node.js dependencies. Cloudflare Workers essentially brought Webpack to
the backend, as well as all the limitations we usually have with
browsers.

And because we depend on Google Cloud Pub/Sub, and the Google Cloud SDK
only has a **Node.js** client for Pub/Sub (not plain JavaScript), we
can't use that directly from Cloudflare Workers.

<div class="note">

**Note:** Google do offer a pure JavaScript SDK (intended for browser
usage) known as [GAPI](https://github.com/google/google-api-javascript-client)
which would syntaxically be compatible with Cloudflare Workers, but it
only supports  OAuth or API key authentication, and not service account
which is necessary in our backend case. See [Google Cloud authentication strategies](https://cloud.google.com/docs/authentication#strategies).

</div>

One solution we had for a while was to call a Google Cloud Function over
HTTP from the Cloudflare Worker, and that Cloud Function could itself
use the Google Cloud Node.js SDK to call Pub/Sub. This worked, but added
an extra overhead to process webhooks, an additional component that can
break, as well as an extra piece of infrastructure to maintain (yeah, I
lied in the beginning of this article, even serverless functions require
you to deal with at least a bit of infrastructure).

So we decided as part of a maintenance effort to remove this Cloud
Function and call directly the Pub/Sub API from Cloudflare, despite the
lack of a pure JavaScript SDK.

## Homemade client overview

This leaves us to build our own Google Cloud client implementing the
service account authentication. Fortunately, this is a topic that's
[covered](https://community.cloudflare.com/t/connecting-to-google-storage/32350)
in a few [forums](https://stackoverflow.com/questions/67644213/accessing-google-cloudtasks-api-without-using-googles-sdks)
and [articles](https://blog.cloudflare.com/api-at-the-edge-workers-and-firestore/)
[already](https://www.jhanley.com/google-cloud-creating-oauth-access-tokens-for-rest-api-calls/).

Here's the gist:

* On Google Cloud, create a service account as well as an IAM user
  associated with it.
* Give the necessary permissions to that IAM user.
* Download the service account JSON key which contains a PEM RSA private
  key, a key ID, and a client email.
* Thanks to those 3 elements, create and sign a [JWT](https://jwt.io/)
  that we can be used as a bearer token for Google Cloud APIs, and that
  will be accepted as long as the requested permissions in the JWT match
those of the associated IAM user.

This involves some [SubtleCrypto](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto)
magic, which we'll cover in this article.

## Passing the service account JSON

Typically this is done with the Google Cloud SDK by setting a
`GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of the
service account JSON key file.

Because we're managing Cloudflare secrets inside environment variables
and not on the filesystem, we put the JSON string directly in a
`GOOGLE_APPLICATION_CREDENTIALS_JSON` environment variable. The name is
arbitrary, it's only a nudge to the original SDK (that we can't use).

On the worker side, we can fetch it from the environment either via a
global variable if you're writing a service-worker-style... worker, or
from the `env` parameter of the `fetch` function if you're in a
module-style worker:

```js
// Service worker
const serviceAccount = JSON.parse(GOOGLE_APPLICATION_CREDENTIALS_JSON)

// Module
export default {
  fetch (request, env, context) {
    const serviceAccount = JSON.parse(env.GOOGLE_APPLICATION_CREDENTIALS_JSON)
    // ...
  }
}
```

## Importing the RSA key

Brace yourselves because I'm gonna go in a little bit of details about
this. And while you can just scroll to the end of this section and copy
the code, I think it's valuable to spend the time to understand
carefully how this all works!

The service account JSON has a `private_key` string, containing a
PEM-encoded RSA private key that we can use to sign JWTs. It looks
something like this:

```js
-----BEGIN PRIVATE KEY-----
MIIBVAIBADANBgkqhkiG9w0BAQEFAASCAT4wggE6AgEAAkEApL8kivZkDZn0NPYR
pVfe8uM+IO8Fk+d3Qd4EaPcD1MHmXY8Jef1T+v33mMNUHTDiEfGi3n/9kmSN4u0p
fr/9rwIDAQABAkEAgQAe6CUYoUHc5B+OH68Xp47i1jzzXCYRzuS/BUXunQfZgncH
EO4LZz/7m6ggAx8dWPaxlsXD4QJZbatlVo4wAQIhANhPWVrWcry8oct3MDMPNLCW
+sP14q3P8fQJDT76rIgBAiEAwvm6k2qPn2S8RLyaD1gHwSgX7/oxS44n8Hztjgwn
Ba8CICp4yg6v9K9iSlJtAKXF4o6Z1nsLmIqQPe2wqU0oYyABAiBk+dqTwCtTnGMY
oiiTa77QXUhQY12mSKAMn1aUK10GRwIgU/+scWe64dWIkodZRorlYjLtJYsjNikR
5MjzJijoE1s=
-----END PRIVATE KEY-----
```

Because our Cloudflare Worker is a browser-like environment, we can't
use the [Node.js `crypto` module](https://nodejs.org/api/crypto.html) to
deal with cryptography, and we need to use the [SubtleCrypto](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto)
API instead. But SubtleCrypto [doesn't support PEM encoding out of the box](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey#parameters).
The good news is that it supports [PKCS #8](https://en.wikipedia.org/wiki/PKCS_8) and
[JWK](https://datatracker.ietf.org/doc/html/rfc7517).

PKCS #8 is the standard encoding for private keys. Our PEM private key
above is essentially a PKCS #8 key that's Base64-encoded, with the
addition of a header and footer string.

On the other hand, JWK stands for **JSON Web Key**, and it's a way to
encode cryptographic keys in a JSON object, as opposed to a binary or
Base64-encoded format.

The same key as above, but formatted as JWK:

```js
{
  "kty": "RSA",
  "n": "pL8kivZkDZn0NPYRpVfe8uM-IO8Fk-d3Qd4EaPcD1MHmXY8Jef1T-v33mMNUHTDiEfGi3n_9kmSN4u0pfr_9rw",
  "e": "AQAB",
  "d": "gQAe6CUYoUHc5B-OH68Xp47i1jzzXCYRzuS_BUXunQfZgncHEO4LZz_7m6ggAx8dWPaxlsXD4QJZbatlVo4wAQ",
  "p": "2E9ZWtZyvLyhy3cwMw80sJb6w_Xirc_x9AkNPvqsiAE",
  "q": "wvm6k2qPn2S8RLyaD1gHwSgX7_oxS44n8HztjgwnBa8",
  "dp": "KnjKDq_0r2JKUm0ApcXijpnWewuYipA97bCpTShjIAE",
  "dq": "ZPnak8ArU5xjGKIok2u-0F1IUGNdpkigDJ9WlCtdBkc",
  "qi": "U_-scWe64dWIkodZRorlYjLtJYsjNikR5MjzJijoE1s"
}
```

### The JWK way

In a Node.js script, we can directly import the PEM key:

```js
const crypto = require('crypto')

const privateKey = crypto.createPrivateKey({
  key: serviceAccount.private_key,
  format: 'pem',
})
```

Which allows us to easily convert it to a JWK:

```js
const jwk = privateKey.export({ format: 'jwk' })
```

If we carry this JWK to the worker, for example putting the serialized
JSON in a `GOOGLE_APPLICATION_CREDENTIALS_JWK` environment variable, we
can import it like this:

```js
const jwk = JSON.parse(env.GOOGLE_APPLICATION_CREDENTIALS_JWK)

const algorithm = {
  name: 'RSASSA-PKCS1-v1_5',
  hash: {
    name: 'SHA-256',
  }
}

const extractable = false
const keyUsages = ['sign']

const privateKey = await crypto.subtle.importKey('jwk', jwk, algorithm, extractable, keyUsages)
```

A couple points here:

* In the `algorithm` parameter, we specify we're working with a
  `RSASSA-PKCS1-v1_5` key, which is basically a standard RSA key.
* We also specify a `hash` of SHA-256, which is not directly related to
  the key itself, but will be useful later on when we want to sign a
  JWT, since we'll use a RS256 signature (RSA signature with SHA-256).
* We set `extractable` to `false` because we don't want further code to
  be able to dump this key. This secrity measure is especially relevant
  in browsers but doesn't hurt here either.
* We set `keyUsages` to `sign`, allowing this key to only be used for
  issuing signatures, again an extra measure tn ensure that the key is
  only used for the usages that we indended.

We know all this information because Google Cloud documents it
[here](https://developers.google.com/identity/protocols/oauth2/service-account#authorizingrequests).

This is great, but that new environment variable is redundant with the
RSA key that's already in the service account JSON. Can we somehow
import the PEM key without using an intermediary JWK?

### Parsing the PEM key to PKCS #8

While we can't import directly a PEM key with SubtleCrypto, the MDN has
us covered with [an example of parsing a PEM-encoded key](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey#subjectpublickeyinfo_import)!
I furthered adapted this example to our Google Cloud service account key
use case.

First, we strip the newlines from the PEM string:

```js
const pem = serviceAccount.private_key.replace(/\n/g, '')
```

Then we strip the PEM header and footer markers:

```js
const pemHeader = '-----BEGIN PRIVATE KEY-----';
const pemFooter = '-----END PRIVATE KEY-----';

if (!pem.startsWith(pemHeader) || !pem.endsWith(pemFooter)) {
  throw new Error('Invalid service account private key');
}

const pemContents = pem.substring(pemHeader.length, pem.length - pemFooter.length);
```

This leaves us with a Base64-encoded string that we can decode to a
`Uint8Array`. For that I like to use the [`js-base64`](https://www.npmjs.com/package/js-base64)
package, which doesn't have the quirks of messing with the deprecated
`atob` function (which only supports ASCII strings), and using
[workarounds](https://developer.mozilla.org/en-US/docs/Glossary/Base64#the_unicode_problem)
like `decodeURIComponent(escape(atob(str)))`.

To be able to use this module, we need to make sure to bundle our code,
since Cloudflare doesn't let us import modules like this. I like to use
[esbuild](https://github.com/evanw/esbuild) for this, but
[webpack](https://webpack.js.org/) is also a popular alternative.

```js
import { Base64 } from 'js-base64'

const buffer = Base64.toUint8Array(pemContents)
```

This buffer contains effectively a binary PKCS #8 key that we can import
like this:

```js
const algorithm = {
  name: 'RSASSA-PKCS1-v1_5',
  hash: {
    name: 'SHA-256',
  }
}

const extractable = false
const keyUsages = ['sign']

const privateKey = await crypto.subtle.importKey('pkcs8', buffer, algorithm, extractable, keyUsages)
```

See above for explanation of `algorithm`, `extractable` and `keyUsage`
parameters.

## Direct JWT vs. OAuth

Google offers us two methods to auth with its APIs in this context.
Either with a server-to-server OAuth flow, or via a self-issued JWT.
This is documented [here](https://developers.google.com/identity/protocols/oauth2/service-account#jwt-auth):

> With some Google APIs, you can make authorized API calls using a
> signed JWT directly as a bearer token, rather than an OAuth 2.0 access
> token. When this is possible, you can avoid having to make a network
> request to Google's authorization server before making an API call.
>
> If the API you want to call has a service definition published in the
> [Google APIs GitHub repository](https://github.com/googleapis/googleapis),
> you can make authorized API calls using a JWT instead of an access
> token.

The direct JWT method is great because we can avoid an extra network
call to the OAuth endpoint, as well as extra error handling and retry
logic around it! And it looks like the most popular APIs support it.

If the API you want to call doesn't though, don't worry, the approach is
very similar. You still need to implement the JWT logic, but instead of
using it directly for your API calls, you use it only against Google's
OAuth endpoint to generate an access token, which you can use in your
further API calls.

## Signing the JWT

Now we managed to import the service account private key, we can use it
to sign a JWT. The format is documented [here](https://developers.google.com/identity/protocols/oauth2/service-account#jwt-auth).

Essentially, a JWT is made of 3 parts:

* A JSON header, Base64URL-encoded
* A JSON payload, Base64URL-encoded
* A signature, not JSON this time, but you guessed it, Base64URL-encoded

What's [Base64URL](https://base64.guru/standards/base64url)? It's
Base64, but slightly tweaked to be URL-safe.

For the Base64 business, I'll keep using the
[`js-base64`](https://www.npmjs.com/package/js-base64) module we
imported above (which conveniently supports Base64URL). Let's start with
the header:

```js
const header = Base64.encodeURI(
  JSON.stringify({
    alg: 'RS256',
    typ: 'JWT',
    kid: serviceAccount.private_key_id,
  }),
)
```

As we saw earlier, we're going to use a RSA signature with SHA-256
(RS256), we're effectively building a JWT, and we forward the
`private_key_id` in the `kid` field like Google wants.

Off to the payload. We need 5 fields:

* `iss` and `sub`, both set to the service account email
* `aud`, the API endpoint we want to use, in our case, Pub/Sub (not the
  trailing slash is important)
* `iat`, the Unix time at the moment the token was issued (now)
* `exp`, the Unix time when the JWT will expire, which can be maximum an
  hour after `iat`

```js
const iat = Math.floor(Date.now() / 1000)
const exp = iat + 3600

const payload = Base64.encodeURI(
  JSON.stringify({
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: 'https://pubsub.googleapis.com/',
    exp,
    iat
  })
)
```

Next, we can compute the signature. Remember we still have our
`privateKey` variable from earlier:

```js
const textEncoder = new TextEncoder()
const inputArrayBuffer = textEncoder.encode(`${header}.${payload}`)

const outputArrayBuffer = await crypto.subtle.sign(
  { name: 'RSASSA-PKCS1-v1_5' },
  privateKey,
  inputArrayBuffer
)

const signature = Base64.fromUint8Array(new Uint8Array(outputArrayBuffer), true)
```

A bit more complexity here. `crypto.subtle.sign` expects an
`ArrayBuffer` but we have a string, so [we use a `TextEncoder` to convert it](https://stackoverflow.com/questions/6965107/converting-between-strings-and-arraybuffers).
Then, we get the signature as an `ArrayBuffer`, but in order to encode
it, `js-base64` expects an `Uint8Array`, so we do the conversion.
Finally, we pass `true` as second parameter to `Base64.fromUint8Array`
because we want a Base64URL representation.

We now have all we need to assemble our JWT. The 3 components of the
token are separated by the `.` character:

```js
const token = `${header}.${payload}.${signature}`
```

## Calling the Google Cloud API

We can now use our fresh token to issue `fetch` requests to the Google
Cloud API!

```js
const res = await fetch(
  `https://pubsub.googleapis.com/v1/projects/.../topics/...:publish`,
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body
  }
)
```

There's still a bit more work to do, especially about dealing with
possible HTTP errors, and handling the token refresh logic. I'll leave
that as an exercise to the reader.

Finally, if you want to use an endpoint that doesn't support
[direct JWT](https://developers.google.com/identity/protocols/oauth2/service-account#jwt-auth)
like this, and you need to get an OAuth token instead, you can use
`https://oauth2.googleapis.com/token` in the `aud` field instead, add a
`scope` field to the JWT, and call that OAuth token endpoint to get an
access token. Again, all the details are [here](https://developers.google.com/identity/protocols/oauth2/service-account#authorizingrequests).

## Wrapping up

And just like this, we managed to call Google Cloud APIs from Cloudflare
Workers! This got a bit technical because there's no Cloudflare-ready
SDK for it, but this was a great opportunity to learn how Google Cloud
authentication normally works with service accounts, and get a better
idea of the cryptography behind it.

I hope you learnt something! And if you like to work with Cloudflare and
Google Cloud, [we're hiring](https://hookdeck.com/jobs/backend-devops-sre),
and that's what we do... every day!
