---
tweet: https://x.com/valeriangalliat/status/1525554351648956416
---

# How to make a GitHub Action that exposes a SSH server
May 14, 2022

In the [first post](debugging-github-actions-workflow-ssh.md), I
explained how to use [action-sshd-cloudflared](https://github.com/valeriangalliat/action-sshd-cloudflared),
a GitHub Action that I wrote to easily SSH to a GitHub workflow
container and debug it efficiently. I gave a precise explanation of
[what the client commands do](debugging-github-actions-workflow-ssh.md#details-of-the-client-connect-commands),
and I [compared it to similar alternatives](debugging-github-actions-workflow-ssh.md#what-about-action-upterm-and-action-tmate).

In this post, we'll go through the details of the server (the code that
runs inside the GitHub workflow). We'll see how to make a simple GitHub
Action that runs a shell script (or anything *executable*), a couple
useful environment variables, and most importantly, what's the recipe to
run a SSH server there and expose it over the internet despite the
container not being publicly addressable.

## Making the simplest GitHub Action possible

All we need to turn a simple GitHub repository in a GitHub Action is to
add a valid `action.yml` at the top level.

GitHub can run
[Docker actions](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action),
[JavaScript actions](https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action),
but the one we care about is the [composite action](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action).
A composite action allows us to run simple *commands* in a *shell* and
that's exactly what we need. 👍

```yaml
name: Debug via SSH
description: Setup a SSH server with a tunnel to access it to debug your action via SSH.
runs:
  using: composite
  steps:
    - run: $GITHUB_ACTION_PATH/setup-ssh
      shell: bash
```

Unlike in a normal workflow YAML, the `run` command must also include an
explicit shell. We can use any of the [GitHub Actions environment variables](https://docs.github.com/en/actions/learn-github-actions/environment-variables)
directly in there, which is convenient because we have
`GITHUB_ACTION_PATH`, the path to our action repository (by default the
working directory is the one containing the user's code, not our action
code).

From there, the [`setup-ssh` script](https://github.com/valeriangalliat/action-sshd-cloudflared/blob/master/setup-ssh)
can be broken down in 9 simple steps:

1. [Download the latest `cloudflared` binary](#download-cloudflared).
1. [Fetch the public SSH keys](#fetch-the-actor-keys) of the GitHub user
   who triggered the workflow to a `authorized_keys` file.
1. [If there was no SSH key, set a password](#set-a-password) for the
   `runner` user so that there's alternative way to connect.
1. [Generate a server key](#generate-a-server-key).
1. [Create the `sshd` config](#create-the-sshd-config).
1. [Start `sshd`](#start-sshd).
1. [Start a tmux session](#start-a-tmux-session).
1. [Start `cloudflared`](#start-cloudflared) to expose the `sshd` port on the internet.
1. [Output the client instructions](#output-the-client-instructions).
1. [Wait for the tmux session to end and stop everything](#watch-for-session-end).

## Download `cloudflared`

We start simple and easy.

```sh
curl --location --silent --output cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared
```

## Fetch the actor keys

In GitHub Actions, the user who trigger the workflow is called an
"actor". Their username is set in the `GITHUB_ACTOR` environment
variable.

As you may know, [you configured](https://github.com/settings/keys) a
number of SSH keys on GitHub to be able to push to repositories over
SSH. Those keys are public knowledge, and we can fetch them via the
public GitHub API, which is convenient here to automatically give the
actor SSH access to that server.

```sh
curl -s "https://api.github.com/users/$GITHUB_ACTOR/keys" | jq -r '.[].key' > authorized_keys
```

The GitHub API response is in JSON, but we use a simple [jq](https://stedolan.github.io/jq/)
script to extract the raw key, one per line, to put it in a valid
`authorized_keys` file.

## Set a password

If there was no SSH keys for that user, we set a password as a fallback,
so they still have a means to connect.

To test whether or not there was any SSH key, we use:

```sh
grep -q . authorized_keys
```

`-q` makes `grep` quiet (we don't need to display the output), `.` is
the regular expression to match (any character), and `authorized_keys`
is the file we use as input.

If there's any character in that file, `grep` will exit with 0
(success). Otherwise with a nonzero code, which means nothing was
matched.

We can conveniently use it in a `if` condition:

```sh
if grep -q . authorized_keys; then
    echo "Configured SSH key(s) for user: $GITHUB_ACTOR"
else
    echo "No SSH key found for user: $GITHUB_ACTOR"
    echo "Setting SSH password..."
fi
```

It's in that `else` branch that we generate and set the password. To
generate it, we fetch 16 characters from `/dev/urandom`:

```sh
password=$(base64 < /dev/urandom | tr -cd '[:alnum:]' | head -c16)
```

* `base64 < /dev/urandom` encodes as Base64 the stream of random bytes
  from `/dev/urandom`. The stream is infinite but the pipleine is
  "lazy".
* `tr -cd '[:alnum:]'` keeps only alphanumeric characters.
* `head -c16` keeps only the first 16 characters (or should I say,
  bytes, to be accurate) and terminates the stream as soon as it has
  them.

This gives us a password that we can set for the current user.

```sh
(echo "$password"; echo "$password") | sudo passwd "$USER"
```

We can't use the `passwd` command directly because it first prompts us
for our own current password (which we don't know), but we have `root`
access in this VM through `sudo`, and `root` doesn't need confirmation
to change anyone's password.

We echo the password twice because `passwd` typically asks to input the
password first, then a second time for confirmation.

## Generate a server key

`ssh-keygen` is a cool utility to generate SSH keys. It defaults to a
RSA key which is fine with me.

* `-q` makes it quiet (we don't need the logs).
* `-f` indicates the output file to write the key to (the public key
  will be in a file with a `.pub` suffix).
* `-N ''` is to set an empty passphrase (otherwise `ssh-keygen` will
  prompt to set a passphrase).

```sh
ssh-keygen -q -f ssh_host_rsa_key -N ''
```

## Create the `sshd` config

We copy it from a template file, where we just replace the `$PWD` and
`$USER` symbols by the corresponding environment variable.

```sh
sed "s,\$PWD,$PWD,;s,\$USER,$USER," sshd_config.template > sshd_config
```

This is a good time to review the template. It's heavily based on my
[standalone userland SSH server](../../2021/11/standalone-userland-ssh-server.md)
config I [published](https://github.com/valeriangalliat/sshd-on-the-go)
last year!

```apache
Port 2222
HostKey $PWD/ssh_host_rsa_key
PidFile $PWD/sshd.pid
```

First we set the port to 2222, and we define the host key and process ID
file. We could have written `PidFile none` to prevent the default of
`/run/sshd.pid`, because we don't actually use it, but it doesn't hurt.

```apache
UsePAM yes
```

We enable PAM (pluggable authentication module). Not going in details
with this, but keep in mind it's required for this to work at least on
Debian-based systems.

```apache
KbdInteractiveAuthentication yes
ChallengeResponseAuthentication yes
PasswordAuthentication yes
```

This enables interactive password authentication. They're actually
enabled by default so we could leave them out.

```apache
AllowUsers $USER
AuthorizedKeysFile $PWD/authorized_keys
```

We only allow the Unix user who the workflow is running as, and we allow
the SSH keys we fetched earlier in `authorized_keys`. Remember that we
replace those `$USER` and `$PWD` symbols with a `sed` command before
starting the server, you can't actually use variables in here otherwise.

```apache
ForceCommand tmux attach
```

Finally we force the `tmux attach` command to run upon login. This makes
sure the user is connecting to the tmux session we'll start in the
following steps, and it's important because we monitor the status of
this session to determine when to stop the server.

## Start `sshd`

```sh
/usr/sbin/sshd -f sshd_config -D &
sshd_pid=$!
```

* We need to start it with an absolute path (it is required when
  starting an ad hoc SSH server like this).
* `-f` lets us specify the configuration file to use.
* `-D` starts it as foreground (by default it starts as a daemon).
* `&` makes it a background process in this script so that we can fetch
  its process ID with `$!` right after, and kill it at the end.

We could avoid `-D` and `&` altogether by using the `sshd.pid` file that
we configured in `PidFile` to retrieve the process ID instead. Whatever
works.

## Start a tmux session

```sh
(cd "$GITHUB_WORKSPACE" && tmux new-session -d -s debug)
```

We start a subshell (the parens around the command), so that `cd` only
affects the subshell and not our top-level environment.

We effectively change the current directory to the main workflow
directory, defined in `GITHUB_WORKSPACE`, and start a tmux session.

With `tmux new-session`, `-d` disables the default behavior of
attaching the session to the current terminal, and `-s` allows us to
give it a name.

## Start `cloudflared`

```sh
./cloudflared tunnel --no-autoupdate --url tcp://localhost:2222 &
cloudflared_pid=$!
```

We run the `cloudflared` binary that we downloaded to the current
directory earlier. This command allows us to start a tunnel forwarding
to port 2222, where our SSH server is listening.

And again, we terminate with `&` to start it as a background process so
that we can keep running commands and kill it at the end.

But there's a few more things we need to add to this command:

```sh
./cloudflared tunnel ... 2>&1 | tee cloudflared.log | sed -u 's/^/cloudflared: /' &
```

* `2>&1` redirects the `stderr` output to `stdout`, so that we can
  `tee` it to `cloudflared.log` file.
* `tee` will write the input to the given file, but also keep outputting
  it to `stdout` at the same time.
* This is great because we can now use a simple `sed` command to prefix
  it with `cloudflared:` (so that the logs have some context).

This log file is useful for us to retrieve the relay URL that
`cloudflared` will output, which we do right after:

```sh
url=$(head -1 <(tail -f cloudflared.log | grep --line-buffered -o 'https://.*\.trycloudflare.com'))
```

* `tail -f cloudflared.log` *follows* the file, meaning that it keeps
  watching for new lines indefinitely, and outputs them as they come.
* The `grep` command has a simple regex to identify the relay URL.
  * `--line-buffered` is important here because we want to work *lazily*
    and exit as soon as we find a match. If `grep` was buffering more
    than one line of data, this could just hang forever.
  * `-o` will print only the text matched by the regex instead of the
    whole matching line.
* We put all of that in a subshell that we use as input to the `head`
  command with the `<()` syntax.
* `head -1` will exit the whole pipeline after one line is outputted,
  allowing us to continue running the script.

<div class="note">

**Note:** we can't put `head -1` at the end of the pipeline even though
that would seem intuitive, because it would take `grep` to try to
*write* to the `head` input after it was closed to notice that the pipe
was broken, and then it would take another line output from `tail` to
notice that `grep` exited.

In practice this just means this would hang indefinitely because
`cloudflared` doesn't output the relay host twice.

See more details [here](https://stackoverflow.com/questions/45326901/lazy-non-buffered-processing-of-shell-pipeline).

</div>

## Output the client instructions

We already have the `url` variable as well as an optional `password`
variable.

With that, all we need is the SSH server public key to include it as
part of the connection command that the user will paste.

```sh
public_key=$(cut -d' ' -f1,2 < ssh_host_rsa_key.pub)
```

Thanks to the `cut` command, we split the single line in the given file
by space, and output only fields 1 and 2. This file normally has 3
fields: the key type, the actual key, and a comment. We don't need the
comment.

We can then display those variables in a friendly and convenient way to
the user. I already detailed that in [the first part](debugging-github-actions-workflow-ssh.md#details-of-the-client-connect-commands)
focusing on the client side, check it out if you didn't already!

## Watch for session end

```sh
tmux wait-for channel
```

This commands waits for a channel named `channel` to be "woken up" by a
matching `tmux wait-for -S channel`.

We don't actually ever run this last command, and we don't really care
about the channel either, but the effect this have if we never "wake up"
the channel, is that it will hang until the tmux session itself is over.

That's exactly what we need: when the user is done debugging, they'll
typically end the tmux session, and this is our way to know we can tear
down the servers:

```sh
kill "$cloudflared_pid"
kill "$sshd_pid"
```

## Wrapping up

And just like that, you know everything about
[action-sshd-cloudflared](https://github.com/valeriangalliat/action-sshd-cloudflared)!

This script is simple enough to be explained in depth in a blog post,
and builds on top of rock solid programs like `sshd`, `cloudflared` and
tmux.

Thanks to Cloudflare Tunnel guest mode, we don't even need an API key or
token to set up the relay, and because GitHub already exposes the actor
public SSH keys, we can preconfigure them so that everything just works
out of the box.

I hope GitHub introduces a SSH feature natively at some point, that
would make actions like this obsolete. In the meantime, I hope this
helps you debug your GitHub workflows!
