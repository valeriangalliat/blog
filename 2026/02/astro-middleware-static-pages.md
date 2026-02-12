---
tweet: https://x.com/valeriangalliat/status/2021761871104430267
---

# Run Astro middleware in front of static pages (Cloudflare Workers)
February 11, 2026

Astro allows to prerender pages as static assets, so everything is
compiled at build time and can be served super quick.

But also, Astro has the concept of a middleware, that allows to run
custom logic in front of every request, which can be handy for things
like auth, redirects, proxying and more.

The problem? [The middleware is not run for static pages](https://github.com/withastro/roadmap/discussions/869).

## Why run the middleware on static pages?

In many cases this is not a problem, because you may not often need to
run custom logic in front of static pages. After all if those pages
needed custom logic per request, they'd probably be dynamic.

Pages behind auth are most likely dynamic so the content can be
contextual to the logged-in user. As for redirects and proxies, they
usually make sense _when no actual page_ matches the URL, and Astro runs
the middleware in both those cases.

However my use case is a bit different. I'd like to get a sense of what
pages are visited on my site, and I don't like the idea of client-side
tracking, partly because of the privacy stigma, and partly because "you
can't trust the client".

### Unnecessary note on client-side tracking

At that point it seems that mostly everyone on the internet does
client-side tracking, including every business I ever worked with. Yet I
never encountered cases where the data got heavily manipulated.

The only anomalies I ever noticed are the occasional pen test with all
sorts of injection attempts, but those typically just get ignored at
ingestion because the data is broken, or at worst, it breaks queries
because corrupted data _was_ ingested (read: data type mismatch,
hopefully we know how to avoid SQL injections by now).

However it seems that most people have something else to do than
programmatically sending well formatted but fake tracking data on public
endpoints for the mere pleasure of causing chaos for someone else.

Despite that, I'm still allergic to client-side tracking because _on
paper_ this is all still possible.

#### Unnecessary note on HTTP logs

You could say I can achieve all this with HTTP logs without bothering
with an edge worker, and you'd be 100% right. However,
Cloudflare [only gives access to HTTP logs to Enterprise customers](https://developers.cloudflare.com/logs/logpush/#availability)
and this is not exactly an interesting option for me right now.

If not for that it would definitely be my favorite solution.

## Running backend code in front of static pages

Back to the topic. Sadly there's no generic way I found to run the
Astro middleware in front of static pages. This means the solution is
gonna be dependent on your _adapter_. In my case, I'm using the
[Cloudflare adapter](https://docs.astro.build/en/guides/integrations-guide/cloudflare/).

We have two layers to deal with here. Out of the box the logic is as
follows:

* Cloudflare Workers:
  * If there's a static asset that matches the URL, serve that.
  * Otherwise, run the Astro `worker.js`.
* Astro `worker.js`:
  * If there's a static asset that matches the URL, serve that.
  * Otherwise, run the user-provided middleware.

## The Cloudflare part

In order to mitigate the _first_ layer (Cloudflare), we need to
configure the runtime to run the worker code in front to some or all
static assets. This is done in `wrangler.jsonc` using the
`run_worker_first` directive
([relevant](https://developers.cloudflare.com/workers/static-assets/routing/worker-script/#run-your-worker-script-first)
[docs](https://developers.cloudflare.com/workers/static-assets/binding/#run_worker_first)):

```json
{
  "assets": {
    "binding": "ASSETS",
    "directory": "./dist",
    "run_worker_first": [
      "/",
      "/en",
      "/en/*",
      "/fr",
      "/fr/*",
    ],
}
```

In this case I force the worker to run for the index, as well as `/en`,
`/fr` and anything under.

This means for other assets like JS/CSS/images, we still skip the
worker, but for the static pages I have that match those paths,
Cloudflare will run the edge worker.

## The Astro part

Now we have Cloudflare run the Astro worker in front of static pages,
but it's still not enough, because the Astro Cloudflare adapter
[skips our middleware](https://github.com/withastro/astro/blob/8780ff2926d59ed196c70032d2ae274b8415655c/packages/integrations/cloudflare/src/utils/handler.ts#L53-L56)
anyway when a static asset matches.

```ts
if (app.manifest.assets.has(requestPathname)) {
  return env.ASSETS.fetch(request.url.replace(/\.html$/, ''))
}
```

In order to solve that, we can't use the Astro middleware anymore.
Instead we need to configure a custom entry point for the worker. This
means we now control the top-level worker code and run our logic there,
regardless what the adapter decides to do.

This is done with [`workerEntryPoint` option](https://docs.astro.build/en/guides/integrations-guide/cloudflare/#workerentrypoint)
in `astro.config.mjs`:

```js
import { defineConfig } from 'astro/config'
import cloudflare from '@astrojs/cloudflare'

export default defineConfig({
  // ...

  adapter: cloudflare({
    workerEntryPoint: {
      path: 'src/worker.ts',
    },
  }),

  // ...
})
```

Where `src/worker.ts` is a custom Cloudflare Worker entry file
[as documented here](https://docs.astro.build/en/guides/integrations-guide/cloudflare/#creating-a-custom-cloudflare-worker-entry-file):

```ts
import type { SSRManifest } from 'astro'
import { App } from 'astro/app'

import { handle } from '@astrojs/cloudflare/handler'

type Env = {
  [key: string]: unknown
  ASSETS: {
    fetch: (req: Request | string) => Promise<Response>
  }
}

export function createExports(manifest: SSRManifest) {
  const app = new App(manifest)

  const fetch: ExportedHandlerFetchHandler<Env> = async (request, env, ctx) => {
    const url = new URL(request.url)
    const { pathname, search } = url

    // Do anything before Astro handles the request

    const response = await handle(manifest, app, request, env, ctx)

    // Do anything after

    return response
  }

  return {
    default: {
      fetch,
    } satisfies ExportedHandler<Env>,
  }
}
```

## What about development?

The `workerEntryPoint` is great for production, but `astro dev` won't
pick up on that. So if you need any of this logic to _also_ run in
development, you need to abstract it and also include it in
`middleware.ts`.

This works fine even for static pages because Astro do run the
middleware when generating static pages, it just outputs a warning if
you try to access things like request headers.

In my case, I chose to move all my production logic in `worker.ts`, so I
don't rely on the middleware whatsoever in production. I use a
conditional export like follows in order to keep the middleware only in
development, where it mimics what `worker.ts` otherwise does in
production.

```ts
import type { MiddlewareHandler } from 'astro'

const handler: MiddlewareHandler = async (context, next) => {
  // ...
}

export const onRequest = import.meta.env.DEV ? handler : undefined
```

## Wrapping up

In short: configure `run_worker_first` on Cloudflare so it runs the
worker in front of static pages, then use a custom `workerEntryPoint`
with the Astro Cloudflare adapter so you get full control over the
worker, and can run code _outside of the middleware_ (which does not
run for static pages).
