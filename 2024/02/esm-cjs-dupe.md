---
tweet: https://x.com/valeriangalliat/status/1759280799852179929
---

# Duplicated ESM and CJS package in bundle
February 18, 2024

<div class="note">

**Note:** for context we're in a Next.js TypeScript project, using
Webpack as a bundler, but I could see this happening with similar tools.

The problem occurred with the [`firebase`](https://www.npmjs.com/package/firebase)
package, but again that could happen with other packages.

</div>

So we upgrade the Firebase SDK by a few minor versions, and suddenly,
our JS bundle size blows up. Like, 50 kB more of (gzipped) JS shipped on
every page. Not good.

Luckily we have [tests](https://github.com/hashicorp/nextjs-bundle-analysis)
to catch this kind of thing.

Further [investigation](https://nextjs.org/docs/app/building-your-application/optimizing/bundle-analyzer)
shown that we were shipping `@firebase/app` and `@firebase/auth` twice. 🤔

## The problem

We use [next-firebase-auth](https://github.com/gladly-team/next-firebase-auth)
to integrate Firebase Auth with Next.js. next-firebase-auth imports
specifically `firebase/app` and `firebase/auth`.

In our own code, we use `import` to import our dependencies:

```ts
import { getApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
```

But next-firebase-auth, while they do the same in their
[TypeScript source code](https://github.com/gladly-team/next-firebase-auth/blob/d51bf07eecf727ef3df45587e4008551b0cb4803/src/initFirebaseClientSDK.ts#L1-L2),
is actually bundled down (also with Webpack) to a [CJS file](https://socket.dev/npm/package/next-firebase-auth/files/1.0.2/build/index.browser.js).

The code is minified, but you can see it uses `require`:

```js
324:e=>{e.exports=require("firebase/app")},610:e=>{e.exports=require("firebase/auth")}
```

The problem is that the version of the Firebase SDK we upgraded to
contains [this PR](https://github.com/firebase/firebase-js-sdk/pull/6981),
that makes `@firebase/auth` export both ESM and CJS variants of their
`browser` bundle, whereas before they only exposed the ESM version for
the browser.

Concretely, this means that before this PR, the `package.json` of
`@firebase/auth` looked like:

```json
{
  "exports": {
    ".": {
      "default": "./dist/esm2017/index.js"
    }
  }
}
```

And after:

```json
{
  "exports": {
    ".": {
      "default": "./dist/esm2017/index.js",
      "browser": {
        "require": "./dist/browser-cjs/index.js",
        "import": "./dist/esm2017/index.js"
      }
    }
  }
}
```

Because initially there was no `browser` entry, Webpack picked the
`default` value for both `import` and `require`, which turns out to be
the ESM bundle.

However after that change, we now have a different bundle configured
depending if it's imported with `import` or `require`. As
[documented](https://webpack.js.org/guides/package-exports/#import)
Webpack will map `import` calls to the file under `import` in the
`package.json`, and `require` to the `require` field, which makes sense.

However this is a problem for us as we saw earlier, we use `import` in
our own codebase, but the distribution bundle of next-firebase-auth
(like probably many other packages in the ecosystem) only comes with a
CJS file using `require`.

This means our own code will use `@firebase/auth/dist/esm2017/index.js`,
while next-firebase-auth will use `@firebase/auth/dist/browser-cjs/index.js`.

Not only this increases our bundle size unnecessarily, but it breaks the
Firebase SDK as it depends on shared global state, and now different
parts of the codebase point to a different, isolated version of the SDK.

## This sucks, and nobody's to blame really

- It's absolutely reasonable for the Firebase SDK to expose a different
  browser bundle for `import` and `require`.
- It's absolutely reasonable, and even expected, that Webpack maps
  `import` and `require` calls to the matching field in `package.json`.
- It's absolutely reasonable for next-firebase-auth to export a single
  CJS bundle (that's how npm packages look like since npm is a thing).

It's just a result of the giant fracture in the ecosystem between CJS
and ESM imports. It's probably for the best, and I look forward to ESM
being widespread enough that we don't encounter those problems, but the
transition is long and painful. It's been 3-4 years I'm dealing with
this kind of issues as a package maintainer, and they tend to be
particularly time consuming, and takes away time to fix real problems or
implement new features.

## The solution

As far as I'm concerned, for that particular instance of this problem,
the solution was to configure Webpack to alias `firebase/app` and
`firebase/auth` (the parts of the Firebase SDK used by
next-firebase-auth) to their ESM bundle, so this same bundle gets used
regardless if imported with `import` or `require`.

In the Webpack config:

```js
module.exports = {
  resolve: {
    alias: {
      'firebase/app': require.resolve('firebase/app').replace('index.cjs.js', 'index.mjs'),
      'firebase/auth': require.resolve('firebase/auth').replace('index.cjs.js', 'index.mjs')
    }
  }
}
```

It's something we'll have to maintain as we update the Firebase SDK, if
they were to change the layout of their distribution files, since this
doesn't bother parsing the `package.json` `exports` field, but it's good
enough.

## Bonus

For reference, a [related GitHub issue](https://github.com/webpack/webpack/issues/15967)
and [discussion](https://github.com/webpack/webpack/discussions/18082).

I've also tried using
[`resolve.conditionNames`](https://webpack.js.org/configuration/resolve/#resolveconditionnames)
as follows, as a more generic fix to force _all_ packages to use the ESM
build if present:

```js
module.exports = {
  resolve: {
    conditionNames: ['import', 'default']
  }
}
```

This would have been great as it would prevent similar (but maybe less
noticeable) duplication issues to happen in the dependency graph,
however, as you can expect, this will break some packages (in my case
some `@babel/runtime` imports), so I couldn't go with that.
