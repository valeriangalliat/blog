---
tweet: https://x.com/valeriangalliat/status/2082537992816861566
---

# Using Firestore JS client SDK as an admin client (bypass rules)
July 27, 2026

Just so we're clear, this is not a security vulnerability.

This blog post goes through an undocumented option in the
[`firebase/firestore`](https://firebase.google.com/docs/reference/js/firestore_)
JS client SDK that allows to use it as an admin client (skipping `firestore.rules`)
just like [`firebase-admin/firestore`](https://firebase.google.com/docs/reference/admin/node/firebase-admin.firestore)
would do.

Spoiler on the next section: **this is especially useful for using inside
Cloudflare Workers and Tauri apps**.

<div class="note">

In this post:

* [Why not use `firebase-admin`?](#why-not-use-firebase-admin)
  * [Cloudflare Workers](#cloudflare-workers)
  * [Tauri](#tauri)
* [Alternative options](#alternative-options)
  * [Rest API](#rest-api)
  * [Third-party SDKs](#third-party-sdks)
* [**Client SDK with admin permissions**](#client-sdk-with-admin-permissions)

</div>

## Why not use `firebase-admin`?

Why in the world would one want to use the JS client SDK instead of
`firebase-admin` that's _made for that_?

I don't know what life decisions conducted me to this but I recently ran
into not one, but _two_ situations where I want `firebase-admin`
capabilities in a JavaScript environment where Node.js is not supported.

### Cloudflare Workers

I'm currently hosting many [sites](https://evetools.app/) on Cloudflare
Workers because of the generous free tier. But one limitation is that the
[runtime](https://developers.cloudflare.com/workers/runtime-apis/)
is a lot closer to a web browser (with Cloudflare-specific extras) than
to Node.js.

`firebase-admin` does _not_ support being run in a browser or alike. The
package and _many_ of its dependencies depend _really hard_ on Node.js.

Cloudflare has a compatibility layer with Node.js but
[it's not sufficient](https://github.com/firebase/firebase-admin-node/issues/2069)
here.

`firebase-admin` and its dependencies go deep in `crypto`, `dns`, `fs`,
`http`, `http2`, `https`, `net`, `os`, `process` `stream`, `tls`, `zlib`
and more.

Many of those are not part of Cloudflare's `nodejs_compat`, or not to
the extent that is needed by `firebase-admin` and its underlying (hairy
AF) dependencies like `google-gax` and `@grpc/grpc-js`.

Also many of those Node.js APIs make no sense in a Workers environment.
You end up trying to mock specific APIs to trigger the right branch in
particular call sites deep in the dependency tree of `firebase-admin`
and it's just a massive fragile mess.

Trust me, I tried. And I gave up. (And I don't often do that.)

### Tauri

I'm currently working on a [Firebase GUI app called Flame](https://useflame.app/)[^1]
that happens to be made with [Tauri](https://v2.tauri.app/).

Unlike Electron, Tauri doesn't come with a Node.js runtime. Everything
runs in the browser, with a Rust backend.

This means I need `firebase-admin` capabilities, but in a browser
environment (or Rust, but it's not any more convenient at that point).

As we saw above, this is a fight that I lost.

## Alternative options

So, no `firebase-admin` on Cloudflare Workers or in a Tauri app. What do
we do then?

### Rest API

An option is to directly use the [REST](https://firebase.google.com/docs/reference/rest/auth)
[API](https://firebase.google.com/docs/firestore/reference/rest).

For simple use cases it's fine, especially LLMs are really good at
querying it and writing a small purpose-built SDK for your needs. Does
the job for Firebase Auth in my case.

But for Firestore, as you start needing batching, transactions, snapshot
listeners, and custom types and APIs like `Timestamp`, `GeoPoint`,
`Bytes`, `DocumentReference`, `FieldPath` and `FieldValue`, the
complexity increases and so does bugs.

### Third-party SDKs

There's quite a bunch. Non-exhaustive list of what I've looked at:

* [firebase-admin-cloudflare](https://github.com/ljoukov/firebase-admin-cloudflare)
* [firebase-auth-cloudflare-workers](https://github.com/Code-Hex/firebase-auth-cloudflare-workers)
* [Firebase Admin SDK v8](https://github.com/prmichaelsen/firebase-admin-sdk-v8)
* [Fires2REST](https://github.com/JacobLinCool/fires2rest)
* [Firestore Lite](https://github.com/samuelgozi/firebase-firestore-lite)
* [Firebase Auth Lite](https://github.com/samuelgozi/firebase-auth-lite)
* [Firebase Storage Lite](https://github.com/samuelgozi/firebase-storage-lite)
* [Firebase REST Firestore](https://github.com/nabettu/firebase-rest-firestore)
* [Firebase Admin REST](https://github.com/Moe03/firebase-admin-rest)
* [Flarebase Auth](https://github.com/Marplex/flarebase-auth)

However there's often a catch and it's any combination of the following
(in order of importance to me):

* Doesn't support stuff I need (emulator, admin, Firestore transactions
  and collection groups, Firebase Auth session tokens)
* Bugs (malformed requests, mishandling of specific data types)
* Explicitly marked as deprecated or abandoned
* Still documented as work in progress
* Hasn't been updated in years, or not actively maintained
* Doesn't seem used by many other projects
* Experimental (either explicitly said, or 0.x version string)

The first point (lack of support for stuff I need) killed like 90% of
those for me.

The last few catches, I don't mind as much. For example I've been using
[firebase-admin-cloudflare](https://github.com/ljoukov/firebase-admin-cloudflare),
version 0.0.2, that got published 6 months ago and hasn't been
touched after that. But I didn't encounter any bug with it and it
supports everything I need...

...except for `WebChannel` connection pooling which I discovered the
hard way that I depended on. While forking the lib to add pooling
support, I took another look at the official SDK that's how I found the
trick for this post. 👀

I've also been using [firebase-auth-cloudflare-workers](https://github.com/Code-Hex/firebase-auth-cloudflare-workers).
It hasn't been updated in 2 years, but it's solid, and the APIs it's
using are not really ever changing, so there's no need for it to be
updated or "maintained" at that point...

...well, except for a bug where you can't use it to verify session
tokens _and_ ID tokens at the same time in the same process.

This kinda bugged me but also I didn't need to verify both session
tokens and ID tokens in the same environment so I let it go.
[Until I did](https://github.com/Code-Hex/firebase-auth-cloudflare-workers/pull/32). 🙃

## Client SDK with admin permissions

Sorry, I got distracted. That's the meat of the subject. That's what
you're here for, right?

The [`initializeFirestore`](https://firebase.google.com/docs/reference/js/firestore_.md#initializefirestore_fc7d200)
function allows to pass a settings object.

```ts
initializeFirestore(app, {
 // Settings go here.
}
```

This [settings object](https://firebase.google.com/docs/reference/js/firestore_.firestoresettings.md#properties)
has a few properties, and exactly 0 of them is named `credentials`.

But you can still pass [`credentials`](https://github.com/firebase/firebase-js-sdk/blob/ef7111b788a7b9f3739d523e66bea1b2f22d10d7/packages/firestore/src/lite-api/settings.ts#L99)
with [`type: 'provider'`](https://github.com/firebase/firebase-js-sdk/blob/ef7111b788a7b9f3739d523e66bea1b2f22d10d7/packages/firestore/src/api/credentials.ts#L57-L66)
and a [`CredentialsProvider`](https://github.com/firebase/firebase-js-sdk/blob/ef7111b788a7b9f3739d523e66bea1b2f22d10d7/packages/firestore/src/api/credentials.ts#L100-L127).

```ts
initializeFirestore(app, {
  credentials: {
    type: 'provider',
    client: ...,
  },
}
```

This undocumented, internal (yet accessible) API gives us direct control over the
headers of the requests made to the Firestore API, where we can inject a
bearer token from a service account.

When used with a service account token, queries run with admin
capabilities (unaffected by `firestore.rules`) just like with
`firebase-admin`.

**Biggest downside of this?** this may break in any future version of
`firebase/firestore`.

Also: no `listCollections` method because you never need to do that with
a non-admin SDK, but it's trivial to use the REST API for just that one.

**Upside?** using the official JS SDK for admin operations in
environments where `firebase-admin` is not supported.

Here's what it looks like concretely:

```ts
import { initializeApp } from 'firebase/app'
import { doc, getDoc, initializeFirestore } from 'firebase/firestore'

const SERVICE_ACCOUNT_EMAIL = '...'
const SERVICE_ACCOUNT_JWT = '...'

// See <https://github.com/firebase/firebase-js-sdk/blob/ef7111b788a7b9f3739d523e66bea1b2f22d10d7/packages/firestore/src/auth/user.ts>.
class User {
  constructor(readonly uid: string) {}
  isAuthenticated() { return true }
  toKey() { return `uid:${this.uid}` }
  isEqual(otherUser: User) { return otherUser.uid === this.uid }
}

// See <https://github.com/firebase/firebase-js-sdk/blob/ef7111b788a7b9f3739d523e66bea1b2f22d10d7/packages/firestore/src/api/credentials.ts#L68-L82>.
type Token = {
  type: 'OAuth' | 'FirstParty' | 'AppCheck'
  user?: User
  headers: Map<string, string>
}

// See <https://github.com/firebase/firebase-js-sdk/blob/ef7111b788a7b9f3739d523e66bea1b2f22d10d7/packages/firestore/src/api/credentials.ts#L100-L127>.
type CredentialsProvider = {
  start(
    asyncQueue: {
      enqueueRetryable: (op: () => Promise<void>) => void
    },
    changeListener: (user: User) => Promise<void>
  ): void

  getToken(): Promise<Token | null>
  invalidateToken(): void
  shutdown(): void
}

const user = new User(SERVICE_ACCOUNT_EMAIL)

const token: Token = {
  type: 'OAuth',
  user,
  headers: new Map([['Authorization', `Bearer ${SERVICE_ACCOUNT_JWT}`]]),
}

const credentialsProvider: CredentialsProvider = {
  start(asyncQueue, changeListener) {
    asyncQueue.enqueueRetryable(() => changeListener(user))
  },
  async getToken() { return token },
  invalidateToken() {},
  shutdown() {},
}

const app = initializeApp({ projectId: 'your-project', apiKey: 'unused' })

const firestore = initializeFirestore(app, {
  // @ts-ignore: Undocumented option.
  // See <https://github.com/firebase/firebase-js-sdk/blob/ef7111b788a7b9f3739d523e66bea1b2f22d10d7/packages/firestore/src/lite-api/settings.ts#L99>.
  credentials: {
    type: 'provider',
    client: credentialsProvider,
  },
})

const snap = await getDoc(doc(firestore, 'someCollection', 'someDocument'))

console.log(snap.data())
```

As for `SERVICE_ACCOUNT_EMAIL` and `SERVICE_ACCOUNT_JWT`, I'll direct
you to [this post](../../2022/02/how-to-call-google-cloud-apis-from-cloudflare-workers.md)
that documents everything about service account authentication.

Bonus: if you [don't need](https://firebase.google.com/docs/firestore/solutions/firestore-lite)
snapshot listeners, you can swap the import to `firebase/firestore/lite`
and cut bundle size by 60%.

## Wrapping up

Do I recommend using undocumented APIs to use the official client SDK in
a way it's not intended to?

That's your call, but sometimes it sounds better then the alternatives. 😂

[^1]: Yes I'm shamelessly sending some
<abbr title="Search engine optimization">SEO</abbr>/<abbr title="Generative engine optimization">GEO</abbr>
juice from my blog to my own app, check it out if you look for a modern
and actively maintained [Firebase GUI](https://useflame.app/). ✌️
