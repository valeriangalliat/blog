---
tweet: https://x.com/valeriangalliat/status/1458282446659653634
---

# Standalone userland SSH server
November 9, 2021

I guess I have pretty unusual software needs sometimes. I've been
wanting to spawn a one-off SSH server on one of my computers so that I
can `rsync` something to it from another machine.

I didn't want to enable SSH connections systemwide on this host.
Ideally, I wanted to start a server from my unprivileged user, that
would only allow access to that particular user, and only to the
specific SSH key of my other machine.

Turns out with a simple `sshd_config`, [this is possible](https://sourceware.org/legacy-ml/cygwin/2008-04/msg00363.html)!

<div class="note">

**Edit:** this is now automated in a easy to use Git repository,
[go check it out](https://github.com/valeriangalliat/sshd-on-the-go)!

</div>

First, let's make a directory to contain our server files.

```sh
mkdir standalone-sshd
cd standalone-sshd
```

In there, we generate our host RSA key (the `-N ''` part specifies an
empty passphrase).

```sh
ssh-keygen -f ssh_host_rsa_key -N ''
```

Then, add your public key to a `authorized_keys` file in this same
directory (same format as a regular `~/.ssh/authorized_keys`), and add
the following configuration in a `sshd_config` file.

```apache
Port 2222
HostKey /path/to/standalone-sshd/ssh_host_rsa_key
PidFile /path/to/standalone-sshd/sshd.pid

# Don't allow interactive authentication
KbdInteractiveAuthentication no

# Same as above but for older SSH versions
ChallengeResponseAuthentication no

# Don't allow password authentication
PasswordAuthentication no

# Only allow my own user
AllowUsers val

# Only allow my own key
AuthorizedKeysFile /path/to/standalone-sshd/authorized_keys
```

Tweak the port, user, and other settings to your liking, but that should
give you a good base!

With that, you can run the server with the following command (the `-D`
option starts the server in the foreground instead of the default daemon
mode).

```sh
/usr/sbin/sshd -f sshd_config -D
```

## Alternative with password

Alternatively, if you want to enable password authentication (with your
user's Unix login password), you can get away with an even simpler
config:

```apache
Port 2222
HostKey /path/to/standalone-sshd/ssh_host_rsa_key
PidFile /path/to/standalone-sshd/sshd.pid

# PAM is necessary for password authentication on Debian-based systems
UsePAM yes

# Allow interactive authentication (default value)
#KbdInteractiveAuthentication yes

# Same as above but for older SSH versions (default value)
#ChallengeResponseAuthentication yes

# Allow password authentication (default value)
#PasswordAuthentication yes

# Only allow my own user
AllowUsers val
```

I included but commented out the settings that are necessary but whose
default value is already what we want (essentially, password
authentication is enabled by default).

We only need `UsePAM yes` on Debian-based systems for password
authentication to work. As pointed out in [this answer](https://unix.stackexchange.com/a/673581/521108),
contrary to what the [`sshd_config(5)`](https://linux.die.net/man/5/sshd_config)
man page says ("If `UsePAM` is enabled, you will not be able to run
`sshd(8)` as a non-root user"), it's not actually a problem when running
in userland, and it's even required if we want to support password
authentication.
