# TypeScript: cannot write file `.d.ts` because it would overwrite input file
October 16, 2021

There's [countless](https://stackoverflow.com/questions/42609768/typescript-error-cannot-write-file-because-it-would-overwrite-input-file)
[issues](https://stackoverflow.com/questions/46914070/how-to-exclude-d-ts-file-for-typescript-compiler)
[about](https://github.com/microsoft/TypeScript/issues/16749)
this error and I thought it would be useful to write a clear explanation
of what's going on and a summary of the possible solutions.

This happens for two reasons:

1. You're explicitly including those `.d.ts` files e.g. as part of your
   `include` array in `tsconfig.json` or as part of the `tsc` arguments,
   and you're asking TypeScript to output type declarations in the same
   place. Then the error is pretty obvious and the fix should be too
   (don't output the generated declarations in the same place as types
   you're importing, for example using `outDir`, or don't import those
   generated declarations in the first place).
1. You're not importing those `.d.ts` files, or you're even explicitly
   ignoring them e.g. with the `exclude` array in `tsconfig.json`, yet
   TypeScript keeps using them as input and complaining that it can't
   overwrite them when generating type declarations.

Here we'll go in more details about the second reason.

## The problem

The main thing that you need to know is that if you're importing a `.js`
file and there's a matching `.d.ts` next to it, TypeScript will
**always** import it, even if you didn't explicitly include those
`.d.ts` files as input, and even if you explicitly put them in the
`exclude` array. There's no way around this.

## Output `.d.ts` declarations to a separate directory

One solution is to put the generated type declarations in a separate
directory instead of next to the `.js` files. You can do that by
configuring a `outDir`, as explained in the documentation about
[creating `.d.ts` files from `.js` files](https://www.typescriptlang.org/docs/handbook/declaration-files/dts-from-js.html#tsconfig):

```json
{
  "compilerOptions": {
    // Tells TypeScript to read `.js` files, as normally they are
    // ignored as source files.
    "allowJs": true,
    // Generate `d.ts` files.
    "declaration": true,
    // This compiler run should only output `d.ts` files.
    "emitDeclarationOnly": true,
    // Types should go into this directory. Removing this would place
    // the `.d.ts` files next to the `.js` files.
    "outDir": "dist"
  }
}
```

As they nicely indicate, if you don't specify `outDir`, the `.d.ts` will
be put next to the `.js` files (which literally means they'll be
automatically considered as inputs on the next build and it will crash),
and it's probably the way you're using this right now.

Then you can tell TypeScript where to [find the package types](https://www.typescriptlang.org/docs/handbook/declaration-files/publishing.html)
in your `package.json`:

```json
{
  "types": "dist"
}
```

But this only works for the main export (`import 'my-lib'`) and will
break if you attempt to import nested files `import 'my-lib/some-file'`.

If you want to support this use case, you **have to** ship the `.d.ts`
files next to the `.js` files.

So here's a few alternative solutions and their tradeoffs.

## Copy the `.js` files next to the `.d.ts` declarations

Since we can't generate the `.d.ts` next to the source `.js` files (well
we can, but just once), we can instead generate the `.d.ts` files to a
`dist` directory and copy the `.js` files next to them.

There's two ways you can do that, the first one I tried is to remove
`emitDeclarationOnly` so that let TypeScript compiles the source `.js`
files to the `outDir`, and the other one is to manually copy them.

In both cases there's a number of caveats with that about how you import
nested files, and I'll go through the possible workarounds.

### Compile your JS files to JS (lol)

The reason you have this error in the first place is likely because
you're writing actual JavaScript and generating types from JSDoc.

One of the numerous benefits of doing that is that you don't need to
compile your code. Your `src` is your `dist` and that's the beauty of
it. You run what you write, no compilation, no source maps, and no
configuration of every single tool and service you use to deal with this
extra complexity.

You can throw away all of those benefits by letting TypeScript compile
your `.js` files to the `outDir`, by removing `emitDeclarationOnly` from
the `tsc` command or `tsconfig.json`, so that they're put along the
generated `.d.ts` files.

But at that point you might as well write TypeScript in the first place.

### Manually copy your JS files to the `outDir`

A [better way](https://vccolombo.github.io/blog/tsc-how-to-copy-non-typescript-files-when-building/)
if you want to ship your `.js` files unaltered is to copy them yourself
next to the `.d.ts` declarations.

```sh
tsc *.js --allowJs --declaration --emitDeclarationOnly --outDir dist && cp *.js dist
```

Then you can `import 'my-lib/dist/some-file` and types will work
properly. If you want to allow deep imports though, we need to dig a bit
further.

## Getting it to work with deep/nested imports

If you want to allow `import 'my-lib/some-file'` and don't like the idea
of documenting `import 'my-lib/dist/some-file'`, you have again
[a few options](https://stackoverflow.com/questions/67097803/how-to-let-users-import-from-subfolders-of-my-npm-package).

### Compile to the project root

Make sure your source files are in a subfolder, e.g. `src`, then compile
to the project root directory.

```sh
tsc src/*.js --allowJs --declaration --emitDeclarationOnly --outDir . && cp src/*.js .
```

### Publish from your `dist` directory

The previous solution might get a bit messy though so
[alternatively](https://stackoverflow.com/questions/38935176/how-to-npm-publish-specific-folder-but-as-package-root)
you can use the earlier command with `--outDir dist`, but put your
`package.json` in the `dist` directory as well, and run `npm publish
dist` (or `cd dist && npm publish`).

Whether you want your `package.json` to live in the `dist` directory
(and commit it there), or run `cp package.json dist` as part of your
build command is up to you.

### Write an `exports` map

If you're not happy with the previous solutions, you can write an
[`exports` map](https://nodejs.org/api/packages.html#packages_exports)
in your `package.json` so that `import 'my-lib/some-file` translates
to `my-lib/dist/some-file`.

```json
{
  "exports": {
   "./some-file": "./dist/some-file",
   "./some/other-file": "./dist/some/other-file"
  }
}
```

That being said only the paths defined here will be allowed to be
imported, you won't be able to import arbitrary files anymore, which
might not be a bad thing, but maybe you like the simplicity of
everything being importable by default.

## Quick and dirty hack that actually works

To get the best of both worlds by generating `.d.ts` files next to your
source `.js` files without adding extra configuration and still allowing
deep imports, you need to **explicitly remove the generated files before
running the compiler**.

Simple, easy and dirty:

```sh
rm -f *.d.ts && tsc *.js --allowJs --declaration --emitDeclarationOnly
```

Here I use `rm -f` so that it doesn't fail if the declaration files are
not generated yet. Feel free to tweak the pattern, for example if you
have subfolders you want to include.

I'm not a big fan of this solution, but it's still my favorite of all
the ones I described in this post. It seems that TypeScript wasn't built
for simplicity, let alone for working with source `.js` files, and deep
imports don't seem to be part of the happy path either. If you found a
better way, please [let me know](/val.md#contact)!
