---
hero: https://photography.codejam.info/photos/hd/P2650095.jpg
heroCredit: Val
heroCreditUrl: https://photography.codejam.info/photos/P2650095.html
---

# A journey to scripting Firefox Sync / Lockwise: existing clients
August 8, 2021

<div class="note">

This article is part of a series about scripting Firefox Sync / Lockwise.

1. A journey to scripting Firefox Sync / Lockwise: existing clients
1. [A journey to scripting Firefox Sync / Lockwise: figuring the protocol](scripting-firefox-sync-lockwise-figuring-the-protocol.md)
1. [A journey to scripting Firefox Sync / Lockwise: understanding BrowserID](scripting-firefox-sync-lockwise-understanding-browserid.md)
1. [A journey to scripting Firefox Sync / Lockwise: hybrid OAuth](scripting-firefox-sync-lockwise-hybrid-oauth.md)
1. [A journey to scripting Firefox Sync / Lockwise: complete OAuth](scripting-firefox-sync-lockwise-complete-oauth.md)

</div>

Recently, I switched to [Firefox Lockwise](https://lockwise.firefox.com/)
as my password manager, for a [number of reasons which I detailed here](why-i-switched-to-firefox-lockwise-as-my-password-manager.md).

There is currently no CLI for Lockwise, and while it's not a critical
thing for me, I like to have the option to use my password manager from
the CLI, and to interact with it programmatically. So I figured it would
be a good exercise to build it myself.

I spent way more time digging in the Firefox Accounts and Firefox Sync
protocols than I'm willing to admit, and now I finally managed to
programmatically connect to my Firefox Account and interact with Firefox
Sync, I'm going to share that journey in a series of blog posts. Fasten
your seatbelts!

## Fair warning

You might not be interested in the whole story, especially in two
following posts, where I explain how I started by implemented the legacy
BrowserID authentication mechanism (because it's what's documented and
used nearly everywhere), before [figuring that there is also support for OAuth](scripting-firefox-sync-lockwise-hybrid-oauth.md)
which seems to be the most modern, recommended way to interact with the
API, and turned out to be much simpler to implement ([until it wasn't](scripting-firefox-sync-lockwise-complete-oauth.md)).

While the two implementations share a lot of code, if you just want to
know what's the best way to interact with Firefox Sync in 2021, go
straight to [hybrid OAuth](scripting-firefox-sync-lockwise-hybrid-oauth.md),
which still requires prompting the user's email/password to open a
Firefox Accounts session first (concretely means that users have to
trust you more), or to [complete OAuth](scripting-firefox-sync-lockwise-complete-oauth.md)
which, while it requires contacting Mozilla to obtain your own OAuth
credentials, frees you from the responsibility of handling the user's
password and primary encryption key.

In both cases, the part to call the Firefox Sync API once the
authentication is performed remains the same and is explained
[in the second post](scripting-firefox-sync-lockwise-figuring-the-protocol.md#actually-calling-firefox-sync).

That being said, if you want the whole story, let's get started!

## Our good old friend Stack Overflow

I started looking for an API, and possibly existing API clients, and I
quickly figured Lockwise was built on top of Firefox Sync's `passwords`
collection.

Looking up "Firefox Sync API" lead me to [this post from 2016 on Stack Overflow](https://stackoverflow.com/questions/35313330/firefox-sync-api-does-it-exist),
where the top answer, which is also the only answer, points to the [Sync client documentation](https://mozilla-services.readthedocs.io/en/latest/sync/index.html)
and mentions an existing [Python client](https://github.com/mozilla-services/syncclient).

While there's a lot of documentation on the first link, it seems to
only explain the protocol specification, but it's unclear where to start
as there's no mention of an URL to query the API and how to authenticate
to it.

Looking at the client should give us a more concrete understanding.

## Official Python client

The first thing I notice is that the repository hasn't been updated
since 2016 and is now archived, which means it's probably not
up-to-date, definitely not actively maintained, and it's even
[documented as a proof of concept](https://github.com/mozilla-services/syncclient/blob/efe0d49a8bd00d341b6e926f6783325b3fe7b676/syncclient/client.py#L11).

I try to use it but `pip install -r requirements.txt` fails with some
weird error. Since I also noticed there was a [Node.js client](#unofficial-node-js-client), I
I left it at that.

I later came back to it while writing this post, and it turns out after
fixing some `requirements.txt` versions issues, it does run
successfully! But it doesn't implement the collection decryption part so
it would only have solved part of my problem.

## Unofficial Node.js client

There is also a [Node.js client](https://github.com/zaach/node-fx-sync),
last updated in 2014.

Out of the box, I cannot install it with `npm install fx-sync`, it fails
with the `jwcrypto` dependency post-install script. [On npm](https://www.npmjs.com/package/jwcrypto)
this package is marked as deprecated, with a recommendation of using [browserid-crypto](https://www.npmjs.com/package/browserid-crypto)
instead (which seems to be API-compatible), so after a quick `sed -i 's/jwcrypto/browserid-crypto/g'`,
I try again.

Sadly I get the same error, and realize that the post-install script was
broken because of a small issue that had to do with minifying the JS
output. I made a [quick fix](https://github.com/mozilla/browserid-crypto/pull/122)
for it, which finally allowed the `fx-sync` package to install.

But the excitement dropped quickly as I get the following error during
the login step:

```js
{
  "code": 400,
  "errno": 125,
  "error": "Request blocked",
  "message": "The request was blocked for security reasons",
  "info": "https://github.com/mozilla/fxa/blob/main/packages/fxa-auth-server/docs/api.md#response-format",
  "verificationMethod": "email-captcha",
  "verificationReason": "login"
}
```

The login request is blocked for security reasons, and it's unclear what
to do to fix it. While investigating, I find [this GitHub issue](https://github.com/mozilla/fxa/issues/5794)
with the same error. While there is no solution in that issue, the OP
mentions an "unblock code" which sounds interesting to me, so I figured
I'll try it myself.

[node-fx-sync](https://github.com/zaach/node-fx-sync) uses
[fxa-js-client](https://www.npmjs.com/package/fxa-js-client) to interact
with Firefox Accounts, and looking at the package API, it contains a
method to send an unblock code, and a way to forward it to the `signIn`
method, so I integrate this flow to allow continuing the process using
the code sent to the account email.

```js
const AuthClient = require('fxa-js-client')

const client = new AuthClient('https://api.accounts.firefox.com/v1')

async function login (email, pass) {
  const params = {
    keys: true
  }

  try {
    return await client.signIn(email, pass, params)
  } catch (err) {
    if (err.code === 400 && err.errno === 125) {
      await client.sendUnblockCode(email)
      params.unblockCode = await promptUserForCode()
      return client.signIn(email, pass, params)
    }

    throw err
  }
}
```

At that point, I hadn't run the [Python client](#official-python-client)
yet, but when I did so later, I realized that it *just worked*, without the
need for an unblock code. How was that possible? I looked at the source
and figured the only difference was that [PyFxA](https://github.com/mozilla/PyFxA),
the Python client for Firefox Accounts, [sent `reason=login`](https://github.com/mozilla/PyFxA/blob/6c3f803b3c27c665f417b0c5bd3ca79add8e2027/fxa/core.py#L78)
as part of the login parameters by default, which made the
authentication successful without external verification. Sweet!

```js
client.signIn(email, pass, {
  keys: true,
  reason: 'login'
})
```

After this patch, I got `fx-sync` to work without the need for an
unblock code, and it was successfully able to access my Firefox Sync
collections and decrypt them.

```js
const FxSync = require('fx-sync')

const sync = new FxSync({
  email: '...',
  password: '...'
})

const passwords = await sync.fetch('passwords')

console.log(passwords)
```

This is a great start, but there's something with using a package that
hasn't been updated since 2014 that just doesn't feel right to me.

Also, this client only allows *read* access, but I would also like to be
able to add new objects, or update and delete existing ones. While I
could just implement this feature in the existing code, this feels like
a great opportunity to understand better how the protocol works by
making our own client. Let's dig into it!

<div class="note">

Check out the other posts in this series!

1. A journey to scripting Firefox Sync / Lockwise: existing clients
1. [A journey to scripting Firefox Sync / Lockwise: figuring the protocol](scripting-firefox-sync-lockwise-figuring-the-protocol.md)
1. [A journey to scripting Firefox Sync / Lockwise: understanding BrowserID](scripting-firefox-sync-lockwise-understanding-browserid.md)
1. [A journey to scripting Firefox Sync / Lockwise: hybrid OAuth](scripting-firefox-sync-lockwise-hybrid-oauth.md)
1. [A journey to scripting Firefox Sync / Lockwise: complete OAuth](scripting-firefox-sync-lockwise-complete-oauth.md)

</div>

