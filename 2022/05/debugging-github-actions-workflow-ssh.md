# Debugging a GitHub Actions workflow via SSH
May 14, 2022

Since GitHub introduced [Actions](https://github.com/features/actions),
it's more and more common to use them for CI/CD tasks, because of the
tight integration with GitHub, and its simplicity.

Coming from [CircleCI](https://circleci.com/), I was used to their
["rerun job with SSH" feature](https://circleci.com/docs/2.0/ssh-access-jobs/),
which allowed to rerun a job while exposing a SSH server, to debug the
live test environment, and I was surprised to not find a similar feature
on GitHub Actions.

## Why SSH to the CI environment?

SSHing to CI is extremely handy in scenarios where **a bug happens only
on CI** and can't be reproduced locally or on other staging servers we
have control over.

It can also be useful **when initially setting up a GitHub Action** for
your app when you're not sure exactly what's available in the GitHub
image, what versions, etc. and want to **quickly fiddle around** to find
the right instructions to set up the environment for success.

## What about containers?

The advent of containers should mitigate part of the problem, with more
and more apps being ["dockerized"](https://en.wiktionary.org/wiki/dockerize),
but the reality is that your GitHub Actions workflow
[likely runs on `ubuntu-latest`](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#choosing-github-hosted-runners)
because that's far more convenient, and that's the main way that's
documented basically everywhere. You're still running in a container,
but that's GitHub's container, and it's (very) different from your
development, staging and production containers.

And even if you [bring your own container](https://docs.github.com/en/actions/using-jobs/running-jobs-in-a-container),
you're still likely to encounter **differences inherent to running in a
CI environment**: are the volumes and ports configured exactly the same?
What about the services you depend on like PostgreSQL, Redis, etc.? How
do you manage your environment variables? Are they any different from
your local environment? (They probably should.)

Also did you ever encounter timing-based bugs that **only happen on a
slow machine** (or network), or inversely, only happen **when the code
runs too fast**? I did. Both of those.

## Introducing action-sshd-cloudflared

This is why I created [action-sshd-cloudflared](https://github.com/valeriangalliat/action-sshd-cloudflared).

The idea? Find the **simplest way to run a SSH server** in a GitHub
Action and somehow connect to it. The last part can be a challenge
because as you can expect, the VM the workflow runs in **doesn't have a
public IP**, and not even IPv6. No way to directly bind a port publicly
accessible from the internet.

That's why we need to **resort to a relay host**. I chose
[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
for that, which is convenient because it includes a way to
[forward abritrary TCP](https://developers.cloudflare.com/cloudflare-one/applications/non-http/arbitrary-tcp/),
and happily runs as guest (no need to be authenticated).

In the end, it takes [100 lines of commented shell script](https://github.com/valeriangalliat/action-sshd-cloudflared/blob/master/setup-ssh),
and if you're interested in the details, I encourage you to read my
[explanation of how the server works](github-action-expose-ssh-server.md).

But for now, I'll start by **showing you how to use it**, then I'll
break down **what the client-side commands do**, and finally I'll
compare it to other options.

## Usage

Here's an example workflow YAML file that does nothing but checking out
your repository and starting a SSH server.

```yaml
name: CI
on:
  - push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: valeriangalliat/action-sshd-cloudflared@v1
```

More likely you already have a workflow YAML and the only part you care
about is to add this to your `steps` array:

```yaml
      - uses: valeriangalliat/action-sshd-cloudflared@v1
```

From there, here's an example output you'll find on your workflow logs:

```
Downloading `cloudflared` from <https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64>...
Configured SSH key(s) for user: valeriangalliat
Creating SSH server key...
Creating SSH server config...
Starting SSH server...
Starting tmux session...
Starting Cloudflare tunnel...

Run the following command to connect:

    ssh-keygen -R action-sshd-cloudflared && echo 'action-sshd-cloudflared ssh-rsa (public key goes here)' >> ~/.ssh/known_hosts && ssh -o ProxyCommand='cloudflared access tcp --hostname https://recycling-currently-enjoy-pregnant.trycloudflare.com' runner@action-sshd-cloudflared

What the one-liner does:

    # Remove old SSH server public key for `action-sshd-cloudflared`
    ssh-keygen -R action-sshd-cloudflared

    # Trust the public key for this session
    echo 'action-sshd-cloudflared ssh-rsa (public key goes here)' >> ~/.ssh/known_hosts

    # Connect using `cloudflared` as a transport (SSH is end-to-end encrpted over this tunnel)
    ssh -o ProxyCommand='cloudflared access tcp --hostname https://recycling-currently-enjoy-pregnant.trycloudflare.com' runner@action-sshd-cloudflared

    # Alternative if you don't want to verify the host key
    ssh -o ProxyCommand='cloudflared access tcp --hostname https://recycling-currently-enjoy-pregnant.trycloudflare.com' -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new runner@action-sshd-cloudflared
```

From there you can copy the (long, I know) one-liner that will connect
you to the VM. As you can see I also a commented version of the commands
for people to have a better understanding of what's happening. Let's go
through it in even more details.

## Details of the client connect commands

### Remove keys from previous debugging sessions

The first step is to remove all the keys matching host
`action-sshd-cloudflared` in `~/.ssh/known_hosts`. This is where your
SSH client stores the public keys of all the server you connected to.

```sh
ssh-keygen -R action-sshd-cloudflared
```

The reason we need to do this is because the fact the action generates a
new key every time it runs, we need to "forget" any previous key as they
won't be valid anymore. Otherwise SSH is confused and will prevent you
to connect to a host whose key is not the one it expects.

<div class="note">

**Note:** an alternative would be to use a unique host every time (as
we'll see later, because of the way use a proxy command, we could put
any host in there), for example the same one that Cloudflare generated
for us (`https://recycling-currently-enjoy-pregnant.trycloudflare.com`
in the earlier example).

What I don't like about that is every time you debug a GitHub workflow,
a new host will be added to your `~/.ssh/known_hosts` and this can
quickly pollute it. Sure, you can garbage collect them manually at some
point, but I'm still not a big fan of this idea.

</div>

### Trust the key for the current session

This step is not technically required, for if we don't do it, the SSH
client will prompt you to trust the key when it first encounters it
(trust on first use model).

But here we're already copy/pasting quite a long one-liner, so might as
well include an extra step to include the server public key and put it
in the known hosts file.

```sh
echo 'action-sshd-cloudflared ssh-rsa (public key goes here)' >> ~/.ssh/known_hosts
```

Trust on first use is fine, but this is better; would you really check
that the server key fingerprint matches what was shown in the server
logs otherwise?

### Connect to the Cloudflare Tunnel

It is the command we use as SSH `ProxyCommand`:

```sh
cloudflared access tcp --hostname https://recycling-currently-enjoy-pregnant.trycloudflare.com
```

This command if run by itself, will open a TCP connection to our SSH
server inside the GitHub VM, on port 2222 (the one we configured from
the other side of the Cloudflare Tunnel), through the relay that
Cloudflare gave us (the random subdomain on `trycloudflare.com`).

Everything written on `stdin` will be sent over the TCP socket, and
everything received will go to `stdout`. Simple as that.

The good thing is that this simple interface is supported by the `ssh`
command configure the underlying connection, with the `-o ProxyCommand`
flag.

### SSH through the proxy

This is the final piece of the puzzle:

```sh
ssh -o ProxyCommand='cloudflared access tcp --hostname https://recycling-currently-enjoy-pregnant.trycloudflare.com' runner@action-sshd-cloudflared
```

We explained already what the `cloudflared access tcp` command does, so
we'll focus on the rest:

```sh
ssh -o ProxyCommand='...' runner@action-sshd-cloudflared
```

Here we issue a SSH connection to host `action-sshd-cloudflared` with
user `runner`. But because of the `ProxyCommand` we configured, the
given host is not actually used, and we could put anything in there.

We could even connect to `runner@` (effectively no hostname), and that
would work. That being said this is not an ideal solution because it
would leave an entry in `~/.ssh/known_hosts` for a "empty string" host,
and that's not really useful. Putting `action-sshd-cloudflared` here is
more clear on what this key is related to.

The combination of both those commands effectively connects you to the
remote SSH server in the GitHub VM.

## What about action-upterm and action-tmate?

When I first tried to debug a GitHub workflow via SSH, I stumbled upon
two actions: [debugging with SSH](https://github.com/marketplace/actions/debugging-with-ssh)
and [debugging with tmate](https://github.com/marketplace/actions/debugging-with-tmate),
also named [action-upterm](https://github.com/lhotari/action-upterm)
and [action-tmate](https://github.com/mxschmitt/action-tmate) in their
respective repos.

They're both great and work perfectly for the task at hand, and can do
even more than that, because both [Upterm](https://upterm.dev/)
and [tmate](https://tmate.io/) are designed to *share* a terminal
session amongst multiple clients.

They both work by providing a client "host" software, and a public relay
server. The host uses the client to connect to the relay server and
share a terminal input and output with it, and other users can SSH to
that relay to access the shared session.

The advantage of the relay server in a world where most computers don't
have a public IP address and probably not public IPv6 either, is to
enable [NAT traversal](https://en.wikipedia.org/wiki/NAT_traversal) to
share a local service with the internet despite not being publicly
routable to. This is the problem that the famous
[ngrok](https://ngrok.com/) is solving, or more simply, SSH TCP
forwarding (with the `-L` and `-R` options).

### The problem with the relay server

There's one thing that bugs me very much with the way they both designed
the relay server: it's not just acting as a TCP relay to enable NAT
traversal! Not only the server contains business logic, but for this
business logic to work, it needs plaintext access to the SSH connection
(as opposed to only forwarding encrypted TCP traffic).

This is very much a no-no for me. The good thing is that they both
provide a way to [host](https://upterm.dev/#deploy-uptermd) your
[own](https://tmate.io/#host) relay server, where it's not as much of a
big deal that the relay sees plaintext traffic (it moves the trust from
"random strangers on the internet" to the entity you pay to host your
server, which is arguably an improvement, although far from end-to-end
encryption).

But I'm lazy, and that's too much work anyways. Especially when I know a
bare `sshd` and a "dumb" (here used in a positive sense) TCP relay would
do the job for me.

I would have been more keep to using Upterm or tmate if they moved all
the business logic to the host client software, and let the relay be...
a (dumb) TCP relay happily breaking NAT and forwarding encrypted traffic
around. But I reckon this can be a challenge especially with the
extended feature set those tools want to support.

## Conclusion

Overall, `sshd` and `cloudflared` work perfectly hand in hand to allow
SSHing in an otherwise unroutable GitHub workflow container.

This is the beauty of the Unix philosophy: tools that do one thing, and
do it well, and are *composable* through *universal interfaces*.

If you liked this post, you will definitely enjoy the second part where
I [explain how action-sshd-cloudflared works internally](github-action-expose-ssh-server.md).
Cheers!
