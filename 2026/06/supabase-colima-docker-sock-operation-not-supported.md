# Supabase with Colima: error from daemon `docker.sock` operation not supported
June 1, 2026

## TLDR

```sh
sudo ln -s ~/.colima/default/docker.sock /var/run/docker.sock
export DOCKER_HOST='unix:///var/run/docker.sock'
```

## Context

Working on a Supabase project, wanna run the whole stack locally using
`supabase start`.

Supabase local development environment is based on Docker containers, so
we need a runtime for it. [Docs](https://supabase.com/docs/guides/local-development)
mention Docker Desktop, Rancher Desktop, Podman and OrbStack.

But I like to be different and I want to use
[Colima](https://github.com/abiosoft/colima). 😂

However `supabase start` fails with:

```
failed to start docker container "supabase_vector_myapp":
Error response from daemon: error while creating mount source path '~/.colima/default/docker.sock':
mkdir ~/.colima/default/docker.sock: operation not supported
```

Found the same error on [this Reddit post](https://www.reddit.com/r/Supabase/comments/1nlh0p1/comment/nfw87m7/)
with the following fix:

```sh
ln -s ~/.colima/default/docker.sock /tmp/docker.sock
export DOCKER_HOST='unix:///tmp/docker.sock' 
```

But in my case, while this goes a bit further, I just get another error.
(And the post is archived so I can't even mention the final solution
there, oh well.)

```
ERROR source{component_kind="source" component_id=docker_host component_type=docker_logs}:
vector::sources::docker_logs: Listing currently running containers failed.
error=HyperLegacyError {
  err: hyper_util::client::legacy::Error(Connect, Os {
    code: 111,
    kind: ConnectionRefused,
    message: "Connection refused"
  })
}
```

Nothing came up online for this error so hopefully this blog post will help
if anyone runs into this.

However I stumbled more generic threads of trying to
[configure Colima to use the default Docker socket](https://github.com/abiosoft/colima/issues/365),
where the way to do this is:

```sh
sudo ln -s ~/.colima/default/docker.sock /var/run/docker.sock
export DOCKER_HOST='unix:///var/run/docker.sock'
```

So same as before but with `/var/run/docker.sock` instead of `/tmp/docker.sock`.

That worked flawlessly for me!
