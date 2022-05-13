---
tweet: https://twitter.com/valeriangalliat/status/1523114655698554880
---

# Google Cloud service account authorization without OAuth
May 7, 2022

Google's [OAuth documentation](https://developers.google.com/identity/protocols/oauth2/service-account)
goes in length about how to sign a JWT with the service account key in
order to call their token endpoint `https://oauth2.googleapis.com/token`
to get an OAuth token so that you can call actual Google Cloud APIs,
only to mention at the end in a small addendum that you can skip the
token endpoint step altogether and
[just use your self-signed JWT directly](https://developers.google.com/identity/protocols/oauth2/service-account#jwt-auth). 😬

In this blog post we'll develop this last step, because it's so much
more convenient, reliable, and there's a few undocumented things about
it.

## The normal flow

But before, let's quickly look at the "normal" recommended OAuth flow.
Borrowing this diagram from their documentation:

<figure class="center">
  <img alt="JWT OAuth flow" src="../../img/2022/05/jwt-flow.png">
</figure>

1. Create a self-signed JWT using your service account key.
1. Use it to authenticate to `https://oauth2.googleapis.com/token` to
   request an OAuth token.
1. Use that OAuth token to call Google APIs.

This is not bad, but having to go over the network to authenticate and
refresh tokens before they expire adds extra overhead, delay, error
handling, retry logic, and in general just an extra few things that can
go wrong.

And I don't like things out of my control that can go wrong.

## The better flow

On the other hand, the poorly documented "service account authorization
without OAuth method" consists in:

1. Create a self-signed JWT using your service account key.
1. Use it directly to call Google APIs.
1. Profit.

Same amount of steps, but you can imagine why I like this method better.

## Implementing direct authorization from scratch

Typically, the Google Cloud SDK in the language of your choice takes
care of this for you (and most of the time uses this self-signed method,
because they too realize it's a much superior method). But in some
cases, you have to reimplement the authorization step, for example
[when running on Cloudflare Workers](https://hookdeck.com/blog/post/how-to-call-google-cloud-apis-from-cloudflare-workers#the-problem-with-cloudflare-workers),
which I wrote about in details in that article.

As of today their [documentation](https://developers.google.com/identity/protocols/oauth2/service-account#jwt-auth)
mentions the JWT must have the following header and payload:

```json
{
  "alg": "RS256",
  "typ": "JWT",
  "kid": "SERVICE_ACCOUNT_PRIVATE_KEY_ID"
}
.
{
  "iss": "SERVICE_ACCOUNT_EMAIL",
  "sub": "SERVICE_ACCOUNT_EMAIL",
  "aud": "https://SERVICE.googleapis.com/",
  "iat": 1511900000,
  "exp": 1511903600
}
```

Where the parts in all caps are variables to adapt to your situation.
Then the JWT can be signed with RS256 (RSA signature with SHA-256), and
used in a `Authorization: Bearer` header against the service you
included in the `aud` field.

And it does work most of the time (again checkout [my post](https://hookdeck.com/blog/post/how-to-call-google-cloud-apis-from-cloudflare-workers#the-problem-with-cloudflare-workers)
to see the vanilla JavaScript implementation), but in some cases like
with Google Cloud Storage, [it breaks down](https://stackoverflow.com/q/63222450).

## When it breaks down

With Google Cloud Storage, when using the documented method with a `aud`
field of `https://storage.googleapis.com/`, we sadly [get an error](https://stackoverflow.com/q/63222450)
when calling the API, e.g. when trying to get a file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>AuthenticationRequired</Code>
  <Message>Authentication required.</Message>
</Error>
```

Or when trying to upload a file:

```json
{
  "error": {
    "code": 401,
    "message": "Invalid Credentials",
    "errors": [
      {
        "message": "Invalid Credentials",
        "domain": "global",
        "reason": "authError",
        "locationType": "header",
        "location": "Authorization"
      }
    ]
  }
}
```

But the exact same code to generate a JWT works seamlessly with Pub/Sub,
Datastore and other services! Why is that? Should we fall back to using
the OAuth endpoint for those problematic services?

No.

## The new, undocumented JWT payload

It turns out that you need to remove the `aud` field and replace it with
a `scope` field, akin to the one we would pass to the main OAuth token
endpoint.

In the case of Google Cloud Storage, our JWT payload would now look like
this:

```json
{
  "iss": "SERVICE_ACCOUNT_EMAIL",
  "sub": "SERVICE_ACCOUNT_EMAIL",
  "scope": "https://www.googleapis.com/auth/iam https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/devstorage.full_control",
  "iat": 1511900000,
  "exp": 1511903600
}
```

You can find the [full list of OAuth scopes](https://developers.google.com/identity/protocols/oauth2/scopes)
in the Google Cloud OAuth 2.0 documentation.

It turns out the `scope` field is also accepted by Pub/Sub and other
services that were working fine with `aud`, so we can just make our
generic implementation use the `scope` field and be done with it. Sweet!

## Bonus: how did I find out about that?

This is the story about [this answer](https://stackoverflow.com/a/71834557)
I posted on the Stack Overflow question I linked earlier.

First, I dug in the [Google Cloud Node.js SDK](https://github.com/googleapis/google-cloud-node)
to see how they implemented the service account authentication.

It turns out they do use the [self-signed JWT method](https://github.com/googleapis/google-auth-library-nodejs/blob/b48254490768799e465a8fa4aae13296ddceea53/src/auth/jwtclient.ts#L126),
in their shared auth library, but it's conditional to a variable
`useJWTAccessWithScope` being set to `true` by the client SDK. For
example, this is [where Pub/Sub sets it](https://github.com/googleapis/nodejs-pubsub/blob/ba333c2284b802cdd43df7568b553b2a90dba8d8/src/v1/publisher_client.ts#L139),
and this is
[where GCS **doesn't** set it](https://github.com/googleapis/nodejs-storage/search?q=useJWTAccessWithScope)
(as of today).

But what if we force this variable to `true`?

```js
import { Storage } from '@google-cloud/storage'

const storage = new Storage()

storage.authClient.useJWTAccessWithScope = true

const file = await storage.bucket('bucket').file('file').get()
```

By running this script with `NODE_DEBUG=https`, we can see that without
the `useJWTAccessWithScope` line, the client makes a call to
`https://www.googleapis.com/oauth2/v4/token` first, then calls
`https://storage.googleapis.com/storage/v1/b/bucket/o/file`, but with
`useJWTAccessWithScope`, it skips the first token call (and everything
works still)!

We can also notice that the token from the OAuth token endpoint contains
hundreds of dots (`.`) at the end, whereas the self-signed token is just
the usual 3 parts Base64URL JWT. Not an useful information, but
interesting.

Either way, this proved that despite not working with the method in the
documentation, self-signed authentication was effectively supported by
Google Cloud Storage. So how did that SDK-generated token differ? The
easiest is to copy that token from our `NODE_DEBUG=https` output and
parse the payload segment:

```sh
pbpaste | cut -d. -f2 | base64 --decode
```

Or in Node.js:

```js
Buffer.from(token.split('.')[1], 'base64').toString()
```

There we see they use a `scope` parameter as opposed to `aud`.

We can track it down to the [code of the authentication library](https://github.com/googleapis/google-auth-library-nodejs/blob/b48254490768799e465a8fa4aae13296ddceea53/src/auth/jwtclient.ts#L191),
and we can also see where the Google Cloud Storage client
[defines the necessary OAuth scopes](https://github.com/googleapis/nodejs-storage/blob/c3240060b3dc905013ab6fa219e975631b41f5c4/src/storage.ts#L653).

## Conclusion

With some investigation in the Google Cloud Node.js SDK source code and
some `NODE_DEBUG=https` debugging, we can dissect their implementation
of the self-signed service account authentication, and replicate it on
our side.

This enables us to use this simpler and superior mechanism that Google
uses internally, instead of the method that's widely documented of
calling their OAuth endpoint.

I hope that you learnt something thanks to this article, and that it
helps you build great things! And as always, keep hacking! 🚀
