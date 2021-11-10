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

# Don't allow interactive authentication.
KbdInteractiveAuthentication no

# Same as above but for older SSH versions.
ChallengeResponseAuthentication no

# Don't allow password authentication.
PasswordAuthentication no

# Only allow my own user.
AllowUsers val

# Only allow my own key.
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
