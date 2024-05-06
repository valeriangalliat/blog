# Using Google Chrome instead of Chromium in Google Cloud Functions
May 5, 2024

When using Puppeteer, Playwright and similar, you need to have Chrome
installed. When you're running on AWS Lambda or Google Cloud Functions,
it can get tricky.

Google Cloud Functions _used to_ bundle Chromium in their base images,
but it's been a few years it's no longer the case. That's where packages
like [`chrome-aws-lambda`](https://github.com/alixaxel/chrome-aws-lambda)
come in handy, by bundling Chromium directly inside a npm package, and
exposing a function that extracts the Chromium binary and returns the
path:

```js
const chromium = require('chrome-aws-lambda')

const path = await chromium.executablePath
```

<div class="note">

**Note:** unnecessary pedantic detail: the above code doesn't look like a function,
but [it is, in fact](https://github.com/alixaxel/chrome-aws-lambda/blob/f9d5a9ff0282ef8e172a29d6d077efc468ca3c76/source/index.ts#L147),
a getter function that returns a promise. 😄

</div>

However that's Chromium, and you may have reasons to want Google Chrome
instead (mainly, proprietary codecs).

## A totally unrelated note about AWS Lambda

This article is about Google Cloud Functions, but if you're on AWS
Lambda, the above option is your best bet. Because of the Lambda total
size limit of 250 MB (all layers combined), it's really hard to get a
binary of Chrome that fits in there.

That's why `chrome-aws-lambda` uses [LambdaFS](https://github.com/alixaxel/lambdafs)
under the hood, to aggressively compress the Chrome installation with
Brotli and make it fit in that limited space.

But again with that build, you won't have proprietary codecs. I tried to
trim down a Chrome Linux build and compress it with the same technique
but never managed to make it fit on AWS Lambda. Recent Chrome versions
are just too big.

There's another option, which is to compile Chromium yourself with
proprietary codecs. I never found any prebuilt binaries of Chromium that
include proprietary codecs (maybe because of license issues
redistributing them 🙃) so you're on your own here.

[Remotion](https://www.remotion.dev/) successfully does that for
[Remotion Lambda](https://www.remotion.dev/docs/lambda).
Here's [their instructions](https://github.com/remotion-dev/chrome-build-instructions)
to compile Chromium with proprietary codecs for Lambda.

Fair warning: it gets hairy, fast.

## Back to Google Cloud Functions

Google Cloud Functions is more generous as for bundle size, so we don't
need to resort to those tricks, and we can include a complete,
uncompressed, Google Chrome installation.

Google publishes [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/),
builds [specifically made](https://developer.chrome.com/blog/chrome-for-testing)
for headless usage.

We can just download the latest build from there as part of the
`gcp-build` script in our `package.json`.

```json
{
  "scripts": {
    "gcp-build": "curl -s -O 'https://storage.googleapis.com/chrome-for-testing-public/124.0.6367.91/linux64/chrome-linux64.zip' && unzip chrome-linux64.zip && rm chrome-linux64.zip"
  }
}
```

<div class="note">

**Note:** the `gcp-build` script allows you to [run a custom build step](https://cloud.google.com/appengine/docs/standard/nodejs/running-custom-build-step)
in Google Cloud Build, which is what Cloud Functions (both 1st and 2nd
gen, as well as Cloud Run and App Engine) use to build your function
image.

It would work just fine with a `postinstall` script as well, but
`gcp-build` makes sure you run it only on Google Cloud Build, which is
probably desirable in this particular case.

</div>

You will then have the Chrome binary in `chrome-linux64/chrome`, that
you can pass to the tool of your choice.

## With Puppeteer

Courtesy of [this post](https://medium.com/@jackklpan/run-puppeteer-in-google-cloud-functions-v2-b18a353e609b),
with Puppeteer, you don't need to download Chrome manually, since it
provides a nifty script to do just that.

Actually, Puppeteer's [`postinstall` script](https://github.com/puppeteer/puppeteer/blob/f23646b3526aa87145c17b22e9967ec8f77d82d2/packages/puppeteer/package.json#L41)
automatically downloads the latest version of Chrome for Testing for
your platform.

The caveat is that this script by default installs it to
`~/.cache/puppeteer`, which in the case of Google Cloud Build, is not
gonna be preserved in the final image. So we need to instruct Puppeteer
to install Chrome in a directory that Cloud Build will keep.

This can be done with the following `.puppeteerrc.js`:

```js
module.exports = {
  cacheDirectory: `${__dirname}/.cache/puppeteer`
}
```

But even then, there's another caveat. Puppeteer's `postinstall` script
will only run after it gets installed. However, because of build
caching, you will get in a state where `node_modules` is restored, with
Puppeteer already installed (so `postinstall` will _not_ run), but the
`.cache/puppeteer` directory will also _not_ be restored.

To mitigate that, we need to make sure to install Chrome systematically.
Again we can leverage the `gcp-build` for that:

```json
{
  "scripts": {
    "gcp-build": "npx puppeteer browsers install chrome"
  }
}
```

<div class="note">

**Note:** you could call Puppeteer's `postinstall` script directly by
doing `node node_modules/puppeteer/install.mjs` instead, but I found the
above command cleaner.

</div>

The good thing is that this script knows to not re-download Chrome if
it's already found in the cache directory, so when the `postinstall`
script _does_ run, the extra `gcp-build` command will be a no-op.
