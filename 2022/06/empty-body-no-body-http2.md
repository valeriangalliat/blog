---
tweet: https://twitter.com/valeriangalliat/status/1532007358225862657
---

# Empty body vs. no body in HTTP/2
June 1, 2022

<abbr title="Today I learnt">TIL</abbr> there's a (subtle) difference
in HTTP/2 between sending an empty body, and sending no body at all.

In this post we'll look at **how that can happen**, how to **test it
with cURL**, and the **subtleties of HTTP/2** that make this distinction
possible.

But as usual, I'll start by telling you the story of how I ended up with
such a hairy bug again *(I'm really, really good at getting myself in
this kind of fucked up situations for some reason)*.

## Cloudflare Workers and the `Content-Length` header

At [Hookdeck](https://hookdeck.com/), we work heavily with [Cloudflare
Workers](https://workers.cloudflare.com/). And we also work heavily with
HTTP payloads.

One thing we asserted in the past, while it doesn't seem to be
officially documented, is that Cloudflare computes the `Content-Length`
header if necessary before hitting the worker.

For example when sending a HTTP/1.1 `Transfer-Encoding: chunked` payload
(typically not including `Content-Length`), Cloudflare **buffers the
whole body** and sets the `Content-Length` header before calling the
worker, despite that header not being set by the client!

We observe a similar behavior in HTTP/2 (whose `DATA` frames
[resemble chunked encoding quite a bit](https://stackoverflow.com/questions/62439557/are-chunk-extensions-supported-by-http-2-and-if-so-how)),
when the client omits the `Content-Length` header.

<div class="note">

**Note:** even if we send a payload with an invalid `Content-Length`
(e.g. claiming a size much smaller than what we actually send),
Cloudflare catches it and refuses the request!

</div>

This is especially useful: because of that observation, we can actually
trust the `Content-Length` header, and rely on it to decide what to do
next in the worker.

## The mysterious requests without `Content-Length`

How then, during an incident response, do I find myself dealing with
`POST` requests that manifestly don't have a `Content-Length` header?

My blind guess was to look at empty payloads. It's the only edge case I
could think of that could, maybe, in some cases, result in Cloudflare
not enforcing a `Content-Length` header.

At first, I try the following:

```sh
curl https://events.hookdeck.com/e/source-id-goes-here \
  -X POST \
  -H 'Content-Type: text/plain' \
  --data '' \
  --verbose
```

But I notice in the verbose logs that cURL nicely computed and sent
`Content-Length: 0`. Luckily we can turn that off by passing an empty
`Content-Length` header (which makes cURL omit the header altogether in
its request):

```sh
curl https://events.hookdeck.com/e/source-id-goes-here \
  -X POST \
  -H 'Content-Type: text/plain' \
  -H 'Content-Length:' \
  --data '' \
  --verbose
```

But somehow, Cloudflare is still able to catch this and forces a
`Content-Length: 0` to be passed to my worker.

I try something else, which in my understanding *should* be the same
thing (omitting the `--data` parameter altogether):

```sh
curl https://events.hookdeck.com/e/source-id-goes-here \
  -X POST \
  -H 'Content-Type: text/plain' \
  --verbose
```

To my surprise, although the verbose logs from cURL look *identical*,
**this results in the request hitting my worker without a
`Content-Length` header**, bypassing Cloudflare's "enforcement". Bingo!

This is a good step forward, but I'm even more confused. To my knowledge
those two commands *should* result in the exact same HTTP requests over
the wire. 🤔

<div class="note">

**Note:** at that point I had a confirmation that having no
`Content-Length` header here was, in fact, possible (in the case of some
obscure empty payloads that are different from "normal" empty payloads
*somehow*).

I went on and made sure that the code could handle that, but I wasn't
exactly *satisfied*. The *"somehow"* part of my previous sentence was
itching me in a particular manner.

</div>

## Digging deeper with `--trace`

I tried adding `--trace`, and `--trace-ascii` to the previous cURL
commands, in order to dump the raw protocol data and compare it:

```diff
 curl https://events.hookdeck.com/e/source-id-goes-here \
   -X POST \
   -H 'Content-Type: text/plain' \
   -H 'Content-Length:' \
-  --data ''
+  --data '' \
+  --trace empty-body.txt
 
 curl https://events.hookdeck.com/e/source-id-goes-here \
   -X POST \
-  -H 'Content-Type: text/plain'
+  -H 'Content-Type: text/plain' \
+  --trace no-body.txt
```

Then diffing it with:

```sh
git diff --no-index empty-body.txt no-body.txt
```

(I like the output of `git diff` more than plain old
[`diff(1)`](https://linux.die.net/man/1/diff).)

But this shows no relevant differences. Only the "SSL data" bits change,
but those are unintelligible. It otherwise appears that cURL sends
*exactly* the same thing.

How in hell could Cloudflare distinguish those two different yet
identical cURL invocations? *Hint: probably in the unintelligible
bits...*

## What about HTTP/1.1

So far, cURL defaulted to use HTTP/2, which is great. Maybe it's a
HTTP/2-specific thing? (I know, I kinda spoiled it in the title of this
post.)

I add `--http1.1` to the earlier cURL commands to try: both requests
don't have the `Content-Length` header after going through Cloudflare.
Interesting.

So there's absolutely no difference between "no data" and "empty body"
in HTTP/1.1, which makes a lot of sense based on my understanding of the
HTTP protocol. There's, finally, some sanity in this world.

So my quest is now to figure **how the f\*\*\* is Cloudflare able to
distinguish between "no body" and "empty body" in HTTP/2 specifically**.

<div class="note">

**Note:** the attentive reader might have noticed that there's virtually
no business value in answering that question.

I already knew a few ways to trigger an undefined `Content-Length` header,
and that was enough information for me to fix the bug and replay
whatever requests needed to.

At that point I'm only trying to quench my thirst of knowledge for sheer
pleasure.

</div>

## Making a PoC in C

I decide to go a bit lower level and instead of using the cURL command,
I make a C program using `libcurl` to try and reproduce that behavior.

```c
#include <curl/curl.h>

int main (void) {
    curl_global_init(CURL_GLOBAL_ALL);

    CURL *curl = curl_easy_init();

    curl_easy_setopt(curl, CURLOPT_URL, "https://events.hookdeck.com/e/source-id-goes-here");
    curl_easy_setopt(curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2TLS);
    curl_easy_setopt(curl, CURLOPT_VERBOSE, 1);

    struct curl_slist *list = NULL;

    list = curl_slist_append(list, "Content-Type: text/plain");
    list = curl_slist_append(list, "Content-Length:");

    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);

    // Empty body
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, "");

    // No body
    // curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");

    curl_easy_perform(curl);

    return 0;
}
```

Here, the `CURLOPT_POSTFIELDS` method will result in the "empty body"
path (where Cloudflare can set `Content-Length: 0` by itself), while
the "no body" version will let the request go through all the way
without `Content-Length`.

It can be compiled and run with:

```sh
gcc test.c -o test -lcurl
./test
```

But this repro doesn't really lead me anywhere. This is not
low-level enough.

## Digging even deeper with netcat

If I can't find on the client side what distinguishes those requests,
let's analyze the server side.

My first bet is to use [`nc(1)`](https://linux.die.net/man/1/nc)
(netcat) in listen mode and send my two `curl` requests to it. Then I'll
be able to see the raw data sent by cURL the underlying socket and
hopefully tell them apart:

```sh
nc -l -k -p 8888
```

(This makes netcat listen on port 8888: `-l` to listen, `-k` to keep
listening after the first connection, and `-p` to specify the port.)

Then I can hit it:

```diff
-curl https://events.hookdeck.com/e/source-id-goes-here \
+curl http://localhost:8888/ \
   -X POST \
   -H 'Content-Type: text/plain' \
   -H 'Content-Length:' \
   --data ''
 
-curl https://events.hookdeck.com/e/source-id-goes-here \
+curl http://localhost:8888/ \
   -X POST \
   -H 'Content-Type: text/plain'
```

Sadly this results in the same HTTP/1.1 request in both cases:

```http
POST / HTTP/1.1
Host: localhost:8888
User-Agent: <3
Accept: */*
Content-Type: text/plain

```

(Yes [my user agent is a heart in ASCII](https://github.com/valeriangalliat/dotfiles/blob/40ca54c1d6fdfca33e8dcc4e56807f9bf060de8e/net/curlrc#L1),
what r u gonna do?)

And adding the `--http2` flag makes cURL ask for an upgrade to HTTP/2,
but can't just send its HTTP/2 traffic right through:

```http
POST / HTTP/1.1
Host: localhost:8888
User-Agent: <3
Accept: */*
Connection: Upgrade, HTTP2-Settings
Upgrade: h2c
HTTP2-Settings: AAMAAABkAAQCAAAAAAIAAAAA
Content-Type: text/plain

```

Looks like some *negotiation* needs to happen prior to using HTTP/2.
Bummer.

## Making a HTTP/2 server with Nodes.js

If we can't *netcat* our way out of this, let's make a real HTTP/2
server with Node.js.

First we'll generate a TLS key and certificate for `localhost` because
it appears that the HTTP/2 negotiation happens over TLS. Although it
doesn't seem that the HTTP/2 spec *requires* TLS per se, I couldn't make
it work without.

```sh
openssl req -x509 -newkey rsa:2048 -nodes -subj '/CN=localhost' -keyout key.pem -out cert.pem
```

<div class="note">

**Note:** in this command, `-nodes` [means "no DES" and not "nodes"](https://stackoverflow.com/a/5087138/4324668)
and is used to leave the private key unencrypted. Without it, OpenSSL
will prompt for a passphrase.

Also the `-subj` argument is required otherwise OpenSSL will prompt for
all the certificate fields.

</div>

```js
import http2 from 'node:http2'
import fs from 'node:fs/promises'

const server = http2.createSecureServer({
  key: await fs.readFile('key.pem'),
  cert: await fs.readFile('cert.pem')
})

server.on('stream', (stream, headers, flags, rawHeaders) => {
  console.log(flags, rawHeaders)

  stream.respond({
    ':status': 200,
    'content-type': 'text/plain'
  })

  stream.end('Hello')
})

server.listen(8888)
```

For each new HTTP/2 stream, this server will log the
["associated flags"](https://nodejs.org/api/http2.html#event-stream) as
well as the raw headers, in the hope to find the key difference there.

As before, we hit it, with the addition of `--insecure` because we don't
want cURL to reject our self-signed certificate:

```diff
 curl http://localhost:8888/ \
   -X POST \
   -H 'Content-Type: text/plain' \
   -H 'Content-Length:' \
-  --data ''
+  --data '' \
+  --insecure
 
 curl http://localhost:8888/ \
   -X POST \
-  -H 'Content-Type: text/plain'
+  -H 'Content-Type: text/plain' \
+  --insecure
```

And while the raw headers are exactly the same, the flag is different:
in the first case (empty body) it's set to **4**, while for the second
one (no body) it's **5**. Bingo!

So what are those flags about anyway? The [Node.js documentation](https://nodejs.org/api/http2.html#event-stream)
doesn't say much...

> `flags` `<number>` The associated numeric flags.

## Understanding the HTTP/2 flags

We get a hint of the available flags in `http2.constants`:

```js
Object.keys(http2.constants)
  .filter(name => name.includes('_FLAG_'))
  .map(name => `${name}: ${http2.constants[name]}`)
  .join('\n')
```

```
NGHTTP2_FLAG_NONE: 0
NGHTTP2_FLAG_END_STREAM: 1
NGHTTP2_FLAG_END_HEADERS: 4
NGHTTP2_FLAG_ACK: 1
NGHTTP2_FLAG_PADDED: 8
NGHTTP2_FLAG_PRIORITY: 32
```

We're in the presence of bitwise flags. Let's "flatten" all of that in
binary, and pad them with zeroes up to 5 digits for display. This can be
done with:

```js
(number).toString(2).padStart(5, 0)
```

(Parentheses around `number` required when putting a literal number in
there.)

This gives us:

```
00100 (4) empty body
00101 (5) no body
```

And the `http2.constants` flags:

```
00000 (0) NGHTTP2_FLAG_NONE
00001 (1) NGHTTP2_FLAG_END_STREAM
00100 (4) NGHTTP2_FLAG_END_HEADERS
00001 (1) NGHTTP2_FLAG_ACK
01000 (8) NGHTTP2_FLAG_PADDED
10000 (32) NGHTTP2_FLAG_PRIORITY
```

Here we can clearly see that "empty body" is just the `END_HEADERS`
flag, whereas "no body" is a combination of `END_HEADERS` *and*
`END_STREAM`.

This is what makes Cloudflare behave in two different ways based on
those cURL requests!

If we go to [the HTTP/2 RFC](https://datatracker.ietf.org/doc/html/rfc7540)
we get extra information in [section 6.2](https://datatracker.ietf.org/doc/html/rfc7540#section-6.2):

> `END_STREAM` (0x1): When set, bit 0 indicates that the header block
>  is the last that the endpoint will send for the identified stream.
>
> `END_HEADERS` (0x4): When set, bit 2 indicates that this frame
> contains an entire header block and is not followed by any
> `CONTINUATION` frames.

## In short

While in HTTP/1.1 a request with no body (`curl -X POST`) is strictly
equivalent to a request with an empty body (`curl -X POST --data ''`),
there's a subtle difference when using HTTP/2:

A "no body" requests sets the `END_HEADERS & END_STREAM` flags on the
HTTP/2 stream, whereas an "empty body" will result in only `END_HEADERS`
(at least in the cURL implementation).

This can lead to those requests being treated slightly differently,
especially when they don't include a `Content-Length` header. In the
case of Cloudflare Workers, here's a table of **whether or not
Cloudflare computed the `Content-Length` header for us** despite not
being set by the client:

| Request                      | HTTP/1.1 | HTTP/2                             |
|------------------------------|----------|------------------------------------|
| non-empty body (chunked)     | Yes      | Yes                                |
| non-empty body (not chunked) | Illegal  | Body is always "chunked" in HTTP/2 |
| empty body                   | No       | Yes                                |
| no body                      | No       | No                                 |

<div class="note">

**Note:** in the case of the `POST` body lacking `Content-Length` and
`Transfer-Encoding: chunked`, this is effectively [forbidden](https://stackoverflow.com/questions/14758729/http-post-content-length-header-required)
in HTTP/1.1.

Cloudflare still accepts those requests, but the `Content-Length` header
will definitely not be set, and the worker will see the body as being
empty (despite the client sending actual data).

Not really supposed to happen but good to know.

</div>

## Conclusion

This was a fun issue to dig into. It wasn't necessary to go that deep in
the rabbit hole, but it was definitely a fun challenge, plus it made me
learnt quite a bit about HTTP/2 which I wasn't really up-to-date with.

I hope you enjoyed the read. Stay curious! 🤙
