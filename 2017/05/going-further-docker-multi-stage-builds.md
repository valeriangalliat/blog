---
canonical: https://www.busbud.com/blog/going-docker-multi-stage-builds/
hero: ../../img/2017/05/going-further-docker-multi-stage-builds.jpg
heroCredit: Thomas Kelley
heroCreditUrl: https://unsplash.com/photos/t20pc32VbrU
---

# Going further Docker multi-stage builds
One Dockerfile to rule them all  
May 21, 2017

<div class="note">

**Note:** this is a mirror of the blog post originally published on
[Busbud blog](https://www.busbud.com/blog/going-docker-multi-stage-builds/)!

</div>

Yesterday, we [learnt about Docker multi-stage builds](docker-multi-stage.md)
and how awesome they are.

Today, we're pushing it even further by combining it with the `ONBUILD`
instruction. Fasten your seat belts!

## The copy-pasted Dockerfile of hell

At the moment we have more than 50 Node.js microservices at Busbud, and
each of them have a Dockerfile. Except for a couple microservices, this
Dockerfile is basically the exact same: installs dependencies (including
system build tools if we have some native dependencies), and add our app.

We managed to do that in both a time efficient and space efficient
manner by [using multi-stage builds][multi-stage-busbud]. But we know
that having many Dockerfiles that are basically identical is a pain to
maintain. We've experienced this pain first hand over [the last two years
worth of changes][dockerfiles-history].

[multi-stage-busbud]: dockerfiles-history.md#2017-04-19-multi-stage
[dockerfiles-history]: dockerfiles-history.md

> In the beginning we were editing the Dockerfiles manually, but when we
> had more than 20 it started to be a real pain.
>
> I started [`bufdo`][bufdo]ing Vim macros to ease that, for a bit, but
> by the time we had 40 or more Dockerfiles I was editing them all at
> once through `sed -i` scripts and checking the `git diff` to make sure
> it applied the change properly  across all the Dockerfiles that can
> have slight variations (some have build dependencies, some other
> don't, some have additional dependencies, some require extra
> build steps, etc.).

[bufdo]: http://vim.wikia.com/wiki/Run_a_command_in_multiple_buffers

This is too much work, and as I'm lazy, I decided to refactor out as
much as I could from the Dockerfiles so we have a single "top-level"
Dockerfile to edit when we want to make a change in the way we build our
microservices.

## Using `ONBUILD` instructions

That's where [`ONBUILD`][onbuild] saves us: we can make a base image that
not only refactors out the common parts (installing a specific version
of npm or Yarn, installing build dependencies), but also the
instructions that are specific to a build, like adding files to the image,
and any `RUN` instruction that depends on those files to be added:

[onbuild]: https://docs.docker.com/engine/reference/builder/#onbuild

```dockerfile
# node:x.x.x-alpine-onbuild

FROM node:x.x.x-alpine
WORKDIR /app/

RUN apk add --no-cache --virtual .build-deps python make g++
RUN rm /usr/local/bin/yarn && npm install -g yarn

ONBUILD COPY ./package.json ./yarn.lock /app/
ONBUILD RUN yarn --production
ONBUILD COPY . /app/
ONBUILD RUN apk del .build-deps

CMD ["node", "."]
```

Then we can extend that base image in all our Dockerfiles, and have the
`FROM` be the only line needed:

```dockerfile
FROM node:x.x.x-alpine-onbuild
```

But we also saw how multi-stage builds allowed us to separate the build
steps from the runtime image to push the smallest image possible to the
registry. What if we could have both?

## Multi-stage + `ONBUILD` = ❤️

I'm not sure if it's a bug, a feature, or a undefined behavior, but it
turns out that you can reference a build stage from the `ONBUILD`
instructions of a base image. Sounds confusing? It'll be more clear with
an example.

Let's start by making a base image only for building our app:

```dockerfile
# node:x.x.x-builder

FROM node:x.x.x-alpine
WORKDIR /app/

RUN apk add --no-cache --virtual .build-deps python make g++
RUN rm /usr/local/bin/yarn && npm install -g yarn

ONBUILD COPY ./package.json ./yarn.lock /app/
ONBUILD RUN yarn --production
ONBUILD RUN apk del .build-deps
```

So far so good, nothing fancy. We can extend it and make a new stage to
make a small production image:

```dockerfile
FROM node:x.x.x-builder AS builder

FROM alpine:x.x
WORKDIR /app/

ONBUILD COPY --from=builder /usr/local/bin/node /usr/local/bin/
ONBUILD COPY --from=builder /usr/lib/ /usr/lib/
ONBUILD COPY --from=builder /app/ /app/
ONBUILD COPY . /app/

CMD ["node", "."]
```

That's great, but we can go *deeper.* Let's extract the second stage that
defines the runtime image in a base image too:

```dockerfile
# node:x.x.x-runtime

FROM alpine:x.x
WORKDIR /app/

ONBUILD COPY --from=builder /usr/local/bin/node /usr/local/bin/
ONBUILD COPY --from=builder /usr/lib/ /usr/lib/
ONBUILD COPY --from=builder /app/ /app/
ONBUILD COPY . /app/

CMD ["node", "."]
```

And modify our Dockerfile to use it:

```dockerfile
FROM node:x.x.x-builder AS builder
FROM node:x.x.x-runtime
```

There's no way this would work, right?

```console
$ docker build -t multi-stage-onbuild-test .
Sending build context to Docker daemon  1.295MB
Step 1/2 : FROM node:6-builder as builder
# Executing 3 build triggers...
Step 1/1 : COPY ./package.json ./yarn.lock /app/
Step 1/1 : RUN yarn --production
 ---> Running in 2af6b63fe907
yarn install v0.24.4
[1/4] Resolving packages...
[2/4] Fetching packages...
[3/4] Linking dependencies...
[4/4] Building fresh packages...
Done in 1.32s.
Step 1/1 : RUN apk del .build-deps
 ---> Running in d4d220dec219
(1/26) Purging .build-deps (0)
...
OK: 6 MiB in 13 packages
 ---> ab798b07ef77
Removing intermediate container fcb4e828e943
Removing intermediate container 2af6b63fe907
Removing intermediate container d4d220dec219
Step 2/2 : FROM node:6-runtime
# Executing 4 build triggers...
Step 1/1 : COPY --from=builder /usr/local/bin/node /usr/local/bin/
Step 1/1 : COPY --from=builder /usr/lib/ /usr/lib/
Step 1/1 : COPY --from=builder /app/ /app/
Step 1/1 : COPY . /app/
 ---> ba7bd1900b34
Removing intermediate container b6dd4d376ef6
Removing intermediate container 9292baa3d600
Removing intermediate container 2e7364e2c000
Removing intermediate container 37b69f6ddd38
Successfully built ba7bd1900b34
Successfully tagged multi-stage-onbuild-test:latest
```

As surprising as it can be, this image builds and does exactly what
we want!

<figure class="center">
  <object data="https://blog-assets.busbud.com/wp-content/uploads/2018/05/amazed.gif" type="image/gif">
    <img alt="Amazed" src="https://i.gifer.com/embedded/download/2IM.gif">
  </object>
</figure>

Now all our Node.js microservices' Dockerfiles are those exact two
lines, with optional additional steps in both the builder and runtime if
needed. But the common part is now factored away from the microservice
images; it sits cleanly in the base builder and runtime images!

## Can we go even deeper?

Combining `ONBUILD` and two base images using multi-stage builds allowed
us to have trivial Dockerfiles and keep common logic in only one place,
but it requires to maintain two Dockerfiles, in the same way [the
builder pattern][builder-pattern] did until multi-stage builds were
introduced. We also need two lines in the main Dockerfile, and we have
to give the build stage the name that is expected by the runtime image.

[builder-pattern]: docker-multi-stage.md#the-smart-but-little-known-hack-aka-the-builder-pattern

This is definitely a hack and could be cleaner by having a way for a
base image to define multiple stages in the context of the downstream
build, the same way `ONBUILD` does for commands. That would allow the
community to make "buildpack" images, that could build and package
applications for production, in a generic way, while keeping all the
benefits of multi-stage builds.

We could even get rid of Dockerfiles entirely if we want, when the
buildpack already supports everything we need. Imagine the following:

```sh
docker build --buildpack=node:6 -t myapp .
```

The buildpack would know how to add your `package.json`, figure out if
it needs to run `npm install` or `yarn`, and add everything to a small
runtime image that doesn't include any build dependencies.

Turns out this is nearly possible... you can use the `--file` option to
use a custom Dockerfile path (that can be the two lines one we just made):

```sh
docker build -f /path/to/buildpacks/node/6 -t myapp .
```

The downside is that the file can't be remote, and can't be managed like
base images. Also it wouldn't allow a way to customize the build out of
the box, so it's maybe not that of a good solution.

Even if it looks hacky, the current solution we have of having two
`FROM`, one for the bulilder and one for the runtime, allows us to
customize the build process and the runtime image without any special
syntax, and those two base images can be pulled from the registry like
any other image.

You're now all caught up on how we use Docker at [Busbud][busbud] to
ship fast and build out the world's largest bus supply. If you're
interested in these challenges and more, be sure to reach out, we're
[hiring]!

[busbud]: https://www.busbud.com/en
[hiring]: https://www.busbud.com/en/careers
