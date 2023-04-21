# Using `zx` with TypeScript, ESM and top-level `await`
April 21, 2023

[`zx`](https://github.com/google/zx) is a cool library by Google to
write shell-like scripts in Node.js.

As shown in their main example, you could have a file `myscript.mjs`:

```js
#!/usr/bin/env zx

await $`cat package.json | grep name`
```

And run it as `./myscript.mjs`, or even put it in your `PATH` and run it
as `myscript.mjs`.

This works if you installed `zx` globally. If you want to keep it local,
`#!/usr/bin/env npx zx` should work with most `env` implementations.

They say that you _have_ to use a `.mjs` extension, and if you prefer
`.js` or no extension at all, you won't have access to top-level
`await`, and you need to wrap your code in an
<abbr title="Immediately invoked function expression">IIFE</abbr>:

```js
#!/usr/bin/env zx

void async function () {
  await $`cat package.json | grep name`
}()
```

**This actually doesn't appear to be necessary!** It looks like when
invoking the script via `zx`, it _forces_ it to be interpreted as an
ECMAScript module, even without extension, so the original example will
work regardless of how the script is named. Sweet.

What if you want TypeScript though? They just document that you need to
explicitly import `zx` and use an IIFE again:

```ts
import { $ } from 'zx'
// Or
import 'zx/globals'

void async function () {
  await $`ls -la`
}()
```

But they also tell you that you need to set `"type": "module"` in your
`package.json` and `"module": "esnext"` in `tsconfig.json`. There's no
mention what shebang to use, nor what file extension.

It turns out you don't necessarily need to do all this. Let's dig in the
details.

## Shebang for a TypeScript script

It's clear that `zx` doesn't support TypeScript out of the box, so we
can ditch the `#!/usr/bin/env -S npx zx` shebang. We need something that
will parse TypeScript, and because we can't rely on the `zx` wrapper,
we'll need to import `zx` explicitly. No problem.

Let's go with [`ts-node`](https://www.npmjs.com/package/ts-node) first,
because it's one of the most common options to do this.

TypeScript defaults to transpiling to CommonJS modules, so we won't be
able to use top-level `await` out of the box. We also won't be able to
use an `import` statement (that TypeScript translates to `require`) to
import `zx`, because `zx` is an ESM-only package. But we can use dynamic
`import` for that:

```ts
#!/usr/bin/env -S npx ts-node

void async function () {
  const { $ } = await import('zx')
  await $`echo ok`
}()
```

You'll also need to set `"moduleResolution": "nodenext"` in the
`compilerOptions` of your `tsconfig.json` for it to support dynamic
imports like this, but you have to be careful, because this will change
the settings for your whole app!

Alternatively, you could put your script in a subdirectory, and have a
dedicated `tsconfig.json` there, then you could set those settings
locally to this subdirectory without affecting the rest of your app.

The advantage of this method is that **the extension doesn't matter**!
You can have this script in `myscript.ts` but you can as well have it
just `myscript` for being more command-looking. This a pretty good
advantage of this solution as we'll see later.

<div class="note">

**Note:** keep in mind because this will run in whatever directory the
script was run from, `npx` will try to install `ts-node` globally if
you're not running this from a directory where `ts-node` is part of the
local modules.

Most of the time this is fine, but if you want a script that can be
called from anywhere, you would be better off using a wrapper shell
script, like we'll see below.

</div>

## Configuring TypeScript in the shebang

Alternatively, we can pass `--compilerOptions` to `ts-node` directly in
the shebang to avoid depending on a `tsconfig.json`. The problem is
that there's no cross-platform way to this (this is made harder by the
fact we have to pass a JSON string).

On macOS:

```ts
#!/usr/bin/env npx ts-node --compilerOptions {"moduleResolution":"nodenext"}
```

On Linux:

```ts
#!/usr/bin/env -S npx ts-node --compilerOptions '{"moduleResolution":"nodenext"}'
```

Notice how on macOS, the quotes of the JSON object were _not_ escaped!
Its implementation of  `env` doesn't try to parse quotes in the first
place, so we can (and need) to give them as is. This also means we can't
include spaces as the JSON would be split into multiple arguments.

For Linux, we have to pass `-S` (makes `env` split arguments), but then
it _does_ support quoting and various escape sequences, so we _have_ to
add the quotes. macOS "supports" the `-S` option but currently it just
ignores it and treats the rest of the string as it normally does.

Sadly I'm not aware of a way to do this in a cross-platform way, without
having to resort to a wrapper shell script. If you have a better option,
let me know!

Such a script would look like:

```sh
#!/bin/sh

cd "$(dirname "$0")"
npx ts-node --compilerOptions '{"moduleResolution":"nodenext"}' myscript.ts
```

It would be in a `myscript` file next to `myscript.ts`, and you invoke
it with `./myscript`.

<div class="note">

This will not preserve the <abbr title="Current working directory">CWD</abbr>
information, because it `cd` into the script directory first. The
advantage is that now `npx` will find your local version of `ts-node`
regardless where you run the script from.

</div>

At that point you could even bypass `npx`, e.g. if your script is in a
`bin` directory at the root of your project, you could run
`../node_modules/.bin/ts-node` instead of `npx ts-node` and remove the
extra latency from `npx`.

**For the rest of this post I'll user the Linux version of the shebang
for simplicity. Adapt accordingly to your needs, either for macOS or
using a script wrapper for portability.**

## Adding ESM support

**If you want to import other parts of your codebase, you should
probably stick with the previous approach.** I'll continue by exploring
options to make _this particular script_ ESM, but keep in mind that if
you import non-ESM parts of your application, this will confuse
TypeScript (especially with default exports) and you'll likely run into
issues.

If you don't though, we have a few ways to force it to be ESM, so we can
directly import `zx` and also use top-level `await`!

`ts-node` has a `--esm` option to parse the input as ECMAScript module,
and even ships a [`ts-node-esm`](https://github.com/TypeStrong/ts-node#esm)
executable to do the same thing.

On top of that, we need to configure the TypeScript compiler to support
ESM, which we do by adding the following to our `tsconfig.json`:

```json
{
  "compilerOptions": {
    "moduleResolution": "nodenext",
    "module": "esnext",
    "target": "esnext"
  }
}
```

As we saw earlier, we can pass that to `ts-node` in a
`--compilerOptions` flag. This gives us:

```ts
#!/usr/bin/env -S npx ts-node --esm --compilerOptions '{"moduleResolution":"nodenext","module":"esnext","target":"esnext"}'

import { $ } from 'zx'

await $`echo ok`
```

We can now import `zx` directly and happily use to-level `await`, and
get rid of that IIFE!

One thing we notice right away though is that the `ts-node` ESM loader
doesn't let us use any extension (or in particular, no extension). **It
_needs_ to be in a `.mts` file.** This means no more command-looking
script. It seems to be related to [this issue](https://github.com/nodejs/node/issues/34049)
on the Node.js side.

## Making it faster

`ts-node` doesn't have a reputation to be fast, actually quite the
opposite. Its excuse is that it not only transpiles TypeScript to
JavaScript, but also performs type checking.

## Using `ts-node --transpile-only`

We can pass `--transpile-only` to skip the type checking part, which
does improve the performance quite a bit:

```ts
#!/usr/bin/env -S npx ts-node --esm --transpile-only --compilerOptions '{"moduleResolution":"nodenext","module":"esnext","target":"esnext"}'

import { $ } from 'zx'

await $`echo ok`
```

This small example takes 500 ms to run on my machine, as opposed to 1
second when it was doing type checking!

```console
time ./myscript.mts
1.61s user 0.13s system 152% cpu 1.137 total

time ./myscript-transpile-only.mts
0.48s user 0.09s system 96% cpu 0.587 total
```

It's still relatively slow though, considering [esbuild](https://esbuild.github.io/)
takes 15 ms to transpile that file:

```console
$ time node_modules/.bin/esbuild myscript.mts --target=node16
0.01s user 0.01s system 79% cpu 0.014 total
```

But for a fair comparison, we have to consider that `npx` adds a 200 ms
overhead:

```console
$ time npx esbuild myscript.mts --target=node16
0.21s user 0.04s system 111% cpu 0.227 total
```

### Using `tsx`

Interestingly, there's a cool project called [`tsx`](https://github.com/esbuild-kit/tsx),
which is TypeScript's analogue to `npx`. And it uses esbuild in the
background.

```ts
#!/usr/bin/env -S npx tsx

import { $ } from 'zx'

await $`echo ok`
```

But we notice it's not quite fast, it does barely better than `ts-node --transpile-only`:

```console
$ time ./myscript.mts
0.42s user 0.08s system 120% cpu 0.413 total
```

There's [an issue open for that](https://github.com/esbuild-kit/tsx/issues/167),
and it seems that it's because `tsx` target older Node.js versions in a
way where it transpiles all the imported `node_modules` too! And it
seems that there's currently no way around this behavior.

And again, this relies on a `.mts` extension being present for ESM
support. And even if you go the CommonJS route, you'll still need a
`.ts` extension, unlike when using `ts-node`. It won't work with
extensionless scripts.

### Using SWC

[SWC](https://swc.rs/) is a "Rust-based platform for the web", but
really the part I care about is that it claims to transpile TypeScript
to JavaScript _pretty damn fast_, just like esbuild.

They provide [`swc-node`](https://github.com/swc-project/swc-node) to
run TypeScript files with Node.js, which is exactly what we want. It's
not directly a command we can invoke unlike `ts-node`, instead we need
to do:

```sh
node --require @swc-node/register script.ts # CJS
node --loader @swc-node/register/esm script.ts # ESM
```

So we can and that to our shebang!

```ts
#!/usr/bin/env -S node --loader @swc-node/register/esm

import { $ } from 'zx'

await $`echo ok`
```

This is the fastest one so far!

```console
$ time ./myscript.mts
0.28s user 0.04s system 110% cpu 0.289 total
```

However, we have to consider that it uses `node --loader`
instead of `npx` like the previous examples, and as we saw `npx` costs
200 ms by itself.

Also, even with today's latest Node.js, custom ESM loaders are
experimental, so running the script like this will show the following
warning:

```
(node:13239) ExperimentalWarning: Custom ESM Loaders is an experimental feature and might change at any time
```

Also you need to make sure your `tsconfig.json` contains `"target": "esnext"`
in `compilerOptions` otherwise SWC will not let you use top-level
`await`. Unlike the previous options, we can't customize this directly
in the shebang.

Lastly, we also need a `.mts` extension for this to work, like with all
the ESM solutions so far.

<div class="note">

**Note:** I couldn't get `swc-node` to work with a CJS file, with the
IIFE and dynamic `import`. Even with a `.swcrc`, which requires running
your code as `SWCRC=true ./myscript.ts`, it keeps transpiling the
dynamic `import` into a `require` statement, which is not supported by
`zx`.

</div>

### Using SWC with `ts-node`

A cool surprised I found while writing this post is that `ts-node`
actually have [first-class support for SWC](https://typestrong.org/ts-node/docs/swc/)!

You can simply use `ts-node --swc`, or set the following in your
`tsconfig.json`:

```json
{
  "ts-node": {
    "swc": true
  }
}
```

In our initial example, this gives us:

```ts
#!/usr/bin/env -S npx ts-node --swc --compilerOptions '{"moduleResolution":"nodenext","module":"esnext"}'

void async function () {
  const { $ } = await import('zx')
  await $`echo ok`
}()
```

<div class="note">

**Note:** we had to add `"module": "esnext"` too, probably because
`ts-node` and SWC have different defaults when it comes to this setting.

</div>

And for the ESM version:

```ts
#!/usr/bin/env -S npx ts-node --swc --esm --compilerOptions '{"moduleResolution":"nodenext","module":"esnext","target":"esnext"}'

import { $ } from 'zx'

await $`echo ok`
```

## Conclusion

All things considered, my favorite option is the `ts-node` approach we
started from but with a few tweaks that we learnt about along the way:
plain `ts-node` in the default CommonJS environment, using an IIFE and
dynamic `import`, but with the addition of `--compilerOptions` and
`--swc` (or alternatively, `--transpile-only`) in the shebang:

```ts
#!/usr/bin/env -S npx ts-node --swc --compilerOptions '{"moduleResolution":"nodenext","module":"esnext"}'

void async function () {
  const { $ } = await import('zx')
  await $`echo ok`
}()
```

* We can configure TypeScript directly in the shebang, no need to
  maintain a separate `tsconfig.json` for our executable scripts.
* We can import any of our project TypeScript files with no CJS/ESM
  interoperability issues.
* It's reasonably fast.

The downside is that it's not cross-platform, but we saw we can use a
wrapper script to work around that if needed.

And if I don't need need to import anything local to my CommonJS
project (or if I'm in a ESM project), I add `--esm` and `"target": "esnext"`
to benefit from top-level `await`:

```ts
#!/usr/bin/env -S npx ts-node --swc --esm --compilerOptions '{"moduleResolution":"nodenext","module":"esnext","target":"esnext"}'

import { $ } from 'zx'

await $`echo ok`
```

Sweet!
