# Cloudflare Workers choke on asdf `.tool-versions`
February 10, 2026

So you have a project you want to deploy to Cloudflare Workers, and you
happen to have a `.tool-versions` file to describe your dependencies,
even just a simple one like:

```
nodejs 24.13.1
```

Then your Cloudflare deploy fails with:

```
Initializing build environment...
Success: Finished initializing build environment
Cloning repository...
Found a .tool-versions file in repository root. Installing dependencies.
Restoring from dependencies cache
Restoring from build output cache
Failed: error occurred while installing tools or dependencies
```

There's a
[couple](https://community.cloudflare.com/t/undocumented-tool-versions-support/855532)
[threads](https://community.cloudflare.com/t/cloudflare-workers-deploy-crashes-on-tool-versions/871072)
on
[Cloudflare](https://community.cloudflare.com/t/how-to-disable-automatic-installs-of-tool-versions-and-package-json/570450)
[Community](https://community.cloudflare.com/t/support-pnpm-in-tool-versions/645235)
about this and similar `.tool-versions` issues. They get closed after 15
days without any answer, with the oldest one from 2023 and still no
solution to this day.

The fact Cloudflare Workers (and Cloudflare Pages) look at
`.tool-versions` is undocumented, it so happens that it chokes on even
the most basic `.tool-versions` possible, so it essentially means the
mere presence of this file in your project will break your build on
Cloudflare, without any way to turn off this behavior (like forcing
Cloudflare to ignore that file). As reported in [this issue](https://community.cloudflare.com/t/how-to-disable-automatic-installs-of-tool-versions-and-package-json/570450),
the `SKIP_DEPENDENCY_INSTALL` environment variable does _not_ help with
this behavior.

## The solution

So what's left? Well, I had to remove `.tool-versions` from my
repository.

Instead, I moved it to `.tool-versions.template`, and when setting up
the repo in any environment that _actually_ supports `.tool-versions`, I
just `cp .tool-versions.template .tool-versions` (with `.tool-versions`
being in `.gitignore`).

## Setting the correct Node.js version on Cloudflare

As for Cloudflare, in order to set the proper versions, I'm using the
`NODE_VERSION` and `PNPM_VERSION` build environment variables. (Also
`NPM_VERSION` and `YARN_VERSION` depending on your package manager of
choice).

```
NODE_VERSION=24.13.1
PNPM_VERSION=10.29.2
```

This is, of course, also undocumented, but it works!
