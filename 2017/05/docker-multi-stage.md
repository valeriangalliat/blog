---
canonical: https://www.busbud.com/blog/introducing-docker-multi-stage-builds/
hero: ../../img/2017/05/docker-multi-stage.jpg
focus: 50% 25%
heroCredit: Axel Ahoi
heroCreditUrl: https://unsplash.com/photos/hjEesK4KSDs
---

# Introducing Docker multi-stage builds
Because we can have both fast builds and small images  
May 15, 2017

<div class="note">

**Note:** this is a mirror of the blog post originally published on
[Busbud blog](https://www.busbud.com/blog/introducing-docker-multi-stage-builds/)!

</div>


Docker 17.05 (**hipster warning:** at the moment of writing, only in the
Edge channel, not yet in Stable), among other features, introduced
[multi-stage builds][multi-stage].

[multi-stage]: https://docs.docker.com/engine/userguide/eng-image/multistage-build/

This feature allows to use multiple images in a Dockerfile, that can
reference each other. Typically, using one image for building your app,
where you install all the build tools and development dependencies, and
a second one, trimmed down for production.

Before multi-stage, we could see a couple patterns to write Dockerfiles
in the community, that would either optimize for image size or build
time. Here's a quick overview:

* [The everything but the kitchen sink image](#the-everything-but-the-kitchen-sink-image)
* [The "my time is cheaper than disk space" one-liner](#the-my-time-is-cheaper-than-disk-space-one-liner)
* [The smart but little-known hack, aka the builder pattern](#the-smart-but-little-known-hack-aka-the-builder-pattern)
* [Multi-stage builds to the rescue](#multi-stage-builds-to-the-rescue)

## The everything but the kitchen sink image

That's [where we started](dockerfiles-history.md#2015-12-03-baby-steps-at-docker),
and because we had better things to do than optimize disk space image,
we even [came back to it](dockerfiles-history.md#2017-01-20-no-base-images)
before multi-stage existed.

The concept is simple: you start from a somewhat clean system, then you
install a compiler toolchain and a bunch of interpreters that you don't
use but that some of your dependencies require to be compiled, the
package manager(s) of your choice in the version that most suits your
taste, on top of the one that comes with the base image that you will
never use, so you can download all your dependencies, maybe even your
development dependencies if you want to run some build steps for your
own app too.

Then you add your app and you push the whole thing to the Docker
registry, because YOLO and storage is cheap anyway, and your connection
is fast enough so you can *just* get a coffee or play a ping pong game
while you push or pull your images.

You're not pushing a container, you're basically pushing a whole cargo
ship that carries not only your container but also a whole bunch of
containers that might have been useful at some point to build your app.

But you put an extra layer to "cleanup" at the end so you feel like a
good guy and go back to asking your sysadmin to buy a couple more hard
drive, even though that extra layer is actually adding a hair to your
ridiculously massive image.

## The "my time is cheaper than disk space" one-liner

This one consists in putting as many commands as you can into a single
`RUN` instruction. The rule is that you must install *and* cleanup
everything that you don't need on your production image, in the same
layer so it doesn't take useless space.

Sounds nice, until you realize the intrinsic idea of build dependencies
is that you *need* them to build your app but you *don't want them* in
your production image. Installing system packages, dependencies,
compiling everything, and cleaning up all end up being in the same step
that you can't break down into smaller steps that could be cached.

And you don't just have to cleanup after yourself, you also need to
cleanup for every single tool that you used in the process that might
have created temporary files, or just files that you don't need
(`/usr/share/man`, `/tmp`, `~/.tmp`, `~/.cache`, `/var/cache`,
`/root/.gnupg`, `/var/my/package/manager/database`,
`/root/.some-build-tool-cache` and a whole bunch of other locations that
you won't know about or will forget anyway).

That's like the complete opposite of the previous pattern: instead of
carrying everything in the final image, you shove the whole thing into a
one-liner, and instead of playing a game of ping pong, you participate
in an entire bracket tournament while your container downloads and
compiles the whole universe to build your app, after all you did was fix
a typo in a static file that doesn't even need to be compiled.

[We tried it too](dockerfiles-history.md#2016-02-24-first-optimizations),
because we thought it would be useful to start caring, but it got extra
frustrating to have such slow builds, and watching `apt-get install`,
`npm install` and native dependencies compilations take the vast
majority of every single build when most of the time you know
it's not necessary at all for what you changed.

## The smart but little-known hack, aka the builder pattern

The [builder pattern][builder-pattern] is the predecessor of multi-stage
builds. It's the DIY version.

[builder-pattern]: http://blog.alexellis.io/mutli-stage-docker-builds/#whatwasthebuilderpattern

You have a Dockerfile for building, where you do absolutely whatever you
want with build tools, dependencies, package manager, compilations and
layers without caring about the size (or really anything), and then you
have a second Dockerfile for production, off a minimal image, where you
install and copy only the stuff that you need for runtime from the
builder image. The best of both worlds!

To do that, you need a script that's going to extract files from the
builder image into a temporary directory, add the given files to the
production image and remove the temporary directory (between building
both images).

That's cool, but it looks like a hack, feels like a hack (hint: it's
probably a hack), and you need two Dockerfiles and a shell script for
this to work.

## Multi-stage builds to the rescue

Multi-stage builds is what happens when you take the previous hack and
put it in Docker's core so it doesn't look like a hack anymore. Clever.

So you don't need two Dockerfiles, a shell script and a whole bunch of
duct tape anymore, you can just keep everything cleanly in your
Dockerfile!

Want an example? This is the one we use for our Node.js microservices at
Busbud:

```dockerfile
FROM node:6-alpine AS builder
WORKDIR /app/

RUN apk add --no-cache --virtual .build-deps python make g++
RUN rm /usr/local/bin/yarn && npm install -g yarn

COPY ./package.json ./yarn.lock /app/
RUN yarn --production
RUN apk del .build-deps

FROM alpine:3.5
WORKDIR /app/

COPY --from=builder /usr/local/bin/node /usr/local/bin/
COPY --from=builder /usr/lib/ /usr/lib/
COPY --from=builder /app/ /app/
COPY . /app/

CMD ["node", "."]
```

See how we base the final image off a bare `alpine:3.5` and copy only
the strict minimum from the builder image?

This way, everything happens with optimal caching in the builder image,
and we can have a slim production image that contains only what it needs
to run: the `node` binary and its system libraries, and the application
source code and its (compiled) dependencies (no package manager, no
forgotten cache directories that would have been used during the build,
no Python and C compiler and so on).

Multi-stage builds allow us to have the smallest production image
possible, without any tradeoff with build time.

## Conclusion

With multi-stage builds, Docker effectively understands that a build
needs...  *building,* and provides us proper tooling to build
efficiently our apps without affecting the production images.

This is an amazing addition to Docker that responds to a crying need,
and that's why we jumped on it as soon as it was available in Edge.

We'd like to extend a heartfelt thank you for putting this together as
it pretty much solved [all our problems](dockerfiles-history.md).

I'm proud to work in a company where we have the freedom to experiment
with cutting edge technologies (and eventually adopt them). If you want
to join us, don't forget that we're [hiring]!

[hiring]: https://www.busbud.com/en/careers

P.S. Hey, we decided to go even further with multi-stage builds! Check
out how to [make it even more powerful](going-further-docker-multi-stage-builds.md)
when combining it with `ONBUILD` instructions!
