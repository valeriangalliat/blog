---
tweet: https://twitter.com/valeriangalliat/status/1449783928970256394
---

# JSDoc: TypeScript inside JavaScript and not the other way around 🤯
October 17, 2021

This post is inspired by this great [Speakeasy JS](https://speakeasyjs.com/)
talk by [Austin Gil](https://austingil.com/). 💯

<figure class="video">
  <iframe src="https://www.youtube.com/embed/iP5XwRT2tNw" allowfullscreen></iframe>
</figure>

Even though I was familiar with the concept of type checking JS files
with TypeScript through JSDoc, I've always seen it as a way to
**transition to TypeScript**. You would progressively add
TypeScript-compatible JSDoc to an existing JavaScript project until
everything is covered, to ultimately transition to the actual TypeScript
syntax.

But it never crossed my mind to use TypeScript with JSDoc as an end
goal. Until I saw that talk.

## The problem with compiled JavaScript

The main reason I don't use TypeScript is not because of TypeScript
itself (even though there's a lot to say here). It's because I don't
like to compile my JavaScript in the first place, at least not when it's
intended for Node.js.

It's the same reason I don't use [Flow](https://flow.org/),
[Elm](https://elm-lang.org/), [Dart](https://dart.dev/),
[Babel](https://babeljs.io/) or [CoffeeScript](https://coffeescript.org/).

JavaScript being an interpreted language, it naturally comes with the
ability to directly run your code. **This is an incredibly convenient
thing.**

* It's fast as fuck because there's nothing to compile.
* You can inspect and debug directly what you write without any extra
  tool or configuration.
* Your stack traces will be readable and usable out of the box.
* Every tool and service you use will (mostly) understand your code by
  default, because it's *native* and doesn't require special treatment.

That's a lot of time saved right there by not having to maintain custom
configurations on all the tools and services you use, on top of the fact
you need to install, configure, update and maintain a number of extra
tools, pipelines, workflows, which you'll also need to teach to
everybody who's going to work with you because we all do those things a
little bit differently.

Now, there are benefits to invest in this extra work, so if the cost of
compiling your JavaScript is worth it for you, or you just enjoy the
process, that's fine! As far as I'm concerned, I don't enjoy a single
bit of it.

## Separate type definitions hell 🔥

Static types are useful and there's no argument that having type
checking is generally a beneficial thing. For that reason, more and more
people want types with the libraries they're going to use.

I maintain [quite a few](https://github.com/valeriangalliat) open source
JavaScript libraries, and on the most popular ones, people have
requested (or better, contributed) TypeScript definitions, whether it's
directly in the package repository or on [Definitely Typed](https://github.com/DefinitelyTyped/DefinitelyTyped).

While this comes from a good intention, it causes a number of issues for
everybody involved:

* When added directly to the package repository, types represent extra
  work for the maintainers who initially wrote a JavaScript project and
  didn't want to write, maintain, and deal with a TypeScript project.

* Types are pretty much always added as manually written, static `.d.ts`
  files, because it would represent a lot more work (on top of being
  extremely bold and opinionated) to convert the project to TypeScript,
  and nobody really wants to do that.

  This means there's no guarantee that the types will match what the JS
  code is actually doing. It's a best effort that worked good enough for
  whoever contributed it.

* On top of that, the maintainers (e.g. me) might "forget" to update the
  previously contributed TypeScript definitions when they make changes.
  The more changes there is, the more likely the types won't be updated
  because of the amount of extra work it represents.

  This means that the included types will most certainly drift out of
  sync with the actual code (even more than they already are) until it
  breaks someone's build and they contribute a fix.

As a maintainer, what can I do?

* Should I reject a PR that add type definitions because I'm not ready
  to commit to the extra work required to maintain them?
* Should I merge the PR only at the condition that the person becomes a
  core contributor and maintain the types in future updates?
* Should I merge the PR but put a note somewhere that types are
  community contributed and might drift out of sync from the JavaScript
  code, a bit like I do for translations contributed in languages that I
  don't speak?

I don't like any of those choices. Luckily, most of my projects are
small enough that the types don't represent a lot of extra work, plus
everybody seems to be happy with type definitions covering only the
happy path which is usually a small subset of the codebase.

So for now I just merge the PRs and let TypeScript users contribute
improvements and bug fixes over time as they need them. It seems that
they're used to having things partially broken all the time and they
prefer to have inaccurate or incomplete types than no types.

## Having the best of both worlds

Out of sympathy for those users (I truly think they deserve something
better), and also because I do believe in the benefits of static typing
(as much as I hate compiling an interpreted language), I decided to
start my [latest JavaScript library](https://github.com/valeriangalliat/node-firefox-sync)
with TypeScript definitions in mind from the start.

Thanks to the talk I shared in the beginning of this post, I decided to
write my JSDoc comments in a way that the TypeScript compiler can
consume. Here's a few examples:

<details>
  <summary><a href="https://github.com/valeriangalliat/node-firefox-sync/blob/master/auth/oauth.js"><code>auth/oauth.js</code></a></summary>

```js
const crypto = require('crypto')
const base = require('./oauth-base')

/**
 * @typedef {Object} SyncOAuthChallengeImpl
 * @property {crypto.KeyPairKeyObjectResult} keyPair
 * @typedef {base.OAuthChallenge & SyncOAuthChallengeImpl} SyncOAuthChallenge
 */

/**
 * @param {SyncOAuthChallenge} challenge
 * @param {base.OAuthResult} result
 * @param {Object} [options]
 * @param {string} [options.clientId] - OAuth client ID.
 * @param {string} [options.scope] - OAuth scope.
 * @param {string} [options.tokenEndpoint] - OAuth token endpoint.
 * @param {string} [options.tokenServerUrl] - TokenServer URL.
 * @returns {Promise<import('../types').SyncCredentials>}
 */
async function complete (challenge, result, options) {
  // Actual code.
}

module.exports = { complete }
```

</details>

<details>
  <summary><a href="https://github.com/valeriangalliat/node-firefox-sync/blob/master/types.js"><code>types.js</code></a></summary>

```js
/**
 * @typedef {Object} SyncOptions
 * @property {string} [authServerUrl]
 * @property {string} [authorizationUrl]
 * @property {string} [tokenEndpoint]
 * @property {string} [tokenServerUrl]
 * @property {import('./auth/oauth-base').OAuthOptions} [oauthOptions]
 *
 * @typedef {Object} OAuthToken
 * @property {string} access_token
 * @property {string} scope
 * @property {number} expires_in
 *
 * @typedef {Object} SyncToken
 * @property {string} id
 * @property {string} key
 *
 * @typedef {Object} SyncKeyBundle
 * @property {string} encryptionKey
 * @property {string} hmacKey
 * @property {string} kid
 *
 * @typedef {Object} SyncCredentials
 * @property {OAuthToken} oauthToken - The OAuth token required to authenticate to the TokenServer.
 * @property {SyncKeyBundle} syncKeyBundle - The Sync key bundle required to decrypt the collection keys.
 * @property {SyncToken} token - The token object required to call the Firefox Sync API.
 * @property {number} tokenIssuedAt - Timestamp in milliseconds of when the token was issued to preemptively refresh it.
 */

// Does nothing but required for TypeScript to import this file.
module.exports = {}
```

</details>

Because I was writing that library from scratch and not adding types to
an existing project, this came at a lower cost, and yielded two major
benefits:

* I can leverage TypeScript for type checking even though the code is
  pure JavaScript.
* I can let TypeScript derivate **accurate** type definitions from the
  source code.

Since the `.d.ts` files are automatically generated as opposed to being
manually maintained, this drastically reduces the chance for them to go
out of sync or be inaccurate, especially because the code itself is also
type checked (this is important because TypeScript will otherwise
happily generate totally broken type definitions from JSDoc comments
that don't pass type checking).

Also for that same reason, if the types were to be incomplete (there's
still a number of `any` in this project, I admit), contributors will
have to add them as JSDoc comments to the JavaScript source and not just
to a "dead" `.d.ts` file, making the code safer as a side effect by
increasing the actual type checking coverage, and guaranteeing that the
exported types match the underlying implementation. Not only this tests
code against the types, but as importantly, **it tests the types against
the code**.

## Why this works best for me

With this pattern, I can still **write, run and debug native JavaScript
code**.

This is what makes me **efficient at what I'm doing**. My development is
not slowed down by constantly running a compiler, dealing with the extra
complexity that comes with debugging transpiled code, and time spent
fixing type errors on non-production code.

When I write a piece of code, it's rarely going to be perfect,
production quality code from the start. It takes me dozens of iterations
and rewriting pieces of it until I reach a point where I'm satisfied.
Only when I'm done I'll clean up and refactor whatever parts need extra
love, handle the edge cases, and make the linter happy. This is when,
and only when, I want to run the type checks. There's no point in having
blocking type checks on code that I'll rewrite or remove a minute later.

<div class="note">

**Note:** this last point is a problem that I had specifically with the
`ts-node` utility, but `tsc` itself is more forgiving and will output a
runnable JS code even when there's type errors.

Also while writing this section, I stumbled upon `ts-node --transpile-only`
that allows running the code even if it doesn't pass type validation,
which seems like a must-have during development. I'm kinda sour that
it took me a 4 months post-burnout retirement kind of step back to
finally find about it, after fighting with this problem for years. 😬

</div>

## The chicken and egg problem between `.js` and `.d.ts`

I didn't share the commands I use to do the type checking and derive the
`.d.ts` files from the JSDoc comments yet, and you're probably dying to
know them. 😉

But first, I need to share something else with you. See, I usually have
this kind of structure for packages I publish on npm:

```
my-cool-package
├── index.js
├── package.json
└── test.js
```

It seems that the natural way to [extract type definitions](https://www.typescriptlang.org/docs/handbook/declaration-files/dts-from-js.html#tsconfig)
would be:

```sh
tsc *.js --allowJs --declaration --emitDeclarationOnly
```

Which yields:

<pre><code class="hljs">my-cool-package
├── <span class="hljs-addition">index.d.ts</span>
├── index.js
├── package.json
├── <span class="hljs-addition">test.d.ts</span>
└── test.js</code></pre>

You'll quickly notice that there's something funky with this method of
doing things.

* We generate `.d.ts` files from `.js` files.
* TypeScript has an **hardcoded** rule where it systematically imports
  any `.d.ts` file that's next to an imported `.js` file. This is
  regardless of your explicit `include` and `exclude` patterns and
  there's no way to turn off this behavior.
* TypeScript refuses to overwrite input files (and that's a good thing).

But guess what? `test.js` imports `index.js` (so that it can, you know,
test it).

The problem here is that while this command will run fine the first
time, [subsequent runs will fail](https://github.com/microsoft/TypeScript/issues/16749)
because TypeScript will *always* consider a `.d.ts` that is next to an
included `.js` file to be part of its inputs and will refuse to
overwrite it. And even if it allowed to overwrite the declaration files,
we would still be loading the stale `.d.ts` instead of using the
up-to-date JSDoc types, which sounds like a hot mess.

You might tell me that hey, we don't really need a `.d.ts` to be
generated for the test file, and you would be right. Replacing `*.js` by
`index.js` in the above example does fix the problem.

But sometimes, I'm dealing with a more complex package where the
structure would look something like this:

<pre><code class="hljs">my-cool-package
├── index.js
├── package.json
├── <span class="hljs-addition">some-other-file.js</span>
└── test.js</code></pre>

As soon as `index.js` imports `some-other-file.js`, we're off the happy
path for TypeScript again.

I wrote about this in more details in [cannot write file `.d.ts` because it would overwrite input file](typescript-cannot-write-file-overwrite-input.md),
and you have many options to go about this, including splitting the code
in a `src` or `dist` directory or some combination of both, and while
they all solve this particular problem, they also all leak into other
aspects that you'll have to work around.

For example in the "complex" case above, you might want to allow
your users to `import 'my-cool-package/some-other-file'`, and not just
`import 'my-cool-package'`. How wild would that be?

Apparently, wild enough that most of the recommended solutions for the
earlier problem will fail to deliver types information for that use
case, or require you to do crazy things like copying your `package.json`
to the `dist` directory and publishing from there.

## The simple hack that just works

Because I prefer a simple hack that just works to a fix that will break
other things and require a cascade of other fixes, I settled for the
following command:

<pre><code class="hljs"><span class="hljs-addition">rm -f *.d.ts && </span>tsc *.js --allowJs --declaration --emitDeclarationOnly</code></pre>

It's simple, reliable, it works and I understand every bit of why it
works and why it needs to be there (as much as I hate that it needs to
be there in the first place).

I also added `--removeComments` and replaced `--allowJs` by `--checkJs`
to make sure that the code passes type checking when I generate the
final definitions.

In my `package.json`, the final `scripts` property looks like this:

```json
{
  "scripts": {
    "check": "tsc *.js --checkJs --noEmit",
    "lint": "standard",
    "prepare": "npm run lint && npm run types",
    "types": "rm *.d.ts && tsc *.js --checkJs --declaration --emitDeclarationOnly --removeComments"
  }
}
```

As always, I use [`standard`](https://standardjs.com/) to lint my code,
and in the [`prepare`](https://docs.npmjs.com/cli/v7/using-npm/scripts#life-cycle-scripts)
script, the code is linted, typed checked and the definitions are
updated.

There's also a convenience `check` script that doesn't emits the
declaration files, to be used for quick checks during development.

## Conclusion

As usual with TypeScript it was a pain in the ass to get this to work
and (also as usual) I had to resort to a hack at the end of the day. But
that's mostly because I'm a perfectionist and I wasn't happy with having
just the happy path working. 😜

Still, I believe that this method allows to reduce the gap between
TypeScript and JavaScript, while **getting rid of manual work**, making
the JavaScript code **safer**, and making the type definitions **more
accurate and reliable** by tightly coupling them to the code.

Because it yields **most of the benefit** at the **lowest cost and
initial investment**, TypeScript-aware JSDoc comments is likely to
become my go-to for writing JS libraries from now on.

What do you think of this solution? Have you used it yourself, or did
this make you want to type your projects this way? Feel free to [reach out](/val.md#contact)
and let me know. And as usual, keep hacking! ✨
