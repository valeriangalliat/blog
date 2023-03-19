# Google OAuth from a CLI application
February 25, 2021

<div class="note">

**Update:** Google dropped the support for the `oob` method described in
this post. We now can't be lazy anymore and need to implement a
`localhost` redirect URL. See [local server redirect](#update-local-server-redirect)!

</div>

I like to make command line (CLI) applications and scripts, and some of
them require to authenticate with a Google account.

This requires OAuth, and the most popular and most documented way is
from a web server and web application, where you redirect to (or open a
pop-up to) a Google auth URL, giving it a redirect URL that they...
redirect to once the auth is complete.

Since the URL can be on `localhost`, this is not an issue for a CLI that
runs on the user device, but it gets fairly annoying if the CLI runs on
another device (e.g. a server).

Or I mean, if your app doesn't have a web server otherwise, you might
just be lazy to implement one solely for the sake of OAuth.

## A note about limited input devices

If your app runs on a TV, a toaster or some other kind of device where
the user can't open a link on the device itself to log in, you can use
the [limited input device flow] which lets you display a short URL and
code so that Google can authenticate the user on your app without having
to type anything on the actual device.

[limited input device flow]: https://developers.google.com/identity/protocols/oauth2/limited-input-device

This is a cool option to know about, but as far as I'm concerned, I can
afford showing a fairly long URL in my CLI output for the user to
open in their browser, so that's what we're going to look at today.

## Application authentication flow

Everything is documented [here][native-app] (look up "manual
copy/paste") but I'll quickly go over the basics in this article, with
some JavaScript examples on Node.js.

[native-app]: https://developers.google.com/identity/protocols/oauth2/native-app

First, [in Google Cloud Platform](https://console.cloud.google.com/apis/credentials), 
you need to create a Oauth client ID of type <kbd>Desktop</kbd>. This
will give you a client ID and client secret that you can configure
in your app.

```js
const clientId = 'your client ID'
const clientSecret = 'your client secret'
```

Then you can create an OAuth client using the SDK.

```js
const { google } = require('googleapis')

const oauth2Client = new google.auth.OAuth2(clientId, clientSecret, 'urn:ietf:wg:oauth:2.0:oob')
```

The third parameter here is the redirect URL, where the Google auth page
would normally redirect to when the authentication is complete.

As I mentioned earlier, we don't want to deal with a web server, which
is why we use the string `urn:ietf:wg:oauth:2.0:oob` instead (look it up
in [the documentation][native-app] for more details). This tells Google to
show a code to the user instead of redirecting, which they can then
paste into your app to complete the process.

Here's an example.

```js
const readline = require('readline')

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
})

const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: [
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/userinfo.email'
  ]
})

console.log('Authorize this app by visiting this URL: ', authUrl)
const code = await new Promise(resolve => rl.question('Enter the code from that page here: ', resolve))
rl.close()

const { tokens } = await oauth2Client.getToken(code)

oauth2Client.setCredentials(tokens)
```

Your `oauth2Client` is now authenticated, and you can use it to access
the Google APIs that you requested in your scope, for example for
YouTube (had we asked for the `https://www.googleapis.com/auth/youtube` scope):

```js
const youtube = google.youtube({
  version: 'v3',
  auth: oauth2Client
})
```

## Bonus: integrating with Firebase

By default, Firebase's Google auth provider only comes with the option to
redirect or open a pop-up, which won't work in a CLI environment, but
they also give you the option to authenticate using a Google auth token.

This is the `id_token` of the token object we retrieved earlier using
the application authentication flow.

Which means we can easily do the following:

```js
const firebase = require('firebase')

const app = firebase.initializeApp({
  // Your config goes here.
})

const auth = app.auth()
const provider = new firebase.auth.GoogleAuthProvider()

// Here, `tokens` is the result of `oauth2Client.getToken` in the earlier example.
const credential = firebase.auth.GoogleAuthProvider.credential(tokens.id_token)
const result = await auth.signInWithCredential(credential)

console.log(result)
```

## Update: local server redirect

Since October 2022, the method described in this post [got deprecated](https://developers.google.com/identity/protocols/oauth2/native-app#manual-copypaste).

We now don't have a choice but spawning a local HTTP server to handle
the redirect URL. I'll past my updated implementation below in case it
can help you getting started with this method.

It works by calling `server.listen()` without passing a port, so the OS
can automatically allocate an available port, and we read it using
`server.address().port` in order to define the redirect URL dynamically.

```js
const http = require('http')
const { google } = require('googleapis')

const clientId = 'your client ID'
const clientSecret = 'your client secret'

let resolve

const codePromise = new Promise((resolve_) => {
  resolve = resolve_
})

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost')

  if (url.pathname !== '/') {
    res.writeHead(404).end('Not Found')
    return
  }

  const code = url.searchParams.get('code')

  if (!code) {
    res.writeHead(400).end('Bad Request')
    return
  }

  res.end('OK')
  server.close()
  resolve(code)
})

server.listen()

const port = server.address().port
const redirect = `http://localhost:${port}`

const oauth2Client = new google.auth.OAuth2(clientId, clientSecret, redirect)

const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: ['https://www.googleapis.com/auth/youtube']
})

console.log('Authorize this app by visiting this URL: ', authUrl)

const code = await codePromise
const { tokens } = await oauth2Client.getToken(code)

oauth2Client.setCredentials(tokens)
```
