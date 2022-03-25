# Clearing cookies: the spec vs. the browser implementations
March 25, 2022

I was watching the awesome
[Stanford CS 253 course about web security](https://www.youtube.com/playlist?list=PL1y1iaEtjSYiiSGVlL1cHsXN_kvJOOhu-)
by [Feross](https://feross.org/), that he graciously made available for
free on YouTube, and in [lecture 4, at 35:32](https://youtu.be/0-q69vAYSwo?t=2132),
one thing bugged me about **clearing cookies**.

> When you actually go to clear the cookies [...], you got to make sure
> that all the other attributes are also exactly the same than when it
> was set.
>
> It's a little bit jinky, because if you don't do this, the browser
> thinks that it's actually a separate cookie with the same name.

In code, using Node.js and Express, this looks like this:

```js
res.cookie('sessionId', sessionId, {
  secure: true,
  httpOnly: true,
  sameSite: 'lax',
  maxAge: 30 * 24 * 60 * 60 * 1000 // 30 days
})

res.clearCookie('sessionId', {
  secure: true,
  httpOnly: true,
  sameSite: 'lax'
})
```

Or on plain HTTP:

```http
Set-Cookie: sessionId=...; MaxAge=...; Path=/; HttpOnly; Secure; SameSite=Lax

Set-Cookie: sessionId=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; Secure; SameSite=Lax
```

That was quite a gotcha moment for me because I've been dealing with
cookies all my career as a web developer and I had no idea about that.
I'm also pretty I've been using `HttpOnly`,  `Secure` and `SameSite`
when setting cookies in the past, and don't remember having issues when
clearing them without those flags.

## The Express documentation

The first step is to look at the [`res.clearCookie` documentation](https://expressjs.com/en/api.html#res.clearCookie).

Indeed, there's a warning box with the following message:

> Web browsers and other compliant clients will only clear the cookie if
> the given `options` is identical to those given to `res.cookie()`,
> excluding `expires` and `maxAge`.

There's no source for what "compliant clients" means here though.

## The spec

By digging a bit, we find [this issue](https://github.com/expressjs/express/issues/3874)
on the Express repo, from someone else that was apparently bugged by
this same warning a few years ago.

An Express maintainer jumps in with a link to the [HTTP cookies RFC](https://tools.ietf.org/search/rfc6265), in
particular the [storage model](https://tools.ietf.org/search/rfc6265#section-5.3)
part:

> Ah, here is the specifics: <https://tools.ietf.org/search/rfc6265#section-5.3>.
>
> I hope that helps! It's the specification of exactly how clients are
> supposed to set cookies, and outlines the algorithm of how to set the
> cookie even when a given cookie already exists. It notes the following
> have to match: `domain`, `path`, `httpOnly` if the `name` already
> exists in the store (see step 11). The list of attributes in that spec
> is not comprehensive, as additional attributes were added by other
> specs, which I suspect define their own behaviors.

And here's the part 11 of the spec that was referred to here:

> 11. If the cookie store contains a cookie with the same name,
>     domain, and path as the newly created cookie:
>
>     1. Let old-cookie be the existing cookie with the same name,
>        domain, and path as the newly created cookie.  (Notice that
>        this algorithm maintains the invariant that there is at most
>        one such cookie.)
>
>     2. If the newly created cookie was received from a "non-HTTP"
>        API and the old-cookie's http-only-flag is set, abort these
>        steps and ignore the newly created cookie entirely.
>
>     3. Update the creation-time of the newly created cookie to
>        match the creation-time of the old-cookie.
>
>     4. Remove the old-cookie from the cookie store.

My understanding of the spec is that indeed `name`, `domain` and `path`
are all used to identify a specific cookie, so a cookie with the same
`name` but different `domain` or `path` won't match. For `httpOnly` though,
it only mentions that if a non-HTTP API tries to expire an existing
`httpOnly` cookie (e.g. by doing `document.cookie = '...'`), this call
will be ignored, which makes sense.

But `httpOnly` is not used to match a cookie otherwise. A HTTP response
can expire a `httpOnly` cookie without setting `httpOnly` in the
`Set-Cookie` options, as long as the `name`, `domain` and `path` match.

As for additional attributes by newer specs like `secure` and
`sameSite`, no behavior seem to be documented but in practice they don't
seem to matter, like `httpOnly`.

## Real-life example

Let's build a server with an endpoint that sets a cookie with `secure`,
`httpOnly` and `sameSite`, and another endpoint that clears the cookie
without passing any option.

```js
const express = require('express')
const cookieParser = require('cookie-parser')

const app = express()

app.use(cookieParser())

app.get('/', (req, res) => {
  res.json(req.cookies)
})

app.get('/set', (req, res) => {
  res.cookie('foo', 'bar', {
    secure: true,
    httpOnly: true,
    sameSite: 'lax',
    maxAge: 30 * 24 * 60 * 60 * 1000
  })

  res.redirect('/')
})

app.get('/clear', (req, res) => {
  res.clearCookie('foo')
  res.redirect('/')
})

app.listen(9999)
```

Interestingly, it appears that both Chrome and Firefox allow cookies
with the `secure` attribute to be set on `http://localhost`, which is
convenient to test this feature. Note that on a "real" domain, you
would need to use HTTPS for `secure` cookies to be accepted.

If you browse to `http://localhost:9999` with Chrome or Firefox, you'll
see an empty JSON object (or whatever cookies already existed on
`localhost`).

By going to `/set`, a cookie will be set with
`foo=bar; MaxAge=...; Path=/; HttpOnly; Secure; SameSite=Lax`, and
redirect to `/`, showing that the cookie is set.

By going to `/clear`, the cookie will be cleared with `foo=; Path=/;
Expires=Thu, 01 Jan 1970 00:00:00 GMT`, then redirect to `/`. We can see
there that the cookie was effectively deleted, without needing to
specify other options.

If we repeat the test this time with a different domain or path, we can
see that they indeed need to match with the cookie that was previously
set in order to clear it.

## The browsers source code

We can confirm what we experienced by looking at the source code of
Chrome and Firefox.

Here's the [Firefox code that identifies a cookie from its
attributes](https://github.com/julienw/mozilla-central/blob/04464210145f8f7921447380d76efe0757243610/netwerk/cookie/nsCookieService.cpp#L5167):

```cpp
if (aHost.Equals(cookie->Host()) &&
    aPath.Equals(cookie->Path()) &&
    aName.Equals(cookie->Name())) {
  aIter = nsListIter(entry, i);
  return true;
}
```

As we can see, it only uses the `host`, `path` and `name` to identify a
cookie.

On the Chrome side, [the code to test cookie equivalence](https://source.chromium.org/chromium/chromium/src/+/main:net/cookies/canonical_cookie.h;drc=379f47d8daef415d929fe269e35e2bd432e1adb4;l=226):

```cpp
// Are the cookies considered equivalent in the eyes of RFC 2965.
// The RFC says that name must match (case-sensitive), domain must
// match (case insensitive), and path must match (case sensitive).
// For the case insensitive domain compare, we rely on the domain
// having been canonicalized (in
// GetCookieDomainWithString->CanonicalizeHost).
// If partitioned cookies are enabled, then we check the cookies have the same
// partition key in addition to the checks in RFC 2965.
bool IsEquivalent(const CanonicalCookie& ecc) const {
  // It seems like it would make sense to take secure, httponly, and samesite
  // into account, but the RFC doesn't specify this.
  // NOTE: Keep this logic in-sync with TrimDuplicateCookiesForKey().
  return UniqueKey() == ecc.UniqueKey();
}

// Returns a key such that two cookies with the same UniqueKey() are
// guaranteed to be equivalent in the sense of IsEquivalent().
// The `partition_key_` field will always be nullopt when partitioned cookies
// are not enabled.
UniqueCookieKey UniqueKey() const {
  return std::make_tuple(partition_key_, name_, domain_, path_);
}
```

Interestingly, they mention that "it seems like it would make sense to
take `secure`, `httpOnly`, and `sameSite` into account, but the RFC
doesn't specify this".

## Conclusion

Cookies are identified by their `name`, `domain` and `path`. On a single
site, you can have multiple cookies with the same `name` if their
`domain` or `path` differ.

This means that at the time of expiring a cookie, the `name`
(obviously) as well as `domain` and `path` much be the same as when the
cookie was originally set, otherwise it will be treated as a different
cookie and won't result in the intended cookie being cleared.

Other attributes like `secure`, `httpOnly` and `sameSite` are not used
to distinguish cookies. They are only *attributes* of an existing cookie
(addressed by its `name`, `domain` and `path` as we just saw) and you
don't need to specify them when clearing a cookie (although it doesn't
hurt to include them, but they don't have to match either). Both Chrome
and Firefox are currently consistent in that implementation.

That being said, it seems that the Chrome team believes that it would
make sense to also use `secure`, `httpOnly` and `sameSite` to address
cookies, even though they don't currently implement it that way, since
the RFC doesn't specify this. If this was to change in the future, and
because specifying those attributes when clearing a cookie doesn't cause
issues with the current implementation, **I would advise to specify all
the attributes when clearing the cookie** just to be on the safe side.

In my example code earlier, I would recommend to rewrite it as:

```js
app.get('/set', (req, res) => {
  res.cookie('foo', 'bar', {
    secure: true,
    httpOnly: true,
    sameSite: 'lax',
    maxAge: 30 * 24 * 60 * 60 * 1000
  })

  res.redirect('/')
})

app.get('/clear', (req, res) => {
  res.clearCookie('foo', {
    secure: true,
    httpOnly: true,
    sameSite: 'lax'
  })

  res.redirect('/')
})
```
