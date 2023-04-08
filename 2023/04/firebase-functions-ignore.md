# How Firebase `functions.ignore` really works
April 7, 2023

Maybe you ran into [Firebase functions space issues](firebase-functions-entity-too-large.md),
which is not uncommon if you're [moving Firebase functions inside a monorepo](firebase-functions-monorepo.md).
Anyhow, you're now playing with the `functions.ignore` list in your
`firebase.json`.

The ignore list is not well documented, nor is the whole
`firebase.json` really, but there is [a section on it](https://firebase.google.com/docs/cli/#the_firebasejson_file)
in the Firebase CLI reference. I always struggle to find this page, and
I systematically find it through [this GitHub issue](https://github.com/firebase/firebase-tools/issues/1409)
about documenting it.

It says the following [about the ignore list](https://firebase.google.com/docs/cli/#functions-ignored-files):

> The list of files ignored by default, shown in JSON format, is:
>
> ```json
> {
>   "ignore": [
>     ".git",
>     ".runtimeconfig.json",
>     "firebase-debug.log",
>     "firebase-debug.*.log",
>     "node_modules"
>   ]
> }
> ```
>
> If you add your own custom values for ignore in `firebase.json`, make
> sure that you keep (or add, if it is missing) the list of files shown
> above.

Let's dig into it in a bit more details.

## If you set an ignore list, it overrides the defaults!

That's the only thing the docs say about the ignore list. It's important
to note because otherwise, you may notice that setting `"ignore": []`
ends up including _much more stuff_ than not setting it, and
[this can be surprising](https://github.com/firebase/firebase-tools/issues/1602).

This is actually partially true (but mostly true to be fair).

We can see [in the source code](https://github.com/firebase/firebase-tools/blob/8976456eebf75ab9ab2a1299c0d6561f324db7f8/src/deploy/functions/prepareFunctionsUpload.ts#L75-L80)
the following:

```js
const ignore = config.ignore || ['node_modules', '.git']

ignore.push(
  'firebase-debug.log',
  'firebase-debug.*.log',
  '.runtimeconfig.json'
)
```

This means that regardless if you customize or not `functions.ignore`,
the debug logs and runtime config will always be ignored. But it's also
true that if you explicitly set `functions.ignore` and forget to add
`node_modules` and `.git`, those will indeed be included. Now you know.

## You can't use `/` to refer to the functions root

In `.gitignore` and any sane ignore format, you can use `/` to refer to
the project root. E.g. ignoring `/bar` will ignore `bar` at the top
level, but will still include `foo/bar`.

This is pretty handy in a number of situations, and just a good practice
in general to be more intentional about what you _mean_ to exclude. If
you have a `data` directory that you want to ignore, but you just put
`data` in your ignore file, and later on you add `src/api/data/load.js`,
guess what, `src/api/data` will be ignored and you'll be confused until
you figure out the sneaky ignore pattern. You really should be ignoring
`/data` in that case.

So again, we can't do that in `functions.ignore`. Why? Ultimately, this
is because Firebase uses [minimatch](https://github.com/isaacs/minimatch)
for this [here](https://github.com/firebase/firebase-tools/blob/8976456eebf75ab9ab2a1299c0d6561f324db7f8/src/fsAsync.ts#L53),
but they pass the system-wide absolute path as the first argument! So
that's what ends up happening when using a `/` pattern (using
`matchBase` and `dot` to mimic how Firebase uses it):

```js
> minimatch('/path/to/functions/foo', '/foo', { matchBase: true, dot: true })
false
```

What would be great is if the first argument was "scoped" to the
functions root. Then we would have nice things:

```js
> minimatch('/foo', '/foo', { matchBase: true, dot: true })
true
```

But because we can't have nice things, we have to resort to using a
wider pattern (without the `/`):

```js
> minimatch('/path/to/functions/foo', 'foo', { matchBase: true, dot: true })
true
```

This is a problem though because as we saw earlier, it's _too_ wide:

```js
> minimatch('/path/to/functions/src/foo', 'foo', { matchBase: true, dot: true })
true
```

## Can't use `/` in base patterns

The last example works only because `matchBase` is enabled, but if you
look at the [`matchBase` documentation](https://github.com/isaacs/minimatch#matchbase),
you see that it breaks down as soon as our pattern includes a `/`:

```js
> minimatch('/path/to/functions/foo/bar', 'foo/bar', { matchBase: true, dot: true })
false
```

But since root patterns don't work _anyway_ as we just saw, we can get
around this by using wildcards:

```js
> minimatch('/path/to/functions/foo/bar', '**/foo/bar', { matchBase: true, dot: true })
true
```

## There's no pattern negation

Pattern negation is what allows you do do something like this in a
`.gitignore`:

```gitignore
/dist/*
!/dist/package.json
```

This would ignore everything in the `dist` directory except for
`dist/package.json`.

This is particularly handy in a number of situations, especially when
you consider the alternative which is to _explicitly ignore every single
file or directory you have in `dist`_. And obviously, remembering to add
any _new_ file to your ignore list when you create them, or when tools
you use create other random files you don't even know exist.

All that to say, you guessed it, that Firebase `functions.ignore`
[doesn't support this](https://github.com/firebase/firebase-tools/issues/2677).

## Conclusion

That's all I have for today. If you're working with Firebase
`functions.ignore` right now and noticed a few quirks, I hope this made
it easier for you to understand what's going on.

And if you're trying to fix a Firebase functions source being too large
to be deployed, I also [wrote a post](firebase-functions-entity-too-large.md)
with tips to troubleshoot it.

Peace. ✌️
