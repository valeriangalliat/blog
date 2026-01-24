---
tweet: https://x.com/valeriangalliat/status/1440401250927857668
---

# Vercel custom log drain (dump HTTP traffic for free on a Vercel app)
With Google Cloud free tier and nginx shenanigans  
September 21, 2021

In the [previous post](free-static-hosting-server-side-analytics.md), we
compared the different services providing free static website hosting,
and their options to access server-side web analytics or raw HTTP logs.

[Vercel](https://vercel.com/) was the only one to allow accessing
traffic data for free, but it's not the easiest thing to do. In this
article, I'll show you how.

<div class="note">

**Note:** if you're in a rush, go straight to the [GitHub repo](https://github.com/valeriangalliat/vercel-custom-log-drain)
which contains the full code for a working integration that allows you
to manage arbitrary log drains!

I also give you the link to the [live integration that I use for myself](https://vercel.com/integrations/custom-log-drain),
and you can use it too!

Otherwise, if you're interested in the underlying implementation, read
on.

</div>

I'll assume that you already have an account with Vercel and deployed
your app there. This shouldn't be too bad, but if you like to keep
things simple, you might want to read a few tips of mine about [keeping Vercel clean and silent](vercel-without-preview-deployments.md).

Neither of Vercel's UI, CLI and API directly allow to manage log drains.
While [the API has endpoints to manage log drains](https://vercel.com/docs/rest-api#integrations/log-drains),
those are only available to Vercel integrations, and are denied when
called with a [regular user token](https://vercel.com/account/tokens)
like the ones the CLI and web app use.

This means that we'll need to create our own Vercel integration in order
to have an integration token that will let us call the log drains API.

## How does a Vercel integration work

* A Vercel integration is a web app hosted on your own domain, which
  needs to respond to a "Vercel callback" page.
* Vercel will redirect the user to that page when they try to install
  your integration, providing a `code` and `next` query parameters.
* You can exchange the `code` parameter for a Vercel API OAuth access token.
* You're expected to redirect to the URL provided in the `next`
  parameter once the installation is complete.

Most integrations will store the OAuth access token and refresh token
that are exchanged during that process to be able to query the API on
behalf of the user later on, but for cost and time reasons, **I want to
keep my integration stateless**. This means that I'll perform the log
drain operations only during the installation process, and **will
instantly forget the token**.

Because of that, we'll have to remove the integration and add it again
if we want to configure a new log drain. Log drains are specific to an
integration, meaning that when you remove the integration, the log
drains are removed with it too.

I could have built a stateful application where I allow to fully manage
log drains, but then I would need to charge for it to pay for the
hosting and development costs, and at that point I believe that most
users who are willing to pay will be happy to pay for Logtrail,
Sematext, Datadog, LogDNA and others that already have an official
Vercel integration.

<div class="note">

**Note:** if I'm wrong with that assumption, and you would pay a monthly
fee for a service that allows you to fully manage your Vercel log drains
with arbitrary URLs, [let me know](/val.md#contact). If there's enough
demand I'll consider building something!

</div>

## Creating our own Vercel integration

For this, head to the [Vercel integrations console](https://vercel.com/dashboard/integrations/console),
which lists you all the integrations that you have created, and allows
you to create new ones.

Click the "create" button. In that form, you need to fill a bunch of
details about your integration that should be pretty obvious.

You'll need to include the redirect URL. If you want to use [the repo I mentioned earlier](https://github.com/valeriangalliat/vercel-custom-log-drain),
it's going to be on the `/vercel/callback` path, on the domain you're
going to host it on.

You can ignore the webhook and configuration URLs unless you want to
build a stateful version that allows editing the log drains after
installation (then you'd need the configuration URL specifically).

### Making the form

We'll go for a very basic HTML form that allows selecting between
`json`, `ndjson` and `syslog` as the log drain type, which are the only
formats supported by Vercel as of writing, as well as the URL to the log
drain we want to add.


```html
<form method="post">
  <p>
    <select name="type">
      <option value="json">json</option>
      <option value="ndjson">ndjson</option>
      <option value="syslog">syslog</option>
    </select>
    <input type="text" name="url" placeholder="URL">
    <button type="submit">Submit</button>
  </p>
</form>
```

See the [full HTML](https://github.com/valeriangalliat/vercel-custom-log-drain/blob/master/form.html)
with a tiny layer of CSS.

### Serving the form

I'll use [Fastify](https://www.fastify.io/) to handle the HTTP requests,
but [Express](https://expressjs.com/) would have worked just fine for
this too.

```js
const fs = require('fs')
const fastify = require('fastify')

const form = fs.readFileSync('form.html', 'utf8')

const app = fastify({ logger: true })

app.get('/vercel/callback', (req, res) => {
  if (!req.query.code || !req.query.next) {
    return res.type('text/plain').send('Hello!')
  }

  res.type('text/html').send(form)
})


app.listen(process.env.PORT || 8080, err => {
  if (err) {
    app.log.error(err)
    process.exit(1)
  }
})
```

This gets us running with a simple app that serves the form we just
built on `/vercel/callback`.

If called without `code` and `next` parameters, it means we're not being
redirected from Vercel integration installation, and we just show a
simple message to say hello, because the form wouldn't be useful when
it's not called from Vercel.

### Handling the form

First, we'll need to trade the `code` parameter for a Vercel OAuth
access token. We can do that by calling the `https://api.vercel.com/v2/oauth/access_token`.

This requires us to configure the OAuth client ID and client secret that
were provided to you at the end of the [integration creation](#creating-our-own-vercel-integration),
as well as the redirect URL that we defined during creation.

```js
const qs = require('querystring')
const fetch = require('node-fetch')
const config = require('./config')

async function getToken (code) {
  const url = 'https://api.vercel.com/v2/oauth/access_token'

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: qs.stringify({
      client_id: config.clientId,
      client_secret: config.clientSecret,
      code,
      redirect_uri: config.redirectUri
    })
  })

  if (!res.ok) {
    throw new Error(`${url} responded with ${res.status}`)
  }

  const json = await res.json()

  return json.access_token
}
```

With that token, we can call the log drains endpoint to create a new log
drain.


```js
async function createLogDrain (token, body) {
  const url = 'https://api.vercel.com/v1/integrations/log-drains'

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify(body)
  })

  if (!res.ok) {
    throw new Error(`${url} responded with ${res.status}`)
  }
}
```

Now, we can put those together when handling the `POST` form submission,
as well as redirecting to the `next` URL at the end.

```js
const formBody = require('fastify-formbody')

app.register(formBody)

app.post('/vercel/callback', async (req, res) => {
  if (!req.query.code || !req.query.next || !req.body.type || !req.body.url) {
    return res.code(400)
  }

  const token = await getToken(req.query.code)

  await createLogDrain(token, {
    name: 'custom-log-drain',
    type: req.body.type,
    url: req.body.url
  })

  res.redirect(req.query.next)
})
```

You can see [the full code on GitHub](https://github.com/valeriangalliat/vercel-custom-log-drain/blob/master/index.js).

After deploying that code, you should be able to use your custom
integration from the integration marketplace to configure any log drain
you want for your Vercel apps.

You can hack on this code if you want to allow setting up the log drain
only on certain apps and not globally (see other [request parameters](https://vercel.com/docs/rest-api#integrations/log-drains/create-a-log-drain/request-parameters)),
or make it stateful with the option to edit and remove existing log
drains without having to reinstall the integration.

## Making a simple log drain with nginx

Now, we only solved half of the problem. We can configure any URL as a
log drain on our Vercel apps, but we don't have a URL to put there yet!
Most of the logging software as a service apps already have
[an integration on the marketplace](https://vercel.com/integrations#logging).

Instead, we want to provide our own URL to handle the logs, in a way
that's the cheapest as possible, or ideally free.

For that, we're going to leverage the Google Cloud free tier, which
includes one `e2-micro` instance for free per billing account.

It should be easy to get one running and to install nginx on it.

<div class="note">

**Note:** if you're interested in how I do the initial configuration of
a Debian Google Cloud VM, I'll have an article about that very soon.
Stay tuned!

</div>

Then, we're going to use a cool "hack" that allows us to configure nginx
to append the `POST` body of an endpoint directly to the file of our
choice. This is essentially the definition of a simple HTTP log
drain.

First, we'll define a `postdata` log format that logs the plain
unescaped request body to the log file:

```nginx
http {
    log_format postdata escape=none $request_body;
}
```

But we can't just us it like this. By default, nginx won't bother
reading the request body if it's not doing anything with it, which means
it won't be included in the log variables.

There's two ways to force nginx to read the request body. One is with the
[nginx `echo` module](https://github.com/openresty/echo-nginx-module),
and the other one (fully native) leverages a hack with the `proxy_pass`
directive.

In both cases, you'll be able to configure `https://your.domain/vercel/drain`
as a Vercel log drain. I find that NDJSON works best with this format.

### With `echo_read_request_body`

```nginx
# Make sure this is loaded, method may vary depending on your setup.
load_module modules/ngx_http_echo_module.so;

server {
    location /vercel/drain {
        access_log off;

        if ($request_method = POST) {
            # Wherever you want to store your logs.
            access_log /path/to/vercel.log postdata;

            # Required to force nginx to read the request body,
            # otherwise it won't log anything.
            echo_read_request_body;
        }
    }
}
```

### With `proxy_pass` hack

If you don't want to load `ngx_http_echo_module`, you can instead use
the native `proxy_pass` directive to force nginx to read the request
body.

Since `proxy_pass` needs to proxy to *something*, the trick consists
into defining a "black hole" endpoint to proxy to. Because `proxy_pass`
will need to read the whole HTTP body in order to forward it, it will
become accessible to our log format.

```nginx
server {
    location /vercel/empty {
      return 204;
    }

    location /vercel/drain {
        access_log off;

        if ($request_method = POST) {
            access_log /path/to/vercel.log postdata;

            # Adapt this to whatever your server responds to, or
            # feel free to use `$scheme`, `$server_name`, `$host`,
            # `$server_port` and so on.
            proxy_pass http://localhost/vercel/empty;
        }
    }
}
```

## Wrapping up

You should now have everything you need to store your Vercel logs in
plain text files on a Google Cloud free tier VM (or wherever else you
wanted to)!

You're now free to `grep` through them or do whatever magic you want
with the data to get all the stats and insights that you want. And all
of that for free (or nearly).

<div class="note">

**Note:** if you need to forward your Vercel logs to a custom endpoint
but this article was too technical for you, feel free to [contact me](/val.md#contact),
I'm available for [freelance work](/freelance.md) and I'll be
happy to help you with that. ✌️

</div>
