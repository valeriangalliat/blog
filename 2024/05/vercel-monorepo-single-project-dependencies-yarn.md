# Vercel monorepo: install only a single project dependencies with Yarn
May 4, 2024

If you have a Vercel app as part of a monorepo, it may bother you that
by default every build installs the whole monorepo dependencies.

If the Vercel app is the _main_ project in the monorepo, it should go
unnoticed, but if you have a bunch of other packages whose dependencies
differ a lot from that of the Vercel app, then it will be very obvious
that you're spending a lot of time installing useless stuff on every
build.

If you're using a modern version of Yarn, aka not "Yarn classic", aka
Yarn "Berry" and later, which would be Yarn 4 today, then you can use
[`yarn workspaces focus`](https://yarnpkg.com/cli/workspaces/focus) to
do just that.

[In Yarn 3](https://v3.yarnpkg.com/cli/workspaces/focus), you need to
install the `workspace-tools` plugin via `yarn plugin import
workspace-tools` for this to work. In Yarn 4, the command is supported
out of the box.

`yarn workspaces focus`, when run from inside a specific workspace
directory, will install that workspace dependencies, as well as the
dependencies of all the workspaces it depends on.

<div class="note">

**Note:** if you're using `nodeLinker: node-modules`, the `node_modules`
layout may differ a bit, especially the fact that packages from your
other workspaces are no longer installed at the root of the monorepo.

This will make it obvious if you're implicitly depending on packages
that are part of your monorepo but not depended on by your specific
workspace.

</div>

In order to configure that on Vercel, you can configure the following in
`vercel.json`:

```json
{
  "installCommand": "yarn workspaces focus"
}
```

<div class="note">

**Note:** you'll probably want to mirror that configuration inside your
app settings in the Vercel dashboard in **Settings > Build & Development
Settings > Install Command**, otherwise after you deploy, Vercel will
warn you that "the configuration of the current production deployment
differ from your current project settings".

</div>

## Making it work with Vercel cache

There's one more problem. Now you download only the dependencies of your
project, which is much better, but on subsequent builds, Yarn keeps
re-downloading everything again. It's like there's no cache!

That's because Vercel and Yarn 3 and greater don't play well together.
Yarn needs its `.yarn/cache` and Vercel doesn't cache it between builds.

More details in [this other post](vercel-monorepo-cache-yarn-installs.md). 😉

TLDR: use the following command.

```json
{
  "installCommand": "YARN_CACHE_FOLDER=.next/cache/yarn-cache yarn workspaces focus"
}
```
