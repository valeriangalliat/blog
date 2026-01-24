---
tweet: https://x.com/valeriangalliat/status/1644037565907890180
---

# Vercel: custom preview domain for free?
April 6, 2023

If you host your app on Vercel, you must be familiar with how preview
deployments are a first-class citizen, and each pull request you make gets
a preview deployment.

Those preview deployments default to be hosted on `vercel.app`, and
Vercel provisions two preview domains for it, with the following
patterns:

* `{app}-{id}-{org}.vercel.app`
* `{app}-git-{branch}-{org}.vercel.app`

So if you make a PR on an app called `my-app` in an organization
`my-org`, on a branch called `hello-world`, and the deployment ID for
this commit was `lkj8trp27`, your URLs would be:

* `https://my-app-lkj8trp27-my-org.vercel.app/`
* `https://my-app-git-hello-world-my-org.vercel.app/`

But what if you want, for example, to allow OAuth on your preview
domains? Whitelisting `vercel.app` is out of the question since it would
allow _any_ Vercel website (including an attacker's website) to be a
valid redirect URI for our OAuth provider!

And we can't typically whitelist a domain pattern like `*-my-org.vercel.app`,
not that this would be a good idea anyway because **this pattern is
_not_ private to your organization**. Any random Vercel user can use
it in their own app!

Then, it would be useful to use your own domain instead of `vercel.app`.
Turns out Vercel supports this, and [charges $100/month](https://vercel.com/docs/concepts/deployments/generated-urls#preview-deployment-suffix)
for it! Steep.

Steep, but if you're looking for a turnkey solution, it's definitely
worth it. Otherwise, keep reading.

## Using the Vercel CLI

An interesting thing in the Vercel CLI is that it lets us manually
associate a custom domain to a given deployment using
[`vercel alias`](https://vercel.com/docs/cli/alias). 😏

Let's say `codejam.info` is part of my Vercel-managed domains:

```sh
vercel alias set my-app-lkj8trp27-my-org.vercel.app hello-world.preview.codejam.info
```

This will associate the deployment example from earlier to my custom
domain!

We can literally put anything we want under `codejam.info` there, and it
will happily generate a SSL certificate for that arbitrary subdomain,
and associate it to our deployment.

This will work as long you associated a wildcard subdomain on your DNS
to Vercel, like `*.preview.codejam.info` in our example.

This is a good start, but it doesn't scale!

## Using the Vercel API

Luckily, the Vercel API exposes an endpoint to do just the same thing:
[`POST /v2/deployments/{id}/aliases`](https://vercel.com/docs/rest-api/endpoints#assign-an-alias).
In our example, we can call it with:

```json
{
  "alias": "hello-world.preview.codejam.info"
}
```

How do we find the deployment ID though? We need the full deployment ID,
something looking like `dpl_hgLKkCqMExSzNpTtA3Dy6sVfWuYj`.

Vercel gives us a handy [`GET /v13/deployments/{idOrUrl}`](https://vercel.com/docs/rest-api/endpoints#get-a-deployment-by-id-or-url)
endpoint for this, where we can pass our deployment URL and get the
deployment object back, including its full `id`.

By combining those two endpoints, we can dynamically associate our
custom domain to any Vercel preview deployment. 🙏

## Getting an API token

In order to call the API, we need to pass a bearer token in the
`Authorization` header. You can create a token from your
[Vercel account settings](https://vercel.com/account/tokens).

Then, you can put it in your app's environment variables, e.g. as
`VERCEL_TOKEN`, so it's available in your server-side code environment.

## Associating the domain on the fly

From there, we can detect when we're running under a `vercel.app`
preview domain, call the API to associate our own custom domain, and
finally redirect to it. This will add a bit of delay when loading our
preview deployments from the `vercel.app` domains, but no big deal.

Where you hook in order to do that is up to you. `_app.jsx` may be a
good start, or maybe some component that's included in all of your
pages, maybe just the home page if you don't expect any deep link on
your `vercel.app` preview domains, or maybe even somewhere in
`getServerSideProps`?

If you do this client-side, you'll want to add an API route or go
through a SSR page that will be doing the call to the Vercel API (you
don't want to expose your Vercel API token client-side), but if you're
hooking directly in `getServerSideProps`, you can skip that step.

On the client, you could do something like this:

```js
const router = useRouter()

if (location.host.endsWith('-my-org.vercel.app')) {
  // Preview env
  router.push('/preview-redirect')
}
```

Then, implement a `preview-redirect` page to associate your custom
domain to the current preview environment, then redirect to it.

```js
export async function getServerSideProps (context) {
  const deployment = await getDeployment(context.req.headers.host)

  const domain = `pr-${deployment.gitSource.prId}.preview.codejam.info`

  await associateDomainToDeployment(deployment.id, domain)

  return {
    redirect: {
      destination: `https://${domain}`
    }
  }
}
```

Where `getDeployment` is a wrapper to [`GET /v13/deployments/{idOrUrl}`](https://vercel.com/docs/rest-api/endpoints#get-a-deployment-by-id-or-url),
and `associateDomainToDeployment` wraps [`POST /v2/deployments/{id}/aliases`](https://vercel.com/docs/rest-api/endpoints#assign-an-alias)
(writing those is left as an exercise to the reader).

Here, I chose to prefix the domain with `pr-` and the PR number, but
you're free to construct your preview domains however you want.

You'll notice this works the first time, but obviously if you open again
the `vercel.app` preview URL, it will fail because the domain was
already assigned! To cover that, you need to call [`/v2/deployments/{id}/aliases`](https://vercel.com/docs/rest-api/endpoints#list-deployment-aliases)
and redirecting to the existing domain if you already associated it
before.

We can add something like this in the beginning of our previous
function:

```js
const aliases = await getDeploymentAliases(deployment.id)

const existingDomain = aliases.find(alias =>
  alias.alias.endsWith('.preview.codejam.info')
)

if (existingDomain) {
  return {
    redirect: {
      destination: `https://${existingDomain.alias}`
    }
  }
}
```

After this, you should have your free custom preview domains working,
congrats!

## About Vercel certificates

However, you may realize this is bloating your domain's SSL certificates
list on Vercel. Every single preview deployment will add a new entry in
your SSL certificates list, and because the Vercel UI for this doesn't
really expect an infinitely growing list of certificates, it'll make it
a pain for you to manage your "actual" certificates!

To prevent this, you need to manually create a wildcard certificate for
the domain you use for your preview deployments. In the example featured
in this post, that would be `*.preview.codejam.info`.

Vercel is smart enough to notice when we associate a new domain to a
deployment, that a wildcard certificate covering it already exists, and
so doesn't create an _individual_ certificate for _that_ particular
preview. This will keep your certificates list clean and tidy!

You can't create the wildcard certificate from the dashboard directly,
but you can do so with the CLI using [`vercel certs issue`](https://vercel.com/docs/cli/certs#extended-usage).

```sh
vercel certs issue '*.preview.codejam.info'
```

Note that this will only work if you use Vercel's nameservers. This
means the following won't work (e.g. in the `codejam.info` DNS zone):

```
*.preview CNAME cname.vercel-dns.com
```

But the following will work:

```
preview NS ns1.vercel-dns.com
preview NS ns2.vercel-dns.com
```

## Conclusion

If you made it here, congrats! You now have everything you need in order
to implement your own custom preview domains, without paying Vercel big
money for it.

Is going through all of this worth saving $100/month? That's up to you.
But as far as I'm concerned, the joy of putting together this little
system was well worth the savings. 😜
