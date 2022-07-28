---
canonical: https://www.busbud.com/blog/history-dockerfiles-busbud/
hero: ../../img/2017/05/dockerfiles-history.jpg
heroCredit: Gabriel Ghnassia
heroCreditUrl: https://unsplash.com/photos/VmS8VQ0n39Q
---

# A history of Dockerfiles at Busbud
The evolution and optimization of our Dockerfiles in the past two years  
May 13, 2017

<div class="note">

**Note:** this is a mirror of the blog post originally published on
[Busbud blog](https://www.busbud.com/blog/history-dockerfiles-busbud/)!

</div>

At Busbud, we implement hundreds of APIs to integrate the bus companies
of our constantly growing list of partners on our API and website, so
that you can search and book those buses in over 60 countries.

About two years ago, we ran into scaling issues as all those
integrations were part of our API code, and the whole monolith was
running on the same Heroku dyno.

We decided to split the integrations from the API, but at the same time
to also split them into microservices, so we can scale and deploy them
independently. That's when we started looking at Docker.

This article will focus only on the way we wrote our Dockerfiles, to
finally find the perfect design to get the fastest build time while
having the smallest image size.

## 2015-12-03 - Baby steps at Docker

The first image was very basic... and not very clever:

```dockerfile
FROM node:x.x.x-slim

# RUN apt-get update
# RUN apt-get -y install build-essential python

RUN npm install -g npm@x.x.x

COPY . /app/
WORKDIR /app/

RUN npm install --production

# RUN apt-get -y remove --purge --auto-remove build-essential python
# RUN apt-get clean
RUN rm -rf /root/.npm

CMD ["npm", "start"]
```

The commented lines would be used when some of our npm dependencies
would have a native build step (I'll use this convention for all
subsequent Dockerfiles).

This would run `npm install` every time we change our code, even if we
didn't change anything in `package.json`, and in case we need build
dependencies, they would be kept as a layer in the final image, thus
making it even heavier; each image would weight from 250 MB to 500 MB,
depending on if we needed or not build tools.


<figure class="center">
  <object data="https://blog-assets.busbud.com/wp-content/uploads/2018/05/no-idea.jpg" type="image/jpeg">
    <img alt="I have no idea what I'm doing" src="https://i.kym-cdn.com/photos/images/original/000/234/765/b7e.jpg">
  </object>
</figure>

## 2016-02-24 - First optimizations

After a couple months, we realized we could do better:

```dockerfile
FROM node:x.x.x-slim

RUN npm install -g npm@x.x.x && \
    rm -rf /root/.npm /root/.node-gyp /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html

COPY ./package.json /app/package.json
WORKDIR /app/

RUN npm install --production && \
    rm -rf /root/.npm /root/.node-gyp

# RUN apt-get -u update && \
#     apt-get -y install build-essential python && \
#     npm install --production && \
#     apt-get -y remove --purge --auto-remove build-essential python && \
#     apt-get clean && \
#     rm -rf /root/.npm /root/.node-gyp

COPY . /app/

CMD ["npm", "start"]
```

The major optimization here is to add only the `package.json` first and
then run `npm install`, this way unless the `package.json` is modified,
the `npm install` step is cached and therefore skipped.

This saves a lot of time during the build of images when there's no
package updates.

It also introduces installing the  build dependencies and cleaning up
with multiple instructions in the same `RUN` so we don't keep temporary
layers in the final image that would include development and temporary
files.

This is a great optimization for the final image size and has been for a
long time considered as [a good][image-size-0]
[practice][image-size-1] [in the][image-size-2] [Docker][image-size-3]
[community][image-size-4], but it prevents leveraging the Docker caching
system, so in our case when we have native dependencies to build, we
need to run the `apt-get install` step together with `npm install` every
time there's an update in the `package.json`.

[image-size-0]: https://blog.codeship.com/reduce-docker-image-size/
[image-size-1]: https://developers.redhat.com/blog/2016/03/09/more-about-docker-images-size/
[image-size-2]: https://blog.replicated.com/engineering/refactoring-a-dockerfile-for-image-size/
[image-size-3]: https://www.codeproject.com/Articles/1133826/tips-to-reduce-Docker-image-size
[image-size-4]: https://dzone.com/articles/optimizing-docker-images-for-image-size-and-build

But we didn't know of a better approach to minimize image size at that point,
and we chose to favor small image size instead of faster builds. That could
bring image size down to 250 MB even if we needed build dependencies.

## 2016-04-04 - Base images

The poor performance of the previous Dockerfile when we have native
dependencies and we update `package.json` (which happened more often
than we thought) required us to find another solution to try to have
fast builds while keeping the image size down.

We identified a recurrent build dependency in most of our microservices:
`libxmljs`. It was the bottleneck for each `npm install` run, because:

1. with our previous design, it required running `apt-get install` on
   every run, and it was the only dependency to require build tools;
1. on every `npm install` even if the `libxml` version was not modified,
   npm would systematically recompile it, which would take easily 30
   seconds to a minute.

We decided to build two base images: a generic one, and a `libxml`
version that would include a prebuilt `libxmljs`:

```dockerfile
FROM docker.busbud/alpine-node
# FROM docker.busbud/alpine-node:libxml

COPY ./package.json /app/package.json
WORKDIR /app/

RUN npm install --production && \
    rm -rf /root/.npm /root/.node-gyp

# RUN sed -i '/libxml/d' package.json && \
#     npm install --production && \
#     rm -rf /root/.npm /root/.node-gyp

COPY . /app/

CMD ["npm", "start"]
```

**Note:** we also switched to [Alpine Linux][alpine] at the same time,
which brought down the base image to 33 MB instead of 205 MB for the
Debian base one, so our final images would be around 50 MB.

This enabled good build performance and minimal image size, but at the
cost of maintaining the base images since there was no official
Alpine Node.js image at that time.

[alpine]: https://alpinelinux.org/

## 2016-04-27 - Squash

Less than a month later, we realized we needed other native dependencies
than `libxmljs` and that our solution was not flexible enough; for those
microservices, we were basically back to the previous iteration, where
we'd have to install and remove build tools around the `npm install`
command, hence losing all the build time gain of the base images.

That's when we found about the squashing technique, which looked like
the silver bullet we'd been searching for.

Squashing allows you to do whatever you want in the Dockerfile,
leveraging numerous layers and the caching that comes with it as you
wish, but the squashing step at the end makes it a single layer that
doesn't include the stuff you removed in the final image (as one would
expect).

Take a look at this example Dockerfile:

```dockerfile
FROM alpine
RUN cat /dev/urandom | head -c 200000000 > /200mb
RUN rm /200mb
```

If you build that image, you'll get an image of 204 MB, that is, 4 MB
for the base Alpine image plus the 200 MB file even though it was
removed.

Now if you install [docker-squash] and run it on the generated image,
you'll get a 4 MB image.

[docker-squash]: https://github.com/goldmann/docker-squash

This sorcery allowed us to keep all the build tools in our base images
without having temporary layers including all build tools in the final
images.

We just had to remove the cleanup steps from our base images, and add a
`RUN /clean` to the end of all our Dockerfiles, a step that would
cleanup everything, so that when squashing we keep only the needed
files.

## 2016-08-03 - No squash

While squashing looked like a great improvement, it ended up taking a
significant amount of time that was close to the time we gained by having
the build tools included and leveraging caching. Worst, the 20 second
squashing time was required for every build, even if we just fixed a
typo in the code, while that would be instant otherwise as long as we
don't touch the `package.json`.

We also realized that even though the total image size as reported per
`docker images` was significantly smaller with squashing (after removing
squashing, we were back to 250 MB images), it had in practice an
insignificant impact for our use case as all microservices would share
the base image layer, so it would be stored only once per host and in
the registry.

Therefore we dropped docker-squash and the `libxml` image, and made one
true base image that would include the build tools.

As a result, builds were lightning fast when there was no modifications
in `package.json`. As a downside, when we had to run `npm install`, we
had to systematically compile `libxmljs` again for the microservices
that use it.

## 2017-01-20 - No base images

We dropped our base images as there was now an official Alpine Node.js
image.

For the build tools problem, we decided to install them as a layer as
the first instruction so they can be cached, in order to have a build
time as fast as possible, giving up on image size as disk space is cheap
anyway.

Our Dockerfiles would now look like this:

```dockerfile
FROM node:x.x.x-alpine

# RUN apk add --no-cache python make g++
COPY ./package.json /app/package.json
WORKDIR /app/

RUN npm install --production && \
    rm -rf /root/.npm /root/.node-gyp

COPY . /app/
# RUN apk del python make g++

CMD ["npm", "start"]
```

When we need build tools, our images were still around 250 MB, but
otherwise we would stay closer to 50 MB.

Since we build Docker images locally on our laptops instead of centrally,
we couldn't guarantee that the build tools layer would be the same
(versions of programs could vary depending on the time the developer
built the image, and the eventual presence of a cache for that layer).
This prevented Docker from sharing that layer across all images and
ended up consuming significantly more space.

So the layering was still useful for having cache and fast builds
locally, but it wouldn't really optimize the size when sharing images
across hosts.

## 2017-04-19 - Multi-stage

I was watching closely the [multi-stage builds][multi-stage] proposition
to Docker, and when I heard that it reached Docker Edge, I was like,
guys, this is it.  The silver bullet actually exists.

[multi-stage]: https://docs.docker.com/engine/userguide/eng-image/multistage-build/

I tried it right away, and it blew my mind.

```dockerfile
FROM node:${NODE_VERSION}-alpine AS builder
WORKDIR /app/

RUN apk add --no-cache --virtual .build-deps python make g++
RUN rm /usr/local/bin/yarn && npm install -g yarn

COPY ./package.json ./yarn.lock /app/
RUN yarn --production
RUN apk del .build-deps

FROM alpine:${ALPINE_VERSION}
WORKDIR /app/

COPY --from=builder /usr/local/bin/node /usr/local/bin/
COPY --from=builder /usr/lib/ /usr/lib/
COPY --from=builder /app/ /app/
COPY . /app/

CMD ["node", "."]
```

The build is fast, we *never* need to run `apk add` locally once cached
for the first time, `yarn` is run only when dependencies changed, and
the final image ends up being the smallest it can be; there's no
temporary building layers, it contains only what's needed for it to run.

We based the actual image on `alpine` instead of `node:x.x.x-alpine`,
and copy just the Node.js binary and the libs that it needs, so we don't
include npm and Yarn in the production image. We started using `node .`
instead of `npm start` as `CMD` because of that, because `npm start` is
not a good reason to include npm in the final image.

By not having npm and Yarn in the final image, we gained 16 MB on all
our images. And not having the temporary build layer included when we
have native dependencies saved another 200 MB per image, bringing all
our images down to 50 MB in all cases, while having fast builds and
being able to completely leverage Docker layering and caching.

## Bonus - Multi-stage `ONBUILD` base images

At the same time we moved to multi-stage builds, we also made trivial
base images that use `ONBUILD` instructions so all the logic is
maintained once in the base images and we have nothing in the
microservices Dockerfiles (only specific stuff like additional system
dependencies).

We have a builder and a runtime base image, that we use like this:

```dockerfile
FROM docker.busbud/node:x.x.x-builder AS builder
FROM docker.busbud/node:x.x.x-runtime
```

The runtime image refers the builder image from `ONBUILD` instructions
so you literally have nothing to write.

And the base images themselves:

```dockerfile
# Builder
FROM node:x.x.x-alpine
WORKDIR /app/

RUN apk add --no-cache --virtual .build-deps python make g++
RUN rm /usr/local/bin/yarn && npm install -g yarn

ONBUILD COPY ./package.json ./yarn.lock /app/
ONBUILD RUN yarn --production
ONBUILD RUN apk del .build-deps

# Runtime
FROM alpine:x.x
WORKDIR /app/

ONBUILD COPY --from=builder /usr/local/bin/node /usr/local/bin/
ONBUILD COPY --from=builder /usr/lib/ /usr/lib/
ONBUILD COPY --from=builder /app/ /app/
ONBUILD COPY . /app/

CMD ["node", "."]
```

## Final word

That's it folks, thanks to multi-stage builds we can finally have
lightning fast builds while keeping the image size as small as possible!

After two years of trials, experiments, and mistakes, we finally found a
way to design our Dockerfiles that we have absolutely no issue with, and
no tradeoff whatsoever.

I hope you enjoyed traveling through the Git history of our Dockerfiles,
and that you'll enjoy multi-stage builds as much as we do.

At [Busbud][busbud] we invest in our productivity on a daily basis and
stay on top of modern technologies so we can deliver the world's bus
schedules to the most people and in the most places faster. If that's
right up your alley, join us, we're [hiring]!

[busbud]: https://www.busbud.com/en
[hiring]: https://www.busbud.com/en/careers

Also if you want to read more about multi-stage builds, please check our
next [article](docker-multi-stage.md)!
