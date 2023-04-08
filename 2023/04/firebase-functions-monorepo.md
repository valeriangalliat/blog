---
tweet: https://twitter.com/valeriangalliat/status/1644495294803898369
---

# Firebase functions in a monorepo? A challenging pile of hacks
April 7, 2023

I recently went through the trouble of migrating a Firebase app to a
monorepo, in particular the Cloud Functions part. While doing so, I went
through a total of 3 different "methods", all of which were full of
surprises that I discovered along the way.

In this blog post I'll go through those 3 options, and highlight their
tradeoffs, in order to help you pick the one that's the most appropriate
to your workflow. It's a long post, so feel free to jump to the
[comparison](#comparison) directly, and then cherry pick what to read
from there. 😄

Here, I assume that your monorepo uses something like npm or Yarn
workspaces. It may be applicable to pnpm but I didn't try it.

## The common ground

Before we get started with the 3 options, they all share a common
ground. And for the sake of this blog post, I'll start with an
hypothetical base monorepo structure which I'll lay down below.

### The base monorepo

This is a basic monorepo with two websites and a shared package, e.g.
for helper functions, types or any other common code.

```
monorepo
├── apps
│   ├── website1
│   │   └── package.json
│   └── website2
│       └── package.json
├── packages
│   └── shared
│       └── package.json
├── package-lock.json
└── package.json
```

The top-level `package.json` contains:

```json
{
  "workspaces": [
    "apps/*",
    "packages/*"
  ]
}
```

### The Firebase functions in its own repo

In another repo, you have a Firebase app with functions:

```
firebase
├── functions
│   ├── src
│   │   └── index.js
│   ├── package-lock.json
│   └── package.json
└── firebase.json
```

Where your `firebase.json` contains:

```json
{
  "functions": {
    "source": "functions"
  }
}
```

### Merging them together

Since in a Firebase repo, `functions` is already its own subdirectory
with its own `package.json`, it feels pretty natural to just "merge"
both repos together, maybe  renaming `functions` into `apps/functions`
to match our initial structure better, but no more than that:

```diff
 monorepo
 ├── apps
 │   ├── website1
 │   │   └── package.json
 │   ├── website2
 │   │   └── package.json
+│   └── functions
+│       ├── src
+│       │   └── index.js
+│       └── package.json
 ├── packages
 │   └── shared
 │       └── package.json
+├── firebase.json
 ├── package-lock.json
 └── package.json
```

In `firebase.json`, we just update the `source` to be `apps/functions`,
and we remove the `functions/package-lock.json` to let npm merge the
functions dependencies in the top-level `package-lock.json`. This way,
we only need to run `npm install` at the root of the monorepo, instead
of having to go inside `apps/functions` and run `npm install` there
again. After all, that's part of the point of a monorepo.

Great, so we're done? That was easy.

## Why this works, but not really

Not so fast. This will seemingly work, but it will do so kind of by
chance, as a somewhat lucky accident.

### How `firebase deploy` works

See, when `firebase deploy` deploys the functions, it will make a ZIP
archive of the functions source directory (as defined in `firebase.json`).

Then, it will deploy the function from that ZIP. The Cloud Functions
deploy process will send that ZIP to Cloud Build, which will:

1. Run some variant of `npm install` or `yarn install`.
1. Run the `gcp-build` script if defined in `package.json`.
1. Prune development dependencies from `node_modules` if needed.
1. Use the output of that process as the source for the function
   runtime.

This is defined in GCP buildpacks, e.g. [for npm](https://github.com/GoogleCloudPlatform/buildpacks/blob/99553d0a2051834324d621f20ad5355453f675a1/cmd/nodejs/npm/main.go)
and [for Yarn](https://github.com/GoogleCloudPlatform/buildpacks/blob/99553d0a2051834324d621f20ad5355453f675a1/cmd/nodejs/yarn/main.go).

We can already see a bit of a problem. Because we're sending only the
`apps/functions` context to Cloud Build, it doesn't have access to the
top-level `package-lock.json`, which means the install output will be
nondeterministic, and each deploy is subject to using different versions
of different packages and potentially break your code without you
knowing.

**This can introduce a whole range of sneaky errors that will be a pain to
debug!**

### Using shared packages

Moreover, we now understand that this will not allow using _shared
packages_ inside the monorepo!

If we wanted to use `packages/shared` inside `apps/functions`, by adding
`"shared": "*"` in our `dependencies`, letting npm or Yarn resolve it to
the local workspace version, it wouldn't actually work.

Or actually, it will work in development, because we have the whole
monorepo there. And in our particular example, even the Firebase
deployment will surprisingly succeed, **but only as an accident because
[`shared`](https://www.npmjs.com/package/shared) is a valid npm
package**! It will break at runtime when you try to use a package that
doesn't contain the code you expect at all.

Other names for common monorepo shared packages that are also valid npm
packages would be [`eslint-config`](https://www.npmjs.com/package/eslint-config)
and [`tsconfig`](https://www.npmjs.com/package/tsconfig), so they would
also result in this kind of collision.

<div class="note">

**Note:** if you use Yarn, you can prevent those collisions by prefixing
your version specifier for your shared dependencies with `workspace:`,
e.g. `"shared": "workspace:*"` to use any version. This will ensure the
dependency is _always_ installed from the local workspace and not from
the registry.

npm doesn't support that, but you can still add a layer of safety by
making sure all your shared package names don't conflict with anything
on npm, for example by prefixing them with `@myorg` such as
`@myorg/shared`, `@myorg/eslint-config`, `@myorg/tsconfig` and so on.

Or as an abundance of caution if you use Yarn, maybe do both. 😬

</div>

## The "good enough for me" approach

We're now in a situation where 1. the top-level `package-lock.json` is
not respected when deploying Cloud Functions, and 2. we cannot use any
workspace shared package in our functions.

You may actually be fine with that. Maybe you don't care that your
production functions have an unpredictable dependency tree every time
you deploy, and maybe you don't want to use shared packages in your
functions anyway!

<div class="note">

**Note:** you can even use shared packages in your `devDependencies`
with that setup, as long as you don't have a `gcp-build` script that
depends on them!

At least if you use npm. Because there's currently a bug with the Yarn
Cloud Build buildpack that makes it install `devDependencies` before
pruning them right after, even when no build script is present. 😅

This would fail your build if the shared package from your
`devDependencies` don't exist on npm. It's one of those cases where
having a shared package name that collisions with a npm package would
help, although I wouldn't really recommend this as a fix.

</div>

If that works for you, congratulations, your job here is done.
Otherwise, let's dig in the two other options. 👇

## The full context approach

There's a [long thread](https://github.com/firebase/firebase-tools/issues/653)
in the `firebase-tools` repo about monorepo support. The majority of the
solutions described there are some variation of a deploy script that
packs your shared dependencies into `.tgz` files, and patch the
`functions/package.json` file to reference them with `file:` for the
time of the deployment. We'll explore this in details in the last solution: [the hybrid approach](#the-hybrid-approach).

However, there's [a particular comment](https://github.com/firebase/firebase-tools/issues/653#issuecomment-1371306331)
in that thread that describes something very different, and caught my
attention despite not being given very much interest there.

<figure class="center">
  <img alt="A comment suggesting to put the monorepo root as the functions source" srcset="../../img/2023/04/firebase-monorepo-comment.png 2x">
</figure>

This comment suggests that we put the monorepo root as the functions
source in `firebase.json` (ignoring unnecessary files as needed), to
ensure we send the whole relevant monorepo context to Cloud Build!

```json
{
  "functions": {
    "source": ".",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**",
      "**/packages/@(web|mobile)/**"
    ]
  }
}
```

Then, adding the functions entrypoint in the top-level `package.json`,
because Cloud Functions still don't know about monorepos, and expects the
functions `package.json` to be at the root.

```json
{
  "main": "./packages/functions/dist/index.js"
}
```

<div class="note">

**Note:** if you use `.env` files in your functions, e.g. `.env`,
`.env.production`, `.env.staging`, and any other project aliases you may
have, which is becoming more and more common [now Firebase deprecated
`functions.config()`](https://firebase.google.com/docs/functions/config-env#environment_configuration),
you also need to put them at the root of your monorepo with this
solution, otherwise they will be ignored during deploy!

</div>

To me, this sounds _much more elegant_ than the hacks with deploy
scripts and `file:` references! But after using this approach in
production for a few weeks, I decided to rollback, because there was too
many downsides for my use case.

### The ignore list is quirky

The ignore list is not exactly intuitive to work with. And if you forget
to ignore anything somewhat large, [your functions will fail to deploy](firebase-functions-entity-too-large.md).
It struggled so much to figure out the precise rules of this ignore list
that I had to go in the `firebase-tools` source code in order to
understand it, and I wrote [another blog post](firebase-functions-ignore.md)
to explain how it really works, and how to test your ignore patterns!

The main caveat is that you [can't use negative ignore rules](https://github.com/firebase/firebase-tools/issues/2677)
like you could in `.gitignore` and most ignore systems, e.g.:

```gitignore
/apps/website1/*
!/apps/website1/package.json
/apps/website2/*
!/apps/website2/package.json
```

In a `.gitignore`, this would ignore everything in `apps/website1` and
`apps/website2` except for their `package.json`. If you use "a modern
version of Yarn" (not 1.x), this is something you would need to do, because
`yarn install --immutable` will fail if the workspaces identified in
your `yarn.lock` don't actually point to directories with a
`package.json` in them!

If you use npm or Yarn 1.x though, `npm ci` and `yarn install
--frozen-lockfile` won't care, so you're good to go.

<div class="note">

**Note:** just keep in mind that Yarn 1.x doesn't let you install
dependencies for a single workspace, you systematically have to install
all dependencies for the whole monorepo, which can be a pretty bad hit
for any pipeline that works only on a small subset of the monorepo.

While you can [`yarn install --focus`](https://classic.yarnpkg.com/en/docs/cli/install#toc-yarn-install-focus)
with 1.x, which kind of sounds like this, it doesn't work with
dependencies that are local to the monorepo, they _need_ to be fetched
from a registry.

</div>

But on new Yarn versions, this is a pretty big deal because you can't
ignore a whole workspace from your functions deploy, and because there's
no negative patterns to ignore everything but the `package.json` in a
given workspace, you're stuck with having to _explicitly_ ignore
everything but the `package.json` in each of the workspaces you want to
exclude. And it's a list you'll now have to maintain forever every time
you add new things to your monorepo.

This is even more of a problem because if you have any kind of secret in
your repo, and you fail to add them to your `functions.ignore` list,
they'll be packaged in your functions source and you won't notice. Your
functions source is private to your Google Cloud account by default, but
this is silently waiting to make a future security issue much worse.

### All the other workspace dependencies are installed

This is the one that made me give up this solution. I could deal with
the ignore list issues, but this was another level.

As we saw earlier, Cloud Functions use Cloud Build to install your
dependencies. The whole thing is not designed for monorepos, which is
why we had to put our `main` entrypoint in the root `package.json`. A
more concerning effect of that though, is that Cloud Build will run `npm install`
at the top level of the monorepo.

This means installing all the dependencies of all your apps and
packages. This is big problem if you have a lot of unrelated
dependencies across your different workspaces.

Firebase doesn't let you configure the install command either, to run
e.g. `npm install --workspace functions` or `yarn workspace function workspaces focus`
(I know, awkward command), which would install only the functions
dependencies. _This can speed up your install times drastically_ in
remote build environments, but here it's not an option.

For us, the difference was 10 minutes to deploy Firebase functions vs. 2
minutes, if we could install the dependencies of the functions only.

This was to much, which is why I ended up with the last approach.

<div class="note">

**Note:** the build time issue was heavily magnified in my case by the
fact Cloud Build [doesn't do any caching for Yarn 2.x and greater](https://github.com/GoogleCloudPlatform/buildpacks/issues/203)
if it's not used in [PnP mode](https://yarnpkg.com/features/pnp).
Proper caching may help a bit with npm and Yarn 1.x, even though it's
still not ideal.

There may be a way though, for example by replacing the top-level
`package.json` and `package-lock.json` by dummy ones during `firebase
deploy` so that from Cloud Build's perspective it looks like you have no
dependencies, and then hijacking the `gcp-build` script to _actually_
install your dependencies yourself using the appropriate command that
doesn't install the whole world at the same time. 🥹

I haven't tested this but it may work. However, if you're gonna get that
hacky, you might as well embrace the third solution.

</div>

## The hybrid approach

This is an improved version of [the first "good enough for me" solution](#the-good-enough-for-me-approach),
where in our development environment, we work with a full-fledged
monorepo, with shared packages and everything, but when we deploy the
Firebase functions, we narrow it down to its own independent-repo-like
entity, but in a way that will actually work with our
`package-lock.json` and shared packages!

This will take a bit of code though, in the form of a `predeploy` and
`postdeploy` script for our functions. The `predeploy` script needs to:

1. Do anything you were already doing in a `predeploy` script like
   linting and building your app.
1. Copy all the shared packages you depend on in your functions
   directory, either through `.tgz` files from using `npm pack` or `yarn
   pack`, or the directories themselves (see below for the difference).
1. Patch your functions `package.json` to reference the internal
   dependencies using `file:` references to the `.tgz` files or
   directories you just created.
1. **Do so recursively for your whole graph of internal dependencies.**
   Hopefully it's small enough to be manageable, but I can see this
   turning into a living hell in complex monorepos.
1. Copy the top-level lock file in the functions directory. If you use
   Yarn 2.x and greater, you'll need to do a bit more than that, see
   below.

As for the `postdeploy` script, it needs to undo everything that
`predeploy` did.

Of course, your repo will be in an inconsistent state for the duration
of `firebase deploy`, so maybe run that from another copy of your
monorepo that you don't work from, or make sure to not mess with your
dependencies during the deploy, or things will fall apart!

You'll find a number of examples of those `predeploy` and `postdeploy`
scripts in the issue thread I linked earlier. Here's
[one of the most recent ones](https://github.com/firebase/firebase-tools/issues/653#issuecomment-1464911379)
that you can take inspiration from.

For the part where you replace the versions of your internal packages in
your `package.json`, you can use [`npm pkg set`](https://docs.npmjs.com/cli/v7/commands/npm-pkg)

```sh
npm pkg set 'dependencies.@myorg/shared=file:shared.tgz' 'dependencies.@myorg/tsconfig=file:tsconfig.tgz'
```

Just make a backup of your original `package.json` so you can restore it
in the `postdeploy` script. Feel free to use it with Yarn as well since
this really just edits your `package.json` from the command line.


Now, about the downsides.

### You have to recursively package your internal dependencies

And to do so, you have to patch your `package.json` files all the way
down the internal dependency graph for your functions. Nasty.

As for using `.tgz` files from `npm pack` or `yarn pack` vs. copying the
directories directly, it comes down to personal preference with npm, but
if you use Yarn and you have nested internal dependencies, you're much
better off going with the directory approach.

That's because npm can resolve `file:` references to `.tgz` files
relative to _where `npm install` is ran from_, but Yarn only looks for
the `.tgz` files relative to the `package.json` referencing it.

You can see how this becomes a problem with more than one level of
dependency, because you would have to embed the archive of the same
packages in all the packages that reference it, and do so recursively,
which can get exponentially heavy and inefficient! Not to mention that
you'd end up with a lot of duplicated dependencies, which can cause a
whole lot of other problems on its own.

It will work with the directory approach though:

1. You make your functions depend on `"@myorg/shared": "file:shared"`.
1. You make `shared/package.json` depends on `"@myorg/tsconfig": "file:../tsconfig"`.
1. You copy both `shared` and `tsconfig` under your functions directory
   and you're god to go.

### You need to mirror some top-level logic

In the previous solution, we saw how we had to copy some functions logic
at the top level (`main` inside `package.json` as well as `.env` files).
Here, we have the opposite problem.

Because we're shipping only the functions directory to Cloud Functions,
it's missing your `package-lock.json` or `yarn.lock` from the top
level (and maybe a number of other files you may need without knowing it).

For example, if you use "a modern version of Yarn" aka not Yarn 1.x, it
also needs its `.yarnrc.yml` as well as `.yarn/releases` and
`.yarn/plugins` directories in order to function!

If you forget to copy any of those inside your functions directory,
Cloud Build will either use the wrong package manager or the wrong
version of your package manager, which may result in the best case in a
broken deploy, or worst, resolving and linking dependencies differently
than in your local environment, which can lead to a number of sneaky
issues.

This is not something that's accounted for in any of the solutions from
[the thread](https://github.com/firebase/firebase-tools/issues/653)
I linked earlier. **They all ship a lonely `functions/package.json` that
will end up installing unpredictable dependency versions in their
production environment.**

Luckily, this is easy to fix! Just copy your top-level
`package-lock.json` or `yarn.lock` in the functions directory as part of
your `predeploy` script.

npm and Yarn 1.x are resilient enough to do the right thing from a
_superset_ of the lock file. More recent versions of Yarn though, are
pretty strict and will refuse to install if it finds anything
_superfluous_ in `yarn.lock` (from its partial perspective).

There's a whole bunch of ways to addresses this, tracked in
[those](https://github.com/yarnpkg/yarn/issues/5428) [issues](https://github.com/yarnpkg/berry/issues/1223),
with the emerging of various experimental Yarn plugins to fix it like
[yarn-plugin-workspace-lockfile](https://github.com/andreialecu/yarn-plugin-workspace-lockfile)
([and](https://github.com/bertho-zero/yarn-plugin-workspace-lockfile)
[its](https://github.com/milesforks/yarn-plugin-workspace-lockfile)
[forks](https://github.com/jakebailey/yarn-plugin-workspace-lockfile))
or [yarn-plugin-entrypoint-lockfiles](https://github.com/JanVoracek/yarn-plugin-entrypoint-lockfiles)
that maintains individual lock files for each workspaces (or
"entrypoint") at the cost of slightly slower installs when you add or
remove dependencies.

I initially used some version of this, but while writing this blog post,
I stumbled upon [this StackOverflow comment](https://stackoverflow.com/a/73118909/4324668)
that mentions `yarn install --mode update-lockfile`. This is _exactly
what we want_! So as of Yarn 3.x, we can just do the following:

```sh
cp yarn.lock apps/functions
cd apps/functions
yarn install --mode update-lockfile
```

This will updates `apps/functions/yarn.lock` to contain _only_ the
entries _necessary_ for your functions, while keeping the versions that
were pinned in the original lock file. This will happily work when Cloud
Build runs `yarn install --immutable` later on. 😍

Again, this is something you need to do in your `predeploy` script, and
undo in your `postdeploy`.

## Comparison

Let's compare the pros and cons of those 3 options.

**[Good enough](#the-good-enough-for-me-approach)**

* 🟢 Easy AF.
* 🟡  Doesn't use your lock file, you're installing nondeterministic
  versions of your dependencies in production (easily fixable by taking
  that specific part of the hybrid approach though).
* 🔴 Can't use workspace shared packages.

**[Full context](#the-full-context-approach)**

* 🟢 Supports your lock file and any other monorepo-wide config
  (Yarn version, etc.) by design and out of the box.
* 🟢 Supports shared workspaces packages by design and out of the box.
* 🟡 Need to proxy the functions `main` entrypoint in the top-level `package.json`,
  as well as other things like functions `.env` files.
* 🟠 Need to maintain the `functions.ignore` list which is clunky,
  and gets significantly worst when using modern Yarn versions.
* 🔴 It installs your whole monorepo dependencies instead of just your
  functions dependencies.

**[Hybrid](#the-hybrid-approach)**

* 🟢 None of the downsides of the previous approach.
* 🟡 You have to copy your lock file and maybe other global requirements
  like your `.yarnrc.yml`, `.yarn` folder and alike inside your
  functions directory.
* 🔴 Needs a `predeploy` and `postdeploy` script to package workspace
  dependencies inside the functions directories, and recursively patch
  their `package.json` to reference them with `file:`.

## Conclusion

Today, we went through 3 methods to make Firebase functions _somewhat_
work with a monorepo: [the "good enough for me" approach](#the-good-enough-for-me-approach),
[the full context approach](#the-full-context-approach)
and [the hybrid approach](#the-hybrid-approach). Finally, we
[compared their pros and cons](#comparison).

By now, you should have everything you need in order to make an educated
decision about which method to pick.

And if you find any other cool trick to make working with Firebase
functions in a monorepo easier, don't hesitate to [let me know](/val.md#contact)!
