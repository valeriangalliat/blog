# Docker build secrets!
April 27, 2021

For a long time now, I've been wanting to have a way when building
Docker containers, to use external secrets, e.g. API or SSH keys, during
build time, that wouldn't be exposed in any layer.

It was possible to use build arguments and multi-stage builds to make
sure that we don't include the secrets in the final image that we push,
but it would still leave the secrets in the intermediate layers on my
local machine. Not ideal.

## Docker 18.09 and BuildKit

With BuildKit, Docker added first-class support for secrets, which makes
this even cleaner and more secure.

Here's for example how to mount a `.netrc` file at build time to give
pip access to your credentials for some hosts. In your Dockerfile:

```dockerfile
RUN --mount=type=secret,id=netrc,dst=/path/to/.netrc pip install -r requirements.txt
```

And to build it:

```sh
DOCKER_BUILDKIT=1 docker build --secret id=netrc,src=~/.netrc .
```

## SSH support

BuildKit also have a flag to forward SSH connections using `ssh-agent`.
From their [documentation](https://docs.docker.com/develop/develop-images/build_enhancements/):

```dockerfile
FROM alpine

RUN apk add --no-cache openssh-client git
RUN mkdir -m 700 ~/.ssh && ssh-keyscan github.com > ~/.ssh/known_hosts

# Clone private repository
RUN --mount=type=ssh git clone git@github.com:myorg/myproject.git
```

To build it (ignore the first two lines if you already have `ssh-agent`
running and configured):

```sh
# Start `ssh-agent` and set environment variables
eval $(ssh-agent)

# Add your default SSH keys to the agent
ssh-add

DOCKER_BUILDKIT=1 docker build --ssh default .
```
