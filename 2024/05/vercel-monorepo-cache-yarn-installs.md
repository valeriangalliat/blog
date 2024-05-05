# Vercel monorepo: properly cache Yarn installs
May 4, 2024

So you have a Vercel app that's part of a monorepo. You may have noticed
that by default it installs the whole monorepo dependencies, and you may
have already [addressed that](vercel-monorepo-single-project-dependencies-yarn.md)!

But either way, you have another problem: Yarn downloads all your
dependencies on every single build. That's pretty time consuming. It
doesn't seem that dependencies are getting cached at all.

Vercel [recommends](https://github.com/orgs/vercel/discussions/222#discussioncomment-2036114)
setting a `ENABLE_ROOT_PATH_BUILD_CACHE=1` environment variable to
[make build times faster in monorepos](https://vercel.com/changelog/faster-build-times-for-monorepos).

It sounds great, but in my experience it didn't do anything, and I'm not
[the](https://github.com/orgs/vercel/discussions/222#discussioncomment-2745510)
[only](https://github.com/orgs/vercel/discussions/222#discussioncomment-5105483)
[one](https://github.com/orgs/vercel/discussions/222#discussioncomment-7077684).

It [_seems_](https://github.com/orgs/vercel/discussions/222#discussioncomment-5166537)
that regardless of `ENABLE_ROOT_PATH_BUILD_CACHE`, Vercel doesn't
cache Yarn's cache folder `.yarn/cache`, and Yarn 3 and greater will
download everything again if this directory is not present, regardless
of the state of `node_modules`.

So the key is to force Yarn's cache folder to be inside a directory that
Vercel actually caches.

I [tried](https://github.com/orgs/vercel/discussions/222#discussioncomment-4295643)
setting it inside the root `node_modules` by doing
`YARN_CACHE_FOLDER=../../node_modules/.yarn-cache yarn workspaces focus`,
which worked at first, but quickly encountered some
[issues](https://github.com/orgs/vercel/discussions/222#discussioncomment-5165657)
when the cache was reused across different build states.

Luckily, thanks to [this comment](https://github.com/vercel/turbo/issues/785#issuecomment-1060054306)
on a totally unrelated issue, I discovered I could put the cache in
`.next/cache` instead, and I never had issues since then!

```json
{
  "installCommand": "YARN_CACHE_FOLDER=.next/cache/yarn-cache yarn workspaces focus"
}
```

